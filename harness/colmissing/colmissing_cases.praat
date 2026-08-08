# ============================================================================
# colmissing_cases.praat -- the MISSING data column, D116.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# harness/coltype drives the twelve ORCHESTRATORS. This file drives the
# eleven table-taking TESTS in stats/eml-inferential.praat directly, because
# that is the layer at which D116 actually lives: an orchestrator that
# refuses with the wrong diagnosis is usually quoting a library test that
# refused with the wrong diagnosis, and a fix applied only at the
# orchestrator leaves every script that calls the test straight -- which is
# the documented, supported way to use eml-lib-stats.praat -- still being
# told its groups are the problem.
#
#     g01 numeric    a clean numeric column       every test must RUN
#     n01 notfound   the column is not there      every test must refuse by
#                                                 NAMING THE COLUMN
#     n02 empty      the column is there and
#                    every cell is empty          a different fault, and it
#                                                 must read differently
#
# The n01/n02 split is the point of the file. "You named a column that is
# not in this table" and "the column you named has nothing in it" have
# different causes and different remedies -- pick another column, versus
# fill in the data -- so they are driven as separate cases and asserted as
# separate messages.
#
# Info window contents are measured after every call, so "printed nothing"
# is a recorded fact. A refusal beside a printed table is the D113 shape and
# a message-only check cannot see it.
#
#     EML_COLMISSING_OUT=harness/colmissing/out \
#         praat --run harness/colmissing/colmissing_cases.praat
#
# Output files (UNQUOTED header cells):
#   manifest.csv   case,n_rows,kind
#   results.csv    case,site,statistic,value      (long form, "NA" = undefined)
#   refusals.tsv   case<TAB>site<TAB>error
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_COLMISSING_OUT")
if outDir$ = ""
    outDir$ = "../../harness/colmissing/out"
endif
createDirectory: outDir$
createDirectory: outDir$ + "/data"

; Alphabetical group order, so the plugin's group index matches the order R
; gets from factor(). Same reason as harness/coltype and harness/homogeneity.
emlGroupSortAlphabetical = 1

manifest$ = "case,n_rows,kind" + newline$
results$ = "case,site,statistic,value" + newline$
refusals$ = "case" + tab$ + "site" + tab$ + "error" + newline$

nRows = 36

procedure emit: .case$, .site$, .stat$, .value
    if .value = undefined
        .txt$ = "NA"
    else
        .txt$ = string$ (.value)
    endif
    results$ = results$ + .case$ + "," + .site$ + "," + .stat$ + ","
    ... + .txt$ + newline$
endproc

procedure refuse: .case$, .site$, .message$
    results$ = results$ + .case$ + "," + .site$ + ",refused,1" + newline$
    refusals$ = refusals$ + .case$ + tab$ + .site$ + tab$ + .message$
    ... + newline$
endproc

# ---------------------------------------------------------------------------
# @buildTable: .kind$
#   grp3  3 levels, 12 rows each   the factor for every k-group test
#   f2    2 levels, crossed        second factor, for the two-way only
#   y     THE MEASUREMENT COLUMN   swapped per case
#
#   f2 is crossed with grp3 nine/three ways so the two-way design is
#   balanced (6 per cell); an unbalanced design would make Type I and Type
#   III sums of squares differ and the R-side comparison ambiguous.
# ---------------------------------------------------------------------------
procedure buildTable: .kind$
    .tid = Create Table with column names: "colmissing", nRows, "grp3 f2 y"
    for .i from 1 to nRows
        selectObject: .tid
        Set string value: .i, "grp3", "H" + string$ (1 + ((.i - 1) mod 3))
        if (.i - 1) mod 6 < 3
            Set string value: .i, "f2", "T1"
        else
            Set string value: .i, "f2", "T2"
        endif
        ; The ((i-1) mod 3) term is the grp3 effect: without it every k-group
        ; test sits on the null and Holm caps every adjusted p at 1, which
        ; asserts nothing about the arithmetic.
        .yVal = 80 + (.i mod 7) * 1.5 + (.i mod 5) * 0.75 + .i * 0.1
        ... + ((.i - 1) mod 3) * 1.6
        if .kind$ = "empty"
            Set string value: .i, "y", ""
        else
            Set numeric value: .i, "y", .yVal
        endif
    endfor
    if .kind$ = "notfound"
        selectObject: .tid
        Set column label (label): "y", "not_y"
    endif
