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
include /home/claude/EMLPraatTools/harness/runblock/cases/callsite/fixture.praat
@emlRecordHeader: "Table cityA", 24, 2, "17 August 2026, 00:00:00"

# THE BOUNDARY IS THE SHIPPED ONE, NOT THE DRIVER'S. Every other case marks
# its passes with @emlRecordNewRun, which stands in for what a form does.
# This case never calls it. It calls @emlHandleCommonFields -- the procedure
# every menu wrapper runs once per press of Run, INSIDE its own
# `repeat ... until allDone` loop -- twice in ONE script scope, which is
# exactly what a wrapper's `New` button does. If the boundary were not in
# that procedure, the two passes would come back as one run.
#
# The form variable @emlHandleCommonFields reads is set here because a form
# would have set it.
clear_Info_window = 0

# ---- The user presses Run ----------------------------------------------
@emlHandleCommonFields
Erase all
@emlDrawBoxPlot: tableA, "City A", "Site", "n", 6, 4, "color", 1,
... "site", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/callsite/ORIG_step1.png"

# ---- The user presses New and Run again, same scope, same loop ---------
@emlHandleCommonFields
Erase all
@emlDrawBoxPlot: tableB, "City B", "Ward", "n", 6, 4, "color", 1,
... "ward", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/callsite/ORIG_step2.png"
@emlRecordFlush: "/home/claude/EMLPraatTools/harness/runblock/out/callsite/emitted.praat"
@emlRecordDiscard
