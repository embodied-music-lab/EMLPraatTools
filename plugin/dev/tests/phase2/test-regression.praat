# ============================================================================
# EML Stats : Regression Test Suite
# ============================================================================
# Module: test-regression.praat
# Version: 1.0
# Date: 10 May 2026
#
# Tests @emlLinearRegression against scipy.stats.linregress reference values.
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-core-descriptive.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

# ============================================================================
# TEST 1: Strong negative relationship (n=10)
# scipy: slope=-0.07333333 intercept=1.76666667 r=-0.97055007
#         R²=0.94196745 F=129.853659 pF=0.0000031760
#         SE_resid=0.11690452 SE_slope=0.00643538 SE_int=0.07986099
# ============================================================================

@emlTestSection: "Strong negative (n=10)"

.x1# = { 2, 4, 6, 8, 10, 12, 14, 16, 18, 20 }
.y1# = { 1.8, 1.5, 1.3, 1.1, 0.9, 0.7, 0.8, 0.6, 0.5, 0.4 }

@emlLinearRegression: .x1#, .y1#

@emlTestAssertEqualNum: "slope", emlLinearRegression.slope, -0.07333333, 0.00001
@emlTestAssertEqualNum: "intercept", emlLinearRegression.intercept, 1.76666667, 0.00001
@emlTestAssertEqualNum: "r", emlLinearRegression.r, -0.97055007, 0.00001
@emlTestAssertEqualNum: "R-squared", emlLinearRegression.rSquared, 0.94196745, 0.00001
@emlTestAssertEqualNum: "F-stat", emlLinearRegression.fStat, 129.853659, 0.01
@emlTestAssertEqualNum: "p(F)", emlLinearRegression.pF, 0.0000031760, 0.0000001
@emlTestAssertEqualNum: "SE residual", emlLinearRegression.seResidual, 0.11690452, 0.00001
@emlTestAssertEqualNum: "SE slope", emlLinearRegression.seSlope, 0.00643538, 0.00001
@emlTestAssertEqualNum: "SE intercept", emlLinearRegression.seIntercept, 0.07986099, 0.00001
@emlTestAssertEqualNum: "t slope", emlLinearRegression.tSlope, -11.3952, 0.001
@emlTestAssertEqualNum: "p slope", emlLinearRegression.pSlope, 0.0000031760, 0.0000001
@emlTestAssertEqualNum: "n", emlLinearRegression.n, 10, 0

# ============================================================================
# TEST 2: Weak positive relationship (n=10)
# scipy: slope=0.10848485 intercept=1.95333333 r=0.77298200
#         R²=0.59750117 F=11.875834 pF=0.0087444455
#         SE_resid=0.28593282 SE_slope=0.03148017 SE_int=0.19532930
# ============================================================================

@emlTestSection: "Weak positive (n=10)"

.x2# = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
.y2# = { 2.1, 1.8, 2.5, 2.2, 2.9, 2.4, 3.1, 2.7, 3.0, 2.8 }

@emlLinearRegression: .x2#, .y2#

@emlTestAssertEqualNum: "slope", emlLinearRegression.slope, 0.10848485, 0.00001
@emlTestAssertEqualNum: "intercept", emlLinearRegression.intercept, 1.95333333, 0.00001
@emlTestAssertEqualNum: "r", emlLinearRegression.r, 0.77298200, 0.00001
@emlTestAssertEqualNum: "R-squared", emlLinearRegression.rSquared, 0.59750117, 0.00001
@emlTestAssertEqualNum: "F-stat", emlLinearRegression.fStat, 11.875834, 0.001
@emlTestAssertEqualNum: "p(F)", emlLinearRegression.pF, 0.0087444455, 0.0001
@emlTestAssertEqualNum: "SE residual", emlLinearRegression.seResidual, 0.28593282, 0.00001
@emlTestAssertEqualNum: "SE slope", emlLinearRegression.seSlope, 0.03148017, 0.00001
@emlTestAssertEqualNum: "p slope", emlLinearRegression.pSlope, 0.0087444455, 0.0001

# ============================================================================
# TEST 3: Non-significant (n=8)
# scipy: slope=-0.00476190 intercept=5.02142857 r=-0.05832118
#         R²=0.00340136 F=0.020478 pF=0.8908954905
#         SE_resid=0.21565699 SE_slope=0.03327660 SE_int=0.16803857
# ============================================================================

@emlTestSection: "Non-significant (n=8)"

.x3# = { 1, 2, 3, 4, 5, 6, 7, 8 }
.y3# = { 5.0, 4.8, 5.2, 5.1, 4.9, 5.0, 5.3, 4.7 }

@emlLinearRegression: .x3#, .y3#

@emlTestAssertEqualNum: "slope", emlLinearRegression.slope, -0.00476190, 0.00001
@emlTestAssertEqualNum: "intercept", emlLinearRegression.intercept, 5.02142857, 0.00001
@emlTestAssertEqualNum: "r", emlLinearRegression.r, -0.05832118, 0.00001
@emlTestAssertEqualNum: "R-squared", emlLinearRegression.rSquared, 0.00340136, 0.00001
@emlTestAssertEqualNum: "F-stat", emlLinearRegression.fStat, 0.020478, 0.001
@emlTestAssertEqualNum: "p(F)", emlLinearRegression.pF, 0.8908954905, 0.001
@emlTestAssertEqualNum: "SE residual", emlLinearRegression.seResidual, 0.21565699, 0.00001
@emlTestAssertEqualNum: "p slope", emlLinearRegression.pSlope, 0.8908954905, 0.001

# ============================================================================
# TEST 4: Edge cases
# ============================================================================

@emlTestSection: "Edge cases"

# n=3 (minimum)
.x4# = { 1, 2, 3 }
.y4# = { 10, 20, 30 }
@emlLinearRegression: .x4#, .y4#
@emlTestAssertEqualNum: "n=3 slope", emlLinearRegression.slope, 10, 0.001
@emlTestAssertEqualNum: "n=3 intercept", emlLinearRegression.intercept, 0, 0.001
@emlTestAssertEqualNum: "n=3 R-squared", emlLinearRegression.rSquared, 1.0, 0.001
@emlTestAssertEqualStr: "n=3 no error", emlLinearRegression.error$, ""

# n=2 (too few)
.x5# = { 1, 2 }
.y5# = { 1, 2 }
@emlLinearRegression: .x5#, .y5#
@emlTestAssertTrue: "n=2 returns error",
... emlLinearRegression.error$ <> ""

# Unequal lengths
.x6# = { 1, 2, 3 }
.y6# = { 1, 2 }
@emlLinearRegression: .x6#, .y6#
@emlTestAssertTrue: "unequal length returns error",
... emlLinearRegression.error$ <> ""

# Zero variance predictor
.x7# = { 5, 5, 5, 5 }
.y7# = { 1, 2, 3, 4 }
@emlLinearRegression: .x7#, .y7#
@emlTestAssertTrue: "zero-var predictor returns error",
... emlLinearRegression.error$ <> ""

# ============================================================================

@emlTestSummary
