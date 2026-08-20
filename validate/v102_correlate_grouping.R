# ============================================================================
# v102_correlate_grouping.R -- a correlation is never grouped by its own X or Y
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS EXISTS FOR. Praat has to know a menu's options before it can
# draw the page, so the correlation wrapper builds its list of candidate
# grouping columns BEFORE the dialog opens, from the X and Y of the previous
# pass -- and X and Y are chosen on that same page. The list can therefore be
# the wrong list. A column that has just been moved onto X is still on the
# grouping menu, and picking it correlates a variable against itself, split by
# itself.
#
# NOTHING ERRORS WHEN THAT HAPPENS. The analysis runs, the report prints with
# its per-group blocks, and every number in it is an artefact of the grouping.
# That is the same shape as the editor's stale-cell write and the comparison
# menu's stale correction: no crash, no red test, a plausible answer that is
# wrong -- which is the only kind of defect that reaches a user's manuscript.
#
# WHY NEITHER OF THE CHECKS THAT ALREADY READ THIS FILE COULD SEE IT.
# `grpName$ [group_column - 1]` is a correct index into a real array, so the
# source-level checks pass. The wrapper parses with or without the guard, so
# the parse drive passes. The only witness is the order the buttons are
# pressed in and what came out, which is what harness/correlgroup/run.sh does.
#
# WHAT THE HARNESS HANDS OVER, and the two proofs that make it evidence about
# the SHIPPED file rather than about a copy: the wrapper's pause stanzas are
# excised mechanically and the remaining body is hashed against the shipped
# file, and stats/eml-output.praat has its refusal dialog -- and nothing else,
# by the same hash -- replaced with a stub that answers from the tape.
#
# Input: harness/correlgroup/out/. $EML_CORREL_DIR overrides that folder and
# $EML_CORREL_FILE the wrapper, so the break run scores the pre-guard file
# without the working tree being touched.
#
# Base R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v102"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

cd <- Sys.getenv("EML_CORREL_DIR", unset = "")
if (!nzchar(cd)) cd <- repo_path("harness", "correlgroup", "out")

tsvPath <- file.path(cd, "CORREL.tsv")

E <- list()
if (file.exists(tsvPath) && file.info(tsvPath)$size > 0) {
    .x <- read.delim(tsvPath, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE)
    E <- setNames(as.list(trimws(as.character(.x[[2]]))),
                  trimws(as.character(.x[[1]])))
}
es <- function(k) if (is.null(E[[k]])) NA_character_ else E[[k]]

lines_of <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
log_of <- function(case) lines_of(file.path(cd, paste0(case, ".log")))
errdlg <- lines_of(file.path(cd, "EXCISED_ERRDLG.txt"))

trace_of <- function(case) {
    t <- es(paste0(case, "_dlg_trace"))
    if (is.na(t) || !nzchar(t)) character(0) else strsplit(t, ",", fixed = TRUE)[[1]]
}
probe_of <- function(case, kind) {
    g <- grep(paste0("^PROBE\\|", kind, "\\|"), log_of(case), value = TRUE)
    if (length(g) == 0) NA_character_ else g[1]
}
errmsg_of <- function(case) {
    g <- grep("^ERRMSG\\|", log_of(case), value = TRUE)
    if (length(g) == 0) NA_character_ else sub("^ERRMSG\\|", "", g[1])
}
num <- function(k) suppressWarnings(as.numeric(es(k)))

CASES <- c("G_stale", "H_legit", "K_movedok")

# ---------------------------------------------------------------------------
# 1. THE TWIN IS THE WRAPPER, AND THE LIBRARY IS THE LIBRARY
# ---------------------------------------------------------------------------
# FIRST, AND UNCONDITIONALLY. Everything below is a statement about the
# shipped files only while the thing that ran was those files with their
# dialogs answered and nothing else changed. Two hashes, because two files
# were touched, and a green suite over a modified library would be a lie of
# exactly the kind this directory exists to prevent.
check_true(V, "the drive ran to completion", identical(es("completed"), "1"))
check_true(V, sprintf("the drive used the target Praat (%s)",
                      es("praat_version")),
           grepl("^Praat 6\\.6\\.30", es("praat_version")))
check_true(V, "the wrapper's body is byte-identical to the shipped wrapper's",
           identical(es("twin_body_identical"), "1"))
check_true(V,
           "eml-output.praat outside the replaced refusal is byte-identical to shipped",
           identical(es("errdlg_body_identical"), "1"))
check_true(V, "the wrapper still has both of its dialogs",
           identical(es("stanza_1_key"), "correlate_two_columns#1") &&
           identical(es("stanza_2_key"), "analysis_complete#1"))

# THE REPLACED PROCEDURE IS SHOWN, NOT JUST NAMED. A reader has to be able to
# see that what went was a dialog. It is also the record of WHY the whole
# procedure had to go rather than one region: two endPause lines, one per
# mode, inside a conditional -- the shape that defeats stanza excision.
check_true(V, "the replaced refusal dialog is on the record",
           length(errdlg) > 0 &&
           any(grepl("^procedure emlErrorDialog: ", errdlg)))
check_true(V,
           "it is the two-exit shape that cannot be cut as a stanza",
           sum(grepl("endPause", errdlg)) == 2)

