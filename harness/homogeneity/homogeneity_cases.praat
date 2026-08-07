# ============================================================================
# homogeneity_cases.praat -- headless driver for the three variance-
# heterogeneity procedures added in Ruling 1:
#
#     @emlBrownForsythe   Levene's test, median centring
#     @emlWelchAnova      Welch's heteroscedastic k-sample F
#     @emlGamesHowell     pairwise Welch post-hoc on the studentized range
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Nothing is compared here. Each case writes its data to data/<case>.csv
# and its statistics to results.csv in long form; validate/v22_homogeneity.R
# recomputes all three in base R and does the comparing, so the two halves
# cannot quietly agree by sharing code.
#
# The grid deliberately includes the shapes that separate a correct
# implementation from a plausible one:
#
#     balanced homoscedastic     the case every implementation gets right
#     10:1 variance ratio        separates Welch from pooled ANOVA
#     6:1 unbalanced             separates Games-Howell from Tukey-Kramer
#     k = 2                      Welch F must equal Welch t^2 exactly
#     +1e6 offset                catches a raw-score cancellation
#     skewed                     median centring must not be mean centring
#     red paths                  singleton group, zero-variance group,
#                                identifier column, one group, all-constant,
#                                non-numeric data column
#
#     EML_HOMOG_OUT=harness/homogeneity/out praat --run harness/homogeneity/homogeneity_cases.praat
#
# Output files (all with UNQUOTED header cells):
#   manifest.csv   case,k,n_total,shape
#   results.csv    case,test,statistic,value        (long form, "NA" = undefined)
#   refusals.tsv   case<TAB>test<TAB>error          (tab-separated because the
#                  refusal messages contain both commas and double quotes)
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_HOMOG_OUT")
if outDir$ = ""
    outDir$ = "../../harness/homogeneity/out"
endif
createDirectory: outDir$
createDirectory: outDir$ + "/data"

random_initializeWithSeedUnsafelyButPredictably: 20260807

; Alphabetical group order, so the plugin's group index matches the order R
; gets from factor(). The labels below are G1..G5, where the two orders
; coincide anyway; this makes that a fact rather than a coincidence.
emlGroupSortAlphabetical = 1

manifest$ = "case,k,n_total,shape" + newline$
results$ = "case,test,statistic,value" + newline$
refusals$ = "case" + tab$ + "test" + tab$ + "error" + newline$
nCases = 0

# ---------------------------------------------------------------------------
# @emit: .case$, .test$, .stat$, .value
#   string$(), not fixed$(v, n): fixed$ counts DECIMAL PLACES, so on a
#   quantity of order 1e-8 it silently discards most of the mantissa.
#   string$() round-trips a double at any magnitude. "NA" for undefined,
#   which read.csv turns into R's own NA.
# ---------------------------------------------------------------------------
procedure emit: .case$, .test$, .stat$, .value
    if .value = undefined
        .txt$ = "NA"
    else
        .txt$ = string$ (.value)
    endif
    results$ = results$ + .case$ + "," + .test$ + "," + .stat$ + ","
    ... + .txt$ + newline$
endproc

# ---------------------------------------------------------------------------
# @refuse: .case$, .test$, .message$
#   Record a refusal verbatim. The message is the deliverable here, not a
#   flag: v22 asserts the words, because an unhelpful refusal is a defect in
#   its own right (D99).
# ---------------------------------------------------------------------------
procedure refuse: .case$, .test$, .message$
    results$ = results$ + .case$ + "," + .test$ + ",refused,1" + newline$
    refusals$ = refusals$ + .case$ + tab$ + .test$ + tab$ + .message$
    ... + newline$
endproc

