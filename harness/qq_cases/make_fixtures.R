# ---------------------------------------------------------------------------
# Fixtures for the Q-Q drive that the existing red-path inputs do not cover.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# validate/redpath/ already carries n = 2 (r2), zero variance (r3) and missing
# cells (r1). Three gaps remain:
#
#   qq_na_below_3  missing cells that take a long-enough column BELOW n = 3.
#                  r1 has NAs but still leaves 6 complete cases, so it tests
#                  the drop, not the refusal the drop causes.
#   qq_n3          exactly n = 3, the smallest sample @emlShapiroWilk accepts.
#   qq_n10         n = 10, the largest sample at which R's ppoints() still
#                  uses a = 3/8 — the only region where the plugin's
#                  theoretical axis is expected to equal qqnorm()'s exactly.
#   qq_skewed      n = 40, strongly right-skewed, so the figure has to show
#                  visible curvature away from the reference line. A straight
#                  Q-Q here would mean the sample axis is not the data.
#
# Written once and committed. Regenerate with:
#     Rscript harness/qq_cases/make_fixtures.R
# ---------------------------------------------------------------------------
here <- (function() {
    a <- commandArgs(FALSE); f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else "."
})()

set.seed(20260807)

w <- function(name, df) {
    write.csv(df, file.path(here, name), row.names = FALSE, quote = FALSE,
              na = "NA")
    cat("wrote", name, "\n")
}

w("qq_na_below_3.csv",
  data.frame(id = sprintf("S%02d", 1:6),
             value = c(12.5, NA, NA, 14.25, NA, NA)))

w("qq_n3.csv",
  data.frame(id = sprintf("S%02d", 1:3),
             value = c(10, 11.5, 15)))

w("qq_n10.csv",
  data.frame(id = sprintf("S%02d", 1:10),
             value = round(rnorm(10, 100, 12), 6)))

w("qq_skewed.csv",
  data.frame(id = sprintf("S%02d", 1:40),
             value = round(rexp(40, rate = 0.05), 6)))
