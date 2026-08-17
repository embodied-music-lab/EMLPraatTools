# D117 — table for the two-factor page (A2C_TWOFACTOR).
tid = Create Table with column names: "demo_2factor", 24,
... "singer sex style SPL_dB"
for i from 1 to 24
    Set string value: i, "singer", "Singer_" + string$ (i)
    if i mod 2 = 0
        Set string value: i, "sex", "F"
    else
        Set string value: i, "sex", "M"
    endif
    if i mod 4 < 2
        Set string value: i, "style", "Classical"
    else
        Set string value: i, "style", "Belt"
    endif
    Set numeric value: i, "SPL_dB", 80 + (i mod 9)
endfor
selectObject: tid
runScript: preferencesDirectory$
... + "/plugin_EML_StatsGraphs/scripts/eml-wizard.praat"
