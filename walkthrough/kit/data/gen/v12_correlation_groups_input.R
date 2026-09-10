# ============================================================================
# Generator for walkthrough/kit/data/v12_correlation_groups_input.csv
#
# Four groups (n = 3, 8, 10, 12): group 1 is too small to run (n < 4) and
# must be skipped and disclosed; groups 2-4 target r ~= 0.9, 0.0, -0.7 so the
# per-group correlation door is exercised across strong-positive,
# near-zero, and moderate-negative cases. Base R only, seeded for
# reproducibility; the seed for each group was chosen (by search over small
# seeds) so the realised sample correlation lands within ~0.03 of its
# target -- the exact figure is confirmed below, not merely hoped for.
#
#     Rscript walkthrough/kit/data/gen/v12_correlation_groups_input.R
# ============================================================================

make_group <- function(seed, n, rho) {
    set.seed(seed)
    x <- rnorm(n, 0, 1)
    e <- rnorm(n, 0, 1)
    y <- rho * x + sqrt(1 - rho^2) * e
    list(x = x, y = y, r = cor(x, y))
}

g1 <- make_group(1,  3,  0.0)          # too small to run; content is irrelevant
g2 <- make_group(3,  8,  0.9)
g3 <- make_group(13, 10, 0.0)
g4 <- make_group(12, 12, -0.7)

targets <- c(0.9, 0.0, -0.7)
got     <- c(g2$r, g3$r, g4$r)
if (any(abs(got - targets) > 0.05))
    stop("v12_correlation_groups: realised r ", paste(round(got, 4), collapse = ", "),
         " strayed from targets ", paste(targets, collapse = ", "))

# Rescale x/y onto plausible Hz-ish measurements so the fixture reads like
# the lab's other correlation inputs rather than raw standard-normal draws.
to_scale <- function(v, mean, sd) v * sd + mean

rows <- do.call(rbind, list(
    data.frame(group = 1, x = to_scale(g1$x, 150, 20), y = to_scale(g1$y, 300, 40)),
    data.frame(group = 2, x = to_scale(g2$x, 150, 20), y = to_scale(g2$y, 300, 40)),
    data.frame(group = 3, x = to_scale(g3$x, 150, 20), y = to_scale(g3$y, 300, 40)),
    data.frame(group = 4, x = to_scale(g4$x, 150, 20), y = to_scale(g4$y, 300, 40))
))
rows$id <- paste0("P", seq_len(nrow(rows)))
rows <- rows[, c("id", "group", "x", "y")]

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v12_correlation_groups_input.csv")
write.csv(rows, out, row.names = FALSE, quote = FALSE)
cat("wrote", out, "(", nrow(rows), "rows; realised r =",
    paste(round(got, 4), collapse = ", "), ")\n")
