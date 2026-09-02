include fixture.praat
# A CALLER THAT NEVER STATED A PEN -- the control.
#
# Not every figure this library draws comes from the graphs form. A stats
# wrapper, a PraatGen companion, a probe in this tree and a replayed script
# all call @emlDrawTimeSeries directly, and none of them runs
# @emlGraphsPublishSeriesPens. What such a caller gets is whatever
# emlLineStyle holds, which @emlInitializeDrawingDefaults seeds at 1.
#
# This case is that caller with nothing drawn before it. The case beside it is
# the same caller after a dotted press, and validate/v96 requires the two
# files to be identical.
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
