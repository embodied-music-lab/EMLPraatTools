# ============================================================================
# harness/batchcmd/drive.praat -- the OTHER half of the batch module's calls
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# harness/acoustic covers the nine acoustic calls. This covers everything
# else eml-batch-process.praat asks Praat to do -- the Strings list, the
# Table, the TextGrid interval queries, the Sound channel handling, the
# folder creation, the CSV write -- in the module's own form, its own
# argument order, and its own selection discipline.
#
# WHY A HARNESS AND NOT JUST A READING OF COMMANDS_*.txt. Every one of those
# files carries the same scope banner: the arity check "establishes that each
# command EXISTS on this object type and that its documented PARAMETER COUNT
# is right. It does NOT verify parameter ORDER, parameter TYPES, default
# values, or semantic correctness." So the corpus settles arity and nothing
# past it. `Extract part: from, to, window shape$, relative width, preserve
# times?` has two numbers, a string, a number and a boolean; a call that put
# the window shape last would still have five arguments. Only running it
# separates the two.
#
# THE THREE THINGS THAT ONLY EXECUTION CAN SETTLE, and they are the reason
# this file exists rather than a longer static validator:
#
#   1. OBJECT LEAKS. The module creates up to seven objects per segment and
#      removes them under conditions that must mirror the ones that created
#      them. Static reading can pair a removeObject: with a creation; it
#      cannot prove the object list is the same size at the end of iteration
#      three as it was at the end of iteration one. `select all` +
#      numberOfSelected () can, and does, below.
#
#   2. THE FAILURE MODES ARE SILENT OR FATAL, NEVER LOUD. `Get string:` past
#      the end of a Strings list does not fail -- it returns "" -- and the
#      empty name then reaches `Read from file:`, which kills the script.
#      Writing that down from the manual would be a guess; the exit status of
#      a real process is not. Those probes live in run.sh, which can see an
#      exit status, because a script cannot survive its own abort to report
#      one. `nocheck` is not used to fake it: COMMANDS_Universal.txt's own
#      errata forbids nocheck as a diagnostic branch.
#
#   3. FORM VARIABLE DERIVATION. APPENDIX_C §C.3 lowercases the first
#      character and preserves every other, so "HNR" derives to hNR and
#      "Clear Info window" to clear_Info_window. The module reads those exact
#      names. A wrong one is not an error -- it is an undefined variable that
#      Praat treats as 0, which is how eml-output.praat:1598 lost a save on
#      13 Aug 2026. Sixteen labels are declared here and every derived name is
#      asked for by variableExists ().
#
#     bash harness/batchcmd/run.sh
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

out$ = "out/COMMANDS.tsv"
deleteFile: out$

procedure emit: .key$, .value$
    appendFileLine: out$, .key$ + tab$ + .value$
endproc

@emit: "praat_version", praatVersion$
@emit: "at_target_version", string$ (praatVersion >= 6630)

select all
baselineObjects = numberOfSelected ()
@emit: "objects_baseline", string$ (baselineObjects)

# ---------------------------------------------------------------------------
# FIXTURE -- a folder of two sounds and two matching TextGrids, so the module's
# TextGrid pairing and its channel handling both have something real to do.
# ---------------------------------------------------------------------------
fixture$ = "out/fixture"
createFolder: fixture$

mono = Create Sound from formula: "one", 1, 0, 2.0, 44100,
    ... "0.5*sin(2*pi*120*x) + 0.3*sin(2*pi*240*x)"
Save as WAV file: fixture$ + "/one.wav"
removeObject: mono

stereo = Create Sound from formula: "two", 2, 0, 2.0, 44100,
    ... "0.5*sin(2*pi*150*x) + 0.2*sin(2*pi*300*x)"
Save as WAV file: fixture$ + "/two.wav"
removeObject: stereo

for iGrid from 1 to 2
    if iGrid = 1
        gname$ = "one"
    else
        gname$ = "two"
    endif
    g = Create TextGrid: 0, 2.0, "segments", ""
    Set interval text: 1, 1, "V"
    Insert boundary: 1, 1.0
    Set interval text: 1, 2, "V"
    Save as text file: fixture$ + "/" + gname$ + ".TextGrid"
    removeObject: g
endfor

