#!/bin/bash
# skills/swt-link/scripts/install.sh — Universal Skill Installer for SWT
# Automates copying skills into multiple agent discovery paths (Physical Mode).

set -e

# Detect physical script location (handles symlinks)
REAL_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT_PATH")" && pwd)"
SWT_HOME="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS_DIR="$SWT_HOME/skills"

# Defaults
SCOPE="local"
CLEAR=false
DRY_RUN=false
TARGET_DIR_ARG=""

# Help
usage() {
    echo "Usage: $0 [options] [target_path]"
    echo "Options:"
    echo "  --global    Install into home directory (~/.agents, etc.)"
    echo "  --clear     Remove existing SWT skills/links before installing"
    echo "  --dry-run   Show what would be done without making changes"
    echo "  --help      Show this help message"
    echo ""
    echo "If target_path is provided, it will be used as the base for agent folders."
    exit 0
}

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --global) SCOPE="global" ;;
        --clear) CLEAR=true ;;
        --dry-run) DRY_RUN=true ;;
        --help) usage ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) TARGET_DIR_ARG="$1" ;;
    esac
    shift
done

# Define discovery paths
if [[ "$SCOPE" == "global" ]]; then
    BASE_DIR="$HOME"
elif [[ -n "$TARGET_DIR_ARG" ]]; then
    BASE_DIR="$(realpath "$TARGET_DIR_ARG")"
else
    BASE_DIR="$(pwd)"
fi

TARGET_PATHS=(
    "$BASE_DIR/.agents/skills"
    "$BASE_DIR/.claude/skills"
)

echo "--- SWT Universal Skill Installer ---"
echo "Source: $SKILLS_DIR"
echo "Target Base: $BASE_DIR"
echo "Scope: $SCOPE"
[[ "$CLEAR" == "true" ]] && echo "Clear: enabled"
[[ "$DRY_RUN" == "true" ]] && echo "DRY RUN MODE"

# 1. Clear existing SWT installations if requested
if [[ "$CLEAR" == "true" ]]; then
    echo "Clearing existing SWT skills/symlinks..."
    for target_dir in "${TARGET_PATHS[@]}"; do
        if [[ -d "$target_dir" ]]; then
            find "$target_dir" -maxdepth 1 | while read -r item; do
                [[ "$item" == "$target_dir" ]] && continue
                
                # Identify if it's an SWT skill (either a symlink to SWT or a directory matching a skill name)
                SKILL_NAME=$(basename "$item")
                if [[ -d "$SKILLS_DIR/$SKILL_NAME" ]]; then
                    echo "Removing: $item"
                    if [[ "$DRY_RUN" == "false" ]]; then
                        rm -rf "$item"
                    fi
                fi
            done
        fi
    done
fi

# 2. Copy skills (Physical Mode)
echo "Installing skills (Copying)..."
for skill_path in "$SKILLS_DIR"/*; do
    if [[ -d "$skill_path" ]]; then
        SKILL_NAME="$(basename "$skill_path")"
        
        # Skip hidden directories
        [[ "$SKILL_NAME" == .* ]] && continue
        
        for target_dir in "${TARGET_PATHS[@]}"; do
            # Ensure target directory exists
            if [[ "$DRY_RUN" == "false" ]]; then
                mkdir -p "$target_dir"
            fi
            
            DEST_PATH="$target_dir/$SKILL_NAME"
            
            # Always remove existing target to ensure a clean copy (no stale files)
            if [[ -e "$DEST_PATH" ]]; then
                echo "Removing existing installation: $DEST_PATH"
                if [[ "$DRY_RUN" == "false" ]]; then
                    rm -rf "$DEST_PATH"
                fi
            fi
            
            echo "Installing: $DEST_PATH"
            if [[ "$DRY_RUN" == "false" ]]; then
                cp -rf "$skill_path" "$DEST_PATH"
            fi
        done
    fi
done

echo "Done."
