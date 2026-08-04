# ============================================================================
# EML Stats : Test Suite — Inferential Statistics (Batch 4)
# ============================================================================
# Tests: @emlRankBiserialR, @emlMatchedPairsR
# Date: 3 March 2026
#
# Uses shared test helpers (eml-test-helpers.praat).
# Reference values computed via scipy (3 Mar 2026) and
# independently verified via R (verify-inferential-batch4.R).
#
# r values are exact arithmetic on U1/U2 (RBS) or T+/T- (MPR),
# which are already verified in Batch 3. These tests focus on
# the effect size computation and passthrough correctness.
#
# Include order: utilities (for @emlRankVector) -> inferential -> test helpers
#
# Revised: 2 August 2026 (v1.1)
# v1.1 — Audit item 7 (exact/approximate routing). The library now follows
# R's wilcox.test rule exactly: the exact null is used only when there are no
# ties (and, for the signed-rank test, no zero differences); otherwise the
# normal approximation with tie correction is used, as R does. Every case
# revised below contains ties, so R itself would not use the exact null. The
# effect sizes (r, from U1/U2 or T+/T-) are exact arithmetic and are unchanged.
# Only .method$ and .rZ change: .rZ is undefined on the exact path (no Z
# exists) and defined on the approximation path, so the three former
# "rZ undefined" assertions now assert the R-consistent Z-derived value.
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.001
tightTolerance = 0.000001
looseTolerance = 0.01


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: @emlRankBiserialR — Exact path
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlRankBiserialR — Exact path"

# --- 1.1: g2 > g1, complete separation (expect r = -1) ---
@emlRankBiserialR: {1, 2, 3}, {4, 5, 6, 7}, 2
@emlTestAssertEqualStr: "RBS-1.1 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.1 r", -1.0, emlRankBiserialR.r, tightTolerance
@emlTestAssertEqualNum: "RBS-1.1 U1", 0.0, emlRankBiserialR.u1, tightTolerance
@emlTestAssertEqualStr: "RBS-1.1 method", "exact", emlRankBiserialR.method$

# --- 1.2: Ties, partial overlap (expect r = -0.5) ---
@emlRankBiserialR: {1, 2, 3, 4}, {2, 3, 5, 6}, 2
@emlTestAssertEqualStr: "RBS-1.2 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.2 r", -0.5, emlRankBiserialR.r, tightTolerance
@emlTestAssertEqualNum: "RBS-1.2 U1", 4.0, emlRankBiserialR.u1, tightTolerance

# --- 1.3: g1 >> g2, complete separation (expect r = +1) ---
@emlRankBiserialR: {10, 20, 30}, {1, 2, 3}, 2
@emlTestAssertEqualStr: "RBS-1.3 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.3 r", 1.0, emlRankBiserialR.r, tightTolerance
@emlTestAssertEqualNum: "RBS-1.3 U1", 9.0, emlRankBiserialR.u1, tightTolerance

# --- 1.4: g1 << g2, complete separation (expect r = -1) ---
@emlRankBiserialR: {1, 2, 3}, {10, 20, 30}, 2
@emlTestAssertEqualStr: "RBS-1.4 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.4 r", -1.0, emlRankBiserialR.r, tightTolerance

# --- 1.5: Identical groups (expect r = 0) ---
@emlRankBiserialR: {1, 2, 3, 4, 5}, {1, 2, 3, 4, 5}, 2
@emlTestAssertEqualStr: "RBS-1.5 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.5 r", 0.0, emlRankBiserialR.r, tightTolerance

# --- 1.6: Overlapping distributions, small effect ---
@emlRankBiserialR: {5.1, 4.9, 5.3, 4.8, 5.0, 5.2, 4.7, 5.4},
    ... {5.0, 5.1, 4.8, 5.2, 4.9, 5.3, 5.1, 4.7}, 2
@emlTestAssertEqualStr: "RBS-1.6 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.6 r", 0.09375, emlRankBiserialR.r, tolerance
# Ties across the two samples (4.7, 4.8, 4.9, 5.0, 5.1, 5.2, 5.3 all repeat),
# so R's wilcox.test uses the normal approximation with tie correction.
@emlTestAssertEqualStr: "RBS-1.6 method", "normal approximation", emlRankBiserialR.method$

# --- 1.7: One-tailed (r is same, p differs from two-tailed) ---
@emlRankBiserialR: {10, 20, 30}, {1, 2, 3}, 1
@emlTestAssertEqualStr: "RBS-1.7 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.7 r", 1.0, emlRankBiserialR.r, tightTolerance

# --- 1.8: Minimal n1=n2=1 ---
@emlRankBiserialR: {5}, {3}, 2
@emlTestAssertEqualStr: "RBS-1.8 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.8 r", 1.0, emlRankBiserialR.r, tightTolerance

