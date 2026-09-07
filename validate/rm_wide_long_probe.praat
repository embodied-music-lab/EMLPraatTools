# ============================================================================
# validate/rm_wide_long_probe.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# EQUIVALENCE PROBE for the two accepted shapes of @emlRunRepeatedMeasuresAnalysis
# and @emlRunFriedmanAnalysis (plugin_EML_StatsGraphs/stats/eml-analysis.praat).
# The frozen 8-argument signature accepts a WIDE table (one row per subject,
# one column per condition) or a LONG table (subject / condition / value); the
# long door reshapes to wide internally (@emlReshapeSeriesWide) and then walks
# the SAME @emlExtractConditionMatrix the wide door walks directly
# (@eml_rmResolveMatrix). On identical underlying data the two doors must
# therefore produce IDENTICAL statistics, and this file's only job is to BUILD
# both shapes from one matrix, DRIVE both orchestrators, and RECORD what came
# back -- it does not decide what counts as agreement; that is
# validate/v166_rm_wide_long_equivalence.R's job, exactly as
# group_extraction_probe.praat's header describes the same division of labour
# for @eml_getGroupData.
#
# THIS FILE ISSUES NO `include`s of its own. It assumes the caller has already
# included the full stats+graphs tree @emlRunRepeatedMeasuresAnalysis and
# @emlRunFriedmanAnalysis need (eml-core-utilities, eml-core-descriptive,
# eml-extract, eml-output, eml-wilcoxon-interval, eml-inferential,
# eml-result-writer, graphs/eml-graph-procedures -- @emlReshapeSeriesWide lives
# there -- graphs/eml-annotation-procedures, and finally eml-analysis.praat
# itself) before including this file. validate/v166_rm_wide_long_equivalence.R
# builds that include list; see its `prelude` function for the exact order,
# copied from validate/v163_hl_paired_disclosure.R's own `prelude`.
#
# WHAT IT DOES NOT REIMPLEMENT. Table construction here writes cells with
# `Set numeric value:` / `Set string value:` and nothing else; every
# statistic -- the condition matrix, the RM-ANOVA and Friedman kernels, the
# post-hoc adjustment -- comes from calling @emlRunRepeatedMeasuresAnalysis
# and @emlRunFriedmanAnalysis themselves, never re-derived here.
#
# ---------------------------------------------------------------------------
# TABLE BUILDERS
# ---------------------------------------------------------------------------
#
# @v166_buildWideTable: .data##, .colNames$#, .exSubj, .exCol
#   One row per subject (1-based numeric "subject" column, unread by the wide
#   door but present for a reader's convenience), one column per
#   .colNames$# entry. When .exSubj > 0, that (subject, condition) cell is
#   left undefined -- the WIDE half of the "one excluded row" fixture Leg A
#   asks for. .exSubj = 0 excludes nothing.
#   Output: .tableId
#
# @v166_buildLongTable: .data##, .colNames$#, .exSubj, .exCol
#   The SAME data, melted subject-major then condition-minor (subject 1's k
#   rows, then subject 2's k rows, ...) into "subject condition value". THE
#   MELT ORDER MATTERS: cycling conditions in .colNames$# order for every
#   subject means the condition column's first-encounter order --
#   @emlCountGroups' own level order, which @eml_rmResolveMatrix's long path
#   uses to build its condition matrix -- is IDENTICAL to .colNames$#'s
#   order, the same order @v166_buildWideTable gives the wide door directly.
#   Without that, the two doors could agree on every statistic and still
#   report condition K under column label K+1's name.
#   When .exSubj > 0, the (subject, condition) ROW IS STILL WRITTEN (pin 3 in
#   @eml_rmResolveMatrix needs every cell present exactly once) but its VALUE
#   is undefined -- the LONG half of the same excluded-row fixture, exercised
#   through the reshape rather than around it.
#   Output: .tableId
#
# @v166_buildLongIncomplete: .data##, .colNames$#, .dropSubj, .dropCol
#   A full melt with exactly one ROW REMOVED -- .dropSubj never has a row for
#   .colNames$# [.dropCol] at all. This is NOT the same fixture as
#   @v166_buildLongTable's .exSubj/.exCol (a present row with an undefined
#   value): here the cell itself never existed, which is what
#   @eml_rmResolveMatrix's pin 3 refuses ("No observation for subject ... in
#   condition ...") rather than silently excluding.
#   Output: .tableId
#
# @v166_buildLongDuplicate: .data##, .colNames$#, .dupSubj, .dupCol
#   A full melt with one extra row appended, repeating .dupSubj's row for
#   .colNames$# [.dupCol] verbatim. Triggers pin 3's other refusal ("Subject
#   ... appears N times in condition ...").
#   Output: .tableId
#
# ---------------------------------------------------------------------------
# DRIVERS -- call the real orchestrator, then dump long-form TSV rows
# ---------------------------------------------------------------------------
#
# @v166_dumpRM / @v166_dumpFriedman:
#   .outTsv$, .dataset$, .pathTag$ ("wide"/"long"), .tableId, .format$,
#   .subjectCol$, .condCols$#, .condCol$, .valueCol$, .adjMethod$
#
#   Calls @emlRunRepeatedMeasuresAnalysis / @emlRunFriedmanAnalysis with
#   .doPostHoc = 1, then writes one TSV row per (dataset, proc, path, field):
#
#     dataset  proc  path  field  value
#
#   `field` is one of: error, warning, ok, n, k, nExcluded, and then --
#   RM only: fStat, dfCond, dfErr, p, ggEpsilon, pGG, ssCond, ssErr
#   Friedman only: chiSq, df, p, kendallsW
#   both: nPairs, then pairKey_i / rawP_i / adjP_i for i = 1..nPairs.
#
#   Every number is written with Praat's `string$ ()`, NOT `fixed$ ()`: Praat
#   6.6.30's `string$` round-trips a double (measured: 0.1 + 0.2 prints as
#   "0.30000000000000004", matching R's own %.17g of the same sum), so two
#   runs whose underlying doubles are bit-identical print identical strings
#   whatever their magnitude -- unlike a fixed decimal width, which floors an
#   F(2,38) p of 3e-29 to "0.0000..." and would call two DIFFERENT tiny p
#   values equal. `undefined` prints as the literal "--undefined--", the same
#   sentinel validate/v163_hl_paired_disclosure.R's `num()` already parses.
#
#   `pairKey_i` is "<colLabelA>-<colLabelB>" for the i-th pair in
#   @emlRMPostHoc's own pairing order (a from 1 to k-1, b from a+1 to k) --
#   written so the R side can confirm the SAME pair occupies slot i on both
#   doors before comparing rawP_i/adjP_i, rather than assuming it.
#
#   On .error$ <> "", only error/warning/ok are written -- there is no n, k,
#   or downstream statistic to report from a refused run.
# ============================================================================

