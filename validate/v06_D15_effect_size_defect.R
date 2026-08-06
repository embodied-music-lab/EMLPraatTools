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
cap <- capture("v05_paired_info.txt")   # same run as v05
a <- d$jitter_pre; b <- d$jitter_post
tt <- t.test(a, b, paired = TRUE)

dz   <- cohens_dz(a, b)
r_t  <- r_from_t(unname(tt$statistic), unname(tt$parameter))
r_rb <- rank_biserial_paired(a, b)

# --- under the paired t-test -----------------------------------------------
# Read from the capture under the "Effect Size" heading — the one that
# follows the Paired t-test block. Until this run there was NO committed
# capture containing this value at all: 1.728 existed only as a literal in
# this script, which made the whole D15 resolution unverifiable by anyone
# but its author.
check("v06", "Cohen's dz reported under the t-test", printed(cap, "Cohen's dz"), dz, tol = 5e-4)
check("v06", "r (from t) reported under the t-test", printed(cap, "r (from t)"), r_t, tol = 5e-4)

# dz and the t statistic are two views of the same quantity: t = dz * sqrt(n).
check_true("v06", "dz is consistent with the reported t",
           abs(dz * sqrt(length(a)) - unname(tt$statistic)) < 1e-9)

# --- under the Wilcoxon signed-rank test -----------------------------------
check("v06", "matched-pairs r reported under Wilcoxon", printed(cap, "Matched-pairs r"), r_rb, tol = 5e-4)

# The heading each value sits under is the entire finding, so assert the
# order of the report: Paired t-test, then Effect Size, then Wilcoxon, then
# Nonparametric Effect Size. D15 was two correct numbers under swapped
# headings, and only the ORDER distinguishes the fixed report from the
# broken one.
hd <- function(k) which(grepl(k, cap$lines, fixed = TRUE))[1]
check_true("v06", "the report orders t-test, its effect size, Wilcoxon, its effect size",
           hd("Paired t-test") < hd("Effect Size") &&
           hd("Effect Size") < hd("Wilcoxon Signed-Rank") &&
           hd("Wilcoxon Signed-Rank") < hd("Nonparametric Effect Size"))
check_true("v06", "Cohen's dz sits above the Wilcoxon heading, not below it",
           which(grepl("Cohen's dz", cap$lines, fixed = TRUE))[1] <
           hd("Wilcoxon Signed-Rank"))
check_true("v06", "Matched-pairs r sits below the Wilcoxon heading",
           which(grepl("Matched-pairs r", cap$lines, fixed = TRUE))[1] >
           hd("Wilcoxon Signed-Rank"))

# --- the two must stay distinguishable -------------------------------------
# This is the regression guard. If a future change routes the rank statistic
# back under the parametric heading, these two values would be reported
# interchangeably again. They differ by about 0.1 on this data, which is why
# the substitution was invisible.
check_true("v06", "the parametric and rank effect sizes remain distinct",
           abs(r_rb - r_t) > 0.05)

check("v06", "the printed rank statistic is NOT the printed t-derived r",
      printed(cap, "Matched-pairs r"), printed(cap, "r (from t)"),
      tol = 5e-4, expect = "differ")

if (!exists("EML_SUITE")) { eml_report("v06 paired effect sizes (D15 resolved)"); eml_exit() }
