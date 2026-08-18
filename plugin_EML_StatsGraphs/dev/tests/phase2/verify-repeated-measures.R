# ============================================================================
# EML Stats : R verification of the literals in test-repeated-measures.praat
# ============================================================================
# Version: 1.0
# Date: 4 August 2026
#
# Run:  Rscript verify-repeated-measures.R ; echo "EXIT=$?"
#
# WHAT THIS FILE IS FOR
# test-repeated-measures.praat asserts the EML library's output against
# numeric literals. Those literals were transcribed by hand from the output
# of repeatedmeasures_refs.py. This file asks the OTHER question: is each
# literal a correct transcription of the true value?
#
#   Praat suite asks:  is the LIBRARY's computed value close to the literal?
#   this file asks:    is the LITERAL a correct value in the first place?
#
# It asserts. It does not print values for a human to eyeball. A v1.0-style
# script that merely cat()s numbers lets a transcription error sit undetected
# while both files report success.
#
# ORACLE ASSIGNMENT AND CHECK LABELS
#   [EXT]  genuine external oracle — base R computed the value independently
#   [LH]   longhand re-implementation of the textbook formula in this file
#
#   Friedman chi-square, p, df   -> stats::friedman.test          [EXT]
#   Friedman rank sums           -> longhand from stats::rank     [LH]
#   RM-ANOVA F, df, p            -> stats::aov + Error() stratum  [EXT]
#   Condition means              -> colMeans                      [EXT]
#   Greenhouse-Geisser epsilon   -> longhand from cov()           [LH]
#   GG-corrected p               -> pf() on [LH] epsilon          [LH]
#
# A [LH] check catches transcription and arithmetic slips; it does NOT catch
# a shared misunderstanding of the estimator. Treat [LH] checks as weaker
# evidence than [EXT] ones and say so in any write-up.
#
# WHY THE GG CHECKS ARE ONLY [LH] HERE
# Base R's `stats` has no Greenhouse-Geisser routine. `ez` and `afex` are
# not installed in the environment of record and CRAN is unreachable from
# the sandbox, so there is no base-R external oracle for epsilon. Per
# dev/tests/REFERENCE_PROVENANCE.md the .R generators call no library() or
# require() — base R stats only — so no package may be pulled in to supply
# one. The genuine [EXT] GG oracle is pingouin 0.6.1, and it lives in the
# companion repeatedmeasures_refs.py. The [LH] epsilon here is written from
# Greenhouse & Geisser (1959) as presented in Winer, and it agrees with
# pingouin to 8e-14 or better on every non-degenerate dataset. That
# agreement is the cross-check; this file records it rather than claiming
# to be the source of it.
#
# WHAT IS DELIBERATELY NOT CHECKED
# Six quantities in the Praat suite are skipped there and skipped here, for
# the same reason: the library and the oracles disagree on degenerate input
# and the disagreement is an open AUTHOR DECISION, not a transcription
# question. Asserting either answer would silently ratify one of them.
#   RM_D (all observations identical): Friedman chiSq/p, GG epsilon,
#        RM-ANOVA F/p. Rank-sum variance is zero, so every statistic is 0/0.
#   RM_F (perfectly additive, zero residual): GG epsilon, RM-ANOVA F/p.
#        ssErr is floating-point noise; statsmodels reports F = 3.09e31 and
#        pingouin 8.58e15 for the same input. No reference value exists.
#
# A disagreement between R and a literal is a FINDING TO RECORD, not a
# licence to change the literal, and never a licence to adopt the EML
# library's own output as the expected value. That would convert the suite
# from a test into a regression lock.
# ============================================================================

cat("==============================================================\n")
cat("R Verification — repeated measures (test-repeated-measures.praat)\n")
cat("==============================================================\n")

pass <- 0
fail <- 0
skipped <- 0
skip_reasons <- character(0)

register_skip <- function(label, reason) {
  skipped <<- skipped + 1
  skip_reasons <<- c(skip_reasons, sprintf("%s — %s", label, reason))
  cat(sprintf("  SKIP: %s (%s)\n", label, reason))
}