# --- 1.9: Unequal sizes, g1 > g2 ---
@emlRankBiserialR: {8, 9, 10, 11, 12}, {1, 2, 3}, 2
@emlTestAssertEqualStr: "RBS-1.9 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-1.9 r", 1.0, emlRankBiserialR.r, tightTolerance
@emlTestAssertEqualNum: "RBS-1.9 n1", 5, emlRankBiserialR.n1, tightTolerance
@emlTestAssertEqualNum: "RBS-1.9 n2", 3, emlRankBiserialR.n2, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: @emlRankBiserialR — Approximation path
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlRankBiserialR — Approximation path"

# --- 2.1: Large, g1 shifted right (n1+n2=21, approx path) ---
# scipy: U1=73.5, U2=36.5, r=0.33636
@emlRankBiserialR: {2.1, 3.4, 4.5, 5.2, 6.1, 7.3, 8.0, 9.1, 10.2, 11.5, 12.0},
    ... {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0}, 2
@emlTestAssertEqualStr: "RBS-2.1 no error", "", emlRankBiserialR.error$
@emlTestAssertEqualNum: "RBS-2.1 r", 0.33636, emlRankBiserialR.r, tolerance
# Ties present across samples, so the normal approximation applies (as in R).
@emlTestAssertEqualStr: "RBS-2.1 method", "normal approximation", emlRankBiserialR.method$
@emlTestAssertEqualNum: "RBS-2.1 n1", 11, emlRankBiserialR.n1, tightTolerance
@emlTestAssertEqualNum: "RBS-2.1 n2", 10, emlRankBiserialR.n2, tightTolerance

# --- 2.2: Passthrough check — p matches direct MWU call ---
@emlMannWhitneyU: {2.1, 3.4, 4.5, 5.2, 6.1, 7.3, 8.0, 9.1, 10.2, 11.5, 12.0},
    ... {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0}, 2
@emlTestAssertEqualNum: "RBS-2.2 p passthrough", emlMannWhitneyU.p, emlRankBiserialR.p, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: @emlRankBiserialR — Error handling
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlRankBiserialR — Error handling"

# --- 3.1: Invalid tails ---
@emlRankBiserialR: {1, 2, 3}, {4, 5, 6}, 3
@emlTestAssertTrue: "RBS-3.1 error on bad tails", emlRankBiserialR.error$ <> ""

# --- 3.2: r is undefined on error ---
@emlTestAssertUndefined: "RBS-3.2 r undefined on error", emlRankBiserialR.r


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: @emlMatchedPairsR — Exact path (r_T only)
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlMatchedPairsR — Exact path"

# --- 4.1: All positive diffs, exact (r = 1.0) ---
# Diffs: 0.7, 1.3, 1.3, 1.3, 0.3 — all positive → T+=15, T-=0, S=15
@emlMatchedPairsR: {1.2, 3.4, 5.6, 7.8, 9.0}, {0.5, 2.1, 4.3, 6.5, 8.7}, 2
@emlTestAssertEqualStr: "MPR-4.1 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.1 r", 1.0, emlMatchedPairsR.r, tightTolerance
@emlTestAssertEqualNum: "MPR-4.1 tPlus", 15.0, emlMatchedPairsR.tPlus, tightTolerance
@emlTestAssertEqualNum: "MPR-4.1 tMinus", 0.0, emlMatchedPairsR.tMinus, tightTolerance
# Tied absolute differences (1.3 appears three times) force the normal
# approximation, matching R wilcox.test(x, y, paired = TRUE).
@emlTestAssertEqualStr: "MPR-4.1 method", "normal approximation", emlMatchedPairsR.method$
# rZ is defined on the approximation path: rZ = Z / sqrt(n).
@emlTestAssertEqualNum: "MPR-4.1 rZ", 0.860013, emlMatchedPairsR.rZ, tolerance

# --- 4.2: Mixed diffs, near zero (r = 0.06667) ---
# Diffs: -2, 2, -7, 5, 2 → T+=8, T-=7, S=15
@emlMatchedPairsR: {10, 20, 15, 25, 30}, {12, 18, 22, 20, 28}, 2
@emlTestAssertEqualStr: "MPR-4.2 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.2 r", 0.06667, emlMatchedPairsR.r, tolerance
@emlTestAssertEqualNum: "MPR-4.2 tPlus", 8.0, emlMatchedPairsR.tPlus, tightTolerance
@emlTestAssertEqualNum: "MPR-4.2 tMinus", 7.0, emlMatchedPairsR.tMinus, tightTolerance

# --- 4.3: Perfect concordance v1 >> v2 (r = 1.0) ---
@emlMatchedPairsR: {10, 20, 30, 40, 50}, {1, 2, 3, 4, 5}, 2
@emlTestAssertEqualStr: "MPR-4.3 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.3 r", 1.0, emlMatchedPairsR.r, tightTolerance

