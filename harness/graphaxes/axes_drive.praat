# ============================================================================
# harness/graphaxes/axes_drive.praat — the axis, the clip and the panel
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Four legs, one per finding, each in its own process (see axes.sh). Every
# number that matters is written to $EML_AXES_OUT as key<TAB>value so a
# validator reads measurements rather than parsing a picture.
#
# NONE OF THIS NEEDS A DISPLAY. The draw procedures call no beginPause:, which
# is what lets a figure be rendered and measured in a container with no X
# server. The stereo gate is the exception and lives in stereo.sh.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

@emlInitDrawingDefaults

leg$ = environment$ ("EML_AXES_LEG")
out$ = environment$ ("EML_AXES_OUT")
pic$ = environment$ ("EML_AXES_PIC")
if out$ = ""
    exitScript: "EML_AXES_OUT unset."
endif

procedure emit: .key$, .value$
    appendFileLine: out$, .key$, tab$, .value$
endproc

# A LABEL THAT IS DELIBERATELY EMPTY IS STILL A RESULT. `appendFileLine` with
# an empty value writes a line with a trailing tab and nothing after it, and a
# TSV reader that splits on tabs sees ONE field and drops the row -- so
# "@emlTickLabelWidth declined to model this" would arrive at the validator as
# "the harness never ran that case". The two are opposite verdicts. Written as
# a visible token instead.
procedure emitLabel: .key$, .text$
    if .text$ = ""
        @emit: .key$, "<not modelled>"
    else
        @emit: .key$, .text$
    endif
endproc

procedure savePic
    if pic$ <> ""
        select all
        .n = numberOfSelected ()
        if .n > 0
            Remove
        endif
        @emlAssertFullViewport
        Save as 300-dpi PNG file: pic$
    endif
endproc

@emit: "leg", leg$

# ---------------------------------------------------------------------------
# STEADY — NEW-G7-1. A rock-steady 200 Hz tone drawn as an F0 contour. The
# pitch values are exact to eleven decimals; what failed was the axis.
# ---------------------------------------------------------------------------
if leg$ = "steady"
    snd = Create Sound from formula: "steady200", 1, 0, 1.0, 44100,
    ... "0.5*sin(2*pi*200*x)"
    pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no",
    ... 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
    pMin = Get minimum: 0, 0, "Hertz", "parabolic"
    pMax = Get maximum: 0, 0, "Hertz", "parabolic"
    @emit: "steady_data_span", fixed$ (pMax - pMin, 9)
    @emit: "steady_data_min", fixed$ (pMin, 6)
    @emit: "steady_data_max", fixed$ (pMax, 6)
    Erase all
    @emlDrawF0Contour: pit, "Steady 200 Hz", "Time (s)", "F0 (Hz)",
    ... 6, 4, "color", 4, 0, 0, 0, 0, 1
    @emit: "steady_axis_min", fixed$ (emlDrawF0Contour.freqMin, 6)
    @emit: "steady_axis_max", fixed$ (emlDrawF0Contour.freqMax, 6)
    @emit: "steady_axis_span",
    ... fixed$ (emlDrawF0Contour.freqMax - emlDrawF0Contour.freqMin, 6)
    removeObject: snd
    @savePic

# ---------------------------------------------------------------------------
# RAMP2 — the regression guard. The verifier established that a 2 Hz span
# ALREADY drew correctly, on 198.5 to 201.5 with half-hertz ticks. A floor
# that moved this figure would be a fix that broke a working one.
# ---------------------------------------------------------------------------
elsif leg$ = "ramp2"
    snd = Create Sound from formula: "ramp2hz", 1, 0, 1.0, 44100,
    ... "0.5*sin(2*pi*(199*x+1*x*x))"
    pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no",
    ... 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
    pMin = Get minimum: 0, 0, "Hertz", "parabolic"
    pMax = Get maximum: 0, 0, "Hertz", "parabolic"
    @emit: "ramp2_data_span", fixed$ (pMax - pMin, 6)
    Erase all
    @emlDrawF0Contour: pit, "Ramp 2 Hz", "Time (s)", "F0 (Hz)",
    ... 6, 4, "color", 4, 0, 0, 0, 0, 1
    @emit: "ramp2_axis_min", fixed$ (emlDrawF0Contour.freqMin, 6)
    @emit: "ramp2_axis_max", fixed$ (emlDrawF0Contour.freqMax, 6)
    removeObject: snd
    @savePic

