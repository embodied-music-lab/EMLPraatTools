# ============================================================================
# EML Stats : Test Suite — Inferential Statistics (Batch 2)
# ============================================================================
# Tests: @emlPearsonCorrelation, @emlSpearmanCorrelation
# Date: 26 February 2026
#
# Uses shared test helpers (eml-test-helpers.praat).
# Reference values computed via scipy.stats (26 Feb 2026) and
# independently verified via R (verify-inferential-batch2.R).
#
# Include order: utilities (for @emlRankVector) → inferential → test helpers
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.001
looseTolerance = 0.01


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: @emlPearsonCorrelation
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlPearsonCorrelation"

# --- Test 1.1: Moderate positive ---
# scipy: r=0.774597, t=2.121320, df=3, p(2)=0.124027
.xa# = {1, 2, 3, 4, 5}
.ya# = {2, 4, 5, 4, 5}
@emlPearsonCorrelation: .xa#, .ya#, 2
@emlTestAssertEqualNum: "Set A r", 0.7746, emlPearsonCorrelation.r, looseTolerance
@emlTestAssertEqualNum: "Set A t", 2.1213, emlPearsonCorrelation.t, looseTolerance
@emlTestAssertEqualNum: "Set A df", 3, emlPearsonCorrelation.df, tolerance
@emlTestAssertEqualNum: "Set A p (2-tail)", 0.1240, emlPearsonCorrelation.p, looseTolerance
@emlTestAssertEqualNum: "Set A n", 5, emlPearsonCorrelation.n, 0
@emlTestAssertTrue: "Set A no error", emlPearsonCorrelation.error$ = ""

# --- Test 1.2: One-tailed ---
# scipy: p(1)=0.062014
@emlPearsonCorrelation: .xa#, .ya#, 1
@emlTestAssertEqualNum: "Set A p (1-tail)", 0.0620, emlPearsonCorrelation.p, looseTolerance

# --- Test 1.3: Perfect positive ---
# scipy: r=1.0, p=0.0
.xb# = {1, 2, 3, 4, 5}
.yb# = {10, 20, 30, 40, 50}
@emlPearsonCorrelation: .xb#, .yb#, 2
@emlTestAssertEqualNum: "Perfect positive r", 1.0, emlPearsonCorrelation.r, tolerance
@emlTestAssertEqualNum: "Perfect positive p = 0", 0, emlPearsonCorrelation.p, tolerance
@emlTestAssertUndefined: "Perfect positive t undefined", emlPearsonCorrelation.t

# --- Test 1.4: Perfect negative ---
# scipy: r=-1.0, p=0.0
.xc# = {1, 2, 3, 4, 5}
.yc# = {50, 40, 30, 20, 10}
@emlPearsonCorrelation: .xc#, .yc#, 2
@emlTestAssertEqualNum: "Perfect negative r", -1.0, emlPearsonCorrelation.r, tolerance
@emlTestAssertEqualNum: "Perfect negative p = 0", 0, emlPearsonCorrelation.p, tolerance

# --- Test 1.5: Weak correlation ---
# scipy: r=0.353553, t=0.654654, p(2)=0.559404
.xd# = {1, 2, 3, 4, 5}
.yd# = {3, 1, 4, 1, 5}
@emlPearsonCorrelation: .xd#, .yd#, 2
@emlTestAssertEqualNum: "Weak r", 0.3536, emlPearsonCorrelation.r, looseTolerance
@emlTestAssertEqualNum: "Weak t", 0.6547, emlPearsonCorrelation.t, looseTolerance
@emlTestAssertEqualNum: "Weak p (2-tail)", 0.5594, emlPearsonCorrelation.p, looseTolerance

