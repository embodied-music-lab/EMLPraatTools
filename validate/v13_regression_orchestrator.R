# ============================================================================
# v13 — Linear regression: orchestrator
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Covers @emlRunRegressionAnalysis: the fitted equation, R and R-squared,
# adjusted R-squared, residual standard error, the overall F test, and the
# coefficient table with standard errors, t statistics and p-values.
#
# The wiring risk in a regression wrapper is the direction of the model. The
# form has separate "Predictor column" and "Response column" menus; swapping
# them yields a completely valid regression with a different slope, a
# different intercept, the same R-squared and the same F. Three of the six
# headline numbers are invariant under the swap, which is why this script
# asserts the slope and intercept against the stated direction and then
# checks the reversed fit differs.
#
# EVERY REPORTED VALUE IS READ FROM THE COMMITTED CAPTURE; see v08.
#
# DRIVEN 5 August 2026:
#   New > EML Stats & Graphs > Linear regression...
#   Predictor practice_hrs_wk, Response vibrato_regularity_pct,
#   Group column (none).
#
# Input:  evidence/csv/v13_regression_input.csv
# Output: evidence/info/v13_regression_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v13_regression_input.csv")
cap <- capture("v13_regression_info.txt")
x <- d$practice_hrs_wk           # predictor, as set on the form
y <- d$vibrato_regularity_pct    # response
n <- length(x)
check("v13", "N", printed(cap, "N"), n, tol = 0)

fit <- lm(y ~ x)
sm  <- summary(fit)
co  <- coef(sm)

# --- model -----------------------------------------------------------------
# The coefficient table row is labelled with the predictor's display name.
pred <- "practice hrs wk"
check("v13", "slope", printed(cap, pred, 1), unname(co["x", "Estimate"]), tol = 5e-5)
check("v13", "intercept", printed(cap, "Intercept", 1), unname(co["(Intercept)", "Estimate"]), tol = 5e-5)
check("v13", "R", printed(cap, "R"), sqrt(sm$r.squared), tol = 5e-5)
check("v13", "R-squared", printed(cap, "R-squared"), sm$r.squared, tol = 5e-5)
check("v13", "adj R-squared", printed(cap, "Adj. R-squared"), sm$adj.r.squared, tol = 5e-5)
check("v13", "residual SE", printed(cap, "Residual SE"), sm$sigma, tol = 5e-5)

# R must be the positive root here because the slope is positive. A wrapper
# that took sqrt(R2) unconditionally would print +0.90 for a negative slope
# too, and no other number in the report would contradict it.
check_true("v13", "sign of the printed R agrees with the printed slope",
           sign(printed(cap, "R")) == sign(printed(cap, pred, 1)))

# --- negative-slope fixture (7.1) ------------------------------------------
# The committed fixture above has a positive slope, so the sign-agreement
# check just above can never fire: sign(R) == sign(slope) holds whether R is
# printed signed or printed as abs(sqrt(R-squared)), because on THIS data the
# true R is positive either way. harness/regsign drives the same production
# procedure, @emlRunRegressionAnalysis, on evidence/csv/
# v13_regression_neg_input.csv, whose slope is negative (R = -0.9852 in R),
# so a wrapper that unconditionally prints the positive root has something to
# disagree with.
dNeg    <- read_input("v13_regression_neg_input.csv")
capNeg  <- capture("v13_regression_neg_info.txt")
xNeg <- dNeg$practice_hrs_wk
yNeg <- dNeg$vibrato_regularity_pct
fitNeg <- lm(yNeg ~ xNeg)
check_true("v13", "negative-slope fixture: R computed in R is indeed negative",
           cor(xNeg, yNeg) < 0)
check_true("v13", "negative-slope fixture: printed slope is indeed negative",
           printed(capNeg, pred, 1) < 0)
check_true("v13", "negative-slope fixture: sign of the printed R agrees with the printed slope",
           sign(printed(capNeg, "R")) == sign(printed(capNeg, pred, 1)))
check("v13", "negative-slope fixture: printed R equals Pearson r(x, y)",
      printed(capNeg, "R"), cor(xNeg, yNeg), tol = 5e-4)

# For simple regression, R must equal Pearson's r between x and y. This ties
# the regression orchestrator to the correlation orchestrator in v12.
check("v13", "printed R equals Pearson r(x, y)", printed(cap, "R"), cor(x, y), tol = 5e-5)

# --- overall F test --------------------------------------------------------
fs <- sm$fstatistic
check("v13", "F", printed(cap, "F(1,23)"), unname(fs["value"]), tol = 5e-5)
check("v13", "F df1 (from the printed label F(1,23))", 1, unname(fs["numdf"]), tol = 0)
check("v13", "F df2 (from the printed label F(1,23))", 23, unname(fs["dendf"]), tol = 0)
check_floored("v13", "F p", cap, "p",
              unname(pf(fs["value"], fs["numdf"], fs["dendf"], lower.tail = FALSE)),
              occurrence = 1)
check_true("v13", "the printed F label names df 1 and 23",
           any(grepl("F(1,23)", cap$lines, fixed = TRUE)))
check("v13", "F df2 is n - 2", n - 2, unname(fs["dendf"]), tol = 0)

# In simple regression F = t^2 for the slope. The report prints both, so
# they must agree with each other, not just with R.
check("v13", "printed F equals the printed slope t, squared",
      printed(cap, "F(1,23)"), printed(cap, pred, 3)^2, tol = 5e-3)

