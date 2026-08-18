include fixture.praat
# THE OTHER CONTINUOUS-X REFUSAL, on the type a reader is most likely to ask
# for next. Same wording, same scope sentence, different type name.
graph_type = 8
title$ = "Scatter, second axis refused"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "cq"
@emlGraphsDrawWithLegendRoom
appendInfoLine: "REFUSAL ", emlSecondAxisRefusal$
appendInfoLine: "REFUSED ", emlSecondAxisRefused
@secondSave
