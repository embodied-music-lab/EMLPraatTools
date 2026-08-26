# ============================================================================
# v137_correlation_scope.R -- the scatter page's display-scope control,
# ruled into 1.0 (punch list item 8.3)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS FIXES, measured by the door census (WORK_ORDER_DOOR_CENSUS
# leg 6 / harness/doorcensus/fixtures/leg6_correlation_scope.csv, Sol's
# Simpson-for-correlation exhibit): on a fixture where each of groups A and
# B correlates at r ~ +0.999 and the pooled data correlates at r ~ -0.561,
# the correlate dialog reports overall AND per-group (labelled), the
# regression dialog reports overall only, and the scatter's own annotation
# block drew per-group only -- with no line on the figure saying which
# model a reader was looking at, and no way to get the pooled model onto
# the figure at all. LANGUAGE_BATCH_2026-08-25.md item 15 rules the fix: a
# three-way "Relationships shown" control (Per group / Overall / Both, each
# line labeled) on the scatter page's Analysis group, replacing the interim
# "this figure shows per-group only" disclosure line that item 15 also
# specifies -- confirmed absent from the tree before this item (grep, no
# hit anywhere in *.praat), so there was nothing to remove; this control is
# what item 15's disclosure clause was standing in for.
#
# WHAT SHIPPED: a new global, scatterCorrScope (1 = Per group, 2 = Overall,
# 3 = Both), written by the form's new "Relationships shown" field
# (graphs/eml-graphs-form.praat, shown only when a grouping column is in
# use -- RULING_DIALOG_COMPACTION section 1, the same "field that cannot be
# discarded" pattern the existing group fields already use) and read
# directly by @emlDrawScatterPlot's grouped path
# (graphs/eml-draw-procedures.praat), which now buffers an "Overall" block
# -- the pooled correlation/regression, computed from the SAME .xData#/
# .yData# the ungrouped path would use, on exactly the rows @emlDrawScatterPlot
# itself accepted as clean -- into the very same all-or-none 20-line
# annotation budget the per-group lines already share. The per-group loop
# is gated on scope <> 2 (Overall only means no per-group line); the pooled
# block is gated on scope <> 1 (Per group only means no Overall line). Both
# read and drawn lines carry their label ("A: ...", "B: ...",
# "Overall: ..."), so a reader moving between scopes on the SAME figure
# cannot mistake one model's number for another's.
#
# WHAT THIS FILE READS:
#   - harness/corrscope/out/CORRSCOPE.tsv, written by
#     harness/corrscope/probe.praat, which calls @emlDrawScatterPlot
#     DIRECTLY (no dialog) three times -- once per scope -- on the leg6
#     fixture, and records exactly what landed in the annotation block.
#   - harness/corrscope/out/CORRSCOPE_RED.tsv, written by the SAME probe
#     against plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat as it
#     stood at git HEAD (harness/corrscope/run.sh --red) -- the state
#     before this item, where scatterCorrScope does not exist and setting
#     it is inert. Section 0 demonstrates that pre-fix run is RED: all
#     three scopes draw the identical two-line, per-group-only content,
#     which is exactly the "three-way control that only ever shows one
#     thing" defect item 8.3 exists to close. Run
#     `bash harness/corrscope/run.sh --red` to regenerate it; it is
#     committed so this claim does not rest on a run nobody can repeat.
#
# THE ORACLE, section 1: base R's own cor.test() (Pearson), per group and
# pooled, on the identical fixture -- literal vectors matching
# harness/doorcensus/fixtures/leg6_correlation_scope.csv exactly (this file
# does not read the CSV; both this file and the probe copy its numbers
# independently, the same double-entry discipline v127 and v136 use for
# their own fixtures).
#
# Base R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v137"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

read_tsv_kv <- function(path) {
    if (!file.exists(path) || file.info(path)$size == 0) return(list())
    x <- read.delim(path, header = TRUE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE)
    setNames(as.list(as.character(x$value)), x$key)
}

green_path <- Sys.getenv("EML_CORRSCOPE_OUT", unset = "")
if (!nzchar(green_path)) green_path <- repo_path("harness", "corrscope", "out", "CORRSCOPE.tsv")
red_path <- repo_path("harness", "corrscope", "out", "CORRSCOPE_RED.tsv")

G <- read_tsv_kv(green_path)
R <- read_tsv_kv(red_path)
gv <- function(k) if (is.null(G[[k]])) NA_character_ else G[[k]]
rv <- function(k) if (is.null(R[[k]])) NA_character_ else R[[k]]

check_true(V, "the GREEN probe ran to completion (harness/corrscope/run.sh)",
           identical(gv("completed"), "1"))

