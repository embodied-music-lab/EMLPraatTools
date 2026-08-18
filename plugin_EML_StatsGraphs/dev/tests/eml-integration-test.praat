# ============================================================================
# Praat + 1 : Integration Test Suite
# ============================================================================
# Version: 1.2
# Date: 3 August 2026
# v1.2: Item 3 — the four library includes were bare filenames, which Praat
#        resolves relative to THIS script's folder (dev/tests/), where none of
#        them exist; the suite aborted at include time with exit 255 and had
#        been doing so undetected. Repointed at ../../stats/. Also brought
#        under the TEST RESULT REPORTING CONTRACT: the hand-rolled summary
#        returned normally, so the process exited 0 with no sentinel — green
#        by construction. Local counters are now bridged into
#        emlTestInit.* and @emlTestSummary emits the sentinel. No assertion
#        call site changed.
# v1.1: Item 2 — test 2.4 called the removed @emlExtractMultipleGroups;
#        rewritten against the current extraction API.
#
# License: GPL-3.0-or-later
#
# Exercises all four Phase 1 modules in a realistic workflow.
# Creates test data, extracts, computes stats, formats output.
# Reports PASS/FAIL for each test.
#
# SETUP: run from anywhere. Praat resolves an include relative to the folder
# holding THIS script, so the library paths below are relative to dev/tests/.
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

include ../../stats/eml-core-utilities.praat
include ../../stats/eml-core-descriptive.praat
include ../../stats/eml-extract.praat
include ../../stats/eml-output.praat
include eml-test-helpers.praat

# ============================================================================
# Test counters
# ============================================================================
@emlTestInit

testsPassed = 0
testsFailed = 0
testsRun = 0

procedure reportTest: .name$, .passed
    testsRun = testsRun + 1
    if .passed
        testsPassed = testsPassed + 1
        .status$ = "PASS"
    else
        testsFailed = testsFailed + 1
        .status$ = "FAIL"
    endif
    .indent$ = "  "
    .line$ = .indent$ + .status$ + " : " + .name$
    appendInfoLine: .line$
endproc

# ============================================================================
# BEGIN TESTS
# ============================================================================

@emlReportHeader: "Integration Test Suite"


# ──────────────────────────────────────────────────────────────────────────────
# TEST GROUP 1: Table extraction -> Descriptive stats -> Output
# ──────────────────────────────────────────────────────────────────────────────

@emlReportSection: "1. Table Extract -> Describe -> Format"

# Create a Table with known values
# Two groups, known statistics for verification:
#   Group A: {10, 20, 30, 40, 50} -> mean=30, sd=15.81, median=30
#   Group B: {5, 10, 15}          -> mean=10, sd=5, median=10

testTable = Create Table with column names: "testData", 8,
    ... "Measure Group"

selectObject: testTable
Set numeric value: 1, "Measure", 10
selectObject: testTable
Set numeric value: 2, "Measure", 20
selectObject: testTable
Set numeric value: 3, "Measure", 30
selectObject: testTable
Set numeric value: 4, "Measure", 40
selectObject: testTable
Set numeric value: 5, "Measure", 50
selectObject: testTable
Set numeric value: 6, "Measure", 5
selectObject: testTable
Set numeric value: 7, "Measure", 10
selectObject: testTable
Set numeric value: 8, "Measure", 15

selectObject: testTable
Set string value: 1, "Group", "A"
selectObject: testTable
Set string value: 2, "Group", "A"
selectObject: testTable
Set string value: 3, "Group", "A"
selectObject: testTable
Set string value: 4, "Group", "A"
selectObject: testTable
Set string value: 5, "Group", "A"
selectObject: testTable
Set string value: 6, "Group", "B"
selectObject: testTable
Set string value: 7, "Group", "B"
selectObject: testTable
Set string value: 8, "Group", "B"

