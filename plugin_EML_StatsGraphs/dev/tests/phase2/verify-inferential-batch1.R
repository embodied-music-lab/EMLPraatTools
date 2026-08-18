# ============================================================================
# EML Stats : R verification of the literals in test-inferential-batch1.praat
# ============================================================================
# Version: 2.0
# Date: 2 August 2026 (original 26 February 2026)
#
# WHAT THIS FILE IS FOR
# ---------------------
# It asserts. It does not print values for a human to eyeball.
#
# v1.0 of this file computed the reference quantities with t.test() and
# cat()-ed them, then ended with "All values computed. Compare against Praat
# test assertions." Nothing was compared. A transcription error in the Praat
# literals would have printed cleanly and exited 0 — and in fact six such
# errors sat in test-inferential-batch1.praat for five months while both this
# file and the Praat suite reported success (see that file's v1.1 CHANGELOG).
#
# v2.0 checks every literal in the Praat suite against R and fails loudly.
#
# WHAT IT CHECKS, AND WHAT THAT MEANS
# -----------------------------------
# The Praat assertion and this file ask DIFFERENT questions:
#
#   Praat:  is the LIBRARY's computed value close enough to the literal?
#   here:   is the LITERAL a correct transcription of the true value?
#
# A literal is either right or mis-typed; the only legitimate slack is the
# rounding of the literal itself. So each literal is checked at half a unit
# in its own last written decimal place — ulp(d) = 0.5 * 10^(-d). A literal
# written to 10 dp gets 5e-11. Literals that are the exact mathematical value
# (integers, 2.5, 1.6, 0) get EXACT_TOL. No check here uses the Praat suite's
# own tolerance; that would make the verification circular.
#
# EXTERNAL VALIDATION vs RE-IMPLEMENTATION
# ----------------------------------------
# Not every check below is external validation, and the distinction is
# labelled per check, because conflating them is how a package convinces
# itself it is verified when it is only self-consistent.
#
#   [EXT] genuine external validation — the reference comes from R's own
#         t.test / mean / sd / var / length. R is an independent
#         implementation; agreement is evidence.
#
#   [LH]  longhand re-implementation — the reference is computed in this
#         file from the textbook formula. The `effsize` and `effectsize`
#         packages are NOT installed and CRAN is unreachable in this
#         environment, so Cohen's d, the pooled SD, Hedges' J and g have no
#         external referent available. Writing the formula out a second time
#         catches transcription and arithmetic slips; it does NOT catch a
#         shared misunderstanding of the estimator. Treat [LH] checks as
#         weaker evidence than [EXT] ones and say so in any write-up.
#
# 31 [EXT] + 9 [LH] = 40 checks; 17 counted skips; 57 total, matching the
# 57 assertions in test-inferential-batch1.praat exactly. The coverage
# assertion at the bottom enforces that arithmetic, so a silently deleted
# check fails the run.
#
# WHAT IS SKIPPED, AND WHY
# ------------------------
# R verifies numeric quantities and inequalities among them. It does not
# verify the library's error-string contract, its method labels, or its
# undefined-ness semantics — those are library API claims with no R
# counterpart. They are registered as counted SKIPs, not silently omitted,
# and they force this script to exit 2 (INCOMPLETE) rather than 0.
#
# EXIT CONTRACT
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
#
# A clean run of this file exits 2. That is the correct, honest status: 40
# literals are externally checked and 17 assertions are outside R's reach.
#
# Run:  Rscript verify-inferential-batch1.R ; echo "EXIT=$?"
# ============================================================================

# ----------------------------------------------------------------------------
# Machinery (shared design with verify-inferential-batch3.R v1.3)
# ----------------------------------------------------------------------------

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

ulp <- function(decimals) 0.5 * 10^(-decimals)
EXACT_TOL <- 1e-12
TEN_DP <- ulp(10)

cat("==============================================================\n")
cat("verify-inferential-batch1.R v2.0\n")
cat(sprintf("R %s.%s\n", R.version$major, R.version$minor))
cat("Verifying every literal in test-inferential-batch1.praat\n")
cat("==============================================================\n\n")

# ----------------------------------------------------------------------------
# Shared test data — transcribed from test-inferential-batch1.praat
# ----------------------------------------------------------------------------

g1 <- c(10, 12, 14, 16, 18)
g2 <- c(8, 9, 10, 11, 12)

# ----------------------------------------------------------------------------
# TEST GROUP 1: @emlTTest — Welch (default)
# ----------------------------------------------------------------------------

cat("--- TG1: @emlTTest, Welch ---\n")

welch <- t.test(g1, g2, var.equal = FALSE)

register_skip("1.1 Welch method label",
              "method label is a library API string; R has no counterpart")

check("1.1 Welch t statistic [EXT]",
      2.5298221281, unname(welch$statistic), TEN_DP)
check("1.1 Welch df (fractional) [EXT]",
      5.8823529412, unname(welch$parameter), TEN_DP)
check("1.1 Welch p two-tailed [EXT]",
      0.0454646190, welch$p.value, TEN_DP)
