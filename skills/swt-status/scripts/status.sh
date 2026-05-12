#!/bin/bash

# swt:status — Metadata Aggregator
# Aggregates project state from .digests, .tasks, and .specs

set -e

# --- Argument Parsing ---
SHOW_GIT=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --git) SHOW_GIT=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# 1. Identify Workspace Root (look for parent AGENTS.md or .git)
# This allows the script to be run from sub-directories
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

echo "--- Workspace ---"
if [ -f "$ROOT_DIR/AGENTS.md" ]; then
    PROJECT_NAME=$(grep -m 1 "^# " "$ROOT_DIR/AGENTS.md" | sed 's/# //')
    echo "Project: $PROJECT_NAME"
else
    echo "Project: Unknown (No AGENTS.md found)"
fi
echo "Root: $ROOT_DIR"
echo ""

# 1.25 Active Task Context
if [ -f "$ROOT_DIR/task.ctx" ]; then
    CTX_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
    # Resolve task file
    if [ -f "$ROOT_DIR/$CTX_FILE" ]; then
        RESOLVED="$ROOT_DIR/$CTX_FILE"
    elif [ -f "$ROOT_DIR/.tasks/${CTX_FILE}.md" ]; then
        RESOLVED="$ROOT_DIR/.tasks/${CTX_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/${CTX_FILE}" ]; then
        RESOLVED="$ROOT_DIR/.tasks/${CTX_FILE}"
    elif [ -f "$ROOT_DIR/.tasks/archive/${CTX_FILE}.md" ]; then
        RESOLVED="$ROOT_DIR/.tasks/archive/${CTX_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/archive/${CTX_FILE}" ]; then
        RESOLVED="$ROOT_DIR/.tasks/archive/${CTX_FILE}"
    else
        RESOLVED=""
    fi

    if [ -n "$RESOLVED" ] && [ -f "$RESOLVED" ]; then
        CTX_STATUS=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$RESOLVED" | head -n 1)
        CTX_PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$RESOLVED" | head -n 1)
        echo "--- Active Task Context ---"
        echo "Task: $(basename "$RESOLVED")"
        echo "Status: $CTX_STATUS | Phase: $CTX_PHASE"
        echo ""
    else
        echo "--- Active Task Context ---"
        echo "STALE: $CTX_FILE not found. Clear with: swt.sh ctx clear"
        echo ""
    fi
else
    echo "--- Active Task Context ---"
    echo "None (task.ctx not found)"
    echo ""
fi

# 1.3 Tactical Roadmap
if [ -f "$ROOT_DIR/protocol.md" ]; then
    echo "--- Tactical Roadmap ---"
    # Extract the Execution Loop section and filter for checklist items
    sed -n '/## 2. Gate 3: Execution Loop/,/##/p' "$ROOT_DIR/protocol.md" | grep -E '^\s*-\s*\[[ xX]\]'
    echo ""
fi

# 1.5 Graphify Status
if [ -f "$ROOT_DIR/skills/swt-graphify/scripts/graphify.sh" ]; then
    bash "$ROOT_DIR/skills/swt-graphify/scripts/graphify.sh" status
    echo ""
fi

# 2. Latest Digest
echo "--- Latest Digest ---"
LATEST_DIGEST=$(ls -t "$ROOT_DIR/.digests/"*.md 2>/dev/null | head -n 1)
if [ -z "$LATEST_DIGEST" ]; then
    LATEST_DIGEST=$(ls -t "$ROOT_DIR/.digests/archive/"*.md 2>/dev/null | head -n 1)
fi

if [ -n "$LATEST_DIGEST" ]; then
    echo "File: $(basename "$LATEST_DIGEST")"
    # Extract the summary or key outcomes (usually under ## Key Outcomes)
    grep -A 5 "## Key Outcomes" "$LATEST_DIGEST" | grep -v "## Key Outcomes" | sed '/^$/d' | head -n 5
else
    echo "No digests found."
fi
echo ""

