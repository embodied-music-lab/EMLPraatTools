# ---------------------------------------------------------------------------
# WRAP PROBE — what the "label = value" rule in @emlWrapText costs.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# NOT WIRED INTO validate/. It is a measurement rig, run by hand through
# harness/wraptext/run.sh, and it answers one question with numbers: keeping
# "Cohen's d = 0.83" on one line lengthens the longest line sometimes, and
# a longer longest line can push @emlDrawAnnotationBlock's fit loop round one
# more time. How often, and by how much.
#
# It is run TWICE by run.sh, against two plugin trees that differ in
# @emlWrapText and nothing else: this tree, and a staged copy carrying the
# plain greedy wrapper from harness/wraptext/greedy_wrap.praat. Both runs
# emit the same keys in the same order, so run.sh joins them by key.
#
# Measuring both wrappers in ONE process was rejected: PART B has to see the
# wrap through @emlDrawAnnotationBlock's own fit loop, and that loop calls
# @emlWrapText by name. A second copy of the loop in this file would drift
# away from the shipped one and then measure itself.
#
# PART A — the wrap alone. 39 annotation strings taken from the omnibus,
# correlation, regression and disclosure call sites, at every width from 16
# to 72. Per case: longest line, line count, and SPLITS — breaks that land on
# a space touching an equals sign, which is the defect being removed.
#
# PART B — the box. Blocks of 1 to 6 of those strings, on seven figure sizes,
# through @emlDrawAnnotationBlock in measure-only mode. Per case: the number
# of fit passes the loop took, the rendered width of its widest line, the rows
# it produced, and the splits left in THOSE ROWS -- the box's own wrapped
# list, which is what a reader of the figure actually sees.
#
# Environment:
#     EML_WRAP_TAG   a name for this run, echoed into every row
#
# Output: TSV to stdout, two row kinds, both starting with the tag:
#     <tag> A <caseIdx> <width> <maxLen> <nLines> <splits>
#     <tag> B <boxIdx> <vpW> <vpH> <passes> <rows> <textW> <boxW> <splits>
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/graphs/eml-annotation-procedures.praat

tag$ = environment$ ("EML_WRAP_TAG")
if tag$ = ""
    tag$ = "run"
endif

@emlInitDrawingDefaults

# ---------------------------------------------------------------------------
# THE CORPUS. Every string here is either a literal an EML call site builds or
# the same shape with realistic numbers substituted. The equals signs are the
# point, so the mix follows the real one: an omnibus line carries two or three,
# a regression formula carries two, a disclosure often carries none.
# ---------------------------------------------------------------------------
nCase = 0
procedure addCase: .text$
    nCase = nCase + 1
    case$[nCase] = .text$
endproc

; Omnibus lines — @emlBridgeGroupComparison, both arms, all four tests.
@addCase: "F(2, 21) = 4.31, p = .027"
@addCase: "One-way ANOVA: F(3, 76) = 5.02, p = .003, \ep^2 = 0.165"
@addCase: "Welch t: t(31.4) = 2.14, p = .041, d = 0.83"
@addCase: "Welch t: t(112.7) = -0.87, p = .386, d = -0.16"
@addCase: "Mann-Whitney: U = 122.0, p = .013, r = 0.42"
@addCase: "Mann-Whitney: U = 1874.5, p < .001, r = 0.61"
@addCase: "Kruskal-Wallis: H(3) = 9.12, p = .028, \ep^2 = 0.271"
@addCase: "Kruskal-Wallis: H(5) = 21.44, p < .001, \ep^2 = 0.318"
@addCase: "RM-ANOVA: F(1.56, 29.6) = 7.44, p = .006, partial \ep^2 = 0.281"
@addCase: "Friedman: chi-square(3) = 11.28, p = .010, W = 0.235"
@addCase: "Paired t: t(23) = 3.02, p = .006, d = 0.62"

