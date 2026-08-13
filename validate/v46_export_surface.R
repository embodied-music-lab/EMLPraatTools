# ============================================================================
# v46_export_surface.R -- one fork, one legacy writer, one save-path utility
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. The plugin writes CSV in two formats: the legacy
# single long file (table,analysis,term,term_type,field,value) and broom's
# three-frame shape. Which one an export writes is decided by ONE `if`, on
# whether the analysis declared -- @emlResultBegin sets emlResult_declared.
#
# Until 13 August 2026 that `if` lived INSIDE @emlWrapperExportCSV, so the
# plugin's other export -- the graphs form's post-draw "Exp CSV" button --
# could not reach it and called @emlExportStatsCSV directly. The same analysis
# produced three broom frames from the stats menu and one legacy file from the
# graphs form.
#
# NOTHING COULD HAVE CAUGHT THAT, and the reason is the reason this file is
# static rather than artefact-driven:
#
#   * v20 and v21 enumerate the stats-MENU orchestrators. v21's own words:
#     "every file written by the orchestrator the menu calls." A second
#     exporter reached from the graphs form is outside that enumeration by
#     construction, not by oversight.
#   * coverage.R compares, per artefact, rendered cases against claimed cases.
#     It catches an unclaimed case and even an artefact with no reader. It
#     cannot catch a path that produces NO ARTEFACT AT ALL, and that button
#     had never been pressed by any harness.
#
# So the population that needed checking was never a set of results. It was a
# set of CALL SITES -- which is a property of the source, and is what this
# file reads. Had the migration been scoped this way, eml-graphs-form.praat
# would have appeared on day one: there have only ever been two live callers
# of @emlExportStatsCSV, and one of them was the graphs button.
#
# WHAT IT PINS
#   1. Exactly one live call of the legacy writer, and it is inside the fork.
#   2. Exactly one place reads emlResult_declared to make a decision.
#   3. No export dialog reaches a writer except through @emlExportResultFiles.
#   4. @emlGenerateUniquePath is in core utilities, not the graphs layer --
#      the non-destructive-save promise has to be reachable from every layer
#      that saves, and while it sat in the graphs form the declared arm of the
#      export could not use it.
#
#     Rscript validate/v46_export_surface.R
#
# Input: the plugin source itself. No harness run is required, which is the
#        point -- this is the check that does not wait for someone to press a
#        button. $EML_PLUGIN_DIR overrides the tree read, for break tests.
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

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
if (!dir.exists(plug)) stop("plugin tree not found: ", plug)

# Shipping code only. plugin/dev/ is tests and tooling, and a static ban that
# swept it would be reporting on things that are allowed to be different.
files <- list.files(plug, pattern = "\\.praat$", recursive = TRUE,
                    full.names = TRUE)
files <- files[!grepl("/dev/", files, fixed = TRUE)]
check_true("v46", "the shipping plugin tree was read", length(files) > 20)

.rel <- function(p) sub(paste0("^", plug, "/"), "", p)

# A LINE IS CODE unless it is a Praat comment. Both comment markers, and both
# with leading whitespace -- the export branches are nested five deep, so an
# anchored "^#" would have called every one of them code.
.codelines <- function(path) {
    x <- readLines(path, warn = FALSE)
    data.frame(file = .rel(path), n = seq_along(x), txt = x,
               stringsAsFactors = FALSE)[!grepl("^\\s*[#;]", x), , drop = FALSE]
}
code <- do.call(rbind, lapply(files, .codelines))
check_true("v46", "the tree has code lines to search", nrow(code) > 1000)

.hits <- function(pat) code[grepl(pat, code$txt), , drop = FALSE]
.where <- function(d) if (nrow(d) == 0) "" else
    paste(sprintf("%s:%d", d$file, d$n), collapse = ", ")

# ---------------------------------------------------------------------------
# 1. THE LEGACY WRITER HAS ONE CALLER
# ---------------------------------------------------------------------------
# @emlExportStatsCSV is the old single-file writer. Every export must reach it
# through the fork, never directly, or that export silently writes the old
# format for an analysis the rest of the plugin exports as broom frames.
legacy <- .hits("@emlExportStatsCSV")
check("v46", "the legacy writer is called exactly once", 1L, nrow(legacy),
      tol = 0)
if (nrow(legacy) > 0) {
    check_true("v46",
               sprintf("and that call is in eml-output.praat (%s)",
                       .where(legacy)),
               all(legacy$file == "stats/eml-output.praat"))
}

