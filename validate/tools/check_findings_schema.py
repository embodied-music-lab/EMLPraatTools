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
#     status    open | fixed-unpinned | closed | superseded | refuted.
#
# and `closed` requires BOTH fixedBy and pinnedBy non-empty. No other path to
# closed.
#
# and a fourth field, CONDITIONAL rather than universal:
#
#     pointer   "<kind>: <path>[:<line>|:<from>-<to>] <note>", where <kind> is
#               `evidence`, `roadmap` or `refutation`. Required on exactly the
#               rows where the hash cannot speak; validated wherever it
#               appears.
#
# THE THREE ROWS THE HASH CANNOT SPEAK FOR, and why each gets a pointer instead
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
#   REFUTED ROWS. A row filed as a defect that somebody then went and LOOKED
#   at, and there was no defect there, is not `open` either. `open` means a
#   repair is owed here, and nothing is owed on a row where the suspicion did
#   not survive contact with the tree. So `refuted` is the literal, and it
#   must carry a `refutation:` pointer at the thing in this tree that shows
#   the suspicion is unfounded -- the same discipline `superseded` carries,
#   for the same reason. A refuted row with a pointer to nothing is WORSE than
#   an open row: an open row admits it is unexamined, and a refuted row asserts
#   it was examined. Like `superseded` it may carry no fix and no pin: nothing
#   was built, so there is nothing to have fixed and nothing to hold in place.
#
# `superseded` is a statement about WHERE THE WORK LIVES. `refuted` is a
# statement about WHETHER THERE WAS EVER WORK. They are different claims and
# neither may be stretched over the other: `superseded` says the work moved to
# a roadmap phase, `refuted` says there was no work, and a row that is one of
# them is not the other.
#
# WHY `refutation:` IS ITS OWN KIND AND DOES NOT REUSE `evidence:`. An
# `evidence:` pointer says A REPAIR IS PRESENT in this tree; a `refutation:`
# pointer says NO REPAIR WAS EVER NEEDED. Reusing `evidence` would not merely
# blur those two sentences, it would make the blur MECHANICAL, because the
# entailment table below switches on the kind: an empty `fixedBy` beside an
# `evidence:` pointer would silently become `refuted`, and the next pre-repo
# row that loses its hash would be reclassified from a repair this project
# cannot prove into a defect this project denies -- in the flattering
# direction, without anybody typing it.
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
#     fixedBy "", roadmap pointer     ->  superseded
#     fixedBy "", refutation pointer  ->  refuted
#     fixedBy ""      ->  open                (whatever pinnedBy says)
#     fixedBy set, pinnedBy ""  ->  fixed-unpinned
#     both set        ->  closed
#
# The first two lines are what keep `superseded` and `refuted` from being
# typeable: each is entailed by a pointer that names a file this checker opens,
# not by an editorial decision. Every literal in this schema has to be earned
# by a field something else can check -- the hash against git, the validator ID
# against validate/, the pointer against the filesystem.
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
# ============================================================================
# THE ID CENSUS (added 18 August 2026)
# ============================================================================
# THE FAILURE IT EXISTS FOR. On 18 August 2026 nine findings -- D88, D97, D110,
# D123, D124, D125, D126, D134, D135 -- were discussed at length in the audit
# tree's prose and had no row in this ledger at all. Two of them had been
# CLOSED for ten days by validators that said so in their own headers while the
# prose still called them LIVE. Nothing noticed, because every check in this
# file reads the ledger and asks whether its rows are well formed. A ledger
# that is missing a row is perfectly well formed. Completeness is the one
# property a schema check cannot see, and it is the property that failed.
#
# So the census asks the other question: DOES EVERY FINDING THE PROSE NAMES
# HAVE A ROW? It walks every Markdown file under audit/, pulls out every token
# matching the finding-ID grammar, and fails on any ID with neither a row in
# the ledger nor a line in audit/FINDINGS_UNMIGRATED.tsv.
#
# THE GRAMMAR, and what it deliberately does not match. Five families, each
# anchored on a prefix this project has actually used:
#
#     D\d+ with an optional -a/-b/-c tail   D5, D110, D66-b
#     NEW-<AREA>-<n>                        NEW-G10-2
#     RULE-<TOKEN>                          RULE-28I
#     LANE-<TOKEN>-<n>                      LANE-B-1
#     SAVED-<TOKEN>                         SAVED-OVERPRINT
#
# NOT MATCHED, ON PURPOSE, EACH DECIDED BY MEASUREMENT RATHER THAN BY TASTE:
#
#   * `P\d+`. Every P<n> in the audit tree -- 7 of them, P0 through P6 -- is a
#     PRIORITY label ("P0 -- one-tailed p defect in scripting API", "P0-3",
#     "From P1: cross-platform render comparison"). Not one is a finding. A
#     family that matched them would put seven non-findings into the unmigrated
#     list on the day it was written, which is the "too loose, and now it
#     matches prose that merely looks like an ID" failure with a paper trail.
#   * A GENERIC `CAPS-CAPS` family, which is the obvious way to catch
#     SAVED-OVERPRINT without naming its prefix. Measured over audit/**.md it
#     matches 32 tokens of which 31 are English: APPEND-ONLY, PRE-REPO,
#     CONFIRMED-LIVE, TOP-LEVEL, MIXED-MODEL. One in thirty-two is not a
#     grammar, it is a coin flip, so the prefix is named instead.
#   * Anything inside a longer word or identifier. The boundaries are explicit
#     (`(?<![A-Za-z0-9_])` / `(?![A-Za-z0-9_])`) rather than `\b`, so `emlD5`
#     and `xD110y` do not match -- but a hyphen is allowed on the LEFT so that
#     the range "D102-D108", which the prose writes constantly, yields both
#     ends and not just the first.
#
# AND THE OTHER SIDE OF THE SAME COIN -- WHAT STOPS THE GRAMMAR GOING STALE.
# A grammar that names its prefixes misses the next convention somebody
# invents, and misses it SILENTLY, which is the failure this whole file is
# about. So the grammar is audited by the ledger: EVERY ID IN THE LEDGER MUST
# BE MATCHED BY THE GRAMMAR. File `WIDGET-7` as a finding and this check goes
# red the same day, saying the family is unknown. The register cannot outrun
# the census, because the register is what tests it.
#
# THE UNMIGRATED LIST, and why it is not a hole. 113 IDs from the 4 August
# drive and the audits after it have never been given rows. They are named in
# audit/FINDINGS_UNMIGRATED.tsv with a reason apiece, and three rules keep that
# file from becoming the drawer failures get swept into:
#
#     an entry that ALSO has a row  -> FAIL   (migrate, then delete the line)
#     an entry named NOWHERE in the audit tree -> FAIL   (no speculative
#                                              padding; the list shrinks as
#                                              prose retires)
#     an entry with no reason -> FAIL          (a bare ID argues nothing)
#
# The only way to quiet a new red is to file a row, or to type an ID and a
# sentence. Both are visible in a diff. Neither happens by accident.
#
# WHAT A DEFECTIVE TREE WOULD STILL HAVE TO LOOK LIKE TO PASS. It would have to
# file a finding whose ID uses a prefix outside the five families AND never put
# that ID in the ledger -- because the moment it IS in the ledger the grammar
# check demands the family. Or it would have to discuss a finding in prose
# without ever writing its ID down. Or somebody would have to add a line to the
# unmigrated list on purpose, with a reason, in a diff. Those are the three
# holes, they are stated here rather than discovered later, and the first two
# are the same hole: an ID that is never written is an ID no census can see.
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

