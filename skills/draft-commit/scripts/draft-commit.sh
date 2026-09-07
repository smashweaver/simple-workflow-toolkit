#!/bin/bash
# draft-commit — Portable Draft-and-Approve commit workflow
# Usage:
#   draft-commit.sh                       Show the ritual guide
#   draft-commit.sh --draft "msg"         Validate a draft and write commit.draft
#   draft-commit.sh --draft "msg" --ref "Fixes #42"   Append a reference to the draft
#   draft-commit.sh --check                Run lint on an existing commit.draft

set -e

# Resolve this script's directory (portable, no project-walk)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT_SCRIPT="$SCRIPT_DIR/lint.sh"
ROOT_DIR="$(pwd)"

function show_guide() {
    cat <<'EOF'
draft-commit — Draft-and-Approve commit ritual

Step 1: Stage your changes
    git add .
    git status

Step 2: Capture the staged diff
    git diff --cached > commit.diff

Step 3: Generate a validated commit draft
    bash skills/draft-commit/scripts/draft-commit.sh --draft "type(scope): summary

    * bullet: user benefit or impact
    * bullet: additional distinct information"

    # Optional: append a reference (e.g. issue tracker ID)
    bash skills/draft-commit/scripts/draft-commit.sh --draft "..." --ref "Fixes #42"

Step 4: Review commit.draft (printed by the skill)

Step 5: Approve
    git commit -F commit.draft

Step 6: Cleanup
    rm -f commit.diff commit.draft
EOF
}

function usage() {
    echo "Usage:"
    echo "  $0                       Show the ritual guide"
    echo "  $0 --draft \"message\"    Validate a draft and write commit.draft"
    echo "  $0 --draft \"message\" --ref \"Fixes #42\"   Append a reference"
    echo "  $0 --check               Re-lint an existing commit.draft"
    exit 1
}

DRAFT=""
REF=""
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --draft)
            DRAFT="$2"
            shift 2
            ;;
        --ref)
            REF="$2"
            shift 2
            ;;
        --check)
            CHECK_ONLY=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "❌ Unknown argument: $1"
            usage
            ;;
    esac
done

# --check: re-lint an existing draft
if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ ! -f "$ROOT_DIR/commit.draft" ]; then
        echo "❌ No commit.draft found in $ROOT_DIR"
        exit 1
    fi
    if bash "$LINT_SCRIPT" "$ROOT_DIR/commit.draft"; then
        echo "✅ commit.draft lints clean."
        exit 0
    else
        exit 1
    fi
fi

# No args: show guide
if [ -z "$DRAFT" ]; then
    show_guide
    exit 0
fi

# Validate the draft
TMP_FILE="$(mktemp -t commit-validate.XXXXXX)"
trap 'rm -f "$TMP_FILE"' EXIT

# Build the full message: header + bullets + optional ref
echo -e "$DRAFT" > "$TMP_FILE"

if [ -n "$REF" ]; then
    # Append a blank line and the reference
    echo "" >> "$TMP_FILE"
    echo "$REF" >> "$TMP_FILE"
fi

echo "🔍 Validating commit message..."

if bash "$LINT_SCRIPT" "$TMP_FILE"; then
    mv "$TMP_FILE" "$ROOT_DIR/commit.draft"
    # Avoid the trap deleting the moved file
    trap - EXIT
    echo "✅ Draft generated: $ROOT_DIR/commit.draft"
    echo ""
    echo "--- Verification Artifacts (COPY-PASTE INTO RESPONSE) ---"
    echo '```'
    cat "$ROOT_DIR/commit.draft"
    echo ""
    echo '```'
    echo "--- End of Artifacts ---"
    exit 0
else
    echo ""
    echo "🛑 LINT FAILED: The commit message violates draft-commit guidelines."
    echo "👉 Self-Correction Required: Read the errors above, re-read this SKILL.md, and try again."
    echo "⚠️  Loop Limit: Do not exceed 3 attempts. If you are stuck, ask the user for help."
    exit 1
fi