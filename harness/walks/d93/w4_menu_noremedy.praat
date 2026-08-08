# ============================================================================
# D93 walk 4 — MENU path, error with NO remedy
# ============================================================================
# scripts/eml-regress.praat:91 — @emlErrorDialog with .remedy$ = "", i.e. the
# other of the two menu-mode branches. 13 of the 14 menu sites can only reach
# this branch: only @emlRunTwoGroupAnalysis ever sets a non-empty .remedy$
# (stats/eml-analysis.praat:114).
#
# Claims under test: 2 (does a remedy-less menu error still say where to go)
# and 3 (form state survives the return).
# ============================================================================

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
... + "/plugin_EML_Praat_Tools/scripts/eml-regress.praat"
