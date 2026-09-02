# ============================================================================
# coltype_cases.praat -- headless driver for the column-type guard, D113.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Drives EVERY orchestrator in stats/eml-analysis.praat that takes a column
# of measurements, over one fixed design whose measurement column is swapped
# for a different KIND of column in each case:
#
#     c01 numeric   a clean numeric column        every analysis must RUN
#     m01 mixed     numeric with one "n/a"        drop-and-disclose, except
#                                                 two-way, which refuses
#     r01 string    subject identifiers           every analysis must REFUSE
#     r02 empty     every cell empty              every analysis must REFUSE
#     r03 locale    every cell "1,5"              every analysis must REFUSE
#     r04 notfound  the column is not there       the CALLER's own not-found
#                                                 message must survive
#     r05 string-second   text in the SECOND column of a two-column test:
#                   the three orchestrators that take a pair must refuse
#                   naming THAT column, and the nine that never look at it
#                   must be unaffected
#
# Nothing is compared here. Each case writes its table to data/<case>.csv and
# every statistic each orchestrator produced to results.csv in long form;
# validate/v28_column_type_guard.R recomputes the green paths in base R and
# asserts the refusals verbatim, so the two halves cannot agree by sharing
# code.
#
# THE SAME COLUMN THROUGHOUT. Every orchestrator is pointed at the column
# named "y", whatever its role in that test -- data column, X column,
# dependent column, first condition. The refusals therefore differ only in
# the role word, and a validator can assert that they are otherwise
# identical. That is the uniformity claim, made checkable.
#
#     EML_COLTYPE_OUT=harness/coltype/out praat --run harness/coltype/coltype_cases.praat
#
# Output files (all with UNQUOTED header cells):
#   manifest.csv   case,n_rows,kind
#   results.csv    case,test,statistic,value      (long form, "NA" = undefined)
#   refusals.tsv   case<TAB>test<TAB>error        (tab-separated: the refusal
#                  messages contain commas AND double quotes)
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_COLTYPE_OUT")
if outDir$ = ""
    outDir$ = "../../harness/coltype/out"
endif
createDirectory: outDir$
createDirectory: outDir$ + "/data"

; Alphabetical group order, so the plugin's group index matches the order R
; gets from factor(). Same reason as harness/homogeneity.
emlGroupSortAlphabetical = 1

manifest$ = "case,n_rows,kind" + newline$
results$ = "case,test,statistic,value" + newline$
refusals$ = "case" + tab$ + "test" + tab$ + "error" + newline$

nRows = 36

# ---------------------------------------------------------------------------
# @emit / @refuse -- same contract as harness/homogeneity/homogeneity_cases.
#   string$(), not fixed$(): fixed$ counts DECIMAL PLACES and would discard
#   most of the mantissa of a small p. "NA" for undefined, which read.csv
#   turns into R's own NA.
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

procedure refuse: .case$, .test$, .message$
    results$ = results$ + .case$ + "," + .test$ + ",refused,1" + newline$
    refusals$ = refusals$ + .case$ + tab$ + .test$ + tab$ + .message$
    ... + newline$
endproc

