include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-inferential.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-analysis.praat

outputFolder$ = "~/voice_study/results"
createFolder: outputFolder$
data = Read Table from comma-separated file: "~/voice_study/singers.csv"

@emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1
@emlExportResultFiles: outputFolder$, "anova_by_voice_type"

appendInfoLine: "declared = ", emlExportResultFiles.declared,
...             "  files written = ", emlExportResultFiles.nWritten,
...             "  reason = [", emlExportResultFiles.reason$, "]"
if emlExportResultFiles.success = 0
    appendInfoLine: "nothing written -- reason: ", emlExportResultFiles.reason$
endif
