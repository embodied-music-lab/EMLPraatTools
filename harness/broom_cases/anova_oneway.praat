# Emit tidy/glance/augment for a one-way ANOVA, headlessly, so the output can
# be diffed against broom::tidy(aov(...)) on the same fixture.
#
# This is the reference implementation of the declaration contract. When the
# wrapper is converted, this is the block that moves into it.

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat

outDir$ = environment$ ("EML_OUT_DIR")
if outDir$ = ""
    ; EML_OUT is set by the driver. The fallback is only reached by a case
    ; run by hand, and it is relative so that cannot write into another tree.
    outDir$ = environment$ ("EML_OUT")
    if outDir$ = ""
        outDir$ = "."
    endif
endif
createDirectory: outDir$

tid = Read Table from comma-separated file: environment$ ("EML_FIXTURE")
tname$ = selected$ ("Table")

dataCol$ = "value"
grpCol$ = "voice_type"

@emlOneWayAnova: tid, dataCol$, grpCol$, 1
if emlOneWayAnova.error$ <> ""
    exitScript: "ANOVA failed: " + emlOneWayAnova.error$
endif

@emlResultBegin: tname$, "One-way ANOVA"

# ---- tidy: one row per term, then Residuals, exactly as broom::tidy(aov) ----
@emlTidyRow: grpCol$
@emlTidyNum: "df", emlOneWayAnova.dfBetween
@emlTidyNum: "sumsq", emlOneWayAnova.ssBetween
@emlTidyNum: "meansq", emlOneWayAnova.msBetween
@emlTidyNum: "statistic", emlOneWayAnova.fValue
@emlTidyNum: "p.value", emlOneWayAnova.p
# Nothing else. broom::tidy(aov) is exactly term, df, sumsq, meansq,
# statistic, p.value -- effect sizes and the method label are separate
# objects in R and are separate files here.

@emlTidyRow: "Residuals"
@emlTidyNum: "df", emlOneWayAnova.dfWithin
@emlTidyNum: "sumsq", emlOneWayAnova.ssWithin
@emlTidyNum: "meansq", emlOneWayAnova.msWithin
# statistic and p.value deliberately absent on the Residuals row: broom leaves
# them NA, and an empty cell is how this writer says NA.

# ---- glance: one row for the model ----
.nobs = 0
for .g from 1 to emlOneWayAnova.nGroups
    .nobs = .nobs + emlOneWayAnova.groupN [.g]
endfor
@emlGlanceNum: "r.squared", emlOneWayAnova.etaSquared
@emlGlanceNum: "adj.r.squared", 1 - (1 - emlOneWayAnova.etaSquared)
... * (.nobs - 1) / emlOneWayAnova.dfWithin
@emlGlanceNum: "sigma", sqrt (emlOneWayAnova.msWithin)
@emlGlanceNum: "statistic", emlOneWayAnova.fValue
@emlGlanceNum: "p.value", emlOneWayAnova.p
@emlGlanceNum: "df", emlOneWayAnova.dfBetween

# Gaussian log-likelihood in closed form, so AIC and BIC are the same numbers
# R reports. k = nGroups fitted means + 1 residual variance.
.rss = emlOneWayAnova.ssWithin
.logLik = -0.5 * .nobs * (ln (2 * pi) + ln (.rss / .nobs) + 1)
.k = emlOneWayAnova.nGroups + 1
@emlGlanceNum: "logLik", .logLik
@emlGlanceNum: "AIC", -2 * .logLik + 2 * .k
@emlGlanceNum: "BIC", -2 * .logLik + ln (.nobs) * .k
@emlGlanceNum: "deviance", .rss
@emlGlanceNum: "df.residual", emlOneWayAnova.dfWithin
@emlGlanceNum: "nobs", .nobs
@emlGlanceNum: "n.groups", emlOneWayAnova.nGroups
@emlGlanceStr: "method", "One-way ANOVA"

