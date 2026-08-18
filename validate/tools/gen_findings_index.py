#!/usr/bin/env python3
# ============================================================================
# gen_findings_index.py -- audit/FINDINGS_INDEX.md, generated from the register.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Until 18 August 2026 audit/FINDINGS_INDEX.md was doing
# two jobs in one document: it was the register of finding status AND it was
# the narrative of how the audit went. That is not a filing preference, it is
# the defect. A dated status paragraph near the top said D125 "is NOT closed --
# it is in flight" and a row two hundred lines below said "LIVE 7 Aug", while
# validate/v28_column_type_guard.R had closed it and said so in its own header;
# a "stands reopened" survived beside its own correction for twelve days.
# Interleaved, nothing in the file was wrong at the moment it was written and
# the file as a whole was wrong the day after.
#
# So the two jobs are split, and the direction of generation is the whole
# point. Deriving structure from prose is fragile -- it is a parser over
# sentences somebody will rewrite. Deriving prose from structure is a report
# generator, and this is it. audit/FINDINGS_MACHINE.json states; this file
# renders; audit/FINDINGS_NARRATIVE.md remembers, append-only and dated, and
# never states current status.
#
# THE LINT IS THE POINT, and it is `--check`: regenerate into memory, diff
# against what is on disk, exit non-zero on any difference. Same shape as the
# export-ignore agreement check. An index edited by hand goes red on the next
# run rather than drifting quietly, which is exactly what the old file did.
#
# USAGE
#   python3 validate/tools/gen_findings_index.py            # write the index
#   python3 validate/tools/gen_findings_index.py --check    # diff, don't write
#   python3 validate/tools/gen_findings_index.py --stdout    # print, don't write
#
# Exit 0 iff clean. Stock Python 3, no third-party packages.
# ============================================================================

import difflib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
LEDGER = os.path.join(ROOT, "audit", "FINDINGS_MACHINE.json")
INDEX = os.path.join(ROOT, "audit", "FINDINGS_INDEX.md")

# The order rows are presented in. It is the order a reader needs them in --
# what is owed first, what is owed a pin second, what is settled last -- and
# it is fixed here rather than left to the ledger's insertion order, because a
# generated file whose ordering depends on where somebody appended a row
# produces a diff on every append and hides the real change.
STATUS_ORDER = ("open", "fixed-unpinned", "closed", "superseded", "refuted")

STATUS_GLOSS = {
    "open": "A repair is owed here. Nothing in the tree fixes it.",
    "fixed-unpinned": ("The backfill queue: a repair this project believes it "
                       "made and cannot prove. Nothing would go red if it were "
                       "undone."),
    "closed": ("Repaired, and something live would notice the repair going "
               "away. Both halves, or it is not closed."),
    "superseded": ("Never built. The work moved to a phase of the feature "
                   "roadmap, and the row's pointer says which."),
    "refuted": ("Somebody looked and there was no defect. The row's pointer "
                "says what they looked at."),
}


def natkey(s):
    """D9 before D110, NEW-G2-1 before NEW-G10-1. Digit runs compare as
    numbers, everything else as text, so an ID scheme that mixes them sorts
    the way a reader expects rather than the way ASCII does."""
    return tuple((int(t), "") if t.isdigit() else (-1, t)
                 for t in re.findall(r"\d+|\D+", s))


def rows_of(doc):
    return doc["findings"] if isinstance(doc, dict) else doc


def meta_of(doc):
    if not isinstance(doc, dict):
        return []
    return [(k, doc[k]) for k in ("session", "build", "praat", "accuracy_verdict")
            if isinstance(doc.get(k), str)]


def cell(s):
    """A table cell. Pipes and newlines end a row in GitHub-flavoured
    Markdown, so they are neutralised rather than emitted -- a title with a
    pipe in it must not silently split the table it is in."""
    return (str(s).replace("|", "\\|").replace("\n", " ").strip()) or "—"


def para(s):
    """A long field, unfolded onto one logical line. The ledger's prose
    carries its own newlines; Markdown would eat some of them and honour
    others, so they are all collapsed and the paragraph reflows."""
    return re.sub(r"\s+", " ", str(s)).strip()


