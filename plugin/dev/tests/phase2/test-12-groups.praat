# ============================================================================
# Test: 12-group ANOVA (verifies no 10-group ceiling)
# ============================================================================
# Run from: dev/tests/phase2/
#
# Version: 1.1
# Date: 3 August 2026
#
# v1.1: Brought under the TEST RESULT REPORTING CONTRACT (v1.1, declared in
#       dev/tests/eml-test-helpers.praat). This suite had no counters and no
#       summary at all — it used bare `assert` statements, which abort the
#       interpreter on failure (exit 255) and print nothing on success. A
#       runner therefore saw either a silent exit 0 or an opaque 255, with
#       no way to tell "5 checks passed" from "the file died at include
#       time". The five checks are now @emlTestAssertTrue calls and
#       @emlTestSummary emits the machine-readable sentinel. The ANOVA
#       error path no longer calls exitScript: — a failed ANOVA is now a
#       reported FAIL plus SKIPs for the checks it makes unanswerable,
#       which is INCOMPLETE rather than a vanished suite.
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
include ../../../stats/eml-extract.praat
include ../../../stats/eml-inferential.praat

include ../eml-test-helpers.praat

@emlTestInit

@emlTestSection: "12-group ANOVA (no 10-group ceiling)"

# Build a 12-group table: 5 observations per group, means shift by 2
tableId = Create Table with column names: "test12", 60, "group value"

selectObject: tableId
row = 0
for g from 1 to 12
    for obs from 1 to 5
        row = row + 1
        selectObject: tableId
        Set string value: row, "group", "G" + string$ (g)
        Set numeric value: row, "value", g * 2 + randomGauss (0, 1)
    endfor
endfor

# Verify CountGroups finds all 12
@emlCountGroups: tableId, "group"
appendInfoLine: "Groups discovered: ", emlCountGroups.nGroups
@emlTestAssertTrue: "emlCountGroups finds 12 groups", emlCountGroups.nGroups = 12

# Verify eml_getGroupData works for group 12
@eml_getGroupData: tableId, "value", "group", "G12"
appendInfoLine: "G12 observations: ", eml_getGroupData.n
@emlTestAssertTrue: "eml_getGroupData returns 5 rows for G12", eml_getGroupData.n = 5

# Run OneWayAnova
@emlOneWayAnova: tableId, "value", "group", 1
appendInfoLine: ""
errorLabel$ = "OneWayAnova error: "
appendInfoLine: errorLabel$, emlOneWayAnova.error$

anovaOk = (emlOneWayAnova.error$ = "")
@emlTestAssertTrue: "emlOneWayAnova completes without error", anovaOk

if anovaOk
    appendInfoLine: "F = ", fixed$ (emlOneWayAnova.fValue, 4)
    appendInfoLine: "p = ", fixed$ (emlOneWayAnova.p, 6)
    appendInfoLine: "df between = ", emlOneWayAnova.dfBetween
    appendInfoLine: "df within = ", emlOneWayAnova.dfWithin
    appendInfoLine: "eta-squared = ", fixed$ (emlOneWayAnova.etaSquared, 4)
    appendInfoLine: "nGroups = ", emlOneWayAnova.nGroups
    appendInfoLine: "nPairs (Tukey) = ", emlOneWayAnova.nPairs

    @emlTestAssertTrue: "ANOVA reports 12 groups", emlOneWayAnova.nGroups = 12
    @emlTestAssertTrue: "ANOVA df between = 11", emlOneWayAnova.dfBetween = 11
    @emlTestAssertTrue: "Tukey pair count = 66", emlOneWayAnova.nPairs = 66
else
    skipReason$ = "ANOVA returned an error, so its outputs are unanswerable."
    @emlTestSkip: "ANOVA reports 12 groups", skipReason$
    @emlTestSkip: "ANOVA df between = 11", skipReason$
    @emlTestSkip: "Tukey pair count = 66", skipReason$
endif

removeObject: tableId

# @emlTestSummary exitScript:s when failed > 0, so this must stay last —
# in particular after the removeObject: cleanup above.
@emlTestSummary
