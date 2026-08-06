# ============================================================================
# tierA_properties.praat -- invariance and refusal properties, no oracle.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Every assertion here is something that must hold WHATEVER the data is, so
# no reference implementation is needed and no certified value is transcribed.
# Half the cases are well-formed data under a transformation that must not
# change the answer; half are malformed data that must produce a refusal that
# names what is wrong.
#
#     praat --run harness/sweep/tierA_properties.praat
#
# Exit is by the printed ledger; the calling script reads sweepFail.
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include lib_sweep.praat

random_initializeWithSeedUnsafelyButPredictably: 20260806
writeInfoLine: "Tier A -- properties that hold regardless of the data"

# ===========================================================================
# WELL-FORMED DATA: relationships that must hold
# ===========================================================================

# --- A1. One-way ANOVA on two groups is the equal-variance t test ----------
# F = t^2 is an algebraic identity, not an approximation, so the tolerance is
# numerical only. Two INDEPENDENT code paths in the plugin must agree.
n2# = {14, 14}
m2# = {100, 104}
@sweepMakeGroups: 2, n2#, m2#, 3, -1
tA1 = sweepMakeGroups.tableId

@emlOneWayAnova: tA1, "value", "grp", 0
fA1 = emlOneWayAnova.fValue
pA1 = emlOneWayAnova.p

@eml_getGroupData: tA1, "value", "grp", "G1"
g1# = eml_getGroupData.data#
@eml_getGroupData: tA1, "value", "grp", "G2"
g2# = eml_getGroupData.data#
@emlTTest: g1#, g2#, 2, 1

@sweepNear: "A1", "one-way F equals t^2 (k=2)", fA1, emlTTest.t ^ 2, 1e-9
@sweepNear: "A1", "one-way p equals t-test p (k=2)", pA1, emlTTest.p, 1e-12

# --- A2. Location invariance ----------------------------------------------
# Adding a constant to every observation cannot change F, p, or eta^2. A
# routine that accumulates raw sums instead of centring will drift here.
@sweepTransform: tA1, "value", 1e6, 1
@emlOneWayAnova: tA1, "value", "grp", 0
@sweepNear: "A2", "F invariant under +1e6", emlOneWayAnova.fValue, fA1, 1e-6
@sweepTransform: tA1, "value", -1e6, 1

# --- A3. Scale equivariance -----------------------------------------------
# Multiplying by k leaves F alone and multiplies every sum of squares by k^2.
@emlOneWayAnova: tA1, "value", "grp", 0
ssB0 = emlOneWayAnova.ssBetween
@sweepTransform: tA1, "value", 0, 1000
@emlOneWayAnova: tA1, "value", "grp", 0
@sweepNear: "A3", "F invariant under x1000", emlOneWayAnova.fValue, fA1, 1e-7
@sweepNear: "A3", "ssBetween scales by k^2", emlOneWayAnova.ssBetween,
... ssB0 * 1e6, abs (ssB0) * 1e-6
@sweepTransform: tA1, "value", 0, 0.001

# --- A4. Eta squared is ssBetween / ssTotal -------------------------------
# Reported separately from the sums of squares, so it can disagree with them.
@emlOneWayAnova: tA1, "value", "grp", 0
@sweepNear: "A4", "eta^2 = ssBetween/ssTotal", emlOneWayAnova.etaSquared,
... emlOneWayAnova.ssBetween / emlOneWayAnova.ssTotal, 1e-12
@sweepNear: "A4", "ssTotal = ssBetween + ssWithin", emlOneWayAnova.ssTotal,
... emlOneWayAnova.ssBetween + emlOneWayAnova.ssWithin, 1e-8

removeObject: tA1

# --- A5. Group-label permutation invariance -------------------------------
# Relabelling G1<->G3 must not move F. Anything that sorts labels and then
# indexes group statistics positionally will fail this.
n3# = {12, 9, 15}
m3# = {50, 53, 57}
@sweepMakeGroups: 3, n3#, m3#, 4, -1
tA5 = sweepMakeGroups.tableId
@emlOneWayAnova: tA5, "value", "grp", 0
fA5 = emlOneWayAnova.fValue
etaA5 = emlOneWayAnova.etaSquared

selectObject: tA5
nr = Get number of rows
for r from 1 to nr
    lab$ = Get value: r, "grp"
    if lab$ = "G1"
        Set string value: r, "grp", "G3"
    elsif lab$ = "G3"
        Set string value: r, "grp", "G1"
    endif
endfor
@emlOneWayAnova: tA5, "value", "grp", 0
@sweepNear: "A5", "F invariant under group relabel", emlOneWayAnova.fValue,
... fA5, 1e-9
@sweepNear: "A5", "eta^2 invariant under group relabel",
... emlOneWayAnova.etaSquared, etaA5, 1e-12

