#!/bin/bash
# swt:audit — Structural Health Audit
# Performs workspace-level structural health checks.

set -e

# Determine workspace root
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

# Run the python auditor
python3 "$ROOT_DIR/skills/swt-audit/scripts/audit.py"

# Optional: Display high-severity findings immediately
if [ -f "$ROOT_DIR/swt-skills-audit.json" ]; then
    HIGH_FINDINGS=$(grep -c "\"severity\": \"high\"" "$ROOT_DIR/swt-skills-audit.json" || echo 0)
    if [ "$HIGH_FINDINGS" -gt 0 ]; then
        echo "🚨 WARNING: Found $HIGH_FINDINGS HIGH severity structural findings!"
        echo "👉 Review swt-skills-audit.json for details."
    fi
fi
