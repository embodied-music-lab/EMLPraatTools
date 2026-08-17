#!/usr/bin/env python3
# ============================================================================
# recipes/extract.py -- lift the runnable scripts out of docs/RECIPES.md
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY EXTRACTION AND NOT TRANSCRIPTION. A harness that holds its own copy of a
# documented script tests the copy. The two agree on the day they are written
# and nothing afterwards makes them keep agreeing: the page is edited by
# whoever is improving the prose, the copy is edited by whoever is fixing the
# test, and the reader is the only one running the version that is wrong.
# So the bytes that ship ARE the bytes that run. This file reads
# plugin/docs/RECIPES.md and writes one .praat per recipe, byte for byte.
#
# THE GRAMMAR, and it is deliberately dumb enough to state in one sentence:
#
#   * a recipe begins at an ATX heading matching `## R<digits>`;
#   * inside it, a fenced block opened with ```praat whose first non-blank
#     line begins with `include ` is that recipe's SCRIPT;
#   * every other fenced block is prose -- the annotation blocks, which are
#     all comment lines -- and is ignored.
#
# Every recipe must have exactly one script block. Two, or none, is an error
# rather than a silent pick, because "the harness ran a different block than
# the reader will paste" is the whole failure this file exists to prevent.
#
# WHAT IS WRITTEN OUT is the block VERBATIM -- the install-path prefix and the
# data-folder prefix are still the ones the page prints. run.sh substitutes
# those two prefixes into a staging copy at drive time and checks that
# reversing the substitution reproduces this file exactly. That keeps the
# committed evidence free of machine paths while leaving the two edits a real
# user makes visible in one place.
#
# Usage:
#   python3 extract.py <RECIPES.md> <outdir>
#     writes <outdir>/R<n>.praat for each recipe and prints one TSV line per
#     recipe on stdout:  recipe<TAB>lines<TAB>sha256
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

import hashlib
import os
import re
import sys

HEADING = re.compile(r"^## +(R\d+)\b")
FENCE_OPEN = re.compile(r"^```praat\s*$")
FENCE_ANY = re.compile(r"^```")


def extract(md_path):
    """Return [(recipe, text)] in document order. Raises on a broken page."""
    with open(md_path, "r", encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    recipe = None
    found = {}          # recipe -> text
    order = []
    in_fence = False
    fence_is_praat = False
    buf = []

    for lineno, line in enumerate(lines, start=1):
        if in_fence:
            if FENCE_ANY.match(line):
                in_fence = False
                if fence_is_praat:
                    body = [b for b in buf if b.strip()]
                    if body and body[0].startswith("include "):
                        if recipe is None:
                            raise SystemExit(
                                "extract.py: runnable block at line %d is "
                                "outside any ## R<n> recipe" % lineno)
                        if recipe in found:
                            raise SystemExit(
                                "extract.py: %s has more than one runnable "
                                "block (second ends line %d)" % (recipe, lineno))
                        found[recipe] = "\n".join(buf) + "\n"
                        order.append(recipe)
                buf = []
                continue
            buf.append(line)
            continue

        if FENCE_ANY.match(line):
            in_fence = True
            fence_is_praat = bool(FENCE_OPEN.match(line))
            buf = []
            continue

        m = HEADING.match(line)
        if m:
            recipe = m.group(1)

    if in_fence:
        raise SystemExit("extract.py: unclosed fenced block")

    # Every recipe heading must have produced a script. A heading with no
    # runnable block is a recipe nothing drives, which is the state this
    # whole harness exists to make impossible.
    headings = [HEADING.match(l).group(1) for l in lines if HEADING.match(l)]
    missing = [h for h in headings if h not in found]
    if missing:
        raise SystemExit("extract.py: no runnable block for: %s"
                         % ", ".join(missing))
    if not headings:
        raise SystemExit("extract.py: no ## R<n> recipe headings found")

    return [(r, found[r]) for r in order]


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: extract.py <RECIPES.md> <outdir>")
    md_path, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    for recipe, text in extract(md_path):
        path = os.path.join(outdir, recipe + ".praat")
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        sys.stdout.write("%s\t%d\t%s\n"
                         % (recipe, text.count("\n"), digest))


if __name__ == "__main__":
    main()
