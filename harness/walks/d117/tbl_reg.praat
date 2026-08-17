# D117 — table for the regression / predict / correlation / paired / describe
# pages. Deterministic (no randomGauss), one text column so that a user
# selection which is legal on the FORM can still fail in the ANALYSIS.
tid = Create Table with column names: "demo_reg", 20,
... "singer SPL_dB vibrato_rate_Hz jitter_pct"
for i from 1 to 20
    Set string value: i, "singer", "Singer_" + string$ (i)
    Set numeric value: i, "SPL_dB", 80 + (i mod 9)
    Set numeric value: i, "vibrato_rate_Hz", 5 + (i mod 7) / 10
    Set numeric value: i, "jitter_pct", 1 + (i mod 5) / 10
endfor
selectObject: tid
runScript: preferencesDirectory$
... + "/plugin_EML_StatsGraphs/scripts/eml-wizard.praat"
