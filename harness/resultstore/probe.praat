; ============================================================================
; harness/resultstore/probe.praat -- what the store actually publishes
; ============================================================================
; Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
;
; DRIVES THE FOUR MENU DOORS THAT COMPUTE A GROUP COMPARISON and writes down
; what the store held after each one. The point is not that a number is right
; -- the oracles in validate/ do that -- it is that the PUBLICATION happened,
; that it states the whole result, and that the key it carries was taken at
; the read and not at the publication.
;
; Reads no evidence and asserts nothing. It MEASURES, into a TSV, and
; validate/v138_result_store.R is what asserts. That split is deliberate: a
; probe that asserted would be a check that is also its own evidence.
;
; Argument (Praat form, driven by run.sh):
;   outDir$   where STORE.tsv is written
;
; THE INCLUDES ARE RELATIVE AND FIXED, because Praat resolves `include` at
; PARSE time and a form variable does not exist yet. So the probe always
; includes the tree it sits in, and the red demonstration COPIES the whole
; repository and runs the copy's probe against the copy's plugin -- which is
; the shape harness/settings/seed_violation.sh already uses, and it is safer:
; a seeded tree cannot be pointed at the shipped plugin by accident.
; ============================================================================
form: "Result store probe"
    sentence: "outDir", ""
endform

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
; THE REPORTERS LIVE IN THE GRAPHS LAYER and the orchestrators call them, so
; the analysis tree does not stand up without it: @emlReportTwoGroupComparison,
; @emlReportAnovaComparison, @emlReportKWComparison and
; @emlReportPairwiseComparison are all in eml-annotation-procedures.praat.
; The recorder is deliberately NOT included -- every hook in the orchestrators
; is guarded on variableExists ("emlRecordLoaded"), so this probe measures the
; store on a tree with no recording in it at all.
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/stats/eml-analysis.praat

out$ = outDir$ + "/STORE.tsv"
writeFileLine: out$, "case", tab$, "field", tab$, "value"

procedure note: .case$, .field$, .value$
    appendFileLine: out$, .case$, tab$, .field$, tab$, .value$
endproc

