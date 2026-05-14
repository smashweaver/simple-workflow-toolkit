#!/usr/bin/env python3
# /// script
# dependencies = ["pyyaml"]
# ///
"""
SWT Transition State Recognizer
Grounded in LOOPS.md — the authoritative state machine for the SWT workflow.

Usage:
    uv run python3 state.py [--json] [--sensor <name>]
"""

import os
import re
import sys
import subprocess
import hashlib
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

# ── LOOPS.md Phase → Loop Map ─────────────────────────────────────────────────
PHASE_LOOP_MAP = {
    0: ("Brainstorm Loop",  "Gate 1: Alignment Loop"),
    1: ("Planning Loop",    "Gate 1: Alignment Loop (entry)"),
    2: ("Analysis Loop",    "Gate 2: Architecture Loop (pending)"),
    3: ("Analysis Loop",    "Gate 2: Architecture Loop (pending)"),
    4: ("Approval",         "Gate 2: Architecture Loop — HARD STOP"),
    5: ("Execution Loop",   "Gate 3: Execution Loop"),
    6: ("Execution Loop",   "Gate 3: Execution Loop"),
    7: ("Execution Loop",   "Gate 4: Refinement Loop (pending)"),
    8: ("Refinement Loop",  "Gate 5: Finality Loop (Commit)"),
}

VALID_NEXT = {
    0: ["Review task file", "Run: /swt:flow graduate <task_file>"],
    1: ["Populate implementation_plan.md", "Run: /swt:flow phase 2 <task_file>"],
    2: ["Perform impact analysis", "Run: /swt:flow phase 3 <task_file>"],
    3: ["Perform risk assessment", "Present to user for Gate 2 approval"],
    4: ["Await user GO", "Run: /swt:flow phase 5 <task_file> after GO"],
    5: ["Implement surgical changes", "Run: /swt:flow status after each chunk"],
    6: ["Update documentation", "Run: /swt:flow phase 7 <task_file>"],
    7: ["Run tests", "Present MVP to user at Gate 4"],
    8: ["Draft commit: ./skills/swt-commit/scripts/commit.sh --draft", "Await user approval"],
}

ROOT_DIR = Path(__file__).resolve().parents[3]

def load_swt_config() -> dict:
    config_path = ROOT_DIR / "swt.json"
    if config_path.exists():
        try:
            return json.loads(config_path.read_text())
        except Exception:
            return {}
    return {}

CONFIG = load_swt_config()


def find_task_ctx() -> str | None:
    ctx = ROOT_DIR / "task.ctx"
    if ctx.exists():
        val = ctx.read_text().strip()
        if val:
            candidate = ROOT_DIR / val
            if candidate.exists():
                return str(candidate)
    return None


def read_phase(task_file: str) -> int:
    with open(task_file) as f:
        for line in f:
            # Flexible: catch "Phase: 1", "**Phase**: 1", etc.
            m = re.match(r'^(?:\*\*)?Phase(?:\*\*)?:\s*(\d+)', line)
            if m:
                return int(m.group(1))
    return -1


def get_substance(filepath: str) -> str:
    """Extract semantic content from Objective + Notes for drift detection."""
    if not os.path.exists(filepath):
        return ""
    with open(filepath) as f:
        content = f.read()
    substance = []
    for section in ("Objective", "Notes"):
        m = re.search(rf'^## {section}\s*\n(.*?)(?=\n## |\Z)', content, re.DOTALL | re.MULTILINE)
        if m:
            text = re.sub(r'\s+', ' ', m.group(1)).strip()
            substance.append(text)
    return " ".join(substance)


def md5(text: str) -> str:
    return hashlib.md5(text.encode()).hexdigest()


