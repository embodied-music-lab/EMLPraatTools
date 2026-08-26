; ============================================================================
; harness/reprintpins/probe.praat -- Ian's driven KW -> violin session,
; reproduced against the shipped store, for validate/v140's two ruled pins
; ============================================================================
; Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
;
; docs/RULING_RESULT_STORE.md section (c): the no-change leg (analysis door
; then figure, zero result-affecting edits -- must print exactly one report
; and zero recomputation lines) and the changed-setting leg (one
; result-affecting edit -- must print the one announcement line, the updated
; brackets, and no second report block).
;
; docs/MEMO_TO_FABLE_unification.md's own scenario: "Ian ran a Kruskal-Wallis
; on a three-group table, then drew a violin plot. The Info window carried
; TWO complete Kruskal-Wallis reports ... The second is the graph door
; recomputing the analysis." This probe reproduces that shape exactly --
; the menu door's @emlRunKWAnalysis, then @emlBridgeGroupComparison, the same
; procedure the violin's brackets are drawn from -- and writes down what
; actually printed, so validate/v140 can count reports rather than trust
; that the mechanism works.
;
; WHAT IS COUNTED, AND HOW. Praat has no API to read the Info window back as
; a string from inside the script that wrote it, so this probe does not try:
; run.sh captures the WHOLE PROCESS's stdout to a transcript file, and
; validate/v140 counts a report marker in that transcript textually -- the
; same shape harness/settingspub and harness/doorcensus use for evidence a
; script cannot read back on its own. Each of the two draws is bracketed by a
; sentinel line of its own, so the count for EACH draw is unambiguous even
; though both draws share one process and one growing transcript.
;
; A SCRIPT ERROR ABORTS PRAAT, WHICH IS READ HONESTLY. If the bridge's own
; call to the write site does not yet match that procedure's arity, this
; probe does not catch the error or paper over it -- Praat exits non-zero,
; run.sh's capture ends where the abort happened, and validate/v140 reads
; that as "the drive did not complete" rather than inventing a report count
; it never saw. That is the same discipline v114's four ways-of-running-
; nothing checks apply to a suite that dies mid-run.
;
; Argument (Praat form, driven by run.sh):
;   outDir$   where the transcript and TSV are written
; ============================================================================
form: "Reprint pins probe"
    sentence: "outDir", ""
endform

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/stats/eml-analysis.praat

tsv$ = outDir$ + "/REPRINTPINS.tsv"
writeFileLine: tsv$, "leg", tab$, "field", tab$, "value"
procedure note: .leg$, .field$, .value$
    appendFileLine: tsv$, .leg$, tab$, .field$, tab$, .value$
endproc

; ---------------------------------------------------------------------------
; The fixture: Ian's own scenario, a three-group table for a Kruskal-Wallis.
; ---------------------------------------------------------------------------
tableId = Create Table with column names: "kwviolin", 0, "value group"
procedure addRow: .v, .g$
    Append row
    .r = Get number of rows
    Set numeric value: .r, "value", .v
    Set string value: .r, "group", .g$
endproc
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

; The settings the graph door carries forward, matching the menu door's own
; alpha (@emlReportAlpha, read fresh by the menu run) and the correction the
; menu run was given, so the "zero result-affecting edits" leg really is zero.
annotCorrectionMethod$ = "holm"
emlGroupSortAlphabetical = 0

; ===========================================================================
; LEG A -- NO CHANGE. Analysis door, then figure, nothing edited in between.
; ===========================================================================
writeInfoLine: "=== SENTINEL: MENU ANALYSIS BEGINS ==="
@emlRunKWAnalysis: tableId, "value", "group", 1, "holm"
appendInfoLine: "=== SENTINEL: MENU ANALYSIS ENDS ==="

appendInfoLine: "=== SENTINEL: NO-CHANGE FIGURE BEGINS ==="
@emlBridgeGroupComparison: tableId, "value", "group", 0.05, "both", 1, 1,
... "nonparametric", 1
appendInfoLine: "=== SENTINEL: NO-CHANGE FIGURE ENDS ==="
@note: "no_change", "verdict", emlBridgeGroupComparison.verdict$
@note: "no_change", "note", emlBridgeGroupComparison.note$
@note: "no_change", "printReport", string$ (emlBridgeGroupComparison.printReport)
@note: "no_change", "error", emlBridgeGroupComparison.error$

; ===========================================================================
; LEG B -- CHANGED SETTING. Same analysis, but the correction the FIGURE
; resolves has moved: holm -> bonferroni. Result-affecting per v112's own
; census and per the ruling's own worked example.
; ===========================================================================
annotCorrectionMethod$ = "bonferroni"
appendInfoLine: "=== SENTINEL: CHANGED-SETTING FIGURE BEGINS ==="
@emlBridgeGroupComparison: tableId, "value", "group", 0.05, "both", 1, 1,
... "nonparametric", 1
appendInfoLine: "=== SENTINEL: CHANGED-SETTING FIGURE ENDS ==="
@note: "changed_setting", "verdict", emlBridgeGroupComparison.verdict$
@note: "changed_setting", "note", emlBridgeGroupComparison.note$
@note: "changed_setting", "printReport", string$ (emlBridgeGroupComparison.printReport)
@note: "changed_setting", "error", emlBridgeGroupComparison.error$

appendInfoLine: "=== SENTINEL: PROBE COMPLETE ==="
