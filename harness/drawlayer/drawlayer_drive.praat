# ============================================================================
# harness/drawlayer/drawlayer_drive.praat — the draw layer's own four rulings
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# One leg per process (see drawlayer.sh), because a Praat script error aborts
# the script: five legs in one process report one failure and hide four.
#
# Every number that matters is written to $EML_DL_OUT as key<TAB>value, so
# validate/v66 reads a MEASUREMENT and never parses a picture. The three
# things a picture can say that no Praat variable can — how many pixels of
# white stand between the axis name and the tick numbers, whether the frame
# has any ink inside it, whether two renders are the same file — are taken
# from the PNG by drawlayer.sh and written into the same TSV.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. The draw procedures call no
# beginPause:, which is what lets a figure be rendered and measured with no X
# server; drawlayer.sh unsets DISPLAY for every leg rather than merely
# ignoring it.
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

# EVERY FILE THIS DRIVE WRITES IS UTF-8, AND SAYING SO IS NOT OPTIONAL.
# Praat's default text-writing setting converts a file to UTF-16 the moment a
# non-ASCII character is written into it -- and one of the strings emitted
# below is a matrix subtitle containing "·" and a curly apostrophe. Measured
# on 15 August 2026: the TSV came back half UTF-8 (the shell's own rows) and
# half UTF-16 (Praat's), and every key the validator looks for read as
# "l e g" with NULs between the letters. A validator cannot tell that from a
# harness that never ran.
Text writing preferences: "UTF-8"

@emlInitializeDrawingDefaults
@emlClearAnnotations

leg$ = environment$ ("EML_DL_LEG")
out$ = environment$ ("EML_DL_OUT")
pic$ = environment$ ("EML_DL_PIC")
aux$ = environment$ ("EML_DL_AUX")
root$ = environment$ ("EML_DL_ROOT")
if out$ = ""
    exitScript: "EML_DL_OUT unset."
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
# THE FIXTURES ARE DETERMINISTIC AND THEY ARE NOT randomGauss.
#
# Two of this file's verdicts are BYTE-FOR-BYTE comparisons between two
# separate Praat processes, and an unseeded generator makes that comparison
# meaningless — it would fail on a correct build and nobody could tell why.
# A linear congruential sequence written out in Praat is reproducible across
# processes, across machines and across Praat versions, which none of Praat's
# own generators promises.
#
# NARROW and WIDE hold the SAME shape at two different scales, which is what
# ruling 10(a)'s replay test needs: the recorded figure and the retargeted one
# must differ only in where the data sits on the axis.
# ---------------------------------------------------------------------------
procedure fixture: .name$, .base, .spread
    .t = Create Table with column names: .name$, 0, "grp val"
    .st = 20260815
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
    .id = .t
endproc

# A NARROW dB AXIS. Values two tenths of a decibel apart put SIX-CHARACTER
# tick labels ("100.10") in the left margin, which is the author's own second
# case for ruling 7 and the threshold @emlDrawAxisNameLeft keys on.
procedure narrowDb: .name$, .withSub
    .t = Create Table with column names: .name$, 0, "grp sub val"
    .r = 0
    for .g from 1 to 2
        for .k from 1 to 12
            .r = .r + 1
            Append row
            Set string value: .r, "grp", "Group " + string$ (.g)
            if .withSub = 1
                Set string value: .r, "sub", "S" + string$ (1 + (.k mod 2))
            else
                Set string value: .r, "sub", "S1"
            endif
            Set numeric value: .r, "val", 100.02 + .g * 0.01 + (.k mod 5) * 0.03
        endfor
    endfor
    .id = .t
endproc

@emit: "leg", leg$

# ===========================================================================
# RULING 10(a) — A RECORDED AUTO AXIS MUST REPLAY AS AUTO
# ===========================================================================
# The recording leg. Draws a violin with the dialog's (0, 0) auto sentinel,
# with a workflow recording running, and flushes the emitted script. What the
# emitted call says in place of that (0, 0) is the whole finding, and
# drawlayer.sh reads it out of the file rather than out of a variable —
# because the file is what a user runs.
# ---------------------------------------------------------------------------
if leg$ = "axis_record"
    @emlRecordInit
    emlRecordPluginRoot$ = root$ + "/plugin"
    @emlRecordBegin: aux$
    emlRecordPluginRoot$ = root$ + "/plugin"
    @emlRecordLoadPhrases: root$ + "/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "narrow", 60, 2, "draw layer"
    @fixture: "narrow", 200, 80
    Erase all
    @emlDrawViolinPlot: fixture.id, "Auto axis", "Group", "Power (dB)",
    ... 6, 4, "color", 1, "grp", "val", 0, 0
    @emit: "record_resolved_min", fixed$ (emlDrawViolinPlot.yMin, 4)
    @emit: "record_resolved_max", fixed$ (emlDrawViolinPlot.yMax, 4)
    @savePic
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emlRecordDiscard

