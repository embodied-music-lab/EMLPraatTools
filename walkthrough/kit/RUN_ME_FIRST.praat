# RUN_ME_FIRST.praat -- runs seven EML Stats & Graphs analyses against the
# six CSVs in data/, and writes one report per dataset into out/, named
# praat_<dataset>.txt. Each report also prints to the Praat Info window.
#
# NOTHING TO EDIT. This script finds its own folder, so it does not matter
# whether you run it from the Objects window (Open Praat script... then Run)
# or from a terminal with `praat --run RUN_ME_FIRST.praat`, and it does not
# matter what your current directory is when you do either. See README.md.

kitDir$ = defaultDirectory$
dataDir$ = kitDir$ + "/data"
outDir$ = kitDir$ + "/out"
createFolder: outDir$

include eml-lib-flat.praat

# ----------------------------------------------------------------------------
# emlWriteReport: run one dataset's analyses, capture the Info window text
# they print, write it to out/praat_<name>.txt, and clear the Info window
# so the next dataset's report does not accumulate this one's.
# ----------------------------------------------------------------------------
procedure emlWriteReport: .name$
    .text$ = info$ ()
    writeFile: outDir$ + "/praat_" + .name$ + ".txt", .text$
    appendInfoLine: "wrote out/praat_" + .name$ + ".txt (", length (.text$), " chars)"
endproc

writeInfoLine: "EML Stats & Graphs -- headless walkthrough kit"
appendInfoLine: "kit folder: ", kitDir$
appendInfoLine: ""

# --- v08: two independent groups --------------------------------------------
clearinfo
table = Read Table from comma-separated file: dataDir$ + "/v08_twogroup_input.csv"
@emlRunTwoGroupAnalysis: table, "jitter_pct", "group", "both", 0
removeObject: table
@emlWriteReport: "v08_twogroup_input"

# --- v09: one-way ANOVA + Tukey ---------------------------------------------
clearinfo
table = Read Table from comma-separated file: dataDir$ + "/v09_anova_tukey_input.csv"
@emlRunAnovaAnalysis: table, "SPL_dB", "voice_type", 1
removeObject: table
@emlWriteReport: "v09_anova_tukey_input"

# --- v10: Kruskal-Wallis + Dunn ----------------------------------------------
clearinfo
table = Read Table from comma-separated file: dataDir$ + "/v10_kw_dunn_input.csv"
@emlRunKWAnalysis: table, "SPL_dB", "voice_type", 1, "holm"
removeObject: table
@emlWriteReport: "v10_kw_dunn_input"

# --- demo_rm3: repeated-measures ANOVA (Greenhouse-Geisser) + Friedman,  ----
# --- both with post hoc -- one report, same as the R side ------------------
clearinfo
table = Read Table from comma-separated file: dataDir$ + "/demo_rm3_input.csv"
@emlRunRepeatedMeasuresAnalysis: table, "", "SPL_soft|SPL_medium|SPL_loud|", 1, "holm"
appendInfoLine: ""
@emlRunFriedmanAnalysis: table, "", "SPL_soft|SPL_medium|SPL_loud|", 1, "holm"
removeObject: table
@emlWriteReport: "demo_rm3_input"

# --- v12: correlation --------------------------------------------------------
clearinfo
table = Read Table from comma-separated file: dataDir$ + "/v12_correlation_input.csv"
@emlRunCorrelationAnalysis: table, "speaking_F0_Hz", "singing_F0_Hz", "both"
removeObject: table
@emlWriteReport: "v12_correlation_input"

# --- v13: linear regression --------------------------------------------------
clearinfo
table = Read Table from comma-separated file: dataDir$ + "/v13_regression_input.csv"
@emlRunRegressionAnalysis: table, "vibrato_regularity_pct", "practice_hrs_wk"
removeObject: table
@emlWriteReport: "v13_regression_input"

writeInfoLine: "Done. Six reports written to ", outDir$