; Correlation and regression — @emlDrawScatterPlot's own annotation block.
@addCase: "r = 0.834, R² = 0.696, p < .001"
@addCase: "r = -0.213, R² = 0.045, p = .188"
@addCase: "rs = -0.512, p = .006"
@addCase: "OLS y = 0.4213x + 12.0031  (R² = 0.691)"
@addCase: "Deming y = 1.0342x + -0.8871  (R² = 0.884)"
@addCase: "Passing-Bablok y = 0.9915x + 1.2044  (R² = 0.902)"
@addCase: "Sopranos: OLS y = 0.0421x + 214.7733  (R² = 0.312)"
@addCase: "Baritones (n = 19): OLS y = -0.1180x + 132.4416  (R² = 0.507)"
@addCase: "Trained singers: Deming y = 1.2211x + -18.3390  (R² = 0.774)"

; Descriptives and assumption checks.
@addCase: "n = 42"
@addCase: "Mean = 214.73, SD = 18.42, n = 24"
@addCase: "Median = 208.5, IQR = 24.3, n = 24"
@addCase: "Shapiro-Wilk W = 0.964, p = .213"
@addCase: "Levene F(2, 57) = 1.82, p = .171; variances treated as equal"
@addCase: "Greenhouse-Geisser epsilon = 0.782, corrected p = .019"
@addCase: "Tukey HSD, alpha = 0.050, 4 groups, 6 pairwise comparisons"
@addCase: "Dunn post-hoc, Holm correction, alpha = 0.050"
@addCase: "95% CI [0.12, 0.87], d = 0.83"

; Disclosures — @emlDisclose call sites, with and without an equals sign.
@addCase: "Bars show the group mean, not individual values."
@addCase: "Error bars: +/-1 SE."
@addCase: "Line shows the mean; band shows the 95% CI."
@addCase: "Lines show the mean per time point."
@addCase: "3 row(s) skipped (missing or non-numeric value)."
@addCase: "17 row(s) skipped (missing or non-numeric value); n = 117 plotted."
@addCase: "Per-group stats (4 groups) computed on the plotted points only."
@addCase: "Line shows the mean; band shows the 95% CI, k = 6 time points."
@addCase: "Points outside the typed y range are withheld: n = 8 of 240."
@addCase: "Bin width = 12.5 Hz, bins = 18, n = 216 values."

# ---------------------------------------------------------------------------
# @wrapMetrics — read the wrap sitting in emlWrapText's namespace.
#
# .maxLen   longest segment, in characters
# .splits   breaks that land on a space touching an "=" -- the last token of
#           a segment is "=" (an orphaned equals) or the first token of the
#           next one is (a label parted from its number). Zero is the whole
#           point of the rule.
# ---------------------------------------------------------------------------
procedure wrapMetrics
    .n = emlWrapText.nLines
    .maxLen = 0
    .splits = 0
    for .i from 1 to .n
        .s$ = emlWrapText.line$[.i]
        if length (.s$) > .maxLen
            .maxLen = length (.s$)
        endif
    endfor
    for .i from 1 to .n - 1
        .a$ = emlWrapText.line$[.i]
        .b$ = emlWrapText.line$[.i + 1]
        ; last token of .a$
        .lastSp = 0
        for .k from 1 to length (.a$)
            if mid$ (.a$, .k, 1) = " "
                .lastSp = .k
            endif
        endfor
        .lastTok$ = mid$ (.a$, .lastSp + 1, length (.a$))
        ; first token of .b$
        .sp = index (.b$, " ")
        if .sp = 0
            .firstTok$ = .b$
        else
            .firstTok$ = left$ (.b$, .sp - 1)
        endif
        if .lastTok$ = "=" or .firstTok$ = "="
            .splits = .splits + 1
        endif
    endfor
endproc

