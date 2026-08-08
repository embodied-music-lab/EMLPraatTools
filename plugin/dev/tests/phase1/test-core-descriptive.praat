# ============================================================================
# EML Stats : Core Descriptive Statistics — Validation Suite
# ============================================================================
# Tests: eml-core-descriptive.praat
# Version: 1.1
# Date: 3 August 2026
#
# Validates all procedures against analytically computed expected values.
# Run this script with eml-core-descriptive.praat in the same directory.
#
# License: GPL-3.0-or-later
#
# v1.1: Brought under the TEST RESULT REPORTING CONTRACT (v1.1, declared in
#        dev/tests/eml-test-helpers.praat). The hand-rolled summary printed
#        "SOME TESTS FAILED" and then returned normally, so the process
#        exited 0 whatever the outcome — green by construction for any
#        runner reading exit status. Local counters are now bridged into
#        emlTestInit.* and @emlTestSummary emits the machine-readable
#        sentinel. No assertion call site changed and the human-readable
#        summary is untouched.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

include ../../../stats/eml-core-descriptive.praat

# Shared harness — used only for @emlTestInit / @emlTestSummary (the
# reporting contract). This suite keeps its own assertion helpers.
include ../eml-test-helpers.praat

@emlTestInit

# ============================================================================
# Test infrastructure
# ============================================================================

# Global test counters (no dot prefix = script-level)
testsTotal = 0
testsPassed = 0
testsFailed = 0

# Tolerance constants
tolStat = 0.0001
tolPct = 0.01
tolCI = 0.001

# ----------------------------------------------------------------------------
# @reportPass
# Records a passing test and prints result.
# ----------------------------------------------------------------------------
procedure reportPass: .name$
    testsTotal = testsTotal + 1
    testsPassed = testsPassed + 1
    .prefix$ = "  PASS: "
    appendInfoLine: .prefix$, .name$
endproc

# ----------------------------------------------------------------------------
# @reportFail
# Records a failing test and prints result with expected/actual values.
# ----------------------------------------------------------------------------
procedure reportFail: .name$, .expected$, .actual$
    testsTotal = testsTotal + 1
    testsFailed = testsFailed + 1
    .prefix$ = "  FAIL: "
    appendInfoLine: .prefix$, .name$
    .expLabel$ = "    Expected: "
    appendInfoLine: .expLabel$, .expected$
    .actLabel$ = "    Actual:   "
    appendInfoLine: .actLabel$, .actual$
endproc

# ----------------------------------------------------------------------------
# @assertApprox
# Checks that actual value matches expected within tolerance.
# Handles undefined comparison.
# ----------------------------------------------------------------------------
procedure assertApprox: .name$, .actual, .expected, .tol
    if .expected = undefined
        if .actual = undefined
            @reportPass: .name$
        else
            .exp$ = "undefined"
            .act$ = fixed$ (.actual, 6)
            @reportFail: .name$, .exp$, .act$
        endif
    elsif .actual = undefined
        .exp$ = fixed$ (.expected, 6)
        .act$ = "undefined"
        @reportFail: .name$, .exp$, .act$
    elsif abs (.actual - .expected) <= .tol
        @reportPass: .name$
    else
        .exp$ = fixed$ (.expected, 6)
        .act$ = fixed$ (.actual, 6)
        @reportFail: .name$, .exp$, .act$
    endif
endproc

# ----------------------------------------------------------------------------
# @assertExact
# Checks that actual integer/boolean matches expected exactly.
# ----------------------------------------------------------------------------
procedure assertExact: .name$, .actual, .expected
    if .actual = .expected
        @reportPass: .name$
    else
        .exp$ = string$ (.expected)
        .act$ = string$ (.actual)
        @reportFail: .name$, .exp$, .act$
    endif
endproc

# ----------------------------------------------------------------------------
# @assertUndefined
# Checks that actual value is undefined.
# ----------------------------------------------------------------------------
procedure assertUndefined: .name$, .actual
    if .actual = undefined
        @reportPass: .name$
    else
        .exp$ = "undefined"
        .act$ = fixed$ (.actual, 6)
        @reportFail: .name$, .exp$, .act$
    endif
