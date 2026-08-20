include fixture.praat
# THE LINE CHART, AXIS PINNED TO THE DATA. data.praat builds t over 1..12 and
# v over 10..120, and the fixture states exactly those four numbers as the
# axis, so the first and last points of the series are the left and right
# edges of the frame and the lowest and highest are the bottom and top. All
# four edges are reachable and all four are claimed -- which makes this the
# case that pins the rectangle from the inside as tightly as it can be pinned.
@bgSetType: 5
@bgPress
@bgSave: "left right bottom top"
