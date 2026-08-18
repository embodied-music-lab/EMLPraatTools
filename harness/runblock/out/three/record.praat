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
include /home/claude/EMLPraatTools/harness/runblock/cases/three/fixture.praat
@emlRecordHeader: "Table t1", 20, 2, "17 August 2026, 00:00:00"

Erase all
@emlDrawBoxPlot: t1, "One", "Site", "n", 6, 4, "color", 1, "site", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/three/ORIG_step1.png"

@emlRecordNewRun
Erase all
@emlDrawBoxPlot: t2, "Two", "Ward", "n", 6, 4, "color", 1, "ward", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/three/ORIG_step2.png"

# Run 3 types its axis rather than leaving it on auto, so the third pair is
# a typed pair and the third suffix has to be 3 whatever the first two were.
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: t3, "Three", "Block", "n", 6, 4, "color", 1,
... "block", "n", 2, 30
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/three/ORIG_step3.png"
@emlRecordFlush: "/home/claude/EMLPraatTools/harness/runblock/out/three/emitted.praat"
@emlRecordDiscard
