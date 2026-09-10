# ============================================================================
# Generator for walkthrough/kit/data/v22_heteroscedastic_input.csv
#
# Four groups with sharply unequal spread (SD 1, 3, 6, 10) so that
# Brown-Forsythe rejects at the alpha in force while Welch's F and
# Games-Howell still print beside the standard one-way result. Base R only,
# seeded for reproducibility.
#
#     Rscript walkthrough/kit/data/gen/v22_heteroscedastic_input.R
# ============================================================================

set.seed(101)

groups <- c("A", "B", "C", "D")
n      <- c(A = 8,  B = 12, C = 15, D = 20)
mu     <- c(A = 60, B = 62, C = 61, D = 66)
sd     <- c(A = 1,  B = 3,  C = 6,  D = 10)

rows <- do.call(rbind, lapply(groups, function(g) {
    data.frame(
        subject = paste0(g, "_", seq_len(n[[g]])),
        group   = g,
        SPL_dB  = rnorm(n[[g]], mu[[g]], sd[[g]]),
        stringsAsFactors = FALSE)
}))

# Confirm the design does what the fixture is for before writing it: a
# regenerated fixture that stopped rejecting would silently break the kit
# case it exists to drive.
z <- abs(rows$SPL_dB - ave(rows$SPL_dB, rows$group, FUN = median))
bf <- anova(lm(z ~ rows$group))
if (!(bf[["Pr(>F)"]][1] < 0.05))
    stop("v22_heteroscedastic: Brown-Forsythe no longer rejects at alpha 0.05 (p = ",
         bf[["Pr(>F)"]][1], ") -- fixture no longer matches its purpose")

here <- local({
    a <- commandArgs(trailingOnly = FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else getwd()
})
out <- file.path(dirname(here), "v22_heteroscedastic_input.csv")
write.csv(rows, out, row.names = FALSE, quote = FALSE)
cat("wrote", out, "(", nrow(rows), "rows )\n")