endproc

# ============================================================================
# Test procedures
# ============================================================================

# --- @test_emlMean --------------------------------------------------------
procedure test_emlMean
    .header$ = "--- @emlMean ---"
    appendInfoLine: .header$
    # Dataset 1: {1,2,3,4,5}
    .d1# = {1, 2, 3, 4, 5}
    @emlMean: .d1#
    @assertApprox: "mean({1,2,3,4,5}) = 3", emlMean.result, 3, tolStat
    # Dataset 4: single element
    .d4# = {5}
    @emlMean: .d4#
    @assertApprox: "mean({5}) = 5", emlMean.result, 5, tolStat
    # Dataset 2: {2,2,3,4,4,4,5,7,9,9}
    .d2# = {2, 2, 3, 4, 4, 4, 5, 7, 9, 9}
    @emlMean: .d2#
    @assertApprox: "mean({2,2,3,4,4,4,5,7,9,9}) = 4.9", emlMean.result, 4.9, tolStat
    appendInfoLine: ""
endproc

# --- @test_emlMedian ------------------------------------------------------
procedure test_emlMedian
    .header$ = "--- @emlMedian ---"
    appendInfoLine: .header$
    # Odd n: {1,2,3,4,5} -> 3
    .d1# = {1, 2, 3, 4, 5}
    @emlMedian: .d1#
    @assertApprox: "median({1,2,3,4,5}) = 3", emlMedian.result, 3, tolStat
    # Even n: {2,2,3,4,4,4,5,7,9,9} -> (4+4)/2 = 4
    .d2# = {2, 2, 3, 4, 4, 4, 5, 7, 9, 9}
    @emlMedian: .d2#
    @assertApprox: "median({2,2,3,4,4,4,5,7,9,9}) = 4", emlMedian.result, 4, tolStat
    # Single element
    .d4# = {5}
    @emlMedian: .d4#
    @assertApprox: "median({5}) = 5", emlMedian.result, 5, tolStat
    # Two elements: {3,7} -> 5
    .d5# = {3, 7}
    @emlMedian: .d5#
    @assertApprox: "median({3,7}) = 5", emlMedian.result, 5, tolStat
    # Skewed: {1,1,1,1,100} -> 1
    .d3# = {1, 1, 1, 1, 100}
    @emlMedian: .d3#
    @assertApprox: "median({1,1,1,1,100}) = 1", emlMedian.result, 1, tolStat
    appendInfoLine: ""
endproc

# --- @test_emlMode --------------------------------------------------------
procedure test_emlMode
    .header$ = "--- @emlMode ---"
    appendInfoLine: .header$
    # Unique mode: {1,2,2,3,3,3,4} -> mode=3, count=3, unique=1
    .d7# = {1, 2, 2, 3, 3, 3, 4}
    @emlMode: .d7#
    @assertApprox: "mode({1,2,2,3,3,3,4}) = 3", emlMode.result, 3, tolStat
    @assertExact: "mode count = 3", emlMode.count, 3
    @assertExact: "mode isUnique = 1", emlMode.isUnique, 1
    # Tied mode: {1,2,2,3,3} -> mode=2 (first), count=2, unique=0
    .d8# = {1, 2, 2, 3, 3}
    @emlMode: .d8#
    @assertApprox: "mode({1,2,2,3,3}) = 2", emlMode.result, 2, tolStat
    @assertExact: "tied mode count = 2", emlMode.count, 2
    @assertExact: "tied mode isUnique = 0", emlMode.isUnique, 0
    # All unique: {1,2,3,4,5} -> first element=1, count=1, unique=0
    .d1# = {1, 2, 3, 4, 5}
    @emlMode: .d1#
    @assertApprox: "mode(all unique) = 1", emlMode.result, 1, tolStat
    @assertExact: "all unique count = 1", emlMode.count, 1
    @assertExact: "all unique isUnique = 0", emlMode.isUnique, 0
    appendInfoLine: ""
endproc

