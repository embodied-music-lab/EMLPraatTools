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
include /home/claude/repo/harness/runblock/cases/twotables/fixture.praat
@emlRecordHeader: "Table cityA", 24, 2, "17 August 2026, 00:00:00"

# ---- RUN 1 -- box plot of n by site, on cityA, axis AUTO ----------------
Erase all
@emlDrawBoxPlot: tableA, "City A", "Site", "n", 6, 4, "color", 1,
... "site", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/twotables/ORIG_step1.png"

# ---- RUN 2 -- box plot of n by ward, on cityB, axis AUTO ----------------
@emlRecordNewRun
Erase all
@emlDrawBoxPlot: tableB, "City B", "Ward", "n", 6, 4, "color", 1,
... "ward", "n", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/twotables/ORIG_step2.png"
@emlRecordFlush: "/home/claude/repo/harness/runblock/out/twotables/emitted.praat"
@emlRecordDiscard
