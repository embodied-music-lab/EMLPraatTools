# ============================================================================
# EML Stats : Test Helpers
# ============================================================================
# Module: eml-test-helpers.praat
# Version: 1.2
# Date: 3 August 2026
#
# Part of the EML Stats library (EML Praat Tools).
# License: GPL-3.0-or-later
#
# Provides: @emlTestInit, @emlTestSection, @emlTestAssertTrue,
#   @emlTestAssertEqualNum, @emlTestAssertEqualRel, @emlTestAssertEqualStr,
#   @emlTestAssertUndefined, @emlTestAssertVectorsEqual,
#   @emlTestAssertContains, @emlTestSkip, @emlTestSummary
#
# Unified test assertion library for all EML Stats test suites.
# Replaces the ad-hoc test helpers in Phase 1 test files.
#
# Usage:
#   include eml-test-helpers.praat
#   @emlTestInit
#   @emlTestSection: "My tests"
#   @emlTestAssertTrue: "something is true", 1
#   @emlTestAssertEqualNum: "values match", 3.14, 3.14, 0.001
#   @emlTestAssertEqualRel: "p matches R", 2.4493583828e-09, p, 1e-5
#   @emlTestSkip: "case needs a reference we cannot compute", "no dunn.test"
#   @emlTestSummary
#
# State management:
#   All assertion procedures increment counters stored as persistent
#   local variables in @emlTestInit (.passed, .failed, .skipped, .count).
#   These are accessed cross-procedure as emlTestInit.passed, etc.
#
# ----------------------------------------------------------------------------
# RESULT REPORTING CONTRACT (v1.1)
# ----------------------------------------------------------------------------
# Three outcomes must be distinguishable by an automated runner:
#
#   PASS       - every declared check ran and passed
#   FAIL       - at least one check failed
#   INCOMPLETE - no failures, but at least one check was SKIPPED
#
# Praat's process exit status cannot carry three values. Empirically
# (Praat 6.4.x, --run, Linux):
#
#   clean completion   -> exit 0
#   exitScript: "..."  -> exit 255
#   failed `assert`    -> exit 255
#
# There is no mechanism to return any other status. The contract is
# therefore split across two channels:
#
#   exit status  - binary only. 0 = no failures, 255 = at least one failure.
#   stdout       - a machine-readable sentinel line emitted by @emlTestSummary:
#
#       EMLTEST-RESULT: status=PASS passed=57 failed=0 skipped=0 total=57
#
#     status is PASS, FAIL, or INCOMPLETE. A runner parses this line to
#     recover the third state; the exit status alone cannot express it.
#
# WHY THIS CHANGED
#   In v1.0 @emlTestSummary printed "SOME TESTS FAILED" and then returned
#   normally, so the process exited 0. Every suite in this repository
#   reported success to any exit-status-driven runner no matter how many
#   assertions failed. A runner built on v1.0 would have been green by
#   construction. v1.1 calls exitScript: when .failed > 0, after the
#   sentinel line has been printed, so the failure reaches both channels.
#
#   Suites that pass are unaffected: they still complete cleanly and exit 0.
#   The change is therefore backwards-compatible for green runs and only
#   alters behaviour for runs that were lying.
#
# A runner MUST NOT treat "exit 0" as sufficient evidence of a green suite:
# a suite that exits 0 with skipped > 0 is INCOMPLETE, not PASS. Parse the
# sentinel. Absence of the sentinel means the suite died before reaching
# @emlTestSummary and must be treated as FAIL, not PASS.
#
# ----------------------------------------------------------------------------
# ASSERTION VACUITY (v1.2)
# ----------------------------------------------------------------------------
# An absolute-tolerance assertion whose NONZERO expected value is smaller
# than its own tolerance cannot distinguish the true value from zero. It
# passes whatever the library returns inside the band, so it is a false green
# even though the suite exits 0 and the sentinel says PASS. Real example from
# the pre-1.2 tree (test-inferential-batch6.praat):
#
#   @emlTestAssertEqualNum: "4 Treatment p", 0.0000000002, ... , 0.000001
#
# The expected value is 1/5000 of the tolerance. A library returning exactly
# 0.0 — or 1e-7, or 9e-7 — passes this check.
#
# @emlTestAssertEqualRel closes the class by construction: a relative
# tolerance scales with the expected value, so it cannot be vacuous for any
# nonzero expected value. Use it for p-values, effect sizes, and any
# statistic whose magnitude is not known in advance to be order 1.
#
# Absolute tolerance stays correct for exactly one case: an assertion whose
# expected value IS zero, where the tolerance legitimately defines the band.
#
# Literals passed to @emlTestAssertEqualRel must be transcribed at full
# precision from the EXTERNAL reference (R, scipy) — never copied from the
# library's own output, which would make the check circular. The relative
# band must then be chosen from the MEASURED library-vs-reference agreement
# for that algorithm family, not assumed. Measured 3 August 2026:
#
#   ANOVA / Kruskal / Mann-Whitney / Wilcoxon p : agree to < 1e-9 relative
#   Tukey HSD & Games-Howell p (ptukey)         : agree to ~1.4e-6 relative
#
# so the Tukey family takes 1e-5 relative and everything else 1e-9.
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