# --- Test 1.1: Extract full column ---
@emlExtractColumn: testTable, "Measure"
.t1_1 = (emlExtractColumn.n = 8 and emlExtractColumn.error$ = "")
@reportTest: "Extract full numeric column (n=8)", .t1_1

# --- Test 1.2: Descriptive stats on extracted column ---
@emlDescribe: emlExtractColumn.data#
# Known: mean of {10,20,30,40,50,5,10,15} = 180/8 = 22.5
.t1_2_meanOk = (abs(emlDescribe.mean - 22.5) < 0.01)
.t1_2_nOk = (emlDescribe.n = 8)
.t1_2 = (.t1_2_meanOk and .t1_2_nOk)
@reportTest: "Descriptive stats (mean=22.5, n=8)", .t1_2

# --- Test 1.3: Extract group vectors ---
@emlExtractGroupVectors: testTable, "Measure", "Group", "A", "B"
.t1_3_n1 = (emlExtractGroupVectors.n1 = 5)
.t1_3_n2 = (emlExtractGroupVectors.n2 = 3)
.t1_3 = (.t1_3_n1 and .t1_3_n2)
@reportTest: "Extract two groups (n1=5, n2=3)", .t1_3

# --- Test 1.4: Stats on Group A ---
@emlDescribe: emlExtractGroupVectors.group1#
.t1_4_mean = (abs(emlDescribe.mean - 30) < 0.01)
.t1_4_median = (abs(emlDescribe.median - 30) < 0.01)
.t1_4 = (.t1_4_mean and .t1_4_median)
@reportTest: "Group A stats (mean=30, median=30)", .t1_4

# --- Test 1.5: Stats on Group B ---
@emlDescribe: emlExtractGroupVectors.group2#
.t1_5_mean = (abs(emlDescribe.mean - 10) < 0.01)
.t1_5_median = (abs(emlDescribe.median - 10) < 0.01)
.t1_5 = (.t1_5_mean and .t1_5_median)
@reportTest: "Group B stats (mean=10, median=10)", .t1_5

# --- Test 1.6: Formatted output ---
@emlReportDescriptiveHeader
@emlDescribe: emlExtractGroupVectors.group1#
@emlReportDescriptiveRow: "Group A", emlDescribe.n, emlDescribe.mean, emlDescribe.sd, emlDescribe.median
@emlDescribe: emlExtractGroupVectors.group2#
@emlReportDescriptiveRow: "Group B", emlDescribe.n, emlDescribe.mean, emlDescribe.sd, emlDescribe.median
# Visual check -- no assertion, just confirms no crash
@reportTest: "Formatted descriptive table (visual check)", 1


# ──────────────────────────────────────────────────────────────────────────────
# TEST GROUP 2: Edge cases and C2 fix validation
# ──────────────────────────────────────────────────────────────────────────────

@emlReportSection: "2. Edge Cases and C2 Fix"

# --- Test 2.1: Extract nonexistent column ---
@emlExtractColumn: testTable, "NONEXISTENT"
.t2_1 = (emlExtractColumn.error$ <> "" and emlExtractColumn.n = 0)
@reportTest: "Nonexistent column returns error", .t2_1

