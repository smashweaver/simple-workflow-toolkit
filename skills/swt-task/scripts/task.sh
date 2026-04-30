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
    echo "  swt.sh ctx set <file>      - Set active task context (writes task.ctx)"
    echo "  swt.sh ctx clear           - Clear active task context (removes task.ctx)"
    echo "  swt.sh ctx show            - Show current active task context"
    echo "  swt.sh tidy                 - Move done/abandoned tasks to .tasks/archive/"
    echo "  swt.sh abandon <file>      - Abandon task (status: abandoned, no commit hash)"
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

    init_gitignore_pattern() {
        local pattern="$1"
        if ! grep -q "^${pattern}$" .gitignore && ! grep -q "^${pattern%/}$" .gitignore; then
            echo "" >> .gitignore
            echo "$pattern" >> .gitignore
            echo "$pattern added to .gitignore."
        else
            echo "$pattern already in .gitignore."
        fi
    }

    if [ -f .gitignore ]; then
        init_gitignore_pattern ".tasks/"
        init_gitignore_pattern ".specs/"
        init_gitignore_pattern ".digests/"
        init_gitignore_pattern "task.ctx"
        init_gitignore_pattern "implementation_plan.md"
        init_gitignore_pattern "walkthrough.md"
        init_gitignore_pattern "task.md"
    else
        cat > .gitignore <<'EOF'
# Task tracking (per-project, not committed)
.tasks/

# Specifications
.specs/

# Session digests
.digests/

# Task context (per-project, not committed)
task.ctx

# Planning Mode root artifacts
implementation_plan.md
walkthrough.md
task.md
EOF
        echo "Created .gitignore with all SWT patterns."
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

    # 1. Check for unpopulated placeholders (Scenario C: Enforcement)
    # Pattern: double braces starting with a letter
    if grep -qE "\{\{[A-Za-z][^}]*\}\}" "$FILE"; then
        echo "🛑 PROTOCOL VIOLATION: Task contains unpopulated placeholders: "
        grep -nE "\{\{[A-Za-z][^}]*\}\}" "$FILE"
        echo "   You are FORBIDDEN from proceeding until these are populated."
        exit 1
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

    # 3. Ritual Log Validation (Exclusive Gateway check)
    # Check if the last ritual log matches the current phase
    LAST_RITUAL=$(grep -oP '<!-- RITUAL: phase \K\d+' "$FILE" | tail -n 1 || echo "none")
    
    if [ "$LAST_RITUAL" != "$PHASE" ]; then
        echo "🛑 PROTOCOL VIOLATION: Phase header ($PHASE) does not match Ritual Log ($LAST_RITUAL)."
        echo "   Manual edits to the Phase header are FORBIDDEN."
        echo "   You MUST use 'swt:task phase $PHASE' to transition correctly."
        exit 1
    fi

    # 4. Anti-Circling Checklist Validation
    # Ensure all previous phases are complete [x] and current phase is active [/] or [x]
    for (( i=1; i<=$PHASE; i++ )); do
        if [ "$i" -eq "$PHASE" ]; then
            CHECK=$(grep -iP "^\s*\- \[[xX/]\] Phase $i" "$FILE" || true)
            if [ -z "$CHECK" ]; then
                echo "🛑 PROTOCOL VIOLATION: Phase $i is not marked as in-progress [/] or complete [x] in $FILE."
                exit 1
            fi
        else
            CHECK=$(grep -iP "^\s*\- \[[xX]\] Phase $i" "$FILE" || true)
            if [ -z "$CHECK" ]; then
                echo "🛑 PROTOCOL VIOLATION (Anti-Circling): Phase $PHASE is active, but Phase $i is not marked complete [x]."
                echo "   You cannot skip phases or leave them incomplete. Ensure previous phases are [x]."
                exit 1
            fi
        fi
    done

    echo "✅ Task state validated: Phase $PHASE is correctly synchronized with Ritual Log and Checklist History."
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

    # Smart mount: auto-mount only if no task is currently mounted
    if [ ! -f "task.ctx" ]; then
        echo "$FILENAME" > task.ctx
        echo "   Auto-mounted as active task (task.ctx was empty)"
    fi

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

> **Covers**: [High-level summary of what this brainstorm entails]

1. **[Core Area 1]**
   - [Detail or requirement]
2. **[Core Area 2]**
   - [Detail or requirement]

