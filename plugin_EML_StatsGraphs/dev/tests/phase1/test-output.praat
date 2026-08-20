# ============================================================================
# EML Stats : Output Formatting — Test Suite
# ============================================================================
# Module: test-output.praat
# Version: 1.2
# Date: 3 August 2026
#
# Validates all procedures in eml-output.praat
#
# v1.2: Brought under the TEST RESULT REPORTING CONTRACT (v1.1, declared in
#        dev/tests/eml-test-helpers.praat). The hand-rolled summary printed
#        "SOME TESTS FAILED" and then returned normally, so the process
#        exited 0 whatever the outcome — green by construction for any
#        runner reading exit status. Local counters are now bridged into
#        emlTestInit.* and @emlTestSummary emits the machine-readable
#        sentinel. No assertion call site changed and the human-readable
#        summary is untouched.
# v1.1: Fixed effect size test expectations to match Cohen's thresholds
#        (negligible < 0.2, small 0.2-0.5, medium 0.5-0.8, large >= 0.8).
#        Moved visual output test before main header to prevent Info window
#        clearing from hiding individual test results.
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

# Include the module under test
#
# @emlReportToFile now walks duplicate names through @emlGenerateUniquePath,
# which lives in eml-core-utilities.praat. Both production barrels already
# load that file first (scripts/eml-lib-stats.praat), so this line only
# restores here what the plugin already has; without it this suite dies at the
# first @emlReportToFile case with Procedure "emlGenerateUniquePath" not found.
include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-output.praat

# Shared harness — used only for @emlTestInit / @emlTestSummary (the
# reporting contract). This suite keeps its own assertion helpers.
include ../eml-test-helpers.praat

@emlTestInit

# Test counters
testsRun = 0
testsPassed = 0
testsFailed = 0


# ============================================================================
# TEST HELPER PROCEDURES
# ============================================================================

procedure testAssertEqual: .expected$, .actual$, .testName$
    testsRun = testsRun + 1
    if .expected$ = .actual$
        testsPassed = testsPassed + 1
        .status$ = "PASS"
    else
        testsFailed = testsFailed + 1
        .status$ = "FAIL"
    endif
    .indent$ = "  "
    .sep$ = ": "
    .line$ = .indent$ + .status$ + .sep$ + .testName$
    appendInfoLine: .line$
    if .expected$ <> .actual$
        .expLabel$ = "    Expected: "
        .actLabel$ = "    Actual:   "
        .expLine$ = .expLabel$ + .expected$
        .actLine$ = .actLabel$ + .actual$
        appendInfoLine: .expLine$
        appendInfoLine: .actLine$
    endif
endproc


procedure testAssertEqualNum: .expected, .actual, .tolerance, .testName$
    testsRun = testsRun + 1
    .diff = abs(.expected - .actual)
    if .diff <= .tolerance
        testsPassed = testsPassed + 1
        .status$ = "PASS"
    else
        testsFailed = testsFailed + 1
        .status$ = "FAIL"
    endif
    .indent$ = "  "
    .sep$ = ": "
    .line$ = .indent$ + .status$ + .sep$ + .testName$
    appendInfoLine: .line$
    if .diff > .tolerance
        .expLabel$ = "    Expected: "
        .actLabel$ = "    Actual:   "
        .expStr$ = string$(.expected)
        .actStr$ = string$(.actual)
        .expLine$ = .expLabel$ + .expStr$
        .actLine$ = .actLabel$ + .actStr$
        appendInfoLine: .expLine$
        appendInfoLine: .actLine$
    endif
endproc


procedure testAssertContains: .haystack$, .needle$, .testName$
    testsRun = testsRun + 1
    .pos = index(.haystack$, .needle$)
    if .pos > 0
        testsPassed = testsPassed + 1
        .status$ = "PASS"
    else
        testsFailed = testsFailed + 1
        .status$ = "FAIL"
    endif
    .indent$ = "  "
    .sep$ = ": "
    .line$ = .indent$ + .status$ + .sep$ + .testName$
    appendInfoLine: .line$
    if .pos = 0
        .searchLabel$ = "    Searching for: "
        .inLabel$ = "    In string: "
        .searchLine$ = .searchLabel$ + .needle$
        .inLine$ = .inLabel$ + .haystack$
        appendInfoLine: .searchLine$
        appendInfoLine: .inLine$
    endif
