Create Table with column names: "vt", 0, "grp val"
rngState = 20260814
row = 0
for g from 1 to 2
    for k from 1 to 20
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set numeric value: row, "val",
        ... 1 + g * 1.2 + (rngState / 2147483648 - 0.5) * 1.4
    endfor
endfor
writeInfoLine: "meta driver"

runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "begin", "A"
runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "step", ""

# The user removes the BUFFER from the Objects window. Measured behaviour: the
# recording silently ends, and the meta table is left behind.
nocheck selectObject: "Table emlRecordBuffer"
if numberOfSelected () = 1
    Remove
endif
select all
nMetaAfterKill = 0
for o from 1 to numberOfSelected ()
    if selected$ (o) = "Table emlRecordMeta"
        nMetaAfterKill = nMetaAfterKill + 1
    endif
endfor
appendInfoLine: "ORPHANMETA=", nMetaAfterKill
runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "report", ""

# A NEW SESSION STARTS WITH THE ORPHAN STILL THERE. This is the audit's
# sequence exactly, and it is the state that stamped a live session with a
# dead one's time.
runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "begin", "B"
select all
nMetaAfterBegin = 0
for o from 1 to numberOfSelected ()
    if selected$ (o) = "Table emlRecordMeta"
        nMetaAfterBegin = nMetaAfterBegin + 1
    endif
endfor
appendInfoLine: "METAAFTERBEGIN=", nMetaAfterBegin

# THE SECOND HALF OF THE DEFECT: a decoy meta from a session that is gone,
# planted so that a lookup by NAME can find it. The pairing is what has to
# refuse it — the sweep above cannot, because this one arrives after the live
# session started, which is exactly how the audit's user reached it (they
# deleted the wrong one of two identically named rows).
Create Table with column names: "emlRecordMeta", 0, "key value"
decoy = selected ("Table")
Append row
Set string value: 1, "key", "stamp"
Set string value: 1, "value", "SESSION_DEAD"
Append row
Set string value: 2, "key", "buffer"
Set string value: 2, "value", "999999"
Append row
Set string value: 3, "key", "input"
Set string value: 3, "value", "Table deadTable"

runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "step", ""
runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "flush", ""

# ---- THE AUDIT'S OWN SEQUENCE, TO THE END -------------------------------
# The user then deleted the LIVE meta, not the decoy — two rows with the same
# name, and they picked the wrong one. That leaves a session whose only
# reachable store belongs to a recording that is gone, and it is what stamped
# a live emission with a dead session's time. The sweep cannot help here: the
# decoy arrived after this session started.
runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "begin", "C"
Create Table with column names: "emlRecordMeta", 0, "key value"
Append row
Set string value: 1, "key", "stamp"
Set string value: 1, "value", "SESSION_DEAD2"
Append row
Set string value: 2, "key", "buffer"
Set string value: 2, "value", "999998"
Append row
Set string value: 3, "key", "input"
Set string value: 3, "value", "Table deadTable2"
decoy2 = selected ("Table")
# Remove every meta table EXCEPT this decoy: the live one this session made,
# and the earlier decoy, so the only store left names a recording that is
# gone. That is the state the audit's user was in, reached the way they
# reached it -- two rows with the same name, and they deleted the wrong one.
select all
nKill = 0
for o from 1 to numberOfSelected ()
    if selected$ (o) = "Table emlRecordMeta" and selected (o) <> decoy2
        nKill = nKill + 1
        killMeta[nKill] = selected (o)
    endif
endfor
for k from 1 to nKill
    nocheck removeObject: killMeta[k]
endfor
appendInfoLine: "METAKILLED=", nKill
runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "step", ""
runScript: "/home/claude/EMLPraatTools/harness/record/replay_out/meta_op.praat", "flush2", ""
