#!/bin/bash

# Universal AI Task Manager (swt.sh)
# Facilitates semantic agent interaction with a local .tasks/ directory

set -e

CMD=$1
ARG=$2

# Determine workspace root (look for AGENTS.md or .git)
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

# --- Steve Ballmer Heartbeat (Protocol Alignment) ---
SWT_CONFIG="$ROOT_DIR/swt.json"
SWT_MODE="protocol" # Default
BALLMER_CHANT="PROTOCOL! PROTOCOL! PROTOCOL!"

if [ -f "$SWT_CONFIG" ]; then
    # Use python to extract mode safely
    SWT_MODE=$(python3 -c "import json; print(json.load(open('$SWT_CONFIG')).get('mode', 'protocol'))" 2>/dev/null || echo "protocol")
    SWT_BALLMER=$(python3 -c "import json; print(json.load(open('$SWT_CONFIG')).get('ritual_gates', {}).get('ballmer_heartbeat', True))" 2>/dev/null || echo "True")
fi

if [ "$SWT_MODE" != "yolo" ] && [ "$SWT_BALLMER" == "True" ] && [ "$CMD" != "ctx" ] && [ "$CMD" != "list" ]; then
    echo "💓 Heartbeat: $BALLMER_CHANT"
fi
# --------------------------------------------------

function log_ritual() {
    local type=$1
    local file=$2
    local extra=$3
    local date_str=$(date +"%Y-%m-%d %H:%M:%S")
    local entry="<!-- RITUAL: $type @ $date_str $extra -->"

    if grep -q "^## Ritual Logs" "$file"; then
        # Insert after the header
        sed -i "/^## Ritual Logs/a $entry" "$file"
    else
        # Fallback to append
        echo "$entry" >> "$file"
    fi
}

function unmount_task {
    # Ensure we are in the root directory for cleanup
    local root_dir=$(pwd)
    while [[ "$root_dir" != "/" && ! -f "$root_dir/AGENTS.md" && ! -d "$root_dir/.git" ]]; do
        root_dir=$(dirname "$root_dir")
    done

    rm -f "$root_dir/task.ctx" "$root_dir/task.md" "$root_dir/protocol.md" "$root_dir/implementation_plan.md"
    rm -f "$root_dir/task.md.json" "$root_dir/protocol.md.json" "$root_dir/implementation_plan.md.json"
    rm -f "$root_dir/commit.draft" "$root_dir/commit.task" "$root_dir/commit.diff"
    # Debris Sweep
    rm -f "$root_dir"/.*.tmp
    echo "✅ Unmounted active task context and cleared ephemeral artifacts."
}

function check_sandbox {
    # Ensure we are in the root directory for cleanup
    local root_dir=$(pwd)
    while [[ "$root_dir" != "/" && ! -f "$root_dir/AGENTS.md" && ! -d "$root_dir/.git" ]]; do
        root_dir=$(dirname "$root_dir")
    done

    # Green Zones: .tasks/, .specs/, .digests/, .tests/, root artifacts, metadata, and graphify output
    local violations=$(git -C "$root_dir" status --porcelain | grep -vE '^.. (\.tasks/|\.specs/|\.digests/|\.tests/|task\.md|implementation_plan\.md|protocol\.md|task\.ctx|commit\.|walkthrough\.md|graphify-out/)' || true)

    if [ -n "$violations" ]; then
        echo "🛑 SANDBOX VIOLATION DETECTED"
        echo "The following files were modified during Phase 0 (Ideate):"
        echo "$violations" | sed 's/^/   /'
        echo ""
        echo "👉 Phase 0 is for architecture and trade-offs ONLY."
        echo "👉 You must discard, stash, or commit these changes before graduating."
        return 1
    fi
    return 0
}

function show_help {
    echo "Usage:"
    echo "  swt.sh init              - Initialize .tasks/ directory and update .gitignore"
    echo "  swt.sh new \"Final Feature Name\"  - Create a new timestamped task file"
    echo "  swt.sh brainstorm \"Topic\"        - Create a Phase 0 ideation task"
    echo "  swt.sh sync <file>        - Sync root task.md from internal task file"
    echo "  swt.sh scaffold <type> <file> [--force] - Generate Plan artifact"
    echo "  swt.sh phase <N> <file>    - Transition task to Phase N"
    echo "  swt.sh validate <file>     - Verify ritual integrity and artifact state"
    echo "  swt.sh list [--open|--done] - List tasks in the project"
    echo "  swt.sh sync-downstream <file> - Sync Spec/Plan after objective changes"
    echo "  swt.sh close <file> <hash> - Finalize task (status: done, checklist: complete)"
    echo "  swt.sh mount <file>        - Set active task context (writes task.ctx)"
    echo "  swt.sh unmount             - Clear active task context (removes task.ctx)"
    echo "  swt.sh ctx set <file>      - [DEPRECATED] Use mount instead"
    echo "  swt.sh ctx clear           - [DEPRECATED] Use unmount instead"
    echo "  swt.sh ctx show            - Show current active task context"
    echo "  swt.sh tidy                 - Move done/abandoned tasks to .tasks/archive/"
    echo "  swt.sh abandon <file>      - Abandon task (status: abandoned, no commit hash)"
    echo "  swt.sh test <file> [--fail] - Run tests via swt.json harness and log ritual"
}