# --- @test_emlPercentile --------------------------------------------------
procedure test_emlPercentile
    .header$ = "--- @emlPercentile ---"
    appendInfoLine: .header$
    # Dataset 9: {15,20,35,40,50}, n=5
    # R type=7: h = (n-1)*p/100 + 1
    .d9# = {15, 20, 35, 40, 50}
    # P25: h = 4*0.25 + 1 = 2 -> sorted[2] = 20
    @emlPercentile: .d9#, 25
    @assertApprox: "P25({15,20,35,40,50}) = 20", emlPercentile.result, 20, tolPct
    # P50: h = 4*0.5 + 1 = 3 -> sorted[3] = 35
    @emlPercentile: .d9#, 50
    @assertApprox: "P50({15,20,35,40,50}) = 35", emlPercentile.result, 35, tolPct
    # P75: h = 4*0.75 + 1 = 4 -> sorted[4] = 40
    @emlPercentile: .d9#, 75
    @assertApprox: "P75({15,20,35,40,50}) = 40", emlPercentile.result, 40, tolPct
    # Interpolation: Dataset 2, P25: h=3.25 -> 3 + 0.25*(4-3) = 3.25
    .d2# = {2, 2, 3, 4, 4, 4, 5, 7, 9, 9}
    @emlPercentile: .d2#, 25
    @assertApprox: "P25 interpolated = 3.25", emlPercentile.result, 3.25, tolPct
    # Edge: p < 0 -> undefined
    @emlPercentile: .d9#, -1
    @assertUndefined: "P(-1) = undefined", emlPercentile.result
    # Edge: p > 100 -> undefined
    @emlPercentile: .d9#, 101
    @assertUndefined: "P(101) = undefined", emlPercentile.result
    # Edge: single element
    .d4# = {5}
    @emlPercentile: .d4#, 50
    @assertApprox: "P50({5}) = 5", emlPercentile.result, 5, tolPct
    # P0 = min, P100 = max
    @emlPercentile: .d9#, 0
    @assertApprox: "P0 = min", emlPercentile.result, 15, tolPct
    @emlPercentile: .d9#, 100
    @assertApprox: "P100 = max", emlPercentile.result, 50, tolPct
    appendInfoLine: ""
endproc

# --- @test_emlQuartiles ---------------------------------------------------
procedure test_emlQuartiles
    .header$ = "--- @emlQuartiles ---"
    appendInfoLine: .header$
    # Dataset 1: Q1=2, Q2=3, Q3=4, IQR=2
    .d1# = {1, 2, 3, 4, 5}
    @emlQuartiles: .d1#
    @assertApprox: "Q1({1..5}) = 2", emlQuartiles.q1, 2, tolPct
    @assertApprox: "Q2({1..5}) = 3", emlQuartiles.q2, 3, tolPct
    @assertApprox: "Q3({1..5}) = 4", emlQuartiles.q3, 4, tolPct
    @assertApprox: "IQR({1..5}) = 2", emlQuartiles.iqr, 2, tolPct
    # Dataset 2: Q1=3.25, Q3=6.5, IQR=3.25
    .d2# = {2, 2, 3, 4, 4, 4, 5, 7, 9, 9}
    @emlQuartiles: .d2#
    @assertApprox: "Q1(d2) = 3.25", emlQuartiles.q1, 3.25, tolPct
    @assertApprox: "Q2(d2) = 4", emlQuartiles.q2, 4, tolPct
    @assertApprox: "Q3(d2) = 6.5", emlQuartiles.q3, 6.5, tolPct
    @assertApprox: "IQR(d2) = 3.25", emlQuartiles.iqr, 3.25, tolPct
    appendInfoLine: ""
endproc

# --- @test_emlVariance ----------------------------------------------------
procedure test_emlVariance
    .header$ = "--- @emlVariance ---"
    appendInfoLine: .header$
    .d1# = {1, 2, 3, 4, 5}
    @emlVariance: .d1#
    @assertApprox: "var({1..5}) = 2.5", emlVariance.result, 2.5, tolStat
    # Single element: undefined
    .d4# = {5}
    @emlVariance: .d4#
    @assertUndefined: "var({5}) = undefined", emlVariance.result
    appendInfoLine: ""
endproc

