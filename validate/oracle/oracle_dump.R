#!/usr/bin/env Rscript
# ============================================================================
# oracle_dump.R — compute every nonstandard statistic in helpers.R on the
# committed inputs and write them to oracle_values.csv for cross-checking
# by oracle_check.py against scipy / pingouin / scikit-posthocs.
#
# This half runs under the base suite's charter (stock R, no packages).
# The Python half is an OPTIONAL tier and is not required by run_all.R.
#
# The point of the two-file design: the values checked are produced by the
# ACTUAL functions in helpers.R, not a transcription of their formulas into
# another language. A transcription can silently correct the thing it copies.
# ============================================================================
.a <- commandArgs(FALSE)
.f <- sub("^--file=", "", .a[grep("^--file=", .a)])
HERE <- if (length(.f)) dirname(normalizePath(.f)) else getwd()
Sys.setenv(EML_VALIDATE_DIR = dirname(HERE))
source(file.path(dirname(HERE), "helpers.R"))

rows <- list()
put <- function(stat, value, tol) {
    rows[[length(rows) + 1L]] <<- data.frame(stat = stat, value = value, tol = tol)
}

# --- RM-ANOVA + GG epsilon + Kendall's W on demo_rm3_input ------------------
d  <- read_input("demo_rm3_input.csv")
Y  <- as.matrix(d[, c("SPL_soft", "SPL_medium", "SPL_loud")])
f  <- rm_anova(Y)
put("rm_anova_F",   f$F,  1e-6)
put("rm_anova_gg",  f$gg, 1e-9)
ft <- friedman.test(Y)
put("friedman_chisq", unname(ft$statistic), 1e-9)
put("kendalls_w", kendalls_w(unname(ft$statistic), nrow(Y), ncol(Y)), 1e-9)

# --- Cohen's dz on demo_paired_input (vs t/sqrt(n), an independent path) ----
dp <- read_input("demo_paired_input.csv")
put("cohens_dz", cohens_dz(dp$jitter_pre, dp$jitter_post), 1e-9)
put("rank_biserial_paired",
    rank_biserial_paired(dp$jitter_pre, dp$jitter_post), 1e-12)

# --- two-group statistics on v08_twogroup_input -----------------------------
d8 <- read_input("v08_twogroup_input.csv")
a  <- d8$jitter_pct[d8$group == "Control"]
b  <- d8$jitter_pct[d8$group == "Patient"]
put("cohens_d_pooled", cohens_d(a, b), 1e-9)
J <- 1 - 3 / (4 * (length(a) + length(b)) - 9)
put("hedges_g", cohens_d(a, b) * J, 1e-4)
put("rank_biserial_indep", rank_biserial_indep(a, b), 1e-9)

# --- Kruskal-Wallis / Dunn / epsilon-squared on v10_kw_dunn_input -----------
d10 <- read_input("v10_kw_dunn_input.csv")
kw  <- kruskal.test(SPL_dB ~ factor(voice_type, levels = unique(voice_type)),
                    data = d10)
dn  <- dunn_test(d10$SPL_dB, d10$voice_type)
put("kw_H", unname(kw$statistic), 1e-9)
put("epsilon_squared", epsilon_squared(unname(kw$statistic), nrow(d10)), 1e-9)
put("dunn_p_Soprano_Mezzo", dn$p["Soprano", "Mezzo"], 1e-10)
put("dunn_p_Soprano_Alto",  dn$p["Soprano", "Alto"],  1e-10)
put("dunn_p_Mezzo_Alto",    dn$p["Mezzo",   "Alto"],  1e-10)
raw <- c(dn$p["Soprano", "Mezzo"], dn$p["Soprano", "Alto"], dn$p["Mezzo", "Alto"])
adj <- holm_adjust(raw)
put("holm_adj_1", adj[1], 1e-12)
put("holm_adj_2", adj[2], 1e-12)
put("holm_adj_3", adj[3], 1e-12)

# --- G1 / G2 on v14_descriptive_input ---------------------------------------
d14 <- read_input("v14_descriptive_input.csv")
put("skewness_g1",     skewness_g1(d14$SPL_dB),     1e-10)
put("excess_kurtosis", excess_kurtosis(d14$SPL_dB), 1e-10)

# --- Shapiro-Wilk on the three v15 columns ----------------------------------
d15 <- read_input("v15_normality_input.csv")
for (nm in c("F0_Hz", "shimmer_pct", "jitter_pct")) {
    sw <- shapiro.test(d15[[nm]])
    put(paste0("shapiro_W_", nm), unname(sw$statistic), 1e-6)
    put(paste0("shapiro_p_", nm), unname(sw$p.value),   1e-4)
}

out <- file.path(HERE, "oracle_values.csv")
write.csv(do.call(rbind, rows), out, row.names = FALSE)
cat("wrote ", length(rows), " values to ", out, "\n", sep = "")
