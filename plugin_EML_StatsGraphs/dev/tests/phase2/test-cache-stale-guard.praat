# ============================================================================
# Throwaway verification script (not part of the tracked test suite) for the
# eml_getGroupData / eml_ak2_gather memoization added in this speed wave.
# Praat 6.6.30's object IDs are strictly monotonic (verified separately: a
# Remove never frees an id for reuse), so the sharpest theoretical risk the
# epoch guard defends against -- an id literally recycled between two
# differently-keyed calls -- cannot be constructed in-process here. What IS
# exercised, hard, is the same shape the task's stale-cache guard cares
# about: several different datasets/cells asked through the SAME doors in
# ONE process, run back to back and interleaved, confirming no run ever
# reads another run's cached group data.
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-core-descriptive.praat
include ../../../stats/eml-extract.praat
include ../../../stats/eml-studentized-range.praat
include ../../../stats/eml-anova-kernel.praat
include ../../../stats/eml-inferential.praat
include ../../../stats/eml-output.praat
include ../../../stats/eml-result-writer.praat
include ../../../stats/eml-analysis.praat
include ../../../graphs/eml-annotation-procedures.praat

nPass = 0
nFail = 0
procedure ok: .label$, .cond
    if .cond = 1
        nPass = nPass + 1
        appendInfoLine: "  PASS : ", .label$
    else
        nFail = nFail + 1
        appendInfoLine: "  FAIL : ", .label$
    endif
endproc

writeInfoLine: "TEST -- stale-cache guard (ID recycling across door calls)"

# --- ONE-WAY: table A, run the door, remove it, create table B with the
# SAME object id (Praat reuses the freed number) and DIFFERENT data under
# the SAME column names, run the door again. ---------------------------------

Create Table with column names: "gA", 12, "val grp"
tableA = selected ("Table")
for i from 1 to 12
    Set string value: i, "grp", "g" + string$ (1 + (i - 1) mod 3)
endfor
Set numeric value: 1, "val", 10
Set numeric value: 2, "val", 11
Set numeric value: 3, "val", 12
Set numeric value: 4, "val", 40
Set numeric value: 5, "val", 41
Set numeric value: 6, "val", 42
Set numeric value: 7, "val", 70
Set numeric value: 8, "val", 71
Set numeric value: 9, "val", 72
Set numeric value: 10, "val", 100
Set numeric value: 11, "val", 101
Set numeric value: 12, "val", 102

@emlRunAnovaAnalysis: tableA, "val", "grp", 0
@ok: "run1 no error", emlRunAnovaAnalysis.error$ = ""
run1F = emlOneWayAnova.fValue
run1BfF = emlRunAnovaAnalysis.bfF
run1WelchF = emlRunAnovaAnalysis.welchF
appendInfoLine: "  run1 F=", run1F, " bfF=", run1BfF, " welchF=", run1WelchF

Remove

Create Table with column names: "gA", 12, "val grp"
tableB = selected ("Table")
for i from 1 to 12
    Set string value: i, "grp", "g" + string$ (1 + (i - 1) mod 3)
endfor
# Completely different data: reversed spread, different group ordering of
# magnitude, so a stale cache hit would print run1's numbers verbatim.
Set numeric value: 1, "val", 5
Set numeric value: 2, "val", 5.2
Set numeric value: 3, "val", 4.8
Set numeric value: 4, "val", 5.1
Set numeric value: 5, "val", 4.9
Set numeric value: 6, "val", 5.05
Set numeric value: 7, "val", 5.15
Set numeric value: 8, "val", 4.95
Set numeric value: 9, "val", 5.0
Set numeric value: 10, "val", 200
Set numeric value: 11, "val", 205
Set numeric value: 12, "val", 195

@emlRunAnovaAnalysis: tableB, "val", "grp", 0
@ok: "run2 no error", emlRunAnovaAnalysis.error$ = ""
run2F = emlOneWayAnova.fValue
run2BfF = emlRunAnovaAnalysis.bfF
run2WelchF = emlRunAnovaAnalysis.welchF
appendInfoLine: "  run2 F=", run2F, " bfF=", run2BfF, " welchF=", run2WelchF

@ok: "run2 F differs from run1 F (no stale hit)", run2F <> run1F
@ok: "run2 Brown-Forsythe F differs from run1 (no stale hit)",
... run2BfF <> run1BfF
@ok: "run2 Welch F differs from run1 (no stale hit)",
... run2WelchF <> run1WelchF

# Independently re-derive run2's expected group means directly, bypassing
# the door/cache entirely, and confirm the door's own group data agrees --
# i.e. the door actually used table B's rows, not table A's. g1 is rows
# 1, 4, 7, 10 (grp cycles g1,g2,g3): values 5, 5.1, 5.15, 200 -> mean 53.8125.
@eml_getGroupData: tableB, "val", "grp", "g1"
directG1Mean = 0
for i from 1 to eml_getGroupData.n
    directG1Mean = directG1Mean + eml_getGroupData.data#[i]
