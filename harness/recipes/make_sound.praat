# ---------------------------------------------------------------------------
# recipes/make_sound.praat -- the fixture Sound recipe R5 reads
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# SYNTHESISED, NOT RECORDED, and not committed as a .wav. A recorded vowel is
# a binary blob whose contents nobody can inspect in a diff, and R5's printed
# numbers are pinned -- so the thing that produces them has to be readable.
# Four harmonics of a 196 Hz fundamental (G3, a comfortable baritone sustain),
# frequency-modulated at 5 Hz for vibrato, with a silent window in the middle.
#
# THE SILENCE IS THE POINT. A Pitch object has a frame everywhere, and only
# some of them carry a value. R5 prints .n against .nTotal, and on an
# all-voiced fixture those two are equal and the recipe teaches nothing about
# the difference. The gap makes the two numbers differ, so a change that
# started reporting total frames as voiced frames would move a pinned number.
#
# THE VIBRATO IS THE OTHER POINT. On a dead-steady tone the median, the
# quartiles and the SD collapse onto one number and three different
# descriptive kernels become indistinguishable from each other. A modulation
# index of 2.0 at 5 Hz is a deviation of +/- 10 Hz, so R5's quartiles and its
# SD are separately meaningful and separately pinned.
#
# The modulated phase is written out in full at each harmonic rather than
# hoisted into a variable: a Praat Sound formula is one expression, evaluated
# per sample, with nowhere to put one.
#
# Argument: the .wav path to write.
# ---------------------------------------------------------------------------
form: "make_sound"
    sentence: "Path", ""
endform

sound = Create Sound from formula: "sustained_a", 1, 0, 2.0, 22050,
... "if x < 0.8 or x > 1.2 then
...      0.5 * sin (    (2*pi*196*x + 2.0 * sin (2*pi*5*x)))
...    + 0.3 * sin (2 * (2*pi*196*x + 2.0 * sin (2*pi*5*x)))
...    + 0.2 * sin (3 * (2*pi*196*x + 2.0 * sin (2*pi*5*x)))
...    + 0.1 * sin (4 * (2*pi*196*x + 2.0 * sin (2*pi*5*x)))
...  else 0 fi"

selectObject: sound
Save as WAV file: path$
writeInfoLine: "MAKESOUND wrote ", path$