# --- @test_emlSD ----------------------------------------------------------
procedure test_emlSD
    .header$ = "--- @emlSD ---"
    appendInfoLine: .header$
    .d1# = {1, 2, 3, 4, 5}
    @emlSD: .d1#
    @assertApprox: "sd({1..5}) = 1.5811", emlSD.result, 1.581139, tolStat
    # Two elements: {3,7} -> sd = sqrt(8) = 2.8284
    .d5# = {3, 7}
    @emlSD: .d5#
    @assertApprox: "sd({3,7}) = 2.8284", emlSD.result, 2.828427, tolStat
    # Single element: undefined
    .d4# = {5}
    @emlSD: .d4#
    @assertUndefined: "sd({5}) = undefined", emlSD.result
    appendInfoLine: ""
endproc

# --- @test_emlSEM ---------------------------------------------------------
procedure test_emlSEM
    .header$ = "--- @emlSEM ---"
    appendInfoLine: .header$
    # SEM = sd/sqrt(n) = sqrt(2.5)/sqrt(5) = sqrt(0.5) = 0.7071
    .d1# = {1, 2, 3, 4, 5}
    @emlSEM: .d1#
    @assertApprox: "sem({1..5}) = 0.7071", emlSEM.result, 0.707107, tolStat
    # Single element: undefined
    .d4# = {5}
    @emlSEM: .d4#
    @assertUndefined: "sem({5}) = undefined", emlSEM.result
    appendInfoLine: ""
endproc

# --- @test_emlSkewness ----------------------------------------------------
procedure test_emlSkewness
    .header$ = "--- @emlSkewness ---"
    appendInfoLine: .header$
    # Symmetric: {1,2,3,4,5} -> skewness = 0
    .d1# = {1, 2, 3, 4, 5}
    @emlSkewness: .d1#
    @assertApprox: "skew({1..5}) = 0", emlSkewness.result, 0, tolStat
    # Strongly positive skew: {1,1,1,1,100}
    # Analytically: (5/(4*3)) * sum(z^3) = 0.41667 * 5.36662 = 2.2361
    .d3# = {1, 1, 1, 1, 100}
    @emlSkewness: .d3#
    @assertApprox: "skew({1,1,1,1,100}) = 2.2361", emlSkewness.result, 2.2361, tolCI
    # n < 3: undefined
    .d5# = {3, 7}
    @emlSkewness: .d5#
    @assertUndefined: "skew(n=2) = undefined", emlSkewness.result
    .d4# = {5}
    @emlSkewness: .d4#
    @assertUndefined: "skew(n=1) = undefined", emlSkewness.result
    appendInfoLine: ""
endproc

# --- @test_emlKurtosis ----------------------------------------------------
procedure test_emlKurtosis
    .header$ = "--- @emlKurtosis ---"
    appendInfoLine: .header$
    # {1,2,3,4,5}: excess kurtosis = -1.2
    .d1# = {1, 2, 3, 4, 5}
    @emlKurtosis: .d1#
    @assertApprox: "kurt({1..5}) = -1.2", emlKurtosis.result, -1.2, tolStat
    # n < 4: undefined
    .d3elem# = {1, 2, 3}
    @emlKurtosis: .d3elem#
    @assertUndefined: "kurt(n=3) = undefined", emlKurtosis.result
    .d4# = {5}
    @emlKurtosis: .d4#
    @assertUndefined: "kurt(n=1) = undefined", emlKurtosis.result
    appendInfoLine: ""
endproc

# --- @test_emlGeometricMean -----------------------------------------------
procedure test_emlGeometricMean
    .header$ = "--- @emlGeometricMean ---"
    appendInfoLine: .header$
    # {1,2,4,8}: gmean = (64)^0.25 = 2*sqrt(2) = 2.8284
    .d6# = {1, 2, 4, 8}
    @emlGeometricMean: .d6#
    @assertApprox: "gmean({1,2,4,8}) = 2.8284", emlGeometricMean.result, 2.828427, tolStat
    # Negative value: undefined
    .dNeg# = {1, -2, 3}
    @emlGeometricMean: .dNeg#
    @assertUndefined: "gmean(negative) = undefined", emlGeometricMean.result
    # Zero value: undefined
    .dZero# = {0, 1, 2}
    @emlGeometricMean: .dZero#
    @assertUndefined: "gmean(zero) = undefined", emlGeometricMean.result
    appendInfoLine: ""
