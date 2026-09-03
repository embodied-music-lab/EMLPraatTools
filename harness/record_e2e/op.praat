# ---------------------------------------------------------------------------
# ONE OPERATION, IN ITS OWN SCRIPT SCOPE.
#
# Run through `runScript:` by driver.praat, which is what makes this harness
# mean anything: `runScript:` gives a script its OWN variable scope inside
# ONE Praat process, which is exactly what a menu command gets. Every earlier
# test of the recorder called @emlRecordStep in the same scope that started
# the recording, so it could not have caught a recorder that failed to
# re-attach -- and re-attaching across scopes is the whole design.
#
# A `form:` BLOCK, AND NOT beginPause:, WHICH IS §8 IN MINIATURE. `runScript:`
# passes arguments positionally into a form. A script with no form refuses
# them -- "Found 1 arguments but expected only 0" -- which is exactly why §8
# says the emitted workflow cannot re-run at wrapper level while the wrappers
# use beginPause:. This file uses a form so it can be driven.
# ---------------------------------------------------------------------------
include ../../plugin/scripts/eml-lib.praat

form: "op"
    word: "Op", "anova"
endform
op$ = op$

; THE DRAW PATH NEEDS ITS GLOBALS, and a caller that skips this gets
; "Unknown variable: emlSubtitle$" from inside the draw procedure rather than
; anything that names the cause. @emlInitializeDrawingDefaults is the documented
; entry point for standalone callers; every harness prelude in this tree calls
; it, and so must anything driving a draw procedure directly.
@emlInitializeDrawingDefaults

; The preamble every draw procedure needs from a standalone caller. Factored
; because it is identical for all fourteen and a caller that skips any of it
; gets "Unknown variable: emlSubtitle$" from inside the draw rather than
; anything that names the cause.
procedure emlPrepDraw
    @emlClearAnnotations
    @emlSetAdaptiveTheme: 6, 4
    @emlSetColorPalette: "color"
    @emlInitAlphaSprites
    selectObject: id
endproc
selectObject: "Table voiceA"
id = selected ("Table")

if op$ = "anova"
    @emlRunAnovaAnalysis: id, "spl", "grp", 0
elsif op$ = "twogroup"
    @emlRunTwoGroupAnalysis: id, "spl", "grp", "welch", 0
elsif op$ = "kw"
    @emlRunKruskalWallisAnalysis: id, "spl", "grp", 0, "holm"
elsif op$ = "descriptive"
    @emlRunDescriptiveAnalysis: id, "spl"
elsif op$ = "normality"
    @emlRunNormalityAnalysis: id, "spl", "both"
elsif op$ = "correlation"
    @emlRunCorrelationAnalysis: id, "spl", "spl2", "pearson"
elsif op$ = "regression"
    @emlRunRegressionAnalysis: id, "spl", "spl2"
elsif op$ = "violin"
    @emlPrepDraw
    @emlDrawViolinPlot: id, "Violin", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 0, 0
elsif op$ = "scatter"
    @emlPrepDraw
    @emlDrawScatterPlot: id, "Scatter", "x", "y", 6, 4, "color", 1, "spl", "spl2", "", 0, 0, 0, 0, 0
elsif op$ = "histogram"
    @emlPrepDraw
    @emlDrawHistogram: id, "Histogram", "spl", "Count", 6, 4, "color", 1, "spl", "", 0, 1, 0, 0, 0
elsif op$ = "pairwise"
    @emlRunPairwiseAnalysis: id, "spl", "grp3", "t", "holm"
elsif op$ = "twoway"
    @emlRunTwoWayAnalysis: id, "spl", "grp", "grp2"
elsif op$ = "paired"
    @emlRunPairedAnalysis: id, "spl", "spl2", "t"
elsif op$ = "reliability"
    ; REWRITTEN 3 September 2026 for the frozen signature
    ; (RULING_SURVEY_ROWS_ACCEPTED_2026-09-03). This passed five arguments --
    ; id, "subj", "r1|r2|r3", "icc", "agreement" -- to the Phase 4 stub, and
    ; its comment said the refusal was by design. The stub is now a working
    ; doorway taking four, so the call died on arity before reaching the
    ; procedure: no OPDONE marker, nothing in the buffer, and this harness
    ; reported "1 operation never completed" without saying which. A doorway
    ; that changes shape breaks its drivers silently, which is the whole
    ; reason this file drives the real thing rather than a copy of it.
    ;
    ; The items are the three condition columns the repeated-measures and
    ; Friedman operations below already use -- the fixture has no separate
    ; rater block, and three columns is enough for alpha-if-item-deleted to
    ; be defined (k >= 3).
    @emlRunReliabilityAnalysis: id, { "c1", "c2", "c3" }, 0.95, 1
