# ============================================================================
# v79_release_artefact.R -- the folder Praat installs: built here, and opened
# once somewhere else
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS
#
# Every other script in this suite reads a COMMITTED artefact. This one
# cannot, for half of its subject, because THE RELEASE ARTEFACT IS NOT IN THE
# REPOSITORY AND MUST NOT BE. It is built by plugin/dev/tools/build-release.py
# out of plugin/, and the whole reason it has to be built is that the defect
# class it exists to catch -- a file installed 0600, unreadable by any account
# but the one that unzipped it -- CANNOT BE REPRESENTED IN A CHECKOUT. Git
# records the executable bit and nothing else. A committed copy of the
# artefact would be a copy with git's modes on it, which is to say a copy with
# the evidence removed.
#
# THE CHOICE, AND THE DEFENCE
#
# So v79 does both, split on a line that is not arbitrary:
#
#   BUILT DURING THE RUN -- everything that is a property of the artefact.
#   The build costs 0.5 s (322 files, 12 directories, one zip), so there is
#   no argument from cost for reading a record instead. This half CANNOT GO
#   STALE, because there is no record: the artefact is made from the tree as
#   it stands at the moment the suite runs, and the assertions are made
#   against that. Rename the plugin, drop a library file, break a mode, and
#   this half is red on the next run of the suite with nothing to re-drive.
#
#   READ FROM A COMMITTED RECORD -- and ONLY the three facts that need a
#   window manager, a display and a human-time keyboard walk:
#   harness/release/run.sh unpacks the zip into a scratch preferences folder,
#   starts Praat on it under Xvfb, walks the New menu into the EML Stats & Graphs
#   cascade, and does the same walk again with the registration removed.
#   Two and a half minutes and an X server. That cannot be in a suite people
#   run on a laptop, so its result is committed as
#   harness/release/out/RELEASE_INSTALL.tsv and read here.
#
# HOW THIS AVOIDS BEING THE THIRD
#
# The repository has been bitten twice this week by exactly the second half:
# harness/walks/gridmode and harness/graphaxes both carried committed evidence
# that no longer reproduced, with a validator making claims out of it. A
# committed record is a photograph of a machine state, and the tree moves.
#
# Four things keep this one honest, and none of them is "remember to re-drive":
#
#   1. THE RECORD IS BOUND BY DIGEST TO THE TWO FILES ITS CLAIM RESTS ON.
#      What decides whether a menu appears is setup.praat. What decides which
#      dialog the walk arrives at is the script that registration points the
#      wanted command at. The harness digests BOTH out of the tree it actually
#      installed, and this file recomputes both digests from plugin/ and
#      requires them to match. Edit either file and v79 goes red saying the
#      GUI evidence predates it -- which is a demand for a re-drive, not a
#      quiet pass on an old green.
#
#      IT IS DELIBERATELY NOT THE WHOLE-ARTEFACT DIGEST. Binding to all 322
#      files would put a two-and-a-half-minute GUI drive behind every comment
#      fix anywhere in the plugin, and a staleness alarm that fires on
#      everything is one that gets silenced. The cost of the narrow binding is
#      stated under "what this cannot see" below.
#
#   2. THE RECORD MUST BE COMPLETE. The committed evidence at the previous
#      commit was an ABORTED RUN -- 18 of the 25 lines a finished run writes,
#      stopping before the falsifier leg, with no `completed` marker and no
#      menu_broken.png beside it. Every scalar in it was true and the run it
#      described had never reached the leg that makes the other two mean
#      anything. So the key set is asserted against the key set a finished run
#      writes, and `completed 1` is required, and the photographs are required
#      to be on disk and to differ from each other. A truncated file is a
#      RED, not a shorter list of passing checks.
#
#   3. EVERY SCALAR IN THE RECORD IS READ BY SOMETHING HERE. eml_census over
#      the file's own keys, with the read side accumulated by the accessor
#      rather than typed out, so a key that stops being read stops being
#      claimed in the same edit. A number written into an evidence file and
#      compared to nothing is decoration, and decoration beside a green tick
#      reads as measurement: the harness's mode counter and its quickstart
#      exit status were both written and neither was read, so a run under a
#      restrictive umask and a run whose headless leg died at exit 255 both
#      left the harness exiting 0.
#
#   4. THE INSTRUMENTS ARE PROVED ALIVE ON THIS MACHINE, NOT ASSUMED. The
#      builder's `--verify` prints "OK: every file 0644..." at the end of
#      every build, and on a freshly built tree that line is close to a
#      tautology: build() chmods every file and verify() then asserts the
#      chmods, with nothing in between. So this file runs `--verify` five
#      more times against deliberately damaged COPIES of what it just built --
#      one file at 0600, the folder renamed, a foreign folder name in a
#      shipped file, a shipped document pointing OUT of the folder, and a
#      shipped document pointing at an artefact path that is not there -- and
#      requires a red and the offender named each time. A verifier that has
#      gone blind fails those five and passes the real one. The last two also
#      carry a census: the link scan prints how many references it examined,
#      and a grammar that had stopped matching would report no bad links
#      forever, so the population is asserted as well as the verdict.
#
# AND ONE THING THAT NEEDS NEITHER HALF. The strongest mode check here is not
# a read of anything: the freshly built ZIP is unpacked UNDER `umask 077`, and
# the modes are measured on what lands on disk. That is the P1 situation
# exactly -- a shared or managed account with a restrictive umask -- and it is
# the only reading in this tree taken on a tree that unzip created rather than
# one the builder chmodded. It is also the only check that can see a zip
# carrying no entry for its own top-level folder, which leaves that folder at
# the user's umask: 0700, and all 322 files unreadable to every other account
# at once, with every file inside it recorded perfectly.
#
# WHAT THIS FILE CANNOT SEE
#
#   * ANY PLATFORM BUT THIS ONE. The artefact is built, zipped and unpacked on
#     Linux. macOS's Archive Utility and Windows Explorer's "Extract All" are
#     different unzippers with different mode behaviour, and neither is here.
#     The install instructions name three platforms; one of them is measured.
#   * WHETHER THE MENU IS RIGHT, only whether it is THERE and CALLED what it
#     should be. The walk is positional -- Up then Right enters whatever
#     cascade is last in the New menu -- so the identity of that cascade rests
#     on tesseract reading the label off the photograph. Nineteen commands are
#     registered; one is clicked.
#   * A FILE ADDED TO OR REMOVED FROM plugin/ SINCE THE GUI DRIVE. The digest
#     binding is setup.praat and the walked script, by the argument in 1
#     above, so the GUI half's file count is the count of the day it ran. The
#     LIVE half covers that population as it stands today -- every mode, every
#     include, the whole name scan -- so the gap is narrow: a file that
#     changes what a menu command DOES, without touching the registration or
#     the walked script, is asserted statically here and was last clicked on
#     the date in the record.
#   * WHETHER A HUMAN CAN USE IT. Reaching `Pause: Create Demo Table` is not
#     the same as the dialog being right, and nothing here presses OK.
#
#     bash harness/release/run.sh          # re-drives the committed record
#     Rscript validate/v79_release_artefact.R
#
# Input: the source tree (built live) and harness/release/out/. $EML_PLUGIN_DIR
#        and $EML_RELEASE_TSV override, for break tests.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

