# ============================================================================
# v136_regression_grouping.R -- per-group regression, ruled into 1.0 (4.5)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS FIXES, MEASURED (harness/doorcensus's own leg5, Sol's
# Simpson fixture): the regression dialog's group column was read into
# groupCol$ and never passed to @emlRunRegressionAnalysis
# (scripts/eml-regress.praat:107-108, confirmed by v127's own structural
# grep) -- two groups with slopes +1.98 and -1.99 pooled to a reported
# zero, and the scatter Draw door's own per-group fit silently disagreed
# with the analysis dialog's report. WORK_ORDER_DOOR_CENSUS.md section 3 and
# OPEN_ITEMS.md's "regression group column" entry rule the fix in for 1.0:
# per-group fits beside the overall one, groups too small to fit named and
# skipped, labelled rows in the export, drawn lines matching the report --
# the correlate dialog's whole existing pattern, ported rather than
# reinvented.
#
# WHAT SHIPPED: @emlRunGroupedRegressionAnalysis (stats/eml-analysis.praat), ONE
# procedure called from BOTH doors -- the menu's eml-regress.praat and
# BOTH of the wizard's regression pages (B_REG_COLUMNS under "Relationship >
# Regression" and D_PREDICT_COLUMNS under "Predict an outcome") -- rather
# than a copy per door, so the group column cannot drift between them.
#
# WHAT THIS FILE READS:
#   - harness/regressiongroup/out/REGGROUP.tsv, written by
#     harness/regressiongroup/probe.praat, which calls
#     @emlRunGroupedRegressionAnalysis DIRECTLY on Sol's Simpson fixture (the same
#     values as harness/doorcensus/fixtures/leg5_grouped_regression.csv,
#     plus one below-floor group C local to this probe) -- oracled below
#     against base R's own lm() per group, section 1.
#   - The shipped source of both doors, by grep, section 2: each door's
#     own call site now carries the group column, and the menu dialog's
#     Draw dispatch and both wizard draw branches pass the SAME grouping
#     column to the figure the report used, so the drawn lines cannot
#     silently disagree with the report the way the pre-fix dialog's own
#     Draw button (which DID carry hasGroupCol) never disagreed with a
#     report that simply never computed a per-group fit at all.
#
# THE RED DEMONSTRATION for this file's SUBSTANCE is v127's own leg5
# section, which reads eml-regress.praat's call site and FAILS on purpose
# ("SILENT DISAGREEMENT ... FAILS on purpose until the port's commit") on
# every commit before this one -- rerun it against an earlier commit and it
# is red, from the real pre-fix source, committed and reusable. This file
# is the check that reads GREEN once the port lands, which is why v127's
# leg5 structural assertion is revised alongside it (see that file's own
# note) rather than left asserting the defect forever.
#
# Base R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v136"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

tsv_path <- Sys.getenv("EML_REGGROUP_OUT", unset = "")
if (!nzchar(tsv_path)) tsv_path <- repo_path("harness", "regressiongroup", "out", "REGGROUP.tsv")
PLUGIN_DIR <- repo_path("plugin_EML_StatsGraphs")

E <- list()
if (file.exists(tsv_path) && file.info(tsv_path)$size > 0) {
    .x <- read.delim(tsv_path, header = TRUE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE)
    E <- setNames(as.list(as.character(.x$value)), .x$key)
}
ev <- function(k) if (is.null(E[[k]])) NA_character_ else E[[k]]
evn <- function(k) suppressWarnings(as.numeric(ev(k)))

check_true(V, "the probe ran to completion", identical(ev("completed"), "1"))

