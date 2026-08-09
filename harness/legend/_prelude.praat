# ---------------------------------------------------------------------------
# LEGEND HARNESS PRELUDE. Included, never run on its own.
#
# WHY THIS EXISTS RATHER THAN harness/stress_cases/_prelude.praat, which is
# what these cases used to include. That file names the plugin by ABSOLUTE
# path — /home/claude/EMLPraatTools/plugin/... — so a copy of this repo
# rendered anywhere else silently loads the ORIGINAL tree's plugin instead of
# the one under test, and every measurement in the copy describes a build
# nobody asked about. It is not a hypothetical: it was hit trying to render a
# shadow build, and the failure is silent because the figures still come out.
#
# harness/stress_cases/_prelude.praat is NOT changed — other harnesses depend
# on its current form. This is harness/legend/ insulating itself.
#
# THE PATHS HERE ARE RELATIVE, AND THEY RESOLVE AGAINST THE TOP-LEVEL SCRIPT'S
# FOLDER. Measured 9 Aug 2026: Praat resolves an `include` inside an included
# file against the folder of the script that was RUN, not against the folder
# of the file the directive is written in. Every case that includes this
# prelude lives in harness/legend/, so `../../plugin/...` is the plugin of
# whatever tree the case file was copied into. A case placed somewhere else
# would have to bring its own prelude, which is the point.
#
# For the default tree these are byte-for-byte the same eight files
# harness/stress_cases/_prelude.praat names, in the same order, so nothing
# that was rendered before moves.
#
# AN ABSOLUTE ROOT IS STILL AVAILABLE. harness/legend/run.sh honours
# EML_PLUGIN_ROOT by staging the case files into a scratch folder beside a
# GENERATED prelude whose includes are absolute into that root. Nothing in
# this file has to change for that, and the default run never uses it.
#
# Same include set as plugin/scripts/eml-graphs.praat, minus eml-graphs-form,
# which is the interactive wrapper and calls beginPause:. A case that needs a
# procedure out of the form includes the form for itself — see
# harness/legend/series_case.praat, which needs @emlLegendHeadroomAfterDraw.
# The draw library is NOT self-contained — emlDrawViolinPlot calls
# emlCountGroups, which lives in stats/eml-extract.praat — so the stats layer
# has to come along.
# ---------------------------------------------------------------------------
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

@emlInitDrawingDefaults

stressOut$ = environment$ ("EML_OUT")
if stressOut$ = ""
    stressOut$ = "/home/claude/stress/out/unnamed.png"
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
    @emlAssertFullViewport
    Save as 300-dpi PNG file: stressOut$
    appendInfoLine: "SAVED ", stressOut$
endproc

# @stressTable: .name$, .n  -> empty table, caller fills it
procedure stressTable: .name$, .cols$, .n
    .id = Create Table with column names: .name$, .n, .cols$
endproc