endproc

# --- @test_emlHarmonicMean ------------------------------------------------
procedure test_emlHarmonicMean
    .header$ = "--- @emlHarmonicMean ---"
    appendInfoLine: .header$
    # {1,2,4,8}: hmean = 4/(1+0.5+0.25+0.125) = 4/1.875 = 2.1333
    .d6# = {1, 2, 4, 8}
    @emlHarmonicMean: .d6#
    @assertApprox: "hmean({1,2,4,8}) = 2.1333", emlHarmonicMean.result, 2.133333, tolStat
    # Zero value: undefined
    .dZero# = {0, 1, 2}
    @emlHarmonicMean: .dZero#
    @assertUndefined: "hmean(zero) = undefined", emlHarmonicMean.result
    # Negative value: undefined
    .dNeg# = {1, -2, 3}
    @emlHarmonicMean: .dNeg#
    @assertUndefined: "hmean(negative) = undefined", emlHarmonicMean.result
    appendInfoLine: ""
endproc

# --- @test_emlTrimmedMean -------------------------------------------------
procedure test_emlTrimmedMean
    .header$ = "--- @emlTrimmedMean ---"
    appendInfoLine: .header$
    # {1,2,3,4,5,6,7,8,9,100}, proportion=0.1 -> trim 1 each end
    # Trimmed set: {2,3,4,5,6,7,8,9}, mean = 44/8 = 5.5
    .dAsym# = {1, 2, 3, 4, 5, 6, 7, 8, 9, 100}
    @emlTrimmedMean: .dAsym#, 0.1
    @assertApprox: "trimmed(0.1) = 5.5", emlTrimmedMean.result, 5.5, tolStat
    # proportion=0.2 -> trim 2 each end
    # Trimmed set: {3,4,5,6,7,8}, mean = 33/6 = 5.5
    @emlTrimmedMean: .dAsym#, 0.2
    @assertApprox: "trimmed(0.2) = 5.5", emlTrimmedMean.result, 5.5, tolStat
    # proportion=0 -> regular mean
    @emlTrimmedMean: .dAsym#, 0
    .expectedMean = 14.5
    @assertApprox: "trimmed(0) = mean = 14.5", emlTrimmedMean.result, .expectedMean, tolStat
    # proportion >= 0.5 -> undefined
    @emlTrimmedMean: .dAsym#, 0.5
    @assertUndefined: "trimmed(0.5) = undefined", emlTrimmedMean.result
    appendInfoLine: ""
endproc

# --- @test_emlWinsorizedMean ----------------------------------------------
procedure test_emlWinsorizedMean
    .header$ = "--- @emlWinsorizedMean ---"
    appendInfoLine: .header$
    # {1,2,3,4,5,6,7,8,9,100}, proportion=0.1 -> k=1
    # Replace sorted[1]=1 with sorted[2]=2, sorted[10]=100 with sorted[9]=9
    # Winsorized: {2,2,3,4,5,6,7,8,9,9}, sum=55, mean=5.5
    .dAsym# = {1, 2, 3, 4, 5, 6, 7, 8, 9, 100}
    @emlWinsorizedMean: .dAsym#, 0.1
    @assertApprox: "winsor(0.1) = 5.5", emlWinsorizedMean.result, 5.5, tolStat
    # proportion=0.2 -> k=2
    # Replace [1,2] with sorted[3]=3, [9,10] with sorted[8]=8
    # Winsorized: {3,3,3,4,5,6,7,8,8,8}, sum=55, mean=5.5
    @emlWinsorizedMean: .dAsym#, 0.2
    @assertApprox: "winsor(0.2) = 5.5", emlWinsorizedMean.result, 5.5, tolStat
    # proportion=0 -> regular mean
    @emlWinsorizedMean: .dAsym#, 0
    @assertApprox: "winsor(0) = mean = 14.5", emlWinsorizedMean.result, 14.5, tolStat
    # proportion >= 0.5 -> undefined
    @emlWinsorizedMean: .dAsym#, 0.5
    @assertUndefined: "winsor(0.5) = undefined", emlWinsorizedMean.result
    # Asymmetric test where winsor differs from trim:
    # {1,10,10,10,10,10,10,10,10,100}, proportion=0.1
    # k=1, sorted same, replace 1->10, 100->10
    # Winsorized: {10,10,10,10,10,10,10,10,10,10}, mean=10
    .dAsym2# = {1, 10, 10, 10, 10, 10, 10, 10, 10, 100}
    @emlWinsorizedMean: .dAsym2#, 0.1
    @assertApprox: "winsor different from trim", emlWinsorizedMean.result, 10, tolStat
    appendInfoLine: ""
