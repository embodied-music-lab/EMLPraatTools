# ============================================================================
# EML Stats : Test Suite — Inferential Statistics (Batch 1)
# ============================================================================
# Tests: @emlTTest, @emlTTestPaired, @emlCohenD
# Version: 1.1
# Date: 2 August 2026 (original 26 February 2026)
#
# Uses shared test helpers (eml-test-helpers.praat).
#
# Every numeric literal below is externally verified by the committed
# companion artifact verify-inferential-batch1.R (same directory), which
# asserts each literal against R's own t.test / var / sd and exits non-zero
# on disagreement. Regenerate/re-check with:
#     Rscript verify-inferential-batch1.R
# Do not hand-edit the literals.
#
# R verification commands (for independent replication):
#
#   # Welch t-test
#   t.test(c(10,12,14,16,18), c(8,9,10,11,12))
#   # → t = 2.5298221281, df = 5.8823529412, p = 0.0454646190
#   # Student t-test
#   t.test(c(10,12,14,16,18), c(8,9,10,11,12), var.equal=TRUE)
#   # → t = 2.5298221281, df = 8, p = 0.0352652035
#   # Paired t-test
#   t.test(c(10,12,14,16,18), c(8,9,10,11,12), paired=TRUE)
#   # → t = 5.6568542495, df = 4, p = 0.0048126783
#   # Cohen's d (effsize package)
#   library(effsize)
#   cohen.d(c(10,12,14,16,18), c(8,9,10,11,12), pooled=TRUE, hedges.correction=TRUE)
#
# CHANGELOG
# 1.1 (2 Aug 2026) — Corrected six mis-transcribed p-value literals and
#     replaced looseTolerance with tightTolerance throughout.
#
#     The six literals were wrong by 6.7e-5 to 1.5e-3:
#         Welch p two-tailed    0.047    → 0.0454646190
#         Welch p one-tailed    0.0236   → 0.0227323095
#         Student p two-tailed  0.0355   → 0.0352652035
#         Student p one-tailed  0.0177   → 0.0176326017
#         Paired p two-tailed   0.00486  → 0.0048126783
#         Paired p one-tailed   0.00243  → 0.0024063392
#     Every one of them PASSED under the old looseTolerance = 0.01, which
#     was 6x to 150x the transcription error. The suite was green and the
#     literals were wrong: the assertion could not have caught a real
#     regression of that size either. The library itself was correct —
#     @emlTTest and @emlTTestPaired agree with R to 12 decimal places on
#     all four data sets. The defect was in the test, not the code.
#
#     The likely origin is the inline R crib at Test 1.1, which read
#     "df = 5.6, p = 0.04712". Both figures were wrong (true 5.8823529412
#     and 0.0454646190) and 0.047 was evidently rounded from the wrong p.
#     All three cribs (header, Test 1.1, Test 2.1, Test 3.1) are corrected.
#
#     All literals are now written to 10 decimal places and checked at
#     tightTolerance = 1e-9 — three orders of magnitude tighter than the
#     rounding of the literal itself, so a wrong literal can no longer
#     hide inside the tolerance. looseTolerance is removed (dead after
#     this change; Rule 35).
# 1.0 (26 Feb 2026) — Initial.
# ============================================================================

include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

# ============================================================================
# Shared test data
# ============================================================================

# Group 1: {10, 12, 14, 16, 18}  mean=14, sd=3.162278
# Group 2: {8, 9, 10, 11, 12}    mean=10, sd=1.581139
# Mean diff = 4

tolerance = 0.001
tightTolerance = 0.000000001


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: @emlTTest — Welch (default)
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTTest — Welch (default)"