function validate_artifacts {
    local phase=$1

    # Phantom Artifact Check
    check_phantom() {
        local name=$1
        # Search common hidden jailbreak locations (relative to root)
        local phantom=$(find . -maxdepth 3 \( -path "./.gemini*" -o -path "./.agents*" -o -path "./.claude*" \) -name "$name" 2>/dev/null | head -n 1)
        if [ -n "$phantom" ] && [ ! -f "$name" ]; then
            echo "🛑 PHANTOM ARTIFACT DETECTED: $name found in $phantom but missing from project root."
            echo "   Move it to the root immediately to pass verification."
            return 1
        fi
        return 0
    }

    if [ "$phase" -ge 1 ] && [ "$phase" -lt 8 ]; then
        if [ ! -f "implementation_plan.md" ]; then
            check_phantom "implementation_plan.md"
            echo "🛑 PROTOCOL VIOLATION: Phase $phase requires implementation_plan.md at the project root."
            return 1
        fi
    fi
    if [ "$phase" -ge 5 ]; then
        if [ ! -f "task.md" ]; then
            check_phantom "task.md"
            echo "🛑 PROTOCOL VIOLATION: Phase $phase requires task.md at the project root."
            return 1
        fi
        if [ ! -f "protocol.md" ]; then
            check_phantom "protocol.md"
            echo "🛑 PROTOCOL VIOLATION: Phase $phase requires protocol.md at the project root as an Execution Guard."
            return 1
        fi
    fi
    return 0
}

function invoke_twin() {
    local file=$1
    shift
    local twin_script="$ROOT_DIR/skills/swt-task/scripts/twin.py"
    
    if [ ! -f "$twin_script" ]; then
        echo "⚠️ Global Twin engine not found. Falling back to legacy patching."
        return 1
    fi

    # The --harvest flag ensures we ingest current root state before applying mods
    python3 "$twin_script" "$file" --harvest "$@" --synthesize
    return $?
}

