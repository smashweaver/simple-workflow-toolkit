import json
import re
import os

def scrape_markdown(filepath):
    """Simple parser to extract ## sections from Markdown."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Extract Title and Metadata
    title_match = re.search(r'^# Spec: (.*)', content)
    title = title_match.group(1) if title_match else ""
    
    sections = {}
    # Find all ## headers and their content
    # This regex looks for ## headers and captures everything until the next header
    matches = re.findall(r'## (.*?)\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    
    for header, body in matches:
        sections[header.strip()] = body.strip()
    
    return {
        "title": title,
        "sections": sections
    }

def render_markdown(template_path, data, output_path):
    """Renders a document using a template and JSON data."""
    with open(template_path, 'r') as f:
        template = f.read()
    
    # Map section names to template placeholders (Simplified for PoC)
    mapping = {
        "1. Problem Statement": "{{PROBLEM_STATEMENT}}",
        "2. Goals": "{{GOALS}}",
        "3. Proposed Solution": "{{PROPOSED_SOLUTION}}",
        "4. User Stories": "{{USER_STORIES}}",
        "6. Implementation Plan": "{{NOTES}}",
        "8. Success Criteria": "{{SUCCESS_CRITERIA}}",
        "12. MVP Definition": "{{MVP}}"
    }
    
    output = template
    output = output.replace("{{Task Slug}}", data["title"])
    
    for section_name, placeholder in mapping.items():
        content = data["sections"].get(section_name, "*")
        output = output.replace(placeholder, content)
    
    with open(output_path, 'w') as f:
        f.write(output)

# --- PoC EXECUTION ---
INPUT_FILE = ".specs/20260502151101_orchestrator-facade-alignment.md"
TEMPLATE_FILE = "skills/swt-task/templates/spec.md"
SCRATCH_DIR = "/tmp/swt"
os.makedirs(SCRATCH_DIR, exist_ok=True)

JSON_STATE = os.path.join(SCRATCH_DIR, os.path.basename(INPUT_FILE) + ".json")
OUTPUT_FILE = "poc_output.md"

# 1. Scrape
print(f"Scraping {INPUT_FILE}...")
state = scrape_markdown(INPUT_FILE)

# 2. Persist to JSON
with open(JSON_STATE, 'w') as f:
    json.dump(state, f, indent=2)
print(f"Saved state to {JSON_STATE}")

# 3. Simulate Agent Update
print("Simulating agent update (Adding a new Goal)...")
state["sections"]["2. Goals"] = "* [NEW] Integration with JSON-backed document state."

# 4. Render
print(f"Rendering to {OUTPUT_FILE}...")
render_markdown(TEMPLATE_FILE, state, OUTPUT_FILE)
print("Done. Manual edits in other sections should be preserved.")