class TaskParser:
    """Surgically extracts metadata and substance from a task file."""
    def __init__(self, filepath: Path):
        self.path = filepath
        self.name = filepath.name
        self.content = filepath.read_text() if filepath.exists() else ""
        self.metadata = self._parse_metadata()

    def _parse_metadata(self):
        meta = {
            "phase": -1,
            "status": "unknown",
            "priority": "low",
            "type": "chore",
            "category": "uncategorized",
            "objective": ""
        }
        if not self.content:
            return meta

        # Extraction regexes
        patterns = {
            "phase": r'^(?:\*\*)?Phase(?:\*\*)?:\s*(\d+)',
            "status": r'^(?:\*\*)?Status(?:\*\*)?:\s*(\S+)',
            "priority": r'^(?:\*\*)?Priority(?:\*\*)?:\s*(\S+)',
            "type": r'^(?:\*\*)?Type(?:\*\*)?:\s*(\S+)',
            "category": r'^(?:\*\*)?Category(?:\*\*)?:\s*(\S+)',
        }

        for key, pattern in patterns.items():
            m = re.search(pattern, self.content, re.MULTILINE)
            if m:
                val = m.group(1).strip()
                meta[key] = int(val) if key == "phase" else val

        # Extract Objective
        m = re.search(r'^## Objective\s*\n(.*?)(?=\n## |\Z)', self.content, re.DOTALL | re.MULTILINE)
        if m:
            meta["objective"] = re.sub(r'\s+', ' ', m.group(1)).strip()
        else:
            # Fallback to Core Concept
            m = re.search(r'^## Core Concept\s*\n(.*?)(?=\n## |\Z)', self.content, re.DOTALL | re.MULTILINE)
            if m:
                meta["objective"] = re.sub(r'\s+', ' ', m.group(1)).strip()

        return meta


def get_backlog() -> list[TaskParser]:
    """Aggregates all active tasks from .tasks/"""
    tasks = []
    task_dir = ROOT_DIR / ".tasks"
    if not task_dir.exists():
        return []
    
    for f in task_dir.glob("*.md"):
        try:
            p = TaskParser(f)
            # Only include active tasks (not done/abandoned)
            if p.metadata["status"] not in ("done", "abandoned"):
                tasks.append(p)
        except Exception:
            continue
    
    # Sort by Category, then Phase descending
    tasks.sort(key=lambda t: (t.metadata["category"], -t.metadata["phase"]))
    return tasks


# ── Sensor 1: Phase / Loop Recognizer ─────────────────────────────────────────
def sensor_phase_loop(task_file: str | None) -> dict:
    result = {"sensor": "Phase/Loop Recognizer", "status": "ok", "findings": [], "warnings": []}
    if not task_file:
        result["status"] = "warn"
        result["warnings"].append("No active task mounted (task.ctx missing or empty).")
        result["loop"] = "Unknown"
        result["gate"] = "Unknown"
        result["phase"] = -1
        return result

    phase = read_phase(task_file)
    result["phase"] = phase
    if phase == -1:
        result["status"] = "warn"
        result["warnings"].append(f"Could not read Phase from {task_file}")
        result["loop"] = "Unknown"
        result["gate"] = "Unknown"
        return result

    loop, gate = PHASE_LOOP_MAP.get(phase, ("Unknown Loop", "Unknown Gate"))
    result["loop"] = loop
    result["gate"] = gate
    result["next_actions"] = VALID_NEXT.get(phase, [])
    result["findings"].append(f"Phase {phase} → {loop} | Active: {gate}")
    return result


