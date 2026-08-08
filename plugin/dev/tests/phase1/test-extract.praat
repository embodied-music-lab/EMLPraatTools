# ============================================================================
# EML Stats : Data Extraction Layer - Test Suite
# ============================================================================
# Module: test-extract.praat
# Version: 1.1
# Date: 3 August 2026
#
# Validation tests for eml-extract.praat
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

# Include the extraction procedures
include ../../../stats/eml-extract.praat

# Shared harness — used only for @emlTestInit / @emlTestSummary (the
# reporting contract). This suite keeps its own assertion helpers.
include ../eml-test-helpers.praat

@emlTestInit

# ============================================================================
# Test infrastructure
# ============================================================================
testsPassed = 0
testsFailed = 0
tolerance = 0.0001
tolerancePitch = 5

procedure reportTest: .name$, .passed
    if .passed
        testsPassed = testsPassed + 1
        .msg$ = "  PASS: "
        .msg$ = .msg$ + .name$
        appendInfoLine: .msg$
    else
        testsFailed = testsFailed + 1
        .msg$ = "  FAIL: "
        .msg$ = .msg$ + .name$
        appendInfoLine: .msg$
    endif
endproc

procedure assertEqualNum: .testName$, .expected, .actual, .tol
    .diff = abs(.expected - .actual)
    .passed = .diff <= .tol
    @reportTest: .testName$, .passed
    if not .passed
        .msg1$ = "    Expected: "
        appendInfoLine: .msg1$, .expected
        .msg2$ = "    Actual: "
        appendInfoLine: .msg2$, .actual
    endif
endproc

procedure assertEqualStr: .testName$, .expected$, .actual$
    .passed = .expected$ = .actual$
    @reportTest: .testName$, .passed
    if not .passed
        .msg1$ = "    Expected: "
        .msg1$ = .msg1$ + .expected$
        appendInfoLine: .msg1$
        .msg2$ = "    Actual: "
        .msg2$ = .msg2$ + .actual$
        appendInfoLine: .msg2$
    endif
endproc

procedure assertTrue: .testName$, .condition
    @reportTest: .testName$, .condition
endproc

# ============================================================================
# Create Test Objects
# ============================================================================
appendInfoLine: "Creating test objects..."
appendInfoLine: ""

# --- Test Table 1: Basic extraction tests ---
# 5 rows: participant (1-5), F0 (120.5, 135.2, 142.8, 128.9, 155.3), condition (pre/post)
testTable1 = Create Table with column names: "testTable1", 5, "participant F0 condition"

selectObject: testTable1
Set numeric value: 1, "participant", 1
Set numeric value: 2, "participant", 2
Set numeric value: 3, "participant", 3
Set numeric value: 4, "participant", 4
Set numeric value: 5, "participant", 5

selectObject: testTable1
Set numeric value: 1, "F0", 120.5
Set numeric value: 2, "F0", 135.2
Set numeric value: 3, "F0", 142.8
Set numeric value: 4, "F0", 128.9
Set numeric value: 5, "F0", 155.3

selectObject: testTable1
Set string value: 1, "condition", "pre"
Set string value: 2, "condition", "pre"
Set string value: 3, "condition", "post"
Set string value: 4, "condition", "pre"
Set string value: 5, "condition", "post"

# --- Test Table 2: Multiple groups (A/B/C) ---
# 9 rows, 3 groups, values 10-90
testTable2 = Create Table with column names: "testTable2", 9, "group value"

selectObject: testTable2
Set string value: 1, "group", "A"
Set numeric value: 1, "value", 10
Set string value: 2, "group", "A"
Set numeric value: 2, "value", 20
Set string value: 3, "group", "A"
Set numeric value: 3, "value", 30
Set string value: 4, "group", "B"
Set numeric value: 4, "value", 40
Set string value: 5, "group", "B"
Set numeric value: 5, "value", 50
Set string value: 6, "group", "B"
Set numeric value: 6, "value", 60
Set string value: 7, "group", "C"
Set numeric value: 7, "value", 70
Set string value: 8, "group", "C"
Set numeric value: 8, "value", 80
Set string value: 9, "group", "C"
Set numeric value: 9, "value", 90

