# ============================================================================
# harness/axisspec/axisspec_drive.praat — the recorded axis and the one-bin
# spectrum, driven
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# One leg per process (see axisspec.sh), because a Praat script error aborts
# the script: nine legs in one process report one failure and hide eight.
#
# Every number that matters is written to $EML_AS_OUT as key<TAB>value, so
# validate/v67 reads a MEASUREMENT and never parses a picture. The things a
# picture can say that no Praat variable can — how much ink is inside a frame,
# which image ROW a mark's tip lands on, whether two renders are the same file
# — are taken from the PNG by axisspec.sh and written into the same TSV.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. The draw procedures call no
# beginPause:, which is what lets a figure be rendered and measured with no X
# server; axisspec.sh unsets DISPLAY for every leg rather than merely ignoring
# it.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/stats/eml-analysis.praat

# EVERY FILE THIS DRIVE WRITES IS UTF-8, AND SAYING SO IS NOT OPTIONAL. Praat
# converts a file to UTF-16 the moment a non-ASCII character is written into
# it, and a validator reading a UTF-16 TSV with readLines() sees keys spelled
# "l e g" with NULs between the letters — which is indistinguishable from a
# harness that never ran. Learned the hard way by harness/drawlayer.
Text writing preferences: "UTF-8"

@emlInitDrawingDefaults
@emlClearAnnotations

leg$ = environment$ ("EML_AS_LEG")
out$ = environment$ ("EML_AS_OUT")
pic$ = environment$ ("EML_AS_PIC")
aux$ = environment$ ("EML_AS_AUX")
root$ = environment$ ("EML_AS_ROOT")
if out$ = ""
    exitScript: "EML_AS_OUT unset."
endif

procedure emit: .key$, .value$
    appendFileLine: out$, .key$, tab$, .value$
endproc

procedure savePic
    if pic$ <> ""
        @emlAssertFullViewport
        Save as 300-dpi PNG file: pic$
    endif
endproc

# ---------------------------------------------------------------------------
# THE SHORT TOKEN, WHICH IS THE WHOLE POINT OF THIS FIXTURE.
#
# Praat's Spectrum bin width is 1 / duration after the analysis window is
# zero-padded to a power of two, so the frequency window that holds only ONE
# bin scales with how SHORT the recording is:
#
#     3 s vowel    0.33 Hz bins   ->  needs a sub-hertz zoom     (absurd)
#     0.15 s token 5.38 Hz bins   ->  ANY zoom under ~10.7 Hz    (routine)
#
# The auditor's original fixture was 1.4861 s and needed a 0.2 Hz window,
# which reads as a curiosity. This one is a 0.15 s token — the length of a
# plosive burst, a vowel in running speech, a sung onset — and a four-hertz
# zoom is an ordinary thing to ask a spectrum for. Both are driven, and the
# short one is the reason the ruling matters.
#
# The tone is EXACT and unseeded noise is deliberately absent: two of this
# file's verdicts compare image rows between separate Praat processes.
# ---------------------------------------------------------------------------
procedure shortToken
    .snd = Create Sound from formula: "tok", 1, 0, 0.15, 44100,
    ... "0.9 * sin (2 * pi * 1000 * x)"
    .spec = To Spectrum: "yes"
endproc

# ---------------------------------------------------------------------------
# @binFacts — what is in the window, said as numbers before anything is drawn.
#
# The counting rule is the one @emlDrawSpectrum uses: the bins whose numbers
# fall INSIDE [lo, hi], so ceiling of the low end and floor of the high end.
# It is published here as well as used there so that a check can ask whether
# the fixture really is a one-bin fixture rather than take it on trust — the
# figure being empty proves nothing if the window secretly held no bins.
# ---------------------------------------------------------------------------
procedure binFacts: .specId, .lo, .hi
    selectObject: .specId
    .df = Get bin width
    .n1 = Get bin number from frequency: .lo
    .n2 = Get bin number from frequency: .hi
    .lowb = ceiling (.n1)
    .highb = floor (.n2)
    .count = .highb - .lowb + 1
    if .count < 0
        .count = 0
    endif
    .peak = -1000
    .peakBin = 0
    .peakFreq = 0
    for .b from .lowb to .highb
        .re = Get real value in bin: .b
        .im = Get imaginary value in bin: .b
        .pw = .re * .re + .im * .im
        if .pw > 0
            ; THE dB PRAAT DRAWS, which is the spectral density and not the
            ; bare power — see @emlDrawSpectrum. The leg `dbcheck` proves the
            ; two are 10.32 dB apart on this fixture and that this one is
            ; Praat's.
            .dbv = 10 * log10 (2 * .df * .pw / 4e-10)
            if .dbv > .peak
                .peak = .dbv
                .peakBin = .b
                .peakFreq = Get frequency from bin number: .b
            endif
        endif
    endfor
