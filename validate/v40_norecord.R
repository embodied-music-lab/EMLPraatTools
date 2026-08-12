# ============================================================================
# v40_norecord.R -- the plugin works WITHOUT the recorder, and it stopped
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. The workflow recorder is optional by design. Anything
# that includes the stats and graphs files directly rather than through a
# shipped barrel -- a hand-written user script, a PraatGen companion file,
# every harness in this tree -- gets the analyses and the figures without it.
# Each capture hook is therefore written to be INERT when the recorder is
# absent, guarded on variableExists ("emlRecordLoaded") rather than on
# recording state, because Praat only errors on an undefined procedure when it
# EXECUTES the call.
#
# On 12 August 2026 that contract was broken twice in one afternoon:
#
#   - the twelve analysis capture hooks were added UNGUARDED, so
#     eml-analysis.praat could no longer be loaded without eml-record.praat.
#     Nothing in validate/ noticed; plugin/dev/tests/phase2 died with
#     Procedure "emlRecordAnalysisStep" not found, which is how it surfaced.
#   - @emlRunAnovaAnalysis called @emlRecordAnova unconditionally, and that
#     procedure opens with @emlRecordInit, so the ANOVA path required the
#     recorder too -- a break the violin hook's own comment had already named,
#     in this repository, as a shipped API break.
#
# EVERY SHIPPED BARREL INCLUDES THE RECORDER. That is why no harness could
# see either one: harness/wrappers loads the barrels, harness/record_e2e
# loads the barrel and then switches recording ON, and both were green
# throughout. The missing driver is the one that loads the individual files
# and nothing else, which is what harness/norecord does.
#
#     bash harness/norecord/run.sh       regenerate the input
#     Rscript validate/v40_norecord.R
#
# Input: <dir>/NORECORD.tsv, two fields, no header:
#            name  ran|DIDNOTRUN
#        <dir> is $EML_NORECORD_DIR, default harness/norecord/out. A missing
#        artefact is a HARD STOP, not a skip.
#
# THE POPULATION IS THE SAME 36 v39 PINS, and deliberately so: the two files
# ask different questions about one list -- v39 "does it record", v40 "does it
# run at all when the recorder is not there" -- and a list that answered only
# one of them would be the gap this file exists to close.
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

nr_dir <- Sys.getenv("EML_NORECORD_DIR", unset = "")
if (!nzchar(nr_dir)) nr_dir <- repo_path("harness", "norecord", "out")
nr_p <- file.path(nr_dir, "NORECORD.tsv")
log_p <- file.path(nr_dir, "driver.log")

if (!file.exists(nr_p)) {
    stop("norecord artefact not found: ", nr_p,
         "\n  Run: bash harness/norecord/run.sh")
}

nr <- read.delim(nr_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("op", "verdict"))

NORECORD_OPS <- c("anova", "twogroup", "kw", "descriptive", "normality",
                  "correlation", "regression", "pairwise", "twoway", "paired",
                  "reliability", "rm", "friedman",
                  "violin", "scatter", "histogram", "timeseries",
                  "timeseriesci", "spaghetti", "barchart", "boxplot",
                  "gviolin", "gbox",
                  "waveform", "f0contour", "spectrum", "ltas",
                  "sound2f0", "sound2spectrum", "sound2ltas",
                  "spectrum2ltas", "spectrum2sound", "spectrum2f0",
                  "tor2table", "matrix2table",
                  "bridge")
eml_census("v40", "operation without the recorder", nr$op, NORECORD_OPS)
eml_claim("v40", "norecord_out", NORECORD_OPS)

check("v40", "every declared operation was driven", nrow(nr),
      length(NORECORD_OPS), tol = 0)
check_true("v40", "the verdict column holds only the two legal values",
           all(nr$verdict %in% c("ran", "DIDNOTRUN")))

# THE ASSERTION THIS FILE WAS BUILT FOR.
dead <- nr[nr$verdict == "DIDNOTRUN", , drop = FALSE]
check("v40", "operations that fail with the recorder absent", 0, nrow(dead),
      tol = 0)
if (nrow(dead) > 0) {
    check_true("v40", sprintf("  failed without the recorder: %s",
                              paste(dead$op, collapse = ", ")), FALSE)
}
# Named, so a future run cannot pass by driving a different 36.
for (op in NORECORD_OPS) {
    r <- nr[nr$op == op, ]
    if (nrow(r) != 1) next
    check_true("v40", paste(op, "runs with the recorder absent"),
               r$verdict[1] == "ran")
}

# ---------------------------------------------------------------------------
# THE RUN PROVED SOMETHING, which is separate from the run passing.
# ---------------------------------------------------------------------------
# A driver that had somehow loaded the recorder would satisfy every check
# above while testing nothing at all, so the driver refuses out loud and the
# refusal is looked for here rather than assumed absent. Same reason v39
# separates DIDNOTRUN from coverage: a harness that did not do the thing is
# not a plugin fact.
if (!file.exists(log_p)) {
    stop("norecord log not found: ", log_p,
         "\n  Run: bash harness/norecord/run.sh")
}
lg <- readLines(log_p, warn = FALSE)
check_true("v40", "the recorder really was absent from the run",
           !any(grepl("^NORECORD: the recorder was loaded", lg)))
check_true("v40", "the driver reached the end of its list",
           any(grepl(sprintf("^NORECORD DONE nOps=%d$", length(NORECORD_OPS)),
                     lg)))

if (!exists("EML_SUITE")) {
    eml_report("v40 norecord: every operation runs with the recorder absent")
    eml_exit()
}
