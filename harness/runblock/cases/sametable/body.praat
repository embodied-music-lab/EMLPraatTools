@emlRecordHeader: "Table one", 24, 3, "17 August 2026, 00:00:00"

# ---- RUN 1 -- val, on "one" -------------------------------------------
Erase all
@emlDrawBoxPlot: tableOne, "First", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

# ---- RUN 2 -- other, on the SAME table ---------------------------------
# Two runs on one table are two decisions, so they get data1$ and data2$
# both reading "Table one". Editing data2$ has to move run 2 and nothing
# else -- that is what the retarget leg drives.
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableOne, "Second", "Group", "other", 6, 4, "color", 1,
... "grp", "other", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step2.png"