function list_tasks {
    local filter=""
    local classify=false
    local priority=false
    local summary=false
    
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --open) filter="--open" ;;
            --done) filter="--done" ;;
            --abandoned) filter="--abandoned" ;;
            --classify|-c) classify=true ;;
            --priority|-p) priority=true ;;
            --summary|-s) summary=true ;;
            *) # Ignore unknown
               ;;
        esac
        shift
    done

    # Create temporary file to store task data for sorting/grouping
    local task_data=$(mktemp)
    
    for f in .tasks/*.md; do
        [ -e "$f" ] || continue
        local ts=$(basename "$f" | cut -d'_' -f1)
        local phase=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$f" | head -n 1)
        local status=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$f" | head -n 1)
        
        # Filtering
        if [ "$filter" == "--open" ]; then
            if [[ "$status" == "done" ]] || [[ "$status" == "abandoned" ]]; then continue; fi
        elif [ "$filter" == "--done" ]; then
            if [[ "$status" != "done" ]]; then continue; fi
        elif [ "$filter" == "--abandoned" ]; then
            if [[ "$status" != "abandoned" ]]; then continue; fi
        fi

        local category=$(grep -oP '^\*\*?Category\*\*?:\s*\K\S+' "$f" | head -n 1)
        category=${category:-uncategorized}
        local prio_str=$(grep -oP '^\*\*?Priority\*\*?:\s*\K\S+' "$f" | head -n 1)
        prio_str=${prio_str:-medium}
        
        # Map priority to numeric for sorting
        local prio_num=2
        case $prio_str in
            critical) prio_num=4 ;;
            high) prio_num=3 ;;
            medium) prio_num=2 ;;
            low) prio_num=1 ;;
        esac

        local objective=$(grep -oP '^## Objective\s*\n\K.*' "$f" | head -n 1)
        if [ -z "$objective" ]; then
            objective=$(sed -n '/^## \(Objective\|Core Concept\)/,/^## /p' "$f" | grep -v '^## ' | grep -v '^$' | head -n 1)
        fi
        objective=$(echo "$objective" | tr '\t' ' ' | cut -c1-60 | sed 's/[[:space:]]*$//')
        [ ${#objective} -ge 60 ] && objective="${objective}..."
        
        echo -e "$category\t$prio_num\t$ts\t$phase\t$status\t$objective" >> "$task_data"
    done

    if [ "$classify" = true ]; then
        # Grouped by Category, then Priority, then Timestamp
        local last_cat=""
        sort -k1,1 -k2,2rn -k3,3 "$task_data" | while IFS=$'\t' read -r cat p_num ts phase stat obj; do
            if [ "$cat" != "$last_cat" ]; then
                [ -n "$last_cat" ] && echo ""
                local cat_display=$(echo "$cat" | sed 's/\b\(.\)/\u\1/g')
                echo "📂 $cat_display"
                last_cat=$cat
            fi
            printf "  %-15s %-3s %-10s %s\n" "$ts" "$phase" "$stat" "$obj"
            if [ "$summary" = true ]; then
                local task_file=$(ls .tasks/${ts}_*.md 2>/dev/null | head -n 1)
                if [ -n "$task_file" ] && [ -f "$task_file" ]; then
                    local sum_content=$(sed -n '/^## What This Task Covers/,/^## /p' "$task_file" | grep -v '^## ' | grep -v '^$' | head -n 3)
                    if [ -n "$sum_content" ]; then
                        echo "    ↳ Summary:"
                        echo "$sum_content" | sed 's/^/      | /'
                        echo ""
                    fi
                fi
            fi
        done
    elif [ "$priority" = true ]; then
        # Sorted by Priority, then Timestamp
        printf "%-15s %-3s %-10s %s\n" "Timestamp" "Ph" "Status" "Objective"
        printf "%-15s %-3s %-10s %s\n" "---------------" "---" "----------" "---------"
        sort -k2,2rn -k3,3 "$task_data" | while IFS=$'\t' read -r cat p_num ts phase stat obj; do
            printf "%-15s %-3s %-10s %s\n" "$ts" "$phase" "$stat" "$obj"
            if [ "$summary" = true ]; then
                local task_file=$(ls .tasks/${ts}_*.md 2>/dev/null | head -n 1)
                if [ -n "$task_file" ] && [ -f "$task_file" ]; then
                    local sum_content=$(sed -n '/^## What This Task Covers/,/^## /p' "$task_file" | grep -v '^## ' | grep -v '^$' | head -n 3)
                    if [ -n "$sum_content" ]; then
                        echo "  ↳ Summary:"
                        echo "$sum_content" | sed 's/^/    | /'
                        echo ""
                    fi
                fi
            fi
        done
    else
        # Default: Flat / Chronological
        printf "%-15s %-3s %-10s %s\n" "Timestamp" "Ph" "Status" "Objective"
        printf "%-15s %-3s %-10s %s\n" "---------------" "---" "----------" "---------"
        sort -k3,3 "$task_data" | while IFS=$'\t' read -r cat p_num ts phase stat obj; do
            printf "%-15s %-3s %-10s %s\n" "$ts" "$phase" "$stat" "$obj"
            if [ "$summary" = true ]; then
                local task_file=$(ls .tasks/${ts}_*.md 2>/dev/null | head -n 1)
                if [ -n "$task_file" ] && [ -f "$task_file" ]; then
                    local sum_content=$(sed -n '/^## What This Task Covers/,/^## /p' "$task_file" | grep -v '^## ' | grep -v '^$' | head -n 3)
                    if [ -n "$sum_content" ]; then
                        echo "  ↳ Summary:"
                        echo "$sum_content" | sed 's/^/    | /'
                        echo ""
                    fi
                fi
            fi
        done
    fi
    rm -f "$task_data"
}

function sync_roadmap {
    local internal_file=$1
    if [ ! -f "protocol.md" ] || [ ! -f "$internal_file" ]; then return 0; fi
    
    echo "🔄 Ingesting tactical progress from protocol.md..."
    # Extract the Execution Loop section and filter for checklist items
    local roadmap=$(sed -n '/## 2. Gate 3: Execution Loop/,/##/p' "protocol.md" | grep -E '^\s*-\s*\[[ xX/]\]' || true)
    
    if [ -n "$roadmap" ]; then
        if [ -f "$ROOT_DIR/skills/swt-task/scripts/crow.py" ]; then
            python3 "$ROOT_DIR/skills/swt-task/scripts/crow.py" "$internal_file" --patch "Tactical Roadmap" "$roadmap"
            echo "✅ Internal tactical roadmap synchronized."
        else
            echo "⚠️  crow.py not found. Roadmap synchronization skipped."
        fi
    fi
}

function sync_task_to_internal {
    local internal_file=$1
    if [ ! -f "task.md" ] || [ ! -f "$internal_file" ]; then return 0; fi
    
    echo "🔄 Ingesting checklist progress from task.md..."
    # Extract the checklist items from task.md
    grep "^- \[" task.md > .checklist.tmp || true
    
    if [ -s .checklist.tmp ]; then
        # Use a temporary file to rebuild the internal task file
        local head_part=$(sed -n '1,/^## Checklist/p' "$internal_file" | head -n -1)
        local tail_part=$(awk '/^## Checklist/{p=1;next} p { if (!started && $0 ~ /^- \[/) next; started=1; print }' "$internal_file")
        
        echo "$head_part" > .task_new.tmp
        echo "## Checklist" >> .task_new.tmp
        cat .checklist.tmp >> .task_new.tmp
        echo "" >> .task_new.tmp
        echo "$tail_part" >> .task_new.tmp
        
        mv .task_new.tmp "$internal_file"
        echo "✅ Internal task checklist synchronized."
    fi
    rm -f .checklist.tmp
}

function check_substance {
    local file=$1
    if [ ! -f "$file" ]; then return 1; fi

    # 1. Template Marker Audit
    if grep -q "{{" "$file"; then
        echo "🛑 NAKED TEMPLATE JAILBREAK: Document contains unpopulated '{{' markers."
        grep -n "{{" "$file" | sed 's/^/   /'
        return 1
    fi

    # 2. Substance Density Check (Minimum 100 chars in Notes + Objective)
    local obj_count=$(sed -n '/^## Objective/,/^## /p' "$file" | grep -v "^## " | tr -d '\n' | wc -c)
    local notes_count=$(sed -n '/^## Notes/,/^## /p' "$file" | grep -v "^## " | tr -d '\n' | wc -c)
    local total_substance=$((obj_count + notes_count))
    
    if [ "$total_substance" -lt 100 ]; then
        echo "🛑 THIN BRAINSTORM JAILBREAK: Task substance insufficient for graduation ($total_substance/100 chars)."
        echo "👉 Fill ## Notes with technical findings and trade-off analysis before proceeding."
        return 1
    fi

    return 0
}

function get_substance() {
    local file=$1
    # Extract Objective and Notes sections, removing headers and empty lines
    sed -n '/^## Objective/,/^## /p' "$file" | grep -v "^## " | sed '/^$/d'
    sed -n '/^## Notes/,/^## /p' "$file" | grep -v "^## " | sed '/^$/d'
}

function check_phase_transition {
    local file=$1
    local new_phase=$2
    
    if [ "$SWT_MODE" == "yolo" ]; then return 0; fi

    local current_phase=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$file" | head -n 1)
    
    # 1. Sequential Enforcement
    local phase_order=$(python3 -c "import json; print(json.load(open('$SWT_CONFIG')).get('ritual_gates', {}).get('phase_order_enforcement', True))" 2>/dev/null || echo "True")
    
    if [ "$phase_order" == "True" ]; then
        if [ "$new_phase" -gt "$((current_phase + 1))" ]; then
            echo "🛑 LOOP JUMP DETECTED: Cannot jump from Phase $current_phase to Phase $new_phase."
            echo "👉 You MUST transition through all intermediate phases and log their rituals."
            return 1
        fi
    fi

    # 2. Phase 5 Approval Gate (The Golden Gate)
    local hitl_approval=$(python3 -c "import json; print(json.load(open('$SWT_CONFIG')).get('ritual_gates', {}).get('hitl_approval', True))" 2>/dev/null || echo "True")
    
    if [ "$new_phase" -eq 5 ] && [ "$hitl_approval" == "True" ]; then
        # Check if user has explicitly approved implementation in the task or spec
        if ! grep -q "GATE 2: APPROVED" "$file"; then
            echo "🛑 GATE 2 LOCKED: Implementation (Phase 5) requires explicit user approval."
            echo "👉 The user MUST append 'GATE 2: APPROVED' to the task or spec before proceeding."
            return 1
        fi
        echo "🔓 GATE 2 UNLOCKED: Implementation authorized."
    fi

    return 0
}

function sync_task_md {
    local file=$1
    if [ ! -f "$file" ]; then return 1; fi
    
    local title=$(grep -m 1 "^# Task:" "$file" | sed 's/# Task: //')
    local template_path="$ROOT_DIR/skills/swt-task/templates/task.md"
    local items=$(sed -n '/## Checklist/,/##/p' "$file" | grep -v "##" | sed '/^$/d')

    if [ -f "$template_path" ]; then
        sed "s|{{Task Name}}|$title|g" "$template_path" > task.md
        echo "$items" > .items.tmp
        sed -i "/{{CHECKLIST_ITEMS}}/{r .items.tmp
d}" task.md
        rm .items.tmp
    else
        {
            echo "# Task Checklist: $title"
            echo ""
            echo "$items"
        } > task.md
    fi
    echo "✅ task.md synced from $(basename "$file")"
}

function scaffold_artifact {
    local type=$1
    local task_file=$2
    local force=$3
    
    local template_path="$ROOT_DIR/skills/swt-task/templates/${type}.md"
    local target_path="${type}.md"
    
    if [ ! -f "$template_path" ]; then
        echo "❌ Error: Template not found for type: $type"
        return 1
    fi
    
    if [ -f "$target_path" ] && [ "$force" != "--force" ]; then
        echo "⚠️ $target_path already exists. Skipping scaffold. (Use --force to overwrite)"
        return 0
    fi
    
    # If sidecar exists, use it for synthesis to preserve content
    if [ -f "${target_path}" ]; then
        echo "🔄 Harvesting current $target_path state..."
        python3 "$ROOT_DIR/skills/swt-task/scripts/twin.py" "$target_path" --harvest
    fi

    if [ -f "${task_file}.json" ]; then
        echo "🔄 Merging Task state and synthesizing $target_path..."
        # We pass task state as the merging input to the existing artifact state
        python3 "$ROOT_DIR/skills/swt-task/scripts/twin.py" "$target_path" --state "${task_file}.json" --template "$template_path" --out "$target_path" --synthesize
    else
        # Legacy fallback
        local title=$(grep -m 1 "^# Task:" "$task_file" | sed 's/^# Task:[[:space:]]*//')
        local spec_link=$(grep -m 1 "^\*\*Spec\*\*:" "$task_file" | sed 's/^\*\*Spec\*\*:[[:space:]]*//')
        
        sed "s|{{Task Name}}|$title|g" "$template_path" | \
        sed "s|{{Spec Link}}|$spec_link|g" > "$target_path"
    fi
    
    echo "✨ Scaffolded $target_path."
}

