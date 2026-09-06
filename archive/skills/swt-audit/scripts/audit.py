import os
import json
import re
from pathlib import Path

def audit_workspace():
    root = Path.cwd()
    
    # Repository Lockdown: Only run in SWT Core
    if not (root / "SKILLS.md").exists():
        print("🛑 ERROR: swt:audit is a core structural tool and is restricted to the SWT repository.")
        return

    report = {
        "skills": {},
        "files": [],
        "summary": {
            "total_skills": 0,
            "total_scripts": 0
        },
        "findings": {}
    }

    # 1. Skill Discovery
    skills_dir = root / "skills"
    if skills_dir.exists():
        for skill_path in skills_dir.iterdir():
            if skill_path.is_dir():
                skill_name = skill_path.name
                skill_data = {
                    "role": "Unknown",
                    "scripts": [],
                    "templates": [],
                    "commands": {}
                }

                # Parse SKILL.md (YAML + Header)
                skill_md = skill_path / "SKILL.md"
                if skill_md.exists():
                    content = skill_md.read_text()
                    
                    # Try YAML first
                    yaml_match = re.search(r"^---\s*\n(.*?)\n---", content, re.DOTALL | re.MULTILINE)
                    if yaml_match:
                        yaml_content = yaml_match.group(1)
                        desc_match = re.search(r"^description:\s*(.+)$", yaml_content, re.MULTILINE)
                        if desc_match:
                            skill_data["role"] = desc_match.group(1).strip()
                    
                    # Fallback to legacy header if still unknown
                    if skill_data["role"] == "Unknown":
                        role_match = re.search(r"^#\s+swt:\w+\s+\u2014\s+(.+)$", content, re.MULTILINE)
                        if role_match:
                            skill_data["role"] = role_match.group(1).strip()

                # Find scripts
                scripts_dir = skill_path / "scripts"
                if scripts_dir.exists():
                    skill_data["scripts"] = [f.name for f in scripts_dir.iterdir() if f.is_file()]
                    report["summary"]["total_scripts"] += len(skill_data["scripts"])

                # Find templates
                templates_dir = skill_path / "templates"
                if templates_dir.exists():
                    skill_data["templates"] = [f.name for f in templates_dir.iterdir() if f.is_file()]

                report["skills"][skill_name] = skill_data
                report["summary"]["total_skills"] += 1

    # 2. Command Categorization (Parsing flow.sh)
    flow_sh = root / "skills/swt-flow/scripts/flow.sh"
    if flow_sh.exists():
        content = flow_sh.read_text()
        # Simple parser for help categories
        help_sections = re.findall(r"echo\s+\"([A-Z][^:]+):\"\n((?:\s+echo\s+\"\s+\w+.*\"\n)+)", content)
        for category, cmd_lines in help_sections:
            category = category.strip()
            cmds = re.findall(r"(\w+)\s+-\s+(.+)\"", cmd_lines)
            for cmd_name, desc in cmds:
                # Find which skill this command delegates to
                delegate_match = re.search(rf"{cmd_name}\)\s+shift;\s+delegate\s+\"skills/([^/]+)/", content)
                if delegate_match:
                    skill_owner = delegate_match.group(1)
                    if skill_owner in report["skills"]:
                        if category not in report["skills"][skill_owner]["commands"]:
                            report["skills"][skill_owner]["commands"][category] = {}
                        report["skills"][skill_owner]["commands"][category][cmd_name] = desc

    # 3. Structural Findings
    findings = {}

    # Finding: Phase 0 Bottleneck
    tasks_dir = root / ".tasks"
    if tasks_dir.exists():
        phase_0_tasks = []
        for task_file in tasks_dir.glob("*.md"):
            content = task_file.read_text()
            if re.search(r"^\*\*?Phase\*\*?:\s*0", content, re.MULTILINE):
                phase_0_tasks.append(task_file.name)
        
        if len(phase_0_tasks) > 3:
            findings["phase_0_bottleneck"] = {
                "severity": "medium",
                "observation": f"Found {len(phase_0_tasks)} tasks stuck in Phase 0 (Ideation).",
                "implication": "High backlog drag. Consider graduating or abandoning idle ideas.",
                "affected": phase_0_tasks
            }

    # Finding: Template Ghosts
    ghosts = []
    for d in [".tasks", ".specs"]:
        search_dir = root / d
        if search_dir.exists():
            for f in search_dir.glob("*.md"):
                if "{{" in f.read_text():
                    ghosts.append(str(f.relative_to(root)))
    
    if ghosts:
        findings["template_ghosts"] = {
            "severity": "high",
            "observation": f"Found {len(ghosts)} documents containing unpopulated '{{{{' markers.",
            "implication": "Naked templates detected. This violates the 'Born Complete' ritual.",
            "affected": ghosts
        }

    # Finding: Passive Skills
    passive_skills = [name for name, data in report["skills"].items() if not data["scripts"]]
    if passive_skills:
        findings["passive_skills"] = {
            "severity": "low",
            "observation": f"Found {len(passive_skills)} skills with no implementation scripts.",
            "implication": "Documentation-only or deprecated skills.",
            "affected": passive_skills
        }

    report["findings"] = findings

    # Write report
    (root / "swt-skills-audit.json").write_text(json.dumps(report, indent=2))
    print(f"✅ Structural Audit Complete: swt-skills-audit.json generated.")

if __name__ == "__main__":
    audit_workspace()
