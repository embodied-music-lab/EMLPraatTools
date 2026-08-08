# ---------------------------------------------------------------------------
# Pre-build question 2: does anything realistic approach the annotation
# block's documented 20-line cap once three more lines can be appended?
#
# Two constructions, both drawn:
#   worst_bar      — every bar-chart disclosure firing at once.
#   worst_scatter  — grouped scatter, eight groups, Analysis = Both,
#                    formula on, plus missing rows. Each group contributes a
#                    Pearson line, a Spearman line and a formula line, and
#                    none of those three is capped: they are pre-existing
#                    @emlDrawScatterPlot code, added straight to annotBlockN.
#
# Writes /home/claude/disc_out/worst_bar.png and worst_scatter.png and prints
# the line counts.
# ---------------------------------------------------------------------------
include /home/claude/EMLPraatTools/harness/stress_cases/_prelude.praat

annotate = 1
emlSubtitle$ = "SENTINEL-SUBTITLE"

# --- worst case 1: bar chart, every disclosure at once ---------------------
# 4 groups. G1 has n > 1 (mean disclosure). G2 has a single observation
# (SE undefined -> skipped error). G3 has no usable value at all (omitted
# bar). Custom error column with a blank cell. A hand-set value range far
# narrower than the data forces truncated error bars.
b = Create Table with column names: "wb", 12, "grp val err"
for i to 12
    g = (i - 1) div 3 + 1
    Set string value: i, "grp", "G" + string$ (g)
    Set numeric value: i, "err", 40
    if g = 3
        Set string value: i, "val", ""
    else
        Set numeric value: i, "val", 20 + i
    endif
    if g = 4
        Set string value: i, "err", ""
    endif
endfor
Erase all
@emlDrawBarChart: b, "Bar worst case", "Group", "Value", 6, 4, "color", 1,
... "grp", "val", 3, "err", 0, 40
appendInfoLine: "WORSTCASE bar info=", emlDiscloseInfoN,
... " fig=", emlDiscloseFigN
select all
nSel = numberOfSelected ()
if nSel > 0
    Remove
endif
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/disc_out/worst_bar.png"

# --- worst case 2: grouped scatter, eight groups ---------------------------
annotCorrType$ = "both"
annotStyle$ = "stars"
scatterRegressionLine = 1
scatterShowFormula = 1
scatterShowDots = 1
scatterAnalysisType = 3
scatterDotSize = 2

nG = 8
nPer = 8
s = Create Table with column names: "ws", nG * nPer, "grp x y"
for i to nG * nPer
    g = (i - 1) div nPer + 1
    k = (i - 1) mod nPer + 1
    Set string value: i, "grp", "Group" + string$ (g)
    Set numeric value: i, "x", k
    if i mod 17 = 0
        Set string value: i, "y", ""
    else
        Set numeric value: i, "y", g * 5 + k * 1.5 + (k mod 3)
    endif
endfor
Erase all
@emlDrawScatterPlot: s, "Scatter worst case", "X", "Y", 6, 4, "color", 1,
... "x", "y", "grp", 0, 0, 0, 0, annotate
appendInfoLine: "WORSTCASE scatter annotBlockN=", annotBlockN,
... " disclosureLinesPlaced=", emlDiscloseFigN
select all
nSel = numberOfSelected ()
if nSel > 0
    Remove
endif
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/disc_out/worst_scatter.png"
