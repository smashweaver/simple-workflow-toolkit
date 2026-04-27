#!/bin/bash
# SWT Digest Automation Script

MILESTONE=false
CONTENT_FILE=""
SUMMARY_TEXT=""

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

if [ "$MILESTONE" = true ]; then
    FILENAME="$DIGEST_ROOT/${TIMESTAMP}_milestone.md"
    TEMPLATE="Project Milestone"
else
    FILENAME="$DIGEST_ROOT/${TIMESTAMP}_digest.md"
    TEMPLATE="Session Summary"
fi

# Gather Parents
PARENTS=$(ls -1 "$DIGEST_ROOT"/*_digest.md 2>/dev/null | tail -n 5)

# Gather Active Tasks
ACTIVE_TASKS=$(ls -1 .tasks/*.md 2>/dev/null | xargs grep -l '\*\*Status\*\*: \(pending\|ideating\|in-progress\)' 2>/dev/null || true)

# Gather Recently Closed Tasks
CLOSED_TASKS=$(ls -1 .tasks/archive/*.md 2>/dev/null | grep "$(date +%Y%m%d)" || true)

# Build Digest
{
    echo "# SWT $TEMPLATE — $DATE_STR"
    echo ""
    if [ -n "$SUMMARY_TEXT" ]; then
        echo "$SUMMARY_TEXT"
    elif [ -f "$CONTENT_FILE" ]; then
        cat "$CONTENT_FILE"
    else
        echo "{{A 1-2 sentence summary of the session's primary focus.}}"
    fi
    echo ""
    echo "## Key Outcomes & Architecture"
    echo ""
    echo "- {{Outcome Title}}: {{Brief explanation.}}"
    echo ""
    echo "## Active Tasks in \`.tasks/\`"
    echo ""
    for task in $ACTIVE_TASKS; do
        SLUG=$(basename "$task" .md)
        PRIO=$(grep -oP '\*\*Priority\*\*:\s*\K\S+' "$task" || echo "medium")
        echo "- **[$SLUG]($task)**: ($PRIO) Active"
    done
    echo ""
    echo "## Changes & Cleanup"
    echo ""
    for task in $CLOSED_TASKS; do
        SLUG=$(basename "$task" .md)
        HASH=$(grep -oP '## Commit Reference\n\K\S+' "$task" | head -n 1 || echo "—")
        echo "- **Closed [$SLUG]($task)**: Committed changes ($HASH)."
    done
    echo ""
    echo "## Immediate Next Steps"
    echo ""
    echo "1. {{Step 1}}: {{Actionable item}}"
    echo ""
    echo "## Synthesized Parent Digests"
    echo ""
    for parent in $PARENTS; do
        echo "- $parent"
    done
} > "$FILENAME"

# Archive Parents
for parent in $PARENTS; do
    mv "$parent" "$DIGEST_ROOT/archive/" 2>/dev/null
done

echo "Digest created: $FILENAME"
if [ -n "$PARENTS" ]; then
    echo "Archived synthesized parents to $DIGEST_ROOT/archive/"
fi
