# ============================================================================
# Generator for walkthrough/kit/data/v13_regression_ties_input.csv
#
# n = 20 with only five distinct x values (four rows each), so pairwise
# Theil-Sen slopes over EQUAL-x pairs are skipped: .tsNSlopes must land
# below n(n-1)/2 = 190. Base R only, seeded for reproducibility.
#
#     Rscript walkthrough/kit/data/gen/v13_regression_ties_input.R
# ============================================================================

set.seed(303)

x <- rep(c(1, 2, 3, 4, 5), each = 4)
n <- length(x)
y <- 2 * x + rnorm(n, 0, 1.5)

pairs   <- combn(n, 2)
nSlopes <- sum(x[pairs[1, ]] != x[pairs[2, ]])
if (!(nSlopes < n * (n - 1) / 2))
    stop("v13_regression_ties: no tied x-pairs were skipped (nSlopes = ",
         nSlopes, ") -- fixture no longer matches its purpose")

rows <- data.frame(id = paste0("R", seq_len(n)), x = x, y = y)

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v13_regression_ties_input.csv")
write.csv(rows, out, row.names = FALSE, quote = FALSE)
cat("wrote", out, "(", nrow(rows), "rows,", nSlopes, "of",
    n * (n - 1) / 2, "pairs usable )\n")
