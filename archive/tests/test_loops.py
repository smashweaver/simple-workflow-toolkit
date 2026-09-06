import unittest
import os
import shutil
import subprocess
import tempfile
import glob
from pathlib import Path

class TestSWTLoops(unittest.TestCase):
    def setUp(self):
        # Resolve project root
        self.root = Path(__file__).resolve().parents[1]
        self.task_script = self.root / "skills/swt-task/scripts/task.sh"
        self.commit_script = self.root / "skills/swt-commit/scripts/commit.sh"
        self.test_dir = tempfile.TemporaryDirectory()
        self.proj_root = Path(self.test_dir.name)
        
        # Scaffold isolated sandbox workspace
        (self.proj_root / "AGENTS.md").write_text("Mock Agents methodology")
        (self.proj_root / ".git").mkdir()
        (self.proj_root / ".tasks").mkdir()
        (self.proj_root / ".specs").mkdir()

        # Copy the skills folder into the isolated sandbox to support local twin script resolution
        shutil.copytree(self.root / "skills", self.proj_root / "skills")

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

    def run_commit(self, *args):
        """Runs commit.sh inside the sandboxed workspace."""
        res = subprocess.run(
            ["bash", str(self.commit_script)] + list(args),
            cwd=str(self.proj_root),
            capture_output=True,
            text=True
        )
        return res.returncode, res.stdout, res.stderr

    def test_brainstorm_graduation_loop(self):
        # 1. Create a Phase 0 Brainstorm Task
        code, stdout, stderr = self.run_task("brainstorm", "test-graduation-loop")
        self.assertEqual(code, 0, f"Failed to create brainstorm task: {stdout}\n{stderr}")
        
        # Assert task file was created
        task_files = glob.glob(str(self.proj_root / ".tasks/*.md"))
        self.assertEqual(len(task_files), 1, "Brainstorm task file was not created inside .tasks/")
        task_file = task_files[0]
        
        # Verify Phase is 0 and status is ideating
        with open(task_file, "r") as f:
            content = f.read()
        self.assertIn("**Phase**: 0", content)
        self.assertIn("**Status**: ideating", content)

        # 2. Verify Graduation is blocked for thin/naked task (Substance Density Guard)
        code, stdout, stderr = self.run_task("graduate", f".tasks/{os.path.basename(task_file)}")
        self.assertIn("🛑 THIN BRAINSTORM JAILBREAK", stdout + stderr, f"Substance density warning was not found! stdout={stdout}, stderr={stderr}")

        # 3. Populate task with sufficient substance (>100 characters in Objective + Notes)
        substance_content = """# Task: test-graduation-loop

**Created**: 2026-05-17 12:00:00
**Status**: ideating
**Phase**: 0
**Priority**: low
**Type**: chore
**Category**: testing

## Objective
The objective of this task is to programmatically verify that a task can go from a Phase 0 brainstorm, graduate, and close successfully.

## Checklist
- [ ] Phase 0

## Notes
This is a detailed note containing technical findings, explored alternatives, and architectural trade-offs to easily exceed the substance density limit.
"""
        with open(task_file, "w") as f:
            f.write(substance_content)

        # 4. Graduate the task to Phase 1
        env = os.environ.copy()
        env["SWT_MODE"] = "yolo" # Skip interactive confirmation block
        res = subprocess.run(
            ["bash", str(self.task_script), "graduate", f".tasks/{os.path.basename(task_file)}"],
            cwd=str(self.proj_root),
            capture_output=True,
            text=True,
            env=env
        )
        self.assertEqual(res.returncode, 0, f"Failed to graduate task: {res.stdout}\n{res.stderr}")

        # Assert task is promoted to Phase 1 and status is pending
        with open(task_file, "r") as f:
            graduated_content = f.read()
        self.assertIn("**Phase**: 1", graduated_content)
        self.assertIn("**Status**: pending", graduated_content)

        # Assert a specification file is scaffolded inside .specs/
        spec_files = glob.glob(str(self.proj_root / ".specs/*.md"))
        self.assertEqual(len(spec_files), 1, "Graduation did not automatically scaffold spec file inside .specs/")

    def test_light_bulb_reset_loop(self):
        # 1. Create a fully populated and graduated Phase 1 task
        task_name = "test-reset-loop"
        task_file = self.proj_root / f".tasks/20260517205100_{task_name}.md"
        task_content = """# Task: test-reset-loop

**Created**: 2026-05-17 12:00:00
**Status**: pending
**Phase**: 5
**Priority**: low
**Type**: chore
**Category**: testing
**Spec**: .specs/20260517205100_test-reset-loop.md

## Objective
Task objective.

## Notes
Technical notes.

## Checklist
- [x] Phase 1: Plan
- [x] Phase 2: Analyze
- [x] Phase 3: Risk Assessment
- [x] Phase 4: Approval
- [/] Phase 5: Implement
- [ ] Phase 6: Document
- [ ] Phase 7: Test
- [ ] Phase 8: Review & Refine
"""
        with open(task_file, "w") as f:
            f.write(task_content)

        # Scaffold mock spec file
        spec_file = self.proj_root / ".specs/20260517205100_test-reset-loop.md"
        spec_file.write_text("# Spec: test-reset-loop\n## Implementation Plan\n* Plan\n")

        # 2. Trigger the Light Bulb Reset using sync-docs
        code, stdout, stderr = self.run_task("sync-docs", f".tasks/20260517205100_{task_name}.md")
        self.assertEqual(code, 0, f"sync-docs failed: {stdout}\n{stderr}")

        # 3. Assert the task phase is physically reset to Phase 1 (Plan)
        with open(task_file, "r") as f:
            reset_content = f.read()
        self.assertIn("**Phase**: 1", reset_content)
        self.assertIn("(Reset via sync-downstream)", reset_content)

    def test_commit_staleness_loop(self):
        # 1. Verify commit fails if no active task is mounted (Locked Gate Protocol)
        code, stdout, stderr = self.run_commit("--draft", "some message")
        self.assertEqual(code, 1, "Commit draft should fail when no task is active/mounted")

if __name__ == "__main__":
    unittest.main()