# ============================================================================
# @emlTestInit
# ============================================================================
# Initialize test counters and print suite header.
# Call once at the start of each test suite.
#
# Output (persistent, read by all other emlTest procedures):
#   .passed       - number of passed assertions
#   .failed       - number of failed assertions
#   .skipped      - number of declared checks that could not be run
#   .count        - total checks accounted for (passed + failed + skipped)
#   .sectionCount - number of sections started
# ============================================================================

procedure emlTestInit
    .passed = 0
    .failed = 0
    .skipped = 0
    .count = 0
    .sectionCount = 0
    .border$ = "═══════════════════════════════════════════════════════"
    .title$ = "  EML Stats Test Suite"
    writeInfoLine: .border$
    appendInfoLine: .title$
    appendInfoLine: .border$
    .empty$ = ""
    appendInfoLine: .empty$
endproc


# ============================================================================
# @emlTestSection
# ============================================================================
# Print a section header to visually group related tests.
#
# Arguments:
#   .title$ - section name
# ============================================================================

procedure emlTestSection: .title$
    emlTestInit.sectionCount = emlTestInit.sectionCount + 1
    .prefix$ = "── "
    .suffix$ = " ──────────────────────────────────"
    .line$ = .prefix$ + .title$ + .suffix$
    .empty$ = ""
    appendInfoLine: .empty$
    appendInfoLine: .line$
endproc


# ============================================================================
# @emlTestAssertTrue
# ============================================================================
# Assert that a condition is true (nonzero).
#
# Arguments:
#   .name$     - test description
#   .condition - numeric value (nonzero = pass, 0 = fail)
# ============================================================================

procedure emlTestAssertTrue: .name$, .condition
    emlTestInit.count = emlTestInit.count + 1
    if .condition
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    endif
endproc


# ============================================================================
# @emlTestAssertEqualNum
# ============================================================================
# Assert that two numeric values are equal within tolerance.
# Handles undefined: both undefined = pass, one undefined = fail.
#
# Arguments:
#   .name$     - test description
#   .expected  - expected value
#   .actual    - actual value
#   .tolerance - maximum allowed difference
# ============================================================================

procedure emlTestAssertEqualNum: .name$, .expected, .actual, .tolerance
    emlTestInit.count = emlTestInit.count + 1

    # Determine pass/fail with undefined handling
    if .expected = undefined and .actual = undefined
        .pass = 1
    elsif .expected = undefined or .actual = undefined
        .pass = 0
    else
        .diff = abs (.actual - .expected)
        if .diff <= .tolerance
            .pass = 1
        else
            .pass = 0
        endif
    endif

    if .pass
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        # Detail lines.
        # string$() not fixed$(): fixed$ (x, 6) renders every value below
        # 5e-7 as "0.000000", so a failure at 2.4e-09 printed
        # "Expected: 0.000000 / Got: 0.000000" and the failure message could
        # not display the failure. Same defect class as the R-side %.8f that
        # was corrected to %.17g.
        if .expected = undefined
            .expectedStr$ = "undefined"
        else
            .expectedStr$ = string$ (.expected)
        endif
        if .actual = undefined
            .actualStr$ = "undefined"
        else
            .actualStr$ = string$ (.actual)
        endif
        .expectedLabel$ = "    Expected:  "
        .actualLabel$ = "    Got:       "
        .diffLabel$ = "    |diff|:    "
        .tolLabel$ = "    Tolerance: "
        .expectedLine$ = .expectedLabel$ + .expectedStr$
        .actualLine$ = .actualLabel$ + .actualStr$
        appendInfoLine: .expectedLine$
        appendInfoLine: .actualLine$
        if .expected <> undefined and .actual <> undefined
            .diffStr$ = string$ (abs (.actual - .expected))
            .diffLine$ = .diffLabel$ + .diffStr$
            appendInfoLine: .diffLine$
        endif
        .tolStr$ = string$ (.tolerance)
        .tolLine$ = .tolLabel$ + .tolStr$
        appendInfoLine: .tolLine$
    endif