# 3. Active Tasks
echo "--- Active Tasks ---"
if [ -d "$ROOT_DIR/.tasks" ]; then
    # Create temporary file to store task data for sorting/grouping
    TASK_DATA=$(mktemp)
    
    FILES=$(ls "$ROOT_DIR/.tasks/"*.md 2>/dev/null || true)
    FOUND_ACTIVE=false
    
    for f in $FILES; do
        STATUS=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$f" | head -n 1)
        if [[ "$STATUS" != "done" && "$STATUS" != "abandoned" ]]; then
            PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$f" | head -n 1)
            CATEGORY=$(grep -oP '^\*\*?Category\*\*?:\s*\K\S+' "$f" | head -n 1)
            CATEGORY=${CATEGORY:-uncategorized}
            TYPE=$(grep -oP '^\*\*?Type\*\*?:\s*\K\S+' "$f" | head -n 1)
            PRIORITY=$(grep -oP '^\*\*?Priority\*\*?:\s*\K\S+' "$f" | head -n 1)
            
            OBJECTIVE=$(grep -A 1 "## Objective" "$f" | grep -v "## Objective" | sed '/^$/d' | head -n 1)
            if [ -z "$OBJECTIVE" ]; then
                OBJECTIVE=$(grep -A 1 "## Core Concept" "$f" | grep -v "## Core Concept" | sed '/^$/d' | head -n 1)
            fi
            
            # Escape tabs in objective and filename
            OBJECTIVE_CLEAN=$(echo "$OBJECTIVE" | tr '\t' ' ')
            F_BASE=$(basename "$f")
            
            # Store data: Category | Type | Phase | Priority | Filename | Objective
            echo -e "$CATEGORY\t$TYPE\t$PHASE\t$PRIORITY\t$F_BASE\t$OBJECTIVE_CLEAN" >> "$TASK_DATA"
            FOUND_ACTIVE=true
        fi
    done

    if [ "$FOUND_ACTIVE" = true ]; then
        # 3.1. Smart Recommendations (Low-Hanging Fruit)
        RECS=$(awk -F'\t' '$3 == "0" && ($2 == "docs" || $2 == "chore" || $2 == "refactor") { print $0 }' "$TASK_DATA" | head -n 3)
        if [ -n "$RECS" ]; then
            echo "💡 Recommendations (Low-Hanging Fruit)"
            echo "$RECS" | while IFS=$'\t' read -r cat type phase prio file obj; do
                echo "  - $(echo "$file" | sed -E 's/^[0-9]+_//; s/\.md$//' | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g') ($type)"
            done
            echo ""
        fi

        # 3.2. Categorized Task List
        # Sort by Category, then Phase descending
        sort -k1,1 -k3,3rn "$TASK_DATA" | while IFS=$'\t' read -r cat type phase prio file obj; do
            # Print category header if it changes
            if [ "$cat" != "$LAST_CAT" ]; then
                [ -n "$LAST_CAT" ] && echo ""
                # Capitalize category
                CAT_DISPLAY=$(echo "$cat" | sed 's/\b\(.\)/\u\1/g')
                echo "📂 $CAT_DISPLAY"
                LAST_CAT=$cat
            fi
            
            echo "Task: $file"
            echo "  Status: $type | Phase: $phase | Priority: $prio"
            echo "  Goal: $obj"
            
            # Validation Check
            if [ -f "$ROOT_DIR/skills/swt-task/scripts/task.sh" ]; then
                VAL=$(bash "$ROOT_DIR/skills/swt-task/scripts/task.sh" validate "$ROOT_DIR/.tasks/$file" 2>&1 || true)
                echo "  Validation: $VAL"
            fi
            
            # Get next step
            NEXT=$(grep -m 1 "\[ \]" "$ROOT_DIR/.tasks/$file" | sed 's/.*\[ \] //')
            if [ -n "$NEXT" ]; then
                echo "  Next Step: $NEXT"
            fi
        done
        echo ""
    else
        echo "No active tasks found."
        echo ""
    fi
    rm -f "$TASK_DATA"
else
    echo "No .tasks/ directory found."
    echo ""
fi

# 4. Recent Specs
echo "--- Recent Specs ---"
if [ -d "$ROOT_DIR/.specs" ]; then
    ACTIVE_TASKS=$(ls -1 .tasks/*.md 2>/dev/null | xargs grep -l -E '^\*\*?Status\*\*?:\s*(pending|ideating|in-progress)' 2>/dev/null || true)
    ls -t "$ROOT_DIR/.specs/"*.md 2>/dev/null | head -n 3 | xargs -n 1 basename
else
    echo "No .specs/ directory found."
fi
echo ""

# 5. Git Logs (Optional)
if [ "$SHOW_GIT" = true ]; then
    echo "--- Recent Commits ---"
    if [ -d "$ROOT_DIR/.git" ]; then
        git -C "$ROOT_DIR" log -n 5 --oneline
    else
        echo "Warning: Not a git repository."
    fi
    echo ""
fi