# ---------------------------------------------------------------------------
# 0. THE RED DEMONSTRATION -- committed, reusable, re-derivable with
#    `bash harness/corrscope/run.sh --red`. Pre-fix, every scope drew the
#    identical per-group-only content: the three-way control existed on
#    paper and nowhere in the drawn figure.
# ---------------------------------------------------------------------------
if (!identical(rv("completed"), "1")) {
    check_true(V, paste0("CORRSCOPE_RED.tsv is missing or incomplete",
                         "\n  Run: bash harness/corrscope/run.sh --red"), FALSE)
} else {
    check_true(V, "RED (pre-fix, HEAD): scope=Overall drew the SAME 2 lines as scope=Per group -- 'Overall' never appeared",
               identical(rv("scope_overall_n_lines"), "2") &&
                   identical(rv("scope_overall_line_1"), rv("scope_pergroup_line_1")) &&
                   identical(rv("scope_overall_line_2"), rv("scope_pergroup_line_2")))
    check_true(V, "RED (pre-fix, HEAD): scope=Both drew the SAME 2 lines too -- no third, no 'Overall' label anywhere",
               identical(rv("scope_both_n_lines"), "2") &&
                   identical(rv("scope_both_line_1"), rv("scope_pergroup_line_1")) &&
                   identical(rv("scope_both_line_2"), rv("scope_pergroup_line_2")))
}

# ---------------------------------------------------------------------------
# 1. THE ORACLE -- base R's cor.test(), per group and pooled, on the exact
#    fixture (harness/doorcensus/fixtures/leg6_correlation_scope.csv).
# ---------------------------------------------------------------------------
xA <- c(1, 2, 3, 4, 5, 6, 7, 8)
yA <- c(7.20, 8.90, 11.15, 12.80, 15.10, 16.85, 19.20, 20.90)
xB <- c(11, 12, 13, 14, 15, 16, 17, 18)
yB <- c(-7.80, -6.10, -3.85, -2.20, 0.10, 1.85, 4.20, 5.90)
xAll <- c(xA, xB); yAll <- c(yA, yB)

caA <- cor.test(xA, yA, method = "pearson")
caB <- cor.test(xB, yB, method = "pearson")
caPooled <- cor.test(xAll, yAll, method = "pearson")

check_true(V,
           sprintf("the fixture is ADVERSARIAL (Simpson-for-correlation): r_A = %+.4f, r_B = %+.4f, r_pooled = %+.4f",
                   unname(caA$estimate), unname(caB$estimate), unname(caPooled$estimate)),
           unname(caA$estimate) > 0.99 && unname(caB$estimate) > 0.99 &&
               unname(caPooled$estimate) < -0.4)

# Parse a drawn annotation line of the shape "<label>: r = <r>, <pcode>"
# where <pcode> is either "p < .NNN" or "p = .NNN" (@emlFormatAnnotLabel's
# own "p-value" style, three decimals, no leading zero -- the same format
# @emlFormatP uses elsewhere in this tree).
parse_line <- function(line) {
    if (is.na(line)) return(list(label = NA_character_, r = NA_real_))
    m <- regmatches(line, regexec("^([^:]+): r = (-?[0-9]\\.[0-9]{3}),", line))
    if (length(m[[1]]) < 3) return(list(label = NA_character_, r = NA_real_))
    list(label = m[[1]][2], r = as.numeric(m[[1]][3]))
}
r3 <- function(x) round(x, 3)

# ---------------------------------------------------------------------------
# 2. GREEN, scope = Per group (1): exactly A and B, no Overall, each r
#    matching cor.test() to 3 decimals -- the format the annotation itself
#    prints at (fixed$ (.,3)), so this is the tightest tolerance that means
#    anything.
# ---------------------------------------------------------------------------
check_true(V, "scope=Per group draws exactly 2 lines", identical(gv("scope_pergroup_n_lines"), "2"))
pg1 <- parse_line(gv("scope_pergroup_line_1"))
pg2 <- parse_line(gv("scope_pergroup_line_2"))
check_true(V, sprintf("scope=Per group, line 1 is labelled 'A' (got '%s')", pg1$label),
           identical(pg1$label, "A"))
check_true(V, sprintf("scope=Per group, line 2 is labelled 'B' (got '%s')", pg2$label),
           identical(pg2$label, "B"))
check(V, "scope=Per group, group A r vs cor.test(xA, yA)", pg1$r, r3(unname(caA$estimate)), tol = 1e-9)
check(V, "scope=Per group, group B r vs cor.test(xB, yB)", pg2$r, r3(unname(caB$estimate)), tol = 1e-9)
check_true(V, "scope=Per group draws NO 'Overall' line",
           !grepl("^Overall:", gv("scope_pergroup_line_1")) &&
               !grepl("^Overall:", gv("scope_pergroup_line_2")))

