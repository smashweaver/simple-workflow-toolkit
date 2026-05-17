#!/usr/bin/env python3
# /// script
# dependencies = ["pyyaml"]
# ///
"""
SWT Template-Driven Continuous Digest Engine
"""

import os
import sys
import re
import argparse
import glob
from datetime import datetime
from pathlib import Path

# Resolve ROOT_DIR
ROOT_DIR = Path(__file__).resolve().parents[3]

# Import state and twin engines
sys.path.append(str(ROOT_DIR / "skills/swt-flow/scripts"))
sys.path.append(str(ROOT_DIR / "skills/swt-task/scripts"))
# pyrefly: ignore [missing-import]
import state
# pyrefly: ignore [missing-import]
from twin import GlobalTwin

def parse_args():
    parser = argparse.ArgumentParser(description="SWT Daily Continuous Digest Engine")
    parser.add_argument("-m", "--milestone", action="store_true", help="Generate project milestone digest")
    parser.add_argument("--content", help="Content file to read summary from")
    parser.add_argument("--summary", help="Raw text summary string")
    return parser.parse_args()

def main():
    args = parse_args()
    
    # 1. Date Context
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    yyyymmdd = now.strftime("%Y%m%d")
    timestamp = now.strftime("%Y%m%d%H%M%S")
    
    digest_root = ROOT_DIR / ".digests"
    archive_root = digest_root / "archive"
    os.makedirs(archive_root, exist_ok=True)
    
    # 2. Select template & file path
    if args.milestone:
        filename = digest_root / f"{timestamp}_milestone.md"
        template_path = ROOT_DIR / "skills/swt-digest/templates/milestone.md"
        existing_file = None
    else:
        # Check for today's existing digest
        pattern = str(digest_root / f"{yyyymmdd}*_digest.md")
        candidates = glob.glob(pattern)
        if candidates:
            existing_file = Path(candidates[0])
            filename = existing_file
            print(f"🔄 Today's digest already exists: {filename.name}. Performing continuous merge.")
        else:
            filename = digest_root / f"{timestamp}_digest.md"
            existing_file = None
        template_path = ROOT_DIR / "skills/swt-digest/templates/session.md"

    if not template_path.exists():
        print(f"❌ Error: Template not found at {template_path}")
        sys.exit(1)

    # 3. Retrieve Context
    context_str = ""
    ctx_path = ROOT_DIR / "task.ctx"
    if ctx_path.exists():
        ctx_val = ctx_path.read_text().strip()
        if ctx_val:
            # Resolve task file location
            resolved = None
            for p in [ROOT_DIR / ctx_val, ROOT_DIR / ".tasks" / f"{ctx_val}.md", ROOT_DIR / ".tasks" / ctx_val, ROOT_DIR / ".tasks" / "archive" / f"{ctx_val}.md"]:
                if p.exists() and p.is_file():
                    resolved = p
                    break
            if resolved:
                context_str = f"**Active Context:** [{resolved.name}]({resolved.relative_to(ROOT_DIR)})\n"
            else:
                context_str = f"**Active Context:** STALE ({ctx_val} not found)\n"
    
    # 4. Retrieve Active Tasks (Priority Sorted)
    active_tasks_list = []
    active_tasks = state.get_backlog()
    for t in active_tasks:
        slug = t.name.replace(".md", "")
        prio = t.metadata.get("priority", "medium")
        active_tasks_list.append(f"- **[{slug}]({t.path.relative_to(ROOT_DIR)})**: ({prio}) Active")
    active_tasks_str = "\n".join(active_tasks_list) if active_tasks_list else "*No active tasks.*"

    # 5. Retrieve Closed Tasks (completed today)
    closed_tasks_list = []
    archive_dir = ROOT_DIR / ".tasks" / "archive"
    if archive_dir.exists():
        for f in archive_dir.glob("*.md"):
            if f.name.startswith(yyyymmdd) and not f.name.endswith(".plan.md") and not f.name.endswith(".tr.md"):
                try:
                    p = state.TaskParser(f)
                    slug = f.name.replace(".md", "")
                    if p.metadata.get("status") == "abandoned":
                        closed_tasks_list.append(f"- **Abandoned [{slug}]({f.relative_to(ROOT_DIR)})**")
                    else:
                        # Extract commit hash
                        commit_hash = "—"
                        m = re.search(r'## Commit Reference\n+(?:[^\n]+\n+)?([a-f0-9]{7,40})', p.content, re.IGNORECASE)
                        if m:
                            commit_hash = m.group(1)
                        closed_tasks_list.append(f"- **Closed [{slug}]({f.relative_to(ROOT_DIR)})**: Committed changes ({commit_hash}).")
                except Exception:
                    continue
    closed_tasks_str = "\n".join(closed_tasks_list) if closed_tasks_list else "*No tasks closed today.*"

    # 6. Retrieve Parents (Older digests to archive)
    parents_list = []
    parent_files = []
    for d in [digest_root, digest_root / "archive"]:
        if d.exists():
            parent_files.extend(glob.glob(str(d / "*_digest.md")))
    parent_files = sorted(list(set(parent_files)), key=lambda x: os.path.basename(x))
    
    for p in parent_files:
        p_path = Path(p)
        if not p_path.name.startswith(yyyymmdd):
            parents_list.append(p_path)
    
    # Take the last 5 parent digests
    parents_to_archive = parents_list[-5:]
    parents_str = "\n".join([f"- [{p.name}]({p.relative_to(ROOT_DIR)})" for p in parents_to_archive]) if parents_to_archive else "*No parent digests.*"

    # 7. Formulate New Input Summary & Outcomes
    new_summary = ""
    if args.summary:
        new_summary = args.summary.strip()
    elif args.content and os.path.exists(args.content):
        with open(args.content) as sf:
            new_summary = sf.read().strip()
            
    # Default Outcomes & Next Steps
    outcomes_str = ""
    next_steps_str = ""
    if not new_summary:
        outcomes_str = "## Key Outcomes & Architecture\n\n- {{Outcome Title}}: {{Brief explanation.}}\n"
        next_steps_str = "## Immediate Next Steps\n\n1. {{Step 1}}: {{Actionable item}}\n"

    if existing_file:
        # Load and harvest existing digest
        twin = GlobalTwin(str(existing_file), template_path=str(template_path))
        twin.harvest()
        
        # Ensure metadata DATE is preserved
        twin.state["meta"]["DATE"] = date_str
        
        # Map harvested section names back to their template tag names and prepend headers
        if "Key Outcomes & Architecture" in twin.state["sections"]:
            twin.state["sections"]["KEY_OUTCOMES"] = f"## Key Outcomes & Architecture\n\n" + twin.state["sections"].pop("Key Outcomes & Architecture")
        if "Immediate Next Steps" in twin.state["sections"]:
            twin.state["sections"]["NEXT_STEPS"] = f"## Immediate Next Steps\n\n" + twin.state["sections"].pop("Immediate Next Steps")
            
        # Merge Summary
        current_summary = twin.state["sections"].get("SUMMARY", "").strip()
        placeholder_regex = r'\{\{A 1-2 sentence summary.*?\}\}'
        
        if not current_summary or re.match(placeholder_regex, current_summary) or current_summary == "*":
            if new_summary:
                twin.state["sections"]["SUMMARY"] = new_summary
            else:
                twin.state["sections"]["SUMMARY"] = "## Summary\n\n*Progress updated continuously.*"
        else:
            if new_summary and new_summary not in current_summary:
                twin.state["sections"]["SUMMARY"] = f"{current_summary}\n\n{new_summary}"
        
        # Keep outcomes safe or append them
        current_outcomes = twin.state["sections"].get("KEY_OUTCOMES", "").strip()
        if outcomes_str and not current_outcomes:
            twin.state["sections"]["KEY_OUTCOMES"] = outcomes_str
        
        # Update dynamic context and list views
        twin.state["sections"]["CONTEXT"] = context_str
        twin.state["sections"]["ACTIVE_TASKS"] = active_tasks_str
        twin.state["sections"]["CLOSED_TASKS"] = closed_tasks_str
        twin.state["sections"]["PARENTS"] = parents_str
        
        # Re-synthesize
        twin.synthesize()
    else:
        # Scaffold brand new digest
        # Create empty file so GlobalTwin can harvest / start
        filename.touch()
        twin = GlobalTwin(str(filename), template_path=str(template_path))
        
        # Populate initial state
        twin.state["meta"]["DATE"] = date_str
        twin.state["sections"]["SUMMARY"] = new_summary if new_summary else "## Summary\n\n{{A 1-2 sentence summary of the session's focus.}}"
        twin.state["sections"]["CONTEXT"] = context_str
        twin.state["sections"]["KEY_OUTCOMES"] = outcomes_str if outcomes_str else "## Key Outcomes & Architecture\n\n- Outcome: Implementation & progress recorded."
        twin.state["sections"]["ACTIVE_TASKS"] = active_tasks_str
        twin.state["sections"]["CLOSED_TASKS"] = closed_tasks_str
        twin.state["sections"]["NEXT_STEPS"] = next_steps_str if next_steps_str else "## Immediate Next Steps\n\n1. Next Step: Proceed with upcoming tasks."
        twin.state["sections"]["PARENTS"] = parents_str
        
        twin.synthesize()

    # 9. Archive Parent Digests
    for p in parents_to_archive:
        try:
            dest = archive_root / p.name
            os.rename(p, dest)
            print(f"📦 Archived parent digest: {p.name}")
        except Exception as e:
            print(f"⚠️ Failed to archive parent digest {p.name}: {e}")

    print(f"✨ Daily continuous digest compiled successfully: {filename.name}")

if __name__ == "__main__":
    main()
