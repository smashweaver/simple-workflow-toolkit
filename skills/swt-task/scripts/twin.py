# /// script
# dependencies = ["markdown-it-py", "argparse", "jinja2"]
# ///

import sys
import os
import argparse
import json
import re
from datetime import datetime
from markdown_it import MarkdownIt

class GlobalTwin:
    def __init__(self, md_path, template_path=None):
        self.md_path = md_path
        self.json_path = f"{md_path}.json"
        self.template_path = template_path
        self.md_parser = MarkdownIt()
        self.state = {
            "version": "1.0",
            "template": os.path.basename(template_path) if template_path else None,
            "meta": {},
            "sections": {},
            "checklists": {},
            "updated_at": datetime.now().isoformat()
        }

    def harvest(self):
        """Extracts metadata, sections, and checklists from Markdown to JSON."""
        if not os.path.exists(self.md_path):
            return self.state

        with open(self.md_path, 'r') as f:
            content = f.read()

        lines = content.splitlines()
        tokens = self.md_parser.parse(content)

        # 1. Harvest Metadata (**Key**: Value)
        # Search preamble (before first ##)
        for line in lines:
            if line.startswith("## "): break
            match = re.match(r'^\*\*?([^*:]+)\*\*?:\s*(.*)', line)
            if match:
                key = match.group(1).strip()
                value = match.group(2).strip()
                # Remove HTML comments from value
                value = re.sub(r'<!--.*?-->', '', value).strip()
                self.state["meta"][key] = value

        # 2. Harvest Sections and Checklists
        headers = []
        for i, token in enumerate(tokens):
            if token.type == "heading_open" and token.tag == "h2":
                header_text = tokens[i+1].content.strip()
                headers.append({
                    "name": header_text,
                    "start": token.map[0]
                })

        for i, h in enumerate(headers):
            end = headers[i+1]["start"] if i + 1 < len(headers) else len(lines)
            section_lines = lines[h["start"]+1:end]
            section_content = "\n".join(section_lines).strip()
            
            # Identify if it's a checklist
            checklist_items = []
            for line in section_lines:
                item_match = re.match(r'^\s*-\s*\[([ xX/])\]\s*(.*)', line)
                if item_match:
                    checklist_items.append({
                        "status": item_match.group(1),
                        "text": item_match.group(2).strip()
                    })
            
            if checklist_items:
                self.state["checklists"][h["name"]] = checklist_items
            else:
                self.state["sections"][h["name"]] = section_content

        return self.state

    def save_state(self):
        """Persists the current state to the sidecar JSON file."""
        with open(self.json_path, 'w') as f:
            json.dump(self.state, f, indent=2)
        print(f"✅ State persisted: {self.json_path}")

    def load_state(self):
        """Loads state from the sidecar JSON file."""
        if os.path.exists(self.json_path):
            with open(self.json_path, 'r') as f:
                self.state = json.load(f)
        return self.state

    def synthesize(self, force_template=False):
        """Re-renders Markdown from JSON state + template."""
        if not self.template_path or not os.path.exists(self.template_path):
            print(f"⚠️ No template found. Falling back to basic synthesis.")
            self._basic_synthesize()
            return

        with open(self.template_path, 'r') as f:
            template_content = f.read()

        output = template_content
        
        # 1. Inject Metadata
        # We replace {{Key}} or {{ Key }} with the value from meta
        for k, v in self.state["meta"].items():
            pattern = re.compile(r'\{\{\s*' + re.escape(k) + r'\s*\}\}')
            output = pattern.sub(v, output)
            # Also handle the header Task Title if needed
            if k == "Task":
                output = re.sub(r'# Task:\s*.*', f'# Task: {v}', output)

        # 2. Inject Sections and Checklists
        # Templates use {{SECTION_NAME}} or similar tags. 
        processed_sections = set()
        
        def clean_tag(name):
            # Strip punctuation and replace spaces with underscores
            tag = re.sub(r'[^a-zA-Z0-9\s]', '', name)
            return tag.upper().replace(' ', '_')

        for name, content in self.state["sections"].items():
            # Try both exact match and cleaned match
            tag_exact = f"{{{{{name.upper().replace(' ', '_')}}}}}"
            tag_clean = f"{{{{{clean_tag(name)}}}}}"
            
            if tag_exact in output:
                output = output.replace(tag_exact, content)
                processed_sections.add(name)
            elif tag_clean in output:
                output = output.replace(tag_clean, content)
                processed_sections.add(name)

        for name, items in self.state["checklists"].items():
            tag_exact = f"{{{{{name.upper().replace(' ', '_')}}}}}"
            tag_clean = f"{{{{{clean_tag(name)}}}}}"
            
            checklist_md = "\n".join([f"- [{item['status']}] {item['text']}" for item in items])
            
            if tag_exact in output:
                output = output.replace(tag_exact, checklist_md)
                processed_sections.add(name)
            elif tag_clean in output:
                output = output.replace(tag_clean, checklist_md)
                processed_sections.add(name)

        # Cleanup: remove any remaining {{TAGS}} that weren't filled
        output = re.sub(r'\{\{.*?\}\}', '*', output)

        # 3. Append Orphaned Sections (Preserve manual edits not in template)
        orphans = []
        for name, content in self.state["sections"].items():
            if name not in processed_sections:
                orphans.append(f"## {name}\n{content}")
        
        for name, items in self.state["checklists"].items():
            if name not in processed_sections:
                checklist_md = "\n".join([f"- [{item['status']}] {item['text']}" for item in items])
                orphans.append(f"## {name}\n{checklist_md}")

        if orphans:
            output += "\n\n" + "\n\n".join(orphans) + "\n"

        with open(self.md_path, 'w') as f:
            f.write(output)
        print(f"✨ Document synthesized from template: {self.md_path}")

    def _basic_synthesize(self):
        """Reconstructs Markdown without a template guide."""
        output = []
        title = self.state["meta"].get("Task", os.path.basename(self.md_path))
        output.append(f"# Task: {title}")
        for k, v in self.state["meta"].items():
            if k == "Task": continue
            output.append(f"**{k}**: {v}")
        output.append("")
        for name, content in self.state["sections"].items():
            output.append(f"## {name}")
            output.append(content)
            output.append("")
        for name, items in self.state["checklists"].items():
            output.append(f"## {name}")
            for item in items:
                output.append(f"- [{item['status']}] {item['text']}")
            output.append("")
        with open(self.md_path, 'w') as f:
            f.write("\n".join(output))
        print(f"✨ Document synthesized (basic): {self.md_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SWT Global Twin Engine")
    parser.add_argument("file", help="Markdown file to process")
    parser.add_argument("--harvest", action="store_true", help="MD -> JSON")
    parser.add_argument("--synthesize", action="store_true", help="JSON -> MD")
    parser.add_argument("--template", help="Template to use for synthesis")
    parser.add_argument("--out", help="Alternative output Markdown path")
    parser.add_argument("--state", help="Alternative input JSON state path")
    
    # State Modification Flags
    parser.add_argument("--set-meta", nargs=2, action="append", metavar=("KEY", "VALUE"), help="Set metadata field")
    parser.add_argument("--set-section", nargs=2, action="append", metavar=("HEADER", "CONTENT"), help="Set section content")
    parser.add_argument("--set-item", nargs=3, action="append", metavar=("LIST", "TEXT", "STATUS"), help="Set/Update checklist item")

    args = parser.parse_args()
    
    twin = GlobalTwin(args.file, template_path=args.template)
    if args.out:
        twin.md_path = args.out
        twin.json_path = f"{args.out}.json"
    
    # 1. Initial State Load (Sidecar first)
    if os.path.exists(twin.json_path):
        twin.load_state()

    # 2. Harvest from Markdown (Manual edits/Initial creation)
    if args.harvest or (not os.path.exists(twin.json_path) and os.path.exists(args.file)):
        twin.harvest()

    # 2. Merge with external state if provided
    if args.state and os.path.exists(args.state):
        with open(args.state, 'r') as f:
            new_state = json.load(f)

            # Protected Fields (Do not overwrite target identity)
            protected = ["Status", "Phase", "Version", "Linked Task", "Created", "Completed"]

            for k, v in new_state.get("meta", {}).items():
                if k not in protected or k not in twin.state["meta"]:
                    twin.state["meta"][k] = v

            # Merge sections and checklists
            twin.state["sections"].update(new_state.get("sections", {}))
            twin.state["checklists"].update(new_state.get("checklists", {}))

    # 4. Apply modifications via CLI flags
    if args.set_meta:
        for k, v in args.set_meta:
            twin.state["meta"][k] = v
            
    if args.set_section:
        for h, c in args.set_section:
            twin.state["sections"][h] = c

    if args.set_item:
        for lst, txt, stat in args.set_item:
            if lst not in twin.state["checklists"]:
                twin.state["checklists"][lst] = []
            
            # Update existing item if text matches, otherwise append
            found = False
            for item in twin.state["checklists"][lst]:
                if item["text"] == txt:
                    item["status"] = stat
                    found = True
                    break
            if not found:
                twin.state["checklists"][lst].append({"text": txt, "status": stat})

    # 5. Finalize Sidecar State
    if args.harvest or args.set_meta or args.set_section or args.set_item:
        twin.state["updated_at"] = datetime.now().isoformat()
        twin.save_state()
    
    # 6. Synthesize if requested
    if args.synthesize:
        twin.synthesize()
