# run_analyses.R -- base R reproduction of six EML Stats & Graphs analyses.
#
# Self-contained: reads its six CSVs from data/ (relative to THIS file's own
# location, not the working directory) and writes one report per analysis
# into out/, named r_<dataset>.txt. Each report also prints to the console.
#
# No packages. Everything nonstandard (Cohen's d, rank-biserial r, Dunn's
# test, epsilon-squared, Holm adjustment, the RM-ANOVA Greenhouse-Geisser
# helper, Kendall's W) is lifted verbatim from validate/helpers.R in the
# source repository -- reproduced here so the file needs nothing else.
# No statistic differs from the six original scripts under walkthrough/r/.

# --- locate this file / self-relative paths ---------------------------------
emlThisFile <- function() {
    args <- commandArgs(trailingOnly = FALSE)
    fileArg <- sub("^--file=", "", args[grepl("^--file=", args)])
    if (length(fileArg)) return(normalizePath(fileArg))
    normalizePath(sys.frames()[[1]]$ofile)
}
kitDir <- dirname(emlThisFile())
dataDir <- file.path(kitDir, "data")
outDir  <- file.path(kitDir, "out")
dir.create(outDir, showWarnings = FALSE)

emlReport <- function(name, expr) {
    con <- textConnection("emlBuf", "w", local = TRUE)
    sink(con)
    force(expr)
    sink()
    close(con)
    text <- paste(emlBuf, collapse = "\n")
    cat(text, "\n")
    writeLines(text, file.path(outDir, paste0("r_", name, ".txt")))
}

# =============================================================================
# v08 -- two independent groups (Welch t, Mann-Whitney U, Cohen's d / RB r)
# =============================================================================
emlReport("v08_twogroup_input", {
    d <- read.csv(file.path(dataDir, "v08_twogroup_input.csv"), stringsAsFactors = FALSE)
    lv <- unique(d$group)
    a <- d$jitter_pct[d$group == lv[1]]
    b <- d$jitter_pct[d$group == lv[2]]

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
})

# =============================================================================
# v09 -- one-way ANOVA + Tukey HSD
# =============================================================================
emlReport("v09_anova_tukey_input", {
    d <- read.csv(file.path(dataDir, "v09_anova_tukey_input.csv"), stringsAsFactors = FALSE)
    d$voice_type <- factor(d$voice_type, levels = c("Soprano", "Mezzo", "Alto"))
    g <- split(d$SPL_dB, d$voice_type)

    cohens_d <- function(a, b) {
        na <- length(a); nb <- length(b)
        sp <- sqrt(((na - 1) * var(a) + (nb - 1) * var(b)) / (na + nb - 2))
        (mean(a) - mean(b)) / sp
    }

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
})

# =============================================================================
# v10 -- Kruskal-Wallis + Dunn's post hoc (Holm)
# =============================================================================
emlReport("v10_kw_dunn_input", {
    d <- read.csv(file.path(dataDir, "v10_kw_dunn_input.csv"), stringsAsFactors = FALSE)
    d$voice_type <- factor(d$voice_type, levels = c("Soprano", "Mezzo", "Alto"))
    g <- split(d$SPL_dB, d$voice_type)
    N <- nrow(d)

    epsilon_squared <- function(H, N) H / ((N^2 - 1) / (N + 1))

    dunn_test <- function(x, g) {
        ok <- !is.na(x) & !is.na(g)
        x <- x[ok]; g <- factor(g[ok])
        N <- length(x); r <- rank(x)
        tie <- table(r)
        Tc <- sum(tie^3 - tie) / (12 * (N - 1))
        lv <- levels(g)
        Rbar <- tapply(r, g, mean); n <- tapply(r, g, length)
        z <- matrix(NA_real_, length(lv), length(lv), dimnames = list(lv, lv))
        p <- z
        for (i in seq_along(lv)) for (j in seq_along(lv)) {
            if (i == j) next
            se <- sqrt((N * (N + 1) / 12 - Tc) * (1 / n[i] + 1 / n[j]))
            z[i, j] <- (Rbar[i] - Rbar[j]) / se
            p[i, j] <- 2 * pnorm(-abs(z[i, j]))
        }
        list(z = z, p = p, meanrank = Rbar, n = n, levels = lv)
    }

    holm_adjust <- function(p) {
        m <- length(p); o <- order(p); adj <- numeric(m); run <- 0
        for (i in seq_len(m)) {
            run <- max(run, (m - i + 1) * p[o[i]])
            adj[o[i]] <- min(1, run)
        }
        adj
    }

    rank_biserial_indep <- function(a, b) {
        U1 <- suppressWarnings(unname(wilcox.test(a, b)$statistic))
        U2 <- length(a) * length(b) - U1
        (U1 - U2) / (length(a) * length(b))
    }

    kw <- kruskal.test(SPL_dB ~ voice_type, data = d)
    eps2 <- epsilon_squared(unname(kw$statistic), N)

    cat("-- Omnibus Test --\n")
    cat(sprintf("H                   %.4f\n", unname(kw$statistic)))
    cat(sprintf("df                  %d\n", unname(kw$parameter)))
    cat(sprintf("Total N             %d\n", N))
    cat(sprintf("Groups              %d\n", nlevels(d$voice_type)))
    cat(sprintf("p                   %.3g\n", kw$p.value))
    cat(sprintf("Epsilon-squared     %.4f\n\n", eps2))

    dn <- dunn_test(d$SPL_dB, d$voice_type)
    cat("-- Group Mean Ranks --\n")
    for (nm in levels(d$voice_type)) {
        cat(sprintf("%-12s N=%-4d MeanRank=%.2f\n", nm, dn$n[nm], dn$meanrank[nm]))
    }
    cat("\n")

    raw <- c(SM = dn$p["Soprano", "Mezzo"],
             SA = dn$p["Soprano", "Alto"],
             MA = dn$p["Mezzo",   "Alto"])
    adj <- holm_adjust(raw); names(adj) <- names(raw)

    cat("-- Dunn's z-statistics --\n")
    print(round(dn$z, 3))
    cat("\n-- Dunn's Post-Hoc adjusted p (Holm) --\n")
    cat(sprintf("Soprano-Mezzo  %.4g\n", adj[["SM"]]))
    cat(sprintf("Soprano-Alto   %.4g\n", adj[["SA"]]))
    cat(sprintf("Mezzo-Alto     %.4g\n\n", adj[["MA"]]))

    cat("-- Pairwise rank-biserial r --\n")
    lv <- levels(d$voice_type)
    for (i in seq_along(lv)) for (j in seq_along(lv)) if (i != j) {
        cat(sprintf("%-10s vs %-10s  r = %7.3f\n", lv[i], lv[j], rank_biserial_indep(g[[lv[i]]], g[[lv[j]]])))
    }
})

