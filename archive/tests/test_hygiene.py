import unittest
import os
import subprocess
from pathlib import Path

class TestEphemeralHygiene(unittest.TestCase):
    def setUp(self):
        # Resolve project root
        self.root = Path(__file__).resolve().parents[1]
        self.cache_dir = self.root / ".cache"
        self.gitignore_path = self.root / ".gitignore"

    def test_cache_directory_exists_and_writable(self):
        # Verify that the .cache directory exists
        self.assertTrue(self.cache_dir.exists(), "Mandatory .cache/ directory is missing from workspace root!")
        self.assertTrue(self.cache_dir.is_dir(), ".cache/ must be a directory!")
        
        # Test writing a temporary transient file into the cache
        test_file = self.cache_dir / "hygiene_test.json"
        try:
            test_file.write_text('{"status": "ok"}')
            self.assertTrue(test_file.exists())
            self.assertEqual(test_file.read_text(), '{"status": "ok"}')
        finally:
            if test_file.exists():
                test_file.unlink()

    def test_cache_is_gitignored(self):
        # Verify .gitignore exists
        self.assertTrue(self.gitignore_path.exists(), ".gitignore is missing from workspace root!")
        
        # Verify that the pattern '.cache/' is in gitignore
        gitignore_content = self.gitignore_path.read_text()
        self.assertIn(".cache/", gitignore_content, "The .cache/ directory is not ignored in .gitignore!")

    def test_cache_write_does_not_pollute_git_index(self):
        # Programmatically write a test file into the cache directory
        test_file = self.cache_dir / "transient_hygiene_pollution_check.tmp"
        test_file.write_text("temporary_data")
        
        try:
            # Run git status to verify it's ignored and not untracked
            res = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=str(self.root),
                capture_output=True,
                text=True,
                check=True
            )
            
            # The porcelain status line should NOT contain our temporary cache file
            output = res.stdout
            self.assertNotIn(str(test_file.name), output, "Pollution detected! Ephemeral file inside .cache/ was tracked by Git!")
            self.assertNotIn(".cache/", output, "Pollution detected! .cache/ directory shows up in Git status!")
            
        finally:
            # Clean up the file to keep cache pristine
            if test_file.exists():
                test_file.unlink()

if __name__ == "__main__":
    unittest.main()
