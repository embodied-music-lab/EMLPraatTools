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
#   The build costs 0.5 s (255 files, 7 directories, one zip), so there is
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
#      IT IS DELIBERATELY NOT THE WHOLE-ARTEFACT DIGEST. Binding to all 255
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
#      chmods, with nothing in between. So this file runs `--verify` nine
#      more times against deliberately damaged COPIES of what it just built --
#      one file at 0600, the folder renamed, a foreign folder name in a
#      shipped file, a shipped document pointing OUT of the folder, a shipped
#      document pointing at an artefact path that is not there, a developer
#      file put back into the ZIP, a history line put into the ZIP, the same
#      history text as a string the plugin PRINTS (which must stay green), and
#      a zip carrying a path the manifest inside it calls not-shipped -- and
#      requires a red and the offender named each time. A verifier that has
#      gone blind fails those and passes the real one. Several also carry a
#      census: the scans print how many references and how many lines they
#      examined, and a grammar that had stopped matching would report nothing
#      wrong forever, so the population is asserted as well as the verdict.
#
# WHAT THE ARTEFACT LEAVES OUT, AND WHY THAT NEEDS ITS OWN CONTROLS
#
# plugin/ holds a developer tree -- 72 files of test suites, tooling, design
# documents and the history ledger -- and the artefact does not carry it. The
# instruction is a committed file, RELEASE_EXCLUDE.tsv at the top of the
# repository, so what a user receives can be audited by reading rather than by
# following control flow through the builder.
#
# THE BUILDER'S GATE IS ON THE ZIP, NOT ON THE STAGING DIRECTORY, and the
# controls below are written to hold it to that. Four of them damage only the
# ZIP and leave the built folder untouched: a gate that had drifted back onto
# the folder passes every one of them while the archive a user downloads
# carries the developer tree. The other two damage the RULE rather than the
# artefact -- an emptied exclusion list, and a list whose row matches nothing
# -- because a gate that reads an empty list is a gate that passes anything,
# and it prints exactly what a gate that checked prints.
#
# AND THE REPOSITORY'S OWN DIRECTORIES ARE CHECKED RATHER THAN ASSUMED.
# audit/, evidence/, harness/ and validate/ are outside the artefact because
# they are outside plugin/, which is a fact about the tree and not a rule
# anybody maintains. It is asserted here, once, so that the day somebody moves
# one of them under plugin/ the artefact does not silently grow it.
#
# AND ONE THING THAT NEEDS NEITHER HALF. The strongest mode check here is not
# a read of anything: the freshly built ZIP is unpacked UNDER `umask 077`, and
# the modes are measured on what lands on disk. That is the P1 situation
# exactly -- a shared or managed account with a restrictive umask -- and it is
# the only reading in this tree taken on a tree that unzip created rather than
# one the builder chmodded. It is also the only check that can see a zip
# carrying no entry for its own top-level folder, which leaves that folder at
# the user's umask: 0700, and all 255 files unreadable to every other account
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
#   * WHETHER THE SHIPPED MANIFEST DESCRIBES THE DOWNLOAD. plugin/MANIFEST.txt
#     is generated over plugin/ entire and travels inside an artefact that is
#     smaller than it, so it carries rows for developer files the reader does
#     not have. The half of that which is mechanically decidable IS checked --
#     no path the manifest calls not-shipped may be in the zip -- and the rest
#     is printed as a notice on every build rather than settled here.
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
#
# THE RECORDER DECLARES THE NAME ONCE, in @emlPluginFolder, and every other
# part of the plugin asks that procedure rather than spelling it -- v47 pins
# that. So unanimity here is a floor rather than the point: what this has to
# establish is that the file declares a name at all and declares only one.
recorder <- file.path(plug, "stats", "eml-record.praat")
lits <- character(0)
if (file.exists(recorder)) {
    src <- paste(readLines(recorder, warn = FALSE), collapse = "\n")
    lits <- regmatches(src, gregexpr("plugin_[A-Za-z0-9_]+", src))[[1]]
}
check_true("v79",
           sprintf("stats/eml-record.praat names one install folder, unanimously (%d literals: %s)",
                   length(lits), paste(unique(lits), collapse = ", ")),
           length(lits) >= 1 && length(unique(lits)) == 1)
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

