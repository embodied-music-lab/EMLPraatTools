# WHAT RUN 2 MUST COME BACK AS once data2$ is pointed at the twin. Drawn
# after the recording is discarded, so it is not a step -- it is the answer
# the edited block is checked against.
Erase all
@emlDrawBoxPlot: tableTwin, "Second", "Group", "other", 6, 4, "color", 1,
... "grp", "other", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/REF_twin.png"
