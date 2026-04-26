#!/bin/bash

# swt:status — Metadata Aggregator
# Aggregates project state from .digests, .tasks, and .specs

set -e

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
if [ -d "$ROOT_DIR/.tasks" ]; then
    # List active tasks (status not done or abandoned)
    FILES=$(ls "$ROOT_DIR/.tasks/"*.md 2>/dev/null || true)
    FOUND_ACTIVE=false
    for f in $FILES; do
        STATUS=$(grep -oP '\*\*Status\*\*:\s*\K\S+' "$f" | head -n 1)
        if [[ "$STATUS" != "done" && "$STATUS" != "abandoned" ]]; then
            PHASE=$(grep -oP '\*\*Phase\*\*:\s*\K\S+' "$f" | head -n 1)
            OBJECTIVE=$(grep -A 1 "## Objective" "$f" | grep -v "## Objective" | sed '/^$/d' | head -n 1)
            if [ -z "$OBJECTIVE" ]; then
                OBJECTIVE=$(grep -A 1 "## Core Concept" "$f" | grep -v "## Core Concept" | sed '/^$/d' | head -n 1)
            fi
            
            echo "Task: $(basename "$f")"
            echo "  Status: $STATUS | Phase: $PHASE"
            echo "  Goal: $OBJECTIVE"
            
            # Validation Check if task script exists
            if [ -f "$ROOT_DIR/skills/swt-task/scripts/task.sh" ]; then
                VAL=$(bash "$ROOT_DIR/skills/swt-task/scripts/task.sh" validate "$f" 2>&1)
                echo "  Validation: $VAL"
            fi
            
            # Get next step (first unchecked item)
            NEXT=$(grep -m 1 "\[ \]" "$f" | sed 's/.*\[ \] //')
            if [ -n "$NEXT" ]; then
                echo "  Next Step: $NEXT"
            fi
            echo ""
            FOUND_ACTIVE=true
        fi
    done
    if [ "$FOUND_ACTIVE" = false ]; then
        echo "No active tasks found."
    fi
else
    echo "No .tasks/ directory found."
fi

# 4. Recent Specs
echo "--- Recent Specs ---"
if [ -d "$ROOT_DIR/.specs" ]; then
    ls -t "$ROOT_DIR/.specs/"*.md 2>/dev/null | head -n 3 | xargs -n 1 basename
else
    echo "No .specs/ directory found."
fi
