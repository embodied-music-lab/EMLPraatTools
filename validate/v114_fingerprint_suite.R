# ============================================================================
# v114 — the data fingerprint's own suite, RUN, and its numbers pinned
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS FILE IS ABOUT, AND WHY IT IS SO SHORT.
#
# The data fingerprint is shipped code. @emlDataFingerprint and the four
# procedures around it sit at the foot of plugin/stats/eml-extract.praat, they
# emit the eTF2 key the result store will use to decide whether a stored
# result still describes the table in front of it, and they have 278 checks
# written against them in
#
#     plugin/dev/tests/phase2/test-fingerprint.praat
#
# The main validation suite did not run that file. Nothing in validate/ so
# much as named it. So the suite's count was unmoved by the entire component,
# and THE ONLY EVIDENCE FOR THE FINGERPRINT WAS EVIDENCE IT WROTE ABOUT
# ITSELF — a suite nobody drives is a suite nobody can tell has stopped
# running. That is the gap this file closes, and it closes it the cheap way:
# it RUNS the phase2 legs and reads their numbers back. It does not add legs
# of its own to phase2, and it does not reimplement the fingerprint in R. A
# second implementation would be a second thing to maintain and would settle
# nothing that the 278 legs do not already settle better.
#
# The component has no shipped caller yet. That is expected while the result
# store is unbuilt, and it is exactly why the coverage question is worth
# settling now: an uncalled component is one whose evidence nobody trips over
# by accident, so the evidence has to be driven on purpose.
#
# ----------------------------------------------------------------------------
# THE RISK THIS FILE IS DESIGNED AGAINST IS ITS OWN
# ----------------------------------------------------------------------------
# A check that shells out to another suite has one characteristic failure: it
# reports green when nothing ran. This repository found that shape in a driver
# on the afternoon of 24 August 2026, and dev/tests/eml-test-helpers.praat
# carries a paragraph about the same defect in its own v1.0 — a summary that
# printed "SOME TESTS FAILED" and then exited 0, so every exit-status-driven
# runner in the tree was green by construction.
#
# So four ways of running nothing are each required to be RED here, and each
# is a line of its own rather than a silent skip:
#
#   THE FILE IS NOT THERE.       Absent, or present and empty. Section 1.
#   PRAAT CANNOT BE RESOLVED.    No binary, or one below the plugin's floor,
#                                or an explicit $PRAAT that is not executable
#                                — the same resolution order and the same
#                                refusal as harness/_env.sh, restated here
#                                because a validator cannot source a bash
#                                file. THERE IS NO BARE `praat` ON PATH IN
#                                THIS TREE; a check that assumed one would
#                                pass on the development machine and fail in
#                                CI. Section 2.
#   NO PARSEABLE RESULT LINE.    The suite died before @emlTestSummary, or
#                                something printed a line that is not the
#                                sentinel. Absence of the sentinel is FAIL,
#                                never PASS — the reporting contract at the
#                                head of eml-test-helpers.praat says so in
#                                those words. Section 4.
#   THE REPORTED TOTAL IS ZERO.  A suite that ran no checks at all. Section 5.
#
# NOTHING HERE IS CONDITIONAL ON THE DRIVE HAVING WORKED. Every fact below is
# NA until the drive supplies it, and every assertion is written so that NA
# fails. That is v110's rule and v53's and v55's before it: a validator that
# stops early on a missing fact has reported nothing, which is strictly worse
# than a red line, because a reader of the report cannot tell it apart from a
# validator that had nothing to say.
#
# AND IT REPORTS THE NUMBERS IT READ, NOT A VERDICT. Every line below names
# the count it is asserting on, so a red says 139 where 278 was expected
# rather than saying "the fingerprint suite did not pass".
#
# ----------------------------------------------------------------------------
# THE TOTAL IS PINNED EXACTLY, NOT AS A FLOOR, AND HERE IS THE ARGUMENT
# ----------------------------------------------------------------------------
# Asserting the pass count alone is not enough and the reason is the whole
# point of this file. A suite that silently stops running half its legs
# reports a SMALLER CLEAN NUMBER — "139 passed, 0 failed" — and that is a
# green under any floor at or below 139. Silent non-coverage does not present
# as a failure; it presents as a tidier success. So the total is asserted too.
#
# A floor and an exact pin trade the same way they always do. A floor never
# has to be updated and never catches a drop above itself. An exact total is
# a ratchet: it catches a single leg going missing, and it has to be updated
# in the same commit that adds a leg.
#
# THE PIN WINS HERE FOR ONE REASON: THIS COUNT IS STRUCTURAL, NOT MEASURED.
# The phase2 file contains no @emlTestSkip, no assertion inside a branch whose
# condition is a measured value, and no loop whose bound is data-dependent —
# its loops run over fixed literal lists. Two legs time the key and assert a
# bound, but they are pass/fail legs and do not change the count. So 278 is a
# property of the file, identical on a fast machine and a slow one, and
# pinning it cannot go red on somebody else's hardware for a reason that is
# not about the plugin.
#
# That is precisely the test v110 section 7 applies and FAILS, which is why
# the control counts there are a floor of 1000 against measured values of
# 10,206 to 196,601: a font renderer's pixel count is not a property of this
# repository. Same criterion, opposite answer, because the quantity is a
# different kind of thing.
#
# The cost is one integer on the next line, and the red that asks for it says
# both numbers, so the update is mechanical and a reviewer sees the delta.
# WHEN THAT RED APPEARS, CHECK THE DELTA BEFORE CHANGING THE NUMBER: legs
# added is a bigger total, legs lost is a smaller one, and only one of those
# is a reason to edit this line.
#
#     Rscript validate/v114_fingerprint_suite.R
#
# Input: plugin/dev/tests/phase2/test-fingerprint.praat and the shipped
#        plugin/stats/eml-extract.praat it includes. $EML_PLUGIN_DIR points at
#        a different tree and $EML_FP_SUITE at a different suite file — the
#        same override shape v47 and v110 use, so a break test drives a
#        damaged copy and never goes near the shipped one. $PRAAT overrides
#        the binary, as everywhere else.
#
# Base R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