# ---------------------------------------------------------------------------
# TICKS — @emlTickPrecision over four axes. Three of them are ordinary and
# must be left to Praat; one is the narrow-and-far-from-zero shape that
# Praat's four significant digits cannot label.
# ---------------------------------------------------------------------------
elsif leg$ = "ticks"
    @emlSetAdaptiveTheme: 6, 4
    # 1: an ordinary percentage axis.
    @emlTickPrecision: 0, 100, 20
    @emit: "tick_ordinary_explicit", string$ (emlTickPrecision.explicit)
    # 2: an ordinary pitch axis.
    @emlTickPrecision: 75, 500, 50
    @emit: "tick_pitch_explicit", string$ (emlTickPrecision.explicit)
    # 3: a time axis in seconds.
    @emlTickPrecision: 0, 1, 0.1
    @emit: "tick_time_explicit", string$ (emlTickPrecision.explicit)
    # 4: the sustained-note shape. 199.98 to 200.02, step 0.005.
    @emlTickPrecision: 199.98, 200.02, 0.005
    @emit: "tick_narrow_explicit", string$ (emlTickPrecision.explicit)
    @emit: "tick_narrow_decimals", string$ (emlTickPrecision.decimals)
    # What the label would read as, written by the plugin rather than Praat.
    @emit: "tick_narrow_label_a", fixed$ (199.995, emlTickPrecision.decimals)
    @emit: "tick_narrow_label_b", fixed$ (200.000, emlTickPrecision.decimals)
    @emit: "tick_narrow_label_c", fixed$ (200.005, emlTickPrecision.decimals)

# ---------------------------------------------------------------------------
# CLIP — NEW-G8-1 and NEW-G8-2. The same 30 rows drawn twice: once on the
# automatic axis, once on a range the user typed that excludes five of them.
# The statistics of the two draws must be IDENTICAL. A range is a viewport.
# ---------------------------------------------------------------------------
elsif leg$ = "clip"
    t = Create Table with column names: "clip", 30, "x y"
    for i from 1 to 30
        selectObject: t
        xv = 90 + (i - 1) * 8
        yv = 2 * xv + 5 + (i mod 5) * 3
        Set numeric value: i, "x", xv
        Set numeric value: i, "y", yv
    endfor
    # Automatic axis: nothing may be withheld.
    Erase all
    @emlDrawScatterPlot: t, "Auto", "X", "Y", 6, 4, "color", 4,
    ... "x", "y", "", 0, 0, 0, 0, 1
    @emit: "clip_auto_outside", string$ (emlDrawScatterPlot.nOutside)
    @emit: "clip_auto_r", fixed$ (emlDrawScatterPlot.pearsonR, 10)
    @emit: "clip_auto_n", string$ (emlDrawScatterPlot.nValid)
    # User range 100 to 300 over data running 90 to 322.
    Erase all
    @emlDrawScatterPlot: t, "Clipped", "X", "Y", 6, 4, "color", 4,
    ... "x", "y", "", 100, 300, 0, 0, 1
    @emit: "clip_set_outside", string$ (emlDrawScatterPlot.nOutside)
    @emit: "clip_set_r", fixed$ (emlDrawScatterPlot.pearsonR, 10)
    @emit: "clip_set_n", string$ (emlDrawScatterPlot.nValid)
    @emit: "clip_set_axis_min", fixed$ (emlDrawScatterPlot.axisXMin, 3)
    @emit: "clip_set_axis_max", fixed$ (emlDrawScatterPlot.axisXMax, 3)
    # Did the disclosure fire, and did it name the range in force?
    @emit: "clip_disclosed_n", string$ (emlDiscloseInfoN)
    @savePic

