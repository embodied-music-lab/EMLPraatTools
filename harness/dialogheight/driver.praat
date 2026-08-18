# ---------------------------------------------------------------------------
# dialogheight/driver.praat — open ONE graph type's dialog and stop there
# ---------------------------------------------------------------------------
# One graph type per session, chosen by $EML_DH_TYPE. Presets are set so that
# every optional block on the page is PRESENT: a group column where the page
# offers one, a subgroup column where it offers one, annotation on, and the
# nonparametric arm (the only arm that carries the "Adjustment method" menu
# rather than the one-line comment that replaces it).
#
# Advanced mode is set from the PREF DIR's config file, not from the toggle
# button: pressing the toggle would put the page on the RESTORE arm, which is
# a different page. Same reason graphseams/adjustarm.sh does it that way.
#
# Nothing is drawn. The shell measures the window and kills the session.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graphs-form.praat

gtype$ = environment$ ("EML_DH_TYPE")
if gtype$ = ""
    gtype$ = "10"
endif
gtype = number (gtype$)

if gtype <= 4
    # Acoustic types. A Sound is made here and left selected; the form's own
    # conversion produces the Pitch/Spectrum/Ltas, which is also the branch
    # that puts the two extra pitch-analysis fields on the Pitch page.
    snd = Create Sound from formula: "dh", 1, 0, 1.2, 22050,
    ... "0.4 * sin (2*pi*180*x) + 0.2 * sin (2*pi*360*x) + 0.05 * randomGauss (0, 1)"
    if gtype = 3
        selectObject: snd
        spec = To Spectrum: "yes"
        selectObject: spec
    elsif gtype = 4
        selectObject: snd
        lt = To Ltas: 100
        selectObject: lt
    elsif gtype = 1
        selectObject: snd
    else
        selectObject: snd
    endif
    targetId = selected ()
else
    table = Read Table from comma-separated file: "fixtures/demo_2factor.csv"
    targetId = selected ("Table")
endif

emlGraphsPresetType = gtype
emlGraphsPresetAnnotate = 1
emlGraphsPresetTestType$ = "nonparametric"
emlGraphsPresetDataCol$ = "F0_Hz"
emlGraphsPresetGroupCol$ = "group"
emlGraphsPresetSubgroupCol$ = "condition"
if gtype = 8
    emlGraphsPresetXCol$ = "F0_Hz"
    emlGraphsPresetYCol$ = "jitter_pct"
endif

# The three two-factor/histogram pages keep the test-type menu in a prev_*
# variable that the preset channel does not reach, so the nonparametric arm --
# the arm that carries the "Adjustment method" optionmenu instead of the
# one-line comment that replaces it -- is set here directly. It is a state a
# user reaches by choosing Nonparametric and coming back to the page.
if environment$ ("EML_DH_NONPAR") = "1"
    prev_histAnnotTestType = 2
    prev_gvAnnotTestType = 2
    prev_gbAnnotTestType = 2
endif

appendInfoLine: "DH begin type=", gtype, " id=", targetId
@emlGraphsWorkflow: targetId
appendInfoLine: "DH end"
