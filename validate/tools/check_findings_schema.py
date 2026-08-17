#!/usr/bin/env python3
# ============================================================================
# check_findings_schema.py -- the findings ledger's three-field schema, and
# the one rule that says when a finding is allowed to be called closed.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE SCHEMA THIS FILE ENFORCES (author's history-migration change order, 16
# August 2026). Every row of the findings ledger carries three fields:
#
#     fixedBy   full git commit hash of the fix; "" until fixed.
#     pinnedBy  validator ID(s) pinning the corrected behaviour ("v66"), or a
#               dev-test ID where the pin lives in plugin/dev/tests/.
#               "" means UNPINNED.
#     status    open | fixed-unpinned | closed.
#
# and `closed` requires BOTH fixedBy and pinnedBy non-empty. No other path to
# closed.
#
# WHY THE RULE IS WORTH A CHECKER. "Closed" in this repository has meant two
# different things, and the difference is the whole subject of the 15 August
# status file: a defect that was repaired, and a defect that was repaired and
# whose repair something would notice the loss of. Those are not the same
# claim. v61 spent a week attesting a repaired defect as still open out of
# committed evidence that had stopped being true; v29 asserted renders the
# tree has never been able to produce; v68's pin asserted a caller count,
# which a nonexistent procedure satisfies trivially. In each case the ledger
# would have said "closed" and been wrong in the same direction -- believing a
# repair was held in place by something that was not holding it.
#
# So `status` is not an editorial field. It is MECHANICAL from the other two,
# and this file recomputes it rather than reading it:
#
#     fixedBy ""      ->  open                (whatever pinnedBy says)
#     fixedBy set, pinnedBy ""  ->  fixed-unpinned
#     both set        ->  closed
#
# A row may not disagree with that table. The point is that "closed" cannot be
# typed; it has to be earned by two fields that are each independently
# checkable -- the hash against git, the validator ID against validate/.
#
# WHAT THIS FILE REFUSES TO DO QUIETLY. A checker that passes when it has
# nothing to check is the failure this repository has now hit twice -- the
# manifest whose `--check` was correct for twelve days while nothing ran it,
# and every pin that was satisfied by the absence of the thing it named. So:
#
#   * a MISSING ledger is a FAILURE, not a skip. If the ledger cannot be
#     found this file exits non-zero and says so. It never reports success
#     on a file it did not read.
#   * an EMPTY ledger is a FAILURE. Zero rows satisfy "every row has all
#     three fields" vacuously, and that is precisely the shape of pin this
#     repository has resolved to stop writing.
#
# USAGE
#   python3 validate/tools/check_findings_schema.py
#   python3 validate/tools/check_findings_schema.py path/to/ledger.json
#   python3 validate/tools/check_findings_schema.py --no-git   (skip hash lookup)
#
# Run from anywhere; the default ledger path is resolved from this file's
# location. Exit 0 iff clean. Stock Python 3, no third-party packages.
# ============================================================================

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VAL = os.path.dirname(HERE)                       # .../validate
ROOT = os.path.dirname(VAL)
DEFAULT_LEDGER = os.path.join(ROOT, "audit", "FINDINGS_MACHINE.json")

STATUSES = ("open", "fixed-unpinned", "closed")
FIELDS = ("fixedBy", "pinnedBy", "status")

fail_n = 0


def say(ok, what, detail=""):
    global fail_n
    if not ok:
        fail_n += 1
    print("%-4s  %-64s %s" % ("OK" if ok else "FAIL", what, detail))


# ---------------------------------------------------------------------------
# The status a row's two evidence fields entail. This is the change order's
# rule as a total function -- every combination of the two fields lands on
# exactly one literal, so there is no row whose status is a matter of opinion.
# ---------------------------------------------------------------------------
def entailed_status(fixed_by, pinned_by):
    if not fixed_by:
        return "open"
    if not pinned_by:
        return "fixed-unpinned"
    return "closed"


def is_str(v):
    return isinstance(v, str)


def norm(v):
    return v.strip() if is_str(v) else v


def row_label(row, i):
    """Whatever the row calls its identifier, for messages only. Not required
    by the schema -- a row with no id is still schema-valid, it is just harder
    to talk about, so this falls back to the index."""
    for k in ("id", "finding", "findingId", "ID", "key"):
        if is_str(row.get(k)) and row[k].strip():
            return row[k].strip()
    return "row[%d]" % i