check("1.1 Welch mean1 [EXT]",
      14, mean(g1), EXACT_TOL)
check("1.1 Welch mean2 [EXT]",
      10, mean(g2), EXACT_TOL)
check("1.1 Welch meanDiff [EXT]",
      4, mean(g1) - mean(g2), EXACT_TOL)
check("1.1 Welch n1 [EXT]",
      5, length(g1), EXACT_TOL)
check("1.1 Welch n2 [EXT]",
      5, length(g2), EXACT_TOL)

# The library's one-tailed p is a fixed H1 of group1 > group2, which is R's
# alternative = "greater" — not simply half the two-tailed p in general.
welch_1t <- t.test(g1, g2, var.equal = FALSE, alternative = "greater")
check("1.2 Welch p one-tailed [EXT]",
      0.0227323095, welch_1t$p.value, TEN_DP)

register_skip("1.3 Equal means error (zero var)",
              "library error-string contract; R errors differently")
register_skip("1.3 Equal means t undefined",
              "library undefined-value semantics; no R counterpart")

# t.test(c(5,5,5,5,5), c(3,4,5,6,7)) does NOT error — the pooled/Welch
# denominator is finite because the second group varies. R returns t = 0.
const <- c(5, 5, 5, 5, 5)
vary  <- c(3, 4, 5, 6, 7)
cv <- t.test(const, vary, var.equal = FALSE)
check("1.4 One constant group t = 0 [EXT]",
      0, unname(cv$statistic), EXACT_TOL)
register_skip("1.4 One constant group no error",
              "library error-string contract; no R counterpart")

register_skip("1.5 n1 < 2 gives error",
              "library input-validation contract; no R counterpart")
register_skip("1.5 n1 < 2 t is undefined",
              "library undefined-value semantics; no R counterpart")
register_skip("1.6 tails=3 gives error",
              "library input-validation contract; no R counterpart")

welch_rev <- t.test(g2, g1, var.equal = FALSE)
check_true("1.7 Reversed groups negative t [EXT]",
           unname(welch_rev$statistic) < 0,
           sprintf("R t = %.10f", unname(welch_rev$statistic)))
check("1.7 Reversed groups same |t| [EXT]",
      2.5298221281, abs(unname(welch_rev$statistic)), TEN_DP)

# ----------------------------------------------------------------------------
# TEST GROUP 2: @emlTTest — Student (pooled)
# ----------------------------------------------------------------------------

cat("\n--- TG2: @emlTTest, Student ---\n")

student <- t.test(g1, g2, var.equal = TRUE)

register_skip("2.1 Student method label",
              "method label is a library API string; R has no counterpart")

check("2.1 Student t statistic [EXT]",
      2.5298221281, unname(student$statistic), TEN_DP)
check("2.1 Student df (integer) [EXT]",
      8, unname(student$parameter), EXACT_TOL)
check("2.1 Student p two-tailed [EXT]",
      0.0352652035, student$p.value, TEN_DP)

student_1t <- t.test(g1, g2, var.equal = TRUE, alternative = "greater")
check("2.2 Student p one-tailed [EXT]",
      0.0176326017, student_1t$p.value, TEN_DP)

# 2.3 asserts only that Welch and Student agree to within 0.01 on
# equal-variance data. R reproduces the same near-identity.
a <- c(20, 22, 24, 26, 28)
b <- c(14, 16, 18, 20, 22)
p_welch_23 <- t.test(a, b, var.equal = FALSE)$p.value
p_stud_23  <- t.test(a, b, var.equal = TRUE)$p.value
check_true("2.3 Equal var: Welch ~ Student p [EXT]",
           abs(p_welch_23 - p_stud_23) < 0.01,
           sprintf("R |pWelch - pStudent| = %.3g", abs(p_welch_23 - p_stud_23)))

# ----------------------------------------------------------------------------
# TEST GROUP 3: @emlTTestPaired
# ----------------------------------------------------------------------------

cat("\n--- TG3: @emlTTestPaired ---\n")

paired <- t.test(g1, g2, paired = TRUE)
diffs <- g1 - g2

check("3.1 Paired t statistic [EXT]",
      5.6568542495, unname(paired$statistic), TEN_DP)
check("3.1 Paired df [EXT]",
      4, unname(paired$parameter), EXACT_TOL)
check("3.1 Paired p two-tailed [EXT]",
      0.0048126783, paired$p.value, TEN_DP)
check("3.1 Paired meanDiff [EXT]",
      4, mean(diffs), EXACT_TOL)
check("3.1 Paired sdDiff [EXT]",
      1.5811388301, sd(diffs), TEN_DP)
check("3.1 Paired n [EXT]",
      5, length(diffs), EXACT_TOL)

paired_1t <- t.test(g1, g2, paired = TRUE, alternative = "greater")
check("3.2 Paired p one-tailed [EXT]",
      0.0024063392, paired_1t$p.value, TEN_DP)

register_skip("3.3 No diff: error (zero var)",
              "library error-string contract; no R counterpart")
