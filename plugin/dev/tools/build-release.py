#!/usr/bin/env python3
"""Build the installable release artefact for the EML Praat Tools plugin.

Why this exists
---------------
Praat installs a plugin as a folder named `plugin_<Name>` under
preferencesDirectory$. THIS REPOSITORY HAS NEVER PRODUCED THAT FOLDER.
The source folder is called `plugin/`; the install name is
`plugin_EML_Praat_Tools`; and until this script existed the only line in
the tree that made the real name was a symlink in a test rig
(harness/walks/rig.sh, `ln -sfn "$REPO/plugin" "$P/plugin_EML_Praat_Tools"`).
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

    emlRecordPluginRoot$ = "~/Praat/plugin_EML_Praat_Tools"          (Windows)
    emlRecordPluginRoot$ = "~/Library/Preferences/Praat Prefs"
    ... + "/plugin_EML_Praat_Tools"                                  (macOS)
    emlRecordPluginRoot$ = "~/.config/praat/plugin_EML_Praat_Tools"  (7.x)
    emlRecordPluginRoot$ = "~/.praat-dir/plugin_EML_Praat_Tools"     (6.x)

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
THE TREE AS IT STANDS. What to leave out of a release is the author's call,
not this script's, so nothing is dropped for being "internal" -- `dev/`
ships, tests and all. The only files skipped are the mechanical droppings
that dev/tools/build-manifest.py already defines as not part of the tree
(__pycache__, *.pyc, editor backups, dotfiles), so the manifest and the
artefact list the same population. Two questions this script deliberately
does NOT answer are printed as notices on every build; see NOTICES below.

Modes
-----
0755 for directories, 0644 for files -- EXCEPT the files git records as
executable, which stay 0755. Git DOES record the executable bit (and only
that bit), so `git ls-files -s` is an authoritative, reviewable statement of
which files are meant to be runnable, and a blanket chmod would silently
demote them. Today that set is exactly one file,
dev/tools/vacuity-negative-controls.py, 0755 since 12 August 2026. The
allowlist is written into RELEASE.tsv beside the artefact so that `--verify`
can be run later against an unpacked artefact with no repository present.

Determinism
-----------
Same tree, same artefact, byte for byte: entries are walked in sorted order,
every mtime in the staged tree and every timestamp in the zip is pinned to
the 1980 epoch (the earliest a zip can express), and the zip stores entries
in path order. The build prints a sha256 over (path, mode, bytes) of every
entry, which is the digest that survives being copied about, and the sha256
of the zip itself.

Usage
-----
    python3 dev/tools/build-release.py                 # build into $TMPDIR
    python3 dev/tools/build-release.py --out DIR       # build into DIR
    python3 dev/tools/build-release.py --no-zip
    python3 dev/tools/build-release.py --verify DIR/plugin_EML_Praat_Tools

Exit status: 0 = built and verified (or --verify passed), 1 = verification
failed, 2 = usage/IO error or an unbuildable tree.
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

# QUESTIONS FOR THE AUTHOR, PRINTED ON EVERY BUILD AND ANSWERED BY NOBODY
# HERE. Each is a decision about what a release contains, which is not a
# packaging detail; silently acting on either would be this script deciding
# it. They are printed rather than filed in a document because the moment to
# read them is the moment somebody builds a release.
NOTICES = (
    "dev/ SHIPS. 300-odd of the plugin's files are dev/tests, dev/tools and "
    "four design documents. Nothing in the repository says they should not "
    "ship, so they do. If a release is meant to carry only what a voice "
    "teacher runs, that is an author ruling and this script needs one line.",
    "dev/retired/ SHIPS, AND THE MANIFEST IT SHIPS BESIDE SAYS IT DOES NOT. "
    "MANIFEST.txt lists the two retired files under a heading reading 'Not "
    "shipped, not discovered by the test runner'. Dropping files is a "
    "decision, so they are included and the contradiction is reported "
    "instead of being resolved here.",
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
def git_exec_set() -> tuple[set[str], str]:
    """Plugin-relative paths git records as 100755, and how we know.

    Git records the executable bit and nothing else, so this is the only
    permission statement in the tree that a clone is guaranteed to
    reproduce. If git is unavailable the working tree's own u+x is used and
    the fallback is announced, because a build that quietly invents its own
    idea of "executable" is how a mode defect gets into an artefact in the
    first place.
    """
    try:
        out = subprocess.run(["git", "-C", str(REPO), "ls-files", "-s", "--",
                              str(ROOT)],
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        found = set()
        for p in ROOT.rglob("*"):
            if p.is_file() and os.access(p, os.X_OK):
                found.add(p.relative_to(ROOT).as_posix())
        return found, "working tree u+x (git unavailable)"
    found = set()
    for line in out.splitlines():
        if not line.startswith("100755"):
            continue
        path = line.split("\t", 1)[-1]
        rel = Path(REPO / path).resolve().relative_to(ROOT).as_posix()
        found.add(rel)
    return found, "git ls-files -s (mode 100755)"


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
# WALKING THE TREE
# ---------------------------------------------------------------------------
def shipped_files() -> list[Path]:
    """Every file that goes into the artefact, in sorted order."""
    out = []
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
        out.append(path)
    return out


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
        with zipfile.ZipFile(zp) as zf:
            for info in zf.infolist():
                mode = info.external_attr >> 16
                nm = info.filename
                if not nm.startswith(artefact.name + "/"):
                    problems.append("zip entry {!r} is outside {}/"
                                    .format(nm, artefact.name))
                    continue
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
    print("verified against: {}".format(source))
    return problems


# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------
def build(out_dir: Path, make_zip: bool) -> int:
    name, n_literals = declared_name(NAME_SOURCE)
    execs, exec_source = git_exec_set()
    files = shipped_files()

    print("install name : {}  (read from {}, {} literals, unanimous)"
          .format(name, NAME_SOURCE.relative_to(REPO), n_literals))
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
          "0755, folder named {}".format(name))

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
            execs, source = git_exec_set()
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