endproc

# ---------------------------------------------------------------------------
# THE RECORDING FIXTURE. Three groups, deterministic, and it is a linear
# congruential sequence written out rather than randomGauss for the reason
# harness/record/roundtrip_graph.sh gives: an unseeded generator makes a
# byte-for-byte comparison between two processes meaningless.
# ---------------------------------------------------------------------------
procedure recTable: .base, .spread
    .t = Create Table with column names: "vt", 0, "grp val"
    .st = 20260816
    .r = 0
    for .g from 1 to 3
        for .k from 1 to 20
            .st = (1103515245 * .st + 12345) mod 2147483648
            .r = .r + 1
            Append row
            Set string value: .r, "grp", "G" + string$ (.g)
            Set numeric value: .r, "val",
            ... .base + .g * .spread * 0.235 + (.st / 2147483648 - 0.5) * .spread
        endfor
    endfor
endproc

procedure startRecording: .folder$
    @emlRecordInit
    emlRecordPluginRoot$ = root$ + "/plugin"
    @emlRecordBegin: .folder$
    emlRecordPluginRoot$ = root$ + "/plugin"
    @emlRecordLoadPhrases: root$ + "/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "vt", 60, 2, "axisspec"
endproc

# ===========================================================================
# RULING A — THE ONE-BIN SPECTRUM
# ===========================================================================
if leg$ = "onebin" or leg$ = "twobin" or leg$ = "zerobin"
    @shortToken
    spec = shortToken.spec
    if leg$ = "onebin"
        ; Four hertz around 1 kHz. Bin 187 (1001.294 Hz) alone.
        lo = 998
        hi = 1002
    elsif leg$ = "twobin"
        ; Ten hertz. Bins 186 and 187 — the control that says the finding is
        ; about the COUNT and not about the range, and the ruler the one-bin
        ; stem's height is measured against, since bin 187 is in both.
        lo = 995
        hi = 1005
    else
        ; Between two bins and touching neither: 1001.294 and 1006.677 are
        ; the neighbours. Nothing to draw, and the ruling says so stays.
        lo = 1002
        hi = 1006
    endif
    @binFacts: spec, lo, hi
    @emit: leg$ + "_bin_width", fixed$ (binFacts.df, 6)
    @emit: leg$ + "_bins_in_range", string$ (binFacts.count)
    @emit: leg$ + "_peak_db", fixed$ (binFacts.peak, 4)
    @emit: leg$ + "_peak_freq", fixed$ (binFacts.peakFreq, 4)
    @emit: leg$ + "_window_lo", fixed$ (lo, 4)
    @emit: leg$ + "_window_hi", fixed$ (hi, 4)
    selectObject: spec
    Erase all
    @emlDrawSpectrum: spec, "1 kHz tone, 0.15 s", "Frequency (Hz)",
    ... "Power (dB)", 6, 4, "color", 1, lo, hi, 0, 100
    @emit: leg$ + "_drawn_one_bin", string$ (emlDrawSpectrum.oneBinDrawn)
    @emit: leg$ + "_proc_bins_in_range",
    ... string$ (emlDrawSpectrum.binsInRange)
    @savePic

# ---------------------------------------------------------------------------
# THE AUDITOR'S OWN FIXTURE, unchanged, so that the long token and the short
# one are shown to be the same finding at two durations rather than two
# findings. 1.4861 s, 0.673 Hz bins, a two-tenths-of-a-hertz window.
# ---------------------------------------------------------------------------
elsif leg$ = "onebin_long"
    snd = Create Sound from formula: "tone", 1, 0, 1.4861, 44100,
    ... "0.9 * sin (2 * pi * 1000 * x)"
    spec = To Spectrum: "yes"
    lo = 999.90
    hi = 1000.10
    @binFacts: spec, lo, hi
    @emit: "long_bin_width", fixed$ (binFacts.df, 6)
    @emit: "long_bins_in_range", string$ (binFacts.count)
    @emit: "long_peak_db", fixed$ (binFacts.peak, 4)
    selectObject: spec
    Erase all
    @emlDrawSpectrum: spec, "1 kHz tone, 1.49 s", "Frequency (Hz)",
    ... "Power (dB)", 6, 4, "color", 1, lo, hi, 0, 100
    @emit: "long_drawn_one_bin", string$ (emlDrawSpectrum.oneBinDrawn)
    @savePic

