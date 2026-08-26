# demo_rm3 — repeated measures across three conditions: RM-ANOVA with
# Greenhouse-Geisser correction, Friedman, and their respective post hocs.
# rm_anova (incl. Greenhouse-Geisser epsilon) and kendalls_w are LIFTED
# verbatim from validate/helpers.R -- base R's aov()/Error() gives F and p
# for the RM-ANOVA but not GG epsilon or partial eta squared directly.

d <- read.csv("evidence/csv/demo_rm3_input.csv", stringsAsFactors = FALSE)
conds <- c("SPL_soft", "SPL_medium", "SPL_loud")
Y <- as.matrix(d[, conds])

# --- lifted from helpers.R --------------------------------------------------
rm_anova <- function(Y) {
    n <- nrow(Y); k <- ncol(Y)
    gm <- mean(Y)
    subj_m <- rowMeans(Y); cond_m <- colMeans(Y)
    ss_cond <- n * sum((cond_m - gm)^2)
    ss_subj <- k * sum((subj_m - gm)^2)
    ss_tot  <- sum((Y - gm)^2)
    ss_err  <- ss_tot - ss_cond - ss_subj
    df_c <- k - 1; df_e <- (k - 1) * (n - 1)
    ms_c <- ss_cond / df_c; ms_e <- ss_err / df_e
    f <- ms_c / ms_e
    p <- pf(f, df_c, df_e, lower.tail = FALSE)

    S  <- cov(Y)
    sb <- mean(S); rm_ <- rowMeans(S)
    num <- k^2 * (mean(diag(S)) - sb)^2
    den <- (k - 1) * (sum(S^2) - 2 * k * sum(rm_^2) + k^2 * sb^2)
    gg  <- num / den

    list(F = f, df1 = df_c, df2 = df_e, p = p, gg = gg,
         p_gg = pf(f, df_c * gg, df_e * gg, lower.tail = FALSE),
         partial_eta2 = ss_cond / (ss_cond + ss_err),
         means = cond_m, n = n, k = k)
}
kendalls_w <- function(chisq, n, k) chisq / (n * (k - 1))
# -----------------------------------------------------------------------------

fit <- rm_anova(Y)
cat(sprintf("Subjects (complete cases) n = %d, conditions k = %d\n", fit$n, fit$k))
cat(sprintf("  SPL_soft mean = %.4f\n", fit$means["SPL_soft"]))
cat(sprintf("  SPL_medium mean = %.4f\n", fit$means["SPL_medium"]))
cat(sprintf("  SPL_loud mean = %.4f\n", fit$means["SPL_loud"]))
cat(sprintf("F(%d, %d) = %.4f, p = %.6g\n", fit$df1, fit$df2, fit$F, fit$p))
cat(sprintf("Greenhouse-Geisser epsilon = %.4f, GG-corrected p = %.6g\n", fit$gg, fit$p_gg))
cat(sprintf("Partial eta squared = %.4f\n\n", fit$partial_eta2))

pr <- c(
    t.test(Y[, "SPL_soft"],   Y[, "SPL_medium"], paired = TRUE)$p.value,
    t.test(Y[, "SPL_soft"],   Y[, "SPL_loud"],   paired = TRUE)$p.value,
    t.test(Y[, "SPL_medium"], Y[, "SPL_loud"],   paired = TRUE)$p.value
)
pa <- p.adjust(pr, method = "holm")
pairs <- c("SPL_soft vs SPL_medium", "SPL_soft vs SPL_loud", "SPL_medium vs SPL_loud")
cat("Post-hoc pairwise (parametric, Holm-adjusted):\n")
for (i in seq_along(pairs)) {
    cat(sprintf("  %s: raw p = %.6g, adj p = %.6g\n", pairs[i], pr[i], pa[i]))
}

cat("\n============================\n")
cat("Friedman test\n")
ft <- friedman.test(Y)
ranks <- t(apply(Y, 1, rank))
rs <- colSums(ranks)
w <- kendalls_w(unname(ft$statistic), nrow(Y), ncol(Y))

cat(sprintf("Subjects (complete cases) n = %d, conditions k = %d\n", nrow(Y), ncol(Y)))
cat(sprintf("  SPL_soft rank sum = %.1f\n", rs["SPL_soft"]))
cat(sprintf("  SPL_medium rank sum = %.1f\n", rs["SPL_medium"]))
cat(sprintf("  SPL_loud rank sum = %.1f\n", rs["SPL_loud"]))
cat(sprintf("chi-square(%d) = %.4f, p = %.6g\n", unname(ft$parameter), unname(ft$statistic), ft$p.value))
cat(sprintf("Kendall's W = %.4f\n\n", w))

prF <- suppressWarnings(c(
    wilcox.test(Y[, "SPL_soft"],   Y[, "SPL_medium"], paired = TRUE)$p.value,
    wilcox.test(Y[, "SPL_soft"],   Y[, "SPL_loud"],   paired = TRUE)$p.value,
    wilcox.test(Y[, "SPL_medium"], Y[, "SPL_loud"],   paired = TRUE)$p.value
))
paF <- p.adjust(prF, method = "holm")
cat("Post-hoc pairwise (nonparametric, Holm-adjusted):\n")
for (i in seq_along(pairs)) {
    cat(sprintf("  %s: raw p = %.6g, adj p = %.6g\n", pairs[i], prF[i], paF[i]))
}
