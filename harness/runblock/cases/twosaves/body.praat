@emlRecordHeader: "Table vt", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- one pass, and the user presses Save TWICE ----------------
# The post-draw dialog stays open, so one pass can hold two format answers.
# There is no second run to name the second one, so it takes the run number
# and a letter.
Erase all
@emlDrawBoxPlot: tableVt, "Voice", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "@@D@@/saved1" + """" + newline$
... + "@emlSavePanel: 1, ""figA_20260817_120000"", outputFolder$, ""PNG""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "@@D@@/saved2" + """" + newline$
... + "@emlSavePanel: 1, ""figB_20260817_120000"", outputFolder$, ""PNG, PDF""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."
