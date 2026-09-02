# ============================================================================
# v135 -- punch list 9.1: the four hand fixes, error propagation
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# docs/ERROR_CENSUS_2026-08-25.md named four confirmed sites where a failure
# produced wrong output rather than a disclosed refusal. Punch list 9.1 rules
# all four fixed before the tag. This file reads the committed red/green
# captures for each -- never re-derives the plugin's numbers itself, per
# "author is never verifier" -- and asserts the fix, PLUS pins the pre-fix
# capture to the exact wrong text it used to print, so a regression that
# brought either behaviour back is caught by name, not by absence.
#
#   SITE 1  @emlRequireNumericColumn (stats/eml-inferential.praat) reported
#           success on a column that does not exist. Driven directly (no
#           @emlRequireColumnPresent shadow ahead of it -- the shadow is
#           exactly why the hole went unnoticed in shipped chains).
#           Evidence: harness/errorprop91/out/{red,green}/report.txt.
#
#   SITE 2  The pairwise Cohen's d matrix a no-post-hoc ANOVA prints kept a
#           failed pair at its zero## default -- "0.000", indistinguishable
#           from a true zero effect. Driven with two zero-variance groups
#           (pooled SD zero -> @emlCohenD refuses that one pair) beside a
#           third group with real spread. Same evidence file; the fix also
#           touches graphs/eml-annotation-procedures.praat's own copy of the
#           loop, exercised in the same call.
#
#   SITE 3  The standalone normality checker's per-group branch
#           (scripts/eml-check-normality.praat) printed Shapiro-Wilk's W and
#           p unconditionally; on a zero-range group (all values identical)
#           they are undefined and printed literally as "--undefined--" / #           "undefined" instead of the producer's own error text. Driven
#           through a real GUI instance (this branch opens a beginPause
#           dialog, which `praat --run` cannot do at all -- see
#           harness/normality/site3_drive.sh). Evidence:
#           harness/normality/out/site3/{red,green}.txt.
#
#   SITE 4  Paired "both" mode drops a single-arm failure silently: the
#           reporter guards each block on its own error$ and prints nothing
#           when one is empty. Driven with a constant nonzero difference
#           (paired t-test refuses -- zero variance in the differences --
#           while Wilcoxon signed-rank still computes). Same evidence file
#           as sites 1 and 2.
#
# The KW/rank-biserial matrix in @emlRunKruskalWallisAnalysis and its
# graphs/eml-annotation-procedures.praat twin get the IDENTICAL mechanical
# fix (section 5 below) but are not driven: @emlKruskalWallis itself refuses
# outright when any group has 0 observations ("Group ""X"" has 0
# observations. Every group needs at least 1.", stats/eml-inferential.praat)
# before the post-hoc loop ever runs, and @emlRankBiserialR (which only ever
# fails via a 0-observation Mann-Whitney arm) cannot be handed a failing pair
# on data a user could actually have while that guard stands. This is the
# "provably-cannot-fail" adjudication the census's own disposition names
# (docs/ERROR_CENSUS_2026-08-25.md, "33 provably cannot fail on their path"),
# stated here rather than left as an unfixed error, per lane 9.4's rule that
# every adjudication carries its reason. Section 5 asserts the fix
# structurally -- same idiom v126 uses for its wizard member, which also has
# no drive: the SHAPE of the fix, in both files, mirrors the driven ANOVA
# fix exactly.
#
# Base R only.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V <- "v135"

rd <- function(...) {
    p <- repo_path(...)
    if (!file.exists(p)) return(NA_character_)
    paste(readLines(p, warn = FALSE), collapse = "\n")
}

# ---------------------------------------------------------------------------
# 1-2-4. harness/errorprop91 -- one driven capture carries all three, red
# and green. Both files must exist: an absent capture is not "nothing to
# check", it is the demonstration never having been run.
# ---------------------------------------------------------------------------
red  <- rd("harness", "errorprop91", "out", "red",   "report.txt")
green <- rd("harness", "errorprop91", "out", "green", "report.txt")

check_true(V, "errorprop91 RED capture exists (harness/errorprop91/out/red/report.txt)",
           !is.na(red))
check_true(V, "errorprop91 GREEN capture exists (harness/errorprop91/out/green/report.txt)",
           !is.na(green))

