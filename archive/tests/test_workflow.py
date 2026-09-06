import unittest
import os
import subprocess
import tempfile
from pathlib import Path

class TestWorkflowTransitions(unittest.TestCase):
    def setUp(self):
        # Resolve project root
        self.root = Path(__file__).resolve().parents[1]
        self.task_script = self.root / "skills/swt-task/scripts/task.sh"
        self.test_dir = tempfile.TemporaryDirectory()
        
        # Scaffold a mock task
        self.task_path = os.path.join(self.test_dir.name, "20260517205100_mock_workflow_task.md")
        self.sample_content = """# Task: mock-workflow-task

**Created**: 2026-05-17 12:00:00
**Status**: pending
**Phase**: 1
**Priority**: low
**Type**: chore
**Category**: testing

## Objective
Verify the workflow sequential and approval gates.

## Checklist
- [ ] Phase 1

## Notes
* Verification notes.
"""
        with open(self.task_path, "w") as f:
            f.write(self.sample_content)

    def tearDown(self):
        self.test_dir.cleanup()

    def run_phase_cmd(self, phase_num, task_file):
        """Runs the CLI task.sh phase command."""
        res = subprocess.run(
            ["bash", str(self.task_script), "phase", str(phase_num), str(task_file)],
            cwd=str(self.root),
            capture_output=True,
            text=True
        )
        return res.returncode, res.stdout, res.stderr

    def test_loop_jumping_protection(self):
        # Current phase is 1. Trying to transition to 5 should fail due to Loop Jumping.
        code, stdout, stderr = self.run_phase_cmd(5, self.task_path)
        
        self.assertEqual(code, 1)
        self.assertIn("🛑 LOOP JUMP DETECTED", stdout)
        self.assertIn("Cannot jump from Phase 1 to Phase 5", stdout)

    def test_sequential_transition_and_gate_2_hitl_lock(self):
        # 0. Create mandatory Phase 2+ sidecar (Implementation Plan)
        plan_path = os.path.join(self.test_dir.name, "20260517205100.plan.md")
        with open(plan_path, "w") as f:
            f.write("# Implementation Plan\n")

        # 1. Transition sequentially to Phase 2 (Should succeed now!)
        code, stdout, stderr = self.run_phase_cmd(2, self.task_path)
        self.assertEqual(code, 0, f"Failed transition 1 -> 2: {stdout}")
        
        # 2. Transition sequentially to Phase 3 (Should succeed)
        code, stdout, stderr = self.run_phase_cmd(3, self.task_path)
        self.assertEqual(code, 0, f"Failed transition 2 -> 3: {stdout}")
        
        # 3. Transition sequentially to Phase 4 (Should succeed)
        code, stdout, stderr = self.run_phase_cmd(4, self.task_path)
        self.assertEqual(code, 0, f"Failed transition 3 -> 4: {stdout}")
        
        # 4. Attempt transition to Phase 5 (Should fail due to Gate 2 Architecture Lock)
        code, stdout, stderr = self.run_phase_cmd(5, self.task_path)
        self.assertEqual(code, 1)
        self.assertIn("🛑 GATE 2 LOCKED", stdout)
        self.assertIn("Implementation (Phase 5) requires explicit user approval", stdout)
        
        # 5. Create mandatory Phase 5+ sidecar (Tactical Roadmap)
        tr_path = os.path.join(self.test_dir.name, "20260517205100.tr.md")
        with open(tr_path, "w") as f:
            f.write("# Tactical Roadmap\n")

        # 6. Append approval string to unlock Gate 2
        with open(self.task_path, "a") as f:
            f.write("\nGATE 2: APPROVED\n")
            
        # 7. Attempt transition to Phase 5 again (Should succeed!)
        code, stdout, stderr = self.run_phase_cmd(5, self.task_path)
        self.assertEqual(code, 0, f"Failed transition 4 -> 5 after approval: {stdout}")
        self.assertIn("🔓 GATE 2 UNLOCKED: Implementation authorized.", stdout)

if __name__ == "__main__":
    unittest.main()
