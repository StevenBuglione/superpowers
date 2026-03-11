#!/usr/bin/env bash
set -euo pipefail

# render-pages.sh — Convert PDF pages to PNG images using pdftoppm.
#
# Usage:
#   ./render-pages.sh <pdf-file> <output-dir> [--dpi 300] [--first-page N] [--last-page N]

###############################################################################
# Defaults
###############################################################################
DPI=300
FIRST_PAGE=""
LAST_PAGE=""

###############################################################################
# Helpers
###############################################################################
die() { echo "error: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <pdf-file> <output-dir> [OPTIONS]

Convert PDF pages to PNG images using pdftoppm.

Options:
  --dpi N          Resolution in dots-per-inch (default: 300)
  --first-page N   First page to render (1-based)
  --last-page N    Last page to render (1-based)
  -h, --help       Show this help message

Output files are named page-001.png, page-002.png, etc.
EOF
  exit 0
}

###############################################################################
# Parse arguments
###############################################################################
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)      usage ;;
    --dpi)          DPI="${2:?--dpi requires a value}"; shift 2 ;;
    --first-page)   FIRST_PAGE="${2:?--first-page requires a value}"; shift 2 ;;
    --last-page)    LAST_PAGE="${2:?--last-page requires a value}"; shift 2 ;;
    -*)             die "unknown option: $1" ;;
    *)              POSITIONAL+=("$1"); shift ;;
  esac
done

[[ ${#POSITIONAL[@]} -ge 2 ]] || die "missing required arguments. See --help."
PDF_FILE="${POSITIONAL[0]}"
OUTPUT_DIR="${POSITIONAL[1]}"

###############################################################################
# Preflight checks
###############################################################################
command -v pdftoppm >/dev/null 2>&1 || die "pdftoppm not found. Install poppler-utils."
command -v pdfinfo  >/dev/null 2>&1 || die "pdfinfo not found. Install poppler-utils."

[[ -f "$PDF_FILE" ]] || die "PDF file not found: $PDF_FILE"

TOTAL_PAGES=$(pdfinfo "$PDF_FILE" 2>/dev/null | awk '/^Pages:/{print $2}')
[[ -n "$TOTAL_PAGES" ]] || die "could not determine page count for: $PDF_FILE"

# Resolve effective page range
EFF_FIRST=${FIRST_PAGE:-1}
EFF_LAST=${LAST_PAGE:-$TOTAL_PAGES}

(( EFF_FIRST >= 1 && EFF_FIRST <= TOTAL_PAGES )) \
  || die "--first-page $EFF_FIRST is out of range (1–$TOTAL_PAGES)"
(( EFF_LAST >= EFF_FIRST && EFF_LAST <= TOTAL_PAGES )) \
  || die "--last-page $EFF_LAST is out of range ($EFF_FIRST–$TOTAL_PAGES)"

EXPECTED_COUNT=$(( EFF_LAST - EFF_FIRST + 1 ))

# Create output directory (check writability)
mkdir -p "$OUTPUT_DIR" || die "cannot create output directory: $OUTPUT_DIR"
[[ -w "$OUTPUT_DIR" ]] || die "output directory is not writable: $OUTPUT_DIR"

###############################################################################
# Render
###############################################################################
echo "Rendering $EXPECTED_COUNT page(s) from $(basename "$PDF_FILE") at ${DPI} DPI …"
echo "  pages : ${EFF_FIRST}–${EFF_LAST} of ${TOTAL_PAGES}"
echo "  output: ${OUTPUT_DIR}/"
echo ""

# pdftoppm names files as <prefix>-<N>.png where <N> is zero-padded.
# We use a temp prefix inside the output dir, then rename for consistency.
TMP_PREFIX="${OUTPUT_DIR}/.tmp-render"

PDFTOPPM_ARGS=(-png -r "$DPI")
[[ -n "$FIRST_PAGE" ]] && PDFTOPPM_ARGS+=(-f "$FIRST_PAGE")
[[ -n "$LAST_PAGE" ]]  && PDFTOPPM_ARGS+=(-l "$LAST_PAGE")

# Progress: render one page at a time so we can report progress for large PDFs.
RENDERED=0
for (( PAGE=EFF_FIRST; PAGE<=EFF_LAST; PAGE++ )); do
  SEQ=$(printf "%03d" "$PAGE")
  OUT_FILE="${OUTPUT_DIR}/page-${SEQ}.png"

  pdftoppm -png -r "$DPI" -f "$PAGE" -l "$PAGE" "$PDF_FILE" "$TMP_PREFIX"

  # pdftoppm appends its own numbering; find the generated file and rename.
  GENERATED=$(ls "${TMP_PREFIX}"*.png 2>/dev/null | head -n1)
  [[ -n "$GENERATED" ]] || die "pdftoppm produced no output for page $PAGE"
  mv "$GENERATED" "$OUT_FILE"

  RENDERED=$((RENDERED + 1))

  # Show progress every 10 pages, or on the last page.
  if (( RENDERED % 10 == 0 || PAGE == EFF_LAST )); then
    printf "  [%d/%d] pages rendered\r" "$RENDERED" "$EXPECTED_COUNT"
  fi
done
echo ""

###############################################################################
# Verify
###############################################################################
ACTUAL_COUNT=$(find "$OUTPUT_DIR" -maxdepth 1 -name 'page-*.png' | wc -l)
if (( ACTUAL_COUNT != EXPECTED_COUNT )); then
  die "verification failed: expected $EXPECTED_COUNT images but found $ACTUAL_COUNT"
fi

DISK_USED=$(du -sh "$OUTPUT_DIR" | cut -f1)

###############################################################################
# Summary
###############################################################################
echo "✓ Done"
echo "  pages rendered : $ACTUAL_COUNT"
echo "  output dir     : $OUTPUT_DIR/"
echo "  disk space used: $DISK_USED"
