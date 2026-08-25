form: "op"
    word: "Mode", ""
    word: "Session", "X"
endform
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
@emlRecordInit
if mode$ = "begin"
    @emlRecordBegin: ""
    # NO emlRecordPluginRoot$ OVERRIDE HERE, unlike the other legs. What this
    # leg measures is precisely the value @emlRecordBegin resolved, and
    # whether it reaches the flush in another scope.
    @emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "Table vt", 40, 2, "SESSION_" + session$
elsif mode$ = "step"
    nocheck selectObject: "Table vt"
    @emlRecordSource: selected ("Table")
    @emlRecordStep: "analysis", "a recorded step", "", "; nothing", ""
elsif mode$ = "flush"
    @emlRecordFlush: "/home/claude/repo/harness/record/replay_out/meta_emitted.praat"
    appendInfoLine: "FLUSHED written=", emlRecordFlush.written
elsif mode$ = "flush2"
    @emlRecordFlush: "/home/claude/repo/harness/record/replay_out/meta_emitted2.praat"
    appendInfoLine: "FLUSHED2 written=", emlRecordFlush.written
elsif mode$ = "report"
    appendInfoLine: "ACTIVE=", emlRecordActive, " META=", emlRecordMetaId,
    ... " STAMP=", emlRecordStamp$
endif
