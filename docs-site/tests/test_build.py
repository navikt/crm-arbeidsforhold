import base64
import hashlib
import io
import sys
import tarfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_docs


def archive(entries):
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w:gz") as package:
        for name, contents in entries.items():
            member = tarfile.TarInfo(name)
            member.size = len(contents)
            package.addfile(member, io.BytesIO(contents))
    return buffer.getvalue()


class MermaidIntegrityTest(unittest.TestCase):
    def test_verified_bundle_includes_runtime_and_license(self):
        data = archive(
            {"package/dist/mermaid.min.js": b"runtime", "package/LICENSE": b"license"}
        )
        digest = base64.b64encode(hashlib.sha512(data).digest()).decode()
        with patch.object(build_docs, "MERMAID_INTEGRITY", digest):
            self.assertEqual(build_docs.extract_mermaid(data), (b"runtime", b"license"))

    def test_rejects_modified_archive(self):
        with self.assertRaisesRegex(ValueError, "integrity"):
            build_docs.extract_mermaid(b"modified archive")

    def test_rejects_archive_without_license(self):
        data = archive({"package/dist/mermaid.min.js": b"runtime"})
        digest = base64.b64encode(hashlib.sha512(data).digest()).decode()
        with patch.object(build_docs, "MERMAID_INTEGRITY", digest):
            with self.assertRaisesRegex(ValueError, "LICENSE"):
                build_docs.extract_mermaid(data)


if __name__ == "__main__":
    unittest.main()
