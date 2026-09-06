#!/usr/bin/env bash
# skills/swt-datastar/scripts/install.sh — Install the Datastar design system into a project.
# Copies static/ (tokens.css, components.css) and templates/ into the target project.

set -euo pipefail

# Resolve physical script location (handles symlinks)
REAL_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT_PATH")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/../resources"

# Defaults
TARGET_DIR="${1:-$(pwd)}"
FORCE=false

usage() {
    echo "Usage: $0 [target_path] [--force]"
    echo "  target_path   Project directory to install into (default: current directory)"
    echo "  --force       Overwrite existing files (default: skip existing files)"
    exit 0
}

for arg in "$@"; do
    case $arg in
        --force) FORCE=true ;;
        --help) usage ;;
        -*) echo "Unknown option: $arg"; usage ;;
        *) TARGET_DIR="$arg" ;;
    esac
done

TARGET_DIR="$(realpath "$TARGET_DIR")"

echo "--- Datastar Design System Installer ---"
echo "Source: $RESOURCES_DIR"
echo "Target: $TARGET_DIR"
[[ "$FORCE" == "true" ]] && echo "Mode: force overwrite"

install_dir() {
    local src="$1"
    local dest="$TARGET_DIR/$2"
    [[ -d "$src" ]] || { echo "⚠ Skipping (missing): $src"; return; }
    mkdir -p "$dest"
    for f in "$src"/*; do
        [[ -e "$f" ]] || continue
        local name
        name="$(basename "$f")"
        if [[ -e "$dest/$name" && "$FORCE" != "true" ]]; then
            echo "  · skipped (exists): $2/$name"
            continue
        fi
        if [[ -d "$f" ]]; then
            cp -r "$f" "$dest/"
        else
            cp "$f" "$dest/"
        fi
        echo "  ✓ installed: $2/$name"
    done
}

install_dir "$RESOURCES_DIR/static" "static"
install_dir "$RESOURCES_DIR/templates" "templates"

echo ""
echo "✅ Datastar design system installed."
echo ""
echo "📋 Next steps:"
echo "   1. Link the CSS in your base layout:"
echo "      <link rel=\"stylesheet\" href=\"/static/css/tokens.css\">"
echo "      <link rel=\"stylesheet\" href=\"/static/css/components.css\">"
echo "   2. Tell your agent to read resources/AGENTS.md + resources/DATASTAR_PATTERNS.md before writing Datastar markup."
echo ""