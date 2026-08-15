# ============================================================================
# EML Praat Tools — Record workflow: buffer, phrases, renderer
# ============================================================================
# Purpose: accumulate every analysis and drawing step of a session and write
#          it out as a single annotated Praat script — one artifact that both
#          re-runs and reads like a lab notebook.
#
# Date: 9 August 2026
# Version: 1.0
#
# THIS FILE IS THE FOUNDATION ONLY. It is the buffer, the phrase table, the
# renderer and the flush. It deliberately does NOT touch a
# single wrapper: nothing here calls an orchestrator and no orchestrator yet
# calls anything here. That is the next increment, and it is separated on
# purpose, because everything in this file is testable headless and nothing
# about wiring a wrapper is.
#
# WHAT THE PROPOSAL SAID THAT TURNED OUT NOT TO BE TRUE
#
# The proposal (TREATMENT_record_workflow.md, 8 Aug 2026) devoted §8.6 to an
# ASCII sanitizer: every string folded on entry, a mapping table of known
# offenders, a final scan for bytes above 127 substituting "?", and a warning
# line written into the log at that position. The stated reason was that a
# single non-ASCII character makes Praat write a file as UTF-16 big-endian
# rather than ASCII, and that the recorder would therefore silently change
# the encoding of the emitted script.
#
# The premise is TRUE. The conclusion is still wrong, and the difference
# matters, so both are recorded rather than the tidier half.
#
#   1. PRAAT REALLY DOES WRITE UTF-16BE. prefs5 carries
#          TextEncoding.outputEncoding: try ASCII, then UTF-16
#      so any report containing a box rule is written UTF-16 big-endian on
#      every installation that has ever saved preferences. An early test here
#      found UTF-8 and I reported the premise as false; that test ran in a
#      sandbox with no prefs5, where a compiled-in default applied. It was
#      measuring a machine no user has. Corrected 10 Aug 2026, after the
#      round-trip harness went from five green runs to a hard failure the
#      moment a prefs file existed.
#
#   2. IT DOES NOT MATTER, WHICH IS THE AUTHOR'S POINT AND THE REAL REASON.
#      Praat reads back what it writes. A UTF-16 script is a perfectly good
#      Praat script, verified by running one. The encoding belongs to the
#      layer that owns encoding, and a recorder that forced ASCII would be
#      overriding a correct decision to protect against a consequence that
#      does not exist.
#
#   3. AND THE PROPOSED FIX WAS NOT ONE ANYWAY.
#      unicodeToBackslashTrigraphs$() is not exhaustive. It converts the
#      characters Praat has trigraphs for and passes the rest through
#      untouched. Measured:
#          \o:  3 -> 1  converted      \em  3 -> 3  no such trigraph
#          \-m  3 -> 1  converted      \>=  3 -> 3  no such trigraph
#      A round-trip test on an unrecognised trigraph reports "lossless" while
#      converting nothing, which is how that claim passed review the first
#      time. It did not survive being asked whether conversion had HAPPENED.
#
# WHAT THIS DOES COST, and it is not the emitted script. Byte-oriented tools
# downstream -- sed, grep, diff -- cannot read a UTF-16 capture with an ASCII
# pattern. harness/record/roundtrip.sh folds both captures to UTF-8 before
# comparing, so it tests content and leaves encoding to Praat.
#
# So there is no @emlLogAscii here, no mapping table, no "?" fallback, and no
# pure-ASCII assertion in the validator. Forcing ASCII would be strictly
# worse than not: it would hand the user their own group labels back mangled,
# in a file whose whole purpose is to be publishable.
#
# WHAT IS KEPT FROM §8.6, AND WHY. Stream A carries Info-formatted strings
# into a file that is read as a script rather than as a report. The box rules
# and arrows in that text are decoration and belong in comments. The renderer
# below guarantees they land there — see @emlRecordRender — so that no reader
# later mistakes a rule character inside an executable line for something the
# recorder put there on purpose.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================


# ============================================================================
# STATE
# ============================================================================
# emlRecordActive     0 = off, 1 = recording
# emlRecordBufferId   Table: one row per step. Columns:
#                       n kind intent caveat code env post result api
#                       derived source
#                     `env` and `post` are the settings a step was drawn
#                     under and what the graphs form drew after it -- both
#                     readable only in the recording scope, so both are
#                     captured there. See @emlRecordCaptureEnv.
# emlRecordPluginRoot$ absolute plugin root, for the include block
# emlRecordPhraseId   Table: the shipped phrase registry
# emlRecordN          steps recorded so far
# emlRecordTempPath$  crash mirror, appended per row
# ============================================================================


; ---------------------------------------------------------------------------
; PRESENT, WHICH IS NOT THE SAME AS RUNNING. Set at LOAD time, so any caller
; can tell "the recorder is loaded" from "the recorder has been initialised".
;
; The draw layer used to test variableExists ("emlRecordActive") to mean both,
; and that was true only while a recording lived inside one script scope. A
; menu command runs in a FRESH scope: emlRecordActive does not exist yet even
; though a recording is in progress, so the guard was false and every figure
; drawn from the menu went unrecorded. Found 12 Aug 2026 by driving ten
; operations through runScript: -- the assembly, not the parts. The ANOVA hook
; escaped it only because it calls @emlRecordInit before testing anything.
;
; A caller with no recorder loaded -- a PraatGen companion file, a direct call
; into the draw library -- has no such variable, and the guarded call is never
; executed, which is what keeps the draw layer free of the recorder.
emlRecordLoaded = 1

# ----------------------------------------------------------------------------
# @emlRecordInit
# Idempotent. Establishes the globals with no side effects, so any procedure
# here can be called defensively without knowing whether recording ever
# started. Mirrors @emlInitDrawingDefaults in shape and intent.
# ----------------------------------------------------------------------------
procedure emlRecordInit
    if not variableExists ("emlRecordActive")
        emlRecordActive = 0
    endif
    if not variableExists ("emlRecordBufferId")
        emlRecordBufferId = 0
    endif
    if not variableExists ("emlRecordCurrentSource$")
        emlRecordCurrentSource$ = ""
    endif
    if not variableExists ("emlRecordAmbiguousName")
        emlRecordAmbiguousName = 0
    endif
    if not variableExists ("emlRecordMetaId")
        emlRecordMetaId = 0
    endif
    ; THE AUTO-CONVERTED INTERMEDIATE, and why this is script-scope state and
    ; not a row in the meta object. @emlGraphsWorkflow converts and draws in
    ; ONE menu invocation -- the Sound becomes a Pitch, the contour is drawn,
    ; the Pitch is removed -- so the pairing never crosses a script boundary.
    ; Persisting it would let a stale id from an earlier command silently
    ; claim the next draw.
    if not variableExists ("emlRecordDerivedId")
        emlRecordDerivedId = 0
    endif
    if not variableExists ("emlRecordDerivedFrom$")
        emlRecordDerivedFrom$ = ""
    endif
    if not variableExists ("emlRecordStepDerived$")
        emlRecordStepDerived$ = ""
    endif

    ; ------------------------------------------------------------------
    ; RE-ATTACH TO A RECORDING LEFT BY AN EARLIER MENU INVOCATION.
    ;
    ; This is what makes a recording span more than one menu command, and
    ; it works because of a fact about Praat rather than a trick: a script
    ; run from a menu ends and takes ALL its variables with it, but the
    ; OBJECTS it created stay in the Objects window, which belongs to the
    ; running Praat instance. emlRecordActive and emlRecordBufferId are
    ; gone by the time the next analysis starts. The buffer Table is not.
    ;
    ; So the buffer's EXISTENCE is the state. There is no flag file and no
    ; config key, which means there is nothing that can disagree with the
    ; data -- the switch and the buffer are the same object.
    ;
    ; `nocheck selectObject:` by name leaves nothing selected and raises no
    ; error when the object is absent, which is exactly the test wanted.
    ; Measured 12 Aug 2026 on 6.6.30.
    ;
    ; ONLY when this script has not already found it: a wrapper that called
    ; @emlRecordBegin in this same run must not have its id replaced.
    ; ------------------------------------------------------------------
    if emlRecordBufferId = 0
        nocheck selectObject: "Table emlRecordBuffer"
        if numberOfSelected () = 1
            emlRecordBufferId = selected ("Table")
            emlRecordActive = 1
            .nSoFar = Get number of rows
            emlRecordN = .nSoFar
        endif
    endif

    ; ------------------------------------------------------------------
    ; THE SESSION'S METADATA IS AN OBJECT TOO, FOR EXACTLY THE SAME REASON.
    ;
    ; The buffer re-attaches above and the steps survive. Everything ABOUT
    ; the session did not: emlRecordStamp$, emlRecordHeaderInput$ and its
    ; shape are ordinary script variables, so a recording made the way a
    ; user makes one -- one menu command per operation -- reached flush with
    ; every one of them at its default. Measured 12 Aug 2026: a 23-step
    ; recording emitted an empty timestamp and the header block
    ;
    ;     # NOT RECORDED. Nothing in this session named the object it
    ;     # ran on ...
    ;
    ; while the manifest three lines below it named "Table voiceA". The file
    ; contradicted itself, and every test passed because every test recorded
    ; in ONE scope.
    ;
    ; So the same fix as the buffer: a second Table, re-attached by name, and
    ; the globals HYDRATED from it below once their defaults are in place. A
    ; field added later needs no new plumbing -- it is a row.
    ; ------------------------------------------------------------------
    ; PAIRED TO THE BUFFER BY ID, NOT FOUND BY NAME (NEW-G11-3, 14 Aug 2026).
    ;
    ; The re-attach used to be `nocheck selectObject: "Table emlRecordMeta"`
    ; and take whatever came back. That is sound while exactly one meta table
    ; exists, and the audit found the state where two do: a user deletes the
    ; BUFFER from the Objects window mid-recording -- which silently ends the
    ; recording -- and the meta table is left behind, orphaned. The next
    ; recording creates its own pair, and now two objects answer to the same
    ; name. Praat resolves that ambiguity on its own terms and the audit
    ; measured it resolving to the DEAD one: a live session emitted a script
    ; stamped with a session that had been thrown away three minutes earlier.
    ; Every step emitted correctly, so nothing looked wrong; only the
    ; provenance lied, which is the half of the file a reader trusts most.
    ;
    ; The fix is to stop asking by name at all. @emlRecordBegin writes the
    ; buffer's own id into the meta under "buffer", so the pair is stated
    ; rather than inferred, and the search below accepts only the meta whose
    ; stated buffer IS the live buffer. A meta that names no buffer, or names
    ; a dead one, is an orphan and is left alone -- hydrating from it is
    ; exactly the defect.
    ;
    ; NO BUFFER MEANS NO META. Before a recording starts, and after one is
    ; discarded, emlRecordBufferId is 0 and nothing can match -- which is
    ; correct, and is what keeps a stale meta from furnishing a session that
    ; has not begun.
    ;
    ; THE SELECTION IS PUT BACK. `select all` is how a name is enumerated in
    ; Praat, and this procedure is called at the top of thirteen orchestrators
    ; and sixteen draw procedures, several of which have a live selection at
    ; that moment. The old one-line re-attach also disturbed it -- and the
    ; wider sweep here would disturb it differently, which is the kind of
    ; change that shows up two files away.
    if emlRecordMetaId = 0 and emlRecordBufferId > 0
        .nSel0 = numberOfSelected ()
        for .i from 1 to .nSel0
            .sel0[.i] = selected (.i)
        endfor
        select all
        .nAll = numberOfSelected ()
        for .o from 1 to .nAll
            .cand$[.o] = selected$ (.o)
            .candId[.o] = selected (.o)
        endfor
        for .o from 1 to .nAll
            if .cand$[.o] = "Table emlRecordMeta" and emlRecordMetaId = 0
                ; Read the candidate's own claim through the ordinary getter,
                ; which works from emlRecordMetaId -- so it is pointed at the
                ; candidate, asked, and pointed back to 0 if the answer is
                ; wrong.
                emlRecordMetaId = .candId[.o]
                @emlRecordMetaGet: "buffer"
                if emlRecordMetaGet.found = 0
                ... or emlRecordMetaGet.result$ <> string$ (emlRecordBufferId)
                    emlRecordMetaId = 0
                endif
            endif
        endfor
        if .nSel0 > 0
            selectObject: .sel0[1]
            for .i from 2 to .nSel0
                plusObject: .sel0[.i]
            endfor
        else
            ; Nothing was selected on entry, so nothing is selected on exit.
            ; `nocheck selectObject:` on an absent name is the documented way
            ; to deselect everything -- see the note above the buffer search.
            nocheck selectObject: "Table emlRecordNothingSelected"
        endif

        ; A LIVE BUFFER WITH NO META OF ITS OWN GETS ONE, AND SAYS SO.
        ;
        ; Refusing the unpaired meta above is the correct half; leaving the
        ; session with no store at all is not, because @emlRecordMetaSet is a
        ; no-op without one and every later step would silently fail to
        ; record its provenance. This is the state a user reaches by deleting
        ; the meta table out of the Objects window -- which the audit did,
        ; picking the wrong of two identically named rows.
        ;
        ; So a replacement is made, paired, and STAMPED HONESTLY: the time is
        ; now, not the session's start, because the session's start is the
        ; thing that was lost. The renderer says as much on the header line
        ; rather than quietly presenting a recovered stamp as an original.
        if emlRecordMetaId = 0
            .nSel1 = numberOfSelected ()
            for .i from 1 to .nSel1
                .sel1[.i] = selected (.i)
            endfor
            Create Table with column names: "emlRecordMeta", 0, "key value"
            emlRecordMetaId = selected ("Table")
            @emlRecordMetaSet: "buffer", string$ (emlRecordBufferId)
            @emlRecordMetaSet: "stamp", date$ ()
            @emlRecordMetaSet: "stampRecovered", "1"
            if .nSel1 > 0
                nocheck selectObject: .sel1[1]
                for .i from 2 to .nSel1
                    nocheck plusObject: .sel1[.i]
                endfor
            else
                nocheck selectObject: "Table emlRecordNothingSelected"
            endif
        endif
    endif

    ; THE PLUGIN ROOT COMES FROM THE META OBJECT, AND BEFORE THE DEFAULT
    ; (NEW-G11-1, 14 Aug 2026).
    ;
    ; @emlRecordBegin resolves this once and rewrites it home-relative where
    ; it can. That resolution then died with the scope that made it: a menu
    ; command runs in a fresh scope, this line re-defaulted to the ABSOLUTE
    ; preferencesDirectory$ path, and the flush that eventually wrote the file
    ; wrote absolute includes under a header claiming they were home-relative.
    ; The file said one thing and did another, and it could never have said
    ; otherwise in real menu-driven use -- only the single-scope tests saw the
    ; tilde. So the resolved value goes into the meta object with everything
    ; else that has to outlive a scope, and is read back HERE, ahead of the
    ; default, rather than in the hydrate block below.
    ;
    ; AHEAD OF THE DEFAULT AND NOT AFTER IT, deliberately. The hydrate block
    ; overwrites unconditionally, which is right for provenance -- the object
    ; knows more than a fresh scope's blank. It is wrong here, because a
    ; caller that sets this variable itself after starting a recording (every
    ; roundtrip harness in this tree does, to point the emitted file at the
    ; working copy rather than at the installed plugin) would have its value
    ; taken away again by the next @emlRecordInit.
    if not variableExists ("emlRecordPluginRoot$")
        emlRecordPluginRoot$ = ""
        if emlRecordMetaId > 0
            @emlRecordMetaGet: "pluginRoot"
            if emlRecordMetaGet.found = 1
                emlRecordPluginRoot$ = emlRecordMetaGet.result$
            endif
        endif
        if emlRecordPluginRoot$ = ""
            emlRecordPluginRoot$ = preferencesDirectory$
            ... + "/plugin_EML_Praat_Tools"
        endif
    endif
    if not variableExists ("emlRecordPhraseId")
        emlRecordPhraseId = 0
    endif
    if not variableExists ("emlRecordN")
        emlRecordN = 0
    endif
    if not variableExists ("emlRecordTempPath$")
        emlRecordTempPath$ = ""
    endif
    if not variableExists ("emlRecordHeaderInput$")
        emlRecordHeaderInput$ = ""
    endif
    if not variableExists ("emlRecordHeaderRows")
        emlRecordHeaderRows = 0
    endif
    if not variableExists ("emlRecordHeaderCols")
        emlRecordHeaderCols = 0
    endif
    ; The shape as a READY SENTENCE rather than two numbers, because not every
    ; object the plugin draws has one -- a Sound, a Pitch, a Spectrum and an
    ; Ltas do not answer "Get number of rows". Empty means "this object type
    ; has no row/column shape to report", which the renderer prints as nothing
    ; rather than as "0 rows, 0 columns". See @emlRecordSource.
    if not variableExists ("emlRecordHeaderShape$")
        emlRecordHeaderShape$ = ""
    endif
    if not variableExists ("emlRecordStamp$")
        emlRecordStamp$ = ""
    endif
    if not variableExists ("emlRecordSourceChanged")
        emlRecordSourceChanged = 0
    endif
    if not variableExists ("emlRecordPraatVersion$")
        emlRecordPraatVersion$ = praatVersion$
    endif
    if not variableExists ("emlRecordPraatVersion")
        emlRecordPraatVersion = praatVersion
    endif

    ; ---- HYDRATE FROM THE META OBJECT --------------------------------
    ; After the defaults, never before: a field the session never set stays
    ; at its default rather than becoming an empty string that overwrote it.
    ; A stored value always wins, because the object outlives every scope
    ; and a fresh scope's default is by definition the thing that knows less.
    if emlRecordMetaId > 0
        @emlRecordMetaGet: "stamp"
        if emlRecordMetaGet.found = 1
            emlRecordStamp$ = emlRecordMetaGet.result$
        endif
        @emlRecordMetaGet: "input"
        if emlRecordMetaGet.found = 1
            emlRecordHeaderInput$ = emlRecordMetaGet.result$
        endif
        @emlRecordMetaGet: "shape"
        if emlRecordMetaGet.found = 1
            emlRecordHeaderShape$ = emlRecordMetaGet.result$
        endif
        @emlRecordMetaGet: "rows"
        if emlRecordMetaGet.found = 1
            emlRecordHeaderRows = number (emlRecordMetaGet.result$)
        endif
        @emlRecordMetaGet: "cols"
        if emlRecordMetaGet.found = 1
            emlRecordHeaderCols = number (emlRecordMetaGet.result$)
        endif
        @emlRecordMetaGet: "sourceChanged"
        if emlRecordMetaGet.found = 1
            emlRecordSourceChanged = number (emlRecordMetaGet.result$)
        endif
        @emlRecordMetaGet: "tempPath"
        if emlRecordMetaGet.found = 1
            emlRecordTempPath$ = emlRecordMetaGet.result$
        endif
        emlRecordStampRecovered = 0
        @emlRecordMetaGet: "stampRecovered"
        if emlRecordMetaGet.found = 1
            emlRecordStampRecovered = number (emlRecordMetaGet.result$)
        endif
    endif
    if not variableExists ("emlRecordStampRecovered")
        emlRecordStampRecovered = 0
    endif
    ; ------------------------------------------------------------------
    ; THE PHRASE TABLE, WHICH IS AN OBJECT TOO, AND WAS NEVER LOADED.
    ;
    ; Until 12 Aug 2026 the ONLY callers of @emlRecordLoadPhrases anywhere
    ; were two phase1 tests. Nothing in the shipped plugin loaded it, so
    ; every recording a user could actually make emitted
    ;
    ;     # [MISSING PHRASE: anova.intent]
    ;
    ; on every step. The tests passed because they loaded it themselves.
    ; Found by harness/record_e2e -- the assembly, not the parts.
    ;
    ; It re-attaches exactly like the buffer, and for the same reason: it is
    ; a Table in the Objects window, so it outlives the scope that read it
    ; and one read serves the whole session.
    ;
    ; `../data/...` resolves against the folder of the script that was RUN,
    ; which is plugin/scripts for every wrapper -- true of an installed
    ; plugin and of this repository alike, so one path serves both.
    if emlRecordActive = 1 and emlRecordPhraseId = 0
        nocheck selectObject: "Table eml-record-phrases"
        if numberOfSelected () = 1
            emlRecordPhraseId = selected ("Table")
        else
            .phrases$ = "../data/eml-record-phrases.csv"
            if variableExists ("emlRecordPhrasePath$")
                if emlRecordPhrasePath$ <> ""
                    .phrases$ = emlRecordPhrasePath$
                endif
            endif
            if fileReadable (.phrases$)
                Read Table from comma-separated file: .phrases$
                emlRecordPhraseId = selected ("Table")
            endif
        endif
    endif
