import argparse
import base64
import hashlib
import hmac
import io
import subprocess
import sys
import tarfile
from pathlib import Path
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parents[1]
MERMAID_URL = "https://registry.npmjs.org/mermaid/-/mermaid-11.17.2.tgz"
MERMAID_INTEGRITY = (
    "V6K3C8EBdEsPFZXSKMJe6ppQOENxuHARr9GvHX4hh47lAbhMRD9qf4oEK7LoaRQx"
    "ULMa80/qt5gHO73aCleBBg=="
)
MAX_ARCHIVE_BYTES = 32 * 1024 * 1024
MAX_MEMBER_BYTES = 8 * 1024 * 1024


def extract_mermaid(data):
    digest = base64.b64encode(hashlib.sha512(data).digest()).decode()
    if not hmac.compare_digest(digest, MERMAID_INTEGRITY):
        raise ValueError("Mermaid archive integrity check failed")

    with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as package:
        contents = []
        for name in ("package/dist/mermaid.min.js", "package/LICENSE"):
            try:
                member = package.getmember(name)
            except KeyError as error:
                raise ValueError(f"Mermaid archive is missing {name}") from error
            if not member.isfile() or member.size > MAX_MEMBER_BYTES:
                raise ValueError(f"Invalid Mermaid archive member: {name}")
            with package.extractfile(member) as stream:
                contents.append(stream.read())
        return tuple(contents)


def main():
    parser = argparse.ArgumentParser(description="Build the documentation site.")
    parser.add_argument("--site-dir", type=Path, default=ROOT / "site")
    args = parser.parse_args()
    site_dir = args.site_dir.resolve()
    if site_dir in (ROOT, *ROOT.parents) or site_dir == ROOT / "docs":
        raise ValueError("The site directory must not contain the repository or docs source")

    with urlopen(MERMAID_URL, timeout=60) as response:
        archive = response.read(MAX_ARCHIVE_BYTES + 1)
    if len(archive) > MAX_ARCHIVE_BYTES:
        raise ValueError("Mermaid archive exceeds the size limit")
    runtime, license_text = extract_mermaid(archive)

    subprocess.run(
        [
            sys.executable,
            "-m",
            "mkdocs",
            "build",
            "--strict",
            "--config-file",
            str(ROOT / "mkdocs.yml"),
            "--site-dir",
            str(site_dir),
        ],
        cwd=ROOT,
        check=True,
    )
    assets = site_dir / "assets" / "javascripts"
    assets.mkdir(parents=True, exist_ok=True)
    (assets / "mermaid.min.js").write_bytes(runtime)
    (assets / "mermaid-LICENSE.txt").write_bytes(license_text)
    print(f"Documentation site built in {site_dir}")


if __name__ == "__main__":
    main()
