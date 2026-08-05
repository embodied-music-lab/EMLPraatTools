# ============================================================================
# EML Praat Tools — validation helpers
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Base R only. No packages are loaded and none need installing. Every
# statistic the plugin reports is recomputed here from first principles or
# from base `stats`, so an independent reviewer can run this suite against a
# stock R installation with no network access.
# ============================================================================

EML_RESULTS <- new.env(parent = emptyenv())
EML_RESULTS$rows <- list()

# ---------------------------------------------------------------------------
# repo_path — resolve a path relative to the repository root, regardless of
# the working directory the suite is launched from.
# ---------------------------------------------------------------------------
repo_path <- function(...) {
    here <- Sys.getenv("EML_VALIDATE_DIR", unset = NA)
    if (is.na(here)) {
        args <- commandArgs(trailingOnly = FALSE)
        f <- sub("^--file=", "", args[grep("^--file=", args)])
        here <- if (length(f)) dirname(normalizePath(f)) else getwd()
    }
    root <- dirname(here)
    file.path(root, ...)
}

read_input <- function(name) {
    p <- repo_path("evidence", "csv", name)
    if (!file.exists(p)) stop("input not found: ", p)
    read.csv(p, stringsAsFactors = FALSE)
}

# ---------------------------------------------------------------------------
# check — record one comparison between a value the plugin PRINTED and the
# value R computes.
#
#   id        finding or wrapper this belongs to
#   what      human description of the quantity
#   reported  the value the plugin printed, transcribed from the Info window
#   computed  what R computes here
#   tol       absolute tolerance; default follows the printed precision
#   expect    "match"  — these must agree; disagreement is a FAILURE
#             "differ" — these must NOT agree; agreement is a FAILURE.
#                        Used to pin a known defect (see D15).
# ---------------------------------------------------------------------------
check <- function(id, what, reported, computed, tol = 5e-4, expect = "match") {
    agree <- is.finite(reported) && is.finite(computed) &&
             abs(reported - computed) <= tol
    pass <- if (expect == "match") agree else !agree
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = reported, computed = computed,
        tol = tol, expect = expect, pass = pass, stringsAsFactors = FALSE
    )
    invisible(pass)
}

# check_below — the plugin floors small p-values to the string "< .001".
# All that can be validated is that R's value is genuinely below .001.
check_below <- function(id, what, threshold, computed) {
    pass <- is.finite(computed) && computed < threshold
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = NA_real_, computed = computed,
        tol = threshold, expect = paste0("< ", threshold), pass = pass,
        stringsAsFactors = FALSE
    )
    invisible(pass)
}

# check_true — a non-numeric assertion (a behaviour, a count, a condition).
check_true <- function(id, what, condition) {
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = NA_real_, computed = NA_real_,
        tol = NA_real_, expect = "TRUE", pass = isTRUE(condition),
        stringsAsFactors = FALSE
    )
    invisible(isTRUE(condition))
}

# ---------------------------------------------------------------------------
# Statistics the plugin reports that base R does not provide directly.
# Implemented from the standard definitions so the suite stays dependency-free.
# ---------------------------------------------------------------------------

# Cohen's d for two independent samples, pooled SD (the classic definition).
cohens_d <- function(a, b) {
    na <- length(a); nb <- length(b)
    sp <- sqrt(((na - 1) * var(a) + (nb - 1) * var(b)) / (na + nb - 2))
    (mean(a) - mean(b)) / sp
}

# Cohen's d_z for a paired design: mean difference over SD of differences.
cohens_dz <- function(a, b) {
    d <- a - b
    mean(d) / sd(d)
}

# r derived from a t statistic: r = t / sqrt(t^2 + df).
r_from_t <- function(t, df) t / sqrt(t^2 + df)

# Matched-pairs rank-biserial correlation for the Wilcoxon signed-rank test.
# r = 1 - 2W / (n(n+1)/2), with W the sum of ranks of the negative
# differences as returned by wilcox.test's V statistic convention.
rank_biserial_paired <- function(a, b) {
    d <- a - b
    d <- d[d != 0]
    n <- length(d)
    V <- suppressWarnings(unname(wilcox.test(a, b, paired = TRUE)$statistic))
    1 - 2 * (n * (n + 1) / 2 - V) / (n * (n + 1) / 2)
}

# One-way repeated-measures ANOVA on a subjects x conditions matrix,
# with the Greenhouse-Geisser epsilon.
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

# Kendall's W from the Friedman chi-square.
kendalls_w <- function(chisq, n, k) chisq / (n * (k - 1))

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
eml_report <- function(title) {
    df <- do.call(rbind, EML_RESULTS$rows)
    if (is.null(df)) { cat("no checks recorded\n"); return(invisible(NULL)) }
    cat("\n", strrep("=", 78), "\n", title, "\n", strrep("=", 78), "\n", sep = "")
    for (i in seq_len(nrow(df))) {
        r <- df[i, ]
        mark <- if (r$pass) "PASS" else "FAIL"
        val <- if (is.na(r$reported)) {
            sprintf("computed=%.10g  expected %s", r$computed, r$expect)
        } else {
            sprintf("reported=%.10g  computed=%.10g  (%s, tol %g)",
                    r$reported, r$computed, r$expect, r$tol)
        }
        cat(sprintf("%-4s  %-6s  %-46s  %s\n", mark, r$id, r$quantity, val))
    }
    n_fail <- sum(!df$pass)
    cat(strrep("-", 78), "\n")
    cat(sprintf("%d checks, %d passed, %d FAILED\n", nrow(df), sum(df$pass), n_fail))
    invisible(df)
}

eml_exit <- function() {
    df <- do.call(rbind, EML_RESULTS$rows)
    if (!is.null(df) && any(!df$pass)) quit(status = 1)
    invisible(NULL)
}
