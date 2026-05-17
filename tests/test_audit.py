import unittest
import os
import sys
import json
import tempfile
from pathlib import Path
from unittest.mock import patch

# Add audit.py directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../skills/swt-audit/scripts")))
# pyrefly: ignore [missing-import]
from audit import audit_workspace

class TestWorkspaceAuditor(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.test_dir.name)
        
        # 1. Create SKILLS.md in root to pass the Core check
        (self.root / "SKILLS.md").write_text("# Mock Skills List")
        
        # 2. Create mock skills directory
        self.skills_dir = self.root / "skills"
        self.skills_dir.mkdir()
        
        # Create a mock active skill with SKILL.md and script
        self.mock_skill = self.skills_dir / "swt-test-skill"
        self.mock_skill.mkdir()
        (self.mock_skill / "SKILL.md").write_text("""---
name: "swt:test-skill"
description: "A mock skill for testing"
---
# swt:test-skill — Mock Title
""")
        (self.mock_skill / "scripts").mkdir()
        (self.mock_skill / "scripts/test.py").write_text("# Mock Python Script")
        
        # 3. Create mock tasks directory with 4 Phase 0 tasks (triggering a bottleneck)
        self.tasks_dir = self.root / ".tasks"
        self.tasks_dir.mkdir()
        for i in range(4):
            task_file = self.tasks_dir / f"2026051720510{i}_mock_task.md"
            task_file.write_text(f"""# Task {i}
**Phase**: 0
**Status**: ideating

## Objective
Mock task objective
""")
            
        # 4. Create mock specs directory with a template ghost
        self.specs_dir = self.root / ".specs"
        self.specs_dir.mkdir()
        (self.specs_dir / "20260517205100_mock_spec.md").write_text("""# Spec
This contains an unfilled {{ghost}} placeholder marker.
""")

    def tearDown(self):
        self.test_dir.cleanup()

    @patch("pathlib.Path.cwd")
    def test_audit_workspace(self, mock_cwd):
        mock_cwd.return_value = self.root
        
        # Run structural auditor
        audit_workspace()
        
        # Check generated audit JSON
        audit_json = self.root / "swt-skills-audit.json"
        self.assertTrue(audit_json.exists())
        
        with open(audit_json, "r") as f:
            data = json.load(f)
            
        # Verify discovered skill
        self.assertIn("swt-test-skill", data["skills"])
        self.assertEqual(data["skills"]["swt-test-skill"]["role"], '"A mock skill for testing"')
        
        # Verify bottleneck and ghost findings
        self.assertIn("phase_0_bottleneck", data["findings"])
        self.assertIn("template_ghosts", data["findings"])
        self.assertEqual(data["findings"]["phase_0_bottleneck"]["severity"], "medium")
        self.assertEqual(data["findings"]["template_ghosts"]["severity"], "high")

if __name__ == "__main__":
    unittest.main()
