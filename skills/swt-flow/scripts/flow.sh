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

    TASK_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')

    # Resolve task file: try as-is, then .tasks/<name>.md, .tasks/<name>, .tasks/archive/<name>.md, .tasks/archive/<name>
    if [ -f "$ROOT_DIR/$TASK_FILE" ]; then
        RESOLVED="$ROOT_DIR/$TASK_FILE"
    elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}.md" ]; then
        RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}" ]; then
        RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}"
    elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}.md" ]; then
        RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}" ]; then
        RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}"
    else
        echo "Stale task.ctx: $TASK_FILE not found."
        echo "Clearing stale context..."
        rm -f "$ROOT_DIR/task.ctx"
        exit 1
    fi

    echo "--- Active Task Context ---"
    echo "Task: $(basename "$RESOLVED")"
    echo ""

    # Extract and display key metadata
    STATUS=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$RESOLVED" | head -n 1)
    PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$RESOLVED" | head -n 1)
    TYPE=$(grep -oP '^\*\*?Type\*\*?:\s*\K\S+' "$RESOLVED" | head -n 1)
    PRIORITY=$(grep -oP '^\*\*?Priority\*\*?:\s*\K\S+' "$RESOLVED" | head -n 1)

    echo "Status: $STATUS | Phase: $PHASE | Type: $TYPE | Priority: $PRIORITY"
    
    # Allowed Next Phases based on State Machine
    case $PHASE in
        0) NEXT_PHASES="Phase 1 (via graduate)" ;;
        1) NEXT_PHASES="Phase 2 (Analyze)" ;;
        2) NEXT_PHASES="Phase 3 (Risk)" ;;
        3) NEXT_PHASES="Gate 2 (Architecture Loop / Phase 4)" ;;
        4) NEXT_PHASES="Phase 5 (Implement)" ;;
        5) NEXT_PHASES="Phase 6 (Document)" ;;
        6) NEXT_PHASES="Phase 7 (Test)" ;;
        7) NEXT_PHASES="Phase 8 (Review & Refine)" ;;
        8) NEXT_PHASES="Gate 5 (Commit) OR Phase 1 (Light Bulb Moment)" ;;
        *) NEXT_PHASES="Unknown" ;;
    esac
    echo "Next Allowed: $NEXT_PHASES"
    echo ""

    # Show Objective or Core Concept
    OBJECTIVE=$(grep -A 2 "## Objective" "$RESOLVED" | grep -v "## Objective" | sed '/^$/d' | head -n 1)
    if [ -z "$OBJECTIVE" ]; then
        OBJECTIVE=$(grep -A 2 "## Core Concept" "$RESOLVED" | grep -v "## Core Concept" | sed '/^$/d' | head -n 1)
    fi
    if [ -n "$OBJECTIVE" ]; then
        echo "Summary: $OBJECTIVE"
        echo ""
    fi

    # Show next unchecked item from checklist
    NEXT=$(grep -m 1 "\[ \]" "$RESOLVED" | sed 's/.*\[ \] //' || true)
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

    TASK_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')

    # Resolve task file
    if [ -f "$ROOT_DIR/$TASK_FILE" ]; then
        RESOLVED="$ROOT_DIR/$TASK_FILE"
    elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}.md" ]; then
        RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}" ]; then
        RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}"
    elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}.md" ]; then
        RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}" ]; then
        RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}"
    else
        echo "Invalid task context: $TASK_FILE not found."
        exit 1
    fi

    echo "Active context: $(basename "$RESOLVED")"
    exit 0
fi

if [ "$CMD" == "status" ]; then
    echo "--- Flow Status ---"

    if [ ! -f "$ROOT_DIR/task.ctx" ]; then
        echo "Active Task: none"
    else
        TASK_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
        if [ -f "$ROOT_DIR/$TASK_FILE" ]; then
            RESOLVED="$ROOT_DIR/$TASK_FILE"
        elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}.md" ]; then
            RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}.md"
        elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}" ]; then
            RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}"
        elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}.md" ]; then
            RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}.md"
        elif [ -f "$ROOT_DIR/.tasks/archive/${TASK_FILE}" ]; then
            RESOLVED="$ROOT_DIR/.tasks/archive/${TASK_FILE}"
        else
            echo "Active Task: STALE ($TASK_FILE not found)"
            exit 0
        fi
        PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$RESOLVED" | head -n 1)
        STATUS=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$RESOLVED" | head -n 1)
        
        # Allowed Next Phases based on State Machine
        case $PHASE in
            0) NEXT_PHASES="Phase 1 (via graduate)" ;;
            1) NEXT_PHASES="Phase 2 (Analyze)" ;;
            2) NEXT_PHASES="Phase 3 (Risk)" ;;
            3) NEXT_PHASES="Gate 2 (Architecture Loop / Phase 4)" ;;
            4) NEXT_PHASES="Phase 5 (Implement)" ;;
            5) NEXT_PHASES="Phase 6 (Document)" ;;
            6) NEXT_PHASES="Phase 7 (Test)" ;;
            7) NEXT_PHASES="Phase 8 (Review & Refine)" ;;
            8) NEXT_PHASES="Gate 5 (Commit) OR Phase 1 (Light Bulb Moment)" ;;
            *) NEXT_PHASES="Unknown" ;;
        esac

        echo "Active Task: $(basename "$RESOLVED")"
        echo "Status: $STATUS | Phase: $PHASE"
        echo "Next Allowed: $NEXT_PHASES"
    fi
    exit 0
fi

echo "Unknown command: $CMD"
show_help
exit 1
