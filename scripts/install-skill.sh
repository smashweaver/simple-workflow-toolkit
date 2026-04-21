#!/bin/bash
# install-skill.sh — Install the workflow skill suite into a project's .claude/skills/ directory
#
# Usage:
#   ./scripts/install-skill.sh                  # installs into the current directory (copy)
#   ./scripts/install-skill.sh --link           # installs into current directory (symlink)
#   ./scripts/install-skill.sh /path/to/project # installs into specified project (copy)

set -euo pipefail

MODE="copy"
DEST=""

# Simple argument parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--link)
      MODE="link"
      shift
      ;;
    *)
      if [ -z "$DEST" ]; then
        DEST="$1"
      else
        echo "Error: Unexpected argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

DEST="${DEST:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 1. Resolve Skills Source
if [ -n "${SWT_HOME:-}" ]; then
  SKILLS_SOURCE="$SWT_HOME/skills"
  echo "Using SWT_HOME: $SWT_HOME"
else
  SKILLS_SOURCE="$REPO_ROOT/skills"
  if [ "$MODE" == "link" ]; then
    echo "Tip: Set SWT_HOME in your .bashrc to make symlinks portable if you move this repo."
  fi
fi

SKILLS_DEST="$DEST/.claude/skills"

# 2. Validate Source
if [ ! -d "$SKILLS_SOURCE" ]; then
  echo "Error: Skills source directory not found at $SKILLS_SOURCE"
  exit 1
fi

# 3. Risk Detection
if [[ "$SKILLS_SOURCE" == *"/Desktop"* ]] || [[ "$SKILLS_SOURCE" == "/tmp"* ]]; then
  echo "⚠️  Warning: SWT repository is in a temporary or non-permanent location: $SKILLS_SOURCE"
  echo "   If you move this repository, any symlinks created will break."
  echo ""
fi

# 4. Create destination directory
mkdir -p "$SKILLS_DEST"

# 5. Install Skills
if [ "$MODE" == "link" ]; then
  echo "Installing SWT skills via symlink to $SKILLS_DEST..."
  for skill in "$SKILLS_SOURCE"/*; do
    [ -d "$skill" ] || continue
    skill_name=$(basename "$skill")
    target="$SKILLS_DEST/$skill_name"
    
    # Defensive handling
    if [ -L "$target" ]; then
      # Already a link, overwrite silently
      rm "$target"
    elif [ -e "$target" ]; then
      echo "⚠️  Warning: $target already exists as a regular file/directory. Skipping."
      continue
    fi
    
    ln -s "$skill" "$target"
    echo "  linked: $skill_name"
  done
else
  echo "Installing SWT skills via copy to $SKILLS_DEST..."
  cp -r "$SKILLS_SOURCE/"* "$SKILLS_DEST/"
fi

echo ""
echo "Simple Workflow Toolkit (SWT) installed successfully."
echo "To use: Start a Claude Code session in $DEST."