ROOT <- repo_path(".")
plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
TSV <- Sys.getenv("EML_RELEASE_TSV", unset = "")
if (!nzchar(TSV)) TSV <- repo_path("harness", "release", "out",
                                   "RELEASE_INSTALL.tsv")
OUTDIR  <- dirname(TSV)
BUILDER <- file.path(plug, "dev", "tools", "build-release.py")
RUNSH   <- repo_path("harness", "release", "run.sh")

py <- Sys.which("python3")
check_true("v79", "python3 is available (the builder is python)", nzchar(py))
check_true("v79", "unzip is available (the install leg unpacks the zip)",
           nzchar(Sys.which("unzip")))
check_true("v79", sprintf("the builder is in the tree (%s)",
                          basename(BUILDER)), file.exists(BUILDER))

# sha256, from coreutils and then from python. NOT tools::md5sum: the harness
# writes sha256 and comparing two different digests of one file is comparing
# nothing. A machine with neither is a FAILED check rather than a skip -- the
# staleness binding is the point of the second half of this file, and losing
# it quietly is the failure it guards.
HAVE_SHA <- nzchar(Sys.which("sha256sum")) || nzchar(py)
check_true("v79", "a sha256 tool is available (the staleness binding needs one)",
           HAVE_SHA)
sha256 <- function(path) {
    if (!file.exists(path)) return(NA_character_)
    if (nzchar(Sys.which("sha256sum"))) {
        o <- suppressWarnings(system2("sha256sum", shQuote(path),
                                      stdout = TRUE, stderr = FALSE))
        if (length(o)) return(sub(" .*$", "", o[1]))
    }
    if (nzchar(py)) {
        o <- suppressWarnings(system2(py, c("-c",
            shQuote("import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())"),
            shQuote(path)), stdout = TRUE, stderr = FALSE))
        if (length(o)) return(o[1])
    }
    NA_character_
}

# THE STALENESS BINDING DIGESTS CODE, NOT FILE BYTES. Praat's comment set is a
# line whose first non-blank character is "#", ";" or "!"; those lines are
# dropped before the digest is taken, and the remainder is joined with "\n"
# exactly as `sed | sha256sum` sees it in harness/release/run.sh, which writes
# the recorded value the same way. THE REASON, which is this file's own reason
# one level down: the binding is deliberately not the whole artefact, because
# an alarm that fires on every edit anywhere in the plugin demands a GUI
# re-drive for a typo and gets silenced. A whole-FILE digest of setup.praat is
# that same alarm, narrowed to one file: it fires when a comment in it is
# rewrapped, and a comment cannot change which menu appears or where a command
# points. On 17 August 2026 a comment-only sweep of the shipped headers turned
# both of these red with the code byte-identical, which is the shape this
# recipe removes. A trailing ";" comment after a statement is NOT stripped:
# that keeps the statement line in the digest, the conservative direction.
code_sha256 <- function(path) {
    if (!file.exists(path)) return(NA_character_)
    src <- readLines(path, warn = FALSE)
    src <- src[!grepl("^[[:space:]]*[#;!]", src)]
    tmp <- tempfile(); on.exit(unlink(tmp))
    writeLines(src, tmp)
    sha256(tmp)
}

run <- function(cmd, args) {
    out <- suppressWarnings(system2(cmd, args, stdout = TRUE, stderr = TRUE))
    st <- attr(out, "status")
    list(status = if (is.null(st)) 0L else as.integer(st), out = out)
}

# The mode of one path as a four-digit octal string, e.g. "0644".
modeof <- function(p) {
    m <- file.info(p)$mode
    if (length(m) != 1 || is.na(m)) return(NA_character_)
    sprintf("0%s", as.character(m))
}

# ---------------------------------------------------------------------------
# 1. THE ARTEFACT, BUILT NOW
# ---------------------------------------------------------------------------
SCRATCH <- file.path(tempdir(), "v79")
unlink(SCRATCH, recursive = TRUE)
dir.create(SCRATCH, recursive = TRUE, showWarnings = FALSE)
D1 <- file.path(SCRATCH, "build1")
D2 <- file.path(SCRATCH, "build2")

b1 <- if (nzchar(py) && file.exists(BUILDER)) {
    run(py, c(shQuote(BUILDER), "--out", shQuote(D1)))
} else list(status = 99L, out = "no python3 or no builder")
check_true("v79",
           sprintf("the release artefact builds and verifies (rc %d)", b1$status),
           b1$status == 0L)
if (b1$status != 0L) {
    check_true("v79", sprintf("build output: %s",
                              paste(utils::tail(b1$out, 3), collapse = " | ")),
               FALSE)
}

readrec <- function(dir) {
    p <- file.path(dir, "RELEASE.tsv")
    if (!file.exists(p)) return(NULL)
    ln <- readLines(p, warn = FALSE)
    ln <- ln[nzchar(ln)]
    list(key = sub("\t.*$", "", ln), val = sub("^[^\t]*\t?", "", ln))
}
recval <- function(r, k) {
    if (is.null(r)) return(NA_character_)
    v <- r$val[r$key == k]
    if (!length(v)) NA_character_ else v[1]
}
R1 <- readrec(D1)

