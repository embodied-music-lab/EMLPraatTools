# ============================================================================
# EML Stats : Test Suite — Shapiro-Wilk (@emlShapiroWilk)
# ============================================================================
# Tests: @emlShapiroWilk
# Version: 2.0
# Date: 2 August 2026 (original 26 February 2026)
#
# Uses shared test helpers (eml-test-helpers.praat).
#
# Every numeric literal below is externally verified by the committed
# companion artifact verify-shapiro-wilk.R (same directory), which asserts
# each literal against R's own shapiro.test and exits non-zero on
# disagreement. Regenerate/re-check with:
#     Rscript verify-shapiro-wilk.R
# Do not hand-edit the literals. The eight data vectors here and the eight in
# verify-shapiro-wilk.R are the same numbers in the same order; edit both or
# neither, or the two files stop corresponding.
#
# CHANGELOG
# 2.0 (2 Aug 2026) — Converted from a printer into a test suite.
#
#     WHAT WAS WRONG WITH 1.0
#     -----------------------
#     v1.0 contained ZERO assertions. It did not use the shared test harness
#     at all. It defined a private @checkSW procedure that printed "PASS" or
#     "FAIL" strings and incremented two local counters, and then, at the
#     end, printed the tally and returned normally. Nothing called
#     exitScript:, nothing called assert, nothing emitted the runner
#     sentinel. The script exited 0 whether every case passed or every case
#     failed, so a runner reading exit status saw an unbroken green that was
#     green by construction. It was not a test; it was a report that nobody
#     was obliged to read.
#
#     Two further consequences of not using the harness:
#       * its results were invisible to the suite runner (no
#         EMLTEST-RESULT sentinel), and
#       * a check that was never reached — an error before the tally, say —
#         reduced the printed total silently, with nothing to notice it.
#
#     WHAT 2.0 DOES
#     -------------
#       * include ../eml-test-helpers.praat; @emlTestInit / @emlTestSection /
#         @emlTestSummary, matching every other phase2 suite
#       * every printed value replaced by an @emlTestAssertEqualNum with the
#         expected literal FIRST and the library's value SECOND
#       * failures now reach both channels: exit 255 and status=FAIL in the
#         sentinel line
#       * literals re-emitted at 12 decimals (v1.0 carried p literals at 5
#         decimals with pTol = 5e-3 — a tolerance 500x the literal's own
#         rounding, inside which a real regression could sit unseen)
#       * error-path cases now assert that .w and .p are undefined, not just
#         that .error$ is non-empty
#       * the n > 5000 upper input bound, previously untested, is covered
#
#     DATA SETS: THE RNG PROBLEM
#     --------------------------
#     v1.0 of the companion R verifier generated its last three samples with
#     set.seed()+rnorm/rexp. R's Mersenne-Twister stream is not reproducible
#     in Praat, so those reference values described numbers this suite would
#     never see. All three are now fixed literal vectors present in both
#     files (SW-6, SW-7 and the new SW-8, n=100). SW-6 and SW-7 are the same
#     30-value vectors this file already used; only the R side was random.
#
#     LIBRARY AGREEMENT (measured before these literals were committed)
#     ----------------------------------------------------------------
#     @emlShapiroWilk was run on all eight vectors and compared with R at 12
#     decimals. W and p agree to within 5e-13 — the rounding of the literals
#     themselves — on every case except SW-1 (n=3), whose p differs by
#     2.8e-8. That is not a defect: for n = 3 both implementations use the
#     exact arcsine form p = (6/pi)(asin(sqrt(W)) - asin(sqrt(3/4))), whose
#     derivative diverges as W -> 1. The library's W is one ulp below 1.0, and
#     asin amplifies 2.2e-16 in W to ~1.5e-8 in p. That single assertion
#     therefore uses nearOneTolerance; everything else uses tightTolerance.
#     The literal asserted is R's value, not the library's output.
# 1.0 (26 Feb 2026) — Initial. Printer only; see above.
# ============================================================================

include ../../../stats/eml-core-descriptive.praat
include ../eml-test-helpers.praat

@emlTestInit

# ============================================================================
# Tolerances
# ============================================================================
# tightTolerance: all W and p literals are written to 12 decimals, and the
#   library was measured to agree with R to within 5e-13 on every one of
#   them. 1e-9 is roughly 2000x that residual — loose enough that a genuine
#   last-bit difference between two implementations of AS R94 cannot trip it,
#   tight enough that a mis-typed literal cannot hide inside it.
# nearOneTolerance: used for exactly one assertion, SW-1's p. See the
#   CHANGELOG note on the arcsine branch at W -> 1. 1e-6 is ~35x the observed
#   2.8e-8 difference, so it still detects any perturbation at 1e-5 or above.
tightTolerance = 0.000000001
nearOneTolerance = 0.000001


