# D117 — table for the two-group and k-group pages (A2A / A2B). Those two
# pages already preserved their column indices correctly; the D117 change
# routed them through @wizardColIdx so the file holds one idiom rather than
# two hand-written copies, and this drives them to confirm nothing regressed.
tid = Create Table with column names: "demo_groups", 45,
... "singer voice_type SPL_dB vibrato_rate_Hz"
for i from 1 to 45
    Set string value: i, "singer", "Singer_" + string$ (i)
endfor
for i from 1 to 15
    Set string value: i, "voice_type", "Soprano"
    Set numeric value: i, "SPL_dB", 90 + (i mod 5)
    Set numeric value: i, "vibrato_rate_Hz", 5.6 + (i mod 4) / 10
endfor
for i from 16 to 30
    Set string value: i, "voice_type", "Mezzo"
    Set numeric value: i, "SPL_dB", 86 + (i mod 6)
    Set numeric value: i, "vibrato_rate_Hz", 5.3 + (i mod 3) / 10
endfor
for i from 31 to 45
    Set string value: i, "voice_type", "Alto"
    Set numeric value: i, "SPL_dB", 83 + (i mod 4)
    Set numeric value: i, "vibrato_rate_Hz", 5.0 + (i mod 5) / 10
endfor
selectObject: tid
runScript: preferencesDirectory$
... + "/plugin_EML_StatsGraphs/scripts/eml-wizard.praat"