NAME <- recval(R1, "name")
check_true("v79", sprintf("the build wrote a record naming the install folder (%s)",
                          NAME), !is.na(NAME) && nzchar(NAME))

# THE NAME, RE-DERIVED HERE. The builder reads it out of the recorder and
# requires the literals to be unanimous; this recomputes both from the same
# file rather than believing the record, which is the v47 argument one layer
# down -- a build that read the name wrongly would write its own wrong answer
# into RELEASE.tsv and agree with itself.
recorder <- file.path(plug, "stats", "eml-record.praat")
lits <- character(0)
if (file.exists(recorder)) {
    src <- paste(readLines(recorder, warn = FALSE), collapse = "\n")
    lits <- regmatches(src, gregexpr("plugin_[A-Za-z0-9_]+", src))[[1]]
}
check_true("v79",
           sprintf("stats/eml-record.praat names one install folder, unanimously (%d literals: %s)",
                   length(lits), paste(unique(lits), collapse = ", ")),
           length(lits) >= 2 && length(unique(lits)) == 1)
check_true("v79",
           sprintf("the built folder is the name the recorder declares (%s vs %s)",
                   NAME, paste(unique(lits), collapse = ",")),
           !is.na(NAME) && length(unique(lits)) == 1 && NAME == unique(lits))

ART <- if (!is.na(NAME)) file.path(D1, NAME) else file.path(D1, "_none_")
ZIP <- paste0(ART, ".zip")
check_true("v79", "the build produced the artefact folder", dir.exists(ART))
check_true("v79", "the build produced the zip", file.exists(ZIP))

built_files <- if (dir.exists(ART))
    list.files(ART, recursive = TRUE, all.files = TRUE, no.. = TRUE) else character(0)
built_files <- built_files[!dir.exists(file.path(ART, built_files))]
n_rec <- suppressWarnings(as.integer(recval(R1, "files")))
check_true("v79",
           sprintf("the artefact holds the file count its record states (%d walked, %s recorded)",
                   length(built_files), n_rec),
           !is.na(n_rec) && n_rec == length(built_files))

# DETERMINISM. Two builds of one tree, byte for byte. It is what licenses
# reading the artefact digest as a statement about the TREE rather than about
# the afternoon -- and the harness's record quotes that digest.
b2 <- if (b1$status == 0L) {
    run(py, c(shQuote(BUILDER), "--out", shQuote(D2)))
} else list(status = 99L, out = "")
R2 <- readrec(D2)
check_true("v79",
           sprintf("a second build reproduces the artefact digest (%s)",
                   substr(recval(R1, "artefact_sha256"), 1, 12)),
           b2$status == 0L && !is.na(recval(R1, "artefact_sha256")) &&
           identical(recval(R1, "artefact_sha256"),
                     recval(R2, "artefact_sha256")))
check_true("v79",
           sprintf("a second build reproduces the zip digest (%s)",
                   substr(recval(R1, "zip_sha256"), 1, 12)),
           b2$status == 0L && !is.na(recval(R1, "zip_sha256")) &&
           identical(recval(R1, "zip_sha256"), recval(R2, "zip_sha256")))

# ---------------------------------------------------------------------------
# 2. THE ZIP, UNPACKED UNDER umask 077 -- THE MODE LEG
# ---------------------------------------------------------------------------
# THIS IS THE ONE READING TAKEN ON A TREE NOBODY CHMODDED. Everywhere else in
# the packaging path, the modes on disk are the modes the builder set moments
# earlier, so asserting them asks whether os.chmod worked. Here `unzip`
# creates the tree, under the most hostile umask a real account carries, and
# the modes are whatever the zip's own entries plus that umask produce.
UNP <- file.path(SCRATCH, "umask077")
dir.create(UNP, recursive = TRUE, showWarnings = FALSE)
uz <- list(status = 99L)
if (file.exists(ZIP) && nzchar(Sys.which("unzip"))) {
    old <- Sys.umask("077")
    uz <- run("unzip", c("-q", shQuote(ZIP), "-d", shQuote(UNP)))
    Sys.umask(old)
}
check_true("v79", sprintf("the zip unpacks under umask 077 (rc %d)", uz$status),
           uz$status == 0L)

UROOT <- file.path(UNP, if (!is.na(NAME)) NAME else "_none_")
check_true("v79", "unpacking the zip produces the plugin folder",
           dir.exists(UROOT))

# THE ROOT'S OWN MODE. A zip with no entry for its top-level folder leaves
# unzip to create that folder under the user's umask; at 077 it lands 0700 and
# every file beneath it becomes unreachable to every other account at once,
# with each of those files recorded perfectly in the zip. It is invisible from
# both sides of a normal check -- a walk of the built tree sees a root the
# builder chmodded, and a walk of the zip's entries sees no root at all.
check_true("v79",
           sprintf("the unpacked plugin folder is 0755, not the umask's (%s)",
                   modeof(UROOT)),
           dir.exists(UROOT) && identical(modeof(UROOT), "0755"))

execs <- if (!is.null(R1)) R1$val[R1$key == "exec"] else character(0)
check_true("v79",
           sprintf("the build declares an executable allowlist (%d file(s): %s)",
                   length(execs), paste(execs, collapse = ", ")),
           length(execs) >= 1)

bad_dirs <- character(0); bad_files <- character(0); n_seen <- 0L
if (dir.exists(UROOT)) {
    all_rel <- list.files(UROOT, recursive = TRUE, all.files = TRUE,
                          no.. = TRUE, include.dirs = TRUE)
    for (rel in all_rel) {
        p <- file.path(UROOT, rel)
        m <- modeof(p)
        n_seen <- n_seen + 1L
        if (dir.exists(p)) {
            if (!identical(m, "0755")) bad_dirs <- c(bad_dirs, paste0(rel, " ", m))
        } else {
            want <- if (rel %in% execs) "0755" else "0644"
            if (!identical(m, want))
                bad_files <- c(bad_files, sprintf("%s %s want %s", rel, m, want))
        }
    }
}
check_true("v79",
           sprintf("the unpacked tree has entries to measure (%d)", n_seen),
           n_seen > 300)
