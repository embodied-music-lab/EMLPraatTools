# ============================================================================
# D93 walk 3 — WIZARD path, correctable selection mistake at a FORMER
# exitScript: site
# ============================================================================
# eml-wizard.praat:1375 — before commit 438cdb1 this read
#   exitScript: "Please select two different columns."
# One of the six "correctable mistake" teardowns.
#
# Claims under test: 1 (wizard errors return into the wizard) and 3 (form
# state on the return).
# ============================================================================

tid = Create Table with column names: "demo_corr", 20,
... "singer SPL_dB vibrato_rate_Hz jitter_pct"
for i from 1 to 20
    Set string value: i, "singer", "Singer_" + string$ (i)
    Set numeric value: i, "SPL_dB", 80 + (i mod 9)
    Set numeric value: i, "vibrato_rate_Hz", 5 + (i mod 7) / 10
    Set numeric value: i, "jitter_pct", 1 + (i mod 5) / 10
endfor

selectObject: tid
runScript: preferencesDirectory$
... + "/plugin_EML_Praat_Tools/scripts/eml-wizard.praat"
