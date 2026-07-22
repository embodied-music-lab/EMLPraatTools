# ============================================================================
# EML Stats : Test Suite — Inferential Statistics (Batch 3)
# ============================================================================
# Tests: @emlMannWhitneyU, @emlWilcoxonSignedRank
# Date: 26 February 2026
#
# Uses shared test helpers (eml-test-helpers.praat).
# Reference values computed via scipy.stats (26 Feb 2026) and
# independently verified via R (verify-inferential-batch3.R).
#
# Include order: utilities (for @emlRankVector) -> inferential -> test helpers
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.001
tightTolerance = 0.000001
looseTolerance = 0.01


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: @emlMannWhitneyU — Exact path
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlMannWhitneyU — Exact path"

# --- 1.1: Small, no ties (n1=3, n2=4) ---
@emlMannWhitneyU: {1, 2, 3}, {4, 5, 6, 7}, 2
@emlTestAssertEqualStr: "MWU-1.1 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-1.1 U1", 0.0, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-1.1 p(2)", 0.05714, emlMannWhitneyU.p, tolerance
@emlTestAssertEqualStr: "MWU-1.1 method", "exact", emlMannWhitneyU.method$

# --- 1.2: Small, with ties (n1=4, n2=4) ---
@emlMannWhitneyU: {1, 2, 3, 4}, {2, 3, 5, 6}, 2
@emlTestAssertEqualStr: "MWU-1.2 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-1.2 U1", 4.0, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-1.2 p(2)", 0.34286, emlMannWhitneyU.p, tolerance

# --- 1.3: Complete separation x > y (one-tailed) ---
@emlMannWhitneyU: {10, 20, 30}, {1, 2, 3}, 1
@emlTestAssertEqualStr: "MWU-1.3 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-1.3 U1", 9.0, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-1.3 p(1)", 0.05000, emlMannWhitneyU.p, tolerance

# --- 1.4: Complete separation x < y (one-tailed) ---
@emlMannWhitneyU: {1, 2, 3}, {10, 20, 30}, 1
@emlTestAssertEqualStr: "MWU-1.4 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-1.4 U1", 0.0, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-1.4 p(1)", 0.05000, emlMannWhitneyU.p, tolerance

# --- 1.5: Identical groups ---
@emlMannWhitneyU: {1, 2, 3, 4, 5}, {1, 2, 3, 4, 5}, 2
@emlTestAssertEqualStr: "MWU-1.5 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-1.5 U1", 12.5, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-1.5 p(2)", 1.0, emlMannWhitneyU.p, tolerance

# --- 1.6: Single element in group 1 ---
@emlMannWhitneyU: {5}, {1, 2, 3, 4}, 1
@emlTestAssertEqualStr: "MWU-1.6 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-1.6 U1", 4.0, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-1.6 p(1)", 0.20000, emlMannWhitneyU.p, tolerance

# --- 1.7: Boundary n1+n2=20 ---
@emlMannWhitneyU: {1,2,3,4,5,6,7,8,9,10}, {6,7,8,9,10,11,12,13,14,15}, 2
@emlTestAssertEqualStr: "MWU-1.7 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-1.7 U1", 12.5, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-1.7 p(2)", 0.00288, emlMannWhitneyU.p, tolerance
@emlTestAssertEqualStr: "MWU-1.7 method", "exact", emlMannWhitneyU.method$


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: @emlMannWhitneyU — Approximation path
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlMannWhitneyU — Exact path (boundary cases, n < 50)"

# --- 2.1: n1+n2=21, ties (was approximation path at threshold 20) ---
@emlMannWhitneyU: {1,2,3,4,5,6,7,8,9,10,11}, {6,7,8,9,10,11,12,13,14,15}, 2
@emlTestAssertEqualStr: "MWU-2.1 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-2.1 U1", 18.0, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-2.1 p(2)", 0.00795, emlMannWhitneyU.p, tolerance
@emlTestAssertEqualStr: "MWU-2.1 method", "exact", emlMannWhitneyU.method$

