@emlRecordHeader: "Table ax1", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- typed axis 2 .. 30 ---------------------------------------
Erase all
@emlDrawBoxPlot: tableAx1, "Ax one", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 2, 30
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

# ---- RUN 2 -- the SAME typed axis literals, other data -----------------
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableAx2, "Ax two", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 2, 30
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step2.png"