# THE MIRROR OF THE SAME RULING, and the leg that says the repair did not
# simply hardcode the sentinel. A user who TYPES an axis range must get that
# range back in the recorded call -- "always emit 0, 0" would satisfy every
# check on the auto arm and would throw away every explicit axis in the
# plugin. Same recorder, same procedure, one dialog field different.
elsif leg$ = "axis_record_explicit"
    @emlRecordInit
    emlRecordPluginRoot$ = root$ + "/plugin"
    @emlRecordBegin: aux$
    emlRecordPluginRoot$ = root$ + "/plugin"
    @emlRecordLoadPhrases: root$ + "/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "narrow", 60, 2, "draw layer"
    @fixture: "narrow", 200, 80
    Erase all
    @emlDrawViolinPlot: fixture.id, "Explicit axis", "Group", "Power (dB)",
    ... 6, 4, "color", 1, "grp", "val", 150, 400
    @emit: "explicit_resolved_min", fixed$ (emlDrawViolinPlot.yMin, 4)
    @emit: "explicit_resolved_max", fixed$ (emlDrawViolinPlot.yMax, 4)
    @savePic
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emlRecordDiscard

# The retarget control: the SAME call, made natively, against the wide data.
# Whatever the replay produces has to match this file byte for byte, and
# "matches a native draw" is a stronger claim than "is not empty" — an empty
# frame is not empty by accident, it is empty in exactly the way a frozen
# axis makes it empty, and only a comparison against the right answer says
# which of the two happened.
elsif leg$ = "axis_native_wide"
    @fixture: "narrow", 1100, 400
    Erase all
    @emlDrawViolinPlot: fixture.id, "Auto axis", "Group", "Power (dB)",
    ... 6, 4, "color", 1, "grp", "val", 0, 0
    @emit: "native_wide_min", fixed$ (emlDrawViolinPlot.yMin, 4)
    @emit: "native_wide_max", fixed$ (emlDrawViolinPlot.yMax, 4)
    @savePic

# ===========================================================================
# RULING 7 — THE Y-AXIS NAME AND ITS TICK LABELS, IN THE SEVEN CATEGORICAL
# DRAW PROCEDURES THAT DO NOT GO THROUGH @emlDrawAxes
# ===========================================================================
# One leg per procedure, all on the same narrow dB fixture, so a difference
# between two legs is a difference between two procedures and nothing else.
# Each emits what @emlDrawAxisNameLeft decided; drawlayer.sh measures what
# the picture actually shows.
# ---------------------------------------------------------------------------
elsif leg$ = "name_violin"
    @narrowDb: "nd", 0
    Erase all
    @emlDrawViolinPlot: narrowDb.id, "Narrow dB", "Group", "Power (dB)",
    ... 6, 4, "color", 4, "grp", "val", 0, 0
    @emitName

elsif leg$ = "name_box"
    @narrowDb: "nd", 0
    Erase all
    @emlDrawBoxPlot: narrowDb.id, "Narrow dB", "Group", "Power (dB)",
    ... 6, 4, "color", 4, "grp", "val", 0, 0
    @emitName

elsif leg$ = "name_bar"
    @narrowDb: "nd", 0
    Erase all
    @emlDrawBarChart: narrowDb.id, "Narrow dB", "Group", "Power (dB)",
    ... 6, 4, "color", 4, "grp", "val", 1, "", 100, 100.2
    @emitName

elsif leg$ = "name_gviolin"
    @narrowDb: "nd", 1
    Erase all
    @emlDrawGroupedViolin: narrowDb.id, "Narrow dB", "Group", "Power (dB)",
    ... 6, 4, "color", 4, "grp", "sub", "val", 0, 0
    @emitName