# ---------------------------------------------------------------------------
# 1. THE FILE LIST -- Create Strings as file list / Get number of strings /
#    Get string, in the module's order (COMMANDS_Strings.txt)
# ---------------------------------------------------------------------------
fileListId = Create Strings as file list: "files", fixture$ + "/*.wav"
nFiles = Get number of strings
@emit: "strings_n_files", string$ (nFiles)
selectObject: fileListId
first$ = Get string: 1
@emit: "strings_get_string_1", first$

# `Get string:` PAST THE END. The module's batch-range dialog takes an
# unbounded `natural:`, so this is reachable from the GUI. It returns the empty
# string rather than failing -- which is what makes the abort happen one line
# later, in Read from file:, where it is no longer obvious what went wrong.
selectObject: fileListId
overrun$ = Get string: nFiles + 99
@emit: "strings_get_string_overrun_len", string$ (length (overrun$))

# ---------------------------------------------------------------------------
# 2. THE RESULTS TABLE (COMMANDS_Table.txt)
#    Create Table with column names / Append row / Set string value /
#    Set numeric value / Save as comma-separated file
# ---------------------------------------------------------------------------
# The space-separated column-name string is the form the module builds; the
# corpus documents the vector literal and notes the string form also works.
colNames$ = "file interval_label interval_start interval_end mean_F0_Hz"
    ... + " mean_intensity_dB jitter_local shimmer_local HNR_dB CPPS_dB"
resultsId = Create Table with column names: "results", 0, colNames$
nCols = Get number of columns
@emit: "table_n_columns", string$ (nCols)

selectObject: resultsId
Append row
Set string value: 1, "file", "one"
Set numeric value: 1, "mean_F0_Hz", 120.5
# UNDEFINED IS ACCEPTED, and what it writes is the thing worth pinning: the
# module's measures return undefined on an unvoiced or too-short segment and
# go into the Table unchanged.
Set numeric value: 1, "HNR_dB", undefined
csvOut$ = "out/probe.csv"
Save as comma-separated file: csvOut$
csvText$ = readFile$ (csvOut$)
@emit: "table_csv_written", string$ (fileReadable (csvOut$))
@emit: "table_undefined_token",
    ... string$ (index (csvText$, "--undefined--") > 0)

# ---------------------------------------------------------------------------
# 3. ONE FULL FILE, THE WAY THE MODULE WALKS IT, THREE TIMES OVER
#    Read from file / Get number of channels / Convert to mono /
#    Extract one channel / Get number of tiers / Is interval tier /
#    Get number of intervals / Get label of interval / Get start time of
#    interval / Get end time of interval / Extract part / Get total duration
# ---------------------------------------------------------------------------
# THREE ITERATIONS, NOT ONE, and the object count is taken after each. A leak
# of one object per file is invisible in a single pass and is the whole finding
# in three.
for iFile from 1 to 3
    # THE STEREO FILE EVERY TIME, so all three arms of the module's
    # `Channel handling` optionmenu are executed across the three iterations.
    # Reading the mono file here instead would leave `Extract one channel: 1`
    # untested while the run still went green — the shape of check this whole
    # harness exists to avoid. The mono no-op path is taken separately below.
    selectObject: fileListId
    fileName$ = Get string: 2
    filePath$ = fixture$ + "/" + fileName$
    soundId = Read from file: filePath$

    selectObject: soundId
    nChannels = Get number of channels
    if nChannels > 1
        if iFile = 1
            derivedId = Convert to mono
        elsif iFile = 2
            derivedId = Extract one channel: 1
        else
            derivedId = Extract one channel: 2
        endif
        removeObject: soundId
        soundId = derivedId
    endif
    selectObject: soundId
    chansAfter = Get number of channels
    @emit: "iter" + string$ (iFile) + "_channels_in", string$ (nChannels)
    @emit: "iter" + string$ (iFile) + "_channels_out", string$ (chansAfter)

    dotPos = rindex (fileName$, ".")
    baseName$ = left$ (fileName$, dotPos - 1)
    gridPath$ = fixture$ + "/" + baseName$ + ".TextGrid"
    gridId = Read from file: gridPath$

    selectObject: gridId
    nTiers = Get number of tiers
    isIntervalTier = Is interval tier: 1
    nIntervals = Get number of intervals: 1
    @emit: "iter" + string$ (iFile) + "_n_tiers", string$ (nTiers)
    @emit: "iter" + string$ (iFile) + "_is_interval_tier",
        ... string$ (isIntervalTier)
    @emit: "iter" + string$ (iFile) + "_n_intervals", string$ (nIntervals)

    nSegments = 0
    for iInt from 1 to nIntervals
        selectObject: gridId
        lab$ = Get label of interval: 1, iInt
        if lab$ = "V"
            nSegments = nSegments + 1
            segStart[nSegments] = Get start time of interval: 1, iInt
            segEnd[nSegments] = Get end time of interval: 1, iInt
        endif
    endfor
    @emit: "iter" + string$ (iFile) + "_n_segments", string$ (nSegments)

    for iSeg from 1 to nSegments
        selectObject: soundId
        segId = Extract part: segStart[iSeg], segEnd[iSeg],
            ... "rectangular", 1, "no"
        selectObject: segId
        segDuration = Get total duration
        if iSeg = 1
            @emit: "iter" + string$ (iFile) + "_seg1_duration",
                ... fixed$ (segDuration, 4)
        endif
        removeObject: segId
    endfor

    removeObject: gridId
    removeObject: soundId

    select all
    @emit: "objects_after_iter" + string$ (iFile),
        ... string$ (numberOfSelected ())
