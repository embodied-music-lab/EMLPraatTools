# ===========================================================================
# lane_survey_oracle_dump.R — committed oracle record for the survey-stats
# lane (Cronbach's alpha, chi-square + Cramér's V, Wilson intervals)
# ===========================================================================
# Recomputes every oracle value the lane's validators (v90, v91, v92)
# settle the kernels against, from the committed fixtures in
# evidence/csv/, and writes lane_survey_oracle_values.csv next to this
# script. The values come from the actual oracle calls — psych::alpha,
# chisq.test, prop.test(correct = FALSE) — not from a transcription of
# their formulas ("a transcription can silently correct the thing it
# copies"). Run:
#     Rscript lane_survey_oracle_dump.R
# Requires the psych package (r-cran-psych).
# ===========================================================================

here <- (function() {
    a <- commandArgs(FALSE)
    f <- sub("^--file=", "", a[grep("^--file=", a)])
    if (length(f)) dirname(normalizePath(f)) else "."
})()
csvdir <- normalizePath(file.path(here, "..", "..", "evidence", "csv"))

rows <- list()
put <- function(stat, value, tol) {
    rows[[length(rows) + 1L]] <<- data.frame(stat = stat, value = value,
                                             tol = tol)
}

# --- Cronbach's alpha ----------------------------------------------------

stopifnot(requireNamespace("psych", quietly = TRUE))
for (fx in c("clean", "revnotrev", "2item", "missing")) {
    m <- as.matrix(read.csv(file.path(csvdir,
                                      paste0("lane_survey_alpha_", fx, ".csv"))))
    cc <- m[complete.cases(m), , drop = FALSE]
    a <- suppressWarnings(psych::alpha(as.data.frame(cc),
                                       check.keys = FALSE, warnings = FALSE))
    put(paste0("alpha_", fx), a$total$raw_alpha, 1e-10)
    put(paste0("alpha_", fx, "_feldt_lo"), a$feldt$lower.ci[[1]], 1e-8)
    put(paste0("alpha_", fx, "_feldt_hi"), a$feldt$upper.ci[[1]], 1e-8)
    put(paste0("alpha_", fx, "_n"), nrow(cc), 0)
    put(paste0("alpha_", fx, "_nExcluded"), nrow(m) - nrow(cc), 0)
    if (ncol(m) >= 3) {
        for (j in seq_len(ncol(m))) {
            put(sprintf("alpha_%s_drop%d", fx, j),
                a$alpha.drop$raw_alpha[j], 1e-10)
        }
    }
}

# --- Chi-square + Cramér's V --------------------------------------------

for (fx in c("2x2_balanced", "2x2_sparse", "3x4", "zerocell")) {
    m <- as.matrix(read.csv(file.path(csvdir,
                                      paste0("lane_survey_chisq_", fx, ".csv"))))
    for (corr in c(TRUE, FALSE)) {
        r <- suppressWarnings(chisq.test(m, correct = corr))
        key <- sprintf("chisq_%s_c%d", fx, as.integer(corr))
        put(paste0(key, "_stat"), unname(r$statistic), 1e-10)
        put(paste0(key, "_df"), unname(r$parameter), 0)
        put(paste0(key, "_p"), r$p.value, 1e-10)
    }
    r0 <- suppressWarnings(chisq.test(m, correct = FALSE))
    put(paste0("chisq_", fx, "_cramersV"),
        sqrt(unname(r0$statistic) / (sum(m) * (min(dim(m)) - 1))), 1e-10)
    put(paste0("chisq_", fx, "_minExpected"), min(r0$expected), 1e-10)
    put(paste0("chisq_", fx, "_nBelow5"), sum(r0$expected < 5), 0)
}

# --- Wilson intervals ----------------------------------------------------

cases <- read.csv(file.path(csvdir, "lane_survey_wilson_cases.csv"))
for (i in seq_len(nrow(cases))) {
    cs <- cases[i, ]
    ci <- suppressWarnings(prop.test(cs$x, cs$n, conf.level = cs$conf,
                                     correct = FALSE)$conf.int)
    put(paste0("wilson_", cs$case, "_lo"), ci[1], 1e-10)
    put(paste0("wilson_", cs$case, "_hi"), ci[2], 1e-10)
}

out <- do.call(rbind, rows)
outfile <- file.path(here, "lane_survey_oracle_values.csv")
write.csv(out, outfile, row.names = FALSE)
cat(sprintf("wrote %d oracle values to %s\n", nrow(out), outfile))