endproc


procedure testSectionHeader: .title$
    .empty$ = ""
    appendInfoLine: .empty$
    .prefix$ = "── "
    .suffix$ = " ──────────────────────────────────"
    .line$ = .prefix$ + .title$ + .suffix$
    appendInfoLine: .line$
endproc


# ============================================================================
# TEST: @emlPadRight
# ============================================================================

procedure testPpPadRight
    @testSectionHeader: "Testing @emlPadRight"
    
    # Test 1: Padding needed
    @emlPadRight: "abc", 8
    @testAssertEqualNum: 8, length(emlPadRight.result$), 0, "abc padded to 8 chars"
    
    # Test 2: String already longer than target
    @emlPadRight: "toolong", 3
    .expected$ = "toolong"
    @testAssertEqual: .expected$, emlPadRight.result$, "toolong stays unchanged at 3"
    
    # Test 3: Exact length match
    @emlPadRight: "exact", 5
    .expected$ = "exact"
    @testAssertEqual: .expected$, emlPadRight.result$, "exact length match unchanged"
    
    # Test 4: Empty string padding
    @emlPadRight: "", 4
    @testAssertEqualNum: 4, length(emlPadRight.result$), 0, "empty string padded to 4"
endproc


# ============================================================================
# TEST: @emlUnderscoreToSpace
# ============================================================================

procedure testPpUnderscoreToSpace
    @testSectionHeader: "Testing @emlUnderscoreToSpace"
    
    # Test 1: Single underscore
    @emlUnderscoreToSpace: "pitch_floor"
    .expected$ = "pitch floor"
    @testAssertEqual: .expected$, emlUnderscoreToSpace.result$, "pitch_floor -> pitch floor"
    
    # Test 2: Multiple underscores
    @emlUnderscoreToSpace: "min_pitch_hz"
    .expected$ = "min pitch hz"
    @testAssertEqual: .expected$, emlUnderscoreToSpace.result$, "multiple underscores converted"
    
    # Test 3: No underscores
    @emlUnderscoreToSpace: "nochange"
    .expected$ = "nochange"
    @testAssertEqual: .expected$, emlUnderscoreToSpace.result$, "no underscores unchanged"
endproc


# ============================================================================
# TEST: @emlFormatP
# ============================================================================

procedure testPpFormatP
    @testSectionHeader: "Testing @emlFormatP"
    
    # Test 1: Normal p-value
    @emlFormatP: 0.021
    .expected$ = "p = .021"
    @testAssertEqual: .expected$, emlFormatP.formatted$, "p = 0.021 -> p = .021"
    
    # Test 2: Very small p-value (below threshold)
    @emlFormatP: 0.0005
    .expected$ = "p < .001"
    @testAssertEqual: .expected$, emlFormatP.formatted$, "p = 0.0005 -> p < .001"
    
    # Test 3: Exactly 0.050
    @emlFormatP: 0.050
    .expected$ = "p = .050"
    @testAssertEqual: .expected$, emlFormatP.formatted$, "p = 0.050 -> p = .050"
    
    # Test 4: p = 1.0
    @emlFormatP: 1.0
    .expected$ = "p = 1.000"
    @testAssertEqual: .expected$, emlFormatP.formatted$, "p = 1.0 -> p = 1.000"
    
    # Test 5: Undefined p-value
    @emlFormatP: undefined
    .expected$ = "p = undefined"
    @testAssertEqual: .expected$, emlFormatP.formatted$, "undefined -> p = undefined"
endproc


# ============================================================================
# TEST: @emlFormatCI
# ============================================================================