elsif leg$ = "name_gbox"
    @narrowDb: "nd", 1
    Erase all
    @emlDrawGroupedBoxPlot: narrowDb.id, "Narrow dB", "Group", "Power (dB)",
    ... 6, 4, "color", 4, "grp", "sub", "val", 0, 0
    @emitName

# The spaghetti plot wants a condition, a value and a subject id, so its
# fixture is built here rather than shared.
elsif leg$ = "name_spaghetti"
    t = Create Table with column names: "sp", 0, "cond val id"
    r = 0
    for s from 1 to 8
        for c from 1 to 3
            r = r + 1
            Append row
            Set string value: r, "cond", "C" + string$ (c)
            Set string value: r, "id", "S" + string$ (s)
            Set numeric value: r, "val", 100.02 + c * 0.03 + (s mod 4) * 0.02
        endfor
    endfor
    Erase all
    @emlDrawSpaghettiPlot: t, "Narrow dB", "Condition", "Power (dB)",
    ... 6, 4, "color", 4, "cond", "val", "id", "", 1, 0, 0
    @emitName

# The faceted histogram's y-axis is a COUNT, so its tick labels reach six
# characters only past a hundred thousand observations. .freqMax is the
# dialog's own y-max field and reaches the same axis without the rows, which
# is how a case that is real but not cheap gets driven at all.
elsif leg$ = "name_hist"
    t = Create Table with column names: "hf", 0, "grp val"
    r = 0
    for g from 1 to 3
        for k from 1 to 40
            r = r + 1
            Append row
            Set string value: r, "grp", "G" + string$ (g)
            Set numeric value: r, "val", 100.02 + (k mod 9) * 0.03
        endfor
    endfor
    Erase all
    @emlDrawHistogram: t, "Faceted", "Power (dB)", "Count", 6, 4,
    ... "color", 1, "val", "grp", 8, 2, 0, 0, 300000
    @emitName

# THE CONTROL, AND IT IS THE POINT. An ordinary figure — labels of four and
# five characters — must not move by one pixel. A repair that widened the
# margin unconditionally would satisfy every leg above and change every
# figure this plugin has ever drawn.
elsif leg$ = "name_plain"
    @fixture: "plain", 200, 80
    Erase all
    @emlDrawViolinPlot: fixture.id, "Ordinary", "Group", "f0 (Hz)",
    ... 6, 4, "color", 4, "grp", "val", 0, 0
    @emitName

# ===========================================================================
# RULING 1b — WHAT THE ANNOTATED FIGURE SAYS ABOUT FAMILY-WISE CONTROL
# ===========================================================================
# Both arms of the same comparison, four groups so the matrix layout is the
# one that carries the disclosure sub-line. The string is emitted AND the
# figure is rendered, because a subtitle that is correct and too wide for the
# canvas is not a disclosure either.
# ---------------------------------------------------------------------------
elsif leg$ = "posthoc_tukey" or leg$ = "posthoc_dunn"
    t = Create Table with column names: "ph", 0, "grp val"
    r = 0
    for g from 1 to 4
        for k from 1 to 10
            r = r + 1
            Append row
            Set string value: r, "grp", "Cohort " + string$ (g)
            Set numeric value: r, "val", 100 + g * 6 + (k mod 5) * 1.5
        endfor
    endfor
    Erase all
    @emlDrawViolinPlot: t, "Post-hoc disclosure", "Cohort", "Power (dB)",
    ... 6, 4, "color", 1, "grp", "val", 0, 0
    if leg$ = "posthoc_tukey"
        @emlRunAnnotationComparison: t, "val", "grp", 0.05, "stars", 1, 1,
        ... "parametric", 3
    else
        annotCorrectionMethod$ = "holm"
        @emlRunAnnotationComparison: t, "val", "grp", 0.05, "stars", 1, 1,
        ... "nonparametric", 3
    endif
    @emit: "posthoc_label", annotMatrixPosthoc$
    figure_width = 6
    figure_height = 4
    mFontInch = emlSetAdaptiveTheme.matrixSize / 72
    mEstHeight = mFontInch * (6 + annotMatrixN * 2.5)
    if mEstHeight < 1.0
        mEstHeight = 1.0
    endif
    @emlMeasureMatrixLayout: 0, figure_width, figure_height,
    ... figure_height + mEstHeight, emlSetAdaptiveTheme.matrixSize
    @emlDrawMatrixPanel: 0, figure_width, figure_height + 0.1,
    ... figure_height + 0.1 + emlMatrixLayout_yMax,
    ... emlSetAdaptiveTheme.matrixSize, "color"
    @emit: "posthoc_subtitle", emlDrawMatrixPanel.sub$
    Font size: emlSetAdaptiveTheme.matrixSize
    subMM = Text width (mm): emlDrawMatrixPanel.sub$
    @emit: "posthoc_subtitle_mm", fixed$ (subMM, 2)
    @emit: "posthoc_canvas_mm", fixed$ (figure_width * 25.4, 2)
    @savePic

