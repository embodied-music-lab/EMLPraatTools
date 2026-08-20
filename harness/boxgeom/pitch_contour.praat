include fixture.praat
# THE PITCH CONTOUR. Praat's own `Draw` on a Pitch object, inside the
# plugin's frame. The time axis is padded and the f0 axis is a fixed 75..600
# window rather than the tracked range, so this figure's contour reaches no
# edge of the frame and claims none. It is here for containment: a contour
# that hangs outside its own box is the defect whatever the axis was.
@bgSetType: 1
@bgPress
@bgSave: "none"