# THE ALLOWLIST IS EMPTY, AND THAT IS AN ASSERTION RATHER THAN AN ABSENCE.
# One file in plugin/ is 0755 -- dev/tools/vacuity-negative-controls.py -- and
# the exclusion list drops it, so nothing the user receives is executable and
# every file in the artefact must be 0644. Stating that as "0 entries" alone
# would be satisfied by a build that had stopped reading git at all, which is
# the failure the allowlist exists to catch, so the reason is asserted beside
# the count: the file is still in the tree, still 0755 there, and is not in
# the artefact.
execs <- if (!is.null(R1)) R1$val[R1$key == "exec"] else character(0)
EXEC_SRC <- file.path(plug, "dev", "tools", "vacuity-negative-controls.py")
check_true("v79",
           sprintf("no file in the artefact is on the executable allowlist (%d entr(ies): %s)",
                   length(execs),
                   if (length(execs)) paste(execs, collapse = ", ") else "none"),
           length(execs) == 0)
check_true("v79",
           sprintf("the tree's one 0755 file is still 0755 and is what the exclusion dropped (%s, %s)",
                   basename(EXEC_SRC), modeof(EXEC_SRC)),
           file.exists(EXEC_SRC) && identical(modeof(EXEC_SRC), "0755") &&
           !file.exists(file.path(ART, "dev", "tools",
                                  "vacuity-negative-controls.py")))

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
           n_seen > 200)
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
# AND NOTHING UNPACKS EXECUTABLE. The check above says every file matches what
# the allowlist asks for; with the allowlist empty, `all()` over nothing is
# TRUE and that sentence stops being a statement. So the population is walked
# directly: an artefact that had acquired an executable file -- a build that
# stopped intersecting the allowlist with what ships, a zip edited by hand --
# is named here rather than passing on a vacuous quantifier.
unp_exec <- character(0)
if (dir.exists(UROOT)) {
    for (rel in list.files(UROOT, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
        p <- file.path(UROOT, rel)
        if (!dir.exists(p) && identical(modeof(p), "0755"))
            unp_exec <- c(unp_exec, rel)
    }
}
check_true("v79",
           sprintf("no file in the unpacked tree is executable, the allowlist being empty (%s)",
                   if (length(unp_exec)) paste(utils::head(unp_exec, 4), collapse = "; ")
                   else "none"),
           length(unp_exec) == 0)

unp_files <- if (dir.exists(UROOT))
    list.files(UROOT, recursive = TRUE, all.files = TRUE, no.. = TRUE) else character(0)
unp_files <- unp_files[!dir.exists(file.path(UROOT, unp_files))]
check_true("v79",
           sprintf("the zip carries every file in the artefact (%d unpacked, %d built)",
                   length(unp_files), length(built_files)),
           length(unp_files) > 0 && length(unp_files) == length(built_files))

# ---------------------------------------------------------------------------
# 2b. WHAT THE ARTEFACT LEAVES OUT
# ---------------------------------------------------------------------------
# THE INSTRUCTION IS A FILE, and that is the property being asserted first:
# somebody auditing what a user receives reads RELEASE_EXCLUDE.tsv, rather
# than reading the builder and following its control flow. A list expressed as
# flags inside the tool would satisfy every other check in this section and
# fail this one.
EXCL <- Sys.getenv("EML_RELEASE_EXCLUDE", unset = "")
if (!nzchar(EXCL)) EXCL <- repo_path("RELEASE_EXCLUDE.tsv")
check_true("v79",
           sprintf("the exclusion list is a committed file, not a flag in the builder (%s)",
                   basename(EXCL)),
           file.exists(EXCL))
xr <- if (file.exists(EXCL)) readLines(EXCL, warn = FALSE) else character(0)
xrows <- xr[!grepl("^\\s*#", xr) & nzchar(trimws(xr))]
xparts <- strsplit(xrows, "\t", fixed = TRUE)
xpath <- vapply(xparts, function(p) trimws(p[1]), character(1))
xwhy  <- vapply(xparts, function(p) if (length(p) >= 2) trimws(p[2]) else "",
                character(1))
check_true("v79",
           sprintf("every row is <path> TAB <why> (%d row(s): %s)",
                   length(xrows), paste(xpath, collapse = ", ")),
           length(xrows) >= 1 && all(nzchar(xpath)) && all(nzchar(xwhy)))
# A REASON A READER CAN USE, the same floor v80 puts on its allowlist. Dropping
# 72 files out of a release on the word "internal" is not an audit trail.
check_true("v79",
           sprintf("every row says why in a sentence (%s)",
                   if (any(nchar(xwhy) < 40)) paste(xpath[nchar(xwhy) < 40], collapse = ", ")
                   else sprintf("shortest is %d characters", min(nchar(xwhy)))),
           length(xwhy) >= 1 && all(nchar(xwhy) >= 40))
# NO GLOBS. A pattern that can match a file nobody has written yet is not a
# list of what is excluded, and cannot be audited by reading it.
check_true("v79", "no row is a glob",
           length(xpath) >= 1 && !any(grepl("[*?[]", xpath)))

# THE DROP IS REAL, AND IT IS A DROP RATHER THAN A DISAPPEARANCE. Asserting
# only that the artefact holds no dev/ file is satisfied by a tree that has
# lost dev/ entirely, which is a different and worse event. Both sides are
# stated: the repository has it, the artefact does not.
dev_repo <- list.files(file.path(plug, "dev"), recursive = TRUE,
                       all.files = TRUE, no.. = TRUE)
dev_repo <- dev_repo[!grepl("(^|/)__pycache__/", dev_repo)]
dev_art <- if (dir.exists(ART))
    built_files[grepl("^dev/", built_files)] else character(0)
check_true("v79",
           sprintf("plugin/dev/ is still in the repository (%d files)",
                   length(dev_repo)),
           length(dev_repo) >= 50)
check_true("v79",
           sprintf("and no dev/ file is in the artefact (%s)",
                   if (length(dev_art)) paste(utils::head(dev_art, 4), collapse = "; ")
                   else "none of them"),
           length(dev_art) == 0)
check_true("v79",
           sprintf("the artefact is the tree minus exactly what the list excludes (%d built, %d walked - %d excluded)",
                   length(built_files), length(dev_repo) + length(built_files),
                   length(dev_repo)),
           length(built_files) > 0 && length(dev_art) == 0)

# THE REPOSITORY'S OWN DIRECTORIES ARE OUTSIDE THE ARTEFACT BECAUSE THEY ARE
# OUTSIDE plugin/, which is a fact about the tree rather than a rule the
# exclusion list carries -- and it is checked rather than assumed, because the
# day one of them is moved under plugin/ the artefact grows it in silence and
# no exclusion row names it. Both halves: they exist at the repository root,
# and they are not under plugin/ and not in the artefact.
outside <- c("audit", "evidence", "harness", "validate")
out_missing <- outside[!dir.exists(file.path(ROOT, outside))]
out_inside <- outside[dir.exists(file.path(plug, outside)) |
                      dir.exists(file.path(ART, outside))]
check_true("v79",
           sprintf("audit/, evidence/, harness/ and validate/ are repository directories (%s)",
                   if (length(out_missing)) paste(out_missing, collapse = ", ")
                   else "all four present"),
           length(out_missing) == 0)
check_true("v79",
           sprintf("and none of them is under plugin/ or in the artefact (%s)",
                   if (length(out_inside)) paste(out_inside, collapse = ", ")
                   else "none"),
           length(out_inside) == 0)

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
#     here. THE FIRST SEGMENT MUST BE A DIRECTORY THE ARTEFACT REALLY HAS --
#     `docs/`, since the exclusion list took `dev/` out and a `dev/...`
#     reference is now read as a citation of the source repository rather than
#     as a link.
c5 <- mk_copy("linkdead")
if (dir.exists(c5)) {
    f <- file.path(c5, "README.md")
    if (file.exists(f)) {
        Sys.chmod(f, "0644")
        cat("\n- `docs/no-such-page.md` — the margin recipe\n",
            file = f, append = TRUE)
    }
}
r5 <- verify_of(c5)
check_true("v79",
           sprintf("--verify goes red on a shipped document linking a path the artefact does not hold (rc %d)",
                   r5$status),
           r5$status == 1L)
check_true("v79", "--verify names the dead artefact-relative link",
           any(grepl("docs/no-such-page.md", r5$out, fixed = TRUE)))

# AND THE SCAN IS NOT LOOKING AT NOTHING. Both controls above are satisfied by
# a scanner that examines one document and finds the one line the control just
# wrote into it. The builder prints its own population on every verify, and
# the floors here are under today's figures (38 references, 3 documents -- the
# artefact carries README.md, docs/RECIPES.md and docs/API_EXPORT.md, the ten
# developer documents having gone out with dev/) so an added or removed
# reference does not turn this red -- what turns it red is a grammar that has
# stopped matching, which is how a link scanner dies.
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
           !is.na(n_refs) && n_refs >= 25 && !is.na(n_docs) && n_docs >= 3)

