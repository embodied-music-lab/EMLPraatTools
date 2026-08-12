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
# emlRecordBufferId   Table: one row per step
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

        endif
    endif
    if not variableExists ("emlRecordPluginRoot$")
        emlRecordPluginRoot$ = preferencesDirectory$ + "/plugin_EMLPraatTools"
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
    Create Table with column names: "emlRecordBuffer", 0,
    ... "n kind intent caveat code result api paths source"
    emlRecordBufferId = selected ("Table")

    ; The include block's path. Resolved at run time from
    ; preferencesDirectory$, then rewritten HOME-RELATIVE, because Praat's
    ; `include` accepts a leading ~ -- tested 10 Aug 2026, including a path
    ; with spaces in it (macOS's "Praat Prefs") and under both 6.4.06 and
    ; 7.0. That one substitution takes the emitted file from
    ; one-machine to any-user-on-this-platform, for free.
    .abs$ = preferencesDirectory$ + "/plugin_EMLPraatTools"
    emlRecordPluginRoot$ = .abs$
    if homeDirectory$ <> ""
        if index (.abs$, homeDirectory$) = 1
            emlRecordPluginRoot$ = "~"
            ... + mid$ (.abs$, length (homeDirectory$) + 1, 100000)
        endif
    endif
    emlRecordPraatVersion$ = praatVersion$
    emlRecordPraatVersion = praatVersion

    emlRecordN = 0
    emlRecordActive = 1
    emlRecordHeaderInput$ = ""
    emlRecordSourceChanged = 0
    emlRecordTempPath$ = ""
    if .tempFolder$ <> ""
        emlRecordTempPath$ = .tempFolder$ + "/eml_record_mirror.txt"
        writeFileLine: emlRecordTempPath$,
        ... "# EML record workflow -- crash mirror. Rows are appended as they"
        appendFileLine: emlRecordTempPath$,
        ... "# are recorded, so a session lost to a crash is still readable."
    endif
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
    emlRecordBufferId = 0
    emlRecordN = 0
    emlRecordActive = 0
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
    emlRecordStamp$ = .stamp$
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

    ; Rows and columns are for the header note only. Every accepted type
    ; answers both, so this needs no branch either.
    .rows = Get number of rows
    .cols = Get number of columns

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
    elsif emlRecordHeaderInput$ <> .name$
        .changed = 1
        emlRecordSourceChanged = 1
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
    .dupes = 0
    select all
    .total = numberOfSelected ()
    for .o from 1 to .total
        if selected$ (.o) = "Table " + .name$
            .dupes = .dupes + 1
        endif
    endfor
    if .dupes > 1
        emlRecordAmbiguousName = 1
    endif
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
    ... .code$, .api$, .error$
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
    ... .api$
    @emlRecordInit
    if emlRecordActive = 0
        goto END_RECORD_DRAW_STEP
    endif

    @emlRecordSource: .objectId
    @emlPhrase: "drawstep.intent", .label$, .detail$, "", "", "", ""
    @emlRecordStep: "draw", emlPhrase.result$, .caveat$, .code$, .api$

    label END_RECORD_DRAW_STEP
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
    Set string value: .row, "result", ""
    Set string value: .row, "api", .api$
    Set string value: .row, "paths", ""
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

    .text$ = .text$ + .bar$ + newline$
    .text$ = .text$ + "# EML Praat Tools -- recorded workflow" + newline$
    .text$ = .text$ + "# " + emlRecordStamp$
    ... + "  --  recorded on Praat " + emlRecordPraatVersion$ + newline$
    if emlRecordHeaderInput$ <> ""
        .text$ = .text$ + "# Input: " + emlRecordHeaderInput$ + " -- "
        ... + string$ (emlRecordHeaderRows) + " rows, "
        ... + string$ (emlRecordHeaderCols) + " columns" + newline$
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
    .text$ = .text$ + .rule$ + newline$
    .text$ = .text$ + "# THE EML LIBRARY" + newline$
    .text$ = .text$
    ... + "# Recorded under Praat " + emlRecordPraatVersion$
    ... + ". Paths are home-relative, so they work" + newline$
    .text$ = .text$
    ... + "# for any user on this platform. If this file fails to parse, the"
    ... + newline$
    .text$ = .text$
    ... + "# plugin is somewhere else -- edit this block and nothing else."
    ... + newline$
    .text$ = .text$ + "#" + newline$
    .text$ = .text$
    ... + "#   Praat 6.x  Linux    ~/.praat-dir/plugin_EMLPraatTools"
    ... + newline$
    .text$ = .text$
    ... + "#   Praat 7.x  Linux    ~/.config/praat/plugin_EMLPraatTools"
    ... + newline$
    .text$ = .text$
    ... + "#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EMLPraatTools"
    ... + newline$
    .text$ = .text$
    ... + "#   Windows    ~/Praat/plugin_EMLPraatTools"
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
    .text$ = .text$ + "@emlInitDrawingDefaults" + newline$ + newline$

    ; ---- THE OBJECT ------------------------------------------------------
    ; No form, no infile. The session's analyses ran on an object the user
    ; had selected, and so does this file. What the header states is WHICH
    ; object that was, by name and shape, because "whatever is selected"
    ; gives a reader no way to check they selected the right thing.
    .text$ = .text$ + .rule$ + newline$
    .text$ = .text$ + "# THE OBJECT" + newline$
    if emlRecordHeaderInput$ <> ""
        .text$ = .text$ + "# Recorded against: " + emlRecordHeaderInput$
        ... + " -- " + string$ (emlRecordHeaderRows) + " rows, "
        ... + string$ (emlRecordHeaderCols) + " columns." + newline$
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
        if .source$ <> ""
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

        .text$ = .text$ + .code$ + newline$

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
