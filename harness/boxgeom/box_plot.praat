include fixture.praat
# THE BOX PLOT. Same pinned value axis as the violin: the whiskers run to the
# extreme observations, which are the axis limits, so bottom and top are
# claimed and the padded category axis is not.
@bgSetType: 9
groupColName$ = "g"
@bgPress
@bgSave: "bottom top"
