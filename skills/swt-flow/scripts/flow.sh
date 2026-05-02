#!/bin/bash
# swt:flow — Active workflow engine
# Unified Facade for the Simple Workflow Toolkit

set -e

CMD=${1:-""}

function show_help {
    echo "Usage: /swt:flow <command> [args]"
    echo ""
    echo "Workspace & Context:"
    echo "  status            - Project summary"
    echo "  pulse             - Status + Git history (Heartbeat)"
    echo "  context           - Show current active task path"
    echo "  mount <task>      - Set active task & open browser"
    echo "  unmount           - Clear active task context"
    echo "  view-task         - Resolve and open task in browser"
    echo ""
    echo "Task Lifecycle:"
    echo "  new <name>        - Create Implementation Task (Phase 1)"
    echo "  brainstorm <topic>- Create Ideation Task (Phase 0)"
    echo "  graduate          - Promote Phase 0 → 1 (+ Spec)"
    echo "  backlog           - Show all open/active tasks"
    echo "  history           - Show complete project timeline"
    echo "  archive           - Show only finished/abandoned tasks"
    echo ""
    echo "Ritual Enforcement:"
    echo "  audit             - Deep ritual/protocol integrity check"
    echo "  phase <N>         - Manual ritual phase transition"
    echo "  test              - Run tests via swt.json harness"
    echo "  test-fail         - Verify test failure (TDD ritual)"
    echo "  sync              - Sync root task.md checklist"
    echo "  sync-docs         - Re-sync Spec/Plan after changes"
    echo "  scaffold <type>   - Manually generate artifacts"
    echo ""
    echo "Lifecycle & Hygiene:"
    echo "  close <hash>      - Finalize task (hash required)"
    echo "  abandon           - Mark task abandoned & archive"
    echo "  tidy              - Move closed tasks to archive"
    echo "  bug               - Report friction to SWT core (Upstream)"
    echo ""
    echo "Environment & Continuity:"
    echo "  digest            - Daily session summary"
    echo "  milestone         - Full project roll-up"
    echo "  setup             - Physical workspace setup (.tasks, .specs)"
    echo "  link-dev          - Global dev setup (--global --clear)"
    echo "  link              - Link skills into current project"
    echo "  link-dry          - Preview symlink changes"
    echo ""
    echo "Structural Awareness (Graphify):"
    echo "  graph-init        - Full deep scan and graph build"
    echo "  graph-up          - Incremental update (Review)"
    echo "  query <text>      - Semantic structural search"
    echo "  explain <node>    - Component breakdown"
    echo "  path <A> <B>      - Relationship between components"
    echo "  graph-on          - Enable structural rituals"
    echo "  graph-off         - Disable structural rituals"
}

if [ -z "$CMD" ] || [ "$CMD" == "help" ] || [ "$CMD" == "--help" ]; then
    show_help
    exit 0
fi

# Determine workspace root
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

    if [ -f "$ROOT_DIR/$task_input" ]; then echo "$ROOT_DIR/$task_input"
    elif [ -f "$ROOT_DIR/.tasks/${task_input}.md" ]; then echo "$ROOT_DIR/.tasks/${task_input}.md"
    elif [ -f "$ROOT_DIR/.tasks/${task_input}" ]; then echo "$ROOT_DIR/.tasks/${task_input}"
    elif [ -f "$ROOT_DIR/.tasks/archive/${task_input}.md" ]; then echo "$ROOT_DIR/.tasks/archive/${task_input}.md"
    elif [ -f "$ROOT_DIR/.tasks/archive/${task_input}" ]; then echo "$ROOT_DIR/.tasks/archive/${task_input}"
    else return 1; fi
}

function delegate() {
    local script=$1
    shift
    bash "$ROOT_DIR/$script" "$@"
}