STATUSES = ("open", "fixed-unpinned", "closed", "superseded", "refuted")
FIELDS = ("fixedBy", "pinnedBy", "status")

# The one non-hash value `fixedBy` may take, spelled exactly. Case and
# punctuation are part of it: a convention that also accepts `pre_repo` and
# `PRE-REPO` is not a convention, it is three of them, and a consumer
# switching on the literal drops the near-misses into its default branch in
# the same silence that made `status` spelling load-bearing above.
PRE_REPO = "pre-repo"

POINTER = "pointer"
POINTER_KINDS = ("evidence", "roadmap", "refutation")

# The two pointer kinds that assert NOTHING WAS BUILT, and therefore forbid
# both evidence fields. Kept as one tuple so the entailment table, the
# required-pointer check and the contradiction check cannot drift apart.
NOTHING_BUILT = {"roadmap": "superseded", "refutation": "refuted"}

# ---------------------------------------------------------------------------
# THE ID CENSUS. Constants first; the reasoning is in the header block above.
# ---------------------------------------------------------------------------
import re

# Five families, each anchored on a prefix this project has used. Kept as an
# ordered list of (name, pattern) so a failure can say WHICH family matched,
# and so adding one is a single line rather than an edit to a regex.
ID_FAMILIES = (
    ("drive",  r"D\d{1,4}(?:-[a-z]{1,2})?"),
    ("stress", r"NEW-[A-Z]+\d*-\d+"),
    ("rule",   r"RULE-[A-Z0-9]+"),
    ("lane",   r"LANE-[A-Z0-9]+-\d+"),
    ("saved",  r"SAVED-[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*"),
)

