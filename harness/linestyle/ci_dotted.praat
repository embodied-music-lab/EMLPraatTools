include fixture.praat
# THE CONFIDENCE-BAND LINE CHART. One control, on the line chart's own dialog, governing both variants -- the band is painted, and the pen is the MEAN LINE's.
# DOTTED. Less ink along the same path, and a frame that is still solid --
# the pen is put back before @emlDrawAxes draws the box and the ticks.
@lsSetType: 5
tsShowCI = 1
tsLineStyle = 2
@lsPress
@lsReport: 2
@lsSave