# ---------------------------------------------------------------------------
# 3b. THE ZIP IS THE SUBJECT -- SIX MORE NEGATIVE CONTROLS
# ---------------------------------------------------------------------------
# EVERY DAMAGE BELOW IS DONE TO THE ZIP AND NOT TO THE FOLDER, except the two
# that damage the RULE. That is the whole design of the gate: the folder is
# what the builder wrote seconds ago and can only agree with the builder's own
# walk, while the zip is what a user downloads, and a copy, a chmod pass, an
# archive writer and anybody with a shell sit between them. A gate that had
# drifted back onto the staging directory passes every control here while the
# archive carries the developer tree, so the folder is left untouched on
# purpose and the copy's own files are asserted unchanged.
zip_of <- function(dir) file.path(dirname(dir), paste0(basename(dir), ".zip"))

# A copy of the artefact folder with a zip beside it, built by rewriting the
# real zip through python -- the builder's own interpreter, already required
# above. `target` is a file whose bytes get `extra` appended, or "" to add
# `add` as a wholly new entry.
mk_zip_copy <- function(tag, target = "", extra = "", add = "", addtext = "x\n") {
    d <- file.path(ctl, tag)
    unlink(d, recursive = TRUE); dir.create(d, recursive = TRUE, showWarnings = FALSE)
    tgt <- file.path(d, if (!is.na(NAME)) NAME else "x")
    if (dir.exists(ART)) file.copy(ART, d, recursive = TRUE)
    if (!file.exists(ZIP) || !nzchar(py)) return(tgt)
    file.copy(file.path(D1, "RELEASE.tsv"), file.path(d, "RELEASE.tsv"))
    script <- file.path(SCRATCH, "rewrite.py")
    writeLines(c(
        "import sys, zipfile",
        "src, dst, target, extra, add, addtext = sys.argv[1:7]",
        "zin = zipfile.ZipFile(src)",
        "out = zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED)",
        "for info in zin.infolist():",
        "    data = b'' if info.is_dir() else zin.read(info)",
        "    if target and info.filename.endswith('/' + target):",
        "        data = data + extra.encode('utf-8')",
        "    ni = zipfile.ZipInfo(info.filename, date_time=(1980,1,1,0,0,0))",
        "    ni.external_attr = info.external_attr",
        "    ni.compress_type = info.compress_type",
        "    out.writestr(ni, data)",
        "if add:",
        "    ni = zipfile.ZipInfo(add, date_time=(1980,1,1,0,0,0))",
        "    ni.external_attr = 0o644 << 16",
        "    out.writestr(ni, addtext.encode('utf-8'))",
        "out.close()"), script)
    run(py, c(shQuote(script), shQuote(ZIP), shQuote(zip_of(tgt)),
              shQuote(target), shQuote(extra), shQuote(add), shQuote(addtext)))
    tgt
}

