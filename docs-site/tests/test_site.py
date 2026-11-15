import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_site


class SiteLinkTest(unittest.TestCase):
    def test_valid_relative_links_and_anchors(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "diagram").mkdir()
            (root / "index.html").write_text(
                '<a href="diagram/#result">Diagram</a>', encoding="utf-8"
            )
            (root / "diagram" / "index.html").write_text(
                '<h1 id="result">Result</h1>', encoding="utf-8"
            )
            self.assertEqual(check_site.validate_site(root), [])

    def test_missing_page_and_anchor_are_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "index.html").write_text(
                '<a href="missing/">Missing</a><a href="#absent">Anchor</a>',
                encoding="utf-8",
            )
            errors = check_site.validate_site(root)
            self.assertEqual(len(errors), 2)
            self.assertTrue(any("missing/" in error for error in errors))
            self.assertTrue(any("#absent" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