# ---------------------------------------------------------------------------
# ONE BIN, AND IT IS BELOW THE FLOOR THE USER ASKED FOR.
#
# "Draw what you can" is not "draw something regardless". A bin whose value
# falls under the axis minimum is a point off the paper, and Praat's own
# `Draw:` does not plot it either — so the stem is refused and the frame is
# honestly empty. Without this leg the repair could be a stem pinned to the
# floor whatever the data said, which is a figure that lies in exactly the
# direction the original defect did.
# ---------------------------------------------------------------------------
elsif leg$ = "onebin_below"
    @shortToken
    spec = shortToken.spec
    ; Bin 188 alone: 1006.677 Hz, 24.85 dB on this fixture — a null between
    ; the tone's bins, far under the 60 dB floor asked for below.
    lo = 1004.5
    hi = 1008.5
    @binFacts: spec, lo, hi
    @emit: "below_bins_in_range", string$ (binFacts.count)
    @emit: "below_peak_db", fixed$ (binFacts.peak, 4)
    @emit: "below_floor", "60.0000"
    selectObject: spec
    Erase all
    @emlDrawSpectrum: spec, "below the floor", "Frequency (Hz)",
    ... "Power (dB)", 6, 4, "color", 1, lo, hi, 60, 100
    @emit: "below_drawn_one_bin", string$ (emlDrawSpectrum.oneBinDrawn)
    @savePic

# ---------------------------------------------------------------------------
# THE dB CONVERSION, AGAINST PRAAT'S OWN.
#
# The obvious formula for a Spectrum bin — 10*log10 ((re^2+im^2) / 4e-10) —
# is NOT what `Draw:` plots. What it plots is the spectral density, which is
# the quantity `To Ltas (1-to-1)` returns, and the difference is 10*log10 of
# twice the bin width: 10.32 dB on the 0.15 s fixture. Getting it wrong draws
# a stem of the right shape at the wrong height, which is a worse figure than
# no stem at all because it looks like a measurement.
#
# Five durations, so that a factor that happens to be right at one bin width
# cannot pass. The delta asserted is EXACT, not a tolerance: these are the
# same number computed two ways.
# ---------------------------------------------------------------------------
elsif leg$ = "dbcheck"
    for k from 1 to 5
        d = 0.05 * k + 0.03
        snd = Create Sound from formula: "tok", 1, 0, d, 44100,
        ... "0.9 * sin (2 * pi * 1000 * x) + 0.05 * sin (2 * pi * 3100 * x)"
        spec = To Spectrum: "yes"
        df = Get bin width
        b = Get bin number from frequency: 1000
        bb = round (b)
        re = Get real value in bin: bb
        im = Get imaginary value in bin: bb
        pw = re * re + im * im
        naive = 10 * log10 (pw / 4e-10)
        mine = 10 * log10 (2 * df * pw / 4e-10)
        lt = To Ltas (1-to-1)
        praats = Get value in bin: bb
        @emit: "db_binwidth", fixed$ (df, 6)
        @emit: "db_naive", fixed$ (naive, 6)
        @emit: "db_mine", fixed$ (mine, 6)
        @emit: "db_praat", fixed$ (praats, 6)
        @emit: "db_delta", fixed$ (praats - mine, 9)
        @emit: "db_naive_gap", fixed$ (praats - naive, 6)
        removeObject: lt, spec, snd
    endfor

