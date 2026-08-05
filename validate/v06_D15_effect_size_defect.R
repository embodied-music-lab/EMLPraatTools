# ============================================================================
# v06 — D15: each paired test reports its own effect size
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# HISTORY. This script was written to PIN A DEFECT. Until 5 August 2026 the
# plugin printed the matched-pairs rank-biserial correlation under the
# heading "Paired t-test" — a Wilcoxon statistic reported as though it
# belonged to the parametric test. The original v06 asserted that
# discrepancy, so it passed while the bug was present and would fail once the
# bug was fixed. The bug is now fixed, so the script has been rewritten to
# assert the corrected behaviour, as its own footer instructed.
#
# Input:  evidence/csv/demo_paired_input.csv
#
# What the plugin prints now, driven 5 August 2026:
#
#     -- Paired t-test --
#     t                   7.726
#     ...
#     -- Effect Size --
#     Cohen's dz          1.728
#     r (from t)          0.871
#
#     -- Wilcoxon Signed-Rank Test --
#     ...
#     -- Nonparametric Effect Size --
#     Matched-pairs r     0.971
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d <- read_input("demo_paired_input.csv")
a <- d$jitter_pre; b <- d$jitter_post
tt <- t.test(a, b, paired = TRUE)

dz   <- cohens_dz(a, b)
r_t  <- r_from_t(unname(tt$statistic), unname(tt$parameter))
r_rb <- rank_biserial_paired(a, b)

# --- under the paired t-test -----------------------------------------------
check("v06", "Cohen's dz reported under the t-test", 1.728, dz,  tol = 5e-4)
check("v06", "r (from t) reported under the t-test", 0.871, r_t, tol = 5e-4)

# dz and the t statistic are two views of the same quantity: t = dz * sqrt(n).
check_true("v06", "dz is consistent with the reported t",
           abs(dz * sqrt(length(a)) - unname(tt$statistic)) < 1e-9)

# --- under the Wilcoxon signed-rank test -----------------------------------
check("v06", "matched-pairs r reported under Wilcoxon", 0.971, r_rb, tol = 5e-4)

# --- the two must stay distinguishable -------------------------------------
# This is the regression guard. If a future change routes the rank statistic
# back under the parametric heading, these two values would be reported
# interchangeably again. They differ by about 0.1 on this data, which is why
# the substitution was invisible.
check_true("v06", "the parametric and rank effect sizes remain distinct",
           abs(r_rb - r_t) > 0.05)

check("v06", "the rank statistic is NOT the t-derived r", r_rb, r_t,
      tol = 5e-4, expect = "differ")

if (!exists("EML_SUITE")) { eml_report("v06 paired effect sizes (D15 resolved)"); eml_exit() }
