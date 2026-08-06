# ============================================================================
# v21_shipping_paths_broom.R -- the other ten shipping paths, in broom's shape.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Same standard as v20 and for the same reason: every file checked here was
# written by the ORCHESTRATOR THE MENU CALLS, driven by
# harness/broom_cases/all_paths_drive.praat. A check against the writer called
# directly proves the writer works and nothing about a path a user can reach.
#
# broom is not installable on R 4.3.3 here, so structural claims are asserted
# from broom's documented contract and every VALUE against base R. Each check
# says which of the two it is.
#
# SHAPE NOTE, asserted rather than assumed: broom has no augment() for htest
# objects. The two-group, paired, correlation, Kruskal-Wallis, normality and
# Friedman paths therefore emit tidy and glance only, and this script checks
# that no augment file was written for them -- an empty or padded augment
# would be a defect, not a courtesy.
#
#     Rscript validate/v21_shipping_paths_broom.R
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

B <- repo_path("evidence", "csv_export", "broom")
E <- function(f) read.csv(repo_path("evidence", "csv", f), stringsAsFactors = FALSE)
rd <- function(base, part)
    read.csv(file.path(B, paste0(base, "_", part, ".csv")),
             stringsAsFactors = FALSE, check.names = FALSE)
has <- function(base, part) file.exists(file.path(B, paste0(base, "_", part, ".csv")))

# broom emits no augment for an htest. Assert the absence.
no_augment <- function(base)
    check_true("v21", paste(base, "writes no augment (broom has none for htest)"),
               !has(base, "augment"))

# ---- 2. two independent groups -------------------------------------------
d  <- E("v08_twogroup_input.csv")
g  <- split(d$F0_Hz, d$group)
tt <- t.test(g[[1]], g[[2]], var.equal = FALSE)
mw <- suppressWarnings(wilcox.test(g[[1]], g[[2]]))
ti <- rd("ship_twogroup", "tidy"); gl <- rd("ship_twogroup", "glance")
check_true("v21", "twogroup tidy has one row per test family run", nrow(ti) == 2L)
check_true("v21", "twogroup tidy uses broom's htest columns, no term",
           all(c("estimate","estimate1","estimate2","statistic","p.value",
                 "parameter","method") %in% names(ti)) && !("term" %in% names(ti)))
check("v21", "twogroup Welch t",  ti$statistic[1], unname(tt$statistic), tol = 1e-9)
check("v21", "twogroup Welch df", ti$parameter[1], unname(tt$parameter), tol = 1e-9)
check("v21", "twogroup Welch p",  ti$p.value[1],   tt$p.value,           tol = 1e-12)
check("v21", "twogroup mean diff", ti$estimate[1],
      unname(tt$estimate[1] - tt$estimate[2]), tol = 1e-9)
check("v21", "twogroup Mann-Whitney U", ti$statistic[2], unname(mw$statistic), tol = 1e-9)
check("v21", "twogroup Mann-Whitney p", ti$p.value[2],   mw$p.value,           tol = 1e-6)
check("v21", "twogroup glance nobs", gl$nobs, nrow(d), tol = 0)
no_augment("ship_twogroup")

es <- rd("ship_twogroup", "effectsize_tidy")
check_true("v21", "twogroup effect sizes are their own frame with 3 rows",
           nrow(es) == 3L)
n1 <- length(g[[1]]); n2 <- length(g[[2]])
sp <- sqrt(((n1-1)*var(g[[1]]) + (n2-1)*var(g[[2]])) / (n1+n2-2))
check("v21", "twogroup Cohen's d",
      es$effect.size[es$effect.size.type == "cohens.d"],
      (mean(g[[1]]) - mean(g[[2]])) / sp, tol = 1e-9)