# ===========================================================================
# RULING B — THE RECORDED AXIS IN THE EDITABLE BLOCK
# ===========================================================================
# ONE FIGURE IN THIS SESSION AND THAT IS DELIBERATE: the emitted script is
# REPLAYED below and the comparison is byte-for-byte against the picture this
# leg saves, so the last thing the replay draws has to be the last thing this
# leg drew. A second figure lives in `rec_two`, which is checked for what it
# SAYS and is never replayed.
# ---------------------------------------------------------------------------
elsif leg$ = "rec_auto"
    @startRecording: aux$
    @recTable: 200, 80
    table = selected ("Table")
    Erase all
    @emlDrawViolinPlot: table, "f0 by group", "Group", "val", 6, 4, "color",
    ... 1, "grp", "val", 0, 0
    @emit: "rec_auto_resolved_min", fixed$ (emlDrawViolinPlot.yMin, 4)
    @emit: "rec_auto_resolved_max", fixed$ (emlDrawViolinPlot.yMax, 4)
    @savePic
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "rec_auto_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# TWO FIGURES OF DIFFERENT KINDS IN ONE SESSION, on purpose. The violin is
# drawn on AUTO and the spectrum on a power range the user typed, so the
# emitted block has to carry both kinds at once — and a repair that hardcodes
# either the sentinel or the typed numbers is visible in one file.
#
# It also exercises the four draw procedures that take no COLUMN at all. The
# spectrum draws an Ltas-like object whole, so it is correctly absent from
# ruling 9's column map; its axis range is still an axis range, and a lift
# keyed only on the column map would silently skip every acoustic figure in
# the library.
# ---------------------------------------------------------------------------
elsif leg$ = "rec_two"
    @startRecording: aux$
    @recTable: 200, 80
    table = selected ("Table")
    Erase all
    @emlDrawViolinPlot: table, "f0 by group", "Group", "val", 6, 4, "color",
    ... 1, "grp", "val", 0, 0
    @shortToken
    spec = shortToken.spec
    Erase all
    @emlDrawSpectrum: spec, "1 kHz tone, 0.15 s", "Frequency (Hz)",
    ... "Power (dB)", 6, 4, "color", 1, 995, 1005, 20, 95
    @emit: "rec_two_spec_resolved_min", fixed$ (emlDrawSpectrum.powerMin, 4)
    @emit: "rec_two_spec_resolved_max", fixed$ (emlDrawSpectrum.powerMax, 4)
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "rec_two_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# THE INTERFACE CONTRACT, DRIVEN FROM THIS SIDE.
#
# This leg IS the annotated and legend-bearing case, without needing the form:
# what those paths do is resolve the user's AUTO range into explicit numbers
# and then call the draw with them, so the recorder's arguments are 190 and
# 290 while the user asked for auto. The form publishes the untouched request
# as emlGraphsAxisYReqMin / emlGraphsAxisYReqMax; this leg publishes the same
# two globals with the same values, and the block must come out reading 0.0.
#
# Setting the globals here rather than running eml-graphs-form.praat is
# deliberate and is stated as a limit: the form is another hand's file this
# week, and what this rig can honestly test is ITS OWN SIDE of the contract —
# that the recorder prefers the globals when they exist. validate/v67 says so
# where it reads these keys.
# ---------------------------------------------------------------------------
elsif leg$ = "rec_form"
    @startRecording: aux$
    @recTable: 200, 80
    table = selected ("Table")
    emlGraphsAxisYReqMin = 0
    emlGraphsAxisYReqMax = 0
    Erase all
    @emlDrawViolinPlot: table, "f0 by group", "Group", "val", 6, 4, "color",
    ... 1, "grp", "val", 190, 290
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "rec_form_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# THE FALLBACK, WHICH IS THE HALF THAT KEEPS EVERY OTHER CALLER WORKING.
#
# No form, no globals, an explicit range the caller passed. This is what the
# API export, the batch module, every harness in this tree and any user script
# calling a draw procedure directly look like. The recorded range must be the
# argument, and it must not become 0.
# ---------------------------------------------------------------------------
elsif leg$ = "rec_noform"
    @startRecording: aux$
    @recTable: 200, 80
    table = selected ("Table")
    Erase all
    @emlDrawViolinPlot: table, "f0 by group", "Group", "val", 6, 4, "color",
    ... 1, "grp", "val", 150, 400
    @emit: "rec_noform_resolved_min", fixed$ (emlDrawViolinPlot.yMin, 4)
    @emit: "rec_noform_resolved_max", fixed$ (emlDrawViolinPlot.yMax, 4)
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "rec_noform_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# THE PAIR RULE, WHICH IS THE ONE PLACE THIS DIFFERS FROM RULING 9's COLUMNS.
#
# THREE figures, and the third one is what makes this leg a test rather than
# an illustration:
#
#   a violin on AUTO          (0, 0)
#   a box with a typed FLOOR of zero   (0, 120)
#   a bar chart with the same floor and a different ceiling   (0, 300)
#
# A lift that takes each NUMBER as its own variable sees "0" in the axisYMin
# role three times. It gives the auto one its own variable — 0.0 and 0 are
# different strings — and then SHARES one axisYMin2 between the box and the
# bar, which means the bar's call reads the box's maximum and the bar is
# silently redrawn at 0..120. Four declarations instead of six, and a figure
# that changed without anybody asking.
#
# Two of the three would not show it: with only the auto and one typed range
# the two minima are "0.0" and "0" and even a per-number lift keeps them
# apart. The defect needs two typed ranges that agree at one end, which is
# also the commonest thing a user does — every bar chart in the world has a
# floor of zero.
# ---------------------------------------------------------------------------
elsif leg$ = "rec_pairs"
    @startRecording: aux$
    @recTable: 200, 80
    table = selected ("Table")
    Erase all
    @emlDrawViolinPlot: table, "auto", "Group", "val", 6, 4, "color", 1,
    ... "grp", "val", 0, 0
    Erase all
    @emlDrawBoxPlot: table, "zero floor", "Group", "val", 6, 4, "color", 1,
    ... "grp", "val", 0, 120
    Erase all
    @emlDrawBarChart: table, "same floor, other ceiling", "Group", "val",
    ... 6, 4, "color", 1, "grp", "val", 1, "", 0, 300
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "rec_pairs_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# THE NATIVE DRAWS THE REPLAYS ARE COMPARED AGAINST. Same fixture, same
# viewport, one at the axis the block was EDITED to and one at the axis the
# session recorded. Both are needed and the second is the one that stops this
# rig being satisfied by a replay that ignores its arguments: an edited block
# must produce the first and NOT the second.
# ---------------------------------------------------------------------------
elsif leg$ = "native_edited" or leg$ = "native_recorded"
    @recTable: 200, 80
    table = selected ("Table")
    Erase all
    if leg$ = "native_edited"
        @emlDrawViolinPlot: table, "f0 by group", "Group", "val", 6, 4,
        ... "color", 1, "grp", "val", 120, 500
    else
        @emlDrawViolinPlot: table, "f0 by group", "Group", "val", 6, 4,
        ... "color", 1, "grp", "val", 0, 0
    endif
    @emit: leg$ + "_min", fixed$ (emlDrawViolinPlot.yMin, 4)
    @emit: leg$ + "_max", fixed$ (emlDrawViolinPlot.yMax, 4)
    @savePic