# ---------------------------------------------------------------------------
# 2. EVERY CASE RAN AND CAME BACK
# ---------------------------------------------------------------------------
for (cs in CASES) {
    check_true(V, sprintf("%s: the wrapper exited cleanly (not an abort)", cs),
               identical(es(paste0(cs, "_exit")), "0"))
    check_true(V, sprintf("%s: control returned from the wrapper", cs),
               identical(es(paste0(cs, "_returned")), "1"))
    check_true(V, sprintf("%s: no Praat error was raised", cs),
               !nzchar(es(paste0(cs, "_stderr_head"))) ||
               is.na(es(paste0(cs, "_stderr_head"))))
}

# ---------------------------------------------------------------------------
# 3. THE DEFECT ITSELF
# ---------------------------------------------------------------------------
# G_stale runs once on x against y -- which puts "dose" and "site" on the
# grouping menu, because neither is bound -- presses New, moves X onto "dose",
# and picks "dose" as the grouping column. The menu is still offering it.
#
# The first probe proves the offer was real: a check that asserted only "the
# guard fired" would pass on a build where the menu never offered the column
# at all, which is a different plugin, not a fixed one.
check_true(V, "G_stale: the grouping menu did offer the column before the move",
           identical(probe_of("G_stale", "list2"),
                     "PROBE|list2|n=2|1=dose|2=site"))
check_true(V, "G_stale: the refusal was raised",
           identical(es("G_stale_errmsgs"), "1"))
check_true(V, "G_stale: it appears between the two visits to the form, not after them",
           identical(trace_of("G_stale"),
                     c("correlate_two_columns#1", "analysis_complete#1",
                       "correlate_two_columns#1", "errdlg",
                       "correlate_two_columns#1")))

# THE HARM, MEASURED WHERE IT WOULD LAND. Not "the guard ran" but "no grouped
# correlation was computed": the pre-guard wrapper reaches here with a
# per-group block headed by the very column it is correlating.
check_true(V, "G_stale: no grouped analysis was run",
           identical(es("G_stale_grouped_blocks"), "0") &&
           !nzchar(es("G_stale_grouped_by")))
check_true(V,
           "G_stale: only the first, legitimate run printed a report at all",
           identical(es("G_stale_reports"), "1"))

# AND THE PROMISE THE REFUSAL MAKES IS KEPT. "Click Back and the list will be
# rebuilt" is checked by reading the list on the way back: with X now "dose",
# "dose" is gone and "site" is what remains.
check_true(V, "G_stale: coming back rebuilt the list against the new X and Y",
           identical(probe_of("G_stale", "list3"), "PROBE|list3|n=1|1=site"))

# ---------------------------------------------------------------------------
# 4. THE REFUSAL SAYS ENOUGH TO ACT ON
# ---------------------------------------------------------------------------
# The plugin's standard, from the editor's refusals: name the thing, say what
# happened to the user's work, say what to do next. A refusal that says only
# "cannot do that" sends the user round the plugin with a spreadsheet.
msg <- errmsg_of("G_stale")
check_true(V, "the refusal names the column it is refusing",
           !is.na(msg) && grepl('"dose"', msg, fixed = TRUE))
check_true(V, "it says plainly that nothing was run",
           !is.na(msg) && grepl("Nothing was run", msg, fixed = TRUE))
check_true(V, "it says why the offer was there in the first place",
           !is.na(msg) && grepl("built before you changed X and Y", msg,
                                fixed = TRUE))
check_true(V, "it says what to do next",
           !is.na(msg) && grepl("click Back", msg, fixed = TRUE))

# ---------------------------------------------------------------------------
# 5. THE GUARD DOES NOT OVER-REFUSE
# ---------------------------------------------------------------------------
# A guard that charged every change of X a press would be paid for on every
# analysis anyone runs, and would be removed within the week. H_legit groups
# by the same column without moving X onto it. K_movedok moves X onto "dose"
# -- the exact motion G_stale makes -- while grouping by "site", which stays
# legal. Both must run on the first press with no refusal in the trace.
check_true(V, "H_legit: the ordinary grouped run still works",
           identical(es("H_legit_grouped_blocks"), "1") &&
           identical(es("H_legit_grouped_by"), "dose"))
check_true(V, "H_legit: no refusal was raised",
           identical(es("H_legit_errmsgs"), "0") &&
           !("errdlg" %in% trace_of("H_legit")))
check_true(V,
           "K_movedok: moving X is fine when the grouping column is not the column moved to",
           identical(es("K_movedok_grouped_blocks"), "1") &&
           identical(es("K_movedok_grouped_by"), "site"))
check_true(V, "K_movedok: no refusal was raised, and no extra press was charged",
           identical(es("K_movedok_errmsgs"), "0") &&
           !("errdlg" %in% trace_of("K_movedok")) &&
           length(trace_of("K_movedok")) == 4)

# ---------------------------------------------------------------------------
# COVERAGE
# ---------------------------------------------------------------------------
# Every case the driver ran is asserted on by something above. A case added to
# run.sh and forgotten here is a drive producing evidence nothing reads.
present <- sub("_exit$", "", grep("_exit$", names(E), value = TRUE))
eml_census(V, "correlation drive case", present, CASES)

if (!exists("EML_SUITE"))
    eml_report("v102 correlation grouping: the grouping column is never X or Y")