# ---- augment: the input table plus what the model says about each row ----
@emlAugmentFrom: tid
selectObject: tid
nRows = Get number of rows
for r from 1 to nRows
    selectObject: tid
    g$ = Get value: r, grpCol$
    v$ = Get value: r, dataCol$
    v = number (v$)
    fit = undefined
    for g from 1 to emlOneWayAnova.nGroups
        if emlOneWayAnova.groupLabel$ [g] = g$
            fit = emlOneWayAnova.groupMean [g]
        endif
    endfor
    if fit <> undefined and v <> undefined
        @emlAugmentNum: ".fitted", r, fit
        @emlAugmentNum: ".resid", r, v - fit
        @emlAugmentNum: ".std.resid", r, (v - fit) / sqrt (emlOneWayAnova.msWithin)
    endif
endfor

@emlResultWrite: outDir$, "anova"
allFiles$ = emlResultWrite.files$

# ---------------------------------------------------------------------------
# TukeyHSD is a SECOND MODEL OBJECT, so in R it is a second tidy() call and a
# second frame -- broom::tidy(TukeyHSD(fit)) gives
#   term, contrast, null.value, estimate, conf.low, conf.high, adj.p.value
# It is emphatically not extra rows on tidy(aov). Same here: clear the tidy
# collector, declare the contrasts, write a second file.
#
# The interval is Tukey's own, diff +/- qCrit * sqrt(msWithin/2 * (1/ni + 1/nj)),
# using the studentised-range critical value @emlTukeyHSD already computed --
# not a t interval, which would be narrower and would not carry the familywise
# correction the adjusted p carries.
# ---------------------------------------------------------------------------
@emlTidyClear
for .i from 1 to emlOneWayAnova.nGroups - 1
    for .j from .i + 1 to emlOneWayAnova.nGroups
        .diff = emlOneWayAnova.meanDiff## [.i, .j]
        .ni = emlOneWayAnova.groupN [.i]
        .nj = emlOneWayAnova.groupN [.j]
        .halfWidth = emlOneWayAnova.qCritical
        ... * sqrt (emlOneWayAnova.msWithin / 2 * (1 / .ni + 1 / .nj))
        @emlTidyRow: grpCol$
        @emlTidyStr: "contrast", emlOneWayAnova.groupName$ [.i] + "-"
        ... + emlOneWayAnova.groupName$ [.j]
        @emlTidyNum: "null.value", 0
        @emlTidyNum: "estimate", .diff
        @emlTidyNum: "conf.low", .diff - .halfWidth
        @emlTidyNum: "conf.high", .diff + .halfWidth
        @emlTidyNum: "adj.p.value", emlOneWayAnova.pMatrix## [.i, .j]
    endfor
endfor
@emlResultWriteTidy: outDir$, "anova_posthoc"
allFiles$ = allFiles$ + emlResultWriteTidy.files$

# ---------------------------------------------------------------------------
# Effect sizes are a third object, for the same reason. In R they come from
# effectsize::eta_squared(fit) and effectsize::cohens_d(), each returning its
# own frame -- base aov and TukeyHSD carry none. Keeping them out of the two
# files above is what makes those two byte-comparable with broom's.
# ---------------------------------------------------------------------------
@emlTidyClear
@emlTidyRow: grpCol$
@emlTidyNum: "effect.size", emlOneWayAnova.etaSquared
@emlTidyStr: "effect.size.type", "eta.squared"
for .i from 1 to emlOneWayAnova.nGroups - 1
    for .j from .i + 1 to emlOneWayAnova.nGroups
        @emlTidyRow: grpCol$
        @emlTidyStr: "contrast", emlOneWayAnova.groupName$ [.i] + "-"
        ... + emlOneWayAnova.groupName$ [.j]
        @emlTidyNum: "effect.size", emlOneWayAnova.dMatrix## [.i, .j]
        @emlTidyStr: "effect.size.type", "cohens.d"
    endfor
endfor
@emlResultWriteTidy: outDir$, "anova_effectsize"
allFiles$ = allFiles$ + emlResultWriteTidy.files$

writeInfoLine: "files written:"
appendInfoLine: allFiles$
if emlResultWrite.skipped$ <> ""
    appendInfoLine: "skipped:"
    appendInfoLine: emlResultWrite.skipped$
endif
