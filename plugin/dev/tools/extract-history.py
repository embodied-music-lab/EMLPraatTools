#!/usr/bin/env python3
"""Capture the header-history blocks out of the shipped .praat files, verbatim.

Why this exists
---------------
A shipped file describes what the code DOES. It does not narrate what the code
used to do wrong: that is change history, and change history belongs in git and
in the developer ledger, where a reader who wants it can go and get it, and
where it cannot be mistaken for a statement about the behaviour of the file
they are reading.

Removing that material is easy. Removing it WITHOUT LOSING IT is the part that
needs an instrument, because the loss is silent -- a deleted comment leaves no
hole, and nobody notices for a year that the one sentence explaining a
threshold went out with the version log around it. So the order is: capture
first, delete second, prove third. This is the capture.

    dev/HISTORY_LEDGER.md  <- everything this tool copies out, verbatim,
                              stamped with the file, the commit and the
                              ORIGINAL line numbers, so any block can be
                              found again with `git show <commit>:<path>`.

TAKING A REVISION IS NOT OPTIONAL. Two sweeps on 16 August 2026 deleted a
large amount of this material before this tool existed, so the tree at HEAD is
already missing it and a HEAD-only capture would produce a ledger that looks
complete and is not -- the exact failure "capture first" exists to prevent,
arriving by the back door. The tool therefore reads its files out of a named
git revision (`git show <rev>:<path>`), never off the working tree, and is
meant to be run once per revision that held history: the pre-sweep tree for
what the sweeps took, and HEAD for what is still there.

WHAT A HISTORY BLOCK IS. A maximal run of comment lines each of which either
    (a) matches one of the patterns in PATTERNS below -- the same list the
        validate/v80 lint enforces, so capture and lint cannot drift apart --
        or
    (b) is an INDENTED CONTINUATION of the line that opened the run: a comment
        line with the same leading whitespace and the same comment marker,
        whose text is indented further than the opening line's text.
Rule (b) is what keeps a "v2.4:" entry attached to the eight indented lines
that explain it. A comment line that is neither ends the run, so a header's
"# Date:" line separates two entries into two blocks rather than swallowing
everything between them.

A BARE "#" DOES NOT END A RUN. An entry several paragraphs long puts an empty
comment line between its paragraphs, and reading that as the end of the block
was measured to truncate eml-output.praat's v2.4 entry at its second line and
leave the twenty-five indented lines under it behind -- material that is
history by every reading of it, orphaned under a heading that had been
deleted, which is the worst of both outcomes. An empty comment line with the
same lead and marker is therefore HELD: the run continues through it if it
resumes, and any held lines still trailing at the end are trimmed back off, so
a block never ends on one.

The block definition is deliberately the lint's own pattern list. If a line
would make v80 red, this tool captures it; if this tool captures it, v80 would
have made it red. That is the property the sweep's completeness argument rests
on -- completeness is proven by the lint, not by attention.

Usage
-----
    python3 dev/tools/extract-history.py <rev> [<rev> ...]
    python3 dev/tools/extract-history.py b4ca5e6 HEAD --out dev/HISTORY_LEDGER.md
    python3 dev/tools/extract-history.py HEAD --verbatim plugin/FIX_NOTES.md
    python3 dev/tools/extract-history.py HEAD --count-only

Prints a per-file line count for every revision walked, and the totals. With
--count-only nothing is written; that mode is how the reconciliation figures
in the report were taken.

Exit status: 0 = written (or counted), 2 = usage / git error.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# THE PATTERN LIST. Kept identical to validate/v80_shipped_history.R. Both
# sides state the list in their own language -- there is no shared file to
# import across R and Python -- so v80 asserts the two agree by re-deriving
# this list out of THIS file and comparing. Edit one, the suite goes red.
# ---------------------------------------------------------------------------
PATTERNS = [
    r"v\d+\.\d+:",
    r"item \d+ -",
    r"no longer",
    r"used to",
    r"previously",
    r"was broken",
    r"changed meaning",
    r"deprecat",
    r"CHANGELOG",
    r"FIX_NOTES",
]
RX = re.compile("|".join(PATTERNS))

# A Praat comment line: first non-blank character is "#" or ";".
COMMENT_RE = re.compile(r"^(\s*)([#;]+)(\s*)(.*)$")


def repo_root() -> Path:
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        sys.exit("extract-history: not inside a git repository (%s)" % exc)
    return Path(out.stdout.strip())


def git(args: list[str]) -> str:
    r = subprocess.run(["git"] + args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("extract-history: git %s failed: %s"
                 % (" ".join(args), r.stderr.strip()))
    return r.stdout


def resolve(rev: str) -> str:
    """Full commit id for a revision, so the ledger stamps cannot slide."""
    return git(["rev-parse", rev]).strip()


def shipped_paths(rev: str) -> list[str]:
    """The .praat files the plugin SHIPS, at a revision.

    plugin/ minus plugin/dev/. dev/ is the developer tree -- tests, tools,
    retired experiments -- and is not installed, so its headers may narrate
    freely; the rule is about what a user receives.
    """
    names = git(["ls-tree", "-r", "--name-only", rev]).split("\n")
    out = []
    for p in names:
        p = p.strip()
        if not p.endswith(".praat"):
            continue
        if not p.startswith("plugin/"):
            continue
        if p.startswith("plugin/dev/"):
            continue
        out.append(p)
    return sorted(out)


def comment_parts(line: str):
    """(lead, marker, text_indent_column) for a comment line, else None."""
    m = COMMENT_RE.match(line)
    if m is None:
        return None
    lead, marker, gap, body = m.groups()
    if body == "":
        # A bare "#" carries no text. It is a paragraph break inside an entry,
        # not the end of one: see the header. -1 marks it as held.
        return (lead, marker, -1)
    return (lead, marker, len(gap))


def find_blocks(lines: list[str]) -> list[tuple[int, int]]:
    """Maximal history blocks, as 1-based inclusive (start, end) line pairs."""
    blocks = []
    i = 0
    n = len(lines)
    while i < n:
        parts = comment_parts(lines[i])
        if parts is None or not RX.search(lines[i]):
            i += 1
            continue
        lead, marker, indent = parts
        start = i
        j = i + 1
        last_real = i                       # last line that was not a bare "#"
        while j < n:
            p = comment_parts(lines[j])
            if p is None:
                break
            if p[0] != lead or p[1] != marker:
                break
            if RX.search(lines[j]):
                last_real = j
                j += 1                      # another entry in the same run
                continue
            if p[2] > indent:
                last_real = j
                j += 1                      # indented continuation
                continue
            if p[2] == -1:
                j += 1                      # bare "#": held, see the header
                continue
            break
        blocks.append((start + 1, last_real + 1))
        i = max(j, last_real + 1)
    return blocks


def matching_lines(lines: list[str]) -> int:
    """Lines that would make v80 red. The reconciliation figure."""
    return sum(1 for ln in lines
               if comment_parts(ln) is not None and RX.search(ln))


def walk(rev: str):
    """Per-file blocks at a revision. Returns (sha, [(path, lines, blocks)])."""
    sha = resolve(rev)
    result = []
    for path in shipped_paths(sha):
        body = git(["show", "%s:%s" % (sha, path)])
        lines = body.split("\n")
        if lines and lines[-1] == "":
            lines.pop()
        blocks = find_blocks(lines)
        if blocks:
            result.append((path, lines, blocks))
    return sha, result


def render(rev_label: str, sha: str, walked, note: str) -> list[str]:
    out = []
    out.append("")
    out.append("# CAPTURE: %s (%s)" % (rev_label, sha[:7]))
    out.append("")
    out.append(note)
    out.append("")
    total = 0
    for path, lines, blocks in walked:
        for (a, b) in blocks:
            out.append("## %s @ %s" % (path, sha[:7]))
            out.append("")
            out.append("Lines %d-%d of %s at %s." % (a, b, path, sha[:7]))
            out.append("")
            out.append("```")
            for k in range(a, b + 1):
                out.append("%5d  %s" % (k, lines[k - 1]))
            out.append("```")
            out.append("")
            total += (b - a + 1)
    out.append("Captured at %s: %d lines in %d blocks across %d files."
               % (sha[:7], total,
                  sum(len(b) for _, _, b in walked), len(walked)))
    out.append("")
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("revs", nargs="+", help="git revisions to capture, in order")
    ap.add_argument("--out", default="plugin/dev/HISTORY_LEDGER.md",
                    help="ledger path, relative to the repository root")
    ap.add_argument("--label", action="append", default=[],
                    help="one label per revision, in the same order")
    ap.add_argument("--verbatim", action="append", default=[],
                    help="extra file (repo-relative) copied whole into the ledger")
    ap.add_argument("--count-only", action="store_true",
                    help="print counts, write nothing")
    args = ap.parse_args()

    root = repo_root()
    body = []
    grand = 0

    for k, rev in enumerate(args.revs):
        label = args.label[k] if k < len(args.label) else rev
        sha, walked = walk(rev)
        lines_total = sum(b - a + 1 for _, _, bl in walked for (a, b) in bl)
        match_total = sum(matching_lines(ln) for _, ln, _ in walked)
        grand += lines_total
        print("== %s (%s)" % (label, sha[:7]))
        for path, lines, blocks in walked:
            n = sum(b - a + 1 for (a, b) in blocks)
            print("%6d lines %3d blocks  %s" % (n, len(blocks), path))
        print("%6d lines %3d blocks  TOTAL  (%d lint-matching lines)"
              % (lines_total, sum(len(b) for _, _, b in walked), match_total))
        note = ("Every block below is copied verbatim from `%s`. Line numbers "
                "are the ORIGINAL ones at that commit; recover any file whole "
                "with `git show %s:<path>`." % (sha[:7], sha[:7]))
        body += render(label, sha, walked, note)

    for extra in args.verbatim:
        p = root / extra
        if not p.exists():
            sys.exit("extract-history: --verbatim file not found: %s" % extra)
        text = p.read_text(encoding="utf-8").split("\n")
        if text and text[-1] == "":
            text.pop()
        print("%6d lines  VERBATIM  %s" % (len(text), extra))
        grand += len(text)
        body.append("")
        body.append("# VERBATIM: %s" % extra)
        body.append("")
        body.append("Copied whole, before the move. %d lines." % len(text))
        body.append("")
        body.append("```")
        body += ["%5d  %s" % (i, ln) for i, ln in enumerate(text, 1)]
        body.append("```")
        body.append("")

    print("%6d lines  GRAND TOTAL" % grand)

    if args.count_only:
        return 0

    head = [
        "# HISTORY LEDGER — EML Stats & Graphs",
        "",
        "Ian Howell — Embodied Music Lab — GPL-3.0-or-later",
        "",
        "Generated by `dev/tools/extract-history.py`. Do not hand-edit: rerun",
        "the tool. Nothing here is a statement about how the code behaves",
        "today — every block is a QUOTATION of a comment that a shipped file",
        "once carried, kept so that removing it from the shipped tree loses",
        "nothing. For what the code does now, read the code.",
        "",
        "Each block is stamped with the commit it was read from, so a reader",
        "can tell material the 16 August sweeps removed BEFORE this ledger",
        "existed (captured here from the pre-sweep tree) from material the",
        "ledgered sweep removed (captured from HEAD).",
        "",
    ]
    out_path = root / args.out
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(head + body).rstrip("\n") + "\n",
                        encoding="utf-8")
    print("wrote %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