elsif op$ = "rm"
    ; PIPE-SEPARATED, not comma. @emlExtractConditionMatrix splits on "|";
    ; a comma-separated list parses as ONE column name and the path refuses
    ; with "Need at least 2 condition columns" -- which is what this harness
    ; recorded for weeks, so the repeated-measures test never actually ran.
    @emlRunRepeatedMeasuresAnalysis: id, "subj", "c1|c2|c3", 0, "holm"
elsif op$ = "friedman"
    @emlRunFriedmanAnalysis: id, "subj", "c1|c2|c3", 0, "holm"
elsif op$ = "timeseries"
    @emlPrepDraw
    @emlDrawTimeSeries: id, "Line", "t", "spl", 6, 4, "color", 1, "t", "spl", "grp", 0, 0, 0, 0
elsif op$ = "timeseriesci"
    @emlPrepDraw
    @emlDrawTimeSeriesCI: id, "Line CI", "t", "spl", 6, 4, "color", 1, "t", "spl", "grp", 0, 0, 0, 0
elsif op$ = "spaghetti"
    @emlPrepDraw
    @emlDrawSpaghettiPlot: id, "Spaghetti", "t", "spl", 6, 4, "color", 1, "t", "spl", "subj", "grp", 1, 0, 0
elsif op$ = "barchart"
    @emlPrepDraw
    @emlDrawBarChart: id, "Bar", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 0, "", 0, 0
elsif op$ = "boxplot"
    @emlPrepDraw
    @emlDrawBoxPlot: id, "Box", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 0, 0
elsif op$ = "gviolin"
    @emlPrepDraw
    @emlDrawGroupedViolin: id, "GViolin", "grp", "spl", 6, 4, "color", 1, "grp", "grp2", "spl", 0, 0
elsif op$ = "gbox"
    @emlPrepDraw
    @emlDrawGroupedBoxPlot: id, "GBox", "grp", "spl", 6, 4, "color", 1, "grp", "grp2", "spl", 0, 0
elsif op$ = "waveform"
    @emlPrepDraw
    selectObject: "Sound tone"
    sid = selected ()
    @emlDrawWaveform: sid, "Waveform", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, 0, 0
elsif op$ = "f0contour"
    @emlPrepDraw
    selectObject: "Pitch tone"
    pid = selected ()
    ; .yUnit IS NUMERIC -- 1 Hertz, 2 semitones re 440 Hz -- and passing the
    ; string "Hz" here got "Found a string expression instead of a numeric
    ; expression" from inside the procedure, with no mention of which argument.
    @emlDrawF0Contour: pid, "F0", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, 0, 0, 1
elsif op$ = "spectrum"
    @emlPrepDraw
    selectObject: "Spectrum tone"
    qid = selected ()
    @emlDrawSpectrum: qid, "Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0
elsif op$ = "ltas"
    @emlPrepDraw
    selectObject: "Ltas tone"
    lid = selected ()
    @emlDrawLTAS: lid, "LTAS", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0, 1, 0, 0, 0
elsif op$ = "sound2f0"
    ; FROM A SOUND, converting the way the graphs form does. The intermediate
    ; is removed afterwards exactly as @emlGraphsWorkflow removes it, so the
    ; recorded step has to name the Sound or it names nothing that exists.
    @emlPrepDraw
    selectObject: "Sound tone"
    sndid = selected ()
    @emlConvertForGraph: sndid, "Pitch", 75, 600
    cid = emlConvertForGraph.result
    @emlDrawF0Contour: cid, "F0 from Sound", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, 0, 0, 1
    removeObject: cid
elsif op$ = "sound2spectrum"
    @emlPrepDraw
    selectObject: "Sound tone"
    sndid = selected ()
    @emlConvertForGraph: sndid, "Spectrum", 75, 600
    cid = emlConvertForGraph.result
    @emlDrawSpectrum: cid, "Spectrum from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0
    removeObject: cid
