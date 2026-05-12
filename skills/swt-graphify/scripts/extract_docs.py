#!/usr/bin/env python3
import sys
import os
import re
import json
import glob
from pathlib import Path

def slugify(text):
    text = text.lower()
    text = re.sub(r'[^a-z0-9\s_]', '', text)
    text = re.sub(r'[\s_]+', '_', text.strip())
    return text or 'unknown'

def extract_yaml_frontmatter(content):
    nodes = []
    edges = []
    fm = {}
    fm_match = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
    if not fm_match:
        return fm, nodes, edges
    for line in fm_match.group(1).splitlines():
        m = re.match(r'^(\w+):\s*(.*)', line)
        if m:
            fm[m.group(1)] = m.group(2).strip()
    name = fm.get('name')
    if name:
        sid = slugify(name)
        nodes.append({"id": sid, "label": name, "file_type": "rationale", "source_file": ""})
    for parent in re.findall(r'inherits:\s*([^\n]+)', fm_match.group(1)):
        parent = parent.strip()
        if parent:
            pid = slugify(parent)
            pid = "swt_" + pid if not pid.startswith("swt_") else pid
            edges.append({"source": pid, "target": pid, "relation": "inherits", "confidence": "EXTRACTED", "confidence_score": 1.0, "source_file": ""})
    return fm, nodes, edges

def extract_headings(content):
    nodes = []
    for m in re.finditer(r'^##\s+(.+)$', content, re.MULTILINE):
        title = m.group(1).strip()
        sid = slugify(title)
        nodes.append({"id": sid, "label": title, "file_type": "rationale", "source_file": ""})
    return nodes

def extract_links(content, current_file, source_file):
    nodes = []
    edges = []
    file_map = {}
    base = os.path.dirname(current_file)
    for m in re.finditer(r'\[([^\]]+)\]\(([^\)]+\.md)\)', content):
        label = m.group(1).strip()
        path = m.group(2)
        path = re.sub(r'^#.*', '', path)
        if not path.endswith('.md'):
            path += '.md'
        if path.startswith('/'):
            full = path.lstrip('/')
        elif base:
            full = os.path.normpath(os.path.join(base, path))
        else:
            full = path
        if full not in file_map:
            file_map[full] = slugify(label)
        else:
            file_map[full] = slugify(label)
        tid = slugify(label)
        nodes.append({"id": tid, "label": label, "file_type": "rationale", "source_file": path})
        cid = slugify(os.path.splitext(os.path.basename(current_file))[0])
        edges.append({"source": cid, "target": tid, "relation": "references", "confidence": "EXTRACTED", "confidence_score": 1.0, "source_file": source_file})
    return nodes, edges

def extract_code_fences(content):
    nodes = []
    seen = set()
    for m in re.finditer(r'^```(\w+)\s*$', content, re.MULTILINE):
        lang = m.group(1).strip()
        if lang in ('sh', 'bash', 'python', 'python3', 'js', 'typescript', 'ts', 'json', 'yaml', 'yml', 'toml', 'html', 'css', 'sql'):
            sid = f"lang_{lang}"
            if sid not in seen:
                seen.add(sid)
                nodes.append({"id": sid, "label": f"{lang} code", "file_type": "code", "source_file": ""})
    return nodes

def extract_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception:
        return [], []

    fm, fm_nodes, fm_edges = extract_yaml_frontmatter(content)
    link_nodes, link_edges = extract_links(content, filepath, filepath)
    code_nodes = extract_code_fences(content)

    all_nodes = fm_nodes + link_nodes + code_nodes
    all_edges = fm_edges + link_edges

    dedup = {}
    for n in all_nodes:
        key = n["id"]
        if key not in dedup:
            n["source_file"] = filepath
            dedup[key] = n
        else:
            if not dedup[key]["source_file"]:
                dedup[key]["source_file"] = filepath

    return list(dedup.values()), all_edges

def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "full"
    project_root = sys.argv[2] if len(sys.argv) > 2 else "."

    md_files = glob.glob(os.path.join(project_root, "**/*.md"), recursive=True)
    md_files = [f for f in md_files if '/graphify-out/' not in f and '/.git/' not in f]

    all_nodes = []
    all_edges = []
    seen_edges = set()

    for fpath in md_files:
        nodes, edges = extract_file(fpath)
        for n in nodes:
            if n not in all_nodes:
                all_nodes.append(n)
        for e in edges:
            key = (e["source"], e["target"], e["relation"])
            if key not in seen_edges:
                seen_edges.add(key)
                all_edges.append(e)

    result = {"nodes": all_nodes, "edges": all_edges}
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
