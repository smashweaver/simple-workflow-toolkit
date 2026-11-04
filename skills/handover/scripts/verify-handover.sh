#!/bin/bash
# verify-handover.sh — Validate HANDOVER.md against git status and local state
# Usage:
#   verify-handover.sh [path/to/HANDOVER.md]

set -e

HANDOVER_FILE="${1:-HANDOVER.md}"

if [ ! -f "$HANDOVER_FILE" ]; then
    echo "❌ Error: Handover file not found: $HANDOVER_FILE"
    exit 1
fi

FAILED=0
WARNED=0

echo "--- Handover Verification Report: $HANDOVER_FILE ---"

# 0. Check Git Ignore status for Handover file
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git check-ignore -q "$HANDOVER_FILE"; then
        echo "✅ Git Ignore: '$HANDOVER_FILE' is properly ignored (in .gitignore or .git/info/exclude)."
    else
        echo "⚠️  Git Ignore: '$HANDOVER_FILE' is NOT ignored by git. Handover documents should remain local-only."
        WARNED=1
    fi
fi

# 1. Check Git HEAD commit reference
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "⚠️  Not a git repository: skipping git status checks."
    exit 0
fi

HEAD_SHORT=$(git rev-parse --short HEAD 2>/dev/null || true)
HEAD_FULL=$(git rev-parse HEAD 2>/dev/null || true)

# Look for patterns like "Latest commit: `abc1234`" or "commit `abc1234`"
COMMITS_MENTIONED=$(grep -oE "(Latest commit: \`[0-9a-fA-F]+\`|commit \`[0-9a-fA-F]+\`)" "$HANDOVER_FILE" | grep -oE "[0-9a-fA-F]{7,40}" | head -n 1 || true)

if [ -n "$COMMITS_MENTIONED" ]; then
    if [[ "$HEAD_SHORT" == "$COMMITS_MENTIONED"* || "$COMMITS_MENTIONED" == "$HEAD_SHORT"* ]]; then
        echo "✅ Commit Reference: Matches HEAD ($HEAD_SHORT)."
    else
        # Check if mentioned commit is an ancestor of HEAD
        if git merge-base --is-ancestor "$COMMITS_MENTIONED" HEAD 2>/dev/null; then
            echo "❌ Commit Reference: HANDOVER.md references older commit \`$COMMITS_MENTIONED\`, but HEAD is now \`$HEAD_SHORT\`."
            FAILED=1
        else
            echo "⚠️  Commit Reference: Mentioned commit \`$COMMITS_MENTIONED\` is not current HEAD (\`$HEAD_SHORT\`)."
            WARNED=1
        fi
    fi
else
    echo "⚠️  Commit Reference: Could not find explicit 'Latest commit: \`<sha>\`' in $HANDOVER_FILE."
    WARNED=1
fi

# 2. Check Uncommitted Work truthfulness
DIRTY_FILES=$(git status --porcelain 2>/dev/null | grep -v "HANDOVER.md" || true)

if grep -qi "Uncommitted work: none" "$HANDOVER_FILE" || grep -qi "working tree.*clean" "$HANDOVER_FILE"; then
    if [ -n "$DIRTY_FILES" ]; then
        echo "❌ Working tree: Handover claims working tree is clean, but git status shows changes:"
        echo "$DIRTY_FILES" | sed 's/^/   /'
        FAILED=1
    else
        echo "✅ Working tree: Clean matches handover description."
    fi
else
    if [ -z "$DIRTY_FILES" ]; then
        if grep -qi "Uncommitted work:" "$HANDOVER_FILE" && ! grep -qi "Uncommitted work: none" "$HANDOVER_FILE"; then
            echo "⚠️  Working tree: Handover lists uncommitted work, but git status is currently clean (changes may have been committed)."
            WARNED=1
        else
            echo "✅ Working tree: Clean."
        fi
    else
        echo "ℹ️  Working tree has local changes:"
        echo "$DIRTY_FILES" | sed 's/^/   /'
    fi
fi

# 3. Check referenced files under /tmp/
TMP_REFS=$(grep -oE "/tmp/[A-Za-z0-9._-]+" "$HANDOVER_FILE" | sort -u || true)
if [ -n "$TMP_REFS" ]; then
    for tmp_path in $TMP_REFS; do
        if [ ! -e "$tmp_path" ]; then
            echo "⚠️  Temporary fixture missing: '$tmp_path' referenced in handover does not exist on disk."
            WARNED=1
        else
            echo "✅ Temporary fixture found: '$tmp_path'."
        fi
    done
fi

# 4. Check internal repository links/anchors (e.g. [AGENTS.md](AGENTS.md))
DOC_LINKS=$(grep -oE "\[[^]]+\]\([A-Za-z0-9/._-]+\.md\)" "$HANDOVER_FILE" | grep -oE "\([A-Za-z0-9/._-]+\.md\)" | tr -d '()' || true)
for link in $DOC_LINKS; do
    if [ ! -f "$link" ]; then
        echo "❌ Broken doc link: '$link' in handover does not exist."
        FAILED=1
    fi
done

echo "--- Summary ---"
if [ $FAILED -gt 0 ]; then
    echo "❌ Handover verification FAILED with $FAILED error(s) and $WARNED warning(s)."
    exit 1
elif [ $WARNED -gt 0 ]; then
    echo "⚠️  Handover verification PASSED with $WARNED warning(s)."
    exit 0
else
    echo "✅ Handover verification PASSED."
    exit 0
fi