# --- A6. Tukey's difference matrix is antisymmetric, p matrix symmetric ----
# UNEQUAL n on purpose: this is Tukey-Kramer, and the half-width depends on
# both cell sizes. The committed suite has never run this path.
@emlOneWayAnova: tA5, "value", "grp", 1
symOk = 1
antiOk = 1
for i from 1 to emlOneWayAnova.nGroups - 1
    for j from i + 1 to emlOneWayAnova.nGroups
        if abs (emlOneWayAnova.pMatrix## [i, j]
        ... - emlOneWayAnova.pMatrix## [j, i]) > 1e-15
            symOk = 0
        endif
        if abs (emlOneWayAnova.meanDiff## [i, j]
        ... + emlOneWayAnova.meanDiff## [j, i]) > 1e-12
            antiOk = 0
        endif
    endfor
endfor
@sweepNear: "A6", "Tukey p matrix symmetric (unequal n)", symOk, 1, 0
@sweepNear: "A6", "Tukey mean-difference matrix antisymmetric", antiOk, 1, 0

removeObject: tA5

# --- A7. Kruskal-Wallis is rank-invariant under a monotone transform ------
# H depends only on ranks, so exp() of the data must give the same H to the
# last bit. A routine that touches a raw value anywhere will move.
n3b# = {10, 10, 10}
m3b# = {2.0, 2.4, 2.9}
@sweepMakeGroups: 3, n3b#, m3b#, 0.4, -1
tA7 = sweepMakeGroups.tableId
@emlKruskalWallis: tA7, "value", "grp"
hA7 = emlKruskalWallis.h

selectObject: tA7
nr = Get number of rows
for r from 1 to nr
    v = Get value: r, "value"
    Set numeric value: r, "value", exp (v)
endfor
@emlKruskalWallis: tA7, "value", "grp"
@sweepNear: "A7", "KW H invariant under exp()", emlKruskalWallis.h, hA7, 1e-12
removeObject: tA7

# --- A8. Ties change the tie correction, and it must be < 1 ---------------
# THE GAP THE COMMITTED SUITE DOES NOT REACH. Rounding sd=1 data to 0 decimals
# forces heavy ties; the correction factor must drop below 1 and H must rise.
n3c# = {14, 14, 14}
m3c# = {10, 11, 12}
@sweepMakeGroups: 3, n3c#, m3c#, 1.2, -1
tA8a = sweepMakeGroups.tableId
@emlKruskalWallis: tA8a, "value", "grp"
corrNoTies = emlKruskalWallis.tieCorrection
@sweepNear: "A8", "tie correction = 1 with no ties", corrNoTies, 1, 1e-12

@sweepMakeGroups: 3, n3c#, m3c#, 1.2, 0
tA8b = sweepMakeGroups.tableId
@emlKruskalWallis: tA8b, "value", "grp"
corrTies = emlKruskalWallis.tieCorrection
if corrTies <> undefined and corrTies < 1
    @sweepNear: "A8", "tie correction < 1 with ties present", 1, 1, 0
else
    @sweepNear: "A8", "tie correction < 1 with ties present", corrTies, 0.5, 0
endif
removeObject: tA8a
removeObject: tA8b

# ===========================================================================
# MALFORMED DATA: refusals that must name what is wrong
# ===========================================================================

# --- A9. Zero variance everywhere -----------------------------------------
nE# = {6, 6}
mE# = {5, 5}
@sweepMakeGroups: 2, nE#, mE#, 0, -1
tE1 = sweepMakeGroups.tableId
@emlOneWayAnova: tE1, "value", "grp", 0
if emlOneWayAnova.error$ <> "" or emlOneWayAnova.warning$ <> ""
    @sweepRefuses: "A9", "ANOVA on zero variance flags it",
    ... emlOneWayAnova.error$ + emlOneWayAnova.warning$, ""
else
    @sweepRefuses: "A9", "ANOVA on zero variance flags it", "", ""
endif
removeObject: tE1

# --- A10. A singleton group -----------------------------------------------
nE2# = {8, 1}
mE2# = {10, 20}
@sweepMakeGroups: 2, nE2#, mE2#, 2, -1
tE2 = sweepMakeGroups.tableId
@emlOneWayAnova: tE2, "value", "grp", 1
@sweepRefuses: "A10", "singleton group named in the refusal",
... emlOneWayAnova.error$ + emlOneWayAnova.warning$, "G2"
removeObject: tE2

# --- A11. Only one group ---------------------------------------------------
nE3# = {10}
mE3# = {10}
@sweepMakeGroups: 1, nE3#, mE3#, 2, -1
tE3 = sweepMakeGroups.tableId
@emlOneWayAnova: tE3, "value", "grp", 0
@sweepRefuses: "A11", "one group refused", emlOneWayAnova.error$, ""
@emlKruskalWallis: tE3, "value", "grp"
@sweepRefuses: "A11", "one group refused (KW)", emlKruskalWallis.error$, ""
removeObject: tE3

# --- A12. A column that is not there --------------------------------------
nE4# = {8, 8}
mE4# = {1, 2}
@sweepMakeGroups: 2, nE4#, mE4#, 1, -1
tE4 = sweepMakeGroups.tableId
@emlOneWayAnova: tE4, "no_such_column", "grp", 0
@sweepRefuses: "A12", "missing data column named", emlOneWayAnova.error$,
... "no_such_column"
@emlOneWayAnova: tE4, "value", "no_such_factor", 0
@sweepRefuses: "A12", "missing factor column named", emlOneWayAnova.error$,
... "no_such_factor"
removeObject: tE4

# --- A13. A European decimal comma in a measure column --------------------
# D96. The cell must be excluded and SAID to be excluded, not read as 1.
tE5 = Create Table with column names: "commacase", 6, "value grp"
for r from 1 to 6
    Set numeric value: r, "value", 10 + r
    Set string value: r, "grp", if r <= 3 then "G1" else "G2" fi
endfor
Set string value: 3, "value", "12,5"
@emlExtractColumn: tE5, "value"
@sweepNear: "A13", "comma cell excluded, not read as 1",
... emlExtractColumn.n, 5, 0
@sweepNear: "A13", "comma cell counted as a LOCALE cause, separately",
... emlExtractColumn.nLocale, 1, 0
removeObject: tE5

@sweepReport: "Tier A"
