import argparse
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


SITE_PREFIX = "/crm-arbeidsforhold/"


class PageLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = set()
        self.links = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if "id" in attributes:
            self.ids.add(attributes["id"])
        if tag == "a" and "name" in attributes:
            self.ids.add(attributes["name"])
        for attribute in ("href", "src"):
            if attributes.get(attribute):
                self.links.append(attributes[attribute])


def validate_site(root):
    root = root.resolve()
    pages = {}
    for file in root.rglob("*.html"):
        page = PageLinks()
        page.feed(file.read_text(encoding="utf-8"))
        pages[file.resolve()] = page

    errors = []
    for file, page in pages.items():
        for link in page.links:
            parts = urlsplit(link)
            if parts.scheme or parts.netloc:
                continue
            path = unquote(parts.path)
            if path.startswith("/"):
                if not path.startswith(SITE_PREFIX):
                    errors.append(f"{file.relative_to(root)}: link outside site: {link}")
                    continue
                target = root / path.removeprefix(SITE_PREFIX)
            else:
                target = file.parent / path if path else file
            target = target.resolve()
            if not target.is_relative_to(root):
                errors.append(f"{file.relative_to(root)}: link outside site: {link}")
                continue
            if target.is_dir():
                target = target / "index.html"
            if not target.is_file():
                errors.append(f"{file.relative_to(root)}: missing target: {link}")
                continue
            if parts.fragment and target in pages:
                if unquote(parts.fragment) not in pages[target].ids:
                    errors.append(f"{file.relative_to(root)}: missing anchor: {link}")
    return errors


def main():
    parser = argparse.ArgumentParser(description="Check generated site links and anchors.")
    parser.add_argument("site_dir", type=Path)
    args = parser.parse_args()
    root = args.site_dir.resolve()
    if not (root / "index.html").is_file():
        raise ValueError(f"No built site found at {root}")
    errors = validate_site(root)
    for error in errors:
        print(error)
    print(f"Checked {len(list(root.rglob('*.html')))} HTML pages; {len(errors)} errors")
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