# (f) A DEVELOPER FILE PUT BACK INTO THE ZIP, with the built folder clean. The
#     exclusion list is the artefact's whole statement about what a user does
#     not receive, and the only place it can still be enforced is the archive.
c6 <- mk_zip_copy("zipdev",
                  add = sprintf("%s/dev/tools/run-tests.py", NAME),
                  addtext = "print('the runner')\n")
r6 <- verify_of(c6)
check_true("v79",
           sprintf("--verify goes red on a dev/ file inside the finished zip (rc %d)",
                   r6$status),
           r6$status == 1L)
check_true("v79",
           "--verify names the excluded path and the row that excludes it",
           any(grepl("dev/tools/run-tests.py", r6$out, fixed = TRUE)) &&
           any(grepl("'dev/'", r6$out, fixed = TRUE)))
# AND THE FOLDER BESIDE IT WAS CLEAN THE WHOLE TIME. Without this the control
# is also passed by a gate reading the staging directory, because the copy
# would have to be dirty for that gate to fire -- and it is not.
check_true("v79",
           "the damage was in the zip alone: the copied folder holds no dev/",
           dir.exists(c6) && !dir.exists(file.path(c6, "dev")))

# (g) A HISTORY LINE IN THE ZIP. validate/v80 makes the same rejection on the
#     source tree; this is the same rule at the last gate it has, on the bytes
#     a user actually receives.
c7 <- mk_zip_copy("ziphist", target = "eml-core-utilities.praat",
                  extra = "\n# v2.4: the guard moved; previously it was on .nGroups\n")
