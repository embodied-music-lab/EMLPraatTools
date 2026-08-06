# ============================================================================
# v04 — Stats Wizard, repeated measures: Friedman test
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Route:    as v03 but Test approach = Nonparametric (Friedman)
# Input:    evidence/csv/demo_rm3_input.csv
# Printed:  evidence/info/wizard_rm3_rmanova_and_friedman.txt
#
# This instance is the tied case: all three post-hoc raw p-values are
# identical, so Holm's monotonicity constraint must give all three the same
# adjusted value rather than three different step values. That is the part
# worth checking independently.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d <- read_input("demo_rm3_input.csv")
cap <- capture("wizard_rm3_rmanova_and_friedman.txt")
conds <- c("SPL_soft", "SPL_medium", "SPL_loud")
Y <- as.matrix(d[, conds])

ft <- friedman.test(Y)

check("v04", "Friedman chi-square", printed_eq(cap, "chi-square(2)", 1),
      unname(ft$statistic), tol = 5e-5)
check_true("v04", "the capture prints chi-square with df 2",
           any(grepl("chi-square(2)", cap$lines, fixed = TRUE)))
check_true("v04", "df reported as 2", unname(ft$parameter) == 2L)
check("v04", "Friedman p", printed_eq(cap, "chi-square(2)", 2), unname(ft$p.value), tol = 5e-10)

# --- rank sums ------------------------------------------------------------
ranks <- t(apply(Y, 1, rank))
rs <- colSums(ranks)
check("v04", "SPL_soft rank sum",   printed_eq(cap, "SPL_soft rank sum"),   unname(rs["SPL_soft"]),   tol = 1e-9)
check("v04", "SPL_medium rank sum", printed_eq(cap, "SPL_medium rank sum"), unname(rs["SPL_medium"]), tol = 1e-9)
check("v04", "SPL_loud rank sum",   printed_eq(cap, "SPL_loud rank sum"),   unname(rs["SPL_loud"]),   tol = 1e-9)

# --- post-hoc Wilcoxon signed-rank, holm-adjusted -------------------------
pr <- suppressWarnings(c(
    wilcox.test(Y[, "SPL_soft"],   Y[, "SPL_medium"], paired = TRUE)$p.value,
    wilcox.test(Y[, "SPL_soft"],   Y[, "SPL_loud"],   paired = TRUE)$p.value,
    wilcox.test(Y[, "SPL_medium"], Y[, "SPL_loud"],   paired = TRUE)$p.value
))
pa <- p.adjust(pr, method = "holm")

# occurrence 2: the pair labels appear under RM-ANOVA first, then under
# Friedman in the same capture.
check("v04", "post-hoc raw p, all pairs",
      printed_eq(cap, "SPL_soft vs SPL_medium", 1, 2), pr[1], tol = 5e-7)
check_true("v04", "all three raw p are equal", diff(range(pr)) < 1e-15)
check("v04", "post-hoc holm adjusted p",
      printed_eq(cap, "SPL_soft vs SPL_medium", 2, 2), pa[1], tol = 5e-7)
# The three pairs are tied, so Holm must give all three the SAME adjusted
# value. Read all three from the capture and assert that, rather than
# assuming the printed value repeats.
adj3 <- c(printed_eq(cap, "SPL_soft vs SPL_medium",  2, 2),
          printed_eq(cap, "SPL_soft vs SPL_loud",    2, 2),
          printed_eq(cap, "SPL_medium vs SPL_loud",  2, 2))
check_true("v04", "printed holm adjusted p are identical across the tied pairs",
           diff(range(adj3)) < 1e-15)
check_true("v04", "holm ties: all three adjusted p equal",
           diff(range(pa)) < 1e-15)
check_true("v04", "holm tied value is raw x 3 (monotonicity, not step-down)",
           abs(pa[1] - min(pr[1] * 3, 1)) < 1e-15)

# --- D86: no effect size reported for this test ---------------------------
w <- kendalls_w(unname(ft$statistic), nrow(Y), ncol(Y))
check_true("v04", "Kendall's W computable (D86: plugin omits it)",
           abs(w - 1.0) < 1e-9)

if (!exists("EML_SUITE")) { eml_report("v04 Friedman"); eml_exit() }
