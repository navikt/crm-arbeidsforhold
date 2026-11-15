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
        deploy = self.workflow["jobs"]["deploy"]
        self.assertIn("github.event_name != 'pull_request'", deploy["if"])
        self.assertIn("github.ref == 'refs/heads/main'", deploy["if"])

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
