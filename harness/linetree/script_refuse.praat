# ============================================================================
# harness/linetree/script_refuse.praat — a right-hand axis asked for by a
# SCRIPT, on a figure whose series are the same measurement
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE ONE LEG WITH NO DIALOG, AND THAT IS ITS SUBJECT.
#
# The question tree cannot ask for this: the right-hand axis page is reached
# only from "different measurements", so no sequence of clicks produces a
# subjects figure with a second scale. That is exactly why @emlSecondAxisGate
# has to refuse it. The callers that CAN produce it are the ones with no
# dialog -- a recorded script edited by hand, the API export, a user's own
# script -- and this file is one of those callers.
#
# WHAT IT PROVES, in one process and two figures:
#   1. role = subjects + a full second-axis request -> ONE y-axis, and a note
#      on the Info window saying the request was refused and why.
#   2. THE SAME REQUEST with role = measurements -> honoured. Without this
#      half, a gate that refused everything would pass the first half.
#
# The globals are set the way @emlGraphsPublishSeriesPens sets them, by name,
# because that is the interface the drawing layer reads. Nothing here reaches
# into a draw procedure's locals.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
include fixture.praat

ltRefusePng$ = environment$ ("EML_LT_PNG2")

# The table is data_subjects4.praat's: four columns that are one measurement
# on four subjects. Two of them are drawn here, which is the smallest figure
# on which a right-hand axis is a coherent request and an incoherent figure.
selectObject: ltSubjects4Id

emlSeriesRole$ = "subjects"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "S2"
emlSecondAxisMin = 0
emlSecondAxisMax = 0
emlSecondAxisLabel$ = "S2"
emlSecondAxisStyle = 3
emlLineStyle = 1

@emlBeginPanel: 0, 0, 1
@emlDrawTimeSeries: ltSubjects4Id, "Same measurement, two subjects",
... "Time", "Value", 6, 4, "color", 1, "time", "S1", "", 0, 0, 0, 0
@ltEmit: "subjects_refused", string$ (emlSecondAxisRefused)
@ltEmit: "subjects_refusal_text", emlSecondAxisRefusal$
@emlAssertFullViewport
@ltEmit: "subjects_union", string$ (emlDrawnMinX) + " " + string$ (emlDrawnMaxX)
... + " " + string$ (emlDrawnMinY) + " " + string$ (emlDrawnMaxY)
if ltPng$ <> ""
    Save as 300-dpi PNG file: ltPng$
endif

# THE CONTROL. Same request, same table, same two columns; only the role
# changes. A gate that refused unconditionally would look identical on the
# leg above and different here.
Erase all
emlSeriesRole$ = "measurements"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "S2"
emlSecondAxisLabel$ = "S2"
@emlBeginPanel: 0, 0, 1
@emlDrawTimeSeries: ltSubjects4Id, "Different measurements, two columns",
... "Time", "Value", 6, 4, "color", 1, "time", "S1", "", 0, 0, 0, 0
@ltEmit: "measurements_refused", string$ (emlSecondAxisRefused)
@emlAssertFullViewport
if ltRefusePng$ <> ""
    Save as 300-dpi PNG file: ltRefusePng$
endif

@ltEmit: "leg_returned", "script_refuse"
if ltInfo$ <> ""
    writeFileLine: ltInfo$, info$ ()
endif
