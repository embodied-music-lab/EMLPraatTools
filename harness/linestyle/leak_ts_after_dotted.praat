include fixture.praat
# THE SAME PIN, ON THE TYPE THAT HAS THE CONTROL. A dotted line chart, then a
# line chart whose dialog says Solid -- the second figure must be the solid
# figure, byte for byte, and not a dotted one drawn by a pen nobody put back.
#
# THIS CASE ALONE WOULD NOT PIN THE DRAW LAYER'S RESET, and that is worth
# saying: @emlDrawTimeSeries applies the requested style at the top of every
# draw, so a second press that asks for Solid issues `Solid line` whatever
# state it inherited. It pins the FORM's reset -- the per-type variable is
# read through @emlGraphsPublishSeriesPens on every press, so a press that
# said Solid cannot inherit the last press's pen. leak_bar_after_dotted is the
# case that pins the draw layer's, because a bar chart sets no pen at all.
@lsSetType: 5
tsLineStyle = 2
@lsPress

tsLineStyle = 1
valueMin = 0
valueMax = 0
@lsPress
@lsReport: 1
@lsSave
