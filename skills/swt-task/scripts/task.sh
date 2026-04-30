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
    echo "  swt.sh ctx set <file>      - Set active task context (writes task.ctx)"
    echo "  swt.sh ctx clear           - Clear active task context (removes task.ctx)"
    echo "  swt.sh ctx show            - Show current active task context"
    echo "  swt.sh tidy                 - Move done/abandoned tasks to .tasks/archive/"
    echo "  swt.sh abandon <file>      - Abandon task (status: abandoned, no commit hash)"
    echo "  swt.sh test <file> [--fail] - Run tests via swt.json harness and log ritual"
}

function audit_artifacts {
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
    fi
    return 0
}

function list_tasks {
    local filter=$1
    echo -e "Timestamp\tPhase\tStatus\tObjective"
    echo -e "---------\t-----\t------\t---------"
    
    for f in .tasks/*.md; do
        [ -e "$f" ] || continue
        local ts=$(basename "$f" | cut -d'_' -f1)
        local phase=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$f" | head -n 1)
        local status=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$f" | head -n 1)
        local objective=$(grep -oP '^## Objective\s*\n\K.*' "$f" | head -n 1)
        # Fallback for objective if the newline grep fails or Core Concept is used
        if [ -z "$objective" ]; then
            objective=$(sed -n '/^## \(Objective\|Core Concept\)/,/^## /p' "$f" | grep -v '^## ' | grep -v '^$' | head -n 1)
        fi
        # Truncate objective for display
        objective=$(echo "$objective" | cut -c1-60 | sed 's/[[:space:]]*$//')
        [ ${#objective} -ge 60 ] && objective="${objective}..."

        if [ "$filter" == "--open" ]; then
            if [[ "$status" == "done" ]] || [[ "$status" == "abandoned" ]]; then continue; fi
        elif [ "$filter" == "--done" ]; then
            if [[ "$status" != "done" ]]; then continue; fi
        elif [ "$filter" == "--abandoned" ]; then
            if [[ "$status" != "abandoned" ]]; then continue; fi
        fi
        
        printf "%s\t%s\t%s\t%s\n" "$ts" "$phase" "$status" "$objective"
    done
}

function sync_task_to_internal {
    local internal_file=$1
    if [ ! -f "task.md" ] || [ ! -f "$internal_file" ]; then return 0; fi
    
    echo "🔄 Ingesting checklist progress from task.md..."
    # Extract the checklist items from task.md
    grep "^- \[" task.md > .checklist.tmp
    
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

function sync_task_md {
    local file=$1
    if [ ! -f "$file" ]; then return 1; fi
    
    local title=$(grep -m 1 "^# Task:" "$file" | sed 's/# Task: //')
    local template_path="$ROOT_DIR/skills/swt-task/templates/task.md"
    local items=$(sed -n '/## Checklist/,/##/p' "$file" | grep -v "##" | sed '/^$/d')

    if [ -f "$template_path" ]; then
        sed "s/{{Task Name}}/$title/g" "$template_path" > task.md
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
    
    local title=$(grep -m 1 "^# Task:" "$task_file" | sed 's/# Task: //')
    sed "s/{{Task Name}}/$title/g" "$template_path" > "$target_path"
    echo "✨ Scaffolded $target_path from template."
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
    local date_str=$(date +"%Y-%m-%d %H:%M:%S")
    echo "<!-- RITUAL: test $status @ $date_str ($log_file) -->" >> "$file"
    
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
    for ignore in ".digests/" ".tasks/*.tmp" "task.ctx" "implementation_plan.md" "task.md" "commit.diff" "commit.draft" "commit.task"; do
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
    
    cat <<EOF > "$FILENAME"
# Task: $ARG
**Created**: $DATE_STR
**Updated**: —
**Completed**: —
**Status**: pending
**Priority**: medium          <!-- low | medium | high | critical -->
**Type**: feature           <!-- feature | bugfix | refactor | chore | docs -->
**Stack**: shared             <!-- frontend | backend | shared -->
**Phase**: 1                  <!-- current active phase (0–8) -->
**Blocked By**: —             <!-- task filename or n/a -->

## Core Concept
$ARG

## Checklist
- [/] Phase 1: Plan
- [ ] Phase 2: Analyze
- [ ] Phase 3: Risk Assessment
- [ ] Phase 4: Approval
- [ ] Phase 5: Implement
- [ ] Phase 6: Document
- [ ] Phase 7: Test
- [ ] Phase 8: Review & Refine
<!-- RITUAL: phase 1 @ $DATE_STR -->

EOF
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
    if [ -f "$template_path" ]; then
        cp "$template_path" "$FILENAME"
        sed -i "s/{{Task Title}}/$ARG/g" "$FILENAME"
        sed -i "s/{{DATE}}/$DATE_STR/g" "$FILENAME"
        sed -i "s/{{ARG}}/$ARG/g" "$FILENAME"
        # Handle UPLINK_CONTEXT which might contain newlines
        if [ -n "$UPLINK_CONTEXT" ]; then
            echo "$UPLINK_CONTEXT" > .uplink.tmp
            sed -i "/{{UPLINK_CONTEXT}}/{r .uplink.tmp
d}" "$FILENAME"
            rm .uplink.tmp
        else
            sed -i "s/{{UPLINK_CONTEXT}}//g" "$FILENAME"
        fi
    else
        cat <<EOF > "$FILENAME"
# Task: $ARG
**Created**: $DATE_STR
**Updated**: —
**Completed**: —
**Status**: ideating
**Priority**: medium          <!-- low | medium | high | critical -->
**Type**: brainstorm          <!-- feature | bugfix | refactor | chore | docs -->
**Stack**: shared             <!-- frontend | backend | shared -->
**Phase**: 0                  <!-- current active phase (0–8) -->
**Blocked By**: —             <!-- task filename or n/a -->

> **Covers**: [High-level summary of what this brainstorm entails]

## What This Task Covers
1. **[Core Area 1]**
   - [Detail or requirement]
2. **[Core Area 2]**
   - [Detail or requirement]

## Objective
$ARG

## Explored Alternatives
- **Scenario A (Discipline)**: {{Methodology/Rule change only}}
- **Scenario B (Automation)**: {{Helper scripts/Templates}}
- **Scenario C (Enforcement)**: {{Hard gates/Physical blocks}}
- **User Suggestion**: {{Explicitly log user ideas here or mark N/A}}

## Notes
$UPLINK_CONTEXT

## Commit Reference

EOF
    fi

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

    # 1. Update status to pending and phase to 1
    sed -i "s/^\*\*?Status\*\*?:\s*ideating/**Status**: pending/" "$FILE"
    sed -i "s/^\*\*?Phase\*\*?:\s*0/**Phase**: 1/" "$FILE"
    
    # 2. Add Ritual Log
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
    echo "<!-- RITUAL: phase 1 @ $DATE_STR -->" >> "$FILE"

    # 3. Scaffold Spec
    SLUG=$(basename "$FILE" .md | sed 's/^[0-9]*_//')
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    SPEC_FILE=".specs/${TIMESTAMP}_${SLUG}.md"
    
    # Extract content from task file
    # Support standardized headers for CORE extraction
    CORE=$(sed -n '/^## \(What This Task Covers\|Objective\|Core Concept\)/,/^## /p' "$FILE" | grep -v "^## " | grep -v '^$' | head -10)
    ALT=$(sed -n '/^## Explored Alternatives/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    GOALS=$(sed -n '/^## Goals/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    STORIES=$(sed -n '/^## User Stories/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    CRITERIA=$(sed -n '/^## Success Criteria/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    MVP=$(sed -n '/^## MVP Definition/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    NOTES=$(sed -n '/^## Notes/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -20)

    template_path="$ROOT_DIR/skills/swt-task/templates/spec.md"
    if [ -f "$template_path" ]; then
        cp "$template_path" "$SPEC_FILE"
        sed -i "s|{{Task Slug}}|$SLUG|g" "$SPEC_FILE"
        sed -i "s|{{Task File}}|$FILE|g" "$SPEC_FILE"
        
        # Inject multiline content
        inject_section() {
            local tag=$1
            local content=$2
            local file=$3
            if [ -n "$content" ]; then
                echo "$content" > .content.tmp
                sed -i "/$tag/{r .content.tmp
d}" "$file"
                rm .content.tmp
            else
                sed -i "s|$tag|*|g" "$file"
            fi
        }

        inject_section "{{PROBLEM_STATEMENT}}" "$CORE" "$SPEC_FILE"
        inject_section "{{GOALS}}" "$GOALS" "$SPEC_FILE"
        inject_section "{{PROPOSED_SOLUTION}}" "$ALT" "$SPEC_FILE"
        inject_section "{{USER_STORIES}}" "$STORIES" "$SPEC_FILE"
        inject_section "{{SUCCESS_CRITERIA}}" "$CRITERIA" "$SPEC_FILE"
        inject_section "{{MVP}}" "$MVP" "$SPEC_FILE"
        inject_section "{{NOTES}}" "$NOTES" "$SPEC_FILE"

        echo "Graduated $FILE to Phase 1. Spec created from template: $SPEC_FILE"
        xdg-open "$SPEC_FILE" &
        
        # Scaffold implementation plan
        scaffold_artifact "implementation_plan" "$FILE"
        
        # Add Spec link to task header (below Phase)
        sed -i "/^\*\*Phase\*\*:/a **Spec**: $SPEC_FILE" "$FILE"
    else
        echo -e "\n## Verification Checklist\n- [ ] ..." >> "$FILE"
        echo "Graduated $FILE to Phase 1 (Lite path)."
    fi

    sync_task_md "$FILE"
    exit 0
fi

if [ "$CMD" == "sync-downstream" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        echo "Usage: swt.sh sync-downstream <task_file>"
        exit 1
    fi
    
    # 1. Re-run metadata extraction and Spec update
    echo "🔄 Re-syncing Spec from Task..."
    # Reuse graduate logic for metadata injection
    SLUG=$(basename "$FILE" .md | sed 's/^[0-9]*_//')
    SPEC_FILE=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$FILE" | head -n 1)
    
    if [ -z "$SPEC_FILE" ] || [ ! -f "$SPEC_FILE" ]; then
        echo "❌ Spec not found for $FILE. Run 'graduate' first."
        exit 1
    fi

    # Extract current content
    CORE=$(sed -n '/^## \(What This Task Covers\|Objective\|Core Concept\)/,/^## /p' "$FILE" | grep -v "^## " | grep -v '^$' | head -10)
    ALT=$(sed -n '/^## Explored Alternatives/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    GOALS=$(sed -n '/^## Goals/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    STORIES=$(sed -n '/^## User Stories/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    CRITERIA=$(sed -n '/^## Success Criteria/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    MVP=$(sed -n '/^## MVP Definition/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -15)
    NOTES=$(sed -n '/^## Notes/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -20)

    # Re-inject into existing Spec (patching the slots)
    # Since we can't easily "patch" multiline without a fresh scaffold, 
    # we'll re-scaffold from template but preserving the Spec filename.
    template_path="$ROOT_DIR/skills/swt-task/templates/spec.md"
    if [ -f "$template_path" ]; then
        cp "$template_path" "$SPEC_FILE"
        sed -i "s|{{Task Slug}}|$SLUG|g" "$SPEC_FILE"
        sed -i "s|{{Task File}}|$FILE|g" "$SPEC_FILE"
        
        inject_section() {
            local tag=$1; local content=$2; local file=$3
            if [ -n "$content" ]; then
                echo "$content" > .content.tmp
                sed -i "/$tag/{r .content.tmp
d}" "$file"
                rm .content.tmp
            else
                sed -i "s|$tag|*|g" "$file"
            fi
        }

        inject_section "{{PROBLEM_STATEMENT}}" "$CORE" "$SPEC_FILE"
        inject_section "{{GOALS}}" "$GOALS" "$SPEC_FILE"
        inject_section "{{PROPOSED_SOLUTION}}" "$ALT" "$SPEC_FILE"
        inject_section "{{USER_STORIES}}" "$STORIES" "$SPEC_FILE"
        inject_section "{{SUCCESS_CRITERIA}}" "$CRITERIA" "$SPEC_FILE"
        inject_section "{{MVP}}" "$MVP" "$SPEC_FILE"
        inject_section "{{NOTES}}" "$NOTES" "$SPEC_FILE"
        echo "✅ Spec updated: $SPEC_FILE"
    fi

    # 2. Re-sync Implementation Plan
    echo "🔄 Re-syncing Implementation Plan..."
    scaffold_artifact "implementation_plan" "$FILE"
    
    # 3. Re-sync task.md
    sync_task_md "$FILE"
    
    echo "✨ Downstream artifacts synchronized. Review and Approval (Gate 2) reset."
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
    sed -i "s|^\*\*?Completed\*\*?:\s*—|**Completed**: $DATE_STR|" "$FILE"
    sed -i "s/^\*\*Status\*\*:.*/**Status**: done/" "$FILE"
    sed -i "s/^\*\*Completed\*\*:.*/**Completed**: $DATE_STR/" "$FILE"
    sed -i "s/- \[[ /]\] Phase 8/- [x] Phase 8/" "$FILE"
    
    # Insert commit hash into ## Commit Reference section
    if grep -q "## Commit Reference" "$FILE"; then
        sed -i "/^## Commit Reference$/a $HASH" "$FILE"
    else
        echo -e "\n## Commit Reference\n$HASH" >> "$FILE"
    fi
    
    # Move to archive
    mkdir -p .tasks/archive
    mv "$FILE" .tasks/archive/
    rm -f implementation_plan.md task.md
    echo "✅ Task closed: $FILE (Commit: $HASH)"
    exit 0
fi

if [ "$CMD" == "ctx" ]; then
    SUB=$2
    VAL=$3
    case $SUB in
        set)
            echo "$VAL" > task.ctx
            echo "Set active task context: $VAL"
            ;;
        clear)
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
            echo "Usage: swt.sh ctx [set <file>|clear|show]"
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
    sed -i "s/^\*\*Status\*\*:.*/**Status**: abandoned/" "$FILE"
    sed -i "s/^\*\*Completed\*\*:.*/**Completed**: $DATE_STR/" "$FILE"
    
    mkdir -p .tasks/archive
    mv "$FILE" .tasks/archive/
    rm -f implementation_plan.md task.md
    echo "Task abandoned: $FILE"
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

    # 1. Update Phase header
    sed -i -E "s/^\*\*?Phase\*\*?:\s*[0-8]/**Phase**: $PHASE_NUM/" "$FILE"

    # 2. Update Checklist (mark current phase as in-progress [/])
    # First, reset any other in-progress phases if appropriate (optional)
    sed -i "s/- \[[ /]\] Phase $PHASE_NUM/- [\/] Phase $PHASE_NUM/" "$FILE"

    # 3. Add Ritual Log immediately after the Checklist
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
    RITUAL_LOG="<!-- RITUAL: phase $PHASE_NUM @ $DATE_STR -->"
    
    awk -v rlog="$RITUAL_LOG" '
        /^- \[[ x\/]\] Phase / || /^- \[[ x\/]\] .+/ || /^<!-- RITUAL: phase/ { last_check = NR }
        { lines[NR] = $0 }
        END {
            if (!last_check) last_check = NR
            for (i=1; i<=NR; i++) {
                print lines[i]
                if (i == last_check) print rlog
            }
        }' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"



    # 4. Ephemeral Artifact Audit (Scenario C: Enforcement)
    if ! audit_artifacts "$PHASE_NUM"; then
        exit 1
    fi

    echo "Transitioned $FILE to Phase $PHASE_NUM. Ritual logged."
    sync_task_md "$FILE"
    exit 0