endfor

# THE MONO NO-OP. A one-channel file must skip the conversion block entirely
# and keep the id it was read with; the module's `removeObject: soundId` in
# that block is what makes a wrong answer here a double-free later.
selectObject: fileListId
monoName$ = Get string: 1
monoId = Read from file: fixture$ + "/" + monoName$
selectObject: monoId
# Assigned, not inlined: COMMANDS_Universal.txt's errata — query commands are
# commands, not functions, and "Unknown symbol «Get» in formula" is what
# inlining one gets you.
monoChannels = Get number of channels
@emit: "mono_file_channels", string$ (monoChannels)
removeObject: monoId

# ---------------------------------------------------------------------------
# 4. Extract part BEYOND THE SOUND'S DOMAIN
# ---------------------------------------------------------------------------
# The module takes its segment bounds from the TextGrid and hands them to
# Extract part without clamping them to the Sound. A grid longer than its
# recording is a real thing -- it is what a re-cut audio file leaves behind --
# and this is what Praat does with it. Not an abort: zero padding, silently.
probeSnd = Create Sound from formula: "domain", 1, 0, 1.0, 44100,
    ... "0.5*sin(2*pi*120*x)"
overhang = Extract part: 0.5, 3.0, "rectangular", 1, "no"
selectObject: overhang
overhangDur = Get total duration
@emit: "extract_part_overhang_duration", fixed$ (overhangDur, 4)
removeObject: overhang
selectObject: probeSnd
outside = Extract part: 5.0, 6.0, "rectangular", 1, "no"
selectObject: outside
outsideDur = Get total duration
@emit: "extract_part_outside_duration", fixed$ (outsideDur, 4)
removeObject: outside, probeSnd

# ---------------------------------------------------------------------------
# 5. createFolder: IS mkdir, NOT mkdir -p
# ---------------------------------------------------------------------------
# @emlEnsureOutputFolder creates every ancestor in turn, and its comment says
# this is why. The claim is measured here rather than trusted, because if
# createFolder: ever became recursive the loop would be harmless dead code, and
# if it is NOT recursive then a user typing "~/Documents/Study A/run 1" into
# the Output folder field depends on that loop entirely.
# A FOLDER IS PROVED BY WRITING INTO IT, not by fileReadable. fileReadable on
# a directory path returns 0 on this platform, so a test built on it would call
# every folder missing and pass the "not recursive" half by accident.
deep$ = "out/scaffold/level1/level2"
nocheck createFolder: deep$
nocheck writeFileLine: deep$ + "/probe.txt", "x"
@emit: "createfolder_missing_parent",
    ... string$ (fileReadable (deep$ + "/probe.txt"))
createFolder: "out/scaffold"
createFolder: "out/scaffold/level1"
createFolder: deep$
writeFileLine: deep$ + "/probe.txt", "x"
@emit: "createfolder_each_level",
    ... string$ (fileReadable (deep$ + "/probe.txt"))

# ---------------------------------------------------------------------------
# 6. TEARDOWN -- and the number that says whether anything leaked
# ---------------------------------------------------------------------------
removeObject: resultsId
removeObject: fileListId
select all
@emit: "objects_final", string$ (numberOfSelected ())
@emit: "completed", "1"
