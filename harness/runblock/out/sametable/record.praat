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
include /home/claude/EMLPraatTools/harness/runblock/cases/sametable/fixture.praat
@emlRecordHeader: "Table one", 24, 3, "17 August 2026, 00:00:00"

# ---- RUN 1 -- val, on "one" -------------------------------------------
Erase all
@emlDrawBoxPlot: tableOne, "First", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/sametable/ORIG_step1.png"

# ---- RUN 2 -- other, on the SAME table ---------------------------------
# Two runs on one table are two decisions, so they get data1$ and data2$
# both reading "Table one". Editing data2$ has to move run 2 and nothing
# else -- that is what the retarget leg drives.
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableOne, "Second", "Group", "other", 6, 4, "color", 1,
... "grp", "other", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/sametable/ORIG_step2.png"
@emlRecordFlush: "/home/claude/EMLPraatTools/harness/runblock/out/sametable/emitted.praat"
@emlRecordDiscard
# WHAT RUN 2 MUST COME BACK AS once data2$ is pointed at the twin. Drawn
# after the recording is discarded, so it is not a step -- it is the answer
# the edited block is checked against.
Erase all
@emlDrawBoxPlot: tableTwin, "Second", "Group", "other", 6, 4, "color", 1,
... "grp", "other", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/sametable/REF_twin.png"
