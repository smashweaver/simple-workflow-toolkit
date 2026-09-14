#!/bin/bash
# draft-commit — Portable Draft-and-Approve commit workflow
# Usage:
#   draft-commit.sh                       Show the ritual guide
#   draft-commit.sh --preview             Run commit-draft checks on unstaged files without staging or writing
#   draft-commit.sh --preview --draft "msg"   Lint a draft against unstaged files in-memory without writing commit.draft
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

Step 0: Preview on unstaged files (optional, no side effects)
    bash skills/draft-commit/scripts/draft-commit.sh --preview
    bash skills/draft-commit/scripts/draft-commit.sh --preview --draft "type(scope): summary

    * bullet: user benefit or impact"

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
    echo "  $0 --preview             Run commit-draft checks on unstaged files without staging or writing"
    echo "  $0 --preview --draft \"message\"   Lint a draft against unstaged files in-memory without writing commit.draft"
    echo "  $0 --draft \"message\"    Validate a draft and write commit.draft"
    echo "  $0 --draft \"message\" --ref \"Fixes #42\"   Append a reference"
    echo "  $0 --check               Re-lint an existing commit.draft"
    exit 1
}

DRAFT=""
REF=""
CHECK_ONLY=0
PREVIEW=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preview)
            PREVIEW=1
            shift
            ;;
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

# --preview: get the diff on unstaged files, then apply draft-commit logic — no staging, no file writes
if [ "$PREVIEW" -eq 1 ] && [ "$CHECK_ONLY" -eq 0 ] && [ -z "$DRAFT" ]; then
    echo "--- Preview on unstaged files (nothing staged, nothing written) ---"
    git status --short
    echo "---"
    git diff --stat
    echo "--- Protocol validation (unstaged diff) ---"
    if [ ! -x "$LINT_SCRIPT" ]; then
        echo "❌ Lint script missing or not executable: $LINT_SCRIPT"
        exit 1
    fi
    echo "✅ Lint script present and executable."
    UNSTAGED_WIP="$(git diff | grep -iE '\b(TODO|FIXME|WIP|XXX|HACK)\b' || true)"
    UNSTAGED_DEBUG="$(git diff | grep -E 'console\.log|debugger|binding\.pry|import pdb|pdb\.set_trace' || true)"
    if [ -n "$UNSTAGED_WIP$UNSTAGED_DEBUG" ]; then
        echo "⚠️  Red flags in unstaged diff:"
        [ -n "$UNSTAGED_WIP" ] && echo "$UNSTAGED_WIP" | sed 's/^/   /'
        [ -n "$UNSTAGED_DEBUG" ] && echo "$UNSTAGED_DEBUG" | sed 's/^/   /'
    else
        echo "✅ No WIP markers or debug statements in unstaged diff."
    fi
    if [ -f "$ROOT_DIR/commit.diff" ] || [ -f "$ROOT_DIR/commit.draft" ]; then
        echo "⚠️  Leftover commit.diff or commit.draft present."
    else
        echo "✅ Repo hygiene clean (no leftover commit.diff or commit.draft)."
    fi
    echo ""
    echo "--- Unstaged diff (apply draft-commit logic to this) ---"
    git diff
    exit 0
fi

# --preview --draft: lint in-memory against unstaged files without writing commit.draft
if [ "$PREVIEW" -eq 1 ] && [ -n "$DRAFT" ]; then
    TMP_FILE="$(mktemp -t commit-preview.XXXXXX)"
    trap 'rm -f "$TMP_FILE"' EXIT
    echo -e "$DRAFT" > "$TMP_FILE"
    if [ -n "$REF" ]; then
        echo "" >> "$TMP_FILE"
        echo "$REF" >> "$TMP_FILE"
    fi
    echo "🔍 Preview lint on unstaged files (nothing staged, nothing written)..."
    UNSTAGED_WIP="$(git diff | grep -iE '\b(TODO|FIXME|WIP|XXX|HACK)\b' || true)"
    if [ -n "$UNSTAGED_WIP" ]; then
        echo "⚠️  WIP markers in unstaged diff (warning only):"
        echo "$UNSTAGED_WIP" | sed 's/^/   /'
    else
        echo "✅ No WIP markers in unstaged diff."
    fi
    if bash "$LINT_SCRIPT" "$TMP_FILE"; then
        echo ""
        echo "--- Draft preview (not saved) ---"
        echo '```'
        cat "$TMP_FILE"
        echo ""
        echo '```'
        exit 0
    else
        echo ""
        echo "🛑 PREVIEW LINT FAILED: fix the draft and retry with --draft to save."
        exit 1
    fi
fi

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