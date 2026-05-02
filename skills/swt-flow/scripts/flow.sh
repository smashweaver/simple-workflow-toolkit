#!/bin/bash
# swt:flow — Active workflow engine
# Manages task context (task.ctx) and session restoration

set -e

CMD=${1:-""}

function show_help {
    echo "Usage:"
    echo "  flow.sh mount <file>      - Set active task context"
    echo "  flow.sh unmount           - Clear active task context"
    echo "  flow.sh status            - Show current flow status (ctx + phase)"
    echo "  flow.sh open              - Read task.ctx and load active task context"
    echo "  flow.sh view-task [file]  - Open active task (or specified file) in browser"
    echo "  flow.sh link [args]       - Delegate to swt:link"
    echo "  flow.sh graphify [args]   - Delegate to swt:graphify"
    echo "  flow.sh init              - Guidance for project initialization"
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

function resolve_task_path() {
    local task_input=$1
    if [ -z "$task_input" ]; then
        if [ -f "$ROOT_DIR/task.ctx" ]; then
            task_input=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
        else
            return 1
        fi
    fi

    # Resolve task file: try as-is, then .tasks/<name>.md, .tasks/<name>, .tasks/archive/<name>.md, .tasks/archive/<name>
    if [ -f "$ROOT_DIR/$task_input" ]; then
        echo "$ROOT_DIR/$task_input"
    elif [ -f "$ROOT_DIR/.tasks/${task_input}.md" ]; then
        echo "$ROOT_DIR/.tasks/${task_input}.md"
    elif [ -f "$ROOT_DIR/.tasks/${task_input}" ]; then
        echo "$ROOT_DIR/.tasks/${task_input}"
    elif [ -f "$ROOT_DIR/.tasks/archive/${task_input}.md" ]; then
        echo "$ROOT_DIR/.tasks/archive/${task_input}.md"
    elif [ -f "$ROOT_DIR/.tasks/archive/${task_input}" ]; then
        echo "$ROOT_DIR/.tasks/archive/${task_input}"
    else
        return 1
    fi
}

function delegate_to_skill() {
    local skill_script=$1
    shift
    if [ -f "$ROOT_DIR/$skill_script" ]; then
        bash "$ROOT_DIR/$skill_script" "$@"
    else
        echo "❌ Error: Skill script not found at $skill_script"
        exit 1
    fi
}

if [ "$CMD" == "open" ]; then
    RESOLVED=$(resolve_task_path)
    if [ $? -ne 0 ]; then
        echo "No active task context (task.ctx not found)."
        echo "Use '/swt:flow mount <task_file>' to set an active task."
        exit 0
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
    RESOLVED=$(resolve_task_path)
    if [ $? -ne 0 ]; then
        echo "No active task context."
        exit 1
    fi

    echo "Active context: $(basename "$RESOLVED")"
    exit 0
fi

if [ "$CMD" == "view-task" ]; then
    RESOLVED=$(resolve_task_path "$2")
    if [ $? -ne 0 ]; then
        echo "❌ Error: Could not resolve task path."
        exit 1
    fi
    
    echo "Opening task in browser: $(basename "$RESOLVED")"
    xdg-open "$RESOLVED" &>/dev/null || open "$RESOLVED" &>/dev/null || echo "⚠️ Could not open browser automatically. Path: $RESOLVED"
    
    # If there is a Spec: link, open it too
    SPEC_FILE=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$RESOLVED" | head -n 1)
    if [ -n "$SPEC_FILE" ] && [ -f "$ROOT_DIR/$SPEC_FILE" ]; then
        echo "Opening companion spec: $(basename "$SPEC_FILE")"
        xdg-open "$ROOT_DIR/$SPEC_FILE" &>/dev/null || open "$ROOT_DIR/$SPEC_FILE" &>/dev/null || true
    fi
    exit 0
fi

if [ "$CMD" == "init" ]; then
    echo "--- SWT Project Initialization ---"
    echo "The '/swt:init' command is a behavioral directive for your AI agent."
    echo ""
    echo "1. Describe your project to the agent."
    echo "2. The agent will interview you to determine the workspace type."
    echo "3. It will then scaffold the mandatory AGENTS.md and discovery pointers."
    echo ""
    echo "To begin, say: \"Bootstrap this project using /swt:init\""
    exit 0
fi

# Orchestrator Routing
case $CMD in
    new|brainstorm|graduate|phase|validate|list|ctx|mount|unmount|tidy|abandon|test|sync|sync-downstream|scaffold)
        delegate_to_skill "skills/swt-task/scripts/task.sh" "$@"
        exit 0
        ;;
    status)
        shift
        delegate_to_skill "skills/swt-status/scripts/status.sh" "$@"
        exit 0
        ;;
    digest)
        shift
        delegate_to_skill "skills/swt-digest/scripts/digest.sh" "$@"
        exit 0
        ;;
    commit)
        shift
        delegate_to_skill "skills/swt-commit/scripts/commit.sh" "$@"
        exit 0
        ;;
    link)
        shift
        delegate_to_skill "skills/swt-link/scripts/link.sh" "$@"
        exit 0
        ;;
    graphify)
        shift
        delegate_to_skill "skills/swt-graphify/scripts/graphify.sh" "$@"
        exit 0
        ;;
esac