; ---------------------------------------------------------------------------
; @snapshot -- every published name, written down under one case name.
; It reads the store and nothing else; if a name is missing the script aborts,
; which is the point: the write site claims to state them all.
; ---------------------------------------------------------------------------
procedure snapshot: .case$
    @note: .case$, "schema", emlStoreFormat$
    @note: .case$, "run", string$ (emlStoreRun)
    @note: .case$, "valid", string$ (emlStoreValid)
    @note: .case$, "error", emlStoreError$
    @note: .case$, "producer", emlStoreProducer$
    @note: .case$, "door", emlStoreDoor$
    @note: .case$, "kind", emlStoreKind$
    @note: .case$, "key", emlStoreKey$
    @note: .case$, "keyError", emlStoreKeyError$
    @note: .case$, "keyError", emlStoreKeyError$
    @note: .case$, "tableName", emlStoreTableName$
    @note: .case$, "dataCol", emlStoreDataCol$
    @note: .case$, "groupCol", emlStoreGroupCol$
    @note: .case$, "testType", emlStoreTestType$
    @note: .case$, "correction", emlStoreCorrection$
    @note: .case$, "alpha", string$ (emlStoreAlpha)
    @note: .case$, "groupSort", emlStoreGroupSort$
    @note: .case$, "nGroups", string$ (emlStoreNGroups)
    @note: .case$, "omnibusLabel", emlStoreOmnibusLabel$
    @note: .case$, "omnibusStat", string$ (emlStoreOmnibusStat)
    @note: .case$, "df1", string$ (emlStoreDf1)
    @note: .case$, "df2", string$ (emlStoreDf2)
    @note: .case$, "omnibusP", string$ (emlStoreOmnibusP)
    @note: .case$, "effectLabel", emlStoreEffectLabel$
    @note: .case$, "effect", string$ (emlStoreEffect)
    @note: .case$, "n", string$ (emlStoreN)
    @note: .case$, "secondLabel", emlStoreSecondLabel$
    @note: .case$, "secondStat", string$ (emlStoreSecondStat)
    @note: .case$, "secondDf1", string$ (emlStoreSecondDf1)
    @note: .case$, "secondP", string$ (emlStoreSecondP)
    @note: .case$, "secondEffectLabel", emlStoreSecondEffectLabel$
    @note: .case$, "secondEffect", string$ (emlStoreSecondEffect)
    @note: .case$, "postHoc", emlStorePostHoc$
    @note: .case$, "hasMatrix", string$ (emlStoreHasMatrix)
    @note: .case$, "statLabel", emlStoreStatLabel$
    @note: .case$, "pairEffectLabel", emlStorePairEffectLabel$
    @note: .case$, "pRows", string$ (numberOfRows (emlStorePMatrix##))
    @note: .case$, "effRows", string$ (numberOfRows (emlStoreEffectMatrix##))
    for .g from 1 to emlStoreNGroups
        @note: .case$, "label" + string$ (.g), emlStoreGroupLabel$ [.g]
    endfor
    ; The 1-2 cell of each matrix, which is what a bracket would quote.
    if emlStoreHasMatrix = 1
        @note: .case$, "p12", string$ (emlStorePMatrix## [1, 2])
        @note: .case$, "stat12", string$ (emlStoreStatMatrix## [1, 2])
        @note: .case$, "diff12", string$ (emlStoreDiffMatrix## [1, 2])
        @note: .case$, "eff12", string$ (emlStoreEffectMatrix## [1, 2])
    endif
endproc

; ---------------------------------------------------------------------------
; The fixture. Three groups, built by hand so the numbers are stable and the
; group labels are deliberately NOT in alphabetical order in the table --
; "Zebra" first -- which is what makes the sort-order leg mean something.
; ---------------------------------------------------------------------------
procedure buildTable
    .id = Create Table with column names: "storefix", 0, "value group"
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
    tableId = .id
endproc

procedure addRow: .v, .g$
    Append row
    .r = Get number of rows
    Set numeric value: .r, "value", .v
    Set string value: .r, "group", .g$
endproc

procedure buildTwoGroup
    .id = Create Table with column names: "storefix2", 0, "value group"
    @addRow: 10.1, "Zebra"
    @addRow: 10.4, "Zebra"
    @addRow: 10.9, "Zebra"
    @addRow: 11.2, "Zebra"
    @addRow:  4.2, "Alpha"
    @addRow:  4.8, "Alpha"
    @addRow:  5.1, "Alpha"
    @addRow:  5.6, "Alpha"
    twoId = .id
endproc

@buildTable
@buildTwoGroup

; -- the four menu doors ----------------------------------------------------
@emlRunTwoGroupAnalysis: twoId, "value", "group", "both", 0
@snapshot: "twogroup_both"

@emlRunTwoGroupAnalysis: twoId, "value", "group", "parametric", 1
@snapshot: "twogroup_student"

@emlRunAnovaAnalysis: tableId, "value", "group", 1
@snapshot: "anova_tukey"

@emlRunAnovaAnalysis: tableId, "value", "group", 0
@snapshot: "anova_only"

@emlRunKruskalWallisAnalysis: tableId, "value", "group", 1, "holm"
@snapshot: "kw_dunn_holm"

@emlRunKruskalWallisAnalysis: tableId, "value", "group", 1, "bonferroni"
@snapshot: "kw_dunn_bonferroni"

@emlRunKruskalWallisAnalysis: tableId, "value", "group", 0, "holm"
@snapshot: "kw_only"

@emlRunPairwiseAnalysis: tableId, "value", "group", "welch", "holm"
@snapshot: "pairwise_welch_holm"

@emlRunPairwiseAnalysis: tableId, "value", "group", "wilcoxon", "bh"
@snapshot: "pairwise_wilcoxon_bh"

@emlRunPairwiseAnalysis: tableId, "value", "group", "scheffe", "holm"
@snapshot: "pairwise_scheffe"

; -- THE SORT ORDER, which has no dialog of its own ------------------------
emlGroupSortAlphabetical = 1
@emlRunAnovaAnalysis: tableId, "value", "group", 1
@snapshot: "anova_tukey_alphabetical"
emlGroupSortAlphabetical = 0

; -- A REFUSAL MUST PUBLISH. The run before this one published a valid
;    three-group result; if a refusal published nothing, that result would
;    still be standing here, wearing this run's silence.
@emlRunAnovaAnalysis: tableId, "value", "no_such_column", 1
@snapshot: "refusal_missing_group_column"

@emlRunAnovaAnalysis: tableId, "no_such_data", "group", 1
@snapshot: "refusal_missing_data_column"

; -- THE STALE SLOT. A two-group result after a three-group one must not
;    leave a third label standing.
@emlRunAnovaAnalysis: tableId, "value", "group", 1
@emlRunTwoGroupAnalysis: twoId, "value", "group", "parametric", 0
@snapshot: "twogroup_after_threegroup"
@note: "twogroup_after_threegroup", "label3_after", emlStoreGroupLabel$ [3]

; -- THE KEY MOVES WITH THE DATA, AND ONLY THE PUBLICATION SAYS SO ---------
@emlRunAnovaAnalysis: tableId, "value", "group", 1
keyBefore$ = emlStoreKey$
selectObject: tableId
Set numeric value: 1, "value", 99.9
@emlRunAnovaAnalysis: tableId, "value", "group", 1
@note: "edit_one_cell", "keyBefore", keyBefore$
@note: "edit_one_cell", "keyAfter", emlStoreKey$
@note: "edit_one_cell", "keysAgree", string$ (keyBefore$ = emlStoreKey$)
; put the edited cell back so the legs below start from the canonical table.
selectObject: tableId
Set numeric value: 1, "value", 10.1

; ============================================================================
; THE THREE REMAINING MUTATION LEGS, RULING SECTION (a), DRIVEN THROUGH THE
; STORE (a menu door's own @emlStoreKeyTake / @emlPublishAnalysisResult, not
; a direct call to @emlGroupFingerprint -- that is validate/v114's job, over
; the 278 phase2 legs. This harness's job is the INTEGRATION claim: that the
; published emlStoreKey$ actually moves when the ruling says it must, for a
; caller that only ever sees the store's own published key and never opens
; the fingerprint procedures directly.
;
; EACH LEG RESTORES THE TABLE TO storefix's CANONICAL CONTENT BEFORE IT ENDS,
; so the legs do not contaminate one another and their order in this file
; does not matter to any of them.
; ============================================================================

; -- RELABEL ONE GROUP CELL (ruling section a, pin b) -----------------------
; Row 5 is the first "Mid" row. Relabelling it changes nothing about the
; VALUE column and nothing about group SIZE overall (Mid loses a row, a new
; level of size 1 appears) -- it is a pure label edit on one cell.
@emlRunAnovaAnalysis: tableId, "value", "group", 1
keyBefore$ = emlStoreKey$
selectObject: tableId
Set string value: 5, "group", "Middish"
@emlRunAnovaAnalysis: tableId, "value", "group", 1
@note: "relabel_group_cell", "keyBefore", keyBefore$
@note: "relabel_group_cell", "keyAfter", emlStoreKey$
@note: "relabel_group_cell", "keysAgree", string$ (keyBefore$ = emlStoreKey$)
selectObject: tableId
Set string value: 5, "group", "Mid"

; -- SWAP ONE VALUE BETWEEN GROUPS (ruling section a, pin c) -----------------
; Row 1 (Zebra, 10.1) and row 5 (Mid, 7.1) exchange their VALUE cells only --
; the group column is untouched at both rows. Every group keeps its size and
; the value column keeps its multiset; only the value*group PAIRING moves,
; which is exactly the case the ruling's per-group binding exists to catch
; (a whole-column checksum would miss this outright).
@emlRunAnovaAnalysis: tableId, "value", "group", 1
keyBefore$ = emlStoreKey$
selectObject: tableId
swapV1 = Get value: 1, "value"
swapV5 = Get value: 5, "value"
Set numeric value: 1, "value", swapV5
Set numeric value: 5, "value", swapV1
@emlRunAnovaAnalysis: tableId, "value", "group", 1
@note: "swap_value_between_groups", "keyBefore", keyBefore$
@note: "swap_value_between_groups", "keyAfter", emlStoreKey$
@note: "swap_value_between_groups", "keysAgree", string$ (keyBefore$ = emlStoreKey$)
selectObject: tableId
Set numeric value: 1, "value", swapV1
Set numeric value: 5, "value", swapV5

; -- REORDER ROWS (ruling section a's negative control, OVERTURNED by Ian's
;    24 August ruling: "any change to the data including reordering of rows
;    forces the mismatch error and redoing of the stats." This leg must
;    INVALIDATE, and a green here on the OLD rationale would be the very
;    regression the ruling amendment exists to forbid.
;
;    The whole table is reversed row-for-row -- both the value and the group
;    cell move together at each swapped pair, so every (value, group) PAIR
;    survives intact and only the ROW POSITIONS change. That is a pure
;    reorder: not a relabel, not a swap between groups, not an edit.
@emlRunAnovaAnalysis: tableId, "value", "group", 1
keyBefore$ = emlStoreKey$
selectObject: tableId
for reo_i to 6
    reo_j = 13 - reo_i
    reo_vi = Get value: reo_i, "value"
    reo_gi$ = Get value: reo_i, "group"
    reo_vj = Get value: reo_j, "value"
    reo_gj$ = Get value: reo_j, "group"
    Set numeric value: reo_i, "value", reo_vj
    Set string value: reo_i, "group", reo_gj$
    Set numeric value: reo_j, "value", reo_vi
    Set string value: reo_j, "group", reo_gi$
endfor
@emlRunAnovaAnalysis: tableId, "value", "group", 1
@note: "reorder_rows", "keyBefore", keyBefore$
@note: "reorder_rows", "keyAfter", emlStoreKey$
@note: "reorder_rows", "keysAgree", string$ (keyBefore$ = emlStoreKey$)
; restore row order (the reversal is its own inverse)
selectObject: tableId
for reo_i to 6
    reo_j = 13 - reo_i
    reo_vi = Get value: reo_i, "value"
    reo_gi$ = Get value: reo_i, "group"
    reo_vj = Get value: reo_j, "value"
    reo_gj$ = Get value: reo_j, "group"
    Set numeric value: reo_i, "value", reo_vj
    Set string value: reo_i, "group", reo_gj$
    Set numeric value: reo_j, "value", reo_vi
    Set string value: reo_j, "group", reo_gi$
endfor

writeInfoLine: "resultstore probe: wrote ", out$