endproc

# ---------------------------------------------------------------------------
# @runCase -- every table-taking test in eml-inferential.praat, in file order.
# ---------------------------------------------------------------------------
procedure runCase: .case$, .kind$
    @buildTable: .kind$
    .tid = buildTable.tid
    selectObject: .tid
    Save as comma-separated file: outDir$ + "/data/" + .case$ + ".csv"
    manifest$ = manifest$ + .case$ + "," + string$ (nRows) + ","
    ... + .kind$ + newline$

    ; --- @emlTukeyHSD -------------------------------------------------------
    clearinfo
    @emlTukeyHSD: .tid, "y", "grp3", 0.05
    .out$ = info$ ()
    if emlTukeyHSD.error$ <> ""
        @refuse: .case$, "tukey", emlTukeyHSD.error$
    else
        @emit: .case$, "tukey", "p:1-2", emlTukeyHSD.pMatrix## [1, 2]
        @emit: .case$, "tukey", "p:1-3", emlTukeyHSD.pMatrix## [1, 3]
        @emit: .case$, "tukey", "p:2-3", emlTukeyHSD.pMatrix## [2, 3]
        @emit: .case$, "tukey", "n.pairs", emlTukeyHSD.nPairs
    endif
    @emit: .case$, "tukey", "output.chars", length (.out$)

    ; --- @emlOneWayAnova ----------------------------------------------------
    clearinfo
    @emlOneWayAnova: .tid, "y", "grp3", 0
    .out$ = info$ ()
    if emlOneWayAnova.error$ <> ""
        @refuse: .case$, "anova", emlOneWayAnova.error$
    else
        @emit: .case$, "anova", "statistic", emlOneWayAnova.fValue
        @emit: .case$, "anova", "p.value", emlOneWayAnova.p
        @emit: .case$, "anova", "df1", emlOneWayAnova.dfBetween
        @emit: .case$, "anova", "df2", emlOneWayAnova.dfWithin
    endif
    @emit: .case$, "anova", "output.chars", length (.out$)

    ; --- @emlTwoWayAnova ----------------------------------------------------
    clearinfo
    @emlTwoWayAnova: .tid, "y", "grp3", "f2"
    .out$ = info$ ()
    if emlTwoWayAnova.error$ <> ""
        @refuse: .case$, "twoway", emlTwoWayAnova.error$
    else
        @emit: .case$, "twoway", "statistic:A", emlTwoWayAnova.fA
        @emit: .case$, "twoway", "statistic:B", emlTwoWayAnova.fB
        @emit: .case$, "twoway", "ss.error", emlTwoWayAnova.ssError
    endif
    @emit: .case$, "twoway", "output.chars", length (.out$)

    ; --- @emlKruskalWallis --------------------------------------------------
    clearinfo
    @emlKruskalWallis: .tid, "y", "grp3"
    .out$ = info$ ()
    if emlKruskalWallis.error$ <> ""
        @refuse: .case$, "kw", emlKruskalWallis.error$
    else
        @emit: .case$, "kw", "statistic", emlKruskalWallis.h
        @emit: .case$, "kw", "p.value", emlKruskalWallis.p
        @emit: .case$, "kw", "df", emlKruskalWallis.df
        @emit: .case$, "kw", "n", emlKruskalWallis.n
    endif
    @emit: .case$, "kw", "output.chars", length (.out$)

    ; --- @emlDunnTest -------------------------------------------------------
    clearinfo
    @emlDunnTest: .tid, "y", "grp3", "holm"
    .out$ = info$ ()
    if emlDunnTest.error$ <> ""
        @refuse: .case$, "dunn", emlDunnTest.error$
    else
        @emit: .case$, "dunn", "p:1-2", emlDunnTest.pMatrix## [1, 2]
        @emit: .case$, "dunn", "p:1-3", emlDunnTest.pMatrix## [1, 3]
        @emit: .case$, "dunn", "p:2-3", emlDunnTest.pMatrix## [2, 3]
    endif
    @emit: .case$, "dunn", "output.chars", length (.out$)

    ; --- @emlPairwiseT ------------------------------------------------------
    clearinfo
    @emlPairwiseT: .tid, "y", "grp3", "holm", "welch"
    .out$ = info$ ()
    if emlPairwiseT.error$ <> ""
        @refuse: .case$, "pairwiset", emlPairwiseT.error$
    else
        @emit: .case$, "pairwiset", "p:1-2", emlPairwiseT.pMatrix## [1, 2]
        @emit: .case$, "pairwiset", "p:1-3", emlPairwiseT.pMatrix## [1, 3]
        @emit: .case$, "pairwiset", "p:2-3", emlPairwiseT.pMatrix## [2, 3]
        @emit: .case$, "pairwiset", "t:1-2", emlPairwiseT.tMatrix## [1, 2]
    endif
    @emit: .case$, "pairwiset", "output.chars", length (.out$)

    ; --- @emlPairwiseWilcoxon -----------------------------------------------
    clearinfo
    @emlPairwiseWilcoxon: .tid, "y", "grp3", "holm"
    .out$ = info$ ()
    if emlPairwiseWilcoxon.error$ <> ""
        @refuse: .case$, "pairwisew", emlPairwiseWilcoxon.error$
    else
        @emit: .case$, "pairwisew", "p:1-2",
        ... emlPairwiseWilcoxon.pMatrix## [1, 2]
        @emit: .case$, "pairwisew", "p:1-3",
        ... emlPairwiseWilcoxon.pMatrix## [1, 3]
        @emit: .case$, "pairwisew", "p:2-3",
        ... emlPairwiseWilcoxon.pMatrix## [2, 3]
    endif
    @emit: .case$, "pairwisew", "output.chars", length (.out$)

    ; --- @emlScheffe --------------------------------------------------------
    clearinfo
    @emlScheffe: .tid, "y", "grp3"
    .out$ = info$ ()
    if emlScheffe.error$ <> ""
        @refuse: .case$, "scheffe", emlScheffe.error$
    else
        @emit: .case$, "scheffe", "p:1-2", emlScheffe.pMatrix## [1, 2]
        @emit: .case$, "scheffe", "f:1-2", emlScheffe.fMatrix## [1, 2]
        @emit: .case$, "scheffe", "mse", emlScheffe.mse
    endif
    @emit: .case$, "scheffe", "output.chars", length (.out$)

    ; --- @emlBrownForsythe --------------------------------------------------
    clearinfo
    @emlBrownForsythe: .tid, "y", "grp3"
    .out$ = info$ ()
    if emlBrownForsythe.error$ <> ""
        @refuse: .case$, "bf", emlBrownForsythe.error$
    else
        @emit: .case$, "bf", "statistic", emlBrownForsythe.f
        @emit: .case$, "bf", "p.value", emlBrownForsythe.p
    endif
    @emit: .case$, "bf", "output.chars", length (.out$)

    ; --- @emlWelchAnova -----------------------------------------------------
    clearinfo
    @emlWelchAnova: .tid, "y", "grp3"
    .out$ = info$ ()
    if emlWelchAnova.error$ <> ""
        @refuse: .case$, "welch", emlWelchAnova.error$
    else
        @emit: .case$, "welch", "statistic", emlWelchAnova.f
        @emit: .case$, "welch", "p.value", emlWelchAnova.p
        @emit: .case$, "welch", "df1", emlWelchAnova.df1
        @emit: .case$, "welch", "df2", emlWelchAnova.df2
    endif
    @emit: .case$, "welch", "output.chars", length (.out$)

    ; --- @emlGamesHowell ----------------------------------------------------
    clearinfo
    @emlGamesHowell: .tid, "y", "grp3", 0.05
    .out$ = info$ ()
    if emlGamesHowell.error$ <> ""
        @refuse: .case$, "gh", emlGamesHowell.error$
    else
        @emit: .case$, "gh", "p:1-2", emlGamesHowell.pMatrix## [1, 2]
        @emit: .case$, "gh", "n.pairs", emlGamesHowell.nPairs
    endif
    @emit: .case$, "gh", "output.chars", length (.out$)

    selectObject: .tid
    Remove
endproc

@runCase: "g01", "numeric"
@runCase: "n01", "notfound"
@runCase: "n02", "empty"

writeFileLine: outDir$ + "/manifest.csv", manifest$ - newline$
writeFileLine: outDir$ + "/results.csv", results$ - newline$
writeFileLine: outDir$ + "/refusals.tsv", refusals$ - newline$

writeInfoLine: "missing-column cases written to ", outDir$
appendInfoLine: "  manifest.csv, results.csv, refusals.tsv, data/*.csv"
