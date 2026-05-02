# /// script
# dependencies = ["markdown-it-py", "argparse"]
# ///

import sys
import os
import argparse
import json
from markdown_it import MarkdownIt

def get_section_map(content):
    """
    Parses Markdown and returns a map of Header -> (start_line, end_line).
    Line numbers are 0-indexed.
    """
    md = MarkdownIt()
    tokens = md.parse(content)
    lines = content.splitlines()
    num_lines = len(lines)
    
    section_map = {}
    headers = []
    
    # Identify all H2 headers and their line offsets
    for i, token in enumerate(tokens):
        if token.type == "heading_open" and token.tag == "h2":
            header_text = tokens[i+1].content.strip()
            # token.map is [start_line, end_line]
            headers.append({
                "name": header_text,
                "start": token.map[0]
            })
            
    # Calculate end lines for each section
    for i, h in enumerate(headers):
        # End line is the line before the next header, or end of file
        end = headers[i+1]["start"] if i + 1 < len(headers) else num_lines
        section_map[h["name"]] = (h["start"], end)
        
    return section_map

def patch_file(filepath, patches, metas):
    """
    Surgically patches sections and metadata in a file.
    """
    if not os.path.exists(filepath):
        print(f"Error: File not found: {filepath}")
        return False

    with open(filepath, 'r') as f:
        content = f.read()
    
    lines = content.splitlines()
    
    # 1. Handle Metadata Patches (**Key**: Value)
    # Metadata is usually in the preamble (before first ##)
    for key, value in metas.items():
        key_found = False
        for i, line in enumerate(lines):
            if line.startswith(f"**{key}**:") or line.startswith(f"**{key}:**"):
                lines[i] = f"**{key}**: {value}"
                key_found = True
                break
            # Stop if we hit a header
            if line.startswith("## "): break
        
        if not key_found:
            # If metadata not found, insert at top after # Title
            if len(lines) > 1 and lines[0].startswith("# "):
                lines.insert(1, f"**{key}**: {value}")
            else:
                lines.insert(0, f"**{key}**: {value}")

    # 2. Handle Section Patches
    # We apply patches in REVERSE order to avoid line offset shifts
    section_map = get_section_map("\n".join(lines))
    
    # Sort patches based on their current start line in the file
    sorted_patches = []
    for header, new_content in patches.items():
        if header in section_map:
            sorted_patches.append((header, new_content, section_map[header][0]))
        else:
            # Missing header: Append to end
            sorted_patches.append((header, new_content, float('inf')))

    # Sort reverse by start line
    sorted_patches.sort(key=lambda x: x[2], reverse=True)

    for header, new_content, start_line in sorted_patches:
        if start_line == float('inf'):
            # Append missing section
            lines.append("")
            lines.append(f"## {header}")
            lines.append(new_content.strip())
        else:
            start, end = section_map[header]
            # Replace lines from Header+1 to End
            # We preserve the header line itself
            del lines[start+1:end]
            lines.insert(start+1, new_content.strip())
            # Refresh map after each patch if we had multiple (not needed if reverse sorting is perfect)

    # 3. Atomic Write
    tmp_path = f"{filepath}.tmp"
    with open(tmp_path, 'w') as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp_path, filepath)
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Crow: Surgical Markdown Patcher")
    parser.add_argument("file", help="Markdown file to patch")
    parser.add_argument("--patch", nargs=2, action="append", help="Section header and new content")
    parser.add_argument("--meta", nargs=2, action="append", help="Metadata Key and Value")
    parser.add_argument("--batch", help="JSON file with {patches: {}, metas: {}}")
    
    args = parser.parse_args()
    
    patches = {}
    metas = {}
    
    if args.patch:
        for h, c in args.patch: patches[h] = c
    
    if args.meta:
        for k, v in args.meta: metas[k] = v
        
    if args.batch and os.path.exists(args.batch):
        with open(args.batch, 'r') as f:
            batch_data = json.load(f)
            patches.update(batch_data.get("patches", {}))
            metas.update(batch_data.get("metas", {}))
            
    if patch_file(args.file, patches, metas):
        print(f"✅ Surgically patched {args.file}")
    else:
        sys.exit(1)
