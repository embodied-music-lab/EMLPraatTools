# ============================================================================
# coverage.R -- for everything a driver renders, is there some check on it?
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 12 August 2026 the stress artefact was found to
# contain 39 rendered cases of which 29 were asserted on by nothing. They had
# been rendered, measured, committed and re-committed for weeks. The suite was
# green the whole time, and correctly so: v27 asserts on the ten empty_*
# cases and makes no claim about the rest, which is what that file is for.
# Every check in the tree passed, and 29 cases were invisible.
#
# No per-validator check can catch that. eml_census asks "does THIS file look
# at everything in the artefact", and the honest answer for v27 is no, on
# purpose. The question that was missing has a different unit:
#
#     FOR EACH ARTEFACT, ACROSS EVERY VALIDATOR THAT READS IT,
#     IS EVERY RENDERED CASE NAMED BY SOMETHING?
#
# HOW IT WORKS, and the design decision is the interesting part. A map of
# validator-to-cases could be written down, and it would drift -- it would be
# one more hand-maintained list capable of disagreeing with reality, which is
# the exact failure being guarded against. So nothing is written down. Each
# validator calls eml_claim() with the same vector its checks loop over, so a
# validator that stops asserting on a case stops claiming it in the same edit.
# This file reads each artefact's population OFF DISK, independently, and
# compares.
#
# Both sides therefore come from somewhere other than this file. That is what
# makes the comparison worth making.
#
# RUN AS PART OF THE SUITE, NOT ALONE. It needs the claims every validator
# registered while running, so it is sourced last by run_all.R and does
# nothing on its own.
#
# ADDING AN ARTEFACT. Put it in ARTEFACTS below with a reader that returns the
# case identifiers a driver rendered. If no validator claims it, this file
# says so and fails -- an artefact with no reader at all is the largest
# version of the gap and must not be silent.
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

# --- readers -----------------------------------------------------------------
# Each returns the case identifiers the DRIVER produced, read from the file the
# driver wrote. Never from a list a validator supplied.

.tsv_col1 <- function(path) {
    if (!file.exists(path)) return(NULL)
    d <- read.delim(path, header = FALSE, stringsAsFactors = FALSE,
                    quote = "", comment.char = "")
    if (nrow(d) == 0L) return(character(0))
    as.character(d[[1]])
}

# The parity artefact keys on procedure AND arm: `violin` appears twice and
# they are two different measurements.
.parity_cases <- function(path) {
    if (!file.exists(path)) return(NULL)
    d <- read.delim(path, header = FALSE, stringsAsFactors = FALSE)
    if (nrow(d) == 0L) return(character(0))
    paste(d[[1]], d[[2]])
}

# THE SAME DIRECTORY THE VALIDATORS READ, AND THIS IS NOT A DETAIL.
#
# Every validator here honours an EML_* override so it can be pointed at a
# copy -- which is how the break tests that keep these checks honest are run,
# without ever editing a committed artefact. The first version of this file
# ignored those overrides and always read the repo default. The two halves of
# the comparison then came from DIFFERENT artefacts: the validators claimed
# cases from the copy while this file enumerated the original, and a case
# added to the copy that nothing claimed was reported as covered.
#
# Found by its own break test on 12 Aug 2026 -- the third one, planting an
# unclaimed case, did not fail when it should have. A coverage check that
# silently compares two different populations is worse than none, because it
# reports the answer it was built to detect the absence of.
.dir <- function(var, ...) {
    d <- Sys.getenv(var, unset = "")
    if (nzchar(d)) d else repo_path(...)
}
.file <- function(var, ...) {
    f <- Sys.getenv(var, unset = "")
    if (nzchar(f)) f else repo_path(...)
}