# ===========================================================================
# RULING 6 — NO RAW DOUBLE REACHES THE INFO WINDOW
# ===========================================================================
# THE DEGENERATE LEG. Three groups with identical means. Every pairwise
# difference, every Cohen's d and the omnibus F are exact zeros, which is the
# input Praat's fixed$ answers with a bare "0" — the spelling that does not
# line up with a column of "3.0871"-shaped neighbours.
# ---------------------------------------------------------------------------
elsif leg$ = "info_degenerate"
    t = Create Table with column names: "ident", 0, "grp val"
    r = 0
    for g from 1 to 3
        for k from 1 to 8
            r = r + 1
            Append row
            Set string value: r, "grp", "G" + string$ (g)
            Set numeric value: r, "val", 10 + k
        endfor
    endfor
    writeInfoLine: "degenerate"
    selectObject: t
    @emlRunAnovaAnalysis: t, "val", "grp", 1
    @emlRunKruskalWallisAnalysis: t, "val", "grp", 1, "holm"

# THE TINY LEG. Values a few ulps from zero, which is what a real measurement
# that cancels looks like. This is where fixed$ escalates PAST the precision
# it was given: seventeen decimals in a column padded for sixteen characters,
# so the SS cell runs into the MS cell.
elsif leg$ = "info_tiny"
    tw = Create Table with column names: "tw", 0, "f1 f2 val"
    r = 0
    for i from 1 to 2
        for j from 1 to 2
            for k from 1 to 5
                r = r + 1
                Append row
                Set string value: r, "f1", "A" + string$ (i)
                Set string value: r, "f2", "B" + string$ (j)
                Set numeric value: r, "val", (0.1 + 0.2 - 0.3) * (k + i + j)
            endfor
        endfor
    endfor
    pr = Create Table with column names: "pr", 0, "a b"
    for k from 1 to 10
        Append row
        Set numeric value: k, "a", (0.1 + 0.2 - 0.3) * k
        Set numeric value: k, "b", (0.1 + 0.2 - 0.3) * k * 2
    endfor
    writeInfoLine: "tiny"
    selectObject: tw
    @emlRunTwoWayAnalysis: tw, "val", "f1", "f2"
    selectObject: pr
    @emlRunPairedAnalysis: pr, "a", "b", "parametric"

# THE REAL LEG, AND IT IS THE TRAP THIS FILE IS BUILT AROUND. Well separated
# groups and a genuine linear relationship. A formatter that "fixed" every
# width by returning a zero of the right shape would pass every width check
# in v66 §3 and go red all over §4, where these printed numbers are compared
# against values recomputed in R. The CSV rows are dumped beside the report
# from the SAME run, so §5 can assert that the export still carries more
# precision than the report — which is where the ruling puts it, and the
# other way this could be "fixed" wrongly.
elsif leg$ = "info_real"
    t = Create Table with column names: "real", 0, "grp val x y"
    r = 0
    for g from 1 to 3
        for k from 1 to 10
            r = r + 1
            Append row
            Set string value: r, "grp", "G" + string$ (g)
            Set numeric value: r, "val", 10 + g * 4.5 + (k mod 5) * 0.7
            Set numeric value: r, "x", r
            Set numeric value: r, "y", 3.25 + 1.7 * r + (k mod 3) * 0.4
        endfor
    endfor
    writeInfoLine: "real"
    selectObject: t
    @emlRunAnovaAnalysis: t, "val", "grp", 1
    @dumpCsv: "anova"
    selectObject: t
    @emlRunRegressionAnalysis: t, "y", "x"
    @dumpCsv: "reg"
    selectObject: t
    @emlRunCorrelationAnalysis: t, "x", "y", "pearson"
    @dumpCsv: "corr"

