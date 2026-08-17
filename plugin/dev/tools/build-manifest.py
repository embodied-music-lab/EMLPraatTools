#!/usr/bin/env python3
"""Regenerate MANIFEST.txt for the EML Stats & Graphs plugin.

Why this exists
---------------
MANIFEST.txt was hand-maintained. Two of its four columns -- line/word count
and version -- are derived from file contents and therefore drift silently
the moment any file is edited. As of the 2026-08-02 manifest, the drift had
already reached at least three rows (eml-test-helpers 1.0 vs 1.2 on disk,
test-regression 1.0 vs 1.1, eml-draw-procedures 1.19/3949 vs 1.20/4016).
A stale count in a manifest is the same class of defect as a hardcoded
version in a download URL: it looks authoritative and is wrong.

The fourth column -- description -- is *curated*, not derivable. Several
descriptions in the existing manifest deliberately differ from the file's
own title line (e.g. verify-shapiro-wilk.R). This script therefore
PRESERVES descriptions by keying on path and only recomputes the derived
columns. A file with no inherited description gets a best-effort guess
marked `TODO:` so it is visible rather than silently invented.

Usage
-----
    python3 dev/tools/build-manifest.py                 # rewrite MANIFEST.txt
    python3 dev/tools/build-manifest.py --check         # exit 1 if stale
    python3 dev/tools/build-manifest.py --date 2026-08-03

Exit status: 0 = manifest written (or already current under --check),
1 = --check found drift, 2 = usage/IO error.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import re
import sys
from pathlib import Path

# Plugin root, relative to this file (dev/tools/build-manifest.py).
ROOT = Path(__file__).resolve().parent.parent.parent
MANIFEST = ROOT / "MANIFEST.txt"

# Directories never walked.
SKIP_DIRS = {"__pycache__", ".git", ".idea", ".vscode"}

# Files never listed in the manifest body.
SKIP_NAMES = {"MANIFEST.txt", ".DS_Store"}

# Suffixes never listed (build/editor droppings and local backups).
SKIP_SUFFIXES = {".bak", ".pyc", ".orig", ".rej", ".swp", ".tmp"}

# Counted as prose (word count) rather than code (line count).
PROSE_SUFFIXES = {".md"}

# Listed separately at the foot of the manifest rather than in the body.
RETIRED_DIR = "dev/retired"

# FOLDED ASSET SETS — one row for the directory, not one row per file.
#
# sprites/ is 204 pre-rendered PNGs named shape_colour_alpha_size.png. The
# code addresses them as a family (@emlSetColorPalette fills .sprite$[1..10]
# and @emlDrawAlphaDot composes the stem with an alpha and a size), never one
# by one, so there is nothing to say about dot_blue_a50_30.png that its name
# does not already say. Listed individually they would be 204 of the
# manifest's 225 rows, each carrying a curated description nobody will ever
# write and a "lines" figure computed by splitting binary PNG data on
# newlines — a meaningless number in a column headed "lines (code)".
#
# The folded row still fails the check on any real change: it carries the
# file count and a content digest over every byte of the set, so adding,
# deleting or re-rendering one sprite moves it. Reproduce the digest with:
#
#   find plugin/sprites -type f | LC_ALL=C sort | \
#       while read f; do printf '%s\0' "${f#plugin/}"; cat "$f"; done | \
#       sha256sum
FOLDED_DIRS = ("sprites",)

VERSION_RE = re.compile(r"^[#;]{0,2}\s*Version:\s*(\S+)\s*$")

ROW_RE = re.compile(r"^(?P<path>[^|]+?)\s*\|\s*(?P<size>[^|]*?)\s*\|"
                    r"\s*(?P<version>[^|]*?)\s*\|\s*(?P<desc>.*?)\s*$")

HEADER_TEMPLATE = """\
# ==========================================================================
# MANIFEST — EML Stats & Graphs plugin
# Generated: {date}  |  {n} files in {rows} rows (retired included, MANIFEST.txt not)
# Columns: path | lines (code) or word count (prose) | version | description
#
# Regenerate with: python3 dev/tools/build-manifest.py
# Check without writing: python3 dev/tools/build-manifest.py --check
#
# The first three columns are derived from file contents and are rewritten
# on every run. The description column is curated — it is inherited by path
# and never overwritten. New files arrive with a `TODO:` description; edit
# it here and it will be preserved from then on.
#
# THIS FILE IS GENERATED AND CHECKED IN, so it goes stale the moment any
# listed file changes size or version — which is most commits. It stays
# green because --check runs in CI on every push and pull request
# (.github/workflows/validate.yml, through validate/run_all.R). That gate is
# the only thing keeping a checked-in generated file honest; without it this
# manifest drifts from the tree within a day.
#
# A row whose path ends in "/" is a FOLDED ASSET SET: one row for a directory
# of uniform generated assets, carrying the file count and a sha256 over the
# whole set in place of a line count and a version. See FOLDED_DIRS in
# dev/tools/build-manifest.py for the digest recipe.
# ==========================================================================
"""


def read_text(path: Path) -> str:
    """Read a file as text, tolerating the odd BOM or stray byte."""
    return path.read_bytes().decode("utf-8-sig", errors="replace")


def measure(path: Path) -> str:
    text = read_text(path)
    if path.suffix.lower() in PROSE_SUFFIXES:
        return "~{} words".format(len(text.split()))
    # Line count matching `wc -l` semantics for files with a trailing
    # newline, but counting a final unterminated line too.
    lines = text.splitlines()
    return str(len(lines))


def extract_version(path: Path) -> str:
    """Return the declared version, or '-' if the file does not declare one.

    Only a dedicated `Version:` header line counts. A version mentioned in
    prose ("Revised: 2 August 2026 (v1.1)") is deliberately NOT picked up:
    the existing manifest treats those files as unversioned, and inferring
    a version from prose would silently change the meaning of the column.
    """
    if path.suffix.lower() in PROSE_SUFFIXES:
        return "-"
    try:
        text = read_text(path)
    except OSError:
        return "-"
    for line in text.splitlines()[:60]:
        m = VERSION_RE.match(line.strip())
        if m:
            return m.group(1)
    return "-"


DOCSTRING_RE = re.compile(r'^\s*(?:[rubRUB]{0,2})("""|\'\'\')')


