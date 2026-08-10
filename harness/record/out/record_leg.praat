include /home/claude/EMLPraatTools/plugin/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-extract.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-output.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-result-writer.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-record.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-analysis.praat

; The emitted file will include the plugin from wherever it was recorded.
; Point that at THIS tree rather than at an installed copy, so the round trip
; compares this build against itself and not against whatever is installed.
@emlRecordInit
emlRecordPluginRoot$ = "/home/claude/EMLPraatTools/plugin"

@emlRecordBegin: "/home/claude/EMLPraatTools/harness/record/out"
emlRecordPluginRoot$ = "/home/claude/EMLPraatTools/plugin"
@emlRecordLoadPhrases: "/home/claude/EMLPraatTools/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "demo_3groups_input.csv", 45, 4, "roundtrip"

Read Table from comma-separated file: "/home/claude/EMLPraatTools/evidence/csv/demo_3groups_input.csv"
t = selected ("Table")

clearinfo
@emlRunAnovaAnalysis: t, "SPL_dB", "voice_type", 1
writeFileLine: "/home/claude/EMLPraatTools/harness/record/out/leg1_info.txt", info$ ()

@emlRecordFlush: "/home/claude/EMLPraatTools/harness/record/out/emitted.praat"
@emlRecordDiscard
