include /home/claude/drive/prefs/plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include /home/claude/drive/prefs/plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include /home/claude/drive/prefs/plugin_EML_Praat_Tools/stats/eml-extract.praat
include /home/claude/drive/prefs/plugin_EML_Praat_Tools/stats/eml-output.praat
include /home/claude/drive/prefs/plugin_EML_Praat_Tools/stats/eml-inferential.praat
include /home/claude/drive/prefs/plugin_EML_Praat_Tools/stats/eml-analysis.praat
include /home/claude/drive/prefs/plugin_EML_Praat_Tools/graphs/eml-graph-procedures.praat
include /home/claude/drive/prefs/plugin_EML_Praat_Tools/graphs/eml-annotation-procedures.praat

Text writing preferences: "UTF-8"
out$ = "/tmp/csvout"
createFolder: out$

procedure dump: .name$
    .path$ = out$ + "/" + .name$ + ".csv"
    @emlExportStatsCSV: .path$
    appendInfoLine: "== ", .name$, "  rows=", emlCSV_n,
    ... "  success=", emlExportStatsCSV.success,
    ... "  reason=[", emlExportStatsCSV.reason$, "]"
endproc

writeInfoLine: "CSV export check", newline$

# --- one-way ANOVA + Tukey (the eight-zero row) ---
t = Create Table with column names: "demo 3groups", 15, "SPL_dB voice_type"
lab$ [1] = "Soprano"
lab$ [2] = "Mezzo"
lab$ [3] = "Alto"
base# = {92, 88, 85}
for i from 1 to 15
    g = (i - 1) mod 3 + 1
    Set numeric value: i, "SPL_dB", base# [g] + (i mod 5) * 1.3
    Set string value: i, "voice_type", lab$ [g]
endfor
@emlCSVInit
@emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", 1
@dump: "anova"

# --- two-way ---
t2 = Create Table with column names: "demo twoway", 24, "SPL_dB voice_type task"
for i from 1 to 24
    vt$ = if (i mod 2 = 0) then "Soprano" else "Alto" fi
    tk$ = if ((i - 1) div 2) mod 2 = 0 then "sung" else "spoken" fi
    Set string value: i, "voice_type", vt$
    Set string value: i, "task", tk$
    Set numeric value: i, "SPL_dB", 80 + (i mod 7) * 1.1 + (if vt$ = "Soprano" then 4 else 0 fi)
endfor
@emlCSVInit
@emlRunTwoWayAnalysis: t2, "SPL_dB", "voice_type", "task"
@dump: "twoway"

# --- regression ---
t3 = Create Table with column names: "demo regression", 12, "practice_hrs_wk vibrato_pct"
px# = {2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18}
py# = {61, 63, 66, 68, 72, 74, 78, 80, 84, 85, 89, 91}
for i from 1 to 12
    Set numeric value: i, "practice_hrs_wk", px# [i]
    Set numeric value: i, "vibrato_pct", py# [i]
endfor
@emlCSVInit
@emlRunRegressionAnalysis: t3, "vibrato_pct", "practice_hrs_wk"
@dump: "regression"

# --- correlation ---
@emlCSVInit
@emlRunCorrelationAnalysis: t3, "practice_hrs_wk", "vibrato_pct", "both"
@dump: "correlation"

# --- empty buffer (D66) ---
@emlCSVInit
@dump: "empty"


# --- two-group + paired + KW, the paths not yet exercised ---
t4 = Create Table with column names: "demo 2groups", 16, "SPL_dB voice_type"
tg# = {71.2, 73.5, 70.8, 74.1, 72.6, 75.0, 71.9, 73.3,
... 64.5, 66.1, 63.8, 67.2, 65.4, 66.9, 64.2, 65.8}
for i from 1 to 16
    Set numeric value: i, "SPL_dB", tg# [i]
    Set string value: i, "voice_type", if i <= 8 then "Soprano" else "Alto" fi
endfor
@emlCSVInit
@emlRunTwoGroupAnalysis: t4, "SPL_dB", "voice_type", "parametric", 0
@dump: "twogroup"

@emlCSVInit
@emlRunKWAnalysis: t, "SPL_dB", "voice_type", 1, "holm"
@dump: "kw"

t5 = Create Table with column names: "demo paired", 10, "jitter_pre jitter_post"
pr# = {1.42, 1.61, 1.33, 1.75, 1.58, 1.49, 1.66, 1.38, 1.71, 1.55}
po# = {1.21, 1.35, 1.18, 1.44, 1.29, 1.26, 1.41, 1.15, 1.48, 1.31}
for i from 1 to 10
    Set numeric value: i, "jitter_pre", pr# [i]
    Set numeric value: i, "jitter_post", po# [i]
endfor
@emlCSVInit
@emlRunPairedAnalysis: t5, "jitter_pre", "jitter_post", "parametric"
@dump: "paired"
removeObject: t4, t5
