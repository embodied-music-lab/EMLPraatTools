include fixture.praat
# THE LIBRARY-LEVEL COLUMN GUARD. The dialog validates the column and
# re-presents its pause on a bad one, but the dialog is not the only caller:
# a recorded script, the API export and any user script can set these globals
# directly. A column that is not numeric produces the one-axis figure and a
# sentence naming the column, not an abort in the middle of a drawing.
emlSecondAxisOn = 1
emlSecondAxisCol$ = "noise"
title$ = "Second axis, non-numeric column"
@emlGraphsDrawWithLegendRoom
@secondReport
@secondSave