check <- function(label, expected, actual, tol) {
  if (length(actual) != 1 || length(expected) != 1 ||
      is.na(actual) || is.na(expected)) {
    register_skip(label, "NA/empty result — check not performed")
    return(invisible(NULL))
  }
  if (abs(expected - actual) <= tol) {
    pass <<- pass + 1
    cat(sprintf("  PASS: %s\n", label))
  } else {
    fail <<- fail + 1
    cat(sprintf("  FAIL: %s (literal=%.17g, R=%.17g, diff=%.3g, tol=%.3g)\n",
                label, expected, actual, abs(expected - actual), tol))
  }
}

check_true <- function(label, condition, detail) {
  if (length(condition) != 1 || is.na(condition)) {
    register_skip(label, "NA condition — check not performed")
    return(invisible(NULL))
  }
  if (isTRUE(condition)) {
    pass <<- pass + 1
    cat(sprintf("  PASS: %s [%s]\n", label, detail))
  } else {
    fail <<- fail + 1
    cat(sprintf("  FAIL: %s — R disagrees [%s]\n", label, detail))
  }
}

# Tolerance is half a unit in the literal's own last written decimal place.
# No check here uses the Praat suite's own tolerance; that would make the
# verification circular.
ulp <- function(decimals) 0.5 * 10^(-decimals)
EXACT_TOL <- 1e-12
TEN_DP <- ulp(10)

# ----------------------------------------------------------------------------
# Longhand helpers
# ----------------------------------------------------------------------------

# Rank sums: within-row average ranks, summed down each column. [LH]
rank_sums_lh <- function(m) {
  r <- t(apply(m, 1, rank, ties.method = "average"))
  if (nrow(m) == 1) r <- matrix(r, nrow = 1)
  colSums(r)
}

# Greenhouse-Geisser epsilon from the k x k covariance matrix. [LH]
# Written from Greenhouse & Geisser (1959) as presented in Winer. This is
# the same estimator emlGGEpsilon implements, derived independently.
gg_epsilon_lh <- function(m) {
  k <- ncol(m)
  s <- cov(m)
  dbar <- sum(diag(s)) / k
  sbar <- mean(s)
  rowmeans <- rowMeans(s)
  num <- k * k * (dbar - sbar)^2
  den <- (k - 1) * (sum(s * s) - 2 * k * sum(rowmeans^2) +
                      k * k * sbar * sbar)
  if (den <= 0) return(1.0)
  eps <- num / den
  min(max(eps, 1 / (k - 1)), 1.0)
}

# Wide n x k matrix -> long data frame for aov(). [EXT] plumbing only.
as_long <- function(m) {
  n <- nrow(m)
  k <- ncol(m)
  data.frame(
    subject   = factor(rep(seq_len(n), times = k)),
    condition = factor(rep(seq_len(k), each = n)),
    value     = as.vector(m)
  )
}

# One-way RM-ANOVA via aov with an Error(subject/condition) stratum. [EXT]
rm_anova_ext <- function(m) {
  long <- as_long(m)
  fit <- aov(value ~ condition + Error(subject / condition), data = long)
  s <- summary(fit)
  # the within-subject stratum is the one carrying the `condition` term
  tab <- NULL
  for (stratum in s) {
    cand <- stratum[[1]]
    if ("condition" %in% trimws(rownames(cand))) {
      tab <- cand
      break
    }
  }
  if (is.null(tab)) {
    return(list(f = NA_real_, df1 = NA_real_, df2 = NA_real_, p = NA_real_))
  }
  rn <- trimws(rownames(tab))
  i <- which(rn == "condition")
  j <- which(rn == "Residuals")
  list(
    f   = as.numeric(tab[i, "F value"]),
    df1 = as.numeric(tab[i, "Df"]),
    df2 = as.numeric(tab[j, "Df"]),
    p   = as.numeric(tab[i, "Pr(>F)"])
  )
}

# ----------------------------------------------------------------------------
# The six datasets — identical to repeatedmeasures_refs.py and to the
# matrix literals in test-repeated-measures.praat.
# ----------------------------------------------------------------------------

RM_A <- matrix(c(
  12, 15, 19,
  10, 14, 17,
  13, 16, 21,
   9, 12, 16,
  11, 15, 20,
  14, 18, 23
), nrow = 6, byrow = TRUE)

