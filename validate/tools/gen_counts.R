#!/usr/bin/env Rscript
# ============================================================================
# gen_counts.R -- the suite's totals are GENERATED, never written down
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 14 August 2026 an audit found four documents in
# this repository carrying four different totals for the same suite -- 6,486
# in README.md, 4,058 at four separate sites in validate/README.md, 8,221 in
# the REGISTRY headline, 9,877 in a session report -- against a live run of
# 10,063 that was 10,291 two days later and higher again by the end of the
# week. Every one of those numbers was correct on the day it was typed. None
# of them was wrong through carelessness. They went stale because a total is
# a measurement of a moving thing, and a measurement written into prose stops
# being a measurement the moment the thing moves.
#
# The repair is not a fifth correction. Correcting them puts four fresh
# numbers into four documents and starts the same clock again. The repair is
# to stop storing the number at all:
#
#     THE ONLY NUMBER ABOUT THIS SUITE THAT THIS REPOSITORY IS ALLOWED TO
#     CONTAIN IS ZERO -- the count of failures, which is a contract rather
#     than a measurement, and which cannot go stale because a suite that
#     violates it is broken by definition.
#
# Everything else -- how many checks ran, how many attestations were recorded,
# how many each script contributed -- is generated on demand, from a specific
# run, by this file, and is stamped with when it was measured and at which
# commit. A generated block is honest about being a photograph of one moment.
# A number in a paragraph pretends to be a fact about the repository.
#
# HOW IT IS ENFORCED. `check_registry_counts.R` lints the front-door documents
# for any total written down in prose and fails on sight. It needs no live run
# and no knowledge of the true figure to do that, which is the whole point: an
# enforcement that has to know the right answer is one more thing that can be
# out of date.
#
# USAGE
#   Rscript validate/run_all.R | tee /tmp/suite.log
#   Rscript validate/tools/gen_counts.R /tmp/suite.log            # to stdout
#   Rscript validate/tools/gen_counts.R /tmp/suite.log COUNTS.md  # to a file
#
# With no log argument it runs the suite itself, which takes several minutes.
# Pass the log of a run you already made whenever you have one.
#
# The output is Markdown, ready to paste into a report or a release note. It
# is deliberately NOT written into the repository by default and no committed
# document includes it: a committed copy is a stale total with extra steps.
#
# Stock R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
.a   <- commandArgs(FALSE)
.f   <- sub("^--file=", "", .a[grep("^--file=", .a)])
HERE <- if (length(.f)) dirname(normalizePath(.f)) else getwd()
VAL  <- dirname(HERE)                       # .../validate
ROOT <- dirname(VAL)

# --- the run ----------------------------------------------------------------
# Either a log handed to us, or a run made here. A log we were handed is
# preferred: the suite must be run once per question asked of it, not once per
# tool that wants to look at the answer.
if (length(args) >= 1 && nzchar(args[1])) {
    if (!file.exists(args[1])) stop("no such log: ", args[1])
    log    <- readLines(args[1], warn = FALSE)
    source <- normalizePath(args[1])
} else {
    log    <- suppressWarnings(system2("Rscript", file.path(VAL, "run_all.R"),
                                       stdout = TRUE, stderr = TRUE))
    source <- "a run made by this script"
}

# --- parse ------------------------------------------------------------------
# Everything below is read out of the run. Nothing is a constant in this file,
# because a constant in this file is the defect this file exists to retire.
n_pass  <- sum(grepl("^PASS\\b", log))
n_fail  <- sum(grepl("^FAIL\\b", log))
n_atst  <- sum(grepl("^ATST\\b", log))
n_check <- n_pass + n_fail

hl <- grep("^\\d+ checks, \\d+ passed, \\d+ FAILED\\s*$", log, value = TRUE)
if (!length(hl)) {
    stop("this log has no '<N> checks, <N> passed, <N> FAILED' summary line -- ",
         "it is not the output of validate/run_all.R, or the run did not finish")
}
# The suite prints one such line per report; run_all.R's SUMMARY is the last.
hlm <- as.integer(regmatches(hl[length(hl)],
                             regexec("^(\\d+) checks, (\\d+) passed, (\\d+) FAILED",
                                     hl[length(hl)]))[[1]][2:4])

# by-script aggregate: "  <id>  <p>/<n>  <attested>"
agg <- grep("^\\s*\\S+\\s+\\d+/\\d+\\s+\\d+\\s*$", log, value = TRUE)
if (!length(agg)) {
    stop("this log has no by-script aggregate -- run_all.R prints one under ",
         "'By script id:'; a partial log cannot be turned into a counts block")
}
m   <- regmatches(agg, regexec("^\\s*(\\S+)\\s+(\\d+)/(\\d+)\\s+(\\d+)\\s*$", agg))
per <- do.call(rbind, lapply(m, function(x)
    data.frame(id = x[2], passed = as.integer(x[3]), total = as.integer(x[4]),
               attested = as.integer(x[5]), stringsAsFactors = FALSE)))
per <- per[order(per$id), , drop = FALSE]

# run_all.R's second line is "R <major>.<minor>  <timestamp>"; the timestamp is
# the run's, and is reported on its own below rather than smuggled into the
# version string.
rline <- grep("^R \\d", log, value = TRUE)
rver  <- if (length(rline)) {
    sub("\\s{2,}.*$", "", trimws(rline[1]))
} else paste("R", getRversion())
rwhen <- if (length(rline)) {
    w <- sub("^R \\S+\\s+", "", trimws(rline[1])); if (nzchar(w)) w else NA_character_
} else NA_character_

git <- suppressWarnings(system2("git", c("-C", shQuote(ROOT), "rev-parse", "--short", "HEAD"),
                                stdout = TRUE, stderr = FALSE))
git <- if (length(git) && nzchar(git[1])) git[1] else "unknown"
dirty <- suppressWarnings(system2("git", c("-C", shQuote(ROOT), "status", "--porcelain"),
                                  stdout = TRUE, stderr = FALSE))
if (length(dirty)) git <- paste0(git, " (working tree modified)")

# --- emit -------------------------------------------------------------------
out <- c(
    "<!-- GENERATED by validate/tools/gen_counts.R. Do not hand-edit, and do",
    "     not commit a copy into a prose document: a committed total is a",
    "     stale total with extra steps. Regenerate it instead. -->",
    "",
    "## Suite counts, as measured",
    "",
    sprintf("**%d checks, %d passed, %d FAILED**, plus %d attestation%s reported",
            hlm[1], hlm[2], hlm[3], n_atst, if (n_atst == 1L) "" else "s"),
    "separately and not counted as checks.",
    "",
    sprintf("Run %s under %s, at commit `%s`. Block generated %s.",
            if (is.na(rwhen)) "at an unrecorded time" else rwhen,
            rver, git, format(Sys.time(), "%d %B %Y %H:%M %Z")),
    sprintf("Source: %s.", source),
    "",
    "| Script | Passed / checks | Attestations |",
    "|---|---|---|",
    sprintf("| `%s` | %d/%d | %s |", per$id, per$passed, per$total,
            ifelse(per$attested > 0L, as.character(per$attested), "—")),
    "",
    sprintf("%d scripts reporting. This table is the inventory; the narrative",
            nrow(per)),
    "index in `validate/REGISTRY.md` explains what the checks are *for* and does",
    "not attempt to stay row-for-row current with it."
)

if (length(args) >= 2 && nzchar(args[2])) {
    writeLines(out, args[2])
    cat("wrote ", args[2], "\n", sep = "")
} else {
    writeLines(out)
}
