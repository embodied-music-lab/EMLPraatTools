#!/usr/bin/env python3
# ============================================================================
# check_findings_schema.py -- the findings ledger's schema, and the one rule
# that says when a finding is allowed to be called closed.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE SCHEMA THIS FILE ENFORCES (author's history-migration change order, 16
# August 2026). Every row of the findings ledger carries three fields:
#
#     fixedBy   full git commit hash of the fix; the literal "pre-repo" for a
#               repair made before this repository existed; "" until fixed.
#     pinnedBy  validator ID(s) pinning the corrected behaviour ("v66"), or a
#               dev-test ID where the pin lives in plugin/dev/tests/.
#               "" means UNPINNED.
#     status    open | fixed-unpinned | closed | superseded.
#
# and `closed` requires BOTH fixedBy and pinnedBy non-empty. No other path to
# closed.
#
# and a fourth field, CONDITIONAL rather than universal:
#
#     pointer   "<kind>: <path>[:<line>|:<from>-<to>] <note>", where <kind> is
#               `evidence` or `roadmap`. Required on exactly the rows where the
#               hash cannot speak; validated wherever it appears.
#
# THE TWO ROWS THE HASH CANNOT SPEAK FOR, and why each gets a pointer instead
# of an empty field.
#
#   PRE-REPO REPAIRS. This repository's root commit is 9b7d5aa, 12 August
#   2026, which imported 2,818 files in one go. A repair made before that date
#   has no commit here to name, and naming the import would be false in the
#   way the change order warns about -- by that logic the import fixed all
#   forty-one. So `fixedBy` may read the literal `pre-repo`. That is a claim
#   about archaeology, and an unsupported claim of that shape is WORSE than
#   the empty field it replaces, because it reads as settled. So a `pre-repo`
#   row must carry an `evidence:` pointer at the earliest thing in this tree
#   that shows the fix present -- a validator, a capture, the import commit.
#   `pinnedBy` is untouched by any of this: a pre-repo repair with no live pin
#   is `fixed-unpinned` exactly like every other unpinned repair. A pointer is
#   a WITNESS STATEMENT about the past; a pin is a live check that would go
#   red if the repair were undone. The ledger has been wrong in that exact
#   direction before (see v83's header) and the two must not be confused.
#
#   ROADMAP-SUPERSEDED ROWS. A row filed as a defect that turns out never to
#   have been a fix at all -- the feature was never built, and the work now
#   lives in a phase of the feature roadmap -- is not `open`. `open` means a
#   repair is owed here. `superseded` means the work moved, and the row's job
#   is now to say where to. So it must carry a `roadmap:` pointer, and it may
#   not carry a fix or a pin: nothing was built, so there is nothing to have
#   fixed and nothing to hold in place.
#
# `superseded` is a statement about WHERE THE WORK LIVES. It is deliberately
# not a statement about whether the finding was a real defect -- the ledger has
# no literal for "examined and found not to be a defect", the two REFUTED rows
# still land on `open` mechanically, and that gap is an open question for the
# author, not something to be closed by stretching this literal over it.
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
#     fixedBy "", roadmap pointer  ->  superseded
#     fixedBy ""      ->  open                (whatever pinnedBy says)
#     fixedBy set, pinnedBy ""  ->  fixed-unpinned
#     both set        ->  closed
#
# The first line is what keeps `superseded` from being typeable: it is entailed
# by a pointer that names a file this checker opens, not by an editorial
# decision. Every literal in this schema has to be earned by a field something
# else can check -- the hash against git, the validator ID against validate/,
# the pointer against the filesystem.
#
# A row may not disagree with that table. The point is that "closed" cannot be
# typed; it has to be earned by fields that are each independently checkable.
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

STATUSES = ("open", "fixed-unpinned", "closed", "superseded")
FIELDS = ("fixedBy", "pinnedBy", "status")

# The one non-hash value `fixedBy` may take, spelled exactly. Case and
# punctuation are part of it: a convention that also accepts `pre_repo` and
# `PRE-REPO` is not a convention, it is three of them, and a consumer
# switching on the literal drops the near-misses into its default branch in
# the same silence that made `status` spelling load-bearing above.
PRE_REPO = "pre-repo"

