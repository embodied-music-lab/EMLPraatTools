# ============================================================================
# v12 — Correlate two columns: orchestrator
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Covers @emlRunCorrelationAnalysis with Test = "Both", so Pearson and
# Spearman are produced in one report and can be checked against each other.
#
# The interesting failure mode here is not either coefficient — both have
# external oracles — but the t statistic and df printed BESIDE them. The
# plugin reports a t and df under the Spearman heading as well as the
# Pearson one, and the Spearman t is computed from rho by the same
# t = r*sqrt((n-2)/(1-r^2)) formula. That is the standard large-sample
# approximation, not an exact permutation p, and this script pins it as such
# rather than pretending it is exact.
#
# EVERY REPORTED VALUE IS READ FROM THE COMMITTED CAPTURE; see v08.
#
# DRIVEN 5 August 2026:
#   New > EML Stats & Graphs > Correlate two columns...
#   Column X speaking_F0_Hz, Column Y singing_F0_Hz,
#   Group column (none), Test = Both.
#
# Input:  evidence/csv/v12_correlation_input.csv
# Output: evidence/info/v12_correlation_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v12_correlation_input.csv")
cap <- capture("v12_correlation_info.txt")
x <- d$speaking_F0_Hz
y <- d$singing_F0_Hz
n <- length(x)
check("v12", "N", printed(cap, "N"), n, tol = 0)

t_from_r <- function(r, n) r * sqrt((n - 2) / (1 - r^2))

# --- Pearson ---------------------------------------------------------------
pe <- cor.test(x, y, method = "pearson")
check("v12", "Pearson r", printed(cap, "r"), unname(pe$estimate), tol = 5e-5)
check("v12", "Pearson t", printed(cap, "t", 1, 1), unname(pe$statistic), tol = 5e-4)
check("v12", "Pearson df", printed(cap, "df", 1, 1), unname(pe$parameter), tol = 0)
check_floored("v12", "Pearson p", cap, "p", unname(pe$p.value), occurrence = 1)

# df must be n - 2. Printing n or n - 1 here is a classic slip that leaves
# the coefficient untouched and the p-value subtly wrong.
check("v12", "printed Pearson df is n - 2", n - 2, printed(cap, "df", 1, 1), tol = 0)

# t and r are two views of the same quantity, so the printed PAIR must be
# mutually consistent and not merely individually right.
#
# The direction matters. Going r -> t is ill-conditioned when r is near 1,
# because t = r*sqrt((n-2)/(1-r^2)) divides by 1 - r^2, which is 0.063 here:
# the 4-decimal rounding of r (0.9680 against 0.96804799) moves t by 0.016,
# swamping any tolerance small enough to be worth setting. That is a
# property of the arithmetic, not a defect, and the first version of this
# check failed on it.
#
# Going t -> r is well-conditioned: r = t/sqrt(t^2 + df) is smooth and
# bounded, and the rounding of t moves r by under 1e-4. So the consistency
# is asserted in that direction.
check("v12", "printed r and printed t are a consistent pair",
      printed(cap, "r"),
      r_from_t(printed(cap, "t", 1, 1), printed(cap, "df", 1, 1)), tol = 5e-4)
check("v12", "printed rho and printed t are a consistent pair",
      printed(cap, "rho"),
      r_from_t(printed(cap, "t", 1, 2), printed(cap, "df", 1, 2)), tol = 5e-4)

# --- Spearman --------------------------------------------------------------
rho <- unname(suppressWarnings(cor.test(x, y, method = "spearman"))$estimate)
check("v12", "Spearman rho", printed(cap, "rho"), rho, tol = 5e-5)
check("v12", "Spearman t", printed(cap, "t", 1, 2), t_from_r(rho, n), tol = 5e-4)
check("v12", "Spearman df", printed(cap, "df", 1, 2), n - 2, tol = 0)
check_floored("v12", "Spearman p", cap, "p",
              2 * pt(-abs(t_from_r(rho, n)), n - 2), occurrence = 2)

# Spearman's rho is Pearson's r on the ranks. Recomputing it that way is an
# independent path through base R and must agree exactly.
check("v12", "Spearman rho equals Pearson r on ranks",
      rho, cor(rank(x), rank(y)), tol = 1e-12)

# --- the two coefficients must stay distinct -------------------------------
# Both are near 1 on this data, which is precisely when a wrapper that
# printed the same coefficient under both headings would go unnoticed.
check("v12", "printed r and printed rho are not the same number",
      printed(cap, "r"), printed(cap, "rho"), tol = 5e-4, expect = "differ")
check("v12", "the two printed t statistics are not the same number",
      printed(cap, "t", 1, 1), printed(cap, "t", 1, 2), tol = 5e-4, expect = "differ")

# On these data the monotone association is slightly weaker than the linear
# one. That ordering is a property of the data, and asserting it catches a
# swap of the two blocks, which magnitude checks alone would not.
check_true("v12", "printed rho < printed r, so the blocks are not swapped",
           printed(cap, "rho") < printed(cap, "r"))

if (!exists("EML_SUITE")) { eml_report("v12 correlation orchestrator"); eml_exit() }