endproc

# --- @test_emlMAD ---------------------------------------------------------
procedure test_emlMAD
    .header$ = "--- @emlMAD ---"
    appendInfoLine: .header$
    # {1,2,3,4,5}: median=3
    # |deviations| = {2,1,0,1,2}, sorted = {0,1,1,2,2}
    # median of deviations = 1, MAD = 1 * 1.4826 = 1.4826
    .d1# = {1, 2, 3, 4, 5}
    @emlMAD: .d1#
    @assertApprox: "rawMAD({1..5}) = 1", emlMAD.rawMAD, 1, tolStat
    @assertApprox: "MAD({1..5}) = 1.4826", emlMAD.result, 1.4826, tolStat
    # Single element: MAD = 0 (deviation from self is 0)
    .d4# = {5}
    @emlMAD: .d4#
    @assertApprox: "rawMAD({5}) = 0", emlMAD.rawMAD, 0, tolStat
    @assertApprox: "MAD({5}) = 0", emlMAD.result, 0, tolStat
    appendInfoLine: ""
endproc

# --- @test_emlRange -------------------------------------------------------
procedure test_emlRange
    .header$ = "--- @emlRange ---"
    appendInfoLine: .header$
    .d1# = {1, 2, 3, 4, 5}
    @emlRange: .d1#
    @assertApprox: "min({1..5}) = 1", emlRange.min, 1, tolStat
    @assertApprox: "max({1..5}) = 5", emlRange.max, 5, tolStat
    @assertApprox: "range({1..5}) = 4", emlRange.range, 4, tolStat
    # Single element
    .d4# = {5}
    @emlRange: .d4#
    @assertApprox: "min({5}) = 5", emlRange.min, 5, tolStat
    @assertApprox: "max({5}) = 5", emlRange.max, 5, tolStat
    @assertApprox: "range({5}) = 0", emlRange.range, 0, tolStat
    appendInfoLine: ""
endproc

# --- @test_emlCI ----------------------------------------------------------
procedure test_emlCI
    .header$ = "--- @emlCI ---"
    appendInfoLine: .header$
    # {1,2,3,4,5} at 95%
    # mean=3, sem=sqrt(0.5)=0.70711, df=4
    # t_crit = invStudentQ(0.025, 4) = 2.776445
    # margin = 2.776445 * 0.70711 = 1.963583
    # lower = 3 - 1.963583 = 1.036417
    # upper = 3 + 1.963583 = 4.963583
    .d1# = {1, 2, 3, 4, 5}
    @emlCI: .d1#, 0.95
    @assertApprox: "CI mean = 3", emlCI.mean, 3, tolStat
    @assertApprox: "CI lower = 1.0364", emlCI.lower, 1.036417, tolCI
    @assertApprox: "CI upper = 4.9636", emlCI.upper, 4.963583, tolCI
    # 99% CI should be wider
    @emlCI: .d1#, 0.99
    .isWider = emlCI.marginOfError > 1.963583
    @assertExact: "99% CI wider than 95%", .isWider, 1
    # Single element: undefined
    .d4# = {5}
    @emlCI: .d4#, 0.95
    @assertUndefined: "CI(n=1) lower = undefined", emlCI.lower
    @assertUndefined: "CI(n=1) upper = undefined", emlCI.upper
    appendInfoLine: ""
