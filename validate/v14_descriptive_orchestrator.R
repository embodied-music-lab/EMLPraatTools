# ============================================================================
# v14 — Describe Table column: orchestrator
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Covers @emlRunDescriptiveAnalysis: central tendency, dispersion, quartiles,
# distribution shape and the 95% confidence interval for the mean.
#
# TWO CONVENTIONS ARE ASSERTED HERE AND BOTH ARE ARGUABLE. A reviewer who
# disagrees should say so; they are the most likely place for this script to
# be wrong rather than the plugin.
#
#   Quartiles. R's quantile() has nine types. The plugin's Q1 and Q3 match
#   type 7 (the R default, linear interpolation of the empirical CDF), NOT
#   type 6 (Minitab/SPSS) or type 2 (the "textbook" median-of-halves). On
#   these data the three differ in the third decimal, so this script pins
#   type 7 explicitly rather than inheriting a default.
#
#   Skewness and kurtosis. The plugin reports the SAMPLE-CORRECTED G1 and
#   G2 — the SPSS/SAS/Excel forms — read off @emlSkewness and @emlKurtosis
#   in stats/eml-core-descriptive.praat. Not the population moments g1 and
#   g2, and not Pearson's b2. On this column g1 = -0.0392 against
#   G1 = -0.0406 and g2 = -0.0052 against G2 = 0.1404: both differences sit
#   inside the printed precision, so the convention has to be stated to be
#   testable. G2 is an EXCESS form; a normal distribution gives 0.
#
# Note on the capture: this wrapper has no "Clear Info window" option, so an
# earlier capture carried the preceding Kruskal-Wallis report as well. It was
# re-driven on a freshly started Praat, whose Info window is empty, and the
# committed capture is now this analysis and nothing else. That matters more
# than tidiness: @printed resolves a label by occurrence, and a polluted
# capture makes every occurrence index a hostage to whatever ran before.
#
# DRIVEN 5 August 2026:
#   New > EML Tools > Describe Table column...  Column SPL_dB.
#
# Input:  evidence/csv/v14_descriptive_input.csv
# Output: evidence/info/v14_descriptive_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v14_descriptive_input.csv")
cap <- capture("v14_descriptive_info.txt")
x <- d$SPL_dB
n <- length(x)

# --- count -----------------------------------------------------------------
check("v14", "N valid", printed(cap, "N (valid)"), n, tol = 0)
check_true("v14", "no missing values, so N valid is N", !any(is.na(x)))

# --- central tendency ------------------------------------------------------
check("v14", "mean", printed(cap, "Mean"), mean(x), tol = 5e-5)
check("v14", "median", printed(cap, "Median"), median(x), tol = 5e-5)
check("v14", "SEM", printed(cap, "SEM"), sd(x) / sqrt(n), tol = 5e-5)

# --- dispersion ------------------------------------------------------------
# SD is the sample form (n - 1). The population form would print 5.1370 here,
# which is far enough away to distinguish.
check("v14", "SD", printed(cap, "SD"), sd(x), tol = 5e-5)
check("v14", "variance", printed(cap, "Variance"), var(x), tol = 5e-5)
check("v14", "range", printed(cap, "Range"), diff(range(x)), tol = 5e-5)
check("v14", "min", printed(cap, "Min"), min(x), tol = 5e-5)
check("v14", "max", printed(cap, "Max"), max(x), tol = 5e-5)
check("v14", "SD is the sample form, not the population form",
      sd(x), sqrt(sum((x - mean(x))^2) / n), tol = 5e-4, expect = "differ")
check("v14", "variance is SD squared", var(x), sd(x)^2, tol = 1e-9)
check("v14", "printed range = printed max - printed min", printed(cap, "Range"),
      printed(cap, "Max") - printed(cap, "Min"), tol = 5e-4)

# --- quartiles -------------------------------------------------------------
q <- quantile(x, c(0.25, 0.5, 0.75), type = 7, names = FALSE)
check("v14", "Q1 (quantile type 7)", printed(cap, "Q1"), q[1], tol = 5e-5)
check("v14", "Q2 equals the median", printed(cap, "Q2 (Median)"), q[2], tol = 5e-5)
check("v14", "Q3 (quantile type 7)", printed(cap, "Q3"), q[3], tol = 5e-5)
check("v14", "IQR", printed(cap, "IQR"), q[3] - q[1], tol = 5e-5)
check("v14", "printed Q2 and printed median are the same number",
      printed(cap, "Q2 (Median)"), printed(cap, "Median"), tol = 5e-9)
# Derived from two values the plugin already rounded to 4 dp, so the
# tolerance has to absorb both roundings rather than the display precision.
check("v14", "printed IQR equals printed Q3 - printed Q1",
      printed(cap, "IQR"), printed(cap, "Q3") - printed(cap, "Q1"), tol = 1e-3)

# The type matters. If it did not, this check would fail and the assertion
# above would be untestable rather than merely unstated.
check("v14", "quantile type 7 differs from type 6 on this data",
      quantile(x, 0.25, type = 7, names = FALSE),
      quantile(x, 0.25, type = 6, names = FALSE), tol = 5e-5, expect = "differ")

# --- distribution shape ----------------------------------------------------
check("v14", "skewness (sample-corrected G1)", printed(cap, "Skewness"), skewness_g1(x), tol = 5e-5)
check("v14", "kurtosis (sample-corrected G2, excess)", printed(cap, "Kurtosis (excess)"), excess_kurtosis(x), tol = 5e-5)

# The population moment g1 is NOT what is printed. If a future change swapped
# the convention silently, this check is what would notice.
check("v14", "printed skewness is G1, not the population g1",
      printed(cap, "Skewness"),
      (sum((x - mean(x))^3) / length(x)) / (sum((x - mean(x))^2) / length(x))^1.5,
      tol = 5e-4, expect = "differ")

# Excess, not Pearson. The Pearson form would print 3.1404 under the same
# label, and the difference of exactly 3 is the signature of the confusion.
check("v14", "kurtosis is the excess form, not Pearson's b2",
      printed(cap, "Kurtosis (excess)") + 3, excess_kurtosis(x) + 3, tol = 5e-5)

# --- 95% confidence interval for the mean ----------------------------------
# t-based with n - 1 df, not the normal quantile. On n = 45 the two differ
# in the third decimal, which is inside the printed precision.
tcrit <- qt(0.975, n - 1)
ci <- mean(x) + c(-1, 1) * tcrit * sd(x) / sqrt(n)
check("v14", "CI lower", printed(cap, "Lower"), ci[1], tol = 5e-5)
check("v14", "CI upper", printed(cap, "Upper"), ci[2], tol = 5e-5)
# Averaging two values the plugin already rounded to 4 dp, so the tolerance
# absorbs both roundings rather than the display precision. Same reason as
# the IQR check above.
check("v14", "printed CI is symmetric about the printed mean",
      mean(c(printed(cap, "Lower"), printed(cap, "Upper"))),
      printed(cap, "Mean"), tol = 1e-3)
check("v14", "CI uses the t quantile, not the normal quantile",
      ci[1], mean(x) - qnorm(0.975) * sd(x) / sqrt(n), tol = 5e-5, expect = "differ")

# The half-width must equal t * SEM, tying the CI to the SEM printed above.
check("v14", "printed CI half-width equals t * printed SEM",
      (printed(cap, "Upper") - printed(cap, "Lower")) / 2,
      tcrit * printed(cap, "SEM"), tol = 5e-4)

if (!exists("EML_SUITE")) { eml_report("v14 descriptive orchestrator"); eml_exit() }