# Explicit boundaries rather than \b: no alphanumeric or underscore on either
# side, but a HYPHEN is allowed on the left so "D102-D108" yields both ends.
ID_RX = re.compile(r"(?<![A-Za-z0-9_])(?:%s)(?![A-Za-z0-9_])"
                   % "|".join(p for _n, p in ID_FAMILIES))
ID_FULL = re.compile(r"(?:%s)\Z" % "|".join(p for _n, p in ID_FAMILIES))

CENSUS_DIR = "audit"
CENSUS_EXT = (".md",)
# The unmigrated list names IDs by definition; censusing it would make it
# self-satisfying. It is READ, not scanned.
UNMIGRATED = os.path.join("audit", "FINDINGS_UNMIGRATED.tsv")


def id_atoms(ident):
    """The grammar-shaped pieces of a ledger id. Compound ids are real in this
    ledger -- `D1/D2`, `D66-b/c`, `D98/D99` -- and prose names their pieces
    singly, so a row filed as `D98/D99` must satisfy a mention of `D98`. The
    bare stem of a lettered id counts too: a row filed as `D66-b/c` covers a
    mention of `D66`, because that is what a reader writing `D66` means."""
    parts = [p.strip() for p in str(ident).split("/") if p.strip()]
    if not parts:
        return {str(ident)}
    stem = re.match(r"\A(D\d{1,4})(?:-[a-z]{1,2})?\Z", parts[0])
    out = set()
    for p in parts:
        if ID_FULL.match(p):
            out.add(p)
        elif stem and re.fullmatch(r"[a-z]{1,2}", p):
            out.add(stem.group(1) + "-" + p)
    if stem:
        out.add(stem.group(1))
    return out or {str(ident)}


def read_unmigrated(path):
    """-> (mapping id -> reason, list of complaints). Blank lines and # lines
    are ignored; everything else must be <id>TAB<reason>."""
    out, bad = {}, []
    with open(path, encoding="utf-8") as fh:
        for n, raw in enumerate(fh, 1):
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if "\t" not in line:
                bad.append("line %d: no tab -- the format is <id>TAB<reason>" % n)
                continue
            ident, reason = line.split("\t", 1)
            ident, reason = ident.strip(), reason.strip()
            if not ident:
                bad.append("line %d: no id" % n)
                continue
            if not reason:
                bad.append("line %d: %s carries no reason" % (n, ident))
                continue
            if ident in out:
                bad.append("line %d: %s listed twice" % (n, ident))
                continue
            out[ident] = reason
    return out, bad


