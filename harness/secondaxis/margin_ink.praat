include fixture.praat
# ---------------------------------------------------------------------------
# CAN THE RIGHT-HAND AXIS FURNITURE WEAR THE SERIES' COLOUR? NO, AND THIS IS
# WHY. Ian left that open, to be implemented one way and reported so he could
# reverse it in a word. Praat answers it instead: its margin commands draw in
# BLACK whatever colour is current, so there is no version of the plugin that
# colours the right ticks without drawing the right margin by hand.
#
# The probe drives the three commands the right margin is made of, each under
# a RED pen, on a bare figure with nothing else on it. validate/v95 reads the
# rendered pixels and requires that no red reached the margin -- and that red
# DID reach a `Draw line` in the same figure under the same pen, which is what
# makes this a statement about margins rather than about the pen.
# ---------------------------------------------------------------------------
Erase all
Select outer viewport: 0, 6, 0, 4
Axes: 0, 10, 0, 100
Draw inner box
Colour: "Red"
; The control: an ordinary stroke inside the plot, same pen.
Draw line: 1, 10, 9, 90
; The three margin commands, all still under the red pen.
One mark right: 50, "yes", "yes", "no", ""
Marks right every: 1, 25, "yes", "yes", "no"
Text right: "yes", "Right axis name"
appendInfoLine: "MARGININK drove three right-margin commands under a red pen"
Save as 300-dpi PNG file: secondOut$
