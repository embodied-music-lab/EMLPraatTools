include fixture.praat
# THE PITCH CONTOUR. Praat's own `Draw:` on the Pitch object strokes it, and it obeys the Picture window's pen like any other stroke.
# DOTTED. Less ink along the same path, and a frame that is still solid --
# the pen is put back before @emlDrawAxes draws the box and the ticks.
@lsSetType: 1
f0LineStyle = 2
@lsPress
@lsReport: 2
@lsSave
