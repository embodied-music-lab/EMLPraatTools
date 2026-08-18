include fixture.praat
include ../../plugin_EML_StatsGraphs/stats/eml-record.praat
# ---------------------------------------------------------------------------
# A PEN ON A TYPE THAT HAD NONE, RECORDED AND EMITTED.
#
# The waveform is one of the three types this change order added the control
# to, and it is the interesting one for the recorder: emlLineStyle is not a
# parameter of @emlDrawWaveform: it is a global the form publishes, so a
# recorded call that carried all twelve arguments faithfully would still
# replay a SOLID waveform.
#
# What is asserted on this case: that the emitted file declares the pen in its
# editable block under the numbering convention, and that running the emitted
# file draws the dashed waveform again, byte for byte.
#
# The recorder is included HERE and not in the fixture: every other case in
# this harness runs with the recorder absent, which is the state most callers
# of the draw layer are in and the one the variableExists guards are for.
# ---------------------------------------------------------------------------
@emlRecordBegin: "out"
@lsSetType: 2
wavLineStyle = 3
@lsPress
@lsReport: 3
@emlRecordFlush: "out/recorded_script.praat"
appendInfoLine: "FLUSHED ", emlRecordFlush.written
@lsSave