# --- Test 1.6: Larger sample ---
# scipy: r=0.964094, t=10.268308, df=8, p(2)=0.000007
.xe# = {10, 20, 20, 30, 40, 50, 50, 60, 70, 80}
.ye# = {15, 25, 20, 35, 30, 55, 50, 65, 60, 85}
@emlPearsonCorrelation: .xe#, .ye#, 2
@emlTestAssertEqualNum: "Large n r", 0.9641, emlPearsonCorrelation.r, looseTolerance
@emlTestAssertEqualNum: "Large n t", 10.268, emlPearsonCorrelation.t, looseTolerance
@emlTestAssertEqualNum: "Large n df", 8, emlPearsonCorrelation.df, tolerance
@emlTestAssertTrue: "Large n p < 0.001", emlPearsonCorrelation.p < 0.001

# --- Test 1.7: Unequal lengths ---
.short# = {1, 2, 3}
.long# = {1, 2, 3, 4, 5}
@emlPearsonCorrelation: .short#, .long#, 2
@emlTestAssertTrue: "Unequal length error", emlPearsonCorrelation.error$ <> ""
@emlTestAssertUndefined: "Unequal length r undefined", emlPearsonCorrelation.r

# --- Test 1.8: Too few pairs ---
.two# = {1, 2}
@emlPearsonCorrelation: .two#, .two#, 2
@emlTestAssertTrue: "n < 3 error", emlPearsonCorrelation.error$ <> ""

# --- Test 1.9: Zero variance ---
.const# = {5, 5, 5, 5, 5}
.vary# = {1, 2, 3, 4, 5}
@emlPearsonCorrelation: .const#, .vary#, 2
@emlTestAssertTrue: "Zero variance error", emlPearsonCorrelation.error$ <> ""

# --- Test 1.10: Perfect negative has undefined t ---
.xn# = {1, 2, 3, 4, 5}
.yn# = {5, 4, 3, 2, 1}
@emlPearsonCorrelation: .xn#, .yn#, 2
@emlTestAssertUndefined: "Perfect negative t undefined", emlPearsonCorrelation.t

# --- Test 1.11: Non-perfect negative has negative t ---
# scipy: r=-0.972272, t=-7.201190, p=0.005520
.xnn# = {1, 2, 3, 4, 5}
.ynn# = {5, 5, 3, 2, 1}
@emlPearsonCorrelation: .xnn#, .ynn#, 2
@emlTestAssertTrue: "Non-perfect negative r < 0", emlPearsonCorrelation.r < 0
@emlTestAssertTrue: "Non-perfect negative t < 0", emlPearsonCorrelation.t < 0
@emlTestAssertEqualNum: "Non-perfect negative t", -7.2012, emlPearsonCorrelation.t, looseTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: @emlSpearmanCorrelation
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlSpearmanCorrelation"

# --- Test 2.1: Set A (no ties in x, ties in y) ---
# scipy: rho=0.737865, t=1.893506, df=3, p(2)=0.154619
.xa# = {1, 2, 3, 4, 5}
.ya# = {2, 4, 5, 4, 5}
@emlSpearmanCorrelation: .xa#, .ya#, 2
@emlTestAssertEqualNum: "Set A rho", 0.7379, emlSpearmanCorrelation.rho, looseTolerance
@emlTestAssertEqualNum: "Set A t", 1.8935, emlSpearmanCorrelation.t, looseTolerance
@emlTestAssertEqualNum: "Set A df", 3, emlSpearmanCorrelation.df, tolerance
@emlTestAssertEqualNum: "Set A p (2-tail)", 0.1546, emlSpearmanCorrelation.p, looseTolerance
@emlTestAssertEqualNum: "Set A n", 5, emlSpearmanCorrelation.n, 0
@emlTestAssertTrue: "Set A no error", emlSpearmanCorrelation.error$ = ""

# --- Test 2.2: One-tailed ---
# scipy: p(1)=0.077309
@emlSpearmanCorrelation: .xa#, .ya#, 1
@emlTestAssertEqualNum: "Set A p (1-tail)", 0.0773, emlSpearmanCorrelation.p, looseTolerance