RM_B <- matrix(c(
  2,  8, 3, 30,
  3,  9, 5, 10,
  4, 11, 4, 50,
  2,  7, 6,  5,
  5, 12, 3, 40
), nrow = 5, byrow = TRUE)

RM_C <- matrix(c(
  5, 5, 8,
  7, 7, 7,
  3, 6, 6,
  4, 4, 9,
  6, 6, 6
), nrow = 5, byrow = TRUE)

RM_D <- matrix(rep(7, 12), nrow = 4, byrow = TRUE)

RM_E <- matrix(c(
  10, 14, 21,
  12, 15, 19
), nrow = 2, byrow = TRUE)

# perfectly additive: value = subject effect + condition effect, no residual
RM_F <- matrix(c(
  1 + 0, 1 + 5, 1 + 9,
  4 + 0, 4 + 5, 4 + 9,
  8 + 0, 8 + 5, 8 + 9
), nrow = 3, byrow = TRUE)

# ============================================================================
cat("\n[1] Friedman — RM_A (clean balanced, k=3 n=6, no ties)\n")
# ============================================================================

fr <- friedman.test(RM_A)
check("1.1 RM_A Friedman chiSq [EXT]",
      12.0, unname(fr$statistic), EXACT_TOL)
check("1.2 RM_A Friedman df [EXT]",
      2, unname(fr$parameter), EXACT_TOL)
check("1.3 RM_A Friedman p [EXT]",
      0.002478752176666357, fr$p.value, TEN_DP)

rs <- rank_sums_lh(RM_A)
check("1.4 RM_A rankSum[1] [LH]", 6.0, rs[1], EXACT_TOL)
check("1.5 RM_A rankSum[2] [LH]", 12.0, rs[2], EXACT_TOL)
check("1.6 RM_A rankSum[3] [LH]", 18.0, rs[3], EXACT_TOL)

# ============================================================================
cat("\n[2] Friedman — RM_B (k=4 n=5, sphericity violated)\n")
# ============================================================================

fr <- friedman.test(RM_B)
check("2.1 RM_B Friedman chiSq [EXT]",
      10.714285714285715, unname(fr$statistic), TEN_DP)
check("2.2 RM_B Friedman df [EXT]",
      3, unname(fr$parameter), EXACT_TOL)
check("2.3 RM_B Friedman p [EXT]",
      0.013375553908094653, fr$p.value, TEN_DP)

rs <- rank_sums_lh(RM_B)
check("2.4 RM_B rankSum[1] [LH]",  6.5, rs[1], EXACT_TOL)
check("2.5 RM_B rankSum[2] [LH]", 16.0, rs[2], EXACT_TOL)
check("2.6 RM_B rankSum[3] [LH]",  9.5, rs[3], EXACT_TOL)
check("2.7 RM_B rankSum[4] [LH]", 18.0, rs[4], EXACT_TOL)

# ============================================================================
cat("\n[3] Friedman — RM_C (heavy within-row ties, tie-correction path)\n")
# ============================================================================

fr <- friedman.test(RM_C)
check("3.1 RM_C Friedman chiSq [EXT]",
      4.6666666666666705, unname(fr$statistic), ulp(9))
check("3.2 RM_C Friedman df [EXT]",
      2, unname(fr$parameter), EXACT_TOL)
check("3.3 RM_C Friedman p [EXT]",
      0.09697196786440486, fr$p.value, TEN_DP)

rs <- rank_sums_lh(RM_C)
check("3.4 RM_C rankSum[1] [LH]",  8.0, rs[1], EXACT_TOL)
check("3.5 RM_C rankSum[2] [LH]",  9.5, rs[2], EXACT_TOL)
check("3.6 RM_C rankSum[3] [LH]", 12.5, rs[3], EXACT_TOL)

# ============================================================================
cat("\n[4] Friedman — RM_E (n=2, minimum admissible) and RM_F (additive)\n")
# ============================================================================

fr <- friedman.test(RM_E)
check("4.1 RM_E Friedman chiSq [EXT]",
      4.0, unname(fr$statistic), EXACT_TOL)
check("4.2 RM_E Friedman p [EXT]",
      0.1353352832366127, fr$p.value, TEN_DP)

