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
    install)
        echo "Running native Antigravity installation..."
        uv tool run --from graphifyy graphify antigravity install
        set_state "enabled"
        ;;
    
    init)
        echo "Initializing knowledge graph..."
        uv tool run --from graphifyy graphify .
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
        # Run native engine uninstall
        uv tool run --from graphifyy graphify antigravity uninstall || true
        
        # Remove Graphify section from AGENTS.md
        if [ -f "$AGENTS_FILE" ]; then
            # Delete from ## Graphify to the end of the block
            sed -i '/## Graphify/,/^- \*\*Engine\*\*:.*/d' "$AGENTS_FILE"
        fi
        
        # Remove artifacts
        rm -rf "$GRAPH_DIR"
        echo "Graphify uninstalled successfully."
        ;;

    status)
        STATE=$(get_state)
        echo "--- Graphify Status ---"
        echo "Flag in AGENTS.md: $STATE"
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
        # Pass through to uv tool run
        uv tool run --from graphifyy graphify $COMMAND $SHIFT_ARGS
        ;;

    *)
        echo "Usage: $0 {install|init|on|off|status|query|explain|update|path}"
        exit 1
        ;;
esac