# --- Test 1.1: Basic Welch two-tailed ---
# R: t.test(c(10,12,14,16,18), c(8,9,10,11,12))
#    t = 2.5298221281, df = 5.8823529412, p = 0.0454646190
.g1# = {10, 12, 14, 16, 18}
.g2# = {8, 9, 10, 11, 12}
@emlTTest: .g1#, .g2#, 2, 0
@emlTestAssertEqualStr: "Welch method label", "Welch", emlTTest.method$
@emlTestAssertEqualNum: "Welch t statistic", 2.5298221281, emlTTest.t, tightTolerance
@emlTestAssertEqualNum: "Welch df (fractional)", 5.8823529412, emlTTest.df, tightTolerance
@emlTestAssertEqualNum: "Welch p two-tailed", 0.0454646190, emlTTest.p, tightTolerance
@emlTestAssertEqualNum: "Welch mean1", 14, emlTTest.mean1, tolerance
@emlTestAssertEqualNum: "Welch mean2", 10, emlTTest.mean2, tolerance
@emlTestAssertEqualNum: "Welch meanDiff", 4, emlTTest.meanDiff, tolerance
@emlTestAssertEqualNum: "Welch n1", 5, emlTTest.n1, 0
@emlTestAssertEqualNum: "Welch n2", 5, emlTTest.n2, 0

# --- Test 1.2: Welch one-tailed ---
# One-tailed p should be half of two-tailed
@emlTTest: .g1#, .g2#, 1, 0
@emlTestAssertEqualNum: "Welch p one-tailed", 0.0227323095, emlTTest.p, tightTolerance

# --- Test 1.3: Equal means (both constant — zero variance) ---
.eq1# = {10, 10, 10, 10, 10}
.eq2# = {10, 10, 10, 10, 10}
@emlTTest: .eq1#, .eq2#, 2, 0
@emlTestAssertTrue: "Equal means error (zero var)", emlTTest.error$ <> ""
@emlTestAssertUndefined: "Equal means t undefined", emlTTest.t

# --- Test 1.4: One group constant, other varies ---
.const# = {5, 5, 5, 5, 5}
.vary# = {3, 4, 5, 6, 7}
@emlTTest: .const#, .vary#, 2, 0
@emlTestAssertEqualNum: "One constant group t = 0", 0, emlTTest.t, tolerance
@emlTestAssertTrue: "One constant group no error", emlTTest.error$ = ""

# --- Test 1.5: Input validation — too few observations ---
.tiny# = {5}
@emlTTest: .tiny#, .g2#, 2, 0
@emlTestAssertTrue: "n1 < 2 gives error", emlTTest.error$ <> ""
@emlTestAssertUndefined: "n1 < 2 t is undefined", emlTTest.t

# --- Test 1.6: Input validation — invalid tails ---
@emlTTest: .g1#, .g2#, 3, 0
@emlTestAssertTrue: "tails=3 gives error", emlTTest.error$ <> ""

# --- Test 1.7: Negative t when mean1 < mean2 ---
@emlTTest: .g2#, .g1#, 2, 0
@emlTestAssertTrue: "Reversed groups negative t", emlTTest.t < 0
@emlTestAssertEqualNum: "Reversed groups same |t|", 2.5298221281, abs (emlTTest.t), tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: @emlTTest — Student (pooled)
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTTest — Student (pooled)"

# --- Test 2.1: Basic Student two-tailed ---
# R: t.test(c(10,12,14,16,18), c(8,9,10,11,12), var.equal=TRUE)
#    t = 2.5298221281, df = 8, p = 0.0352652035
.g1# = {10, 12, 14, 16, 18}
.g2# = {8, 9, 10, 11, 12}
@emlTTest: .g1#, .g2#, 2, 1
@emlTestAssertEqualStr: "Student method label", "Student", emlTTest.method$
@emlTestAssertEqualNum: "Student t statistic", 2.5298221281, emlTTest.t, tightTolerance
@emlTestAssertEqualNum: "Student df (integer)", 8, emlTTest.df, tolerance
@emlTestAssertEqualNum: "Student p two-tailed", 0.0352652035, emlTTest.p, tightTolerance