# ============================================================================
# Shared test data
# ============================================================================
# Identical to the sw1..sw8 vectors in verify-shapiro-wilk.R.

sw1# = {1, 2, 3}

sw2# = {3.1, 4.2, 3.8, 4.5}

sw3# = {2.3, 1.8, 2.5, 2.1, 2.0}

sw4# = {92.96, 96.49, 96.49, 97.93, 107.45,
    ... 108.14, 109.72, 111.51, 122.85, 123.69}

sw5# = {8.86, 0.78, 9.8, 2.48, 7.53, 5.27, 9.08, 8.84, 0.89, 5.17,
    ... 3.44, 2.12, 3.61, 2.71, 7.62, 4.78, 0.99, 2.75, 7.94, 5.14}

# SW-6: formerly generated by set.seed(123); round(rnorm(30, 50, 10), 2).
# Frozen as literals so both files hold the identical sample.
sw6# = {39.14, 59.97, 52.83, 34.94, 44.21, 66.51, 25.73, 45.71, 62.66,
    ... 41.33, 43.21, 49.05, 64.91, 43.61, 45.56, 45.66, 72.06, 71.87,
    ... 60.04, 53.86, 57.37, 64.91, 40.64, 61.76, 37.46, 43.62, 59.07,
    ... 35.71, 48.6, 41.38}

# SW-7: formerly generated by set.seed(456); round(rexp(30, 1/5), 2).
sw7# = {1.43, 0.89, 7.65, 8.26, 4.91, 4.63, 10.84, 7.12, 1.0, 0.81,
    ... 2.86, 2.43, 4.29, 0.79, 5.8, 3.16, 4.22, 5.19, 6.42, 5.71,
    ... 1.0, 0.63, 1.39, 0.04, 2.23, 0.79, 3.91, 9.73, 1.12, 0.72}

# SW-8: formerly generated by set.seed(789); round(rnorm(100, 0, 1), 4).
# The case needs a large approximately-normal sample, not a random one.
sw8# = {0.5241, -2.2608, -0.0197, 0.1831, -0.3614, -0.4845, -0.6663,
    ... -0.1745, -1.011, 0.7397, -0.4023, -1.0028, -0.1777, -0.4879,
    ... 0.9279, -0.7744, 0.4229, -0.607, 0.2094, -0.7773, -0.7021,
    ... 0.6835, -0.8577, 0.3678, -1.4297, -0.5123, -0.2681, -0.1992,
    ... 0.8566, -0.1668, -0.3757, -1.135, 0.6093, 0.5659, -0.736,
    ... -1.0586, -1.3179, -0.2044, -0.6014, 0.6606, -0.1647, 1.7595,
    ... 1.612, 0.8032, 1.2652, 0.511, -3.0876, 0.4742, 0.6259, 0.9812,
    ... -0.0477, -1.5196, 0.7949, -0.1442, -0.7065, 0.6107, 1.0851,
    ... -0.7113, 1.1563, 1.2356, -0.3225, 0.7328, -0.2875, 2.3485,
    ... 0.3477, -0.3455, -0.9026, -0.3939, -0.9638, 0.7693, 0.5447,
    ... 1.0497, 1.1928, -0.3382, -1.0578, -0.2644, 1.5017, 0.7877,
    ... 0.3347, -1.6272, 1.8495, 0.4749, -0.9872, 0.2559, -1.4109,
    ... 0.0878, 0.3146, -0.4388, -1.45, 1.3237, -0.4779, 1.0525,
    ... -0.8171, -1.1369, -2.6197, 0.9858, 0.1984, -0.6233, 0.45,
    ... 1.4992}


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: small n — exact (n=3) and gamma (n=4,5) branches
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlShapiroWilk — small n (exact and gamma branches)"

# --- Test 1.1: n=3, perfectly linear ---
# R: shapiro.test(c(1,2,3)) -> W = 1, p = 1
# The n=3 p-value uses the exact arcsine form, which is ill-conditioned at
# W = 1; see the tolerance note above for why p is asserted at 1e-6.
@emlShapiroWilk: sw1#
@emlTestAssertEqualNum: "SW-1 n=3 W", 1.0, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-1 n=3 p", 1.0, emlShapiroWilk.p, nearOneTolerance
@emlTestAssertEqualNum: "SW-1 n=3 reports n", 3, emlShapiroWilk.n, 0
@emlTestAssertTrue: "SW-1 n=3 no error", emlShapiroWilk.error$ = ""

# --- Test 1.2: n=4 ---
# R: shapiro.test(c(3.1,4.2,3.8,4.5))
#    W = 0.962030073282, p = 0.791677943443
@emlShapiroWilk: sw2#
@emlTestAssertEqualNum: "SW-2 n=4 W", 0.962030073282, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-2 n=4 p", 0.791677943443, emlShapiroWilk.p, tightTolerance

