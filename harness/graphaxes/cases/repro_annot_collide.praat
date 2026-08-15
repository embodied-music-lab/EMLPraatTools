include _prelude.praat
# NEW-G8-4 reproduction: the annotation panel lands on a datum.
#
# A rising diagonal cloud, plus ONE point tucked into the top-left corner
# (inside where the panel is drawn) and TWO in the bottom-right but far from
# that corner (outside where the panel would be drawn). Quadrant scoring
# picks top-left because 1 < 2 and covers the point; rectangle scoring picks
# bottom-right because 0 < 1 and covers nothing.
annotate = 1
t = Create Table with column names: "collide", 23, "x y"
for i from 1 to 20
    selectObject: t
    Set numeric value: i, "x", 10 + (i - 1) * 4
    Set numeric value: i, "y", 10 + (i - 1) * 4
endfor
selectObject: t
# The one in the top-left corner, right where the panel goes.
Set numeric value: 21, "x", 15
Set numeric value: 21, "y", 100
# Two in the bottom-right quadrant but nowhere near its corner.
Set numeric value: 22, "x", 55
Set numeric value: 22, "y", 30
Set numeric value: 23, "x", 60
Set numeric value: 23, "y", 25
Erase all
@emlDrawScatterPlot: t, "Collision probe", "X", "Y", 6, 4, "color", 4, "x", "y", "", 0, 0, 0, 0, 1
appendInfoLine: "CORNER ", emlPlaceAnnotationBox.corner1$
appendInfoLine: "COLLISIONS ", emlPlaceAnnotationBox.collisions
appendInfoLine: "QUADRANT_CORNER ", emlPlaceElements.corner1$
appendInfoLine: "BOXW ", emlPlaceAnnotationBox.boxW
appendInfoLine: "BOXH ", emlPlaceAnnotationBox.boxH
appendInfoLine: "COLLIDEN ", emlCollideN
appendInfoLine: "HITS ", emlPlaceAnnotationBox.hit[1], " ", emlPlaceAnnotationBox.hit[2], " ", emlPlaceAnnotationBox.hit[3], " ", emlPlaceAnnotationBox.hit[4]
appendInfoLine: "TLBOX ", emlPlaceAnnotationBox.cLeft[1], " ", emlPlaceAnnotationBox.cTop[1]
appendInfoLine: "AXY ", emlDrawScatterPlot.axisYMin, " ", emlDrawScatterPlot.axisYMax
@axSave
