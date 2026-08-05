# ============================================================================
# v06 — D15: the effect size printed under the paired t-test is the
#       nonparametric one
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THIS SCRIPT PINS A KNOWN DEFECT. Its checks are written so that they PASS
# while the defect is present. When D15 is fixed, v06 will FAIL, and that
# failure is the signal that the fix landed. Do not "repair" v06 to make it
# pass again — replace it with the assertions in the commented block at the
# foot of the file.
#
# Input:  evidence/csv/demo_paired_input.csv
#
# What the plugin printed under the heading "Paired t-test":
#
#     -- Effect Size --
#     Matched-pairs r     0.971
#     Magnitude           large effect
#
# 0.971 is the matched-pairs rank-biserial correlation of the WILCOXON
# signed-rank test. The correlation derived from the paired t is 0.871.
# Both are plausible-looking and nothing on screen distinguishes them.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d <- read_input("demo_paired_input.csv")
a <- d$jitter_pre; b <- d$jitter_post
tt <- t.test(a, b, paired = TRUE)

r_t  <- r_from_t(unname(tt$statistic), unname(tt$parameter))
r_rb <- rank_biserial_paired(a, b)
dz   <- cohens_dz(a, b)

PRINTED <- 0.971

# 1. The printed value IS the Wilcoxon rank-biserial.
check("v06", "printed 0.971 equals the rank-biserial r", PRINTED, r_rb, tol = 5e-4)

# 2. The printed value is NOT the t-derived r. This check is declared
#    expect="differ": it passes while the two disagree.
check("v06", "printed 0.971 is not the t-derived r", PRINTED, r_t,
      tol = 5e-4, expect = "differ")

# 3. The t-derived r for this data, for the record.
check("v06", "t-derived r = t / sqrt(t^2 + df)", 0.871, r_t, tol = 5e-4)

# 4. The gap is large enough to change an interpretation, not rounding.
check_true("v06", "the two effect sizes differ by about 0.1",
           abs(r_rb - r_t) > 0.05)

# 5. Cohen's d_z, the conventional effect size for a paired t, is not
#    reported anywhere by the plugin (D86 family).
check("v06", "Cohen's d_z, unreported by the plugin", 1.728, dz, tol = 5e-4)

# ---------------------------------------------------------------------------
# WHEN D15 IS FIXED, replace the checks above with:
#
#   check("v06", "printed effect size is the t-derived r", <printed>, r_t)
#   check("v06", "Cohen's d_z is reported",                <printed>, dz)
#
# and delete the expect="differ" check.
# ---------------------------------------------------------------------------

if (!exists("EML_SUITE")) { eml_report("v06 D15 effect-size defect (pins a known bug)"); eml_exit() }
