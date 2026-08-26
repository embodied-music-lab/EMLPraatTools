; ============================================================================
; harness/bridgeconsume/probe.praat -- what the BRIDGE does with a publication
; ============================================================================
; Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
;
; THE READ SIDE, MEASURED IN ISOLATION FROM THE WRITE SIDE. The store's single
; write site is a separate piece of work; this probe stands a publication up
; BY HAND, in the published names the read side's contract block names, and
; drives @emlBridgeGroupComparison against it. That is deliberate rather than
; a stopgap: the read side's contract is "given these globals, do this", and a
; probe that could only run once the writer existed would be testing the pair
; and not the rule.
;
; WHAT IT WRITES DOWN, per case: the verdict, whether a report was authorised,
; the announcement line if there was one, and the annotation the figure ends
; up carrying -- the omnibus sentence, the bracket count, the pairwise p and
; effect size, and both halves of the caption. Those are the observables a
; reader of the figure has.
;
; Reads no evidence and asserts nothing. It MEASURES, into a TSV, and
; validate/v140_bridge_consumption.R is what asserts.
;
; Argument (Praat form, driven by run.sh):
;   outDir$   where CONSUME.tsv is written
; ============================================================================
form: "Bridge consumption probe"
    sentence: "outDir", ""
endform

include ../../plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ../../plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ../../plugin_EML_StatsGraphs/stats/eml-extract.praat
include ../../plugin_EML_StatsGraphs/stats/eml-output.praat
include ../../plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ../../plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat

out$ = outDir$ + "/CONSUME.tsv"
writeFileLine: out$, "case", "field", "value"

procedure note: .case$, .field$, .value$
    appendFileLine: out$, .case$, tab$, .field$, tab$, .value$
endproc

; ---------------------------------------------------------------------------
; The fixture. Three groups, NOT in alphabetical order in the table, so the
; sort-order setting names different groups first.
; ---------------------------------------------------------------------------
procedure addRow: .v, .g$
    Append row
    .r = Get number of rows
    Set numeric value: .r, "value", .v
    Set string value: .r, "group", .g$
endproc

tableId = Create Table with column names: "consumefix", 0, "value group"
@addRow: 10.1, "Zebra"
@addRow: 10.4, "Zebra"
@addRow: 10.9, "Zebra"
@addRow: 11.2, "Zebra"
@addRow:  7.1, "Mid"
@addRow:  7.6, "Mid"
@addRow:  8.0, "Mid"
@addRow:  8.4, "Mid"
@addRow:  4.2, "Alpha"
@addRow:  4.8, "Alpha"
@addRow:  5.1, "Alpha"
@addRow:  5.6, "Alpha"

twoId = Create Table with column names: "consumefix2", 0, "value group"
selectObject: twoId
@addRow: 10.1, "Zebra"
@addRow: 10.4, "Zebra"
@addRow: 10.9, "Zebra"
@addRow: 11.2, "Zebra"
@addRow:  4.2, "Alpha"
@addRow:  4.8, "Alpha"
@addRow:  5.1, "Alpha"
@addRow:  5.6, "Alpha"

emlGroupSortAlphabetical = 0
annotCorrectionMethod$ = "holm"

; ---------------------------------------------------------------------------
; @drive -- one bridge call, with the Info window cleared first so the lines
; this draw produced can be told from the lines the last one did. THE INFO
; WINDOW IS THE OBSERVABLE the reprint rule is about, so it is read rather
; than reasoned about.
; ---------------------------------------------------------------------------
procedure drive: .case$, .tid, .layout
    writeInfo: ""
    @emlClearAnnotations
    @emlBridgeGroupComparison: .tid, "value", "group", 0.05, "p-value", 1, 1,
    ... testType$, .layout
    .said$ = info$ ()

    @note: .case$, "verdict", emlBridgeGroupComparison.verdict$
    @note: .case$, "consumed", string$ (emlBridgeGroupComparison.consumed)
    @note: .case$, "printReport", string$ (emlBridgeGroupComparison.printReport)
    @note: .case$, "note", emlBridgeGroupComparison.note$
    @note: .case$, "error", emlBridgeGroupComparison.error$
    @note: .case$, "omnibus", emlBridgeGroupComparison.omnibus$
    @note: .case$, "nGroups", string$ (emlBridgeGroupComparison.nGroups)
    @note: .case$, "bracketN", string$ (annotBracketN)
    @note: .case$, "matrixN", string$ (annotMatrixN)
    @note: .case$, "captionTest", annotBracketPosthoc$
    @note: .case$, "captionAdjust", annotBracketAdjust$
    @note: .case$, "matrixPosthoc", annotMatrixPosthoc$
    ; Every line the Info window gained, with newlines turned into pipes so
    ; one measurement is one TSV cell.
    @note: .case$, "infoLines", replace$ (.said$, newline$, " | ", 0)
    ; THE MATRIX CELLS, which are the other layout's observable and the one
    ; the remap can get wrong: the store's matrices are indexed by ITS labels
    ; and the panel is indexed by the x axis.
    for .i from 1 to annotMatrixN - 1
        for .j from .i + 1 to annotMatrixN
            @note: .case$, "cell" + string$ (.i) + "_" + string$ (.j),
            ... annotMatrixCell'.i'_'.j'$
            @note: .case$, "cellD" + string$ (.i) + "_" + string$ (.j),
            ... string$ (annotMatrixD'.i'_'.j')
            @note: .case$, "cellSig" + string$ (.i) + "_" + string$ (.j),
            ... string$ (annotMatrixSig'.i'_'.j')
        endfor
    endfor
    for .i from 1 to annotMatrixN
        @note: .case$, "mlabel" + string$ (.i), annotMatrixLabel$ [.i]
    endfor
    for .b from 1 to annotBracketN
        @note: .case$, "bracket" + string$ (.b) + ".i",
        ... string$ (annotBracketI[.b])
        @note: .case$, "bracket" + string$ (.b) + ".j",
        ... string$ (annotBracketJ[.b])
        @note: .case$, "bracket" + string$ (.b) + ".p",
        ... string$ (annotBracketP[.b])
        @note: .case$, "bracket" + string$ (.b) + ".d",
        ... string$ (annotBracketD[.b])
        @note: .case$, "bracket" + string$ (.b) + ".label",
        ... annotBracketLabel$[.b]
    endfor