# --- Test 2.2: C2 fix -- group extraction with no matching rows ---
# Request labels that don't exist in the table
@emlExtractGroupVectors: testTable, "Measure", "Group", "X", "Y"
.t2_2_n1 = (emlExtractGroupVectors.n1 = 0)
.t2_2_n2 = (emlExtractGroupVectors.n2 = 0)
.t2_2_size1 = (size(emlExtractGroupVectors.group1#) = 0)
.t2_2_size2 = (size(emlExtractGroupVectors.group2#) = 0)
.t2_2 = (.t2_2_n1 and .t2_2_n2 and .t2_2_size1 and .t2_2_size2)
@reportTest: "C2 fix: empty groups -> zero#(0)", .t2_2

# --- Test 2.3: C2 fix -- empty vector into descriptive stats ---
# This is the critical end-to-end test:
# zero#(0) passed to @emlDescribe should return undefined, not crash
emptyVector# = zero#(0)
@emlDescribe: emptyVector#
.t2_3_n = (emlDescribe.n = 0)
.t2_3_mean = (emlDescribe.mean = undefined)
.t2_3_sd = (emlDescribe.sd = undefined)
.t2_3 = (.t2_3_n and .t2_3_mean and .t2_3_sd)
@reportTest: "C2 fix: empty vector -> undefined stats", .t2_3

# --- Test 2.4: Group auto-discovery + per-group extraction ---
# Current API: @emlCountGroups discovers labels, @eml_getGroupData
# pulls one group's data on demand (@emlExtractMultipleGroups was
# deleted in eml-extract v1.1).
@emlCountGroups: testTable, "Group"
.t2_4_nGroups = (emlCountGroups.nGroups = 2)
.t2_4_err = (emlCountGroups.error$ = "")
.t2_4_label1$ = emlCountGroups.groupLabel$[1]
.t2_4_label2$ = emlCountGroups.groupLabel$[2]
@eml_getGroupData: testTable, "Measure", "Group", .t2_4_label1$
.t2_4_size1 = (eml_getGroupData.n = 5)
@eml_getGroupData: testTable, "Measure", "Group", .t2_4_label2$
.t2_4_size2 = (eml_getGroupData.n = 3)
.t2_4 = (.t2_4_nGroups and .t2_4_err and .t2_4_size1 and .t2_4_size2)
@reportTest: "Group auto-discovery + per-group extract (2 groups)", .t2_4

# --- Test 2.5: Extract string column ---
@emlExtractColumnAsStrings: testTable, "Group"
.t2_5_n = (emlExtractColumnAsStrings.n = 8)
.t2_5_first = (emlExtractColumnAsStrings.str$[1] = "A")
.t2_5_last = (emlExtractColumnAsStrings.str$[8] = "B")
.t2_5 = (.t2_5_n and .t2_5_first and .t2_5_last)
@reportTest: "Extract string column", .t2_5

# --- Test 2.6: Paired column extraction ---
selectObject: testTable
Append column: "Measure2"
selectObject: testTable
Set numeric value: 1, "Measure2", 12
selectObject: testTable
Set numeric value: 2, "Measure2", 22
selectObject: testTable
Set numeric value: 3, "Measure2", 32
selectObject: testTable
Set numeric value: 4, "Measure2", 42
selectObject: testTable
Set numeric value: 5, "Measure2", 52
selectObject: testTable
Set numeric value: 6, "Measure2", 7
selectObject: testTable
Set numeric value: 7, "Measure2", 12
selectObject: testTable
Set numeric value: 8, "Measure2", 17

@emlExtractPairedColumns: testTable, "Measure", "Measure2"
.t2_6_n = (emlExtractPairedColumns.n = 8)
.t2_6_err = (emlExtractPairedColumns.error$ = "")
.t2_6 = (.t2_6_n and .t2_6_err)
@reportTest: "Paired column extraction (n=8)", .t2_6

# --- Test 2.7: Table validation ---
@emlValidateTable: testTable, "Measure Group"
.t2_7_valid = (emlValidateTable.valid = 1)
@reportTest: "Table validation (required cols exist)", .t2_7_valid

@emlValidateTable: testTable, "Measure Group Missing"
.t2_7b = (emlValidateTable.valid = 0)
@reportTest: "Table validation (missing col detected)", .t2_7b

# --- Test 2.8: Count groups ---
# @emlCountGroups reports .nGroups and .groupLabel$[] only; per-group
# sizes come from @eml_getGroupData.
@emlCountGroups: testTable, "Group"
.t2_8_n = (emlCountGroups.nGroups = 2)
.t2_8_lab1 = (emlCountGroups.groupLabel$[1] = "A")
.t2_8_lab2 = (emlCountGroups.groupLabel$[2] = "B")
.t2_8 = (.t2_8_n and .t2_8_lab1 and .t2_8_lab2)
@reportTest: "Count groups", .t2_8


# ──────────────────────────────────────────────────────────────────────────────
# TEST GROUP 3: Core utilities
# ──────────────────────────────────────────────────────────────────────────────

@emlReportSection: "3. Core Utilities"

# --- Test 3.1: Z-scores ---
testData# = {10, 20, 30, 40, 50}
@emlZScore: testData#
# mean=30, sd=15.81...; z of 10 = (10-30)/15.81 = -1.265
.t3_1_n = (emlZScore.n = 5)
.t3_1_z1 = (abs(emlZScore.result#[1] - (-1.2649)) < 0.01)
.t3_1 = (.t3_1_n and .t3_1_z1)
@reportTest: "Z-scores (z[1] approx -1.26)", .t3_1

# --- Test 3.2: Rank vector ---
rankData# = {30, 10, 50, 20, 40}
@emlRankVector: rankData#
# Sorted order: 10(idx2)=rank1, 20(idx4)=rank2, 30(idx1)=rank3, 40(idx5)=rank4, 50(idx3)=rank5
# So ranks#[1]=3, ranks#[2]=1
.t3_2_n = (emlRankVector.n = 5)
.t3_2_r1 = (emlRankVector.ranks#[1] = 3)
.t3_2_r2 = (emlRankVector.ranks#[2] = 1)
.t3_2 = (.t3_2_n and .t3_2_r1 and .t3_2_r2)
@reportTest: "Rank vector", .t3_2

# --- Test 3.3: Subset ---
subData# = {1, 2, 3, 4, 5}
subIndices# = {2, 3, 4}
@emlSubset: subData#, subIndices#
.t3_3_n = (size(emlSubset.result#) = 3)
.t3_3_v1 = (emlSubset.result#[1] = 2)
.t3_3_v3 = (emlSubset.result#[3] = 4)
.t3_3 = (.t3_3_n and .t3_3_v1 and .t3_3_v3)
@reportTest: "Subset [2,3,4]", .t3_3

# --- Test 3.4: Concatenate vectors ---
vecA# = {1, 2, 3}
vecB# = {4, 5}
@emlConcatenateVectors: vecA#, vecB#
.t3_4_n = (emlConcatenateVectors.nTotal = 5)
.t3_4_last = (emlConcatenateVectors.result#[5] = 5)
.t3_4 = (.t3_4_n and .t3_4_last)
@reportTest: "Concatenate vectors", .t3_4

# --- Test 3.5: Bin data ---
binData# = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
@emlBinData: binData#, 5
.t3_5_nBins = (emlBinData.nBins = 5)
.t3_5 = .t3_5_nBins
@reportTest: "Bin data (5 bins)", .t3_5

# --- Test 3.6: Cumulative sum ---
cumData# = {1, 2, 3, 4, 5}
@emlCumulativeSum: cumData#
.t3_6_last = (emlCumulativeSum.result#[5] = 15)
.t3_6_mid = (emlCumulativeSum.result#[3] = 6)
.t3_6 = (.t3_6_last and .t3_6_mid)
@reportTest: "Cumulative sum", .t3_6


# ──────────────────────────────────────────────────────────────────────────────
# TEST GROUP 4: Output formatting
# ──────────────────────────────────────────────────────────────────────────────

@emlReportSection: "4. Output Formatting"

# --- Test 4.1: p-value formatting ---
@emlFormatP: 0.034
.t4_1 = (emlFormatP.formatted$ = "p = .034")
@reportTest: "Format p = .034", .t4_1

@emlFormatP: 0.0001
.t4_1b = (emlFormatP.formatted$ = "p < .001")
@reportTest: "Format p < .001", .t4_1b

# --- Test 4.2: CI formatting ---
@emlFormatCI: 0.22, 1.40, 0.95
.t4_2 = (emlFormatCI.formatted$ = "95% CI [0.22, 1.40]")
@reportTest: "Format 95% CI", .t4_2

# --- Test 4.3: Effect size labels ---
@emlFormatEffectLabel: 0.85, "d"
.t4_3a = (emlFormatEffectLabel.label$ = "large effect")
@reportTest: "Effect label: d=0.85 -> large", .t4_3a

@emlFormatEffectLabel: 0.15, "d"
.t4_3b = (emlFormatEffectLabel.label$ = "negligible effect")
@reportTest: "Effect label: d=0.15 -> negligible", .t4_3b

@emlFormatEffectLabel: 0.35, "r"
.t4_3c = (emlFormatEffectLabel.label$ = "medium effect")
@reportTest: "Effect label: r=0.35 -> medium", .t4_3c

# --- Test 4.4: Underscore to space ---
@emlUnderscoreToSpace: "pitch_floor_hz"
.t4_4 = (emlUnderscoreToSpace.result$ = "pitch floor hz")
@reportTest: "Underscore to space", .t4_4

# --- Test 4.5: APA formatting ---
@emlReportAPA: "t", 2.45, 23, 0, 0.021, "d", 0.89, 0.32, 1.45
# Just check it produces non-empty string
.t4_5 = (length(emlReportAPA.formatted$) > 10)
@reportTest: "APA t-test format (non-empty)", .t4_5


# ──────────────────────────────────────────────────────────────────────────────
# TEST GROUP 5: Acoustic object extraction (refactored Intensity)
# ──────────────────────────────────────────────────────────────────────────────

@emlReportSection: "5. Acoustic Object Extraction"

# Create a 1-second test tone
testSound = Create Sound as pure tone: "test", 1, 0, 1, 44100, 440, 0.4, 0.01, 0.01

# --- Test 5.1: Pitch extraction ---
selectObject: testSound
testPitch = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 0.14
@emlExtractPitchValues: testPitch, "Hertz"
.t5_1_hasData = (emlExtractPitchValues.n > 0)
# A 440 Hz tone should produce values near 440
if .t5_1_hasData
    @emlDescribe: emlExtractPitchValues.data#
    .t5_1_freq = (abs(emlDescribe.mean - 440) < 5)
else
    .t5_1_freq = 0
endif
.t5_1 = (.t5_1_hasData and .t5_1_freq)
@reportTest: "Pitch extraction (440 Hz tone)", .t5_1

# --- Test 5.2: Intensity extraction (refactored) ---
selectObject: testSound
testIntensity = To Intensity: 75, 0, "yes"
@emlExtractIntensityFrames: testIntensity
.t5_2_hasData = (emlExtractIntensityFrames.n > 0)
.t5_2_nTotal = (emlExtractIntensityFrames.nTotal > 0)
.t5_2_match = (emlExtractIntensityFrames.n = emlExtractIntensityFrames.nTotal)
.t5_2 = (.t5_2_hasData and .t5_2_nTotal and .t5_2_match)
@reportTest: "Intensity extraction (refactored, no Matrix)", .t5_2

# --- Test 5.3: Intensity values are reasonable ---
if emlExtractIntensityFrames.n > 0
    @emlDescribe: emlExtractIntensityFrames.data#
    # Intensity of a 0.4 amplitude tone should be in a sensible dB range
    .t5_3 = (emlDescribe.mean > 50 and emlDescribe.mean < 100)
else
    .t5_3 = 0
endif
@reportTest: "Intensity values in sensible dB range", .t5_3

# --- Test 5.4: Formant extraction ---
selectObject: testSound
testFormant = To Formant (burg): 0, 5, 5500, 0.025, 50
@emlExtractFormantValues: testFormant, 1, "hertz"
.t5_4 = (emlExtractFormantValues.n > 0 and emlExtractFormantValues.nTotal > 0)
@reportTest: "Formant extraction (F1)", .t5_4

# --- Test 5.5: Harmonicity extraction ---
selectObject: testSound
testHarmonicity = To Harmonicity (cc): 0.01, 75, 0.1, 1
@emlExtractHarmonicityFrames: testHarmonicity
.t5_5 = (emlExtractHarmonicityFrames.n > 0)
@reportTest: "Harmonicity extraction", .t5_5


# ──────────────────────────────────────────────────────────────────────────────
# TEST GROUP 6: Additional descriptive stats
# ──────────────────────────────────────────────────────────────────────────────

@emlReportSection: "6. Additional Descriptive Stats"

statData# = {2, 4, 4, 4, 5, 5, 7, 9}

# --- Test 6.1: Quartiles ---
@emlQuartiles: statData#
# Q2 (median) of 8 values: average of 4th and 5th = (4+5)/2 = 4.5
.t6_1_q2 = (abs(emlQuartiles.q2 - 4.5) < 0.01)
.t6_1 = .t6_1_q2
@reportTest: "Quartiles (Q2=4.5)", .t6_1

# --- Test 6.2: Percentile ---
@emlPercentile: statData#, 50
.t6_2 = (abs(emlPercentile.result - 4.5) < 0.01)
@reportTest: "50th percentile = median", .t6_2

# --- Test 6.3: SEM ---
@emlSEM: statData#
# sd of {2,4,4,4,5,5,7,9} = 2.138, sem = 2.138/sqrt(8) = 0.756
.t6_3 = (abs(emlSEM.result - 0.756) < 0.01)
@reportTest: "SEM", .t6_3

# --- Test 6.4: Confidence interval ---
@emlCI: statData#, 0.95
.t6_4 = (emlCI.lower < emlCI.upper and emlCI.lower <> undefined)
@reportTest: "95% CI (lower < upper)", .t6_4

# --- Test 6.5: Skewness ---
@emlSkewness: statData#
.t6_5 = (emlSkewness.result <> undefined)
@reportTest: "Skewness (defined)", .t6_5

# --- Test 6.6: Kurtosis ---
@emlKurtosis: statData#
.t6_6 = (emlKurtosis.result <> undefined)
@reportTest: "Kurtosis (defined)", .t6_6

# --- Test 6.7: MAD ---
@emlMAD: statData#
.t6_7 = (emlMAD.result <> undefined and emlMAD.result >= 0)
@reportTest: "MAD (non-negative)", .t6_7

# --- Test 6.8: Trimmed mean ---
@emlTrimmedMean: statData#, 0.1
.t6_8 = (emlTrimmedMean.result <> undefined)
@reportTest: "Trimmed mean (10%)", .t6_8


# ============================================================================
# SUMMARY
# ============================================================================

@emlReportSection: "Summary"

passStr$ = string$(testsPassed)
failStr$ = string$(testsFailed)
totalStr$ = string$(testsRun)
appendInfoLine: ""
summaryLine$ = "  " + passStr$ + " passed, " + failStr$ + " failed, " + totalStr$ + " total"
appendInfoLine: summaryLine$

if testsFailed = 0
    appendInfoLine: ""
    resultLine$ = "  ALL TESTS PASSED"
    appendInfoLine: resultLine$
else
    appendInfoLine: ""
    resultLine$ = "  SOME TESTS FAILED -- review output above"
    appendInfoLine: resultLine$
endif

@emlReportFooter

# Clean up test objects
removeObject: testTable, testSound, testPitch, testIntensity,
    ... testFormant, testHarmonicity

# Bridge the local counters into the shared harness so @emlTestSummary can
# emit the machine-readable sentinel (TEST RESULT REPORTING CONTRACT v1.1).
# This suite predates the shared helpers and keeps its own reportTest; only
# the summary is delegated. @emlTestSummary exitScript:s when failed > 0, so
# a failing run now exits nonzero instead of 0 — hence this runs AFTER the
# object cleanup above, not before it.
emlTestInit.passed = testsPassed
emlTestInit.failed = testsFailed
emlTestInit.skipped = 0
emlTestInit.count = testsRun
@emlTestSummary