# --- coefficient table -----------------------------------------------------
check("v13", "intercept SE", printed(cap, "Intercept", 2), unname(co["(Intercept)", "Std. Error"]), tol = 5e-5)
check("v13", "intercept t", printed(cap, "Intercept", 3), unname(co["(Intercept)", "t value"]), tol = 5e-4)
check("v13", "slope SE", printed(cap, pred, 2), unname(co["x", "Std. Error"]), tol = 5e-5)
check("v13", "slope t", printed(cap, pred, 3), unname(co["x", "t value"]), tol = 5e-4)
check_true("v13", "intercept p is floored in the coefficient table",
           grepl("<", printed_str(cap, "Intercept", 4)))
check_true("v13", "and R agrees it is below .001",
           unname(co["(Intercept)", "Pr(>|t|)"]) < 0.001)
check_true("v13", "slope p is floored in the coefficient table",
           grepl("<", printed_str(cap, pred, 4)))
check_true("v13", "and R agrees it is below .001",
           unname(co["x", "Pr(>|t|)"]) < 0.001)

# Each t must equal its own estimate over its own SE. This is the check that
# catches a coefficient table assembled by row index rather than by name —
# every value present and correct, two of them in each other's places.
check("v13", "printed intercept t = printed estimate / printed SE",
      printed(cap, "Intercept", 3),
      printed(cap, "Intercept", 1) / printed(cap, "Intercept", 2), tol = 5e-3)
check("v13", "printed slope t = printed estimate / printed SE",
      printed(cap, pred, 3), printed(cap, pred, 1) / printed(cap, pred, 2), tol = 5e-3)

# --- direction ------------------------------------------------------------
# The plugin prints "Direction: positive (vibrato regularity pct increases as
# practice hrs wk increases)". That sentence names response and predictor in
# a specific order; the slope sign is what makes it true or false.
check_true("v13", "the capture prints a positive-direction sentence",
           any(grepl("Direction: positive", cap$lines, fixed = TRUE)))
check_true("v13", "and the printed slope is indeed positive",
           printed(cap, pred, 1) > 0)

# The reversed model must differ, or the direction claim would be untestable.
rev_fit <- lm(x ~ y)
check("v13", "reversing predictor and response changes the slope",
      printed(cap, pred, 1), unname(coef(rev_fit)[2]),
      tol = 5e-4, expect = "differ")
check("v13", "but leaves the printed R-squared unchanged, which is why direction needs its own check",
      printed(cap, "R-squared"), summary(rev_fit)$r.squared, tol = 5e-5)

# ============================================================================
# DATA-CLEANING WAVE — level-1 / level-2 fixtures for this door
#
# Built 8 September 2026, driven like v08's block above:
# @emlRunRegressionAnalysis is a plain procedure, called directly by
# evidence/redrive/kit_cleandata_named_doors.praat against
# validate/redpath/kit_cleandata_{l1,l2}_regression.csv (predictor "pred",
# response "dep", 8 rows, a near-perfect line).
#
# LEVEL 1: row 3's pred-cell carries "3,4", the ONLY comma in column pred --
# read unambiguously as mode 1 (decimal) and repaired to 3.4. N is 8, and the
# door prints no "Excluded" line.
# LEVEL 2: the same cell is "??" -- refused. The door prints
# "Excluded (missing)  1" directly under N, which is the refusal text this
# fixture asserts on, alongside the recomputed fit over the 7 remaining rows.
# ============================================================================

# --- LEVEL 1: the decimal comma is repaired, not excluded -------------------
rd1  <- read_input("kit_cleandata_l1_regression_input.csv")
rcap1 <- capture("kit_cleandata_l1_regression_info.txt")
rx1 <- as.numeric(gsub(",", ".", rd1$pred))
ry1 <- rd1$dep
check_true("v13-cleandata", "the fixture's one comma cell parses as 3.4 once repaired",
           any(rx1 == 3.4))
check("v13-cleandata", "L1: N is 8 -- the comma cell is analysed, not dropped",
      printed(rcap1, "N"), length(rx1), tol = 0)
fit1 <- lm(ry1 ~ rx1)
check("v13-cleandata", "L1: slope over the repaired data",
      printed(rcap1, "pred", 1), unname(coef(fit1)[2]), tol = 5e-4)
check_true("v13-cleandata", "L1: no \"Excluded\" line is printed",
           !any(grepl("^  Excluded", rcap1$lines)))

# --- LEVEL 2: the unreadable cell is refused, exactly as before ------------
rd2  <- read_input("kit_cleandata_l2_regression_input.csv")
rcap2 <- capture("kit_cleandata_l2_regression_info.txt")
keep2 <- !is.na(suppressWarnings(as.numeric(rd2$pred)))
rx2 <- as.numeric(rd2$pred[keep2])
ry2 <- rd2$dep[keep2]
check_true("v13-cleandata", "the fixture's one unreadable cell (\"??\") leaves 7 usable rows",
           length(rx2) == 7L)
check("v13-cleandata", "L2: N is 7 -- the unreadable cell is refused",
      printed(rcap2, "N"), length(rx2), tol = 0)
check("v13-cleandata", "L2: Excluded (missing) names exactly 1 row",
      printed(rcap2, "Excluded (missing)"), 1, tol = 0)
fit2 <- lm(ry2 ~ rx2)
check("v13-cleandata", "L2: slope over the reduced sample",
      printed(rcap2, "pred", 1), unname(coef(fit2)[2]), tol = 5e-4)
check("v13-cleandata", "L1 and L2 give different N -- the repair, not a coincidence, moved the count",
      printed(rcap1, "N"), printed(rcap2, "N"), tol = 0, expect = "differ")

if (!exists("EML_SUITE")) { eml_report("v13 regression orchestrator"); eml_exit() }
