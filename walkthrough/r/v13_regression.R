# v13 — simple linear regression, base R only. Everything the plugin reports
# here comes straight out of lm()/summary.lm() -- no nonstandard statistics,
# nothing lifted from helpers.R.

d <- read.csv("evidence/csv/v13_regression_input.csv", stringsAsFactors = FALSE)
x <- d$practice_hrs_wk           # predictor
y <- d$vibrato_regularity_pct    # response
n <- length(x)

fit <- lm(y ~ x)
sm  <- summary(fit)
co  <- coef(sm)
fs  <- sm$fstatistic

cat(sprintf("N                   %d\n\n", n))
cat("-- Model --\n")
cat(sprintf("Equation            y = %.4fx + %.4f\n", co["x", "Estimate"], co["(Intercept)", "Estimate"]))
cat(sprintf("R                   %.4f\n", sign(co["x", "Estimate"]) * sqrt(sm$r.squared)))
cat(sprintf("R-squared           %.4f\n", sm$r.squared))
cat(sprintf("Adj. R-squared      %.4f\n", sm$adj.r.squared))
cat(sprintf("Residual SE         %.4f\n\n", sm$sigma))

cat("-- Overall Model Test (F) --\n")
cat(sprintf("F(%d,%d)             %.4f\n", fs["numdf"], fs["dendf"], fs["value"]))
cat(sprintf("p                   %.3g\n\n", pf(fs["value"], fs["numdf"], fs["dendf"], lower.tail = FALSE)))

cat("-- Coefficients --\n")
cat(sprintf("%-18s Estimate   SE         t          p\n", ""))
cat(sprintf("Intercept          %-10.4f %-10.4f %-10.3f %.3g\n",
            co["(Intercept)", "Estimate"], co["(Intercept)", "Std. Error"],
            co["(Intercept)", "t value"], co["(Intercept)", "Pr(>|t|)"]))
cat(sprintf("practice_hrs_wk    %-10.4f %-10.4f %-10.3f %.3g\n",
            co["x", "Estimate"], co["x", "Std. Error"],
            co["x", "t value"], co["x", "Pr(>|t|)"]))

cat(sprintf("\nDirection: %s\n", if (co["x", "Estimate"] > 0) "positive" else "negative"))
