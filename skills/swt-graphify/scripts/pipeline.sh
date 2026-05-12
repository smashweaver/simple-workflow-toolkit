#!/bin/bash
set -e

COMMAND=$1
PROJECT_ROOT=${2:-.}

PYTHON="/home/jason/.local/share/uv/tools/graphifyy/bin/python"
GRAPHIFY_DIR="$PROJECT_ROOT/graphify-out"
CACHE_DIR="$GRAPHIFY_DIR/.cache"
CACHE_AST="$CACHE_DIR/ast.json"
CACHE_SEM="$CACHE_DIR/semantic.json"

mkdir -p "$GRAPHIFY_DIR" "$CACHE_DIR"

run_step() {
    echo "[$(date +%H:%M:%S)] $1"
}

case $COMMAND in
    full)
        run_step "Detect files..."
        $PYTHON -c "
import json
from pathlib import Path
from graphify.detect import detect
result = detect(Path('$PROJECT_ROOT'))
with open('$CACHE_DIR/detect.json', 'w') as f:
    json.dump(result, f, indent=2)
"
        run_step "Extract code AST..."
        $PYTHON -c "
import json
from pathlib import Path
from graphify.extract import extract
d = json.load(open('$CACHE_DIR/detect.json'))
files = [Path('$PROJECT_ROOT') / f for f in d.get('files', {}).get('code', [])]
result = extract(files)
with open('$CACHE_AST', 'w') as f:
    json.dump(result, f, indent=2)
"
        run_step "Extract semantic from docs..."
        $PYTHON "$PROJECT_ROOT/skills/swt-graphify/scripts/extract_docs.py" full "$PROJECT_ROOT" > "$CACHE_SEM"
        run_step "Merge and build graph..."
        $PYTHON -c "
import json
from graphify.build import build_merge
from graphify.export import to_json
from graphify.cluster import cluster
ast_data = json.load(open('$CACHE_AST'))
sem_data = json.load(open('$CACHE_SEM'))
G = build_merge([ast_data, sem_data], directed=False)
communities = cluster(G)
to_json(G, communities, '$GRAPHIFY_DIR/graph.json', force=True)
"
        run_step "Export HTML..."
        $PYTHON -c "
import json
from pathlib import Path
from graphify.build import build_from_json
from graphify.cluster import cluster
from graphify.export import to_html
data = json.load(open('$GRAPHIFY_DIR/graph.json'))
G = build_from_json(data, directed=False)
communities = cluster(G)
node_degrees = dict(G.degree())
def community_label(community_nodes):
    best, best_deg = None, -1
    for n in community_nodes:
        if node_degrees.get(n, 0) > best_deg:
            best_deg = node_degrees[n]
            best = n
    if not best:
        return f'Community {community_nodes[0][:12]}'
    for node in data['nodes']:
        if node.get('id') == best:
            return node.get('label', best)
    return best
community_labels = {cid: community_label(nodes) for cid, nodes in communities.items()}
to_html(G, communities, '$GRAPHIFY_DIR/graph.html', community_labels=community_labels)
"
        run_step "Write report..."
        $PYTHON -c "
import json
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.report import generate as generate_report
data = json.load(open('$GRAPHIFY_DIR/graph.json'))
G = build_from_json(data, directed=False)
communities = cluster(G)
cohesion = score_all(G, communities)
node_degrees = dict(G.degree())
def community_label(community_nodes):
    best, best_deg = None, -1
    for n in community_nodes:
        if node_degrees.get(n, 0) > best_deg:
            best_deg = node_degrees[n]
            best = n
    if not best:
        return f'Community {community_nodes[0][:12]}'
    for node in data['nodes']:
        if node.get('id') == best:
            return node.get('label', best)
    return best
