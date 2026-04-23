#!/bin/bash
# skills/swt-link/scripts/link.sh — Universal Skill Linker for SWT
# Automates symlinking skills into multiple agent discovery paths.

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
    echo "  --global    Link into home directory (~/.agents, etc.)"
    echo "  --clear     Remove existing SWT symlinks before linking"
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
    # Default to CWD instead of SWT_HOME if we are running the skill
    # This allows /swt:link to work in whatever folder the agent is currently in
    BASE_DIR="$(pwd)"
fi

TARGET_PATHS=(
    "$BASE_DIR/.agents/skills"
    "$BASE_DIR/.claude/skills"
    "$BASE_DIR/.gemini/skills"
)

echo "--- SWT Universal Skill Linker ---"
echo "Source: $SKILLS_DIR"
echo "Target Base: $BASE_DIR"
echo "Scope: $SCOPE"
[[ "$CLEAR" == "true" ]] && echo "Clear: enabled"
[[ "$DRY_RUN" == "true" ]] && echo "DRY RUN MODE"

# 1. Clear existing SWT links if requested
if [[ "$CLEAR" == "true" ]]; then
    echo "Clearing existing SWT symlinks..."
    for target_dir in "${TARGET_PATHS[@]}"; do
        if [[ -d "$target_dir" ]]; then
            # Use find to avoid "glob expansion failed" errors if directory is empty
            find "$target_dir" -maxdepth 1 -type l | while read -r item; do
                # Check if link points to this project
                TARGET="$(readlink -f "$item")"
                if [[ "$TARGET" == "$SKILLS_DIR"* ]]; then
                    echo "Removing link: $item -> $TARGET"
                    if [[ "$DRY_RUN" == "false" ]]; then
                        rm "$item"
                    fi
                fi
            done
        fi
    done
fi

# 2. Create new symlinks
echo "Linking skills..."
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
            
            LINK_PATH="$target_dir/$SKILL_NAME"
            
            # Skip if it's a regular file (safety)
            if [[ -f "$LINK_PATH" && ! -L "$LINK_PATH" ]]; then
                echo "Warning: Skipping $LINK_PATH (regular file exists)"
                continue
            fi
            
            echo "Linking: $LINK_PATH -> $skill_path"
            if [[ "$DRY_RUN" == "false" ]]; then
                ln -sfn "$skill_path" "$LINK_PATH"
            fi
        done
    fi
done

echo "Done."