# THE NORMALITY WRAPPER'S PER-GROUP BRANCH, which is the twin of a wizard
# line already repaired. It lives in a form-driven script, so what is driven
# here is the same shared machinery on the same shape of data: a symmetric
# column whose skewness is a few ulps from zero, and a strongly skewed one
# whose Shapiro-Wilk p is far past the APA floor.
elsif leg$ = "info_normality"
    t = Create Table with column names: "nm", 0, "sym skew"
    for k from 1 to 24
        Append row
        Set numeric value: k, "sym", k - 12.5
        Set numeric value: k, "skew", exp ((k - 1) / 3)
    endfor
    writeInfoLine: "normality"
    selectObject: t
    @emlRunNormalityAnalysis: t, "sym", ""
    selectObject: t
    @emlRunNormalityAnalysis: t, "skew", ""

# ===========================================================================
# RULING 8c — THE ONE-BIN SPECTRUM. MEASURED, NOT REPAIRED.
# ===========================================================================
# Reported here so the finding is on the record from this side as well; v66
# prints it and asserts only the facts, never the repair, because the choice
# between drawing a stem and refusing with a message is the author's.
# ---------------------------------------------------------------------------
elsif leg$ = "onebin" or leg$ = "twobin"
    snd = Create Sound from formula: "tone", 1, 0, 1.4861, 44100,
    ... "0.9 * sin (2 * pi * 1000 * x)"
    spec = To Spectrum: "yes"
    df = Get bin width
    if leg$ = "onebin"
        lo = 999.90
        hi = 1000.10
    else
        lo = 999.40
        hi = 1000.90
    endif
    n1 = Get bin number from frequency: lo
    n2 = Get bin number from frequency: hi
    lowb = ceiling (n1)
    highb = floor (n2)
    peak = -1000
    for b from lowb to highb
        re = Get real value in bin: b
        im = Get imaginary value in bin: b
        pw = re * re + im * im
        if pw > 0
            dbv = 10 * log10 (pw / 4e-10)
            if dbv > peak
                peak = dbv
            endif
        endif
    endfor
    @emit: leg$ + "_bin_width", fixed$ (df, 6)
    @emit: leg$ + "_bins_in_range", string$ (highb - lowb + 1)
    @emit: leg$ + "_peak_db", fixed$ (peak, 2)
    selectObject: spec
    Erase all
    @emlDrawSpectrum: spec, "1 kHz tone", "Frequency (Hz)", "Power (dB)",
    ... 6, 4, "color", 1, lo, hi, 0, 100
    @savePic