# --- 4.4: All negative diffs (r = -1.0) ---
@emlMatchedPairsR: {1, 2, 3, 4, 5}, {10, 20, 30, 40, 50}, 2
@emlTestAssertEqualStr: "MPR-4.4 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.4 r", -1.0, emlMatchedPairsR.r, tightTolerance
@emlTestAssertEqualNum: "MPR-4.4 tPlus", 0.0, emlMatchedPairsR.tPlus, tightTolerance
@emlTestAssertEqualNum: "MPR-4.4 tMinus", 15.0, emlMatchedPairsR.tMinus, tightTolerance

# --- 4.5: Some zero diffs (excluded from ranking; n_nonzero=3) ---
# v1 - v2: 0, 2, 0, 5, -5 → nonzero: 2, 5, -5
# abs: 2, 5, 5 → ranks: 1, 2.5, 2.5
# T+ = 1 + 2.5 = 3.5, T- = 2.5, S = 6
# r = (3.5 - 2.5)/6 = 0.16667
@emlMatchedPairsR: {10, 20, 30, 40, 50}, {10, 18, 30, 35, 55}, 2
@emlTestAssertEqualStr: "MPR-4.5 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.5 r", 0.16667, emlMatchedPairsR.r, tolerance
@emlTestAssertEqualNum: "MPR-4.5 nNonzero", 3, emlMatchedPairsR.nNonzero, tightTolerance
@emlTestAssertEqualNum: "MPR-4.5 nZero", 2, emlMatchedPairsR.nZero, tightTolerance

# --- 4.6: One-tailed, all positive (r = 1.0, lower p) ---
@emlMatchedPairsR: {10, 20, 30, 40, 50}, {1, 2, 3, 4, 5}, 1
@emlTestAssertEqualStr: "MPR-4.6 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.6 r", 1.0, emlMatchedPairsR.r, tightTolerance
@emlTestAssertEqualNum: "MPR-4.6 p", 0.03125, emlMatchedPairsR.p, tolerance

# --- 4.7: Minimal pairs n=2 (r = 1.0) ---
# Diffs: 2, 3 — both positive → T+=3, T-=0, S=3
@emlMatchedPairsR: {5, 10}, {3, 7}, 2
@emlTestAssertEqualStr: "MPR-4.7 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.7 r", 1.0, emlMatchedPairsR.r, tightTolerance
@emlTestAssertEqualNum: "MPR-4.7 n", 2, emlMatchedPairsR.n, tightTolerance

# --- 4.8: Ties in abs diffs (r = 0.71429) ---
# Diffs: 2, 2, 2, 2, -2, 3 → abs: 2,2,2,2,2,3 → ranks: 3,3,3,3,3,6
# T+ = 3+3+3+3+6 = 18, T- = 3, S = 21
# r = (18 - 3)/21 = 0.71429
@emlMatchedPairsR: {10, 20, 30, 40, 50, 60}, {8, 18, 28, 38, 52, 57}, 2
@emlTestAssertEqualStr: "MPR-4.8 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-4.8 r", 0.71429, emlMatchedPairsR.r, tolerance
@emlTestAssertEqualNum: "MPR-4.8 tPlus", 18.0, emlMatchedPairsR.tPlus, tightTolerance
@emlTestAssertEqualNum: "MPR-4.8 tMinus", 3.0, emlMatchedPairsR.tMinus, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 5: @emlMatchedPairsR — Approximation path (r_T and r_Z)
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlMatchedPairsR — Approximation path"

# --- 5.1: Large, all positive diffs (n=20, r_T=1.0, r_Z=0.882) ---
# All v1[i] > v2[i]; T+=210, T-=0, S=210
# z=3.94445 (our procedure, with continuity + tie correction)
# rZ = 3.94445/sqrt(20) = 0.88201
@emlMatchedPairsR: {12.1, 14.3, 11.8, 15.2, 13.7, 16.0, 12.5, 14.8,
    ... 13.1, 15.5, 11.9, 14.0, 16.2, 13.3, 15.8, 12.7,
    ... 14.5, 11.6, 15.0, 13.9},
    ... {10.5, 12.1, 10.2, 13.0, 11.5, 13.8, 10.9, 12.6,
    ... 11.0, 13.3, 10.0, 11.8, 14.0, 11.2, 13.5, 10.5,
    ... 12.3, 9.8, 12.8, 11.7}, 2
@emlTestAssertEqualStr: "MPR-5.1 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-5.1 r", 1.0, emlMatchedPairsR.r, tightTolerance
# Tied absolute differences force the normal approximation (as in R);
# rZ = Z / sqrt(n) is therefore defined.
@emlTestAssertEqualNum: "MPR-5.1 rZ", 0.882006, emlMatchedPairsR.rZ, tolerance
@emlTestAssertEqualStr: "MPR-5.1 method", "normal approximation", emlMatchedPairsR.method$
@emlTestAssertEqualNum: "MPR-5.1 nNonzero", 20, emlMatchedPairsR.nNonzero, tightTolerance
@emlTestAssertEqualNum: "MPR-5.1 tPlus", 210.0, emlMatchedPairsR.tPlus, tightTolerance

