include fixture.praat
# THE PAGE CONTROLS, NEVER TOUCHED.
#
# @composePanel sets emlEraseFirst, emlPanelOriginX and emlPanelOriginY on
# every press, which is what the graphs form does. This case sets none of
# them and draws the same figure single.praat draws, so what it renders is
# what a caller that has never heard of page composition gets:
# @emlInitDrawingDefaults' erase-on single panel at the origin.
#
# validate/v94 asserts this PNG is byte-identical to single.png. That is the
# whole of the compatibility claim, and it is a comparison between two files
# this harness produced rather than a hash written down in a validator, which
# would only say that the figure has not changed since somebody typed a hash.
valueMin = 0
valueMax = 0
histFreqMax = 0
totalCanvasHeight = figure_height
graph_type = 11
title$ = "Grouped violin"
config_legendPlacement = 1
@emlClearAnnotations
@emlGraphsDrawWithLegendRoom
appendInfoLine: "PANEL ", title$, " type=11 origin=untouched",
... " erase=untouched placement=1 passes=", legendRoomPass
@composeSave
