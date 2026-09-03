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
include /home/claude/repo/harness/runblock/cases/axisedit/fixture.praat
@emlRecordHeader: "Table ax1", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- typed axis 2 .. 30 ---------------------------------------
Erase all
@emlDrawBoxPlot: tableAx1, "Ax one", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 2, 30
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/axisedit/ORIG_step1.png"

# ---- RUN 2 -- the SAME typed axis literals, other data -----------------
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableAx2, "Ax two", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 2, 30
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/axisedit/ORIG_step2.png"
@emlRecordFlush: "/home/claude/repo/harness/runblock/out/axisedit/emitted.praat"
@emlRecordDiscard
# WHAT RUN 1 MUST COME BACK AS once its axisYMax is widened to 60. Drawn
# after the recording is discarded, so it is not a step.
Erase all
@emlDrawBoxPlot: tableAx1, "Ax one", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 2, 60
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/axisedit/REF_wide.png"