endproc

# --- @test_emlDescribe ----------------------------------------------------
procedure test_emlDescribe
    .header$ = "--- @emlDescribe ---"
    appendInfoLine: .header$
    # Comprehensive check with Dataset 1: {1,2,3,4,5}
    .d1# = {1, 2, 3, 4, 5}
    @emlDescribe: .d1#
    @assertExact: "describe n = 5", emlDescribe.n, 5
    @assertApprox: "describe mean = 3", emlDescribe.mean, 3, tolStat
    @assertApprox: "describe sd = 1.5811", emlDescribe.sd, 1.581139, tolStat
    @assertApprox: "describe variance = 2.5", emlDescribe.variance, 2.5, tolStat
    @assertApprox: "describe sem = 0.7071", emlDescribe.sem, 0.707107, tolStat
    @assertApprox: "describe median = 3", emlDescribe.median, 3, tolStat
    @assertApprox: "describe q1 = 2", emlDescribe.q1, 2, tolPct
    @assertApprox: "describe q3 = 4", emlDescribe.q3, 4, tolPct
    @assertApprox: "describe iqr = 2", emlDescribe.iqr, 2, tolPct
    @assertApprox: "describe min = 1", emlDescribe.min, 1, tolStat
    @assertApprox: "describe max = 5", emlDescribe.max, 5, tolStat
    @assertApprox: "describe range = 4", emlDescribe.range, 4, tolStat
    @assertApprox: "describe skewness = 0", emlDescribe.skewness, 0, tolStat
    @assertApprox: "describe kurtosis = -1.2", emlDescribe.kurtosis, -1.2, tolStat
    @assertApprox: "describe ci95Lower", emlDescribe.ci95Lower, 1.036417, tolCI
    @assertApprox: "describe ci95Upper", emlDescribe.ci95Upper, 4.963583, tolCI
    # emlDescribe.summary$ was deleted on 6 Aug 2026 (D7): it was a second
    # renderer of the same values that no shipping code read, and it had
    # already drifted from the one users see -- it said "Kurtosis (excess)"
    # where the report path said "Kurtosis", which is D4. The report path
    # @emlReportDescriptives is what is tested now, in the wrapper tests.
    appendInfoLine: ""
endproc

# ============================================================================
# Test runner
# ============================================================================

clearinfo
.title$ = "============================================"
writeInfoLine: .title$
.subtitle$ = "EML Stats Core Descriptive Statistics Tests"
appendInfoLine: .subtitle$
appendInfoLine: .title$
appendInfoLine: ""

@test_emlMean
@test_emlMedian
@test_emlMode
@test_emlPercentile
@test_emlQuartiles
@test_emlVariance
@test_emlSD
@test_emlSEM
@test_emlSkewness
@test_emlKurtosis
@test_emlGeometricMean
@test_emlHarmonicMean
@test_emlTrimmedMean
@test_emlWinsorizedMean
@test_emlMAD
@test_emlRange
@test_emlCI
@test_emlDescribe

appendInfoLine: .title$
.summaryLabel$ = "SUMMARY"
appendInfoLine: .summaryLabel$
.passLabel$ = "  Passed: "
appendInfoLine: .passLabel$, testsPassed
.failLabel$ = "  Failed: "
appendInfoLine: .failLabel$, testsFailed
.totalLabel$ = "  Total:  "
appendInfoLine: .totalLabel$, testsTotal
appendInfoLine: .title$
if testsFailed = 0
    .allPass$ = "ALL TESTS PASSED"
    appendInfoLine: .allPass$
else
    .someFail$ = "SOME TESTS FAILED — review output above"
    appendInfoLine: .someFail$
endif

# Bridge the local counters into the shared harness so @emlTestSummary can
# emit the machine-readable sentinel (TEST RESULT REPORTING CONTRACT v1.1).
# @emlTestSummary exitScript:s when failed > 0, so this must stay last —
# nothing that needs to run may follow it.
emlTestInit.passed = testsPassed
emlTestInit.failed = testsFailed
emlTestInit.skipped = 0
emlTestInit.count = testsTotal
@emlTestSummary