if (!is.na(red) && !is.na(green)) {

    # --- SITE 1 ---------------------------------------------------------
    check_true(V, "SITE1 red: emlRequireNumericColumn reports success (error=[]) on a missing column, strict=0",
               grepl("strict=0 error=\\[\\]", red, fixed = FALSE))
    check_true(V, "SITE1 red: same false success at strict=1",
               grepl("strict=1 error=\\[\\]", red, fixed = FALSE))
    check_true(V, "SITE1 green: strict=0 now refuses, naming the column",
               grepl("strict=0 error=[Column not found: y]", green, fixed = TRUE))
    check_true(V, "SITE1 green: strict=1 refuses the same way",
               grepl("strict=1 error=[Column not found: y]", green, fixed = TRUE))

    # --- SITE 2 -----------------------------------------------------------
    # The A-flat/B-flat cell of the printed Cohen's d matrix. Row "A flat"
    # then "B flat" is column 2 of that row in the fixed-width grid; matched
    # as a substring so the exact column padding is not this check's business.
    check_true(V, "SITE2 red: the failed A-flat/B-flat pair prints as a bare zero (0.000), not distinguishable from a true zero effect",
               grepl("A flat        ---         0.000", red, fixed = TRUE))
    check_true(V, "SITE2 green: the same pair now prints n/a",
               grepl("A flat        ---         n/a", green, fixed = TRUE))
    # The pair's OWN failure is real (pooled SD is exactly zero -- both
    # groups are exactly constant), and Praat's own arithmetic agrees:
    # oracled independently in R below, not read back from the plugin.
    a <- c(5, 5, 5); b <- c(8, 8, 8)
    pooled_var <- ((length(a) - 1) * var(a) + (length(b) - 1) * var(b)) /
                  (length(a) + length(b) - 2)
    check_true(V, "SITE2 oracle: A-flat/B-flat pooled variance is exactly 0 (R agrees this pair cannot yield a Cohen's d)",
               pooled_var == 0)
    # A real pair (A vs C) must still print its actual number, in both
    # captures identically -- the fix touches only the FAILED cell.
    c_y <- c(10, 14, 9, 12, 11)
    pooled_ac <- sqrt(((length(a) - 1) * var(a) + (length(c_y) - 1) * var(c_y)) /
                       (length(a) + length(c_y) - 2))
    d_ac <- (mean(a) - mean(c_y)) / pooled_ac
    check_true(V, "SITE2 oracle: the A-flat/C-spread cell (a REAL pair) prints Cohen's d agreeing with R to 3 decimals, green capture",
               grepl(sprintf("%.3f", d_ac), green, fixed = TRUE))
    check_true(V, "SITE2: the same real pair's value is untouched by the fix (identical in red and green)",
               grepl(sprintf("%.3f", d_ac), red, fixed = TRUE))

    # --- SITE 4 -------------------------------------------------------
    disclosure <- "Parametric results omitted — Paired t-test failed: All differences are identical (zero variance)"
    check_true(V, "SITE4 red: single-arm failure (parametric) in both-mode paired test is NOT disclosed",
               !grepl(disclosure, red, fixed = TRUE))
    check_true(V, "SITE4 green: the same failure now discloses, in the two-group report's own wording",
               grepl(disclosure, green, fixed = TRUE))
    # The arm that succeeded must still print its own result in BOTH
    # captures -- the fix adds a note, it does not touch the working arm.
    check_true(V, "SITE4: Wilcoxon (the arm that succeeded) still reports its own p in red",
               grepl("Wilcoxon Signed-Rank", red, fixed = TRUE))
    check_true(V, "SITE4: same in green",
               grepl("Wilcoxon Signed-Rank", green, fixed = TRUE))
}

# ---------------------------------------------------------------------------
# 3. harness/normality/site3_drive.sh -- GUI-driven, per-group Shapiro-Wilk
# ---------------------------------------------------------------------------
red3   <- rd("harness", "normality", "out", "site3", "red.txt")
green3 <- rd("harness", "normality", "out", "site3", "green.txt")

check_true(V, "SITE3 RED capture exists (harness/normality/out/site3/red.txt)",
           !is.na(red3))
check_true(V, "SITE3 GREEN capture exists (harness/normality/out/site3/green.txt)",
           !is.na(green3))

