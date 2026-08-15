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
    pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "yes",
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
    pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "yes",
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

else
    @emit: "error", "unknown leg"
endif

@emit: "completed", "1"