function run_tests {
    local file=$1
    local mode=$2
    if [ ! -f "$file" ]; then echo "❌ Error: Task file not found: $file"; exit 1; fi
    if [ ! -f "swt.json" ]; then
        echo "🛑 NO HARNESS DETECTED: swt.json is missing."
        echo "   Please create a harness first: swt.sh scaffold swt.json $file"
        exit 1
    fi

    # Extract command from swt.json
    local test_cmd=$(grep -oP '"test_command":\s*"\K[^"]+' swt.json || true)
    if [ -z "$test_cmd" ] || [ "$test_cmd" == "null" ]; then
        echo "⚠️ No test command defined in swt.json. Manual verification required."
        exit 0
    fi

    echo "🚀 Running tests: $test_cmd"
    mkdir -p .tests
    local timestamp=$(date +%Y%m%d%H%M%S)
    local log_file=".tests/${timestamp}.log"
    
    set +e
    eval "$test_cmd" 2>&1 | tee "$log_file"
    local exit_code=${PIPESTATUS[0]}
    set -e

    local status="fail"
    [ $exit_code -eq 0 ] && status="pass"

    # Add Ritual Log to task file
    log_ritual "test $status" "$file" "($log_file)"
    
    if [ "$status" == "pass" ]; then
        echo "✅ Tests passed! Ritual logged in $(basename "$file")"
    else
        echo "❌ Tests failed. Log captured in $log_file"
        if [ "$mode" == "--fail" ]; then
            echo "✅ Verified failure logged as requested."
        else
            exit 1
        fi
    fi
}

if [ -z "$CMD" ]; then
    show_help
    exit 0
fi

if [ "$CMD" == "init" ]; then
    mkdir -p .tasks/archive
    mkdir -p .specs
    
    # Initialize .gitignore if it exists, otherwise create it
    if [ ! -f .gitignore ]; then
        touch .gitignore
    fi
    
    # Add SWT ignores if they don't exist
    for ignore in ".digests/" ".tasks/*.tmp" "task.ctx" "implementation_plan.md" "task.md" "protocol.md" "commit.diff" "commit.draft" "commit.task"; do
        if ! grep -q "^$ignore" .gitignore; then
            echo "$ignore" >> .gitignore
        fi
    done
    
    echo "Initialized SWT workspace."
    exit 0
fi