POINTER = "pointer"
POINTER_KINDS = ("evidence", "roadmap")

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
def entailed_status(fixed_by, pinned_by, pointer_kind=""):
    if not fixed_by:
        return "superseded" if pointer_kind == "roadmap" else "open"
    if not pinned_by:
        return "fixed-unpinned"
    return "closed"


# ---------------------------------------------------------------------------
# The pointer's grammar, as a parser rather than as a description, so that the
# checks below act on parts and not on substrings.
#
#     <kind>: <path>[:<line>|:<from>-<to>] <note>
#
# Everything after the first run of whitespace following the path token is the
# note. The note's PRESENCE is enforced; its usefulness cannot be, and saying
# so here is more honest than a minimum length that invites padding. What IS
# mechanical is the path -- it is opened -- and the line numbers, which are
# checked against the file's real length, because a pointer at line 900 of a
# 300-line file is as dead as a pointer at a file that was deleted, and it
# rots the same way: silently, while the row goes on reading as settled.
# ---------------------------------------------------------------------------
def parse_pointer(text):
    """-> (kind, path, span, note, error). error is "" when the pointer parses;
    on error the other parts are best-effort and must not be trusted."""
    s = text.strip()
    if ":" not in s:
        return "", "", None, "", "no '<kind>:' prefix"
    kind, rest = s.split(":", 1)
    kind = kind.strip()
    if kind not in POINTER_KINDS:
        return kind, "", None, "", ("kind %r is not one of %s"
                                    % (kind, " | ".join(POINTER_KINDS)))
    rest = rest.strip()
    if not rest:
        return kind, "", None, "", "names nothing after the kind"
    parts = rest.split(None, 1)
    target = parts[0]
    note = parts[1].strip() if len(parts) > 1 else ""

    span = None
    path = target
    if ":" in target:
        head, tail = target.rsplit(":", 1)
        bits = tail.split("-")
        if head and bits and all(b.isdigit() and b for b in bits) \
                and len(bits) <= 2:
            path = head
            lo = int(bits[0])
            hi = int(bits[-1])
            if lo < 1 or hi < lo:
                return kind, path, None, note, "line span %r is not ascending" % tail
            span = (lo, hi)

    if not path:
        return kind, "", span, note, "names no path"
    if path.startswith("/") or path.startswith("~"):
        return kind, path, span, note, "path is absolute; pointers are repo-relative"
    if ".." in path.split("/"):
        return kind, path, span, note, "path escapes the repository"
    if not note:
        return kind, path, span, note, ("names %s and says nothing about what to "
                                        "read there" % path)
    return kind, path, span, note, ""


