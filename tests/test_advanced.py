import unittest
import os
import shutil
import subprocess
import tempfile
import glob
import json
from pathlib import Path

class TestSWTAdvanced(unittest.TestCase):
    def setUp(self):
        # Resolve project root
        self.root = Path(__file__).resolve().parents[1]
        self.test_dir = tempfile.TemporaryDirectory()
        self.proj_root = Path(self.test_dir.name)
        
        # Scaffold isolated sandbox workspace
        (self.proj_root / "AGENTS.md").write_text("Mock Agents methodology")
        (self.proj_root / ".git").mkdir()
        (self.proj_root / ".tasks").mkdir()
        (self.proj_root / ".specs").mkdir()

        # Copy the skills folder into the isolated sandbox to support local twin script resolution
        shutil.copytree(self.root / "skills", self.proj_root / "skills")

        self.task_script = self.proj_root / "skills/swt-task/scripts/task.sh"
        self.state_script = self.proj_root / "skills/swt-flow/scripts/state.py"

    def tearDown(self):
        self.test_dir.cleanup()

    def run_task(self, *args):
        """Runs task.sh inside the sandboxed workspace."""
        res = subprocess.run(
            ["bash", str(self.task_script)] + list(args),
            cwd=str(self.proj_root),
            capture_output=True,
            text=True
        )
        return res.returncode, res.stdout, res.stderr

    def run_state(self, *args):
        """Runs state.py inside the sandboxed workspace."""
        res = subprocess.run(
            ["python3", str(self.state_script)] + list(args),
            cwd=str(self.proj_root),
            capture_output=True,
            text=True
        )
        return res.returncode, res.stdout, res.stderr

    def test_ritual_log_forgery_detection(self):
        # 1. Scaffold a valid graduated Phase 1 task
        task_file = self.proj_root / ".tasks/20260517205100_test-forgery.md"
        task_content = """# Task: test-forgery

**Created**: 2026-05-17 12:00:00
**Status**: pending
**Phase**: 1
**Priority**: low
**Type**: chore
**Category**: testing
**Spec**: .specs/20260517205100_test-forgery.md

## Objective
Objective substance.

## Notes
Technical notes.

## Checklist
- [x] Phase 1: Plan

## Ritual Logs
<!-- RITUAL: phase 1 @ 2026-05-17T12:00:00Z (State Verified) -->
"""
        with open(task_file, "w") as f:
            f.write(task_content)

        # Scaffold spec file
        spec_file = self.proj_root / ".specs/20260517205100_test-forgery.md"
        spec_file.write_text("# Spec: test-forgery\n## Implementation Plan\n* Plan\n")

        # Scaffold companion sidecars required for Phase 1 validation
        (self.proj_root / ".tasks/20260517205100.plan.md").write_text("# Plan: test-forgery\n")
        (self.proj_root / ".tasks/20260517205100.tr.md").write_text("# Protocol: test-forgery\n")

        # 2. Verify that validation initially passes
        code, stdout, stderr = self.run_task("validate", ".tasks/20260517205100_test-forgery.md")
        self.assertEqual(code, 0, f"Valid task validation failed: {stdout}\n{stderr}")

        # 3. Forge the Phase header to "Phase: 2" without running transition ritual
        forged_content = task_content.replace("**Phase**: 1", "**Phase**: 2")
        with open(task_file, "w") as f:
            f.write(forged_content)

        # 4. Assert that validation blocks the manual phase modification
        code, stdout, stderr = self.run_task("validate", ".tasks/20260517205100_test-forgery.md")
        self.assertEqual(code, 1, "Validation should have failed due to ritual forgery!")
        self.assertIn("MANUAL PHASE FORGERY DETECTED", stdout + stderr)

    def test_template_ghost_and_orphan_detection(self):
        # 1. Create a task containing a template ghost marker
        ghost_file = self.proj_root / ".tasks/20260517205100_ghost.md"
        ghost_file.write_text("# Ghost Task\n{{placeholder_tag}}\n")

        # 2. Create an orphan file (commit.draft in Phase 1 context)
        (self.proj_root / "commit.draft").write_text("Mock draft commit message")

        # 3. Create a valid task reference and mount it in task.ctx
        task_file = self.proj_root / ".tasks/20260517205100_active.md"
        task_file.write_text("# Task: active\n**Phase**: 1\n")
        (self.proj_root / "task.ctx").write_text(".tasks/20260517205100_active.md")

        # 4. Run the state recognizer with JSON output
        code, stdout, stderr = self.run_state("--json")
        self.assertEqual(code, 0, f"state.py failed: {stdout}\n{stderr}")

        # 5. Assert report contains warnings about Template Ghost and Orphans
        report = json.loads(stdout)
        warnings = []
        for sensor in report.get("sensors", []):
            warnings.extend(sensor.get("warnings", []))

        # Join warnings for simple assertion checking
        warning_str = " ".join(warnings)
        self.assertIn("Template Ghosts", warning_str)
        self.assertIn("Orphan artifacts found", warning_str)

    def test_liquidation_and_archival_hygiene(self):
        # 1. Set up active task and transient artifacts
        task_file = self.proj_root / ".tasks/20260517205100_test-liquidation.md"
        task_file.write_text("# Task: test-liquidation\n**Status**: pending\n**Phase**: 8\n**Spec**: .specs/20260517205100_test-liquidation.md\n")

        # Scaffold spec
        spec_file = self.proj_root / ".specs/20260517205100_test-liquidation.md"
        spec_file.write_text("# Spec: test-liquidation\n")

        # Scaffold active context and commit transients
        (self.proj_root / "task.ctx").write_text(str(task_file))
        (self.proj_root / "task.md").write_text("Mock view pointer")
        (self.proj_root / "commit.draft").write_text("Mock draft")
        (self.proj_root / "commit.task").write_text("Mock task ref")
        (self.proj_root / "commit.diff").write_text("Mock diff")

        # 2. Close the task (which triggers unmount and liquidation)
        env = os.environ.copy()
        env["SWT_MODE"] = "yolo" # skip hitl confirmation block
        res = subprocess.run(
            ["bash", str(self.task_script), "close", f".tasks/{os.path.basename(task_file)}", "mock_hash_xyz"],
            cwd=str(self.proj_root),
            capture_output=True,
            text=True,
            env=env
        )
        self.assertEqual(res.returncode, 0, f"Task close failed: {res.stdout}\n{res.stderr}")

        # 3. Assert all transient files are physically liquidated/deleted from the root
        self.assertFalse((self.proj_root / "task.ctx").exists(), "task.ctx was not liquidated!")
        self.assertFalse((self.proj_root / "task.md").exists(), "task.md viewport was not liquidated!")
        self.assertFalse((self.proj_root / "commit.draft").exists(), "commit.draft was not liquidated!")
        self.assertFalse((self.proj_root / "commit.task").exists(), "commit.task was not liquidated!")
        self.assertFalse((self.proj_root / "commit.diff").exists(), "commit.diff was not liquidated!")

if __name__ == "__main__":
    unittest.main()
