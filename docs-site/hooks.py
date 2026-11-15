import posixpath
import re
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit, urlunsplit

from mkdocs.structure.files import File


ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = "https://github.com/navikt/crm-arbeidsforhold"
PDF = "docs/integrations/p360/source/sif-api.pdf"
LINK = re.compile(r"(?P<prefix>\]\()(?P<target><[^>]+>|[^\s)]+)")
FENCE = re.compile(r"^\s{0,3}(`{3,}|~{3,})")
BACKTICKS = re.compile(r"(`+)")


def rewrite_link(target, page_uri):
    parts = urlsplit(target)
    if parts.scheme or parts.netloc or not parts.path or parts.path.startswith("/"):
        return target

    relative = unquote(parts.path)
    repo_path = posixpath.normpath(
        posixpath.join("docs", posixpath.dirname(page_uri), relative)
    )
    if repo_path == ".." or repo_path.startswith("../"):
        raise ValueError(f"Link leaves repository: {target} in {page_uri}")

    if repo_path == PDF or not repo_path.startswith("docs/"):
        kind = "tree" if (ROOT / repo_path).is_dir() else "blob"
        suffix = "/" if parts.path.endswith("/") and not repo_path.endswith("/") else ""
        path = f"/navikt/crm-arbeidsforhold/{kind}/main/{quote(repo_path)}{suffix}"
        return urlunsplit(("https", "github.com", path, parts.query, parts.fragment))

    if relative.endswith(".mmd"):
        return urlunsplit(("", "", parts.path + ".md", parts.query, parts.fragment))

    if (ROOT / repo_path / "README.md").is_file():
        return urlunsplit(
            ("", "", parts.path.rstrip("/") + "/README.md", parts.query, parts.fragment)
        )

    return target


def rewrite_markdown(markdown, page_uri):
    def replace(match):
        target = match.group("target")
        angled = target.startswith("<") and target.endswith(">")
        rewritten = rewrite_link(target[1:-1] if angled else target, page_uri)
        return match.group("prefix") + (f"<{rewritten}>" if angled else rewritten)

    lines = []
    fence = None
    for line in markdown.splitlines(keepends=True):
        marker = FENCE.match(line)
        if marker:
            sequence = marker.group(1)
            if fence is None:
                fence = sequence
            elif sequence[0] == fence[0] and len(sequence) >= len(fence):
                fence = None
            lines.append(line)
            continue
        if fence is not None:
            lines.append(line)
            continue

        parts = BACKTICKS.split(line)
        delimiter = None
        for index, part in enumerate(parts):
            if BACKTICKS.fullmatch(part):
                if delimiter is None:
                    delimiter = part
                elif part == delimiter:
                    delimiter = None
            elif delimiter is None:
                parts[index] = LINK.sub(replace, part)
        lines.append("".join(parts))
    return "".join(lines)


def on_files(files, config):
    for file in list(files):
        if file.src_uri == PDF.removeprefix("docs/"):
            files.remove(file)
        elif file.src_uri.endswith(".mmd"):
            source = Path(file.abs_src_path).read_text(encoding="utf-8")
            source_url = f"{REPOSITORY}/blob/main/docs/{quote(file.src_uri)}"
            title = Path(file.src_uri).stem
            content = (
                f"# {title}\n\n[Kjelde på GitHub]({source_url})\n\n"
                f"```mermaid\n{source.rstrip()}\n```\n"
            )
            files.append(File.generated(config, file.src_uri + ".md", content=content))
            files.remove(file)
    return files


def on_page_markdown(markdown, page, config, files):
    return rewrite_markdown(markdown, page.file.src_uri)
