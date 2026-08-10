# Pre-build probe: does the scatter annotation block draw when Annotate is
# UNTICKED? Reads the block state the drawing procedure leaves behind.
; Relative, and it resolves against the TOP-LEVEL script's folder -- this
; file's own folder, which is two levels below the repository root, the same
; depth as harness/stress_cases/. So the prelude's own "../../plugin/..."
; lines resolve correctly too. Absolute paths here meant a copy of the repo
; silently tested the ORIGINAL tree. See harness/_env.sh.
include ../stress_cases/_prelude.praat

annotate = 0
scatterRegressionLine = 1
scatterShowFormula = 1
scatterAnalysisType = 1
scatterDotSize = 2
scatterShowDots = 1
annotBlockN = 0

id = Create Table with column names: "probe", 12, "x y"
for i to 12
    selectObject: id
    Set numeric value: i, "x", i
    Set numeric value: i, "y", 2 * i + (i mod 3)
endfor

@emlDrawScatterPlot: id, "Probe", "x", "y", 6, 4, "color", 1, "x", "y", "", 0, 0, 0, 0, annotate
appendInfoLine: "PROBE annotate=", annotate, " annotBlockN_after=", annotBlockN
if annotBlockN > 0
    for i to annotBlockN
        appendInfoLine: "PROBE line ", i, ": ", annotBlockLabel$[i]
    endfor
endif
@stressSave: 6, 4