# --- Test 2.2: Student one-tailed ---
@emlTTest: .g1#, .g2#, 1, 1
@emlTestAssertEqualNum: "Student p one-tailed", 0.0176326017, emlTTest.p, tightTolerance

# --- Test 2.3: Equal variances scenario ---
# Groups with similar variance — Welch and Student should agree closely
.a# = {20, 22, 24, 26, 28}
.b# = {14, 16, 18, 20, 22}
@emlTTest: .a#, .b#, 2, 0
.welchP = emlTTest.p
@emlTTest: .a#, .b#, 2, 1
.studentP = emlTTest.p
.pDiff = abs (.welchP - .studentP)
@emlTestAssertTrue: "Equal var: Welch ~ Student p", .pDiff < 0.01


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: @emlTTestPaired
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlTTestPaired"

# --- Test 3.1: Basic paired two-tailed ---
# R: t.test(c(10,12,14,16,18), c(8,9,10,11,12), paired=TRUE)
#    t = 5.6568542495, df = 4, p = 0.0048126783
# Diffs: {2, 3, 4, 5, 6}, mean=4, sd=1.5811, se=0.7071
.g1# = {10, 12, 14, 16, 18}
.g2# = {8, 9, 10, 11, 12}
@emlTTestPaired: .g1#, .g2#, 2
@emlTestAssertEqualNum: "Paired t statistic", 5.6568542495, emlTTestPaired.t, tightTolerance
@emlTestAssertEqualNum: "Paired df", 4, emlTTestPaired.df, tolerance
@emlTestAssertEqualNum: "Paired p two-tailed", 0.0048126783, emlTTestPaired.p, tightTolerance
@emlTestAssertEqualNum: "Paired meanDiff", 4, emlTTestPaired.meanDiff, tolerance
@emlTestAssertEqualNum: "Paired sdDiff", 1.5811388301, emlTTestPaired.sdDiff, tightTolerance
@emlTestAssertEqualNum: "Paired n", 5, emlTTestPaired.n, 0

# --- Test 3.2: Paired one-tailed ---
@emlTTestPaired: .g1#, .g2#, 1
@emlTestAssertEqualNum: "Paired p one-tailed", 0.0024063392, emlTTestPaired.p, tightTolerance

# --- Test 3.3: No difference ---
.same1# = {10, 20, 30, 40, 50}
.same2# = {10, 20, 30, 40, 50}
@emlTTestPaired: .same1#, .same2#, 2
@emlTestAssertTrue: "No diff: error (zero var)", emlTTestPaired.error$ <> ""

# --- Test 3.4: Constant difference —
# Diffs: {5, 5, 5, 5, 5}, sd=0
.c1# = {10, 20, 30, 40, 50}
.c2# = {5, 15, 25, 35, 45}
@emlTTestPaired: .c1#, .c2#, 2
@emlTestAssertTrue: "Constant diff: error (zero var)", emlTTestPaired.error$ <> ""

# --- Test 3.5: Unequal lengths ---
.short# = {10, 12, 14}
.long# = {8, 9, 10, 11, 12}
@emlTTestPaired: .short#, .long#, 2
@emlTestAssertTrue: "Unequal length: error", emlTTestPaired.error$ <> ""
@emlTestAssertUndefined: "Unequal length: t undefined", emlTTestPaired.t

# --- Test 3.6: Negative t when v1 < v2 ---
@emlTTestPaired: .g2#, .g1#, 2
@emlTestAssertTrue: "Reversed paired: negative t", emlTTestPaired.t < 0
@emlTestAssertEqualNum: "Reversed paired: same |t|", 5.6568542495, abs (emlTTestPaired.t), tightTolerance

