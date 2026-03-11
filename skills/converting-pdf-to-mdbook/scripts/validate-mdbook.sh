#!/usr/bin/env bash
set -euo pipefail

# Deterministic validation of an mdBook project.
# Usage: ./validate-mdbook.sh <mdbook-project-dir>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <mdbook-project-dir>" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$1" && pwd)"
SRC_DIR="$PROJECT_DIR/src"
SUMMARY="$SRC_DIR/SUMMARY.md"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Error: $SRC_DIR does not exist. Is this an mdBook project?" >&2
  exit 1
fi

if [[ ! -f "$SUMMARY" ]]; then
  echo "Error: $SUMMARY not found." >&2
  exit 1
fi

# --- Counters ---
PASS=0
FAIL=0
WARN=0

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

echo "=== mdBook Validation Report ==="
echo ""

# -------------------------------------------------------
# 1. mdbook build
# -------------------------------------------------------
if command -v mdbook &>/dev/null; then
  BUILD_OUTPUT=""
  BUILD_RC=0
  BUILD_OUTPUT=$(mdbook build "$PROJECT_DIR" 2>&1) || BUILD_RC=$?

  BUILD_ERRORS=$(echo "$BUILD_OUTPUT" | grep -iE '(error|warning)' || true)

  if [[ $BUILD_RC -ne 0 ]]; then
    report_fail "mdbook build - build failed (exit code $BUILD_RC)"
    if [[ -n "$BUILD_ERRORS" ]]; then
      echo "$BUILD_ERRORS" | sed 's/^/  /'
    fi
  elif [[ -n "$BUILD_ERRORS" ]]; then
    report_fail "mdbook build - compiled with warnings/errors"
    echo "$BUILD_ERRORS" | sed 's/^/  /'
  else
    report_pass "mdbook build - compiled successfully"
  fi
else
  report_fail "mdbook build - mdbook not found (install: cargo install mdbook)"
fi

# -------------------------------------------------------
# 2. markdownlint
# -------------------------------------------------------
if command -v markdownlint-cli2 &>/dev/null; then
  LINT_OUTPUT=""
  LINT_RC=0
  LINT_OUTPUT=$(markdownlint-cli2 --config "$SCRIPT_DIR/.markdownlint-cli2.yaml" "$SRC_DIR/**/*.md" 2>&1) || LINT_RC=$?

  if [[ $LINT_RC -ne 0 && -n "$LINT_OUTPUT" ]]; then
    VIOLATION_COUNT=$(echo "$LINT_OUTPUT" | grep -cE '^.+:[0-9]+' || true)
    report_fail "markdownlint - ${VIOLATION_COUNT} violation(s) found"
    echo "$LINT_OUTPUT" | grep -E '^.+:[0-9]+' | sed 's/^/  /' || true
  else
    report_pass "markdownlint - no violations"
  fi
else
  report_fail "markdownlint - markdownlint-cli2 not found (install: npm install -g markdownlint-cli2)"
fi

# -------------------------------------------------------
# 3. SUMMARY.md link integrity
# -------------------------------------------------------
BROKEN_LINKS=()
LINK_COUNT=0

while IFS= read -r link; do
  [[ -z "$link" ]] && continue
  LINK_COUNT=$((LINK_COUNT + 1))
  TARGET="$SRC_DIR/$link"
  if [[ ! -f "$TARGET" ]]; then
    BROKEN_LINKS+=("$link")
  fi
done < <(grep -oE '\[.*?\]\(([^)]+\.md)\)' "$SUMMARY" | sed -E 's/.*\(([^)]+)\)/\1/')

if [[ ${#BROKEN_LINKS[@]} -gt 0 ]]; then
  report_fail "SUMMARY.md links - ${#BROKEN_LINKS[@]} broken link(s) out of $LINK_COUNT"
  for bl in "${BROKEN_LINKS[@]}"; do
    echo "  $bl"
  done
else
  report_pass "SUMMARY.md links - all $LINK_COUNT link(s) valid"
fi

# -------------------------------------------------------
# 4. Orphan file check
# -------------------------------------------------------
ORPHANS=()

while IFS= read -r md_file; do
  [[ -z "$md_file" ]] && continue
  REL_PATH="${md_file#"$SRC_DIR/"}"
  [[ "$REL_PATH" == "SUMMARY.md" ]] && continue
  if ! grep -qF "$REL_PATH" "$SUMMARY"; then
    ORPHANS+=("$REL_PATH")
  fi
done < <(find "$SRC_DIR" -name '*.md' -type f | sort)

if [[ ${#ORPHANS[@]} -gt 0 ]]; then
  report_warn "Orphan check - ${#ORPHANS[@]} orphaned file(s)"
  for o in "${ORPHANS[@]}"; do
    echo "  src/$o"
  done
else
  report_pass "Orphan check - no orphaned files"
fi

# -------------------------------------------------------
# 5. Page metadata check
# -------------------------------------------------------
MISSING_META=()
NON_SEQUENTIAL=()

while IFS= read -r md_file; do
  [[ -z "$md_file" ]] && continue
  REL_PATH="${md_file#"$SRC_DIR/"}"

  PAGES=()
  while IFS= read -r page_num; do
    [[ -n "$page_num" ]] && PAGES+=("$page_num")
  done < <(grep -oE '<!-- pdf-page: ([0-9]+) -->' "$md_file" | grep -oE '[0-9]+' || true)

  if [[ ${#PAGES[@]} -eq 0 ]]; then
    MISSING_META+=("$REL_PATH")
    continue
  fi

  # Check sequential within file
  for ((i = 1; i < ${#PAGES[@]}; i++)); do
    PREV=${PAGES[$((i - 1))]}
    CURR=${PAGES[$i]}
    if [[ $((CURR)) -ne $((PREV + 1)) ]]; then
      NON_SEQUENTIAL+=("$REL_PATH (page $PREV -> $CURR)")
      break
    fi
  done
done < <(find "$SRC_DIR" -name '*.md' -type f | sort)

HAS_META_ISSUE=false

if [[ ${#MISSING_META[@]} -gt 0 ]]; then
  HAS_META_ISSUE=true
  report_warn "Page metadata - ${#MISSING_META[@]} file(s) missing pdf-page comments"
  for m in "${MISSING_META[@]}"; do
    echo "  src/$m"
  done
fi

if [[ ${#NON_SEQUENTIAL[@]} -gt 0 ]]; then
  HAS_META_ISSUE=true
  report_warn "Page metadata - ${#NON_SEQUENTIAL[@]} file(s) with non-sequential pages"
  for ns in "${NON_SEQUENTIAL[@]}"; do
    echo "  src/$ns"
  done
fi

if [[ "$HAS_META_ISSUE" == false ]]; then
  report_pass "Page metadata - sequential across all files"
fi

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
echo ""
echo "=== Result: $FAIL FAIL, $WARN WARN, $PASS PASS ==="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi

exit 0
