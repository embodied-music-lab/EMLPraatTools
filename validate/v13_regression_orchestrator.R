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
#   New > EML Tools > Linear regression...
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

if (!exists("EML_SUITE")) { eml_report("v13 regression orchestrator"); eml_exit() }
