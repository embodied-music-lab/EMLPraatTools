# ============================================================================
# Batch Voice Analysis
# ============================================================================
# Purpose: Batch process a folder of Sound files to extract user-selected
#          acoustic measures (mean F0, mean intensity, jitter, shimmer, HNR,
#          CPPS), optionally constrained to labeled TextGrid intervals.
#          Results are exported to a CSV file with one row per analysis
#          segment.
# Date: 3 April 2026
# Version: 1.1
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
# Procedures
# ============================================================================

procedure emlBuildDateStamp
    .vec# = date# ()
    .year$ = string$ (.vec#[1])
    .month$ = right$ ("0" + string$ (.vec#[2]), 2)
    .day$ = right$ ("0" + string$ (.vec#[3]), 2)
    .result$ = .year$ + "-" + .month$ + "-" + .day$
endproc

procedure emlCheckStopSentinel: .sentinelPath$
    .shouldStop = 0
    if fileReadable (.sentinelPath$)
        .content$ = readFile$ (.sentinelPath$)
        .firstLine$ = extractWord$ (.content$, "")
        if index_caseInsensitive (.firstLine$, "stop") > 0
            .shouldStop = 1
        endif
    endif
endproc

procedure emlInitSentinel: .sentinelPath$
    writeFileLine: .sentinelPath$, "RUN"
    appendFileLine: .sentinelPath$, "---"
    appendFileLine: .sentinelPath$, "To stop processing after the current file,"
    appendFileLine: .sentinelPath$, "change the first line from RUN to STOP and save."
    appendFileLine: .sentinelPath$, "The script checks this file after each file completes."
endproc

# ────────────────────────────────────────────────────────────────────────────
# @emlSentinelIsOurs: .path$   →  .ours
# ────────────────────────────────────────────────────────────────────────────
# NEVER TRUNCATE SOMEONE ELSE'S FILE. @emlInitSentinel writes with
# writeFileLine:, which TRUNCATES. Until 14 August 2026 the sentinel path was
# hard-wired to <sound folder>/STOP.txt, so a user who kept their own STOP.txt
# — a note to a collaborator, a stop-word list, a marker file — lost it the
# moment they ran a batch: silently, with no prompt and no undo. The results
# CSV has walked to a free name on collision since S9; the sentinel did not.
# This procedure is the missing half of that protection.
#
# A path that does NOT exist is ours to make. A path that exists is ours only
# if its whole FIRST LINE is RUN or STOP — the line @emlInitSentinel writes and
# the one edit the Info window asks the user to make.
#
# THE FIRST LINE, NOT THE FIRST WORD, and that distinction is not theoretical:
# the first draft of this procedure tested the first word, and the end-to-end
# drive on 14 Aug 2026 destroyed a file whose first line was "Stop list for
# this study" — the very failure this exists to prevent, reproduced by the
# guard meant to stop it. A file that BEGINS with the word stop is exactly what
# a human writes in a file they name STOP.txt.
#
# `length = n and index_caseInsensitive (...) = 1` is then a WHOLE-LINE
# case-insensitive compare, deliberately stricter than @emlCheckStopSentinel's
# substring test: deciding whether to destroy a file is not the place to accept
# "stopwords" as evidence that we wrote it. "run", "Run" and "STOP" alone on
# the line are ours; "Running order" and "STOP — ask Ian first" are not.
#
# BLANKS EITHER SIDE ARE TRIMMED, because a text editor and a human both leave
# them, and because @emlCheckStopSentinel — the halt test on the same file —
# uses extractWord$ and so already ignores them. A file this script would STOP
# for must be a file this script is willing to own; disagreeing would leave a
# user whose "  STOP" halted one run watching the next run write STOP_2.txt.
#
# unicode$ (13) is trimmed with them as belt and braces only. Measured on
# 6.4.06, 14 Aug 2026: readFile$ normalises both CRLF and lone-CR line endings
# to newline$, so no CR survives to be seen — but the trim costs nothing and
# the day that stops being true is not a day to lose a file.
#
# AN EMPTY FILE IS NOT OURS. It is far more likely to be the user's placeholder
# than a sentinel of ours that died halfway through its first line, and the
# cost of being wrong is asymmetric: refusing a file we did write costs one
# extra STOP_2.txt, truncating a file we did not costs the user their data.
# ────────────────────────────────────────────────────────────────────────────
procedure emlSentinelIsOurs: .path$
    .ours = 1
    if fileReadable (.path$)
        .ours = 0
        .content$ = readFile$ (.path$)
        .nl = index (.content$, newline$)
        if .nl > 0
            .line$ = left$ (.content$, .nl - 1)
        else
            .line$ = .content$
        endif
        while length (.line$) > 0 and (right$ (.line$, 1) = " "
            ... or right$ (.line$, 1) = tab$
            ... or right$ (.line$, 1) = unicode$ (13))
            .line$ = left$ (.line$, length (.line$) - 1)
        endwhile
        while length (.line$) > 0 and (left$ (.line$, 1) = " "
            ... or left$ (.line$, 1) = tab$)
            .line$ = right$ (.line$, length (.line$) - 1)
        endwhile
        if length (.line$) = 3 and index_caseInsensitive (.line$, "run") = 1
            .ours = 1
        endif
        if length (.line$) = 4 and index_caseInsensitive (.line$, "stop") = 1
            .ours = 1
        endif
    endif
endproc

# ────────────────────────────────────────────────────────────────────────────
# @emlResolveSentinelPath: .folder$   →  .path$, .displaced
# ────────────────────────────────────────────────────────────────────────────
# THE SAME WALK THE CSV ALREADY DOES (Rule 27, S9): try the wanted name, and
# on collision append _2, _3, … until a name is acceptable. Deliberately the
# same shape, so there is one collision idiom in this file and not two.
#
# ONE DIFFERENCE, AND IT IS ON PURPOSE. The CSV's walk stops at a name that is
# FREE, because a previous run's results must never be overwritten. The
# sentinel's stops at a name that is free OR ALREADY OURS, because the sentinel
# is a control file we rewrite at the start of every run: if a foreign STOP.txt
# sits in the output folder and we insisted on a free name, every run would
# leave one more STOP_2.txt, STOP_3.txt … behind forever. Neither test can pick
# a foreign file, which is the property that matters.
#
# .displaced tells the caller the user's own STOP.txt was found and left alone,
# so the Info window can name the file they must actually edit to stop the run
# — a sentinel whose location the user cannot guess is a sentinel that does not
# work.
# ────────────────────────────────────────────────────────────────────────────
procedure emlResolveSentinelPath: .folder$
    .path$ = .folder$ + "/STOP.txt"
    .displaced = 0
    @emlSentinelIsOurs: .path$
    if emlSentinelIsOurs.ours = 0
        .displaced = 1
        .suffix = 2
        repeat
            .path$ = .folder$ + "/STOP_" + string$ (.suffix) + ".txt"
            .suffix = .suffix + 1
            @emlSentinelIsOurs: .path$
        until emlSentinelIsOurs.ours = 1
    endif
endproc

# ────────────────────────────────────────────────────────────────────────────
# @emlEnsureOutputFolder: .folder$, .probePath$   →  .writable
# ────────────────────────────────────────────────────────────────────────────
# THE FOLDER IS MADE, NOT ASSUMED — the same reasoning as @emlSavePanel in
# stats/eml-output.praat (14 Aug 2026): `folder:` is a freely editable text
# field with a Browse button beside it, so the user can type a path that does
# not exist yet, and typing one is the natural thing to do when you want this
# batch's results in their own folder.
#
# EVERY LEVEL IS MADE, NOT JUST THE LAST ONE. Measured on Praat 6.4.06,
# 14 Aug 2026: createFolder: creates ONE level — it is mkdir, not mkdir -p —
# and refuses outright when the parent is missing. "~/Documents/Study A/run 1"
# is exactly the kind of path a user types into this field, and typing the
# whole thing at once is the normal way to do it, so the parents are created
# here in turn. The scan is for BOTH separators, per the truth table at "Last
# path component of the sound folder": a folder typed on Windows arrives as
# "C:\Users\ian\Study A" and a scan for "/" alone would find no levels at all.
# A prefix ending in ":" is a drive root, which exists and is not ours to
# create, so it is skipped.
#
# WHY IT IS ALSO PROVED WRITABLE, which the save panel does not do. This script
# runs unattended for a long time, and the CSV is written at the END: a folder
# that cannot be written would otherwise be discovered after the whole batch
# had run, with the results in a Table and Praat's own error — "Cannot create
# file …" — as the only explanation. The probe is what turns every way this can
# fail — unmakeable path, read-only folder, full disk — into one message,
# before any audio is read.
#
# The probe is the sentinel itself rather than a scratch file: it is the first
# thing this script writes anyway, the caller has already resolved it to a path
# that is free or ours, and a scratch file would need its own collision walk
# not to delete something of the user's.
#
# nocheck GUARDS EXACTLY ONE COMMAND — the one it prefixes — and is used here
# so a refusal becomes a message this script can write instead of a Praat abort
# the user has to interpret. .writable is set BEFORE the nochecks and only
# raised inside an if, never assigned on the line following one (M4 in
# audit/static: a failing nocheck can corrupt the next assignment).
# ────────────────────────────────────────────────────────────────────────────
procedure emlEnsureOutputFolder: .folder$, .probePath$
    .writable = 0
    for .i from 1 to length (.folder$)
        .ch$ = mid$ (.folder$, .i, 1)
        if .ch$ = "/" or .ch$ = "\"
            .prefix$ = left$ (.folder$, .i - 1)
            if .prefix$ <> "" and right$ (.prefix$, 1) <> ":"
                nocheck createFolder: .prefix$
            endif
        endif
    endfor
    nocheck createFolder: .folder$
    nocheck writeFileLine: .probePath$, "RUN"
    if fileReadable (.probePath$)
        .writable = 1
    endif
endproc

# ============================================================================
# Initialize defaults
# ============================================================================

sound_folder$ = ""
file_extension$ = "wav"

# THE OUTPUT FOLDER, AND WHY ITS DEFAULT IS NOT THE SOUND FOLDER.
#
# AUTHOR RULING, 14 August 2026, verbatim: "re stop file, yes? To users output
# folder. Output folder is user designated. Not the input folder."
#
# Until that ruling this script wrote both of its files — STOP.txt and the
# results CSV — into the folder of recordings it was reading, which is the
# user's corpus and often someone else's shared data.
#
# THE DEFAULT IS PART OF THE RULING, not decoration. An empty default that
# falls back to the sound folder was considered and rejected: it would preserve
# today's behaviour for existing users at the price of re-creating the exact
# defect for every user who does not edit the field — and the users who do not
# edit fields are precisely the ones the truncation would surprise. A default
# is what most runs will actually use, so it has to be a folder the ruling
# allows.
#
# HOME, IN A NAMED FOLDER. homeDirectory$ exists and is writable on every
# platform Praat runs on, so the pre-filled path works with one click; it is
# outside the corpus, so nothing this script writes can ever land among the
# recordings; and the name says what is in it, so a user who has forgotten
# where their results went can find them. It is also exactly ONE level below a
# folder that is certain to exist, so the default is creatable by the plainest
# possible means and never leans on the ancestor-creating loop in
# @emlEnsureOutputFolder, which exists for the paths users type by hand.
#
# NOT preferencesDirectory$, though the plugin uses it for the review copies in
# eml-record-open.praat (13 Aug 2026). That folder is for things the plugin
# owns and the user is not meant to keep; a batch's results are the deliverable
# and belong where a user will look for them.
#
# The field is pre-filled, not fixed: a user who wants the results elsewhere
# — including, with their eyes open, the sound folder — types it or browses.
output_folder$ = homeDirectory$ + "/EML Batch Results"
channel_handling = 1
mean_F0 = 1
mean_intensity = 1
jitter = 0
shimmer = 0
hNR = 0
cPPS = 0
highest_expected_F0 = 500
use_TextGrids = 0
textGrid_folder$ = ""
tier_number = 1
target_label$ = "V"

# ============================================================================
# Configuration dialog (with Standard button for analysis parameters)
# ============================================================================

repeat
    beginPause: "Batch Voice Analysis"
        comment: "--- Input ---"
        folder: "Sound folder", sound_folder$
        word: "File extension", file_extension$
        optionmenu: "Channel handling", channel_handling
            option: "Mix to mono"
            option: "Left channel only"
            option: "Right channel only"
        comment: "--- Output ---"
        # `folder:` to match "Sound folder" above — the same widget, with the
        # same Browse button, for the same kind of thing.
        #
        # THE READBACK VARIABLE IS output_folder$. Praat derives it from the
        # LABEL: the first character lowercases and every other character keeps
        # its case, so `boolean: "Figure PNG"` reads back as figure_PNG. That
        # rule cost this project a silent no-op save on 13 Aug 2026
        # (eml-output.praat:1598). This label is two lowercase words, so the
        # derived name is output_folder$ — verified by readback, not assumed.
        folder: "Output folder", output_folder$
        comment: "--- Measures ---"
        boolean: "Mean F0", mean_F0
        boolean: "Mean intensity", mean_intensity
        boolean: "Jitter (local)", jitter
        boolean: "Shimmer (local)", shimmer
        boolean: "HNR", hNR
        boolean: "CPPS", cPPS
        comment: "--- Pitch range ---"
        positive: "Highest expected F0 (Hz)", string$ (highest_expected_F0)
        comment: "--- TextGrid options ---"
        boolean: "Use TextGrids", use_TextGrids
        folder: "TextGrid folder", textGrid_folder$
        natural: "Tier number", string$ (tier_number)
        word: "Target label", target_label$
        comment: ""
        boolean: "Clear Info window", 0
    clicked = endPause: "Quit", "Standard", "Run", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        # Reset analysis parameters to canonical defaults
        mean_F0 = 1
        mean_intensity = 1
        jitter = 0
        shimmer = 0
        hNR = 0
        cPPS = 0
        highest_expected_F0 = 500
    endif
until clicked <> 2

# ============================================================================
# Validate inputs
# ============================================================================

if sound_folder$ = ""
    exitScript: "No sound folder selected. Please re-run and select a folder."
endif

# NO SILENT FALLBACK TO THE INPUT FOLDER. A user who clears the output field
# is asked again rather than quietly given the behaviour the author ruled
# against on 14 August 2026; guessing here is what put STOP.txt in a corpus.
if output_folder$ = ""
    exitScript: "No output folder selected. The results CSV and the STOP "
        ... + "file are written there, not into the sound folder. Please "
        ... + "re-run and choose one."
endif

# TRAILING SEPARATORS ARE DROPPED, BOTH KINDS. Every path below is built as
# output_folder$ + "/" + name, so "…/Results/" would give "…/Results//STOP.txt".
# Praat tolerates that on the way in, but the doubled separator is then printed
# in the Info window as the file the user must open, and copied from there.
# BOTH separators are matched for the reason set out at "Last path component of
# the sound folder" below: a folder typed or picked on Windows arrives with
# backslashes, so testing only "/" would leave "C:\Users\ian\Results\" intact
# and produce "C:\Users\ian\Results\/STOP.txt".
while length (output_folder$) > 1 and (right$ (output_folder$, 1) = "/"
    ... or right$ (output_folder$, 1) = "\")
    output_folder$ = left$ (output_folder$, length (output_folder$) - 1)
endwhile

if not mean_F0 and not mean_intensity and not jitter and not shimmer and not hNR and not cPPS
    exitScript: "No measures selected. Please re-run and select at least one measure."
endif

if use_TextGrids and textGrid_folder$ = ""
    exitScript: "TextGrid folder is required when Use TextGrids is selected."
endif

# Strip leading dot from extension if present
if left$ (file_extension$, 1) = "."
    file_extension$ = right$ (file_extension$, length (file_extension$) - 1)
endif

# ============================================================================
# Pre-compute derived analysis parameters
# ============================================================================

needsRccPitch = jitter or shimmer
needsPointProcess = jitter or shimmer

# FAC pitch top: canonical 800 (APPENDIX_D S1A), raise only if needed
facPitchTop = max (2 * highest_expected_F0, 800)

# RCC pitch ceiling: canonical 600 (APPENDIX_D S1B), raise only if needed
rccPitchCeiling = max (highest_expected_F0 * 1.1, 600)

# ============================================================================
# Create file list and validate
# ============================================================================

fileListId = Create Strings as file list: "files",
    ... sound_folder$ + "/*." + file_extension$
nFiles = Get number of strings

if nFiles = 0
    removeObject: fileListId
    exitScript: "No ." + file_extension$ + " files found in selected folder."
endif

# ============================================================================
# Output folder and STOP sentinel (S5, author ruling 14 August 2026)
# ============================================================================

# WHY HERE. After the file list, so a mistyped extension does not leave an
# empty output folder behind; before the batch range dialog and before a single
# analysis, so a folder that cannot be written is reported in seconds rather
# than after an hour of processing with the results still in a Table.
#
# THE ORDER MATTERS. Resolve first, then create, then write: resolving is
# read-only and never touches a file, so the path handed to the writability
# probe is already known to be free or ours.
@emlResolveSentinelPath: output_folder$
sentinelPath$ = emlResolveSentinelPath.path$
sentinelDisplaced = emlResolveSentinelPath.displaced

@emlEnsureOutputFolder: output_folder$, sentinelPath$
if emlEnsureOutputFolder.writable = 0
    removeObject: fileListId
    exitScript: "Cannot write to the output folder:" + newline$
        ... + output_folder$ + newline$ + newline$
        ... + "It could not be created, or it is not writable. Check the "
        ... + "spelling of the path, and that you have permission to write "
        ... + "there — a drive that is full, read-only or not mounted will "
        ... + "also fail here. No audio has been read and nothing has been "
        ... + "written."
endif

@emlInitSentinel: sentinelPath$

# ============================================================================
# Batch range dialog (S10B)
# ============================================================================

beginPause: "Batch range"
    comment: "Found " + string$ (nFiles) + " ." + file_extension$ + " files."
    natural: "Start from file", "1"
    natural: "End at file", string$ (nFiles)
clicked = endPause: "Quit", "Run", 2, 0
if clicked = 1
    removeObject: fileListId
    exitScript: ""
endif

# ============================================================================
# Build table columns (dynamic based on selected measures)
# ============================================================================

colNames$ = "file"
if use_TextGrids
    colNames$ = colNames$ + " interval_label interval_start interval_end"
endif
if mean_F0
    colNames$ = colNames$ + " mean_F0_Hz"
endif
if mean_intensity
    colNames$ = colNames$ + " mean_intensity_dB"
endif
if jitter
    colNames$ = colNames$ + " jitter_local"
endif
if shimmer
    colNames$ = colNames$ + " shimmer_local"
endif
if hNR
    colNames$ = colNames$ + " HNR_dB"
endif
if cPPS
    colNames$ = colNames$ + " CPPS_dB"
endif

resultsId = Create Table with column names: "results", 0, colNames$
currentRow = 0

# ============================================================================
# Auto-generate output filename (S9)
# ============================================================================

# Last path component of the sound folder, used ONLY as a filename prefix.
#
# THE PREFIX MATTERS MORE SINCE 14 August 2026, not less: the CSV no longer
# lands beside the recordings it describes but in an output folder the user
# designates, which one user will point at from several corpora in turn. The
# corpus name in the file name is now the only thing that says which run of
# which folder a CSV came from.
#
# This is the one place in this script that PARSES a path instead of handing
# one to Praat. Praat accepts "/" on Windows in every path it consumes, so
# every "sound_folder$ + "/" + ..." elsewhere in this file is portable as
# written — but a folder the user picked or typed on Windows arrives with
# backslashes ("C:\Users\ian\Data"), and rindex for "/" alone then returns
# 0. The old else-branch made folderName$ the WHOLE path, so csvPath$ became
# "C:\Users\ian\Data/C:\Users\ian\Data_results_<date>.csv" — an invalid name
# (embedded drive colon) that only fails at "Save as comma-separated file"
# after the entire batch has run. Both separators must therefore be matched.
#
# A path that ends in a separator has no component of its own, so trailing
# separators are dropped first; a bare root ("/" or "C:\") leaves nothing
# usable and falls back to a fixed prefix.
pathTail$ = sound_folder$
while length (pathTail$) > 1 and (right$ (pathTail$, 1) = "/"
    ... or right$ (pathTail$, 1) = "\")
    pathTail$ = left$ (pathTail$, length (pathTail$) - 1)
endwhile

slashPos = max (rindex (pathTail$, "/"), rindex (pathTail$, "\"))
if slashPos > 0
    folderName$ = right$ (pathTail$, length (pathTail$) - slashPos)
else
    folderName$ = pathTail$
endif

if folderName$ = "" or right$ (folderName$, 1) = ":"
    folderName$ = "batch"
endif

@emlBuildDateStamp
proposedCsv$ = folderName$ + "_results_" + emlBuildDateStamp.result$ + ".csv"

# THE NAME IS BUILT FROM THE SOUND FOLDER, THE PATH FROM THE OUTPUT FOLDER.
# Both files this script writes now go to output_folder$ (author ruling,
# 14 August 2026) — the sentinel above, the results here.
csvPath$ = output_folder$ + "/" + proposedCsv$

# Non-colliding path (Rule 27)
if fileReadable (csvPath$)
    baseCsv$ = folderName$ + "_results_" + emlBuildDateStamp.result$
    suffix = 2
    repeat
        csvPath$ = output_folder$ + "/" + baseCsv$ + "_"
            ... + string$ (suffix) + ".csv"
        suffix = suffix + 1
    until not fileReadable (csvPath$)
endif

# The STOP sentinel was resolved, created and armed above, before the batch
# range dialog — see "Output folder and STOP sentinel (S5)".

# ============================================================================
# Info window header
# ============================================================================

if clear_Info_window
    writeInfoLine: ""
endif

appendInfoLine: "Batch Voice Analysis"
line$ = "Sound folder: " + sound_folder$
appendInfoLine: line$
if use_TextGrids
    line$ = "TextGrid folder: " + textGrid_folder$
    appendInfoLine: line$
    line$ = "Tier: " + string$ (tier_number) + ", Label: " + target_label$
    appendInfoLine: line$
endif
# BOTH FOLDERS ARE NAMED, because they are no longer the same folder and the
# user chose them in two different fields. Printing only the CSV's full path
# left "where did my results go" answerable only by reading a long line.
line$ = "Output folder: " + output_folder$
appendInfoLine: line$
line$ = "Results CSV: " + csvPath$
appendInfoLine: line$
appendInfoLine: ""
line$ = "Sentinel file: " + sentinelPath$
appendInfoLine: line$
appendInfoLine: "To stop: open that file, change first line to STOP, save."

# THE SENTINEL IS NOT ALWAYS CALLED STOP.txt, so the user has to be told when
# it is not. @emlResolveSentinelPath found a STOP.txt in the output folder that
# this script did not write and left it alone (it would have been TRUNCATED
# before 14 August 2026); a user who then edits the STOP.txt they can see would
# be editing the wrong file and the batch would never stop.
if sentinelDisplaced
    appendInfoLine: "NOTE: a STOP.txt already in that folder was not written"
    appendInfoLine: "by this script. It has been left untouched, and this run"
    appendInfoLine: "uses the sentinel file named above instead — edit that"
    appendInfoLine: "one, not STOP.txt."
endif
appendInfoLine: ""

# ============================================================================
# Tracking variables
# ============================================================================

nProcessed = 0
nSkipped = 0
nWarnings = 0

# ============================================================================
# Main processing loop
# ============================================================================

for iFile from start_from_file to end_at_file

    # --- Check STOP sentinel ---
    @emlCheckStopSentinel: sentinelPath$
    if emlCheckStopSentinel.shouldStop
        line$ = "=== STOPPED BY USER after " + string$ (nProcessed)
            ... + " of " + string$ (nFiles) + " files ==="
        appendInfoLine: newline$, line$
        @emlInitSentinel: sentinelPath$
        goto BATCH_END
    endif

    # --- Read file ---
    selectObject: fileListId
    fileName$ = Get string: iFile
    filePath$ = sound_folder$ + "/" + fileName$
    soundId = Read from file: filePath$

    # Extract base name for display and TextGrid pairing
    dotPos = rindex (fileName$, ".")
    if dotPos > 1
        baseName$ = left$ (fileName$, dotPos - 1)
    else
        baseName$ = fileName$
    endif

    # --- Progress (S7A) ---
    line$ = "[" + string$ (iFile) + "/" + string$ (end_at_file) + "] "
        ... + baseName$
    appendInfoLine: line$

    # --- Channel handling ---
    selectObject: soundId
    nChannels = Get number of channels
    if nChannels > 1
        if channel_handling = 1
            derivedId = Convert to mono
        elsif channel_handling = 2
            derivedId = Extract one channel: 1
        else
            derivedId = Extract one channel: 2
        endif
        removeObject: soundId
        soundId = derivedId
        line$ = "  Converted: " + channel_handling$
        appendInfoLine: line$
    endif

    # --- Determine segments to analyze ---
    if use_TextGrids
        gridPath$ = textGrid_folder$ + "/" + baseName$ + ".TextGrid"
        if not fileReadable (gridPath$)
            line$ = "  WARNING: No TextGrid for " + baseName$ + " — skipping."
            appendInfoLine: line$
            nSkipped = nSkipped + 1
            nWarnings = nWarnings + 1
            removeObject: soundId
            goto NEXT_FILE
        endif
        gridId = Read from file: gridPath$

        # Find matching intervals
        selectObject: gridId
        nIntervals = Get number of intervals: tier_number
        nSegments = 0
        for iInt from 1 to nIntervals
            selectObject: gridId
            lab$ = Get label of interval: tier_number, iInt
            if lab$ = target_label$
                nSegments = nSegments + 1
                segStart[nSegments] = Get start time of interval: tier_number, iInt
                segEnd[nSegments] = Get end time of interval: tier_number, iInt
                segLabel$[nSegments] = lab$
            endif
        endfor

        if nSegments = 0
            line$ = "  WARNING: No intervals labeled """
                ... + target_label$ + """ — skipping."
            appendInfoLine: line$
            nSkipped = nSkipped + 1
            nWarnings = nWarnings + 1
            removeObject: gridId, soundId
            goto NEXT_FILE
        endif
    else
        nSegments = 1
    endif

    # --- Segment loop ---
    for iSeg from 1 to nSegments

        # Get analysis sound
        if use_TextGrids
            selectObject: soundId
            segId = Extract part: segStart[iSeg], segEnd[iSeg],
                ... "rectangular", 1, "no"
        else
            segId = soundId
        endif

        # Check segment duration
        selectObject: segId
        segDuration = Get total duration
        if segDuration < 0.064
            line$ = "  WARNING: Segment duration "
                ... + fixed$ (segDuration, 3)
                ... + " s — measures may be undefined."
            appendInfoLine: line$
            nWarnings = nWarnings + 1
        endif

        # ========================================================
        # Create analysis objects and query measures
        # ========================================================

        # --- Mean F0 (filtered autocorrelation, APPENDIX_D S1A) ---
        if mean_F0
            selectObject: segId
            facPitchId = noprogress To Pitch (filtered autocorrelation):
                ... 0.0, 50, facPitchTop, 15, "no", 0.03, 0.09,
                ... 0.5, 0.055, 0.35, 0.14
            selectObject: facPitchId
            meanF0Val = Get mean: 0, 0, "Hertz"
        endif

        # --- Pitch for voice quality (raw cross-correlation, APPENDIX_D S1B) ---
        if needsRccPitch
            selectObject: segId
            rccPitchId = noprogress To Pitch (raw cross-correlation):
                ... 0.0, 75, rccPitchCeiling, 15, "no", 0.03,
                ... 0.45, 0.01, 0.35, 0.14
        endif

        # --- PointProcess for jitter/shimmer (APPENDIX_D S3A) ---
        if needsPointProcess
            selectObject: segId
            plusObject: rccPitchId
            ppId = noprogress To PointProcess (cc)
        endif

        # --- Jitter (APPENDIX_D S3B) ---
        if jitter
            selectObject: ppId
            jitterVal = Get jitter (local): 0, 0, 0.0001, 0.02, 1.3
        endif

        # --- Shimmer (APPENDIX_D S3C, requires PointProcess + Sound) ---
        if shimmer
            selectObject: ppId
            plusObject: segId
            shimmerVal = Get shimmer (local): 0, 0, 0.0001, 0.02,
                ... 1.3, 1.6
        endif

        # --- Mean intensity (APPENDIX_D S6) ---
        if mean_intensity
            selectObject: segId
            intId = noprogress To Intensity: 100, 0.0, "yes"
            selectObject: intId
            intVal = Get mean: 0, 0, "dB"
        endif

        # --- HNR (APPENDIX_D S2A) ---
        if hNR
            selectObject: segId
            harmId = noprogress To Harmonicity (cc): 0.01, 75,
                ... 0.1, 1.0
            selectObject: harmId
            hnrVal = Get mean: 0, 0
        endif

        # --- CPPS (APPENDIX_D S5, Maryn et al. parameters) ---
        if cPPS
            selectObject: segId
            cepId = noprogress To PowerCepstrogram: 60, 0.002,
                ... 5000, 50
            selectObject: cepId
            cppsVal = Get CPPS: "no", 0.01, 0.001, 60, 330, 0.05,
                ... "parabolic", 0.001, 0, "Straight",
                ... "Robust"
        endif

        # ========================================================
        # Plausibility warnings (APPENDIX_D S7)
        # ========================================================

        if mean_F0
            if meanF0Val <> undefined
                if meanF0Val < 50 or meanF0Val > 1000
                    line$ = "  WARNING: Mean F0 = "
                        ... + fixed$ (meanF0Val, 1)
                        ... + " Hz — outside range (50-1000)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if jitter
            if jitterVal <> undefined
                if jitterVal > 0.05
                    line$ = "  WARNING: Jitter = "
                        ... + fixed$ (jitterVal, 4)
                        ... + " — unusually high (> 5%)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if shimmer
            if shimmerVal <> undefined
                if shimmerVal > 0.15
                    line$ = "  WARNING: Shimmer = "
                        ... + fixed$ (shimmerVal, 4)
                        ... + " — unusually high (> 15%)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if hNR
            if hnrVal <> undefined
                if hnrVal < -20 or hnrVal > 40
                    line$ = "  WARNING: HNR = "
                        ... + fixed$ (hnrVal, 2)
                        ... + " dB — outside range (-20 to 40)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        if cPPS
            if cppsVal <> undefined
                if cppsVal < 0 or cppsVal > 25
                    line$ = "  WARNING: CPPS = "
                        ... + fixed$ (cppsVal, 2)
                        ... + " dB — outside range (0 to 25)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        # --- Mean intensity plausibility (APPENDIX_D S7: 20-120 dB) (M6) ---
        if mean_intensity
            if intVal <> undefined
                if intVal < 20 or intVal > 120
                    line$ = "  WARNING: Mean intensity = "
                        ... + fixed$ (intVal, 2)
                        ... + " dB — outside range (20 to 120)."
                    appendInfoLine: line$
                    nWarnings = nWarnings + 1
                endif
            endif
        endif

        # ========================================================
        # Write row to results table
        # ========================================================

        selectObject: resultsId
        Append row
        currentRow = currentRow + 1

        Set string value: currentRow, "file", baseName$

        if use_TextGrids
            Set string value: currentRow, "interval_label",
                ... segLabel$[iSeg]
            Set numeric value: currentRow, "interval_start",
                ... segStart[iSeg]
            Set numeric value: currentRow, "interval_end",
                ... segEnd[iSeg]
        endif

        if mean_F0
            Set numeric value: currentRow, "mean_F0_Hz", meanF0Val
        endif
        if mean_intensity
            Set numeric value: currentRow, "mean_intensity_dB", intVal
        endif
        if jitter
            Set numeric value: currentRow, "jitter_local", jitterVal
        endif
        if shimmer
            Set numeric value: currentRow, "shimmer_local", shimmerVal
        endif
        if hNR
            Set numeric value: currentRow, "HNR_dB", hnrVal
        endif
        if cPPS
            Set numeric value: currentRow, "CPPS_dB", cppsVal
        endif

        # ========================================================
        # Clean up analysis objects for this segment
        # ========================================================

        if mean_F0
            removeObject: facPitchId
        endif
        if needsPointProcess
            removeObject: ppId
        endif
        if needsRccPitch
            removeObject: rccPitchId
        endif
        if mean_intensity
            removeObject: intId
        endif
        if hNR
            removeObject: harmId
        endif
        if cPPS
            removeObject: cepId
        endif
        if use_TextGrids
            removeObject: segId
        endif

    endfor

    # --- Clean up file-level objects ---
    if use_TextGrids
        removeObject: gridId
    endif
    removeObject: soundId
    nProcessed = nProcessed + 1

    label NEXT_FILE
endfor

label BATCH_END

# ============================================================================
# Export results
# ============================================================================

selectObject: resultsId
Save as comma-separated file: csvPath$

# ============================================================================
# Post-completion summary (S8)
# ============================================================================

sep$ = "============================================"
appendInfoLine: ""
appendInfoLine: sep$
appendInfoLine: "COMPLETE"
appendInfoLine: sep$
line$ = "Files processed: " + string$ (nProcessed)
appendInfoLine: line$
line$ = "Files skipped:   " + string$ (nSkipped)
appendInfoLine: line$
line$ = "Warnings:        " + string$ (nWarnings)
appendInfoLine: line$
line$ = "Data rows:       " + string$ (currentRow)
appendInfoLine: line$
# THE REAL PATH, and the sentinel with it. The summary is what a user copies
# into a lab notebook, and since 14 August 2026 neither file is where a reader
# of an older notebook would look for it — they are in the designated output
# folder, not beside the recordings.
line$ = "Results CSV:     " + csvPath$
appendInfoLine: line$
line$ = "Sentinel file:   " + sentinelPath$
appendInfoLine: line$
appendInfoLine: sep$
appendInfoLine: ""
appendInfoLine: "Results Table retained in Objects window."
appendInfoLine: "Run stats or draw graphs from the EML Tools menu."

# Reset sentinel for next run
@emlInitSentinel: sentinelPath$

# Clean up file list, keep results table
removeObject: fileListId
selectObject: resultsId
