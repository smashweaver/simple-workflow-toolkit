#!/bin/bash
# SWT Digest Automation Script

MILESTONE=false
CONTENT_FILE=""
SUMMARY_TEXT=""

# Determine workspace root (look for AGENTS.md or .git)
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -m|--milestone) MILESTONE=true ;;
        --content) CONTENT_FILE="$2"; shift ;;
        --summary) SUMMARY_TEXT="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

TIMESTAMP=$(date +%Y%m%d%H%M%S)
DATE_STR=$(date +%Y-%m-%d)
DIGEST_ROOT=".digests"
mkdir -p "$DIGEST_ROOT/archive"

# Select template
if [ "$MILESTONE" = true ]; then
    FILENAME="$DIGEST_ROOT/${TIMESTAMP}_milestone.md"
    TEMPLATE_PATH="$ROOT_DIR/skills/swt-digest/templates/milestone.md"
else
    FILENAME="$DIGEST_ROOT/${TIMESTAMP}_digest.md"
    TEMPLATE_PATH="$ROOT_DIR/skills/swt-digest/templates/session.md"
fi

if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "❌ Error: Template not found: $TEMPLATE_PATH"
    exit 1
fi

# Gather Data
PARENTS=$(ls -1 "$DIGEST_ROOT"/*_digest.md 2>/dev/null | tail -n 5)
ACTIVE_TASKS=$(ls -1 .tasks/*.md 2>/dev/null | xargs grep -l -E '^\*\*?Status\*\*?:\s*(pending|ideating|in-progress)' 2>/dev/null || true)
CLOSED_TASKS=$(ls -1 .tasks/archive/*.md 2>/dev/null | grep "$(date +%Y%m%d)" || true)

# Build Digest
cp "$TEMPLATE_PATH" "$FILENAME"

# 1. Date
sed -i "s/{{DATE}}/$DATE_STR/g" "$FILENAME"

# 2. Summary
if [ -n "$SUMMARY_TEXT" ]; then
    echo "$SUMMARY_TEXT" > .sum.tmp
elif [ -f "$CONTENT_FILE" ]; then
    cat "$CONTENT_FILE" > .sum.tmp
else
    echo -e "## Summary\n\n{{A 1-2 sentence summary of the session's primary focus.}}" > .sum.tmp
fi
sed -i "/{{SUMMARY}}/{r .sum.tmp
d}" "$FILENAME"

# 3. Context
if [ -f "$ROOT_DIR/task.ctx" ]; then
    CTX_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
    if [ -f "$ROOT_DIR/$CTX_FILE" ]; then RESOLVED="$ROOT_DIR/$CTX_FILE"
    elif [ -f "$ROOT_DIR/.tasks/${CTX_FILE}.md" ]; then RESOLVED="$ROOT_DIR/.tasks/${CTX_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/${CTX_FILE}" ]; then RESOLVED="$ROOT_DIR/.tasks/${CTX_FILE}"
    elif [ -f "$ROOT_DIR/.tasks/archive/${CTX_FILE}.md" ]; then RESOLVED="$ROOT_DIR/.tasks/archive/${CTX_FILE}.md"
    elif [ -f "$ROOT_DIR/.tasks/archive/${CTX_FILE}" ]; then RESOLVED="$ROOT_DIR/.tasks/archive/${CTX_FILE}"
    else RESOLVED=""; fi
    
    if [ -n "$RESOLVED" ] && [ -f "$RESOLVED" ]; then
        echo -e "**Active Context:** $(basename "$RESOLVED")\n" > .ctx.tmp
    else
        echo -e "**Active Context:** STALE ($CTX_FILE not found)\n" > .ctx.tmp
    fi
else
    echo "" > .ctx.tmp
fi
sed -i "/{{CONTEXT}}/{r .ctx.tmp
d}" "$FILENAME"

# 4. Optional Sections (Outcomes & Next Steps)
# Only show if NO manual content provided
if [ -z "$SUMMARY_TEXT" ] && [ -z "$CONTENT_FILE" ]; then
    echo -e "## Key Outcomes & Architecture\n\n- {{Outcome Title}}: {{Brief explanation.}}\n" > .out.tmp
    echo -e "## Immediate Next Steps\n\n1. {{Step 1}}: {{Actionable item}}\n" > .next.tmp
else
    echo "" > .out.tmp
    echo "" > .next.tmp
fi
sed -i "/{{KEY_OUTCOMES}}/{r .out.tmp
d}" "$FILENAME"
sed -i "/{{NEXT_STEPS}}/{r .next.tmp
d}" "$FILENAME"

# 5. Active Tasks
{
    for task in $ACTIVE_TASKS; do
        SLUG=$(basename "$task" .md)
        PRIO=$(grep -oP '^\*\*?Priority\*\*?:\s*\K\S+' "$task" | head -n 1 || echo "medium")
        echo "- **[$SLUG]($task)**: ($PRIO) Active"
    done
} > .active.tmp
sed -i "/{{ACTIVE_TASKS}}/{r .active.tmp
d}" "$FILENAME"

# 6. Closed Tasks
{
    for task in $CLOSED_TASKS; do
        SLUG=$(basename "$task" .md)
        STATUS=$(grep -oP '^\*\*?Status\*\*?:\s*\K\S+' "$task" | head -n 1)
        if [ "$STATUS" == "abandoned" ]; then
            echo "- **Abandoned [$SLUG]($task)**"
        else
            HASH=$(grep -A 1 "## Commit Reference" "$task" | grep -v "## Commit Reference" | grep -oE "[a-f0-9]{7,40}" | head -n 1 || echo "—")
            echo "- **Closed [$SLUG]($task)**: Committed changes ($HASH)."
        fi
    done
} > .closed.tmp
sed -i "/{{CLOSED_TASKS}}/{r .closed.tmp
d}" "$FILENAME"

# 7. Parents
{
    for parent in $PARENTS; do
        echo "- $parent"
    done
} > .parents.tmp
sed -i "/{{PARENTS}}/{r .parents.tmp
d}" "$FILENAME"

rm -f .sum.tmp .ctx.tmp .out.tmp .next.tmp .active.tmp .closed.tmp .parents.tmp

# Archive Parents
for parent in $PARENTS; do
    mv "$parent" "$DIGEST_ROOT/archive/" 2>/dev/null
done

echo "Digest created: $FILENAME"

# Post-Generation Validation (Scenario C)
if grep -qE "\{\{[A-Za-z][^}]*\}\}" "$FILENAME"; then
    echo "🛑 PROTOCOL WARNING: Generated digest contains unpopulated placeholders!"
    grep -nE "\{\{[A-Za-z][^}]*\}\}" "$FILENAME"
    echo "   You MUST fill these in manually or re-run the synthesis correctly."
fi