elsif op$ = "sound2ltas"
    @emlPrepDraw
    selectObject: "Sound tone"
    sndid = selected ()
    @emlConvertForGraph: sndid, "Ltas", 75, 600
    cid = emlConvertForGraph.result
    @emlDrawLTAS: cid, "LTAS from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0, 1, 0, 0, 0
    removeObject: cid
elsif op$ = "spectrum2ltas"
    @emlPrepDraw
    selectObject: "Spectrum tone"
    @emlConvertForGraph: selected (), "Ltas", 75, 600
    cid = emlConvertForGraph.result
    @emlDrawLTAS: cid, "LTAS from Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0, 1, 0, 0, 0
    removeObject: cid
elsif op$ = "spectrum2sound"
    @emlPrepDraw
    selectObject: "Spectrum tone"
    @emlConvertForGraph: selected (), "Sound", 75, 600
    cid = emlConvertForGraph.result
    @emlDrawWaveform: cid, "Waveform from Spectrum", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, 0, 0
    removeObject: cid
elsif op$ = "spectrum2f0"
    ; TWO STEPS INSIDE ONE CONVERSION: Spectrum -> Sound -> Pitch. The
    ; intermediate Sound is removed by the procedure on both sides, so the
    ; emitted script leaves nothing behind either.
    @emlPrepDraw
    selectObject: "Spectrum tone"
    @emlConvertForGraph: selected (), "Pitch", 75, 600
    cid = emlConvertForGraph.result
    @emlDrawF0Contour: cid, "F0 from Spectrum", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, 0, 0, 1
    removeObject: cid
elsif op$ = "tor2table"
    ; NOT REMOVED AFTERWARDS -- .temporary is 0 for this pair, because the
    ; form keeps the converted Table as the session's working object.
    @emlPrepDraw
    selectObject: "TableOfReal tor"
    @emlConvertForGraph: selected (), "Table", 75, 600
    cid = emlConvertForGraph.result
    selectObject: cid
    col$ = Get column label: 1
    @emlDrawHistogram: cid, "Histogram from TableOfReal", col$, "Count", 6, 4, "color", 1, col$, "", 0, 1, 0, 0, 0
elsif op$ = "matrix2table"
    @emlPrepDraw
    selectObject: "Matrix mat"
    @emlConvertForGraph: selected (), "Table", 75, 600
    cid = emlConvertForGraph.result
    selectObject: cid
    col$ = Get column label: 1
    @emlDrawHistogram: cid, "Histogram from Matrix", col$, "Count", 6, 4, "color", 1, col$, "", 0, 1, 0, 0, 0
elsif op$ = "scatterstats"
    ; SET THE WAY @emlGraphsWorkflow SETS THEM. These three are globals the
    ; form owns and the draw procedure reads; a direct caller has to supply
    ; them or the analysis branch never runs.
    ;   scatterAnalysisType  1 correlation, 2 regression, 3 both
    ;   annotCorrType$       pearson | spearman -- also picks the estimator
    ;                        for the fitted line (OLS vs Theil-Sen)
    ;   scatterRegressionLine  draw the fit
    @emlPrepDraw
    scatterAnalysisType = 3
    annotCorrType$ = "spearman"
    scatterRegressionLine = 1
    @emlDrawScatterPlot: id, "Scatter with stats", "x", "y", 6, 4, "color", 1, "spl", "spl2", "", 0, 0, 0, 0, 1
elsif op$ = "scattermonotonic"
    ; scatterAnalysisType = 1 (correlation only) leaves .reportedOLS = 0, so
    ; the Spearman context selects Theil-Sen for the line -- the robust,
    ; rank-coherent estimator. This is the branch the OLS case cannot reach.
    @emlPrepDraw
    scatterAnalysisType = 1
    annotCorrType$ = "spearman"
    scatterRegressionLine = 1
    @emlDrawScatterPlot: id, "Scatter, monotonic fit", "x", "y", 6, 4, "color", 1, "spl", "spl2", "", 0, 0, 0, 0, 1
elsif op$ = "bridge"
    ; The graphs -> stats direction: @emlRunAnnotationComparison runs the
    ; omnibus test and the post-hoc that the figure's brackets are drawn
    ; from. Same statistics as @emlRunAnovaAnalysis, reached the other way.
    @emlPrepDraw
    @emlRunAnnotationComparison: id, "spl", "grp3", 0.05, "stars", 0, 1, "parametric", 1
endif

appendInfoLine: "OPDONE ", op$