# ---------------------------------------------------------------------------
# COLLIDE — NEW-G8-4. A cloud whose EMPTIEST QUADRANT is not its emptiest
# CORNER. Quadrant scoring puts the panel on a datum; rectangle scoring does
# not. Both answers are recorded, from the same figure, in the same pass.
# ---------------------------------------------------------------------------
elsif leg$ = "collide"
    annotate = 1
    t = Create Table with column names: "collide", 23, "x y"
    for i from 1 to 20
        selectObject: t
        Set numeric value: i, "x", 10 + (i - 1) * 4
        Set numeric value: i, "y", 10 + (i - 1) * 4
    endfor
    selectObject: t
    # One point in the top-left corner, inside where the panel is drawn.
    Set numeric value: 21, "x", 15
    Set numeric value: 21, "y", 100
    # Two in the bottom-right QUADRANT but nowhere near its corner, so the
    # quadrant score prefers top-left and the rectangle score does not.
    Set numeric value: 22, "x", 55
    Set numeric value: 22, "y", 30
    Set numeric value: 23, "x", 60
    Set numeric value: 23, "y", 25
    Erase all
    @emlDrawScatterPlot: t, "Collision probe", "X", "Y", 6, 4, "color", 4,
    ... "x", "y", "", 0, 0, 0, 0, 1
    @emit: "collide_quadrant_corner", emlPlaceElements.corner1$
    @emit: "collide_box_corner", emlPlaceAnnotationBox.corner1$
    @emit: "collide_box_collisions",
    ... string$ (emlPlaceAnnotationBox.collisions)
    @emit: "collide_hits_top_left", string$ (emlPlaceAnnotationBox.hit[1])
    @emit: "collide_hits_top_right", string$ (emlPlaceAnnotationBox.hit[2])
    @emit: "collide_hits_bottom_left", string$ (emlPlaceAnnotationBox.hit[3])
    @emit: "collide_hits_bottom_right", string$ (emlPlaceAnnotationBox.hit[4])
    @emit: "collide_registered", string$ (emlCollideN)
    @savePic

# ---------------------------------------------------------------------------
# MARGIN_ST — RULING 7, the author's first case. A sustained C2 drawn on a
# SEMITONE axis: the axis runs around -33, the nice step is a hundredth of a
# semitone, and Praat's own four significant digits render "-33.08" — six
# characters, into a margin band that holds about five. @emlTickPrecision does
# NOT engage here (2 integer digits + 2 decimals = 4), which is exactly why
# the guard cannot be hung off .explicit alone.
#
# The gap itself is not measured in Praat — no script can read back a pixel —
# so the figure is saved and axes.sh measures the column profile. What IS
# emitted here is the arithmetic the plugin used to decide, so the two can be
# compared: a shift that is computed and not drawn, or drawn and not needed,
# shows up as a disagreement between the mm here and the pixels there.
# ---------------------------------------------------------------------------
elsif leg$ = "margin_st"
    snd = Create Sound from formula: "c2", 1, 0, 1.0, 44100,
    ... "0.5*sin(2*pi*65.406*x)"
    pit = To Pitch (filtered autocorrelation): 0, 50, 300, 15, "no",
    ... 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
    Erase all
    @emlDrawF0Contour: pit, "Sustained C2", "Time (s)",
    ... "F0 (semitones re 440 Hz)", 6, 4, "color", 4, 0, 0, 0, 0, 2
    @emit: "margin_st_axis_min", fixed$ (emlDrawF0Contour.freqMin, 4)
    @emit: "margin_st_axis_max", fixed$ (emlDrawF0Contour.freqMax, 4)
    @emit: "margin_st_tick_explicit",
    ... string$ (emlDrawAlignedMarksLeft.tickExplicit)
    @emit: "margin_st_widest_label_mm",
    ... fixed$ (emlDrawAlignedMarksLeft.maxWideLabelMM, 3)
    @emit: "margin_st_shift_inch",
    ... fixed$ (emlDrawAxisNameLeft.shiftInch, 4)
    @emit: "margin_st_room_inch",
    ... fixed$ (emlDrawAxisNameLeft.roomInch, 4)
    @emit: "margin_st_clamped", string$ (emlDrawAxisNameLeft.clamped)
    removeObject: snd
    @savePic

