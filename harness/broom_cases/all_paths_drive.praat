# Drive EVERY converted orchestrator through the shipping path and write its
# broom-shape files. One process, one fixture per analysis, so a regression in
# any path shows up here rather than in a hand-written case.
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
inDir$ = "../../evidence/csv/"
outDir$ = "../../evidence/csv_export/broom"
createDirectory: outDir$
report$ = ""

procedure flush: .base$
    if emlResult_declared <> 1
        report$ = report$ + .base$ + ": NOT DECLARED" + newline$
        goto FLUSH_DONE
    endif
    @emlResultWrite: outDir$, .base$
    .n = emlResultWrite.written
    if emlResult_extra1$ <> ""
        writeFile: outDir$ + "/" + .base$ + "_" + emlResult_extra1$ + "_tidy.csv",
        ... emlResult_extra1Text$
        .n = .n + 1
    endif
    if emlResult_extra2$ <> ""
        writeFile: outDir$ + "/" + .base$ + "_" + emlResult_extra2$ + "_tidy.csv",
        ... emlResult_extra2Text$
        .n = .n + 1
    endif
    report$ = report$ + .base$ + ": " + string$ (.n) + " files" + newline$
    label FLUSH_DONE
endproc

t = Read Table from comma-separated file: inDir$ + "v08_twogroup_input.csv"
@emlRunTwoGroupAnalysis: t, "F0_Hz", "group", "both", 0
@flush: "ship_twogroup"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "v10_kw_dunn_input.csv"
@emlRunKWAnalysis: t, "SPL_dB", "voice_type", 1, "holm"
@flush: "ship_kruskal"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "demo_3groups_input.csv"
@emlRunPairwiseAnalysis: t, "SPL_dB", "voice_type", "welch", "bonferroni"
@flush: "ship_pairwise"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "v11_twoway_input.csv"
@emlRunTwoWayAnalysis: t, "SPL_dB", "voice_type", "task"
@flush: "ship_twoway"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "v05_paired_input.csv"
@emlRunPairedAnalysis: t, "jitter_pre", "jitter_post", "both"
@flush: "ship_paired"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "v12_correlation_input.csv"
@emlRunCorrelationAnalysis: t, "speaking_F0_Hz", "singing_F0_Hz", "both"
@flush: "ship_correlation"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "v13_regression_input.csv"
@emlRunRegressionAnalysis: t, "vibrato_regularity_pct", "practice_hrs_wk"
@flush: "ship_regression"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "v15_normality_input.csv"
@emlRunNormalityAnalysis: t, "F0_Hz", "both"
@flush: "ship_normality"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "demo_rm3_input.csv"
@emlRunRepeatedMeasuresAnalysis: t, "", "SPL_soft|SPL_medium|SPL_loud|", 1, "holm"
@flush: "ship_rmanova"
removeObject: t

t = Read Table from comma-separated file: inDir$ + "demo_rm3_input.csv"
@emlRunFriedmanAnalysis: t, "", "SPL_soft|SPL_medium|SPL_loud|", 1, "holm"
@flush: "ship_friedman"
removeObject: t

writeInfoLine: report$