# --- Test 3.7: Larger sample ---
# 10 pairs with known values
.pre# = {85, 90, 78, 92, 88, 76, 95, 82, 91, 87}
.post# = {88, 93, 82, 94, 91, 80, 97, 86, 93, 90}
# Diffs: {-3,-3,-4,-2,-3,-4,-2,-4,-2,-3}, mean=-3, sd=0.8165
@emlTTestPaired: .pre#, .post#, 2
@emlTestAssertEqualNum: "Larger paired meanDiff", -3, emlTTestPaired.meanDiff, tolerance
@emlTestAssertEqualNum: "Larger paired n", 10, emlTTestPaired.n, 0
@emlTestAssertTrue: "Larger paired significant", emlTTestPaired.p < 0.001


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: @emlCohenD
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlCohenD"

# --- Test 4.1: Basic Cohen's d ---
# pooled_sd = sqrt(((4*10 + 4*2.5) / 8)) = sqrt(6.25) = 2.5
# d = 4 / 2.5 = 1.6
.g1# = {10, 12, 14, 16, 18}
.g2# = {8, 9, 10, 11, 12}
@emlCohenD: .g1#, .g2#
@emlTestAssertEqualNum: "Cohen d", 1.6, emlCohenD.d, tolerance
@emlTestAssertEqualNum: "Pooled SD", 2.5, emlCohenD.pooledSD, tolerance
@emlTestAssertEqualNum: "Mean1", 14, emlCohenD.mean1, tolerance
@emlTestAssertEqualNum: "Mean2", 10, emlCohenD.mean2, tolerance
@emlTestAssertTrue: "No error", emlCohenD.error$ = ""

# --- Test 4.2: Hedges' g correction ---
# df = 8, J = 1 - 3/(4*8 - 1) = 1 - 3/31 = 0.90323
# g = 1.6 * 0.90323 = 1.4452
@emlTestAssertEqualNum: "Hedges g correction factor", 0.9032258065, emlCohenD.correctionFactor, tightTolerance
@emlTestAssertEqualNum: "Hedges g", 1.4451612903, emlCohenD.g, tightTolerance

# --- Test 4.3: g < d always (for finite samples) ---
@emlTestAssertTrue: "g < d", emlCohenD.g < emlCohenD.d

# --- Test 4.4: Negative d when mean1 < mean2 ---
@emlCohenD: .g2#, .g1#
@emlTestAssertEqualNum: "Reversed d = -1.6", -1.6, emlCohenD.d, tolerance

# --- Test 4.5: Zero effect size ---
.z1# = {10, 12, 14, 16, 18}
.z2# = {10, 12, 14, 16, 18}
@emlCohenD: .z1#, .z2#
@emlTestAssertEqualNum: "Zero effect d = 0", 0, emlCohenD.d, tolerance
@emlTestAssertEqualNum: "Zero effect g = 0", 0, emlCohenD.g, tolerance

# --- Test 4.6: Large sample correction factor approaches 1 ---
.big1# = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
    ... 21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
    ... 41,42,43,44,45,46,47,48,49,50}
.big2# = {2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,
    ... 22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
    ... 42,43,44,45,46,47,48,49,50,51}
@emlCohenD: .big1#, .big2#
@emlTestAssertTrue: "Large n: J close to 1", emlCohenD.correctionFactor > 0.99

# --- Test 4.7: Input validation ---
.tiny# = {5}
@emlCohenD: .tiny#, .g2#
@emlTestAssertTrue: "n1 < 2 gives error", emlCohenD.error$ <> ""
@emlTestAssertUndefined: "n1 < 2 d is undefined", emlCohenD.d
@emlTestAssertUndefined: "n1 < 2 g is undefined", emlCohenD.g

# --- Test 4.8: Zero variance in both groups ---
.flat1# = {5, 5, 5, 5, 5}
.flat2# = {3, 3, 3, 3, 3}
@emlCohenD: .flat1#, .flat2#
@emlTestAssertTrue: "Zero pooled SD: error", emlCohenD.error$ <> ""


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
