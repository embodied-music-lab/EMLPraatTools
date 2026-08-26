# v09 — one-way ANOVA with Tukey HSD post hoc, base R only.
# Cohen's d for the pairwise matrix is LIFTED verbatim from validate/helpers.R.

d <- read.csv("evidence/csv/v09_anova_tukey_input.csv", stringsAsFactors = FALSE)
d$voice_type <- factor(d$voice_type, levels = c("Soprano", "Mezzo", "Alto"))
g <- split(d$SPL_dB, d$voice_type)

# --- lifted from helpers.R --------------------------------------------------
cohens_d <- function(a, b) {
    na <- length(a); nb <- length(b)
    sp <- sqrt(((na - 1) * var(a) + (nb - 1) * var(b)) / (na + nb - 2))
    (mean(a) - mean(b)) / sp
}
# -----------------------------------------------------------------------------

fit <- aov(SPL_dB ~ voice_type, data = d)
s <- summary(fit)[[1]]
ss_b <- s[["Sum Sq"]][1]; ss_w <- s[["Sum Sq"]][2]
df_b <- s[["Df"]][1];     df_w <- s[["Df"]][2]
ms_b <- ss_b / df_b; ms_w <- ss_w / df_w
Fval <- unname(s[["F value"]][1]); pval <- unname(s[["Pr(>F)"]][1])
eta2 <- ss_b / (ss_b + ss_w)

cat("-- ANOVA Table --\n")
cat(sprintf("Source              SS              df    MS              F           p\n"))
cat(sprintf("Between             %-15.2f %-5d %-15.2f %-11.4f %.3g\n", ss_b, df_b, ms_b, Fval, pval))
cat(sprintf("Within              %-15.2f %-5d %-15.2f\n", ss_w, df_w, ms_w))
cat(sprintf("Total               %-15.2f %-5d\n\n", ss_b + ss_w, df_b + df_w))
cat(sprintf("F                   %.4f\n", Fval))
cat(sprintf("p                   %.3g\n", pval))
cat(sprintf("eta-squared         %.4f\n\n", eta2))

cat("-- Group Descriptives --\n")
for (nm in levels(d$voice_type)) {
    v <- g[[nm]]
    cat(sprintf("%-12s  N=%-4d Mean=%-8.2f SD=%-8.2f Median=%-8.2f\n",
                nm, length(v), mean(v), sd(v), median(v)))
}
cat("\n")

tk <- TukeyHSD(fit)$voice_type
cat("-- Tukey HSD (p adj, mean diff, 95% CI) --\n")
print(round(tk, 4))
cat("\n")

cat("-- Pairwise Cohen's d --\n")
lv <- levels(d$voice_type)
for (i in seq_along(lv)) for (j in seq_along(lv)) if (i != j) {
    cat(sprintf("%-10s vs %-10s  d = %7.3f\n", lv[i], lv[j], cohens_d(g[[lv[i]]], g[[lv[j]]])))
}
