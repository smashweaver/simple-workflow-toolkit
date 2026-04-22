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
    echo "  swt.sh list [--open|--archived]  - List tasks (filters: --open, --pending, --archived, etc.)"
    echo "  swt.sh --tidy                    - Move done/abandoned tasks to .tasks/archive/"
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
**Stack**: frontend           <!-- frontend | backend | shared -->
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

    if [ ! -d ".tasks" ]; then
        echo "Error: No .tasks/ directory found. Run 'swt.sh init' first."
        exit 1
    fi

    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")

    SAFE_NAME=$(echo "$ARG" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')
    FILENAME=".tasks/${TIMESTAMP}_${SAFE_NAME}.md"

    cat <<EOF > "$FILENAME"
# Task: $SAFE_NAME
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
What is the core problem or idea being explored?

## Explored Alternatives
What other approaches were considered and why set aside?

## Unresolved Questions
What still needs to be answered before this can become a task?

## Notes

## Commit Reference

EOF

    echo "Created brainstorm task: $FILENAME"
    exit 0
fi

echo "Unknown command: $CMD"
show_help
exit 1