procedure v166_buildWideTable: .data##, .colNames$#, .exSubj, .exCol
    .n = numberOfRows (.data##)
    .k = numberOfColumns (.data##)
    .spec$ = "subject"
    for .j from 1 to .k
        .spec$ = .spec$ + " " + .colNames$# [.j]
    endfor
    .tableId = Create Table with column names: "v166wide", .n, .spec$
    for .i from 1 to .n
        Set numeric value: .i, "subject", .i
        for .j from 1 to .k
            if .i = .exSubj and .j = .exCol
                Set numeric value: .i, .colNames$# [.j], undefined
            else
                Set numeric value: .i, .colNames$# [.j], .data## [.i, .j]
            endif
        endfor
    endfor
endproc

procedure v166_buildLongTable: .data##, .colNames$#, .exSubj, .exCol
    .n = numberOfRows (.data##)
    .k = numberOfColumns (.data##)
    .tableId = Create Table with column names: "v166long", .n * .k,
    ... "subject condition value"
    .r = 0
    for .i from 1 to .n
        for .j from 1 to .k
            .r = .r + 1
            Set numeric value: .r, "subject", .i
            Set string value: .r, "condition", .colNames$# [.j]
            if .i = .exSubj and .j = .exCol
                Set numeric value: .r, "value", undefined
            else
                Set numeric value: .r, "value", .data## [.i, .j]
            endif
        endfor
    endfor
endproc

procedure v166_buildLongIncomplete: .data##, .colNames$#, .dropSubj, .dropCol
    @v166_buildLongTable: .data##, .colNames$#, 0, 0
    .tableId = v166_buildLongTable.tableId
    .k = numberOfColumns (.data##)
    .dropRow = (.dropSubj - 1) * .k + .dropCol
    selectObject: .tableId
    Remove row: .dropRow
endproc

procedure v166_buildLongDuplicate: .data##, .colNames$#, .dupSubj, .dupCol
    @v166_buildLongTable: .data##, .colNames$#, 0, 0
    .tableId = v166_buildLongTable.tableId
    selectObject: .tableId
    Append row
    .newRow = Get number of rows
    Set numeric value: .newRow, "subject", .dupSubj
    Set string value: .newRow, "condition", .colNames$# [.dupCol]
    Set numeric value: .newRow, "value", .data## [.dupSubj, .dupCol]
endproc

procedure v166_tsvHeader: .path$
    deleteFile: .path$
    appendFileLine: .path$, "dataset", tab$, "proc", tab$, "path", tab$,
    ... "field", tab$, "value"
endproc

procedure v166_writeField: .path$, .dataset$, .proc$, .pathTag$, .field$, .value$
    appendFileLine: .path$, .dataset$, tab$, .proc$, tab$, .pathTag$, tab$,
    ... .field$, tab$, .value$
endproc

procedure v166_dumpRM: .outTsv$, .dataset$, .pathTag$, .tableId, .format$,
... .subjectCol$, .condCols$#, .condCol$, .valueCol$, .adjMethod$
    selectObject: .tableId
    @emlRunRepeatedMeasuresAnalysis: .tableId, .format$, .subjectCol$,
    ... .condCols$#, .condCol$, .valueCol$, 1, .adjMethod$
    .err$ = emlRunRepeatedMeasuresAnalysis.error$
    .warn$ = emlRunRepeatedMeasuresAnalysis.warning$
    .ok = emlRunRepeatedMeasuresAnalysis.ok
    @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "error", .err$
    @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "warning", .warn$
    @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "ok", string$ (.ok)
    if .err$ = ""
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "n",
        ... string$ (emlRunRepeatedMeasuresAnalysis.n)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "k",
        ... string$ (emlRunRepeatedMeasuresAnalysis.k)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "nExcluded",
        ... string$ (emlRunRepeatedMeasuresAnalysis.nExcluded)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "fStat",
        ... string$ (emlRMAnovaTest.fStat)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "dfCond",
        ... string$ (emlRMAnovaTest.dfCond)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "dfErr",
        ... string$ (emlRMAnovaTest.dfErr)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "p",
        ... string$ (emlRMAnovaTest.p)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "ggEpsilon",
        ... string$ (emlRMAnovaTest.ggEpsilon)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "pGG",
        ... string$ (emlRMAnovaTest.pGG)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "ssCond",
        ... string$ (emlRMAnovaTest.ssCond)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "ssErr",
        ... string$ (emlRMAnovaTest.ssErr)
        @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$, "nPairs",
        ... string$ (emlRMPostHoc.nPairs)
        for .pp from 1 to emlRMPostHoc.nPairs
            .ai = emlRMPostHoc.pairLabelA [.pp]
            .bi = emlRMPostHoc.pairLabelB [.pp]
            .pairKey$ = emlExtractConditionMatrix.colLabel$ [.ai] + "-"
            ... + emlExtractConditionMatrix.colLabel$ [.bi]
            @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$,
            ... "pairKey_" + string$ (.pp), .pairKey$
            @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$,
            ... "rawP_" + string$ (.pp), string$ (emlRMPostHoc.rawP# [.pp])
            @v166_writeField: .outTsv$, .dataset$, "rm", .pathTag$,
            ... "adjP_" + string$ (.pp), string$ (emlRMPostHoc.adj# [.pp])
        endfor
    endif
endproc

procedure v166_dumpFriedman: .outTsv$, .dataset$, .pathTag$, .tableId, .format$,
... .subjectCol$, .condCols$#, .condCol$, .valueCol$, .adjMethod$
    selectObject: .tableId
    @emlRunFriedmanAnalysis: .tableId, .format$, .subjectCol$, .condCols$#,
    ... .condCol$, .valueCol$, 1, .adjMethod$
    .err$ = emlRunFriedmanAnalysis.error$
    .warn$ = emlRunFriedmanAnalysis.warning$
    .ok = emlRunFriedmanAnalysis.ok
    @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "error", .err$
    @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "warning", .warn$
    @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "ok", string$ (.ok)
    if .err$ = ""
        .n = emlRunFriedmanAnalysis.n
        .k = emlRunFriedmanAnalysis.k
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "n",
        ... string$ (.n)
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "k",
        ... string$ (.k)
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "nExcluded",
        ... string$ (emlRunFriedmanAnalysis.nExcluded)
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "chiSq",
        ... string$ (emlFriedmanTest.chiSq)
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "df",
        ... string$ (emlFriedmanTest.df)
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "p",
        ... string$ (emlFriedmanTest.p)
        ; Kendall's W has no dedicated output field on @emlFriedmanTest -- it
        ; is the same chiSq / (n * (k - 1)) quantity the report line and
        ; helpers.R's own kendalls_w() compute, read here off the SAME .n/.k
        ; the run itself reported rather than off the input matrix, so an
        ; excluded row is accounted for identically to the report.
        .kendallsW = emlFriedmanTest.chiSq / (.n * (.k - 1))
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "kendallsW",
        ... string$ (.kendallsW)
        @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$, "nPairs",
        ... string$ (emlRMPostHoc.nPairs)
        for .pp from 1 to emlRMPostHoc.nPairs
            .ai = emlRMPostHoc.pairLabelA [.pp]
            .bi = emlRMPostHoc.pairLabelB [.pp]
            .pairKey$ = emlExtractConditionMatrix.colLabel$ [.ai] + "-"
            ... + emlExtractConditionMatrix.colLabel$ [.bi]
            @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$,
            ... "pairKey_" + string$ (.pp), .pairKey$
            @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$,
            ... "rawP_" + string$ (.pp), string$ (emlRMPostHoc.rawP# [.pp])
            @v166_writeField: .outTsv$, .dataset$, "friedman", .pathTag$,
            ... "adjP_" + string$ (.pp), string$ (emlRMPostHoc.adj# [.pp])
        endfor
    endif
endproc