endproc


# ----------------------------------------------------------------------------
# @emlRecordBegin: .tempFolder$
# Start a recording. Creates the buffer and the path registry.
#
# Starting a recording while one is already running is, per the proposal §8.8,
# "a question the UI has to answer rather than silently resolve". This
# procedure is not the UI: it REFUSES, so that no caller can discard a
# session's buffer by accident. The UI asks, then calls @emlRecordDiscard or
# @emlRecordFlush first.
#
# Arguments:
#   .tempFolder$ — where the crash mirror is written. "" disables the mirror.
# Outputs:
#   .started  — 1 if a recording began, 0 if one was already running
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# @emlRecordMetaGet: .key$   ->  .result$, .found
# @emlRecordMetaSet: .key$, .value$
#
# The session's key/value store, held in a Table so that it outlives the
# script scope that wrote it -- see the note in @emlRecordInit. A key/value
# TABLE rather than one column per field on the buffer: the buffer's schema is
# per-STEP and these are per-SESSION, and putting them there would repeat
# every value on every row and invite the two to disagree.
#
# NEITHER CALLS @emlRecordInit. Init calls Get to hydrate, so a call back into
# it here is a loop; both work from emlRecordMetaId directly and do nothing at
# all when there is no meta object, which is the state before a recording
# starts and after one is discarded.
#
# .found IS SEPARATE FROM .result$ because an empty string is a legitimate
# stored value -- "this session set no stamp" and "this session has never been
# asked" are different facts, and only the second may be overwritten by a
# default.
# ----------------------------------------------------------------------------
procedure emlRecordMetaGet: .key$
    .result$ = ""
    .found = 0
    if not variableExists ("emlRecordMetaId")
        emlRecordMetaId = 0
    endif
    ; THE AUTO-CONVERTED INTERMEDIATE, and why this is script-scope state and
    ; not a row in the meta object. @emlGraphsWorkflow converts and draws in
    ; ONE menu invocation -- the Sound becomes a Pitch, the contour is drawn,
    ; the Pitch is removed -- so the pairing never crosses a script boundary.
    ; Persisting it would let a stale id from an earlier command silently
    ; claim the next draw.
    if not variableExists ("emlRecordDerivedId")
        emlRecordDerivedId = 0
    endif
    if not variableExists ("emlRecordDerivedFrom$")
        emlRecordDerivedFrom$ = ""
    endif
    if not variableExists ("emlRecordStepDerived$")
        emlRecordStepDerived$ = ""
    endif
    if emlRecordMetaId = 0
        goto END_RECORD_META_GET
    endif
    selectObject: emlRecordMetaId
    .n = Get number of rows
    for .i from 1 to .n
        selectObject: emlRecordMetaId
        .k$ = Get value: .i, "key"
        if .k$ = .key$
            .result$ = Get value: .i, "value"
            .found = 1
        endif
    endfor
    label END_RECORD_META_GET
endproc


procedure emlRecordMetaSet: .key$, .value$
    if not variableExists ("emlRecordMetaId")
        emlRecordMetaId = 0
    endif
    ; THE AUTO-CONVERTED INTERMEDIATE, and why this is script-scope state and
    ; not a row in the meta object. @emlGraphsWorkflow converts and draws in
    ; ONE menu invocation -- the Sound becomes a Pitch, the contour is drawn,
    ; the Pitch is removed -- so the pairing never crosses a script boundary.
    ; Persisting it would let a stale id from an earlier command silently
    ; claim the next draw.
    if not variableExists ("emlRecordDerivedId")
        emlRecordDerivedId = 0
    endif
    if not variableExists ("emlRecordDerivedFrom$")
        emlRecordDerivedFrom$ = ""
    endif
    if not variableExists ("emlRecordStepDerived$")
        emlRecordStepDerived$ = ""
    endif
    if emlRecordMetaId = 0
        goto END_RECORD_META_SET
    endif
    selectObject: emlRecordMetaId
    .n = Get number of rows
    .row = 0
    for .i from 1 to .n
        selectObject: emlRecordMetaId
        .k$ = Get value: .i, "key"
        if .k$ = .key$
            .row = .i
        endif
    endfor
    selectObject: emlRecordMetaId
    if .row = 0
        Append row
        .row = Get number of rows
        Set string value: .row, "key", .key$
    endif
    Set string value: .row, "value", .value$
    label END_RECORD_META_SET
endproc


# ----------------------------------------------------------------------------
# @emlRecordSweepOrphans   ->  .removed
# @emlRecordOrphanCheck    ->  .orphan
#
# THE TWO HALVES OF ONE MEASURED FACT (audit §6, 14 Aug 2026): removing the
# buffer from the Objects window silently stops the recording. Later analyses
# simply never appear in the script, with no signal anywhere.
#
# That is not a defect this file can fix on its own -- the buffer's EXISTENCE
# is deliberately the state, and nothing in Praat notifies a script that an
# object was removed. What it CAN do is stop the orphan being invisible and
# stop it being inherited:
#
#   SweepOrphans removes any meta table with no live buffer. Called from
#   @emlRecordBegin, where no recording is running by definition, so every
#   meta present is by definition dead.
#
#   OrphanCheck answers "did a recording end this way?" without changing
#   anything, so the two Stop commands can say WHY there is nothing to save
#   instead of the bare "nothing is being recorded" the audit met.
#
# WHERE ELSE THE SIGNAL SHOULD GO -- at the moment of deletion, or at the next
# analysis -- is a design question, and it is in the report rather than
# implemented here.
# ----------------------------------------------------------------------------
procedure emlRecordSweepOrphans
    .removed = 0
    .nSel0 = numberOfSelected ()
    for .i from 1 to .nSel0
        .sel0[.i] = selected (.i)
    endfor
    select all
    .nAll = numberOfSelected ()
    for .o from 1 to .nAll
        .cand$[.o] = selected$ (.o)
        .candId[.o] = selected (.o)
    endfor
    ; A live buffer anywhere means this is not the state this procedure is
    ; for, and nothing is touched. @emlRecordBegin refuses before it gets
    ; here in that case, but the guard is cheap and this procedure is
    ; callable on its own.
    .liveBuffer = 0
    for .o from 1 to .nAll
        if .cand$[.o] = "Table emlRecordBuffer"
            .liveBuffer = 1
        endif
    endfor
    if .liveBuffer = 0
        for .o from 1 to .nAll
            if .cand$[.o] = "Table emlRecordMeta"
                nocheck removeObject: .candId[.o]
                .removed = .removed + 1
            endif
        endfor
    endif
    if .nSel0 > 0
        nocheck selectObject: .sel0[1]
        for .i from 2 to .nSel0
            nocheck plusObject: .sel0[.i]
        endfor
    else
        nocheck selectObject: "Table emlRecordNothingSelected"
    endif
