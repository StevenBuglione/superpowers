#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# setup-tools.sh — Install and verify tools for PDF-to-mdBook conversion
#
# Required tools:
#   mdbook            – Builds mdBook projects from Markdown sources
#   markdownlint-cli2 – Lints Markdown files for style/syntax issues
#   poppler-utils     – Provides pdftoppm, pdfinfo, pdftotext for PDF handling
#
# Usage:
#   ./setup-tools.sh          # Install missing tools then verify all
#   ./setup-tools.sh --check  # Verify only, do not install anything
#
# Exit codes:
#   0  All tools available and working
#   1  One or more tools missing or broken
# =============================================================================

CHECK_ONLY=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

# ---- Colour helpers (disabled when stdout is not a terminal) ----------------
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' BOLD='' RESET=''
fi

ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
fail() { printf "${RED}✗${RESET} %s\n" "$*"; }
info() { printf "${YELLOW}→${RESET} %s\n" "$*"; }

# ---- OS / package-manager detection ----------------------------------------
detect_pkg_manager() {
  if command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v brew &>/dev/null; then
    echo "brew"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v yum &>/dev/null; then
    echo "yum"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "unknown"
  fi
}

PKG_MANAGER="$(detect_pkg_manager)"

# ---- Install helpers --------------------------------------------------------

install_poppler() {
  info "Installing poppler-utils (provides pdftoppm, pdfinfo, pdftotext)…"
  case "$PKG_MANAGER" in
    apt)
      sudo apt-get update -qq && sudo apt-get install -y -qq poppler-utils
      ;;
    brew)
      brew install poppler
      ;;
    dnf)
      sudo dnf install -y poppler-utils
      ;;
    yum)
      sudo yum install -y poppler-utils
      ;;
    pacman)
      sudo pacman -S --noconfirm poppler
      ;;
    *)
      fail "Unknown package manager — please install poppler-utils manually."
      return 1
      ;;
  esac
}

install_mdbook() {
  if command -v cargo &>/dev/null; then
    info "Installing mdbook via cargo…"
    cargo install mdbook
  else
    fail "cargo not found. Install Rust (https://rustup.rs) then re-run this script."
    return 1
  fi
}

install_markdownlint() {
  if command -v npm &>/dev/null; then
    info "Installing markdownlint-cli2 via npm…"
    npm install -g markdownlint-cli2
  else
    fail "npm not found. Install Node.js (https://nodejs.org) then re-run this script."
    return 1
  fi
}

# ---- Version-detection helpers ----------------------------------------------

get_version() {
  local tool="$1"
  case "$tool" in
    mdbook)
      mdbook --version 2>/dev/null | head -1 || echo ""
      ;;
    markdownlint-cli2)
      markdownlint-cli2 --help 2>&1 | grep -oP 'v[\d.]+' | head -1 || echo ""
      ;;
    pdftoppm|pdfinfo|pdftotext)
      "$tool" -v 2>&1 | head -1 || echo ""
      ;;
  esac
}

# ---- Main logic: check → install → verify ----------------------------------

# Track overall status: array of "tool|version|status"
declare -a RESULTS=()
ALL_OK=true

check_and_install() {
  local tool="$1"
  local install_fn="$2"

  if command -v "$tool" &>/dev/null; then
    local ver
    ver="$(get_version "$tool")"
    RESULTS+=("${tool}|${ver:-unknown}|ok")
  else
    if $CHECK_ONLY; then
      RESULTS+=("${tool}|—|missing")
      ALL_OK=false
    else
      # Attempt installation
      if $install_fn; then
        # Re-check after install
        if command -v "$tool" &>/dev/null; then
          local ver
          ver="$(get_version "$tool")"
          RESULTS+=("${tool}|${ver:-unknown}|ok")
        else
          RESULTS+=("${tool}|—|missing")
          ALL_OK=false
        fi
      else
        RESULTS+=("${tool}|—|install failed")
        ALL_OK=false
      fi
    fi
  fi
}

echo ""
printf "${BOLD}PDF-to-mdBook · Tool Setup${RESET}\n"
echo "════════════════════════════════════════"
echo ""

# -- mdbook -------------------------------------------------------------------
check_and_install "mdbook" install_mdbook

# -- markdownlint-cli2 --------------------------------------------------------
check_and_install "markdownlint-cli2" install_markdownlint

# -- poppler-utils (check each binary individually) ---------------------------
for poppler_tool in pdftoppm pdfinfo pdftotext; do
  check_and_install "$poppler_tool" install_poppler
done

# ---- Summary table ----------------------------------------------------------
echo ""
printf "${BOLD}%-22s %-28s %s${RESET}\n" "Tool" "Version" "Status"
echo "────────────────────── ──────────────────────────── ──────"

for entry in "${RESULTS[@]}"; do
  IFS='|' read -r tool ver status <<< "$entry"
  if [[ "$status" == "ok" ]]; then
    status_icon="${GREEN}✓${RESET}"
  else
    status_icon="${RED}✗ ${status}${RESET}"
  fi
  printf "%-22s %-28s %b\n" "$tool" "$ver" "$status_icon"
done

echo ""

# ---- Final verdict ----------------------------------------------------------
if $ALL_OK; then
  ok "All tools are installed and working. Ready to convert PDFs!"
  exit 0
else
  fail "Some tools are missing or failed to install."
  if $CHECK_ONLY; then
    info "Run without --check to attempt automatic installation."
  else
    info "Check the errors above and install missing dependencies manually."
  fi
  exit 1
fi
