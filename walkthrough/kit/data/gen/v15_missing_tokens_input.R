# ============================================================================
# Generator for walkthrough/kit/data/v15_missing_tokens_input.csv
#
# n = 24: three levels of `group` crossed with two of `factor2`, four rows
# per cell. Column `x` carries one of each missing-value token from the
# canon (empty, NA, n/a, --undefined--, ?, .), one per cell, so no cell is
# emptied; column `y` is complete throughout. Every analysis door that
# reads `x` -- the two-way door included, on group x factor2 -- must
# exclude and list exactly those six rows; R reads the same file with
# na.strings from validate/canon/missing_tokens.tsv. Base R only, seeded
# for reproducibility; the six token rows are chosen with a fixed seed and
# then imposed by name, not by search, since token PLACEMENT (not the
# underlying numbers) is what this fixture tests.
#
#     Rscript walkthrough/kit/data/gen/v15_missing_tokens_input.R
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

if (nrow(rows) != 24) stop("v15_missing_tokens: expected 24 rows, got ", nrow(rows))

# x becomes character once the tokens are spliced in; keep full precision
# for the untouched numeric rows the same way the plugin's own tables would
# print them.
x_chr <- format(rows$x, digits = 15)

# One token per cell (first row of each 4-row block), covering the full
# canon list once each: empty, NA, n/a, --undefined--, ?, .
token_rows  <- c(1, 5, 9, 13, 17, 21)
tokens      <- c("", "NA", "n/a", "--undefined--", "?", ".")
x_chr[token_rows] <- tokens

out_df <- data.frame(id = rows$id, group = rows$group, factor2 = rows$factor2,
                      x = x_chr, y = rows$y, stringsAsFactors = FALSE)

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v15_missing_tokens_input.csv")
write.csv(out_df, out, row.names = FALSE, quote = FALSE, na = "")
cat("wrote", out, "(", nrow(out_df), "rows,", length(token_rows), "missing tokens )\n")
