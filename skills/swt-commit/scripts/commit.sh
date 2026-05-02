#!/bin/bash
# swt:commit — Commit Workflow Orchestrator & Hard Shell Gate
# Usage: 
#   ./commit.sh                 # Show ritual guide
#   ./commit.sh --draft "msg"    # Validate and generate commit.draft

set -e

# Identify Workspace Root
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

LINT_SCRIPT="$ROOT_DIR/skills/swt-commit/scripts/lint.sh"

function show_guide() {
    echo "🚀 Loading swt:commit ritual..."
    echo "--- Step 1: Stage Changes ---"
    echo "Command: git add ."
    echo ""
    echo "--- Step 2: Export Diff ---"
    echo "Command: git diff --cached > commit.diff"
    echo ""
    echo "--- Step 3: Draft Message ---"
    echo "Command: ./skills/swt-commit/scripts/commit.sh --draft \"type(scope): summary\n\n* bullet\" "
    echo ""
    echo "--- Step 4: Approval ---"
    echo "Ask the user for approval of commit.draft."
    echo ""
    echo "--- Step 5: Apply & Close ---"
    echo "Command: git commit -F commit.draft"
    
    if [ -f "$ROOT_DIR/task.ctx" ]; then
        TASK_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
        echo "Command: bash skills/swt-task/scripts/task.sh close $TASK_FILE <hash>"
    else
        echo "Command: bash skills/swt-task/scripts/task.sh close <task_file> <hash>"
    fi
}

if [ "$1" == "--draft" ]; then
    MESSAGE=$2
    if [ -z "$MESSAGE" ]; then
        echo "❌ Error: No message provided for --draft."
        exit 1
    fi

    TMP_FILE=".commit.tmp"
    echo -e "$MESSAGE" > "$TMP_FILE"

    echo "🔍 Validating commit message..."
    if bash "$LINT_SCRIPT" "$TMP_FILE"; then
        mv "$TMP_FILE" "$ROOT_DIR/commit.draft"
        echo "✅ Draft generated: $ROOT_DIR/commit.draft"
        echo ""
        echo "--- Verification Artifacts (COPY-PASTE INTO RESPONSE) ---"
        echo '```'
        cat "$ROOT_DIR/commit.draft"
        echo ""
        if [ -f "$ROOT_DIR/commit.task" ]; then
            cat "$ROOT_DIR/commit.task"
        fi
        echo '```'
        echo "--- End of Artifacts ---"
        exit 0
    else
        rm -f "$TMP_FILE"
        echo ""
        echo "🛑 LINT FAILED: The commit message violates swt:commit guidelines."
        echo "👉 Self-Correction Required: Read the errors above, re-read swt:commit/SKILL.md, and try again."
        echo "⚠️  Loop Limit: Do not exceed 3 attempts. If you are stuck, ask the user for help."
        exit 1
    fi
else
    show_guide
fi