check_true("v79",
           sprintf("every unpacked directory is 0755 (%s)",
                   if (length(bad_dirs)) paste(utils::head(bad_dirs, 4), collapse = "; ")
                   else "all"),
           length(bad_dirs) == 0)
check_true("v79",
           sprintf("every unpacked file is 0644, or 0755 where git says executable (%s)",
                   if (length(bad_files)) paste(utils::head(bad_files, 4), collapse = "; ")
                   else "all"),
           length(bad_files) == 0)
# THE ALLOWLIST IS ASSERTED IN THE OTHER DIRECTION TOO. "every file is 0644"
# is satisfied by an artefact that has quietly demoted the one executable it
# ships, and that failure has the same shape as the one above with the sign
# flipped: a build that stopped reading git would produce it silently.
exec_ok <- length(execs) >= 1 && dir.exists(UROOT) &&
    all(vapply(execs, function(e)
        identical(modeof(file.path(UROOT, e)), "0755"), logical(1)))
check_true("v79",
           "every file on the executable allowlist unpacks 0755, not demoted to 0644",
           exec_ok)

unp_files <- if (dir.exists(UROOT))
    list.files(UROOT, recursive = TRUE, all.files = TRUE, no.. = TRUE) else character(0)
unp_files <- unp_files[!dir.exists(file.path(UROOT, unp_files))]
check_true("v79",
           sprintf("the zip carries every file in the artefact (%d unpacked, %d built)",
                   length(unp_files), length(built_files)),
           length(unp_files) > 0 && length(unp_files) == length(built_files))

# ---------------------------------------------------------------------------
# 3. THE VERIFIER IS ALIVE -- THREE NEGATIVE CONTROLS
# ---------------------------------------------------------------------------
# The build's own verify pass runs on a tree the build chmodded seconds
# earlier, so its green is close to a statement about os.chmod. These three
# damage a COPY and require a red that NAMES the damage: a verifier that had
# stopped looking would pass all three, and so would one whose walk had
# quietly stopped finding files.
verify_of <- function(dir) {
    if (!nzchar(py) || !file.exists(BUILDER)) return(list(status = 99L, out = ""))
    run(py, c(shQuote(BUILDER), "--verify", shQuote(dir)))
}
v_ok <- verify_of(ART)
check_true("v79", sprintf("--verify passes the artefact as built (rc %d)", v_ok$status),
           v_ok$status == 0L)

ctl <- file.path(SCRATCH, "controls")
mk_copy <- function(tag) {
    d <- file.path(ctl, tag)
    unlink(d, recursive = TRUE); dir.create(d, recursive = TRUE, showWarnings = FALSE)
    tgt <- file.path(d, if (!is.na(NAME)) NAME else "x")
    if (dir.exists(ART)) file.copy(ART, d, recursive = TRUE)
    tgt
}

# (a) ONE FILE AT 0600 -- P1 itself, one file deep in the tree.
c1 <- mk_copy("mode")
victim_rel <- "stats/eml-core-utilities.praat"
if (dir.exists(c1)) Sys.chmod(file.path(c1, victim_rel), "0600")
r1 <- verify_of(c1)
check_true("v79",
           sprintf("--verify goes red on one file at 0600 (rc %d)", r1$status),
           r1$status == 1L)
check_true("v79",
           "--verify names the 0600 file rather than counting it",
           any(grepl(victim_rel, r1$out, fixed = TRUE)) &&
           any(grepl("0600", r1$out, fixed = TRUE)))

# (b) THE FOLDER RENAMED. The artefact's own recorder still emits include
#     lines against the old name, so every script it writes for a user would
#     name a folder that does not exist.
c2 <- mk_copy("name")
c2b <- file.path(dirname(c2), "plugin_EML_Not_The_Name")
if (dir.exists(c2)) file.rename(c2, c2b)
r2 <- verify_of(c2b)
check_true("v79",
           sprintf("--verify goes red on a renamed artefact folder (rc %d)", r2$status),
           r2$status == 1L)
check_true("v79", "--verify names both the folder it found and the one the recorder wants",
           any(grepl("plugin_EML_Not_The_Name", r2$out, fixed = TRUE)))

# (c) A FOREIGN FOLDER NAME LEFT IN A SHIPPED FILE. This is the half of a
#     rename that the folder check cannot see: the name is written into a
#     sprite loader, a tutorial and fifteen lines of README.md, and those do
#     not follow a rename by themselves. An artefact can verify, install, and
#     walk green while its sprite loader points at a folder nobody has.
c3 <- mk_copy("literal")
if (dir.exists(c3)) {
    f <- file.path(c3, "graphs", "eml-graph-procedures.praat")
    if (file.exists(f)) {
        Sys.chmod(f, "0644")
        cat("\n.tryPath$ = preferencesDirectory$ + \"/plugin_EML_Somewhere_Else/sprites/\"\n",
            file = f, append = TRUE)
    }
}
r3 <- verify_of(c3)
check_true("v79",
           sprintf("--verify goes red on a foreign plugin_ folder name inside a shipped file (rc %d)",
                   r3$status),
           r3$status == 1L)
check_true("v79", "--verify names the file carrying the foreign name",
           any(grepl("eml-graph-procedures.praat", r3$out, fixed = TRUE)))

# (d) A SHIPPED DOCUMENT POINTING OUT OF THE FOLDER. The install instruction
#     is "copy this folder", so the folder is the whole of what the reader
#     ends up holding, and `../anything` in a document inside it names a file
#     that was never in the download. It raises nothing, breaks no menu and
#     changes no mode: README.md carried exactly this for `docs/API_EXPORT.md`
#     while every other check in this file was green.
c4 <- mk_copy("linkout")
if (dir.exists(c4)) {
    f <- file.path(c4, "README.md")
    if (file.exists(f)) {
        Sys.chmod(f, "0644")
        cat("\n- `../docs/API_EXPORT.md` — the export how-to\n",
            file = f, append = TRUE)
    }
}
r4 <- verify_of(c4)
check_true("v79",
           sprintf("--verify goes red on a shipped document linking outside the artefact (rc %d)",
                   r4$status),
           r4$status == 1L)