# ---- 3. Kruskal-Wallis ----------------------------------------------------
d  <- E("v10_kw_dunn_input.csv")
kw <- kruskal.test(SPL_dB ~ factor(voice_type), data = d)
ti <- rd("ship_kruskal", "tidy"); gl <- rd("ship_kruskal", "glance")
check_true("v21", "kruskal tidy is one row", nrow(ti) == 1L)
check("v21", "kruskal H",  ti$statistic, unname(kw$statistic), tol = 1e-9)
check("v21", "kruskal df", ti$parameter, unname(kw$parameter), tol = 0)
check("v21", "kruskal p",  ti$p.value,   kw$p.value,           tol = 1e-12)
tt2 <- table(d$SPL_dB); n <- nrow(d)
check("v21", "kruskal tie correction from its definition",
      gl$tie.correction, 1 - sum(tt2^3 - tt2) / (n^3 - n), tol = 1e-12)
no_augment("ship_kruskal")

ph <- rd("ship_kruskal", "posthoc_tidy")
check_true("v21", "Dunn frame has one row per pair", nrow(ph) == 3L)
check_true("v21", "Dunn frame carries BOTH raw and adjusted p",
           all(c("p.value","adj.p.value") %in% names(ph)))
check_true("v21", "Dunn adjusted p is never below raw p",
           all(ph$adj.p.value >= ph$p.value - 1e-12))

# ---- 4. pairwise (a BUILD: this path exported nothing at all before) ------
d  <- E("demo_3groups_input.csv")
ti <- rd("ship_pairwise", "tidy"); gl <- rd("ship_pairwise", "glance")
check_true("v21", "pairwise tidy exists at all (D66: it exported nothing)",
           nrow(ti) == 3L)
check_true("v21", "pairwise carries contrast, raw p and adjusted p",
           all(c("contrast","p.value","adj.p.value") %in% names(ti)))
check("v21", "pairwise n.pairs", gl$n.pairs, 3, tol = 0)
pw <- pairwise.t.test(d$SPL_dB, d$voice_type, p.adjust.method = "bonferroni",
                      pool.sd = FALSE)
# R returns a lower-triangular matrix, so a contrast is present in exactly one
# of the two orientations. Look both up rather than assuming which.
pw_lookup <- function(a, b) {
  m <- pw$p.value
  if (a %in% rownames(m) && b %in% colnames(m) && !is.na(m[a, b])) return(m[a, b])
  if (b %in% rownames(m) && a %in% colnames(m) && !is.na(m[b, a])) return(m[b, a])
  NA_real_
}
for (i in seq_len(nrow(ti))) {
  parts <- strsplit(ti$contrast[i], "-", fixed = TRUE)[[1]]
  rv <- pw_lookup(parts[1], parts[2])
  check_true("v21", paste("pairwise contrast", ti$contrast[i], "exists in R too"),
             !is.na(rv))
  if (is.na(rv)) next
  check("v21", paste("pairwise adj p", ti$contrast[i]), ti$adj.p.value[i], rv,
        tol = 1e-9)
}

# ---- 5. two-way ANOVA -----------------------------------------------------
d   <- E("v11_twoway_input.csv")
fit <- aov(SPL_dB ~ voice_type * task, data = d)
s   <- summary(fit)[[1]]
ti  <- rd("ship_twoway", "tidy"); gl <- rd("ship_twoway", "glance")
check_true("v21", "twoway tidy is 3 terms plus Residuals", nrow(ti) == 4L)
check_true("v21", "twoway names the interaction as R does, a:b",
           ti$term[3] == "voice_type:task")
rn <- trimws(rownames(s))
# Looser than the one-way tolerances (1e-9), and deliberately so. R fits the
# two-way model by QR on the model matrix; the plugin accumulates cell sums.
# The two are algebraically identical and differ only in rounding order, which
# on sums of squares near 1000 shows up around 4e-7 absolute -- a relative
# agreement of about 1e-9, the same standard as everywhere else, expressed
# against a larger quantity. Tightening this would be asserting an equality of
# floating-point summation ORDER, which is not a claim about correctness.
for (k in 1:4) {
  j <- match(ti$term[k], c(rn[1:3], "Residuals"))
  check("v21", paste("twoway sumsq", ti$term[k]), ti$sumsq[k], s[["Sum Sq"]][j],
        tol = abs(s[["Sum Sq"]][j]) * 1e-8)
  check("v21", paste("twoway df", ti$term[k]),    ti$df[k],    s[["Df"]][j],     tol = 0)
}
for (k in 1:3)
  check("v21", paste("twoway F", ti$term[k]), ti$statistic[k], s[["F value"]][k],
        tol = abs(s[["F value"]][k]) * 1e-8)