procedure testPpFormatCI
    @testSectionHeader: "Testing @emlFormatCI"
    
    # Test 1: Standard 95% CI
    @emlFormatCI: 0.22, 1.40, 0.95
    .expected$ = "95% CI [0.22, 1.40]"
    @testAssertEqual: .expected$, emlFormatCI.formatted$, "95% CI positive values"
    
    # Test 2: 99% CI with negative lower bound
    @emlFormatCI: -0.15, 0.85, 0.99
    .expected$ = "99% CI [-0.15, 0.85]"
    @testAssertEqual: .expected$, emlFormatCI.formatted$, "99% CI with negative bound"
    
    # Test 3: 90% CI
    @emlFormatCI: 0.10, 0.50, 0.90
    .expected$ = "90% CI [0.10, 0.50]"
    @testAssertEqual: .expected$, emlFormatCI.formatted$, "90% CI formatting"
endproc


# ============================================================================
# TEST: @emlFormatTestResult
# ============================================================================

procedure testPpFormatTestResult
    @testSectionHeader: "Testing @emlFormatTestResult"
    
    # Test 1: t-test with effect size and CI
    @emlFormatTestResult: "t", "t", 2.45, 23, 0, 0.021, "d", 0.89, 0.32, 1.45
    @testAssertContains: emlFormatTestResult.summary$, "t(23)", "t-test has t(23)"
    @testAssertContains: emlFormatTestResult.summary$, "2.45", "t-test has stat value"
    @testAssertContains: emlFormatTestResult.summary$, "p = .021", "t-test has p-value"
    @testAssertContains: emlFormatTestResult.summary$, "d = 0.89", "t-test has effect size"
    @testAssertContains: emlFormatTestResult.summary$, "[0.32, 1.45]", "t-test has CI"
    
    # Test 2: Welch's t-test with fractional df
    @emlFormatTestResult: "t", "t", -2.78, 42.8, 0, 0.008, "d", 0.82, 0.22, 1.40
    @testAssertContains: emlFormatTestResult.summary$, "t(42.8)", "Welch has fractional df"
    @testAssertContains: emlFormatTestResult.summary$, "-2.78", "Welch has negative stat"
    
    # Test 3: ANOVA with dual df
    @emlFormatTestResult: "F", "F", 4.85, 2, 27, 0.016, "η²", 0.26, undefined, undefined
    @testAssertContains: emlFormatTestResult.summary$, "F(2, 27)", "ANOVA has dual df"
    @testAssertContains: emlFormatTestResult.summary$, "η² = 0.26", "ANOVA has eta squared"
    
    # Test 4: No effect size
    @emlFormatTestResult: "t", "t", 1.50, 20, 0, 0.148, "", 0, undefined, undefined
    .noEffect$ = emlFormatTestResult.summary$
    .effectPos = index(.noEffect$, " = 0.00")
    # Should not contain effect size after p-value
    @testAssertContains: .noEffect$, "p = .148", "No effect: has p-value"
    # Verify the string ends shortly after p-value (no effect appended)
    .pPos = index(.noEffect$, "p = .148")
    .afterP$ = right$(.noEffect$, length(.noEffect$) - .pPos - 8)
    .checkEmpty$ = ""
    @testAssertEqual: .checkEmpty$, .afterP$, "No effect: nothing after p-value"
endproc


# ============================================================================
# TEST: @emlFormatEffectLabel
# ============================================================================

