#!/bin/bash

# Universal AI Task Manager (taskmgr)
# Facilitates semantic agent interaction with a local .tasks/ directory

set -e

CMD=$1
ARG=$2

function show_help {
    echo "Usage:"
    echo "  taskmgr init         - Initialize .tasks/ directory and update .gitignore"
    echo "  taskmgr new \"Name\"   - Create a new timestamped task file"
    echo "  taskmgr list         - List existing tasks"
}

if [ -z "$CMD" ]; then
    show_help
    exit 1
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
        echo "No .tasks/ directory found. Run 'taskmgr init' first."
        exit 1
    fi
    files=$(ls .tasks/*.md 2>/dev/null | sort || true)
    if [ -z "$files" ]; then
         echo "No tasks found in .tasks/"
    else
         echo "Tasks found:"
         for f in $files; do
             echo " - $f"
         done
    fi
    exit 0
fi

if [ "$CMD" == "new" ]; then
    if [ -z "$ARG" ]; then
        echo "Error: Must provide a task description."
        echo "Usage: taskmgr new \"Description\""
        exit 1
    fi

    if [ ! -d ".tasks" ]; then
        echo "Error: No .tasks/ directory found. Run 'taskmgr init' first."
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

echo "Unknown command: $CMD"
show_help
exit 1
