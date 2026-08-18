include fixture.praat
# ONE FIGURE, ERASE ON, ORIGIN 0,0 -- the default path, and the case that
# matters most. Its PNG must be byte-identical to the one the same draw
# produced before page composition existed. Anything else means the feature
# moved a figure nobody asked it to move.
@composePanel: 11, 0, 0, 1, 1, "Grouped violin"
@composeSave
