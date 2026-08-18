include fixture.praat
# THE HISTOGRAM'S OWN REASON: a distribution has one count axis, so there is
# nothing for a second vertical scale to measure.
graph_type = 10
title$ = "Histogram, second axis refused"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "cq"
@emlGraphsDrawWithLegendRoom
appendInfoLine: "REFUSAL ", emlSecondAxisRefusal$
appendInfoLine: "REFUSED ", emlSecondAxisRefused
@secondSave