endproc


# ============================================================================
# @emlTestAssertEqualRel
# ============================================================================
# Assert that two numeric values agree to within a RELATIVE tolerance.
#
# Pass condition:  |actual - expected| <= relTolerance * |expected|
#
# Use this instead of @emlTestAssertEqualNum whenever the expected value is
# nonzero and its magnitude is not known in advance to be order 1 — p-values
# above all. An absolute tolerance applied to a p-value of 2e-10 is vacuous
# (see ASSERTION VACUITY in the file header); a relative tolerance cannot be.
#
# Undefined handling matches @emlTestAssertEqualNum: both undefined = pass,
# one undefined = fail.
#
# A zero expected value is a USAGE ERROR here, not a legitimate case: the
# relative band collapses to zero and the assertion would demand exact
# equality by accident. It is counted as a failure with an explicit message
# so it cannot pass silently. Use @emlTestAssertEqualNum for zero targets.
#
# Arguments:
#   .name$        - test description
#   .expected     - expected value, full precision, from the EXTERNAL
#                   reference (R / scipy) — never copied from the library
#   .actual       - value returned by the library under test
#   .relTolerance - maximum allowed |diff| / |expected|, e.g. 1e-9
# ============================================================================

procedure emlTestAssertEqualRel: .name$, .expected, .actual, .relTolerance
    emlTestInit.count = emlTestInit.count + 1
    .misuse = 0

    if .expected = undefined and .actual = undefined
        .pass = 1
    elsif .expected = undefined or .actual = undefined
        .pass = 0
    elsif .expected = 0
        .pass = 0
        .misuse = 1
    else
        .diff = abs (.actual - .expected)
        .allowed = .relTolerance * abs (.expected)
        if .diff <= .allowed
            .pass = 1
        else
            .pass = 0
        endif
    endif

    .indent$ = "  "
    .sep$ = ": "

    if .pass
        emlTestInit.passed = emlTestInit.passed + 1
        .status$ = "PASS"
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .status$ = "FAIL"
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        if .misuse
            .misuseMsg$ = "    MISUSE: expected = 0 with a relative"
            ... + " tolerance. Use @emlTestAssertEqualNum for zero targets."
            appendInfoLine: .misuseMsg$
        endif
        if .expected = undefined
            .expectedStr$ = "undefined"
        else
            .expectedStr$ = string$ (.expected)
        endif
        if .actual = undefined
            .actualStr$ = "undefined"
        else
            .actualStr$ = string$ (.actual)
        endif
        .expectedLabel$ = "    Expected:  "
        .actualLabel$ = "    Got:       "
        .relLabel$ = "    Rel error: "
        .bandLabel$ = "    Rel band:  "
        .expectedLine$ = .expectedLabel$ + .expectedStr$
        .actualLine$ = .actualLabel$ + .actualStr$
        appendInfoLine: .expectedLine$
        appendInfoLine: .actualLine$
        if .expected <> undefined and .actual <> undefined and .expected <> 0
            .relErr = abs (.actual - .expected) / abs (.expected)
            .relStr$ = string$ (.relErr)
            .relLine$ = .relLabel$ + .relStr$
            appendInfoLine: .relLine$
        endif
        .bandStr$ = string$ (.relTolerance)
        .bandLine$ = .bandLabel$ + .bandStr$
        appendInfoLine: .bandLine$
    endif