check_true("v79", "--verify names the document and the link that leaves the folder",
           any(grepl("README.md", r4$out, fixed = TRUE)) &&
           any(grepl("../docs/API_EXPORT.md", r4$out, fixed = TRUE)))

# (e) THE OTHER ARM OF THE SAME SCAN: a reference that ADDRESSES the artefact
#     -- its first segment is a directory the artefact really has -- and names
#     nothing. That is a rename nobody followed through, and unlike (d) it
#     needs the scanner to look on disk rather than only at the text, so a
#     scanner that had been reduced to a `\\.\\.` grep passes (d) and fails
#     here.
c5 <- mk_copy("linkdead")
if (dir.exists(c5)) {
    f <- file.path(c5, "README.md")
    if (file.exists(f)) {
        Sys.chmod(f, "0644")
        cat("\n- `dev/tools/no-such-tool.py` — the margin recipe\n",
            file = f, append = TRUE)
    }
}
r5 <- verify_of(c5)
check_true("v79",
           sprintf("--verify goes red on a shipped document linking a path the artefact does not hold (rc %d)",
                   r5$status),
           r5$status == 1L)
check_true("v79", "--verify names the dead artefact-relative link",
           any(grepl("dev/tools/no-such-tool.py", r5$out, fixed = TRUE)))

# AND THE SCAN IS NOT LOOKING AT NOTHING. Both controls above are satisfied by
# a scanner that examines one document and finds the one line the control just
# wrote into it. The builder prints its own population on every verify, and
# the floors here are well under today's figures (67 references, 10 documents)
# so a document added or removed does not turn this red -- what turns it red
# is a grammar that has stopped matching, which is how a link scanner dies.
census <- grep("^shipped \\.md links:", v_ok$out, value = TRUE)
census_n <- function(rx) {
    if (!length(census)) return(NA_integer_)
    suppressWarnings(as.integer(sub(rx, "\\1", census[1])))
}
n_refs <- census_n("^.*: ([0-9]+) reference.*$")
n_docs <- census_n("^.*in ([0-9]+) document.*$")
check_true("v79",
           sprintf("the link scan examined a real population (%s reference(s) in %s document(s))",
                   n_refs, n_docs),
           !is.na(n_refs) && n_refs >= 40 && !is.na(n_docs) && n_docs >= 5)

# ---------------------------------------------------------------------------
# 4. EVERY `include` IN THE ARTEFACT RESOLVES -- RECOMPUTED HERE
# ---------------------------------------------------------------------------
# THE POPULATION NO MENU WALK REACHES. The install harness enters ONE of the
# nineteen registered commands, and the one it enters -- Create Demo Table --
# is the only script in scripts/ carrying no include lines at all, so it is
# precisely the item a missing library file cannot break. Drop
# scripts/eml-lib-stats.praat and the menu is present, the cascade opens, the
# walk reaches its dialog, and five of the nineteen die on their first line
# with "Cannot open file". Praat resolves `include` against the INCLUDING
# script's own folder, which is what makes this answerable without running
# anything.
inc_seen <- 0L; inc_bad <- character(0)
if (dir.exists(ART)) {
    for (rel in built_files[grepl("\\.praat$", built_files)]) {
        src <- file.path(ART, rel)
        for (ln in readLines(src, warn = FALSE)) {
            if (!grepl("^\\s*include\\s+\\S", ln)) next
            inc_seen <- inc_seen + 1L
            tgt <- trimws(sub("^\\s*include\\s+", "", ln))
            abs <- normalizePath(file.path(dirname(src), tgt), mustWork = FALSE)
            if (!file.exists(abs))
                inc_bad <- c(inc_bad, sprintf("%s -> %s", rel, tgt))
        }
    }
}
check_true("v79",
           sprintf("the artefact carries include lines to resolve (%d)", inc_seen),
           inc_seen >= 100)
check_true("v79",
           sprintf("every include in the artefact names a file that is in it (%s)",
                   if (length(inc_bad)) paste(utils::head(inc_bad, 4), collapse = "; ")
                   else "all resolve"),
           length(inc_bad) == 0)

# ---------------------------------------------------------------------------
# 5. THE COMMITTED GUI RECORD
# ---------------------------------------------------------------------------
# Everything above was measured a second ago. Everything below was measured
# once, by harness/release/run.sh, on a machine with an X server -- and is
# therefore the half that can rot. Read the header, "HOW THIS AVOIDS BEING
# THE THIRD".
KEYS_READ <- character(0)
rec_keys <- character(0); rec_vals <- character(0)
if (file.exists(TSV)) {
    ln <- readLines(TSV, warn = FALSE)
    ln <- ln[nzchar(ln)]
    rec_keys <- sub("\t.*$", "", ln)
    rec_vals <- sub("^[^\t]*\t?", "", ln)
    rec_vals[rec_keys == rec_vals] <- ""      # a key with no value at all
}
# THE READ SIDE OF THE CENSUS IS ACCUMULATED BY THE ACCESSOR, never typed out
# again: a check that stops reading a key stops claiming it in the same edit.
tsv <- function(k) {
    KEYS_READ <<- c(KEYS_READ, k)
    v <- rec_vals[rec_keys == k]
    if (!length(v)) NA_character_ else v[1]
}
tsvn <- function(k) suppressWarnings(as.integer(tsv(k)))

check_true("v79", sprintf("the install record is committed (%s)",
                          basename(TSV)), file.exists(TSV))