# ---------------------------------------------------------------------------
# @boxSplits — the same defect count as @wrapMetrics.splits, read off the row
# list @emlDrawAnnotationBlock is about to draw (.wLabel$[1..wN]) rather than
# off one @emlWrapText call. A block's rows come from several wraps and from
# lines short enough not to be wrapped at all, so this is the number that
# describes the figure.
# ---------------------------------------------------------------------------
procedure boxSplits
    .splits = 0
    for .i from 1 to emlDrawAnnotationBlock.wN - 1
        .a$ = emlDrawAnnotationBlock.wLabel$[.i]
        .b$ = emlDrawAnnotationBlock.wLabel$[.i + 1]
        .lastSp = 0
        for .k from 1 to length (.a$)
            if mid$ (.a$, .k, 1) = " "
                .lastSp = .k
            endif
        endfor
        .lastTok$ = mid$ (.a$, .lastSp + 1, length (.a$))
        .sp = index (.b$, " ")
        if .sp = 0
            .firstTok$ = .b$
        else
            .firstTok$ = left$ (.b$, .sp - 1)
        endif
        if .lastTok$ = "=" or .firstTok$ = "="
            .splits = .splits + 1
        endif
    endfor
endproc


# ---------------------------------------------------------------------------
# PART A
# ---------------------------------------------------------------------------
for c from 1 to nCase
    for w from 16 to 72
        @emlWrapText: case$[c], w
        @wrapMetrics
        appendInfoLine: tag$, tab$, "A", tab$, c, tab$, w, tab$,
        ... wrapMetrics.maxLen, tab$, emlWrapText.nLines, tab$,
        ... wrapMetrics.splits
    endfor
endfor

# ---------------------------------------------------------------------------
# PART B — the same strings through the box that draws them.
#
# Seven figure sizes: the three the wrap contract is measured at, plus the
# form's default and three more from harness/legend's sweep. Blocks are built
# by an LCG rather than by hand so the mix of line lengths is not curated, and
# the seed is fixed so the two runs see identical blocks.
# ---------------------------------------------------------------------------
nSize = 7
sizeW[1] = 3.6
sizeH[1] = 3
sizeW[2] = 4.5
sizeH[2] = 3.5
sizeW[3] = 6
sizeH[3] = 4
sizeW[4] = 6
sizeH[4] = 4.5
sizeW[5] = 8
sizeH[5] = 5
sizeW[6] = 5
sizeH[6] = 5
sizeW[7] = 3
sizeH[7] = 2.5

rngState = 20260820
procedure rnd: .lo, .hi
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = floor (.lo + (rngState / 2147483648) * (.hi - .lo + 1))
    if .v > .hi
        .v = .hi
    endif
endproc

emlSubtitle$ = ""
nBlock = 182
for b from 1 to nBlock
    @rnd: 1, 6
    kLines = rnd.v
    for l from 1 to kLines
        @rnd: 1, nCase
        blockLine$[l] = case$[rnd.v]
    endfor
    for s from 1 to nSize
        Erase all
        @emlSetAdaptiveTheme: sizeW[s], sizeH[s]
        @emlSetPanelViewport
        xLo = 0.5
        xHi = 4.5
        yLo = 180
        yHi = 260
        Axes: xLo, xHi, yLo, yHi
        annotBlockN = kLines
        for l from 1 to kLines
            annotBlockLabel$[l] = blockLine$[l]
            @emlSanitizeLabel: blockLine$[l]
            annotBlockDraw$[l] = emlSanitizeLabel.result$
        endfor
        ; Measure-only: the fit loop runs in full, nothing is painted, and the
        ; flag is cleared by this caller because the procedure never clears it.
        emlAnnotBlockMeasureOnly = 1
        @emlDrawAnnotationBlock: "top-right", xLo, xHi, yLo, yHi,
        ... emlSetAdaptiveTheme.annotSize
        emlAnnotBlockMeasureOnly = 0
        @boxSplits
        appendInfoLine: tag$, tab$, "B", tab$, b, tab$, sizeW[s], tab$,
        ... sizeH[s], tab$, emlDrawAnnotationBlock.pass, tab$,
        ... emlDrawAnnotationBlock.wN, tab$,
        ... fixed$ (emlDrawAnnotationBlock.textW, 6), tab$,
        ... fixed$ (emlDrawAnnotationBlock.boxW, 6), tab$,
        ... boxSplits.splits
    endfor
endfor
