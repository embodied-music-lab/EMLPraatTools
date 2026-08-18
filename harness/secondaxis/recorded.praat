include fixture.praat
include ../../plugin_EML_StatsGraphs/stats/eml-record.praat
# ---------------------------------------------------------------------------
# THE SECOND AXIS, RECORDED AND EMITTED. A recording is started, one two-scale
# figure is drawn through the form's own dispatch, and the script is flushed.
#
# WHAT THIS PROVES that a PNG cannot: that the request is carried on the STEP
# and lifted into the editable block at the top of the emitted file, under the
# numbering convention every other choice follows -- so a user who reruns the
# script gets the same two-scale figure, and one who retypes secondAxisCol$
# retargets it.
#
# The recorder is included HERE and not in the fixture: every other case in
# this harness runs with the recorder absent, which is the state most callers
# of the draw layer are in and the one the variableExists guards are for.
# ---------------------------------------------------------------------------
@emlRecordBegin: "out"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "cq"
emlSecondAxisMin = 0
emlSecondAxisMax = 0
emlSecondAxisLabel$ = "Contact quotient"
emlSecondAxisStyle = 3
emlLineStyle = 2
@emlGraphsDrawWithLegendRoom
@secondReport
@emlRecordFlush: "out/recorded_script.praat"
appendInfoLine: "FLUSHED ", emlRecordFlush.written
@secondSave