def render(doc):
    rows = rows_of(doc)
    order = {s: i for i, s in enumerate(STATUS_ORDER)}
    rows = sorted(rows, key=lambda r: (order.get(str(r.get("status")), 99),
                                       r.get("severity", 99),
                                       natkey(str(r.get("id", "")))))
    tally = {s: sum(1 for r in rows if r.get("status") == s)
             for s in STATUS_ORDER}

    L = []
    a = L.append

    # LINE 1, and it says what this file is before it says anything else.
    a("<!-- GENERATED FILE. Do not edit. Regenerate with: "
      "python3 validate/tools/gen_findings_index.py -->")
    a("")
    a("# Findings register — EML Stats & Graphs")
    a("")
    a("**This file is generated from `audit/FINDINGS_MACHINE.json` and is a "
      "view of it, not a source.** Edits here are overwritten and are caught "
      "by `gen_findings_index.py --check`. To change what a row says, change "
      "the register. To say what an earlier record got wrong, add a dated "
      "entry to `FINDINGS_NARRATIVE.md` — that file is append-only and never "
      "states current status, because status is this file's only job.")
    a("")
    for k, v in meta_of(doc):
        a("- **%s** — %s" % (k.replace("_", " "), v))
    a("")
    a("## Census")
    a("")
    a("| status | rows | what the literal means |")
    a("|---|---:|---|")
    for s in STATUS_ORDER:
        a("| `%s` | %d | %s |" % (s, tally[s], STATUS_GLOSS[s]))
    a("| **total** | **%d** | |" % len(rows))
    a("")
    a("`status` is not an editorial field: it is entailed by `fixedBy` and "
      "`pinnedBy` (and, where the hash cannot speak, by the `pointer` kind), "
      "and `validate/tools/check_findings_schema.py` recomputes it rather than "
      "reading it. `closed` cannot be typed.")
    a("")

    a("## Rows")
    a("")
    a("| id | sev | area | status | verdict | fixedBy | pinnedBy | title |")
    a("|---|---:|---|---|---|---|---|---|")
    for r in rows:
        a("| `%s` | %s | %s | `%s` | %s | %s | %s | %s |" % (
            cell(r.get("id", "")),
            cell(r.get("severity", "")),
            cell(r.get("area", "")),
            cell(r.get("status", "")),
            cell(r.get("verdict", "")),
            "`%s`" % cell(r["fixedBy"]) if r.get("fixedBy") else "—",
            "`%s`" % cell(r["pinnedBy"]) if r.get("pinnedBy") else "—",
            cell(r.get("title", "")),
        ))
    a("")

    a("## Rows in full")
    a("")
    for r in rows:
        a("### `%s` — %s" % (r.get("id", ""), para(r.get("title", ""))))
        a("")
        a("`%s` · severity %s · %s · verdict %s · fixedBy %s · pinnedBy %s" % (
            r.get("status", ""), r.get("severity", "—"), r.get("area", "—"),
            r.get("verdict", "—"),
            "`%s`" % r["fixedBy"] if r.get("fixedBy") else "*(empty)*",
            "`%s`" % r["pinnedBy"] if r.get("pinnedBy") else "*(empty)*"))
        for label, key in (("Mechanism", "mechanism"),
                           ("Pointer", "pointer"),
                           ("Measured", "measured"),
                           ("Reach", "reach"),
                           ("Deferral", "deferral")):
            if r.get(key):
                a("")
                a("**%s.** %s" % (label, para(r[key])))
        a("")
    return "\n".join(L).rstrip("\n") + "\n"


def main():
    args = sys.argv[1:]
    if not os.path.exists(LEDGER):
        sys.stderr.write("gen_findings_index: no ledger at %s\n" % LEDGER)
        return 1
    with open(LEDGER, encoding="utf-8") as fh:
        doc = json.load(fh)
    want = render(doc)

    if "--stdout" in args:
        sys.stdout.write(want)
        return 0

    if "--check" in args:
        have = ""
        if os.path.exists(INDEX):
            with open(INDEX, encoding="utf-8") as fh:
                have = fh.read()
        if have == want:
            print("OK    audit/FINDINGS_INDEX.md is what the register renders")
            return 0
        print("FAIL  audit/FINDINGS_INDEX.md does not match the register")
        d = difflib.unified_diff(have.splitlines(True), want.splitlines(True),
                                 "on disk", "regenerated", n=2)
        sys.stdout.writelines(list(d)[:200])
        print("\nRegenerate: python3 validate/tools/gen_findings_index.py")
        return 1

    with open(INDEX, "w", encoding="utf-8") as fh:
        fh.write(want)
    print("wrote %s (%d rows)" % (os.path.relpath(INDEX, ROOT),
                                  len(rows_of(doc))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
