# ============================================================================
# Test: 12-group ANOVA (verifies no 10-group ceiling)
# ============================================================================
# Run from: dev/tests/phase2/
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-extract.praat
include ../../../stats/eml-inferential.praat

# Build a 12-group table: 5 observations per group, means shift by 2
tableId = Create Table with column names: "test12", 60, "group value"

selectObject: tableId
.row = 0
for .g from 1 to 12
    for .obs from 1 to 5
        .row = .row + 1
        selectObject: tableId
        Set string value: .row, "group", "G" + string$ (.g)
        Set numeric value: .row, "value", .g * 2 + randomGauss (0, 1)
    endfor
endfor

# Verify CountGroups finds all 12
@emlCountGroups: tableId, "group"
appendInfoLine: "Groups discovered: ", emlCountGroups.nGroups
assert emlCountGroups.nGroups = 12

# Verify eml_getGroupData works for group 12
@eml_getGroupData: tableId, "value", "group", "G12"
appendInfoLine: "G12 observations: ", eml_getGroupData.n
assert eml_getGroupData.n = 5

# Run OneWayAnova
@emlOneWayAnova: tableId, "value", "group", 1
appendInfoLine: ""
appendInfoLine: "OneWayAnova error: """, emlOneWayAnova.error$, """"

if emlOneWayAnova.error$ <> ""
    appendInfoLine: "ANOVA FAILED: ", emlOneWayAnova.error$
    removeObject: tableId
    exitScript: "12-group ANOVA failed."
endif

appendInfoLine: "F = ", fixed$ (emlOneWayAnova.fValue, 4)
appendInfoLine: "p = ", fixed$ (emlOneWayAnova.p, 6)
appendInfoLine: "df between = ", emlOneWayAnova.dfBetween
appendInfoLine: "df within = ", emlOneWayAnova.dfWithin
appendInfoLine: "eta-squared = ", fixed$ (emlOneWayAnova.etaSquared, 4)
appendInfoLine: "nGroups = ", emlOneWayAnova.nGroups
appendInfoLine: "nPairs (Tukey) = ", emlOneWayAnova.nPairs

assert emlOneWayAnova.nGroups = 12
assert emlOneWayAnova.dfBetween = 11
assert emlOneWayAnova.nPairs = 66

appendInfoLine: ""
appendInfoLine: "12-GROUP ANOVA: PASSED"

removeObject: tableId
