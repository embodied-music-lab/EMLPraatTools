# Drive the SHIPPING two-way ANOVA orchestrator on two committed inputs and
# save both Info windows, so the interaction caveat can be asserted in BOTH
# directions.
#
#   v11_twoway_input.csv    interaction p = .116   caveat ABSENT
#   dump_demo_twoway.csv    interaction p < .001   caveat PRESENT
#
# Unlike the one-way show-both pair, these are two different files rather than
# two columns of one, because no committed input carries both a significant
# and a non-significant interaction. That is a weaker control, so v26 also
# asserts that the two captures agree on their label sequence down to the
# ANOVA table -- the same guard the one-way pair uses.
#
# Same include reasoning as anova_shipping_drive.praat: NOT the eml-lib
# barrel, because Praat resolves a relative include against the TOP-LEVEL
# script's directory.
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_OUT_DIR")
if outDir$ = ""
    outDir$ = "../../evidence/info"
endif
createDirectory: outDir$

; clearinfo between runs: info$() returns the CUMULATIVE Info window, so
; without it the second capture carries the first run as well.
clearinfo
tid = Read Table from comma-separated file:
... "../../evidence/csv/v11_twoway_input.csv"
@emlRunTwoWayAnalysis: tid, "SPL_dB", "voice_type", "task"
writeFile: outDir$ + "/v26_caveat_absent_info.txt", info$ ()
removeObject: tid

clearinfo
tid = Read Table from comma-separated file:
... "../../evidence/csv/dump_demo_twoway.csv"
@emlRunTwoWayAnalysis: tid, "SPL_dB", "voice_type", "task"
writeFile: outDir$ + "/v26_caveat_present_info.txt", info$ ()
removeObject: tid

writeInfoLine: "captures written: 2"
