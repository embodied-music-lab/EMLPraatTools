@emlRecordHeader: "Table cityA", 24, 2, "17 August 2026, 00:00:00"

# THE BOUNDARY IS THE SHIPPED ONE, NOT THE DRIVER'S. Every other case marks
# its passes with @emlRecordNewRun, which stands in for what a form does.
# This case never calls it. It calls @emlHandleCommonFields -- the procedure
# every menu wrapper runs once per press of Run, INSIDE its own
# `repeat ... until allDone` loop -- twice in ONE script scope, which is
# exactly what a wrapper's `New` button does. If the boundary were not in
# that procedure, the two passes would come back as one run.
#
# The form variable @emlHandleCommonFields reads is set here because a form
# would have set it.
clear_Info_window = 0

# ---- The user presses Run ----------------------------------------------
@emlHandleCommonFields
Erase all
@emlDrawBoxPlot: tableA, "City A", "Site", "n", 6, 4, "color", 1,
... "site", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

# ---- The user presses New and Run again, same scope, same loop ---------
@emlHandleCommonFields
Erase all
@emlDrawBoxPlot: tableB, "City B", "Ward", "n", 6, 4, "color", 1,
... "ward", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step2.png"