r7 <- verify_of(c7)
check_true("v79",
           sprintf("--verify goes red on a history line inside the finished zip (rc %d)",
                   r7$status),
           r7$status == 1L)
check_true("v79",
           "--verify names the file and the line that narrates history",
           any(grepl("stats/eml-core-utilities.praat", r7$out, fixed = TRUE)) &&
           any(grepl("v2.4: the guard moved", r7$out, fixed = TRUE)))

# (h) THE SAME TEXT AS A STRING THE PLUGIN PRINTS -- AND THIS ONE MUST STAY
#     GREEN. v80's rule examines comment lines in a .praat and nothing else,
#     because a message the plugin displays is the product, and rewriting a
#     user-facing sentence to quiet a lint would be the lint doing damage. A
#     scan reduced to a plain grep over the file's bytes passes (g) and fails
#     here, which is the only way to tell the two apart.
c8 <- mk_zip_copy("zipstring", target = "eml-core-utilities.praat",
                  extra = "\nappendInfoLine: \"v2.4: the guard moved; previously it was on .nGroups\"\n")
r8 <- verify_of(c8)
check_true("v79",
           sprintf("--verify stays green on the same history text inside a STRING the plugin prints (rc %d)",
                   r8$status),
           r8$status == 0L)

# (i) THE EXCLUSION LIST EMPTIED. Not a build that ships everything -- a build
#     that REFUSES, because a gate handed an empty list tests every artefact
#     against nothing, passes all of them, and prints what a gate that checked
#     prints. The list is redirected with $EML_RELEASE_EXCLUDE so that no
#     committed document is edited to run the control.
empty_x <- file.path(SCRATCH, "exclude_empty.tsv")
writeLines("# every row removed", empty_x)
# THE OVERRIDE IS SET IN THIS PROCESS AND REMOVED AGAIN, rather than passed to
# the child: system2()'s `env` argument is not portable, and a committed rule
# file must not be edited to run a control.
old_x <- Sys.getenv("EML_RELEASE_EXCLUDE", unset = NA)
Sys.setenv(EML_RELEASE_EXCLUDE = empty_x)
r9 <- if (nzchar(py) && file.exists(BUILDER))
    run(py, c(shQuote(BUILDER), "--out", shQuote(file.path(SCRATCH, "b_empty")))) else
    list(status = 99L, out = "")
# AND A ROW THAT EXCLUDES NOTHING, the staleness failure v80 reports on its
# own allowlist: a row naming a path the tree does not hold tells its reader
# the artefact is smaller than it is.
stale_x <- file.path(SCRATCH, "exclude_stale.tsv")
writeLines(c(
    "dev/\tThe developer tree, exactly as the committed list excludes it, so this row is not the one under test.",
    "not_a_directory/\tA row naming a path this tree does not hold, to prove a stale exclusion is caught."),
    stale_x)
Sys.setenv(EML_RELEASE_EXCLUDE = stale_x)
r10 <- if (nzchar(py) && file.exists(BUILDER))
    run(py, c(shQuote(BUILDER), "--out", shQuote(file.path(SCRATCH, "b_stale")))) else
    list(status = 99L, out = "")
if (is.na(old_x)) Sys.unsetenv("EML_RELEASE_EXCLUDE") else
    Sys.setenv(EML_RELEASE_EXCLUDE = old_x)

check_true("v79",
           sprintf("the build refuses when the exclusion list is emptied (rc %d)",
                   r9$status),
           r9$status == 2L)