au <- rd("ship_twoway", "augment")
check_true("v21", "twoway augment is one row per observation", nrow(au) == nrow(d))
check("v21", "twoway augment .resid total deviation",
      sum(abs(au$.resid - residuals(fit))), 0, tol = 1e-8)

# ---- 6. paired ------------------------------------------------------------
d  <- E("v05_paired_input.csv")
pt <- t.test(d$jitter_pre, d$jitter_post, paired = TRUE)
ws <- suppressWarnings(wilcox.test(d$jitter_pre, d$jitter_post, paired = TRUE))
ti <- rd("ship_paired", "tidy")
check_true("v21", "paired tidy has one row per family run", nrow(ti) == 2L)
check("v21", "paired t",        ti$statistic[1], unname(pt$statistic), tol = 1e-9)
check("v21", "paired df",       ti$parameter[1], unname(pt$parameter), tol = 0)
check("v21", "paired p",        ti$p.value[1],   pt$p.value,           tol = 1e-12)
check("v21", "paired mean diff",ti$estimate[1],  unname(pt$estimate),  tol = 1e-9)
check("v21", "paired Wilcoxon V", ti$statistic[2], unname(ws$statistic), tol = 1e-9)
no_augment("ship_paired")

# ---- 7. correlation -------------------------------------------------------
d  <- E("v12_correlation_input.csv")
pe <- cor.test(d$speaking_F0_Hz, d$singing_F0_Hz, method = "pearson")
sp <- suppressWarnings(cor.test(d$speaking_F0_Hz, d$singing_F0_Hz, method = "spearman"))
ti <- rd("ship_correlation", "tidy"); gl <- rd("ship_correlation", "glance")
check_true("v21", "correlation tidy has one row per method", nrow(ti) == 2L)
check("v21", "Pearson r",  ti$estimate[1],  unname(pe$estimate),  tol = 1e-9)
check("v21", "Pearson t",  ti$statistic[1], unname(pe$statistic), tol = 1e-7)
check("v21", "Pearson df", ti$parameter[1], unname(pe$parameter), tol = 0)
check("v21", "Pearson p",  ti$p.value[1],   pe$p.value,           tol = 1e-12)
check("v21", "Spearman rho", ti$estimate[2], unname(sp$estimate), tol = 1e-9)
check("v21", "glance r.squared is r^2", gl$r.squared,
      unname(pe$estimate)^2, tol = 1e-12)
no_augment("ship_correlation")

# ---- 8. regression: literally broom's tidy(lm) ---------------------------
d   <- E("v13_regression_input.csv")
fit <- lm(vibrato_regularity_pct ~ practice_hrs_wk, data = d)
cs  <- summary(fit)$coefficients
ti  <- rd("ship_regression", "tidy"); gl <- rd("ship_regression", "glance")
check_true("v21", "regression tidy is broom's tidy(lm), in broom's order",
           identical(names(ti),
                     c("term","estimate","std.error","statistic","p.value")))
check_true("v21", "regression terms are (Intercept) then the predictor",
           ti$term[1] == "(Intercept)" && ti$term[2] == "practice_hrs_wk")
for (k in 1:2) {
  check("v21", paste("regression estimate",  ti$term[k]), ti$estimate[k],  cs[k,1], tol = 1e-9)
  check("v21", paste("regression std.error", ti$term[k]), ti$std.error[k], cs[k,2], tol = 1e-9)
  check("v21", paste("regression statistic", ti$term[k]), ti$statistic[k], cs[k,3], tol = 1e-7)
  check("v21", paste("regression p.value",   ti$term[k]), ti$p.value[k],   cs[k,4], tol = 1e-10)
}
check("v21", "regression glance r.squared",     gl$r.squared,     summary(fit)$r.squared,     tol = 1e-12)
check("v21", "regression glance adj.r.squared", gl$adj.r.squared, summary(fit)$adj.r.squared, tol = 1e-12)
check("v21", "regression glance sigma",         gl$sigma,         summary(fit)$sigma,         tol = 1e-9)
check("v21", "regression glance logLik",        gl$logLik,        as.numeric(logLik(fit)),    tol = 1e-9)
check("v21", "regression glance AIC",           gl$AIC,           AIC(fit),                   tol = 1e-9)
check("v21", "regression glance BIC",           gl$BIC,           BIC(fit),                   tol = 1e-9)
au <- rd("ship_regression", "augment")
check("v21", "regression augment .resid total deviation",
      sum(abs(au$.resid[!is.na(au$.resid)] - residuals(fit))), 0, tol = 1e-8)

