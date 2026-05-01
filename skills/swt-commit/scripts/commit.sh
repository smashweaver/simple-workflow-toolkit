#!/bin/bash
# swt:commit — Commit Workflow Orchestrator

set -e

# Identify Workspace Root
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

if [ ! -f "$ROOT_DIR/task.ctx" ]; then
    echo "❌ Error: No active task context. You must be working on a task to commit."
    exit 1
fi

TASK_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
# Resolve task file
if [ -f "$ROOT_DIR/$TASK_FILE" ]; then RESOLVED="$ROOT_DIR/$TASK_FILE"
elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}.md" ]; then RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}.md"
elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}" ]; then RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}"
elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}.md" ]; then RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}.md"
elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}" ]; then RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}"
else RESOLVED=""; fi

if [ -n "$RESOLVED" ] && [ -f "$RESOLVED" ]; then
    PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$RESOLVED" | head -n 1)
    if [ "$PHASE" -lt 8 ]; then
        echo "⚠️  Phase Warning: You are in Phase $PHASE. Commits are reserved for Phase 8 (Review & Refine)."
        echo "   Proceeding anyway as requested, but ensure verification is complete."
    fi
fi

echo "🚀 Loading swt:commit ritual..."
echo "--- Step 1: Stage Changes ---"
echo "Command: git add ."
echo ""
echo "--- Step 2: Export Diff ---"
echo "Command: git diff --cached > commit.diff"
echo ""
echo "--- Step 3: Draft Message ---"
echo "Command: Use 'generate_commit_message' tool or draft manually to commit.draft"
echo ""
echo "--- Step 4: Approval ---"
echo "Ask the user for approval of commit.draft."
echo ""
echo "--- Step 5: Apply & Close ---"
echo "Command: git commit -F commit.draft"
echo "Command: bash skills/swt-task/scripts/task.sh close $(basename "$RESOLVED") <hash>"