rs <- rank_sums_lh(RM_E)
check("4.3 RM_E rankSum[1] [LH]", 2.0, rs[1], EXACT_TOL)
check("4.4 RM_E rankSum[2] [LH]", 4.0, rs[2], EXACT_TOL)
check("4.5 RM_E rankSum[3] [LH]", 6.0, rs[3], EXACT_TOL)

fr <- friedman.test(RM_F)
check("4.6 RM_F Friedman chiSq [EXT]",
      6.0, unname(fr$statistic), EXACT_TOL)
check("4.7 RM_F Friedman p [EXT]",
      0.04978706836786395, fr$p.value, TEN_DP)

rs <- rank_sums_lh(RM_F)
check("4.8 RM_F rankSum[1] [LH]", 3.0, rs[1], EXACT_TOL)
check("4.9 RM_F rankSum[2] [LH]", 6.0, rs[2], EXACT_TOL)
check("4.10 RM_F rankSum[3] [LH]", 9.0, rs[3], EXACT_TOL)

# ============================================================================
cat("\n[5] Friedman — RM_D (all observations identical, DEGENERATE)\n")
# ============================================================================

# The rank sums are still well defined even when every observation ties:
# every within-row rank is (k+1)/2, so each column sums to n*(k+1)/2 = 8.
rs <- rank_sums_lh(RM_D)
check("5.1 RM_D rankSum[1] [LH]", 8.0, rs[1], EXACT_TOL)
check("5.2 RM_D rankSum[2] [LH]", 8.0, rs[2], EXACT_TOL)
check("5.3 RM_D rankSum[3] [LH]", 8.0, rs[3], EXACT_TOL)

register_skip("5.4 RM_D Friedman chiSq",
              paste("all observations identical: rank-sum variance is zero,",
                    "so the statistic is 0/0. The library clamps and returns",
                    "chiSq = 0, p = 1; scipy returns nan. Open AUTHOR",
                    "DECISION — not asserted in the Praat suite either"))
register_skip("5.5 RM_D Friedman p",
              "same 0/0 degeneracy as 5.4")

# ============================================================================
cat("\n[6] RM-ANOVA — RM_A\n")
# ============================================================================

ra <- rm_anova_ext(RM_A)
check("6.1 RM_A F [EXT]",      286.7241379310342, ra$f, ulp(7))
check("6.2 RM_A dfCond [EXT]",  2, ra$df1, EXACT_TOL)
check("6.3 RM_A dfErr [EXT]",  10, ra$df2, EXACT_TOL)
check("6.4 RM_A p [EXT]",       1.4790681869019914e-09, ra$p, ulp(19))

cm <- colMeans(RM_A)
check("6.5 RM_A condMean[1] [EXT]", 11.5, cm[1], EXACT_TOL)
check("6.6 RM_A condMean[2] [EXT]", 15.0, cm[2], EXACT_TOL)
check("6.7 RM_A condMean[3] [EXT]", 19.333333333333332, cm[3], TEN_DP)

eps <- gg_epsilon_lh(RM_A)
check("6.8 RM_A GG epsilon [LH]", 0.7364273204903339, eps, ulp(10))
check("6.9 RM_A GG-corrected p [LH]",
      1.7527450251467276e-07,
      pf(ra$f, ra$df1 * eps, ra$df2 * eps, lower.tail = FALSE), ulp(17))
check_true("6.10 RM_A epsilon above lower bound 1/(k-1) [LH]",
           eps > 1 / (ncol(RM_A) - 1),
           sprintf("eps=%.12g, bound=%.12g", eps, 1 / (ncol(RM_A) - 1)))

# ============================================================================
cat("\n[7] RM-ANOVA — RM_B (sphericity violated; GG moves p across 0.05)\n")
# ============================================================================

ra <- rm_anova_ext(RM_B)
check("7.1 RM_B F [EXT]",      6.808118424727679, ra$f, ulp(9))
check("7.2 RM_B dfCond [EXT]",  3, ra$df1, EXACT_TOL)
check("7.3 RM_B dfErr [EXT]",  12, ra$df2, EXACT_TOL)
check("7.4 RM_B p [EXT]",       0.00622328180490924, ra$p, ulp(12))

