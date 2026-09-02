# Shared prelude for every graph stress case.
# Included, not run on its own.
#
# THE PATHS BELOW ARE RELATIVE, AND THEY RESOLVE AGAINST THE TOP-LEVEL
# SCRIPT'S FOLDER — not against this file's. Every case that includes this
# prelude lives in harness/stress_cases/, so "../../plugin/..." is the plugin
# of whatever tree the case was copied into.
#
# THEY USED TO BE ABSOLUTE, and that was not a cosmetic defect. A copy of
# this repository rendered anywhere else silently loaded the ORIGINAL tree's
# plugin and produced 39 figures that looked entirely correct while
# describing a build nobody asked about. Hit for real, trying to render a
# shadow build: the only symptom was that a revert appeared not to take
# effect. Corrected 10 August 2026, and verified by rendering the whole suite
# from a copy of the repo at a different path and diffing every output.
# Same include set as plugin/scripts/eml-graphs.praat, minus eml-graphs-form,
# which is the interactive wrapper and calls beginPause:. The draw library is
# NOT self-contained — emlDrawViolinPlot calls emlCountGroups, which lives in
# stats/eml-extract.praat — so the stats layer has to come along.
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

@emlInitializeDrawingDefaults

; EML_OUT is set by harness/stress_graphs.sh for every case. The fallback is
; only reached by a case run BY HAND, and it is deliberately relative so that
; doing so cannot write into another tree.
stressOut$ = environment$ ("EML_OUT")
if stressOut$ = ""
    stressOut$ = "unnamed.png"
endif

# @stressSave: .vpW, .vpH
# Saves the Picture window at the viewport the case drew into. Called last.
procedure stressSave: .vpW, .vpH
    # "Save as 300-dpi PNG file:" is a Picture-window command, but with a Table
    # selected Praat resolves the name against the Table's own save actions and
    # reports "not available for current selection". Clearing the object list
    # first is the only reliable way to reach the Picture command from a script.
    select all
    .nSel = numberOfSelected ()
    if .nSel > 0
        Remove
    endif
    # Use the plugin's own pre-save idiom rather than a fixed viewport, so
    # what the harness saves is what the plugin saves. Anything clipped here
    # is clipped in the product too.
    #
    # ANCHOR, not a line number:
    #     grep -n '@emlAssertFullViewport' plugin/graphs/eml-graphs-form.praat
    # returns the plugin's two pre-save call sites. The procedure itself is
    # `procedure emlAssertFullViewport` in graphs/eml-graph-procedures.praat.
    # (C5: this comment used to cite `:5735`, which is
    # `spGroupIdx = spPresetGroupIdx`; it was retargeted to `:6595`/`:6670`,
    # and those had already drifted to `:6612`/`:6687` within the hour. Two
    # retargetings in two days is the argument for grepping the name. Do NOT
    # write a line number back into this comment.)
    @emlAssertFullViewport
    Save as 300-dpi PNG file: stressOut$
    appendInfoLine: "SAVED ", stressOut$
endproc

# @stressTable: .name$, .n  -> empty table, caller fills it
procedure stressTable: .name$, .cols$, .n
    .id = Create Table with column names: .name$, .n, .cols$
endproc