endproc


# ============================================================================
# @emlTestAssertEqualStr
# ============================================================================
# Assert that two strings are identical.
#
# Arguments:
#   .name$     - test description
#   .expected$ - expected string
#   .actual$   - actual string
# ============================================================================

procedure emlTestAssertEqualStr: .name$, .expected$, .actual$
    emlTestInit.count = emlTestInit.count + 1
    if .expected$ = .actual$
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        .expectedLabel$ = "    Expected: "
        .actualLabel$ = "    Got:      "
        .expectedLine$ = .expectedLabel$ + .expected$
        .actualLine$ = .actualLabel$ + .actual$
        appendInfoLine: .expectedLine$
        appendInfoLine: .actualLine$
    endif
endproc


# ============================================================================
# @emlTestAssertUndefined
# ============================================================================
# Assert that a value is undefined.
#
# Arguments:
#   .name$  - test description
#   .value  - value to check
# ============================================================================

procedure emlTestAssertUndefined: .name$, .value
    emlTestInit.count = emlTestInit.count + 1
    if .value = undefined
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        .actualStr$ = fixed$ (.value, 6)
        .detailLabel$ = "    Expected undefined, got: "
        .detailLine$ = .detailLabel$ + .actualStr$
        appendInfoLine: .detailLine$
    endif
endproc


# ============================================================================
# @emlTestAssertVectorsEqual
# ============================================================================
# Assert that two numeric vectors are element-wise equal within tolerance.
# Fails if sizes differ or any element pair exceeds tolerance.
#
# Arguments:
#   .name$     - test description
#   .v1#       - expected vector
#   .v2#       - actual vector
#   .tolerance - maximum allowed per-element difference
#
# Note: undefined elements are compared via subtraction — if both are
#   undefined, the difference is undefined (not zero), which will exceed
#   tolerance. Use @emlTestAssertTrue with explicit undefined checks if
#   vectors may contain undefined values.
# ============================================================================

