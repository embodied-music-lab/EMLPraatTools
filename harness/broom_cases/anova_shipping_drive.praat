# Drive the SHIPPING one-way ANOVA orchestrator and write its three-file
# result, so the export is proven through the real path rather than through a
# hand-written harness. This is the difference the previous migration record
# missed: anova_oneway.praat calls the writer directly; this calls
# @emlRunAnovaAnalysis, which is what the menu calls.
# NOT the eml-lib barrel: Praat resolves a relative include against the
# TOP-LEVEL script's directory, and the barrel's paths are written from
# plugin/scripts/. From here they would resolve to harness/stats/.
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
    outDir$ = "../../evidence/csv_export/broom"
endif
createDirectory: outDir$

tid = Read Table from comma-separated file: environment$ ("EML_FIXTURE")
tname$ = selected$ ("Table")

@emlRunAnovaAnalysis: tid, "SPL_dB", "voice_type", 1

if emlResult_declared <> 1
    exitScript: "orchestrator did not declare a result"
endif

@emlResultWrite: outDir$, "shipping_anova"
n = emlResultWrite.written
if emlResult_extra1$ <> ""
    writeFile: outDir$ + "/shipping_anova_" + emlResult_extra1$ + "_tidy.csv",
    ... emlResult_extra1Text$
    n = n + 1
endif
if emlResult_extra2$ <> ""
    writeFile: outDir$ + "/shipping_anova_" + emlResult_extra2$ + "_tidy.csv",
    ... emlResult_extra2Text$
    n = n + 1
endif
writeInfoLine: "files written: ", n
appendInfoLine: emlResultWrite.files$
appendInfoLine: "skipped: ", emlResultWrite.skipped$
