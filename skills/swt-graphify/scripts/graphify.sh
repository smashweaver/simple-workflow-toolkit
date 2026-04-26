#!/bin/bash

# swt:graphify — Structural Awareness Orchestrator
# Manages the lifecycle and state of the graphify engine.

set -e

COMMAND=$1
SHIFT_ARGS=${@:2}

# --- Discovery Ritual ---
# Find Workspace Root (look for parent AGENTS.md or .git)
ROOT_DIR=$(pwd)
while [[ "$ROOT_DIR" != "/" && ! -f "$ROOT_DIR/AGENTS.md" && ! -d "$ROOT_DIR/.git" ]]; do
    ROOT_DIR=$(dirname "$ROOT_DIR")
done

AGENTS_FILE="$ROOT_DIR/AGENTS.md"
GRAPH_DIR="$ROOT_DIR/graphify-out"
GRAPH_FILE="$GRAPH_DIR/graph.json"

# --- Helper Functions ---

check_engine() {
    if ! command -v graphify &> /dev/null; then
        echo "Error: 'graphify' engine not found in PATH."
        echo "Please install it manually (e.g., 'pip install graphifyy') to use this skill."
        exit 1
    fi
}

ensure_agents_section() {
    if ! grep -q "## Graphify" "$AGENTS_FILE"; then
        echo -e "\n## Graphify\n<!-- swt:graphify state -->\n- **Status**: disabled\n- **Engine**: safishamsi/graphify\n" >> "$AGENTS_FILE"
    fi
}

set_state() {
    local state=$1
    ensure_agents_section
    sed -i "s/- \*\*Status\*\*:.*/- \*\*Status\*\*: $state/" "$AGENTS_FILE"
    echo "Graphify state set to: $state"
}

get_state() {
    if [ ! -f "$AGENTS_FILE" ]; then
        echo "missing"
        return
    fi
    grep -oP '\*\*Status\*\*:\s*\K\S+' "$AGENTS_FILE" | tail -n 1 || echo "missing"
}

# --- Command Router ---

case $COMMAND in
    verify)
        echo "Verifying Graphify engine..."
        if command -v graphify &> /dev/null; then
            echo "✅ Graphify engine found: $(which graphify)"
            if graphify --version &> /dev/null; then
                echo "Version: $(graphify --version)"
            fi
            set_state "enabled"
        else
            echo "❌ Graphify engine NOT found in PATH."
            echo "Action required: pip install graphifyy"
            set_state "disabled"
            exit 1
        fi
        ;;
    
    init)
        check_engine
        echo "Initializing knowledge graph..."
        graphify .
        set_state "enabled"
        ;;

    on)
        set_state "enabled"
        ;;

    off)
        set_state "disabled"
        ;;

    uninstall)
        echo "Cleaning up Graphify artifacts..."
        # Run native engine uninstall if exists
        if command -v graphify &> /dev/null; then
            graphify antigravity uninstall || true
        fi
        
        # Remove Graphify section from AGENTS.md
        if [ -f "$AGENTS_FILE" ]; then
            # Delete from ## Graphify to the end of the block
            sed -i '/## Graphify/,/^- \*\*Engine\*\*:.*/d' "$AGENTS_FILE"
        fi
        
        # Remove artifacts
        rm -rf "$GRAPH_DIR"
        echo "Graphify artifacts removed."
        ;;

    status)
        STATE=$(get_state)
        echo "--- Graphify Status ---"
        echo "Flag in AGENTS.md: $STATE"
        
        if command -v graphify &> /dev/null; then
            echo "Engine: Found ($(which graphify))"
        else
            echo "Engine: MISSING"
        fi

        if [ -d "$GRAPH_DIR" ]; then
            echo "Artifacts: Present ($GRAPH_DIR)"
            if [ -f "$GRAPH_FILE" ]; then
                echo "Graph: Found ($(du -h "$GRAPH_FILE" | cut -f1))"
            fi
        else
            echo "Artifacts: Missing"
        fi
        ;;

    query|explain|update|path)
        check_engine
        graphify $COMMAND $SHIFT_ARGS
        ;;

    *)
        echo "Usage: $0 {verify|init|on|off|status|query|explain|update|path}"
        exit 1
        ;;
esac