# --- Test Table 3: Paired data ---
testTable3 = Create Table with column names: "testTable3", 4, "pre post"

selectObject: testTable3
Set numeric value: 1, "pre", 100
Set numeric value: 2, "pre", 105
Set numeric value: 3, "pre", 98
Set numeric value: 4, "pre", 112

selectObject: testTable3
Set numeric value: 1, "post", 110
Set numeric value: 2, "post", 115
Set numeric value: 3, "post", 108
Set numeric value: 4, "post", 120

# --- Test Pitch object: pure tone at 200 Hz ---
# Create a 1-second sound at 200 Hz
testSound = Create Sound from formula: "testTone", 1, 0, 1, 44100, "sin(2*pi*200*x)"

selectObject: testSound
testPitch = To Pitch: 0.0, 75, 600

# --- Test Formant object ---
# Use a vowel-like sound for formant testing
testVowelSound = Create Sound from formula: "testVowel", 1, 0, 0.5, 44100, "sin(2*pi*500*x) + 0.5*sin(2*pi*1500*x)"

selectObject: testVowelSound
testFormant = To Formant (burg): 0.0, 5, 5500, 0.025, 50

# --- Test Intensity object ---
selectObject: testSound
testIntensity = To Intensity: 100, 0, "yes"

# --- Test Harmonicity object ---
selectObject: testSound
testHarmonicity = To Harmonicity (cc): 0.01, 75, 0.1, 1.0

appendInfoLine: "Test objects created."
appendInfoLine: ""

# ============================================================================
# Test @emlExtractColumn
# ============================================================================
appendInfoLine: "Testing @emlExtractColumn..."

@emlExtractColumn: testTable1, "F0"
@assertEqualNum: "emlExtractColumn - correct count", 5, emlExtractColumn.n, 0
@assertEqualNum: "emlExtractColumn - value 1", 120.5, emlExtractColumn.data#[1], tolerance
@assertEqualNum: "emlExtractColumn - value 3", 142.8, emlExtractColumn.data#[3], tolerance
@assertEqualNum: "emlExtractColumn - value 5", 155.3, emlExtractColumn.data#[5], tolerance
@assertEqualNum: "emlExtractColumn - no undefined", 0, emlExtractColumn.nUndefined, 0

# Test missing column
@emlExtractColumn: testTable1, "nonexistent"
@assertEqualNum: "emlExtractColumn - missing column n=0", 0, emlExtractColumn.n, 0
@assertTrue: "emlExtractColumn - missing column has error", emlExtractColumn.error$ <> ""

appendInfoLine: ""

# ============================================================================
# Test @emlExtractColumnAsStrings
# ============================================================================
appendInfoLine: "Testing @emlExtractColumnAsStrings..."

@emlExtractColumnAsStrings: testTable1, "condition"
@assertEqualNum: "emlExtractColumnAsStrings - correct count", 5, emlExtractColumnAsStrings.n, 0
@assertEqualStr: "emlExtractColumnAsStrings - value 1", "pre", emlExtractColumnAsStrings.str$[1]
@assertEqualStr: "emlExtractColumnAsStrings - value 3", "post", emlExtractColumnAsStrings.str$[3]
@assertEqualStr: "emlExtractColumnAsStrings - value 5", "post", emlExtractColumnAsStrings.str$[5]

appendInfoLine: ""

# ============================================================================
# Test @emlExtractGroupVectors
# ============================================================================
appendInfoLine: "Testing @emlExtractGroupVectors..."

