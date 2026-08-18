include /home/claude/EMLPraatTools/plugin/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-extract.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-output.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-result-writer.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-record.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-draw-procedures.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-analysis.praat
Text writing preferences: "UTF-8"
@emlInitDrawingDefaults
@emlClearAnnotations
@emlRecordInit
emlRecordPluginRoot$ = "/home/claude/EMLPraatTools/plugin"
@emlRecordBegin: ""
emlRecordPluginRoot$ = "/home/claude/EMLPraatTools/plugin"
@emlRecordLoadPhrases: "/home/claude/EMLPraatTools/plugin/data/eml-record-phrases.csv"
include /home/claude/EMLPraatTools/harness/runblock/cases/single/fixture.praat
@emlRecordHeader: "Table vt", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- a draw and the save that belongs to it -------------------
# No @emlRecordNewRun anywhere: one pass. This body is driven twice, once
# against the working tree and once against a plugin built from HEAD, and
# the two blocks are compared.
Erase all
@emlDrawBoxPlot: tableVt, "Voice", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/single/ORIG_step1.png"

@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "/home/claude/EMLPraatTools/harness/runblock/out/single/saved" + """" + newline$
... + "@emlSavePanel: 1, ""vt_20260817_120000"", outputFolder$, ""PNG, EPS""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."
@emlRecordFlush: "/home/claude/EMLPraatTools/harness/runblock/out/single/emitted.praat"
@emlRecordDiscard