# --- 2.2: Large interleaved, no ties ---
@emlMannWhitneyU: {2,4,6,8,10,12,14,16,18,20,22,24,26,28,30}, {1,3,5,7,9,11,13,15,17,19,21,23,25,27,29}, 2
@emlTestAssertEqualStr: "MWU-2.2 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-2.2 U1", 120.0, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-2.2 p(2)", 0.77484, emlMannWhitneyU.p, tolerance

# --- 2.3: Large separated, ties ---
@emlMannWhitneyU: {10,12,14,16,18,20,22,24,26,28,30,32,34,36,38}, {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}, 2
@emlTestAssertEqualStr: "MWU-2.3 no error", "", emlMannWhitneyU.error$
@emlTestAssertEqualNum: "MWU-2.3 U1", 214.5, emlMannWhitneyU.u1, tightTolerance
@emlTestAssertEqualNum: "MWU-2.3 p(2)", 0.00003, emlMannWhitneyU.p, 0.00005


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: @emlMannWhitneyU — Validation / edge cases
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlMannWhitneyU — Edge cases"

# --- 3.1: Empty group 1 ---
@emlMannWhitneyU: zero# (0), {1, 2, 3}, 2
@emlTestAssertTrue: "MWU-3.1 error on empty g1", emlMannWhitneyU.error$ <> ""

# --- 3.2: Empty group 2 ---
@emlMannWhitneyU: {1, 2, 3}, zero# (0), 2
@emlTestAssertTrue: "MWU-3.2 error on empty g2", emlMannWhitneyU.error$ <> ""

# --- 3.3: Invalid tails ---
@emlMannWhitneyU: {1, 2, 3}, {4, 5, 6}, 3
@emlTestAssertTrue: "MWU-3.3 error on bad tails", emlMannWhitneyU.error$ <> ""


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: @emlWilcoxonSignedRank — Exact path
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlWilcoxonSignedRank — Exact path"

# --- 4.1: All positive diffs, no ties (n=5) ---
@emlWilcoxonSignedRank: {10, 20, 30, 40, 50}, {1, 2, 3, 4, 5}, 2
@emlTestAssertEqualStr: "WSR-4.1 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.1 T+", 15.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.1 T-", 0.0, emlWilcoxonSignedRank.tMinus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.1 p(2)", 0.0625, emlWilcoxonSignedRank.p, tightTolerance
@emlTestAssertEqualNum: "WSR-4.1 nNonzero", 5, emlWilcoxonSignedRank.nNonzero, 0
@emlTestAssertEqualNum: "WSR-4.1 nZero", 0, emlWilcoxonSignedRank.nZero, 0
@emlTestAssertEqualStr: "WSR-4.1 method", "exact", emlWilcoxonSignedRank.method$

# --- 4.2: All positive diffs, tied abs diffs (n=5) ---
@emlWilcoxonSignedRank: {8, 6, 3, 12, 5}, {5, 3, 1, 7, 4}, 2
@emlTestAssertEqualStr: "WSR-4.2 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.2 T+", 15.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.2 p(2)", 0.0625, emlWilcoxonSignedRank.p, tightTolerance

# --- 4.3: Zero diffs excluded (n_nonzero=2) ---
@emlWilcoxonSignedRank: {5, 3, 7, 4, 6}, {5, 1, 7, 2, 6}, 2
@emlTestAssertEqualStr: "WSR-4.3 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.3 T+", 3.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.3 p(2)", 0.5, emlWilcoxonSignedRank.p, tightTolerance
@emlTestAssertEqualNum: "WSR-4.3 nNonzero", 2, emlWilcoxonSignedRank.nNonzero, 0
@emlTestAssertEqualNum: "WSR-4.3 nZero", 3, emlWilcoxonSignedRank.nZero, 0

# --- 4.4: All negative diffs ---
@emlWilcoxonSignedRank: {1, 2, 3, 4, 5}, {10, 20, 30, 40, 50}, 2
@emlTestAssertEqualStr: "WSR-4.4 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.4 T+", 0.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.4 T-", 15.0, emlWilcoxonSignedRank.tMinus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.4 p(2)", 0.0625, emlWilcoxonSignedRank.p, tightTolerance

# --- 4.5: Single pair ---
@emlWilcoxonSignedRank: {10}, {5}, 2
@emlTestAssertEqualStr: "WSR-4.5 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.5 T+", 1.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.5 p(2)", 1.0, emlWilcoxonSignedRank.p, tightTolerance

