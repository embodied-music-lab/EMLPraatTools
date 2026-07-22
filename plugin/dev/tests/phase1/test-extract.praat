# ============================================================================
# EML Stats : Data Extraction Layer - Test Suite
# ============================================================================
# Module: test-extract.praat
# Version: 1.0
# Date: 20 February 2026
#
# Validation tests for eml-extract.praat
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# License: Creative Commons Share-Alike
# ============================================================================

# Include the extraction procedures
include ../../../stats/eml-extract.praat

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