# AND THE CALL IS INSIDE THE FORK, not merely in the same file. Checked by
# line order against the procedure's own bounds: a call that drifted out of
# @emlExportResultFiles into some other procedure of eml-output.praat would
# satisfy the check above and reintroduce the defect.
out_p <- file.path(plug, "stats", "eml-output.praat")
if (file.exists(out_p)) {
    ol <- readLines(out_p, warn = FALSE)
    start <- grep("^procedure emlExportResultFiles", ol)
    check("v46", "@emlExportResultFiles exists exactly once", 1L, length(start),
          tol = 0)
    if (length(start) == 1) {
        ends <- grep("^endproc", ol)
        stop_at <- ends[ends > start][1]
        inside <- legacy$file == "stats/eml-output.praat" &
                  legacy$n > start & legacy$n < stop_at
        check_true("v46", "the legacy writer is called from inside the fork",
                   nrow(legacy) == 1 && all(inside))
    }
}

# ---------------------------------------------------------------------------
# 2. ONE DECISION POINT
# ---------------------------------------------------------------------------
# emlResult_declared is written in many places -- @emlResultBegin sets it, and
# every orchestrator's entry guard clears it via @emlCSVInit. Those are state
# changes. What must stay singular is the number of places that READ it to
# choose a format, because two readers are two chances to disagree.
decide <- .hits("if\\s+.*emlResult_declared")
check("v46", "exactly one place forks on the declaration", 1L, nrow(decide),
      tol = 0)
if (nrow(decide) > 0) {
    check_true("v46", sprintf("and it is in eml-output.praat (%s)",
                              .where(decide)),
               all(decide$file == "stats/eml-output.praat"))
}

# ---------------------------------------------------------------------------
# 3. NO EXPORT REACHES A WRITER AROUND THE FORK
# ---------------------------------------------------------------------------
# @emlResultWrite is the broom writer. Only the fork may call it in shipping
# code; a dialog that called it directly would write three frames for an
# analysis that never declared, or skip the legacy fallback for one that did.
# (harness/broom_cases calls it and @emlResultWriteTidy directly on purpose --
# that is the batch API, and the harness is not shipping code.)
broom <- .hits("@emlResultWrite:")
check("v46", "the broom writer is called exactly once in shipping code", 1L,
      nrow(broom), tol = 0)
if (nrow(broom) > 0) {
    check_true("v46", sprintf("and it is in eml-output.praat (%s)",
                              .where(broom)),
               all(broom$file == "stats/eml-output.praat"))
}

# THE GRAPHS FORM MUST NOT REACH EITHER WRITER. Named on its own because it is
# the path that actually regressed, and a general check that happened to pass
# for a different reason would not say so.
gf <- code[code$file == "graphs/eml-graphs-form.praat", , drop = FALSE]
check_true("v46", "the graphs form calls no writer directly",
           !any(grepl("@emlExportStatsCSV|@emlResultWrite", gf$txt)))
check_true("v46", "the graphs form exports through the shared fork",
           any(grepl("@emlExportResultFiles", gf$txt)))

# ---------------------------------------------------------------------------
# 4. THE SAVE-PATH UTILITY IS REACHABLE FROM EVERY LAYER
# ---------------------------------------------------------------------------
# @emlGenerateUniquePath is the non-destructive-save promise for every save in
# the plugin. It lived in graphs/eml-graphs-form.praat, which both barrels
# include LAST -- so stats/eml-output.praat could not call it, and the broom
# export shipped unable to protect itself against overwriting a previous one.
# Core utilities is the first include in both barrels. Pinned here so the
# procedure cannot drift back down the include order.
defs <- .hits("^procedure emlGenerateUniquePath")
check("v46", "the save-path utility is defined exactly once", 1L, nrow(defs),
      tol = 0)
if (nrow(defs) == 1) {
    check_true("v46", sprintf("and it lives in core utilities, not a form (%s)",
                              .where(defs)),
               defs$file == "stats/eml-core-utilities.praat")
}
# ITS CALLERS SPAN LAYERS, which is the evidence it was never a graphs-local
# helper: the figure save, the recorded-script save, and the CSV export.
callers <- unique(.hits("@emlGenerateUniquePath:")$file)
check_true("v46", "it is called from more than one layer",
           length(callers) >= 2)
check_true("v46", "including from outside the graphs layer",
           any(!grepl("^graphs/", callers)))

if (!exists("EML_SUITE")) {
    eml_report("v46 export surface: one fork, one writer, one save-path utility")
    eml_exit()
}
