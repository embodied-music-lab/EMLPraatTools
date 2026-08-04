# ============================================================================
# EML Stats : R Verification Script — Inferential Statistics (Batch 3)
# ============================================================================
# Independent verification of reference values for:
#   @emlMannWhitneyU and @emlWilcoxonSignedRank
#
# Run this script in R to confirm that our Praat test expectations
# match an independent statistical implementation.
#
# Version: 1.3
# Date: 2 August 2026
#
# WHAT THIS FILE CHECKS
# ---------------------
# Every expected value in this file is transcribed from the corresponding
# @emlTestAssertEqualNum literal in test-inferential-batch3.praat. The R
# call is arranged to compute the same quantity the library claims to
# compute, and the check compares R's result to the Praat literal at a
# transcription tolerance — half a unit in the literal's last written
# decimal place, NOT the Praat assertion's working tolerance. See the
# TOLERANCE POLICY block below and CHANGELOG 1.3. Coverage is now complete:
# all 20 p-value assertions and all 20 test-statistic assertions, plus the
# separately-exposed one-tailed .pLess of MWU-1.4.
#
# TWO CONVENTIONS THAT MUST BE HELD IN MIND WHEN READING THIS FILE
# ----------------------------------------------------------------
# 1. The library's one-tailed H1 is FIXED as group1 > group2. Its .p is
#    that tail. The opposite tail is exposed separately as .pLess. So a
#    one-tailed case is verified against R's alternative="greater", and
#    R's alternative="less" verifies .pLess, not .p.
# 2. R reports the rank-sum statistic as W and the signed-rank statistic
#    as V. W corresponds to the library's .u1; V corresponds to .tPlus.
#    (V is T+ regardless of the alternative.)
#
# CHANGELOG
# 1.3 (2 Aug 2026) — Tolerance policy, and a failure message that could not
#     display the failure. Both were found by a negative control that passed
#     when it should have failed.
#
#     (a) TOLERANCE POLICY. Up to 1.2 this file copied the tolerance from the
#         corresponding Praat assertion, on the reasoning that a check here
#         should verify "the same claim, no looser." That reasoning was
#         wrong, because the two comparisons are not the same claim:
#
#           Praat assertion : is the LIBRARY's computed value close enough to
#                             the reference literal? Genuine last-bit
#                             differences between two implementations are
#                             acceptable, so a working tolerance (1e-3) is
#                             right there.
#           This file       : is the reference LITERAL a correct
#                             transcription of the true value? A literal is
#                             either right or mis-typed; there is no
#                             legitimate slack beyond rounding.
#
#         Every literal is now checked at half a unit in its own last written
#         decimal place — ulp(d) = 0.5e-d — the largest error correct
#         rounding can produce and the smallest error a typo can produce.
#         Literals that are exactly representable (1.0, 0.0625, 0.05) are
#         checked at EXACT_TOL = 1e-12.
#
#         Measured slack under the old policy, across all 21 p-value checks:
#         350x to 430,000x the actual residual. MWU-1.7 carried a tolerance
#         of 1e-3 against a true residual of 2.3e-9. A literal could have
#         been wrong by hundreds of times its real error and still read
#         green — the same false-green class this file exists to remove,
#         one level up.
#
#         All 41 checks still pass under the tightened tolerances, which is
#         the evidence that no literal is a mis-transcription. Two are worth
#         watching: MWU-1.1 sits at 57% of its half-ULP budget and MWU-2.3
#         at 92%. If either is ever re-emitted, take the extra digits.
#
#         Demonstrated sensitivity gain (negative controls, this version):
#           perturb MWU-1.7 p(2) by 1e-7  -> old policy: PASSES silently
#                                            new policy: EXIT 1, FAIL
#           perturb WSR-4.1 p(2) by 1e-10 -> new policy: EXIT 1, FAIL
#         Under 1.2 the perturbation had to exceed 1e-3 to be detected.
#
#     (b) FAILURE MESSAGE PRECISION. The FAIL line printed both values at
#         %.8f. With tolerances down to 1e-12 a real failure printed as two
#         identical numbers ("expected=0.06250000, got=0.06250000") — a
#         report that hides what it is reporting. Now %.17g, plus the
#         residual and the tolerance in the same line. Found by negative
#         control C; it is the same defect class as the reversed-argument
#         FAIL messages fixed in test-regression.praat 1.1.
#
#     NOT changed: the statistic checks (U1, T+) stay at TIGHT_TOL = 1e-6.
#     They compare exact integers and half-integers, where 1e-6 is already
#     far tighter than any transcription error could be.
#
#     KNOWN DEFECT FLAGGED, NOT FIXED HERE (it is in the Praat file, not
#     this one): test-inferential-batch3.praat asserts MWU-2.3 p(2) =
#     0.00003 with tolerance 0.00005. The tolerance is nearly twice the
#     asserted value, so the library could return anything in roughly
#     [0, 0.00008] and pass. The true value is 0.0000253760. That literal
#     should be re-emitted at full precision with a proportionate tolerance.
#
# 1.2 (2 Aug 2026) — Coverage 12/22 -> 41/41, and three misalignments fixed.
#
#     (a) The eight tied/zero cases were registered as skips on the premise
#         that "ties make R fall back to the normal approximation, so
#         wilcox.test cannot supply an independent exact reference." That
#         premise was stale. It was written when the library computed an
#         exact tied null. In v1.1 of the library @emlMannWhitneyU and
#         @emlWilcoxonSignedRank were changed to follow R's routing rule
#         exactly — the exact null only when there are no ties (and, for
#         signed-rank, no zero differences), otherwise the tie-corrected
#         normal approximation with continuity correction. Every one of
#         those eight cases now asserts method$ = "normal approximation"
#         in the Praat test. The normal approximation IS the quantity to
#         verify, and R computes it directly. Requesting it explicitly
#         (exact=FALSE, correct=TRUE) reaches the same computation the
#         fallback would with no warning emitted. All eight now check, and
#         all eight pass. A skip premised on a stale library behaviour is
#         itself a defect; the fix is to re-test the premise, not to
#         reword the skip.
#
#         batch3_scipy_refs.py (same directory) remains committed and is
#         now a SECOND independent reference for the same eight values
#         rather than the only one. Two independent implementations
#         agreeing is strictly stronger than one.
#
#     (b) MWU-2.2 was checking the wrong path. It called
#         exact=FALSE, correct=TRUE (0.7715511878) against the literal
#         0.77155 — but that data has no ties, so the library takes the
#         exact path and asserts 0.77484. The check verified R against R
#         and said nothing about the library. Now exact=TRUE, giving
#         0.7748403017, against the library's actual literal.
#
#     (c) MWU-1.4 was checking .pLess under a label claiming p(1). It
#         called alternative="less" (0.05) and labelled the result
#         "MWU-1.4 p(1)", but the library's .p for that case is 1.0 (see
#         convention 1 above). Split into two correctly-labelled checks.
#
#     (d) Added test-statistic checks (R's W vs .u1, R's V vs .tPlus) for
#         all 20 cases. Previously no statistic was verified at all: a
#         p-value can match while the statistic behind it does not, if two
#         errors happen to cancel in the tail.
#
#     Consequence: this file's steady state is now exit 0, not exit 2.
#     If it ever exits 2 again, something was skipped that should not have
#     been, and the reason will be printed.
#
# 1.1 (2 Aug 2026) — Removed a structural false green. Eight tied/zero cases
#     were skipped with a bare cat() that incremented nothing, and the
#     check() helper returned silently on NA, so the file could print
#     "ALL CHECKS PASSED" while verifying only 12 of 22 expectations. Skips
#     are now registered, counted, echoed in the summary, and the banner
#     degrades to INCOMPLETE with a non-zero exit whenever anything is
#     skipped.
# 1.0 (26 Feb 2026) — Initial.
# ============================================================================

