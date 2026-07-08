import unittest
import os
import subprocess
import tempfile
from pathlib import Path

class TestSubstanceValidation(unittest.TestCase):
    def setUp(self):
        self.root = Path(__file__).resolve().parents[1]
        self.task_script = self.root / "skills/swt-task/scripts/task.sh"
        self.test_dir = tempfile.TemporaryDirectory()
        
        # Base task path
        self.task_path = os.path.join(self.test_dir.name, "20260709120000_test_validation.md")
        
    def tearDown(self):
        self.test_dir.cleanup()
        
    def write_task(self, content):
        with open(self.task_path, "w", encoding="utf-8") as f:
            f.write(content)
            
    def run_phase_cmd(self, phase_num, task_file):
        res = subprocess.run(
            ["bash", str(self.task_script), "phase", str(phase_num), str(task_file)],
            cwd=str(self.root),
            capture_output=True,
            text=True
        )
        return res.returncode, res.stdout, res.stderr

    def test_bare_implementation_plan_blocking(self):
        # 1. Start in phase 1 with bare plan template
        content = """# Task: test validation
**Created**: 2026-07-09 12:00:00
**Status**: pending
**Phase**: 1
**Type**: brainstorm

## Objective
Test implementation plan validation.

## Checklist
- [ ] Phase 1: Plan

## Implementation Plan

## Proposed Changes
*

## Verification Plan

### Automated Tests
*

### Manual Verification
*
"""
        self.write_task(content)
        
        # Attempt to transition to Phase 2 (should fail because plan is bare)
        code, stdout, stderr = self.run_phase_cmd(2, self.task_path)
        self.assertEqual(code, 1)
        self.assertIn("🛑 PROTOCOL VIOLATION: Implementation Plan section 'Proposed Changes' is empty or bare", stdout)

    def test_populated_implementation_plan_passing(self):
        # 1. Start in phase 1 with populated plan
        content = """# Task: test validation
**Created**: 2026-07-09 12:00:00
**Status**: pending
**Phase**: 1
**Type**: brainstorm

## Objective
Test implementation plan validation.

## Checklist
- [ ] Phase 1: Plan

## Implementation Plan

## Proposed Changes
We will modify the templates and update validate logic.

## Verification Plan

### Automated Tests
Run unit tests to verify.

### Manual Verification
*
"""
        self.write_task(content)
        
        # Transition to Phase 2 (should pass)
        code, stdout, stderr = self.run_phase_cmd(2, self.task_path)
        self.assertEqual(code, 0, f"Validation failed: {stdout}")

    def test_bare_tactical_roadmap_blocking(self):
        # 1. Start in phase 4 (Approved) with bare roadmap template
        content = """# Task: test validation
**Created**: 2026-07-09 12:00:00
**Status**: pending
**Phase**: 4
**Type**: brainstorm

GATE 2: APPROVED

## Objective
Test roadmap validation.

## Checklist
- [ ] Phase 4: Approval

## Implementation Plan

## Proposed Changes
Populated proposed changes.

## Verification Plan

### Automated Tests
*

### Manual Verification
Perform manual checks.

## Tactical Roadmap Protocol
> Roadmap

## 1. Mission Briefing
*

## 2. Gate 3: Execution Loop (Tactical Chunks)
*
"""
        self.write_task(content)
        
        # Transition to Phase 5 (should fail because roadmap is bare)
        code, stdout, stderr = self.run_phase_cmd(5, self.task_path)
        self.assertEqual(code, 1)
        self.assertIn("🛑 PROTOCOL VIOLATION: Tactical Roadmap Protocol section 'Mission Briefing' is empty or bare", stdout)

    def test_populated_tactical_roadmap_passing(self):
        # 1. Start in phase 4 (Approved) with populated roadmap
        content = """# Task: test validation
**Created**: 2026-07-09 12:00:00
**Status**: pending
**Phase**: 4
**Type**: brainstorm

GATE 2: APPROVED

## Objective
Test roadmap validation.

## Checklist
- [ ] Phase 4: Approval

## Implementation Plan

## Proposed Changes
Populated proposed changes.

## Verification Plan

### Automated Tests
*

### Manual Verification
Perform manual checks.

## Tactical Roadmap Protocol
> Roadmap

## 1. Mission Briefing
We will implement the code and run tests.

## 2. Gate 3: Execution Loop (Tactical Chunks)
1. Write code.
2. Verify.
"""
        self.write_task(content)
        
        # Transition to Phase 5 (should pass)
        code, stdout, stderr = self.run_phase_cmd(5, self.task_path)
        self.assertEqual(code, 0, f"Transition failed: {stdout}")

    def test_plan_archival_on_task_close(self):
        # Setup task with spec
        spec_path = os.path.join(self.test_dir.name, "20260709120000_test_validation.spec.md")
        spec_content = """# Spec: Test Validation
## 1. Problem Statement
Test.

## 6. Implementation Plan
*

## 7. Risks & Mitigations
*
"""
        with open(spec_path, "w", encoding="utf-8") as f:
            f.write(spec_content)
            
        task_content = f"""# Task: test validation
**Created**: 2026-07-09 12:00:00
**Status**: pending
**Phase**: 8
**Type**: brainstorm
**Spec**: {spec_path}

## Objective
Test.

## Checklist
- [ ] Phase 8: Review & Refine

## Implementation Plan

## Proposed Changes
- Modified script to copy plan.

## Verification Plan

### Automated Tests
- Run tests.

### Manual Verification
*
"""
        self.write_task(task_content)
        
        # Call close command
        res = subprocess.run(
            ["bash", str(self.task_script), "close", self.task_path, "fdc7d28"],
            cwd=str(self.root),
            capture_output=True,
            text=True
        )
        self.assertEqual(res.returncode, 0, f"Close command failed: {res.stdout}")
        
        # Check spec file has been updated
        with open(spec_path, "r", encoding="utf-8") as f:
            spec_updated = f.read()
            
        self.assertIn("Proposed Changes", spec_updated)
        self.assertIn("Modified script to copy plan", spec_updated)
        self.assertIn("Run tests", spec_updated)

if __name__ == "__main__":
    unittest.main()
