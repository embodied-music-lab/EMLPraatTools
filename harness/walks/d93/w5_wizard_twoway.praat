# ============================================================================
# D93 walk 5 — WIZARD two-factor page, FORMER exitScript: analysis error
# ============================================================================
# eml-wizard.praat:785 — before commit 438cdb1 this read
#   exitScript: emlRunTwoWayAnalysis.error$
#
# The page's three optionmenus are seeded from dataDefault / f1Default /
# f2Default (set once at :727-729 from @wizardPrepareTable) and nothing ever
# writes the user's own answers back into them, so the `goto A2C_TWOFACTOR`
# return re-renders the page from the guess.
#
# Claims under test: 1 (wizard survives) and 3 (form state survives).
# ============================================================================

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
