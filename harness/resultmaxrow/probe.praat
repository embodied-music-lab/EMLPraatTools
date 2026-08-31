; ============================================================================
; harness/resultmaxrow/probe.praat -- drive the result-store row cap
; ============================================================================
; Builds a table of 18,009 rows (the NIST StRD SmLs03/06/09 row count) and
; puts it through the real emlAugmentFrom / emlResultWrite path. Writes a
; TSV recording whether the export completed and what MAXROW is; asserts
; nothing itself -- validate/v20_result_maxrow.R does that.
; ============================================================================
form: "Result store max-row probe"
    sentence: "outDir", ""
endform

include ../../plugin_EML_StatsGraphs/stats/eml-result-writer.praat

out$ = outDir$ + "/MAXROW.tsv"
writeFileLine: out$, "field", tab$, "value"

procedure note: .field$, .value$
    appendFileLine: out$, .field$, tab$, .value$
endproc

@note: "maxrow_constant", string$ (emlResult_MAXROW)

; -- build the 18,009-row table, vectorized (Append row 18009 times would
;    work too but is far slower; Formula fills the whole column at once) --
n = 18009
tbl = Create Table with column names: "nist18009", n, "value"
Formula: "value", "row"

@emlResultBegin: "nist18009", "row cap regression"
@emlAugmentFrom: tbl
@note: "augment_nRows", string$ (emlAugment_nRows)

@emlResultWrite: outDir$, "maxrow_probe"
@note: "files_written", string$ (emlResultWrite.written)

writeInfoLine: "maxrow probe: wrote ", out$
