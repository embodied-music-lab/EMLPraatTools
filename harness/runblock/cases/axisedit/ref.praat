# WHAT RUN 1 MUST COME BACK AS once its axisYMax is widened to 60. Drawn
# after the recording is discarded, so it is not a step.
Erase all
@emlDrawBoxPlot: tableAx1, "Ax one", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 2, 60
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/REF_wide.png"