# ---------------------------------------------------------------------------
# MARGIN_DB — RULING 7, the author's second case, and the other half of the
# trigger. A Spectrum drawn on a dB window two tenths wide: three integer
# digits and two decimals, so @emlTickPrecision DOES engage, the plugin writes
# "100.10" itself, and six characters arrive by the other route.
# ---------------------------------------------------------------------------
elsif leg$ = "margin_db"
    snd = Create Sound from formula: "tone", 1, 0, 0.5, 44100,
    ... "0.5*sin(2*pi*1000*x)"
    spec = To Spectrum: "yes"
    Erase all
    @emlDrawSpectrum: spec, "Narrow dB window", "Frequency (Hz)",
    ... "Power (dB)", 6, 4, "color", 4, 0, 5000, 100, 100.2
    @emit: "margin_db_tick_explicit",
    ... string$ (emlDrawAlignedMarksLeft.tickExplicit)
    @emit: "margin_db_tick_decimals",
    ... string$ (emlDrawAlignedMarksLeft.tickDecimals)
    @emit: "margin_db_widest_label_mm",
    ... fixed$ (emlDrawAlignedMarksLeft.maxWideLabelMM, 3)
    @emit: "margin_db_shift_inch",
    ... fixed$ (emlDrawAxisNameLeft.shiftInch, 4)
    @emit: "margin_db_room_inch",
    ... fixed$ (emlDrawAxisNameLeft.roomInch, 4)
    @emit: "margin_db_clamped", string$ (emlDrawAxisNameLeft.clamped)
    removeObject: snd
    @savePic

# ---------------------------------------------------------------------------
# MARGIN_PLAIN — THE FIGURE THAT MUST NOT MOVE. The same draw path, the same
# procedure, an ordinary axis whose ticks are two characters wide. A fix that
# widened the margin unconditionally would satisfy every "no collision" test
# above and would change this figure too, so the shift is asserted to be
# exactly zero and the picture is kept for the byte comparison.
# ---------------------------------------------------------------------------
elsif leg$ = "margin_plain"
    t = Create Table with column names: "plain", 12, "x y"
    for i from 1 to 12
        selectObject: t
        Set numeric value: i, "x", i
        Set numeric value: i, "y", 20 + i * 5
    endfor
    Erase all
    @emlDrawScatterPlot: t, "Ordinary figure", "X", "Y", 6, 4, "color", 4,
    ... "x", "y", "", 0, 0, 0, 0, 0
    @emit: "margin_plain_widest_label_mm",
    ... fixed$ (emlDrawAlignedMarksLeft.maxWideLabelMM, 3)
    @emit: "margin_plain_shift_inch",
    ... fixed$ (emlDrawAxisNameLeft.shiftInch, 4)
    @emit: "margin_plain_room_inch",
    ... fixed$ (emlDrawAxisNameLeft.roomInch, 4)
    @emit: "margin_plain_clamped", string$ (emlDrawAxisNameLeft.clamped)
    @savePic

# ---------------------------------------------------------------------------
# MARGIN_PANEL — THE CLAMP, EXERCISED. A 3 x 2 panel is small enough that the
# axis name has about a hundredth of an inch of room inside it before Praat's
# own fixed allocation runs out of panel. The shift is limited to that room,
# so the collision is only partly relieved there and NOTHING IS CUT ON EXPORT
# — which is the trade @emlDrawAxisNameLeft's header argues for. Without the
# clamp this figure loses a fifth of an inch off the axis name's left side,
# because Praat saves the selected outer viewport and saves nothing outside it.
# ---------------------------------------------------------------------------
elsif leg$ = "margin_panel"
    t = Create Table with column names: "panel", 12, "x y"
    for i from 1 to 12
        selectObject: t
        Set numeric value: i, "x", i
        Set numeric value: i, "y", 100.02 + (i mod 5) * 0.03
    endfor
    Erase all
    @emlDrawScatterPlot: t, "Small panel", "X", "Power (dB)", 3, 2,
    ... "color", 4, "x", "y", "", 0, 0, 0, 0, 0
    @emit: "margin_panel_widest_label_mm",
    ... fixed$ (emlDrawAlignedMarksLeft.maxWideLabelMM, 3)
    @emit: "margin_panel_shift_inch",
    ... fixed$ (emlDrawAxisNameLeft.shiftInch, 4)
    @emit: "margin_panel_room_inch",
    ... fixed$ (emlDrawAxisNameLeft.roomInch, 4)
    @emit: "margin_panel_clamped", string$ (emlDrawAxisNameLeft.clamped)
    @savePic