procedure emlTestAssertVectorsEqual: .name$, .v1#, .v2#, .tolerance
    emlTestInit.count = emlTestInit.count + 1
    .n1 = size (.v1#)
    .n2 = size (.v2#)

    if .n1 <> .n2
        .pass = 0
        .failIdx = 0
        .reason$ = "size mismatch"
    else
        .pass = 1
        .failIdx = 0
        .reason$ = ""
        for .i from 1 to .n1
            if .pass = 1
                .diff = abs (.v1#[.i] - .v2#[.i])
                if .diff > .tolerance
                    .pass = 0
                    .failIdx = .i
                endif
            endif
        endfor
    endif

    if .pass
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        if .reason$ = "size mismatch"
            .n1Str$ = string$ (.n1)
            .n2Str$ = string$ (.n2)
            .detailLine$ = "    Size mismatch: expected " + .n1Str$ + ", got " + .n2Str$
            appendInfoLine: .detailLine$
        else
            .idxStr$ = string$ (.failIdx)
            .expectedStr$ = fixed$ (.v1#[.failIdx], 6)
            .actualStr$ = fixed$ (.v2#[.failIdx], 6)
            .detailLine$ = "    Element [" + .idxStr$ + "]: expected " + .expectedStr$ + ", got " + .actualStr$
            appendInfoLine: .detailLine$
        endif
    endif
endproc


# ============================================================================
# @emlTestAssertContains
# ============================================================================
# Assert that a string contains a substring.
#
# Arguments:
#   .name$     - test description
#   .haystack$ - string to search in
#   .needle$   - substring to find
# ============================================================================

procedure emlTestAssertContains: .name$, .haystack$, .needle$
    emlTestInit.count = emlTestInit.count + 1
    .pos = index (.haystack$, .needle$)
    if .pos > 0
        emlTestInit.passed = emlTestInit.passed + 1
        .indent$ = "  "
        .status$ = "PASS"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
    else
        emlTestInit.failed = emlTestInit.failed + 1
        .indent$ = "  "
        .status$ = "FAIL"
        .sep$ = ": "
        .line$ = .indent$ + .status$ + .sep$ + .name$
        appendInfoLine: .line$
        .searchLabel$ = "    Searching for: "
        .inLabel$ = "    In string:     "
        .searchLine$ = .searchLabel$ + .needle$
        .inLine$ = .inLabel$ + .haystack$
        appendInfoLine: .searchLine$
        appendInfoLine: .inLine$
    endif
endproc


# ============================================================================
# @emlTestSkip
# ============================================================================
# Register a check that was DECLARED but could not be RUN.
#
# A skip is not a pass. It is counted separately and forces the suite's
# reported status to INCOMPLETE, so that a check which silently vanished
# (missing R package, unavailable reference, unreproducible RNG) can never
# be mistaken for a check that ran and succeeded.
#
# Use this instead of quietly omitting a check or wrapping it in a comment.
#
# Arguments:
#   .name$   - what the check would have verified
#   .reason$ - why it could not be run (state the blocking condition)
# ============================================================================

procedure emlTestSkip: .name$, .reason$
    emlTestInit.count = emlTestInit.count + 1
    emlTestInit.skipped = emlTestInit.skipped + 1
    .indent$ = "  "
    .status$ = "SKIP"
    .sep$ = ": "
    .line$ = .indent$ + .status$ + .sep$ + .name$
    appendInfoLine: .line$
    .reasonLabel$ = "    Reason: "
    .reasonLine$ = .reasonLabel$ + .reason$
    appendInfoLine: .reasonLine$
endproc


# ============================================================================
# @emlTestSummary
# ============================================================================
# Print final test results. Call once at the end of each test suite.
#
# Emits a machine-readable sentinel line for the runner:
#
#   EMLTEST-RESULT: status=<PASS|FAIL|INCOMPLETE> passed=N failed=N
#       skipped=N total=N
#
# (one physical line; wrapped here only for the comment width)
#
# Calls exitScript: when any assertion failed, so the failure also reaches
# the process exit status (255). See the RESULT REPORTING CONTRACT at the
# top of this file for why the status is split across two channels.
# ============================================================================

procedure emlTestSummary
    .empty$ = ""
    .border$ = "═══════════════════════════════════════════════════════"
    .heading$ = "  TEST SUMMARY"
    appendInfoLine: .empty$
    appendInfoLine: .border$
    appendInfoLine: .heading$
    appendInfoLine: .border$

    .passedStr$ = string$ (emlTestInit.passed)
    .failedStr$ = string$ (emlTestInit.failed)
    .skippedStr$ = string$ (emlTestInit.skipped)
    .countStr$ = string$ (emlTestInit.count)

    .passLine$ = "  Passed:  " + .passedStr$
    .failLine$ = "  Failed:  " + .failedStr$
    .skipLine$ = "  Skipped: " + .skippedStr$
    .totalLine$ = "  Total:   " + .countStr$
    appendInfoLine: .passLine$
    appendInfoLine: .failLine$
    appendInfoLine: .skipLine$
    appendInfoLine: .totalLine$

    appendInfoLine: .empty$
    if emlTestInit.failed > 0
        .status$ = "FAIL"
        .resultLine$ = "  SOME TESTS FAILED"
    elsif emlTestInit.skipped > 0
        .status$ = "INCOMPLETE"
        .resultLine$ = "  NO FAILURES, BUT SOME CHECKS WERE SKIPPED"
    else
        .status$ = "PASS"
        .resultLine$ = "  ALL TESTS PASSED"
    endif
    appendInfoLine: .resultLine$
    appendInfoLine: .border$

    .sentinelLabel$ = "EMLTEST-RESULT: status="
    .passedField$ = " passed="
    .failedField$ = " failed="
    .skippedField$ = " skipped="
    .totalField$ = " total="
    .sentinel$ = .sentinelLabel$ + .status$ + .passedField$ + .passedStr$
    ... + .failedField$ + .failedStr$ + .skippedField$ + .skippedStr$
    ... + .totalField$ + .countStr$
    appendInfoLine: .empty$
    appendInfoLine: .sentinel$

    if emlTestInit.failed > 0
        .exitMsg$ = "EML test suite FAILED: " + .failedStr$
        ... + " of " + .countStr$ + " checks failed."
        exitScript: .exitMsg$
    endif
endproc


# ============================================================================
# END OF MODULE
# ============================================================================
