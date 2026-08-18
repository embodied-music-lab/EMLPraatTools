# ---------------------------------------------------------------------------
# DOES PRAAT'S PLOT FURNITURE HONOUR THE PICTURE WINDOW'S PEN?
#
# WHY THE QUESTION HAD TO BE ASKED. The reason @emlResetLineStyle exists is
# that Praat keeps the line style in the PICTURE WINDOW rather than in the
# figure, so a pen left set outlives the figure it was set for. The obvious
# consequence -- a dashed pen giving a dashed inner box and dashed tick marks
# on the same figure, since @emlDrawAxes draws them after the series -- was
# ASSERTED in the first draft of validate/v96 and turned out to be false.
# harness/linestyle/break.sh, driving a tree with every reset commented out,
# produced broken error bars on the next figure and a frame that was still
# perfectly solid.
#
# SO THIS CASE MEASURES IT INSTEAD OF ASSUMING IT, and it is deliberately
# plugin-free: one dotted pen, one ordinary `Draw line` for control, and then
# the three commands @emlDrawAxes uses to put a box and its ticks on a figure.
# If the furniture honoured the pen, the box's top edge would come back as a
# row of short dashes. It comes back as one unbroken run the full width of the
# box while the control stroke beside it is in pieces.
#
# It is the same shape of finding as validate/v95 section 12, which measured
# that Praat's right-margin commands draw in black whatever colour is current.
# The furniture is not the caller's to style.
#
# WHAT FOLLOWS FROM IT, and it is the reason this case is worth its seven
# seconds: the frame is a STABLE reference on every figure in this harness. A
# figure whose frame is broken has something wrong with it that no line-style
# option in this plugin can cause.
# ---------------------------------------------------------------------------
fpOut$ = environment$ ("EML_OUT")
if fpOut$ = ""
    fpOut$ = "unnamed.png"
endif

Erase all
Select outer viewport: 0, 6, 0, 4
Axes: 0, 10, 0, 10
Dotted line
; THE CONTROL, INSIDE THE BOX: an ordinary stroke under the same pen.
Draw line: 0.5, 5, 9.5, 5
; AND THE FURNITURE, under that same pen.
Draw inner box
Marks left every: 1, 2, "yes", "yes", "no"
Marks bottom every: 1, 2, "yes", "yes", "no"
Solid line

Select outer viewport: 0, 6, 0, 4
Save as 300-dpi PNG file: fpOut$
