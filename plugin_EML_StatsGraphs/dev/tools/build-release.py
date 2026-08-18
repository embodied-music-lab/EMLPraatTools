#!/usr/bin/env python3
"""Build the installable release artefact for the EML Stats & Graphs plugin.

Why this exists
---------------
Praat installs a plugin as a folder named `plugin_<Name>` under
preferencesDirectory$. THIS REPOSITORY HAS NEVER PRODUCED THAT FOLDER.
The source folder is called `plugin/`; the install name is
`plugin_EML_StatsGraphs`; and until this script existed the only line in
the tree that made the real name was a symlink in a test rig
(harness/walks/rig.sh, `ln -sfn "$REPO/plugin" "$P/plugin_EML_StatsGraphs"`).
So `plugin/README.md` told a user to copy a folder that was not in what
they downloaded, and nothing renamed, copied or zipped anything.

Two defects were parked on "the packaging step" while there was no
packaging step, which is not a deferral, it is a drop:

  * THE NAME. It is a CONVENTION, not derivable from the tree, and it is
    written in 40-odd places. See "Where the name comes from" below.
  * FINDING P1 (file modes). Thirteen of the twenty-one files in
    plugin/scripts/ were mode 0600 in the built tree of 4 August 2026,
    which makes the plugin unreadable for any account but the one that
    installed it. Git records only the executable bit, so that defect
    cannot be represented in a checkout and will never appear in a
    `git diff` -- validate/REGISTRY.md, "What a clean clone structurally
    cannot show". It is answerable ONLY on a built artefact, and this is
    the first thing in the tree that builds one. `--verify` is therefore
    not a nicety attached to the build; it is the half of this file that
    closes P1, and it runs automatically at the end of every build.

Where the name comes from
-------------------------
IT IS NOT REPEATED HERE, and that is the point. This script reads it out of
`stats/eml-record.praat` -- the file whose per-platform fallbacks decide the
`include` lines of every script the recorder emits for a user:

    emlRecordPluginRoot$ = "~/Praat/plugin_EML_StatsGraphs"          (Windows)
    emlRecordPluginRoot$ = "~/Library/Preferences/Praat Prefs"
    ... + "/plugin_EML_StatsGraphs"                                  (macOS)
    emlRecordPluginRoot$ = "~/.config/praat/plugin_EML_StatsGraphs"  (7.x)
    emlRecordPluginRoot$ = "~/.praat-dir/plugin_EML_StatsGraphs"     (6.x)

A recorded script runs only if the folder it names is the folder the user
actually has, so the artefact and the recorder cannot be allowed to
disagree. Reading the recorder means they cannot: change the recorder and
the next build changes with it.

THE NAME IS NOT DECLARED ONCE. It is TEN literals in that one file and
about forty across the repository -- Praat gives a script no way to learn
its own plugin folder, so the copies are duplicated rather than derived,
and the only defence is that they all agree (validate/v47 is that defence).
So this script does not add a forty-first copy. It reads every
`plugin_<Name>` literal in the recorder, REQUIRES THEM TO BE UNANIMOUS, and
refuses to build if they are not: a tree whose recorder cannot say what the
folder is called is a tree with nothing to package.

What ships
----------
plugin/, MINUS THE PATHS NAMED IN A COMMITTED LIST. The list is
RELEASE_EXCLUDE.tsv at the top of the repository -- a file, deliberately, and
not a set of flags in here: someone asking what a user receives should be able
to read the answer without following control flow through a build tool. Its
one entry today is `dev/`, the developer tree.

Beyond that list the only files skipped are the mechanical droppings that
dev/tools/build-manifest.py already defines as not part of the tree
(__pycache__, *.pyc, editor backups, dotfiles).

THE REPOSITORY'S OWN DIRECTORIES ARE NOT IN THE LIST. audit/, evidence/,
harness/ and validate/ sit BESIDE plugin/, and this script stages plugin/
alone, so they are outside the artefact by the shape of the tree rather than
by a rule anybody has to maintain. An entry naming one of them could never
match, and an entry that matches nothing is rejected below.

Questions this script does NOT answer are printed as notices on every build;
see NOTICES below.

What the finished zip is checked for
------------------------------------
THE ZIP, OPENED AND READ BACK -- not the staging directory. The user receives
the zip, and every step between the walk that chooses files and the archive
that leaves the machine (a copy, a chmod, a second writer appending an entry,
a hand-edited archive) is somewhere the property can be lost while every
earlier check still reads green. So the last thing a build does is open its
own output and look inside it, for three things:

  EXCLUDED PATHS. Any entry matching RELEASE_EXCLUDE.tsv, named individually
  with the row that excludes it. An empty or missing list is a FAILURE and not
  a permissive default: a gate with nothing to check would pass every artefact
  ever built, silently, and read exactly like a gate that checked.

  HISTORY NARRATION. Any line matching validate/v80's patterns, in the file
  types v80 examines and by v80's rule about which lines count (comment lines
  in .praat, every line in .md/.txt/.csv). The patterns are read out of
  dev/tools/extract-history.py -- THE SAME LIST v80 reads and pins -- rather
  than copied here, so a fourth copy cannot drift. The exceptions are
  validate/v80_history_allowlist.tsv, unchanged and unextended: v80 guards the
  repository and this guards the artefact, and the artefact is the last place
  the rule can still be enforced before a user is holding the file.

  THE SHIPPED MANIFEST'S OWN CLAIM. plugin/MANIFEST.txt travels inside the
  artefact and carries a section headed "Not shipped". Every path under that
  heading must be absent from the zip. This gate is not a restatement of the
  exclusion list -- it reads what the artefact SAYS about itself and compares
  it to what the artefact IS, so it still fires if the exclusion list and the
  manifest are edited into disagreement.

Modes
-----
0755 for directories, 0644 for files -- EXCEPT the files git records as
executable, which stay 0755. Git DOES record the executable bit (and only
that bit), so `git ls-files -s` is an authoritative, reviewable statement of
which files are meant to be runnable, and a blanket chmod would silently
demote them. THE ALLOWLIST IS INTERSECTED WITH WHAT SHIPS, so a file git
records as executable but the exclusion list drops does not appear in it; a
record naming a file the artefact does not carry is a permission statement
about nothing. Today that leaves the allowlist EMPTY -- the one 0755 file in
the tree, dev/tools/vacuity-negative-controls.py, is under dev/ -- so every
file in the artefact is 0644. The allowlist is written into RELEASE.tsv beside
the artefact so that `--verify` can be run later against an unpacked artefact
with no repository present.

Determinism
-----------
Same tree, same artefact, byte for byte: entries are walked in sorted order,
every mtime in the staged tree and every timestamp in the zip is pinned to
the 1980 epoch (the earliest a zip can express), and the zip stores entries
in path order. The build prints a sha256 over (path, mode, bytes) of every
entry, which is the digest that survives being copied about, and the sha256
of the zip itself.

What --verify asserts
---------------------
Six things, on the artefact folder it is handed -- which may be a freshly
built one, or a tree somebody has unzipped somewhere:

  1. THE FOLDER NAME, against the recorder INSIDE that folder, so an unpacked
     artefact with no repository beside it still answers the question.
  2. EVERY MODE, file by file and directory by directory, named rather than
     counted, plus every mode recorded in the zip if the zip is beside it.
  3. THE ZIP'S ROOT ENTRY. A zip with no entry for its own top level leaves
     `unzip` to create that folder under the user's umask.
  4. THE NAME EVERYWHERE ELSE IN THE ARTEFACT: no shipped file may name a
     `plugin_<Other>` folder. Check 1 covers the recorder and the folder; the
     name is also written into a sprite loader, a tutorial and the README's
     install instructions, and those do not follow a rename by themselves.
  5. EVERY PATH A SHIPPED .md OFFERS THE READER IS IN THE ARTEFACT. The whole
     install instruction is "copy this folder", so a document inside it that
     points at a path the folder does not contain points at nothing the reader
     has. See "Links out of the artefact" below.
  6. WHAT IS INSIDE THE ZIP: no excluded path, no history narration, nothing
     the shipped manifest calls not-shipped. See "What the finished zip is
     checked for" above. When there is no zip beside the artefact -- an
     unpacked tree somebody is verifying by hand -- the same three gates run
     over the FOLDER instead, and the report says which was read, because a
     gate that quietly checked nothing is the failure this section exists to
     prevent.

Links out of the artefact
-------------------------
WHAT COUNTS AS A LINK is the definition validate/v78 already uses on the
repository's front-door documents, so the two scanners agree about what a
reference is: backticked or bracketed, containing a "/" (a bare `run.sh`
named in a sentence is not a claim about a path), no whitespace (a shell
fragment like `praat x > out/y.txt` is not a file name), carrying a suffix
this tree actually uses, and not a URL.

TWO VERDICTS, and each is decidable without asking a human what a sentence
meant:

  ESCAPE. The reference, normalised lexically against the folder of the
  document it sits in, leaves the artefact -- a leading `../` from the root,
  or an absolute path. Nothing outside the folder travels with it, so this is
  a pointer at a file the reader does not have, whatever the reference meant.
  Lexical rather than by resolution: the answer must not depend on what
  happens to exist beside the artefact on the machine doing the verifying.

  DANGLING. The reference ADDRESSES the artefact -- its first segment is a
  directory that exists beside the document or at the artefact root -- and
  nothing is there. `docs/gone.md` in a document shipping beside a real
  `docs/` is a broken pointer, which is a rename nobody followed through.

AND ONE THING THIS DELIBERATELY DOES NOT CALL A LINK. The shipped documents
cite where a measurement was taken, and where the developer material lives:
`evidence/figures/...`, `harness/api_export/run.sh`,
`validate/v50_api_export.R`, `dev/tools/build-manifest.py`. Those name paths
in the SOURCE REPOSITORY, which is not shipped and cannot be, and they are
provenance rather than an invitation to open anything. The first-segment rule
separates them without a judgement call and without an exception list: there
is no `evidence/`, `harness/`, `validate/` or `dev/` in the artefact, so those
references address something else and are left alone, while `stats/`,
`graphs/`, `scripts/`, `docs/`, `data/` and `sprites/` do exist and are held
to it. An exception list would have to grow with every new citation, and a
list that gets edited on every failure is not a check.

THE COST OF THAT RULE IS REAL AND IS NOT HIDDEN HERE. `dev/` moved from the
second group to the first when the exclusion list dropped it, so
plugin/README.md's two `dev/...` references stopped being checked links and
became citations -- correct as statements about the repository, and pointing
at nothing the reader downloaded. Notice 2 on every build says so.

Usage
-----
    python3 dev/tools/build-release.py                 # build into $TMPDIR
    python3 dev/tools/build-release.py --out DIR       # build into DIR
    python3 dev/tools/build-release.py --no-zip
    python3 dev/tools/build-release.py --verify DIR/plugin_EML_StatsGraphs

$EML_RELEASE_EXCLUDE and $EML_V80_ALLOWLIST point the two rule files
elsewhere. They exist so that validate/v79 can drive this script against a
deliberately damaged rule file -- an emptied exclusion list, say -- and watch
it refuse, without editing a committed document to do it.

Exit status: 0 = built and verified (or --verify passed), 1 = verification
failed, 2 = usage/IO error, an unbuildable tree, or a rule file this script
cannot act on.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import shutil
import stat
import subprocess
import sys
import zipfile
from pathlib import Path

# Plugin root, relative to this file (dev/tools/build-release.py). Same
# derivation as build-manifest.py, deliberately -- the two tools must agree
# about what "the plugin" is.
ROOT = Path(__file__).resolve().parent.parent.parent
REPO = ROOT.parent

# THE ONE FILE THIS SCRIPT TAKES THE INSTALL NAME FROM.
NAME_SOURCE = ROOT / "stats" / "eml-record.praat"
NAME_RE = re.compile(r"plugin_[A-Za-z0-9_]+")

# Skips, character for character the ones in build-manifest.py. A file the
# manifest does not list must not appear in the artefact, or the artefact
# ships a manifest that does not describe it.
SKIP_DIRS = {"__pycache__", ".git", ".idea", ".vscode"}
SKIP_NAMES = {".DS_Store"}
SKIP_SUFFIXES = {".bak", ".pyc", ".orig", ".rej", ".swp", ".tmp"}

FILE_MODE = 0o644
EXEC_MODE = 0o755
DIR_MODE = 0o755

# The earliest timestamp a zip entry can carry. Pinned rather than "now" so
# two builds of one tree are byte-identical.
ZIP_EPOCH = (1980, 1, 1, 0, 0, 0)
EPOCH_SECONDS = 315532800  # 1980-01-01T00:00:00Z, for the staged tree

RECORD = "RELEASE.tsv"

# ---------------------------------------------------------------------------
# THE THREE RULE FILES. None of them lives in here, and that is the point:
# what a release leaves out, and what a shipped line may not say, are rulings
# about the product rather than details of packaging, so they are read from
# files a person can open. Each has an environment override, for break tests
# that must not edit a committed file.
# ---------------------------------------------------------------------------
EXCLUDE_DEFAULT = REPO / "RELEASE_EXCLUDE.tsv"        # $EML_RELEASE_EXCLUDE
ALLOW_DEFAULT = REPO / "validate" / "v80_history_allowlist.tsv"  # $EML_V80_ALLOWLIST
HISTORY_SOURCE = ROOT / "dev" / "tools" / "extract-history.py"

# WHAT THE HISTORY SCAN READS, character for character validate/v80's rule.
# In a .praat file only comment lines are examined -- a string literal holding
# "used to" is text the plugin prints, and rewriting a user-facing message to
# satisfy a lint would be the lint damaging the product. The prose files have
# no comment syntax and no code, so every line of them is a statement to a
# reader and every line is examined.
HISTORY_PROSE = {".md", ".txt", ".csv"}
HISTORY_CODE = {".praat"}
COMMENT_LINE = re.compile(r"^\s*[#;]")

# ONE CONTROL LINE, fired through the parsed pattern list on every run. The
# patterns are PARSED out of another file, so the way this gate dies is the
# parse returning a list that matches nothing -- and a scan with no live
# pattern reports a clean artefact forever. The control is a line that must
# match; if it does not, the list is not the list.
HISTORY_CONTROL = "# v1.19: the guard moved, and previously it did not"

# QUESTIONS FOR THE AUTHOR, PRINTED ON EVERY BUILD AND ANSWERED BY NOBODY
# HERE. Each is a decision about what a release contains, which is not a
# packaging detail; silently acting on either would be this script deciding
# it. They are printed rather than filed in a document because the moment to
# read them is the moment somebody builds a release.
NOTICES = (
    "MANIFEST.txt DESCRIBES THE REPOSITORY'S PLUGIN TREE, AND SHIPS INSIDE AN "
    "ARTEFACT THAT IS SMALLER THAN IT. It is generated by "
    "dev/tools/build-manifest.py over plugin/ entire, so it lists the "
    "developer files this build drops, and a user reading it finds rows for "
    "files they do not have. Whether the shipped index should describe the "
    "download or the source tree is a decision about the product; the two "
    "gates that CAN be settled mechanically are, and are: no not-shipped row "
    "is contradicted by the zip, and every path a shipped .md offers is in "
    "the artefact.",
    "plugin/README.md STILL NAMES TWO dev/ FILES the reader no longer "
    "receives -- dev/tools/build-manifest.py and dev/FIX_NOTES.md. They are "
    "true statements about this repository, and the artefact's link scan "
    "reads them as repository citations rather than broken links, because "
    "there is no dev/ in the artefact for them to address. Whether the "
    "README should say so is the author's call; nothing here rewrites a "
    "shipped document to make a check quieter.",
)


def fail(msg: str, code: int = 2) -> None:
    print("build-release: {}".format(msg), file=sys.stderr)
    sys.exit(code)


# ---------------------------------------------------------------------------
# THE NAME
# ---------------------------------------------------------------------------
def declared_name(source: Path) -> tuple[str, int]:
    """(install folder name, how many literals said so) from the recorder.

    Unanimity is required, not majority: a half-applied rename leaves a
    recorder emitting some include lines against a folder that exists and
    some against one that does not, and Praat stops at the first include it
    cannot read. That is the defect v47 was written for, found on 13 August
    2026 with every recorded script in the world unrunnable.
    """
    if not source.is_file():
        fail("no {} -- nothing in this tree declares the install name"
             .format(source))
    text = source.read_bytes().decode("utf-8-sig", errors="replace")
    hits = NAME_RE.findall(text)
    if not hits:
        fail("{} names no plugin_ folder; the install name cannot be read"
             .format(source.name))
    names = sorted(set(hits))
    if len(names) > 1:
        fail("{} names {} different plugin folders ({}). The recorder cannot "
             "say what this plugin installs as, so there is nothing to "
             "package."
             .format(source.name, len(names), ", ".join(names)))
    return names[0], len(hits)


# ---------------------------------------------------------------------------
# THE EXECUTABLE ALLOWLIST
# ---------------------------------------------------------------------------
def git_exec_set(exclusions: list[tuple[str, str]] | None = None
                 ) -> tuple[set[str], str]:
    """Plugin-relative paths git records as 100755, and how we know.

    Git records the executable bit and nothing else, so this is the only
    permission statement in the tree that a clone is guaranteed to
    reproduce. If git is unavailable the working tree's own u+x is used and
    the fallback is announced, because a build that quietly invents its own
    idea of "executable" is how a mode defect gets into an artefact in the
    first place.

    INTERSECTED WITH WHAT SHIPS when an exclusion list is given. A record
    stating that a file is executable in an artefact that does not carry that
    file is a permission statement about nothing, and verify() would then hold
    an allowlist entry that can never be reached -- which is exactly the shape
    of check that cannot fail.
    """
    def keep(rel: str) -> bool:
        return exclusions is None or excluded_by(rel, exclusions) is None

    try:
        out = subprocess.run(["git", "-C", str(REPO), "ls-files", "-s", "--",
                              str(ROOT)],
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        found = set()
        for p in ROOT.rglob("*"):
            if p.is_file() and os.access(p, os.X_OK):
                rel = p.relative_to(ROOT).as_posix()
                if keep(rel):
                    found.add(rel)
        return found, "working tree u+x (git unavailable)"
    found = set()
    for line in out.splitlines():
        if not line.startswith("100755"):
            continue
        path = line.split("\t", 1)[-1]
        rel = Path(REPO / path).resolve().relative_to(ROOT).as_posix()
        if keep(rel):
            found.add(rel)
    return found, "git ls-files -s (mode 100755), intersected with what ships"


def read_record_exec(record: Path) -> set[str] | None:
    """The exec allowlist out of a RELEASE.tsv beside an artefact, or None."""
    if not record.is_file():
        return None
    found = set()
    for line in record.read_text(encoding="utf-8").splitlines():
        if line.startswith("exec\t"):
            found.add(line.split("\t", 1)[1])
    return found


# ---------------------------------------------------------------------------
# THE EXCLUSION LIST
# ---------------------------------------------------------------------------
def env_path(var: str, default: Path) -> Path:
    raw = os.environ.get(var, "")
    return Path(raw) if raw else default


def read_exclusions(path: Path) -> list[tuple[str, str]]:
    """[(plugin-relative path, why)] out of RELEASE_EXCLUDE.tsv.

    AN ABSENT OR EMPTY LIST IS A REFUSAL TO BUILD, not "ship everything". The
    zip gate below tests the artefact against this list, so a list with no
    rows makes that gate pass every artefact ever produced, in silence and
    indistinguishably from a gate that looked. There is no reading of an empty
    file that is safe to act on: either the exclusion was deleted by accident,
    in which case building is wrong, or it was deleted on purpose, in which
    case the gate should be deleted too and this script should say so.
    """
    if not path.is_file():
        fail("no {} -- nothing in this tree says what a release leaves out, "
             "and the zip gate has nothing to test against".format(path))
    rows: list[tuple[str, str]] = []
    text = path.read_bytes().decode("utf-8-sig", errors="replace")
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2 or not parts[0].strip() or not parts[1].strip():
            fail("{}:{}: every row is <path> TAB <why>; got {!r}"
                 .format(path.name, n, line))
        rel = parts[0].strip()
        if rel.startswith("/") or ".." in rel.split("/"):
            fail("{}:{}: {!r} is not plugin-relative. The list names paths "
                 "inside plugin/, because that is the only tree this script "
                 "stages.".format(path.name, n, rel))
        if any(ch in rel for ch in "*?["):
            fail("{}:{}: {!r} is a glob. NO GLOBS -- a pattern that can match "
                 "a file nobody has written yet is not a list of what is "
                 "excluded, it is a rule about what might be, and it cannot "
                 "be audited by reading.".format(path.name, n, rel))
        rows.append((rel, parts[1].strip()))
    if not rows:
        fail("{} lists nothing. An empty exclusion list is not a permissive "
             "default: the zip gate would then pass every artefact ever built "
             "while reading exactly like a gate that checked. Name what is "
             "excluded, or remove the gate deliberately.".format(path))
    return rows


def excluded_by(rel: str, rows: list[tuple[str, str]]) -> str | None:
    """The exclusion row covering `rel`, or None. Directory rows end in "/"."""
    for pat, _why in rows:
        if pat.endswith("/"):
            if rel == pat[:-1] or rel.startswith(pat):
                return pat
        elif rel == pat:
            return pat
    return None


# ---------------------------------------------------------------------------
# THE HISTORY RULE, READ FROM THE FILES THAT ALREADY OWN IT
# ---------------------------------------------------------------------------
def read_history_patterns(source: Path) -> list[str]:
    """validate/v80's ten patterns, out of dev/tools/extract-history.py.

    NOT COPIED HERE. The list already exists twice by necessity -- once in
    Python for the capture tool and once in R for the lint -- and v80 asserts
    those two are identical, character for character. A third hand-written
    copy would be a third thing to keep in step, and the first divergence
    would be invisible: this scan would quietly stop rejecting whatever the
    copy had lost.
    """
    if not source.is_file():
        fail("no {} -- the history patterns live there and are not written "
             "here; the artefact cannot be checked against a rule this tree "
             "does not state".format(source))
    lines = source.read_text(encoding="utf-8").splitlines()
    try:
        start = next(i for i, ln in enumerate(lines)
                     if ln.startswith("PATTERNS = ["))
        end = next(i for i in range(start + 1, len(lines))
                   if lines[i].startswith("]"))
    except StopIteration:
        fail("{} carries no `PATTERNS = [...]` block; the history rule cannot "
             "be read".format(source.name))
    body = [ln.strip() for ln in lines[start + 1:end] if ln.strip().startswith('r"')]
    pats = [re.sub(r'^r"(.*)",?$', r"\1", ln) for ln in body]
    pats = [p for p in pats if p]
    if not pats:
        fail("{}'s PATTERNS block parsed to nothing".format(source.name))
    rx = re.compile("|".join(pats))
    if not rx.search(HISTORY_CONTROL):
        fail("the history patterns read out of {} do not match their own "
             "control line {!r}. A scan with no live pattern reports a clean "
             "artefact forever."
             .format(source.name, HISTORY_CONTROL))
    return pats


def read_history_allow(path: Path) -> list[tuple[str, str]]:
    """[(repository-relative path, line pattern)] from v80's allowlist.

    v80's file, unchanged and unextended. The exceptions are written once,
    with a justification, for the repository; the artefact is the same tree
    with paths one level shorter, so it is the same set of exceptions or the
    two gates disagree about the same line.
    """
    if not path.is_file():
        return []
    out: list[tuple[str, str]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) >= 2 and parts[0].strip() and parts[1]:
            out.append((parts[0].strip(), parts[1]))
    return out


# ---------------------------------------------------------------------------
# WALKING THE TREE
# ---------------------------------------------------------------------------
def shipped_files(exclusions: list[tuple[str, str]]) -> tuple[list[Path],
                                                              dict[str, int]]:
    """(files that go into the artefact, how many paths each row excluded).

    The second half is returned rather than discarded because A ROW THAT
    EXCLUDES NOTHING IS A FAILURE, on the same argument v80 makes about its
    allowlist: a row naming a path the tree no longer holds tells its reader
    the artefact is smaller than it is, and sits ready to be read as covering
    some later file it was never written about.
    """
    out = []
    hits = {pat: 0 for pat, _ in exclusions}
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
        hit = excluded_by(rel.as_posix(), exclusions)
        if hit is not None:
            hits[hit] += 1
            continue
        out.append(path)
    return out, hits


def tree_digest(base: Path, rels: list[str]) -> str:
    """sha256 over (path, mode, bytes) of every entry, path-sorted.

    Paths go in NUL-separated so "a.praat" + "b" cannot hash the same as
    "a.praatb" + "" -- the same argument build-manifest.py makes for its
    folded sprite digest. The MODE is in the digest because two artefacts
    that differ only in permissions are two different artefacts, which is
    the whole of finding P1.
    """
    h = hashlib.sha256()
    for rel in sorted(rels):
        p = base / rel
        h.update(rel.encode("utf-8"))
        h.update(b"\0")
        h.update("{:o}".format(stat.S_IMODE(p.stat().st_mode)).encode("ascii"))
        h.update(b"\0")
        h.update(p.read_bytes())
    return h.hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


# ---------------------------------------------------------------------------
# THE NAME, EVERYWHERE
# ---------------------------------------------------------------------------
# THE SCAN CARRIES NO EXCEPTION LIST. Every `plugin_<Name>` token in the
# artefact is required to be the artefact's own name, with nothing excused.
# That is possible because the tokens in this tree that are NOT folder names
# -- a Python identifier, and a superseded product name that is the needle of
# a search-and-replace -- all live under dev/, which the exclusion list drops,
# so none of them reaches an artefact. If one ever appears in a shipped file
# the build refuses and names it, which is the right way round: an exception
# is added deliberately by whoever needs it, rather than found already sitting
# in the file, matching nothing, ready to excuse the next thing that looks
# like it.


def name_disagreements(artefact: Path) -> list[str]:
    """Every `plugin_<Name>` literal in the artefact that is not its own name.

    Section 1 of verify() compares the FOLDER against the recorder, and those
    two agreeing is the whole of what makes a recorded script runnable. It is
    not the whole of what makes an artefact coherent: the name is written into
    graphs/eml-graph-procedures.praat's sprite loader, into
    scripts/eml-tutorial.praat, and into fifteen lines of README.md that tell
    a user which folder to copy. Change the recorder's ten literals and
    rebuild and all of those keep the old name, the folder is renamed, the
    build verifies, the install verifies, the menu walk passes -- and EML
    Graphs silently loads no sprites while the README names a folder that is
    not in the download.
    """
    bad: list[str] = []
    want = artefact.name.encode("ascii")
    rx = re.compile(rb"plugin_[A-Za-z0-9_]+")
    for path in sorted(artefact.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(artefact).as_posix()
        try:
            blob = path.read_bytes()
        except OSError as exc:               # unreadable is section 2's job
            bad.append("{} could not be read for the name scan ({})"
                       .format(rel, exc))
            continue
        for tok in sorted(set(rx.findall(blob))):
            if tok == want:
                continue
            name = tok.decode("ascii")
            bad.append("{} names {!r}; this artefact is {!r}"
                       .format(rel, name, artefact.name))
    return bad


# ---------------------------------------------------------------------------
# LINKS OUT OF THE ARTEFACT
# ---------------------------------------------------------------------------
# The reference grammar of validate/v78, so the artefact scanner and the
# repository scanner cannot disagree about what a reference is. Read the
# module docstring, "Links out of the artefact", for what the two verdicts are
# and why the repository-provenance citations are not among them.
LINK_SUFFIX = re.compile(r"\.(md|praat|py|R|csv|txt|sh|json|ya?ml|tsv)$")
LINK_SCHEME = re.compile(r"^(?:[a-z][a-z0-9+.-]*:|//|#)")
LINK_TOKEN = re.compile(r"`([^`\n]+)`|\]\(([^)\n]+)\)")


def md_references(text: str) -> list[str]:
    """Every path-shaped reference in one markdown document, deduplicated."""
    out: set[str] = set()
    for backticked, bracketed in LINK_TOKEN.findall(text):
        ref = (backticked or bracketed).split("#", 1)[0].strip()
        if not ref or re.search(r"\s", ref):
            continue
        if "/" not in ref:
            continue
        if LINK_SCHEME.match(ref) or not LINK_SUFFIX.search(ref):
            continue
        out.add(ref)
    return sorted(out)


def leaves_artefact(doc_rel: Path, ref: str) -> bool:
    """Does `ref`, read from a document at `doc_rel`, climb out of the root?

    LEXICAL. `(artefact / doc.parent / ref).resolve()` would answer a
    different question -- it follows symlinks and consults the filesystem
    around the artefact -- and whether a shipped document points outside the
    folder a user copied cannot depend on what else is on the verifying
    machine's disk.
    """
    if ref.startswith("/"):
        return True
    stack = [p for p in doc_rel.parent.as_posix().split("/") if p and p != "."]
    for seg in ref.split("/"):
        if seg in ("", "."):
            continue
        if seg == "..":
            if not stack:
                return True
            stack.pop()
        else:
            stack.append(seg)
    return False


def outward_links(artefact: Path) -> tuple[list[str], int, int]:
    """(problems, references scanned, documents scanned) for shipped .md.

    Section 4 asks whether the artefact agrees with itself about its own NAME.
    This asks whether it agrees with itself about its own CONTENTS. The entire
    install instruction in README.md is "copy this folder into Praat's
    preferences folder", so the folder is everything the reader ends up
    holding, and a document inside it offering `../docs/something.md` offers a
    file that was never in the download -- with no error, no missing menu and
    nothing for the build, the install walk or the mode scan to notice.
    """
    bad: list[str] = []
    n_refs = 0
    n_docs = 0
    for path in sorted(artefact.rglob("*.md")):
        if not path.is_file():
            continue
        rel = path.relative_to(artefact)
        n_docs += 1
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:               # unreadable is section 2's job
            bad.append("{} could not be read for the link scan ({})"
                       .format(rel.as_posix(), exc))
            continue
        for ref in md_references(text):
            n_refs += 1
            if leaves_artefact(rel, ref):
                bad.append("{} links {!r}, which is outside the artefact; "
                           "the reader copied {!r} and has nothing else"
                           .format(rel.as_posix(), ref, artefact.name))
                continue
            head = ref.split("/", 1)[0]
            addressed = (path.parent / head).is_dir() or (artefact / head).is_dir()
            if not addressed:
                continue                     # a repository path, not a link
            if (path.parent / ref).exists() or (artefact / ref).exists():
                continue
            bad.append("{} links {!r}, and {!r} is in the artefact but that "
                       "path is not".format(rel.as_posix(), ref, head + "/"))
    return bad, n_refs, n_docs


# ---------------------------------------------------------------------------
# WHAT IS INSIDE THE ZIP
# ---------------------------------------------------------------------------
# THE ZIP IS THE SUBJECT, not the staging directory. The staging directory is
# what this script wrote a moment ago and can only tell us that the walk and
# the copy agreed with each other; the zip is what leaves the machine, and
# between the two there is a copy, a chmod pass, an mtime pass, a second
# writer and every opportunity a human has to add one file to an archive. A
# property that is only ever asserted upstream of the artefact is a property
# the artefact does not have to have.
def population_from_zip(zp: Path, name: str) -> tuple[list[tuple[str, bool]],
                                                      dict[str, bytes]]:
    """(every entry as (artefact-relative path, is_dir), text blobs read).

    An entry that is not under the artefact's own folder keeps its full name,
    so a stray `../` or top-level entry is reported rather than silently
    reduced to something that looks in-tree.
    """
    items: list[tuple[str, bool]] = []
    blobs: dict[str, bytes] = {}
    prefix = name + "/"
    with zipfile.ZipFile(zp) as zf:
        for info in zf.infolist():
            nm = info.filename
            rel = nm[len(prefix):] if nm.startswith(prefix) else nm
            rel = rel.rstrip("/")
            if not rel:
                continue
            items.append((rel, info.is_dir()))
            if not info.is_dir() and \
                    Path(rel).suffix.lower() in (HISTORY_PROSE | HISTORY_CODE):
                blobs[rel] = zf.read(info)
    return items, blobs


def population_from_dir(artefact: Path) -> tuple[list[tuple[str, bool]],
                                                 dict[str, bytes]]:
    items: list[tuple[str, bool]] = []
    blobs: dict[str, bytes] = {}
    for p in sorted(artefact.rglob("*")):
        rel = p.relative_to(artefact).as_posix()
        items.append((rel, p.is_dir()))
        if p.is_file() and p.suffix.lower() in (HISTORY_PROSE | HISTORY_CODE):
            try:
                blobs[rel] = p.read_bytes()
            except OSError:
                pass
    return items, blobs


def excluded_inside(items: list[tuple[str, bool]],
                    exclusions: list[tuple[str, str]]) -> list[str]:
    """Every entry the exclusion list forbids, NAMED, one line each."""
    bad = []
    for rel, is_dir in sorted(items):
        hit = excluded_by(rel, exclusions)
        if hit is not None:
            bad.append("{} {} is in the artefact, and {!r} excludes it"
                       .format("dir " if is_dir else "file", rel, hit))
    return bad


def history_inside(blobs: dict[str, bytes], patterns: list[str],
                   allow: list[tuple[str, str]]
                   ) -> tuple[list[str], int, int, int]:
    """(problems, lines examined, files examined, lines excused).

    THE POPULATION IS RETURNED WITH THE VERDICT. Zero violations out of zero
    lines and zero violations out of nine thousand read identically in a build
    log, and the way a line scanner dies is by examining nothing -- a suffix
    set that stopped matching, a decode that started throwing. So the count is
    printed on every build and can be floored by a check outside this file.
    """
    rx = [re.compile(p) for p in patterns]
    rules = [(path, re.compile(pat)) for path, pat in allow]
    bad: list[str] = []
    n_lines = 0
    n_files = 0
    n_excused = 0
    for rel in sorted(blobs):
        suffix = Path(rel).suffix.lower()
        text = blobs[rel].decode("utf-8", errors="replace")
        lines = text.splitlines()
        n_files += 1
        for i, line in enumerate(lines, 1):
            if suffix in HISTORY_CODE and not COMMENT_LINE.match(line):
                continue
            n_lines += 1
            if not any(r.search(line) for r in rx):
                continue
            # v80's allowlist names paths in the REPOSITORY, where this file
            # is one level deeper. Same file, same line, same exception.
            repo_rel = "plugin/" + rel
            if any(p == repo_rel and r.search(line) for p, r in rules):
                n_excused += 1
                continue
            bad.append("{}:{}: {} -- a shipped file narrating the project's "
                       "history; the artefact is the last gate this rule has"
                       .format(rel, i, line.strip()[:90]))
    return bad, n_lines, n_files, n_excused


def manifest_contradictions(items: list[tuple[str, bool]],
                            blobs: dict[str, bytes]) -> tuple[list[str], int]:
    """(problems, how many paths the shipped manifest calls not-shipped).

    NOT A RESTATEMENT OF THE EXCLUSION LIST. This reads what the artefact SAYS
    about itself -- MANIFEST.txt travels inside it and carries a section headed
    "Not shipped" -- and compares that to what the artefact IS. The exclusion
    list and the manifest are two files that can be edited apart, and when they
    are, the artefact contradicts a document it is carrying.
    """
    blob = blobs.get("MANIFEST.txt")
    if blob is None:
        return (["the artefact carries no MANIFEST.txt, so its own statement "
                 "about what it does not ship cannot be read back"], 0)
    present = {rel for rel, is_dir in items if not is_dir}
    claimed: list[str] = []
    started = False
    for line in blob.decode("utf-8", errors="replace").splitlines():
        if line.lstrip().startswith("#"):
            if "Not shipped" in line:
                started = True
            continue
        if not started or "|" not in line:
            continue
        claimed.append(line.split("|", 1)[0].strip())
    bad = ["MANIFEST.txt says {} is not shipped, and the artefact ships it"
           .format(rel) for rel in claimed if rel in present]
    return bad, len(claimed)


def zip_gates(artefact: Path, exclusions: list[tuple[str, str]],
              patterns: list[str], allow: list[tuple[str, str]],
              rule_source: str) -> list[str]:
    """The three gates, run on the finished zip if there is one."""
    zp = artefact.parent / (artefact.name + ".zip")
    if zp.is_file():
        items, blobs = population_from_zip(zp, artefact.name)
        read = "the zip ({} entries)".format(len(items))
    else:
        items, blobs = population_from_dir(artefact)
        read = ("the artefact FOLDER ({} entries) -- no zip beside it"
                .format(len(items)))

    problems = excluded_inside(items, exclusions)
    hist, n_lines, n_files, n_excused = history_inside(blobs, patterns, allow)
    problems += hist
    contra, n_claimed = manifest_contradictions(items, blobs)
    problems += contra

    print("artefact contents read from: {}".format(read))
    print("  exclusion rows {}, history patterns {}, allowlist rows {} [{}]"
          .format(len(exclusions), len(patterns), len(allow), rule_source))
    print("  history scan: {} line(s) in {} file(s), {} excused"
          .format(n_lines, n_files, n_excused))
    print("  manifest not-shipped rows checked: {}".format(n_claimed))
    return problems


def rules_for(artefact: Path) -> tuple[list[tuple[str, str]], list[str],
                                       list[tuple[str, str]], str]:
    """The three rule inputs, from the repository or from RELEASE.tsv.

    THE REPOSITORY WINS when it is there, because it is the current statement
    of the rule and the artefact's record is a photograph of the rule as it
    stood at build time. RELEASE.tsv is the fallback for the case the mode
    allowlist already has to serve: an artefact somebody has unzipped
    somewhere with no clone beside it. Either way the source is printed, so a
    reader of the output knows which document the verdict rests on.
    """
    excl_path = env_path("EML_RELEASE_EXCLUDE", EXCLUDE_DEFAULT)
    if excl_path.is_file():
        return (read_exclusions(excl_path),
                read_history_patterns(HISTORY_SOURCE),
                read_history_allow(env_path("EML_V80_ALLOWLIST", ALLOW_DEFAULT)),
                "{} + {} + {}".format(excl_path.name, HISTORY_SOURCE.name,
                                      ALLOW_DEFAULT.name))
    rec = artefact.parent / RECORD
    if not rec.is_file():
        fail("no {} and no {} beside the artefact -- there is no statement of "
             "what a release excludes, and a gate with nothing to test against "
             "would pass anything at all"
             .format(excl_path, RECORD))
    excl: list[tuple[str, str]] = []
    pats: list[str] = []
    allow: list[tuple[str, str]] = []
    for line in rec.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if parts[0] == "exclude" and len(parts) >= 3:
            excl.append((parts[1], parts[2]))
        elif parts[0] == "history_pattern" and len(parts) >= 2:
            pats.append(parts[1])
        elif parts[0] == "history_allow" and len(parts) >= 3:
            allow.append((parts[1], parts[2]))
    if not excl:
        fail("{} records no `exclude` row: the artefact beside it was built "
             "without a statement of what a release leaves out".format(rec))
    if not pats or not re.compile("|".join(pats)).search(HISTORY_CONTROL):
        fail("{}'s recorded history patterns do not match their own control "
             "line; the history gate would examine every line and reject "
             "nothing".format(rec))
    return excl, pats, allow, "{} beside the artefact".format(RECORD)


# ---------------------------------------------------------------------------
# VERIFY -- the half that closes P1
# ---------------------------------------------------------------------------
def verify(artefact: Path, execs: set[str] | None, source: str) -> list[str]:
    """Return a list of problems. Empty means the artefact is sound.

    EVERY FILE IS ASSERTED, not sampled and not counted. A count passes on a
    tree where one file is 0600 and another has been added; naming the
    offender is what the 4 August finding needed and did not have.
    """
    problems: list[str] = []

    if not artefact.is_dir():
        return ["{} is not a directory".format(artefact)]

    # 1. THE NAME. Read out of the artefact's OWN recorder, so an unpacked
    #    artefact with no repository beside it still answers the question.
    inner = artefact / "stats" / "eml-record.praat"
    if not inner.is_file():
        problems.append("the artefact carries no stats/eml-record.praat, so "
                        "it cannot state its own install name")
    else:
        want, _ = declared_name(inner)
        if artefact.name != want:
            problems.append(
                "folder is named {!r}; its own recorder emits include lines "
                "against {!r}. Praat would load the folder and every recorded "
                "script would name a folder that does not exist."
                .format(artefact.name, want))

    # 2. THE MODES.
    if execs is None:
        problems.append("no executable allowlist available (no {} beside the "
                        "artefact and no git); any file not 0644 is reported "
                        "below".format(RECORD))
        execs = set()

    for path in sorted(artefact.rglob("*")):
        rel = path.relative_to(artefact).as_posix()
        mode = stat.S_IMODE(path.lstat().st_mode)
        if path.is_dir():
            if mode != DIR_MODE:
                problems.append("dir  {} is {:04o}, want {:04o}"
                                .format(rel, mode, DIR_MODE))
        elif path.is_file():
            want = EXEC_MODE if rel in execs else FILE_MODE
            if mode != want:
                extra = ""
                if not mode & stat.S_IROTH or not mode & stat.S_IRGRP:
                    extra = ("  <- unreadable by any account but the "
                             "installing one (finding P1)")
                problems.append("file {} is {:04o}, want {:04o}{}"
                                .format(rel, mode, want, extra))
        else:
            problems.append("{} is neither a file nor a directory".format(rel))

    # 3. THE ZIP, IF IT IS BESIDE THE ARTEFACT. What a user unzips is what
    #    lands on their disk, so modes recorded wrongly in the zip are the
    #    same defect one step earlier.
    zp = artefact.parent / (artefact.name + ".zip")
    if zp.is_file():
        root_entry = artefact.name + "/"
        seen_root = False
        with zipfile.ZipFile(zp) as zf:
            for info in zf.infolist():
                mode = info.external_attr >> 16
                nm = info.filename
                if not nm.startswith(artefact.name + "/"):
                    problems.append("zip entry {!r} is outside {}/"
                                    .format(nm, artefact.name))
                    continue
                if nm == root_entry:
                    seen_root = True
                rel = nm[len(artefact.name) + 1:].rstrip("/")
                if info.is_dir():
                    if stat.S_IMODE(mode) != DIR_MODE:
                        problems.append("zip dir  {} records {:04o}"
                                        .format(rel, stat.S_IMODE(mode)))
                else:
                    want = EXEC_MODE if rel in execs else FILE_MODE
                    if stat.S_IMODE(mode) != want:
                        problems.append("zip file {} records {:04o}, want "
                                        "{:04o}".format(rel,
                                                        stat.S_IMODE(mode),
                                                        want))
        if not seen_root:
            problems.append(
                "the zip carries no entry for {!r}, so unzip creates the "
                "plugin folder under the user's umask; on umask 077 it "
                "installs 0700 and every file in it is unreadable by any "
                "other account"
                .format(root_entry))

    # 4. THE NAME, EVERYWHERE IT IS WRITTEN, not only on the folder. Section 1
    #    settles the folder against the recorder; those two agreeing is what
    #    makes a RECORDED script runnable, and nothing more. The name is also
    #    written into a sprite loader, a tutorial, and fifteen lines of
    #    README.md telling a user which folder to copy -- so a rename that
    #    satisfies section 1 can still ship an artefact whose sprite loader
    #    points at a folder that does not exist and whose install
    #    instructions name a folder that is not in the download.
    problems += name_disagreements(artefact)

    # 5. EVERY PATH A SHIPPED DOCUMENT OFFERS IS IN THE ARTEFACT. Section 4
    #    settles the folder's NAME wherever it is written; this settles what
    #    the documents inside it point AT. The install instruction is "copy
    #    this folder", so the folder is the whole of what the reader gets, and
    #    a `../docs/...` in README.md is a reference to a file that was never
    #    in the download -- silent, and invisible to every other check here.
    links, n_refs, n_docs = outward_links(artefact)
    problems += links
    # THE SCAN'S OWN POPULATION, PRINTED. A grammar that had stopped matching
    # would report no bad links forever, and zero problems out of zero
    # references reads exactly like zero problems out of sixty-seven.
    print("shipped .md links: {} reference(s) in {} document(s)"
          .format(n_refs, n_docs))

    # 6. WHAT IS INSIDE THE ZIP. Sections 1-5 read the artefact FOLDER, which
    #    is what this script wrote; the user receives the ZIP. Every step
    #    between them -- the copy, the chmods, the archive writer, and anybody
    #    with a shell -- can put a file back that the walk left out, with all
    #    five sections above still green. So the finished archive is opened
    #    and read for the three things a release must not carry: an excluded
    #    path, a line narrating the project's history, and anything the
    #    manifest travelling inside it calls not-shipped.
    excl, pats, allow, rule_source = rules_for(artefact)
    problems += zip_gates(artefact, excl, pats, allow, rule_source)

    print("verified against: {}".format(source))
    return problems


# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------
def build(out_dir: Path, make_zip: bool) -> int:
    name, n_literals = declared_name(NAME_SOURCE)
    excl_path = env_path("EML_RELEASE_EXCLUDE", EXCLUDE_DEFAULT)
    exclusions = read_exclusions(excl_path)
    patterns = read_history_patterns(HISTORY_SOURCE)
    allow = read_history_allow(env_path("EML_V80_ALLOWLIST", ALLOW_DEFAULT))
    execs, exec_source = git_exec_set(exclusions)
    files, excl_hits = shipped_files(exclusions)

    # A ROW THAT EXCLUDED NOTHING STOPS THE BUILD. It is the same failure v80
    # reports on a stale allowlist entry, one document over: a reader of the
    # exclusion list believes the artefact is smaller than it is, and the row
    # stands ready to be read as covering a later file it was never written
    # about. Reported before anything is written, because there is nothing to
    # package until the tree and the list agree.
    dead = [pat for pat, n in excl_hits.items() if n == 0]
    if dead:
        fail("{} excludes {} that the tree does not hold: {}. An exclusion "
             "that matches nothing is not a no-op -- it misdescribes the "
             "artefact to whoever reads the list."
             .format(excl_path.name,
                     "a path" if len(dead) == 1 else "paths",
                     ", ".join(sorted(dead))))

    print("install name : {}  (read from {}, {} literals, unanimous)"
          .format(name, NAME_SOURCE.relative_to(REPO), n_literals))
    print("excluded     : {} row(s) from {}, {} file(s) dropped"
          .format(len(exclusions), excl_path.name, sum(excl_hits.values())))
    for pat, _why in exclusions:
        print("               {}  ({} file(s))".format(pat, excl_hits[pat]))
    print("executable   : {} file(s) from {}".format(len(execs), exec_source))
    for rel in sorted(execs):
        print("               {}".format(rel))

    artefact = out_dir / name
    out_dir.mkdir(parents=True, exist_ok=True)
    # RE-RUNNABLE. A build that merged into a previous one would carry files
    # deleted from the tree since, which is the stale-artefact failure v47
    # section 3 is about.
    if artefact.exists():
        shutil.rmtree(artefact)
    zip_path = out_dir / (name + ".zip")
    if zip_path.exists():
        zip_path.unlink()

    rels = []
    for src in files:
        rel = src.relative_to(ROOT).as_posix()
        rels.append(rel)
        dst = artefact / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)          # copyfile, NOT copy2: no mode, no
        os.chmod(dst, EXEC_MODE if rel in execs else FILE_MODE)  # mtime carried

    dirs = []
    for d in sorted(artefact.rglob("*")):
        if d.is_dir():
            dirs.append(d.relative_to(artefact).as_posix())
            os.chmod(d, DIR_MODE)
    os.chmod(artefact, DIR_MODE)

    # Timestamps last, deepest first, or setting a directory's mtime would be
    # undone by writing the files inside it.
    for p in sorted(artefact.rglob("*"), key=lambda q: -len(q.parts)):
        os.utime(p, (EPOCH_SECONDS, EPOCH_SECONDS))
    os.utime(artefact, (EPOCH_SECONDS, EPOCH_SECONDS))

    digest = tree_digest(artefact, rels)

    zip_sha = "-"
    if make_zip:
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED,
                             compresslevel=9) as zf:
            # THE ROOT ENTRY, FIRST AND EXPLICIT. `dirs` is relative to the
            # artefact, so the artefact's own folder never appears in it. A
            # zip with no entry for its top level makes `unzip` create that
            # folder IMPLICITLY, under the unpacking account's umask -- and on
            # `umask 077`, routine on managed and shared machines, the plugin
            # lands as a 0700 folder that no other account can traverse. Every
            # file inside it is then unreadable at once, and that is
            # invisible to a walk of the built
            # tree (whose root this script chmods) and to a walk of the zip's
            # entries (where the root does not appear). So the entry is
            # written, and verify() below requires it.
            root_info = zipfile.ZipInfo("{}/".format(name),
                                        date_time=ZIP_EPOCH)
            root_info.external_attr = (DIR_MODE << 16) | 0x10
            zf.writestr(root_info, b"")
            for rel in sorted(dirs):
                info = zipfile.ZipInfo(
                    "{}/{}/".format(name, rel), date_time=ZIP_EPOCH)
                info.external_attr = (DIR_MODE << 16) | 0x10
                zf.writestr(info, b"")
            for rel in sorted(rels):
                mode = EXEC_MODE if rel in execs else FILE_MODE
                info = zipfile.ZipInfo("{}/{}".format(name, rel),
                                       date_time=ZIP_EPOCH)
                info.external_attr = mode << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                zf.writestr(info, (artefact / rel).read_bytes())
        zip_sha = sha256_file(zip_path)

    # THE RECORD, beside the artefact and not inside it. Inside, it would be
    # a file the digest has to describe and cannot.
    rec = out_dir / RECORD
    lines = [
        "name\t{}".format(name),
        "name_source\t{}".format(NAME_SOURCE.relative_to(REPO).as_posix()),
        "name_literals\t{}".format(n_literals),
        "files\t{}".format(len(rels)),
        "dirs\t{}".format(len(dirs) + 1),
        "exec_source\t{}".format(exec_source),
        "artefact_sha256\t{}".format(digest),
        "zip\t{}".format(zip_path.name if make_zip else "-"),
        "zip_sha256\t{}".format(zip_sha),
        "setup_sha256\t{}".format(sha256_file(artefact / "setup.praat")),
    ]
    lines += ["exec\t{}".format(r) for r in sorted(execs)]
    # THE RULES THIS ARTEFACT WAS BUILT UNDER, written down beside it for the
    # same reason the exec allowlist is: --verify may be run months later on a
    # tree somebody unzipped, with no clone of this repository present, and a
    # gate that cannot read its rule is a gate that passes everything.
    lines += ["exclude\t{}\t{}".format(p, w) for p, w in exclusions]
    lines += ["history_pattern\t{}".format(p) for p in patterns]
    lines += ["history_allow\t{}\t{}".format(p, r) for p, r in allow]
    rec.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("")
    print("artefact     : {}".format(artefact))
    print("  {} files, {} directories".format(len(rels), len(dirs) + 1))
    print("  sha256(path,mode,bytes) {}".format(digest))
    if make_zip:
        print("zip          : {}  sha256 {}".format(zip_path, zip_sha))
    print("record       : {}".format(rec))

    # THE BUILD VERIFIES ITSELF. P1 is a defect of the built tree, so the
    # only moment it can be caught is here, and a build that produced an
    # unreadable artefact and exited 0 would be the 4 August failure again.
    print("")
    problems = verify(artefact, execs, exec_source)
    if problems:
        print("FAILED: {} problem(s) in the artefact just built"
              .format(len(problems)), file=sys.stderr)
        for p in problems:
            print("  {}".format(p), file=sys.stderr)
        return 1
    print("OK: every file 0644 (or 0755 where git says so), every directory "
          "0755, folder named {}; the zip carries no excluded path, no line "
          "narrating this project's history, and nothing MANIFEST.txt calls "
          "not-shipped".format(name))

    print("")
    for i, n in enumerate(NOTICES, 1):
        print("NOTICE {}. {}".format(i, n))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", default=None,
                    help="directory to build into (default: "
                         "$TMPDIR/eml-release). Outside the repository on "
                         "purpose -- a release artefact is not repository "
                         "content.")
    ap.add_argument("--no-zip", action="store_true",
                    help="build the folder only")
    ap.add_argument("--verify", default=None, metavar="DIR",
                    help="verify an already-built artefact folder and exit")
    args = ap.parse_args()

    if args.verify:
        artefact = Path(args.verify).resolve()
        execs = read_record_exec(artefact.parent / RECORD)
        source = "{} beside the artefact".format(RECORD)
        if execs is None:
            excl_path = env_path("EML_RELEASE_EXCLUDE", EXCLUDE_DEFAULT)
            execs, source = git_exec_set(
                read_exclusions(excl_path) if excl_path.is_file() else None)
            if not execs and not (REPO / ".git").exists():
                execs, source = None, "nothing"
        problems = verify(artefact, execs, source)
        if problems:
            print("FAILED: {} problem(s) in {}".format(len(problems),
                                                       artefact),
                  file=sys.stderr)
            for p in problems:
                print("  {}".format(p), file=sys.stderr)
            return 1
        print("OK: {} verifies".format(artefact))
        return 0

    out = Path(args.out) if args.out else \
        Path(os.environ.get("TMPDIR", "/tmp")) / "eml-release"
    return build(out.resolve(), not args.no_zip)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except OSError as exc:
        print("error: {}".format(exc), file=sys.stderr)
        sys.exit(2)