endproc

; ---------------------------------------------------------------------------
; @publish -- stand a publication up BY HAND in the store's published names.
; It copies whatever the last @drive computed, which is exactly what the write
; site would have published for that run.
; ---------------------------------------------------------------------------
procedure publish: .tid, .dataCol$, .groupCol$
    selectObject: .tid
    .tableName$ = selected$ ("Table")
    @emlStoreKeyTake: .tid, .dataCol$, .groupCol$
    .n = emlBridgeGroupComparison.nGroups
    for .g from 1 to .n
        emlPublishInLabel$ [.g] = emlBridgeGroupComparison.gLabel$ [.g]
    endfor
    @emlBridgeStoreIdentity: .n, testType$, annotCorrectionMethod$
    if .n > 2
        .hasMatrix = 1
    else
        .hasMatrix = 0
    endif
    @emlPublishAnalysisResult: "probe", "menu", "group", "",
    ... emlStoreKeyTake.key$, emlStoreKeyTake.error$, .tid, .tableName$,
    ... .dataCol$, .groupCol$, emlBridgeStoreIdentity.test$,
    ... emlBridgeStoreIdentity.correction$, 0.05, emlStoreKeyTake.sort$,
    ... .n, emlBridgeGroupComparison.omniLabel$,
    ... emlBridgeGroupComparison.omniStat, emlBridgeGroupComparison.omniDf1,
    ... emlBridgeGroupComparison.omniDf2, emlBridgeGroupComparison.omniP,
    ... emlBridgeGroupComparison.omniEffectLabel$,
    ... emlBridgeGroupComparison.omniEffect, emlBridgeGroupComparison.omniN,
    ... "", undefined, undefined, undefined, "", undefined,
    ... emlBridgeGroupComparison.postHoc$, .hasMatrix,
    ... emlBridgeGroupComparison.statLabel$, emlBridgeGroupComparison.effLabel$,
    ... emlBridgeGroupComparison.pRes##, emlBridgeGroupComparison.diffRes##,
    ... emlBridgeGroupComparison.statRes##, emlBridgeGroupComparison.eRes##
endproc

; ---------------------------------------------------------------------------
; @unpublish -- put the store back to "nothing has been published". Used
; before every warm-up drive, so the drive that FILLS the publication is
; always a drive that actually computed: the omnibus locals a publication is
; built from exist only on the compute path, by design.
; ---------------------------------------------------------------------------
procedure unpublish
    emlStoreFormat$ = "eRS1"
    emlStoreValid = 0
endproc

; ===========================================================================
; LEG 1 -- NO PUBLICATION. The common case: a figure drawn with no analysis
; door in front of it. It must compute, and it must authorise its report.
; ===========================================================================
testType$ = "parametric"
@unpublish
@drive: "cold_anova", tableId, 1

; ===========================================================================
; LEG 2 -- THE NO-CHANGE PATH. Publish what leg 1 computed, then draw again.
; Zero recomputation lines, no report authorised, same brackets.
; ===========================================================================
@publish: tableId, "value", "group"
@drive: "consume_anova", tableId, 1

; A SECOND figure off the SAME publication: a result is consumed by MANY
; figures, and there is no spent flag.
@drive: "consume_anova_again", tableId, 1

; And at a different LAYOUT, which is display-only: brackets from the same
; stored numbers.
@drive: "consume_anova_brackets", tableId, 2