# ---- 9. normality ---------------------------------------------------------
d  <- E("v15_normality_input.csv")
sw <- shapiro.test(d$F0_Hz)
ti <- rd("ship_normality", "tidy"); gl <- rd("ship_normality", "glance")
check("v21", "Shapiro-Wilk W", ti$statistic, unname(sw$statistic), tol = 1e-7)
check("v21", "Shapiro-Wilk p", ti$p.value,   sw$p.value,           tol = 1e-6)
check("v21", "normality glance nobs", gl$nobs, nrow(d), tol = 0)
no_augment("ship_normality")

# ---- 10. repeated-measures ANOVA (a BUILD) --------------------------------
d    <- E("demo_rm3_input.csv")
long <- data.frame(subj = factor(rep(seq_len(nrow(d)), 3)),
                   cond = factor(rep(c("s","m","l"), each = nrow(d))),
                   y    = c(d$SPL_soft, d$SPL_medium, d$SPL_loud))
rm_s <- summary(aov(y ~ cond + Error(subj/cond), data = long))
w    <- rm_s[["Error: subj:cond"]][[1]]
ti   <- rd("ship_rmanova", "tidy"); gl <- rd("ship_rmanova", "glance")
check_true("v21", "RM tidy exists at all (this path exported nothing before)",
           nrow(ti) == 2L)
check("v21", "RM F",  ti$statistic[1], w[["F value"]][1], tol = 1e-7)
check("v21", "RM p",  ti$p.value[1],   w[["Pr(>F)"]][1],  tol = 1e-10)
check("v21", "RM df condition", ti$df[1], w[["Df"]][1], tol = 0)
check("v21", "RM df error",     ti$df[2], w[["Df"]][2], tol = 0)
check("v21", "RM sumsq condition", ti$sumsq[1], w[["Sum Sq"]][1], tol = 1e-8)
check("v21", "RM n.subjects", gl$n.subjects, nrow(d), tol = 0)
check_true("v21", "RM glance carries Greenhouse-Geisser epsilon and its p",
           all(c("gg.epsilon","p.value.gg") %in% names(gl)))
check_true("v21", "RM GG epsilon is within its theoretical bounds",
           gl$gg.epsilon >= 1/(3-1) - 1e-9 && gl$gg.epsilon <= 1 + 1e-9)
no_augment("ship_rmanova")
ph <- rd("ship_rmanova", "posthoc_tidy")
check_true("v21", "RM post-hoc names contrasts by column, not by index",
           nrow(ph) == 3L && !any(grepl("^[0-9]+-[0-9]+$", ph$contrast)))

# ---- 11. Friedman (a BUILD) ----------------------------------------------
fr <- friedman.test(as.matrix(d[, c("SPL_soft","SPL_medium","SPL_loud")]))
ti <- rd("ship_friedman", "tidy"); gl <- rd("ship_friedman", "glance")
check("v21", "Friedman chi-squared", ti$statistic, unname(fr$statistic), tol = 1e-9)
check("v21", "Friedman df",          ti$parameter, unname(fr$parameter), tol = 0)
check("v21", "Friedman p",           ti$p.value,   fr$p.value,           tol = 1e-12)
# Kendall's W from its definition; the plugin computes it because
# @emlFriedmanTest exposes no effect size at all.
check("v21", "Kendall's W from its definition",
      gl$kendalls.w, unname(fr$statistic) / (nrow(d) * (3 - 1)), tol = 1e-12)
no_augment("ship_friedman")

if (!exists("EML_SUITE")) { eml_report("v21 shipping paths, broom shape"); eml_exit() }