# ---------------------------------------------------------------------------
# @runCase: .case$, .tid, .shape$
#   Save the table, then run all three procedures over it and record
#   everything they expose.
# ---------------------------------------------------------------------------
procedure runCase: .case$, .tid, .shape$
    selectObject: .tid
    .nRows = Get number of rows
    Save as comma-separated file: outDir$ + "/data/" + .case$ + ".csv"

    @emlCountGroups: .tid, "grp"
    if emlCountGroups.error$ = ""
        .k = emlCountGroups.nGroups
    else
        .k = 0
    endif
    manifest$ = manifest$ + .case$ + "," + string$ (.k) + ","
    ... + string$ (.nRows) + "," + .shape$ + newline$

    # --- Brown-Forsythe (Levene, median centred) ---
    @emlBrownForsythe: .tid, "value", "grp"
    if emlBrownForsythe.error$ <> ""
        @refuse: .case$, "bf", emlBrownForsythe.error$
    else
        @emit: .case$, "bf", "statistic", emlBrownForsythe.f
        @emit: .case$, "bf", "df1", emlBrownForsythe.df1
        @emit: .case$, "bf", "df2", emlBrownForsythe.df2
        @emit: .case$, "bf", "p.value", emlBrownForsythe.p
        @emit: .case$, "bf", "ss.between", emlBrownForsythe.ssBetween
        @emit: .case$, "bf", "ss.within", emlBrownForsythe.ssWithin
        for .g from 1 to emlBrownForsythe.nGroups
            @emit: .case$, "bf",
            ... "median:" + emlBrownForsythe.groupLabel$ [.g],
            ... emlBrownForsythe.groupMedian [.g]
            @emit: .case$, "bf",
            ... "meandev:" + emlBrownForsythe.groupLabel$ [.g],
            ... emlBrownForsythe.groupMeanDev [.g]
        endfor
        if emlBrownForsythe.warning$ <> ""
            @refuse: .case$, "bf.warning", emlBrownForsythe.warning$
        endif
    endif

    # --- Welch's heteroscedastic F ---
    @emlWelchAnova: .tid, "value", "grp"
    if emlWelchAnova.error$ <> ""
        @refuse: .case$, "welch", emlWelchAnova.error$
    else
        @emit: .case$, "welch", "statistic", emlWelchAnova.f
        @emit: .case$, "welch", "df1", emlWelchAnova.df1
        @emit: .case$, "welch", "df2", emlWelchAnova.df2
        @emit: .case$, "welch", "p.value", emlWelchAnova.p
        @emit: .case$, "welch", "weighted.mean", emlWelchAnova.weightedMean
        @emit: .case$, "welch", "sum.weights", emlWelchAnova.sumWeights
        for .g from 1 to emlWelchAnova.nGroups
            @emit: .case$, "welch",
            ... "var:" + emlWelchAnova.groupLabel$ [.g],
            ... emlWelchAnova.groupVar [.g]
        endfor
    endif

    # --- Games-Howell ---
    @emlGamesHowell: .tid, "value", "grp", 0.05
    if emlGamesHowell.error$ <> ""
        @refuse: .case$, "gh", emlGamesHowell.error$
    else
        @emit: .case$, "gh", "n.undefined", emlGamesHowell.nUndefined
        @emit: .case$, "gh", "n.pairs", emlGamesHowell.nPairs
        for .i from 1 to emlGamesHowell.nGroups - 1
            for .j from .i + 1 to emlGamesHowell.nGroups
                .pair$ = emlGamesHowell.groupName$ [.i] + "-"
                ... + emlGamesHowell.groupName$ [.j]
                @emit: .case$, "gh", "q:" + .pair$,
                ... emlGamesHowell.qMatrix## [.i, .j]
                @emit: .case$, "gh", "df:" + .pair$,
                ... emlGamesHowell.dfMatrix## [.i, .j]
                @emit: .case$, "gh", "se:" + .pair$,
                ... emlGamesHowell.seMatrix## [.i, .j]
                @emit: .case$, "gh", "estimate:" + .pair$,
                ... emlGamesHowell.meanDiff## [.i, .j]
                @emit: .case$, "gh", "adj.p.value:" + .pair$,
                ... emlGamesHowell.pMatrix## [.i, .j]
                @emit: .case$, "gh", "q.crit:" + .pair$,
                ... emlGamesHowell.qCritMatrix## [.i, .j]
            endfor
        endfor
        ; The pooled names exist but are deliberately undefined; record them
        ; so v22 can assert they are NOT quietly carrying a number.
        @emit: .case$, "gh", "ms.within", emlGamesHowell.msWithin
        @emit: .case$, "gh", "df.within", emlGamesHowell.dfWithin
        @emit: .case$, "gh", "q.critical", emlGamesHowell.qCritical
        if emlGamesHowell.warning$ <> ""
            @refuse: .case$, "gh.warning", emlGamesHowell.warning$
        endif
    endif

    # --- k = 2: the Welch t whose square Welch's F must equal ---
    if emlGamesHowell.error$ = ""
        if emlGamesHowell.nGroups = 2
            @eml_getGroupData: .tid, "value", "grp",
            ... emlGamesHowell.groupName$ [1]
            .a# = eml_getGroupData.data#
            @eml_getGroupData: .tid, "value", "grp",
            ... emlGamesHowell.groupName$ [2]
            @emlTTest: .a#, eml_getGroupData.data#, 2, 0
            if emlTTest.error$ = ""
                @emit: .case$, "welcht", "t", emlTTest.t
                @emit: .case$, "welcht", "df", emlTTest.df
                @emit: .case$, "welcht", "p.value", emlTTest.p
            endif
        endif
    endif

    selectObject: .tid
    Remove
endproc

