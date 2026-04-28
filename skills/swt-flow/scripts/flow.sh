#!/bin/bash
# swt:flow — Active workflow engine
# Manages task context (task.ctx) and session restoration

set -e

CMD=${1:-""}

function show_help {
    echo "Usage:"
    echo "  flow.sh open              - Read task.ctx and load active task context"
    echo "  flow.sh check             - Validate active task context (non-zero exit if invalid)"
    echo "  flow.sh status            - Show current flow status (ctx + phase)"
}

if [ -z "$CMD" ]; then
    show_help
    exit 1
fi

# Determine workspace root (look for AGENTS.md or .git)
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

if [ "$CMD" == "open" ]; then
    if [ ! -f "$ROOT_DIR/task.ctx" ]; then
        echo "No active task context (task.ctx not found)."
        echo "Use 'swt.sh ctx set <task_file>' to set an active task."
        exit 0
    fi

    TASK_FILE=$(cat "$ROOT_DIR/task.ctx")

    if [ ! -f "$ROOT_DIR/$TASK_FILE" ]; then
        echo "Stale task.ctx: $TASK_FILE not found."
        echo "Clearing stale context..."
        rm -f "$ROOT_DIR/task.ctx"
        exit 1
    fi

    echo "--- Active Task Context ---"
    echo "Task: $TASK_FILE"
    echo ""

    # Extract and display key metadata
    STATUS=$(grep -oP '\*\*Status\*\*:\s*\K\S+' "$ROOT_DIR/$TASK_FILE" | head -n 1)
    PHASE=$(grep -oP '\*\*Phase\*\*:\s*\K\S+' "$ROOT_DIR/$TASK_FILE" | head -n 1)
    TYPE=$(grep -oP '\*\*Type\*\*:\s*\K\S+' "$ROOT_DIR/$TASK_FILE" | head -n 1)
    PRIORITY=$(grep -oP '\*\*Priority\*\*:\s*\K\S+' "$ROOT_DIR/$TASK_FILE" | head -n 1)

    echo "Status: $STATUS | Phase: $PHASE | Type: $TYPE | Priority: $PRIORITY"
    echo ""

    # Show Objective or Core Concept
    OBJECTIVE=$(grep -A 2 "## Objective" "$ROOT_DIR/$TASK_FILE" | grep -v "## Objective" | sed '/^$/d' | head -n 1)
    if [ -z "$OBJECTIVE" ]; then
        OBJECTIVE=$(grep -A 2 "## Core Concept" "$ROOT_DIR/$TASK_FILE" | grep -v "## Core Concept" | sed '/^$/d' | head -n 1)
    fi
    if [ -n "$OBJECTIVE" ]; then
        echo "Summary: $OBJECTIVE"
        echo ""
    fi

    # Show next unchecked item from checklist
    NEXT=$(grep -m 1 "\[ \]" "$ROOT_DIR/$TASK_FILE" | sed 's/.*\[ \] //' || true)
    if [ -n "$NEXT" ]; then
        echo "Next Step: $NEXT"
    fi

    exit 0
fi

if [ "$CMD" == "check" ]; then
    if [ ! -f "$ROOT_DIR/task.ctx" ]; then
        echo "No active task context."
        exit 1
    fi

    TASK_FILE=$(cat "$ROOT_DIR/task.ctx")

    if [ ! -f "$ROOT_DIR/$TASK_FILE" ]; then
        echo "Invalid task context: $TASK_FILE not found."
        exit 1
    fi

    echo "Active context: $TASK_FILE"
    exit 0
fi

if [ "$CMD" == "status" ]; then
    echo "--- Flow Status ---"

    if [ ! -f "$ROOT_DIR/task.ctx" ]; then
        echo "Active Task: none"
    else
        TASK_FILE=$(cat "$ROOT_DIR/task.ctx")
        if [ ! -f "$ROOT_DIR/$TASK_FILE" ]; then
            echo "Active Task: STALE ($TASK_FILE not found)"
        else
            PHASE=$(grep -oP '\*\*Phase\*\*:\s*\K\S+' "$ROOT_DIR/$TASK_FILE" | head -n 1)
            STATUS=$(grep -oP '\*\*Status\*\*:\s*\K\S+' "$ROOT_DIR/$TASK_FILE" | head -n 1)
            echo "Active Task: $TASK_FILE"
            echo "Status: $STATUS | Phase: $PHASE"
        fi
    fi
    exit 0
fi

echo "Unknown command: $CMD"
show_help
exit 1