def pointer_kind_of(row):
    """The kind alone, for the entailment table. A pointer that does not parse
    has no kind, so it cannot entail anything -- which is the safe direction:
    the row falls back to `open` and its bad pointer is reported separately."""
    v = row.get(POINTER)
    if not is_str(v) or not v.strip():
        return ""
    kind, _p, _s, _n, err = parse_pointer(v)
    return "" if err else kind


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
    say(not bad_lit, "status is one of " + " | ".join(STATUSES),
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
        want = entailed_status(norm(r["fixedBy"]), norm(r["pinnedBy"]),
                               pointer_kind_of(r))
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
        if not h or h == PRE_REPO:
            continue
        if len(h) != 40 or any(c not in "0123456789abcdef" for c in h.lower()):
            extra = ""
            if h.lower().replace("_", "-") == PRE_REPO:
                extra = (" -- the pre-repo literal is spelled exactly %r"
                         % PRE_REPO)
            bad_hash.append("%s: fixedBy %r is neither a 40-char hex hash nor %r%s"
                            % (row_label(r, i), h, PRE_REPO, extra))
    say(not bad_hash,
        'every fixedBy is a full 40-character hash or the literal "pre-repo"',
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
            # "pre-repo" is the one value that is asserted by its pointer
            # rather than by git, and it is asserted below.
            if not h or h == PRE_REPO:
                continue
            if len(h) != 40 or any(c not in "0123456789abcdef" for c in h.lower()):
                continue          # already reported as malformed

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
    # 7. THE POINTER. Wherever one appears it must parse and its path must
    #    open; a pointer at a file that is not there is the failure this whole
    #    field exists to prevent, dressed as its own remedy.
    # -----------------------------------------------------------------------
    bad_ptr = []
    ptr_kind = {}                       # row index -> pointer kind
    for i, r in lit_rows:
        lbl = row_label(r, i)
        if POINTER not in r:
            continue
        v = r[POINTER]
        if not is_str(v):
            bad_ptr.append("%s: pointer is %s, not a string"
                           % (lbl, type(v).__name__))
            continue
        if not v.strip():
            bad_ptr.append("%s: pointer is empty; omit the field or fill it"
                           % lbl)
            continue
        kind, path, span, _note, err = parse_pointer(v)
        if err:
            bad_ptr.append("%s: pointer %s" % (lbl, err))
            continue
        full = os.path.join(ROOT, path)
        if not os.path.exists(full):
            bad_ptr.append("%s: pointer names %s, which does not exist" % (lbl, path))
            continue
        if span:
            if os.path.isdir(full):
                bad_ptr.append("%s: pointer gives a line span on a directory (%s)"
                               % (lbl, path))
                continue
            try:
                with open(full, "rb") as fh:
                    n_lines = sum(1 for _ in fh)
            except OSError as e:
                bad_ptr.append("%s: pointer names %s, which will not open (%s)"
                               % (lbl, path, e))
                continue
            if span[1] > n_lines:
                bad_ptr.append("%s: pointer names %s:%d, past its last line (%d)"
                               % (lbl, path, span[1], n_lines))
                continue
        ptr_kind[i] = kind
    say(not bad_ptr, "every pointer parses and opens the file it names",
        "" if not bad_ptr else "%d bad pointer(s)" % len(bad_ptr))
    for m in bad_ptr:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 8. And it is REQUIRED exactly where the hash cannot speak. A `pre-repo`
    #    with no pointer is worse than the empty field it replaced, because it
    #    looks settled; a `superseded` with no pointer says work moved and
    #    declines to say where.
    # -----------------------------------------------------------------------
    unsupported = []
    for i, r in lit_rows:
        lbl = row_label(r, i)
        kind = ptr_kind.get(i, "")
        if norm(r["fixedBy"]) == PRE_REPO and kind != "evidence":
            unsupported.append(
                '%s: fixedBy "%s" with no valid `evidence:` pointer -- name the '
                "earliest thing in this tree that shows the fix present"
                % (lbl, PRE_REPO))
        if norm(r["status"]) == "superseded" and kind != "roadmap":
            unsupported.append(
                "%s: status superseded with no valid `roadmap:` pointer -- name "
                "the phase the work moved to" % lbl)
    say(not unsupported,
        "pre-repo and superseded rows carry the pointer that supports them",
        "" if not unsupported else "%d unsupported claim(s)" % len(unsupported))
    for m in unsupported:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 9. A roadmap pointer says the thing was never built. A fix hash or a pin
    #    says it was built and is held in place. A row may not say both.
    # -----------------------------------------------------------------------
    both = []
    for i, r in lit_rows:
        lbl = row_label(r, i)
        if ptr_kind.get(i, "") != "roadmap":
            continue
        held = [f for f in ("fixedBy", "pinnedBy") if norm(r[f])]
        if held:
            both.append("%s: roadmap pointer, but %s set -- nothing was built"
                        % (lbl, " and ".join(held)))
    say(not both, "no roadmap-superseded row also claims a fix or a pin",
        "" if not both else "%d contradiction(s)" % len(both))
    for m in both:
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
    if tally["superseded"]:
        print("   (superseded is not a queue and not a closure: the work moved"
              "\n    to a roadmap phase, and the row's pointer says which.)")

    print("\n%s" % ("all checks passed" if fail_n == 0
                    else "%d check(s) FAILED" % fail_n))
    return 0 if fail_n == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