# ---------------------------------------------------------------------------
# THE SAME MECHANISM AT A SECOND SITE, MEASURED AND NOT REPAIRED.
#
# @emlDrawLTAS's Curve mode is `Draw: ..., "Curve"` on an Ltas, which joins
# bin points with segments exactly as the Spectrum's `Draw:` does. A one-bin
# window is therefore an empty frame there too -- and an Ltas's bin width is
# the BANDWIDTH the user chose, 100 Hz by default, so a hundred-hertz window
# reaches it. Curve is also the mode the procedure falls back to when the
# caller enables none of the four.
#
# Its Bars mode draws the same single bin without complaint, which is both the
# control that says this is the segment mechanism and the reason the remedy is
# not obvious: an LTAS already has a working mode for this case, so "draw what
# you can" here might mean a stem, or might mean falling back to Bars. That is
# the author's call and validate/v67 asserts no remedy -- it prints the facts,
# the way validate/v66 §8 printed the spectrum's before the ruling existed.
# ---------------------------------------------------------------------------
elsif leg$ = "ltas_curve" or leg$ = "ltas_bars"
    @shortToken
    snd = shortToken.snd
    selectObject: snd
    lt = To Ltas: 100
    df = Get bin width
    nb = Get number of bins
    lo = 960
    hi = 1060
    n1 = Get bin number from frequency: lo
    n2 = Get bin number from frequency: hi
    lowb = ceiling (n1)
    highb = floor (n2)
    @emit: leg$ + "_bin_width", fixed$ (df, 4)
    @emit: leg$ + "_bins_in_range", string$ (highb - lowb + 1)
    v = Get value in bin: lowb
    @emit: leg$ + "_bin_db", fixed$ (v, 4)
    selectObject: lt
    Erase all
    if leg$ = "ltas_curve"
        @emlDrawLTAS: lt, "LTAS, one bin, Curve", "Frequency (Hz)",
        ... "Power (dB)", 6, 4, "color", 1, lo, hi, 0, 100, 1, 0, 0, 0
    else
        @emlDrawLTAS: lt, "LTAS, one bin, Bars", "Frequency (Hz)",
        ... "Power (dB)", 6, 4, "color", 1, lo, hi, 0, 100, 0, 1, 0, 0
    endif
    @savePic

else
    @emit: "unknown_leg", leg$
endif