# ---------------------------------------------------------------------------
# @buildTable: .kind$
#   One design, six measurement columns' worth of content.
#
#   grp   2 levels, 18 rows each          two-group, two-way factor 1
#   f2    2 levels, crossed 9 per cell    two-way factor 2 (balanced)
#   grp3  3 levels, 12 rows each          ANOVA / Kruskal-Wallis / pairwise
#   y     THE MEASUREMENT COLUMN          swapped per case
#   x     numeric, always clean           correlation Y, regression predictor,
#                                         paired second column
#   c2 c3 numeric, always clean           RM / Friedman conditions 2 and 3
#
#   x, c2 and c3 stay clean in every case so that a refusal can only be
#   coming from "y". A guard that refused whenever ANY column were unusable
#   would pass a test that dirtied them all.
# ---------------------------------------------------------------------------
procedure buildTable: .kind$
    .tid = Create Table with column names: "coltype", nRows,
    ... "grp f2 grp3 y x c2 c3"
    for .i from 1 to nRows
        selectObject: .tid
        if .i <= 18
            Set string value: .i, "grp", "G1"
        else
            Set string value: .i, "grp", "G2"
        endif
        if (.i - 1) mod 18 < 9
            Set string value: .i, "f2", "T1"
        else
            Set string value: .i, "f2", "T2"
        endif
        Set string value: .i, "grp3", "H" + string$ (1 + ((.i - 1) mod 3))
        ; x is clean in every case but "string-second", which exists purely
        ; to reach the SECOND column of the three two-column orchestrators.
        ; Without it the role words "Second column", "Y column" and
        ; "Predictor column" are never produced, and a copy-paste slip at one
        ; of those three call sites would go unseen.
        if .kind$ = "string-second"
            Set string value: .i, "x", "Take_" + string$ (.i)
        else
            Set numeric value: .i, "x", 20 + (.i mod 11) * 0.5 - .i * 0.05
        endif
        ; c2 and c3 OVERLAP the range of y on purpose. Stacked, disjoint
        ; conditions make Friedman's chi-square hit its ceiling n(k-1) and
        ; the RM F run to four figures, and a validator that only ever sees
        ; a degenerate statistic is not testing much.
        Set numeric value: .i, "c2", 80 + (.i mod 3) * 1.25 + .i * 0.2
        Set numeric value: .i, "c3", 84 + (.i mod 4) * 0.75 - .i * 0.15

        ; The measurement column. The numeric content is the same in every
        ; case that has any, so the mixed case differs from the clean case
        ; in exactly one cell. The ((i-1) mod 3) term is the grp3 effect --
        ; without it the one-way ANOVA, Kruskal-Wallis and all three pairwise
        ; comparisons sit on the null and Holm caps every adjusted p at 1.
        .yVal = 80 + (.i mod 7) * 1.5 + (.i mod 5) * 0.75 + .i * 0.1
        ... + ((.i - 1) mod 3) * 1.6
        if .kind$ = "string"
            Set string value: .i, "y", "Singer_" + string$ (.i)
        elsif .kind$ = "empty"
            Set string value: .i, "y", ""
        elsif .kind$ = "locale"
            ; A European decimal comma. Praat's LENIENT reader turns "1,5"
            ; into 1 -- a plausible wrong number, not a dropped row -- which
            ; is why @emlAuditColumn counts it separately and why a column
            ; made entirely of these must refuse rather than analyse 36
            ; copies of the integer 1.
            Set string value: .i, "y", "1,5"
        else
            Set numeric value: .i, "y", .yVal
        endif
    endfor

    if .kind$ = "mixed"
        selectObject: .tid
        Set string value: 3, "y", "n/a"
    endif

    if .kind$ = "notfound"
        selectObject: .tid
        Set column label (label): "y", "not_y"
    endif
endproc

