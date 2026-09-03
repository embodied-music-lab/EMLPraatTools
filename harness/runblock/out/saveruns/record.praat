include /home/claude/repo/plugin/stats/eml-core-utilities.praat
include /home/claude/repo/plugin/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin/stats/eml-extract.praat
include /home/claude/repo/plugin/stats/eml-output.praat
include /home/claude/repo/plugin/stats/eml-inferential.praat
include /home/claude/repo/plugin/stats/eml-result-writer.praat
include /home/claude/repo/plugin/stats/eml-record.praat
include /home/claude/repo/plugin/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin/graphs/eml-draw-procedures.praat
include /home/claude/repo/plugin/stats/eml-analysis.praat
Text writing preferences: "UTF-8"
@emlInitializeDrawingDefaults
@emlClearAnnotations
@emlRecordInit
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordBegin: ""
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
include /home/claude/repo/harness/runblock/cases/saveruns/fixture.praat
@emlRecordHeader: "Table sa", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- draw, then save as PNG only ------------------------------
Erase all
@emlDrawBoxPlot: tableSa, "A", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/saveruns/ORIG_step1.png"

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "/home/claude/repo/harness/runblock/out/saveruns/saved1" + """" + newline$
... + "@emlSavePanel: 1, ""figA_20260817_120000"", outputFolder$, ""PNG""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."

# ---- RUN 2 -- draw, then save as PNG and PDF ---------------------------
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableSb, "B", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/saveruns/ORIG_step3.png"

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "/home/claude/repo/harness/runblock/out/saveruns/saved2" + """" + newline$
... + "@emlSavePanel: 1, ""figB_20260817_120000"", outputFolder$, ""PNG, PDF""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."
@emlRecordFlush: "/home/claude/repo/harness/runblock/out/saveruns/emitted.praat"
@emlRecordDiscard
