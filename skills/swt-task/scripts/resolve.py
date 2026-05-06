#!/usr/bin/env python3
import os
import sys
import argparse

def resolve(task_input, root_dir):
    """
    Resolves a task input (timestamp, partial name, or path) to a full absolute path.
    """
    # Normalize input
    task_input = task_input.strip()
    if not task_input:
        return None

    # 1. Check if it's already a valid path (absolute or relative to CWD)
    if os.path.isfile(task_input):
        return os.path.abspath(task_input)
    
    # 2. Check if it's relative to the root_dir
    root_rel_path = os.path.join(root_dir, task_input)
    if os.path.isfile(root_rel_path):
        return os.path.abspath(root_rel_path)

    # 3. Search in .tasks, .tasks/archive, .digests, and .specs
    search_dirs = [
        os.path.join(root_dir, ".tasks"),
        os.path.join(root_dir, ".tasks/archive"),
        os.path.join(root_dir, ".digests"),
        os.path.join(root_dir, ".digests/archive"),
        os.path.join(root_dir, ".specs")
    ]
    
    # Priority 1: Exact timestamp/prefix match (e.g. 20260506100443)
    for d in search_dirs:
        if not os.path.isdir(d):
            continue
        
        # Check for exact filename match first
        exact_match = os.path.join(d, task_input)
        if os.path.isfile(exact_match):
            return os.path.abspath(exact_match)
            
        # Check for exact match with .md extension
        exact_md = os.path.join(d, f"{task_input}.md")
        if os.path.isfile(exact_md):
            return os.path.abspath(exact_md)
        
        # Prefix match (handles timestamp-only inputs)
        # We sort to ensure we get the most recent if there are multiple (unlikely for timestamp)
        matches = [f for f in os.listdir(d) if f.startswith(task_input) and f.endswith(".md")]
        if matches:
            matches.sort(reverse=True)
            return os.path.abspath(os.path.join(d, matches[0]))

    # Priority 2: Fuzzy slug match (if the input is part of the name)
    for d in search_dirs:
        if not os.path.isdir(d):
            continue
        matches = [f for f in os.listdir(d) if task_input in f and f.endswith(".md")]
        if matches:
            matches.sort(reverse=True)
            return os.path.abspath(os.path.join(d, matches[0]))
                
    return None

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Smart Task Resolver")
    parser.add_argument("input", help="Task timestamp, partial name, or path")
    parser.add_argument("--root", help="Workspace root directory")
    args = parser.parse_args()
    
    # Determine root directory if not provided
    root = args.root
    if not root:
        root = os.getcwd()
        while root != "/" and not os.path.exists(os.path.join(root, "AGENTS.md")):
            root = os.path.dirname(root)

    result = resolve(args.input, root)
    if result:
        print(result)
        sys.exit(0)
    else:
        # Failure: print nothing to stdout, exit with error
        sys.exit(1)