# ---------------------------------------------------------------------------
# @runCase: .case$, .kind$
#   Build the table, save it, and drive all twelve orchestrators over it.
#
#   The Info window is cleared before each orchestrator and its contents
#   measured after, so "printed a result table" and "printed nothing" are
#   recorded facts rather than inferences from error$. That distinction is
#   the whole finding: the two-way ANOVA had an EMPTY error$ and a full
#   result table.
# ---------------------------------------------------------------------------
procedure runCase: .case$, .kind$
    @buildTable: .kind$
    .tid = buildTable.tid
    selectObject: .tid
    Save as comma-separated file: outDir$ + "/data/" + .case$ + ".csv"
    manifest$ = manifest$ + .case$ + "," + string$ (nRows) + ","
    ... + .kind$ + newline$

    ; --- 1. two-group -------------------------------------------------------
    clearinfo
    @emlRunTwoGroupAnalysis: .tid, "y", "grp", "both", 0
    .out$ = info$ ()
    if emlRunTwoGroupAnalysis.error$ <> ""
        @refuse: .case$, "twogroup", emlRunTwoGroupAnalysis.error$
    else
        @emit: .case$, "twogroup", "n1", emlRunTwoGroupAnalysis.n1
        @emit: .case$, "twogroup", "n2", emlRunTwoGroupAnalysis.n2
        @emit: .case$, "twogroup", "mean1", emlRunTwoGroupAnalysis.mean1
        @emit: .case$, "twogroup", "mean2", emlRunTwoGroupAnalysis.mean2
        @emit: .case$, "twogroup", "t", emlTTest.t
        @emit: .case$, "twogroup", "df", emlTTest.df
        @emit: .case$, "twogroup", "p.value", emlTTest.p
    endif
    @emit: .case$, "twogroup", "output.chars", length (.out$)

    ; --- 2. one-way ANOVA ---------------------------------------------------
    clearinfo
    @emlRunAnovaAnalysis: .tid, "y", "grp3", 1
    .out$ = info$ ()
    if emlRunAnovaAnalysis.error$ <> ""
        @refuse: .case$, "anova", emlRunAnovaAnalysis.error$
    else
        @emit: .case$, "anova", "statistic", emlOneWayAnova.fValue
        @emit: .case$, "anova", "p.value", emlOneWayAnova.p
        @emit: .case$, "anova", "df1", emlOneWayAnova.dfBetween
        @emit: .case$, "anova", "df2", emlOneWayAnova.dfWithin
        @emit: .case$, "anova", "ss.between", emlOneWayAnova.ssBetween
        @emit: .case$, "anova", "ss.within", emlOneWayAnova.ssWithin
        for .g from 1 to emlOneWayAnova.nGroups
            @emit: .case$, "anova", "n:" + emlOneWayAnova.groupLabel$ [.g],
            ... emlOneWayAnova.groupN [.g]
        endfor
    endif
    @emit: .case$, "anova", "output.chars", length (.out$)

    ; --- 3. Kruskal-Wallis --------------------------------------------------
    clearinfo
    @emlRunKruskalWallisAnalysis: .tid, "y", "grp3", 1, "holm"
    .out$ = info$ ()
    if emlRunKruskalWallisAnalysis.error$ <> ""
        @refuse: .case$, "kw", emlRunKruskalWallisAnalysis.error$
    else
        @emit: .case$, "kw", "statistic", emlKruskalWallis.h
        @emit: .case$, "kw", "p.value", emlKruskalWallis.p
        @emit: .case$, "kw", "df", emlKruskalWallis.df
        @emit: .case$, "kw", "n", emlKruskalWallis.n
    endif
    @emit: .case$, "kw", "output.chars", length (.out$)

    ; --- 4. pairwise (Welch t, Holm) ---------------------------------------
    clearinfo
    @emlRunPairwiseAnalysis: .tid, "y", "grp3", "welch", "holm"
    .out$ = info$ ()
    if emlRunPairwiseAnalysis.error$ <> ""
        @refuse: .case$, "pairwise", emlRunPairwiseAnalysis.error$
    else
        for .i from 1 to emlPairwiseT.nGroups - 1
            for .j from .i + 1 to emlPairwiseT.nGroups
                .pair$ = emlPairwiseT.groupName$ [.i] + "-"
                ... + emlPairwiseT.groupName$ [.j]
                @emit: .case$, "pairwise", "adj.p.value:" + .pair$,
                ... emlPairwiseT.pMatrix## [.i, .j]
                @emit: .case$, "pairwise", "t:" + .pair$,
                ... emlPairwiseT.tMatrix## [.i, .j]
            endfor
        endfor
    endif
    @emit: .case$, "pairwise", "output.chars", length (.out$)

    ; --- 5. two-way ANOVA ---------------------------------------------------
    ; The defect that opened D113. @emlTwoWayAnova clears the Info window
    ; itself (Praat's built-in uses MelderInfo_open), so what is measured
    ; here is what the USER is left looking at.
    clearinfo
    @emlRunTwoWayAnalysis: .tid, "y", "grp", "f2"
    .out$ = info$ ()
    if emlRunTwoWayAnalysis.error$ <> ""
        @refuse: .case$, "twoway", emlRunTwoWayAnalysis.error$
    else
        @emit: .case$, "twoway", "statistic:A", emlTwoWayAnova.fA
        @emit: .case$, "twoway", "p.value:A", emlTwoWayAnova.pA
        @emit: .case$, "twoway", "statistic:B", emlTwoWayAnova.fB
        @emit: .case$, "twoway", "p.value:B", emlTwoWayAnova.pB
        @emit: .case$, "twoway", "statistic:AB", emlTwoWayAnova.fAB
        @emit: .case$, "twoway", "p.value:AB", emlTwoWayAnova.pAB
        @emit: .case$, "twoway", "ss:A", emlTwoWayAnova.ssA
        @emit: .case$, "twoway", "ss:B", emlTwoWayAnova.ssB
        @emit: .case$, "twoway", "ss:AB", emlTwoWayAnova.ssAB
        @emit: .case$, "twoway", "ss.error", emlTwoWayAnova.ssError
        @emit: .case$, "twoway", "df.error", emlTwoWayAnova.dfError
    endif
    @emit: .case$, "twoway", "output.chars", length (.out$)

    ; --- 6. paired ----------------------------------------------------------
    clearinfo
    @emlRunPairedAnalysis: .tid, "y", "x", "both"
    .out$ = info$ ()
    if emlRunPairedAnalysis.error$ <> ""
        @refuse: .case$, "paired", emlRunPairedAnalysis.error$
    else
        @emit: .case$, "paired", "n", emlRunPairedAnalysis.n
        @emit: .case$, "paired", "n.excluded", emlRunPairedAnalysis.nExcluded
        @emit: .case$, "paired", "statistic", emlTTestPaired.t
        @emit: .case$, "paired", "df", emlTTestPaired.df
        @emit: .case$, "paired", "p.value", emlTTestPaired.p
    endif
    @emit: .case$, "paired", "output.chars", length (.out$)

    ; --- 7. correlation -----------------------------------------------------
    ; Read from the ORCHESTRATOR's captured locals, not from
    ; emlPearsonCorrelation.*: @emlSpearmanCorrelation re-enters the Pearson
    ; procedure on the ranks (v1.2 item 3).
    clearinfo
    @emlRunCorrelationAnalysis: .tid, "y", "x", "both"
    .out$ = info$ ()
    if emlRunCorrelationAnalysis.error$ <> ""
        @refuse: .case$, "correlation", emlRunCorrelationAnalysis.error$
    else
        @emit: .case$, "correlation", "n", emlRunCorrelationAnalysis.n
        @emit: .case$, "correlation", "n.excluded",
        ... emlRunCorrelationAnalysis.nExcluded
        @emit: .case$, "correlation", "estimate",
        ... emlRunCorrelationAnalysis.pearR
        @emit: .case$, "correlation", "p.value",
        ... emlRunCorrelationAnalysis.pearP
        @emit: .case$, "correlation", "rho",
        ... emlRunCorrelationAnalysis.spearRho
    endif
    @emit: .case$, "correlation", "output.chars", length (.out$)

    ; --- 8. descriptive -----------------------------------------------------
    clearinfo
    @emlRunDescriptiveAnalysis: .tid, "y"
    .out$ = info$ ()
    if emlRunDescriptiveAnalysis.error$ <> ""
        @refuse: .case$, "descriptive", emlRunDescriptiveAnalysis.error$
    else
        @emit: .case$, "descriptive", "n", emlRunDescriptiveAnalysis.nValid
        @emit: .case$, "descriptive", "n.excluded",
        ... emlRunDescriptiveAnalysis.nUndefined
        @emit: .case$, "descriptive", "mean", emlDescribe.mean
        @emit: .case$, "descriptive", "sd", emlDescribe.sd
        @emit: .case$, "descriptive", "median", emlDescribe.median
    endif
    @emit: .case$, "descriptive", "output.chars", length (.out$)

    ; --- 9. regression ------------------------------------------------------
    clearinfo
    @emlRunRegressionAnalysis: .tid, "y", "x"
    .out$ = info$ ()
    if emlRunRegressionAnalysis.error$ <> ""
        @refuse: .case$, "regression", emlRunRegressionAnalysis.error$
    else
        @emit: .case$, "regression", "n", emlRunRegressionAnalysis.nValid
        @emit: .case$, "regression", "slope", emlLinearRegression.slope
        @emit: .case$, "regression", "intercept",
        ... emlLinearRegression.intercept
        @emit: .case$, "regression", "r.squared",
        ... emlLinearRegression.rSquared
        @emit: .case$, "regression", "p.value", emlLinearRegression.pSlope
    endif
    @emit: .case$, "regression", "output.chars", length (.out$)

    ; --- 10. normality ------------------------------------------------------
    clearinfo
    @emlRunNormalityAnalysis: .tid, "y", "both"
    .out$ = info$ ()
    if emlRunNormalityAnalysis.error$ <> ""
        @refuse: .case$, "normality", emlRunNormalityAnalysis.error$
    else
        @emit: .case$, "normality", "n", emlRunNormalityAnalysis.nValid
        @emit: .case$, "normality", "statistic", emlShapiroWilk.w
        @emit: .case$, "normality", "p.value", emlShapiroWilk.p
    endif
    @emit: .case$, "normality", "output.chars", length (.out$)

    ; --- 11. repeated measures ---------------------------------------------
    clearinfo
    @emlRunRepeatedMeasuresAnalysis: .tid, "grp", "y|c2|c3", 1, "holm"
    .out$ = info$ ()
    if emlRunRepeatedMeasuresAnalysis.error$ <> ""
        @refuse: .case$, "rm", emlRunRepeatedMeasuresAnalysis.error$
    else
        @emit: .case$, "rm", "n", emlRunRepeatedMeasuresAnalysis.n
        @emit: .case$, "rm", "k", emlRunRepeatedMeasuresAnalysis.k
        @emit: .case$, "rm", "n.excluded",
        ... emlRunRepeatedMeasuresAnalysis.nExcluded
        @emit: .case$, "rm", "statistic", emlRMAnovaTest.fStat
        @emit: .case$, "rm", "df1", emlRMAnovaTest.dfCond
        @emit: .case$, "rm", "df2", emlRMAnovaTest.dfErr
        @emit: .case$, "rm", "p.value", emlRMAnovaTest.p
        @emit: .case$, "rm", "gg.epsilon", emlRMAnovaTest.ggEpsilon
    endif
    @emit: .case$, "rm", "output.chars", length (.out$)

    ; --- 12. Friedman -------------------------------------------------------
    clearinfo
    @emlRunFriedmanAnalysis: .tid, "grp", "y|c2|c3", 1, "holm"
    .out$ = info$ ()
    if emlRunFriedmanAnalysis.error$ <> ""
        @refuse: .case$, "friedman", emlRunFriedmanAnalysis.error$
    else
        @emit: .case$, "friedman", "n", emlRunFriedmanAnalysis.n
        @emit: .case$, "friedman", "k", emlRunFriedmanAnalysis.k
        @emit: .case$, "friedman", "statistic", emlFriedmanTest.chiSq
        @emit: .case$, "friedman", "df", emlFriedmanTest.df
        @emit: .case$, "friedman", "p.value", emlFriedmanTest.p
    endif
    @emit: .case$, "friedman", "output.chars", length (.out$)

    removeObject: .tid
endproc

@runCase: "c01", "numeric"
@runCase: "m01", "mixed"
@runCase: "r01", "string"
@runCase: "r02", "empty"
@runCase: "r03", "locale"
@runCase: "r04", "notfound"
@runCase: "r05", "string-second"

writeFileLine: outDir$ + "/manifest.csv", manifest$
writeFileLine: outDir$ + "/results.csv", results$
writeFileLine: outDir$ + "/refusals.tsv", refusals$

writeInfoLine: "column-type cases written to ", outDir$
appendInfoLine: "  manifest.csv, results.csv, refusals.tsv, data/*.csv"