@emlExtractGroupVectors: testTable1, "F0", "condition", "pre", "post"
@assertEqualNum: "emlExtractGroupVectors - pre count", 3, emlExtractGroupVectors.n1, 0
@assertEqualNum: "emlExtractGroupVectors - post count", 2, emlExtractGroupVectors.n2, 0
@assertEqualNum: "emlExtractGroupVectors - no excluded", 0, emlExtractGroupVectors.nExcluded, 0

# Check pre group values (rows 1, 2, 4)
@assertEqualNum: "emlExtractGroupVectors - pre value 1", 120.5, emlExtractGroupVectors.group1#[1], tolerance
@assertEqualNum: "emlExtractGroupVectors - pre value 2", 135.2, emlExtractGroupVectors.group1#[2], tolerance
@assertEqualNum: "emlExtractGroupVectors - pre value 3", 128.9, emlExtractGroupVectors.group1#[3], tolerance

# Check post group values (rows 3, 5)
@assertEqualNum: "emlExtractGroupVectors - post value 1", 142.8, emlExtractGroupVectors.group2#[1], tolerance
@assertEqualNum: "emlExtractGroupVectors - post value 2", 155.3, emlExtractGroupVectors.group2#[2], tolerance

appendInfoLine: ""

# ============================================================================
# Test @eml_getGroupData
# ============================================================================
appendInfoLine: "Testing @eml_getGroupData..."

# Group A: should get [10, 20, 30]
@eml_getGroupData: testTable2, "value", "group", "A"
@assertEqualNum: "eml_getGroupData - A count", 3, eml_getGroupData.n, 0
@assertEqualNum: "eml_getGroupData - A val 1", 10, eml_getGroupData.data#[1], tolerance
@assertEqualNum: "eml_getGroupData - A val 2", 20, eml_getGroupData.data#[2], tolerance
@assertEqualNum: "eml_getGroupData - A val 3", 30, eml_getGroupData.data#[3], tolerance

# Group C: should get [70, 80, 90]
@eml_getGroupData: testTable2, "value", "group", "C"
@assertEqualNum: "eml_getGroupData - C count", 3, eml_getGroupData.n, 0
@assertEqualNum: "eml_getGroupData - C val 1", 70, eml_getGroupData.data#[1], tolerance
@assertEqualNum: "eml_getGroupData - C val 3", 90, eml_getGroupData.data#[3], tolerance

# Nonexistent group: should get 0
@eml_getGroupData: testTable2, "value", "group", "Z"
@assertEqualNum: "eml_getGroupData - missing group n=0", 0, eml_getGroupData.n, 0

appendInfoLine: ""

# ============================================================================
# Test @emlExtractPairedColumns
# ============================================================================
appendInfoLine: "Testing @emlExtractPairedColumns..."

@emlExtractPairedColumns: testTable3, "pre", "post"
@assertEqualNum: "emlExtractPairedColumns - 4 pairs", 4, emlExtractPairedColumns.n, 0
@assertEqualNum: "emlExtractPairedColumns - no excluded", 0, emlExtractPairedColumns.nExcludedRows, 0

@assertEqualNum: "emlExtractPairedColumns - pre val 1", 100, emlExtractPairedColumns.data1#[1], tolerance
@assertEqualNum: "emlExtractPairedColumns - pre val 4", 112, emlExtractPairedColumns.data1#[4], tolerance
@assertEqualNum: "emlExtractPairedColumns - post val 1", 110, emlExtractPairedColumns.data2#[1], tolerance
@assertEqualNum: "emlExtractPairedColumns - post val 4", 120, emlExtractPairedColumns.data2#[4], tolerance

appendInfoLine: ""

# ============================================================================
# Test @emlExtractPitchValues
# ============================================================================
appendInfoLine: "Testing @emlExtractPitchValues..."

@emlExtractPitchValues: testPitch, "Hertz"

@assertTrue: "emlExtractPitchValues - found voiced frames", emlExtractPitchValues.n > 0
@assertTrue: "emlExtractPitchValues - has total frames", emlExtractPitchValues.nTotal > 0