; ===========================================================================
; LEG 3 -- THE CHANGED-SETTING PATH. One result-affecting setting moves.
; ===========================================================================
; The test type. Publication is the parametric run above.
testType$ = "nonparametric"
@drive: "changed_testtype", tableId, 1
testType$ = "parametric"

; The group sort order, which has no dialog of its own.
@unpublish
@drive: "warm_sort", tableId, 1
@publish: tableId, "value", "group"
emlGroupSortAlphabetical = 1
@drive: "changed_sort", tableId, 1
emlGroupSortAlphabetical = 0

; THE ADJUSTMENT METHOD, ON THE ARM THAT HAS ONE. Dunn's honours it; Tukey
; does not, and the store records "" for a Tukey run precisely so that a
; figure drawn with the form's menu on "bonferroni" still matches a Tukey
; analysis that never applied it. So this leg is nonparametric, and the
; parametric case is the negative control immediately after it.
testType$ = "nonparametric"
annotCorrectionMethod$ = "holm"
@unpublish
@drive: "warm_dunn_holm", tableId, 1
@publish: tableId, "value", "group"
annotCorrectionMethod$ = "bonferroni"
@drive: "changed_correction", tableId, 1
annotCorrectionMethod$ = "holm"
testType$ = "parametric"

; THE NEGATIVE CONTROL: the same menu change on a TUKEY figure is not a
; change to that analysis, and must not re-run it.
@unpublish
@drive: "warm_tukey", tableId, 1
@publish: tableId, "value", "group"
annotCorrectionMethod$ = "bonferroni"
@drive: "tukey_ignores_correction", tableId, 1
annotCorrectionMethod$ = "holm"

; ===========================================================================
; LEG 4 -- THE DATA PATH. One cell moves; the reorder leg is the one Ian's
; 24 August ruling inverted, and it must invalidate.
; ===========================================================================
@unpublish
@drive: "warm_edit", tableId, 1
@publish: tableId, "value", "group"
@drive: "before_edit", tableId, 1
selectObject: tableId
Set numeric value: 1, "value", 99.9
@drive: "edited_cell", tableId, 1
selectObject: tableId
Set numeric value: 1, "value", 10.1

@unpublish
@drive: "warm_reorder", tableId, 1
@publish: tableId, "value", "group"
@drive: "before_reorder", tableId, 1
selectObject: tableId
; Move the first Zebra row to the end -- same values, same groups, same n.
Append row
nR = Get number of rows
Set numeric value: nR, "value", 10.1
Set string value: nR, "group", "Zebra"
Remove row: 1
@drive: "reordered_rows", tableId, 1

; ===========================================================================
; LEG 4b -- THE REMAP. The store's matrices are indexed by ITS OWN group
; labels, which for a one-way ANOVA is Tukey's alphabetical sort and not the
; order the table discovers. So a consumed figure and a computed one are
; compared CELL BY CELL, at both layouts and on both arms, because a remap
; that is off by one draws a real p-value over the wrong pair of violins and
; nothing else in this probe would notice.
; ===========================================================================
testType$ = "parametric"
@unpublish
@drive: "remap_par_matrix_computed", tableId, 3
@publish: tableId, "value", "group"
@drive: "remap_par_matrix_consumed", tableId, 3

@unpublish
@drive: "remap_par_bracket_computed", tableId, 2
@publish: tableId, "value", "group"
@drive: "remap_par_bracket_consumed", tableId, 2

testType$ = "nonparametric"
@unpublish
@drive: "remap_non_matrix_computed", tableId, 3
@publish: tableId, "value", "group"
@drive: "remap_non_matrix_consumed", tableId, 3

@unpublish
@drive: "remap_non_bracket_computed", tableId, 2
@publish: tableId, "value", "group"
@drive: "remap_non_bracket_consumed", tableId, 2
testType$ = "parametric"

; ===========================================================================
; LEG 5 -- THE WRONG QUESTION. A publication about another comparison must
; not be served to this one.
; ===========================================================================
@unpublish
@drive: "twogroup_cold", twoId, 2
@publish: twoId, "value", "group"
@drive: "twogroup_consume", twoId, 2
; ... and the three-group table must miss against the two-group publication.
@drive: "threegroup_vs_twogroup_store", tableId, 1

; ===========================================================================
; LEG 6 -- A REFUSAL IN THE STORE IS NOT A RESULT.
; ===========================================================================
@unpublish
@drive: "warm_refusal", tableId, 1
@publish: tableId, "value", "group"
@drive: "before_refusal", tableId, 1
emlStoreValid = 0
@drive: "store_refusal", tableId, 1
emlStoreValid = 1

; An unknown schema does not upgrade.
emlStoreFormat$ = "eRS0"
@drive: "store_old_schema", tableId, 1
emlStoreFormat$ = "eRS1"

writeInfoLine: "bridgeconsume probe: wrote ", out$
