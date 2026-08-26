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
; ITEM 1.2, AMENDED 26 AUGUST BY FABLE -- THE MINIMAL RENDERER. Two further
; legs, and they are the two halves of Ian's rule of 24 August that "THE
; REPORT COMPARISON, NOT THE KEY, DECIDES WHAT THE USER SEES":
;
;   changed_data_same_report   one cell moves from 10.1 to 10.2. It is still
;                              the smallest value in the Zebra group and
;                              still above every value in every other group,
;                              so not one rank moves and the Kruskal-Wallis
;                              report is the same report character for
;                              character. The KEY sees the edit -- it is a
;                              digest of every cell -- so the figure re-runs;
;                              and because the re-run reproduces the stored
;                              report exactly, it must print NOTHING. Not a
;                              second report, and not the "Data changed"
;                              line above it either. THIS LEG IS THE DEFECT:
;                              before item 1.2 it printed that line and a
;                              second complete 62-line report.
;
;   changed_data_new_report    one cell moves from 8.4 to 12.0, which lifts a
;                              Mid observation above every Zebra one. Ranks
;                              move, the report is a different report, and
;                              the figure prints the 24 August line and
;                              exactly one new report. This is the leg that
;                              stops the fix above being "never print
;                              anything again", which a comparison that
;                              always answered "identical" would also pass.
;
; THE MENU DOOR IS RE-RUN BEFORE THE FIRST OF THEM, deliberately: leg B's
; changed-setting draw recomputed and printed ONE LINE rather than a report,
; so it published emlStoreReport$ = "" -- no report was printed for that
; result -- and a stored "" never matches. Re-running the analysis door is
; how the store gets back a report a reader has actually seen, which is the
; only thing the comparison is allowed to fall silent against.
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

; ITEM 1.2 -- .notePending is new with the minimal renderer. Read through
; variableExists so this probe drives the PRE-ITEM tree as well and records
; "absent" there rather than aborting: the red demonstration for the new legs
; is this same file run against a tree that does not have the item.
procedure readPending
    .v$ = "absent"
    if variableExists ("emlBridgeGroupComparison.notePending")
        .v$ = string$ (emlBridgeGroupComparison.notePending)
    endif
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
; THE REPRINT GATE, WHICH IS WHAT THE GRAPHS FORM CALLS. Without it this
; probe could never print a second report however broken the tree, and every
; "no second report" pin below would pass vacuously. It is inside the
; sentinels because whatever it prints belongs to this draw.
@emlGraphsReportBridgeIfNew: tableId, "value", "group"
appendInfoLine: "=== SENTINEL: NO-CHANGE FIGURE ENDS ==="
@note: "no_change", "verdict", emlBridgeGroupComparison.verdict$
@note: "no_change", "note", emlBridgeGroupComparison.note$
@note: "no_change", "printReport", string$ (emlBridgeGroupComparison.printReport)
@readPending
@note: "no_change", "notePending", readPending.v$
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
@emlGraphsReportBridgeIfNew: tableId, "value", "group"
appendInfoLine: "=== SENTINEL: CHANGED-SETTING FIGURE ENDS ==="
@note: "changed_setting", "verdict", emlBridgeGroupComparison.verdict$
@note: "changed_setting", "note", emlBridgeGroupComparison.note$
@note: "changed_setting", "printReport", string$ (emlBridgeGroupComparison.printReport)
@readPending
@note: "changed_setting", "notePending", readPending.v$
@note: "changed_setting", "error", emlBridgeGroupComparison.error$

; ===========================================================================
; ITEM 1.2 -- LEG C. CHANGED DATA, SAME REPORT. The correction goes back to
; the one the menu door will run under, the analysis door is re-run so the
; store carries the text of a report a reader has actually seen, one cell
; moves inside its own rank position, and the figure is drawn again.
; ===========================================================================
annotCorrectionMethod$ = "holm"
appendInfoLine: "=== SENTINEL: LEG C MENU ANALYSIS BEGINS ==="
@emlRunKWAnalysis: tableId, "value", "group", 1, "holm"
appendInfoLine: "=== SENTINEL: LEG C MENU ANALYSIS ENDS ==="

; 10.1 -> 10.2. Row 1 is the Zebra group's smallest value; the next value up
; in that group is 10.4 and the largest value in any other group is 8.4, so
; the edited value keeps its rank and every other value keeps its own.
selectObject: tableId
Set numeric value: 1, "value", 10.2
@note: "changed_data_same_report", "edit", "row 1 value 10.1 -> 10.2"

appendInfoLine: "=== SENTINEL: SAME-REPORT FIGURE BEGINS ==="
@emlBridgeGroupComparison: tableId, "value", "group", 0.05, "both", 1, 1,
... "nonparametric", 1
@emlGraphsReportBridgeIfNew: tableId, "value", "group"
appendInfoLine: "=== SENTINEL: SAME-REPORT FIGURE ENDS ==="
@note: "changed_data_same_report", "verdict", emlBridgeGroupComparison.verdict$
@note: "changed_data_same_report", "note", emlBridgeGroupComparison.note$
@note: "changed_data_same_report", "printReport",
... string$ (emlBridgeGroupComparison.printReport)
@readPending
@note: "changed_data_same_report", "notePending", readPending.v$
@note: "changed_data_same_report", "error", emlBridgeGroupComparison.error$

; ===========================================================================
; ITEM 1.2 -- LEG D. CHANGED DATA, DIFFERENT REPORT. The anti-vacuity half:
; a comparison that answered "identical" to everything would pass leg C and
; fail here.
; ===========================================================================
; 8.4 -> 12.0. Row 8 is the Mid group's largest value; 12.0 puts it above
; every Zebra value, so the pooled ranking really does change.
selectObject: tableId
Set numeric value: 8, "value", 12.0
@note: "changed_data_new_report", "edit", "row 8 value 8.4 -> 12.0"

appendInfoLine: "=== SENTINEL: NEW-REPORT FIGURE BEGINS ==="
@emlBridgeGroupComparison: tableId, "value", "group", 0.05, "both", 1, 1,
... "nonparametric", 1
@emlGraphsReportBridgeIfNew: tableId, "value", "group"
appendInfoLine: "=== SENTINEL: NEW-REPORT FIGURE ENDS ==="
@note: "changed_data_new_report", "verdict", emlBridgeGroupComparison.verdict$
@note: "changed_data_new_report", "note", emlBridgeGroupComparison.note$
@note: "changed_data_new_report", "printReport",
... string$ (emlBridgeGroupComparison.printReport)
@readPending
@note: "changed_data_new_report", "notePending", readPending.v$
@note: "changed_data_new_report", "error", emlBridgeGroupComparison.error$

appendInfoLine: "=== SENTINEL: PROBE COMPLETE ==="