# ── Sensor 2: Twin Protocol Recognizer ────────────────────────────────────────
def sensor_twin_protocol(task_file: str | None) -> dict:
    result = {"sensor": "Twin Protocol Recognizer", "status": "ok", "findings": [], "warnings": []}
    if not task_file:
        result["status"] = "skip"
        result["warnings"].append("No active task — skipping.")
        return result

    md_mtime = os.path.getmtime(task_file)
    yaml_path = f"{task_file}.yaml"
    json_path = f"{task_file}.json"

    if os.path.exists(yaml_path):
        sidecar_mtime = os.path.getmtime(yaml_path)
        sidecar = yaml_path
    elif os.path.exists(json_path):
        sidecar_mtime = os.path.getmtime(json_path)
        sidecar = json_path
        result["warnings"].append(f"Legacy JSON sidecar in use: {json_path} — run --harvest to migrate.")
        result["status"] = "warn"
    else:
        result["warnings"].append("No sidecar found. Run: twin.py <file> --harvest")
        result["status"] = "warn"
        return result

    delta = md_mtime - sidecar_mtime
    if delta > 30:
        result["warnings"].append(
            f".md is {int(delta)}s newer than sidecar — harvest pending. Run: twin.py {task_file} --harvest"
        )
        result["status"] = "warn"
    elif delta < -30:
        result["warnings"].append(
            f"Sidecar is {int(-delta)}s newer than .md — synthesize pending. Run: twin.py {task_file} --synthesize"
        )
        result["status"] = "warn"
    else:
        result["findings"].append(f"Sidecar in sync ({sidecar})")

    # Detect \n literal debris in sidecar content
    if sidecar.endswith('.yaml'):
        try:
            import yaml
            with open(sidecar) as f:
                state = yaml.safe_load(f) or {}
            debris_found = []
            for section, content in state.get("sections", {}).items():
                if isinstance(content, str) and "\\n" in content:
                    debris_found.append(section)
            if debris_found:
                result["warnings"].append(
                    f"Debris detected in YAML sidecar sections: {debris_found}. "
                    "These contain literal \\\\n strings from --set-section misuse. "
                    "Fix: write .md directly → run --harvest."
                )
                result["status"] = "warn"
        except Exception as e:
            result["warnings"].append(f"Could not parse YAML sidecar: {e}")

    return result


# ── Sensor 3: Substance Drift Recognizer ──────────────────────────────────────
def sensor_substance_drift(task_file: str | None, phase: int) -> dict:
    result = {"sensor": "Substance Drift Recognizer", "status": "ok", "findings": [], "warnings": []}
    if not task_file or phase < 1:
        result["status"] = "skip"
        result["findings"].append("Phase 0 or no task — substance check N/A.")
        return result
    if phase >= 8:
        result["status"] = "skip"
        result["findings"].append("Phase 8 (Commit Loop) — substance staleness check bypassed.")
        return result

    # Find companion spec
    spec_file = None
    with open(task_file) as f:
        for line in f:
            m = re.match(r'^\*\*Spec\*\*:\s*(\S+)', line)
            if m:
                candidate = ROOT_DIR / m.group(1)
                if candidate.exists():
                    spec_file = str(candidate)
                break

    if not spec_file:
        result["status"] = "skip"
        result["findings"].append("No companion Spec found — drift check N/A.")
        return result

    task_substance = get_substance(task_file)
    spec_substance = get_substance(spec_file)
    task_hash = md5(task_substance)
    spec_hash = md5(spec_substance)

    if task_hash != spec_hash:
        result["status"] = "warn"
        result["warnings"].append(
            "OBJECTIVE DRIFT DETECTED: Task substance differs from Spec. "
            "Light Bulb Loop required. Run: /swt:flow sync-docs <task_file>"
        )
    else:
        result["findings"].append("Substance match ✓ (Task ↔ Spec content identical)")

    return result


def get_artifact_path(task_file: str, type: str) -> str:
    path = Path(task_file)
    ts = path.name.split('_')[0]
    ext = "md"
    if type == "implementation_plan": ext = "plan.md"
    elif type == "protocol": ext = "tr.md"
    elif type == "walkthrough": ext = "walkthrough.md"
    return str(path.parent / f"{ts}.{ext}")


