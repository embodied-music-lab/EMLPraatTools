# Shared prelude for every graph stress case.
# Included, not run on its own.
# Same include set as plugin/scripts/eml-graphs.praat, minus eml-graphs-form,
# which is the interactive wrapper and calls beginPause:. The draw library is
# NOT self-contained — emlDrawViolinPlot calls emlCountGroups, which lives in
# stats/eml-extract.praat — so the stats layer has to come along.
include /home/claude/EMLPraatTools/plugin/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-extract.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-output.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-draw-procedures.praat

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
    # Use the plugin's own pre-save idiom (eml-graphs-form.praat:5735) rather
    # than a fixed viewport, so what the harness saves is what the plugin
    # saves. Anything clipped here is clipped in the product too.
    @emlAssertFullViewport
    Save as 300-dpi PNG file: stressOut$
    appendInfoLine: "SAVED ", stressOut$
endproc

# @stressTable: .name$, .n  -> empty table, caller fills it
procedure stressTable: .name$, .cols$, .n
    .id = Create Table with column names: .name$, .n, .cols$
endproc