register_skip("3.4 Constant diff: error (zero var)",
              "library error-string contract; no R counterpart")
register_skip("3.5 Unequal length: error",
              "library input-validation contract; no R counterpart")
register_skip("3.5 Unequal length: t undefined",
              "library undefined-value semantics; no R counterpart")

paired_rev <- t.test(g2, g1, paired = TRUE)
check_true("3.6 Reversed paired: negative t [EXT]",
           unname(paired_rev$statistic) < 0,
           sprintf("R t = %.10f", unname(paired_rev$statistic)))
check("3.6 Reversed paired: same |t| [EXT]",
      5.6568542495, abs(unname(paired_rev$statistic)), TEN_DP)

pre  <- c(85, 90, 78, 92, 88, 76, 95, 82, 91, 87)
post <- c(88, 93, 82, 94, 91, 80, 97, 86, 93, 90)
paired_lg <- t.test(pre, post, paired = TRUE)
check("3.7 Larger paired meanDiff [EXT]",
      -3, mean(pre - post), EXACT_TOL)
check("3.7 Larger paired n [EXT]",
      10, length(pre - post), EXACT_TOL)
check_true("3.7 Larger paired significant [EXT]",
           paired_lg$p.value < 0.001,
           sprintf("R p = %.6g", paired_lg$p.value))

# ----------------------------------------------------------------------------
# TEST GROUP 4: @emlCohenD
# ----------------------------------------------------------------------------
# All checks in this group are [LH]. `effsize` and `effectsize` are not
# installed and CRAN is unreachable, so there is no external referent for
# Cohen's d or Hedges' g here. The formulas are written out from Hedges &
# Olkin (1985): pooled SD from the two sample variances, d as the raw mean
# difference over the pooled SD, and the small-sample correction
# J = 1 - 3/(4*df - 1) with g = J*d. R's own var() and mean() do supply the
# inputs, so an arithmetic slip in the library is still caught; a shared
# misconception about the estimator is not.
# ----------------------------------------------------------------------------

cat("\n--- TG4: @emlCohenD  [LH — no external effect-size package available] ---\n")

cohen_d <- function(x, y) {
  nx <- length(x)
  ny <- length(y)
  df <- nx + ny - 2
  pooled_var <- ((nx - 1) * var(x) + (ny - 1) * var(y)) / df
  pooled_sd <- sqrt(pooled_var)
  d <- (mean(x) - mean(y)) / pooled_sd
  j <- 1 - 3 / (4 * df - 1)
  list(pooledSD = pooled_sd, d = d, J = j, g = j * d, df = df)
}

cd <- cohen_d(g1, g2)

check("4.1 Cohen d [LH]",        1.6, cd$d,        EXACT_TOL)
check("4.1 Pooled SD [LH]",      2.5, cd$pooledSD, EXACT_TOL)
check("4.1 Mean1 [EXT]",         14,  mean(g1),    EXACT_TOL)
check("4.1 Mean2 [EXT]",         10,  mean(g2),    EXACT_TOL)
register_skip("4.1 No error",
              "library error-string contract; no R counterpart")

check("4.2 Hedges g correction factor [LH]",
      0.9032258065, cd$J, TEN_DP)
check("4.2 Hedges g [LH]",
      1.4451612903, cd$g, TEN_DP)

check_true("4.3 g < d [LH]",
           cd$g < cd$d,
           sprintf("longhand g = %.10f, d = %.10f", cd$g, cd$d))

cd_rev <- cohen_d(g2, g1)
check("4.4 Reversed d = -1.6 [LH]", -1.6, cd_rev$d, EXACT_TOL)

z <- c(10, 12, 14, 16, 18)
cd_zero <- cohen_d(z, z)
check("4.5 Zero effect d = 0 [LH]", 0, cd_zero$d, EXACT_TOL)
check("4.5 Zero effect g = 0 [LH]", 0, cd_zero$g, EXACT_TOL)

big1 <- 1:50
big2 <- 2:51
cd_big <- cohen_d(big1, big2)
check_true("4.6 Large n: J close to 1 [LH]",
           cd_big$J > 0.99,
           sprintf("longhand J = %.10f", cd_big$J))

register_skip("4.7 n1 < 2 gives error",
              "library input-validation contract; no R counterpart")
register_skip("4.7 n1 < 2 d is undefined",
              "library undefined-value semantics; no R counterpart")
register_skip("4.7 n1 < 2 g is undefined",
              "library undefined-value semantics; no R counterpart")
register_skip("4.8 Zero pooled SD: error",
              "library error-string contract; no R counterpart")

# ----------------------------------------------------------------------------
# Coverage assertion
# ----------------------------------------------------------------------------
# 57 = the assertion count in test-inferential-batch1.praat
#      (34 AssertEqualNum + 2 AssertEqualStr + 16 AssertTrue
#       + 5 AssertUndefined). If a check above is deleted or an assertion is
#      added to the Praat suite without a counterpart here, this fails.

EXPECTED_CHECKS <- 57
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
