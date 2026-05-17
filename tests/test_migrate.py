import unittest
import os
import shutil
import tempfile
import json
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../skills/swt-task/scripts")))
# pyrefly: ignore [missing-import]
from twin import GlobalTwin

class TestMigrate(unittest.TestCase):
    def setUp(self):
        # Create a temporary directory for output files
        self.test_dir = tempfile.mkdtemp()
        
        # Target the physical, concrete sample Markdown task and spec file fixtures
        self.md_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "fixtures/sample_legacy_task.md"))
        self.spec_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "fixtures/sample_legacy_spec.md"))
        
        self.html_path = os.path.join(self.test_dir, "test_task.html")
        self.spec_html_path = os.path.join(self.test_dir, "test_spec.html")

    def tearDown(self):
        # Clean up the temporary directory
        shutil.rmtree(self.test_dir)

    def test_markdown_harvest_to_html_synthesis(self):
        """Verify that harvesting a real Markdown task and synthesizing it to HTML succeeds."""
        # 1. Harvest Markdown
        twin = GlobalTwin(self.md_path)
        state = twin.harvest()
        
        self.assertEqual(state["meta"]["Task"], "build legacy markdown to html migration converter")
        self.assertEqual(state["meta"]["Status"], "pending")
        self.assertEqual(state["meta"]["Priority"], "high")
        self.assertEqual(state["meta"]["Category"], "research")
        
        self.assertIn("Objective", state["sections"])
        self.assertIn("Build a robust, highly reliable MD-to-HTML migration parser", state["sections"]["Objective"])
        self.assertIn("Notes", state["sections"])
        
        self.assertIn("Goals", state["checklists"])
        self.assertEqual(len(state["checklists"]["Goals"]), 3)
        self.assertEqual(state["checklists"]["Goals"][0]["status"], " ")
        self.assertEqual(state["checklists"]["Goals"][1]["status"], " ")
        self.assertEqual(state["checklists"]["Goals"][2]["status"], " ")

        # 2. Synthesize to HTML
        twin.md_path = self.html_path
        twin.synthesize()
        
        self.assertTrue(os.path.exists(self.html_path))
        with open(self.html_path, "r") as f:
            html_content = f.read()
            
        # Assert HTML styling and database tags exist
        self.assertIn("SWT Dashboard - build legacy markdown to html migration converter", html_content)
        self.assertIn('<script id="swt-metadata" type="application/json">', html_content)
        self.assertIn('[ ]', html_content) # Unchecked icon in monospace format

    def test_spec_migration(self):
        """Verify that harvesting a real Markdown specification and synthesizing it to HTML succeeds."""
        # 1. Harvest Spec
        twin = GlobalTwin(self.spec_path)
        state = twin.harvest()
        
        self.assertEqual(state["meta"]["Task"], "Markdown-to-HTML Migration Engine (Unified HTML Ecosystem)")
        self.assertEqual(state["meta"]["Status"], "approved")
        self.assertEqual(state["meta"]["Version"], "1.0")
        
        self.assertIn("Objective", state["sections"])
        self.assertIn("Build a robust, highly reliable MD-to-HTML migration parser", state["sections"]["Objective"])
        
        self.assertIn("2. Goals", state["sections"])
        self.assertIn("Markdown AST Extraction", state["sections"]["2. Goals"])

        # 2. Synthesize Spec to HTML
        twin.md_path = self.spec_html_path
        twin.synthesize()
        
        self.assertTrue(os.path.exists(self.spec_html_path))
        with open(self.spec_html_path, "r") as f:
            html_content = f.read()
            
        self.assertIn("SWT Dashboard - Markdown-to-HTML Migration Engine", html_content)
        self.assertIn('<script id="swt-metadata" type="application/json">', html_content)

    def test_html_state_rehydration(self):
        """Assert that we can load and parse the embedded JSON state from the HTML file perfectly."""
        # 1. Create HTML via synthesis
        twin_md = GlobalTwin(self.md_path)
        twin_md.harvest()
        twin_md.md_path = self.html_path
        twin_md.synthesize()
        
        # 2. Re-hydrate via new HTML parser
        twin_html = GlobalTwin(self.html_path)
        hydrated_state = twin_html.harvest()
        
        self.assertEqual(hydrated_state["meta"]["Task"], "build legacy markdown to html migration converter")
        self.assertEqual(hydrated_state["meta"]["Status"], "pending")
        self.assertEqual(hydrated_state["meta"]["Priority"], "high")
        
        self.assertIn("Build a robust, highly reliable MD-to-HTML migration parser", hydrated_state["sections"]["Objective"])
        self.assertEqual(hydrated_state["checklists"]["Goals"][0]["status"], " ")

    def test_state_modification_and_recompile(self):
        """Assert that we can modify the hydrated state and re-compile a pristine HTML file."""
        # 1. Generate initial HTML
        twin_md = GlobalTwin(self.md_path)
        twin_md.harvest()
        twin_md.md_path = self.html_path
        twin_md.synthesize()
        
        # 2. Load HTML, check a checkbox, update status
        twin_html = GlobalTwin(self.html_path)
        twin_html.load_state()
        
        twin_html.state["meta"]["Status"] = "completed"
        twin_html.state["checklists"]["Goals"][0]["status"] = "x"
        twin_html.synthesize()
        
        # 3. Verify changes persist in the HTML's JSON database
        twin_final = GlobalTwin(self.html_path)
        final_state = twin_final.harvest()
        
        self.assertEqual(final_state["meta"]["Status"], "completed")
        self.assertEqual(final_state["checklists"]["Goals"][0]["status"], "x")

if __name__ == "__main__":
    unittest.main()