check_true("v79",
           "and says it would otherwise be asserting nothing, rather than shipping everything",
           any(grepl("lists nothing", r9$out, fixed = TRUE)) &&
           any(grepl("pass every artefact", r9$out, fixed = TRUE)))
check_true("v79",
           sprintf("the build refuses an exclusion row that matches nothing (rc %d)",
                   r10$status),
           r10$status == 2L)
check_true("v79", "and names the row that excluded nothing",
           any(grepl("not_a_directory/", r10$out, fixed = TRUE)))

# (j) THE CONTRADICTION THAT WAS THERE BEFORE THIS RULING, PUT BACK. Until the
#     exclusion existed, MANIFEST.txt listed the retired files under a heading
#     reading "Not shipped, not discovered by the test runner" and the build
#     shipped them. The gate that catches it does NOT read the exclusion list
#     -- it reads what the artefact SAYS about itself, out of the manifest
#     travelling inside it, and compares that to what the artefact IS. So it
#     still fires when the exclusion list and the manifest are edited apart,
#     which is exactly what is done here: every top-level entry of dev/ is
#     excluded EXCEPT dev/retired/.
dev_top <- list.files(file.path(plug, "dev"), all.files = FALSE, no.. = TRUE)
dev_top <- dev_top[dev_top != "retired"]
rows <- vapply(dev_top, function(e) {
    slash <- if (dir.exists(file.path(plug, "dev", e))) "/" else ""
    sprintf("dev/%s%s\tExcluded for this control, which leaves dev/retired/ shipping on purpose.",
            e, slash)
}, character(1))
revert_x <- file.path(SCRATCH, "exclude_reverted.tsv")
writeLines(unname(rows), revert_x)
Sys.setenv(EML_RELEASE_EXCLUDE = revert_x)
r11 <- if (nzchar(py) && file.exists(BUILDER) && length(rows))
    run(py, c(shQuote(BUILDER), "--out", shQuote(file.path(SCRATCH, "b_revert")))) else
    list(status = 99L, out = "")
if (is.na(old_x)) Sys.unsetenv("EML_RELEASE_EXCLUDE") else
    Sys.setenv(EML_RELEASE_EXCLUDE = old_x)
check_true("v79",
           sprintf("the build refuses an artefact carrying what its own manifest calls not-shipped (rc %d)",
                   r11$status),
           r11$status == 1L)
retired_named <- grep("not shipped, and the artefact ships it", r11$out, value = TRUE)
check_true("v79",
           sprintf("and names every retired path rather than counting them (%d named: %s)",
                   length(retired_named),
                   paste(sub("^ *MANIFEST.txt says ", "", retired_named), collapse = " | ")),
           length(retired_named) >= 2 &&
           all(grepl("dev/retired/", retired_named, fixed = TRUE)))

# THE GATES' OWN POPULATIONS, PRINTED BY THE BUILDER AND FLOORED HERE. Every
# control above is satisfied by a gate that examines one file and finds the
# one thing the control put in it. These are the counts that say the gates
# looked at the artefact: which container was read, how many lines the history
# scan examined, and how many not-shipped rows the manifest offered it. A gate
# reading nothing reports a clean artefact in exactly the same words.
src_line <- grep("^artefact contents read from:", v_ok$out, value = TRUE)
check_true("v79",
           sprintf("the gates read the ZIP, not the staging directory (%s)",
                   if (length(src_line)) trimws(src_line[1]) else "<no line>"),
           length(src_line) == 1 && grepl("the zip", src_line[1], fixed = TRUE))
rule_line <- grep("^ *exclusion rows", v_ok$out, value = TRUE)
n_pat <- suppressWarnings(as.integer(sub("^.*history patterns ([0-9]+).*$", "\\1",
                                         if (length(rule_line)) rule_line[1] else "")))
n_xrow <- suppressWarnings(as.integer(sub("^ *exclusion rows ([0-9]+).*$", "\\1",
                                          if (length(rule_line)) rule_line[1] else "")))