# ---------------------------------------------------------------------------
# @makeGroups: .k, .n#, .mean#, .sd#, .offset
#   Build a (value, grp) Table with per-group n, mean and SD. .offset is
#   added to every value, which is how the large-offset case is built.
# Result: .tableId
# ---------------------------------------------------------------------------
procedure makeGroups: .k, .n#, .mean#, .sd#, .offset
    .total = 0
    for .g from 1 to .k
        .total = .total + .n# [.g]
    endfor
    .tableId = Create Table with column names: "homog", .total, "value grp"
    .r = 0
    for .g from 1 to .k
        for .i from 1 to .n# [.g]
            .r = .r + 1
            .v = .mean# [.g] + randomGauss (0, .sd# [.g]) + .offset
            selectObject: .tableId
            Set numeric value: .r, "value", .v
            Set string value: .r, "grp", "G" + string$ (.g)
        endfor
    endfor
endproc

# ===========================================================================
# THE GRID
# ===========================================================================

# --- c01: balanced, homoscedastic, k = 3 -----------------------------------
n# = {12, 12, 12}
m# = {10, 11, 13}
s# = {2, 2, 2}
@makeGroups: 3, n#, m#, s#, 0
@runCase: "c01", makeGroups.tableId, "balanced-homoscedastic-k3"

# --- c02: balanced, 10:1 VARIANCE ratio, k = 3 -----------------------------
# sd = sqrt(10) on the last group, so the variance ratio is exactly 10:1.
n# = {15, 15, 15}
m# = {10, 11, 13}
s# = {1, 1, 3.1622776601683795}
@makeGroups: 3, n#, m#, s#, 0
@runCase: "c02", makeGroups.tableId, "balanced-var10to1-k3"

# --- c03: 6:1 unbalanced, heteroscedastic, k = 3 ---------------------------
# The large group carries the SMALL variance, which is the arrangement that
# makes pooled ANOVA anti-conservative -- the direction that matters.
n# = {30, 10, 5}
m# = {10, 11, 13}
s# = {1, 2, 4}
@makeGroups: 3, n#, m#, s#, 0
@runCase: "c03", makeGroups.tableId, "unbalanced6to1-heteroscedastic-k3"

# --- c04: k = 2, balanced, heteroscedastic ---------------------------------
n# = {10, 10}
m# = {10, 12}
s# = {1, 3}
@makeGroups: 2, n#, m#, s#, 0
@runCase: "c04", makeGroups.tableId, "k2-balanced-heteroscedastic"

# --- c05: k = 2, unbalanced 4:1, heteroscedastic ---------------------------
n# = {20, 5}
m# = {10, 12}
s# = {1, 4}
@makeGroups: 2, n#, m#, s#, 0
@runCase: "c05", makeGroups.tableId, "k2-unbalanced-heteroscedastic"

# --- c06: k = 5, unbalanced, heteroscedastic -------------------------------
n# = {18, 4, 11, 7, 25}
m# = {10, 11, 12, 13, 14}
s# = {1, 2, 0.5, 3, 1.5}
@makeGroups: 5, n#, m#, s#, 0
@runCase: "c06", makeGroups.tableId, "k5-unbalanced-heteroscedastic"

# --- c07: balanced, homoscedastic, k = 3, offset by 1e6 --------------------
# Thirteen constant leading digits. A raw-score formula loses the mantissa
# here; all three statistics are invariant under the shift, so R computing
# on the same shifted data must still agree.
n# = {12, 12, 12}
m# = {10, 11, 13}
s# = {2, 2, 2}
@makeGroups: 3, n#, m#, s#, 1000000
@runCase: "c07", makeGroups.tableId, "offset1e6-balanced-k3"

# --- c08: skewed, k = 3 ----------------------------------------------------
# Exponential-ish tails. Median centring and mean centring disagree here,
# which is the whole reason Brown-Forsythe exists; if the procedure had
# quietly centred on the mean, c01-c07 would not catch it and this will.
tid = Create Table with column names: "homog", 45, "value grp"
r = 0
for g from 1 to 3
    for i from 1 to 15
        r = r + 1
        v = g * (-ln (randomUniform (0.0001, 1)))
        selectObject: tid
        Set numeric value: r, "value", v
        Set string value: r, "grp", "G" + string$ (g)
    endfor
endfor
@runCase: "c08", tid, "skewed-exponential-k3"

# --- c09: k = 2, one group flat --------------------------------------------
# Welch must refuse (the weight n/0 is the statistic's foundation);
# Games-Howell must NOT -- one flat group against one varying group is a
# perfectly well defined Welch comparison. Brown-Forsythe must not refuse
# either: the deviations of the flat group are all zero, which is a datum.
tid = Create Table with column names: "homog", 20, "value grp"
r = 0
for i from 1 to 10
    r = r + 1
    selectObject: tid
    Set numeric value: r, "value", 10 + randomGauss (0, 2)
    Set string value: r, "grp", "G1"