# ---------------------------------------------------------------------------
# 1. THE ORACLE -- base R's own lm(), per group, on the exact fixture the
#    probe used (harness/regressiongroup/probe.praat's own literal copy of
#    Sol's Simpson exhibit, plus a below-floor group C local to the probe).
# ---------------------------------------------------------------------------
x <- 1:10
yA <- c(7.30,8.80,11.10,12.60,15.20,16.90,19.30,20.70,23.10,24.80)
yB <- c(97.80,96.30,93.90,92.20,89.70,88.10,85.80,84.20,81.90,80.30)
xC <- c(1, 2); yC <- c(50.00, 51.00)
# The OVERALL (pooled) fit the probe's door-1 step ran includes every row
# in the table, group C's two included -- the pooled model has no group
# column to exclude them by. The per-group oracles below (mA, mB) do NOT
# include C: each group's own fit only ever sees its own rows.
mAll <- lm(y ~ x, data = data.frame(x = c(x, x, xC), y = c(yA, yB, yC)))
mA <- lm(yA ~ x)
mB <- lm(yB ~ x)
cA <- summary(mA)$coefficients
cB <- summary(mB)$coefficients

check(V, "overall (pooled) slope", evn("overall_slope"),
      unname(coef(mAll)["x"]), tol = 1e-6)
check(V, "overall (pooled) R^2", evn("overall_r2"),
      summary(mAll)$r.squared, tol = 1e-8)
check_true(V,
           sprintf("the fixture is ADVERSARIAL (Simpson): pooled slope = %.4f (~0) while the two groups are %+.3f and %+.3f",
                   evn("overall_slope"), unname(coef(mA)["x"]), unname(coef(mB)["x"])),
           is.finite(evn("overall_slope")) && abs(evn("overall_slope")) < 0.1)

check(V, "group A intercept", evn("tidy_estimate_3"), unname(cA["(Intercept)", "Estimate"]), tol = 1e-6)
check(V, "group A slope", evn("tidy_estimate_4"), unname(cA["x", "Estimate"]), tol = 1e-6)
check(V, "group A slope SE", evn("tidy_se_4"), unname(cA["x", "Std. Error"]), tol = 1e-6)
check(V, "group A slope t", evn("tidy_stat_4"), unname(cA["x", "t value"]), tol = 1e-4)
check(V, "group A slope p", evn("tidy_p_4"), unname(cA["x", "Pr(>|t|)"]), tol = 1e-6)

check(V, "group B intercept", evn("tidy_estimate_5"), unname(cB["(Intercept)", "Estimate"]), tol = 1e-6)
check(V, "group B slope", evn("tidy_estimate_6"), unname(cB["x", "Estimate"]), tol = 1e-6)
check(V, "group B slope SE", evn("tidy_se_6"), unname(cB["x", "Std. Error"]), tol = 1e-6)
check(V, "group B slope t", evn("tidy_stat_6"), unname(cB["x", "t value"]), tol = 1e-4)
check(V, "group B slope p", evn("tidy_p_6"), unname(cB["x", "Pr(>|t|)"]), tol = 1e-6)

check_true(V,
           sprintf("groups A and B are the OPPOSITE-sign, near-perfect fits the door census names: A = %+.3f, B = %+.3f",
                   evn("tidy_estimate_4"), evn("tidy_estimate_6")),
           evn("tidy_estimate_4") > 1.5 && evn("tidy_estimate_6") < -1.5)

# The overall row the tidy rebuild re-emits must still be the SAME pooled
# fit checked above -- a grouped run must not silently change the overall
# numbers, only how they are labelled.
check(V, "tidy's re-emitted overall intercept matches the pooled fit",
      evn("tidy_estimate_1"), unname(coef(mAll)["(Intercept)"]), tol = 1e-6)
check(V, "tidy's re-emitted overall slope matches the pooled fit",
      evn("tidy_estimate_2"), unname(coef(mAll)["x"]), tol = 1e-6)

# ---------------------------------------------------------------------------
# 2. GROUPS TOO SMALL TO FIT -- named and skipped, not silently dropped and
#    not silently run. Group C has n = 2, below @emlLinearRegression's own
#    floor of 3.
# ---------------------------------------------------------------------------
check_true(V, "three groups were seen (A, B, C)", identical(evn("pgTotal"), 3))
check_true(V, "exactly two were fit (A, B)", identical(evn("pgRun"), 2))
check_true(V, "exactly one was skipped (C, n < 3)", identical(evn("pgSkipped"), 1))
check_true(V, "glance's n.groups records the groups actually fit, not the groups seen",
           identical(ev("glance_n_groups"), "2"))