if [ "$CMD" == "new" ]; then
    if [ -z "$ARG" ]; then
        echo "Usage: swt.sh new \"Task Name\""
        exit 1
    fi
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
    SAFE_NAME=$(echo "$ARG" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')
    FILENAME=".tasks/${TIMESTAMP}_${SAFE_NAME}.md"
    
    template_path="$ROOT_DIR/skills/swt-task/templates/task.md"

    # Initialize via Global Twin
    invoke_twin "$FILENAME" --template "$template_path" \
        --set-meta "Task" "$ARG" \
        --set-meta "Created" "$DATE_STR" \
        --set-meta "Status" "pending" \
        --set-meta "Phase" "1" \
        --set-section "Core Concept" "$ARG" \
        --set-item "Checklist" "Phase 1: Plan" "/"

    log_ritual "phase 1" "$FILENAME"
    echo "Created task: $FILENAME"
    sync_task_md "$FILENAME"
    exit 0
fi

if [ "$CMD" == "brainstorm" ]; then
    if [ -z "$ARG" ]; then
        echo "Usage: swt.sh brainstorm \"Topic\" [--uplink]"
        exit 1
    fi

    UPLINK=$2
    TASK_ROOT=".tasks"
    UPLINK_CONTEXT=""

    if [ "$UPLINK" == "--uplink" ]; then
        # Determine SWT_HOME (where AGENTS.md lives)
        SWT_HOME=$ROOT_DIR
        if [ ! -f "$SWT_HOME/AGENTS.md" ]; then
            echo "Error: AGENTS.md not found in $SWT_HOME. Cannot uplink."
            exit 1
        fi
        if [ ! -d "$SWT_HOME/.tasks" ]; then
            echo "Error: $SWT_HOME/.tasks not found. Cannot uplink."
            exit 1
        fi
        TASK_ROOT="$SWT_HOME/.tasks"
        
        # Capture Context
        C_PWD=$(pwd)
        # Find active task (most recent non-closed md in .tasks)
        C_TASK=$(ls -t .tasks/*.md 2>/dev/null | xargs grep -l -E '^\*\*?Status\*\*?:\s*(pending|ideating|in-progress)' | head -n 1 || echo "none")
        C_PHASE="unknown"
        if [ "$C_TASK" != "none" ]; then
            C_PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$C_TASK" | head -n 1)
        fi
        
        UPLINK_CONTEXT="- **Source Project**: $C_PWD
- **Source Task**: $(basename "$C_TASK")
- **Source Phase**: $C_PHASE"
    elif [ ! -d ".tasks" ]; then
        echo "Error: No .tasks/ directory found. Run 'swt.sh init' first."
        exit 1
    fi

    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")

    SAFE_NAME=$(echo "$ARG" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')
    FILENAME="${TASK_ROOT}/${TIMESTAMP}_${SAFE_NAME}.md"

    template_path="$ROOT_DIR/skills/swt-task/templates/brainstorm.md"
    
    # Initialize via Global Twin
    invoke_twin "$FILENAME" --template "$template_path" \
        --set-meta "Task" "$ARG" \
        --set-meta "Created" "$DATE_STR" \
        --set-meta "Status" "ideating" \
        --set-meta "Phase" "0" \
        --set-section "Objective" "$ARG" \
        --set-section "Notes" "$UPLINK_CONTEXT"

    echo "Created brainstorm task: $FILENAME"
    sync_task_md "$FILENAME"

    # Smart mount: auto-mount only if no task is currently mounted
    if [ ! -f "task.ctx" ]; then
        echo "$FILENAME" > task.ctx
        echo "   Auto-mounted as active task (task.ctx was empty)"
    fi

    exit 0
fi

if [ "$CMD" == "sync" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        echo "Usage: swt.sh sync <task_file>"
        exit 1
    fi
    sync_task_md "$FILE"
    exit 0
fi

if [ "$CMD" == "sync-roadmap" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        if [ -f "task.ctx" ]; then
            FILE=$(cat task.ctx | tr -d '[:space:]')
        else
            echo "Usage: swt.sh sync-roadmap <task_file>"
            exit 1
        fi
    fi
    sync_roadmap "$FILE"
    exit 0
fi

if [ "$CMD" == "test" ]; then
    FILE=$2
    MODE=$3
    if [ -z "$FILE" ]; then
        echo "Usage: swt.sh test <file> [--fail]"
        exit 1
    fi
    run_tests "$FILE" "$MODE"
    exit 0
fi

if [ "$CMD" == "scaffold" ]; then
    TYPE=$2
    FILE=$3
    FORCE=$4
    if [ -z "$TYPE" ] || [ -z "$FILE" ]; then
        echo "Usage: swt.sh scaffold <type> <file> [--force]"
        exit 1
    fi
    scaffold_artifact "$TYPE" "$FILE" "$FORCE"
    exit 0
fi

if [ "$CMD" == "graduate" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        echo "Usage: swt.sh graduate <task_file>"
        exit 1
    fi

    STATUS=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$FILE" | head -n 1)
    PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$FILE" | head -n 1)

    if [ "$PHASE" -ne 0 ]; then
        echo "Error: Task is already in Phase $PHASE. Only Phase 0 tasks can be graduated."
        exit 1
    fi

    # 0. Substance Check (Born Complete Enforcement)
    if [ "$SWT_MODE" != "yolo" ]; then
        if ! check_substance "$FILE"; then
            exit 1
        fi
    fi

    # 0. Sandbox Check (Safety Interlock)
    if ! check_sandbox; then
        exit 1
    fi

    # 1. Update status to pending and phase to 1 via Global Twin
    invoke_twin "$FILE" --set-meta "Status" "pending" --set-meta "Phase" "1" --set-item "Checklist" "Phase 1: Plan" "/"
    
    # 2. Add Ritual Log
    log_ritual "phase 1" "$FILE"

    # 3. Scaffold Spec via Global Twin
    SLUG=$(basename "$FILE" .md | sed 's/^[0-9]*_//')
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    SPEC_FILE=".specs/${TIMESTAMP}_${SLUG}.md"
    
    spec_template="$ROOT_DIR/skills/swt-task/templates/spec.md"
    
    if [ -f "$spec_template" ]; then
        # Map task sections to spec sections via Global Twin synthesis
        # We use the task's JSON state as the input for the spec synthesis
        python3 "$ROOT_DIR/skills/swt-task/scripts/twin.py" "$FILE" --state "${FILE}.json" --template "$spec_template" --out "$SPEC_FILE" --synthesize

        echo "Graduated $FILE to Phase 1. Spec created: $SPEC_FILE"
        xdg-open "$SPEC_FILE" &
        
        # Scaffold implementation plan and protocol
        scaffold_artifact "implementation_plan" "$FILE"
        scaffold_artifact "protocol" "$FILE"
        
        # Add Spec link to task header via Global Twin
        invoke_twin "$FILE" --set-meta "Spec" "$SPEC_FILE"
        
        if [ "$SWT_MODE" != "yolo" ] && [ "$SWT_BALLMER" == "True" ]; then
            echo "🎉 GRADUATION VERIFIED: $BALLMER_CHANT"
        fi
    else
        echo "Graduated $FILE to Phase 1 (Lite path)."
    fi

    sync_task_md "$FILE"
    exit 0
fi

if [ "$CMD" == "sync-docs" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        echo "Usage: swt.sh sync-docs <task_file>"
        exit 1
    fi
    
    # 1. Harvest latest Task state
    python3 "$ROOT_DIR/skills/swt-task/scripts/twin.py" "$FILE" --harvest

    # 2. Re-sync Spec from Task state
    echo "🔄 Re-syncing Spec from Task via Global Twin..."
    SPEC_FILE=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$FILE" | head -n 1)
    
    if [ -z "$SPEC_FILE" ] || [ ! -f "$SPEC_FILE" ]; then
        echo "❌ Spec not found for $FILE. Run 'graduate' first."
        exit 1
    fi

    spec_template="$ROOT_DIR/skills/swt-task/templates/spec.md"
    # We use the task's state to re-synthesize the spec, preserving spec's own sidecar if it exists
    python3 "$ROOT_DIR/skills/swt-task/scripts/twin.py" "$FILE" --state "${FILE}.json" --template "$spec_template" --out "$SPEC_FILE" --synthesize
    echo "✅ Spec synchronized: $SPEC_FILE"

    # 3. Re-sync Implementation Plan and Protocol
    echo "🔄 Re-syncing Implementation Plan and Protocol..."
    scaffold_artifact "implementation_plan" "$FILE" --force
    scaffold_artifact "protocol" "$FILE" --force
    
    # 4. Physically reset Task to Phase 1 via Global Twin
    echo "🔄 Resetting Task to Phase 1 due to objective change..."
    invoke_twin "$FILE" --set-meta "Phase" "1" --set-item "Checklist" "Phase 1: Plan" "/"

    log_ritual "phase 1" "$FILE" "(Reset via sync-downstream)"

    # 5. Re-sync task.md
    sync_task_md "$FILE"
    
    echo "✨ Downstream artifacts synchronized via Global Twin. Task reset to Phase 1."
    xdg-open "$SPEC_FILE" &
    exit 0
fi

if [ "$CMD" == "close" ]; then
    FILE=$2
    HASH=$3
    if [ -z "$FILE" ] || [ -z "$HASH" ]; then
        echo "Usage: swt.sh close <task_file> <commit_hash>"
        exit 1
    fi

    # 0. Sync final human progress back to internal task file
    sync_task_to_internal "$FILE"

    # 1. Archive Implementation Plan into Spec
    SPEC_FILE=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$FILE" | head -n 1)
    if [ -f "$SPEC_FILE" ] && [ -f "implementation_plan.md" ]; then
        echo "🔄 Archiving Implementation Plan into Spec..."
        # Extract content excluding title
        grep -v "^# Implementation Plan" "implementation_plan.md" > .plan_content.tmp
        
        # Use a temporary file to rebuild the Spec
        sed -n '1,/^## Implementation Plan/p' "$SPEC_FILE" | head -n -1 > .spec_new.tmp
        echo "## Implementation Plan" >> .spec_new.tmp
        echo "" >> .spec_new.tmp
        cat .plan_content.tmp >> .spec_new.tmp
        
        # Capture everything after the Implementation Plan section (if anything)
        # Assuming Implementation Plan is the last or second to last section
        # Actually, let's just append the rest
        sed -n '/^## Risks & Mitigations/,$p' "$SPEC_FILE" >> .spec_new.tmp
        
        mv .spec_new.tmp "$SPEC_FILE"
        rm .plan_content.tmp
        echo "✅ Plan archived into $SPEC_FILE"
    fi

    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
    invoke_twin "$FILE" --set-meta "Completed" "$DATE_STR" --set-meta "Status" "done" --set-item "Checklist" "Phase 8: Review & Refine" "x"
    
    # Insert commit hash into ## Commit Reference section via Global Twin
    invoke_twin "$FILE" --set-section "Commit Reference" "$HASH"
    
    # Move to archive (including sidecar)
    mkdir -p .tasks/archive
    mv "$FILE" .tasks/archive/
    if [ -f "${FILE}.json" ]; then
        mv "${FILE}.json" .tasks/archive/
    fi
    echo "✅ Task closed: $FILE (Commit: $HASH)"
    unmount_task
    exit 0
fi

if [ "$CMD" == "mount" ]; then
    VAL=$2
    if [ -z "$VAL" ]; then
        echo "Usage: swt.sh mount <file>"
        exit 1
    fi
    echo "$VAL" > task.ctx
    echo "✅ Mounted task: $VAL"
    exit 0
fi

if [ "$CMD" == "unmount" ]; then
    unmount_task
    exit 0
fi

if [ "$CMD" == "ctx" ]; then
    SUB=$2
    VAL=$3
    case $SUB in
        set)
            echo "⚠️ [DEPRECATED] 'ctx set' is deprecated. Use 'mount' instead."
            echo "$VAL" > task.ctx
            echo "Set active task context: $VAL"
            ;;
        clear)
            echo "⚠️ [DEPRECATED] 'ctx clear' is deprecated. Use 'unmount' instead."
            rm -f task.ctx
            echo "Cleared active task context."
            ;;
        show)
            if [ -f task.ctx ]; then
                cat task.ctx
            else
                echo "No active task context."
            fi
            ;;
        *)
            echo "Usage: swt.sh ctx [set <file>|clear|show] (Note: set/clear are deprecated)"
            exit 1
            ;;
    esac
    exit 0
fi

if [ "$CMD" == "tidy" ]; then
    mkdir -p .tasks/archive
    for f in .tasks/*.md; do
        if grep -qE "^\*\*?Status\*\*?:\s*(done|abandoned)" "$f"; then
            mv "$f" .tasks/archive/
            echo "Archived $f"
        fi
    done
    exit 0
fi

if [ "$CMD" == "abandon" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        echo "Usage: swt.sh abandon <task_file>"
        exit 1
    fi
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
    invoke_twin "$FILE" --set-meta "Status" "abandoned" --set-meta "Completed" "$DATE_STR"
    
    mkdir -p .tasks/archive
    mv "$FILE" .tasks/archive/
    if [ -f "${FILE}.json" ]; then
        mv "${FILE}.json" .tasks/archive/
    fi
    echo "Task abandoned: $FILE"
    unmount_task
    exit 0
fi

if [ "$CMD" == "phase" ]; then
    PHASE_NUM=$2
    FILE=$3

    if [ -z "$PHASE_NUM" ] || [ -z "$FILE" ]; then
        echo "Usage: swt.sh phase <N> <task_file>"
        exit 1
    fi

    if [ ! -f "$FILE" ]; then
        echo "Error: File $FILE not found."
        exit 1
    fi

    # 0. Phase Transition Guard (Physical Cage)
    if ! check_phase_transition "$FILE" "$PHASE_NUM"; then
        exit 1
    fi

    # 1. Update Phase header via Global Twin
    invoke_twin "$FILE" --set-meta "Phase" "$PHASE_NUM" --set-item "Checklist" "Phase $PHASE_NUM" "/"

    # 3. Add Ritual Log (with State Verification Signature)
    log_ritual "phase $PHASE_NUM" "$FILE" "(State Verified)"

    if [ "$SWT_MODE" != "yolo" ] && [ "$SWT_BALLMER" == "True" ]; then
        echo "🎉 RITUAL VERIFIED: $BALLMER_CHANT"
    fi



    # 4. Ephemeral Artifact Audit (Scenario C: Enforcement)
    if ! validate_artifacts "$PHASE_NUM"; then
        exit 1
    fi

    echo "Transitioned $FILE to Phase $PHASE_NUM. Ritual logged."
    sync_task_md "$FILE"
    # Sync companion artifact mtimes to prevent false staleness on ritual-only changes
    spec_file=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$FILE" | head -n 1)
    [ -n "$spec_file" ] && [ -f "$spec_file" ] && touch -r "$FILE" "$spec_file"
    [ -f "implementation_plan.md" ] && touch -r "$FILE" "implementation_plan.md"
    [ -f "protocol.md" ] && touch -r "$FILE" "protocol.md"
    exit 0
fi

if [ "$CMD" == "validate" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        if [ -f "$ROOT_DIR/task.ctx" ]; then
            FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
        else
            echo "❌ No active task context. Use 'swt:task mount <file>'."
            exit 1
        fi
    fi

    # Resolve Path (mimic flow.sh)
    if [[ "$FILE" = /* ]] && [ -f "$FILE" ]; then RESOLVED="$FILE"
    elif [ -f "$ROOT_DIR/$FILE" ]; then RESOLVED="$ROOT_DIR/$FILE"
    elif [ -f "$ROOT_DIR/.tasks/${FILE}" ]; then RESOLVED="$ROOT_DIR/.tasks/${FILE}"
    elif [ -f "$ROOT_DIR/.tasks/${FILE}.md" ]; then RESOLVED="$ROOT_DIR/.tasks/${FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/archive/${FILE}" ]; then RESOLVED="$ROOT_DIR/.tasks/archive/${FILE}"
    elif [ -f "$ROOT_DIR/.tasks/archive/${FILE}.md" ]; then RESOLVED="$ROOT_DIR/.tasks/archive/${FILE}.md"
    else
        echo "❌ Error: Task file not found: $FILE"
        exit 1
    fi
    FILE=$RESOLVED

    # 0. Sync human progress back to internal task file
    sync_task_to_internal "$FILE"

    # Extract Phase and Status
    PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$FILE" | head -n 1)
    PHASE=${PHASE:-0}
    STATUS=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$FILE" | head -n 1)
    STATUS=${STATUS:-ideating}

    # 1. Historical Breadcrumb Validation (Anti-Circling)
    # Ensure no ritual logs exist for phases higher than current header phase
    MAX_RITUAL=$(grep -oP '<!-- RITUAL: phase \K\d+' "$FILE" | sort -rn | head -n 1)
    MAX_RITUAL=${MAX_RITUAL:--1}
    
    if [ "$MAX_RITUAL" -gt "$PHASE" ]; then
        echo "🛑 AGENT CIRCLING DETECTED: Header says Phase $PHASE, but ritual logs exist for Phase $MAX_RITUAL."
        exit 1
    fi

    # 2. Phase Forgery Detection (Exclusive Gateway)
    # Header phase must match the latest ritual log (except for phase 0/1 transition edge cases)
    if [ "$PHASE" -gt 0 ] && [ "$MAX_RITUAL" -lt "$PHASE" ]; then
        echo "🛑 MANUAL PHASE FORGERY DETECTED: Header says Phase $PHASE, but the latest ritual log is Phase $MAX_RITUAL."
        echo "   Use 'swt:task phase $PHASE <file>' to transition correctly."
        exit 1
    fi

    # 2.5. Orientation Signature Validation (Continuous Orientation)
    if [ "$PHASE" -gt 0 ]; then
        LATEST_RITUAL_LOG=$(grep "<!-- RITUAL: phase $PHASE" "$FILE" | head -n 1)
        if [[ ! "$LATEST_RITUAL_LOG" =~ "(State Verified)" ]]; then
            echo "🛑 RITUAL DRIFT DETECTED: Phase $PHASE transition is missing the '(State Verified)' signature."
            echo "   PROTOCOL VIOLATION: You MUST consult the State Transition Diagram (AGENTS.md#L122) before transitioning."
            echo "   Fix: Re-run 'swt:task phase $PHASE $FILE' to sign-off on the orientation."
            exit 1
        fi
    fi

    # 3. Sandbox Status
    if [ "$PHASE" -eq 0 ]; then
        echo "🛡️  SANDBOX ACTIVE: Task is in Phase 0 (Ideating)."
        echo "   AGENT PERSONA: Senior Advisor / Co-pilot."
        echo "   RESTRICTION: Source code edits are FORBIDDEN. Graduation required for implementation."
        if ! check_sandbox; then
            exit 1
        fi
    fi

    # 4. Stale Artifact Detection (Dependency Chain)
    if [ "$PHASE" -gt 0 ] && [ "$PHASE" -lt 8 ]; then
        # Find companion spec
        spec=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$FILE" | head -n 1)
        if [ -n "$spec" ] && [ -f "$spec" ]; then
            task_time=$(stat -c %Y "$FILE")
            spec_time=$(stat -c %Y "$spec")
            if [ "$task_time" -gt $((spec_time + 60)) ]; then
                # Perform Substance-Aware Check: Only fail if the core objectives have drifted
                TASK_SUBSTANCE=$(get_substance "$FILE" | md5sum | cut -d' ' -f1)
                SPEC_SUBSTANCE=$(get_substance "$spec" | md5sum | cut -d' ' -f1)
                
                if [ "$TASK_SUBSTANCE" != "$SPEC_SUBSTANCE" ]; then
                    echo "🛑 STALE SPEC DETECTED: Task objectives have drifted from the Spec."
                    echo "   Loop back to re-sync: swt.sh sync-docs $FILE"
                    exit 1
                fi
                # Auto-heal the timestamp if substance is identical
                touch -r "$FILE" "$spec"
                echo "✅ Spec synchronization verified (Substance match)."
            fi
            
            if [ -f "implementation_plan.md" ]; then
                plan_time=$(stat -c %Y "implementation_plan.md")
                if [ "$spec_time" -gt $((plan_time + 60)) ]; then
                    echo "🛑 STALE PLAN DETECTED: Spec is newer than the Implementation Plan."
                    echo "   Loop back to re-sync: swt.sh sync-docs $FILE"
                    exit 1
                fi
            fi
        fi
    fi

    # 5. Verification Audit (Test Forgery & TDD)
    if [ "$PHASE" -gt 0 ]; then
        # Check if TDD is enabled (Global or Task)
        tdd_global=$(grep -q "^## Ritual: TDD" "$ROOT_DIR/AGENTS.md" && echo "true" || echo "false")
        tdd_task=$(grep -q "\*\*TDD\*\*:\s*enabled" "$FILE" && echo "true" || echo "false")
        tdd_enforced="false"
        [ "$tdd_global" == "true" ] || [ "$tdd_task" == "true" ] && tdd_enforced="true"

        # Find latest test logs
        latest_pass=$(grep "<!-- RITUAL: test pass" "$FILE" | head -n 1)
        latest_fail=$(grep "<!-- RITUAL: test fail" "$FILE" | head -n 1)

        # TDD Gate (Phase 5+)
        if [ "$tdd_enforced" == "true" ] && [ "$PHASE" -ge 5 ]; then
            if [ -z "$latest_fail" ]; then
                echo "🛑 TDD VIOLATION: No verified failure log found. Write a failing test first."
                echo "   Run: swt.sh test $FILE --fail"
                exit 1
            fi
        fi

        # Test Forgery / Staleness (Phase 8)
        if [ "$PHASE" -eq 8 ] && [ -n "$latest_pass" ]; then
            # Extract log path from ritual: <!-- RITUAL: test pass @ ... (.tests/...) -->
            log_path=$(echo "$latest_pass" | grep -oP '\(\K.tests/[^)]+')
            if [ ! -f "$log_path" ]; then
                echo "🛑 TEST FORGERY DETECTED: Ritual log exists, but physical log file $log_path is missing."
                exit 1
            fi

            # Check staleness: Latest code edit must be older than the test log
            last_code_edit=$(find "$ROOT_DIR" -maxdepth 5 -type f -not -path '*/.*' -not -path '*/node_modules*' -not -path '*/demo*' -not -path "$ROOT_DIR/task.md" -not -path "$ROOT_DIR/implementation_plan.md" -printf '%T@ %p\n' | sort -rn | head -n 1 | cut -d' ' -f1 | cut -d. -f1)
            last_test_time=$(stat -c %Y "$log_path")

            if [ "$last_code_edit" -gt "$last_test_time" ]; then
                echo "🛑 STALE VERIFICATION: Code has changed since the last verified test pass."
                echo "   Re-run tests: swt.sh test $FILE"
                exit 1
            fi
        fi
    fi

    # 6. Artifact Audit
    if ! validate_artifacts "$PHASE"; then
        exit 1
    fi

    echo "✅ Phase $PHASE validated (Status: $STATUS)."
    exit 0
fi

if [ "$CMD" == "update" ]; then
    FILE=$2
    APPEND_FLAG=$3
    APPEND_TEXT=$4

    if [ -z "$FILE" ]; then
        echo "Usage: swt.sh update <task_file> [--append \"item text\"]"
        exit 1
    fi

    if [ ! -f "$FILE" ]; then
        echo "Error: File $FILE not found."
        exit 1
    fi

    if [ "$APPEND_FLAG" == "--append" ]; then
        if [ -z "$APPEND_TEXT" ]; then
            echo "Error: Must provide item text after --append"
            exit 1
        fi
        # Append to checklist section
        if grep -q "## Checklist" "$FILE"; then
            # Find the line number of "## Checklist" and append after it (before next ## section)
            sed -i "/^## Checklist$/a - [ ] $APPEND_TEXT" "$FILE"
            echo "Appended to checklist: $APPEND_TEXT"
        else
            # No checklist section, create one
            echo -e "\n## Checklist\n- [ ] $APPEND_TEXT" >> "$FILE"
            echo "Created checklist and appended: $APPEND_TEXT"
        fi
        exit 0
    else
        echo "Usage: swt.sh update <task_file> [--append \"item text\"]"
        exit 1
    fi
fi

if [ "$CMD" == "list" ]; then
    shift
    list_tasks "$@"
    exit 0
fi

echo "Unknown command: $CMD"
show_help
exit 1
