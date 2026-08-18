include fixture.praat
# A REFUSAL ON A CATEGORICAL-X TYPE, WITH THE REASON THAT BELONGS TO IT.
# The request is set and a violin plot is drawn: the figure comes out with one
# y-axis and the Info window says why, naming the axis SHAPE rather than the
# version.
graph_type = 7
groupColName$ = "g"
valueColName$ = "f0"
title$ = "Violin, second axis refused"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "cq"
emlSecondAxisLabel$ = "Contact quotient"
@emlGraphsDrawWithLegendRoom
appendInfoLine: "REFUSAL ", emlSecondAxisRefusal$
appendInfoLine: "REFUSED ", emlSecondAxisRefused
@secondSave