> **This task document structure is the template for future brainstorming tasks.** Use the numbered list above as the summary section.

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
- **User Suggestion**: {{Explicitly log user ideas here or mark N/A}}

## Unresolved Questions
What still needs to be answered before this can become a task?

## Notes
$UPLINK_CONTEXT

## Commit Reference

EOF

    echo "Created brainstorm task: $FILENAME"

    # Smart mount: auto-mount only if no task is currently mounted
    if [ ! -f "task.ctx" ]; then
        echo "$FILENAME" > task.ctx
        echo "   Auto-mounted as active task (task.ctx was empty)"
    fi

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
        # Ensure .specs/ is in .gitignore
        if [ -f .gitignore ] && ! grep -q "^\.specs/$" .gitignore && ! grep -q "^\.specs$" .gitignore; then
            echo "" >> .gitignore
            echo ".specs/" >> .gitignore
        fi
        mkdir -p .specs
        TIMESTAMP=$(date +"%Y%m%d%H%M%S")
        BASENAME=$(basename "$FILE")
        SLUG=${BASENAME#*_}
        SLUG=${SLUG%.md}
        SPEC_FILE=".specs/${TIMESTAMP}_${SLUG}.md"
        
        # Extract content from task file
        CORE=$(sed -n '/^## Core Concept/,/^## /p' "$FILE" | grep -v "^## " | grep -v '^$' | head -5)
        ALT=$(sed -n '/^## Explored Alternatives/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -10)
        NOTES=$(sed -n '/^## Notes/,/^## /p' "$FILE" | grep -v '^## ' | grep -v '^$' | head -20)

        cat <<EOF > "$SPEC_FILE"
# Spec: $SLUG
**Version**: 0.1
**Status**: draft
**Linked Task**: $FILE

## 1. Problem Statement

$(echo "$CORE" | sed 's/^/* /')

## 2. Goals

- Route all work through the SWT task lifecycle (create → graduate → implement)
- Persist active task context across sessions and agent switches
- Guide users to create brainstorm tasks when new topics arise mid-session
- Prevent coding outside of swt:flow phases

## 3. Proposed Solution

$(echo "$ALT" | sed 's/^/- /')

Introduce \`task.ctx\` — a single-line file in the project root containing the active task filename. Back it with:
- \`swt.sh ctx set/clear/show\` commands in task.sh
- \`flow.sh\` — active engine with open/check/status commands
- Updates to swt:status, swt:digest, swt:think, swt:flow, and AGENTS.md

## 4. User Stories

- [ ] US-001: As an agent, I can read \`task.ctx\` at session start and immediately know what task is active
- [ ] US-002: As a user, when I raise a new issue mid-session, the agent asks if I want a brainstorm task created
- [ ] US-003: As an agent, I refuse to code outside swt:flow phases — I guide the user to create a task first
- [ ] US-004: As a user switching agents, the new agent picks up the same task context automatically
- [ ] US-005: As an agent, when a task is closed, I automatically clear \`task.ctx\`

## 5. Non-Functional Requirements

- \`task.ctx\` must be gitignored (not committed to repo)
- All context reads/writes must handle stale references (task file deleted/moved)
- Scripts must work from subdirectories (workspace root detection via AGENTS.md/.git)

## 6. Implementation Plan

$(echo "$NOTES" | grep -oP '^\*\*\s*\K.*' | head -8 | sed 's/^/* /')

## 7. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| \`task.ctx\` points to deleted task | Validate file existence; clear stale ctx automatically |
| Stale context after manual edits | Only \`task.sh\` modifies \`task.ctx\`; document this rule |
| Multiple agents write simultaneously | Single line file; filesystem write is atomic |

## 8. Success Criteria

- [ ] \`swt.sh ctx set <file>\` creates \`task.ctx\`; \`swt.sh ctx show\` displays it
- [ ] \`flow.sh open\` reads \`task.ctx\` and displays task metadata
- [ ] \`flow.sh check\` exits non-zero when no/invalid context exists
- [ ] \`status.sh\` shows active task context at top of output
- [ ] \`task.sh close\` auto-clears \`task.ctx\` when it points to closed task
- [ ] \`task.ctx\` is gitignored and survives across sessions

## 9. Out of Scope

- Keyword-based task surfacing in conversation (too many false positives)
- Auto-activation of related tasks without user confirmation
- Complex conflict resolution for simultaneous agent writes

## 10. Open Questions

- Should \`task.ctx\` store additional metadata (phase, last updated) or stay single-line?
- What happens when user has multiple projects — one \`task.ctx\` per project root (current answer: yes)

## 11. References

- Task file: \`$FILE\`
- Skills: \`swt:flow\`, \`swt:task\`, \`swt:status\`, \`swt:think\`, \`swt:digest\`
- AGENTS.md Section 7: Session Start & Restoration

## 12. MVP Definition

- [ ] \`task.ctx\` file tracks active task filename in project root
- [ ] \`swt.sh ctx set/clear/show\` manages context lifecycle
- [ ] \`flow.sh open/check/status\` provides active task engine
- [ ] \`status.sh\` displays active context at top of output
- [ ] \`swt:think\` documents Task-First Workflow rule
- [ ] \`digest.sh\` includes active context in output
- [ ] \`swt-flow/SKILL.md\` updated with task.ctx check
- [ ] \`AGENTS.md\` Section 7 updated with task.ctx step
- [ ] \`.gitignore\` includes \`task.ctx\`
- [ ] User confirms MVP works as expected
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
    echo "   (Note: task.ctx is preserved until manually cleared or a commit finalizes.)"
    exit 0
fi

if [ "$CMD" == "abandon" ]; then
    FILE="$2"
    if [ -z "$FILE" ]; then
        echo "Error: Must provide a task file to abandon."
        exit 1
    fi
    if [ ! -f "$FILE" ]; then
        echo "Error: Task file not found: $FILE"
        exit 1
    fi

    DATE_LOG=$(date +"%Y-%m-%d %H:%M:%S")

    # 1. Update Headers (status=abandoned, set Completed)
    sed -i "s/^\*\*Status\*\*:.*/\*\*Status\*\*: abandoned/" "$FILE"
    sed -i "s/^\*\*Completed\*\*:.*/\*\*Completed\*\*: $DATE_LOG/" "$FILE"
    sed -i "s/^\*\*Updated\*\*:.*/\*\*Updated\*\*: $DATE_LOG/" "$FILE"

    # 2. Leave Checklist AS-IS (do NOT check off items)

    echo "Abandoned task: $FILE (Status: abandoned, Checklist unchanged)"
    echo "   (Note: task.ctx is preserved until manually cleared.)"

    exit 0
fi

if [ "$CMD" == "ctx" ]; then
    CTX_CMD=$2
    CTX_FILE=$3

    case "$CTX_CMD" in
        set)
            if [ -z "$CTX_FILE" ]; then
                echo "Usage: swt.sh ctx set <task_file>"
                exit 1
            fi
            # Resolve: accept bare name, relative path, or full path
            if [ -f "$CTX_FILE" ]; then
                RESOLVED=$(realpath --relative-to=. "$CTX_FILE" 2>/dev/null || echo "$CTX_FILE")
            elif [ -f ".tasks/${CTX_FILE}.md" ]; then
                RESOLVED=".tasks/${CTX_FILE}.md"
            elif [ -f ".tasks/${CTX_FILE}" ]; then
                RESOLVED=".tasks/${CTX_FILE}"
            elif [ -f ".tasks/archive/${CTX_FILE}.md" ]; then
                RESOLVED=".tasks/archive/${CTX_FILE}.md"
            elif [ -f ".tasks/archive/${CTX_FILE}" ]; then
                RESOLVED=".tasks/archive/${CTX_FILE}"
            else
                echo "Error: Task file $CTX_FILE not found (looked in .tasks/, .tasks/archive/, and cwd)."
                exit 1
            fi
            echo "$RESOLVED" > task.ctx
            echo "Set active task context: $RESOLVED"
            echo "$RESOLVED"
            ;;
        clear)
            rm -f task.ctx
            echo "Cleared active task context."
            ;;
        show)
            if [ -f "task.ctx" ]; then
                CTX=$(cat task.ctx | tr -d '[:space:]')
                echo "Active task context: $CTX"
            else
                echo "No active task context (task.ctx not found)."
            fi
            ;;
        *)
            echo "Usage: swt.sh ctx [set|clear|show] <task_file>"
            exit 1
            ;;
    esac
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

    echo "Transitioned $FILE to Phase $PHASE_NUM. Ritual logged."
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
