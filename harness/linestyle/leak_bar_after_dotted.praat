include fixture.praat
# THE PIN ON THE RESET, AND THE REASON THE RESET EXISTS.
#
# Praat keeps the line style in the PICTURE WINDOW, not in the figure, so a
# pen left set does not merely dash the next series -- it dashes the next
# error bar, the next inner box and the next tick mark, on every figure drawn
# afterwards in the same session.
#
# So: a dotted line chart, and then a bar chart, in ONE process, exactly as a
# user gets them from two presses of Draw. The bar chart is what is saved, and
# validate/v96 requires it to be byte-identical to bar_alone.png. Remove
# either reset -- @emlResetLineStyle inside the draw, or
# @emlGraphsResetSeriesPens after the press -- and the second figure comes
# back with a dotted frame, dotted ticks and dotted error bars.
#
# THE AXIS IS RESTATED BETWEEN THE PRESSES because the legend-room loop writes
# valueMin/valueMax on the figure it resolved them for, and the form's next
# press restates them from its own dialog. Without that this case would
# compare two bar charts on two different axes and the pen would not be what
# it was measuring.
@lsSetType: 5
tsLineStyle = 2
@lsPress

@lsSetType: 6
groupColName$ = "g"
valueColName$ = "v"
valueMin = 0
valueMax = 0
@lsPress
@lsReport: 1
@lsSave
