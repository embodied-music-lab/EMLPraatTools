include fixture.praat
# THE WAVEFORM. The x axis is the sound's whole duration, so the first and
# last samples ARE the left and right edges of the frame -- that reach is a
# property of the type, not of the fixture, and holds for any sound.
# The amplitude axis is padded past the peak, so top and bottom are not
# claimed.
@bgSetType: 2
@bgPress
@bgSave: "left right"