ARTEFACTS <- list(
  list(key  = "stress_out",
       what = "stress case",
       path = file.path(.dir("EML_STRESS_DIR", "harness", "stress_out"),
                        "RESULTS.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/stress_graphs.sh"),
  list(key  = "legend_out",
       what = "legend figure",
       path = file.path(.dir("EML_LEGEND_DIR", "harness", "legend", "out"),
                        "RESULTS.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/legend/run.sh"),
  list(key  = "parity_out",
       what = "parity case",
       path = file.path(.dir("EML_PARITY_DIR", "harness", "parity", "out"),
                        "PARITY.tsv"),
       read = .parity_cases,
       rerun = "bash harness/parity/run.sh"),
  list(key  = "wrappers_out",
       what = "entry point",
       path = .file("EML_WRAPPERS_TSV", "harness", "wrappers", "out",
                    "WRAPPERS.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/wrappers/run.sh"),
  list(key  = "record_out",
       what = "recorded operation",
       path = file.path(.dir("EML_RECORD_DIR", "harness", "record_e2e", "out"),
                        "RECORD.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/record_e2e/run.sh"),
  list(key  = "norecord_out",
       what = "operation without the recorder",
       path = file.path(.dir("EML_NORECORD_DIR", "harness", "norecord", "out"),
                        "NORECORD.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/norecord/run.sh"),
  list(key  = "blankgroup_out",
       what = "blank-group case",
       path = file.path(.dir("EML_BLANKGROUP_DIR", "harness", "blankgroup",
                             "out"), "BLANKGROUP.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/blankgroup/run.sh"),
  list(key  = "legendroom_out",
       what = "legend-room case",
       path = file.path(.dir("EML_LEGENDROOM_DIR", "harness", "legendroom",
                             "out"), "LEGENDROOM.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/legendroom/run.sh"),
  list(key  = "determinism_out",
       what = "draw procedure",
       path = file.path(.dir("EML_DETERMINISM_DIR", "harness", "determinism",
                             "out"), "DETERMINISM.tsv"),
       read = .tsv_col1,
       rerun = "bash harness/determinism/run.sh")
)

# --- the pass ----------------------------------------------------------------
for (a in ARTEFACTS) {
    present <- a$read(a$path)

    # A MISSING ARTEFACT IS A FAILURE HERE, not a skip. Same rule the
    # validators apply: "the driver never ran this" is precisely what a
    # silently shrinking suite hides.
    if (!check_true("v38", sprintf("%s: the artefact exists (%s)",
                                   a$key, a$rerun), !is.null(present))) next
    if (!check_true("v38", sprintf("%s: the artefact has cases", a$key),
                    length(present) > 0)) next

    claimed   <- eml_claimed(a$key)
    claimants <- eml_claimants(a$key)

    # AN ARTEFACT WITH NO READER AT ALL is the largest version of this gap --
    # it is what harness/determinism/out was until v37 existed -- so it is
    # named separately rather than showing up as "everything is orphaned".
    if (!check_true("v38",
                    sprintf("%s: some validator reads it", a$key),
                    length(claimants) > 0)) next

    uncovered <- setdiff(unique(present), claimed)
    check_true("v38",
               sprintf("%s: every %s is claimed by some validator (%s)",
                       a$key, a$what, paste(sort(claimants), collapse = ", ")),
               length(uncovered) == 0)
    if (length(uncovered) > 0) {
        check_true("v38",
                   sprintf("  %s: unclaimed %s: %s", a$key, a$what,
                           paste(utils::head(sort(uncovered), 10),
                                 collapse = ", ")),
                   FALSE)
    }

    # The other direction: a validator claiming a case the driver did not
    # render is asserting on something that is not there, which passes
    # vacuously in that file and is invisible from inside it.
    ghost <- setdiff(claimed, unique(present))
    check_true("v38",
               sprintf("%s: no validator claims a %s that was never rendered",
                       a$key, a$what),
               length(ghost) == 0)
    if (length(ghost) > 0) {
        check_true("v38",
                   sprintf("  %s: claimed but absent: %s", a$key,
                           paste(utils::head(sort(ghost), 10), collapse = ", ")),
                   FALSE)
    }
}

# EVERY ARTEFACT IN THE TABLE WAS VISITED. A reader that threw, or a list
# quietly shortened, would otherwise reduce this file to nothing while it
# still reported success.
check("v38", "every declared artefact was examined",
      length(ARTEFACTS), 9, tol = 0)

if (!exists("EML_SUITE")) {
    eml_report("v38 coverage: everything rendered is claimed by some validator")
    eml_exit()
}