endproc


procedure emlRecordOrphanCheck
    .orphan = 0
    .nSel0 = numberOfSelected ()
    for .i from 1 to .nSel0
        .sel0[.i] = selected (.i)
    endfor
    select all
    .nAll = numberOfSelected ()
    .haveBuffer = 0
    .haveMeta = 0
    for .o from 1 to .nAll
        if selected$ (.o) = "Table emlRecordBuffer"
            .haveBuffer = 1
        endif
        if selected$ (.o) = "Table emlRecordMeta"
            .haveMeta = 1
        endif
    endfor
    if .haveMeta = 1 and .haveBuffer = 0
        .orphan = 1
    endif
    if .nSel0 > 0
        nocheck selectObject: .sel0[1]
        for .i from 2 to .nSel0
            nocheck plusObject: .sel0[.i]
        endfor
    else
        nocheck selectObject: "Table emlRecordNothingSelected"
    endif
endproc


procedure emlRecordBegin: .tempFolder$
    @emlRecordInit
    .started = 0
    if emlRecordActive = 1
        goto RECORD_BEGIN_DONE
    endif

    ; A Table is the buffer because Praat has no structs and no associative
    ; arrays. It is queryable, countable, renderable by loop, and dumpable to
    ; CSV when something looks wrong — none of which is true of parallel
    ; indexed variables, which is what this would otherwise have to be.
    .keep = 0
    if numberOfSelected () > 0
        .keep = 1
    endif

    ; ---- SWEEP THE ORPHANS FIRST (NEW-G11-3) -------------------------------
    ; Reached only when no recording is running, so any meta table in the
    ; Objects window belongs to a session that has ended -- and the only way
    ; one survives is the one the audit found: the user removed the BUFFER by
    ; hand, which ends the recording, and the meta was left behind because
    ; nothing was watching. Two objects then answer to "Table emlRecordMeta"
    ; and the next session's provenance is a coin toss.
    ;
    ; Cleared here rather than defended against later. The pairing check in
    ; @emlRecordInit is the belt; this is the braces, and it also stops the
    ; Objects window accumulating a table per abandoned recording.
    @emlRecordSweepOrphans

    Create Table with column names: "emlRecordBuffer", 0,
    ... "n kind intent caveat code env post result api derived source"
    emlRecordBufferId = selected ("Table")

    ; The per-session store. Created with the buffer and removed with it, so
    ; "a recording exists" stays a single fact about the Objects window.
    Create Table with column names: "emlRecordMeta", 0, "key value"
    emlRecordMetaId = selected ("Table")

    ; WHICH BUFFER THIS META BELONGS TO, STATED RATHER THAN INFERRED. The
    ; re-attach in @emlRecordInit matches on this and on nothing else, so a
    ; meta left over from a dead session can never furnish a live one.
    @emlRecordMetaSet: "buffer", string$ (emlRecordBufferId)

    ; The include block's path. Resolved at run time from
    ; preferencesDirectory$, then rewritten HOME-RELATIVE, because Praat's
    ; `include` accepts a leading ~ -- tested 10 Aug 2026, including a path
    ; with spaces in it (macOS's "Praat Prefs") and under both 6.4.06 and
    ; 7.0. That one substitution takes the emitted file from
    ; one-machine to any-user-on-this-platform, for free.
    .abs$ = preferencesDirectory$ + "/plugin_EML_Praat_Tools"
    emlRecordPluginRoot$ = .abs$
    if homeDirectory$ <> ""
        if index (.abs$, homeDirectory$) = 1
            emlRecordPluginRoot$ = "~"
            ... + mid$ (.abs$, length (homeDirectory$) + 1, 100000)
        endif
    endif
    ; INTO THE META OBJECT, OR IT DIES WITH THIS SCOPE (NEW-G11-1). The
    ; substitution above is the only thing that makes the emitted include
    ; block portable, and until 14 Aug 2026 it never survived to the flush:
    ; the menu command that saves the file runs in a fresh scope where
    ; @emlRecordInit re-defaulted the root to the absolute path. Every
    ; recording a user could actually make emitted absolute includes under a
    ; header promising home-relative ones. See the matching read in
    ; @emlRecordInit and the honesty branch in @emlRecordRender.
    @emlRecordMetaSet: "pluginRoot", emlRecordPluginRoot$
    emlRecordPraatVersion$ = praatVersion$
    emlRecordPraatVersion = praatVersion

    emlRecordN = 0
    emlRecordActive = 1
    emlRecordHeaderInput$ = ""
    emlRecordHeaderShape$ = ""
    emlRecordSourceChanged = 0
    emlRecordTempPath$ = ""
    if .tempFolder$ <> ""
        emlRecordTempPath$ = .tempFolder$ + "/eml_record_mirror.txt"
        writeFileLine: emlRecordTempPath$,
        ... "# EML record workflow -- crash mirror. Rows are appended as they"
        appendFileLine: emlRecordTempPath$,
        ... "# are recorded, so a session lost to a crash is still readable."
    endif
    @emlRecordMetaSet: "tempPath", emlRecordTempPath$

    ; WHEN THE SESSION HAPPENED, STAMPED HERE AND NOT AT FLUSH.
    ;
    ; Nothing in the shipped plugin called @emlRecordHeader -- its only
    ; callers were two phase1 tests and two roundtrip harnesses -- so every
    ; recording a user could actually make emitted a header line with an
    ; empty date on it. The stamp belongs to the moment recording STARTED,
    ; which is here, and it goes straight into the meta object so that the
    ; menu command that eventually saves the file can still read it.
    ;
    ; THE ENVIRONMENT OVERRIDE IS A TEST SEAM, and the same one EML_RECORD_OUT
    ; already is. A recorder whose output cannot be diffed byte for byte
    ; cannot be regression-tested at all, and every artefact this repository
    ; commits is compared that way. An unset variable gives a real date, which
    ; is what a user gets.
    .stamp$ = environment$ ("EML_RECORD_STAMP")
    if .stamp$ = ""
        .stamp$ = date$ ()
    endif
    emlRecordStamp$ = .stamp$
    @emlRecordMetaSet: "stamp", .stamp$
    .started = 1

    label RECORD_BEGIN_DONE
endproc


# ----------------------------------------------------------------------------
# @emlRecordDiscard
# Throw the buffer away without emitting. The only way to end a recording
# without a file, and it is explicit for the same reason @emlRecordBegin
# refuses: losing a session has to be something a caller asked for.
# ----------------------------------------------------------------------------
procedure emlRecordDiscard
    @emlRecordInit
    if emlRecordBufferId > 0
        nocheck removeObject: emlRecordBufferId
    endif
    ; The meta object goes with it. Leaving it behind would let the NEXT
    ; recording inherit this one's timestamp and input name through the
    ; re-attach in @emlRecordInit -- provenance from a session that was
    ; deliberately thrown away.
    if emlRecordMetaId > 0
        nocheck removeObject: emlRecordMetaId
    endif
    emlRecordMetaId = 0
    emlRecordBufferId = 0
    emlRecordN = 0
    emlRecordActive = 0
    emlRecordStamp$ = ""
    emlRecordHeaderInput$ = ""
    emlRecordHeaderShape$ = ""
endproc


# ----------------------------------------------------------------------------
# @emlRecordHeader: .inputName$, .nRows, .nCols, .stamp$
# The provenance the emitted file opens with. Held rather than written,
# because the file does not exist until flush.
#
# .stamp$ is passed in rather than read from date$() so that a test can pin
# it. A recorder that cannot be made deterministic cannot be diffed.
# ----------------------------------------------------------------------------
procedure emlRecordHeader: .inputName$, .nRows, .nCols, .stamp$
    @emlRecordInit
    emlRecordHeaderInput$ = .inputName$
    emlRecordHeaderRows = .nRows
    emlRecordHeaderCols = .nCols
    emlRecordHeaderShape$ = string$ (.nRows) + " rows, "
    ... + string$ (.nCols) + " columns"
    emlRecordStamp$ = .stamp$
    @emlRecordMetaSet: "input", .inputName$
    @emlRecordMetaSet: "rows", string$ (.nRows)
    @emlRecordMetaSet: "cols", string$ (.nCols)
    @emlRecordMetaSet: "shape", emlRecordHeaderShape$
    @emlRecordMetaSet: "stamp", .stamp$
endproc


# ----------------------------------------------------------------------------
# @emlRecordSource: .tableId
# Record WHICH object the session worked on, as provenance.
#
# THE PATH REGISTRY THAT USED TO LIVE HERE IS GONE. It registered every path
# the session touched, assigned form-variable names by role, and resolved
# tokens into a `form:` block at flush so the emitted file could be re-run on
# any machine by pressing OK.
#
# It was solving a problem the emission level created. Emitting wrapper-level
# `runScript:` calls meant the file had to bootstrap itself -- find the
# plugin, read the input, name the outputs -- and every one of those needed a
# path. Emitting at the API level instead, with an `include` block and
# whatever object the user has selected, removes the requirement rather than
# meeting it. Author's call, 9 Aug 2026, and it deleted more machinery than
# it added: the registry, the tokens, the roles, the form block, the
# `folder:`-resolves-to-cwd trap, and the thirteen batch wrapper siblings the
# other route would have needed.
#
# WHAT IS KEPT IS THE PART A READER ACTUALLY NEEDS. "Whatever is selected"
# gives no way to know whether the right thing was selected. So the object's
# name and shape go in the header as provenance -- not as a field to fill in,
# as a statement of what this record describes.
# ----------------------------------------------------------------------------
procedure emlRecordSource: .tableId
    @emlRecordInit
    if emlRecordActive = 0
        goto END_RECORD_SOURCE
    endif
    selectObject: .tableId

    ; THE OBJECT'S FULL NAME, TYPE INCLUDED, AND NOT ASSUMED TO BE A TABLE.
    ;
    ; The plugin accepts a Table, a TableOfReal and a Matrix -- the graphs
    ; form's own @emlDetectContext branches on all three -- so a recorder
    ; that writes `selectObject: "Table " + name$` produces a script that
    ; cannot select two of the three. It was written that way and this is
    ; the fix.
    ;
    ; `selected$ ()` with NO argument returns "Type name" -- measured
    ; 12 Aug 2026 on 6.6.30: "Table vt", "Matrix spec", "TableOfReal tor" --
    ; and that whole string is what `selectObject:` takes back. So the
    ; recorder never has to know which type it is holding, and adding a
    ; fourth type needs no change here.
    .name$ = selected$ ()

    ; AN AUTO-CONVERTED OBJECT IS RECORDED AS ITS SOURCE, and this is the
    ; whole point of the convert step (author, 12 Aug 2026: "fo, waveform,
    ; spectrum, and LTAS will all also run from just a sound. They auto
    ; convert").
    ;
    ; @emlGraphsWorkflow turns a selected Sound into a Pitch, a Spectrum or
    ; an Ltas, hands THAT to the draw procedure, and REMOVES it at the end of
    ; the pass. The capture hook lives inside the draw procedure, so without
    ; this the recorder wrote "Pitch tone" into the manifest -- an object the
    ; user never created and which does not exist by the time they re-run the
    ; file. Every acoustic figure recorded from the menu emitted a script
    ; that could not run, and instructed the reader to open an object that
    ; had been deleted.
    ;
    ; So the step is attributed to the Sound, and flagged: the renderer emits
    ; no select for it, because the convert step immediately above left the
    ; derived object in `data`.
    .fromConversion = 0
    if emlRecordDerivedId > 0 and .tableId = emlRecordDerivedId
        .fromConversion = 1
        .name$ = emlRecordDerivedFrom$
        emlRecordStepDerived$ = "1"
    endif

    ; ROWS AND COLUMNS ARE NOT UNIVERSAL, AND ASSUMING THEY WERE KILLED FOUR
    ; OPERATIONS (12 Aug 2026).
    ;
    ; This block used to read `Get number of rows` unconditionally with a
    ; comment saying every accepted type answers it. That is true of the three
    ; TABULAR types -- Table, TableOfReal, Matrix -- and false of the objects
    ; the acoustic draw procedures take. @emlDrawWaveform is handed a Sound;
    ; @emlDrawF0Contour a Pitch; @emlDrawSpectrum a Spectrum; @emlDrawLTAS an
    ; Ltas. None answers "Get number of rows", so with a recording running,
    ; each of those four draws died inside the RECORDER: "Command Get number
    ; of rows not available for current selection", from a procedure whose
    ; whole contract is to be inert.
    ;
    ; It was invisible standalone. With no recording active @emlRecordSource
    ; returns at the guard above, so every unit test of the draw path passed;
    ; only harness/record_e2e, which switches recording ON and then draws,
    ; reaches this line with a Sound selected.
    ;
    ; `nocheck` IS NOT THE FIX and was tried first: `nocheck .rows = Get
    ; number of rows` suppresses the ASSIGNMENT as well as the error, so the
    ; variable keeps its prior value and a Sound silently inherits the last
    ; Table's dimensions. The type is therefore read from the name -- the
    ; first word of `selected$ ()` -- and the shape is reported only for the
    ; types that have one. An object with no row/column shape is not a
    ; failure; it just has nothing to say here.
    .space = index (.name$, " ")
    if .space > 0
        .type$ = left$ (.name$, .space - 1)
    else
        .type$ = .name$
    endif

    .rows = 0
    .cols = 0
    .shape$ = ""
    if .fromConversion = 1
        ; The selected object is the intermediate, not the source, so its
        ; shape would describe something the record does not name.
        .type$ = ""
    endif
    if .type$ = "Table" or .type$ = "TableOfReal" or .type$ = "Matrix"
        .rows = Get number of rows
        .cols = Get number of columns
        .shape$ = string$ (.rows) + " rows, " + string$ (.cols) + " columns"
    endif

    ; FIRST WINS, AND THE REST IS NAMED.
    ;
    ; This overwrote on every call in its first cut, so the header described
    ; the LAST object any step touched. Observed immediately: a fixture that
    ; ran an ANOVA on the real table and then a refusal on a one-group copy
    ; emitted "Recorded against: oneGroup" -- naming, as the subject of the
    ; record, a table the reported analysis never saw. A header that is
    ; confidently wrong is worse than one that is missing.
    ;
    ; The header therefore describes the object the session STARTED on. A
    ; session that moves to another object is not silently flattened into
    ; that claim: .changed is raised, and the renderer says so.
    .changed = 0
    if emlRecordHeaderInput$ = ""
        emlRecordHeaderInput$ = .name$
        emlRecordHeaderRows = .rows
        emlRecordHeaderCols = .cols
        emlRecordHeaderShape$ = .shape$
        ; Into the object, not just the variable: the next menu command runs
        ; in a scope where none of these exist.
        @emlRecordMetaSet: "input", .name$
        @emlRecordMetaSet: "rows", string$ (.rows)
        @emlRecordMetaSet: "cols", string$ (.cols)
        @emlRecordMetaSet: "shape", .shape$
    elsif emlRecordHeaderInput$ <> .name$
        .changed = 1
        emlRecordSourceChanged = 1
        @emlRecordMetaSet: "sourceChanged", "1"
    endif

    ; THE SOURCE OF THE STEP ABOUT TO BE RECORDED.
    ;
    ; The header above describes the object the session STARTED on and that
    ; is still right. What it cannot do is carry a session that MOVES, and
    ; once recording spans several menu commands moving is ordinary rather
    ; than exceptional -- an ANOVA on one table, a correlation on another.
    ; The old behaviour raised emlRecordSourceChanged and the emitted file
    ; said it would not reproduce; useful as a warning, useless as a script,
    ; and it would have fired on most real sessions.
    ;
    ; So the source is now carried PER STEP, and the renderer emits a
    ; select only where it changes. A single-table session is unchanged --
    ; one select at the top and no noise.
    emlRecordCurrentSource$ = .name$

    ; AN AMBIGUOUS NAME, DETECTED WHERE IT IS KNOWABLE. The emitted script
    ; selects by NAME, and two Tables sharing one name make that ambiguous:
    ; measured 12 Aug 2026, `selectObject: "Table vt"` with two such Tables
    ; silently picks the MOST RECENT. Here the id is known, so the collision
    ; can be seen; in the emitted file it cannot. Counted now, reported by
    ; the renderer.
    ;
    ; COMPARED AGAINST .name$ WHOLE, and it used to read `"Table " + .name$`.
    ; That was correct while .name$ came from `selected$ ("Table")` and held
    ; the bare name; it stopped being correct the moment .name$ became
    ; `selected$ ()`, which already carries the type. The comparison then
    ; asked whether any object was called "Table Table voiceA" and the answer
    ; was always no, so the duplicate-name warning could not fire at all.
    .dupes = 0
    if .fromConversion = 1
        goto END_RECORD_SOURCE_DUPES
    endif
    select all
    .total = numberOfSelected ()
    for .o from 1 to .total
        if selected$ (.o) = .name$
            .dupes = .dupes + 1
        endif
    endfor
    if .dupes > 1
        emlRecordAmbiguousName = 1
    endif
    label END_RECORD_SOURCE_DUPES
    selectObject: .tableId

    label END_RECORD_SOURCE
endproc


# ----------------------------------------------------------------------------
# @emlRecordAnalysisStep: .tableId, .label$, .detail$, .caveat$, .code$,
#                         .api$, .error$
#
# ONE RECORDER FOR EVERY ANALYSIS, rather than thirteen near-copies.
#
# @emlRecordAnova came first and is bespoke because it also emits the F, the
# p, the eta-squared and a line per group from emlOneWayAnova.*. Every other
# orchestrator exposes a different result surface, and writing twelve more
# procedures that differ only in which globals they read is how a recorder
# drifts out of agreement with the analyses it records.
#
# So this takes the four strings that are genuinely per-analysis and does
# everything else once: the source, the refusal path, the phrase lookup.
# Results are added by the caller afterwards with @emlRecordResult where the
# orchestrator has numbers worth carrying.
#
# THE REFUSAL PATH IS THE REASON THIS IS CALLED AFTER THE END LABEL. Every
# guard in an orchestrator jumps there, so an analysis that refused -- too few
# groups, a non-numeric column -- is recorded as a step carrying its refusal
# rather than vanishing. A log that shows only the analyses that succeeded
# lies by omission, and the one it hides is usually the one worth reading.
# ----------------------------------------------------------------------------
procedure emlRecordAnalysisStep: .tableId, .label$, .detail$, .caveat$,
    ... .code$, .api$, .result$, .error$
    @emlRecordInit
    if emlRecordActive = 0
        goto END_RECORD_ANALYSIS_STEP
    endif

    @emlRecordSource: .tableId

    if .error$ <> ""
        @emlPhrase: "refusal.intent", .error$, "", "", "", "", ""
        @emlRecordStep: "refusal", emlPhrase.result$, "", "", ""
        goto END_RECORD_ANALYSIS_STEP
    endif

    @emlPhrase: "analysis.intent", .label$, .detail$, "", "", "", ""
    @emlRecordStep: "analysis", emlPhrase.result$, .caveat$, .code$, .api$

    ; THE NUMBERS, NOT JUST THE CALL (12 Aug 2026).
    ;
    ; This procedure took no result when it was written, so the twelve
    ; orchestrators wired to it recorded THAT an analysis ran and never WHAT
    ; it produced. @emlRecordAnova -- the hand-written recorder that predates
    ; it -- had always emitted
    ;
    ;     # F(1, 22) = 5.2251, p = 0.0323, eta-squared = 0.1919
    ;
    ; so a session's ANOVA carried its own answer and its correlation did not.
    ; For a correlation or a regression the coefficient IS the step; a record
    ; that omits it documents an intention rather than a result.
    ;
    ; THE NUMBERS COME FROM THE CALLER'S OWN VARIABLES, never from a re-read
    ; of the Info window. That is the rule @emlRecordAnova already states and
    ; the reason is in validate/REGISTRY.md: scraping info$() reintroduces the
    ; label-matching hazard where "Soprano" matches five lines in one capture
    ; and seven in the next. The caller has the values the reporter printed;
    ; it passes them.
    ;
    ; Empty is legitimate -- a descriptive path has no single number worth
    ; hoisting -- and the renderer simply omits the block.
    if .result$ <> ""
        @emlRecordResult: .result$
    endif

    label END_RECORD_ANALYSIS_STEP
endproc


# ----------------------------------------------------------------------------
# @emlRecordDrawStep: .objectId, .label$, .detail$, .caveat$, .code$, .api$
#
# The draw-layer twin of @emlRecordAnalysisStep, and it exists for the same
# reason: sixteen draw procedures, and writing sixteen recorders that differ
# only in which locals they read is how a recorder drifts away from the
# figures it records.
#
# NO REFUSAL PATH. A draw procedure that cannot draw does not return an error
# string -- it draws the labelled empty frame and says so on the figure, which
# is D111's whole design and is asserted by v27. There is nothing here for a
# refusal branch to catch.
# ----------------------------------------------------------------------------
procedure emlRecordDrawStep: .objectId, .label$, .detail$, .caveat$, .code$,
    ... .api$, .result$
    @emlRecordInit
    if emlRecordActive = 0
        goto END_RECORD_DRAW_STEP
    endif

    @emlRecordSource: .objectId
    @emlPhrase: "drawstep.intent", .label$, .detail$, "", "", "", ""
    @emlRecordStep: "draw", emlPhrase.result$, .caveat$, .code$, .api$

    ; A FIGURE CAN PRODUCE STATISTICS, and the scatter does: correlation and
    ; regression are reported FROM the plot when the form asks for them, the
    ; mirror of Correlate and Regress on the stats menu. Most draws have
    ; nothing to put here and pass "", which the renderer omits.
    if .result$ <> ""
        @emlRecordResult: .result$
    endif

    label END_RECORD_DRAW_STEP
endproc


# ----------------------------------------------------------------------------
# @emlRecordConvert: .sourceId, .targetId, .code$, .why$
# The auto-conversion the graphs form performs, recorded as its own step.
#
# WHY THIS EXISTS. Four of the plugin's figures are drawn from objects the
# user does not have to make. Select a Sound and ask for an F0 contour, a
# spectrum or an LTAS and @emlGraphsWorkflow converts it, draws, and REMOVES
# the intermediate at the end of the pass. That is the documented behaviour
# and it is the behaviour most users will meet, since a Sound is what comes
# off a recorder.
#
# The recorder's capture hook is inside the DRAW procedure, so what it saw
# was the intermediate: every acoustic figure recorded from the menu wrote
# `data1$ = "Pitch tone"` into the manifest and told the reader to have that
# object open. It had been deleted by the plugin itself moments earlier, and
# the user never made it. The emitted script could not run.
#
# Recording the conversion fixes both halves at once: the manifest names the
# SOUND, which is the thing the user actually selected and still has, and the
# emitted file carries the command that turns it into what the figure needs.
# The reader can also SEE the conversion, with its parameters, which is worth
# more than the figure line on its own -- the pitch floor and ceiling used
# are a methods-section fact.
#
# Arguments:
#   .sourceId   the object the user selected (the Sound)
#   .targetId   the object the conversion produced (the Pitch/Spectrum/Ltas)
#   .code$      the conversion, written so that it assigns to `data`
#   .why$       one line for the reader: what this is for
# ----------------------------------------------------------------------------
procedure emlRecordConvert: .sourceId, .targetId, .code$, .why$
    @emlRecordInit
    if emlRecordActive = 0
        goto END_RECORD_CONVERT
    endif

    ; Cleared FIRST, so a conversion recorded while a previous one is still
    ; registered attributes itself to the right source. The pairing lasts one
    ; menu invocation and must not outlive it.
    emlRecordDerivedId = 0
    emlRecordDerivedFrom$ = ""

    @emlRecordSource: .sourceId
    .from$ = emlRecordCurrentSource$

    selectObject: .targetId
    .to$ = selected$ ()

    @emlRecordStep: "convert",
    ... "Converted " + .from$ + " to " + .to$ + ".", .why$, .code$,
    ... "In the GUI: this happens automatically when you ask for a figure "
    ... + "that needs it."

    ; Registered only AFTER the step is recorded: @emlRecordStep reads
    ; emlRecordStepDerived$, and the conversion itself ran on the SOURCE.
    emlRecordDerivedId = .targetId
    emlRecordDerivedFrom$ = .from$

    label END_RECORD_CONVERT
endproc


# ----------------------------------------------------------------------------
# @emlRecordStep: .kind$, .intent$, .caveat$, .code$, .api$
# Add one step. Every argument is already-resolved text; this procedure
# composes nothing and decides nothing.
#
# A REFUSAL IS A ROW LIKE ANY OTHER — kind "refusal", empty result, the
# refusal message in caveat. A step that refused is still a step, and it is
# usually the most useful line in the file.
#
# .code$ may carry several lines joined by newline$. It may NOT be empty:
# a row with nothing executable is a gap that reads as completeness, which
# is the failure this feature exists to prevent. Callers that genuinely have
# no code — a refusal before anything ran — pass the sentinel below and the
# renderer emits it as a comment rather than as code.
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# @emlRecordCaptureEnv   ->  .out$
#
# THE SETTINGS THAT ARE NOT ARGUMENTS (NEW-G11-2, 14 August 2026).
#
# WHAT WENT WRONG. Record an advanced-mode violin with "Show jittered points"
# ticked, stop, save, replay: the violin comes back and the points do not.
# The reason is that `Show jittered points` is not a parameter of
# @emlDrawViolinPlot. It is a GLOBAL -- prev_violinShowJitter -- set by the
# graphs form and read by the draw procedure through variableExists. The
# recorded call carries every argument faithfully and the emitted script still
# draws a different figure, because the thing that made it advanced was never
# an argument to record. Reproduced 14 Aug 2026 against a 2-group violin: the
# original and the replay differ by ~2400 dark pixels and the jitter is all of
# them.
#
# THE PRECEDENT IS ALREADY IN THE TREE and this is its generalisation. The
# scatter recorder in eml-draw-procedures.praat prepends
# `scatterAnalysisType = ...` and two siblings to its own code line, for
# exactly this reason, and v39 pins that it does. Four more draw procedures
# have the same shape and none of them prepend anything. Writing the block
# five more times in the draw layer is how a recorder drifts away from the
# figures it records -- the argument @emlRecordDrawStep's own header makes --
# so it is done ONCE, here, for every step.
#
# WHY IT CAN ONLY BE DONE HERE. These globals belong to the FORM's scope. The
# flush is a different menu command in a different scope, where none of them
# exist. @emlRecordStep is the last moment they are readable, so it is the
# only moment they can be recorded.
#
# EVERY GLOBAL PRESENT IS EMITTED, INCLUDING THE ZEROES, and that is not
# tidiness. An emitted script is one scope: a figure drawn with jitter on
# leaves prev_violinShowJitter = 1 behind, and a later figure in the same
# script that was drawn WITHOUT it would inherit the 1 and gain points the
# user never asked for. A step is only self-contained if it states the
# settings it did not use.
#
# READ THROUGH variableExists, ALWAYS. A direct caller -- a user script, a
# PraatGen companion, this tree's own harnesses -- sets none of these, and
# reading one unconditionally is how the scatter's first cut killed the
# harness with "Unknown variable".
# ----------------------------------------------------------------------------
procedure emlRecordCaptureEnv
    .out$ = ""
    ; The four jitter switches, one per categorical figure that offers the
    ; tickbox. Named individually rather than swept, because a sweep cannot
    ; be read and this list is the statement of what the recorder carries.
    if variableExists ("prev_violinShowJitter")
        .out$ = .out$ + "prev_violinShowJitter = "
        ... + string$ (prev_violinShowJitter) + newline$
    endif
    if variableExists ("prev_boxShowJitter")
        .out$ = .out$ + "prev_boxShowJitter = "
        ... + string$ (prev_boxShowJitter) + newline$
    endif
    if variableExists ("prev_gvShowJitter")
        .out$ = .out$ + "prev_gvShowJitter = "
        ... + string$ (prev_gvShowJitter) + newline$
    endif
    if variableExists ("prev_gbShowJitter")
        .out$ = .out$ + "prev_gbShowJitter = "
        ... + string$ (prev_gbShowJitter) + newline$
    endif
    ; `annotate` is read by @emlDiscloseEnd to decide which corner the
    ; disclosure block may not occupy, so it changes the figure even on a
    ; step that draws no bracket.
    if variableExists ("annotate")
        .out$ = .out$ + "annotate = " + string$ (annotate) + newline$
    endif
endproc


# ----------------------------------------------------------------------------
# @emlRecordCaptureAnnotations: .kind$   ->  .out$
#
# THE OTHER HALF OF NEW-G11-2: THE BRACKET.
#
# WHAT WENT WRONG, AND IT IS NOT WHAT IT LOOKS LIKE. The recorded script for
# an annotated violin contains both halves of the annotation already: the
# bridge step that runs the test and fills annotBracketN, annotBracketLabel$[]
# and the rest, and the draw step that draws the violin. Replay it and there
# is no bracket. Nothing is missing from the emission and nothing is in the
# wrong order.
#
# The bracket is drawn by neither of them. It is drawn by
# @emlGraphsPostDispatchAnnotations in eml-graphs-form.praat, AFTER the draw
# procedure returns, and the emitted file cannot call it: including
# eml-graphs-form.praat would run the graphs form. So a recorded annotated
# figure was structurally incapable of coming back annotated -- the recorder
# was carrying the inputs to a step it never carried.
#
# So the render is emitted, from here, as the step's own tail. The values it
# needs that belong to the form -- the data maximum the brackets sit above,
# which figure was drawn -- are captured as literals at record time; the
# values that belong to the FIGURE are referenced through the draw
# procedure's own axis accessors, so a script re-pointed at other data
# re-resolves them rather than pinning last month's axis.
#
# THE MATRIX PANEL IS NOT REPLAYED, AND THE FILE SAYS SO. With four or more
# groups (or a grouped violin or grouped box plot) the annotation is a
# comparison-matrix panel drawn BELOW the figure, on a canvas the graphs form
# enlarges around the draw. The recorded step carries the draw, not the
# canvas, so emitting the panel call would place it outside the picture that
# gets saved. An honest comment is worth more than a silently misplaced
# panel: the emitted file names what it did not reproduce, and the gap is in
# the audit reply rather than papered over.
#
# WHY .kind$ IS TAKEN AND CHECKED. Only a draw step has a figure to annotate.
# The bridge step that computed the statistics is an "analysis" step and must
# emit nothing here, or the annotation would be rendered before the figure it
# belongs to exists.
# ----------------------------------------------------------------------------
procedure emlRecordCaptureAnnotations: .kind$
    .out$ = ""
    if .kind$ <> "draw"
        goto END_CAPTURE_ANNOT
    endif
    if not variableExists ("annotate")
        goto END_CAPTURE_ANNOT
    endif
    if annotate <> 1
        goto END_CAPTURE_ANNOT
    endif

    .nB = 0
    .nT = 0
    .nM = 0
    if variableExists ("annotBracketN")
        .nB = annotBracketN
    endif
    if variableExists ("annotTextN")
        .nT = annotTextN
    endif
    if variableExists ("annotMatrixN")
        .nM = annotMatrixN
    endif
    if .nB = 0 and .nT = 0 and .nM = 0
        goto END_CAPTURE_ANNOT
    endif

    ; WHICH FIGURE WAS DRAWN, so the axis can be asked for. The map is the
    ; one in @emlGraphsPostDispatchAnnotations and it is duplicated rather
    ; than shared, because the form is not includable from an emitted file.
    ; A graph type not on this list has no bracket path in the form either,
    ; so emitting nothing for it is agreement, not a gap.
    .acc$ = ""
    if variableExists ("graph_type")
        if graph_type = 6
            .acc$ = "emlDrawBarChart"
        elsif graph_type = 7
            .acc$ = "emlDrawViolinPlot"
        elsif graph_type = 9
            .acc$ = "emlDrawBoxPlot"
        elsif graph_type = 11
            .acc$ = "emlDrawGroupedViolin"
        elsif graph_type = 12
            .acc$ = "emlDrawGroupedBoxPlot"
        endif
    endif
    if .acc$ = ""
        goto END_CAPTURE_ANNOT
    endif

    ; The matrix arm, stated and not drawn. Reached whenever the form chose a
    ; panel over brackets -- four or more groups, or a grouped figure.
    if .nM > 0
        .out$ = .out$
        ... + "# NOT REPLAYED: this figure carried a comparison-matrix panel."
        ... + newline$
        ... + "# The panel is drawn below the figure on a taller canvas that"
        ... + newline$
        ... + "# the graphs form sets up around the draw, and a recorded step"
        ... + newline$
        ... + "# carries the draw and not the canvas. The statistics are in"
        ... + newline$
        ... + "# the step above; re-run the figure through EML Graphs... with"
        ... + newline$
        ... + "# annotation on to get the panel back." + newline$
        goto END_CAPTURE_ANNOT
    endif

    .dMax = 0
    if variableExists ("dataYMax_forAnnotation")
        .dMax = dataYMax_forAnnotation
    endif

    .out$ = .out$
    ... + "# The figure's statistical annotation. In the GUI the graphs form"
    ... + newline$
    ... + "# draws this after the figure returns; a recorded script has no"
    ... + newline$
    ... + "# form, so the step carries its own render." + newline$
    .out$ = .out$ + "annotXMin = " + .acc$ + ".axisXMin" + newline$
    .out$ = .out$ + "annotXMax = " + .acc$ + ".axisXMax" + newline$
    .out$ = .out$ + "annotYMin = " + .acc$ + ".axisYMin" + newline$
    .out$ = .out$ + "annotYMax = " + .acc$ + ".axisYMax" + newline$
    .out$ = .out$ + "annotYRange = annotYMax - annotYMin" + newline$
    ; The omnibus line is routed into the corner block exactly as the form
    ; routes it, and the counter is zeroed after, so a second figure in the
    ; same script does not inherit this one's sentence.
    .out$ = .out$ + "if annotTextN > 0" + newline$
    .out$ = .out$ + "    annotBlockN = annotBlockN + 1" + newline$
    .out$ = .out$
    ... + "    annotBlockLabel$[annotBlockN] = annotTextLabel$[1]" + newline$
    .out$ = .out$
    ... + "    annotBlockDraw$[annotBlockN] = annotTextLabel$[1]" + newline$
    .out$ = .out$ + "    annotTextN = 0" + newline$
    .out$ = .out$ + "endif" + newline$
    .out$ = .out$ + "if annotBracketN > 0" + newline$
    .out$ = .out$ + "    @emlDrawAnnotations: annotXMin, annotXMax, "
    ... + fixed$ (.dMax, 6) + ", annotYRange, ""{0.3, 0.3, 0.3}"", "
    ... + "emlSetAdaptiveTheme.annotSize, annotYMin, annotYMax" + newline$
    .out$ = .out$ + "endif" + newline$
    .out$ = .out$ + "if annotBlockN > 0" + newline$
    .out$ = .out$ + "    if annotBracketN > 0" + newline$
    .out$ = .out$ + "        omnibusCorner$ = ""bottom-right""" + newline$
    .out$ = .out$ + "    else" + newline$
    .out$ = .out$ + "        omnibusCorner$ = ""top-right""" + newline$
    .out$ = .out$ + "    endif" + newline$
    .out$ = .out$ + "    @emlDrawAnnotationBlock: omnibusCorner$, annotXMin, "
    ... + "annotXMax, annotYMin, annotYMax, "
    ... + "emlSetAdaptiveTheme.annotSize" + newline$
    .out$ = .out$ + "endif" + newline$
    ; Cleared after the render, so the NEXT recorded figure's bridge starts
    ; from the same blank state the form gives it.
    .out$ = .out$ + "@emlClearAnnotations" + newline$

    label END_CAPTURE_ANNOT
endproc


procedure emlRecordStep: .kind$, .intent$, .caveat$, .code$, .api$
    @emlRecordInit
    .added = 0
    if emlRecordActive = 0
        goto RECORD_STEP_DONE
    endif

    .codeOut$ = .code$
    if .codeOut$ = ""
        .codeOut$ = "; (nothing executed at this step -- see the note above)"
    endif

    emlRecordN = emlRecordN + 1
    selectObject: emlRecordBufferId
    Append row
    .row = Get number of rows
    Set numeric value: .row, "n", emlRecordN
    Set string value: .row, "kind", .kind$
    Set string value: .row, "intent", .intent$
    Set string value: .row, "caveat", .caveat$
    Set string value: .row, "code", .codeOut$
    ; THE SETTINGS THE STEP WAS DRAWN UNDER, AND WHAT IT DREW AFTERWARDS.
    ; Captured HERE because here is the only place that can: this procedure
    ; runs inside the same script scope as the operation that recorded it, so
    ; the graphs form's globals are still live. By flush time they are gone --
    ; the flush is its own menu command. See @emlRecordCaptureEnv and
    ; @emlRecordCaptureAnnotations, which are one fix (NEW-G11-2) in two
    ; halves.
    @emlRecordCaptureEnv
    Set string value: .row, "env", emlRecordCaptureEnv.out$
    @emlRecordCaptureAnnotations: .kind$
    Set string value: .row, "post", emlRecordCaptureAnnotations.out$
    Set string value: .row, "result", ""
    Set string value: .row, "api", .api$
    ; DERIVED: "1" when the object this step ran on was AUTO-CREATED from
    ; something the user selected -- the graphs form converts a Sound to a
    ; Pitch, a Spectrum or an Ltas, draws, and then REMOVES the intermediate.
    ; The renderer must not emit a manifest select for such a step: the
    ; object it names no longer exists by the time anyone re-runs the file,
    ; and it never existed in the user's session as something they made. The
    ; preceding convert step left it in `data`, which is what the step uses.
    ;
    ; (This column was "paths" -- written empty on every row since the path
    ; registry was deleted on 9 Aug 2026, and read by nothing.)
    Set string value: .row, "derived", emlRecordStepDerived$
    emlRecordStepDerived$ = "" 
    ; The object this step ran on, so the renderer can emit a select where
    ; it changes. Empty when a caller recorded a step without a source --
    ; a refusal before anything was read -- and the renderer leaves those
    ; on whatever was selected, which is correct: they select nothing.
    Set string value: .row, "source", emlRecordCurrentSource$
    .added = 1

    ; §8.3: mirror to a temp file as the row is added. A Table lost to a
    ; crash takes the session with it; a file does not.
    if emlRecordTempPath$ <> ""
        appendFileLine: emlRecordTempPath$, "--- step ", emlRecordN,
        ... " (", .kind$, ")"
        appendFileLine: emlRecordTempPath$, .intent$
        if .caveat$ <> ""
            appendFileLine: emlRecordTempPath$, .caveat$
        endif
        appendFileLine: emlRecordTempPath$, .codeOut$
    endif

    label RECORD_STEP_DONE
endproc


# ----------------------------------------------------------------------------
# @emlRecordResult: .text$
# Stream A. Attach an outcome to the step most recently recorded.
#
# THE ONE THING THIS PROCEDURE EXISTS TO AVOID is scraping info$(). The
# obvious implementation of Stream A is to snapshot the Info window before
# and after a step and keep the difference. That reintroduces a failure this
# project has already paid for twice — an unwitnessed step in the middle of
# a chain, and label matching that resolves silently to the wrong line.
# validate/REGISTRY.md records that "Soprano" matches five lines in the v09
# capture and seven in v10, and that the fix was to pin expected hit counts.
# A Praat-side scraper inherits that hazard with none of the guards.
#
# So the orchestrator declares its own log line at the moment it prints it,
# from the same variables. More call sites, no ambiguity, no second parser.
# ----------------------------------------------------------------------------
procedure emlRecordResult: .text$
    @emlRecordInit
    if emlRecordActive = 0
        goto RECORD_RESULT_DONE
    endif
    selectObject: emlRecordBufferId
    .row = Get number of rows
    if .row < 1
        goto RECORD_RESULT_DONE
    endif
    .prev$ = Get value: .row, "result"
    if .prev$ = ""
        Set string value: .row, "result", .text$
    else
        Set string value: .row, "result", .prev$ + newline$ + .text$
    endif

    label RECORD_RESULT_DONE
endproc


# ============================================================================
# PHRASES
# ============================================================================

# ----------------------------------------------------------------------------
# @emlRecordLoadPhrases: .csvPath$
# Read the shipped phrase registry once. Two columns, key and template.
# Outputs: .ok — 1 if loaded, 0 if the file was not readable
# ----------------------------------------------------------------------------
procedure emlRecordLoadPhrases: .csvPath$
    @emlRecordInit
    .ok = 0
    if not fileReadable (.csvPath$)
        goto RECORD_PHRASES_DONE
    endif
    if emlRecordPhraseId > 0
        nocheck removeObject: emlRecordPhraseId
    endif
    Read Table from comma-separated file: .csvPath$
    emlRecordPhraseId = selected ("Table")
    .ok = 1

    label RECORD_PHRASES_DONE
endproc


# ----------------------------------------------------------------------------
# @emlPhrase: .key$, .a1$, .a2$, .a3$, .a4$, .a5$, .a6$
# Positional substitution into a shipped template.
#
# PLACEHOLDERS ARE POSITIONAL — {1}..{6} — AND NOT NAMED, and that is forced
# rather than chosen. Praat procedures have fixed arity, so a variadic
# named-substitution helper is not expressible; and single-quote
# interpolation is confined to procedure bodies. Positional keeps this to one
# procedure. Legibility lives in the CSV, which is where a human edits the
# wording.
#
# A MISSING KEY IS NOT SILENT. It returns a marked string that a reader
# cannot mistake for prose and that the validator greps for. Silence is a
# defect: a step whose narrative vanished would leave a code line with no
# account of why it ran.
#
# COMPOSING TWO PHRASES: CAPTURE THE FIRST BEFORE CALLING AGAIN.
# Praat procedure locals live in ONE namespace per procedure, not one per
# call, so emlPhrase.result$ is overwritten by the next @emlPhrase. A step
# whose narrative is built from two keys must be written
#
#     @emlPhrase: "anova.intent", ...
#     .intent$ = emlPhrase.result$              <- capture
#     @emlPhrase: "alpha.source.default", ...
#     .intent$ = .intent$ + " " + emlPhrase.result$
#
# and NOT as two calls followed by one read. This bit during the first
# render of the test fixture: step 2 came out narrated "default, not
# specified by the user" with the ANOVA sentence silently gone. The code
# line was still correct, which is what makes it dangerous — the file looked
# complete and described the wrong thing. There is no way to make the
# namespace per-call in Praat, so the guard is this note plus the
# composition test in plugin/dev/tests/phase1/test-record.praat.
# ----------------------------------------------------------------------------
procedure emlPhrase: .key$, .a1$, .a2$, .a3$, .a4$, .a5$, .a6$
    @emlRecordInit
    .result$ = ""
    .found = 0
    if emlRecordPhraseId > 0
        selectObject: emlRecordPhraseId
        .n = Get number of rows
        for .i from 1 to .n
            selectObject: emlRecordPhraseId
            .k$ = Get value: .i, "key"
            if .k$ = .key$ and .found = 0
                .found = .i
            endif
        endfor
    endif
    if .found = 0
        .result$ = "[MISSING PHRASE: " + .key$ + "]"
        goto RECORD_PHRASE_DONE
    endif
    selectObject: emlRecordPhraseId
    .result$ = Get value: .found, "template"
    .result$ = replace$ (.result$, "{1}", .a1$, 0)
    .result$ = replace$ (.result$, "{2}", .a2$, 0)
    .result$ = replace$ (.result$, "{3}", .a3$, 0)
    .result$ = replace$ (.result$, "{4}", .a4$, 0)
    .result$ = replace$ (.result$, "{5}", .a5$, 0)
    .result$ = replace$ (.result$, "{6}", .a6$, 0)

    label RECORD_PHRASE_DONE
endproc


# ============================================================================
# RENDER
# ============================================================================

# ----------------------------------------------------------------------------
# @emlRecordCommentBlock: .text$
# Turn a possibly multi-line string into "# " lines. Used for intent, caveat,
# result and api — everything that is narrative rather than executable.
#
# This is where the one surviving concern from §8.6 is discharged. Stream A
# hands over Info-formatted text, rules and arrows included. Routing every
# narrative string through here guarantees those characters land in comments,
# so nothing decorative can ever appear inside an executable line.
# ----------------------------------------------------------------------------
procedure emlRecordCommentBlock: .text$
    .out$ = ""
    .rest$ = .text$
    .guard = 0
    while .rest$ <> "" and .guard < 500
        .guard = .guard + 1
        .nl = index (.rest$, newline$)
        if .nl = 0
            .line$ = .rest$
            .rest$ = ""
        else
            .line$ = left$ (.rest$, .nl - 1)
            .rest$ = mid$ (.rest$, .nl + 1, 1000000)
        endif
        .out$ = .out$ + "# " + .line$ + newline$
    endwhile
endproc


# ----------------------------------------------------------------------------
# @emlRecordTableManifest
# The block at the top of an emitted script that names every object the
# session ran on, once each, with the steps that used it.
#
# WHY A BLOCK RATHER THAN A SELECT PER STEP. Both produce a script that runs.
# Only one of them can be EDITED: re-pointing a recorded workflow at another
# data set is the main thing anybody will want to do with the file, and that
# has to be one visible place near the top rather than a hunt through the body
# for every mention of an object.
#
# So each distinct source becomes `tableN$ = "name"` with an inline note of
# the steps that used it, and the body refers to tableN$ and never to a name.
# Change the string, run it again on other data.
#
# ONE SOURCE MEANS NO BLOCK. A session that never moved keeps the contract it
# has always had -- select the Table, run the file -- and emits nothing here.
# The block exists to answer a question a single-source session does not ask.
#
# Outputs: .out$   the block, empty when fewer than two sources were used
#          .n      how many distinct sources the session used
# ----------------------------------------------------------------------------
procedure emlRecordTableManifest
    @emlRecordInit
    .out$ = ""
    .n = 0

    selectObject: emlRecordBufferId
    .nSteps = Get number of rows

    ; Distinct sources, in the order they were first used, so the numbering
    ; follows the session rather than the alphabet.
    for .s from 1 to .nSteps
        selectObject: emlRecordBufferId
        .src$ = Get value: .s, "source"
        if .src$ <> ""
            .seen = 0
            for .k from 1 to .n
                if .name$[.k] = .src$
                    .seen = .k
                endif
            endfor
            if .seen = 0
                .n = .n + 1
                .name$[.n] = .src$
                .steps$[.n] = ""
                .seen = .n
            endif
            ; The steps that used it, and what they were, so the note says
            ; something a reader can act on rather than a bare number.
            selectObject: emlRecordBufferId
            .kind$ = Get value: .s, "kind"
            .stepN = Get value: .s, "n"
            if .steps$[.seen] <> ""
                .steps$[.seen] = .steps$[.seen] + ", "
            endif
            .steps$[.seen] = .steps$[.seen] + string$ (.stepN)
            ... + " (" + .kind$ + ")"
        endif
    endfor

    if .n = 0
        goto END_TABLE_MANIFEST
    endif

    ; ONE FORMAT, WHETHER THE SESSION USED ONE OBJECT OR FIVE.
    ;
    ; The first cut emitted this block only when a session moved between
    ; objects, and left a single-object session on the older "run it with
    ; that Table selected" contract. Author ruling 12 Aug 2026: standardise.
    ; A reader who learns the format on one recorded script then meets a
    ; second one with a different shape has been given two things to learn
    ; for no gain, and the single-object script loses the property that
    ; makes this block worth having -- one visible place to re-point the
    ; workflow at other data.
    .out$ = .out$ + "# Name your data objects here for this recorded workflow."
    ... + newline$
    .out$ = .out$ + "# Edit a name to run the same workflow on other data;"
    ... + newline$
    .out$ = .out$ + "# nothing below this block names an object."
    ... + newline$
    for .k from 1 to .n
        .word$ = "steps "
        if not index (.steps$[.k], ",")
            .word$ = "step "
        endif
        .out$ = .out$ + "data" + string$ (.k) + "$ = """ + .name$[.k]
        ... + """   ; " + .word$ + .steps$[.k] + newline$
    endfor
    .out$ = .out$ + newline$

    label END_TABLE_MANIFEST
endproc

# ----------------------------------------------------------------------------
# @emlRecordRender
# Walk the buffer in order and build the whole file as one string.
#
# THE BLANK LINES ARE NOT COSMETIC. Every run of code carries a blank line
# before and after it, so the reader's eye finds what actually executes
# without parsing prose. In a file that is comment-heavy by design — and the
# narrative is the larger part by design — code without that separation
# disappears into it. Applied here, by the renderer, rather than left to
# whoever writes the next wrapper.
#
# Ordering inside a step is fixed: intent and caveat ABOVE the code, result
# and API equivalent BELOW it. A reader scanning for what ran finds an
# unbroken executable block; a reader who wants the reasoning finds it
# immediately above, and the outcome immediately below.
#
# Outputs: .text$ — the complete file
# ----------------------------------------------------------------------------
procedure emlRecordRender
    @emlRecordInit
    .text$ = ""
    .bar$ = "# ============================================================"
    .rule$ = "# ------------------------------------------------------------"

    ; THE FIRST TWO CHARACTERS HAVE TO BE `#!`, and that is not decoration.
    ; Praat's own documentation for `Read from file...` says it "recognizes
    ; script files if they begin with #!" -- so with this line the emitted
    ; file opens in a ScriptEditor, and without it Praat tries to read it as
    ; a data object. Confirmed 13 Aug 2026 under Xvfb: `Read from file:` on a
    ; file starting `#!` raises a window titled Script "<path>", with no file
    ; chooser and no error.
    ;
    ; That is what lets "Stop recording" put the script in front of the user
    ; in a real, editable, runnable editor -- author ruling 13 Aug 2026: the
    ; script must NEVER be printed into the Info window, which holds the
    ; analysis reports and is what Save Info writes.
    ;
    ; It is a legal Praat comment either way, so it costs nothing on the
    ; paths that only ever write the file.
    .text$ = .text$ + "#!praat" + newline$
    .text$ = .text$ + .bar$ + newline$
    .text$ = .text$ + "# EML Praat Tools -- recorded workflow" + newline$
    .text$ = .text$ + "# " + emlRecordStamp$
    ... + "  --  recorded on Praat " + emlRecordPraatVersion$ + newline$
    ; A RECOVERED STAMP IS LABELLED AS ONE. The session's own start time is
    ; lost when its meta table is removed from the Objects window; what the
    ; line above then carries is the time the recorder noticed, and a reader
    ; who is going to cite this file needs to know which of the two it is.
    if emlRecordStampRecovered = 1
        .text$ = .text$
        ... + "# (The session's start time was lost -- its record table was"
        ... + newline$
        .text$ = .text$
        ... + "# removed from the Objects window -- so the time above is when"
        ... + newline$
        .text$ = .text$
        ... + "# the recorder noticed, not when recording began.)" + newline$
    endif
    if emlRecordHeaderInput$ <> ""
        .text$ = .text$ + "# Input: " + emlRecordHeaderInput$
        if emlRecordHeaderShape$ <> ""
            .text$ = .text$ + " -- " + emlRecordHeaderShape$
        endif
        .text$ = .text$ + newline$
    endif
    .text$ = .text$ + .bar$ + newline$ + newline$

    ; ---- LIBRARY ---------------------------------------------------------
    ; ONE EDITABLE BLOCK. HOME-RELATIVE, NOT MACHINE-ABSOLUTE.
    ;
    ; `include` takes a LITERAL path -- no variable, no form field. But it
    ; DOES accept a leading `~`, tested 10 Aug 2026 on a path containing
    ; spaces (macOS's "Praat Prefs") under both 6.4.06 and 7.0. So the block
    ; below is portable across every user on this platform, and only the
    ; middle segment is platform- and version-specific.
    ;
    ; A CONDITIONAL INCLUDE WOULD SOLVE THE REST, AND DOES NOT WORK.
    ; Wrapping the two spellings in `if praatVersion >= 7000 ... else ...`
    ; looks like it works: a FALSE branch's include is skipped and the script
    ; runs to the end. That is a false positive -- nothing ran. Put the
    ; include in the TRUE branch and Praat refuses it:
    ;
    ;     Script line 4 not performed or completed:
    ;     « include ~/... »
    ;
    ; So the file carries the spelling for the version that recorded it and
    ; NAMES the others, because a failed parse cannot be caught by a guard --
    ; the guard would never run.
    ;
    ; THE FOLDER MOVED IN PRAAT 7. Measured on this machine:
    ;     6.6.30  ->  ~/.praat-dir
    ;     7.0     ->  ~/.config/praat
    ; which is why the version that recorded the session is stated above and
    ; the known locations are listed below.
    ;
    ; AND THE HEADER SAYS WHICH ONE IT GOT (NEW-G11-1, 14 Aug 2026).
    ;
    ; This block used to claim "Paths are home-relative, so they work for any
    ; user on this platform" unconditionally, above eleven absolute
    ; /home/<someone>/... include lines. Two separate things were wrong and
    ; only one of them was the claim: the home-relative rewrite was computed
    ; in @emlRecordBegin's scope and never survived to the flush, so in real
    ; menu-driven use the paths were ALWAYS absolute and the sentence was
    ; ALWAYS false. That half is fixed at the source -- the resolved root now
    ; lives in the meta object.
    ;
    ; The other half is that the claim cannot be true everywhere and must
    ; therefore be conditional. A plugin installed outside the user's home --
    ; a shared machine, a lab image, this repository's own harnesses running
    ; under --pref-dir=/tmp -- has no tilde to write, and a file that promises
    ; portability it does not have sends its reader looking for the wrong
    ; fault. So the sentence is chosen from the path that was actually
    ; emitted, which is the only way it can be checked by reading the file.
    .homeRel = 0
    if left$ (emlRecordPluginRoot$, 1) = "~"
        .homeRel = 1
    endif
    .text$ = .text$ + .rule$ + newline$
    .text$ = .text$ + "# THE EML LIBRARY" + newline$
    if .homeRel = 1
        .text$ = .text$
        ... + "# Recorded under Praat " + emlRecordPraatVersion$
        ... + ". Paths are home-relative, so they work" + newline$
        .text$ = .text$
        ... + "# for any user on this platform. If this file fails to parse, the"
        ... + newline$
        .text$ = .text$
        ... + "# plugin is somewhere else -- edit this block and nothing else."
        ... + newline$
    else
        .text$ = .text$
        ... + "# Recorded under Praat " + emlRecordPraatVersion$
        ... + ". These paths are ABSOLUTE to the machine" + newline$
        .text$ = .text$
        ... + "# that recorded this session: the plugin does not sit under a"
        ... + newline$
        .text$ = .text$
        ... + "# home folder here, so there is no ~ to write and this file is"
        ... + newline$
        .text$ = .text$
        ... + "# NOT portable as it stands. To run it anywhere else you must"
        ... + newline$
        .text$ = .text$
        ... + "# edit this block and nothing else -- the usual locations are"
        ... + newline$
        .text$ = .text$
        ... + "# listed below." + newline$
    endif
    .text$ = .text$ + "#" + newline$
    .text$ = .text$
    ... + "#   Praat 6.x  Linux    ~/.praat-dir/plugin_EML_Praat_Tools"
    ... + newline$
    .text$ = .text$
    ... + "#   Praat 7.x  Linux    ~/.config/praat/plugin_EML_Praat_Tools"
    ... + newline$
    .text$ = .text$
    ... + "#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EML_Praat_Tools"
    ... + newline$
    .text$ = .text$
    ... + "#   Windows    ~/Praat/plugin_EML_Praat_Tools"
    ... + newline$
    .text$ = .text$
    ... + "#   Not sure?  Run  writeInfoLine: preferencesDirectory$"
    ... + newline$
    .text$ = .text$ + "#" + newline$
    .text$ = .text$
    ... + "# A version guard cannot help here: `include` is refused inside an"
    ... + newline$
    .text$ = .text$
    ... + "# if-block, so the file cannot choose its own path at run time."
    ... + newline$
    .text$ = .text$
    ... + "# The barrel eml-lib-stats.praat will NOT work in place of this"
    ... + newline$
    .text$ = .text$
    ... + "# list: its own relative includes resolve against THIS file's"
    ... + newline$
    .text$ = .text$ + "# folder, not its own." + newline$
    .text$ = .text$ + .rule$ + newline$ + newline$

    .p$ = emlRecordPluginRoot$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-core-utilities.praat"
    ... + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-core-descriptive.praat"
    ... + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-extract.praat" + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-output.praat" + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-inferential.praat"
    ... + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-result-writer.praat"
    ... + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-record.praat" + newline$
    .text$ = .text$ + "include " + .p$ + "/graphs/eml-graph-procedures.praat"
    ... + newline$
    .text$ = .text$ + "include " + .p$
    ... + "/graphs/eml-annotation-procedures.praat" + newline$
    ; The DRAW layer. Omitted from the first cut of this list, which meant a
    ; recorded FIGURE emitted a script that could not run --
    ; "Procedure emlDrawViolinPlot not found" -- while a recorded ANALYSIS
    ; emitted one that could. Caught by harness/record/roundtrip_graph.sh on
    ; its first run, which is the entire reason that check exists: the list
    ; is hand-maintained, so nothing but a replay can prove it complete.
    .text$ = .text$ + "include " + .p$ + "/graphs/eml-draw-procedures.praat"
    ... + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-analysis.praat"
    ... + newline$
    .text$ = .text$ + newline$

    ; INITIALISE THE DRAWING DEFAULTS. Every real caller does this before it
    ; draws, and the emitted file is a real caller. Omitting it made a
    ; recorded FIGURE emit a script that died on "Unknown variable:
    ; emlSubtitle$" -- a global the draw layer reads and this procedure sets.
    ; Caught by harness/record/roundtrip_graph.sh, one failure after it caught
    ; the missing draw-layer include.
    ;
    ; Called unconditionally rather than only for sessions that drew: it is
    ; idempotent, it costs nothing in an analysis-only file, and a condition
    ; here would be one more thing that can be wrong in a file whose whole
    ; purpose is to run somewhere else.
    .text$ = .text$ + "@emlInitDrawingDefaults" + newline$
    ; AND CLEAR THE ANNOTATION STATE. The graphs form calls this before every
    ; draw; an emitted file that carries an annotated figure has to call it
    ; too, or the first bridge in the file adds its bracket to whatever
    ; annotBracketN happened to be in the scope that included this file.
    ; Idempotent, and it costs an analysis-only file one line.
    .text$ = .text$ + "@emlClearAnnotations" + newline$ + newline$

    ; ---- THE OBJECT ------------------------------------------------------
    ; No form, no infile. The session's analyses ran on an object the user
    ; had selected, and so does this file. What the header states is WHICH
    ; object that was, by name and shape, because "whatever is selected"
    ; gives a reader no way to check they selected the right thing.
    .text$ = .text$ + .rule$ + newline$
    .text$ = .text$ + "# THE OBJECT" + newline$
    if emlRecordHeaderInput$ <> ""
        .text$ = .text$ + "# Recorded against: " + emlRecordHeaderInput$
        if emlRecordHeaderShape$ <> ""
            .text$ = .text$ + " -- " + emlRecordHeaderShape$
        endif
        .text$ = .text$ + "." + newline$
    else
        .text$ = .text$
        ... + "# NOT RECORDED. Nothing in this session named the object it"
        ... + newline$
        .text$ = .text$
        ... + "# ran on, so a reader cannot check that the right Table is"
        ... + newline$
        .text$ = .text$
        ... + "# selected before running this file." + newline$
    endif
    .text$ = .text$
    ... + "# The objects this workflow ran on are named in the block below."
    ... + newline$
    .text$ = .text$
    ... + "# All of them must be open before you run this script."
    ... + newline$
    if emlRecordAmbiguousName = 1
        .text$ = .text$
        ... + "# WARNING: more than one Table shared a name during this"
        ... + newline$
        .text$ = .text$
        ... + "# session. Selecting by name picks the most recently created"
        ... + newline$
        .text$ = .text$
        ... + "# one, so a step below may not run on the object it recorded."
        ... + newline$
    endif
    .text$ = .text$ + .rule$ + newline$ + newline$

    ; ---- THE TABLE MANIFEST ----------------------------------------------
    ;
    ; A session that stayed on ONE object emits nothing here and keeps the
    ; contract it has always had: run it with that Table selected. A session
    ; that MOVED gets a named block instead, and it is the reason this is a
    ; block and not a select scattered through the body.
    ;
    ; The point is EDITING. Re-pointing a recorded workflow at next month's
    ; data should be one visible place near the top, not a hunt through the
    ; steps for every mention of an object. So the names are variables, each
    ; carrying an inline note saying which steps used it, and nothing below
    ; ever writes an object name again.
    ;
    ; INLINE COMMENTS USE `;` AND NOT `#`. Measured 12 Aug 2026 on 6.6.30:
    ; a trailing `;` comment after code parses, a trailing `#` does not --
    ; `table2$ = "voiceB"   # step 2` fails with
    ;     Error: Unknown symbol: « "voiceB"   #
    ; The manifest is the only place in an emitted file that puts a comment
    ; on the same line as code, which is why this is written down here.
    @emlRecordTableManifest
    .text$ = .text$ + emlRecordTableManifest.out$

    ; THERE IS NO LONGER A NO-MANIFEST PATH. Every session that recorded a
    ; source gets the block, and every step selects through it. A session
    ; that recorded NO source at all -- a refusal before anything was read --
    ; emits neither, and its steps select nothing, which is correct.

    ; ---- BODY ------------------------------------------------------------
    selectObject: emlRecordBufferId
    .nSteps = Get number of rows
    .manifestN = emlRecordTableManifest.n
    for .s from 1 to .nSteps
        selectObject: emlRecordBufferId
        .n = Get value: .s, "n"
        .kind$ = Get value: .s, "kind"
        .intent$ = Get value: .s, "intent"
        .caveat$ = Get value: .s, "caveat"
        .code$ = Get value: .s, "code"
        .result$ = Get value: .s, "result"
        .api$ = Get value: .s, "api"
        .source$ = Get value: .s, "source"
        .derived$ = Get value: .s, "derived"
        .env$ = Get value: .s, "env"
        .post$ = Get value: .s, "post"

        ; A refused step and a successful one must be distinguishable at a
        ; glance, so the separator carries the kind rather than only a number.
        .text$ = .text$ + "# --- Step " + string$ (.n) + " ("
        ... + .kind$ + ") ---" + newline$

        ; THE SELECT, EMITTED ONLY WHERE THE OBJECT CHANGES, AND ALWAYS
        ; THROUGH THE MANIFEST.
        ;
        ; The body never writes an object name. It writes tableN$, which the
        ; block at the top defines, so re-pointing this workflow at other
        ; data is one edit in one visible place rather than a hunt through
        ; the steps. That is the whole reason the manifest is a block.
        ;
        ; A session that stayed on ONE object has no manifest and emits
        ; nothing here: the `table = selected ("Table")` line above is the
        ; whole of its object handling, exactly as before.
        ; EVERY STEP SELECTS, AND NOT ONLY WHERE THE OBJECT CHANGED.
        ;
        ; Selecting only on change is shorter and is a bet that nothing
        ; between two steps disturbs the selection. That bet has already
        ; lost once in this plugin: `removeObject:` leaves NOTHING selected,
        ; which is how six disclosure cases died on 11 Aug when a helper
        ; started using it. An analysis is free to select whatever it likes
        ; while it works, and the emitted script has no way to know.
        ;
        ; Two idempotent lines per step buys immunity from that whole class,
        ; and the variable is `data` rather than `table` because the object
        ; may be a Matrix or a TableOfReal.
        ; A step on an auto-converted object selects NOTHING: the convert
        ; step above it left that object in `data`, and the manifest names
        ; the Sound it came from, not the intermediate that no longer exists.
        if .source$ <> "" and .derived$ <> "1"
            .slot = 0
            for .k from 1 to .manifestN
                if emlRecordTableManifest.name$[.k] = .source$
                    .slot = .k
                endif
            endfor
            if .slot > 0
                .text$ = .text$ + "selectObject: data" + string$ (.slot)
                ... + "$" + newline$
                .text$ = .text$ + "data = selected ()" + newline$
            endif
        endif

        @emlRecordCommentBlock: .intent$
        .text$ = .text$ + emlRecordCommentBlock.out$
        if .caveat$ <> ""
            @emlRecordCommentBlock: .caveat$
            .text$ = .text$ + emlRecordCommentBlock.out$
        endif

        .text$ = .text$ + newline$

        ; THE SETTINGS FIRST, THEN THE CALL, THEN WHAT THE FORM DREW AFTER IT.
        ; All three are the step -- see @emlRecordCaptureEnv. The blank-line
        ; discipline stays: one unbroken executable block per step, so a
        ; reader scanning for what ran still finds it in one piece.
        if .env$ <> ""
            .text$ = .text$ + .env$
        endif

        ; ---- THE SAVE STEP IS REWRITTEN TO ITS NON-INTERACTIVE TWIN --------
        ;
        ; AUTHOR RULING, 14 August 2026: a replayed recording must not reopen
        ; any dialog. "Just output the output." This is the SPSS model, and
        ; Stata's, and R's, and Praat's own: a dialog AUTHORS syntax, and
        ; running the syntax is headless. A user who wants different settings
        ; runs the workflow fresh; they do not run the recording.
        ;
        ; The save step is recorded by @emlSavePanel's own caller as a call
        ; back into @emlSavePanel -- which is the panel, so replaying a
        ; recorded workflow stopped dead at a dialog. It also re-proposed a
        ; base name of "old stem + new stamp", so each replay generation grew
        ; another timestamp: demo_two-group_20260815_013159_20260815_014836_*
        ; and so on. That defect (NEW-G11-5) is not patched here, it is
        ; DISSOLVED: the twin below strips the recorded stamp and takes a
        ; fresh one, so a replay names its outputs after the replay and the
        ; name cannot accrete.
        ;
        ; REWRITTEN HERE, IN THE RENDERER, rather than at the call site. The
        ; call site is @emlSavePanel's own caller in stats/eml-output.praat,
        ; which is the one place that legitimately knows about the panel. The
        ; recorder owns what the emitted file SAYS, and "what this step means
        ; when it is replayed" is exactly that. One substitution, one place.
        .codeOut$ = .code$
        if .kind$ = "save"
            .codeOut$ = replace$ (.codeOut$, "@emlSavePanel:",
            ... "@emlRecordReplaySave:", 0)
        endif
        .text$ = .text$ + .codeOut$ + newline$

        if .post$ <> ""
            .text$ = .text$ + .post$
        endif

        .text$ = .text$ + newline$

        if .result$ <> ""
            @emlRecordCommentBlock: .result$
            .text$ = .text$ + emlRecordCommentBlock.out$
        endif
        if .api$ <> ""
            .text$ = .text$
            ... + "# The same step through the menu:" + newline$
            @emlRecordCommentBlock: .api$
            .text$ = .text$ + emlRecordCommentBlock.out$
        endif
        .text$ = .text$ + newline$
    endfor
endproc


# ----------------------------------------------------------------------------
# @emlRecordFlush: .outPath$
# Render and write. Does NOT stop the recording — the proposal asks for flush
# on demand as well as flush on stop, and a flush that silently ended the
# session would make the on-demand case a trap.
# Outputs: .written — 1 on success, 0 if nothing was recorded
# ----------------------------------------------------------------------------
procedure emlRecordFlush: .outPath$
    @emlRecordInit
    .written = 0
    if emlRecordActive = 0
        goto RECORD_FLUSH_DONE
    endif
    if emlRecordN < 1
        goto RECORD_FLUSH_DONE
    endif
    @emlRecordRender
    writeFileLine: .outPath$, emlRecordRender.text$
    .written = 1

    label RECORD_FLUSH_DONE
endproc


# ----------------------------------------------------------------------------
# @emlRecordMakeFolder: .path$
#
# createFolder: IS mkdir, NOT mkdir -p, and the difference cost a session.
#
# Measured on 6.6.30, 14 Aug 2026: `createFolder: "/tmp/x/a/b/c"` with none of
# a, b, c present creates NOTHING and raises an error -- it does not walk the
# path. Every caller in this plugin that types a folder into a dialog can be
# handed a path two levels deep that does not exist yet, because typing one is
# the natural thing to do when you want this study's outputs in their own
# folder.
#
# So the ancestors are created explicitly, left to right, and every step is
# `nocheck`: an ancestor that cannot be made (a drive root, a path element
# that is really a file) is not by itself a failure, and neither is the leaf,
# because this procedure does not get to decide. It is BEST EFFORT, and both
# callers follow it with a real write probe -- the only test that answers the
# question that actually matters, which is not "does this folder exist" but
# "can this folder be written to".
#
# AND `nocheck` CANNOT BE USED ON THE CALL. Measured on 6.6.30, 14 Aug 2026:
# `nocheck @someProcedure: arg` does not run the procedure at ALL -- it is not
# an error suppressor there, it is a skip. The first cut of the two callers
# wrapped this procedure that way to keep a bad path from aborting them, and
# the effect was that no folder was ever created and the write probe below
# refused every save. So the suppression lives INSIDE, per command, and the
# callers call it plainly.
# ----------------------------------------------------------------------------
procedure emlRecordMakeFolder: .path$
    .p$ = .path$
    while endsWith (.p$, "/") and length (.p$) > 1
        .p$ = left$ (.p$, length (.p$) - 1)
    endwhile
    if .p$ = "" or .p$ = "/"
        goto END_RECORD_MAKE_FOLDER
    endif
    ; From 2, so a leading "/" is never offered on its own.
    for .i from 2 to length (.p$)
        if mid$ (.p$, .i, 1) = "/"
            .anc$ = left$ (.p$, .i - 1)
            if .anc$ <> "" and not endsWith (.anc$, ":")
                nocheck createFolder: .anc$
            endif
        endif
    endfor
    nocheck createFolder: .p$
    label END_RECORD_MAKE_FOLDER
endproc


# ----------------------------------------------------------------------------
# @emlRecordStripStamp: .name$   ->  .result$
#
# Remove one trailing _YYYYMMDD_HHMMSS, and only one.
#
# The stamp is @emlFileStamp's format and nothing else's, so the pattern is
# anchored and exact rather than "anything that looks like digits". A base
# name a user typed themselves -- "pre_post_2026" -- is not a stamp and is
# left alone, which the anchoring is what guarantees.
# ----------------------------------------------------------------------------
procedure emlRecordStripStamp: .name$
    .result$ = replace_regex$ (.name$, "_[0-9]{8}_[0-9]{6}$", "", 0)
endproc


# ----------------------------------------------------------------------------
# @emlRecordReplaySave: .offerFigure, .stem$, .folder$
#
# THE NON-INTERACTIVE TWIN OF @emlSavePanel, and the whole of the author's
# 14 August 2026 ruling in one procedure.
#
#   "Recorder replay: NON-INTERACTIVE -- just output the output. A replayed
#    recording must not reopen any dialog. This is the SPSS model (dialogs
#    author syntax; running syntax is headless), same as Stata do-files /
#    R scripts / Praat's own paradigm."
#
# WHAT IT COSTS, stated because it is a real cost and the ruling accepts it:
# a replayed save writes wherever the recording was made. The folder and the
# base name are literals in the emitted file, on their own line, editable --
# and a user who wants somewhere else edits that line or runs the workflow
# fresh. The alternative is the panel reopening, which is what made a recorded
# workflow unrunnable unattended.
#
# THE TIMESTAMP IS REGENERATED, NOT REPLAYED, and that is the ruling's second
# bullet. A recorded stem carries the stamp of the session that recorded it;
# replaying it would either overwrite that session's outputs or -- what the
# panel actually did -- append a second stamp to the first, so names grew by
# sixteen characters per replay generation. Stripping the recorded stamp and
# taking a fresh one makes a replay's outputs the replay's, dated when they
# were made, and removes the accretion (NEW-G11-5) rather than bounding it.
#
# THE COLLISION RULE IS THE PANEL'S, NOT THE RECORDER'S. One stamp per press,
# shared by every file the press writes, and the STEM is uniqued -- never the
# individual files -- against every name this call could write. That is the
# author's 14 August condition and the reason is in @emlSavePanel: three
# independent collision behaviours in one save produced <stem>_1.png beside
# <stem>_1_tidy.csv beside an overwritten <stem>_report.txt.
#
# 300 dpi, because the panel's DPI switch is a dialog field and there is no
# dialog. It is the panel's own default and the figure is redrawable at any
# resolution by re-running the step above.
#
# Outputs: .nWritten, .fileList$
# ----------------------------------------------------------------------------
procedure emlRecordReplaySave: .offerFigure, .stem$, .folder$
    .nWritten = 0
    .fileList$ = ""

    while endsWith (.folder$, "/") and length (.folder$) > 1
        .folder$ = left$ (.folder$, length (.folder$) - 1)
    endwhile
    ; MADE ALL THE WAY DOWN, AND THEN PROVED. The recorded folder may not
    ; exist on the machine replaying this file -- that is the ordinary case,
    ; not the exceptional one -- and createFolder: is mkdir, not mkdir -p.
    ; The probe is a real write, because a folder that exists and a folder
    ; that can be written to are different questions and only the second one
    ; matters here. A replay that cannot write says so in one sentence and
    ; returns; it does not abort the script with the plugin's own source
    ; quoted back at the reader (NEW-G11-4).
    @emlRecordMakeFolder: .folder$
    .probe$ = .folder$ + "/.eml_record_write_probe"
    nocheck deleteFile: .probe$
    nocheck writeFileLine: .probe$, "eml"
    if not fileReadable (.probe$)
        appendInfoLine: ""
        appendInfoLine: "EML: this recorded save could not write to"
        appendInfoLine: .folder$
        appendInfoLine: "Nothing was written for this step. Edit the"
        appendInfoLine: "outputFolder$ line above it and run the file again."
        goto END_RECORD_REPLAY_SAVE
    endif
    nocheck deleteFile: .probe$

    @emlRecordStripStamp: .stem$
    .base$ = emlRecordStripStamp.result$
    if .base$ = ""
        .base$ = "eml_results"
    endif
    @emlFileStamp
    .stem$ = .base$ + "_" + emlFileStamp.result$

    ; ONE FREE STEM, tested against every name this call could write whether
    ; or not it ends up writing it -- the panel's rule, and for the panel's
    ; reason: a stem that is free only because this session produced no CSVs
    ; would give two different base names for the same analysis depending on
    ; what the analysis happened to make.
    .try$ = .stem$
    .n = 0
    label RECORD_REPLAY_STEM_FREE
    .taken = 0
    if fileReadable (.folder$ + "/" + .try$ + ".png")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_legend.png")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_tidy.csv")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_glance.csv")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + ".csv")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_report.txt")
        .taken = 1
    endif
    if .taken = 1
        .n = .n + 1
        .try$ = .stem$ + "_" + string$ (.n)
        goto RECORD_REPLAY_STEM_FREE
    endif
    .stem$ = .try$

    ; --- the figure -------------------------------------------------------
    if .offerFigure = 1
        .figPath$ = .folder$ + "/" + .stem$ + ".png"
        @emlAssertFullViewport
        Save as 300-dpi PNG file: .figPath$
        .nWritten = .nWritten + 1
        .fileList$ = .fileList$ + .figPath$ + newline$
        if variableExists ("emlLegendSepActive")
            if emlLegendSepActive = 1
                .legPath$ = .folder$ + "/" + .stem$ + "_legend.png"
                Select outer viewport: emlLegendSepX0, emlLegendSepX1,
                ... emlLegendSepY0, emlLegendSepY1
                Save as 300-dpi PNG file: .legPath$
                @emlAssertFullViewport
                .nWritten = .nWritten + 1
                .fileList$ = .fileList$ + .legPath$ + newline$
            endif
        endif
    endif

    ; --- the numbers ------------------------------------------------------
    ; Both halves count, exactly as the panel counts them: a converted
    ; analysis declares into the broom collectors, an unconverted one fills
    ; the legacy buffer, and @emlExportResultFiles forks between them.
    # ASK, DO NOT RE-DERIVE. Both halves count -- a converted analysis declares
    # into the broom collectors, an unconverted one fills the legacy buffer --
    # but which flags mean that is eml-output.praat's knowledge, not ours. v46
    # pins it: only that file may branch on the migration state, so that the day
    # the migration finishes there is one reader to update rather than two that
    # can drift apart in silence. This writer needs the same answer the panel
    # needs; it asks the same procedure.
    @emlHaveExportableResult
    .haveCSV = emlHaveExportableResult.result
    if .haveCSV = 1
        @emlExportResultFiles: .folder$, .stem$
        .nWritten = .nWritten + emlExportResultFiles.nWritten
        .fileList$ = .fileList$ + emlExportResultFiles.fileList$
        if right$ (.fileList$, 1) <> newline$
            .fileList$ = .fileList$ + newline$
        endif
    endif

    ; --- the report -------------------------------------------------------
    ; WRITTEN BEFORE THE RECEIPT, or the receipt lands inside the report:
    ; info$ () is the whole Info window, which is what the panel writes too.
    .txtPath$ = .folder$ + "/" + .stem$ + "_report.txt"
    @emlSaveInfoToFile: .txtPath$
    if emlSaveInfoToFile.success = 1
        .nWritten = .nWritten + 1
        .fileList$ = .fileList$ + emlSaveInfoToFile.actualPath$ + newline$
    endif

    ; --- say what happened, without asking anything ------------------------
    appendInfoLine: ""
    appendInfoLine: "EML: replayed save -- wrote ", .nWritten, " file(s) to"
    appendInfoLine: .folder$
    appendInfoLine: "base name ", .stem$

    label END_RECORD_REPLAY_SAVE
endproc