cat("==================================================\n")
cat("EML Stats Batch 3 — R Verification\n")
cat("==================================================\n\n")

pass <- 0
fail <- 0
skipped <- 0
skip_reasons <- character(0)

# A skipped check must never be able to read as a pass. Every skip — whether
# a deliberate section skip or an NA result — registers itself here, and the
# final banner is gated on skipped == 0 as well as fail == 0.
register_skip <- function(reason) {
  skipped <<- skipped + 1
  skip_reasons <<- c(skip_reasons, reason)
  cat(sprintf("  SKIP: %s\n", reason))
}

# ----------------------------------------------------------------------------
# REFERENCE-EMITTER MODE (added 3 August 2026)
# ----------------------------------------------------------------------------
# Set EML_EMIT_REFS=1 in the environment to make every performed check also
# print its R-computed value at full double precision:
#
#     REF: <label> = <%.17g>
#
# This exists so that Praat-side reference literals can be regenerated from
# the EXTERNAL reference rather than from the library under test. Copying a
# replacement literal out of the library's own output would make the assertion
# circular; copying it from this emitter does not, because these values come
# from base R.
#
# The mode is additive: checks still run and the exit code is unchanged, so an
# emitting run is also a verifying run and cannot silently ship a REF line for
# a quantity whose own check failed.
# ----------------------------------------------------------------------------
EMIT_REFS <- nzchar(Sys.getenv("EML_EMIT_REFS"))

