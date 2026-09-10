# ============================================================================
# Generator for walkthrough/kit/data/v14_descriptive_groups_input.csv
#
# Four groups (n = 1, 5, 12, 30) exercising the descriptive door's per-group
# path: the n = 1 group reports n and mean only (rest undefined, disclosed);
# the n = 5 group's `value` column contains an exact zero, so the
# geometric- and harmonic-mean branches refuse and disclose there (and for
# the whole column); the n = 30 group is built with one exact duplicate so
# `.mode` is unique there. `value_pos` mirrors `value`'s shape but is
# shifted strictly positive throughout, so the same door run on that column
# instead succeeds for geometric and harmonic mean everywhere. Base R only,
# seeded for reproducibility.
#
#     Rscript walkthrough/kit/data/gen/v14_descriptive_groups_input.R
# ============================================================================

set.seed(77)

g1v <- rnorm(1, 60, 5)
g2v <- c(0, rnorm(4, 60, 5))                 # exact zero -> geo/harm refuse here
g3v <- rnorm(12, 60, 5)
g4v <- c(rnorm(27, 60, 5), rep(61.5, 3))     # 61.5 x3 is the unique mode

tab <- sort(table(g4v), decreasing = TRUE)
if (!(length(tab) >= 2 && tab[[1]] > tab[[2]]))
    stop("v14_descriptive_groups: group 4 does not have a unique mode")
if (!any(g2v == 0))
    stop("v14_descriptive_groups: group 2 lost its exact zero")

set.seed(78)
g1p <- rnorm(1, 60, 5) + 150
g2p <- rnorm(5, 60, 5) + 150
g3p <- rnorm(12, 60, 5) + 150
g4p <- rnorm(30, 60, 5) + 150
allp <- c(g1p, g2p, g3p, g4p)
if (!all(allp > 0))
    stop("v14_descriptive_groups: value_pos is not strictly positive throughout")

rows <- data.frame(
    group     = c(rep(1, 1), rep(2, 5), rep(3, 12), rep(4, 30)),
    value     = c(g1v, g2v, g3v, g4v),
    value_pos = allp,
    stringsAsFactors = FALSE)
rows$id <- paste0("D", seq_len(nrow(rows)))
rows <- rows[, c("id", "group", "value", "value_pos")]

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v14_descriptive_groups_input.csv")
write.csv(rows, out, row.names = FALSE, quote = FALSE)
cat("wrote", out, "(", nrow(rows), "rows )\n")