V <- "v114"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# THE RATCHET. Measured on Praat 6.6.30, 24 August 2026: 278 passed, 0 failed,
# 0 skipped, 278 total, in 2.5 s. See the argument above before editing.
EXPECTED_TOTAL <- 278L

# ---------------------------------------------------------------------------
# 1. THE FILE IS THERE, AND IT IS THE ONE THAT TESTS THE SHIPPED FINGERPRINT
# ---------------------------------------------------------------------------
# An absent suite is the largest version of "nothing ran" and must be the
# loudest. An EMPTY one is the quiet version: Praat runs it, prints nothing,
# and exits 0, so an exit-status-driven runner calls that a pass. Both are
# refused here, and the sentinel check in section 4 refuses the second again
# from the other side.
plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")

suite <- Sys.getenv("EML_FP_SUITE", unset = "")
if (!nzchar(suite))
    suite <- file.path(plug, "dev", "tests", "phase2", "test-fingerprint.praat")

haveSuite <- check_true(V,
    sprintf("the phase2 fingerprint suite is in the tree and is not empty (%s)",
            basename(suite)),
    file.exists(suite) && !dir.exists(suite) && file.size(suite) > 0)

suiteSrc <- if (haveSuite) readLines(suite, warn = FALSE) else character(0)
suiteTxt <- paste(suiteSrc, collapse = "\n")

# WHAT RAN HAS TO BE THE SHIPPED FINGERPRINT, not a copy of it staged beside
# the test. v110 section 1 makes the same statement first and unconditionally,
# for the same reason: every count below is a statement about the plugin only
# while the thing under test was the plugin.
check_true(V, "the suite includes the shipped module the fingerprint lives in",
           grepl("include ../../../stats/eml-extract.praat", suiteTxt, fixed = TRUE))
check_true(V, "and reaches @emlTestSummary, so it can emit a result at all",
           grepl("@emlTestSummary", suiteTxt, fixed = TRUE))

# AND THE SHIPPED SIDE IS READ HERE TOO. If the fingerprint were deleted from
# eml-extract.praat and its suite deleted in the same edit, everything above
# would be satisfied by both files being absent together. This is the line
# that is not.
extract <- file.path(plug, "stats", "eml-extract.praat")
extractTxt <- if (file.exists(extract))
    paste(readLines(extract, warn = FALSE), collapse = "\n") else ""
