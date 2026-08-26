# RUN_ME_FIRST.praat -- runs seven EML Stats & Graphs analyses against the
# six CSVs in data/, and writes one report per dataset into out/, named
# praat_<dataset>.txt. Each report also prints to the Praat Info window.
#
# NOTHING TO EDIT, AND NOTHING TO INSTALL. There is no plugin in a
# preferences folder; the statistics layer travels with this kit as
# eml-lib-flat.praat, included on the line below.
#
# EVERY PATH HERE IS RELATIVE, and that is deliberate. Praat resolves a
# relative path in a script against THE SCRIPT'S OWN FOLDER, not against
# whatever directory the process happens to be in. Measured, not assumed:
# a script reading "data/v08_twogroup_input.csv", invoked from a completely
# different working directory, read the file sitting beside itself. So this
# folder can live anywhere, and it does not matter where you launched Praat
# from or what directory it thinks it is in.
#
# One consequence worth knowing if you ever move these files apart:
# `include` is resolved while Praat PARSES the script, before any line of it
# runs, and it does not accept a variable. So if eml-lib-flat.praat is not
# beside this file, Praat's own "Cannot open file" fires before this script
# can say anything more helpful. Keep the folder together.

createFolder: "out"

include eml-lib-flat.praat

if not folderExists ("data")
    writeInfoLine: "RUN_ME_FIRST.praat cannot find its data."
    appendInfoLine: ""
    appendInfoLine: "It expects a folder called data/ sitting beside it, "
    ... + "holding the six CSV files."
    appendInfoLine: "Keep the kit folder together: RUN_ME_FIRST.praat, "
    ... + "eml-lib-flat.praat,"
    appendInfoLine: "run_analyses.R, data/ and out/ all in one place."
    exitScript ()
endif

# ----------------------------------------------------------------------------
# emlWriteReport: run one dataset's analyses, capture the Info window text
# they print, write it to out/praat_<name>.txt, and clear the Info window
# so the next dataset's report does not accumulate this one's.
# ----------------------------------------------------------------------------
emlReportCount = 0
procedure emlWriteReport: .name$
    .text$ = info$ ()
    writeFile: "out/praat_" + .name$ + ".txt", .text$
    appendInfoLine: "wrote out/praat_" + .name$ + ".txt (", length (.text$), " chars)"
    emlReportCount = emlReportCount + 1
endproc

writeInfoLine: "EML Stats & Graphs -- headless walkthrough kit"
appendInfoLine: ""

# --- v08: two independent groups --------------------------------------------
clearinfo
table = Read Table from comma-separated file: "data/v08_twogroup_input.csv"
@emlRunTwoGroupAnalysis: table, "jitter_pct", "group", "both", 0
removeObject: table
@emlWriteReport: "v08_twogroup_input"

# --- v09: one-way ANOVA + Tukey ---------------------------------------------
clearinfo
table = Read Table from comma-separated file: "data/v09_anova_tukey_input.csv"
@emlRunAnovaAnalysis: table, "SPL_dB", "voice_type", 1
removeObject: table
@emlWriteReport: "v09_anova_tukey_input"

# --- v10: Kruskal-Wallis + Dunn ----------------------------------------------
clearinfo
table = Read Table from comma-separated file: "data/v10_kw_dunn_input.csv"
@emlRunKWAnalysis: table, "SPL_dB", "voice_type", 1, "holm"
removeObject: table
@emlWriteReport: "v10_kw_dunn_input"

# --- demo_rm3: repeated-measures ANOVA (Greenhouse-Geisser) + Friedman,  ----
# --- both with post hoc -- one report, same as the R side ------------------
clearinfo
table = Read Table from comma-separated file: "data/demo_rm3_input.csv"
@emlRunRepeatedMeasuresAnalysis: table, "", "SPL_soft|SPL_medium|SPL_loud|", 1, "holm"
appendInfoLine: ""
@emlRunFriedmanAnalysis: table, "", "SPL_soft|SPL_medium|SPL_loud|", 1, "holm"
removeObject: table
@emlWriteReport: "demo_rm3_input"

# --- v12: correlation --------------------------------------------------------
clearinfo
table = Read Table from comma-separated file: "data/v12_correlation_input.csv"
@emlRunCorrelationAnalysis: table, "speaking_F0_Hz", "singing_F0_Hz", "both"
removeObject: table
@emlWriteReport: "v12_correlation_input"

# --- v13: linear regression --------------------------------------------------
clearinfo
table = Read Table from comma-separated file: "data/v13_regression_input.csv"
@emlRunRegressionAnalysis: table, "vibrato_regularity_pct", "practice_hrs_wk"
removeObject: table
@emlWriteReport: "v13_regression_input"

# The Info window came to the front of the script editor the moment the
# first writeInfoLine/appendInfoLine ran above, so it may now be hiding the
# editor -- this line is what tells Josh, looking at the Info window, that
# the run is over and not stalled: it names how many reports landed and
# where, using a live count rather than a hardcoded number so it is honest
# even if a future edit adds or removes a dataset.
writeInfoLine: "Done. ", emlReportCount, " report(s) written to the kit's out/ folder."