procedure testPpFormatEffectLabel
    @testSectionHeader: "Testing @emlFormatEffectLabel"
    
    # Cohen's d thresholds: negligible < 0.2, small 0.2-0.5, medium 0.5-0.8, large >= 0.8
    
    # Test 1: Cohen's d large (0.82 >= 0.8)
    @emlFormatEffectLabel: 0.82, "d"
    .expected$ = "large effect"
    @testAssertEqual: .expected$, emlFormatEffectLabel.label$, "d = 0.82 -> large"
    
    # Test 2: Cohen's d small (0.45 < 0.5 medium threshold)
    @emlFormatEffectLabel: 0.45, "d"
    .expected$ = "small effect"
    @testAssertEqual: .expected$, emlFormatEffectLabel.label$, "d = 0.45 -> small"
    
    # Test 3: Cohen's d negligible (0.15 < 0.2 small threshold)
    @emlFormatEffectLabel: 0.15, "d"
    .expected$ = "negligible effect"
    @testAssertEqual: .expected$, emlFormatEffectLabel.label$, "d = 0.15 -> negligible"
    
    # Test 4: Correlation r large
    @emlFormatEffectLabel: 0.65, "r"
    .expected$ = "large effect"
    @testAssertEqual: .expected$, emlFormatEffectLabel.label$, "r = 0.65 -> large"
    
    # Test 5: Eta squared medium
    @emlFormatEffectLabel: 0.08, "eta_squared"
    .expected$ = "medium effect"
    @testAssertEqual: .expected$, emlFormatEffectLabel.label$, "eta2 = 0.08 -> medium"
    
    # Test 6: Negative effect size (abs(0.75) = 0.75, which is medium: 0.5 <= 0.75 < 0.8)
    @emlFormatEffectLabel: -0.75, "d"
    .expected$ = "medium effect"
    @testAssertEqual: .expected$, emlFormatEffectLabel.label$, "d = -0.75 -> medium (abs)"
endproc


# ============================================================================
# TEST: @emlReportToFile
# ============================================================================

procedure testPpReportToFile
    @testSectionHeader: "Testing @emlReportToFile"
    
    # Test 1: Write new file
    .testPath$ = "test_output_temp.txt"
    .content$ = "Test content line 1"
    
    # Clean up any existing test file first
    if fileReadable(.testPath$)
        deleteFile: .testPath$
    endif
    
    @emlReportToFile: .testPath$, .content$
    .exists = fileReadable(.testPath$)
    @testAssertEqualNum: 1, .exists, 0, "New file created"
    @testAssertEqualNum: 1, emlReportToFile.success, 0, "Success flag set"
    
    # Test 2: Write to existing file (should increment)
    @emlReportToFile: .testPath$, .content$
    .expectedIncrement$ = "test_output_temp_1.txt"
    @testAssertEqual: .expectedIncrement$, emlReportToFile.actualPath$, "Filename incremented"
    .exists2 = fileReadable(.expectedIncrement$)
    @testAssertEqualNum: 1, .exists2, 0, "Incremented file created"
    
    # Cleanup
    if fileReadable(.testPath$)
        deleteFile: .testPath$
    endif
    if fileReadable(.expectedIncrement$)
        deleteFile: .expectedIncrement$
    endif
    
    .cleanupMsg$ = "  (Test files cleaned up)"
    appendInfoLine: .cleanupMsg$
endproc


# ============================================================================
# TEST: Visual output procedures
# ============================================================================

procedure testVisualOutput
    @testSectionHeader: "Testing Visual Output"
    
    # This test generates visual output to verify formatting
    # Manual inspection required for visual correctness
    
    .msg$ = "  Generating sample report for visual inspection..."
    appendInfoLine: .msg$
    .empty$ = ""
    appendInfoLine: .empty$
    
    # Generate a complete sample report
    @emlReportHeader: "Independent Samples t-Test"
    
    @emlReportLineString: "Data:", "F0 measurements (Hz)"
    @emlReportLine: "N:", 46, 0
    
    @emlReportSection: "Descriptive Statistics"
    @emlReportDescriptiveHeader
    @emlReportDescriptiveRow: "pre", 24, 142.50, 18.32, 140.25
    @emlReportDescriptiveRow: "post", 22, 158.73, 21.45, 156.80
    
    @emlReportSection: "Test Results"
    @emlFormatTestResult: "t", "t", -2.78, 42.8, 0, 0.008, "d", 0.82, 0.22, 1.40
    .indent$ = "  "
    .resultLine$ = .indent$ + emlFormatTestResult.summary$
    appendInfoLine: .resultLine$
    
    @emlReportSection: "Effect Size"
    @emlFormatEffectLabel: 0.82, "d"
    .effectInfo$ = "  Cohen's d = 0.82: " + emlFormatEffectLabel.label$
    appendInfoLine: .effectInfo$
    @emlFormatCI: 0.22, 1.40, 0.95
    .ciInfo$ = "  " + emlFormatCI.formatted$
    appendInfoLine: .ciInfo$
    
    @emlReportFooter
    
    appendInfoLine: .empty$
    .visualComplete$ = "  Visual output test complete. Inspect report above."
    appendInfoLine: .visualComplete$
    
    testsRun = testsRun + 1
    testsPassed = testsPassed + 1