def scan_prose(root):
    """-> (id -> set of repo-relative files naming it, number of files read)."""
    where, nfiles = {}, 0
    base = os.path.join(root, CENSUS_DIR)
    skip = os.path.join(root, UNMIGRATED)
    for dirpath, _dirs, fns in os.walk(base):
        for fn in sorted(fns):
            if not fn.endswith(CENSUS_EXT):
                continue
            full = os.path.join(dirpath, fn)
            if os.path.abspath(full) == os.path.abspath(skip):
                continue
            rel = os.path.relpath(full, root)
            try:
                with open(full, encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError:
                continue
            nfiles += 1
            for m in ID_RX.findall(text):
                where.setdefault(m, set()).add(rel)
    return where, nfiles


def natkey(s):
    return tuple((int(t), "") if t.isdigit() else (-1, t)
                 for t in re.findall(r"\d+|\D+", s))


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
        return NOTHING_BUILT.get(pointer_kind, "open")
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
    # 2. status is one of the literals. Spelling is part of the schema:
    #    a consumer switching on "fixed_unpinned" or "Closed" silently drops
    #    the row into whatever its default branch is.
    #
    #    AND IT IS SPELLED EXACTLY, whitespace included. This checker can
    #    afford to strip a stray space before comparing; a consumer reading
    #    the JSON and switching on the raw string cannot, and "refuted " is
    #    exactly as invisible to such a switch as "REFUTED" is. A vocabulary
    #    that quietly accepts near-misses is not a vocabulary, so the padding
    #    is reported here rather than absorbed -- the same argument the
    #    `pre-repo` literal carries above, applied to the field whose spelling
    #    the whole census is computed from.
    # -----------------------------------------------------------------------
    bad_lit, padded = [], []
    for i, r in ok_rows:
        raw = r["status"]
        if norm(raw) not in STATUSES:
            bad_lit.append("%s: status %r" % (row_label(r, i), raw))
        elif raw != norm(raw):
            padded.append("%s: status %r carries whitespace; the literal is %r"
                          % (row_label(r, i), raw, norm(raw)))
    say(not bad_lit, "status is one of " + " | ".join(STATUSES),
        "" if not bad_lit else "%d bad literal(s)" % len(bad_lit))
    for m in bad_lit:
        print("        " + m)
    say(not padded, "and each is spelled exactly, with no surrounding whitespace",
        "" if not padded else "%d padded literal(s)" % len(padded))
    for m in padded:
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
    #    declines to say where; a `refuted` with no pointer asserts somebody
    #    examined this and declines to say what they looked at, which is the
    #    most expensive of the three, because it is the one that says a defect
    #    is not there.
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
        if norm(r["status"]) == "refuted" and kind != "refutation":
            unsupported.append(
                "%s: status refuted with no valid `refutation:` pointer -- name "
                "the thing in this tree that shows there is no defect here" % lbl)
    say(not unsupported,
        "pre-repo, superseded and refuted rows carry the pointer that supports them",
        "" if not unsupported else "%d unsupported claim(s)" % len(unsupported))
    for m in unsupported:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 9. A roadmap pointer says the thing was never built; a refutation pointer
    #    says there was nothing to build. A fix hash or a pin says it WAS built
    #    and is held in place. A row may not say both, and the message names
    #    which two sentences are in conflict rather than reporting a bare
    #    mismatch -- section 4 already reports mismatches, and a reader looking
    #    at "refuted, but fixedBy set" needs to be told that those are two
    #    incompatible claims about the same row, not one field to retype.
    # -----------------------------------------------------------------------
    both = []
    for i, r in lit_rows:
        lbl = row_label(r, i)
        kind = ptr_kind.get(i, "")
        if kind not in NOTHING_BUILT:
            continue
        held = [f for f in ("fixedBy", "pinnedBy") if norm(r[f])]
        if held:
            both.append(
                "%s: %s pointer says %s -- nothing was built -- but %s set"
                % (lbl, kind, NOTHING_BUILT[kind], " and ".join(held)))
    say(not both,
        "no superseded or refuted row also claims a fix or a pin",
        "" if not both else "%d contradiction(s)" % len(both))
    for m in both:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 10. THE GRAMMAR IS AUDITED BY THE LEDGER. Every id in the ledger must be
    #     matched by one of the families below, so a naming convention the
    #     census cannot see is a naming convention this file refuses. This is
    #     the guard against the OTHER failure direction -- a grammar so tight
    #     it stops seeing the findings people actually file, silently.
    # -----------------------------------------------------------------------
    unknown_shape = []
    ledger_atoms = set()
    for i, r in lit_rows:
        atoms = id_atoms(row_label(r, i))
        ledger_atoms |= atoms
        for a in atoms:
            if not ID_FULL.match(a):
                unknown_shape.append(
                    "%s: the atom %r matches no ID family (%s) -- teach the "
                    "census the family, or the next one goes unseen"
                    % (row_label(r, i), a,
                       ", ".join(n for n, _p in ID_FAMILIES)))
    say(not unknown_shape,
        "every ledger id is a shape the census grammar recognises",
        "" if not unknown_shape else "%d unrecognised" % len(unknown_shape))
    for m in unknown_shape:
        print("        " + m)

    # -----------------------------------------------------------------------
    # 11. THE UNMIGRATED LIST. It exists so the census can be green and honest
    #     at once, and these three rules are what stop it being the drawer
    #     failures get swept into.
    # -----------------------------------------------------------------------
    unmig_path = os.path.join(ROOT, UNMIGRATED)
    unmig, unmig_bad = {}, []
    if not os.path.exists(unmig_path):
        say(False, "the unmigrated list exists", "not found at " + UNMIGRATED)
    else:
        unmig, unmig_bad = read_unmigrated(unmig_path)
        say(not unmig_bad, "the unmigrated list parses (<id>TAB<reason>)",
            "" if not unmig_bad else "%d bad line(s)" % len(unmig_bad))
        for m in unmig_bad:
            print("        " + m)
        also_row = sorted((set(unmig) & ledger_atoms), key=natkey)
        say(not also_row,
            "no unmigrated entry names an id that already has a row",
            "" if not also_row
            else "%d stale excuse(s): %s" % (len(also_row), ", ".join(also_row)))
        for m in also_row:
            print("        %s has a row in the ledger -- delete its line from %s"
                  % (m, UNMIGRATED))

    # -----------------------------------------------------------------------
    # 12. THE CENSUS ITSELF. Every finding id the audit tree names must have a
    #     row, or a line in the unmigrated list saying why not.
    # -----------------------------------------------------------------------
    where, nfiles = scan_prose(ROOT)

    # A census that read nothing is not a clean census -- the same rule the
    # empty ledger gets above, applied to the other input.
    say(nfiles > 0, "the census read the audit tree",
        "%d markdown file(s) under %s/" % (nfiles, CENSUS_DIR))
    say(len(where) > 0, "and found finding ids in it",
        "%d distinct id(s)" % len(where))

    orphan = sorted((i for i in where
                     if i not in ledger_atoms and i not in unmig), key=natkey)
    say(not orphan,
        "every id the audit prose names has a row or an unmigrated line",
        "" if not orphan else "%d id(s) filed nowhere" % len(orphan))
    for m in orphan:
        seen = sorted(where[m])
        print("        %s -- named in %s%s, and it is neither a row in the "
              "ledger nor a line in %s"
              % (m, ", ".join(seen[:3]),
                 " (+%d more)" % (len(seen) - 3) if len(seen) > 3 else "",
                 UNMIGRATED))

    # And the reverse: an unmigrated entry for an id nothing names any more.
    ghost = sorted((i for i in unmig if i not in where), key=natkey)
    say(not ghost,
        "no unmigrated entry names an id the audit tree has stopped mentioning",
        "" if not ghost else "%d ghost(s): %s" % (len(ghost), ", ".join(ghost)))
    for m in ghost:
        print("        %s appears nowhere under %s/ -- delete its line, the "
              "list may not be padded" % (m, CENSUS_DIR))

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
    if tally["refuted"]:
        print("   (refuted is not a queue either: somebody looked and there was"
              "\n    no defect, and the row's pointer says what they looked at.)")
    print("   %-16s %d" % ("unmigrated", len(unmig)))
    if unmig:
        print("   (unmigrated is not a status: these are ids the audit tree"
              "\n    names and this ledger does not carry. Every line is a debt.)")

    print("\n%s" % ("all checks passed" if fail_n == 0
                    else "%d check(s) FAILED" % fail_n))
    return 0 if fail_n == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