# ---------------------------------------------------------------------------
# 3. GREEN, scope = Overall (2): exactly one line, "Overall", matching
#    cor.test() on the POOLED data -- and NEITHER group line present. This
#    is the capability item 8.3 adds; it did not exist before this item
#    (section 0).
# ---------------------------------------------------------------------------
check_true(V, "scope=Overall draws exactly 1 line", identical(gv("scope_overall_n_lines"), "1"))
ov1 <- parse_line(gv("scope_overall_line_1"))
check_true(V, sprintf("scope=Overall, the one line is labelled 'Overall' (got '%s')", ov1$label),
           identical(ov1$label, "Overall"))
check(V, "scope=Overall, r vs cor.test(pooled)", ov1$r, r3(unname(caPooled$estimate)), tol = 1e-9)
check_true(V, "scope=Overall draws NO per-group line ('A' or 'B')",
           !grepl("^A:", gv("scope_overall_line_1")) && !grepl("^B:", gv("scope_overall_line_1")))
check_true(V,
           sprintf("scope=Overall's r (%.3f) is the OPPOSITE sign of scope=Per group's (A = %.3f, B = %.3f) -- the exact reader-facing confusion item 8.3 closes",
                   ov1$r, pg1$r, pg2$r),
           ov1$r < 0 && pg1$r > 0 && pg2$r > 0)

# ---------------------------------------------------------------------------
# 4. GREEN, scope = Both (3): all three lines, each independently matching
#    its own oracle -- the figure that shows a reader all three models at
#    once, each labeled with the model it represents.
# ---------------------------------------------------------------------------
check_true(V, "scope=Both draws exactly 3 lines", identical(gv("scope_both_n_lines"), "3"))
bo1 <- parse_line(gv("scope_both_line_1"))
bo2 <- parse_line(gv("scope_both_line_2"))
bo3 <- parse_line(gv("scope_both_line_3"))
check_true(V, "scope=Both: line labels are exactly A, B, Overall, in that order",
           identical(c(bo1$label, bo2$label, bo3$label), c("A", "B", "Overall")))
check(V, "scope=Both, group A r vs cor.test(xA, yA)", bo1$r, r3(unname(caA$estimate)), tol = 1e-9)
check(V, "scope=Both, group B r vs cor.test(xB, yB)", bo2$r, r3(unname(caB$estimate)), tol = 1e-9)
check(V, "scope=Both, Overall r vs cor.test(pooled)", bo3$r, r3(unname(caPooled$estimate)), tol = 1e-9)

# ---------------------------------------------------------------------------
# 5. STRUCTURAL -- the field exists, is guarded to the branch that renders
#    it, and the interim disclosure line item 15 specified is confirmed
#    absent (nothing to remove; this control is what it was standing in
#    for). A grep-based check, so it reads the shipped source directly
#    rather than trusting this file's own account of it.
# ---------------------------------------------------------------------------
form_path <- file.path(PLUGIN_DIR <- repo_path("plugin_EML_StatsGraphs"),
                        "graphs", "eml-graphs-form.praat")
draw_path <- file.path(PLUGIN_DIR, "graphs", "eml-draw-procedures.praat")
form_src <- if (file.exists(form_path)) readLines(form_path, warn = FALSE) else character(0)
draw_src <- if (file.exists(draw_path)) readLines(draw_path, warn = FALSE) else character(0)

check_true(V, "the form declares the 'Relationships shown' field, verbatim (language batch item 15)",
           any(grepl('optionmenu:\\s*"Relationships shown"', form_src)))
check_true(V, "its three options are the batch's wording, verbatim, in order",
           {
               idx <- which(grepl('optionmenu:\\s*"Relationships shown"', form_src))
               if (length(idx) != 1) FALSE else {
                   opts <- form_src[(idx[1] + 1):(idx[1] + 3)]
                   identical(trimws(gsub('^option:\\s*"|"$', '', trimws(opts))),
                             c("Per group", "Overall", "Both, each line labeled"))
               }
           })
check_true(V, "the field is guarded to scatterGroupShown = 1 (RULING_DIALOG_COMPACTION 1: not there to discard)",
           any(grepl("scatterGroupShown = 1", form_src) &
               c(FALSE, grepl('optionmenu:\\s*"Relationships shown"', form_src)[-1])) ||
               {
                   idx <- which(grepl('optionmenu:\\s*"Relationships shown"', form_src))
                   length(idx) == 1 && any(grepl("if scatterGroupShown = 1", form_src[max(1, idx - 3):idx]))
               })
check_true(V, "the interim 'shows per-group only' disclosure (item 15) is absent -- this control replaces it, nothing to remove",
           !any(grepl("shows per-group relationships only|per-group only", c(form_src, draw_src), ignore.case = TRUE)))
check_true(V, "the drawing layer reads scatterCorrScope (the field's target global)",
           any(grepl("scatterCorrScope", draw_src)))

if (!exists("EML_SUITE")) {
    eml_report("v137 -- scatter's grouped-correlation scope control, ruled into 1.0 (punch-list 8.3)")
    eml_exit()
}
