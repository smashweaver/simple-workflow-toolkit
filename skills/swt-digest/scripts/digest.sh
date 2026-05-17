#!/bin/bash
# SWT Digest Facade Script

# Determine workspace root (look for AGENTS.md or .git)
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

# Route execution directly to the template-driven Python continuous digest engine
uv run python3 "$ROOT_DIR/skills/swt-digest/scripts/digest.py" "$@"
