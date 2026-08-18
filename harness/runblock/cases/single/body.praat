@emlRecordHeader: "Table vt", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- a draw and the save that belongs to it -------------------
# No @emlRecordNewRun anywhere: one pass. This body is driven twice, once
# against the working tree and once against a plugin built from HEAD, and
# the two blocks are compared.
Erase all
@emlDrawBoxPlot: tableVt, "Voice", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "@@D@@/ORIG_step1.png"

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "@@D@@/saved" + """" + newline$
... + "@emlSavePanel: 1, ""vt_20260817_120000"", outputFolder$, ""PNG, EPS""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."