# THE KEY SET OF A FINISHED RUN. The record at the previous commit was an
# aborted run: 18 lines, everything in it true, and the falsifier leg -- the
# leg the harness's own header calls the one that makes the other two mean
# anything -- had never happened. A short evidence file reads as a shorter
# list of passing checks unless something asserts the length.
WANT_KEYS <- c("praat_version", "build_rc", "name", "artefact_sha256",
               "zip_sha256", "setup_under_test", "setup_sha256",
               "unpacked_folder", "unpacked_files", "record_files",
               "unpacked_modes_other_than_0644_0755", "installed_verify_rc",
               "installed_verify_line", "installed_include_lines",
               "installed_includes_dangling", "installed_includes_first_dangling",
               "installed_target_script", "installed_target_sha256",
               "installed_menu_registrations", "want_menu", "broken_damage",
               "broken_setup_lines_cut", "broken_setup_first_line",
               "quickstart_rc", "quickstart_line", "quickstart_ok",
               "installed_objects_window", "installed_dialog_title",
               "installed_windows", "installed_menu_ocr_lines",
               "installed_menu_label_seen", "broken_menu_label_row",
               "broken_objects_window",
               "broken_dialog_title", "broken_windows", "want_dialog_title",
               "menu_ordinal", "menu_present", "falsifier_ok", "completed")
missing_keys <- setdiff(WANT_KEYS, rec_keys)
check_true("v79",
           sprintf("the record carries every line a finished run writes (%d of %d; missing: %s)",
                   length(intersect(WANT_KEYS, rec_keys)), length(WANT_KEYS),
                   if (length(missing_keys)) paste(missing_keys, collapse = ", ")
                   else "none"),
           length(missing_keys) == 0)
check_true("v79", "the run reached its own end marker (completed 1)",
           identical(tsv("completed"), "1"))

pv <- tsv("praat_version")
pvn <- suppressWarnings(as.numeric(sub("^(\\d+)\\.(\\d+)\\.(\\d+).*$", "\\1.\\2\\3",
                                       regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv)))))
check_true("v79",
           sprintf("the record was driven at or above the plugin's 6.6.30 floor (%s)", pv),
           length(pvn) == 1 && !is.na(pvn) && pvn >= 6.630)
check_true("v79", sprintf("the build inside that run verified (build_rc %s)",
                          tsv("build_rc")),
           identical(tsv("build_rc"), "0"))
check_true("v79",
           sprintf("the SHIPPED setup.praat was driven, not an override (%s)",
                   tsv("setup_under_test")),
           identical(tsv("setup_under_test"), "shipped"))

# THE TWO ARTEFACT DIGESTS ARE PROVENANCE, AND ARE DELIBERATELY NOT COMPARED
# TO TODAY'S BUILD. They say which artefact that GUI drive installed, which is
# what a reader needs to reproduce it -- but requiring them to equal the
# artefact this suite just built would put a two-and-a-half-minute GUI drive
# behind every comment fix anywhere in plugin/, and an alarm that fires on
# everything gets silenced. The narrow binding is setup.praat and the walked
# script, above. So what is asserted here is that the record STATES both
# digests, in the shape a sha256 has, and that they are two different numbers
# -- one value written into both fields would be a harness bug that no other
# check in this file can see. Today's digests are printed beside them so a
# reader can tell at a glance whether the drive is of this exact tree.
hexish <- function(s) !is.na(s) && grepl("^[0-9a-f]{64}$", s)
check_true("v79",
           sprintf("the record states the artefact it installed (%s; built here today: %s)",
                   substr(tsv("artefact_sha256"), 1, 12),
                   substr(recval(R1, "artefact_sha256"), 1, 12)),
           hexish(tsv("artefact_sha256")))
check_true("v79",
           sprintf("the record states the zip it unpacked, and it is a different digest (%s; built here today: %s)",
                   substr(tsv("zip_sha256"), 1, 12),
                   substr(recval(R1, "zip_sha256"), 1, 12)),
           hexish(tsv("zip_sha256")) &&
           !identical(tsv("zip_sha256"), tsv("artefact_sha256")))

# --- THE STALENESS BINDING ------------------------------------------------
setup_now <- code_sha256(file.path(plug, "setup.praat"))
check_true("v79",
           sprintf("the registration driven in that run is the registration shipping today (%s)",
                   substr(setup_now, 1, 12)),
           !is.na(setup_now) && identical(tsv("setup_sha256"), setup_now))
# AND THE RECIPE IS NOT A NO-OP. A code digest that had quietly become a
# digest of nothing -- an empty strip, a regex that matched every line --
# would agree with the record forever. setup.praat is majority comment and
# must still hold executable lines after the strip.
setup_src <- readLines(file.path(plug, "setup.praat"), warn = FALSE)
setup_code <- setup_src[!grepl("^[[:space:]]*[#;!]", setup_src)]
check_true("v79",
           sprintf("the code digest is taken over code (%d of %d lines survive the comment strip)",
                   length(setup_code), length(setup_src)),
           length(setup_code) >= 20 && length(setup_code) < length(setup_src))

TARGET <- tsv("installed_target_script")
tgt_now <- if (!is.na(TARGET) && nzchar(TARGET))
    code_sha256(file.path(plug, TARGET)) else NA_character_
check_true("v79",
           sprintf("the script behind the dialog that walk reached is the one shipping today (%s, %s)",
                   TARGET, substr(tgt_now, 1, 12)),
           !is.na(tgt_now) && identical(tsv("installed_target_sha256"), tgt_now))

# AND THE TARGET IS THE ONE THE SHIPPED REGISTRATION POINTS AT. Without this,
# the two digests above could both match while setup.praat sends that menu
# command somewhere else entirely.
setup_src <- if (file.exists(file.path(plug, "setup.praat")))
    readLines(file.path(plug, "setup.praat"), warn = FALSE) else character(0)
want_title <- tsv("want_dialog_title")
reg_line <- grep(sprintf("^Add menu command: \"Objects\", \"New\", \"%s",
                         want_title), setup_src, value = TRUE)
reg_script <- if (length(reg_line))
    sub(".*\"([^\"]*)\"[^\"]*$", "\\1", reg_line[1]) else ""
check_true("v79",
           sprintf("the shipped setup.praat points '%s' at the script the record walked to (%s)",
                   want_title, reg_script),
           nzchar(reg_script) && identical(reg_script, TARGET))

# --- THE UNPACKED TREE, AS THAT RUN MEASURED IT ---------------------------
check_true("v79",
           sprintf("the record's install name is the name the recorder declares (%s)",
                   tsv("name")),
           !is.na(NAME) && identical(tsv("name"), NAME))
