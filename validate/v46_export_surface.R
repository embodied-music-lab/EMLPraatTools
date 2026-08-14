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
#   5. @emlWrapperExportCSV is neither called nor DEFINED. It was deleted on
#      14 Aug 2026; the reasoning for pinning its absence rather than only its
#      disuse is written out at the check itself.
#   6. The panel's folder seed, emlLastCSVFolder$, is set at file scope and
#      not from inside any procedure -- the fact that survives the deletion.
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
# ONE FILE MAY BRANCH ON MIGRATION STATE, and it is the file that owns the
# writers. The count of reads is deliberately NOT pinned: since the save panel
# landed there are three, and two of them ask a different question -- "is
# there anything to offer the user" rather than "which format do I write".
# Pinning the count would have failed on a refactor that changed nothing about
# the invariant, and the temptation would then be to relax it into uselessness.
# What must stay true is that no OTHER file decides, because a second decider
# is a second chance to disagree.
# BRANCH-SHAPED READS ONLY. The bare name also matches the WRITES -- the set
# in @emlResultBegin and the clears in @emlCSVInit -- and those are state
# changes, not decisions. Broadening the pattern to catch the panel's reads
# swept in eml-result-writer.praat:187 and failed on a line that is doing
# exactly what it should.
decide <- .hits("if\\s+.*emlResult_declared")
check_true("v46", "something still branches on the declaration",
           nrow(decide) > 0)
check_true("v46",
           sprintf("only eml-output.praat branches on migration state (%s)",
                   .where(decide[decide$file != "stats/eml-output.praat", ,
                                 drop = FALSE])),
           all(decide$file == "stats/eml-output.praat"))

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
# THE GRAPHS FORM EXPORTS THROUGH THE PANEL, which exports through the fork.
# It called @emlExportResultFiles directly until the save panel landed on
# 13 Aug 2026; now one Save writes the figure, the result frames and the Info
# report under one folder and one stem, and the panel is the only thing that
# needs to know how each is written.
check_true("v46", "the graphs form saves through the shared panel",
           any(grepl("@emlSavePanel", gf$txt)))
panel <- code[code$file == "stats/eml-output.praat", , drop = FALSE]
check_true("v46", "and the panel exports through the fork",
           any(grepl("@emlExportResultFiles", panel$txt)))

# EVERY SAVE JOURNEY IN THE PLUGIN IS THE PANEL. Nine stats wrappers and the
# wizard used to carry their own CSV button calling @emlWrapperExportCSV,
# which wrote the numbers only and remembered its own folder. If any of them
# reverts, the outputs of one analysis scatter again.
wrappers <- code[grepl("^scripts/", code$file), , drop = FALSE]
check_true("v46", "no shipping script calls the superseded CSV export",
           !any(grepl("@emlWrapperExportCSV", wrappers$txt)))

# ---------------------------------------------------------------------------
# THE SUPERSEDED EXPORT IS GONE, NOT MERELY UNCALLED
# ---------------------------------------------------------------------------
# @emlWrapperExportCSV was deleted from stats/eml-output.praat on 14 August
# 2026 (author ruling: "We can retire the superseded csv wrapper code if we
# use it nowhere now"). That raises a question about the call-site check
# directly above, and the answer is that it STAYS AND IS JOINED, not replaced.
#
# WHY THE CALL-SITE CHECK STAYS. Two reasons, and neither is sentiment.
#   * v48's header cites this file for exactly that claim -- "no longer names
#     the superseded @emlWrapperExportCSV" -- and a check another validator
#     describes in prose should not quietly stop existing.
#   * The way a wrapper reverts is by someone pasting an old post-analysis
#     block back in, and that paste brings the call whether or not the
#     procedure survived. Deleting the check would move that catch onto
#     harness/check_includes.py, which is a different tool run at a different
#     time. Cheap check, real population, keep it.
#
# WHY IT IS NO LONGER THE LOAD-BEARING ONE, which is the honest part. The
# defect this check was built for was SILENT DIVERGENCE: a wrapper reaching
# the old procedure wrote numbers only, into its own remembered folder, under
# its own naming, while every other path wrote a set. That failure needed the
# procedure to EXIST. With the definition gone, a reintroduced call is a loud
# "Procedure not found" the instant Run is clicked -- bad, but not silent, and
# not this file's kind of bug. So the invariant worth pinning moved: it is now
# the ABSENCE OF THE DEFINITION, because that is the thing whose return would
# make a stray call dangerous again instead of merely broken.
#
# AND THERE IS PRECEDENT FOR A CALLERLESS DEFINITION BEING HARMFUL. Between
# 13 and 14 August the procedure sat in the tree with no callers and looked
# inert. It was not: the ONLY seed of emlLastCSVFolder$ was inside it, so the
# panel that superseded it inherited a variable nothing set, and all nine
# non-graphing Save buttons died on "Unknown variable" before the panel drew.
# A dead procedure holding live shared state is the specific way this went
# wrong once, which is why "it has no callers" is not accepted as safe here.
defn <- .hits("^\\s*procedure\\s+emlWrapperExportCSV\\b")
check("v46", "the superseded CSV export is defined nowhere in shipping code",
      0L, nrow(defn), tol = 0)

# THE FOLDER SEED IS AT FILE SCOPE. The corollary of the above, and the one
# fact the deletion had to preserve. emlLastCSVFolder$ is the folder every
# non-graphing save proposes; it is seeded once when the barrel loads, by a
# top-level line in the file that defines the panel. Praat evaluates a
# procedure's arguments BEFORE entering it, so a seed that lives inside any
# procedure cannot be relied on by a caller that passes the variable in -- the
# exact shape of the 13 August outage. Checked structurally rather than by
# indentation: the seed line must fall outside every procedure/endproc pair.
# This is the check that would have caught that outage without a display;
# v48 catches it too, but only after someone runs harness/savepaths.
panel_all <- code[code$file == "stats/eml-output.praat", , drop = FALSE]
depth <- cumsum(grepl("^\\s*procedure\\s", panel_all$txt)) -
         cumsum(grepl("^\\s*endproc\\s*$", panel_all$txt))
check_true("v46", "procedure/endproc pairing in eml-output.praat is well formed",
           max(depth) == 1 && min(depth) == 0 &&
           depth[length(depth)] == 0)
seed <- grepl("variableExists\\s*\\(\\s*\"emlLastCSVFolder\\$\"\\s*\\)",
              panel_all$txt)
check_true("v46", "the panel's folder seed exists", any(seed))
check_true("v46",
           sprintf("and it is seeded at file scope, not inside a procedure (%s)",
                   paste(sprintf("stats/eml-output.praat:%d",
                                 panel_all$n[seed]), collapse = ", ")),
           any(seed) && all(depth[seed] == 0))

savers <- unique(wrappers$file[grepl("@emlSavePanel", wrappers$txt)])
check_true("v46", sprintf("the wrappers save through the panel (%d of them)",
                          length(savers)),
           length(savers) >= 9)

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