endfor
directG1Mean = directG1Mean / eml_getGroupData.n
@ok: "direct re-extraction from table B matches its own known g1 mean",
... abs (directG1Mean - 53.8125) < 1e-9

selectObject: tableB
Remove

# --- TWO-WAY: same ID-recycling stress on emlRunTwoWayAnalysis / eml_ak2_gather ---

Create Table with column names: "twA", 16, "val f1 f2"
twA = selected ("Table")
for i from 1 to 16
    r = 1 + floor ((i - 1) / 8)
    c = 1 + floor (((i - 1) mod 8) / 4)
    Set string value: i, "f1", "A" + string$ (r)
    Set string value: i, "f2", "B" + string$ (c)
    Set numeric value: i, "val", 10 * r + c + (i mod 3)
endfor

@emlRunTwoWayAnalysis: twA, "val", "f1", "f2", 3, "bonferroni"
@ok: "twoway run1 no error", emlRunTwoWayAnalysis.error$ = ""
tw1FA = emlTwoWayAnova.fA
tw1EmmA1 = emlRunTwoWayAnalysis.emmA#[1]
appendInfoLine: "  twoway run1 fA=", tw1FA, " emmA1=", tw1EmmA1

Remove
Create Table with column names: "twB", 16, "val f1 f2"
twB = selected ("Table")
for i from 1 to 16
    r = 1 + floor ((i - 1) / 8)
    c = 1 + floor (((i - 1) mod 8) / 4)
    Set string value: i, "f1", "A" + string$ (r)
    Set string value: i, "f2", "B" + string$ (c)
    # Wildly different values from run 1's table.
    Set numeric value: i, "val", 1000 * r - 50 * c + i
endfor

@emlRunTwoWayAnalysis: twB, "val", "f1", "f2", 3, "bonferroni"
@ok: "twoway run2 no error", emlRunTwoWayAnalysis.error$ = ""
tw2FA = emlTwoWayAnova.fA
tw2EmmA1 = emlRunTwoWayAnalysis.emmA#[1]
appendInfoLine: "  twoway run2 fA=", tw2FA, " emmA1=", tw2EmmA1

@ok: "twoway run2 fA differs from run1 (no stale hit)", tw2FA <> tw1FA
@ok: "twoway run2 emmA1 differs from run1 (no stale hit)",
... tw2EmmA1 <> tw1EmmA1

selectObject: twB
Remove

# --- Multiple DIFFERENT cells within the SAME process, interleaved, exactly
# the "several different datasets/cells in one process" shape. -------------

Create Table with column names: "gC", 9, "val grp"
tableC = selected ("Table")
for i from 1 to 9
    Set string value: i, "grp", "g" + string$ (1 + (i - 1) mod 3)
    Set numeric value: i, "val", 1 + i
endfor
@emlRunAnovaAnalysis: tableC, "val", "grp", 0
cF = emlOneWayAnova.fValue

# NOT an affine rescaling of table C's values -- the one-way F ratio is
# scale/shift invariant, so a linear transform of C would (correctly)
# reproduce C's exact F and give a false "stale cache" alarm. This pattern
# has unequal within-group spread across groups and non-linearly spaced
# group means, so its F genuinely differs from C's.
Create Table with column names: "gD", 9, "val grp"
tableD = selected ("Table")
Set string value: 1, "grp", "g1"
Set string value: 2, "grp", "g1"
Set string value: 3, "grp", "g1"
Set string value: 4, "grp", "g2"
Set string value: 5, "grp", "g2"
Set string value: 6, "grp", "g2"
Set string value: 7, "grp", "g3"
Set string value: 8, "grp", "g3"
Set string value: 9, "grp", "g3"
Set numeric value: 1, "val", 50
Set numeric value: 2, "val", 52
Set numeric value: 3, "val", 49
Set numeric value: 4, "val", 10
Set numeric value: 5, "val", 11
Set numeric value: 6, "val", 9
Set numeric value: 7, "val", 100
Set numeric value: 8, "val", 98
Set numeric value: 9, "val", 300
@emlRunAnovaAnalysis: tableD, "val", "grp", 0
dF = emlOneWayAnova.fValue

@ok: "interleaved cell C and cell D give different F (no cross-cell bleed)",
... cF <> dF

selectObject: tableC
plus tableD
Remove

appendInfoLine: ""
appendInfoLine: "Passed: ", nPass
appendInfoLine: "Failed: ", nFail
if nFail = 0
    appendInfoLine: "ALL PASSED"
else
    appendInfoLine: "SOME FAILED"
endif
