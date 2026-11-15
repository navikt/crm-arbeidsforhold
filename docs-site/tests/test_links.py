import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import hooks


class LinkRewritingTest(unittest.TestCase):
    def test_code_links_point_to_repository_and_keep_fragment(self):
        self.assertEqual(
            hooks.rewrite_link(
                "../../../force-app/integration/p360/classes/client/P360_RpcClient.cls#L23",
                "integrations/p360/kodegjennomgang.md",
            ),
            "https://github.com/navikt/crm-arbeidsforhold/blob/main/"
            "force-app/integration/p360/classes/client/P360_RpcClient.cls#L23",
        )

    def test_directory_links_use_repository_tree(self):
        self.assertEqual(
            hooks.rewrite_link("../bin/", "README.md"),
            "https://github.com/navikt/crm-arbeidsforhold/tree/main/bin/",
        )

    def test_diagram_links_open_generated_pages(self):
        self.assertEqual(
            hooks.rewrite_link("architecture/pakkeoversikt.mmd", "README.md"),
            "architecture/pakkeoversikt.mmd.md",
        )

    def test_documentation_directory_links_resolve_to_index(self):
        self.assertEqual(
            hooks.rewrite_link("architecture/", "README.md"),
            "architecture/README.md",
        )

    def test_third_party_pdf_is_not_served_as_site_asset(self):
        self.assertEqual(
            hooks.rewrite_link("source/sif-api.pdf", "integrations/p360/README.md"),
            "https://github.com/navikt/crm-arbeidsforhold/blob/main/"
            "docs/integrations/p360/source/sif-api.pdf",
        )

    def test_regular_and_external_links_are_unchanged(self):
        for target in (
            "architecture/hele-loysinga.md#organisering",
            "#evidens",
            "https://example.org/a.mmd",
            "mailto:docs@example.org",
        ):
            with self.subTest(target=target):
                self.assertEqual(hooks.rewrite_link(target, "README.md"), target)

    def test_fenced_code_is_not_rewritten(self):
        markdown = (
            "[diagram](architecture/pakkeoversikt.mmd)\n\n"
            "```markdown\n"
            "[example](architecture/pakkeoversikt.mmd)\n"
            "```\n"
        )
        self.assertEqual(
            hooks.rewrite_markdown(markdown, "README.md"),
            "[diagram](architecture/pakkeoversikt.mmd.md)\n\n"
            "```markdown\n"
            "[example](architecture/pakkeoversikt.mmd)\n"
            "```\n",
        )


if __name__ == "__main__":
    unittest.main()
