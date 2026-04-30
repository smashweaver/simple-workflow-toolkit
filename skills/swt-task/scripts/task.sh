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
    echo "  swt.sh scaffold <type> <file> [--force] - Generate Plan or Walkthrough"
    echo "  swt.sh phase <N> <file>    - Transition task to Phase N"
    echo "  swt.sh close <file> <hash> - Finalize task (status: done, checklist: complete)"
    echo "  swt.sh ctx set <file>      - Set active task context (writes task.ctx)"
    echo "  swt.sh ctx clear           - Clear active task context (removes task.ctx)"
    echo "  swt.sh ctx show            - Show current active task context"
    echo "  swt.sh tidy                 - Move done/abandoned tasks to .tasks/archive/"
    echo "  swt.sh abandon <file>      - Abandon task (status: abandoned, no commit hash)"
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
    if [ "$phase" -ge 8 ]; then
        if [ ! -f "walkthrough.md" ]; then
            check_phantom "walkthrough.md"
            echo "🛑 PROTOCOL VIOLATION: Phase $phase requires walkthrough.md at the project root."
            return 1
        fi
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
    for ignore in ".digests/" ".tasks/*.tmp" "task.ctx" "implementation_plan.md" "task.md" "walkthrough.md" "commit.diff" "commit.draft" "commit.task"; do
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
        inject_section "{{PROPOSED_SOLUTION}}" "$ALT" "$SPEC_FILE"
        inject_section "{{USER_STORIES}}" "$STORIES" "$SPEC_FILE"
        inject_section "{{SUCCESS_CRITERIA}}" "$CRITERIA" "$SPEC_FILE"
        inject_section "{{MVP}}" "$MVP" "$SPEC_FILE"
        inject_section "{{NOTES}}" "$NOTES" "$SPEC_FILE"

        echo "Graduated $FILE to Phase 1. Spec created from template: $SPEC_FILE"
        
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

if [ "$CMD" == "close" ]; then
    FILE=$2
    HASH=$3
    if [ -z "$FILE" ] || [ -z "$HASH" ]; then
        echo "Usage: swt.sh close <task_file> <commit_hash>"
        exit 1
    fi
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
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

    if [ "$PHASE_NUM" -eq 8 ]; then
        scaffold_artifact "walkthrough" "$FILE"
    fi

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
        echo "Usage: swt.sh validate <task_file>"
        exit 1
    fi
    if [ ! -f "$FILE" ]; then
        echo "Error: File $FILE not found."
        exit 1
    fi

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

    # 4. Artifact Audit
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

echo "Unknown command: $CMD"
show_help
exit 1
