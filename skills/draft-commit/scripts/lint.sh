#!/bin/bash
# commit — Commit message linter (portable, no project dependencies)
# Usage: lint.sh <draft_file>
#
# Checks:
#   1. Format: header matches type(scope): summary
#   2. Syntax: bullets use '*', not '-'
#   3. Context: no file paths or extensions in bullets
#   4. Separation: no metadata leaks (Closes:/Task:/Spec:) — use --ref instead
#   5. Hygiene: warning (not error) for WIP markers in body
#   6. Foresight: warning (not error) for forward-looking bullets — history records delivered impact, plans belong in progress records
#   7. Readability: warning (not error) for bullets over 30 words — a long bullet is a paragraph; split or cut it

set -e

DRAFT_FILE="$1"

if [ -z "$DRAFT_FILE" ]; then
    echo "Usage: $0 <draft_file>"
    exit 1
fi

if [ ! -f "$DRAFT_FILE" ]; then
    echo "❌ Error: Draft file not found: $DRAFT_FILE"
    exit 1
fi

FAILED=0
WARNED=0

echo "--- Commit Message Lint Report ---"

# 1. Format Check: type(scope): summary
TITLE=$(head -n 1 "$DRAFT_FILE")
if [[ ! "$TITLE" =~ ^([a-z]+)(\([a-z0-9_-]+\))?:\ .+ ]]; then
    echo "❌ Format: Title must follow 'type(scope): summary' format."
    echo "   Got: $TITLE"
    FAILED=1
else
    echo "✅ Format: Valid header detected."
fi

# 2. Syntax Check: * bullets only
if grep -q "^-" "$DRAFT_FILE"; then
    echo "❌ Syntax: Use '*' for bullets, not '-'."
    FAILED=1
else
    echo "✅ Syntax: Bullet markers are valid."
fi

# 3. Context Check: No structural noise (file paths / extensions) in bullets
NOISE=$(tail -n +2 "$DRAFT_FILE" | grep -E "\.(md|sh|py|js|ts|css|html|json|yaml|yml|toml|go|rs|java|cpp|c|h)" || true)
PATH_NOISE=$(tail -n +2 "$DRAFT_FILE" | grep -E "(\s|^)/[a-z]" || true)

if [ -n "$NOISE" ]; then
    echo "❌ Context: Found file extensions in bullets. REMOVE STRUCTURAL NOISE."
    echo "   Offending lines:"
    echo "$NOISE" | sed 's/^/   /'
    FAILED=1
elif [ -n "$PATH_NOISE" ]; then
    echo "❌ Context: Found directory paths in bullets. REMOVE STRUCTURAL NOISE."
    echo "   Offending lines:"
    echo "$PATH_NOISE" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ Context: No obvious structural noise detected."
fi

# 4. Separation Check: No metadata leaks (use --ref instead)
if grep -qE "^(Closes|Task|Spec|Fixes|Resolves):" "$DRAFT_FILE"; then
    echo "❌ Separation: Metadata prefix detected at line start. Use --ref to append references."
    FAILED=1
else
    echo "✅ Separation: No metadata leaks detected."
fi

# 5. Hygiene Check: WIP markers (warning, not error)
WIP=$(grep -iE "\b(TODO|FIXME|WIP|XXX|HACK)\b" "$DRAFT_FILE" || true)
if [ -n "$WIP" ]; then
    echo "⚠️  Hygiene: WIP markers detected in message body (warning only)."
    echo "   $WIP" | sed 's/^/   /'
    WARNED=1
else
    echo "✅ Hygiene: No WIP markers."
fi

# 6. Foresight Check: forward-looking bullets (warning, not error)
FUTURE=$(tail -n +2 "$DRAFT_FILE" | grep -iE "\b(next steps?|follow-?ups?|plan to|remaining work)\b" || true)
if [ -n "$FUTURE" ]; then
    echo "⚠️  Foresight: forward-looking phrasing detected in bullets (warning only). Describe delivered impact; keep plans in progress records."
    echo "$FUTURE" | sed 's/^/   /'
    WARNED=1
else
    echo "✅ Foresight: No forward-looking phrasing."
fi

# 7. Readability Check: bullet length (warning, not error)
# Bullets wrap across lines in the draft, so paragraphs are rejoined before counting.
LONG=$(awk '
    /^\*/ { if (buf != "") print buf; buf = $0; next }
    /^$/    { if (buf != "") print buf; buf = ""; next }
         { buf = buf " " $0 }
    END     { if (buf != "") print buf }
' "$DRAFT_FILE" | while IFS= read -r bullet; do
    n=$(printf '%s' "$bullet" | sed 's/^\* *//' | wc -w)
    if [ "$n" -gt 30 ]; then
        echo "   $n words: $(printf '%s' "$bullet" | cut -c1-90)..."
    fi
done)

if [ -n "$LONG" ]; then
    echo "⚠️  Readability: bullet(s) over 30 words detected (warning only). A bullet that long is a paragraph; split it or keep the claim and drop the explanation."
    echo "$LONG" | sed 's/^/   /'
    WARNED=1
else
    echo "✅ Readability: bullets are within 30 words."
fi

if [ $FAILED -eq 1 ]; then
    echo "--- LINT FAILED ---"
    exit 1
else
    if [ $WARNED -eq 1 ]; then
        echo "--- LINT PASSED (with warnings) ---"
    else
        echo "--- LINT PASSED ---"
    fi
    exit 0
fi