# --- Test 1.3: n=5 ---
# R: shapiro.test(c(2.3,1.8,2.5,2.1,2.0))
#    W = 0.989977466626, p = 0.979615511470
@emlShapiroWilk: sw3#
@emlTestAssertEqualNum: "SW-3 n=5 W", 0.989977466626, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-3 n=5 p", 0.979615511470, emlShapiroWilk.p, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: n=10 — gamma branch at its upper end, with tied values
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlShapiroWilk — n=10 (gamma branch, tied values)"

# --- Test 2.1: n=10, contains a tied pair (96.49 twice) ---
# R: W = 0.907650153011, p = 0.265236942071
@emlShapiroWilk: sw4#
@emlTestAssertEqualNum: "SW-4 n=10 W", 0.907650153011, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-4 n=10 p", 0.265236942071, emlShapiroWilk.p, tightTolerance

# --- Test 2.2: order invariance ---
# The statistic is defined on the order statistics, so a permutation of the
# same values must give the identical W and p. Same numbers as sw4#, shuffled.
sw4shuffled# = {107.45, 97.93, 109.72, 122.85, 96.49,
    ... 96.49, 123.69, 111.51, 92.96, 108.14}
@emlShapiroWilk: sw4shuffled#
@emlTestAssertEqualNum: "SW-4 unsorted input gives same W", 0.907650153011,
    ... emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-4 unsorted input gives same p", 0.265236942071,
    ... emlShapiroWilk.p, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: n >= 12 — Royston (1995) log-normal branch
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlShapiroWilk — n >= 12 (log-normal branch)"

# --- Test 3.1: n=20, uniform (moderate departure from normality) ---
# R: W = 0.922737157512, p = 0.111874183264
@emlShapiroWilk: sw5#
@emlTestAssertEqualNum: "SW-5 n=20 uniform W", 0.922737157512, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-5 n=20 uniform p", 0.111874183264, emlShapiroWilk.p, tightTolerance

# --- Test 3.2: n=30, normal ---
# R: W = 0.962136866176, p = 0.350871750897
@emlShapiroWilk: sw6#
@emlTestAssertEqualNum: "SW-6 n=30 normal W", 0.962136866176, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-6 n=30 normal p", 0.350871750897, emlShapiroWilk.p, tightTolerance
@emlTestAssertTrue: "SW-6 n=30 normal not rejected at .05", emlShapiroWilk.p > 0.05

# --- Test 3.3: n=30, exponential (clearly non-normal) ---
# R: W = 0.903974016144, p = 0.010519966454
@emlShapiroWilk: sw7#
@emlTestAssertEqualNum: "SW-7 n=30 exponential W", 0.903974016144, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-7 n=30 exponential p", 0.010519966454, emlShapiroWilk.p, tightTolerance
@emlTestAssertTrue: "SW-7 n=30 exponential rejected at .05", emlShapiroWilk.p < 0.05

# --- Test 3.4: n=100, normal (large sample) ---
# R: W = 0.987633495666, p = 0.481589049392
@emlShapiroWilk: sw8#
@emlTestAssertEqualNum: "SW-8 n=100 normal W", 0.987633495666, emlShapiroWilk.w, tightTolerance
@emlTestAssertEqualNum: "SW-8 n=100 normal p", 0.481589049392, emlShapiroWilk.p, tightTolerance
@emlTestAssertEqualNum: "SW-8 n=100 reports n", 100, emlShapiroWilk.n, 0


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: input validation and error paths
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlShapiroWilk — input validation"

# --- Test 4.1: n < 3 (below the lower bound) ---
tooFew# = {1, 2}
@emlShapiroWilk: tooFew#
@emlTestAssertTrue: "n<3 reports error", emlShapiroWilk.error$ <> ""
@emlTestAssertUndefined: "n<3 W undefined", emlShapiroWilk.w
@emlTestAssertUndefined: "n<3 p undefined", emlShapiroWilk.p

# --- Test 4.2: constant data (zero range) ---
flat# = {5, 5, 5, 5}
@emlShapiroWilk: flat#
@emlTestAssertTrue: "constant data reports error", emlShapiroWilk.error$ <> ""
@emlTestAssertUndefined: "constant data W undefined", emlShapiroWilk.w
@emlTestAssertUndefined: "constant data p undefined", emlShapiroWilk.p

# --- Test 4.3: n > 5000 (above the upper bound) ---
# The n-range check runs before the zero-range check, so an all-zero vector
# of length 5001 exercises the upper bound and not the constant-data path.
tooMany# = zero# (5001)
@emlShapiroWilk: tooMany#
@emlTestAssertTrue: "n>5000 reports error", emlShapiroWilk.error$ <> ""
@emlTestAssertUndefined: "n>5000 W undefined", emlShapiroWilk.w


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
