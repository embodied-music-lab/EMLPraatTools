include _prelude.praat
Erase all
@emlInitializeDrawingDefaults
Create Table with column names: "t", 0, "x y"
for i from 1 to 600
    Append row
    Set numeric value: i, "x", randomUniform (0.2, 9.8)
    Set numeric value: i, "y", randomUniform (0.2, 9.8)
endfor
tid = selected ("Table")
@emlDrawScatterPlot: tid, "Alpha probe", "x", "y", 6, 5, "color", 4,
... "x", "y", "", 0, 10, 0, 10, 0
@emlClearAnnotations
annotTextN = 1
annotTextX[1] = 5
annotTextY[1] = 5
annotTextAnchor$[1] = "centre"
annotTextLabel$[1] = "n = 600, r = .02"
@emlDrawAnnotations: emlDrawScatterPlot.axisXMin, emlDrawScatterPlot.axisXMax,
... emlDrawScatterPlot.axisYMax,
... emlDrawScatterPlot.axisYMax - emlDrawScatterPlot.axisYMin,
... "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize,
... emlDrawScatterPlot.axisYMin, emlDrawScatterPlot.axisYMax
appendInfoLine: "ALPHAMODE=", emlAlphaBgMode$
appendInfoLine: "SPRITE=", emlInitAlphaSprites.available
@emlAssertFullViewport
Save as 300-dpi PNG file: "annot_alpha.png"