cm <- colMeans(RM_B)
check("7.5 RM_B condMean[1] [EXT]",  3.2, cm[1], EXACT_TOL)
check("7.6 RM_B condMean[2] [EXT]",  9.4, cm[2], EXACT_TOL)
check("7.7 RM_B condMean[3] [EXT]",  4.2, cm[3], EXACT_TOL)
check("7.8 RM_B condMean[4] [EXT]", 27.0, cm[4], EXACT_TOL)

eps <- gg_epsilon_lh(RM_B)
check("7.9 RM_B GG epsilon [LH]", 0.3367309662151602, eps, ulp(10))
pgg <- pf(ra$f, ra$df1 * eps, ra$df2 * eps, lower.tail = FALSE)
check("7.10 RM_B GG-corrected p [LH]",
      0.058750528968868926, pgg, ulp(12))

# This is the substantive claim the Praat suite asserts as a behaviour, not
# a value: the sphericity correction changes the decision at alpha = 0.05.
check_true("7.11 RM_B GG correction moves p across 0.05 [EXT/LH]",
           ra$p < 0.05 && pgg > 0.05,
           sprintf("p=%.6g -> pGG=%.6g", ra$p, pgg))
check_true("7.12 RM_B epsilon sits just above the 1/(k-1) clamp [LH]",
           eps > 1 / (ncol(RM_B) - 1) && eps < 0.34,
           sprintf("eps=%.12g, bound=%.12g", eps, 1 / (ncol(RM_B) - 1)))

# ============================================================================
cat("\n[8] RM-ANOVA — RM_C (ties) and RM_E (n=2 boundary)\n")
# ============================================================================

ra <- rm_anova_ext(RM_C)
check("8.1 RM_C F [EXT]",      3.288135593220338, ra$f, ulp(9))
check("8.2 RM_C dfCond [EXT]",  2, ra$df1, EXACT_TOL)
check("8.3 RM_C dfErr [EXT]",   8, ra$df2, EXACT_TOL)
check("8.4 RM_C p [EXT]",       0.09073486336291588, ra$p, TEN_DP)

cm <- colMeans(RM_C)
check("8.5 RM_C condMean[1] [EXT]", 5.0, cm[1], EXACT_TOL)
check("8.6 RM_C condMean[2] [EXT]", 5.6, cm[2], EXACT_TOL)
check("8.7 RM_C condMean[3] [EXT]", 7.2, cm[3], EXACT_TOL)

eps <- gg_epsilon_lh(RM_C)
check("8.8 RM_C GG epsilon [LH]", 0.7680935569285082, eps, ulp(10))
check("8.9 RM_C GG-corrected p [LH]",
      0.11219902011637321,
      pf(ra$f, ra$df1 * eps, ra$df2 * eps, lower.tail = FALSE), ulp(12))

ra <- rm_anova_ext(RM_E)
check("8.10 RM_E F [EXT]",      19.000000000000004, ra$f, ulp(8))
check("8.11 RM_E dfCond [EXT]",  2, ra$df1, EXACT_TOL)
check("8.12 RM_E dfErr [EXT]",   2, ra$df2, EXACT_TOL)
check("8.13 RM_E p [EXT]",       0.04999999999999999, ra$p, ulp(11))

cm <- colMeans(RM_E)
check("8.14 RM_E condMean[1] [EXT]", 11.0, cm[1], EXACT_TOL)
check("8.15 RM_E condMean[2] [EXT]", 14.5, cm[2], EXACT_TOL)
check("8.16 RM_E condMean[3] [EXT]", 20.0, cm[3], EXACT_TOL)

eps <- gg_epsilon_lh(RM_E)
# n=2 with k=3 puts epsilon exactly ON the 1/(k-1) clamp.
check("8.17 RM_E GG epsilon [LH]", 0.5, eps, ulp(10))
check("8.18 RM_E GG-corrected p [LH]",
      0.1435662931287063,
      pf(ra$f, ra$df1 * eps, ra$df2 * eps, lower.tail = FALSE), ulp(12))
check_true("8.19 RM_E epsilon sits ON the 1/(k-1) clamp [LH]",
           abs(eps - 1 / (ncol(RM_E) - 1)) < 1e-12,
           sprintf("eps=%.17g, bound=%.17g", eps, 1 / (ncol(RM_E) - 1)))