# ── Sensor 4: Artifact Hygiene Recognizer ─────────────────────────────────────
def sensor_artifact_hygiene(phase: int, task_file: str | None) -> dict:
    result = {"sensor": "Artifact Hygiene Recognizer", "status": "ok", "findings": [], "warnings": []}
    orphans = []

    # Orphan artifact patterns
    for pattern in ["commit.hash", "*.tmp", ".*.tmp"]:
        for f in ROOT_DIR.glob(pattern):
            orphans.append(str(f.relative_to(ROOT_DIR)))

    # commit.draft outside of Phase 8 is an orphan
    commit_draft = ROOT_DIR / "commit.draft"
    if commit_draft.exists() and phase < 8:
        orphans.append("commit.draft (outside Commit Loop — Phase 8 required)")

    if orphans:
        result["status"] = "warn"
        result["warnings"].append(f"Orphan artifacts found: {orphans}")

    # Template Ghost scan
    ghosts = []
    # Scan all .md files in .tasks and .specs
    for path in list((ROOT_DIR / ".tasks").glob("*.md")) + list((ROOT_DIR / ".specs").glob("*.md")):
        try:
            content = path.read_text()
            if "{{" in content:
                ghosts.append(str(path.relative_to(ROOT_DIR)))
        except Exception:
            pass

    # Legacy Root Artifact Check
    for root_md in ["implementation_plan.md", "protocol.md"]:
        p = ROOT_DIR / root_md
        if p.exists() and "{{" in p.read_text():
            ghosts.append(root_md)

    if ghosts:
        result["status"] = "warn"
        result["warnings"].append(f"Template Ghosts (unfilled {{{{ markers) in: {ghosts}")

    if not orphans and not ghosts:
        result["findings"].append("Workspace hygiene OK — no orphans or template ghosts.")

    return result


# ── Sensor 5: Commit Loop Recognizer ──────────────────────────────────────────
def sensor_commit_loop(phase: int, task_file: str | None) -> dict:
    result = {"sensor": "Commit Loop Recognizer", "status": "ok", "findings": [], "warnings": []}

    if phase != 8:
        result["status"] = "skip"
        result["findings"].append(f"Phase {phase} — Commit Loop sensors inactive (Phase 8 required).")
        return result

    commit_draft = ROOT_DIR / "commit.draft"
    commit_task = ROOT_DIR / "commit.task"

    # Check for Test Ritual (obeying swt.json)
    test_cmd = CONFIG.get("test_command")
    if task_file:
        try:
            content = Path(task_file).read_text()
            
            # 1. Guidelines Handshake (Scenario B)
            if "<!-- RITUAL: commit guidelines read -->" not in content:
                result["warnings"].append(
                    "COMMIT GUIDELINES RITUAL MISSING: You must acknowledge the manual before drafting. "
                    "Run: 'cat skills/swt-commit/SKILL.md' and log 'RITUAL: commit guidelines read' in your task file."
                )
                result["status"] = "error"
            else:
                result["findings"].append("Commit guidelines ritual verified ✓")

            # 2. Test Ritual
            if test_cmd:
                # Look for recent success log: RITUAL: test pass @ ...
                if "RITUAL: test pass" not in content:
                    result["warnings"].append(
                        f"TEST RITUAL MISSING: You must run the test command ('{test_cmd}') via /swt:flow test before committing."
                    )
                    if result["status"] != "error":
                        result["status"] = "warn"
                else:
                    result["findings"].append(f"Test ritual verified ✓ ({test_cmd})")
        except Exception:
            pass

    if not commit_draft.exists():
        result["warnings"].append(
            "commit.draft not found. Generate via: ./skills/swt-commit/scripts/commit.sh --draft \"<message>\""
        )
        if result["status"] != "error":
            result["status"] = "warn"
    else:
        content = commit_draft.read_text()
        # Check for metadata leaks
        if "Closes:" in content:
            result["warnings"].append("METADATA LEAK: 'Closes:' found in commit.draft. Move to commit.task.")
            result["status"] = "error"
        if not commit_task.exists():
            result["warnings"].append("commit.task missing — create it with task closure reference.")
            result["status"] = "warn"
        else:
            result["findings"].append("commit.draft and commit.task are separate ✓")

    # Check for direct git commit attempts via history (best-effort)
    result["findings"].append("Commit Loop active — use commit.sh --draft only, never git commit directly.")
    return result