check_true(V, "the shipped fingerprint is at the foot of eml-extract.praat",
           grepl("procedure emlDataFingerprint", extractTxt, fixed = TRUE) &&
           grepl("procedure eml_fpMix", extractTxt, fixed = TRUE))
check_true(V, "and still emits the eTF2 format tag this suite was written for",
           grepl("eTF2", extractTxt, fixed = TRUE))

# ---------------------------------------------------------------------------
# 2. THE BINARY — the same resolution order and the same refusal as
#    harness/_env.sh, which a validator cannot source
# ---------------------------------------------------------------------------
# Order, first match wins:  $PRAAT  ->  <root>/../praat  ->  praat_barren  ->
# praat. AN EXPLICIT $PRAAT THAT IS NOT EXECUTABLE IS REFUSED RATHER THAN
# FALLEN BACK FROM, because _env.sh treats an explicit override as final and a
# fallback would quietly measure a binary the caller did not choose. The floor
# is 6.6.30: setup.praat refuses to load the plugin below it, so a green run on
# an older build would describe a plugin no user can run.
praat <- Sys.getenv("PRAAT", unset = "")
explicit <- nzchar(praat)
if (!explicit) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pv <- NA_character_
pvnum <- 0L
if (nzchar(praat) && file.exists(praat) && file.access(praat, 1L) == 0L) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+(\\.[0-9]+)?", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        p <- c(p, 0L, 0L)[1:3]
        pvnum <- p[1] * 1000L + p[2] * 100L + p[3]
    }
}
canDrive <- isTRUE(pvnum >= 6630L)

check_true(V,
    sprintf("a Praat at or above the plugin's floor of 6.6.30 was resolved (found %s)",
            if (is.na(pv)) "none" else pv),
    canDrive)

# ---------------------------------------------------------------------------
# 3. THE DRIVE
# ---------------------------------------------------------------------------
# Headless, off a scratch preferences folder, in a scratch process: Praat
# persists Picture-window and other preferences, and a run started from
# somebody else's leftovers measures a state it did not choose.
#
# THE WORKING DIRECTORY IS THE SUITE'S OWN FOLDER, which is not decoration.
# The phase2 file reads ../../../stats/eml-extract.praat by a path relative to
# the process, to check the shipped modulus as text. Run from anywhere else
# that read fails and the suite dies — which this file would report as red, so
# the failure would be honest, but it would be red about the wrong thing.
# plugin/dev/tools/run-tests.py sets the same cwd for the same reason.
fp <- list(exit = NA_integer_, secs = NA_real_, nSentinel = NA_integer_,
           banner = NA, status = NA_character_,
           passed = NA_integer_, failed = NA_integer_,
           skipped = NA_integer_, total = NA_integer_)

SENTINEL <- paste0("^EMLTEST-RESULT:\\s*status=(\\w+)\\s+passed=(-?\\d+)\\s+",
                   "failed=(-?\\d+)\\s+skipped=(-?\\d+)\\s+total=(-?\\d+)\\s*$")

drive <- function(binary, script) {
    old <- getwd()
    on.exit(setwd(old), add = TRUE)
    prefs <- file.path(tempdir(), "v114-prefs")
    unlink(prefs, recursive = TRUE)
    dir.create(prefs, showWarnings = FALSE, recursive = TRUE)
    setwd(dirname(script))
    t0 <- Sys.time()
    out <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(binary),
          shQuote(paste0("--pref-dir=", prefs)),
          "--run", shQuote(basename(script))),
        stdout = TRUE, stderr = TRUE))
    list(out = as.character(out),
         exit = { st <- attr(out, "status"); if (is.null(st)) 0L else as.integer(st) },
         secs = as.numeric(difftime(Sys.time(), t0, units = "secs")))
}