# ============================================================================
cat("\n[9] RM-ANOVA — RM_D and RM_F (DEGENERATE: only df and means assertable)\n")
# ============================================================================

# Degrees of freedom and condition means are still exactly determined even
# when F is 0/0 — those are the quantities the Praat suite asserts here.
cm <- colMeans(RM_D)
check("9.1 RM_D condMean[1] [EXT]", 7.0, cm[1], EXACT_TOL)
check("9.2 RM_D condMean[2] [EXT]", 7.0, cm[2], EXACT_TOL)
check("9.3 RM_D condMean[3] [EXT]", 7.0, cm[3], EXACT_TOL)
check("9.4 RM_D dfCond [LH]", 2, ncol(RM_D) - 1, EXACT_TOL)
check("9.5 RM_D dfErr [LH]",  6, (ncol(RM_D) - 1) * (nrow(RM_D) - 1),
      EXACT_TOL)

register_skip("9.6 RM_D GG epsilon",
              paste("zero covariance: the denominator of the epsilon ratio",
                    "is 0, so epsilon is 0/0. The library returns 1;",
                    "pingouin returns nan. Open AUTHOR DECISION"))
register_skip("9.7 RM_D RM-ANOVA F and p",
              paste("msErr is exactly 0, so F is 0/0. The library returns",
                    "undefined; statsmodels returns F = 0, p = 1.",
                    "Open AUTHOR DECISION"))

cm <- colMeans(RM_F)
check("9.8 RM_F condMean[1] [EXT]",  4.333333333333333, cm[1], TEN_DP)
check("9.9 RM_F condMean[2] [EXT]",  9.333333333333334, cm[2], TEN_DP)
check("9.10 RM_F condMean[3] [EXT]", 13.333333333333334, cm[3], TEN_DP)
check("9.11 RM_F dfCond [LH]", 2, ncol(RM_F) - 1, EXACT_TOL)
check("9.12 RM_F dfErr [LH]",  4, (ncol(RM_F) - 1) * (nrow(RM_F) - 1),
      EXACT_TOL)

register_skip("9.13 RM_F GG epsilon",
              paste("perfectly additive data: the epsilon denominator is",
                    "floating-point noise. The library returns 1; pingouin",
                    "returns nan. Open AUTHOR DECISION"))
register_skip("9.14 RM_F RM-ANOVA F and p",
              paste("ssErr is floating-point noise, so F is x/0.",
                    "statsmodels reports 3.09e31 and pingouin 8.58e15 for",
                    "the same input — no reference value exists"))

# ============================================================================
cat("\n[10] Reshape fixtures (emlExtractConditionMatrix)\n")
# ============================================================================

# The reshape is a complete-case row filter, not a statistic. R verifies the
# arithmetic consequence of the documented contract: which rows survive, in
# what order, and what n/k/nExcluded follow. The error strings themselves are
# library API text with no R counterpart and are asserted only in Praat.

F_wide <- matrix(c(
  12, 15, 19,
  10, 14, 17,
  13, 16, 21,
   9, 12, 16
), nrow = 4, byrow = TRUE)

check("10.1 F1 n (all cells present) [LH]", 4, nrow(F_wide), EXACT_TOL)
check("10.2 F1 k [LH]", 3, ncol(F_wide), EXACT_TOL)
check("10.3 F1 nExcluded [LH]", 0,
      sum(!complete.cases(F_wide)), EXACT_TOL)

F2 <- F_wide
F2[2, 2] <- NA
F2[4, 3] <- NA
keep <- complete.cases(F2)
surv <- F2[keep, , drop = FALSE]

check("10.4 F2 n after complete-case filter [LH]",
      2, nrow(surv), EXACT_TOL)
check("10.5 F2 nExcluded [LH]", 2, sum(!keep), EXACT_TOL)
check_true("10.6 F2 survivors are original rows 1 and 3, in order [LH]",
           identical(which(keep), c(1L, 3L)),
           sprintf("kept rows %s", paste(which(keep), collapse = ",")))
