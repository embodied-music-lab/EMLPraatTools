@emlRecordHeader: "Table cityA", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- box plot of n by site, on cityA, axis AUTO ----------------
Erase all
@emlDrawBoxPlot: tableA, "City A", "Site", "n", 6, 4, "color", 1,
... "site", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

# ---- RUN 2 -- box plot of n by ward, on cityB, axis AUTO ----------------
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableB, "City B", "Ward", "n", 6, 4, "color", 1,
... "ward", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step2.png"