def load_rows(path):
    """Accepts a bare list of rows, or an object wrapping them under one of
    the usual keys. Returns (rows, shape) or raises."""
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
    if isinstance(doc, list):
        return doc, "top-level array"
    if isinstance(doc, dict):
        for k in ("findings", "rows", "items"):
            if isinstance(doc.get(k), list):
                return doc[k], 'object, rows under "%s"' % k
        raise ValueError(
            "object with no findings array (looked for: findings, rows, items)")
    raise ValueError("top level is %s, expected array or object"
                     % type(doc).__name__)


def git_commit_exists(h):
    try:
        r = subprocess.run(["git", "-C", ROOT, "cat-file", "-t", h],
                           capture_output=True, text=True, timeout=20)
        return r.returncode == 0 and r.stdout.strip() == "commit"
    except Exception:
        return None          # git unavailable -- not a pass and not a failure


def main():
    args = [a for a in sys.argv[1:] if a != "--no-git"]
    use_git = "--no-git" not in sys.argv[1:]
    path = args[0] if args else DEFAULT_LEDGER

    rel = os.path.relpath(path, ROOT) if path.startswith(ROOT) else path
    print("-- findings ledger schema: %s\n" % rel)

    # -----------------------------------------------------------------------
    # The ledger has to exist and has to parse. Both are failures rather than
    # skips: this file must never print a clean run over a file it never read.
    # -----------------------------------------------------------------------
    if not os.path.exists(path):
        say(False, "the ledger exists", "not found at " + rel)
        print("\n%d check(s) FAILED" % fail_n)
        return 1

    try:
        rows, shape = load_rows(path)
    except json.JSONDecodeError as e:
        say(False, "the ledger is valid JSON", "%s" % e)
        print("\n%d check(s) FAILED" % fail_n)
        return 1
    except ValueError as e:
        say(False, "the ledger holds an array of rows", "%s" % e)
        print("\n%d check(s) FAILED" % fail_n)
        return 1

    say(True, "the ledger exists and parses", shape)

    # An empty ledger passes every per-row rule below by having no rows. That
    # is the vacuous pass this repository has resolved to stop shipping.
    say(len(rows) > 0, "the ledger has at least one row",
        "%d row(s)" % len(rows))
    if not rows:
        print("\n%d check(s) FAILED" % fail_n)
        return 1

    non_obj = [i for i, r in enumerate(rows) if not isinstance(r, dict)]
    say(not non_obj, "every row is an object",
        "" if not non_obj else "row index/es " + ", ".join(map(str, non_obj)))
    if non_obj:
        print("\n%d check(s) FAILED" % fail_n)
        return 1

    # -----------------------------------------------------------------------
    # 1. Every row carries all three fields, as strings.
    # -----------------------------------------------------------------------
    missing, nonstr = [], []
    for i, r in enumerate(rows):
        for f in FIELDS:
            if f not in r:
                missing.append("%s: no %s" % (row_label(r, i), f))
            elif not is_str(r[f]):
                nonstr.append("%s: %s is %s, not a string"
                              % (row_label(r, i), f, type(r[f]).__name__))
    say(not missing, "every row carries fixedBy, pinnedBy and status",
        "" if not missing else "%d gap(s)" % len(missing))
    for m in missing:
        print("        " + m)
    say(not nonstr, "and all three are strings",
        "" if not nonstr else "%d wrong type(s)" % len(nonstr))
    for m in nonstr:
        print("        " + m)

    # Rows that failed the shape check cannot be reasoned about further.
    ok_rows = [(i, r) for i, r in enumerate(rows)
               if all(f in r and is_str(r[f]) for f in FIELDS)]

    # -----------------------------------------------------------------------
    # 2. status is one of the three literals. Spelling is part of the schema:
    #    a consumer switching on "fixed_unpinned" or "Closed" silently drops
    #    the row into whatever its default branch is.
    # -----------------------------------------------------------------------
    bad_lit = ["%s: status %r" % (row_label(r, i), r["status"])
               for i, r in ok_rows if norm(r["status"]) not in STATUSES]
    say(not bad_lit, "status is one of open | fixed-unpinned | closed",
        "" if not bad_lit else "%d bad literal(s)" % len(bad_lit))
    for m in bad_lit:
        print("        " + m)

    lit_rows = [(i, r) for i, r in ok_rows if norm(r["status"]) in STATUSES]

    # -----------------------------------------------------------------------
    # 3. THE RULE. closed requires both fields non-empty.
    # -----------------------------------------------------------------------
    bad_closed = []
    for i, r in lit_rows:
        if norm(r["status"]) != "closed":
            continue
        why = [f for f in ("fixedBy", "pinnedBy") if not norm(r[f])]
        if why:
            bad_closed.append("%s: closed with empty %s"
                              % (row_label(r, i), " and ".join(why)))
    say(not bad_closed, "no row is closed without both fixedBy and pinnedBy",
        "" if not bad_closed else "%d unearned closure(s)" % len(bad_closed))
    for m in bad_closed:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 4. And the rule's other three quarters. status is mechanical from the
    #    two evidence fields, so a row claiming `open` while carrying a fix
    #    hash is as wrong as an unearned closure -- it just fails safe rather
    #    than flattering. Checking only the closed direction would leave the
    #    backfill queue -- the fixed-unpinned rows, which are the reason the
    #    schema exists -- unenforced.
    # -----------------------------------------------------------------------
    mism = []
    for i, r in lit_rows:
        want = entailed_status(norm(r["fixedBy"]), norm(r["pinnedBy"]))
        got = norm(r["status"])
        if want != got:
            mism.append("%s: status %r, but fixedBy %s and pinnedBy %s entail %r"
                        % (row_label(r, i), got,
                           "set" if norm(r["fixedBy"]) else "empty",
                           "set" if norm(r["pinnedBy"]) else "empty", want))
    say(not mism, "status agrees with what fixedBy and pinnedBy entail",
        "" if not mism else "%d disagreement(s)" % len(mism))
    for m in mism:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 5. fixedBy is a FULL hash. The change order says full, and the reason is
    #    the reason the field exists: an abbreviation is ambiguous as the tree
    #    grows, and a hash nobody can resolve is the "wrong hash is worse than
    #    none" case with extra steps.
    # -----------------------------------------------------------------------
    bad_hash = []
    for i, r in lit_rows:
        h = norm(r["fixedBy"])
        if not h:
            continue
        if len(h) != 40 or any(c not in "0123456789abcdef" for c in h.lower()):
            bad_hash.append("%s: fixedBy %r is not a 40-char hex hash"
                            % (row_label(r, i), h))
    say(not bad_hash, "every fixedBy is a full 40-character hash",
        "" if not bad_hash else "%d malformed" % len(bad_hash))
    for m in bad_hash:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 6. And it names a commit that is actually in this repository. This is
    #    the check that catches a plausible-looking hash from somewhere else.
    #    Skipped -- announced, not silently -- when git cannot answer.
    # -----------------------------------------------------------------------
    if use_git:
        unknown, unresolved = [], False
        for i, r in lit_rows:
            h = norm(r["fixedBy"])
            if not h or h in [b.split(":")[0] for b in bad_hash]:
                continue
            got = git_commit_exists(h)
            if got is None:
                unresolved = True
                break
            if not got:
                unknown.append("%s: fixedBy %s is not a commit in this repo"
                               % (row_label(r, i), h))
        if unresolved:
            print("%-4s  %-64s %s" % ("--", "fixedBy hashes resolve in this repo",
                                      "skipped: git unavailable"))
        else:
            say(not unknown, "every fixedBy names a commit in this repository",
                "" if not unknown else "%d unresolvable" % len(unknown))
            for m in unknown:
                print("        " + m)

    # -----------------------------------------------------------------------
    # The census. Not an assertion -- a photograph, printed because the
    # fixed-unpinned count is the number this change order exists to surface.
    # -----------------------------------------------------------------------
    tally = {s: 0 for s in STATUSES}
    for _, r in lit_rows:
        tally[norm(r["status"])] += 1
    print("\n-- census -------------------------------------------------------")
    for s in STATUSES:
        print("   %-16s %d" % (s, tally[s]))
    if tally["fixed-unpinned"]:
        print("   (fixed-unpinned is the backfill queue: repairs this project"
              "\n    believes it made and cannot prove.)")

    print("\n%s" % ("all checks passed" if fail_n == 0
                    else "%d check(s) FAILED" % fail_n))
    return 0 if fail_n == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