runOut <- character(0)
if (canDrive && haveSuite) {
    r <- drive(praat, normalizePath(suite))
    runOut <- r$out
    fp$exit <- r$exit
    fp$secs <- r$secs
    fp$banner <- any(grepl("TEST SUMMARY", runOut, fixed = TRUE))
    hits <- grep(SENTINEL, runOut, value = TRUE)
    fp$nSentinel <- length(hits)
    if (length(hits) == 1L) {
        g <- regmatches(hits[1], regexec(SENTINEL, hits[1]))[[1]]
        fp$status  <- g[2]
        fp$passed  <- as.integer(g[3])
        fp$failed  <- as.integer(g[4])
        fp$skipped <- as.integer(g[5])
        fp$total   <- as.integer(g[6])
    }
}

n <- function(x) if (is.null(x) || length(x) != 1L || is.na(x)) "no measurement" else
    format(x, scientific = FALSE)

# ---------------------------------------------------------------------------
# 4. THE SUITE RAN, AND SAID SO IN THE ONE WAY A RUNNER MAY BELIEVE
# ---------------------------------------------------------------------------
# The reporting contract splits the result across two channels because Praat's
# exit status cannot carry three values: 0 or 255 on the status, and PASS /
# FAIL / INCOMPLETE on a stdout sentinel. BOTH ARE READ. Exit 0 alone is the
# thing the contract forbids a runner to trust, and the sentinel alone would
# be trusting a line of text over the process that printed it.
check_true(V, sprintf("the phase2 suite ran to a clean exit (status %s, %s s)",
                      n(fp$exit), if (is.na(fp$secs)) "no" else sprintf("%.1f", fp$secs)),
           identical(fp$exit, 0L))
check_true(V, "the run reached @emlTestSummary and printed its banner",
           isTRUE(fp$banner))
check_true(V, sprintf("exactly one machine-readable result line was printed (%s found)",
                      n(fp$nSentinel)),
           identical(fp$nSentinel, 1L))
check_true(V, sprintf("the result line parsed, and its status is PASS (%s)",
                      if (is.na(fp$status)) "no status read" else fp$status),
           identical(fp$status, "PASS"))

# ---------------------------------------------------------------------------
# 5. THE NUMBERS
# ---------------------------------------------------------------------------
# Reported, not summarised. Each line carries the count it read so a red says
# what was seen as well as what was wanted.
check_true(V, sprintf("the suite reported a nonzero total (%s checks)", n(fp$total)),
           !is.na(fp$total) && fp$total > 0L)
check_true(V, sprintf("no check failed (failed=%s)", n(fp$failed)),
           identical(fp$failed, 0L))
check_true(V, sprintf("no check was skipped (skipped=%s)", n(fp$skipped)),
           identical(fp$skipped, 0L))
check_true(V, sprintf("every check the suite counted also passed (passed=%s, total=%s)",
                      n(fp$passed), n(fp$total)),
           !is.na(fp$passed) && !is.na(fp$total) && fp$passed == fp$total)

# THE RATCHET, BOTH ENDS. The total is the line that catches a suite quietly
# running fewer legs; the pass count is the line that catches it running them
# and not counting them. They are separate lines because they fail for
# different reasons and a reader should be told which.
check(V, sprintf("the total the suite reported, against the pinned %d",
                 EXPECTED_TOTAL),
      EXPECTED_TOTAL, if (is.na(fp$total)) NA_real_ else as.numeric(fp$total),
      tol = 0)
check(V, sprintf("the pass count the suite reported, against the pinned %d",
                 EXPECTED_TOTAL),
      EXPECTED_TOTAL, if (is.na(fp$passed)) NA_real_ else as.numeric(fp$passed),
      tol = 0)

# WHICH FILE AND WHICH BINARY PRODUCED THESE NUMBERS. A break run drives a
# damaged copy on purpose, and a reader of a green report should be able to
# see which tree it describes without inferring it.
attest(V, "the fingerprint suite these numbers came from",
       sprintf("%s | %s | %s", suite, if (nzchar(praat)) praat else "no binary",
               if (is.na(pv)) "no version" else pv))

if (!exists("EML_SUITE")) {
    eml_report(if (is.na(fp$total))
        "v114 fingerprint suite: NO NUMBERS -- the phase2 suite did not report a result"
    else sprintf(
        "v114 fingerprint suite: %s of %s phase2 checks passed, %s failed, %s skipped",
        n(fp$passed), n(fp$total), n(fp$failed), n(fp$skipped)))
    eml_exit()
}
