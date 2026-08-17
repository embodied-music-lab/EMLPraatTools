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

column$ [1] = "SPL_dB"
column$ [2] = "vibrato_rate_Hz"

for i from 1 to 2
    selectObject: data
    @emlRunAnovaAnalysis: data, column$ [i], "voice_type", 1
    @emlExportResultFiles: outputFolder$, "anova_" + column$ [i]
    appendInfoLine: "BATCH ", column$ [i],
    ... ": written = ", emlExportResultFiles.nWritten,
    ... "  success = ", emlExportResultFiles.success
    if emlExportResultFiles.success = 0
        appendInfoLine: "nothing written for ", column$ [i],
        ... " -- reason: ", emlExportResultFiles.reason$
    endif
endfor
