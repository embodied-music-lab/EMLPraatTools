include fixture.praat
# THE WAVEFORM. Praat's own `Draw:` on the Sound object in "Curve" style.
# DOTTED. Less ink along the same path, and a frame that is still solid --
# the pen is put back before @emlDrawAxes draws the box and the ticks.
@lsSetType: 2
wavLineStyle = 2
@lsPress
@lsReport: 2
@lsSave