check_true("v79",
           sprintf("the zip unpacked a folder of that name (%s)",
                   tsv("unpacked_folder")),
           identical(tsv("unpacked_folder"), NAME))
check_true("v79",
           sprintf("the zip unpacked the file count its build recorded (%s of %s)",
                   tsv("unpacked_files"), tsv("record_files")),
           !is.na(tsvn("unpacked_files")) &&
           identical(tsv("unpacked_files"), tsv("record_files")))
check_true("v79",
           sprintf("no entry in the installed tree was other than 0644 or 0755 (%s)",
                   tsv("unpacked_modes_other_than_0644_0755")),
           identical(tsv("unpacked_modes_other_than_0644_0755"), "0"))
check_true("v79",
           sprintf("the builder verified the tree the zip produced (rc %s: %s)",
                   tsv("installed_verify_rc"), tsv("installed_verify_line")),
           identical(tsv("installed_verify_rc"), "0"))
check_true("v79",
           sprintf("every include in the installed tree resolved (%s lines, %s dangling: %s)",
                   tsv("installed_include_lines"), tsv("installed_includes_dangling"),
                   tsv("installed_includes_first_dangling")),
           identical(tsv("installed_includes_dangling"), "0") &&
           !is.na(tsvn("installed_include_lines")) &&
           tsvn("installed_include_lines") >= 100)

# --- THE HEADLESS LEG, AND ITS NUMBER RECOMPUTED --------------------------
check_true("v79",
           sprintf("the headless quickstart exited 0 (%s)", tsv("quickstart_rc")),
           identical(tsv("quickstart_rc"), "0"))
check_true("v79",
           sprintf("the headless quickstart printed a t-test (%s)",
                   tsv("quickstart_line")),
           identical(tsv("quickstart_ok"), "1"))

# THE SUITE'S OWN SHAPE, ONCE, IN THIS FILE: a number the plugin PRINTED --
# out of an installed artefact, by a script that lives outside the plugin --
# against a number R computes from the same two vectors. The vectors are read
# out of the harness that ran them rather than retyped here.
qs_vec <- function(nm) {
    src <- if (file.exists(RUNSH)) readLines(RUNSH, warn = FALSE) else character(0)
    ln <- grep(sprintf("^%s# = \\{", nm), src, value = TRUE)
    if (!length(ln)) return(numeric(0))
    as.numeric(strsplit(gsub("^[^{]*\\{|\\}.*$", "", ln[1]), ",")[[1]])
}
trained <- qs_vec("trained"); untrained <- qs_vec("untrained")
check_true("v79",
           sprintf("the quickstart's two vectors are readable from the harness (%d, %d)",
                   length(trained), length(untrained)),
           length(trained) >= 5 && length(untrained) >= 5)
qs_line <- tsv("quickstart_line")
qs_t  <- suppressWarnings(as.numeric(sub(".*= *(-?[0-9.]+),.*", "\\1", qs_line)))
qs_df <- suppressWarnings(as.numeric(sub("^t\\(([0-9.]+)\\).*", "\\1", qs_line)))
if (length(trained) >= 5 && length(untrained) >= 5) {
    tt <- t.test(trained, untrained)          # Welch, as the example asks for
    check("v79", "quickstart t from the installed artefact", qs_t,
          unname(tt$statistic), tol = 5e-3)
    check("v79", "quickstart df from the installed artefact", qs_df,
          unname(tt$parameter), tol = 5e-2)
    check_below("v79", "quickstart p is below the .001 the report floors at",
                0.001, unname(tt$p.value))
}

# --- THE GUI LEGS ---------------------------------------------------------
check_true("v79", sprintf("Praat came up on the installed tree (%s)",
                          tsv("installed_objects_window")),
           identical(tsv("installed_objects_window"), "1"))
# EVERY tsv() A CHECK NEEDS IS READ BEFORE THE CONDITION, never inside an
# `&&`. R short-circuits, so a key read only on the right of a failing `&&`
# is never read at all -- and the census below would then report it orphaned
# for no reason but the order of two comparisons.
dlg_title <- tsv("installed_dialog_title"); menu_present <- tsv("menu_present")
check_true("v79",
           sprintf("the walk to command %s reached its dialog (%s)",
                   tsv("menu_ordinal"), dlg_title),
           identical(dlg_title, want_title) && identical(menu_present, "1"))
check_true("v79",
           sprintf("the installed session carried the dialog as a window (%s)",
                   tsv("installed_windows")),
           grepl(paste0("Pause: ", want_title), tsv("installed_windows"), fixed = TRUE))

# THE FALSIFIER, AND ITS TWO PRECONDITIONS. A red here that meant "Praat did
# not start" would be the falsifier passing for the wrong reason, so Praat is
# required to be UP on the broken tree; and the damage is required to be the
# SHARPER of the two the harness offers -- `unregister` leaves Praat healthy
# with no error dialog and asks whether the walk can tell an EML-less New menu
# from an EML one, where `syntax` only shows that a modal blocks a keyboard.
check_true("v79", sprintf("Praat came up on the broken tree too (%s)",
                          tsv("broken_objects_window")),
           identical(tsv("broken_objects_window"), "1"))
check_true("v79",
           sprintf("the falsifier was the registration-removing one (%s, %s lines cut)",
                   tsv("broken_damage"), tsv("broken_setup_lines_cut")),
           identical(tsv("broken_damage"), "unregister") &&
           !is.na(tsvn("broken_setup_lines_cut")) &&
           tsvn("broken_setup_lines_cut") > 0)
check_true("v79",
           sprintf("the broken tree's setup.praat still parses (first line: %s)",
                   substr(tsv("broken_setup_first_line"), 1, 40)),
           nzchar(tsv("broken_setup_first_line")))
bad_title <- tsv("broken_dialog_title"); fals <- tsv("falsifier_ok")
check_true("v79",
           sprintf("the same walk reached NO dialog with the registration removed (%s)",
                   ifelse(nzchar(bad_title), bad_title, "<none>")),
           identical(fals, "1") && !identical(bad_title, want_title))
check_true("v79",
           sprintf("the broken session carried no EML dialog window (%s)",
                   tsv("broken_windows")),
           !grepl("Pause: ", tsv("broken_windows"), fixed = TRUE))