# =============================================================================
# demo_rm3 -- RM-ANOVA (Greenhouse-Geisser) + Friedman, both with post hoc
# =============================================================================
emlReport("demo_rm3_input", {
    d <- read.csv(file.path(dataDir, "demo_rm3_input.csv"), stringsAsFactors = FALSE)
    conds <- c("SPL_soft", "SPL_medium", "SPL_loud")
    Y <- as.matrix(d[, conds])

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
})

# =============================================================================
# v12 -- Pearson + Spearman correlation
# =============================================================================
emlReport("v12_correlation_input", {
    d <- read.csv(file.path(dataDir, "v12_correlation_input.csv"), stringsAsFactors = FALSE)
    x <- d$speaking_F0_Hz
    y <- d$singing_F0_Hz
    n <- length(x)

    t_from_r <- function(r, n) r * sqrt((n - 2) / (1 - r^2))

    cat(sprintf("N                   %d\n\n", n))

    pe <- cor.test(x, y, method = "pearson")
    cat("-- Pearson Correlation --\n")
    cat(sprintf("r                   %.4f\n", unname(pe$estimate)))
    cat(sprintf("t                   %.3f\n", unname(pe$statistic)))
    cat(sprintf("df                  %d\n", unname(pe$parameter)))
    cat(sprintf("p                   %.3g\n\n", pe$p.value))

    sp <- suppressWarnings(cor.test(x, y, method = "spearman"))
    rho <- unname(sp$estimate)
    t_s <- t_from_r(rho, n)
    p_s <- 2 * pt(-abs(t_s), n - 2)
    cat("-- Spearman Correlation --\n")
    cat(sprintf("rho                 %.4f\n", rho))
    cat(sprintf("t (approx, from rho) %.3f\n", t_s))
    cat(sprintf("df                  %d\n", n - 2))
    cat(sprintf("p (approx, from t)  %.3g\n", p_s))
    cat(sprintf("p (exact, cor.test) %.3g   [cor.test's own S-statistic exact/AS89 p; NOT what's shown above]\n", sp$p.value))
})

# =============================================================================
# v13 -- simple linear regression
# =============================================================================
emlReport("v13_regression_input", {
    d <- read.csv(file.path(dataDir, "v13_regression_input.csv"), stringsAsFactors = FALSE)
    x <- d$practice_hrs_wk
    y <- d$vibrato_regularity_pct
    n <- length(x)

    fit <- lm(y ~ x)
    sm  <- summary(fit)
    co  <- coef(sm)
    fs  <- sm$fstatistic

    cat(sprintf("N                   %d\n\n", n))
    cat("-- Model --\n")
    cat(sprintf("Equation            y = %.4fx + %.4f\n", co["x", "Estimate"], co["(Intercept)", "Estimate"]))
    cat(sprintf("R                   %.4f\n", sign(co["x", "Estimate"]) * sqrt(sm$r.squared)))
    cat(sprintf("R-squared           %.4f\n", sm$r.squared))
    cat(sprintf("Adj. R-squared      %.4f\n", sm$adj.r.squared))
    cat(sprintf("Residual SE         %.4f\n\n", sm$sigma))

    cat("-- Overall Model Test (F) --\n")
    cat(sprintf("F(%d,%d)             %.4f\n", fs["numdf"], fs["dendf"], fs["value"]))
    cat(sprintf("p                   %.3g\n\n", pf(fs["value"], fs["numdf"], fs["dendf"], lower.tail = FALSE)))

    cat("-- Coefficients --\n")
    cat(sprintf("%-18s Estimate   SE         t          p\n", ""))
    cat(sprintf("Intercept          %-10.4f %-10.4f %-10.3f %.3g\n",
                co["(Intercept)", "Estimate"], co["(Intercept)", "Std. Error"],
                co["(Intercept)", "t value"], co["(Intercept)", "Pr(>|t|)"]))
    cat(sprintf("practice_hrs_wk    %-10.4f %-10.4f %-10.3f %.3g\n",
                co["x", "Estimate"], co["x", "Std. Error"],
                co["x", "t value"], co["x", "Pr(>|t|)"]))

    cat(sprintf("\nDirection: %s\n", if (co["x", "Estimate"] > 0) "positive" else "negative"))
})

cat(sprintf("\nAll six reports written to %s\n", outDir))