fi

if [ "$CMD" == "validate" ]; then
    FILE=$2
    if [ -z "$FILE" ]; then
        FILE=$(cat "$ROOT_DIR/task.ctx" 2>/dev/null)
    fi
    if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
        echo "❌ No active task context. Use 'swt:task mount <file>'."
        exit 1
    fi

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

    # 3. Sandbox Status
    if [ "$PHASE" -eq 0 ]; then
        echo "🛡️  SANDBOX ACTIVE: Task is in Phase 0 (Ideating)."
        echo "   AGENT PERSONA: Senior Advisor / Co-pilot."
        echo "   RESTRICTION: Source code edits are FORBIDDEN. Graduation required for implementation."
    fi

    # 4. Stale Artifact Detection (Dependency Chain)
    if [ "$PHASE" -gt 0 ]; then
        # Find companion spec
        spec=$(grep -oP '^\*\*?Spec\*\*?:\s*\K\S+' "$FILE" | head -n 1)
        if [ -n "$spec" ] && [ -f "$spec" ]; then
            task_time=$(stat -c %Y "$FILE")
            spec_time=$(stat -c %Y "$spec")
            if [ "$task_time" -gt "$spec_time" ]; then
                echo "🛑 STALE SPEC DETECTED: Task objectives are newer than the Spec."
                echo "   Loop back to re-sync: swt.sh sync-downstream $FILE"
                exit 1
            fi
            
            if [ -f "implementation_plan.md" ]; then
                plan_time=$(stat -c %Y "implementation_plan.md")
                if [ "$spec_time" -gt "$plan_time" ]; then
                    echo "🛑 STALE PLAN DETECTED: Spec is newer than the Implementation Plan."
                    echo "   Loop back to re-sync: swt.sh sync-downstream $FILE"
                    exit 1
                fi
            fi
        fi
    fi

    # 5. Verification Audit (Test Forgery & TDD)
    if [ "$PHASE" -gt 0 ]; then
        # Check if TDD is enabled (Global or Task)
        tdd_global=$(grep -q "## Ritual: TDD" "$ROOT_DIR/AGENTS.md" && echo "true" || echo "false")
        tdd_task=$(grep -q "\*\*TDD\*\*:\s*enabled" "$FILE" && echo "true" || echo "false")
        tdd_enforced="false"
        [ "$tdd_global" == "true" ] || [ "$tdd_task" == "true" ] && tdd_enforced="true"

        # Find latest test logs
        latest_pass=$(grep "<!-- RITUAL: test pass" "$FILE" | tail -n 1)
        latest_fail=$(grep "<!-- RITUAL: test fail" "$FILE" | tail -n 1)

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
            last_code_edit=$(find "$ROOT_DIR" -maxdepth 2 -not -path '*/.*' -not -path '*/node_modules*' -not -path '*/demo*' -not -path "$ROOT_DIR/task.md" -not -path "$ROOT_DIR/implementation_plan.md" -printf '%T@ %p\n' | sort -rn | head -n 1 | cut -d' ' -f1 | cut -d. -f1)
            last_test_time=$(stat -c %Y "$log_path")

            if [ "$last_code_edit" -gt "$last_test_time" ]; then
                echo "🛑 STALE VERIFICATION: Code has changed since the last verified test pass."
                echo "   Re-run tests: swt.sh test $FILE"
                exit 1
            fi
        fi
    fi

    # 6. Artifact Audit
    if ! audit_artifacts "$PHASE"; then
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
    list_tasks "$2"
    exit 0
fi

echo "Unknown command: $CMD"
show_help
exit 1
