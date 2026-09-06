import unittest
import os
import sys
import tempfile
from pathlib import Path

# Add state.py directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../skills/swt-flow/scripts")))
# pyrefly: ignore [missing-import]
import state
# pyrefly: ignore [missing-import]
from state import read_phase, get_substance, md5, sensor_phase_loop, sensor_twin_protocol, TaskParser

class TestStateRecognizer(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.TemporaryDirectory()
        self.root = self.test_dir.name
        
        # Mock active task file
        self.task_path = os.path.join(self.root, "test_task.md")
        self.sample_content = """# Task: test-state-sensor

**Created**: 2026-05-17 12:00:00
**Status**: pending
**Phase**: 8
**Priority**: high
**Type**: feature
**Category**: testing

## Objective
Verify the state recognizer sensors.

## Notes
* Mock Notes Content.
"""
        with open(self.task_path, "w") as f:
            f.write(self.sample_content)

    def tearDown(self):
        self.test_dir.cleanup()

    def test_read_phase(self):
        # Flexible parsing check
        phase = read_phase(self.task_path)
        self.assertEqual(phase, 8)

    def test_get_substance_and_md5(self):
        substance = get_substance(self.task_path)
        self.assertIn("Verify the state recognizer sensors.", substance)
        self.assertIn("Mock Notes Content.", substance)
        
        h = md5(substance)
        self.assertEqual(len(h), 32) # Standard MD5 hex length

    def test_task_parser(self):
        parser = TaskParser(Path(self.task_path))
        self.assertEqual(parser.metadata["phase"], 8)
        self.assertEqual(parser.metadata["status"], "pending")
        self.assertEqual(parser.metadata["priority"], "high")
        self.assertEqual(parser.metadata["type"], "feature")
        self.assertEqual(parser.metadata["category"], "testing")
        self.assertEqual(parser.metadata["objective"], "Verify the state recognizer sensors.")

    def test_sensor_phase_loop(self):
        # When active task exists
        res = sensor_phase_loop(self.task_path)
        self.assertEqual(res["status"], "ok")
        self.assertEqual(res["phase"], 8)
        self.assertEqual(res["loop"], "Refinement Loop")
        self.assertEqual(res["gate"], "Gate 5: Finality Loop (Commit)")

        # When no task exists
        res_none = sensor_phase_loop(None)
        self.assertEqual(res_none["status"], "warn")
        self.assertEqual(res_none["loop"], "Unknown")

    def test_sensor_twin_protocol_system_bypass(self):
        # System directories (.tasks) should bypass sidecars
        system_task = os.path.join(self.root, ".tasks", "20260517205100_task.md")
        os.makedirs(os.path.dirname(system_task), exist_ok=True)
        with open(system_task, "w") as f:
            f.write(self.sample_content)
            
        res = sensor_twin_protocol(system_task)
        self.assertEqual(res["status"], "ok")
        self.assertIn("Direct Markdown state verified", res["findings"][0])

if __name__ == "__main__":
    unittest.main()