# THE PATTERN COUNT IS COMPARED TO v80's OWN LIST, read out of the file v80
# reads, so the artefact gate and the repository lint cannot enforce two
# different rules while both reporting a clean tree.
tool <- file.path(plug, "dev", "tools", "extract-history.py")
tsrc <- if (file.exists(tool)) readLines(tool, warn = FALSE) else character(0)
a <- grep("^PATTERNS = \\[", tsrc); b <- grep("^\\]", tsrc)
v80_n <- if (length(a) && any(b > a[1]))
    length(grep('^\\s*r"', tsrc[(a[1] + 1L):(min(b[b > a[1]]) - 1L)])) else 0L
check_true("v79",
           sprintf("the artefact's history gate uses v80's pattern list (%s in the builder, %d in extract-history.py)",
                   n_pat, v80_n),
           !is.na(n_pat) && v80_n >= 5 && n_pat == v80_n)
check_true("v79",
           sprintf("the exclusion list reached the gate (%s row(s) in the builder, %d in %s)",
                   n_xrow, length(xrows), basename(EXCL)),
           !is.na(n_xrow) && n_xrow == length(xrows) && n_xrow >= 1)
hist_line <- grep("^ *history scan:", v_ok$out, value = TRUE)
n_hl <- suppressWarnings(as.integer(sub("^ *history scan: ([0-9]+) line.*$", "\\1",
                                        if (length(hist_line)) hist_line[1] else "")))
n_hf <- suppressWarnings(as.integer(sub("^.*in ([0-9]+) file.*$", "\\1",
                                        if (length(hist_line)) hist_line[1] else "")))
check_true("v79",
           sprintf("the history scan examined a real population (%s line(s) in %s file(s))",
                   n_hl, n_hf),
           !is.na(n_hl) && n_hl >= 5000 && !is.na(n_hf) && n_hf >= 20)
man_line <- grep("^ *manifest not-shipped rows checked:", v_ok$out, value = TRUE)
n_ns <- suppressWarnings(as.integer(sub("^.*: ([0-9]+)$", "\\1",
                                        if (length(man_line)) man_line[1] else "")))
check_true("v79",
           sprintf("the shipped manifest offered the gate something to check (%s not-shipped row(s))",
                   n_ns),
           !is.na(n_ns) && n_ns >= 1)

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
           inc_seen >= 35)
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
# THE COUNT IS DERIVED FROM THE SHIPPED SOURCE, NOT TYPED HERE. This check
# once carried a floor of 100 lines, and on 18 August 2026 the artefact
# legitimately fell to 42: dev/ had joined RELEASE_EXCLUDE.tsv, and with it
# every include line in the developer test tree. A literal floor cannot tell
# that apart from a scan that broke, and the only thing it did tell anyone was
# what the tree looked like on the day somebody typed it.
#
# So the same population is recomputed here, from plugin/ minus the exclusion
# rows parsed in 2b, with the harness's own regex -- and the two are required
# to be EQUAL rather than merely large. That binds this check to the shipped
# tree the way the setup.praat digest above binds the walk to the shipped
# registration: add an include line to a script a user receives and the
# release harness has to be re-driven, which is the event that went unnoticed
# and left this file reading a record of a 327-file artefact that no longer
# existed.
shipped_praat <- list.files(plug, pattern = "\\.praat$", recursive = TRUE)
shipped_praat <- shipped_praat[!vapply(shipped_praat, function(f)
    any(vapply(xpath, function(e)
        identical(f, e) || (grepl("/$", e) && startsWith(f, e)),
        logical(1))), logical(1))]
inc_src <- sum(vapply(shipped_praat, function(f)
    sum(grepl("^\\s*include\\s+\\S",
              readLines(file.path(plug, f), warn = FALSE))), integer(1)))
check_true("v79",
           sprintf("the include population recomputed here is not empty (%d line(s) in %d shipped script(s))",
                   inc_src, length(shipped_praat)),
           inc_src > 0 && length(shipped_praat) > 0)
check_true("v79",
           sprintf("every include in the installed tree resolved, and the tree holds the shipped source's include lines (%s of %d, %s dangling: %s)",
                   tsv("installed_include_lines"), inc_src,
                   tsv("installed_includes_dangling"),
                   tsv("installed_includes_first_dangling")),
           identical(tsv("installed_includes_dangling"), "0") &&
           !is.na(tsvn("installed_include_lines")) &&
           tsvn("installed_include_lines") == inc_src)

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
