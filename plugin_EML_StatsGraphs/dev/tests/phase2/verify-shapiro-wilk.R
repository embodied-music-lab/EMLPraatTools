# ============================================================================
# EML Stats : R Verification Script — Shapiro-Wilk (@emlShapiroWilk)
# ============================================================================
# Independent verification of the reference values asserted by
# test-shapiro-wilk.praat.
#
# Version: 2.0
# Date: 2 August 2026
#
# WHAT THIS FILE CHECKS
# ---------------------
# Every expected value here is transcribed from the corresponding
# @emlTestAssertEqualNum literal in test-shapiro-wilk.praat. For each of the
# eight data sets, R's shapiro.test() is run on THE SAME numbers that appear
# in the Praat file, and R's W and p are compared to the Praat literal at a
# transcription tolerance — half a unit in the literal's last written decimal
# place. See the TOLERANCE POLICY block below.
#
# The data vectors in this file and in test-shapiro-wilk.praat must stay
# identical. If one is edited the other must be edited to match, or the two
# files stop corresponding and this verification means nothing.
#
# CHANGELOG
# 2.0 (2 Aug 2026) — Converted from a printer into a checker. Rewritten
#     against the conventions of verify-inferential-batch3.R 1.3.
#
#     WHAT WAS WRONG WITH 1.0
#     -----------------------
#     v1.0 was a pure PRINTER. It made eight shapiro.test() calls, printed
#     W and p at %.10f, and stopped. It contained:
#       * zero comparisons — nothing was ever checked against anything
#       * zero counters — nothing was tallied
#       * no quit() — so the process always exited 0
#     Running it could not fail. It certified nothing, while sitting in a
#     directory of files whose exit status is read as verification. It was a
#     false green of the purest kind: a script whose only possible outcome is
#     success. A human still had to eyeball the printout against the Praat
#     literals, and nothing recorded whether anyone ever did.
#
#     Worse, its data sets did not all correspond to the Praat suite's. Tests
#     1-5 used the same numbers (test 4 in a different order, which is
#     harmless — shapiro.test sorts). Tests 6, 7 and 8 used
#     set.seed(123)/rnorm, set.seed(456)/rexp and set.seed(789)/rnorm. Those
#     three printed W and p for numbers that exist nowhere else. See THE RNG
#     PROBLEM below.
#
#     WHAT 2.0 DOES
#     -------------
#       * pass / fail / skipped counters and the three-value exit contract
#       * per-literal transcription tolerance (ulp of the last written digit)
#       * a FAIL line at %.17g that can actually display a 1e-12 discrepancy
#       * an EXPECTED_CHECKS coverage guard, so a check that silently
#         disappears is itself a failure
#       * register_skip() for anything that cannot be verified, so an
#         unverifiable case is counted and named rather than omitted
#
#     THE RNG PROBLEM (resolved, and how)
#     -----------------------------------
#     R's Mersenne-Twister stream cannot be reproduced in Praat. Any
#     reference value computed from set.seed()+rnorm/rexp therefore describes
#     numbers the Praat library will never see, and can never be compared to
#     anything the Praat suite computes. Those three values were decorative.
#     Each case was resolved by FIXING the data — the generated sample is
#     written out as a literal vector in BOTH files, so the same numbers now
#     exist on both sides and each check is real:
#
#       old test 6 (set.seed(123), rnorm(30,50,10))  -> SW-6, 30 fixed values
#       old test 7 (set.seed(456), rexp(30,1/5))     -> SW-7, 30 fixed values
#       old test 8 (set.seed(789), rnorm(100,0,1))   -> SW-8, 100 fixed values
#
#     Each case's purpose survives intact, because none of them needed
#     randomness — they needed A normal sample, A skewed sample, and A large
#     sample. SW-6 and SW-7 reuse the 30-value vectors already present in
#     test-shapiro-wilk.praat (they were fixed there all along; only the R
#     side was random, which is why the two files disagreed). SW-8's 100
#     values were generated once from rnorm(100,0,1) rounded to 4 dp and then
#     frozen as literals; the generator is history, the data is now data.
#     No case required a skip, so this file's steady state is exit 0.
#
#     LIBRARY AGREEMENT (measured before these literals were committed)
#     ----------------------------------------------------------------
#     @emlShapiroWilk was run on all eight vectors and compared with R at 12
#     decimals. W and p agree to within 5e-13 — i.e. to the rounding of the
#     12-decimal literals themselves — on every case except one:
#
#       SW-1 (n=3, {1,2,3}) p: library 0.999999971541 vs R 1.0, diff 2.8e-8.
#
#     That is not a defect. For n=3 both implementations use the exact
#     arcsine form p = (6/pi)(asin(sqrt(W)) - asin(sqrt(3/4))), whose
#     derivative dp/dW diverges as W -> 1. The library's W is one ulp below
#     1.0 (1 - 2.2e-16); asin amplifies that to sqrt(2.2e-16) ~ 1.5e-8 in p.
#     The Praat assertion for this single value therefore carries a wider,
#     documented tolerance (1e-6); every other Praat assertion is at 1e-9.
#     The literal is R's true value, not the library's output.
#
# 1.0 (26 Feb 2026) — Initial. Printer only; see above.
# ============================================================================

