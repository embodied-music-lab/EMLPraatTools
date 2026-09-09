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

# ============================================================================
# DATA-CLEANING WAVE — level-1 / level-2 fixtures for this door
#
# Built 8 September 2026, driven like v08's block above:
# @emlRunCorrelationAnalysis is a plain procedure, called directly by
# evidence/redrive/kit_cleandata_named_doors.praat against
# validate/redpath/kit_cleandata_{l1,l2}_correlation.csv (8 rows, x and y
# columns increasing together).
#
# LEVEL 1: row 3's x-cell carries "3,2", the ONLY comma in column x -- read
# unambiguously as mode 1 (decimal) and repaired to 3.2. N is 8.
#
# LEVEL 2 -- RE-DERIVED 9 September 2026 under CORRECTION_LEVEL2_IS_A_REFUSAL:
# the same cell is "??", which now REFUSES the whole door instead of the
# old "1 row(s) excluded for missing data (analyzed n = 7 complete pairs)"
# complete-case wording. @emlRunCorrelationAnalysis checks column x through
# @emlRequireNumericColumn with role "X column" (eml-analysis.praat:3124)
# before column y is even looked at, so no pair is ever built and no report
# is printed. .remedy$ reads "" here (orchestrators do not forward it -- see
# v08's level-2 comment; the text itself is proved at its source, see v170's
# categorical case).
# ============================================================================

# --- LEVEL 1: the decimal comma is repaired, not excluded -------------------
cd1  <- read_input("kit_cleandata_l1_correlation_input.csv")
ccap1 <- capture("kit_cleandata_l1_correlation_info.txt")
cx1 <- as.numeric(gsub(",", ".", cd1$x))
cy1 <- cd1$y
check_true("v12-cleandata", "the fixture's one comma cell parses as 3.2 once repaired",
           any(cx1 == 3.2))
check("v12-cleandata", "L1: N is 8 -- the comma cell is analysed, not dropped",
      printed(ccap1, "N"), length(cx1), tol = 0)
check("v12-cleandata", "L1: Pearson r over the repaired data",
      printed(ccap1, "r"), cor(cx1, cy1), tol = 5e-4)
check_true("v12-cleandata", "L1: no exclusion note is printed",
           !any(grepl("excluded", ccap1$lines, fixed = TRUE)))

# --- LEVEL 2: the unreadable cell now refuses the whole door ---------------
ccap2 <- capture("kit_cleandata_l2_correlation_info.txt")
ccap2flat <- paste(trimws(ccap2$lines), collapse = " ")
check_true("v12-cleandata", "L2: no report is printed -- the refusal happens before either column is read",
           !any(grepl("^N", trimws(ccap2$lines))))
check_true("v12-cleandata", "L2: correlation.ok = 0",
           any(grepl("correlation.ok = 0", ccap2$lines, fixed = TRUE)))
check_true("v12-cleandata", "L2: the three-part .error$ names column x, row 3, and the literal \"??\"",
           grepl('correlation.error$ = "X column "x" has a cell that is not numeric, at row 3: "??"."',
                 ccap2flat, fixed = TRUE))
check_true("v12-cleandata", "L2: .remedy$ is empty -- orchestrators do not forward the gate's .remedy$ (documented gap, out of scope)",
           any(grepl('correlation.remedy$ = ""', ccap2$lines, fixed = TRUE)))

if (!exists("EML_SUITE")) { eml_report("v12 correlation orchestrator"); eml_exit() }
