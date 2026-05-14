#!/bin/bash

# swt:status — Metadata Aggregator
# Aggregates project state from .digests, .tasks, and .specs

set -e

# --- Argument Parsing ---
SHOW_GIT=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --git) SHOW_GIT=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# 1. Identify Workspace Root (look for parent AGENTS.md or .git)
# This allows the script to be run from sub-directories
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

echo "--- Workspace ---"
if [ -f "$ROOT_DIR/AGENTS.md" ]; then
    PROJECT_NAME=$(grep -m 1 "^# " "$ROOT_DIR/AGENTS.md" | sed 's/# //')
    echo "Project: $PROJECT_NAME"
else
    echo "Project: Unknown (No AGENTS.md found)"
fi
echo "Root: $ROOT_DIR"
echo ""

# 1.25 Active Task Context
if [ -f "$ROOT_DIR/skills/swt-flow/scripts/state.py" ]; then
    # Use state.py to show active context (Sensor 1 report)
    uv run python3 "$ROOT_DIR/skills/swt-flow/scripts/state.py" | sed -n '/SWT State Report/,/===/p' | grep -v '==='
else
    echo "--- Active Task Context ---"
    echo "Engine (state.py) not found."
    echo ""
fi

# 1.3 Tactical Roadmap
if [ -f "$ROOT_DIR/protocol.md" ]; then
    echo "--- Tactical Roadmap ---"
    # Extract the Execution Loop section and filter for checklist items
    sed -n '/## 2. Gate 3: Execution Loop/,/##/p' "$ROOT_DIR/protocol.md" | grep -E '^\s*-\s*\[[ xX]\]' || true
    echo ""
fi

# 1.5 Graphify Status
if [ -f "$ROOT_DIR/skills/swt-graphify/scripts/graphify.sh" ]; then
    bash "$ROOT_DIR/skills/swt-graphify/scripts/graphify.sh" status
    echo ""
fi

# 2. Latest Digest
echo "--- Latest Digest ---"
LATEST_DIGEST=$(ls -t "$ROOT_DIR/.digests/"*.md 2>/dev/null | head -n 1)
if [ -z "$LATEST_DIGEST" ]; then
    LATEST_DIGEST=$(ls -t "$ROOT_DIR/.digests/archive/"*.md 2>/dev/null | head -n 1)
fi

if [ -n "$LATEST_DIGEST" ]; then
    echo "File: $(basename "$LATEST_DIGEST")"
    # Extract the summary or key outcomes (usually under ## Key Outcomes)
    grep -A 5 "## Key Outcomes" "$LATEST_DIGEST" | grep -v "## Key Outcomes" | sed '/^$/d' | head -n 5
else
    echo "No digests found."
fi
echo ""

# 3. Active Tasks
echo "--- Active Tasks ---"
if [ -f "$ROOT_DIR/skills/swt-flow/scripts/state.py" ]; then
    uv run python3 "$ROOT_DIR/skills/swt-flow/scripts/state.py" --backlog --classify
else
    echo "Engine (state.py) not found."
fi
echo ""

# 4. Recent Specs
echo "--- Recent Specs ---"
if [ -d "$ROOT_DIR/.specs" ]; then
    ACTIVE_TASKS=$(ls -1 .tasks/*.md 2>/dev/null | xargs grep -l -E '^\*\*?Status\*\*?:\s*(pending|ideating|in-progress)' 2>/dev/null || true)
    ls -t "$ROOT_DIR/.specs/"*.md 2>/dev/null | head -n 3 | xargs -n 1 basename
else
    echo "No .specs/ directory found."
fi
echo ""

# 5. Git Logs (Optional)
if [ "$SHOW_GIT" = true ]; then
    echo "--- Recent Commits ---"
    if [ -d "$ROOT_DIR/.git" ]; then
        git -C "$ROOT_DIR" log -n 5 --oneline
    else
        echo "Warning: Not a git repository."
    fi
    echo ""
fi
