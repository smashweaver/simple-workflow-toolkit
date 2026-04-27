#!/bin/bash

# Universal AI Task Manager (swt.sh)
# Facilitates semantic agent interaction with a local .tasks/ directory

set -e

CMD=$1
ARG=$2

function show_help {
    echo "Usage:"
    echo "  swt.sh init              - Initialize .tasks/ directory and update .gitignore"
    echo "  swt.sh new \"Final Feature Name\"  - Create a new timestamped task file"
    echo "  swt.sh brainstorm \"Topic\"        - Create a Phase 0 ideation task"
    echo "  swt.sh graduate <task_file>      - Transition Phase 0 to Phase 1"
    echo "  swt.sh phase <N> <file>    - Transition task to Phase N"
    echo "  swt.sh close <file> <hash> - Finalize task (status: done, checklist: complete)"
    echo "  swt.sh --tidy              - Move done/abandoned tasks to .tasks/archive/"
}

if [ -z "$CMD" ]; then
    show_help
    exit 1
fi

# Normalize flags to commands
if [ "$CMD" == "--tidy" ]; then
    CMD="tidy"
fi

if [ "$CMD" == "init" ]; then
    mkdir -p .tasks
    echo ".tasks/ initialized."

    if [ -f .gitignore ]; then
        if ! grep -q "^\.tasks/$" .gitignore && ! grep -q "^\.tasks$" .gitignore; then
            echo "" >> .gitignore
            echo ".tasks/" >> .gitignore
            echo ".tasks/ added to .gitignore."
        else
            echo ".tasks/ already in .gitignore."
        fi
    else
        echo ".tasks/" > .gitignore
        echo "Created .gitignore and added .tasks/."
    fi
    exit 0
fi

