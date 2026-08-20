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
@emlInitDrawingDefaults
@emlClearAnnotations
@emlRecordInit
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordBegin: ""
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
include /home/claude/repo/harness/runblock/cases/onlyrun2/fixture.praat
@emlRecordHeader: "Table box", 20, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- a box plot: grouping column and value column -------------
Erase all
@emlDrawBoxPlot: tableBox, "Box", "Group", "val", 6, 4, "color", 1,
... "grp", "val", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/onlyrun2/ORIG_step1.png"

# ---- RUN 2 -- a scatter: x column, y column, grouping column -----------
# xCol and yCol are roles run 1 never used. The ruling says they are still
# named for the run they belong to, so they come back as xCol2$ and yCol2$
# despite being the first of their role in the file.
@emlRecordNewRun
Erase all
@emlDrawScatterPlot: tableSc, "Scatter", "xx", "yy", 6, 4, "color", 1,
... "xx", "yy", "cohort", 0, 0, 0, 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/onlyrun2/ORIG_step2.png"
@emlRecordFlush: "/home/claude/repo/harness/runblock/out/onlyrun2/emitted.praat"
@emlRecordDiscard
