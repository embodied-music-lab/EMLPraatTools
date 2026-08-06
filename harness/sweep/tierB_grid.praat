# ============================================================================
# tierB_grid.praat -- run every orchestrator over a DESIGNED grid of shapes,
# headlessly, and emit the data and the results so R can check all of it.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# The committed suite drives one balanced, complete, tie-free table per test.
# This walks the axes that suite does not move:
#
#     k          2, 3, 5 groups
#     n per cell 3 (the minimum), 8, 30
#     balance    equal, mildly unequal, 6:1 unequal
#     ties       none, moderate (1 dp), heavy (0 dp)
#     variance   equal, 10:1 ratio between cells
#
# Each case writes its data to data/case_NNN.csv and its statistics to
# results.csv in long form. Nothing is compared here -- comparison is R's job
# in validate/v18_sweep_parity.R, so the two halves cannot quietly agree by
# sharing code.
#
#     EML_SWEEP_OUT=evidence/sweep praat --run harness/sweep/tierB_grid.praat
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include lib_sweep.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_SWEEP_OUT")
if outDir$ = ""
    outDir$ = "../../evidence/sweep"
endif
createDirectory: outDir$
createDirectory: outDir$ + "/data"

random_initializeWithSeedUnsafelyButPredictably: 20260806

manifest$ = "case,k,n_total,balance,ties,var_ratio,n_spec" + newline$
results$ = "case,test,statistic,value" + newline$
nCases = 0

# ---------------------------------------------------------------------------
# @emit: .case$, .test$, .stat$, .value
#   17 significant digits, so R's tolerance choice is not constrained by the
#   file. "NA" for undefined, which read.csv turns into R's own NA.
# ---------------------------------------------------------------------------
procedure emit: .case$, .test$, .stat$, .value
    if .value = undefined
        .txt$ = "NA"
    else
        ; string$(), not fixed$(v, 17). fixed$ counts DECIMAL PLACES, not
        ; significant digits: on a quantity of order 1e-8 it keeps only nine
        ; significant digits and silently throws the rest away. That cost two
        ; spurious v19 failures on AtmWtAg before it was noticed -- the
        ; harness was the defect, not the plugin. string$() emits enough
        ; digits to round-trip a double at any magnitude.
        .txt$ = string$ (.value)
    endif
    results$ = results$ + .case$ + "," + .test$ + "," + .stat$ + ","
    ... + .txt$ + newline$
endproc

