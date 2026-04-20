#!/bin/bash
# install-skill.sh — Install the workflow skill suite into a project's .claude/skills/ directory
#
# Usage:
#   ./scripts/install-skill.sh                  # installs into the current directory
#   ./scripts/install-skill.sh /path/to/project # installs into the specified project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="${1:-$(pwd)}"
SKILLS_SOURCE="$PROJECT_ROOT/skills"
SKILLS_DEST="$DEST/.claude/skills"

# Validate source directory exists
if [ ! -d "$SKILLS_SOURCE" ]; then
  echo "Error: Skills source directory not found at $SKILLS_SOURCE"
  exit 1
fi

# Create destination directory
mkdir -p "$SKILLS_DEST"

# Copy all skills
cp -r "$SKILLS_SOURCE/"* "$SKILLS_DEST/"

echo "Simple Workflow Toolkit (SWT) installed to $SKILLS_DEST"
echo "Skills now available: swt:flow, swt:code, swt:commit, swt:mermaid, swt:task, swt:init, swt:spec"
echo ""
echo "To use: Start a Claude Code session in the target project."
echo "Skills will auto-trigger based on context or can be invoked via /commands (if applicable)."
