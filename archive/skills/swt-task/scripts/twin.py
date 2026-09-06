# /// script
# dependencies = ["markdown-it-py", "argparse", "jinja2", "pyyaml"]
# ///

import sys
import os
import argparse
import yaml
import re
import json
from datetime import datetime
from markdown_it import MarkdownIt

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SWT Dashboard - {task_title}</title>
    <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {{
            /* ☀️ LIGHT THEME DEFAULTS */
            --bg-color: #f3f4f6;
            --card-bg: #ffffff;
            --border-color: #e5e7eb;
            --text-primary: #111827;
            --text-secondary: #4b5563;
            --text-content: #374151;
            --accent-cyan: #0284c7;
            --success-color: #059669;
            --pending-color: #d97706;
            --code-bg: #f1f5f9;
            --pre-bg: #f8fafc;
            --code-text: #db2777;
        }}

        @media (prefers-color-scheme: dark) {{
            :root {{
                /* 🌙 AUTOMATIC DARK THEME OVERRIDES */
                --bg-color: #0b0c10;
                --card-bg: #111216;
                --border-color: #1f2937;
                --text-primary: #f3f4f6;
                --text-secondary: #9ca3af;
                --text-content: #d1d5db;
                --accent-cyan: #38bdf8;
                --success-color: #34d399;
                --pending-color: #fbbf24;
                --code-bg: #1e1e24;
                --pre-bg: #18181c;
                --code-text: #f472b6;
            }}
        }}

        body {{
            background-color: var(--bg-color);
            color: var(--text-primary);
            font-family: 'Fira Code', monospace;
            font-size: 14px;
            margin: 0;
            padding: 40px 20px;
            display: flex;
            justify-content: center;
        }}

        .container {{
            max-width: 95%;
            width: 100%;
        }}

        .container.narrow {{
            max-width: 1000px;
        }}

        .card {{
            border: none;
            background-color: transparent;
            border-radius: 0;
            padding: 40px 0;
            box-shadow: none;
            margin-bottom: 24px;
        }}

        .container.narrow .card {{
            border: 1px solid var(--border-color);
            background-color: var(--card-bg);
            border-radius: 8px;
            padding: 40px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
        }}

        header {{
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 24px;
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }}

        .task-title {{
            font-size: 22px;
            font-weight: 700;
            margin: 0 0 10px 0;
            color: var(--accent-cyan);
        }}

        .task-meta-row {{
            display: flex;
            flex-wrap: wrap;
            gap: 16px;
            color: var(--text-secondary);
            font-size: 12px;
        }}

        .badge {{
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            display: inline-block;
        }}

        .badge-status {{
            background: rgba(251, 191, 36, 0.1);
            color: var(--pending-color);
            border: 1px solid rgba(251, 191, 36, 0.2);
        }}

        .badge-status-completed {{
            background: rgba(52, 211, 153, 0.1);
            color: var(--success-color);
            border: 1px solid rgba(52, 211, 153, 0.2);
        }}

        .badge-status-markdown {{
            background: rgba(167, 139, 250, 0.1);
            color: #a78bfa;
            border: 1px solid rgba(167, 139, 250, 0.2);
        }}

        .badge-phase {{
            background: rgba(56, 189, 248, 0.1);
            color: var(--accent-cyan);
            border: 1px solid rgba(56, 189, 248, 0.2);
        }}

        .badge-priority {{
            background: rgba(248, 113, 113, 0.1);
            color: #f87171;
            border: 1px solid rgba(248, 113, 113, 0.2);
        }}

        h2 {{
            font-size: 15px;
            font-weight: 600;
            margin-top: 0;
            margin-bottom: 16px;
            color: var(--accent-cyan);
        }}

        .section-content {{
            color: var(--text-content);
            line-height: 1.6;
        }}

        .section-content p {{
            margin-top: 0;
            margin-bottom: 16px;
        }}

        .section-content code {{
            background: var(--code-bg);
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Fira Code', monospace;
            font-size: 13px;
            color: var(--code-text);
        }}

        .section-content pre {{
            background: var(--pre-bg);
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            border: 1px solid var(--border-color);
            margin-bottom: 16px;
        }}

        .section-content pre code {{
            background: none;
            padding: 0;
            color: inherit;
        }}

        .section-content a {{
            color: var(--accent-cyan);
            text-decoration: none;
        }}

        .section-content a:hover {{
            text-decoration: underline;
        }}

        .section-content ul, .section-content ol {{
            margin-top: 0;
            margin-bottom: 16px;
            padding-left: 20px;
        }}

        .section-content li {{
            margin-bottom: 8px;
        }}

        .checklist-item {{
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 8px 0;
        }}

        .checkbox {{
            font-family: 'Fira Code', monospace;
            font-size: 14px;
            font-weight: 600;
            flex-shrink: 0;
        }}

        .checkbox-checked {{
            color: var(--success-color);
        }}

        .checkbox-partial {{
            color: var(--pending-color);
        }}

        .checkbox-unchecked {{
            color: var(--text-secondary);
        }}

        .item-text {{
            font-size: 14px;
        }}

        .item-text-completed {{
            color: var(--text-secondary);
            text-decoration: line-through;
            opacity: 0.7;
        }}

        .mermaid {{
            display: flex;
            justify-content: center;
            margin: 20px 0;
            background: var(--pre-bg);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 20px;
        }}

        .header-badges {{
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 8px;
        }}

        .toggle-btn {{
            background: none;
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            border-radius: 4px;
            padding: 2px 6px;
            font-family: inherit;
            font-size: 10px;
            cursor: pointer;
            transition: all 0.2s ease;
            outline: none;
        }}

        .toggle-btn:hover {{
            border-color: var(--accent-cyan);
            color: var(--accent-cyan);
            background: rgba(0, 240, 255, 0.05);
        }}

        @media (max-width: 768px) {{
            body {{
                padding: 20px 10px;
            }}
            .card {{
                padding: 20px 0;
            }}
            .container.narrow .card {{
                padding: 20px;
            }}
            header {{
                flex-direction: column;
                gap: 16px;
                align-items: stretch;
            }}
            .header-badges {{
                align-items: flex-start;
            }}
            .mermaid {{
                padding: 10px;
                overflow-x: auto;
            }}
            pre {{
                overflow-x: auto;
            }}
        }}
    </style>
    <script type="module">
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
        const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        mermaid.initialize({{ startOnLoad: false, theme: isDark ? 'dark' : 'default' }});
        
        document.addEventListener("DOMContentLoaded", async () => {{
            // Fluid/Narrow Width Toggle Control
            const container = document.querySelector(".container");
            const toggleBtn = document.getElementById("width-toggle");
            
            // Default to fluid unless narrow preference is saved
            if (localStorage.getItem("swt-fluid-width") === "false") {{
                container.classList.add("narrow");
                toggleBtn.textContent = "↔";
                toggleBtn.title = "Toggle Full Width";
            }} else {{
                toggleBtn.textContent = "→🔀←";
                toggleBtn.title = "Toggle Normal Width";
            }}
            
            toggleBtn.addEventListener("click", () => {{
                const isNarrow = container.classList.toggle("narrow");
                localStorage.setItem("swt-fluid-width", !isNarrow);
                if (isNarrow) {{
                    toggleBtn.textContent = "↔";
                    toggleBtn.title = "Toggle Full Width";
                }} else {{
                    toggleBtn.textContent = "→🔀←";
                    toggleBtn.title = "Toggle Normal Width";
                }}
            }});

            const mermaidCodes = document.querySelectorAll("pre code.language-mermaid");
            for (const codeEl of mermaidCodes) {{
                const preEl = codeEl.parentElement;
                const graphDefinition = codeEl.textContent;
                const insertDiv = document.createElement("div");
                insertDiv.className = "mermaid";
                insertDiv.textContent = graphDefinition;
                preEl.parentElement.replaceChild(insertDiv, preEl);
            }}
            await mermaid.run();
        }});
    </script>