# ---------------------------------------------------------------------------
# MARGIN_CAT — THE SAME COLLISION, AT A DOOR THIS CHANGE MAY NOT TOUCH. The
# six categorical draw procedures (bar, violin, box, spaghetti, histogram,
# grouped violin, grouped box) do not call @emlDrawAxes: they draw their own
# axis name with a bare `Text left`, in eml-draw-procedures.praat, which is
# another hand's file this turn. A violin of dB values two tenths of a dB
# apart is the same shape as the author's second case, and it is rendered here
# so the divergence is a measured number in the evidence rather than a remark
# in a report. Not asserted either way — see validate/v62 section 6.
# ---------------------------------------------------------------------------
elsif leg$ = "margin_cat"
    t = Create Table with column names: "cat", 24, "grp val"
    for i from 1 to 24
        selectObject: t
        if i <= 12
            Set string value: i, "grp", "A"
            Set numeric value: i, "val", 100.02 + (i mod 5) * 0.03
        else
            Set string value: i, "grp", "B"
            Set numeric value: i, "val", 100.05 + (i mod 4) * 0.03
        endif
    endfor
    Erase all
    @emlDrawViolinPlot: t, "Narrow dB", "Group", "Power (dB)", 6, 4,
    ... "color", 4, "grp", "val", 0, 0
    @emit: "margin_cat_widest_label_mm",
    ... fixed$ (emlDrawAlignedMarksLeft.maxWideLabelMM, 3)
    @savePic

# ---------------------------------------------------------------------------
# TICKLABEL — @emlTickLabelWidth on its own, over the four shapes that decide
# whether the guard can see a label at all. The predictor is the one part of
# ruling 7 that models Praat rather than measuring it, so what it predicts is
# put on the record next to what Praat draws (aud: fmt probes, 15 Aug 2026).
# ---------------------------------------------------------------------------
elsif leg$ = "ticklabel"
    @emlSetAdaptiveTheme: 6, 4
    # Praat's own four significant digits, inside the plain-decimal window.
    @emlTickLabelWidth: -33.08, 0, 0
    @emitLabel: "ticklabel_auto_neg", emlTickLabelWidth.text$
    @emlTickLabelWidth: 100, 0, 0
    @emitLabel: "ticklabel_auto_100", emlTickLabelWidth.text$
    @emlTickLabelWidth: 0.05, 0, 0
    @emitLabel: "ticklabel_auto_005", emlTickLabelWidth.text$
    # The plugin's own string when @emlTickPrecision has engaged.
    @emlTickLabelWidth: 100.1, 1, 2
    @emitLabel: "ticklabel_explicit", emlTickLabelWidth.text$
    @emit: "ticklabel_explicit_chars", string$ (emlTickLabelWidth.chars)
    # OUTSIDE THE WINDOW: Praat writes "10^9", not ten digits. The predictor
    # must decline, or violin_hugevalues moves for nothing.
    @emlTickLabelWidth: 1e9, 0, 0
    @emitLabel: "ticklabel_huge", emlTickLabelWidth.text$
    @emit: "ticklabel_huge_mm", fixed$ (emlTickLabelWidth.mm, 3)
    @emlTickLabelWidth: 2.1e-9, 0, 0
    @emitLabel: "ticklabel_tiny", emlTickLabelWidth.text$
    @emit: "ticklabel_tiny_mm", fixed$ (emlTickLabelWidth.mm, 3)