def first_docstring_line(text: str) -> str | None:
    """First non-empty line of a module docstring, or None.

    Only considers a docstring that opens in the first few statements of
    the file (after any shebang / encoding line / blank lines), which is
    where a module docstring lives.
    """
    lines = text.splitlines()
    for idx, raw in enumerate(lines[:10]):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = DOCSTRING_RE.match(line)
        if not m:
            return None
        quote = m.group(1)
        rest = line[m.end():].strip()
        if rest:
            return rest.rstrip(quote).strip() or None
        for follow in lines[idx + 1:idx + 6]:
            body = follow.strip()
            if body and body != quote:
                return body.rstrip(quote).strip() or None
        return None
    return None


def guess_description(path: Path) -> str:
    """Best-effort title for a file with no inherited description."""
    try:
        text = read_text(path)
    except OSError:
        return "TODO: describe this file"

    # Python: the module docstring is the authored summary; a leading
    # comment is usually the shebang or an encoding line.
    if path.suffix.lower() == ".py":
        doc = first_docstring_line(text)
        if doc:
            return "TODO: " + doc

    for raw in text.splitlines()[:40]:
        line = raw.strip()
        if not line:
            continue
        if path.suffix.lower() in PROSE_SUFFIXES:
            if line.startswith("#"):
                return "TODO: " + line.lstrip("#").strip()
            continue
        # Shebang / encoding pragma — not a description.
        if line.startswith("#!") or line.startswith("# -*-"):
            continue
        if not line.startswith("#"):
            continue
        body = line.lstrip("#").strip()
        # Skip rule bars (# ====== / # ------).
        if body and set(body) <= set("=-_ "):
            continue
        if body:
            return "TODO: " + body
    return "TODO: describe this file"


def load_existing() -> dict[str, str]:
    """Path -> curated description, from the current MANIFEST.txt."""
    descriptions: dict[str, str] = {}
    if not MANIFEST.exists():
        return descriptions
    for raw in read_text(MANIFEST).splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "|" not in line:
            continue
        m = ROW_RE.match(line)
        if m:
            descriptions[m.group("path")] = m.group("desc")
    return descriptions


