include fixture.praat
# THE BAR CHART. Bars stand on the value axis's lower limit, so the baseline
# is the frame's bottom edge. The category axis pads a half slot at each end
# and the tallest bar is a group MEAN rather than the data maximum, so left,
# right and top are not claimed.
@bgSetType: 6
groupColName$ = "g"
@bgPress
@bgSave: "bottom"
