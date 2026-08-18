include fixture.praat
# A REFUSAL ON A CONTINUOUS-X TYPE OUTSIDE V1 SCOPE. The confidence-band
# variant of the very chart that carries the feature: same dialog, same
# columns, one tickbox further on -- and the message names the CURRENT SCOPE,
# so the answer to "why not mine" is a version rather than a shrug.
tsShowCI = 1
title$ = "Time series with CI, second axis refused"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "cq"
@emlGraphsDrawWithLegendRoom
appendInfoLine: "REFUSAL ", emlSecondAxisRefusal$
appendInfoLine: "REFUSED ", emlSecondAxisRefused
@secondSave