# ---------------------------------------------------------------------------
# COERCE — RULING 5, door 3. A Matrix through the graphs coercion. The cell is
# col * 100 + row, as v63's probe writes it, so `value div 100` recovers the
# SOURCE column index from any cell and the check reduces to: does Column_k
# hold column k? Emitted as one row per manufactured header.
# ---------------------------------------------------------------------------
elsif leg$ = "coerce"
    mx = Create simple Matrix: "g7coerce", 4, 3, "col * 100 + row"
    selectObject: mx
    @emlConvertForGraph: mx, "Table", 75, 600
    tb = emlConvertForGraph.result
    selectObject: tb
    nCol = Get number of columns
    nRow = Get number of rows
    @emit: "coerce_ncols", string$ (nCol)
    for i from 1 to nCol
        selectObject: tb
        lab$ = Get column label: i
        selectObject: tb
        cell$ = Get value: 1, lab$
        @emit: "coerce_pos" + string$ (i) + "_header", lab$
        @emit: "coerce_pos" + string$ (i) + "_row1", cell$
    endfor
    for r from 1 to nRow
        selectObject: tb
        lab1$ = Get column label: 1
        selectObject: tb
        cell$ = Get value: r, lab1$
        @emit: "coerce_rowlabel_" + string$ (r), cell$
    endfor

# ---------------------------------------------------------------------------
# ONEBIN — RULING 8c, CHASED AND MEASURED, NOT REPAIRED. A Spectrum drawn over
# a range that contains ONE bin renders an empty frame with axis furniture
# only. The numbers that say why are emitted here; whether the answer is to
# draw the bin, widen the range or refuse is the author's call, and nothing in
# this tree implements any of them yet.
# ---------------------------------------------------------------------------
elsif leg$ = "onebin"
    snd = Create Sound from formula: "tone", 1, 0, 1.0, 44100,
    ... "0.5*sin(2*pi*1000*x)"
    spec = To Spectrum: "yes"
    selectObject: spec
    dfreq = Get bin width
    b1 = Get bin number from frequency: 999.4
    b2 = Get bin number from frequency: 1000.2
    @emit: "onebin_bin_width", fixed$ (dfreq, 6)
    @emit: "onebin_bins_in_range", string$ (floor (b2) - ceiling (b1) + 1)
    # The value the empty frame is not showing: the peak of the tone.
    bPeak = round (b1 + (b2 - b1) / 2)
    selectObject: spec
    re = Get real value in bin: bPeak
    selectObject: spec
    im = Get imaginary value in bin: bPeak
    @emit: "onebin_peak_db", fixed$ (10 * log10 ((re * re + im * im) / 4e-10), 2)
    Erase all
    @emlDrawSpectrum: spec, "One bin", "Frequency (Hz)", "Power (dB)",
    ... 6, 4, "color", 4, 999.4, 1000.2, 0, 0
    removeObject: snd
    @savePic

# ---------------------------------------------------------------------------
# TWOBIN — the control for the leg above. The same Spectrum, the same
# procedure, the same everything except that the range is wide enough to hold
# two bins. If this one were empty too, the finding would be about the draw
# path and not about the range.
# ---------------------------------------------------------------------------
elsif leg$ = "twobin"
    snd = Create Sound from formula: "tone", 1, 0, 1.0, 44100,
    ... "0.5*sin(2*pi*1000*x)"
    spec = To Spectrum: "yes"
    selectObject: spec
    dfreq = Get bin width
    b1 = Get bin number from frequency: 999.0
    b2 = Get bin number from frequency: 1000.6
    @emit: "twobin_bins_in_range", string$ (floor (b2) - ceiling (b1) + 1)
    Erase all
    @emlDrawSpectrum: spec, "Two bins", "Frequency (Hz)", "Power (dB)",
    ... 6, 4, "color", 4, 999.0, 1000.6, 0, 0
    removeObject: snd
    @savePic

else
    @emit: "error", "unknown leg"
endif

@emit: "completed", "1"
