include /home/claude/repo/plugin/stats/eml-core-utilities.praat
include /home/claude/repo/plugin/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin/stats/eml-extract.praat
include /home/claude/repo/plugin/stats/eml-output.praat
include /home/claude/repo/plugin/stats/eml-inferential.praat
include /home/claude/repo/plugin/stats/eml-result-writer.praat
include /home/claude/repo/plugin/stats/eml-record.praat
include /home/claude/repo/plugin/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin/graphs/eml-draw-procedures.praat
include /home/claude/repo/plugin/stats/eml-analysis.praat
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "Table vt", 40, 2, "14 August 2026, 00:00:00"

Create Table with column names: "vt", 0, "grp val"
rngState = 20260814
row = 0
for g from 1 to 2
    for k from 1 to 20
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set numeric value: row, "val",
        ... 1 + g * 1.2 + (rngState / 2147483648 - 0.5) * 1.4
    endfor
endfor
table = selected ("Table")

annotate = 1
annotAlpha = 0.05
annotStyle$ = "p-value"
annotShowNS = 0
annotShowEffect = 1
annotTestType$ = "parametric"
annotLayoutMode = 1
annotCorrectionMethod$ = "holm"
graph_type = 7
prev_violinShowJitter = 1
@emlClearAnnotations
@emlSetAdaptiveTheme: 6, 4
@emlBridgeGroupComparison: table, "val", "grp", annotAlpha, annotStyle$,
... annotShowNS, annotShowEffect, annotTestType$, annotLayoutMode
selectObject: table
dMax = Get maximum: "val"
dMin = Get minimum: "val"
dataYMax_forAnnotation = dMax
@emlComputeAnnotationHeadroom: dMax - dMin, emlSetAdaptiveTheme.annotSize, 0, ""
valueMin = dMin
valueMax = dMax + emlComputeAnnotationHeadroom.headroom

Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
@emlDrawViolinPlot: table, "advanced violin", "Cohort", "val", 6, 4,
... "color", 1, "grp", "val", valueMin, valueMax
annotXMin = emlDrawViolinPlot.axisXMin
annotXMax = emlDrawViolinPlot.axisXMax
annotYMin = emlDrawViolinPlot.axisYMin
annotYMax = emlDrawViolinPlot.axisYMax
if annotBracketN > 0 or (annotTextN > 0 and annotMatrixN = 0)
    annotYRange = annotYMax - annotYMin
    if annotTextN > 0
        annotBlockN = annotBlockN + 1
        annotBlockLabel$[annotBlockN] = annotTextLabel$[1]
        annotBlockDraw$[annotBlockN] = annotTextLabel$[1]
        annotTextN = 0
    endif
    if annotBracketN > 0
        @emlDrawAnnotations: annotXMin, annotXMax, dataYMax_forAnnotation,
        ... annotYRange, "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize,
        ... annotYMin, annotYMax
    endif
    if annotBlockN > 0
        if annotBracketN > 0
            omnibusCorner$ = "bottom-right"
        else
            omnibusCorner$ = "top-right"
        endif
        @emlDrawAnnotationBlock: omnibusCorner$, annotXMin, annotXMax,
        ... annotYMin, annotYMax, emlSetAdaptiveTheme.annotSize
    endif
endif
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/record/replay_out/ADV_ORIG.png"

@emlRecordFlush: "/home/claude/repo/harness/record/replay_out/adv_emitted.praat"
@emlRecordDiscard

# THE UN-ADVANCED REFERENCE, drawn in the same process at the same axis so
# nothing but the advanced settings can differ. This is what a replay that
# drops them looks like, and having it makes the ADV result an identification
# rather than an inequality: "the replay matches the bare figure" says which
# way it failed, where "the replay differs from the original" does not.
annotate = 0
prev_violinShowJitter = 0
@emlClearAnnotations
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
@emlDrawViolinPlot: table, "advanced violin", "Cohort", "val", 6, 4,
... "color", 1, "grp", "val", valueMin, valueMax
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/record/replay_out/ADV_BARE.png"
