# ============================================================================
# Generator for walkthrough/kit/data/v13_regression_theil_input.csv
#
# n = 25, y = 1.5x + 3 + noise, with two gross outliers so OLS and Theil-Sen
# disagree materially -- both estimators are graded against the fixture.
# Base R only, seeded for reproducibility.
#
#     Rscript walkthrough/kit/data/gen/v13_regression_theil_input.R
# ============================================================================

set.seed(404)

n <- 25
x <- seq_len(n) + rnorm(n, 0, 0.3)
y <- 1.5 * x + 3 + rnorm(n, 0, 1.2)
y[5]  <- y[5]  + 40
y[20] <- y[20] - 35

ols_slope <- unname(coef(lm(y ~ x))[2])
pairs   <- combn(n, 2)
slopes  <- apply(pairs, 2, function(ij) {
    i <- ij[1]; j <- ij[2]
    if (x[i] == x[j]) return(NA_real_)
    (y[j] - y[i]) / (x[j] - x[i])
})
ts_slope <- median(slopes, na.rm = TRUE)
if (abs(ols_slope - ts_slope) < 0.2)
    stop("v13_regression_theil: OLS (", ols_slope, ") and Theil-Sen (",
         ts_slope, ") slopes no longer differ materially -- ",
         "fixture no longer matches its purpose")

rows <- data.frame(id = paste0("R", seq_len(n)), x = x, y = y)

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v13_regression_theil_input.csv")
write.csv(rows, out, row.names = FALSE, quote = FALSE)
cat("wrote", out, "(", nrow(rows), "rows; OLS slope", round(ols_slope, 3),
    "vs Theil-Sen slope", round(ts_slope, 3), ")\n")