# ===========================================================================
# RULING 8c AT THE SECOND SITE — THE ONE-BIN LTAS CURVE.
# ===========================================================================
# THE SAME DEFECT, MORE REACHABLE, AND WITH A CONTROL THE SPECTRUM DOES NOT
# HAVE. A Spectrum's bin width is 1/duration and nothing can be done about it;
# an Ltas bin width is the bandwidth the CALLER asked for, so 100 Hz -- the
# form's own default -- puts one bin in any 100 Hz window at any recording
# length. Three legs, and the third is what makes the finding an argument
# rather than an observation:
#
#   ltas_onebin       one bin in the window, "Curve" only. Before the repair
#                     this was a fully furnished frame with nothing in it.
#   ltas_twobin       the same figure one bin wider, "Curve" only. It draws
#                     normally, which says the finding is about the COUNT.
#   ltas_onebin_bars  the SAME one bin, "Bars" only. It draws. Which says the
#                     finding is about the STYLE and not about the bin, the
#                     window, the data or the axis -- and that is the thing no
#                     amount of staring at the empty figure could establish.
#
# THE WINDOWS ARE 1000..1100 AND 1000..1200, and the numbers are not arbitrary:
# with `To Ltas: 100` the bin centres sit at 50, 150, ... 1050, 1150, so the
# first window holds exactly bin #11 and the second holds #11 and #12. The
# probe emits the count it measured rather than the count it assumed, and v66
# asserts that count, because a fixture that quietly stopped being a one-bin
# fixture would turn this whole section green for the wrong reason.
elsif leg$ = "ltas_onebin" or leg$ = "ltas_twobin"
... or leg$ = "ltas_onebin_bars"
    snd = Create Sound from formula: "tone", 1, 0, 1.4861, 44100,
    ... "0.9 * sin (2 * pi * 1000 * x)"
    ltas = To Ltas: 100
    df = Get bin width
    lo = 1000
    if leg$ = "ltas_twobin"
        hi = 1200
    else
        hi = 1100
    endif
    n1 = Get bin number from frequency: lo
    n2 = Get bin number from frequency: hi
    lowb = ceiling (n1)
    highb = floor (n2)
    peak = -1000
    for b from lowb to highb
        v = Get value in bin: b
        if v <> undefined
            if v > peak
                peak = v
            endif
        endif
    endfor
    @emit: leg$ + "_bin_width", fixed$ (df, 6)
    @emit: leg$ + "_bins_in_range", string$ (highb - lowb + 1)
    @emit: leg$ + "_peak_db", fixed$ (peak, 2)
    # showCurve, showBars, showPoles, showSpeckles. The bars leg turns Curve
    # OFF, so the ink it measures is Praat's own bar and nothing of this
    # change's making.
    curve = 1
    bars = 0
    if leg$ = "ltas_onebin_bars"
        curve = 0
        bars = 1
    endif
    # GRIDLINES OFF, AND THAT IS A MEASUREMENT DECISION, NOT A TASTE ONE.
    # This leg's verdict is the HEIGHT of the mark, taken as the top row of
    # ink inside the frame. A horizontal gridline runs the full width of the
    # panel at 20, 40, 60, 80 and 100 dB, and every one of them is above a
    # 66.95 dB mark -- so with the grid on, the top row of ink is a gridline
    # on every figure and the measurement reports the theme rather than the
    # data. gridMode 4 is "off"; nothing else about the figure changes.
    selectObject: ltas
    Erase all
    @emlDrawLTAS: ltas, "1 kHz tone", "Frequency (Hz)", "Power (dB)",
    ... 6, 4, "color", 4, lo, hi, 0, 100, curve, bars, 0, 0
    @savePic
    # WHAT THE PROCEDURE ITSELF DECIDED, so that "the stem was drawn" is read
    # from the branch that draws it and not inferred from a pixel count. Ink
    # alone cannot tell a stem from a bar; this can.
    if curve = 1
        @emit: leg$ + "_curve_bins", string$ (emlDrawLTAS.curveBins)
        @emit: leg$ + "_curve_stem", string$ (emlDrawLTAS.curveStemDrawn)
    endif

else
    @emit: "unknown_leg", leg$
endif

# ---------------------------------------------------------------------------
# @emitName — what @emlDrawAxisNameLeft decided, for whichever leg just ran.
#
# The three outputs are the whole decision: how wide the widest six-character
# tick label was, how far the name was moved, and whether the panel had less
# room than the labels needed. A leg whose widest label is 0 must show a
# shift of 0; that pairing is what separates "the guard did nothing because
# nothing was needed" from "the guard did nothing".
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# @dumpCsv — the export rows of the orchestrator that just ran.
#
# THE OTHER FIX-SHAPED FIX. A repair that satisfied every width check by
# ROUNDING THE DATA rather than the display would leave the report looking
# right and the CSV -- the artefact the ruling reserves full precision for --
# quietly ruined. @emlCSVInit resets the row buffer at every orchestrator, so
# the dump is taken after each one rather than once at the end.
# ---------------------------------------------------------------------------
procedure dumpCsv: .tag$
    for .i from 1 to emlCSV_n
        @emit: "csv_" + .tag$, emlCSV_row$ [.i]
    endfor
endproc

procedure emitName
    # THE PICTURE IS SAVED FIRST, AND THE ORDER IS LOAD-BEARING. Reading
    # emlDrawAxisNameLeft.shiftInch is itself a test of whether the procedure
    # was reached: on a tree where the site still draws a bare `Text left` the
    # variable does not exist and Praat aborts the leg at that line. Saving
    # after it would mean the broken tree produced NO FIGURE, and "no figure"
    # and "a figure with a four-pixel gap" are different findings -- the
    # second is the one this rig has to be able to show.
    @savePic
    @emit: "widest_label_mm", fixed$ (emlDrawAlignedMarksLeft.maxWideLabelMM, 3)
    @emit: "shift_inch", fixed$ (emlDrawAxisNameLeft.shiftInch, 4)
    @emit: "room_inch", fixed$ (emlDrawAxisNameLeft.roomInch, 4)
    @emit: "clamped", string$ (emlDrawAxisNameLeft.clamped)
endproc