endfor
for i from 1 to 10
    r = r + 1
    selectObject: tid
    Set numeric value: r, "value", 7
    Set string value: r, "grp", "G2"
endfor
@runCase: "c09", tid, "k2-one-flat-group"

# ===========================================================================
# RED PATHS
# ===========================================================================

# --- r01: singleton group --------------------------------------------------
tid = Create Table with column names: "homog", 13, "value grp"
r = 0
for g from 1 to 2
    for i from 1 to 6
        r = r + 1
        selectObject: tid
        Set numeric value: r, "value", 10 + g + randomGauss (0, 1)
        Set string value: r, "grp", "G" + string$ (g)
    endfor
endfor
r = r + 1
selectObject: tid
Set numeric value: r, "value", 99
Set string value: r, "grp", "G3"
@runCase: "r01", tid, "singleton-group"

# --- r02: zero-variance group among varying ones ---------------------------
tid = Create Table with column names: "homog", 24, "value grp"
r = 0
for i from 1 to 8
    r = r + 1
    selectObject: tid
    Set numeric value: r, "value", 10 + randomGauss (0, 2)
    Set string value: r, "grp", "G1"
endfor
for i from 1 to 8
    r = r + 1
    selectObject: tid
    Set numeric value: r, "value", 12 + randomGauss (0, 2)
    Set string value: r, "grp", "G2"
endfor
for i from 1 to 8
    r = r + 1
    selectObject: tid
    Set numeric value: r, "value", 5
    Set string value: r, "grp", "G3"
endfor
@runCase: "r02", tid, "zero-variance-group"

# --- r03: identifier column (one group per row) ----------------------------
tid = Create Table with column names: "homog", 9, "value grp"
for r from 1 to 9
    selectObject: tid
    Set numeric value: r, "value", 10 + randomGauss (0, 1)
    Set string value: r, "grp", "id" + string$ (r)
endfor
@runCase: "r03", tid, "identifier-column"

# --- r04: one group only ---------------------------------------------------
tid = Create Table with column names: "homog", 8, "value grp"
for r from 1 to 8
    selectObject: tid
    Set numeric value: r, "value", 10 + randomGauss (0, 1)
    Set string value: r, "grp", "only"
endfor
@runCase: "r04", tid, "single-group"

# --- r05: every observation identical --------------------------------------
# Welch refuses (all groups flat). Brown-Forsythe does not refuse: its
# deviations are all zero, so MS-within is zero and F is undefined WITH a
# warning, not a silently reported 1. Games-Howell computes every pair as
# undefined and says so.
tid = Create Table with column names: "homog", 12, "value grp"
r = 0
for g from 1 to 3
    for i from 1 to 4
        r = r + 1
        selectObject: tid
        Set numeric value: r, "value", 4.5
        Set string value: r, "grp", "G" + string$ (g)
    endfor
endfor
@runCase: "r05", tid, "all-constant"

# --- r06: non-numeric data column ------------------------------------------
# @eml_getGroupData drops the unusable rows, so this presents as groups with
# fewer than 2 observations -- exactly as it does for @emlOneWayAnova.
tid = Create Table with column names: "homog", 12, "value grp"
r = 0
for g from 1 to 3
    for i from 1 to 4
        r = r + 1
        selectObject: tid
        Set string value: r, "value", "n/a"
        Set string value: r, "grp", "G" + string$ (g)
    endfor
endfor
@runCase: "r06", tid, "non-numeric-data"

# --- r07: fewer than 3 rows ------------------------------------------------
tid = Create Table with column names: "homog", 2, "value grp"
selectObject: tid
Set numeric value: 1, "value", 3
Set string value: 1, "grp", "G1"
Set numeric value: 2, "value", 5
Set string value: 2, "grp", "G2"
@runCase: "r07", tid, "too-few-rows"

# --- r08: missing data column ----------------------------------------------
tid = Create Table with column names: "homog", 6, "value grp"
for r from 1 to 6
    selectObject: tid
    Set numeric value: r, "value", r
    Set string value: r, "grp", "G" + string$ (1 + (r mod 2))
endfor
selectObject: tid
Set column label (label): "value", "notvalue"
@runCase: "r08", tid, "missing-data-column"

writeFileLine: outDir$ + "/manifest.csv", manifest$
writeFileLine: outDir$ + "/results.csv", results$
writeFileLine: outDir$ + "/refusals.tsv", refusals$

writeInfoLine: "homogeneity cases written to ", outDir$
appendInfoLine: "  manifest.csv, results.csv, refusals.tsv, data/*.csv"
