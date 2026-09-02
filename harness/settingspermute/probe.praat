; ============================================================================
; harness/settingspermute/probe.praat -- R1's settings-permutation drive
; ============================================================================
; Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
;
; docs/RISK_REGISTER_2026-08-25.md, R1: "a settings-permutation drive -- same
; data, every display setting toggled between draws -- asserting zero
; reprints." The DISPLAY-ONLY settings under test are the four
; @emlRunAnnotationComparison itself takes as arguments and validate/v112's
; census classifies as display-only for that door: .style$, .showNS,
; .showEffect, .layoutMode. Toggling any of these must never move the
; bridge's verdict to "settings" and must never print a "Recomputed:" line --
; a display choice is not a result-affecting one, by the census's own
; classification, and this is R1's guard against a canonical-form comparison
; that quietly disagrees with that classification.
;
; ONE ANALYSIS PUBLICATION, THEN MANY DRAWS, NONE OF WHICH TOUCH THE DATA OR A
; RESULT-AFFECTING SETTING (testType, correction, alpha, group sort all held
; fixed at the values the published analysis used). Each draw's own leg name
; identifies which display setting moved and to what.
;
; Argument (Praat form, driven by run.sh):
;   outDir$   where the TSV is written
; ============================================================================
form: "Settings-permutation probe"
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

tsv$ = outDir$ + "/SETTINGSPERMUTE.tsv"
writeFileLine: tsv$, "leg", tab$, "field", tab$, "value"
procedure note: .leg$, .field$, .value$
    appendFileLine: tsv$, .leg$, tab$, .field$, tab$, .value$
endproc

tableId = Create Table with column names: "sp3", 0, "value group"
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

annotCorrectionMethod$ = "holm"
emlGroupSortAlphabetical = 0

writeInfoLine: "=== SENTINEL: MENU ANALYSIS BEGINS ==="
@emlRunAnovaAnalysis: tableId, "value", "group", 1
appendInfoLine: "=== SENTINEL: MENU ANALYSIS ENDS ==="

; The result-affecting settings held fixed at what the published analysis
; used, on every draw below -- only the display setting under test moves.
fixedAlpha = 0.05
fixedTestType$ = "parametric"

; -- style$: "p-value" / "stars" / "both" ------------------------------------
@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "p-value",
... 1, 1, fixedTestType$, 1
@note: "style_pvalue", "verdict", emlRunAnnotationComparison.verdict$
@note: "style_pvalue", "note", emlRunAnnotationComparison.note$

@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "stars",
... 1, 1, fixedTestType$, 1
@note: "style_stars", "verdict", emlRunAnnotationComparison.verdict$
@note: "style_stars", "note", emlRunAnnotationComparison.note$

; -- showNS: 0 / 1 ------------------------------------------------------------
@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "both",
... 0, 1, fixedTestType$, 1
@note: "shownsigns_0", "verdict", emlRunAnnotationComparison.verdict$
@note: "shownsigns_0", "note", emlRunAnnotationComparison.note$

@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "both",
... 1, 1, fixedTestType$, 1
@note: "shownsigns_1", "verdict", emlRunAnnotationComparison.verdict$
@note: "shownsigns_1", "note", emlRunAnnotationComparison.note$

; -- showEffect: 0 / 1 --------------------------------------------------------
@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "both",
... 1, 0, fixedTestType$, 1
@note: "showeffect_0", "verdict", emlRunAnnotationComparison.verdict$
@note: "showeffect_0", "note", emlRunAnnotationComparison.note$

@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "both",
... 1, 1, fixedTestType$, 1
@note: "showeffect_1", "verdict", emlRunAnnotationComparison.verdict$
@note: "showeffect_1", "note", emlRunAnnotationComparison.note$

; -- layoutMode: brackets (2) / matrix (3) -----------------------------------
@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "both",
... 1, 1, fixedTestType$, 2
@note: "layout_brackets", "verdict", emlRunAnnotationComparison.verdict$
@note: "layout_brackets", "note", emlRunAnnotationComparison.note$

@emlRunAnnotationComparison: tableId, "value", "group", fixedAlpha, "both",
... 1, 1, fixedTestType$, 3
@note: "layout_matrix", "verdict", emlRunAnnotationComparison.verdict$
@note: "layout_matrix", "note", emlRunAnnotationComparison.note$

appendInfoLine: "=== SENTINEL: PROBE COMPLETE ==="
