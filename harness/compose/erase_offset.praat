include fixture.praat
# ERASE ON, AT AN OFFSET ORIGIN, WHICH IS VALID AND STARTS A COMPOSITE.
#
# The origin is live whether or not the page is erased: this press clears the
# page and puts its panel at 2, 1 rather than at 0, 0, and the union is that
# panel where it sits. A second press with the erase unticked would then
# compose around it. The saved image is the union, so an offset first panel
# does NOT pad the file with the inch of margin above and to the left of it --
# the page is what was drawn, not the region a coordinate system was measured
# from.
@composePanel: 11, 2, 1, 1, 1, "Offset first panel"
@composeSave
