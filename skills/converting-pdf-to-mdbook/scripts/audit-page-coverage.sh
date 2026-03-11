#!/usr/bin/env bash
set -euo pipefail

# Deterministic page coverage audit for assembled mdBook content.
# Usage: ./audit-page-coverage.sh <mdbook-project-dir>

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <mdbook-project-dir>" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$1" && pwd)"
SRC_DIR="$PROJECT_DIR/src"
SUMMARY="$SRC_DIR/SUMMARY.md"
BOOK_TOML="$PROJECT_DIR/book.toml"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Error: $SRC_DIR does not exist. Is this an mdBook project?" >&2
  exit 1
fi

if [[ ! -f "$SUMMARY" ]]; then
  echo "Error: $SUMMARY not found." >&2
  exit 1
fi

PASS=0
FAIL=0
WARN=0
EXPECTED_FIRST_PAGE=""
EXPECTED_LAST_PAGE=""
EXPECTED_RANGE_CONFIGURED=false

report_pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

report_fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

report_warn() {
  echo "[WARN] $1"
  WARN=$((WARN + 1))
}

format_range() {
  local first="$1"
  local last="$2"

  if [[ "$first" -eq "$last" ]]; then
    printf '%s' "$first"
  else
    printf '%s-%s' "$first" "$last"
  fi
}

extract_summary_links() {
  grep -oE '\[[^]]+\]\(([^)]+\.md)\)' "$SUMMARY" | sed -E 's/.*\(([^)]+)\)/\1/'
}

extract_physical_page() {
  local line="$1"
  local page=""

  page=$(printf '%s\n' "$line" | sed -nE 's/.*<!--[[:space:]]*pdf-page:[[:space:]]*([0-9]+)[[:space:]]*-->.*$/\1/p')
  if [[ -n "$page" ]]; then
    printf '%d\n' "$((10#$page))"
    return 0
  fi

  page=$(printf '%s\n' "$line" | sed -nE 's/.*<!--[[:space:]]*pdf-page:[^>]*physical=([0-9]+)[^>]*-->.*$/\1/p')
  if [[ -n "$page" ]]; then
    printf '%d\n' "$((10#$page))"
    return 0
  fi

  return 1
}

read_expected_range() {
  local config_first="${PDF_AUDIT_EXPECTED_FIRST_PAGE:-}"
  local config_last="${PDF_AUDIT_EXPECTED_LAST_PAGE:-}"

  if [[ -z "$config_first" && -f "$BOOK_TOML" ]]; then
    config_first=$(sed -nE 's/^[[:space:]]*#[[:space:]]*pdf-audit-first-page[[:space:]]*=[[:space:]]*"?([0-9]+)"?[[:space:]]*$/\1/p' "$BOOK_TOML" | head -1)
  fi

  if [[ -z "$config_last" && -f "$BOOK_TOML" ]]; then
    config_last=$(sed -nE 's/^[[:space:]]*#[[:space:]]*pdf-audit-last-page[[:space:]]*=[[:space:]]*"?([0-9]+)"?[[:space:]]*$/\1/p' "$BOOK_TOML" | head -1)
  fi

  if [[ -z "$config_first" && -z "$config_last" ]]; then
    return 0
  fi

  if [[ -z "$config_first" || -z "$config_last" ]]; then
    report_warn "Page coverage - expected range metadata is incomplete; set both # pdf-audit-first-page and # pdf-audit-last-page comments in book.toml to enable edge-page auditing"
    return 0
  fi

  EXPECTED_FIRST_PAGE="$((10#$config_first))"
  EXPECTED_LAST_PAGE="$((10#$config_last))"

  if (( EXPECTED_FIRST_PAGE < 1 || EXPECTED_LAST_PAGE < 1 )); then
    report_fail "Page coverage - configured expected range must be positive (found ${EXPECTED_FIRST_PAGE}-${EXPECTED_LAST_PAGE})"
    return 0
  fi

  if (( EXPECTED_FIRST_PAGE > EXPECTED_LAST_PAGE )); then
    report_fail "Page coverage - configured expected range is invalid (${EXPECTED_FIRST_PAGE}-${EXPECTED_LAST_PAGE})"
    return 0
  fi

  EXPECTED_RANGE_CONFIGURED=true
}