case $CMD in
    # Workspace & Context
    status) shift; delegate "skills/swt-status/scripts/status.sh" "$@" ;;
    pulse) shift; delegate "skills/swt-status/scripts/status.sh" --git "$@" ;;
    context) shift; delegate "skills/swt-task/scripts/task.sh" ctx show "$@" ;;
    mount) shift; delegate "skills/swt-task/scripts/task.sh" mount "$@" ;;
    unmount) shift; delegate "skills/swt-task/scripts/task.sh" unmount "$@" ;;
    open) shift; # Internal flow.sh logic
        RESOLVED=$(resolve_task_path)
        if [ $? -ne 0 ]; then echo "No active task context."; exit 0; fi
        echo "--- Active Task Context ---"
        echo "Task: $(basename "$RESOLVED")"
        grep -E "^\*\*?(Status|Phase|Type|Priority)\*\*?:" "$RESOLVED"
        echo ""
        grep -A 1 "## Objective" "$RESOLVED" | grep -v "## Objective" | sed '/^$/d' | head -1
        grep -m 1 "\[ \]" "$RESOLVED" | sed 's/.*\[ \] /Next: /'
        ;;
    view-task) shift; # Internal flow.sh logic
        RESOLVED=$(resolve_task_path "$1")
        if [ $? -ne 0 ]; then echo "❌ Error: Could not resolve task."; exit 1; fi
        xdg-open "$RESOLVED" &>/dev/null || open "$RESOLVED" &>/dev/null || true
        SPEC_FILE=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$RESOLVED" | head -n 1)
        if [ -n "$SPEC_FILE" ] && [ -f "$ROOT_DIR/$SPEC_FILE" ]; then
            xdg-open "$ROOT_DIR/$SPEC_FILE" &>/dev/null || open "$ROOT_DIR/$SPEC_FILE" &>/dev/null || true
        fi
        ;;

    # Task Lifecycle
    new|brainstorm|graduate) shift; delegate "skills/swt-task/scripts/task.sh" "$CMD" "$@" ;;
    backlog) shift; delegate "skills/swt-task/scripts/task.sh" list --open "$@" ;;
    history) shift; delegate "skills/swt-task/scripts/task.sh" list --all "$@" ;;
    archive) shift; delegate "skills/swt-task/scripts/task.sh" list --done "$@" ;;

    # Ritual Enforcement
    audit) shift; delegate "skills/swt-task/scripts/task.sh" validate "$@" ;;
    phase) shift; delegate "skills/swt-task/scripts/task.sh" phase "$@" ;;
    test) shift; delegate "skills/swt-task/scripts/task.sh" test "$@" ;;
    test-fail) shift; delegate "skills/swt-task/scripts/task.sh" test "$@" --fail ;;
    sync) shift; delegate "skills/swt-task/scripts/task.sh" sync "$@" ;;
    sync-docs) shift; delegate "skills/swt-task/scripts/task.sh" sync-downstream "$@" ;;
    scaffold) shift; delegate "skills/swt-task/scripts/task.sh" scaffold "$@" ;;

    # Lifecycle & Hygiene
    close|abandon|tidy) shift; delegate "skills/swt-task/scripts/task.sh" "$CMD" "$@" ;;
    bug) shift; delegate "skills/swt-task/scripts/task.sh" brainstorm "$@" --uplink ;;

    # Environment & Continuity
    digest) shift; delegate "skills/swt-digest/scripts/digest.sh" "$@" ;;
    milestone) shift; delegate "skills/swt-digest/scripts/digest.sh" --milestone "$@" ;;
    setup) shift; delegate "skills/swt-task/scripts/task.sh" init "$@" ;;
    link-dev) shift; delegate "skills/swt-link/scripts/link.sh" --global --clear "$@" ;;
    link) shift; delegate "skills/swt-link/scripts/link.sh" "$@" ;;
    link-dry) shift; delegate "skills/swt-link/scripts/link.sh" --dry-run "$@" ;;
    link-clear) shift; delegate "skills/swt-link/scripts/link.sh" --clear "$@" ;;
    link-global) shift; delegate "skills/swt-link/scripts/link.sh" --global "$@" ;;

    # Structural Awareness (Graphify)
    graph-init) shift; delegate "skills/swt-graphify/scripts/graphify.sh" init "$@" ;;
    graph-up) shift; delegate "skills/swt-graphify/scripts/graphify.sh" update "$@" ;;
    graph-on) shift; delegate "skills/swt-graphify/scripts/graphify.sh" on "$@" ;;
    graph-off) shift; delegate "skills/swt-graphify/scripts/graphify.sh" off "$@" ;;
    graph-check) shift; delegate "skills/swt-graphify/scripts/graphify.sh" verify "$@" ;;
    graph-wipe) shift; delegate "skills/swt-graphify/scripts/graphify.sh" uninstall "$@" ;;
    query|explain|path) shift; delegate "skills/swt-graphify/scripts/graphify.sh" "$CMD" "$@" ;;

    # Legacy / Internal
    init) # swt:init guidance
        echo "--- SWT Project Initialization ---"
        echo "The '/swt:init' command is a behavioral directive for your AI agent."
        echo "To begin, say: \"Bootstrap this project using /swt:init\""
        ;;
    check) shift; # Internal context check
        RESOLVED=$(resolve_task_path)
        if [ $? -ne 0 ]; then exit 1; fi
        echo "Active context: $(basename "$RESOLVED")"
        ;;
    *)
        echo "Unknown command: $CMD"
        show_help
        exit 1
        ;;
esac
