@emlRecordHeader: "Table box", 20, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- a box plot: grouping column and value column -------------
Erase all
@emlDrawBoxPlot: tableBox, "Box", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

# ---- RUN 2 -- a scatter: x column, y column, grouping column -----------
# xCol and yCol are roles run 1 never used. The ruling says they are still
# named for the run they belong to, so they come back as xCol2$ and yCol2$
# despite being the first of their role in the file.
@emlRecordNewRun
Erase all
@emlDrawScatterPlot: tableSc, "Scatter", "xx", "yy", 6, 4, "color", 1,
... "xx", "yy", "cohort", 0, 0, 0, 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step2.png"