find_page_index() {
  local needle="$1"
  local i

  for ((i = 0; i < ${#SEEN_PAGES[@]}; i++)); do
    if [[ "${SEEN_PAGES[$i]}" == "$needle" ]]; then
      printf '%s\n' "$i"
      return 0
    fi
  done

  return 1
}

read_expected_range

declare -a ORDERED_FILES=()
declare -a NO_MARKERS=()
declare -a MALFORMED_MARKERS=()
declare -a MISSING_FILES=()
declare -a PAGE_VALUES=()
declare -a PAGE_FILES=()
declare -a PAGE_LINES=()
declare -a SEEN_PAGES=()
declare -a SEEN_FILES=()
declare -a SEEN_LINES=()
declare -a MISSING_RANGES=()
declare -a DUPLICATES=()
declare -a OUT_OF_ORDER=()
declare -a OUT_OF_RANGE=()

while IFS= read -r summary_link; do
  [[ -z "$summary_link" ]] && continue
  ORDERED_FILES+=("$summary_link")
done < <(extract_summary_links)

if [[ ${#ORDERED_FILES[@]} -eq 0 ]]; then
  report_fail "Page coverage - SUMMARY.md does not reference any markdown content files"
fi

for rel_path in "${ORDERED_FILES[@]}"; do
  target="$SRC_DIR/$rel_path"

  if [[ ! -f "$target" ]]; then
    MISSING_FILES+=("$rel_path")
    continue
  fi

  file_has_marker=false
  line_no=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    [[ "$line" == *'pdf-page:'* ]] || continue

    if ! page_num=$(extract_physical_page "$line"); then
      MALFORMED_MARKERS+=("src/$rel_path:$line_no")
      continue
    fi

    if (( page_num < 1 )); then
      MALFORMED_MARKERS+=("src/$rel_path:$line_no")
      continue
    fi

    file_has_marker=true
    PAGE_VALUES+=("$page_num")
    PAGE_FILES+=("$rel_path")
    PAGE_LINES+=("$line_no")
  done < "$target"

  if [[ "$file_has_marker" == false ]]; then
    NO_MARKERS+=("$rel_path")
  fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  report_fail "Page coverage - ${#MISSING_FILES[@]} SUMMARY.md file(s) could not be audited"
  for rel_path in "${MISSING_FILES[@]}"; do
    echo "  src/$rel_path"
  done
fi

if [[ ${#NO_MARKERS[@]} -gt 0 ]]; then
  report_fail "Page coverage - ${#NO_MARKERS[@]} assembled file(s) are missing pdf-page markers"
  for rel_path in "${NO_MARKERS[@]}"; do
    echo "  src/$rel_path"
  done
fi

if [[ ${#MALFORMED_MARKERS[@]} -gt 0 ]]; then
  report_fail "Page coverage - ${#MALFORMED_MARKERS[@]} malformed pdf-page marker(s)"
  for location in "${MALFORMED_MARKERS[@]}"; do
    echo "  $location"
  done
fi

if [[ ${#PAGE_VALUES[@]} -eq 0 ]]; then
  report_fail "Page coverage - no valid pdf-page markers found in assembled content"
else
  if [[ "$EXPECTED_RANGE_CONFIGURED" == false ]]; then
    EXPECTED_FIRST_PAGE="${PAGE_VALUES[0]}"
    EXPECTED_LAST_PAGE="${PAGE_VALUES[$(( ${#PAGE_VALUES[@]} - 1 ))]}"
    report_warn "Page coverage - expected range inferred from observed markers (${EXPECTED_FIRST_PAGE}-$(printf '%s' "$EXPECTED_LAST_PAGE")); set # pdf-audit-first-page/# pdf-audit-last-page comments in book.toml or PDF_AUDIT_EXPECTED_FIRST_PAGE/PDF_AUDIT_EXPECTED_LAST_PAGE to audit leading and trailing edges explicitly"
  fi

  expected_page="$EXPECTED_FIRST_PAGE"
  prev_page=""
  prev_origin=""

  for ((i = 0; i < ${#PAGE_VALUES[@]}; i++)); do
    current_page="${PAGE_VALUES[$i]}"
    current_file="${PAGE_FILES[$i]}"
    current_line="${PAGE_LINES[$i]}"
    current_origin="src/$current_file:$current_line"

    if (( current_page < EXPECTED_FIRST_PAGE || current_page > EXPECTED_LAST_PAGE )); then
      OUT_OF_RANGE+=("page $current_page at $current_origin is outside expected range $(format_range "$EXPECTED_FIRST_PAGE" "$EXPECTED_LAST_PAGE")")
      prev_page="$current_page"
      prev_origin="$current_origin"
      continue
    fi

    if duplicate_index=$(find_page_index "$current_page"); then
      first_origin="src/${SEEN_FILES[$duplicate_index]}:${SEEN_LINES[$duplicate_index]}"
      DUPLICATES+=("page $current_page first appears at $first_origin and repeats at $current_origin")
      prev_page="$current_page"
      prev_origin="$current_origin"
      continue
    fi

    if (( current_page < expected_page )); then
      if [[ -n "$prev_page" ]]; then
        OUT_OF_ORDER+=("page $current_page at $current_origin appears after page $prev_page at $prev_origin")
      else
        OUT_OF_ORDER+=("page $current_page at $current_origin appears before the expected sequence start")
      fi
    elif (( current_page > expected_page )); then
      MISSING_RANGES+=("$(format_range "$expected_page" "$((current_page - 1))") before $current_origin")
      expected_page="$current_page"
    fi

    SEEN_PAGES+=("$current_page")
    SEEN_FILES+=("$current_file")
    SEEN_LINES+=("$current_line")
    expected_page="$((current_page + 1))"
    prev_page="$current_page"
    prev_origin="$current_origin"
  done

  if (( expected_page <= EXPECTED_LAST_PAGE )); then
    MISSING_RANGES+=("$(format_range "$expected_page" "$EXPECTED_LAST_PAGE") at end of assembled content")
  fi
fi

if [[ ${#MISSING_RANGES[@]} -gt 0 ]]; then
  report_fail "Page coverage - missing physical page range(s) detected"
  for missing_range in "${MISSING_RANGES[@]}"; do
    echo "  $missing_range"
  done
fi

if [[ ${#DUPLICATES[@]} -gt 0 ]]; then
  report_fail "Page coverage - duplicate physical page marker(s) detected"
  for duplicate in "${DUPLICATES[@]}"; do
    echo "  $duplicate"
  done
fi

if [[ ${#OUT_OF_ORDER[@]} -gt 0 ]]; then
  report_fail "Page coverage - out-of-order or reversed physical page marker(s) detected"
  for issue in "${OUT_OF_ORDER[@]}"; do
    echo "  $issue"
  done
fi

if [[ ${#OUT_OF_RANGE[@]} -gt 0 ]]; then
  report_fail "Page coverage - physical page marker(s) fell outside the expected range"
  for issue in "${OUT_OF_RANGE[@]}"; do
    echo "  $issue"
  done
fi

if [[ $FAIL -eq 0 ]]; then
  report_pass "Page coverage - physical pages $(format_range "$EXPECTED_FIRST_PAGE" "$EXPECTED_LAST_PAGE") appear exactly once in SUMMARY order"
fi

echo ""
echo "=== Page Coverage Audit: $FAIL FAIL, $WARN WARN, $PASS PASS ==="

if [[ $FAIL -gt 0 ]]; then
  echo "AUDIT_STATUS=fail"
  exit 1
fi

if [[ $WARN -gt 0 ]]; then
  echo "AUDIT_STATUS=warn"
  exit 0
fi

echo "AUDIT_STATUS=pass"
exit 0