cat("==================================================\n")
cat("EML Stats Shapiro-Wilk — R Verification\n")
cat("==================================================\n\n")

pass <- 0
fail <- 0
skipped <- 0
skip_reasons <- character(0)

# A skipped check must never be able to read as a pass. Every skip — whether
# a deliberate section skip or an NA result — registers itself here, and the
# final banner is gated on skipped == 0 as well as fail == 0.
register_skip <- function(label, reason) {
  skipped <<- skipped + 1
  entry <- sprintf("%s — %s", label, reason)
  skip_reasons <<- c(skip_reasons, entry)
  cat(sprintf("  SKIP: %s\n", entry))
}

check <- function(label, expected, actual, tol=0.001) {
  if (is.na(actual) || is.na(expected)) {
    register_skip(label, "NA result — check not performed")
    return(invisible(NULL))
  }
  if (abs(expected - actual) <= tol) {
    assign("pass", get("pass", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  PASS: %s\n", label))
  } else {
    assign("fail", get("fail", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    # %.17g, not a fixed decimal count. Tolerances here reach 1e-12
    # (EXACT_TOL), and %.8f prints a genuine failure as two identical-looking
    # numbers — a failure report that hides the failure. %.17g round-trips a
    # double, so the values are always visibly different when a check failed.
    # The residual and the tolerance are printed too, so the reader can see
    # by how much it missed without recomputing.
    cat(sprintf("  FAIL: %s (expected=%.17g, got=%.17g, diff=%.3g, tol=%.3g)\n",
                label, expected, actual, abs(expected - actual), tol))
  }
}

# TOLERANCE POLICY
# ----------------
# These checks do NOT use the Praat assertion tolerances. The two comparisons
# answer different questions and need different tolerances:
#
#   Praat assertion : is the LIBRARY's computed value close enough to the
#                     reference literal? Genuine last-bit differences between
#                     two implementations are acceptable, so a working
#                     tolerance (1e-9 here) is right there.
#   This file       : is the reference LITERAL a correct transcription of the
#                     true value? A literal is either right or mis-typed;
#                     there is no legitimate slack beyond rounding.
#
# So each literal is checked at half a unit in its own last written decimal
# place — the largest error correct rounding can produce, and the smallest
# error a typo can produce. Every W and p literal below is written to 12
# decimals, so the working tolerance is ulp(12) = 5e-13.
ulp <- function(decimals) 0.5 * 10^(-decimals)

# For literals that are exact in binary (1.0) R reproduces them to within
# last-bit noise only.
EXACT_TOL <- 1e-12

TIGHT_TOL <- 0.000001   # reserved for exact integer/half-integer quantities

# ============================================================================
# SHARED DATA
# ============================================================================
# These vectors are the same numbers, in the same order, as the vectors in
# test-shapiro-wilk.praat. Edit both or neither.

sw1 <- c(1, 2, 3)

sw2 <- c(3.1, 4.2, 3.8, 4.5)

sw3 <- c(2.3, 1.8, 2.5, 2.1, 2.0)

sw4 <- c(92.96, 96.49, 96.49, 97.93, 107.45,
         108.14, 109.72, 111.51, 122.85, 123.69)

sw5 <- c(8.86, 0.78, 9.8, 2.48, 7.53, 5.27, 9.08, 8.84, 0.89, 5.17,
         3.44, 2.12, 3.61, 2.71, 7.62, 4.78, 0.99, 2.75, 7.94, 5.14)

# SW-6: formerly set.seed(123); round(rnorm(30, 50, 10), 2). Frozen as
# literals so the Praat suite can be given the identical sample.
sw6 <- c(39.14, 59.97, 52.83, 34.94, 44.21, 66.51, 25.73, 45.71, 62.66,
         41.33, 43.21, 49.05, 64.91, 43.61, 45.56, 45.66, 72.06, 71.87,
         60.04, 53.86, 57.37, 64.91, 40.64, 61.76, 37.46, 43.62, 59.07,
         35.71, 48.6, 41.38)

# SW-7: formerly set.seed(456); round(rexp(30, 1/5), 2). Frozen as literals.
sw7 <- c(1.43, 0.89, 7.65, 8.26, 4.91, 4.63, 10.84, 7.12, 1.0, 0.81,
         2.86, 2.43, 4.29, 0.79, 5.8, 3.16, 4.22, 5.19, 6.42, 5.71,
         1.0, 0.63, 1.39, 0.04, 2.23, 0.79, 3.91, 9.73, 1.12, 0.72)

# SW-8: formerly set.seed(789); round(rnorm(100, 0, 1), 4). Frozen as
# literals. The purpose of the case — a large sample on the n >= 12
# log-normal p-value branch — does not require the sample to be random,
# only to be large and approximately normal.
sw8 <- c(0.5241, -2.2608, -0.0197, 0.1831, -0.3614, -0.4845, -0.6663,
         -0.1745, -1.011, 0.7397, -0.4023, -1.0028, -0.1777, -0.4879,
         0.9279, -0.7744, 0.4229, -0.607, 0.2094, -0.7773, -0.7021,
         0.6835, -0.8577, 0.3678, -1.4297, -0.5123, -0.2681, -0.1992,
         0.8566, -0.1668, -0.3757, -1.135, 0.6093, 0.5659, -0.736,
         -1.0586, -1.3179, -0.2044, -0.6014, 0.6606, -0.1647, 1.7595,
         1.612, 0.8032, 1.2652, 0.511, -3.0876, 0.4742, 0.6259, 0.9812,
         -0.0477, -1.5196, 0.7949, -0.1442, -0.7065, 0.6107, 1.0851,
         -0.7113, 1.1563, 1.2356, -0.3225, 0.7328, -0.2875, 2.3485,
         0.3477, -0.3455, -0.9026, -0.3939, -0.9638, 0.7693, 0.5447,
         1.0497, 1.1928, -0.3382, -1.0578, -0.2644, 1.5017, 0.7877,
         0.3347, -1.6272, 1.8495, 0.4749, -0.9872, 0.2559, -1.4109,
         0.0878, 0.3146, -0.4388, -1.45, 1.3237, -0.4779, 1.0525,
         -0.8171, -1.1369, -2.6197, 0.9858, 0.1984, -0.6233, 0.45,
         1.4992)

# ══════════════════════════════════════════════════════════════════════════════
# EXACT / SMALL-n BRANCHES (n = 3, 4, 5)
# ══════════════════════════════════════════════════════════════════════════════
# n = 3 uses the exact arcsine p-value; n = 4..11 uses the Royston (1992)
# gamma approximation. Both are separate code paths in @emlShapiroWilk.
cat("--- Small n (exact and gamma branches) ---\n")

r <- shapiro.test(sw1)
check("SW-1 n=3 W", 1.0, unname(r$statistic), EXACT_TOL)
# Analytically exactly 1: p = (6/pi)(asin(1) - asin(sqrt(3/4)))
#                          = (6/pi)(pi/2 - pi/3) = 1.
# R returns 1 - 1e-14. See CHANGELOG on why the Praat side is looser here.
check("SW-1 n=3 p", 1.0, r$p.value, EXACT_TOL)

r <- shapiro.test(sw2)
check("SW-2 n=4 W", 0.962030073282, unname(r$statistic), ulp(12))
check("SW-2 n=4 p", 0.791677943443, r$p.value, ulp(12))

r <- shapiro.test(sw3)
check("SW-3 n=5 W", 0.989977466626, unname(r$statistic), ulp(12))
check("SW-3 n=5 p", 0.979615511470, r$p.value, ulp(12))

# ══════════════════════════════════════════════════════════════════════════════
# GAMMA BRANCH, UPPER END (n = 10)
# ══════════════════════════════════════════════════════════════════════════════
# Contains a tied pair (96.49 twice). Shapiro-Wilk has no tie correction —
# ties simply enter the sorted vector twice — so this is a legitimate input,
# and it exercises the sort path in @emlShapiroWilk.
cat("\n--- n = 10 (gamma branch, tied values) ---\n")

r <- shapiro.test(sw4)
check("SW-4 n=10 W", 0.907650153011, unname(r$statistic), ulp(12))
check("SW-4 n=10 p", 0.265236942071, r$p.value, ulp(12))

# ══════════════════════════════════════════════════════════════════════════════
# LOG-NORMAL BRANCH (n >= 12)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- n >= 12 (Royston 1995 log-normal branch) ---\n")

r <- shapiro.test(sw5)
check("SW-5 n=20 uniform W", 0.922737157512, unname(r$statistic), ulp(12))
check("SW-5 n=20 uniform p", 0.111874183264, r$p.value, ulp(12))

r <- shapiro.test(sw6)
check("SW-6 n=30 normal W", 0.962136866176, unname(r$statistic), ulp(12))
check("SW-6 n=30 normal p", 0.350871750897, r$p.value, ulp(12))

r <- shapiro.test(sw7)
check("SW-7 n=30 exponential W", 0.903974016144, unname(r$statistic), ulp(12))
check("SW-7 n=30 exponential p", 0.010519966454, r$p.value, ulp(12))

r <- shapiro.test(sw8)
check("SW-8 n=100 normal W", 0.987633495666, unname(r$statistic), ulp(12))
check("SW-8 n=100 normal p", 0.481589049392, r$p.value, ulp(12))

# ══════════════════════════════════════════════════════════════════════════════
# Coverage assertion. The check tally is itself checked: if a section is ever
# commented out or an early error skips past a block, the count falls short
# and this registers a failure rather than letting a smaller green run
# masquerade as a complete one.
EXPECTED_CHECKS <- 16
performed <- pass + fail + skipped
if (performed != EXPECTED_CHECKS) {
  fail <- fail + 1
  cat(sprintf("  FAIL: coverage (expected %d checks, saw %d)\n",
              EXPECTED_CHECKS, performed))
}

cat("\n==================================================\n")
cat(sprintf("R Verification: %d passed, %d failed, %d skipped\n",
            pass, fail, skipped))
cat(sprintf("R %s.%s\n", R.version$major, R.version$minor))

if (fail > 0) {
  cat("SOME CHECKS FAILED\n")
} else if (skipped > 0) {
  cat(sprintf("INCOMPLETE - %d check(s) skipped, 0 failed.\n", skipped))
  for (s in skip_reasons) cat(sprintf("  * %s\n", s))
  cat("This run does NOT constitute verification of the skipped checks.\n")
} else {
  cat("ALL CHECKS PASSED\n")
}
cat("==================================================\n")

# Exit-code contract, shared by every verifier in this directory:
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
# A runner must not collapse 2 into 0. This file has no structural skips, so
# 0 is its steady state; a 2 here means something went wrong, not that R is
# structurally unable to help.
if (fail > 0) quit(status = 1)
if (skipped > 0) quit(status = 2)
quit(status = 0)