# --- Test 2.3: Perfect monotonic positive ---
# scipy: rho=1.0, p=0.0
.xb# = {1, 2, 3, 4, 5}
.yb# = {10, 20, 30, 40, 50}
@emlSpearmanCorrelation: .xb#, .yb#, 2
@emlTestAssertEqualNum: "Perfect positive rho", 1.0, emlSpearmanCorrelation.rho, tolerance
@emlTestAssertEqualNum: "Perfect positive p = 0", 0, emlSpearmanCorrelation.p, tolerance

# --- Test 2.4: Perfect monotonic negative ---
# scipy: rho=-1.0, p=0.0
.xc# = {1, 2, 3, 4, 5}
.yc# = {50, 40, 30, 20, 10}
@emlSpearmanCorrelation: .xc#, .yc#, 2
@emlTestAssertEqualNum: "Perfect negative rho", -1.0, emlSpearmanCorrelation.rho, tolerance

# --- Test 2.5: Weak correlation ---
# scipy: rho=0.410391, p(2)=0.492536
.xd# = {1, 2, 3, 4, 5}
.yd# = {3, 1, 4, 1, 5}
@emlSpearmanCorrelation: .xd#, .yd#, 2
@emlTestAssertEqualNum: "Weak rho", 0.4104, emlSpearmanCorrelation.rho, looseTolerance
@emlTestAssertEqualNum: "Weak p (2-tail)", 0.4925, emlSpearmanCorrelation.p, looseTolerance

# --- Test 2.6: Larger sample with ties ---
# scipy: rho=0.969530, t=11.194130, df=8, p(2)=0.000004
# Rank verification:
#   ranks(x) = [1, 2.5, 2.5, 4, 5, 6.5, 6.5, 8, 9, 10]
#   ranks(y) = [1, 3, 2, 5, 4, 7, 6, 9, 8, 10]
.xe# = {10, 20, 20, 30, 40, 50, 50, 60, 70, 80}
.ye# = {15, 25, 20, 35, 30, 55, 50, 65, 60, 85}
@emlSpearmanCorrelation: .xe#, .ye#, 2
@emlTestAssertEqualNum: "Ties rho", 0.9695, emlSpearmanCorrelation.rho, looseTolerance
@emlTestAssertEqualNum: "Ties t", 11.194, emlSpearmanCorrelation.t, looseTolerance
@emlTestAssertEqualNum: "Ties df", 8, emlSpearmanCorrelation.df, tolerance
@emlTestAssertTrue: "Ties p < 0.001", emlSpearmanCorrelation.p < 0.001

# --- Test 2.7: Spearman != Pearson when relationship is nonlinear ---
# Monotonic but not linear: ranks stay perfect, Pearson drops
.xm# = {1, 2, 3, 4, 5}
.ym# = {1, 4, 9, 16, 25}
@emlSpearmanCorrelation: .xm#, .ym#, 2
.spearmanRho = emlSpearmanCorrelation.rho
@emlPearsonCorrelation: .xm#, .ym#, 2
.pearsonR = emlPearsonCorrelation.r
@emlTestAssertEqualNum: "Monotonic: Spearman rho = 1.0", 1.0, .spearmanRho, tolerance
@emlTestAssertTrue: "Monotonic: Pearson r < 1.0", .pearsonR < 1.0

# --- Test 2.8: Input validation ---
.short# = {1, 2, 3}
.long# = {1, 2, 3, 4, 5}
@emlSpearmanCorrelation: .short#, .long#, 2
@emlTestAssertTrue: "Unequal length error", emlSpearmanCorrelation.error$ <> ""
@emlTestAssertUndefined: "Unequal length rho undefined", emlSpearmanCorrelation.rho

.two# = {1, 2}
@emlSpearmanCorrelation: .two#, .two#, 2
@emlTestAssertTrue: "n < 3 error", emlSpearmanCorrelation.error$ <> ""


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
