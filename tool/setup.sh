#!/usr/bin/env bash
# =============================================================================
# Dragonfly development environment setup
#
# Usage:  bash tool/setup.sh
#
# Installs:
#   1. Git hooks via lefthook (or fallback script)
#   2. Verifies required tooling
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "  Dragonfly — development setup"
echo "  =============================="
echo ""

# ── Check required tools ────────────────────────────────────────────────────

check_tool() {
  if command -v "$1" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $1 found"
    return 0
  else
    echo -e "  ${RED}✗${NC} $1 not found"
    return 1
  fi
}

MISSING=0

check_tool dart   || ((MISSING++))
check_tool flutter || ((MISSING++))

if [ "$MISSING" -gt 0 ]; then
  echo ""
  echo -e "  ${RED}Missing required tools. Install them and re-run.${NC}"
  exit 1
fi

# ── Install git hooks ────────────────────────────────────────────────────────

echo ""
echo "  Installing git hooks..."

HOOKS_DIR="$REPO_ROOT/.git/hooks"
GIT_HOOKS_DIR="$REPO_ROOT/.githooks"

if [ ! -d "$HOOKS_DIR" ]; then
  echo -e "  ${RED}✗${NC} .git/hooks/ not found — is this a git repository?"
  exit 1
fi

install_hook() {
  local hook="$1"
  local source="$GIT_HOOKS_DIR/$hook"
  local target="$HOOKS_DIR/$hook"

  if [ -f "$source" ]; then
    cp "$source" "$target"
    chmod +x "$target"
    echo -e "  ${GREEN}✓${NC} $hook"
  fi
}

install_hook commit-msg

# ── Install lefthook for pre-commit / pre-push ──────────────────────────────

if command -v lefthook &>/dev/null; then
  cd "$REPO_ROOT"
  lefthook install --force
  echo -e "  ${GREEN}✓${NC} lefthook hooks installed"
elif [ -f "$REPO_ROOT/lefthook.yml" ]; then
  echo ""
  echo -e "  ${YELLOW}⚠${NC}  lefthook not installed — pre-commit and pre-push checks won't run."
  echo ""
  echo "  Install lefthook:"
  echo "    macOS:  brew install lefthook"
  echo "    Linux:  go install github.com/evilmartians/lefthook@latest"
  echo "    Manual: https://github.com/evilmartians/lefthook#install"
  echo ""
  echo "  Then re-run: bash tool/setup.sh"
fi

# ── Install pub dependencies ─────────────────────────────────────────────────

echo ""
echo "  Installing package dependencies..."

cd "$REPO_ROOT/dragonfly_annotations"
dart pub get --no-example 2>/dev/null
echo -e "  ${GREEN}✓${NC} dragonfly_annotations"

cd "$REPO_ROOT/dragonfly_builder"
dart pub get --no-example 2>/dev/null
echo -e "  ${GREEN}✓${NC} dragonfly_builder"

cd "$REPO_ROOT/dragonfly"
flutter pub get --no-example 2>/dev/null
echo -e "  ${GREEN}✓${NC} dragonfly"

cd "$REPO_ROOT/example"
flutter pub get 2>/dev/null
echo -e "  ${GREEN}✓${NC} example"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "  ${GREEN}Setup complete.${NC}"
echo ""
echo "  Next steps:"
echo "    Build:    cd example && dart run build_runner build --delete-conflicting-outputs"
echo "    Analyze:  cd example && flutter analyze"
echo "    Test:     cd example && flutter test"
echo ""
