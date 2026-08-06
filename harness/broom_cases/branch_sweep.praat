# Drive EVERY orchestrator on EVERY branch of its test-type argument.
#
# The class of defect this exists to catch, found 6 Aug 2026: the CSV
# migration read per-test locals unconditionally that were only assigned
# inside their own branch, so @emlRunCorrelationAnalysis aborted on
# "pearson" and "spearman" and survived only on "both" -- and "both" is
# what every driver happened to use. A default setting was broken and no
# harness could see it.
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat

inDir$ = "../../evidence/csv/"
out$ = ""
nRun = 0

procedure note: .what$
    nRun = nRun + 1
    out$ = out$ + "OK  " + .what$ + "  declared=" + string$ (emlResult_declared)
    ... + newline$
endproc

for i to 3
    tt$ = if i = 1 then "parametric" else if i = 2 then "nonparametric" else "both" fi fi
    t = Read Table from comma-separated file: inDir$ + "v08_twogroup_input.csv"
    @emlRunTwoGroupAnalysis: t, "F0_Hz", "group", tt$, 0
    @note: "twogroup/" + tt$
    removeObject: t
    t = Read Table from comma-separated file: inDir$ + "v05_paired_input.csv"
    @emlRunPairedAnalysis: t, "jitter_pre", "jitter_post", tt$
    @note: "paired/" + tt$
    removeObject: t
endfor

for i to 3
    tt$ = if i = 1 then "pearson" else if i = 2 then "spearman" else "both" fi fi
    t = Read Table from comma-separated file: inDir$ + "v12_correlation_input.csv"
    @emlRunCorrelationAnalysis: t, "speaking_F0_Hz", "singing_F0_Hz", tt$
    @note: "correlation/" + tt$
    removeObject: t
endfor

for i to 4
    tt$ = if i = 1 then "welch" else if i = 2 then "student" else if i = 3 then "wilcoxon" else "scheffe" fi fi fi
    t = Read Table from comma-separated file: inDir$ + "demo_3groups_input.csv"
    @emlRunPairwiseAnalysis: t, "SPL_dB", "voice_type", tt$, "bonferroni"
    @note: "pairwise/" + tt$
    removeObject: t
endfor

for i to 2
    dd = i - 1
    t = Read Table from comma-separated file: inDir$ + "v10_kw_dunn_input.csv"
    @emlRunKWAnalysis: t, "SPL_dB", "voice_type", dd, "holm"
    @note: "kruskal/dunn=" + string$ (dd)
    removeObject: t
    t = Read Table from comma-separated file: inDir$ + "v09_anova_tukey_input.csv"
    @emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", dd
    @note: "anova/tukey=" + string$ (dd)
    removeObject: t
    t = Read Table from comma-separated file: inDir$ + "demo_rm3_input.csv"
    @emlRunRepeatedMeasuresAnalysis: t, "", "SPL_soft|SPL_medium|SPL_loud|", dd, "holm"
    @note: "rmanova/posthoc=" + string$ (dd)
    removeObject: t
    t = Read Table from comma-separated file: inDir$ + "demo_rm3_input.csv"
    @emlRunFriedmanAnalysis: t, "", "SPL_soft|SPL_medium|SPL_loud|", dd, "holm"
    @note: "friedman/posthoc=" + string$ (dd)
    removeObject: t
endfor

t = Read Table from comma-separated file: inDir$ + "v11_twoway_input.csv"
@emlRunTwoWayAnalysis: t, "SPL_dB", "voice_type", "task"
@note: "twoway"
removeObject: t
t = Read Table from comma-separated file: inDir$ + "v13_regression_input.csv"
@emlRunRegressionAnalysis: t, "vibrato_regularity_pct", "practice_hrs_wk"
@note: "regression"
removeObject: t
t = Read Table from comma-separated file: inDir$ + "v15_normality_input.csv"
@emlRunNormalityAnalysis: t, "F0_Hz", "both"
@note: "normality"
removeObject: t

writeInfoLine: out$
appendInfoLine: nRun, " branch combinations completed with no abort"