# --- 5.2: Large, near-zero effect (n=16, r_T=0.07353, r_Z=0.05841) ---
# T+=73, T-=63, S=136
# z=0.23363 (our procedure)
# rZ = 0.23363/sqrt(16) = 0.05841
@emlMatchedPairsR: {5.1, 4.9, 5.3, 4.8, 5.0, 5.2, 4.7, 5.4,
    ... 5.0, 4.6, 5.5, 4.8, 5.1, 5.3, 4.9, 5.2},
    ... {5.0, 5.1, 4.8, 5.2, 4.9, 5.3, 5.1, 4.7,
    ... 5.2, 4.8, 5.0, 5.1, 4.9, 5.2, 5.0, 4.8}, 2
@emlTestAssertEqualStr: "MPR-5.2 no error", "", emlMatchedPairsR.error$
@emlTestAssertEqualNum: "MPR-5.2 r", 0.07353, emlMatchedPairsR.r, tolerance
# Ties in |diff| force the normal approximation; rZ = Z / sqrt(n) is defined.
@emlTestAssertEqualNum: "MPR-5.2 rZ", 0.0584071, emlMatchedPairsR.rZ, tolerance
@emlTestAssertEqualNum: "MPR-5.2 tPlus", 73.0, emlMatchedPairsR.tPlus, tightTolerance
@emlTestAssertEqualNum: "MPR-5.2 tMinus", 63.0, emlMatchedPairsR.tMinus, tightTolerance

# --- 5.3: Passthrough check — p matches direct Wilcoxon call ---
@emlWilcoxonSignedRank: {5.1, 4.9, 5.3, 4.8, 5.0, 5.2, 4.7, 5.4,
    ... 5.0, 4.6, 5.5, 4.8, 5.1, 5.3, 4.9, 5.2},
    ... {5.0, 5.1, 4.8, 5.2, 4.9, 5.3, 5.1, 4.7,
    ... 5.2, 4.8, 5.0, 5.1, 4.9, 5.2, 5.0, 4.8}, 2
@emlTestAssertEqualNum: "MPR-5.3 p passthrough", emlWilcoxonSignedRank.p, emlMatchedPairsR.p, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 6: @emlMatchedPairsR — Error handling
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlMatchedPairsR — Error handling"

# --- 6.1: Unequal lengths ---
@emlMatchedPairsR: {1, 2, 3}, {4, 5}, 2
@emlTestAssertTrue: "MPR-6.1 error on unequal", emlMatchedPairsR.error$ <> ""

# --- 6.2: All zero diffs ---
@emlMatchedPairsR: {5, 10, 15}, {5, 10, 15}, 2
@emlTestAssertTrue: "MPR-6.2 error on zero diffs", emlMatchedPairsR.error$ <> ""

# --- 6.3: r undefined on error ---
@emlTestAssertUndefined: "MPR-6.3 r undefined on error", emlMatchedPairsR.r

# --- 6.4: Invalid tails ---
@emlMatchedPairsR: {1, 2, 3}, {4, 5, 6}, 0
@emlTestAssertTrue: "MPR-6.4 error on bad tails", emlMatchedPairsR.error$ <> ""


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 7: Direction consistency checks
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "Direction consistency"

# --- 7.1: RBS sign flips when groups are swapped ---
@emlRankBiserialR: {10, 20, 30}, {1, 2, 3}, 2
rForward = emlRankBiserialR.r
@emlRankBiserialR: {1, 2, 3}, {10, 20, 30}, 2
rReverse = emlRankBiserialR.r
@emlTestAssertEqualNum: "RBS-7.1 sign flips", rForward, -rReverse, tightTolerance

# --- 7.2: MPR sign flips when pairs are swapped ---
@emlMatchedPairsR: {10, 20, 30, 40, 50}, {1, 2, 3, 4, 5}, 2
rForward = emlMatchedPairsR.r
@emlMatchedPairsR: {1, 2, 3, 4, 5}, {10, 20, 30, 40, 50}, 2
rReverse = emlMatchedPairsR.r
@emlTestAssertEqualNum: "MPR-7.2 sign flips", rForward, -rReverse, tightTolerance

# --- 7.3: RBS r=0 when no group difference ---
@emlRankBiserialR: {3, 3, 3, 3}, {3, 3, 3, 3}, 2
@emlTestAssertEqualNum: "RBS-7.3 r=0 for equal groups", 0.0, emlRankBiserialR.r, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
