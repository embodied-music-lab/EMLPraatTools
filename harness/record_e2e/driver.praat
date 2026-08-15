# ---------------------------------------------------------------------------
# RECORD END TO END — the recorder driven the way a user drives it.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS EXISTS TO CATCH, and it is the §2h shape again. Every earlier test
# of the recorder started a recording and added steps IN THE SAME SCRIPT
# SCOPE. A menu command does not work that way: it ends and takes every
# variable with it, and the next command starts with nothing. Re-attaching to
# the buffer across that boundary is the entire design of the feature, and
# nothing had ever crossed it.
#
# `runScript:` gives a script its own variable scope inside one Praat process
# and shares the Objects window — the menu model exactly, and without needing
# a display.
#
# IT ALSO MEASURES COVERAGE, which is the finding that prompted it. The
# recorder's infrastructure is complete; the number of operations that CALL it
# is not. Every operation below is driven, and the artefact records for each
# one whether a step actually appeared in the buffer. A user who switches
# recording on and runs an operation that captures nothing gets an empty
# script and no warning, so the count is written down rather than assumed.
#
# Output: one line per operation to stdout, read by run.sh.
# ---------------------------------------------------------------------------
include ../../plugin/scripts/eml-lib.praat

include fixture.praat

# --- click: Start recording script -----------------------------------------
runScript: "../../plugin/scripts/eml-record-start.praat"

nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
started = numberOfSelected ()
appendInfoLine: "RECSTART buffer=", started

before = 0
for k from 1 to nOps
    # THE STEP COUNT BEFORE AND AFTER, so "did this operation record" is
    # measured rather than inferred from the operation's name.
    nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
    if numberOfSelected () = 1
        before = Get number of rows
    else
        before = -1
    endif

    # Each operation in its OWN scope, as a menu command would be.
    #
    # `nocheck` is deliberate -- an operation that refuses on this fixture
    # must not abort the sweep -- but it MUST NOT be allowed to disguise a
    # crash as a quiet success. The first version had no completion marker,
    # so ten scripts that never ran at all were reported as ten operations
    # that ran and recorded nothing, and the coverage number was fiction.
    # op.praat prints OPDONE as its last line; run.sh pairs it with this one.
    nocheck runScript: "op.praat", op$[k]

    after = -1
    nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
    if numberOfSelected () = 1
        after = Get number of rows
    endif
    appendInfoLine: "OP name=", op$[k], " k=", k, " nOps=", nOps, " before=", before, " after=", after
endfor

# --- the buffer survived every one of them ---------------------------------
nocheck selectObject: "Table emlRecording_DO_NOT_REMOVE"
survived = numberOfSelected ()
total = -1
if survived = 1
    total = Get number of rows
endif
appendInfoLine: "RECEND buffer=", survived, " steps=", total

# --- render, so the emitted file can be parse-checked -----------------------
outPath$ = environment$ ("EML_RECORD_OUT")
if outPath$ = ""
    outPath$ = "out/recorded.praat"
endif
@emlRecordFlush: outPath$
appendInfoLine: "FLUSH written=", emlRecordFlush.written, " path=", outPath$
