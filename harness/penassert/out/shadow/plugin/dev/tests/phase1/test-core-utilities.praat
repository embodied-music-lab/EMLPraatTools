# ============================================================================
# EML Stats : Core Utility Procedures — Validation Suite
# ============================================================================
# Tests: eml-core-utilities.praat
# Version: 1.1
# Date: 3 August 2026
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
# NOTE ON LAYOUT: this suite runs its whole main body (header, test calls,
# summary) at the top of the file and defines its procedures below. Praat
# resolves a procedure definition wherever it sits, so the ordering is
# correct — but it means the bridge belongs immediately after the summary
# block, NOT at the file tail. Code after the last endproc never executes.
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

include ../../../stats/eml-core-utilities.praat

# Shared harness — used only for @emlTestInit / @emlTestSummary (the
# reporting contract). This suite keeps its own assertion helpers.
include ../eml-test-helpers.praat

@emlTestInit

# ============================================================================
# TEST RUNNER
# ============================================================================

# Global test counters
testsPassed = 0
testsFailed = 0
tolerance = 0.0001

# Header
headerLine$ = "=============================================="
writeInfoLine: headerLine$
titleLine$ = "EML Stats Core Utilities - Test Suite"
appendInfoLine: titleLine$
appendInfoLine: headerLine$
appendInfoLine: ""

# Run all test procedures
@testRankVector
@testCountIf
@testSubset
@testUniqueValues
@testFrequency
@testCumulativeSum
@testDiff
@testLag
@testBinData
@testZScore
@testRemoveUndefined
@testSortWithIndex
@testConcatenateVectors
@testRepeatVector

# Summary
appendInfoLine: ""
appendInfoLine: headerLine$
summaryLabel$ = "TEST SUMMARY"
appendInfoLine: summaryLabel$
appendInfoLine: headerLine$
passedLabel$ = "Passed: "
appendInfoLine: passedLabel$, testsPassed
failedLabel$ = "Failed: "
appendInfoLine: failedLabel$, testsFailed
totalTests = testsPassed + testsFailed
totalLabel$ = "Total:  "
appendInfoLine: totalLabel$, totalTests
appendInfoLine: ""

if testsFailed = 0
    successMsg$ = "*** ALL TESTS PASSED ***"
    appendInfoLine: successMsg$
else
    failMsg$ = "*** SOME TESTS FAILED ***"
    appendInfoLine: failMsg$
endif

# Bridge the local counters into the shared harness so @emlTestSummary can
# emit the machine-readable sentinel (TEST RESULT REPORTING CONTRACT v1.1).
# @emlTestSummary exitScript:s when failed > 0, so this is the last executed
# statement of the main body; the procedure definitions below are
# declarations, not execution, and are unaffected.
emlTestInit.passed = testsPassed
emlTestInit.failed = testsFailed
emlTestInit.skipped = 0
emlTestInit.count = totalTests
@emlTestSummary


# ============================================================================
# HELPER: Report test result
# ============================================================================

procedure reportTest: .name$, .passed
    if .passed
        testsPassed = testsPassed + 1
        .status$ = "PASS"
    else
        testsFailed = testsFailed + 1
        .status$ = "FAIL"
    endif
    .prefix$ = "  ["
    .suffix$ = "] "
    appendInfoLine: .prefix$, .status$, .suffix$, .name$
endproc


# ============================================================================
# HELPER: Compare vectors with tolerance
# ============================================================================