# ── Report Renderer ────────────────────────────────────────────────────────────
def render_report(sensors: list[dict], phase: int, task_file: str | None, as_json: bool, show_backlog: bool = False, classify: bool = False):
    if as_json:
        import json
        tasks = [t.metadata for t in get_backlog()] if show_backlog else []
        print(json.dumps({"phase": phase, "task": task_file, "sensors": sensors, "backlog": tasks}, indent=2))
        return

    if show_backlog:
        backlog = get_backlog()
        if not backlog:
            print("No active tasks found.")
            return

        # Low-Hanging Fruit
        recs = [t for t in backlog if t.metadata["phase"] == 0 and t.metadata["type"] in ("docs", "chore", "refactor")][:3]
        if recs:
            print("💡 Recommendations (Low-Hanging Fruit)")
            for r in recs:
                # Pretty print name (remove timestamp and .md)
                display_name = re.sub(r'^\d+_', '', r.path.name).replace('.md', '').replace('-', ' ').title()
                print(f"  - {display_name} ({r.metadata['type']})")
            print()

        last_cat = None
        for t in backlog:
            cat = t.metadata["category"]
            if classify and cat != last_cat:
                print(f"{' ' if last_cat else ''}📂 {cat.title()}")
                last_cat = cat
            
            print(f"Task: {t.path.name}")
            print(f"  Status: {t.metadata['status']} | Phase: {t.metadata['phase']} | Priority: {t.metadata['priority']}")
            print(f"  Goal: {t.metadata['objective']}")
            
            # Simple next step extraction
            m = re.search(r'\[ \] (.*)', t.content)
            if m:
                print(f"  Next Step: {m.group(1).strip()}")
        return

    loop_sensor = next((s for s in sensors if s["sensor"] == "Phase/Loop Recognizer"), {})
    loop = loop_sensor.get("loop", "Unknown")
    gate = loop_sensor.get("gate", "Unknown")

    print("=" * 50)
    print("  SWT State Report")
    print("=" * 50)
    print(f"  Task   : {os.path.basename(task_file) if task_file else '(none)'}")
    print(f"  Phase  : {phase if phase >= 0 else 'Unknown'}")
    print(f"  Loop   : {loop}")
    print(f"  Gate   : {gate}")
    print()

    overall_ok = all(s.get("status") in ("ok", "skip") for s in sensors)
    for s in sensors:
        status_icon = {"ok": "✅", "warn": "⚠️ ", "error": "🛑", "skip": "⏭️ "}.get(s.get("status", "ok"), "❓")
        print(f"  {status_icon} {s['sensor']}")
        for f in s.get("findings", []):
            print(f"       {f}")
        for w in s.get("warnings", []):
            print(f"     ⚠  {w}")

    print()
    next_actions = loop_sensor.get("next_actions", [])
    if next_actions:
        print("  Next Actions:")
        for i, action in enumerate(next_actions, 1):
            print(f"    {i}. {action}")

    print("=" * 50)
    if not overall_ok:
        sys.exit(1)


# ── Entry Point ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SWT Transition State Recognizer")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--sensor", help="Run a single sensor by name")
    parser.add_argument("--backlog", action="store_true", help="Report on the active task backlog")
    parser.add_argument("--classify", action="store_true", help="Group backlog by category")
    args = parser.parse_args()

    task_file = find_task_ctx()
    phase = read_phase(task_file) if task_file else -1

    s1 = sensor_phase_loop(task_file)
    s2 = sensor_twin_protocol(task_file)
    s3 = sensor_substance_drift(task_file, phase)
    s4 = sensor_artifact_hygiene(phase, task_file)
    s5 = sensor_commit_loop(phase, task_file)

    all_sensors = [s1, s2, s3, s4, s5]

    # Respect ritual_gates from swt.json
    gates = CONFIG.get("ritual_gates", {})
    if not gates.get("phase_order_enforcement", True):
        # Downgrade s1 warnings if enforcement is disabled
        if s1["status"] == "warn": s1["status"] = "ok"
    
    if not gates.get("hitl_approval", True):
        # Downgrade substance drift if HITL is disabled
        if s3["status"] == "warn": s3["status"] = "ok"

    if args.sensor:
        all_sensors = [s for s in all_sensors if args.sensor.lower() in s["sensor"].lower()]

    render_report(all_sensors, phase, task_file, args.json, args.backlog, args.classify)
