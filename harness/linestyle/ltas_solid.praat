include fixture.praat
# THE LTAS CURVE. The pen is set inside `if .showCurve` and nowhere else: bars, poles and speckles are not strokes of a line, and a dashed pen would break a bar's outline into pieces.
# SOLID, the control: the same figure, same data, same axis, differing from
# the case beside it in one option.
@lsSetType: 4
ltasLineStyle = 1
@lsPress
@lsReport: 1
@lsSave