</head>
<body>
    <div class="container">
        <div class="card">
            <header>
                <div>
                    <h1 class="task-title">{task_title}</h1>
                    {meta_row_html}
                </div>
                {badges_container_html}
            </header>

            {dynamic_cards}
        </div>
    </div>

    <!-- 💾 EMBEDDED JSON DATABASE STATE -->
    <script id="swt-metadata" type="application/json">
{json_metadata}
    </script>
</body>
</html>
"""

class GlobalTwin:
    SECTION_CROSSWALK = {
        "Objective": "1_PROBLEM_STATEMENT",
        "Goals": "2_GOALS",
        "Explored Alternatives": "3_PROPOSED_SOLUTION",
        "User Stories": "4_USER_STORIES",
        "Success Criteria": "8_SUCCESS_CRITERIA",
        "MVP Definition": "12_MVP_DEFINITION",
    }

    META_CROSSWALK = {
        "Task": ["TASK_NAME", "TASK_TITLE"],
        "Version": ["VERSION"],
        "Status": ["STATUS"],
        "Linked Task": ["LINKED_TASK"],
        "Spec": ["SPEC_LINK", "SPEC_FILE"],
    }

    def __init__(self, md_path, template_path=None):
        self.md_path = md_path
        self.yaml_path = f"{md_path}.yaml"
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
        """Extracts metadata, sections, and checklists from Markdown or HTML to JSON."""
        if not os.path.exists(self.md_path):
            return self.state

        if self.md_path.endswith('.html'):
            self.state = self.extract_metadata_from_html(self.md_path)
            return self.state

        with open(self.md_path, 'r') as f:
            content = f.read()

        lines = content.splitlines()
        tokens = self.md_parser.parse(content)

        # 1. Harvest Metadata (**Key**: Value)
        for line in lines:
            if line.startswith("## "): break
            title_match_generic = re.match(r'^#\s*(.*)', line)
            if title_match_generic and "Task" not in self.state["meta"]:
                title_val = title_match_generic.group(1).strip()
                # Clean up prefixes if present
                if title_val.lower().startswith("task:"):
                    title_val = title_val[5:].strip()
                elif title_val.lower().startswith("spec:"):
                    title_val = title_val[5:].strip()
                self.state["meta"]["Task"] = title_val
                continue
            match = re.match(r'^\*\*?([^*:]+)\*\*?:\s*(.*)', line)
            if match:
                key = match.group(1).strip()
                value = match.group(2).strip()
                value = re.sub(r'<!--.*?-->', '', value).strip()
                self.state["meta"][key] = value

        # 2. Harvest Sections and Checklists
        headers = []
        for i, token in enumerate(tokens):
            if token.type == "heading_open" and token.tag in ("h2", "h3"):
                header_text = tokens[i+1].content.strip()
                headers.append({
                    "name": header_text,
                    "start": token.map[0]
                })

        for i, h in enumerate(headers):
            end = headers[i+1]["start"] if i + 1 < len(headers) else len(lines)
            section_lines = lines[h["start"]+1:end]
            section_content = "\n".join(section_lines).strip()
            
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

    def is_system_path(self):
        """Checks if the path is in a system directory (.tasks/, .specs/, or .digests/)."""
        norm = os.path.normpath(self.md_path)
        parts = norm.split(os.sep)
        return any(x in parts for x in (".tasks", ".specs", ".digests"))

    def save_state(self):
        """Persists the current state to the sidecar YAML file."""
        if self.is_system_path() or self.md_path.endswith('.html'):
            return
        with open(self.yaml_path, 'w') as f:
            yaml.dump(self.state, f, default_flow_style=False, allow_unicode=True)
        print(f"✅ State persisted: {self.yaml_path}")

    def load_state(self):
        """Loads state from the sidecar YAML file."""
        if self.md_path.endswith('.html'):
            if os.path.exists(self.md_path):
                self.state = self.extract_metadata_from_html(self.md_path)
            return self.state
        if self.is_system_path():
            return self.state
        if os.path.exists(self.yaml_path):
            with open(self.yaml_path, 'r') as f:
                self.state = yaml.safe_load(f) or self.state
        elif os.path.exists(self.json_path):
            import json as _json
            try:
                with open(self.json_path, 'r') as f:
                    self.state = _json.load(f)
                self.save_state()
                os.remove(self.json_path)
            except Exception as e:
                print(f"⚠️  Failed to migrate legacy JSON: {e}")
        return self.state

    def extract_metadata_from_html(self, html_path):
        """Surgically extracts and parses the JSON metadata block inside the HTML file."""
        with open(html_path, "r") as f:
            content = f.read()
        
        start_tag = '<script id="swt-metadata" type="application/json">'
        end_tag = '</script>'
        
        start_idx = content.find(start_tag)
        if start_idx == -1:
            raise ValueError(f"Could not find start of swt-metadata block in {html_path}!")
            
        start_idx += len(start_tag)
        end_idx = content.find(end_tag, start_idx)
        
        if end_idx == -1:
            raise ValueError(f"Could not find end of swt-metadata block in {html_path}!")
            
        json_str = content[start_idx:end_idx].strip()
        return json.loads(json_str)

    def compile_state_to_html(self, state_dict):
        """Renders the standard state dictionary into visual HTML and embeds the JSON."""
        meta = state_dict.get("meta", {})
        sections = state_dict.get("sections", {})
        checklists = state_dict.get("checklists", {})
        
        priority = meta.get("Priority", "low").lower()
        if priority == "high":
            priority_style = "background: rgba(239, 68, 68, 0.15); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.3);"
        elif priority == "medium":
            priority_style = "background: rgba(245, 158, 11, 0.15); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.3);"
        else:
            priority_style = "background: rgba(59, 130, 246, 0.15); color: #60a5fa; border: 1px solid rgba(59, 130, 246, 0.3);"

        dynamic_cards = []
        
        # Render dynamic section cards
        for name, content in sections.items():
            rendered_md = self.md_parser.render(content)
            if name == "Objective" or name == "Summary":
                dynamic_cards.append(f"""
            <section style="margin-bottom: 28px;">
                <h2>🎯 {name}</h2>
                <div class="section-content">{rendered_md}</div>
            </section>""")
            else:
                dynamic_cards.append(f"""
            <section style="margin-bottom: 28px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                <h2>## {name}</h2>
                <div class="section-content">{rendered_md}</div>
            </section>""")
            
        # Render dynamic checklists
        for name, items in checklists.items():
            checklist_html_list = []
            for item in items:
                status = item.get("status", " ")
                text = item.get("text", "")
                
                if status in ("x", "X"):
                    box_class = "checkbox checkbox-checked"
                    icon = "[✓]"
                    text_class = "item-text item-text-completed"
                elif status == "/":
                    box_class = "checkbox checkbox-partial"
                    icon = "[⚡]"
                    text_class = "item-text"
                else:
                    box_class = "checkbox checkbox-unchecked"
                    icon = "[ ]"
                    text_class = "item-text"
                    
                checklist_html_list.append(f"""
                <div class="checklist-item">
                    <div class="{box_class}">{icon}</div>
                    <span class="{text_class}">{text}</span>
                </div>""")
                
            checklist_html = "\n".join(checklist_html_list)
            
            dynamic_cards.append(f"""
            <section style="margin-bottom: 28px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                <h2>📋 {name}</h2>
                <div id="checklist-container">
                    {checklist_html}
                </div>
            </section>""")
            
        dynamic_cards_str = "\n".join(dynamic_cards)
        
        # Extract metadata
        meta_created = meta.get("Created")
        meta_updated = meta.get("Updated")
        meta_category = meta.get("Category")
        
        meta_row_items = []
        if meta_created and meta_created != "N/A":
            meta_row_items.append(f"<span>Created: {meta_created}</span>")
        if meta_updated and meta_updated != "N/A":
            meta_row_items.append(f"<span>Updated: {meta_updated}</span>")
        if meta_category and meta_category != "uncategorized":
            meta_row_items.append(f"<span>Category: {meta_category}</span>")
            
        meta_row_html = ""
        if meta_row_items:
            meta_row_html = f'<div class="task-meta-row">{" ".join(meta_row_items)}</div>'

        # Badges
        meta_status = meta.get("Status")
        meta_phase = meta.get("Phase")
        meta_priority = meta.get("Priority")
        
        status_badge_html = ""
        if meta_status and meta_status.lower() != "unknown" and meta_status.lower() != "markdown":
            status_badge_html = f'<span class="badge badge-status badge-status-{meta_status.lower()}">{meta_status}</span>'
            
        badge_row_items = []
        if meta_phase and meta_phase != "0":
            badge_row_items.append(f'<span class="badge badge-phase">Phase {meta_phase}</span>')
        if meta_priority and meta_priority.lower() != "low":
            badge_row_items.append(f'<span class="badge badge-priority" style="{priority_style}">{meta_priority}</span>')
            
        badge_row_html = ""
        if badge_row_items:
            badge_row_html = f'<div style="display: flex; gap: 6px;">{" ".join(badge_row_items)}</div>'
            
        if status_badge_html or badge_row_html:
            badges_container_html = f"""
                <div class="header-badges">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        {status_badge_html}
                        <button id="width-toggle" class="toggle-btn" title="Toggle Full Width">↔</button>
                    </div>
                    {badge_row_html}
                </div>
            """
        else:
            badges_container_html = """
                <div class="header-badges">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <button id="width-toggle" class="toggle-btn" title="Toggle Full Width">↔</button>
                    </div>
                </div>
            """

        rendered_html = HTML_TEMPLATE.format(
            task_title=meta.get("Task", "Unnamed Document"),
            meta_row_html=meta_row_html,
            badges_container_html=badges_container_html,
            dynamic_cards=dynamic_cards_str,
            json_metadata=json.dumps(state_dict, indent=2).replace("</script>", "<\\/script>").replace("</SCRIPT>", "<\\/SCRIPT>")
        )
        
        return rendered_html

    def synthesize(self, force_template=False):
        """Re-renders Markdown or HTML from JSON state + template."""
        if self.md_path.endswith('.html'):
            html_content = self.compile_state_to_html(self.state)
            with open(self.md_path, 'w') as f:
                f.write(html_content)
            print(f"✨ Visual HTML document synthesized: {self.md_path}")
            return

        if not self.template_path or not os.path.exists(self.template_path):
            print(f"⚠️ No template found. Falling back to basic synthesis.")
            self._basic_synthesize()
            return

        with open(self.template_path, 'r') as f:
            template_content = f.read()

        output = template_content
        
        all_aliases = set()
        for k in self.state["meta"]:
            all_aliases.add(k)
            if k in self.META_CROSSWALK:
                all_aliases.update(self.META_CROSSWALK[k])
        if "VERSION" not in all_aliases:
            self.state["meta"]["Version"] = "1.0"
        if "LINKED_TASK" not in all_aliases:
            spec_val = self.state["meta"].get("Spec", "")
            if spec_val:
                self.state["meta"]["Linked Task"] = spec_val
        for k, v in self.state["meta"].items():
            pattern = re.compile(r'\{\{\s*' + re.escape(k) + r'\s*\}\}')
            output = pattern.sub(v, output)
            if k in self.META_CROSSWALK:
                for alias in self.META_CROSSWALK[k]:
                    alias_pattern = re.compile(r'\{\{\s*' + re.escape(alias) + r'\s*\}\}')
                    output = alias_pattern.sub(v, output)
            if k == "Task":
                output = re.sub(r'# Task:\s*.*', f'# Task: {v}', output)

        processed_sections = set()
        
        def clean_tag(name):
            tag = re.sub(r'[^a-zA-Z0-9\s]', ' ', name)
            tag = re.sub(r'\s+', ' ', tag).strip()
            return tag.upper().replace(' ', '_')

        for name, content in self.state["sections"].items():
            tag_exact = f"{{{{{name.upper().replace(' ', '_')}}}}}"
            tag_clean = f"{{{{{clean_tag(name)}}}}}"
            
            if tag_exact in output:
                output = output.replace(tag_exact, content)
                processed_sections.add(name)
            elif tag_clean in output:
                output = output.replace(tag_clean, content)
                processed_sections.add(name)
            elif name in self.SECTION_CROSSWALK:
                tag_crosswalk = f"{{{{{self.SECTION_CROSSWALK[name]}}}}}"
                if tag_crosswalk in output:
                    output = output.replace(tag_crosswalk, content)
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
            elif name in self.SECTION_CROSSWALK:
                tag_crosswalk = f"{{{{{self.SECTION_CROSSWALK[name]}}}}}"
                if tag_crosswalk in output:
                    output = output.replace(tag_crosswalk, checklist_md)
                    processed_sections.add(name)

        unfilled = re.findall(r'\{\{.*?\}\}', output)
        if unfilled:
            for tag in set(unfilled):
                print(f"⚠️  Unfilled template tag: {tag}")
        output = re.sub(r'\{\{.*?\}\}', '*', output)

        existing_headers = set(re.findall(r'^##\s+(.+)$', output, re.MULTILINE))
        orphans = []
        for name, content in self.state["sections"].items():
            if name not in processed_sections and name not in existing_headers:
                orphans.append(f"## {name}\n{content}")
        
        for name, items in self.state["checklists"].items():
            if name not in processed_sections and name not in existing_headers:
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
    parser.add_argument("file", nargs="?", help="Markdown or HTML file to process")
    parser.add_argument("--harvest", action="store_true", help="MD -> JSON")
    parser.add_argument("--synthesize", action="store_true", help="JSON -> MD")
    parser.add_argument("--template", help="Template to use for synthesis")
    parser.add_argument("--out", help="Alternative output path")
    parser.add_argument("--state", help="Alternative input JSON state path")
    parser.add_argument("--convert", nargs=2, metavar=("INPUT_MD", "OUTPUT_HTML"), help="Convert Markdown to HTML-embedded JSON")
    
    # State Modification Flags
    parser.add_argument("--set-meta", nargs=2, action="append", metavar=("KEY", "VALUE"), help="Set metadata field")
    parser.add_argument("--set-section", nargs=2, action="append", metavar=("HEADER", "CONTENT"), help="Set section content")
    parser.add_argument("--set-item", nargs=3, action="append", metavar=("LIST", "TEXT", "STATUS"), help="Set/Update checklist item")

    args = parser.parse_args()
    
    if args.convert:
        in_path, out_path = args.convert
        print(f"🔄 Migrating legacy Markdown from '{in_path}' to HTML-embedded JSON '{out_path}'...")
        temp_twin = GlobalTwin(in_path)
        temp_twin.harvest()
        temp_twin.md_path = out_path
        temp_twin.synthesize()
        print(f"🎉 Successful Migration! '{out_path}' generated with 100% data fidelity.")
        sys.exit(0)

    if not args.file:
        parser.print_help()
        sys.exit(1)

    twin = GlobalTwin(args.file, template_path=args.template)
    
    # 1. Initial State Load from source file
    if os.path.exists(twin.yaml_path) or os.path.exists(twin.json_path) or (twin.md_path.endswith('.html') and os.path.exists(twin.md_path)):
        twin.load_state()

    # 2. Harvest from source file
    if os.path.exists(twin.md_path):
        twin.harvest()
    elif args.harvest or (not os.path.exists(twin.yaml_path) and os.path.exists(args.file)):
        twin.harvest()

    # 3. Apply alternative output path if requested
    if args.out:
        twin.md_path = args.out
        twin.yaml_path = f"{args.out}.yaml"
        twin.json_path = f"{args.out}.json"

    # 3. Merge with external state if provided
    if args.state and os.path.exists(args.state):
        if args.state.endswith('.md'):
            temp_twin = GlobalTwin(args.state)
            temp_twin.harvest()
            new_state = temp_twin.state
        else:
            import json as _json
            with open(args.state, 'r') as f:
                if args.state.endswith('.yaml'):
                    new_state = yaml.safe_load(f) or {}
                else:
                    new_state = _json.load(f)

            protected = ["Status", "Phase", "Version", "Linked Task", "Created", "Completed"]

            for k, v in new_state.get("meta", {}).items():
                if k not in protected or k not in twin.state["meta"]:
                    twin.state["meta"][k] = v

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
            
            found = False
            for item in twin.state["checklists"][lst]:
                if item["text"] == txt:
                    item["status"] = stat
                    found = True
                    break
            if not found:
                twin.state["checklists"][lst].append({"text": txt, "status": stat})

    # 5. Finalize State
    if args.harvest or args.set_meta or args.set_section or args.set_item:
        twin.state["updated_at"] = datetime.now().isoformat()
        twin.save_state()
    
    # 6. Synthesize if requested
    if args.synthesize:
        twin.synthesize()
        twin.state["updated_at"] = datetime.now().isoformat()
        twin.save_state()
