import unittest
import os
import sys
import tempfile

# Add resolve.py directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../skills/swt-task/scripts")))
from resolve import resolve

class TestResolve(unittest.TestCase):
    def setUp(self):
        # Create a mock workspace root
        self.test_dir = tempfile.TemporaryDirectory()
        self.root = self.test_dir.name
        
        # Create folder structures
        self.tasks_dir = os.path.join(self.root, ".tasks")
        self.archive_dir = os.path.join(self.root, ".tasks/archive")
        self.specs_dir = os.path.join(self.root, ".specs")
        os.makedirs(self.tasks_dir)
        os.makedirs(self.archive_dir)
        os.makedirs(self.specs_dir)
        
        # Create mock files
        self.active_task = os.path.join(self.tasks_dir, "20260517205100_active-task.md")
        self.archive_task = os.path.join(self.archive_dir, "20260510123456_archive-task.md")
        self.spec_file = os.path.join(self.specs_dir, "20260430090000_sample-spec.md")
        
        for fpath in [self.active_task, self.archive_task, self.spec_file]:
            with open(fpath, "w") as f:
                f.write("# Mock task/spec content")

    def tearDown(self):
        self.test_dir.cleanup()

    def test_resolve_exact_path(self):
        # Absolute path should resolve exactly
        res = resolve(self.active_task, self.root)
        self.assertEqual(res, os.path.abspath(self.active_task))

    def test_resolve_relative_to_root(self):
        # Path relative to root should resolve
        res = resolve(".tasks/20260517205100_active-task.md", self.root)
        self.assertEqual(res, os.path.abspath(self.active_task))

    def test_resolve_timestamp_prefix(self):
        # Active task timestamp prefix matching
        res = resolve("20260517205100", self.root)
        self.assertEqual(res, os.path.abspath(self.active_task))
        
        # Archive task timestamp prefix matching
        res = resolve("20260510123456", self.root)
        self.assertEqual(res, os.path.abspath(self.archive_task))

    def test_resolve_fuzzy_slug(self):
        # Fuzzy match active task by keyword
        res = resolve("active-task", self.root)
        self.assertEqual(res, os.path.abspath(self.active_task))
        
        # Fuzzy match archive task by keyword
        res = resolve("archive-task", self.root)
        self.assertEqual(res, os.path.abspath(self.archive_task))
        
        # Fuzzy match spec by keyword
        res = resolve("sample-spec", self.root)
        self.assertEqual(res, os.path.abspath(self.spec_file))

    def test_resolve_non_existent(self):
        # Non-existent input should return None
        res = resolve("non-existent-task-slug", self.root)
        self.assertIsNone(res)

if __name__ == "__main__":
    unittest.main()
