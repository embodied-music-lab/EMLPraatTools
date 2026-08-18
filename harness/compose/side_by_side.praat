include fixture.praat
# TWO PANELS SIDE BY SIDE, FROM TWO PRESSES OF DRAW.
# Press 1 erases the page and draws at the origin. Press 2 leaves the page
# alone and draws one figure width to the right. The saved image is the
# extent union, which is how Save has always worked.
@composePanel: 11, 0, 0, 1, 1, "Left panel"
@composePanel: 12, 6.5, 0, 0, 1, "Right panel"
@composeSave