# --- 4.6: Opposite diffs, tied ranks ---
@emlWilcoxonSignedRank: {10, 5}, {5, 10}, 2
@emlTestAssertEqualStr: "WSR-4.6 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.6 T+", 1.5, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.6 T-", 1.5, emlWilcoxonSignedRank.tMinus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.6 p(2)", 1.0, emlWilcoxonSignedRank.p, tightTolerance

# --- 4.7: Boundary n=15, one-tailed ---
@emlWilcoxonSignedRank: {16,17,18,19,20,21,22,23,24,25,26,27,28,29,30}, {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}, 1
@emlTestAssertEqualStr: "WSR-4.7 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.7 T+", 120.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.7 p(1)", 0.0000305176, emlWilcoxonSignedRank.p, 1e-8
@emlTestAssertEqualStr: "WSR-4.7 method", "exact", emlWilcoxonSignedRank.method$

# --- 4.8: Boundary n=15, ties, two-tailed ---
@emlWilcoxonSignedRank: {10,12,8,15,6,20,3,14,9,11,7,16,5,18,13}, {8,10,9,12,7,15,5,10,11,8,9,12,7,14,10}, 2
@emlTestAssertEqualStr: "WSR-4.8 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-4.8 T+", 95.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.8 T-", 25.0, emlWilcoxonSignedRank.tMinus, tightTolerance
@emlTestAssertEqualNum: "WSR-4.8 p(2)", 0.0479126, emlWilcoxonSignedRank.p, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 5: @emlWilcoxonSignedRank — Approximation path
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlWilcoxonSignedRank — Exact path (boundary cases, n < 50)"

# --- 5.1: n=16, ties (was approximation path at threshold 15) ---
@emlWilcoxonSignedRank: {10,12,8,15,6,20,3,14,9,11,7,16,5,18,13,22}, {8,10,9,12,7,15,5,10,11,8,9,12,7,14,10,17}, 2
@emlTestAssertEqualStr: "WSR-5.1 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-5.1 T+", 111.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-5.1 p(2)", 0.02496, emlWilcoxonSignedRank.p, tolerance
@emlTestAssertEqualStr: "WSR-5.1 method", "exact", emlWilcoxonSignedRank.method$

# --- 5.2: n=20, ties ---
@emlWilcoxonSignedRank: {20,22,18,25,16,30,13,24,19,21,17,26,15,28,23,31,14,27,20,29}, {15,18,19,20,17,22,16,18,21,16,19,20,18,22,17,25,16,21,22,23}, 2
@emlTestAssertEqualStr: "WSR-5.2 no error", "", emlWilcoxonSignedRank.error$
@emlTestAssertEqualNum: "WSR-5.2 T+", 174.0, emlWilcoxonSignedRank.tPlus, tightTolerance
@emlTestAssertEqualNum: "WSR-5.2 p(2)", 0.00831, emlWilcoxonSignedRank.p, tolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 6: @emlWilcoxonSignedRank — Edge cases
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlWilcoxonSignedRank — Edge cases"

# --- 6.1: All diffs zero ---
@emlWilcoxonSignedRank: {5, 5, 5}, {5, 5, 5}, 2
@emlTestAssertTrue: "WSR-6.1 error on all-zero", emlWilcoxonSignedRank.error$ <> ""

# --- 6.2: Unequal lengths ---
@emlWilcoxonSignedRank: {1, 2}, {1, 2, 3}, 2
@emlTestAssertTrue: "WSR-6.2 error on unequal", emlWilcoxonSignedRank.error$ <> ""

# --- 6.3: Single pair, zero diff ---
@emlWilcoxonSignedRank: {5}, {5}, 2
@emlTestAssertTrue: "WSR-6.3 error on single-zero", emlWilcoxonSignedRank.error$ <> ""

# --- 6.4: Invalid tails ---
@emlWilcoxonSignedRank: {10, 20}, {1, 2}, 3
@emlTestAssertTrue: "WSR-6.4 error on bad tails", emlWilcoxonSignedRank.error$ <> ""


# ══════════════════════════════════════════════════════════════════════════════
@emlTestSummary
