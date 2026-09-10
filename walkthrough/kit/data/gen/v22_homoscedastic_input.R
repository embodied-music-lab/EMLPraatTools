# ============================================================================
# Generator for walkthrough/kit/data/v22_homoscedastic_input.csv
#
# Four groups, equal n and equal spread (SD 2 throughout), so that
# Brown-Forsythe does NOT reject at the alpha in force -- Welch's F and
# Games-Howell are still computed and named on the door, just not printed
# beside the standard result. Base R only, seeded for reproducibility.
#
#     Rscript walkthrough/kit/data/gen/v22_homoscedastic_input.R
# ============================================================================

set.seed(202)

groups <- c("A", "B", "C", "D")
n      <- c(A = 10, B = 10,  C = 10, D = 10)
mu     <- c(A = 60, B = 61,  C = 60.5, D = 62)
sd     <- c(A = 2,  B = 2,   C = 2,  D = 2)

rows <- do.call(rbind, lapply(groups, function(g) {
    data.frame(
        subject = paste0(g, "_", seq_len(n[[g]])),
        group   = g,
        SPL_dB  = rnorm(n[[g]], mu[[g]], sd[[g]]),
        stringsAsFactors = FALSE)
}))

z <- abs(rows$SPL_dB - ave(rows$SPL_dB, rows$group, FUN = median))
bf <- anova(lm(z ~ rows$group))
if (!(bf[["Pr(>F)"]][1] >= 0.05))
    stop("v22_homoscedastic: Brown-Forsythe now rejects at alpha 0.05 (p = ",
         bf[["Pr(>F)"]][1], ") -- fixture no longer matches its purpose")

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v22_homoscedastic_input.csv")
write.csv(rows, out, row.names = FALSE, quote = FALSE)
cat("wrote", out, "(", nrow(rows), "rows )\n")
