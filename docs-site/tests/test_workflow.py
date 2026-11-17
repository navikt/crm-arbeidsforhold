import os
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml


WORKFLOW = Path(__file__).resolve().parents[2] / ".github/workflows/docs-pages.yml"


class PagesWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = yaml.load(WORKFLOW.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)

    def test_pull_requests_build_read_only_without_deploying(self):
        self.assertIn("pull_request", self.workflow["on"])
        self.assertEqual(self.workflow["permissions"], {"contents": "read"})
        build = self.workflow["jobs"]["build"]
        self.assertEqual(build["permissions"], {"contents": "read"})
        self.assertEqual(self.workflow["jobs"]["changes"]["permissions"], {"contents": "read"})
        deploy = self.workflow["jobs"]["deploy"]
        self.assertIn("github.event_name != 'pull_request'", deploy["if"])
        self.assertIn("github.ref == 'refs/heads/main'", deploy["if"])

    def test_pull_request_filter_checks_the_complete_change_set(self):
        self.assertIn("changes", self.workflow["jobs"])
        change_job = self.workflow["jobs"]["changes"]
        script = next(step["run"] for step in change_job["steps"] if step.get("id") == "docs")

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            repository = root / "repository"
            repository.mkdir()
            output = root / "output"
            env = {
                key: os.environ[key]
                for key in ("PATH", "SYSTEMROOT", "WINDIR", "TMPDIR")
                if key in os.environ
            }
            env.update(
                HOME=directory,
                XDG_CONFIG_HOME=directory,
                GIT_CONFIG_NOSYSTEM="1",
                GIT_AUTHOR_NAME="Documentation tests",
                GIT_AUTHOR_EMAIL="docs-test@example.invalid",
                GIT_COMMITTER_NAME="Documentation tests",
                GIT_COMMITTER_EMAIL="docs-test@example.invalid",
            )

            def git(*args):
                result = subprocess.run(
                    ["git", *args],
                    cwd=repository,
                    env=env,
                    text=True,
                    capture_output=True,
                    check=True,
                )
                return result.stdout.strip()

            def classify(base, head):
                output.write_text("", encoding="utf-8")
                result = subprocess.run(
                    ["bash", "-e", "-c", script],
                    cwd=repository,
                    env={
                        **env,
                        "BASE_SHA": base,
                        "HEAD_SHA": head,
                        "GITHUB_OUTPUT": str(output),
                    },
                    text=True,
                    capture_output=True,
                )
                return result, output.read_text(encoding="utf-8")

            git("init", "--quiet")
            (repository / "seed.txt").write_text("baseline\n", encoding="utf-8")
            git("add", "seed.txt")
            git("commit", "-qm", "baseline")
            base = git("rev-parse", "HEAD")

            cases = (
                ("force-app/tests/classes/example.cls", False),
                ("docs/architecture/guide with spaces.md", True),
                ("docs-site/overrides/example.html", True),
                ("mkdocs.yml", True),
                ("requirements-docs.in", True),
                ("requirements-docs.txt", True),
                (".github/workflows/docs-pages.yml", True),
                ("README.md", True),
                ("other/README.MD", True),
                ("other/notes.md", True),
                ("other/notes.markdown", True),
                ("other/notes.mdx", True),
                ("other/diagram.mmd", True),
                ("other/diagram.MERMAID", True),
            )
            for path, expected in cases:
                file = repository / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text("changed\n", encoding="utf-8")
                git("add", path)
                git("commit", "-qm", "change")
                head = git("rev-parse", "HEAD")
                with self.subTest(path=path):
                    result, actual = classify(base, head)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(actual, f"docs={str(expected).lower()}\n")
                base = head

            (repository / "moved").mkdir()
            git("mv", "docs/architecture/guide with spaces.md", "moved/guide.txt")
            git("commit", "-qm", "move documentation")
            head = git("rev-parse", "HEAD")
            result, actual = classify(base, head)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(actual, "docs=true\n")
            base = head

            git("rm", "other/notes.md")
            git("commit", "-qm", "delete documentation")
            head = git("rev-parse", "HEAD")
            result, actual = classify(base, head)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(actual, "docs=true\n")
            base = head

            bulk = repository / "force-app/bulk"
            bulk.mkdir(parents=True)
            for index in range(301):
                (bulk / f"{index:03d}.cls").write_text("source\n", encoding="utf-8")
            git("add", "force-app/bulk")
            git("commit", "-qm", "large source change")
            head = git("rev-parse", "HEAD")
            result, actual = classify(base, head)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(actual, "docs=false\n")

            (repository / "zz-end").mkdir()
            (repository / "zz-end/late.md").write_text("documentation\n", encoding="utf-8")
            git("add", "zz-end/late.md")
            git("commit", "-qm", "add documentation")
            head = git("rev-parse", "HEAD")
            changed_paths = git("diff", "--name-only", f"{base}...{head}").splitlines()
            self.assertEqual(len(changed_paths), 302)
            self.assertEqual(changed_paths[-1], "zz-end/late.md")
            result, actual = classify(base, head)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(actual, "docs=true\n")

            result, actual = classify("missing-ref", head)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(actual, "")

    def test_main_and_manual_builds_are_not_skipped(self):
        self.assertEqual(self.workflow["on"]["push"]["branches"], ["main"])
        self.assertNotIn("paths", self.workflow["on"]["push"])
        self.assertIn("workflow_dispatch", self.workflow["on"])
        self.assertEqual(
            self.workflow["jobs"]["changes"]["if"], "github.event_name == 'pull_request'"
        )
        build = self.workflow["jobs"]["build"]
        self.assertEqual(build["needs"], "changes")
        self.assertIn("!cancelled()", build["if"])
        self.assertIn("github.event_name != 'pull_request'", build["if"])
        self.assertIn("needs.changes.outputs.docs != 'false'", build["if"])

    def test_deploy_requires_protected_pages_environment(self):
        deploy = self.workflow["jobs"]["deploy"]
        self.assertEqual(deploy["needs"], "build")
        self.assertEqual(deploy["environment"]["name"], "github-pages")
        self.assertEqual(
            deploy["permissions"],
            {"contents": "read", "pages": "write", "id-token": "write"},
        )

    def test_deploy_checks_latest_main_before_publishing(self):
        steps = self.workflow["jobs"]["deploy"]["steps"]
        guard = next(step for step in steps if "git/ref/heads/main" in step.get("run", ""))
        self.assertIn("GITHUB_SHA", guard["run"])
        self.assertIn("exit 1", guard["run"])
        deployment = next(i for i, step in enumerate(steps) if step.get("id") == "deployment")
        self.assertLess(steps.index(guard), deployment)

    def test_actions_are_pinned_and_checkout_does_not_persist_credentials(self):
        for job in self.workflow["jobs"].values():
            for step in job.get("steps", []):
                if "uses" in step:
                    self.assertRegex(step["uses"], r"^[^@]+@[0-9a-f]{40}$")
                    if step["uses"].startswith("actions/checkout@"):
                        self.assertEqual(step["with"]["persist-credentials"], "false")


if __name__ == "__main__":
    unittest.main()