check <- function(label, expected, actual, tol=0.001) {
  if (EMIT_REFS && !is.na(actual)) cat(sprintf("REF: %s = %.17g\n", label, actual))
  if (is.na(actual) || is.na(expected)) {
    register_skip(sprintf("%s (NA result — check not performed)", label))
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

# TOLERANCE POLICY (changed in 1.3 — see CHANGELOG)
# --------------------------------------------------
# These checks do NOT use the Praat assertion tolerances. The two
# comparisons answer different questions and need different tolerances:
#
#   Praat assertion : is the LIBRARY's computed value close enough to the
#                     reference literal? Genuine last-bit differences between
#                     two implementations are acceptable, so a working
#                     tolerance (1e-3) is right there.
#   This file       : is the reference LITERAL a correct transcription of the
#                     true value? A literal is either right or mis-typed;
#                     there is no legitimate slack beyond rounding.
#
# So each literal is checked at half a unit in its own last written decimal
# place — the largest error correct rounding can produce, and the smallest
# error a typo can produce. Under the previous policy (Praat tolerances) the
# slack ranged from 350x to 430,000x the actual residual, meaning a literal
# could be wrong by hundreds of times its real error and still read green.
ulp <- function(decimals) 0.5 * 10^(-decimals)

# For literals that are exact in binary or exactly representable rationals
# (1.0, 0.0625, 0.05) R reproduces them bit-for-bit; only last-bit noise is
# admissible.
EXACT_TOL <- 1e-12

TIGHT_TOL <- 0.000001   # test statistics: exact integers / half-integers

# ══════════════════════════════════════════════════════════════════════════════
# MANN-WHITNEY U (exact path, no ties)
# ══════════════════════════════════════════════════════════════════════════════
cat("--- Mann-Whitney U (exact path, no ties) ---\n")

r <- wilcox.test(c(1,2,3), c(4,5,6,7), exact=TRUE, alternative="two.sided")
check("MWU-1.1 U1", 0.0, unname(r$statistic), TIGHT_TOL)
check("MWU-1.1 p(2)", 0.05714, r$p.value, ulp(5))

r <- wilcox.test(c(10,20,30), c(1,2,3), exact=TRUE, alternative="greater")
check("MWU-1.3 U1", 9.0, unname(r$statistic), TIGHT_TOL)
check("MWU-1.3 p(1)", 0.05000, r$p.value, ulp(5))

# The library's one-tailed H1 is fixed as group1 > group2. Group 1 is
# entirely below group 2 here, so .p is ~1 and the opposite tail is
# exposed as .pLess. Both are checked, each against the matching R call.
r <- wilcox.test(c(1,2,3), c(10,20,30), exact=TRUE, alternative="greater")
check("MWU-1.4 U1", 0.0, unname(r$statistic), TIGHT_TOL)
check("MWU-1.4 p(1)", 1.0, r$p.value, EXACT_TOL)
r <- wilcox.test(c(1,2,3), c(10,20,30), exact=TRUE, alternative="less")
check("MWU-1.4 pLess", 0.05000, r$p.value, ulp(5))

r <- wilcox.test(c(5), c(1,2,3,4), exact=TRUE, alternative="greater")
check("MWU-1.6 U1", 4.0, unname(r$statistic), TIGHT_TOL)
check("MWU-1.6 p(1)", 0.20000, r$p.value, ulp(5))

# ══════════════════════════════════════════════════════════════════════════════
# MANN-WHITNEY U (tied inputs — normal approximation)
# ══════════════════════════════════════════════════════════════════════════════
# These were skipped through v1.1 on the premise that R could not supply a
# reference for them. See CHANGELOG 1.2(a): the library follows R's routing
# rule, so the tie-corrected normal approximation with continuity correction
# is exactly what the library computes here, and it is what R computes.
# exact=FALSE is stated explicitly rather than left to the tie fallback, so
# the computation is requested rather than stumbled into (and no warning is
# emitted). Independently corroborated by batch3_scipy_refs.py.
cat("\n--- Mann-Whitney U (tied inputs, normal approximation) ---\n")

r <- wilcox.test(c(1,2,3,4), c(2,3,5,6), exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-1.2 U1", 4.0, unname(r$statistic), TIGHT_TOL)
check("MWU-1.2 p(2)", 0.306492, r$p.value, ulp(6))

r <- wilcox.test(c(1,2,3,4,5), c(1,2,3,4,5), exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-1.5 U1", 12.5, unname(r$statistic), TIGHT_TOL)
check("MWU-1.5 p(2)", 1.0, r$p.value, EXACT_TOL)

r <- wilcox.test(1:10, 6:15, exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-1.7 U1", 12.5, unname(r$statistic), TIGHT_TOL)
check("MWU-1.7 p(2)", 0.00507539, r$p.value, ulp(8))

# ══════════════════════════════════════════════════════════════════════════════
# MANN-WHITNEY U (approximation path — n at/over the exact-path boundary)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Mann-Whitney U (approximation path) ---\n")

r <- wilcox.test(1:11, 6:15, exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-2.1 U1", 18.0, unname(r$statistic), TIGHT_TOL)
check("MWU-2.1 p(2)", 0.0100161, r$p.value, ulp(7))

# MWU-2.2 has no ties, so the library takes its EXACT path and asserts
# 0.77484. Verifying it against R's normal approximation (0.77155) checked
# a quantity the library does not compute here — see CHANGELOG 1.2(b).
r <- wilcox.test(seq(2,30,2), seq(1,29,2), exact=TRUE, alternative="two.sided")
check("MWU-2.2 U1", 120.0, unname(r$statistic), TIGHT_TOL)
check("MWU-2.2 p(2)", 0.77484, r$p.value, ulp(5))

r <- wilcox.test(seq(10,38,2), 1:15, exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-2.3 U1", 214.5, unname(r$statistic), TIGHT_TOL)
check("MWU-2.3 p(2)", 0.00003, r$p.value, ulp(5))

# ══════════════════════════════════════════════════════════════════════════════
# WILCOXON SIGNED-RANK (exact path, no ties, no zero differences)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Wilcoxon Signed-Rank (exact path, no ties) ---\n")

r <- wilcox.test(c(10,20,30,40,50), c(1,2,3,4,5), paired=TRUE, exact=TRUE, alternative="two.sided")
check("WSR-4.1 T+", 15.0, unname(r$statistic), TIGHT_TOL)
check("WSR-4.1 p(2)", 0.0625, r$p.value, EXACT_TOL)

r <- wilcox.test(c(1,2,3,4,5), c(10,20,30,40,50), paired=TRUE, exact=TRUE, alternative="two.sided")
check("WSR-4.4 T+", 0.0, unname(r$statistic), TIGHT_TOL)
check("WSR-4.4 p(2)", 0.0625, r$p.value, EXACT_TOL)

r <- wilcox.test(c(10), c(5), paired=TRUE, exact=TRUE, alternative="two.sided")
check("WSR-4.5 T+", 1.0, unname(r$statistic), TIGHT_TOL)
check("WSR-4.5 p(2)", 1.0, r$p.value, EXACT_TOL)

# ══════════════════════════════════════════════════════════════════════════════
# WILCOXON SIGNED-RANK (tied / zero differences — normal approximation)
# ══════════════════════════════════════════════════════════════════════════════
# Formerly skipped; see CHANGELOG 1.2(a). Zero differences are dropped
# before ranking by both R and the library, so R's V and the library's
# .tPlus are computed over the same non-zero set.
cat("\n--- Wilcoxon Signed-Rank (tied / zero differences) ---\n")

r <- wilcox.test(c(8,6,3,12,5), c(5,3,1,7,4), paired=TRUE,
                 exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-4.2 T+", 15.0, unname(r$statistic), TIGHT_TOL)
check("WSR-4.2 p(2)", 0.0579073, r$p.value, ulp(7))

r <- wilcox.test(c(5,3,7,4,6), c(5,1,7,2,6), paired=TRUE,
                 exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-4.3 T+", 3.0, unname(r$statistic), TIGHT_TOL)
check("WSR-4.3 p(2)", 0.345779, r$p.value, ulp(6))

r <- wilcox.test(c(10,5), c(5,10), paired=TRUE,
                 exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-4.6 T+", 1.5, unname(r$statistic), TIGHT_TOL)
check("WSR-4.6 p(2)", 1.0, r$p.value, EXACT_TOL)

# One-tailed: the library's fixed H1 (group1 > group2) is R's "greater".
r <- wilcox.test(16:30, 1:15, paired=TRUE,
                 exact=FALSE, correct=TRUE, alternative="greater")
check("WSR-4.7 T+", 120.0, unname(r$statistic), TIGHT_TOL)
check("WSR-4.7 p(1)", 0.0000613399, r$p.value, ulp(10))

x48 <- c(10,12,8,15,6,20,3,14,9,11,7,16,5,18,13)
y48 <- c(8,10,9,12,7,15,5,10,11,8,9,12,7,14,10)
r <- wilcox.test(x48, y48, paired=TRUE,
                 exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-4.8 T+", 95.0, unname(r$statistic), TIGHT_TOL)
check("WSR-4.8 p(2)", 0.048032, r$p.value, ulp(6))

# ══════════════════════════════════════════════════════════════════════════════
# WILCOXON SIGNED-RANK (approximation path — larger n)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Wilcoxon Signed-Rank (approximation path) ---\n")

x9 <- c(10,12,8,15,6,20,3,14,9,11,7,16,5,18,13,22)
y9 <- c(8,10,9,12,7,15,5,10,11,8,9,12,7,14,10,17)
r <- wilcox.test(x9, y9, paired=TRUE, exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-5.1 T+", 111.0, unname(r$statistic), TIGHT_TOL)
check("WSR-5.1 p(2)", 0.0268056, r$p.value, ulp(7))

x10 <- c(20,22,18,25,16,30,13,24,19,21,17,26,15,28,23,31,14,27,20,29)
y10 <- c(15,18,19,20,17,22,16,18,21,16,19,20,18,22,17,25,16,21,22,23)
r <- wilcox.test(x10, y10, paired=TRUE, exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-5.2 T+", 174.0, unname(r$statistic), TIGHT_TOL)
check("WSR-5.2 p(2)", 0.0100682, r$p.value, ulp(7))

# ══════════════════════════════════════════════════════════════════════════════
# Coverage assertion. The check tally is itself checked: if a section is
# ever commented out or an early error skips past a block, the count falls
# short and this registers a failure rather than letting a smaller green
# run masquerade as a complete one.
EXPECTED_CHECKS <- 41
performed <- pass + fail + skipped
if (performed != EXPECTED_CHECKS) {
  fail <- fail + 1
  cat(sprintf("  FAIL: coverage (expected %d checks to be performed, saw %d)\n",
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
  for (r in skip_reasons) cat(sprintf("  * %s\n", r))
  cat("This run does NOT constitute verification of the skipped checks.\n")
} else {
  cat("ALL CHECKS PASSED\n")
}
cat("==================================================\n")

# Exit-code contract, shared by every verifier in this directory:
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
# A runner must not collapse 2 into 0. As of v1.2 this file has no
# structural skips left, so 0 is its steady state; a 2 here now means
# something went wrong, not that R is structurally unable to help.
if (fail > 0) quit(status = 1)
if (skipped > 0) quit(status = 2)
quit(status = 0)