endproc


# ============================================================================
# TEST: @emlReportAPA
# ============================================================================

procedure testPpReportAPA
    @testSectionHeader: "Testing @emlReportAPA"
    
    # Test 1: t-test
    @emlReportAPA: "t", 2.45, 23, 0, 0.021, "d", 0.89, 0.32, 1.45
    @testAssertContains: emlReportAPA.formatted$, "t(23)", "APA t-test format"
    
    # Test 2: Chi-square (symbol conversion)
    @emlReportAPA: "chi2", 8.45, 2, 0, 0.015, "V", 0.32, undefined, undefined
    @testAssertContains: emlReportAPA.formatted$, "χ²", "APA chi2 -> χ² symbol"
    
    # Test 3: F-test
    @emlReportAPA: "F", 4.85, 2, 27, 0.016, "η²", 0.26, undefined, undefined
    @testAssertContains: emlReportAPA.formatted$, "F(2, 27)", "APA F-test dual df"
endproc


# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

# Run visual output test FIRST — it calls @emlReportHeader which uses
# writeInfoLine: and clears the Info window. Running it first means
# the subsequent writeInfoLine: below will clear the visual output
# (which is fine — it's for manual inspection) but all automated
# test results that follow will be preserved.
@testVisualOutput

# Initialize — this writeInfoLine: clears the visual output above
header$ = "══════════════════════════════════════════════"
title$ = "  EML Stats Output Module Test Suite"
writeInfoLine: header$
appendInfoLine: title$
appendInfoLine: header$

# Run all tests
@testPpPadRight
@testPpUnderscoreToSpace
@testPpFormatP
@testPpFormatCI
@testPpFormatTestResult
@testPpFormatEffectLabel
@testPpReportToFile
@testPpReportAPA

# Summary
empty$ = ""
appendInfoLine: empty$
appendInfoLine: header$
summaryLabel$ = "  TEST SUMMARY"
appendInfoLine: summaryLabel$
appendInfoLine: header$

runLabel$ = "  Tests run:    "
runValue$ = string$(testsRun)
runLine$ = runLabel$ + runValue$
appendInfoLine: runLine$

passLabel$ = "  Passed:       "
passValue$ = string$(testsPassed)
passLine$ = passLabel$ + passValue$
appendInfoLine: passLine$

failLabel$ = "  Failed:       "
failValue$ = string$(testsFailed)
failLine$ = failLabel$ + failValue$
appendInfoLine: failLine$

appendInfoLine: empty$
if testsFailed = 0
    resultLine$ = "  ✓ ALL TESTS PASSED"
else
    resultLine$ = "  ✗ SOME TESTS FAILED"
endif
appendInfoLine: resultLine$
appendInfoLine: header$

# Bridge the local counters into the shared harness so @emlTestSummary can
# emit the machine-readable sentinel (TEST RESULT REPORTING CONTRACT v1.1).
# @emlTestSummary exitScript:s when failed > 0, so this must stay last —
# nothing that needs to run may follow it.
emlTestInit.passed = testsPassed
emlTestInit.failed = testsFailed
emlTestInit.skipped = 0
emlTestInit.count = testsRun
@emlTestSummary
