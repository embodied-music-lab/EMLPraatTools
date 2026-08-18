include fixture.praat
# THE SAME FIGURE WITH THE RIGHT RANGE TYPED rather than automatic. 0 to 1 is
# the whole of a proportion, so the right series sits in the middle band of
# the box and the right ticks run 0 .. 1 -- which is the point: a typed pair
# is obeyed, and the auto path's proportional placement is not applied to it.
emlSecondAxisOn = 1
emlSecondAxisCol$ = "cq"
emlSecondAxisMin = 0
emlSecondAxisMax = 1
emlSecondAxisLabel$ = "Contact quotient"
emlSecondAxisStyle = 3
@emlGraphsDrawWithLegendRoom
@secondReport
@secondSave