# ---------------------------------------------------------------------------
# 3. THE EXPORT IS LABELLED, AND IS EXACTLY THE GROUPED ROWS -- ONE export,
#    not the overall rows plus an accumulating pile. tidy_nRows = 6: two
#    rows (Intercept, slope) each for (overall), group A, group B; C is
#    skipped and contributes nothing.
# ---------------------------------------------------------------------------
check_true(V, "tidy has exactly 6 rows: (overall)+A+B, 2 rows each",
           identical(evn("tidy_nRows"), 6))
expected_terms <- c("(overall) (Intercept)", "(overall) x",
                     "group = A (Intercept)", "group = A x",
                     "group = B (Intercept)", "group = B x")
actual_terms <- vapply(1:6, function(i) ev(paste0("tidy_term_", i)), character(1))
check_true(V,
           sprintf("every tidy row is labelled in `term`, in order: %s",
                   paste(actual_terms, collapse = " | ")),
           identical(actual_terms, expected_terms))

# ---------------------------------------------------------------------------
# 4. STRUCTURAL EVIDENCE -- both doors call the SAME shared procedure, and
#    each door's Draw dispatch passes the SAME grouping column the report
#    just used, so a reader can confirm from source (not just from this
#    one fixture) that the fix is not a one-door patch.
# ---------------------------------------------------------------------------
regress_src <- readLines(file.path(PLUGIN_DIR, "scripts", "eml-regress.praat"), warn = FALSE)
wizard_src <- readLines(file.path(PLUGIN_DIR, "scripts", "eml-wizard.praat"), warn = FALSE)
analysis_src <- readLines(file.path(PLUGIN_DIR, "stats", "eml-analysis.praat"), warn = FALSE)

check_true(V, "stats/eml-analysis.praat defines @emlRunGroupedRegressionAnalysis exactly once",
           sum(grepl("^procedure emlRunGroupedRegressionAnalysis", analysis_src)) == 1)

menu_calls <- sum(grepl("@emlRunGroupedRegressionAnalysis:", regress_src, fixed = TRUE))
wizard_calls <- sum(grepl("@emlRunGroupedRegressionAnalysis:", wizard_src, fixed = TRUE))
check_true(V,
           sprintf("the menu door (eml-regress.praat) calls the shared port (%d call site(s))", menu_calls),
           menu_calls == 1)
check_true(V,
           sprintf("the wizard calls the shared port from BOTH its regression pages (%d call site(s), want 2: B_REG_COLUMNS and D_PREDICT_COLUMNS)", wizard_calls),
           wizard_calls == 2)

# The old defect's own signature -- the three-argument call with no group --
# must be gone from the menu door now that the group column is threaded
# through @emlRunGroupedRegressionAnalysis instead.
old_defect_line <- grep("@emlRunRegressionAnalysis:\\s*tableId,\\s*respCol\\$,\\s*predCol\\$\\s*$", regress_src)
check_true(V,
           "the menu door's overall-fit call is unchanged (still the plain 3-argument form; grouping now rides the separate port call, not this one)",
           length(old_defect_line) == 1)

# Draw dispatch: the menu door's own Draw button already carried
# emlGraphsPresetGroupCol$ before this port (that half was never the
# defect -- only the ANALYSIS side dropped the column), so this is a
# regression guard, not new evidence of the fix.
menu_draw_group <- any(grepl("emlGraphsPresetGroupCol\\$ = groupCol\\$", regress_src))
check_true(V, "the menu door's Draw dispatch still passes the group column to the figure",
           menu_draw_group)

# The wizard's regression draw branch did NOT carry the group column before
# this port (there was no group column to carry) -- this is new.
wiz_draw_group <- any(grepl("emlGraphsPresetGroupCol\\$ = wizRegDrawGroupCol\\$", wizard_src))
check_true(V,
           "the wizard's regression Draw dispatch now passes the SAME group column its per-group report just used",
           wiz_draw_group)

if (!exists("EML_SUITE")) {
    eml_report("v136 -- per-group regression, ruled into 1.0 (punch-list 4.5)")
    eml_exit()
}