community_labels = {cid: community_label(nodes) for cid, nodes in communities.items()}
god = sorted([(n, d) for n, d in node_degrees.items()], key=lambda x: -x[1])[:10]
god_list = [{'id': n, 'label': n, 'degree': d} for n, d in god]
detection_result = {'total_files': len(data.get('nodes', [])), 'total_words': 0, 'file_types': {}}
report = generate_report(G, communities, cohesion, community_labels, god_list, [], detection_result, {}, '$PROJECT_ROOT')
with open('$GRAPHIFY_DIR/GRAPH_REPORT.md', 'w') as f:
    f.write(report)
print(f'Nodes: {G.number_of_nodes()}, Edges: {G.number_of_edges()}, Communities: {len(communities)}')
"
        run_step "Done. Graph saved to $GRAPHIFY_DIR"
        ;;

    up)
        run_step "Incremental update..."
        if [ -f "$GRAPHIFY_DIR/graph.json" ]; then
            run_step "Detect changed files..."
            $PYTHON -c "
import json
from pathlib import Path
from graphify.detect import detect_incremental
result = detect_incremental(Path('$PROJECT_ROOT'))
with open('$CACHE_DIR/detect.json', 'w') as f:
    json.dump(result, f, indent=2)
"
            run_step "Extract changed AST..."
            $PYTHON -c "
import json
from pathlib import Path
from graphify.extract import extract
d = json.load(open('$CACHE_DIR/detect.json'))
files = [Path('$PROJECT_ROOT') / f for f in d.get('files', {}).get('code', [])]
result = extract(files)
with open('$CACHE_AST', 'w') as f:
    json.dump(result, f, indent=2)
"
            run_step "Extract semantic from docs..."
            $PYTHON "$PROJECT_ROOT/skills/swt-graphify/scripts/extract_docs.py" full "$PROJECT_ROOT" > "$CACHE_SEM"
            run_step "Merge with existing graph (GlobalTwin rehydration)..."
            $PYTHON -c "
import json
from graphify.build import build_merge
from graphify.export import to_json
from graphify.cluster import cluster
ast_data = json.load(open('$CACHE_AST'))
sem_data = json.load(open('$CACHE_SEM'))
G = build_merge([ast_data, sem_data], directed=False)
communities = cluster(G)
to_json(G, communities, '$GRAPHIFY_DIR/graph.json', force=True)
print(f'Nodes: {G.number_of_nodes()}, Edges: {G.number_of_edges()}, Communities: {len(communities)}')
"
            run_step "Export HTML..."
            $PYTHON -c "
import json
from graphify.build import build_from_json
from graphify.cluster import cluster
from graphify.export import to_html
from graphify.cluster import score_all
from graphify.report import generate as generate_report
data = json.load(open('$GRAPHIFY_DIR/graph.json'))
G = build_from_json(data, directed=False)
communities = cluster(G)
cohesion = score_all(G, communities)
node_degrees = dict(G.degree())
def community_label(community_nodes):
    best, best_deg = None, -1
    for n in community_nodes:
        if node_degrees.get(n, 0) > best_deg:
            best_deg = node_degrees[n]
            best = n
    if not best:
        return f'Community {community_nodes[0][:12]}'
    for node in data['nodes']:
        if node.get('id') == best:
            return node.get('label', best)
    return best
community_labels = {cid: community_label(nodes) for cid, nodes in communities.items()}
to_html(G, communities, '$GRAPHIFY_DIR/graph.html', community_labels=community_labels)
god = sorted([(n, d) for n, d in node_degrees.items()], key=lambda x: -x[1])[:10]
god_list = [{'id': n, 'label': n, 'degree': d} for n, d in god]
detection_result = {'total_files': len(data.get('nodes', [])), 'total_words': 0, 'file_types': {}}
report = generate_report(G, communities, cohesion, community_labels, god_list, [], detection_result, {}, '$PROJECT_ROOT')
with open('$GRAPHIFY_DIR/GRAPH_REPORT.md', 'w') as f:
    f.write(report)
"
        else
            $0 full "$PROJECT_ROOT"
        fi
        run_step "Done."
        ;;

    *)
        echo "Usage: $0 {full|up} [project_root]"
        exit 1
        ;;
esac
