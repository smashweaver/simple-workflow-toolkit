import unittest
import os
import sys
import tempfile

# Add crow.py directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../skills/swt-task/scripts")))
from crow import get_section_map, patch_file

class TestCrowPatcher(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.TemporaryDirectory()
        self.md_path = os.path.join(self.test_dir.name, "test_doc.md")
        
        self.sample_content = """# Sample Document

**Status**: pending
**Author**: Jason

## Section One
This is content for section one.
It is multiline.

## Section Two
This is content for section two.
"""
        with open(self.md_path, "w") as f:
            f.write(self.sample_content)

    def tearDown(self):
        self.test_dir.cleanup()

    def test_get_section_map(self):
        section_map = get_section_map(self.sample_content)
        self.assertIn("Section One", section_map)
        self.assertIn("Section Two", section_map)
        
        # Section One starts on line 5 (0-indexed)
        # Section Two starts on line 9 (0-indexed)
        self.assertEqual(section_map["Section One"][0], 5)
        self.assertEqual(section_map["Section Two"][0], 9)

    def test_patch_metadata(self):
        # Update existing metadata and add a new one
        patches = {}
        metas = {"Status": "completed", "Version": "1.2"}
        
        success = patch_file(self.md_path, patches, metas)
        self.assertTrue(success)
        
        with open(self.md_path, "r") as f:
            content = f.read()
            
        self.assertIn("**Status**: completed", content)
        self.assertIn("**Version**: 1.2", content)
        self.assertNotIn("**Status**: pending", content)

    def test_patch_sections(self):
        # Replace Section One and add a missing Section Three
        patches = {
            "Section One": "This is patched content for section one.",
            "Section Three": "This is a new section content."
        }
        metas = {}
        
        success = patch_file(self.md_path, patches, metas)
        self.assertTrue(success)
        
        with open(self.md_path, "r") as f:
            content = f.read()
            
        self.assertIn("This is patched content for section one.", content)
        self.assertNotIn("This is content for section one.", content)
        self.assertIn("## Section Three\nThis is a new section content.", content)

if __name__ == "__main__":
    unittest.main()