def folded_row(name: str) -> tuple[str, int]:
    """(row text without the description, file count) for one asset set.

    The digest covers the path and the bytes of every file in the set, so it
    moves if a sprite is added, removed, renamed or re-rendered. Paths go in
    NUL-separated and unhashed lengths are impossible to confuse, which is
    what stops "a.png"+"b" hashing the same as "a.pngb"+"".
    """
    d = ROOT / name
    files = sorted((p for p in d.rglob("*") if p.is_file()),
                   key=lambda p: p.relative_to(ROOT).as_posix())
    h = hashlib.sha256()
    total = 0
    for p in files:
        h.update(p.relative_to(ROOT).as_posix().encode("utf-8"))
        h.update(b"\0")
        data = p.read_bytes()
        total += len(data)
        h.update(data)
    return ("{}/ | {} files, {} bytes | sha256:{}".format(
        name, len(files), total, h.hexdigest()[:16]), len(files))


def collect() -> tuple[list[Path], list[Path], list[str]]:
    body: list[Path] = []
    retired: list[Path] = []
    folded: list[str] = []
    for name in FOLDED_DIRS:
        if (ROOT / name).is_dir():
            folded.append(name)
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if rel.name in SKIP_NAMES or rel.name.startswith("."):
            continue
        if path.suffix.lower() in SKIP_SUFFIXES:
            continue
        if rel.parts and rel.parts[0] in folded:
            continue
        if rel.as_posix().startswith(RETIRED_DIR + "/"):
            retired.append(path)
        else:
            body.append(path)
    return body, retired, folded


def render(date: str) -> str:
    inherited = load_existing()
    body, retired, folded = collect()

    new_files: list[str] = []
    # (sort key, row without description, description) so the folded rows
    # land in path order beside the files rather than in a block at the end.
    rows: list[tuple[str, str, str]] = []

    for path in body:
        rel = path.relative_to(ROOT).as_posix()
        desc = inherited.get(rel)
        if desc is None:
            desc = guess_description(path)
            new_files.append(rel)
        rows.append((rel, "{} | {} | {}".format(
            rel, measure(path), extract_version(path)), desc))

    n_files = len(body)
    for name in folded:
        row, count = folded_row(name)
        n_files += count
        key = name + "/"
        desc = inherited.get(key)
        if desc is None:
            desc = "TODO: describe this asset set"
            new_files.append(key)
        rows.append((key, row, desc))

    rows.sort(key=lambda r: r[0])
    # The count is every file this manifest LISTS, retired rows included --
    # a count over the body alone reads as a claim about the tree while being
    # a claim about part of it.
    n_files += len(retired)
    lines = [HEADER_TEMPLATE.format(date=date, n=n_files,
                                    rows=len(rows) + len(retired)), ""]
    lines += ["{} | {}".format(r[1], r[2]) for r in rows]

    if retired:
        lines.append("")
        lines.append("# --------------------------------------------------"
                     "------------------------")
        lines.append("# RETIRED — moved out of the plugin, kept on disk "
                     "because this tree is not")
        lines.append("# under version control. Not shipped, not discovered "
                     "by the test runner.")
        lines.append("# See dev/retired/README.md for why each was retired.")
        lines.append("# --------------------------------------------------"
                     "------------------------")
        for path in retired:
            rel = path.relative_to(ROOT).as_posix()
            desc = inherited.get(rel) or guess_description(path)
            lines.append("{} | {} | {} | {}".format(
                rel, measure(path), extract_version(path), desc))

    for rel in new_files:
        print("new file (description marked TODO): {}".format(rel),
              file=sys.stderr)

    present = {p.relative_to(ROOT).as_posix() for p in body + retired}
    present |= {name + "/" for name in folded}
    dropped = sorted(set(inherited) - present)
    for rel in dropped:
        print("no longer present, row dropped: {}".format(rel),
              file=sys.stderr)

    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="do not write; exit 1 if MANIFEST.txt is stale")
    parser.add_argument("--date", default=None,
                        help="date stamp for the header (default: today)")
    args = parser.parse_args()

    date = args.date or datetime.date.today().isoformat()
    rendered = render(date)

    if args.check:
        current = read_text(MANIFEST) if MANIFEST.exists() else ""
        # Ignore the Generated: line, which carries only the date stamp.
        strip = lambda t: "\n".join(
            l for l in t.splitlines() if not l.startswith("# Generated:"))
        if strip(current) == strip(rendered):
            print("MANIFEST.txt is current.")
            return 0
        print("MANIFEST.txt is STALE — run build-manifest.py.",
              file=sys.stderr)
        return 1

    MANIFEST.write_text(rendered, encoding="utf-8")
    print("wrote {}".format(MANIFEST))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except OSError as exc:
        print("error: {}".format(exc), file=sys.stderr)
        sys.exit(2)