check("10.7 F2 survivor[1,1] [LH]", 12, surv[1, 1], EXACT_TOL)
check("10.8 F2 survivor[1,2] [LH]", 15, surv[1, 2], EXACT_TOL)
check("10.9 F2 survivor[1,3] [LH]", 19, surv[1, 3], EXACT_TOL)
check("10.10 F2 survivor[2,1] [LH]", 13, surv[2, 1], EXACT_TOL)
check("10.11 F2 survivor[2,2] [LH]", 16, surv[2, 2], EXACT_TOL)
check("10.12 F2 survivor[2,3] [LH]", 21, surv[2, 3], EXACT_TOL)

register_skip("10.13 F3 unknown-column error string",
              "library API text; R has no counterpart")
register_skip("10.14 F4 single-column error string",
              "library API text; R has no counterpart")
register_skip("10.15 F5 too-few-complete-cases error string",
              "library API text; R has no counterpart")
register_skip("10.16 F6 column-list whitespace parsing",
              "string parsing of a Praat argument; R has no counterpart")

# ============================================================================
cat("\n[11] End-to-end composition (F2 survivors -> Friedman, RM-ANOVA)\n")
# ============================================================================

# Section E of the Praat suite feeds the F2 reshape output straight into the
# tests. The two survivors share RM_E's rank pattern, so the Friedman result
# must match RM_E exactly — that identity is itself a check on the reshape.
fr <- friedman.test(surv)
check("11.1 F2-composed Friedman chiSq [EXT]",
      4.0, unname(fr$statistic), EXACT_TOL)
check("11.2 F2-composed Friedman p [EXT]",
      0.1353352832366127, fr$p.value, TEN_DP)
check_true("11.3 F2-composed Friedman matches RM_E (same rank pattern) [EXT]",
           abs(unname(fr$statistic) -
                 unname(friedman.test(RM_E)$statistic)) < 1e-12,
           "chiSq identical to RM_E")

cm <- colMeans(surv)
check("11.4 F2-composed condMean[1] [EXT]", 12.5, cm[1], EXACT_TOL)
check("11.5 F2-composed condMean[2] [EXT]", 15.5, cm[2], EXACT_TOL)
check("11.6 F2-composed condMean[3] [EXT]", 20.0, cm[3], EXACT_TOL)

# ============================================================================
# Coverage assertion
# ============================================================================
# 111 checks are attempted here: 101 assertions and 10 registered skips.
# This is NOT the same count as the Praat suite's 96 (90 asserted + 6
# skipped) and it is not meant to be. The two files answer different
# questions and their inventories differ for three structural reasons:
#   - the Praat suite asserts library API strings and reshape error text,
#     which have no R counterpart (4 skips here, asserted there);
#   - the Praat suite asserts .n/.k/.nExcluded/.colLabel$ structure from the
#     reshape, part of which is Praat-object bookkeeping;
#   - this file adds behavioural cross-checks (clamp position, GG decision
#     flip, the F2/RM_E identity) that have no single-literal counterpart.
# What must hold is that every numeric literal in the Praat suite that has a
# meaningful R reference value is checked here. The count below is the guard
# against a check being silently dropped from this file.

EXPECTED_CHECKS <- 111
performed <- pass + fail + skipped
if (performed != EXPECTED_CHECKS) {
  fail <- fail + 1
  cat(sprintf("\n  FAIL: coverage (expected %d checks to be performed, saw %d)\n",
              EXPECTED_CHECKS, performed))
}

cat("\n==============================================================\n")
cat(sprintf("R Verification: %d passed, %d failed, %d skipped\n",
            pass, fail, skipped))
cat(sprintf("R %s.%s\n", R.version$major, R.version$minor))

if (fail > 0) {
  cat("SOME CHECKS FAILED\n")
} else if (skipped > 0) {
  cat(sprintf("INCOMPLETE - %d check(s) skipped, 0 failed.\n", skipped))
  for (r in skip_reasons) cat(sprintf("  * %s\n", r))
  cat("This run does NOT constitute verification of the skipped checks.\n")
} else {
  cat("ALL CHECKS PASSED\n")
}
cat("==============================================================\n")

if (fail > 0) quit(status = 1)
if (skipped > 0) quit(status = 2)
quit(status = 0)