# ---------------------------------------------------------------------------
# @runCase: .k, .n#, .mean#, .sdBase, .sdRatio, .decimals, .balance$, .ties$
#   Build one table, save it, run both orchestrators, record every number
#   they expose. Unequal variance is applied to the LAST group only, which is
#   the arrangement that makes a pooled-variance test optimistic rather than
#   conservative -- the direction that matters.
# ---------------------------------------------------------------------------
procedure runCase: .k, .n#, .mean#, .sdBase, .sdRatio, .decimals, .balance$, .ties$
    nCases = nCases + 1
    .case$ = "c" + fixed$ (nCases, 0)
    if nCases < 10
        .case$ = "c0" + fixed$ (nCases, 0)
    endif

    .total = 0
    .spec$ = ""
    for .g from 1 to .k
        .total = .total + .n# [.g]
        .spec$ = .spec$ + fixed$ (.n# [.g], 0)
        if .g < .k
            .spec$ = .spec$ + "-"
        endif
    endfor

    .tid = Create Table with column names: .case$, .total, "value grp"
    .r = 0
    for .g from 1 to .k
        .sd = .sdBase
        if .g = .k
            .sd = .sdBase * .sdRatio
        endif
        for .i from 1 to .n# [.g]
            .r = .r + 1
            .v = .mean# [.g] + randomGauss (0, .sd)
            if .decimals >= 0
                .v = round (.v * 10 ^ .decimals) / 10 ^ .decimals
            endif
            selectObject: .tid
            Set numeric value: .r, "value", .v
            Set string value: .r, "grp", "G" + fixed$ (.g, 0)
        endfor
    endfor

    selectObject: .tid
    Save as comma-separated file: outDir$ + "/data/" + .case$ + ".csv"

    manifest$ = manifest$ + .case$ + "," + fixed$ (.k, 0) + ","
    ... + fixed$ (.total, 0) + "," + .balance$ + "," + .ties$ + ","
    ... + fixed$ (.sdRatio, 1) + "," + .spec$ + newline$

    # --- one-way ANOVA with Tukey ---
    @emlOneWayAnova: .tid, "value", "grp", 1
    if emlOneWayAnova.error$ <> ""
        @emit: .case$, "anova", "refused", 1
    else
        @emit: .case$, "anova", "statistic", emlOneWayAnova.fValue
        @emit: .case$, "anova", "p.value", emlOneWayAnova.p
        @emit: .case$, "anova", "df.between", emlOneWayAnova.dfBetween
        @emit: .case$, "anova", "df.within", emlOneWayAnova.dfWithin
        @emit: .case$, "anova", "sumsq.between", emlOneWayAnova.ssBetween
        @emit: .case$, "anova", "sumsq.within", emlOneWayAnova.ssWithin
        @emit: .case$, "anova", "meansq.within", emlOneWayAnova.msWithin
        @emit: .case$, "anova", "eta.squared", emlOneWayAnova.etaSquared
        for .i from 1 to emlOneWayAnova.nGroups - 1
            for .j from .i + 1 to emlOneWayAnova.nGroups
                .pair$ = emlOneWayAnova.groupName$ [.i] + "-"
                ... + emlOneWayAnova.groupName$ [.j]
                @emit: .case$, "tukey", "estimate:" + .pair$,
                ... emlOneWayAnova.meanDiff## [.i, .j]
                @emit: .case$, "tukey", "adj.p.value:" + .pair$,
                ... emlOneWayAnova.pMatrix## [.i, .j]
            endfor
        endfor
    endif

    # --- Kruskal-Wallis ---
    @emlKruskalWallis: .tid, "value", "grp"
    if emlKruskalWallis.error$ <> ""
        @emit: .case$, "kruskal", "refused", 1
    else
        @emit: .case$, "kruskal", "statistic", emlKruskalWallis.h
        @emit: .case$, "kruskal", "p.value", emlKruskalWallis.p
        @emit: .case$, "kruskal", "df", emlKruskalWallis.df
        @emit: .case$, "kruskal", "tie.correction", emlKruskalWallis.tieCorrection
    endif

    removeObject: .tid
endproc

# ===========================================================================
# THE GRID
# ===========================================================================

# --- k = 2 ----------------------------------------------------------------
n# = {8, 8}
m# = {10, 12}
@runCase: 2, n#, m#, 2, 1, -1, "equal", "none"
n# = {3, 3}
m# = {10, 12}
@runCase: 2, n#, m#, 2, 1, -1, "equal", "none"
n# = {30, 5}
m# = {10, 12}
@runCase: 2, n#, m#, 2, 1, -1, "6to1", "none"
n# = {12, 12}
m# = {10, 12}
@runCase: 2, n#, m#, 2, 10, -1, "equal", "none"
n# = {12, 12}
m# = {10, 12}
@runCase: 2, n#, m#, 2, 1, 0, "equal", "heavy"

# --- k = 3 ----------------------------------------------------------------
n# = {8, 8, 8}
m# = {10, 11, 13}
@runCase: 3, n#, m#, 2, 1, -1, "equal", "none"
n# = {3, 3, 3}
m# = {10, 11, 13}
@runCase: 3, n#, m#, 2, 1, -1, "equal", "none"
n# = {30, 12, 5}
m# = {10, 11, 13}
@runCase: 3, n#, m#, 2, 1, -1, "6to1", "none"
n# = {14, 9, 20}
m# = {10, 11, 13}
@runCase: 3, n#, m#, 2, 1, 1, "mild", "moderate"
n# = {14, 14, 14}
m# = {10, 11, 13}
@runCase: 3, n#, m#, 2, 1, 0, "equal", "heavy"
n# = {20, 20, 20}
m# = {10, 11, 13}
@runCase: 3, n#, m#, 2, 10, -1, "equal", "none"
n# = {10, 10, 10}
m# = {10, 10, 10}
@runCase: 3, n#, m#, 2, 1, -1, "equal", "none"

# --- k = 5 ----------------------------------------------------------------
n# = {6, 6, 6, 6, 6}
m# = {10, 11, 12, 13, 14}
@runCase: 5, n#, m#, 2, 1, -1, "equal", "none"
n# = {18, 4, 11, 7, 25}
m# = {10, 11, 12, 13, 14}
@runCase: 5, n#, m#, 2, 1, -1, "6to1", "none"
n# = {12, 12, 12, 12, 12}
m# = {10, 11, 12, 13, 14}
@runCase: 5, n#, m#, 2, 1, 0, "equal", "heavy"

# --- large n, to separate an O(n^2) mistake from an O(n) one --------------
n# = {200, 200, 200}
m# = {10, 10.4, 10.9}
@runCase: 3, n#, m#, 2, 1, -1, "equal", "none"

writeFileLine: outDir$ + "/manifest.csv", manifest$
writeFileLine: outDir$ + "/results.csv", results$

writeInfoLine: "Tier B: ", nCases, " cases written to ", outDir$
appendInfoLine: "  data/case.csv, manifest.csv, results.csv"