if (!is.na(red3) && !is.na(green3)) {
    check_true(V, "SITE3 red: a zero-range group prints undefined statistics (\"W = --undefined--\")",
               grepl("W = --undefined--", red3, fixed = TRUE))
    check_true(V, "SITE3 red: ...and \"p = undefined\", not the producer's own error text",
               grepl("p = undefined", red3, fixed = TRUE))
    check_true(V, "SITE3 green: the producer's own error text prints instead",
               grepl("Shapiro-Wilk: All values identical (zero range)", green3, fixed = TRUE))
    check_true(V, "SITE3 green: the undefined W/p line is gone",
               !grepl("W = --undefined--", green3, fixed = TRUE))
}

# ---------------------------------------------------------------------------
# 5. THE KW/RANK-BISERIAL SIBLING -- structural, not driven (see header).
# Same shape as the driven ANOVA fix, in both files, plus the standing
# guard that makes the real path unreachable, named rather than assumed.
# ---------------------------------------------------------------------------
inf_src <- {
    p <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-inferential.praat")
    if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
}
an_src <- {
    p <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-analysis.praat")
    if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
}
gp_src <- {
    p <- repo_path("plugin_EML_StatsGraphs", "graphs", "eml-annotation-procedures.praat")
    if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
}

check_true(V, "RESOLVER: source files for the structural check were found (non-empty)",
           length(inf_src) > 0 && length(an_src) > 0 && length(gp_src) > 0)

kw_guard <- 'has 0 observations. Every group needs at "'
check_true(V, "the standing guard that makes a 0-observation group refuse before the post-hoc loop is still present (stats/eml-inferential.praat, @emlKruskalWallis) -- this is what makes the sibling provably-unreachable on real data; if this guard is ever relaxed, the fix below is what stands between that change and the exact D2-class bug this file exists to catch",
           any(grepl(kw_guard, an_src, fixed = TRUE)) ||
           any(grepl(kw_guard, inf_src, fixed = TRUE)))

# Both fill sites now set `undefined` on the failed pair (mirrors the
# Cohen's d fix exactly), and both print sites now special-case undefined
# before formatting the cell.
n_fill_analysis <- sum(grepl(
    "emlKruskalWallis\\.rMatrix##\\s*\\[\\.i,\\s*\\.j\\]\\s*=\\s*undefined", an_src))
n_fill_graphs <- sum(grepl(
    "emlKruskalWallis\\.rMatrix##\\s*\\[\\.i,\\s*\\.j\\]\\s*=\\s*undefined", gp_src))
check_true(V, "stats/eml-analysis.praat: the KW rank-biserial fill loop now sets undefined on a failed pair (1 site)",
           n_fill_analysis >= 1)
check_true(V, "graphs/eml-annotation-procedures.praat: its own copy of the same loop does too (1 site)",
           n_fill_graphs >= 1)

n_print_undef <- sum(grepl('\\.rVal = undefined', gp_src)) +
                 sum(grepl('if \\.rVal = undefined', gp_src))
check_true(V, "graphs/eml-annotation-procedures.praat: the r-matrix PRINT loop now special-cases undefined (\"n/a\") rather than handing it to @eml_fixed unconditionally",
           any(grepl("if \\.rVal = undefined", gp_src)))

# And the ANOVA/Cohen's d member this was modelled on carries the same
# shape in the same two files, so "mirrors the driven fix" is a checkable
# claim and not just a comment's say-so.
check_true(V, "stats/eml-analysis.praat: the ANOVA Cohen's d fill loop carries the identical shape (undefined on failure)",
           any(grepl(
               "emlOneWayAnova\\.dMatrix##\\s*\\[\\.i,\\s*\\.j\\]\\s*=\\s*undefined", an_src)))
check_true(V, "graphs/eml-annotation-procedures.praat: same for its Cohen's d fill loop",
           any(grepl(
               "emlOneWayAnova\\.dMatrix##\\s*\\[\\.i,\\s*\\.j\\]\\s*=\\s*undefined", gp_src)))
check_true(V, "graphs/eml-annotation-procedures.praat: the d-matrix PRINT loop special-cases undefined the same way",
           any(grepl("if \\.dVal = undefined", gp_src)))

if (!exists("EML_SUITE")) {
    eml_report("v135 error propagation, punch list 9.1"); eml_exit()
}
