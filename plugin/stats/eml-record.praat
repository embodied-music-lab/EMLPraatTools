# ============================================================================
# EML Praat Tools — Record workflow: buffer, paths, phrases, renderer
# ============================================================================
# Purpose: accumulate every analysis and drawing step of a session and write
#          it out as a single annotated Praat script — one artifact that both
#          re-runs and reads like a lab notebook.
#
# Date: 9 August 2026
# Version: 1.0
#
# THIS FILE IS THE FOUNDATION ONLY. It is the buffer, the path registry, the
# phrase table, the renderer and the flush. It deliberately does NOT touch a
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
# None of that survived test on 9 Aug 2026 in Praat 6.6.30.
#
#   1. Praat wrote UTF-8, not UTF-16BE. A generated script containing an
#      emoji and two box-drawing characters came out as UTF-8 and RAN:
#          file: Unicode text, UTF-8 text
#          run:  EMOJI SCRIPT RAN
#
#   2. Even when Praat does choose UTF-16, that is Praat's business. It reads
#      back what it writes. A UTF-16 script is a perfectly good Praat script,
#      so there was never a defect to defend against — only an encoding
#      choice made by the layer that owns encoding.
#
#   3. unicodeToBackslashTrigraphs$() is NOT the exhaustive one-call fix it
#      was briefly claimed to be. It converts characters Praat has trigraphs
#      for and passes everything else through untouched. Measured:
#          \o:  3 -> 1  converted      \em  3 -> 3  no such trigraph
#          \-m  3 -> 1  converted      \>=  3 -> 3  no such trigraph
#          \xx  3 -> 1  converted
#      A round-trip test on an unrecognised trigraph reports "lossless" while
#      converting nothing, which is how the claim passed review the first
#      time. It did not survive being asked whether conversion had HAPPENED.
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
# emlRecordPathsId    Table: one row per distinct path
# emlRecordPhraseId   Table: the shipped phrase registry
# emlRecordN          steps recorded so far
# emlRecordTempPath$  crash mirror, appended per row
# ============================================================================


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
    if not variableExists ("emlRecordPathsId")
        emlRecordPathsId = 0
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
    ... "n kind intent caveat code result api paths"
    emlRecordBufferId = selected ("Table")

    Create Table with column names: "emlRecordPaths", 0,
    ... "token literal role varName"
    emlRecordPathsId = selected ("Table")

    emlRecordN = 0
    emlRecordActive = 1
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
    if emlRecordPathsId > 0
        nocheck removeObject: emlRecordPathsId
    endif
    emlRecordBufferId = 0
    emlRecordPathsId = 0
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
# @emlRecordPath: .literal$, .role$
# Register a path and get back the TOKEN that stands for it in a step's code
# slot. Called every time a path is seen; the registry de-duplicates.
#
# WHY A TOKEN AND NOT THE LITERAL. The paths block at the top of the emitted
# file cannot be written while recording, because the full set of inputs and
# outputs is not known until the session ends. So the body stores tokens and
# flush resolves them. This is the difference between a paths block that is
# complete and one that is a best effort.
#
# Arguments:
#   .literal$ — the path as it was actually used
#   .role$    — "plugin", "input", or "output"
# Outputs:
#   .token$   — e.g. "<<path2>>", to be embedded in a code line
#   .varName$ — the form variable that will carry it, e.g. "data_file$"
# ----------------------------------------------------------------------------
procedure emlRecordPath: .literal$, .role$
    @emlRecordInit
    .token$ = ""
    .varName$ = ""
    if emlRecordActive = 0
        goto RECORD_PATH_DONE
    endif

    selectObject: emlRecordPathsId
    .n = Get number of rows
    .found = 0
    for .i from 1 to .n
        selectObject: emlRecordPathsId
        .lit$ = Get value: .i, "literal"
        if .lit$ = .literal$
            .found = .i
        endif
    endfor

    if .found > 0
        selectObject: emlRecordPathsId
        .token$ = Get value: .found, "token"
        .varName$ = Get value: .found, "varName"
        goto RECORD_PATH_DONE
    endif

    ; New path. The variable name comes from the role and the ordinal WITHIN
    ; that role, not from the global order, so a file that reads two inputs
    ; and writes one output gets data_file$ / data_file_2$ / output_folder$
    ; rather than three numbers a reader has to trace.
    .inRole = 0
    for .i from 1 to .n
        selectObject: emlRecordPathsId
        .r$ = Get value: .i, "role"
        if .r$ = .role$
            .inRole = .inRole + 1
        endif
    endfor
    .inRole = .inRole + 1

    if .role$ = "plugin"
        .varName$ = "plugin_folder$"
    elsif .role$ = "output"
        .varName$ = "output_folder$"
    else
        .varName$ = "data_file$"
    endif
    if .inRole > 1
        .varName$ = replace$ (.varName$, "$", "", 0)
        ... + "_" + string$ (.inRole) + "$"
    endif

    .token$ = "<<path" + string$ (.n + 1) + ">>"
    selectObject: emlRecordPathsId
    Append row
    .row = Get number of rows
    Set string value: .row, "token", .token$
    Set string value: .row, "literal", .literal$
    Set string value: .row, "role", .role$
    Set string value: .row, "varName", .varName$

    label RECORD_PATH_DONE
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
    .text$ = .text$ + "# " + emlRecordStamp$ + newline$
    if emlRecordHeaderInput$ <> ""
        .text$ = .text$ + "# Input: " + emlRecordHeaderInput$ + " -- "
        ... + string$ (emlRecordHeaderRows) + " rows, "
        ... + string$ (emlRecordHeaderCols) + " columns" + newline$
    endif
    .text$ = .text$ + .bar$ + newline$ + newline$

    ; ---- PATHS -----------------------------------------------------------
    .text$ = .text$ + .rule$ + newline$
    .text$ = .text$ + "# PATHS" + newline$
    .text$ = .text$
    ... + "# Every path this file uses is asked for here and nowhere else."
    ... + newline$
    .text$ = .text$
    ... + "# The values shown are the ones recorded when the workflow ran."
    ... + newline$
    .text$ = .text$
    ... + "# On this machine, press OK. On another, browse to the equivalents."
    ... + newline$
    .text$ = .text$ + .rule$ + newline$ + newline$

    selectObject: emlRecordPathsId
    .nPaths = Get number of rows

    .text$ = .text$ + "form: ""Recorded workflow - confirm paths""" + newline$
    for .i from 1 to .nPaths
        selectObject: emlRecordPathsId
        .role$ = Get value: .i, "role"
        .lit$ = Get value: .i, "literal"
        .var$ = Get value: .i, "varName"
        ; Path fields are folder:/infile:/outfile:, NEVER sentence:, because
        ; a path field needs a browse button. The empty-folder trap that
        ; argues the other way -- a folder: left blank resolves to the
        ; current working directory rather than to nothing -- is closed by
        ; pre-populating every field, so none is ever empty.
        if .role$ = "input"
            .kw$ = "infile"
        else
            .kw$ = "folder"
        endif
        ; The label generates the variable name, and only the FIRST character
        ; is lowercased: "EML plugin folder" would give eML_plugin_folder$.
        ; So the label is derived from the variable we want, not chosen for
        ; prose.
        .label$ = replace$ (.var$, "$", "", 0)
        .label$ = replace$ (.label$, "_", " ", 0)
        .label$ = replace_regex$ (.label$, "^(.)", "\u\1", 1)
        .text$ = .text$ + "    " + .kw$ + ": """ + .label$ + """, """
        ... + .lit$ + """" + newline$
    endfor
    .text$ = .text$ + "endform" + newline$ + newline$

    ; ---- BODY ------------------------------------------------------------
    selectObject: emlRecordBufferId
    .nSteps = Get number of rows
    for .s from 1 to .nSteps
        selectObject: emlRecordBufferId
        .n = Get value: .s, "n"
        .kind$ = Get value: .s, "kind"
        .intent$ = Get value: .s, "intent"
        .caveat$ = Get value: .s, "caveat"
        .code$ = Get value: .s, "code"
        .result$ = Get value: .s, "result"
        .api$ = Get value: .s, "api"

        ; A refused step and a successful one must be distinguishable at a
        ; glance, so the separator carries the kind rather than only a number.
        .text$ = .text$ + "# --- Step " + string$ (.n) + " ("
        ... + .kind$ + ") ---" + newline$

        @emlRecordCommentBlock: .intent$
        .text$ = .text$ + emlRecordCommentBlock.out$
        if .caveat$ <> ""
            @emlRecordCommentBlock: .caveat$
            .text$ = .text$ + emlRecordCommentBlock.out$
        endif

        .text$ = .text$ + newline$

        ; Tokens become variable references here and only here.
        .codeOut$ = .code$
        for .i from 1 to .nPaths
            selectObject: emlRecordPathsId
            .tok$ = Get value: .i, "token"
            .var$ = Get value: .i, "varName"
            .codeOut$ = replace$ (.codeOut$, .tok$, .var$, 0)
        endfor
        .text$ = .text$ + .codeOut$ + newline$

        .text$ = .text$ + newline$

        if .result$ <> ""
            @emlRecordCommentBlock: .result$
            .text$ = .text$ + emlRecordCommentBlock.out$
        endif
        if .api$ <> ""
            .text$ = .text$
            ... + "# API equivalent, if you are writing your own script:"
            ... + newline$
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
