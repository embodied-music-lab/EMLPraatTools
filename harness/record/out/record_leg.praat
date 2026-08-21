include /home/claude/repo/plugin/stats/eml-core-utilities.praat
include /home/claude/repo/plugin/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin/stats/eml-extract.praat
include /home/claude/repo/plugin/stats/eml-output.praat
include /home/claude/repo/plugin/stats/eml-inferential.praat
include /home/claude/repo/plugin/stats/eml-result-writer.praat
include /home/claude/repo/plugin/stats/eml-record.praat
include /home/claude/repo/plugin/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin/stats/eml-analysis.praat

; The emitted file will include the plugin from wherever it was recorded.
; Point that at THIS tree rather than at an installed copy, so the round trip
; compares this build against itself and not against whatever is installed.
@emlRecordInit
emlRecordPluginRoot$ = "/home/claude/repo/plugin"

@emlRecordBegin: "/home/claude/repo/harness/record/out"
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "demo_3groups_input.csv", 45, 4, "roundtrip"

Read Table from comma-separated file: "/home/claude/repo/evidence/csv/demo_3groups_input.csv"
t = selected ("Table")

clearinfo
@emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", 1
writeFileLine: "/home/claude/repo/harness/record/out/leg1_info.txt", info$ ()

@emlRecordFlush: "/home/claude/repo/harness/record/out/emitted.praat"
@emlRecordDiscard
