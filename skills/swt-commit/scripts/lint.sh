#!/bin/bash
# swt:commit — Commit Protocol Linter
# Usage: ./lint.sh <draft_file>

set -e

DRAFT_FILE=$1

if [ -z "$DRAFT_FILE" ]; then
    echo "Usage: $0 <draft_file>"
    exit 1
fi

if [ ! -f "$DRAFT_FILE" ]; then
    echo "❌ Error: Draft file not found: $DRAFT_FILE"
    exit 1
fi

# Identify Workspace Root
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

FAILED=0

echo "--- Commit Protocol Lint Report ---"

# 1. Format Check: type(scope): summary
TITLE=$(head -n 1 "$DRAFT_FILE")
if [[ ! "$TITLE" =~ ^([a-z]+)(\([a-z0-9_-]+\))?:\ .+$ ]]; then
    echo "❌ Format: Title must follow 'type(scope): summary' format."
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

# 3. Context Check: No Structural Noise (Slashes, dots, extensions) in bullets
# We skip the title line and look for paths/extensions
NOISE=$(tail -n +2 "$DRAFT_FILE" | grep -E "\.|/|README|SKILL|AGENTS" || true)
if [ -n "$NOISE" ]; then
    # Be specific about what failed
    if echo "$NOISE" | grep -qE "\.(md|sh|py|js|ts|css|html)"; then
        echo "❌ Context: Found file extensions in bullets. REMOVE STRUCTURAL NOISE."
        FAILED=1
    elif echo "$NOISE" | grep -q "/"; then
        echo "❌ Context: Found directory paths in bullets. REMOVE STRUCTURAL NOISE."
        FAILED=1
    else
        echo "✅ Context: No obvious structural noise detected."
    fi
else
    echo "✅ Context: No obvious structural noise detected."
fi

# 4. Separation Check: No metadata leaks (Closes:)
if grep -qE "Closes:|Task:|Spec:" "$DRAFT_FILE"; then
    echo "❌ Separation: Metadata detected in draft. Move 'Closes:' to commit.task."
    FAILED=1
else
    echo "✅ Separation: No metadata leaks detected."
fi

# 5. Ritual Check: Task State & Phase
    TASK_FILE=$(cat "$ROOT_DIR/task.ctx" | tr -d '[:space:]')
    # Resolve task file
    if [ -f "$ROOT_DIR/$TASK_FILE" ]; then RESOLVED="$ROOT_DIR/$TASK_FILE"
    elif [ -f "$ROOT_DIR/.tasks/${TASK_FILE}" ]; then RESOLVED="$ROOT_DIR/.tasks/${TASK_FILE}"
    else RESOLVED=""; fi

    if [ -n "$RESOLVED" ] && [ -f "$RESOLVED" ]; then
        # Use swt-task audit for a thorough check
        if ! bash "$ROOT_DIR/skills/swt-task/scripts/task.sh" audit "$TASK_FILE" > /dev/null 2>&1; then
            echo "❌ Audit: Task validation failed (likely a stale spec). Run swt:flow sync-docs."
            FAILED=1
        else
            # Check Phase explicitly
            PHASE=$(grep -oP '^\*\*?Phase\*\*?:\s*\K\d+' "$RESOLVED" | head -n 1 || echo "0")
            if [ "$PHASE" -lt 8 ]; then
                echo "❌ Ritual: Task is in Phase $PHASE. Advance to Phase 8 (Review) before committing."
                FAILED=1
            else
                echo "✅ Ritual: Phase 8 and Spec synchronization verified."
            fi
        fi
    else
        echo "⚠️  Ritual: Task file not found. Skipping phase checks."
    fi

if [ $FAILED -eq 1 ]; then
    echo "--- LINT FAILED ---"
    exit 1
else
    echo "--- LINT PASSED ---"
    exit 0
fi
