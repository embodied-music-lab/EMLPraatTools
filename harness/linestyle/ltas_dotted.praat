include fixture.praat
# THE LTAS CURVE. The pen is set inside `if .showCurve` and nowhere else: bars, poles and speckles are not strokes of a line, and a dashed pen would break a bar's outline into pieces.
# DOTTED. Less ink along the same path, and a frame that is still solid --
# the pen is put back before @emlDrawAxes draws the box and the ticks.
@lsSetType: 4
ltasLineStyle = 2
@lsPress
@lsReport: 2
@lsSave
