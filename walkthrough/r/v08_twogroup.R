# v08 — Compare two groups (Control vs Patient), base R only.
# Nonstandard statistics (Cohen's d, rank-biserial r) are LIFTED verbatim
# from validate/helpers.R, not reimplemented.

d <- read.csv("evidence/csv/v08_twogroup_input.csv", stringsAsFactors = FALSE)
lv <- unique(d$group)                 # table order: Control, Patient
a <- d$jitter_pct[d$group == lv[1]]   # Control
b <- d$jitter_pct[d$group == lv[2]]   # Patient

# --- lifted from helpers.R --------------------------------------------------
cohens_d <- function(a, b) {
    na <- length(a); nb <- length(b)
    sp <- sqrt(((na - 1) * var(a) + (nb - 1) * var(b)) / (na + nb - 2))
    (mean(a) - mean(b)) / sp
}
rank_biserial_indep <- function(a, b) {
    U1 <- suppressWarnings(unname(wilcox.test(a, b)$statistic))
    U2 <- length(a) * length(b) - U1
    (U1 - U2) / (length(a) * length(b))
}
# -----------------------------------------------------------------------------

cat(sprintf("Group         N     Mean      SD        Median\n"))
cat(sprintf("Control       %-5d %-9.2f %-9.2f %-9.2f\n",
            length(a), mean(a), sd(a), median(a)))
cat(sprintf("Patient       %-5d %-9.2f %-9.2f %-9.2f\n\n",
            length(b), mean(b), sd(b), median(b)))

tt <- t.test(a, b, var.equal = FALSE)
cat("-- Welch --\n")
cat(sprintf("t                   %.3f\n", unname(tt$statistic)))
cat(sprintf("df                  %.1f\n", unname(tt$parameter)))
cat(sprintf("p                   %.3g\n", tt$p.value))
cat(sprintf("Mean difference     %.4f\n\n", mean(a) - mean(b)))

d_val <- cohens_d(a, b)
J <- 1 - 3 / (4 * (length(a) + length(b)) - 9)
cat("-- Effect Size --\n")
cat(sprintf("Cohen's d           %.3f\n", d_val))
cat(sprintf("Hedges' g           %.3f\n\n", d_val * J))

wt <- suppressWarnings(wilcox.test(a, b, exact = TRUE))
U1 <- unname(wt$statistic)
U2 <- length(a) * length(b) - U1
cat("-- Mann-Whitney U Test --\n")
cat(sprintf("U1                  %.1f\n", U1))
cat(sprintf("U2                  %.1f\n", U2))
cat(sprintf("p                   %.3g\n", wt$p.value))
cat(sprintf("Method              %s\n\n", "exact"))

rb <- rank_biserial_indep(a, b)
cat("-- Nonparametric Effect Size --\n")
cat(sprintf("Rank-biserial r     %.3f\n", rb))