if [ "$CMD" == "list" ]; then
    if [ ! -d ".tasks" ]; then
        echo "No .tasks/ directory found. Run 'swt.sh init' first."
        exit 1
    fi

    FILTER=$2
    # Strip -- prefix if present for standard CLI feel
    FILTER=${FILTER#--}
    
    if [ "$FILTER" == "archived" ]; then
        files=$(ls .tasks/archive/*.md 2>/dev/null | sort || true)
        if [ -z "$files" ]; then
             echo "No archived tasks found in .tasks/archive/"
             exit 0
        fi
    else
        files=$(ls .tasks/*.md 2>/dev/null | sort || true)
    fi
    
    if [ -z "$files" ]; then
         echo "No tasks found in .tasks/"
         exit 0
    fi

    echo "Tasks found ($([ -n "$FILTER" ] && echo "$FILTER" || echo "all")):"
    for f in $files; do
        # Extract status (handles cases with comments or trailing spaces)
        STATUS=$(grep -oP '\*\*Status\*\*:\s*\K\S+' "$f" | head -n 1)
        
        SHOW=true
        if [ "$FILTER" == "open" ]; then
            if [[ "$STATUS" == "done" || "$STATUS" == "abandoned" ]]; then
                SHOW=false
            fi
        elif [ -n "$FILTER" ] && [ "$FILTER" != "all" ] && [ "$FILTER" != "archived" ]; then
            if [ "$STATUS" != "$FILTER" ]; then
                SHOW=false
            fi
        fi

        if [ "$SHOW" == "true" ]; then
             echo " - [$STATUS] $f"
        fi
    done
    exit 0
fi

if [ "$CMD" == "tidy" ]; then
    if [ ! -d ".tasks" ]; then
        echo "Error: No .tasks/ directory found."
        exit 1
    fi

    mkdir -p .tasks/archive
    
    count=0
    files=$(ls .tasks/*.md 2>/dev/null || true)
    for f in $files; do
        STATUS=$(grep -oP '\*\*Status\*\*:\s*\K\S+' "$f" | head -n 1)
        if [[ "$STATUS" == "done" || "$STATUS" == "abandoned" ]]; then
            mv "$f" .tasks/archive/
            echo "Archived: $f"
            count=$((count + 1))
        fi
    done
    
    echo "Tidy complete. Moved $count tasks to .tasks/archive/."
    exit 0
fi

if [ "$CMD" == "validate" ]; then
    if [ -z "$ARG" ]; then
        echo "Error: Must provide a task file to validate."
        exit 1
    fi
    FILE=$ARG
    if [ ! -f "$FILE" ]; then
        echo "Error: File $FILE not found."
        exit 1
    fi

    # 1. Check for unpopulated placeholders (Scenario A: Discipline)
    if grep -qE "^- .*: .*\{\{Methodology|^- .*: .*\{\{Helper|^- .*: .*\{\{Hard gates" "$FILE"; then
        echo "⚠️ PROTOCOL WARNING: Task contains unpopulated placeholders. It is not 'Born Complete'."
        echo "   You MUST populate all sections before proceeding."
    fi

    # 2. Get current phase
    PHASE=$(grep -oP '\*\*Phase\*\*:\s*\K\d+' "$FILE" | head -n 1)

    if [ -z "$PHASE" ]; then
        echo "Error: Could not determine current Phase from $FILE."
        exit 1
    fi

    # Phase 0 (Ideating) doesn't always have a checklist
    if [ "$PHASE" -eq 0 ]; then
        STATUS=$(grep -oP '\*\*Status\*\*:\s*\K\S+' "$FILE" | head -n 1)
        if [ "$STATUS" == "ideating" ]; then
            echo "✅ Phase 0 validated (Status: ideating)."
            exit 0
        else
            echo "🛑 PROTOCOL VIOLATION: Phase 0 task must have Status: ideating."
            exit 1
        fi
    fi

    # 2. Ritual Log Validation (Exclusive Gateway check)
    # Check if the last ritual log matches the current phase
    LAST_RITUAL=$(grep -oP '<!-- RITUAL: phase \K\d+' "$FILE" | tail -n 1 || echo "none")
    
    if [ "$LAST_RITUAL" != "$PHASE" ]; then
        echo "🛑 PROTOCOL VIOLATION: Phase header ($PHASE) does not match Ritual Log ($LAST_RITUAL)."
        echo "   Manual edits to the Phase header are FORBIDDEN."
        echo "   You MUST use 'swt:task phase $PHASE' to transition correctly."
        exit 1
    fi

    # 4. Check the checklist for that phase
    CHECK=$(grep -iP "\- \[[x/]\] Phase $PHASE" "$FILE" || true)

    if [ -z "$CHECK" ]; then
        echo "🛑 PROTOCOL VIOLATION: Phase $PHASE is not marked as in-progress [/] or complete [x] in $FILE."
        exit 1
    fi

    echo "✅ Task state validated: Phase $PHASE is correctly synchronized with Ritual Log."
    exit 0
fi

if [ "$CMD" == "new" ]; then
    if [ -z "$ARG" ]; then
        echo "Error: Must provide a task description (e.g. final feature name)."
        echo "Usage: swt.sh new \"Final Feature Name\""
        exit 1
    fi

    if [ ! -d ".tasks" ]; then
        echo "Error: No .tasks/ directory found. Run 'swt.sh init' first."
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
**Type**: feature             <!-- feature | bugfix | refactor | chore | docs -->
**Stack**: shared             <!-- frontend | backend | shared -->
**Phase**: 1                  <!-- current active phase (1–8) -->
**Blocked By**: —             <!-- task filename or n/a -->

## Objective
Provide a short description of what this task achieves.

## Checklist
- [ ] Phase 1: Plan
- [ ] Phase 2: Analyze
- [ ] Phase 3: Risk Assessment
- [ ] Phase 4: Approval
- [ ] Phase 5: Implement
- [ ] Phase 6: Document
- [ ] Phase 7: Test
- [ ] Phase 8: Iterative Development

## Notes

## Risks

## Commit Reference

EOF

    echo "Created new task: $FILENAME"
    exit 0
fi

if [ "$CMD" == "brainstorm" ]; then
    if [ -z "$ARG" ]; then
        echo "Error: Must provide a topic (e.g. swt.sh brainstorm \"Remote install from GitHub\")"
        exit 1
    fi

    UPLINK=false
    if [ "$3" == "--uplink" ] || [ "$4" == "--uplink" ]; then
        UPLINK=true
    fi

    TASK_ROOT=".tasks"
    UPLINK_CONTEXT=""

    if [ "$UPLINK" == "true" ]; then
        if [ -z "$SWT_HOME" ]; then
            echo "Error: --uplink specified but SWT_HOME is not set."
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
        C_TASK=$(ls -t .tasks/*.md 2>/dev/null | xargs grep -l '\*\*Status\*\*: \(pending\|ideating\|in-progress\)' | head -n 1 || echo "none")
        C_PHASE="unknown"
        if [ "$C_TASK" != "none" ]; then
            C_PHASE=$(grep -oP '\*\*Phase\*\*:\s*\K\d+' "$C_TASK" | head -n 1)
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

## Core Concept
$ARG

## Explored Alternatives
- **Scenario A (Discipline)**: {{Methodology/Rule change only}}
- **Scenario B (Automation)**: {{Helper scripts/Templates}}
- **Scenario C (Enforcement)**: {{Hard gates/Physical blocks}}

## Unresolved Questions
What still needs to be answered before this can become a task?

## Notes
$UPLINK_CONTEXT

## Commit Reference

EOF

    echo "Created brainstorm task: $FILENAME"
    exit 0
fi

if [ "$CMD" == "graduate" ]; then
    if [ -z "$ARG" ]; then
        echo "Error: Must provide a task file to graduate."
        exit 1
    fi
    FILE=$ARG
    if [ ! -f "$FILE" ]; then
        echo "Error: File $FILE not found."
        exit 1
    fi

    PHASE=$(grep -oP '\*\*Phase\*\*:\s*\K\d+' "$FILE" | head -n 1)
    if [ "$PHASE" -ne 0 ]; then
        echo "Error: Task is already in Phase $PHASE. Only Phase 0 tasks can be graduated."
        exit 1
    fi

    TYPE=$(grep -oP '\*\*Type\*\*:\s*\K\S+' "$FILE" | head -n 1)
    
    # Update Status and Phase
    sed -i "s/^\*\*Status\*\*:\s*ideating/**Status**: pending/" "$FILE"
    sed -i "s/^\*\*Phase\*\*:\s*0/**Phase**: 1/" "$FILE"
    
    # Add implementation checklist if missing
    if ! grep -q "## Checklist" "$FILE"; then
        cat <<EOF >> "$FILE"

## Checklist
- [/] Phase 1: Plan
- [ ] Phase 2: Analyze
- [ ] Phase 3: Risk Assessment
- [ ] Phase 4: Approval
- [ ] Phase 5: Implement
- [ ] Phase 6: Document
- [ ] Phase 7: Test
- [ ] Phase 8: Review & Refine
EOF
    fi

    # Add Ritual Log (initial)
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
    echo "<!-- RITUAL: phase 1 @ $DATE_STR -->" >> "$FILE"

    if [[ "$TYPE" == "feature" || "$TYPE" == "brainstorm" ]]; then
        mkdir -p .specs
        TIMESTAMP=$(date +"%Y%m%d%H%M%S")
        BASENAME=$(basename "$FILE")
        SLUG=${BASENAME#*_}
        SLUG=${SLUG%.md}
        SPEC_FILE=".specs/${TIMESTAMP}_${SLUG}.md"
        
        cat <<EOF > "$SPEC_FILE"
# Spec: $SLUG
**Version**: 0.1
**Status**: draft
**Linked Task**: $FILE

## 1. Problem Statement
(required)

## 5. User Stories
- [ ] US-001: ...

## 12. MVP Definition
- [ ] ...
EOF
        # Add Spec link to task header (below Phase)
        sed -i "/^\*\*Phase\*\*:/a **Spec**: $SPEC_FILE" "$FILE"
        echo "Graduated $FILE to Phase 1. Spec created: $SPEC_FILE"
    else
        echo -e "\n## Verification Checklist\n- [ ] ..." >> "$FILE"
        echo "Graduated $FILE to Phase 1 (Lite path)."
    fi
    exit 0
fi

if [ "$CMD" == "close" ]; then
    FILE="$2"
    HASH="$3"
    if [ ! -f "$FILE" ]; then
        echo "❌ Error: Task file not found: $FILE"
        exit 1
    fi
    if [ -z "$HASH" ]; then
        echo "❌ Error: Commit hash is required for closure."
        exit 1
    fi

    DATE_LOG=$(date +"%Y-%m-%d %H:%M:%S")

    # 1. Update Headers
    sed -i "s/^\*\*Status\*\*:.*/\*\*Status\*\*: done/" "$FILE"
    sed -i "s/^\*\*Completed\*\*:.*/\*\*Completed\*\*: $DATE_LOG/" "$FILE"
    sed -i "s/^\*\*Updated\*\*:.*/\*\*Updated\*\*: $DATE_LOG/" "$FILE"

    # 2. Complete Checklist
    # Matches bulleted checklist items: - [ ] or - [/]
    sed -i 's/^- \[[ /]\]/- [x]/g' "$FILE"

    # 3. Add Commit Reference
    if grep -q "## Commit Reference" "$FILE"; then
        # Insert hash after the header
        sed -i "/## Commit Reference/a $HASH" "$FILE"
    else
        echo -e "\n## Commit Reference\n$HASH" >> "$FILE"
    fi

    echo "✅ Task closed: $FILE (Commit: $HASH)"
    echo "   Status: done | Checklist: fully completed"
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
    sed -i "s/^\*\*Phase\*\*:\s*[0-8]/**Phase**: $PHASE_NUM/" "$FILE"

    # 2. Update Checklist (mark current phase as in-progress [/])
    # First, reset any other in-progress phases if appropriate (optional)
    sed -i "s/- \[[ /]\] Phase $PHASE_NUM/- [\/] Phase $PHASE_NUM/" "$FILE"

    # 3. Add Ritual Log
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
    echo "<!-- RITUAL: phase $PHASE_NUM @ $DATE_STR -->" >> "$FILE"

    echo "Transitioned $FILE to Phase $PHASE_NUM. Ritual logged."
    exit 0
fi

echo "Unknown command: $CMD"
show_help
exit 1
