@emlRecordHeader: "Table sa", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- draw, then save as PNG only ------------------------------
Erase all
@emlDrawBoxPlot: tableSa, "A", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "@@D@@/saved1" + """" + newline$
... + "@emlSavePanel: 1, ""figA_20260817_120000"", outputFolder$, ""PNG""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."

# ---- RUN 2 -- draw, then save as PNG and PDF ---------------------------
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableSb, "B", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step3.png"

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "@@D@@/saved2" + """" + newline$
... + "@emlSavePanel: 1, ""figB_20260817_120000"", outputFolder$, ""PNG, PDF""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."