# --- THE MENU'S IDENTITY --------------------------------------------------
# The walk is POSITIONAL: Up then Right enters whatever cascade is last in the
# New menu, whatever it is called. Register the plugin's nineteen commands
# under "NOT THE EML MENU" and the walk still arrives at Create Demo Table.
# The label exists in one machine-readable place, the pixels, so the
# photograph is read -- here, again, rather than on the harness's word.
WANT_MENU <- tsv("want_menu")
n_reg <- tsvn("installed_menu_registrations")
check_true("v79",
           sprintf("the shipped setup.praat registers under '%s' (%s registrations in the installed tree)",
                   WANT_MENU, n_reg),
           !is.na(WANT_MENU) && nzchar(WANT_MENU) &&
           any(grepl(sprintf("^Add menu command: .*\"%s\"", WANT_MENU), setup_src)) &&
           !is.na(n_reg) && n_reg >= 1)
check_true("v79",
           sprintf("the harness read that label off the HIGHLIGHTED row (%s lines of OCR)",
                   tsv("installed_menu_ocr_lines")),
           identical(tsv("installed_menu_label_seen"), "1"))
# THE SAME READING ON THE FALSIFIER'S PHOTOGRAPH MUST COME OUT THE OTHER WAY.
# With the registrations cut, Up-then-Right still enters the last cascade in
# the New menu -- one of Praat's own -- so the highlighted row is a real menu
# row with a real label, and it is not this one. A reading that said yes to
# both screens would not be reading the row.
check_true("v79",
           sprintf("and NOT off the highlighted row with the registration cut ('%s' on both screens would mean the reading is not reading the row)",
                   WANT_MENU),
           identical(tsv("broken_menu_label_row"), "0"))

# RE-READ HERE. The reading is two passes: the page whole, and every band
# painted in the GTK selection colour cropped out and read on its own --
# tesseract's layout analysis DROPS the selected row, which is the only row
# whose identity this leg is claiming. validate/tools/menu_label_ocr.py is
# the one implementation of that, shared with the harness so the drive and
# this file cannot read the photograph two different ways.
#
# Re-run here when the machine has tesseract and PIL, in which case the
# assertion is on the committed PNG and nothing between it and this line is
# trusted; otherwise on the two readings the harness committed beside it,
# which is one step weaker and says so.
norm <- function(s) toupper(gsub("[^A-Za-z0-9]", "", paste(s, collapse = " ")))
MARKER <- "---- highlighted rows, cropped and read separately ----"
PNG <- file.path(OUTDIR, "menu_installed.png")
OCRPY <- repo_path("validate", "tools", "menu_label_ocr.py")
ocr_mode <- "MENU_OCR.txt (the reading committed by the drive)"
ocr_txt <- ""
if (nzchar(Sys.which("python3")) && file.exists(PNG) && file.exists(OCRPY)) {
    o <- run("python3", c(shQuote(OCRPY), shQuote(PNG)))
    if (o$status == 0L) { ocr_txt <- paste(o$out, collapse = "\n")
                          ocr_mode <- "re-read here off the committed PNG" }
}
if (!nzchar(ocr_txt) && file.exists(file.path(OUTDIR, "MENU_OCR.txt")))
    ocr_txt <- paste(readLines(file.path(OUTDIR, "MENU_OCR.txt"), warn = FALSE),
                     collapse = "\n")
# THE HIGHLIGHTED-ROW HALF ONLY. The whole-page half is the transcript a
# human reads; it cannot distinguish the cascade the walk ENTERED from any
# other row on the screen, and the row it entered is the claim.
row_txt <- if (grepl(MARKER, ocr_txt, fixed = TRUE))
    sub(paste0("^.*", MARKER), "", ocr_txt) else ""
wn <- norm(WANT_MENU)
# The one-character tolerance is measured, not defensive: a trailing glyph
# can be lost where the submenu arrow abuts the label. It is not what decides
# the check -- "NOT THE EML MENU" normalises to NOTTHEEMLMENU, which contains
# no prefix of the wanted label.
seen <- nzchar(wn) &&
    grepl(substr(wn, 1, nchar(wn) - 1L), norm(row_txt), fixed = TRUE)
check_true("v79",
           sprintf("'%s' is legible on the highlighted row of the submenu photograph [%s]",
                   WANT_MENU, ocr_mode),
           seen)

# --- THE PHOTOGRAPHS EXIST, AND ARE TWO DIFFERENT PHOTOGRAPHS -------------
for (f in c("menu_installed.png", "menu_broken.png", "dialog_installed.png",
            "QUICKSTART.txt", "MENU_OCR.txt")) {
    p <- file.path(OUTDIR, f)
    check_true("v79", sprintf("out/%s is on disk and not empty (%s bytes)", f,
                              if (file.exists(p)) file.info(p)$size else 0),
               file.exists(p) && file.info(p)$size > 0)
}
# menu_broken.png is the file that was ABSENT at the previous commit, and its
# absence was the tell that the run had stopped before the falsifier leg. Its
# presence is necessary and not sufficient: two identical photographs would
# mean one screen was photographed twice.
d1 <- sha256(file.path(OUTDIR, "menu_installed.png"))
d2 <- sha256(file.path(OUTDIR, "menu_broken.png"))
check_true("v79",
           "the installed and broken submenu photographs are different screens",
           !is.na(d1) && !is.na(d2) && d1 != d2)

# ---------------------------------------------------------------------------
# 6. EVERY SCALAR IN THE RECORD IS READ BY SOMETHING ABOVE
# ---------------------------------------------------------------------------
# The failure this guards is the one that was there: `say` writes a number,
# nothing compares it, and the number sits in a committed evidence file next
# to a green tick, where it reads as a measurement. Both halves of the census
# matter -- a key nothing reads is decoration, and a key this file reads that
# the harness has stopped writing is a check passing on NA.
eml_census("v79", "RELEASE_INSTALL.tsv row", rec_keys, KEYS_READ)

if (!exists("EML_SUITE")) {
    eml_report("v79 the release artefact: built here, installed once elsewhere")
    eml_exit()
}
