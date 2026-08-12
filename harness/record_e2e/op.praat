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
; anything that names the cause. @emlInitDrawingDefaults is the documented
; entry point for standalone callers; every harness prelude in this tree calls
; it, and so must anything driving a draw procedure directly.
@emlInitDrawingDefaults
selectObject: "Table voiceA"
id = selected ("Table")

if op$ = "anova"
    @emlRunAnovaAnalysis: id, "spl", "grp", 0
elsif op$ = "twogroup"
    @emlRunTwoGroupAnalysis: id, "spl", "grp", "welch", 0
elsif op$ = "kw"
    @emlRunKWAnalysis: id, "spl", "grp", 0, "holm"
elsif op$ = "descriptive"
    @emlRunDescriptiveAnalysis: id, "spl"
elsif op$ = "normality"
    @emlRunNormalityAnalysis: id, "spl", "both"
elsif op$ = "correlation"
    @emlRunCorrelationAnalysis: id, "spl", "spl2", "pearson"
elsif op$ = "regression"
    @emlRunRegressionAnalysis: id, "spl", "spl2"
elsif op$ = "violin"
    @emlClearAnnotations
    @emlSetAdaptiveTheme: 6, 4
    @emlSetColorPalette: "color"
    @emlInitAlphaSprites
    selectObject: id
    @emlDrawViolinPlot: id, "Violin", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 0, 0
elsif op$ = "scatter"
    @emlClearAnnotations
    @emlSetAdaptiveTheme: 6, 4
    @emlSetColorPalette: "color"
    @emlInitAlphaSprites
    selectObject: id
    @emlDrawScatterPlot: id, "Scatter", "x", "y", 6, 4, "color", 1, "spl", "spl2", "", 0, 0, 0, 0, 0
elsif op$ = "histogram"
    @emlClearAnnotations
    @emlSetAdaptiveTheme: 6, 4
    @emlSetColorPalette: "color"
    @emlInitAlphaSprites
    selectObject: id
    @emlDrawHistogram: id, "Histogram", "spl", "Count", 6, 4, "color", 1, "spl", "", 0, 1, 0, 0, 0
endif

appendInfoLine: "OPDONE ", op$
