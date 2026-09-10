# ============================================================================
# Generator for walkthrough/kit/data/v15_missing_tokens_emptycell_input.csv
#
# Same 3x2, four-per-cell layout as v15_missing_tokens_input.csv (same seed,
# same underlying numbers), but instead of one token per cell, all four
# rows of ONE cell (group B x factor2 Sing) are set to the literal token
# `NA` in `x`. That empties the cell entirely: the two-way door must refuse,
# naming the empty cell; every other door that reads `x` still excludes and
# lists the four rows (R's `car::Anova` on that design also fails, so the
# two-way cell for this fixture is `expect refuse` on the R side too).
# Base R only, seeded for reproducibility.
#
#     Rscript walkthrough/kit/data/gen/v15_missing_tokens_emptycell_input.R
# ============================================================================

set.seed(88)

groups <- c("A", "B", "C")
f2s    <- c("Sing", "Speak")
cells  <- expand.grid(group = groups, factor2 = f2s, stringsAsFactors = FALSE)

rows <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
    g <- cells$group[i]; f <- cells$factor2[i]
    data.frame(
        group   = g,
        factor2 = f,
        x = rnorm(4, 60 + 2 * match(g, groups) + 3 * (f == "Speak"), 4),
        y = rnorm(4, 100 + match(g, groups), 5),
        stringsAsFactors = FALSE)
}))
rows$id <- paste0("R", seq_len(nrow(rows)))
rows <- rows[, c("id", "group", "factor2", "x", "y")]

if (nrow(rows) != 24) stop("v15_missing_tokens_emptycell: expected 24 rows, got ", nrow(rows))

x_chr <- format(rows$x, digits = 15)

empty_cell_rows <- which(rows$group == "B" & rows$factor2 == "Sing")
if (length(empty_cell_rows) != 4)
    stop("v15_missing_tokens_emptycell: expected 4 rows in the emptied cell, got ",
         length(empty_cell_rows))
x_chr[empty_cell_rows] <- "NA"

out_df <- data.frame(id = rows$id, group = rows$group, factor2 = rows$factor2,
                      x = x_chr, y = rows$y, stringsAsFactors = FALSE)

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v15_missing_tokens_emptycell_input.csv")
write.csv(out_df, out, row.names = FALSE, quote = FALSE, na = "")
cat("wrote", out, "(", nrow(out_df), "rows, cell group=B factor2=Sing emptied )\n")
