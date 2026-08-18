@emlRecordHeader: "Table t1", 20, 2, "17 August 2026, 00:00:00"

Erase all
@emlDrawBoxPlot: t1, "One", "Site", "n", 6, 4, "color", 1, "site", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

@emlRecordNewRun
Erase all
@emlDrawBoxPlot: t2, "Two", "Ward", "n", 6, 4, "color", 1, "ward", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step2.png"

# Run 3 types its axis rather than leaving it on auto, so the third pair is
# a typed pair and the third suffix has to be 3 whatever the first two were.
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: t3, "Three", "Block", "n", 6, 4, "color", 1,
... "block", "n", 2, 30
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step3.png"
