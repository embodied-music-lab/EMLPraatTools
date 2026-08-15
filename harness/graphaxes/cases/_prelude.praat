# Shared prelude for the axis / channel harness cases.
# Same include set as harness/stress_cases/_prelude.praat, resolved relative
# to the TOP-LEVEL script's folder (harness/graphaxes/cases/).
include ../../../plugin/graphs/eml-graph-procedures.praat
include ../../../plugin/stats/eml-core-utilities.praat
include ../../../plugin/stats/eml-core-descriptive.praat
include ../../../plugin/stats/eml-extract.praat
include ../../../plugin/stats/eml-output.praat
include ../../../plugin/stats/eml-inferential.praat
include ../../../plugin/graphs/eml-annotation-procedures.praat
include ../../../plugin/graphs/eml-draw-procedures.praat

@emlInitDrawingDefaults

axOut$ = environment$ ("EML_OUT")
if axOut$ = ""
    axOut$ = "unnamed.png"
endif

procedure axSave
    select all
    .nSel = numberOfSelected ()
    if .nSel > 0
        Remove
    endif
    @emlAssertFullViewport
    Save as 300-dpi PNG file: axOut$
    appendInfoLine: "SAVED ", axOut$
endproc
