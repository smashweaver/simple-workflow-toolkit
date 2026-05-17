import unittest
import os
import sys
import tempfile
from datetime import datetime

# Add twin.py directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../skills/swt-task/scripts")))
# pyrefly: ignore [missing-import]
from twin import GlobalTwin

class TestGlobalTwin(unittest.TestCase):
    def setUp(self):
        # Create a temporary markdown file to simulate a task
        self.test_dir = tempfile.TemporaryDirectory()
        self.md_path = os.path.join(self.test_dir.name, "test_task.md")
        
        self.sample_content = """# Task: test-task-runner

**Created**: 2026-05-17 12:00:00
**Updated**: 2026-05-17 12:00:00
**Status**: pending
**Phase**: 8

> This is a sample task for unit testing.

## Objective
Implement robust unit tests for GlobalTwin.

## Checklist
- [x] Test Setup
- [/] Test Execution
- [ ] Test Verification

## Notes
* Some test notes.
"""
        with open(self.md_path, "w") as f:
            f.write(self.sample_content)

    def tearDown(self):
        self.test_dir.cleanup()

    def test_harvest_metadata(self):
        twin = GlobalTwin(self.md_path)
        state = twin.harvest()
        
        self.assertEqual(state["meta"]["Task"], "test-task-runner")
        self.assertEqual(state["meta"]["Status"], "pending")
        self.assertEqual(state["meta"]["Phase"], "8")

    def test_harvest_sections_and_checklists(self):
        twin = GlobalTwin(self.md_path)
        state = twin.harvest()
        
        self.assertIn("Objective", state["sections"])
        self.assertEqual(state["sections"]["Objective"], "Implement robust unit tests for GlobalTwin.")
        
        self.assertIn("Checklist", state["checklists"])
        checklist = state["checklists"]["Checklist"]
        self.assertEqual(len(checklist), 3)
        self.assertEqual(checklist[0]["status"], "x")
        self.assertEqual(checklist[0]["text"], "Test Setup")
        self.assertEqual(checklist[1]["status"], "/")
        self.assertEqual(checklist[1]["text"], "Test Execution")
        self.assertEqual(checklist[2]["status"], " ")
        self.assertEqual(checklist[2]["text"], "Test Verification")

    def test_basic_synthesize(self):
        twin = GlobalTwin(self.md_path)
        twin.harvest()
        
        # Modify some states in-memory
        twin.state["meta"]["Status"] = "completed"
        twin.state["checklists"]["Checklist"][2]["status"] = "x"
        
        twin.synthesize()
        
        # Re-read and check changes
        twin2 = GlobalTwin(self.md_path)
        state2 = twin2.harvest()
        self.assertEqual(state2["meta"]["Status"], "completed")
        self.assertEqual(state2["checklists"]["Checklist"][2]["status"], "x")

    def test_templated_synthesize(self):
        # Create a mock template
        template_path = os.path.join(self.test_dir.name, "template.md")
        template_content = """# Task: {{TASK_NAME}}
**Status**: {{STATUS}}

## Objective
{{OBJECTIVE}}
"""
        with open(template_path, "w") as f:
            f.write(template_content)

        twin = GlobalTwin(self.md_path, template_path)
        twin.harvest()
        
        # Modify some values
        twin.state["meta"]["Task"] = "new-task-name"
        twin.state["meta"]["Status"] = "completed"
        twin.state["sections"]["Objective"] = "New objective text."
        
        twin.synthesize()
        
        # Read the synthesized document and assert substitutions
        with open(self.md_path, "r") as f:
            content = f.read()
            
        self.assertIn("# Task: new-task-name", content)
        self.assertIn("**Status**: completed", content)
        self.assertIn("New objective text.", content)

    def test_universal_heading_fallback(self):
        generic_md_path = os.path.join(self.test_dir.name, "generic_document.md")
        generic_content = """# Universal Viewport Mock Fixture
**Created**: 2026-05-18 06:20:00
**Status**: pending

## Core Objective
Prove that the HTML compiler parses non-prefixed generic headers.
"""
        with open(generic_md_path, "w") as f:
            f.write(generic_content)

        twin = GlobalTwin(generic_md_path)
        state = twin.harvest()

        self.assertEqual(state["meta"]["Task"], "Universal Viewport Mock Fixture")
        self.assertEqual(state["meta"]["Status"], "pending")

if __name__ == "__main__":
    unittest.main()