procedure vectorsEqual: .v1#, .v2#, .tol
    .equal = 1
    .n1 = size (.v1#)
    .n2 = size (.v2#)
    
    if .n1 <> .n2
        .equal = 0
    else
        for .i from 1 to .n1
            .diff = abs (.v1#[.i] - .v2#[.i])
            if .diff > .tol
                .equal = 0
            endif
        endfor
    endif
endproc


# ============================================================================
# TEST: @emlRankVector
# ============================================================================

procedure testRankVector
    .sectionHeader$ = "--- @emlRankVector ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Basic ties
    .data1# = {10, 20, 20, 30}
    .expected1# = {1, 2.5, 2.5, 4}
    @emlRankVector: .data1#
    @vectorsEqual: emlRankVector.ranks#, .expected1#, tolerance
    .passed = vectorsEqual.equal and (emlRankVector.hasTies = 1)
    @reportTest: "Basic ties {10,20,20,30}", .passed
    
    # Test 2: No ties, unsorted
    .data2# = {5, 3, 1, 4, 2}
    .expected2# = {5, 3, 1, 4, 2}
    @emlRankVector: .data2#
    @vectorsEqual: emlRankVector.ranks#, .expected2#, tolerance
    .passed = vectorsEqual.equal and (emlRankVector.hasTies = 0)
    @reportTest: "No ties {5,3,1,4,2}", .passed
    
    # Test 3: All tied
    .data3# = {7, 7, 7}
    .expected3# = {2, 2, 2}
    @emlRankVector: .data3#
    @vectorsEqual: emlRankVector.ranks#, .expected3#, tolerance
    .passed = vectorsEqual.equal and (emlRankVector.hasTies = 1)
    @reportTest: "All tied {7,7,7}", .passed
    
    # Test 4: Single element
    .data4# = {100}
    .expected4# = {1}
    @emlRankVector: .data4#
    @vectorsEqual: emlRankVector.ranks#, .expected4#, tolerance
    .passed = vectorsEqual.equal and (emlRankVector.hasTies = 0)
    @reportTest: "Single element {100}", .passed
    
    # Test 5: Already sorted, no ties
    .data5# = {1, 2, 3, 4, 5}
    .expected5# = {1, 2, 3, 4, 5}
    @emlRankVector: .data5#
    @vectorsEqual: emlRankVector.ranks#, .expected5#, tolerance
    .passed = vectorsEqual.equal and (emlRankVector.hasTies = 0)
    @reportTest: "Already sorted {1,2,3,4,5}", .passed
    
    # Test 6: Reverse sorted, no ties
    .data6# = {5, 4, 3, 2, 1}
    .expected6# = {5, 4, 3, 2, 1}
    @emlRankVector: .data6#
    @vectorsEqual: emlRankVector.ranks#, .expected6#, tolerance
    .passed = vectorsEqual.equal and (emlRankVector.hasTies = 0)
    @reportTest: "Reverse sorted {5,4,3,2,1}", .passed
    
    # Test 7: All tied pairs
    .data7# = {1, 1, 2, 2, 3, 3}
    .expected7# = {1.5, 1.5, 3.5, 3.5, 5.5, 5.5}
    @emlRankVector: .data7#
    @vectorsEqual: emlRankVector.ranks#, .expected7#, tolerance
    .passed = vectorsEqual.equal and (emlRankVector.hasTies = 1) and (emlRankVector.nTieGroups = 3)
    @reportTest: "All tied pairs {1,1,2,2,3,3}", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlCountIf
# ============================================================================

procedure testCountIf
    .sectionHeader$ = "--- @emlCountIf ---"
    appendInfoLine: .sectionHeader$
    
    .data# = {1, 2, 3, 4, 5}
    
    # Test 1: Greater than
    @emlCountIf: .data#, ">", 3
    .passed = (emlCountIf.count = 2)
    @reportTest: "count > 3 in {1,2,3,4,5}", .passed
    
    # Test 2: Equals
    @emlCountIf: .data#, "=", 3
    .passed = (emlCountIf.count = 1)
    @reportTest: "count = 3 in {1,2,3,4,5}", .passed
    
    # Test 3: Not equals
    @emlCountIf: .data#, "<>", 3
    .passed = (emlCountIf.count = 4)
    @reportTest: "count <> 3 in {1,2,3,4,5}", .passed
    
    # Test 4: All match
    .data2# = {1, 1, 1}
    @emlCountIf: .data2#, "=", 1
    .passed = (emlCountIf.count = 3)
    @reportTest: "count = 1 in {1,1,1}", .passed
    
    # Test 5: Less than or equal
    @emlCountIf: .data#, "<=", 3
    .passed = (emlCountIf.count = 3)
    @reportTest: "count <= 3 in {1,2,3,4,5}", .passed
    
    # Test 6: Greater than or equal
    @emlCountIf: .data#, ">=", 3
    .passed = (emlCountIf.count = 3)
    @reportTest: "count >= 3 in {1,2,3,4,5}", .passed
    
    # Test 7: Invalid operator
    @emlCountIf: .data#, "??", 3
    .passed = (emlCountIf.error$ <> "")
    @reportTest: "Invalid operator error", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlSubset
# ============================================================================

procedure testSubset
    .sectionHeader$ = "--- @emlSubset ---"
    appendInfoLine: .sectionHeader$
    
    .data# = {10, 20, 30, 40, 50}
    
    # Test 1: Select indices 2, 4
    .indices1# = {2, 4}
    .expected1# = {20, 40}
    @emlSubset: .data#, .indices1#
    @vectorsEqual: emlSubset.result#, .expected1#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Subset indices {2,4}", .passed
    
    # Test 2: Select all in reverse
    .indices2# = {5, 4, 3, 2, 1}
    .expected2# = {50, 40, 30, 20, 10}
    @emlSubset: .data#, .indices2#
    @vectorsEqual: emlSubset.result#, .expected2#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Subset reversed", .passed
    
    # Test 3: Out of range indices skipped
    .indices3# = {1, 10, 3}
    @emlSubset: .data#, .indices3#
    .passed = (size (emlSubset.result#) = 2) and (emlSubset.nSkipped = 1)
    @reportTest: "Out of range skipped", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlUniqueValues
# ============================================================================

procedure testUniqueValues
    .sectionHeader$ = "--- @emlUniqueValues ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Multiple duplicates
    .data1# = {3, 1, 4, 1, 5, 9, 2, 6, 5}
    .expected1# = {1, 2, 3, 4, 5, 6, 9}
    @emlUniqueValues: .data1#
    @vectorsEqual: emlUniqueValues.values#, .expected1#, tolerance
    .passed = vectorsEqual.equal and (emlUniqueValues.nUnique = 7)
    @reportTest: "Multiple duplicates", .passed
    
    # Test 2: All identical
    .data2# = {5, 5, 5}
    .expected2# = {5}
    @emlUniqueValues: .data2#
    @vectorsEqual: emlUniqueValues.values#, .expected2#, tolerance
    .passed = vectorsEqual.equal and (emlUniqueValues.nUnique = 1)
    @reportTest: "All identical {5,5,5}", .passed
    
    # Test 3: Single element
    .data3# = {1}
    .expected3# = {1}
    @emlUniqueValues: .data3#
    @vectorsEqual: emlUniqueValues.values#, .expected3#, tolerance
    .passed = vectorsEqual.equal and (emlUniqueValues.nUnique = 1)
    @reportTest: "Single element {1}", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlFrequency
# ============================================================================

procedure testFrequency
    .sectionHeader$ = "--- @emlFrequency ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Standard distribution
    .data1# = {1, 2, 2, 3, 3, 3}
    .expectedVals1# = {1, 2, 3}
    .expectedCounts1# = {1, 2, 3}
    @emlFrequency: .data1#
    @vectorsEqual: emlFrequency.values#, .expectedVals1#, tolerance
    .valsMatch = vectorsEqual.equal
    @vectorsEqual: emlFrequency.counts#, .expectedCounts1#, tolerance
    .countsMatch = vectorsEqual.equal
    .passed = .valsMatch and .countsMatch
    @reportTest: "Frequency {1,2,2,3,3,3}", .passed
    
    # Test 2: All identical
    .data2# = {5, 5, 5, 5}
    .expectedVals2# = {5}
    .expectedCounts2# = {4}
    @emlFrequency: .data2#
    @vectorsEqual: emlFrequency.values#, .expectedVals2#, tolerance
    .valsMatch = vectorsEqual.equal
    @vectorsEqual: emlFrequency.counts#, .expectedCounts2#, tolerance
    .countsMatch = vectorsEqual.equal
    .passed = .valsMatch and .countsMatch
    @reportTest: "Frequency all same {5,5,5,5}", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlCumulativeSum
# ============================================================================

procedure testCumulativeSum
    .sectionHeader$ = "--- @emlCumulativeSum ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Standard case
    .data1# = {1, 2, 3, 4}
    .expected1# = {1, 3, 6, 10}
    @emlCumulativeSum: .data1#
    @vectorsEqual: emlCumulativeSum.result#, .expected1#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "CumSum {1,2,3,4}", .passed
    
    # Test 2: Single element
    .data2# = {5}
    .expected2# = {5}
    @emlCumulativeSum: .data2#
    @vectorsEqual: emlCumulativeSum.result#, .expected2#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "CumSum single {5}", .passed
    
    # Test 3: With negatives
    .data3# = {1, -1, 2, -2}
    .expected3# = {1, 0, 2, 0}
    @emlCumulativeSum: .data3#
    @vectorsEqual: emlCumulativeSum.result#, .expected3#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "CumSum with negatives", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlDiff
# ============================================================================

procedure testDiff
    .sectionHeader$ = "--- @emlDiff ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Increasing
    .data1# = {1, 3, 6, 10}
    .expected1# = {2, 3, 4}
    @emlDiff: .data1#
    @vectorsEqual: emlDiff.result#, .expected1#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Diff {1,3,6,10}", .passed
    
    # Test 2: Constant
    .data2# = {5, 5, 5}
    .expected2# = {0, 0}
    @emlDiff: .data2#
    @vectorsEqual: emlDiff.result#, .expected2#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Diff constant {5,5,5}", .passed
    
    # Test 3: Decreasing
    .data3# = {10, 7, 3}
    .expected3# = {-3, -4}
    @emlDiff: .data3#
    @vectorsEqual: emlDiff.result#, .expected3#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Diff decreasing {10,7,3}", .passed
    
    # Test 4: Single element (error case)
    .data4# = {5}
    @emlDiff: .data4#
    .passed = (emlDiff.error$ <> "")
    @reportTest: "Diff single element error", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlLag
# ============================================================================

procedure testLag
    .sectionHeader$ = "--- @emlLag ---"
    appendInfoLine: .sectionHeader$
    
    .data# = {10, 20, 30, 40, 50}
    
    # Test 1: Lag 1
    @emlLag: .data#, 1
    .passed = (emlLag.result#[1] = undefined) and (emlLag.result#[2] = 10) and (emlLag.result#[5] = 40)
    @reportTest: "Lag 1", .passed
    
    # Test 2: Lag 2
    @emlLag: .data#, 2
    .passed = (emlLag.result#[1] = undefined) and (emlLag.result#[2] = undefined) and (emlLag.result#[3] = 10)
    @reportTest: "Lag 2", .passed
    
    # Test 3: Lag 0 (copy)
    @emlLag: .data#, 0
    @vectorsEqual: emlLag.result#, .data#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Lag 0 (copy)", .passed
    
    # Test 4: Lag >= n (all undefined)
    @emlLag: .data#, 5
    .allUndef = 1
    for .i from 1 to 5
        if emlLag.result#[.i] <> undefined
            .allUndef = 0
        endif
    endfor
    .passed = .allUndef
    @reportTest: "Lag >= n (all undefined)", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlBinData
# ============================================================================

procedure testBinData
    .sectionHeader$ = "--- @emlBinData ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Uniform distribution into 5 bins
    .data1# = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    .expectedCounts1# = {2, 2, 2, 2, 2}
    @emlBinData: .data1#, 5
    @vectorsEqual: emlBinData.counts#, .expectedCounts1#, tolerance
    .passed = vectorsEqual.equal and (emlBinData.nBins = 5)
    @reportTest: "Bin 1-10 into 5 bins", .passed
    
    # Test 2: All identical (single bin)
    .data2# = {5, 5, 5, 5}
    @emlBinData: .data2#, 3
    .passed = (emlBinData.nBins = 1) and (emlBinData.counts#[1] = 4)
    @reportTest: "Bin all identical", .passed
    
    # Test 3: Verify bin edges
    @emlBinData: .data1#, 5
    .edgesCorrect = (abs (emlBinData.binEdges#[1] - 1) < tolerance) and (abs (emlBinData.binEdges#[6] - 10) < tolerance)
    .passed = .edgesCorrect
    @reportTest: "Bin edges correct", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlZScore
# ============================================================================

procedure testZScore
    .sectionHeader$ = "--- @emlZScore ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Standard case {2,4,6,8,10}
    # Mean = 6, SD = sqrt(10) ≈ 3.162
    .data1# = {2, 4, 6, 8, 10}
    @emlZScore: .data1#
    
    # Check mean of result is ~0
    .zMean = mean (emlZScore.result#)
    .meanOk = (abs (.zMean) < 0.001)
    
    # Check SD of result is ~1
    .zSD = stdev (emlZScore.result#)
    .sdOk = (abs (.zSD - 1) < 0.001)
    
    .passed = .meanOk and .sdOk
    @reportTest: "Z-score mean=0, sd=1", .passed
    
    # Test 2: Verify individual z-scores
    # z = (x - 6) / sqrt(10)
    # For x=2: z = -4/3.162 ≈ -1.265
    # For x=6: z = 0
    .expectedMid = 0
    .midOk = (abs (emlZScore.result#[3] - .expectedMid) < 0.001)
    .passed = .midOk
    @reportTest: "Z-score middle value = 0", .passed
    
    # Test 3: All identical (sd = 0)
    .data3# = {5, 5, 5, 5}
    @emlZScore: .data3#
    .passed = (emlZScore.warning$ <> "") and (emlZScore.result#[1] = 0)
    @reportTest: "Z-score all identical warning", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlRemoveUndefined
# ============================================================================

procedure testRemoveUndefined
    .sectionHeader$ = "--- @emlRemoveUndefined ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Mixed defined and undefined
    .data1# = {1, undefined, 3, undefined, 5}
    @emlRemoveUndefined: .data1#
    .expected1# = {1, 3, 5}
    @vectorsEqual: emlRemoveUndefined.result#, .expected1#, tolerance
    .passed = vectorsEqual.equal and (emlRemoveUndefined.nRemoved = 2) and (emlRemoveUndefined.nKept = 3)
    @reportTest: "Remove undefined mixed", .passed
    
    # Test 2: All defined
    .data2# = {1, 2, 3}
    @emlRemoveUndefined: .data2#
    @vectorsEqual: emlRemoveUndefined.result#, .data2#, tolerance
    .passed = vectorsEqual.equal and (emlRemoveUndefined.nRemoved = 0)
    @reportTest: "Remove undefined (none)", .passed
    
    # Test 3: Verify kept indices
    @emlRemoveUndefined: .data1#
    .expectedIndices# = {1, 3, 5}
    @vectorsEqual: emlRemoveUndefined.keptIndices#, .expectedIndices#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Kept indices correct", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlSortWithIndex
# ============================================================================

procedure testSortWithIndex
    .sectionHeader$ = "--- @emlSortWithIndex ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Unsorted data
    .data1# = {30, 10, 20}
    .expectedSorted1# = {10, 20, 30}
    .expectedIndices1# = {2, 3, 1}
    @emlSortWithIndex: .data1#
    @vectorsEqual: emlSortWithIndex.sorted#, .expectedSorted1#, tolerance
    .sortedOk = vectorsEqual.equal
    @vectorsEqual: emlSortWithIndex.indices#, .expectedIndices1#, tolerance
    .indicesOk = vectorsEqual.equal
    .passed = .sortedOk and .indicesOk
    @reportTest: "Sort {30,10,20} with index", .passed
    
    # Test 2: Already sorted
    .data2# = {1, 2, 3}
    .expectedSorted2# = {1, 2, 3}
    .expectedIndices2# = {1, 2, 3}
    @emlSortWithIndex: .data2#
    @vectorsEqual: emlSortWithIndex.sorted#, .expectedSorted2#, tolerance
    .sortedOk = vectorsEqual.equal
    @vectorsEqual: emlSortWithIndex.indices#, .expectedIndices2#, tolerance
    .indicesOk = vectorsEqual.equal
    .passed = .sortedOk and .indicesOk
    @reportTest: "Sort already sorted", .passed
    
    # Test 3: Reverse sorted
    .data3# = {5, 4, 3, 2, 1}
    .expectedSorted3# = {1, 2, 3, 4, 5}
    .expectedIndices3# = {5, 4, 3, 2, 1}
    @emlSortWithIndex: .data3#
    @vectorsEqual: emlSortWithIndex.sorted#, .expectedSorted3#, tolerance
    .sortedOk = vectorsEqual.equal
    @vectorsEqual: emlSortWithIndex.indices#, .expectedIndices3#, tolerance
    .indicesOk = vectorsEqual.equal
    .passed = .sortedOk and .indicesOk
    @reportTest: "Sort reverse sorted", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlConcatenateVectors
# ============================================================================

procedure testConcatenateVectors
    .sectionHeader$ = "--- @emlConcatenateVectors ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Standard concatenation
    .v1# = {1, 2}
    .v2# = {3, 4, 5}
    .expected1# = {1, 2, 3, 4, 5}
    @emlConcatenateVectors: .v1#, .v2#
    @vectorsEqual: emlConcatenateVectors.result#, .expected1#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Concat {1,2} + {3,4,5}", .passed
    
    # Test 2: First empty
    .empty# = zero# (0)
    .v3# = {7, 8, 9}
    @emlConcatenateVectors: .empty#, .v3#
    @vectorsEqual: emlConcatenateVectors.result#, .v3#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Concat empty + {7,8,9}", .passed
    
    # Test 3: Second empty
    @emlConcatenateVectors: .v3#, .empty#
    @vectorsEqual: emlConcatenateVectors.result#, .v3#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Concat {7,8,9} + empty", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# TEST: @emlRepeatVector
# ============================================================================

procedure testRepeatVector
    .sectionHeader$ = "--- @emlRepeatVector ---"
    appendInfoLine: .sectionHeader$
    
    # Test 1: Standard repeat
    .v1# = {1, 2, 3}
    .expected1# = {1, 2, 3, 1, 2, 3}
    @emlRepeatVector: .v1#, 2
    @vectorsEqual: emlRepeatVector.result#, .expected1#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Repeat {1,2,3} x2", .passed
    
    # Test 2: Single repetition (copy)
    @emlRepeatVector: .v1#, 1
    @vectorsEqual: emlRepeatVector.result#, .v1#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Repeat x1 (copy)", .passed
    
    # Test 3: Zero repetitions (empty)
    @emlRepeatVector: .v1#, 0
    .passed = (size (emlRepeatVector.result#) = 0)
    @reportTest: "Repeat x0 (empty)", .passed
    
    # Test 4: Triple repeat
    .expected4# = {1, 2, 3, 1, 2, 3, 1, 2, 3}
    @emlRepeatVector: .v1#, 3
    @vectorsEqual: emlRepeatVector.result#, .expected4#, tolerance
    .passed = vectorsEqual.equal
    @reportTest: "Repeat {1,2,3} x3", .passed
    
    appendInfoLine: ""
endproc


# ============================================================================
# END OF TEST SUITE
# ============================================================================