# Check that extracted values are near 200 Hz
if emlExtractPitchValues.n > 0
    .sampleVal = emlExtractPitchValues.data#[1]
    .pitchDiff = abs(.sampleVal - 200)
    @assertTrue: "emlExtractPitchValues - value near 200 Hz", .pitchDiff < tolerancePitch
    
    # Check middle value too
    .midIdx = ceiling(emlExtractPitchValues.n / 2)
    .midVal = emlExtractPitchValues.data#[.midIdx]
    .midDiff = abs(.midVal - 200)
    @assertTrue: "emlExtractPitchValues - mid value near 200 Hz", .midDiff < tolerancePitch
endif

appendInfoLine: ""

# ============================================================================
# Test @emlExtractFormantValues
# ============================================================================
appendInfoLine: "Testing @emlExtractFormantValues..."

@emlExtractFormantValues: testFormant, 1, "hertz"

@assertTrue: "emlExtractFormantValues - found frames", emlExtractFormantValues.n > 0
@assertTrue: "emlExtractFormantValues - has total frames", emlExtractFormantValues.nTotal > 0
@assertTrue: "emlExtractFormantValues - has times", size(emlExtractFormantValues.times#) > 0
@assertTrue: "emlExtractFormantValues - has bandwidths", size(emlExtractFormantValues.bandwidths#) > 0

# F1 should be present (exact value depends on Praat analysis)
if emlExtractFormantValues.n > 0
    @assertTrue: "emlExtractFormantValues - F1 value positive", emlExtractFormantValues.data#[1] > 0
endif

appendInfoLine: ""

# ============================================================================
# Test @emlExtractIntensityFrames
# ============================================================================
appendInfoLine: "Testing @emlExtractIntensityFrames..."

@emlExtractIntensityFrames: testIntensity

@assertTrue: "emlExtractIntensityFrames - found frames", emlExtractIntensityFrames.n > 0
@assertTrue: "emlExtractIntensityFrames - has times", size(emlExtractIntensityFrames.times#) > 0
@assertTrue: "emlExtractIntensityFrames - data same size as n", size(emlExtractIntensityFrames.data#) = emlExtractIntensityFrames.n

# Intensity values should be reasonable (dB scale)
if emlExtractIntensityFrames.n > 0
    .intVal = emlExtractIntensityFrames.data#[1]
    @assertTrue: "emlExtractIntensityFrames - reasonable dB value", .intVal > 0 and .intVal < 120
endif

appendInfoLine: ""

# ============================================================================
# Test @emlExtractHarmonicityFrames
# ============================================================================
appendInfoLine: "Testing @emlExtractHarmonicityFrames..."

@emlExtractHarmonicityFrames: testHarmonicity

@assertTrue: "emlExtractHarmonicityFrames - has total", emlExtractHarmonicityFrames.nTotal > 0

# Pure tone should have high HNR in most frames
if emlExtractHarmonicityFrames.n > 0
    @assertTrue: "emlExtractHarmonicityFrames - found defined frames", emlExtractHarmonicityFrames.n > 0
    @assertTrue: "emlExtractHarmonicityFrames - has times", size(emlExtractHarmonicityFrames.times#) = emlExtractHarmonicityFrames.n
endif

appendInfoLine: ""

# ============================================================================
# Test @emlValidateTable
# ============================================================================
appendInfoLine: "Testing @emlValidateTable..."

# Test with existing columns
@emlValidateTable: testTable1, "participant F0 condition"
@assertEqualNum: "emlValidateTable - valid with all cols", 1, emlValidateTable.valid, 0
@assertEqualStr: "emlValidateTable - no message when valid", "", emlValidateTable.message$
@assertEqualNum: "emlValidateTable - correct row count", 5, emlValidateTable.nRows, 0
@assertEqualNum: "emlValidateTable - correct col count", 3, emlValidateTable.nCols, 0

# Test with missing column
@emlValidateTable: testTable1, "participant F0 missing"
@assertEqualNum: "emlValidateTable - invalid with missing col", 0, emlValidateTable.valid, 0
@assertTrue: "emlValidateTable - has error message", emlValidateTable.message$ <> ""

appendInfoLine: ""

# ============================================================================
# Test @emlValidateNumericColumn
# ============================================================================
appendInfoLine: "Testing @emlValidateNumericColumn..."

# Test numeric column
@emlValidateNumericColumn: testTable1, "F0"
@assertEqualNum: "emlValidateNumericColumn - F0 valid", 1, emlValidateNumericColumn.valid, 0
@assertEqualNum: "emlValidateNumericColumn - F0 total", 5, emlValidateNumericColumn.nTotal, 0
@assertEqualNum: "emlValidateNumericColumn - F0 numeric", 5, emlValidateNumericColumn.nNumeric, 0
@assertEqualNum: "emlValidateNumericColumn - F0 no missing", 0, emlValidateNumericColumn.nMissing, 0

# Test missing column
@emlValidateNumericColumn: testTable1, "nonexistent"
@assertEqualNum: "emlValidateNumericColumn - missing col invalid", 0, emlValidateNumericColumn.valid, 0

appendInfoLine: ""

# ============================================================================
# Test @emlTableColumnNames
# ============================================================================
appendInfoLine: "Testing @emlTableColumnNames..."

@emlTableColumnNames: testTable1
@assertEqualNum: "emlTableColumnNames - 3 columns", 3, emlTableColumnNames.nCols, 0
@assertEqualStr: "emlTableColumnNames - col 1", "participant", emlTableColumnNames.name$[1]
@assertEqualStr: "emlTableColumnNames - col 2", "F0", emlTableColumnNames.name$[2]
@assertEqualStr: "emlTableColumnNames - col 3", "condition", emlTableColumnNames.name$[3]

appendInfoLine: ""

# ============================================================================
# Test @emlCountGroups
# ============================================================================
appendInfoLine: "Testing @emlCountGroups..."

# Test with Table 1 (2 groups)
@emlCountGroups: testTable1, "condition"
@assertEqualNum: "emlCountGroups - 2 conditions", 2, emlCountGroups.nGroups, 0
# Note: order depends on first occurrence
@assertTrue: "emlCountGroups - has pre label", emlCountGroups.groupLabel$[1] = "pre" or emlCountGroups.groupLabel$[2] = "pre"
@assertTrue: "emlCountGroups - has post label", emlCountGroups.groupLabel$[1] = "post" or emlCountGroups.groupLabel$[2] = "post"

# Test with Table 2 (3 groups)
@emlCountGroups: testTable2, "group"
@assertEqualNum: "emlCountGroups - 3 groups", 3, emlCountGroups.nGroups, 0
@assertEqualStr: "emlCountGroups - group A", "A", emlCountGroups.groupLabel$[1]
@assertEqualStr: "emlCountGroups - group B", "B", emlCountGroups.groupLabel$[2]
@assertEqualStr: "emlCountGroups - group C", "C", emlCountGroups.groupLabel$[3]

# Verify per-group sizes via @eml_getGroupData
@eml_getGroupData: testTable2, "value", "group", "A"
@assertEqualNum: "emlCountGroups + getGroupData - A size", 3, eml_getGroupData.n, 0
@eml_getGroupData: testTable2, "value", "group", "B"
@assertEqualNum: "emlCountGroups + getGroupData - B size", 3, eml_getGroupData.n, 0
@eml_getGroupData: testTable2, "value", "group", "C"
@assertEqualNum: "emlCountGroups + getGroupData - C size", 3, eml_getGroupData.n, 0

appendInfoLine: ""

# ============================================================================
# Cleanup Test Objects
# ============================================================================
appendInfoLine: "Cleaning up test objects..."

removeObject: testTable1
removeObject: testTable2
removeObject: testTable3
removeObject: testSound
removeObject: testPitch
removeObject: testVowelSound
removeObject: testFormant
removeObject: testIntensity
removeObject: testHarmonicity

appendInfoLine: "Cleanup complete."
appendInfoLine: ""

# ============================================================================
# D96 — the classifying parse helper
# ============================================================================
# "Get value:" answers a narrower question than a user asks. These assert the
# five kinds are told apart, and — the part that matters — that the row-wise
# and column-wise readers give the SAME account of the same cell. Before the
# D96 work they did not: "1,5" entered a column mean as 1 and was counted as
# a present value by the paired reader.

@emlTestSection: "D96 — cell classification"

@eml_classifyCell: "70.1"
@assertEqualNum: "D96 plain decimal is kind 0", 0, eml_classifyCell.kind, 0
@eml_classifyCell: "-3.5"
@assertEqualNum: "D96 signed decimal is kind 0", 0, eml_classifyCell.kind, 0
@eml_classifyCell: "  62.4  "
@assertEqualNum: "D96 surrounding space does not change the kind",
... 0, eml_classifyCell.kind, 0
@eml_classifyCell: ""
@assertEqualNum: "D96 empty cell is kind 1", 1, eml_classifyCell.kind, 0
@eml_classifyCell: "   "
@assertEqualNum: "D96 whitespace-only cell is kind 1", 1, eml_classifyCell.kind, 0
@eml_classifyCell: "--undefined--"
@assertEqualNum: "D96 Praat's own undefined literal is kind 1",
... 1, eml_classifyCell.kind, 0
@eml_classifyCell: "1,5"
@assertEqualNum: "D96 decimal comma is kind 2", 2, eml_classifyCell.kind, 0
@assertEqualNum: "D96 decimal comma recovers 1.5", 1.5,
... eml_classifyCell.recovered, tolerance
@eml_classifyCell: "n/a"
@assertEqualNum: "D96 text is kind 3", 3, eml_classifyCell.kind, 0
@eml_classifyCell: "1/2"
@assertEqualNum: "D96 fraction is kind 4", 4, eml_classifyCell.kind, 0
@eml_classifyCell: "2 3"
@assertEqualNum: "D96 internal space is kind 4", 4, eml_classifyCell.kind, 0
@eml_classifyCell: "30%"
@assertEqualNum: "D96 percent is kind 4, not kind 0", 4,
... eml_classifyCell.kind, 0
@eml_classifyCell: "1.234,5"
@assertEqualNum: "D96 thousands dot with decimal comma is kind 4", 4,
... eml_classifyCell.kind, 0
@eml_classifyCell: ".5"
@assertEqualNum: "D96 bare leading point is kind 5", 5, eml_classifyCell.kind, 0
@assertEqualNum: "D96 bare leading point recovers 0.5", 0.5,
... eml_classifyCell.recovered, tolerance
@eml_classifyCell: "-.5"
@assertEqualNum: "D96 signed bare leading point is kind 5", 5,
... eml_classifyCell.kind, 0
@assertEqualNum: "D96 signed bare leading point recovers -0.5", -0.5,
... eml_classifyCell.recovered, tolerance

@emlTestSection: "D96 — one account of the same cell, row-wise and column-wise"

d96t = Create Table with column names: "d96", 5, "pre post"
d96pre$ [1] = "10.0"
d96pre$ [2] = "11.0"
d96pre$ [3] = "12,5"
d96pre$ [4] = "13.0"
d96pre$ [5] = "20.0"
d96post$ [1] = "12.0"
d96post$ [2] = "13.0"
d96post$ [3] = "14.0"
d96post$ [4] = ""
d96post$ [5] = "16.0"
for d96i from 1 to 5
    selectObject: d96t
    Set string value: d96i, "pre", d96pre$ [d96i]
    Set string value: d96i, "post", d96post$ [d96i]
endfor

@emlExtractColumn: d96t, "pre"
@assertEqualNum: "D96 column reader keeps 4 of 5 in pre", 4,
... emlExtractColumn.n, 0
@assertEqualNum: "D96 column reader attributes the drop to a decimal comma",
... 1, emlExtractColumn.nLocale, 0
@assertTrue: "D96 column reader names the offending value",
... index (emlExtractColumn.note$, "12,5") > 0
@assertTrue: "D96 the excluded comma value is NOT in the data",
... emlExtractColumn.n = size (emlExtractColumn.data#)
# The fixture's last value is 20 and not 14 for a reason. With 14 the two
# readings give the SAME mean -- 12 either way -- so the check would pass
# whether or not the comma cell was excluded, which is worse than no check.
# With 20 the clean mean is 13.5 and the coerced mean is 13.2, and the two
# assertions below can only both hold under the corrected behaviour.
@assertEqualNum: "D96 pre mean is over the clean values only",
... 13.5, mean (emlExtractColumn.data#), tolerance
@assertTrue: "D96 and is NOT the mean coercing 12,5 to 12 would give",
... abs (mean (emlExtractColumn.data#) - 13.2) > 0.01

@emlExtractColumn: d96t, "post"
@assertEqualNum: "D96 column reader keeps 4 of 5 in post", 4,
... emlExtractColumn.n, 0
@assertEqualNum: "D96 and calls the post drop an empty cell", 1,
... emlExtractColumn.nEmpty, 0
@assertEqualNum: "D96 which is not a locale problem", 0,
... emlExtractColumn.nLocale, 0

@emlExtractPairedColumns: d96t, "pre", "post"
@assertEqualNum: "D96 row-wise reader keeps 3 complete pairs", 3,
... emlExtractPairedColumns.n, 0
@assertEqualNum: "D96 row-wise reader excludes 2 rows", 2,
... emlExtractPairedColumns.nExcludedRows, 0
@assertTrue: "D96 row-wise x agrees with the column-wise reading",
... emlExtractPairedColumns.data1# [1] = 10 and
... emlExtractPairedColumns.data1# [2] = 11 and
... emlExtractPairedColumns.data1# [3] = 20

removeObject: d96t

# A clean column must take the fast path and be untouched by any of this.
d96c = Create Table with column names: "d96clean", 4, "v"
for d96i from 1 to 4
    selectObject: d96c
    Set numeric value: d96i, "v", 10 + d96i / 4
endfor
@emlExtractColumn: d96c, "v"
@assertEqualNum: "D96 clean column keeps every row", 4, emlExtractColumn.n, 0
@assertEqualNum: "D96 clean column excludes nothing", 0,
... emlExtractColumn.nUndefined, 0
@assertEqualStr: "D96 clean column produces no note", "",
... emlExtractColumn.note$
@assertEqualNum: "D96 clean column values are unaltered", 10.25,
... emlExtractColumn.data# [1], tolerance
removeObject: d96c

totalTests = testsPassed + testsFailed

# ============================================================================
# Final Summary
# ============================================================================
appendInfoLine: "============================================"
appendInfoLine: "TEST SUMMARY"
appendInfoLine: "============================================"
totalTests = testsPassed + testsFailed
.msg$ = "Total tests: "
appendInfoLine: .msg$, totalTests
.msg$ = "Passed: "
appendInfoLine: .msg$, testsPassed
.msg$ = "Failed: "
appendInfoLine: .msg$, testsFailed

if testsFailed = 0
    appendInfoLine: ""
    appendInfoLine: "ALL TESTS PASSED"
else
    appendInfoLine: ""
    appendInfoLine: "SOME TESTS FAILED - Review output above"
endif

appendInfoLine: "============================================"

# Bridge the local counters into the shared harness so @emlTestSummary can
# emit the machine-readable sentinel (TEST RESULT REPORTING CONTRACT v1.1).
# @emlTestSummary exitScript:s when failed > 0, so this must stay last, and
# in particular after the removeObject: cleanup above.
emlTestInit.passed = testsPassed
emlTestInit.failed = testsFailed
emlTestInit.skipped = 0
emlTestInit.count = totalTests
@emlTestSummary
