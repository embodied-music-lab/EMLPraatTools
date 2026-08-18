include fixture.praat
# A TYPE WITH NO PEN OF ITS OWN, DRAWN ALONE. The bar chart strokes no series:
# it paints rectangles and it draws error bars, and no line-style control
# appears on its dialog. This is the control half of the leak pair below --
# the same figure with nothing drawn before it.
@lsSetType: 6
groupColName$ = "g"
valueColName$ = "v"
valueMin = 0
valueMax = 0
@lsPress
@lsReport: 1
@lsSave
