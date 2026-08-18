include fixture.praat
# THE PIN ON THE FORM'S RESET, AND THE ONLY CASE THAT CAN SEE IT.
#
# @emlGraphsResetSeriesPens is not what makes the next PRESS correct -- the
# publish states the whole request on every press, so a press cannot inherit
# one. It is what makes correct every draw that does not come through the
# form: a stats wrapper's figure, a probe, a script replayed in the same
# session. Those callers read emlLineStyle without setting it, and Praat
# cannot unset a variable, so the only thing standing between them and the
# last press's pen is the reset.
#
# So: a dotted line chart through the form's own dispatch, and then a direct
# call to @emlDrawTimeSeries stating no pen at all. The second figure must be
# the one unpublished_alone.praat draws, byte for byte. Take the pen line out
# of @emlGraphsResetSeriesPens and it comes back dotted.
@lsSetType: 5
tsLineStyle = 2
@lsPress

valueMin = 0
valueMax = 0
; THE PAGE IS THE CALLER'S JOB, NOT THE DRAW PROCEDURE'S. @emlBeginPanel is
; called by the graphs form before it dispatches; a direct caller states it
; itself or draws on top of whatever was there. Measured, not assumed: without
; this line the second figure is the first one with a second figure over it,
; and the residue along the overlapping strokes made the two cases differ by
; several hundred pixels for a reason that had nothing to do with the pen.
@emlBeginPanel: 0, 0, 1
@emlDrawTimeSeries: lsTableId, "Line style", "Time (s)", "Value", 6, 4,
... "color", 1, "t", "v", "", 0, 0, 0, 0
@lsReport: 1
@lsSave
