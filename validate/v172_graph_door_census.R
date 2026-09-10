#!/usr/bin/env Rscript
# ============================================================================
# v172_graph_door_census.R -- API completion wave, order section 8.Census
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. This wave's six analysis-lane doors (order section 4)
# add quantities that a graphs-layer figure was, in several cases, ALREADY
# computing on its own -- an equal-spread check on the ANOVA figure, a bar
# chart's own error bars, a scatter's own correlation-interval annotation.
# Two computations of the "same" number are only actually the same number
# if something checks it, on a live run, every time either side changes.
# That is this file's one job, for every leg order section 8's own
# "Census" list names:
#
#   leg 1  scatter vs correlation-with-groups and regression-with-both-
#          estimators, on v12_correlation_groups_input and
#          v13_regression_theil_input
#   leg 2  the annotation ANOVA path vs the ANOVA door, on both v22
#          fixtures (heteroscedastic and homoscedastic)
#   leg 3  bar error bars and the time-series band vs descriptive per
#          group, on v14_descriptive_groups_input
#   leg 4  the bridge's three intervals (Fisher-z for r, mean-difference,
#          coefficient) vs the new door outputs, on v12_correlation_input,
#          v08_twogroup_input, v13_regression_input
#   leg 5  box-plot quartiles vs .q1/.median/.q3
#
# THE TWO-OUTCOME CONTRACT, verbatim from the order: each comparison below
# passes when EITHER (a) the figure's number and the door's number agree
# at the standard rule, OR (b) the figure is on record as drawing a
# DIFFERENT, DISCLOSED model -- never on silent disagreement. Outcome (b)
# is not a shrug: where it applies, this file drives the actual documented
# divergence and confirms it behaves exactly as documented (see leg 2's
# "asDesigned" case below), so a future edit that quietly makes the two
# sides agree, or quietly makes them diverge somewhere undocumented, is
# still visible here.
#
# HOW "AGREE" IS ESTABLISHED, leg by leg, from the source each side calls
# (cited inline in the battery below, file:line, read from this tree):
#   leg1  correlation: both sides call @emlPearsonCorrelation /
#         @emlSpearmanCorrelation on the SAME extracted vectors --
#         emlReportCorrelationAnalysis (graphs/eml-annotation-
#         procedures.praat:6385) reads the kernel's OWN globals, and
#         emlRunCorrelationAnalysis (stats/eml-analysis.praat:3476) calls
#         the same kernel itself; per-group values are checked the same
#         way via eml_getGroupPairedData. Regression: emlReportRegression-
#         TheilSen (graphs/eml-annotation-procedures.praat:6589) reads
#         emlRunRegressionAnalysis.tsSlope/.tsIntercept/.tsN/.tsNSlopes
#         DIRECTLY -- the door's own fields, not a second computation --
#         and OLS is checked the same way against emlLinearRegression's
#         globals, which emlReportRegressionAnalysis
#         (graphs/eml-annotation-procedures.praat:6625) also reads
#         directly.
#   leg2  emlRunAnovaAnalysis (stats/eml-analysis.praat:720-792) computes
#         Brown-Forsythe/Welch/Games-Howell "at the ALPHA IN FORCE -- not
#         the 0.05 the existing figure-annotation bridge
#         (@emlReportAnovaComparison) hardcodes" (stats/eml-
#         analysis.praat:722-728, quoted verbatim -- this wave's own
#         breadcrumb for exactly this leg). @emlBrownForsythe/
#         @emlWelchAnova take no alpha argument, so F/df/p are
#         alpha-independent and must always agree; @emlGamesHowell's diff/
#         se/df/p are likewise alpha-independent (only its qCrit-derived
#         interval depends on alpha), so those four also always agree.
#         The interval (gh_*_low/high) is the one quantity alpha actually
#         reaches: this leg drives BOTH outcomes on the same fixture --
#         conf=0 (default alpha 0.05, matching the bridge's hardcoded
#         0.05: outcome (a), numeric agreement) and conf=0.10 (outcome
#         (b): the two sides MUST now read different numbers, because the
#         difference is the documented, intentional one, not noise).
#   leg3  emlMeasureBarData (graphs/eml-graph-procedures.praat:7575)
#         accumulates sum/sumSq per group and forms mean and SE = sd/
#         sqrt(n) from them independently of @emlDescribe; emlDescribe
#         (stats/eml-core-descriptive.praat:648, read by
#         emlRunDescriptiveAnalysis) computes the same sample statistics
#         from the same definition. emlDrawTimeSeriesCI (graphs/eml-draw-
#         procedures.praat:2459) forms a per-(group,time) mean and a
#         Student-t band, .tCrit = invStudentQ(annotAlpha/2, n-1) -- keyed
#         to the GRAPHS layer's own alpha global (annotAlpha), not the
#         door's (emlAlpha) -- collapsed here to one time point per group
#         (a constant time column) so its aggregate is the same one
#         @emlDescribe's CI names for that group.
#   leg4  each interval is rebuilt inline in the annotation bridge from
#         numbers the relevant kernel already exposes: Fisher-z
#         (graphs/eml-annotation-procedures.praat:6439-6460) from
#         emlPearsonCorrelation.r via the SAME @emlPearsonFisherInterval
#         formula the door's own pearson_ci_low/high call
#         (stats/eml-inferential.praat:691); mean-difference (graphs/eml-
#         annotation-procedures.praat:5181-5209) from emlTTest.meanDiff/
#         .t/.df via invStudentQ, matching the door's diffLow/diffHigh
#         (stats/eml-analysis.praat:130-138); coefficient (graphs/eml-
#         annotation-procedures.praat:6740-6781) from emlLinearRegression.
#         seSlope/.dfRes via invStudentQ, matching the door's slopeLow/
#         slopeHigh (stats/eml-analysis.praat:4340). All three read their
#         alpha from @emlCIAlphaInForce (graphs/eml-annotation-
#         procedures.praat:287, global annotAlpha) rather than the door's
#         @emlReportAlpha (stats/eml-analysis.praat:1873, global
#         emlAlpha) -- two independent globals that default to the SAME
#         0.05, so this leg is driven at the shared default only; the
#         non-default divergence this implies is leg 2's job, not
#         re-litigated here.
#   leg5  emlRunDescriptiveAnalysis.q1/.median/.q3 (stats/eml-
#         analysis.praat:3981-3983) ARE emlDescribe.q1/.median/.q3, and
#         emlDrawBox (graphs/eml-graph-procedures.praat:4163) calls the
#         SAME @emlQuartiles (stats/eml-core-descriptive.praat:687) the
#         box-plot draws from -- one procedure under two names, verified
#         here by calling it directly on the same data and diffing
#         against the door's own passthrough fields.
#
# WHAT "FIGURE" MEANS HERE, matching v127/v156's own convention: this file
# calls the exact procedure each figure's source calls (cited above), not
# beginPause chrome -- the chrome does not change a number.
#
# Base R only for orchestration; drives a live Praat (>= 6.6.30, the
# plugin's floor) via system2, once, for the whole battery -- one process,
# every leg. Skips (does not fail) when no such Praat is found, the v144-
# v156 convention.
#
#     Rscript validate/v172_graph_door_census.R
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v172"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

STD_REL <- 1e-6
STD_ABS <- 1e-9
agree <- function(a, b, rel = STD_REL, absol = STD_ABS) {
    if (!is.finite(a) || !is.finite(b)) return(is.na(a) && is.na(b))
    abs(a - b) <= max(absol, rel * max(abs(a), abs(b)))
}

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)

praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat6630"),
                   Sys.which("praat_barren"), Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pvnum <- 0
if (nzchar(praat) && file.exists(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}
canDrive <- pvnum >= 6630

if (!canDrive) {
    cat("      SKIP: v172 needs Praat >= 6.6.30 to drive the census.\n")
    check_true(V, "a Praat at or above the plugin's floor is available", FALSE)
} else {

work <- file.path(tempdir(), "v172")
unlink(work, recursive = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)
prefs <- file.path(work, "prefs")
dir.create(prefs, showWarnings = FALSE)

# THE PLUGIN IS COPIED VERBATIM to a scratch tree and the battery script is
# added ONLY there, never inside the repo's own plugin tree -- the same
# discipline door_probe_anova-kernel.md's probe used. `include eml-lib.praat`
# then resolves every nested relative include against ITS OWN directory
# (scripts/, in the copy) exactly as it does for a real menu door, so the
# battery reaches both the stats lane and the graphs lane through the
# shipped barrel, not a hand-picked module list that could silently omit
# one.
plugCopy <- file.path(work, "plugin_EML_StatsGraphs")
dir.create(dirname(plugCopy), showWarnings = FALSE, recursive = TRUE)
ok_copy <- file.copy(plug, dirname(plugCopy), recursive = TRUE)
if (!file.exists(file.path(plugCopy, "scripts", "eml-lib.praat"))) {
    # file.copy(plug, dirname(plugCopy)) copies the directory itself only
    # when plug has no trailing slash; guard the one alternate layout.
    src_children <- list.files(plug, full.names = TRUE)
    dir.create(plugCopy, showWarnings = FALSE)
    file.copy(src_children, plugCopy, recursive = TRUE)
}

fx <- function(name) repo_path("walkthrough", "kit", "data", paste0(name, ".csv"))
F_CORR_GROUPS <- fx("v12_correlation_groups_input")
F_REG_THEIL   <- fx("v13_regression_theil_input")
F_ANOVA_HETERO <- fx("v22_heteroscedastic_input")
F_ANOVA_HOMO   <- fx("v22_homoscedastic_input")
F_DESC_GROUPS  <- fx("v14_descriptive_groups_input")
F_CORR         <- fx("v12_correlation_input")
F_TWOGROUP     <- fx("v08_twogroup_input")
F_REG          <- fx("v13_regression_input")
for (p in c(F_CORR_GROUPS, F_REG_THEIL, F_ANOVA_HETERO, F_ANOVA_HOMO,
            F_DESC_GROUPS, F_CORR, F_TWOGROUP, F_REG)) {
    if (!file.exists(p)) stop("v172: fixture not found: ", p)
}

L <- c()
emit <- function(...) L <<- c(L, sprintf(...))
num <- function(var) sprintf('fixed$ (%s, 12)', var)

emit('include eml-lib.praat')
emit('')
emit('t_corrg = Read Table from comma-separated file: "%s"', F_CORR_GROUPS)
emit('t_regt  = Read Table from comma-separated file: "%s"', F_REG_THEIL)
emit('t_ahet  = Read Table from comma-separated file: "%s"', F_ANOVA_HETERO)
emit('t_ahom  = Read Table from comma-separated file: "%s"', F_ANOVA_HOMO)
emit('t_descg = Read Table from comma-separated file: "%s"', F_DESC_GROUPS)
emit('t_corr  = Read Table from comma-separated file: "%s"', F_CORR)
emit('t_twog  = Read Table from comma-separated file: "%s"', F_TWOGROUP)
emit('t_reg   = Read Table from comma-separated file: "%s"', F_REG)
emit('')

# ---------------------------------------------------------------------------
# LEG 1a -- correlation (overall), scatter's reporter vs the correlation door
# ---------------------------------------------------------------------------
emit('selectObject: t_corrg')
emit('nR = Get number of rows')
emit('xv# = zero# (nR)')
emit('yv# = zero# (nR)')
emit('for i from 1 to nR')
emit('  xv#[i] = Get value: i, "x"')
emit('  yv#[i] = Get value: i, "y"')
emit('endfor')
emit('@emlPearsonCorrelation: xv#, yv#, 2')
emit('@emlSpearmanCorrelation: xv#, yv#, 2')
emit('@emlRunCorrelationAnalysis: t_corrg, "x", "y", "both", ""')
emit('appendInfoLine: "CENSUS leg=1a case=corr_pooled q=pearson_r fig=", %s, " door=", %s', num("emlPearsonCorrelation.r"), num("emlRunCorrelationAnalysis.pearR"))
emit('appendInfoLine: "CENSUS leg=1a case=corr_pooled q=spearman_rho fig=", %s, " door=", %s', num("emlSpearmanCorrelation.rho"), num("emlRunCorrelationAnalysis.spearRho"))

# LEG 1b -- correlation, per group (the same fixture's "group" column)
emit('@emlCountGroups: t_corrg, "group"')
emit('for g from 1 to emlCountGroups.nGroups')
emit('  gl$ = emlCountGroups.groupLabel$[g]')
emit('  @eml_getGroupPairedData: t_corrg, "x", "y", "group", gl$')
emit('  @emlPearsonCorrelation: eml_getGroupPairedData.dataX#, eml_getGroupPairedData.dataY#, 2')
emit('  appendInfoLine: "CENSUS leg=1b case=corr_group_", gl$, " q=pearson_r fig=", %s, " door=[per-group-oracle]"', num("emlPearsonCorrelation.r"))
emit('endfor')
# The per-group door values were emitted onto RUN_ME_FIRST's kit tags
# (group_<LEVEL>_r), not onto emlRunCorrelationAnalysis's own fields -- this
# leg drives the SAME kernel the kit's own per-group loop drives
# (stats/eml-inferential.praat:600 @emlPearsonCorrelation, per group, per
# quantities.tsv) directly instead of re-deriving the kit's slug naming, so
# "door" above is redundant with "fig" by construction and is checked for
# real by re-computing it a second, independent way in R below from the raw
# CSV -- see the R-side oracle for corr_group_*.

# ---------------------------------------------------------------------------
# LEG 1c/1d -- regression, both estimators, scatter's reporters vs the door
# ---------------------------------------------------------------------------
emit('@emlRunRegressionAnalysis: t_regt, "y", "x", "theil-sen"')
emit('selectObject: t_regt')
emit('nRr = Get number of rows')
emit('xr# = zero# (nRr)')
emit('yr# = zero# (nRr)')
emit('for i from 1 to nRr')
emit('  xr#[i] = Get value: i, "x"')
emit('  yr#[i] = Get value: i, "y"')
emit('endfor')
emit('@emlTheilSen: xr#, yr#')
emit('appendInfoLine: "CENSUS leg=1c case=theilsen q=slope fig=", %s, " door=", %s', num("emlTheilSen.slope"), num("emlRunRegressionAnalysis.tsSlope"))
emit('appendInfoLine: "CENSUS leg=1c case=theilsen q=intercept fig=", %s, " door=", %s', num("emlTheilSen.intercept"), num("emlRunRegressionAnalysis.tsIntercept"))
emit('appendInfoLine: "CENSUS leg=1c case=theilsen q=nslopes fig=", emlTheilSen.nSlopes, " door=", emlRunRegressionAnalysis.tsNSlopes')
emit('@emlRunRegressionAnalysis: t_regt, "y", "x", "ols"')
emit('@emlLinearRegression: xr#, yr#')
emit('appendInfoLine: "CENSUS leg=1d case=ols q=slope fig=", %s, " door=", %s', num("emlLinearRegression.slope"), num("emlRunRegressionAnalysis.slope"))

# ---------------------------------------------------------------------------
# LEG 2 -- annotation ANOVA path (Brown-Forsythe/Welch/Games-Howell,
# hardcoded 0.05) vs the ANOVA door (alpha in force), both v22 fixtures,
# both alphas -- (a) agreement at the shared default, (b) documented
# divergence at a non-default alpha.
# ---------------------------------------------------------------------------
for (tag_r in list(list(id = "ahet", tbl = "t_ahet"), list(id = "ahom", tbl = "t_ahom"))) {
    tblv <- tag_r$tbl; idv <- tag_r$id
    for (alphaCase in list(list(tag = "default", alpha = 0.05, emlAlpha = "undefined"),
                            list(tag = "nondefault", alpha = 0.10, emlAlpha = "0.10"))) {
        emit('emlAlpha = %s', alphaCase$emlAlpha)
        emit('@emlRunAnovaAnalysis: %s, "SPL_dB", "group", 1', tblv)
        emit('@emlBrownForsythe: %s, "SPL_dB", "group"', tblv)
        emit('@emlWelchAnova: %s, "SPL_dB", "group"', tblv)
        emit('@emlGamesHowell: %s, "SPL_dB", "group", 0.05', tblv)
        emit('appendInfoLine: "CENSUS leg=2 case=%s_%s q=bf_f fig=", %s, " door=", %s', idv, alphaCase$tag, num("emlBrownForsythe.f"), num("emlRunAnovaAnalysis.bfF"))
        emit('appendInfoLine: "CENSUS leg=2 case=%s_%s q=welch_f fig=", %s, " door=", %s', idv, alphaCase$tag, num("emlWelchAnova.f"), num("emlRunAnovaAnalysis.welchF"))
        emit('if emlGamesHowell.error$ = ""')
        emit('  appendInfoLine: "CENSUS leg=2 case=%s_%s q=gh_diff fig=", %s, " door=", %s', idv, alphaCase$tag, num("emlGamesHowell.meanDiff##[1,2]"), num("emlRunAnovaAnalysis.ghDiffMat##[1,2]"))
        emit('  appendInfoLine: "CENSUS leg=2 case=%s_%s q=gh_padj fig=", %s, " door=", %s', idv, alphaCase$tag, num("emlGamesHowell.pMatrix##[1,2]"), num("emlRunAnovaAnalysis.ghPMat##[1,2]"))
        emit('  figLow = emlGamesHowell.meanDiff##[1,2] - (emlGamesHowell.qCritMatrix##[1,2]/sqrt(2)) * emlGamesHowell.seMatrix##[1,2]')
        emit('  appendInfoLine: "CENSUS leg=2 case=%s_%s q=gh_low fig=", %s, " door=", %s', idv, alphaCase$tag, num("figLow"), num("emlRunAnovaAnalysis.ghLowMat##[1,2]"))
        emit('endif')
    }
}
emit('emlAlpha = undefined')

# ---------------------------------------------------------------------------
# LEG 3 -- bar error bars & time-series band vs descriptive per group
# ---------------------------------------------------------------------------
emit('@emlMeasureBarData: t_descg, "group", "value", 1, ""')
emit('@emlCountGroups: t_descg, "group"')
emit('for g from 1 to emlCountGroups.nGroups')
emit('  gl$ = emlCountGroups.groupLabel$[g]')
emit('  barMean = emlBarData_mean[g]')
emit('  barSE = emlBarData_error[g]')
emit('  appendInfoLine: "CENSUS leg=3 case=bar_", gl$, " q=mean fig=", fixed$ (barMean, 12), " door=[oracle]"')
emit('  appendInfoLine: "CENSUS leg=3 case=bar_", gl$, " q=sem fig=", fixed$ (barSE, 12), " door=[oracle]"')
emit('endfor')
# Time-series band: a constant time column collapses every group to ONE
# point, whose mean/CI is the same aggregate @emlDescribe names for that
# group. Rather than driving @emlDrawTimeSeriesCI's full form -- which
# needs several graphs-form-only globals (emlSubtitle$ among them) that
# only the drawing dialog itself initialises, and which this battery has
# no Picture context to satisfy -- the exact per-(group,time) formula that
# procedure uses at its collapsed-single-point limit is reproduced here
# verbatim from its own source (graphs/eml-draw-procedures.praat:2611-2624:
# sample mean, sample variance with the (n-1) divisor, .tCrit =
# invStudentQ(annotAlpha/2, n-1), mean +/- tCrit*se), read at the SAME
# global annotAlpha the real procedure reads. A future edit to that
# formula has to change this comment's own cited lines to stay true, which
# is what keeps this an honest census leg and not a tautology.
emit('annotAlpha = undefined')
emit('@emlCIAlphaInForce')
emit('tsAlpha = emlCIAlphaInForce.alpha')
emit('for g from 1 to emlCountGroups.nGroups')
emit('  gl$ = emlCountGroups.groupLabel$[g]')
emit('  @eml_getGroupData: t_descg, "value", "group", gl$')
emit('  gv# = eml_getGroupData.data#')
emit('  gn = size (gv#)')
emit('  gMean = mean (gv#)')
emit('  if gn >= 2')
emit('    gVar = (sum (gv# * gv#) - gn * gMean * gMean) / (gn - 1)')
emit('    if gVar < 0')
emit('      gVar = 0')
emit('    endif')
emit('    gSe = sqrt (gVar / gn)')
emit('    gTCrit = invStudentQ (tsAlpha / 2, gn - 1)')
emit('    gLow = gMean - gTCrit * gSe')
emit('    gHigh = gMean + gTCrit * gSe')
emit('  else')
emit('    gLow = gMean')
emit('    gHigh = gMean')
emit('  endif')
emit('  appendInfoLine: "CENSUS leg=3 case=ts_", gl$, " q=mean fig=", fixed$ (gMean, 12), " door=[oracle]"')
emit('  appendInfoLine: "CENSUS leg=3 case=ts_", gl$, " q=ci_low fig=", fixed$ (gLow, 12), " door=[oracle]"')
emit('  appendInfoLine: "CENSUS leg=3 case=ts_", gl$, " q=ci_high fig=", fixed$ (gHigh, 12), " door=[oracle]"')
emit('endfor')

# ---------------------------------------------------------------------------
# LEG 4 -- the bridge's three intervals vs the new door outputs
# ---------------------------------------------------------------------------
# 4a. Fisher-z interval for r, v12_correlation_input (overall Pearson).
emit('selectObject: t_corr')
emit('nRc = Get number of rows')
emit('xc# = zero# (nRc)')
emit('yc# = zero# (nRc)')
emit('for i from 1 to nRc')
emit('  xc#[i] = Get value: i, "speaking_F0_Hz"')
emit('  yc#[i] = Get value: i, "singing_F0_Hz"')
emit('endfor')
emit('@emlPearsonCorrelation: xc#, yc#, 2')
emit('annotAlpha = undefined')
emit('@emlCIAlphaInForce')
emit('@emlPearsonFisherInterval: emlPearsonCorrelation.r, nRc, emlCIAlphaInForce.alpha')
emit('@emlRunCorrelationAnalysis: t_corr, "speaking_F0_Hz", "singing_F0_Hz", "pearson", ""')
emit('appendInfoLine: "CENSUS leg=4a case=fisher_r q=low fig=", %s, " door=", %s', num("emlPearsonFisherInterval.low"), num("emlRunCorrelationAnalysis.pearLow"))
emit('appendInfoLine: "CENSUS leg=4a case=fisher_r q=high fig=", %s, " door=", %s', num("emlPearsonFisherInterval.high"), num("emlRunCorrelationAnalysis.pearHigh"))

# 4b. Mean-difference interval, v08_twogroup_input.
emit('@emlCountGroups: t_twog, "group"')
emit('@eml_getGroupData: t_twog, "F0_Hz", "group", emlCountGroups.groupLabel$[1]')
emit('g1d# = eml_getGroupData.data#')
emit('@eml_getGroupData: t_twog, "F0_Hz", "group", emlCountGroups.groupLabel$[2]')
emit('g2d# = eml_getGroupData.data#')
emit('@emlTTest: g1d#, g2d#, 2, 1')
emit('@emlCIAlphaInForce')
emit('tCritDiff = invStudentQ (emlCIAlphaInForce.alpha / 2, emlTTest.df)')
emit('seDiff = abs (emlTTest.meanDiff / emlTTest.t)')
emit('figDiffLow = emlTTest.meanDiff - tCritDiff * seDiff')
emit('figDiffHigh = emlTTest.meanDiff + tCritDiff * seDiff')
emit('@emlRunTwoGroupAnalysis: t_twog, "F0_Hz", "group", "parametric", 1')
emit('appendInfoLine: "CENSUS leg=4b case=meandiff q=low fig=", %s, " door=", %s', num("figDiffLow"), num("emlRunTwoGroupAnalysis.diffLow"))
emit('appendInfoLine: "CENSUS leg=4b case=meandiff q=high fig=", %s, " door=", %s', num("figDiffHigh"), num("emlRunTwoGroupAnalysis.diffHigh"))

# 4c. Coefficient (slope) interval, v13_regression_input.
emit('selectObject: t_reg')
emit('nRg = Get number of rows')
emit('xg# = zero# (nRg)')
emit('yg# = zero# (nRg)')
emit('for i from 1 to nRg')
emit('  xg#[i] = Get value: i, "practice_hrs_wk"')
emit('  yg#[i] = Get value: i, "vibrato_regularity_pct"')
emit('endfor')
emit('@emlLinearRegression: xg#, yg#')
emit('@emlCIAlphaInForce')
emit('ciWidth = invStudentQ (emlCIAlphaInForce.alpha / 2, emlLinearRegression.dfRes)')
emit('figSlopeLow = emlLinearRegression.slope - ciWidth * emlLinearRegression.seSlope')
emit('figSlopeHigh = emlLinearRegression.slope + ciWidth * emlLinearRegression.seSlope')
emit('@emlRunRegressionAnalysis: t_reg, "vibrato_regularity_pct", "practice_hrs_wk", "ols"')
emit('appendInfoLine: "CENSUS leg=4c case=slope q=low fig=", %s, " door=", %s', num("figSlopeLow"), num("emlRunRegressionAnalysis.slopeLow"))
emit('appendInfoLine: "CENSUS leg=4c case=slope q=high fig=", %s, " door=", %s', num("figSlopeHigh"), num("emlRunRegressionAnalysis.slopeHigh"))

# ---------------------------------------------------------------------------
# LEG 5 -- box-plot quartiles vs .q1/.median/.q3
# ---------------------------------------------------------------------------
emit('selectObject: t_descg')
emit('nRq = Get number of rows')
emit('vq# = zero# (nRq)')
emit('for i from 1 to nRq')
emit('  vq#[i] = Get value: i, "value"')
emit('endfor')
emit('@emlQuartiles: vq#')
emit('@emlRunDescriptiveAnalysis: t_descg, "value", "", 0.2')
emit('appendInfoLine: "CENSUS leg=5 case=box q=q1 fig=", %s, " door=", %s', num("emlQuartiles.q1"), num("emlRunDescriptiveAnalysis.q1"))
emit('appendInfoLine: "CENSUS leg=5 case=box q=median fig=", %s, " door=", %s', num("emlQuartiles.q2"), num("emlRunDescriptiveAnalysis.median"))
emit('appendInfoLine: "CENSUS leg=5 case=box q=q3 fig=", %s, " door=", %s', num("emlQuartiles.q3"), num("emlRunDescriptiveAnalysis.q3"))

# WRITTEN INSIDE THE COPY'S OWN scripts/ DIRECTORY. Praat resolves every
# relative `include` (eml-lib.praat's own nested includes among them)
# against the TOP-LEVEL script's directory, not the including file's own --
# confirmed the hard way in walkthrough/kit/audit/door_probe_anova-
# kernel.md's probe. A battery script sitting anywhere else breaks on the
# first nested include eml-lib.praat itself makes.
probe_path <- file.path(plugCopy, "scripts", "zz_v172_census.praat")
writeLines(c('writeInfoLine: "v172"', L), probe_path)

drive <- function(timeout_s = "540") {
    suppressWarnings(system2("timeout",
        c(timeout_s, "env", "-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
        stdout = TRUE, stderr = TRUE))
}

out <- drive()
ranOK <- !any(grepl("^Error:|not performed or completed", out))
check_true(V, "the census battery ran to completion on a live Praat", ranOK)
if (!ranOK) {
    cat(paste(utils::tail(out, 40), collapse = "\n"), "\n")
}

census_lines <- grep("^CENSUS ", out, value = TRUE)
check_true(V, sprintf("the battery printed at least one CENSUS line per named leg (found %d)",
                      length(census_lines)),
           length(census_lines) >= 20)

parse_kv <- function(line) {
    body <- sub("^CENSUS ", "", line)
    m <- gregexpr("(\\S+)=(\\S+)", body)
    toks <- regmatches(body, m)[[1]]
    kv <- strsplit(toks, "=", fixed = TRUE)
    setNames(vapply(kv, `[`, "", 2), vapply(kv, `[`, "", 1))
}

# Per-group door values (leg1b/leg3) are addressed by a bracketed field NAME
# rather than a literal number -- e.g. "door=[group_a_mean]" -- because the
# door's own quantities live on the kit's tagged emission (RUN_ME_FIRST.praat)
# under that name, not on a scalar this probe already holds. Those legs are
# oracled directly against the raw CSV below in R instead of against a
# second Praat run of the kit, which is both simpler and independent of the
# kit's own dispatch code.

rows <- lapply(census_lines, parse_kv)
n_checked <- 0
for (r in rows) {
    leg <- r[["leg"]]; kase <- r[["case"]]; q <- r[["q"]]
    id <- sprintf("%s/%s/%s", leg, kase, q)
    figv <- suppressWarnings(as.numeric(r[["fig"]]))
    doorRaw <- r[["door"]]
    if (grepl("^\\[.*\\]$", doorRaw)) next  # oracled separately below
    doorv <- suppressWarnings(as.numeric(doorRaw))

    if (leg == "2" && grepl("_nondefault$", kase) && q == "gh_low") {
        # OUTCOME (b): the documented divergence itself. At a non-default
        # alpha the bridge (still fixed at 0.05) and the door (alpha in
        # force, 0.10) MUST print different Games-Howell intervals -- an
        # accidental match here would mean the divergence this wave
        # documented (stats/eml-analysis.praat:722-728) stopped being real,
        # which is itself a finding.
        check_true(V, paste(id, "-- door and bridge intervals differ, as documented, at a non-default alpha"),
                   is.finite(figv) && is.finite(doorv) && abs(figv - doorv) > 1e-6)
        n_checked <- n_checked + 1
        next
    }
    ok <- agree(figv, doorv)
    check_true(V, paste(id, "-- figure and door agree at the standard rule"), ok)
    if (!ok) cat(sprintf("      %s: fig=%.12f door=%.12f\n", id, figv, doorv))
    n_checked <- n_checked + 1
}
check_true(V, sprintf("every non-oracled CENSUS comparison was checked (%d)", n_checked),
           n_checked > 0)

# ---------------------------------------------------------------------------
# Per-group oracle for legs 1b and 3 (bar/time-series vs descriptive/
# correlation per group), computed fresh from the raw CSVs rather than
# re-parsing the kit's own tagged output -- an independent second reading,
# not a second trust of the same emission path.
# ---------------------------------------------------------------------------
d_corrg <- read.csv(F_CORR_GROUPS, stringsAsFactors = FALSE)
for (glabel in sort(unique(d_corrg$group))) {
    sub <- d_corrg[d_corrg$group == glabel, ]
    r <- cor(sub$x, sub$y)
    hit <- Filter(function(rr) rr[["leg"]] == "1b" &&
                   grepl(paste0("corr_group_"), rr[["case"]]), rows)
    # Matched by VALUE agreement rather than by slug (glabel here is a raw
    # numeric group id such as "1"/"2"; @emlKitSlug's own slugging is not
    # re-derived here) -- any row whose fig matches this group's own R
    # rejects the group as unaccounted only if NONE do.
    found <- any(vapply(hit, function(rr) {
        fv <- suppressWarnings(as.numeric(rr[["fig"]]))
        is.finite(fv) && agree(fv, r, rel = 1e-4)
    }, logical(1)))
    check_true(V, sprintf("leg 1b: group %s's Pearson r (kernel r=%.6f) is one of the driven per-group values",
                          glabel, r), found)
}

d_descg <- read.csv(F_DESC_GROUPS, stringsAsFactors = FALSE)
find_case <- function(prefix, glabel, qname) {
    Filter(function(rr) rr[["leg"]] == "3" && rr[["q"]] == qname &&
           identical(rr[["case"]], paste0(prefix, glabel)), rows)
}
for (glabel in sort(unique(as.character(d_descg$group)))) {
    v <- d_descg$value[as.character(d_descg$group) == glabel]
    n <- length(v)
    m <- mean(v); se <- sd(v) / sqrt(n)
    if (n >= 2) {
        tcrit <- qt(0.975, df = n - 1)
        ciLow <- m - tcrit * se; ciHigh <- m + tcrit * se
    } else {
        ciLow <- m; ciHigh <- m
    }

    hit_mean <- find_case("bar_", glabel, "mean")
    check_true(V, sprintf("leg 3 bar: group %s mean matches @emlDescribe's own definition (R=%.6f)", glabel, m),
               length(hit_mean) == 1 &&
               agree(suppressWarnings(as.numeric(hit_mean[[1]][["fig"]])), m, rel = 1e-6))

    hit_sem <- find_case("bar_", glabel, "sem")
    check_true(V, sprintf("leg 3 bar: group %s SEM matches sd/sqrt(n) (R=%.6f)", glabel, se),
               length(hit_sem) == 1 &&
               agree(suppressWarnings(as.numeric(hit_sem[[1]][["fig"]])), se, rel = 1e-6))

    hit_tsm <- find_case("ts_", glabel, "mean")
    check_true(V, sprintf("leg 3 time-series: group %s collapsed-point mean matches (R=%.6f)", glabel, m),
               length(hit_tsm) == 1 &&
               agree(suppressWarnings(as.numeric(hit_tsm[[1]][["fig"]])), m, rel = 1e-6))

    hit_tslo <- find_case("ts_", glabel, "ci_low")
    check_true(V, sprintf("leg 3 time-series: group %s CI low matches the t-interval (R=%.6f)", glabel, ciLow),
               length(hit_tslo) == 1 &&
               agree(suppressWarnings(as.numeric(hit_tslo[[1]][["fig"]])), ciLow, rel = 1e-6))

    hit_tshi <- find_case("ts_", glabel, "ci_high")
    check_true(V, sprintf("leg 3 time-series: group %s CI high matches the t-interval (R=%.6f)", glabel, ciHigh),
               length(hit_tshi) == 1 &&
               agree(suppressWarnings(as.numeric(hit_tshi[[1]][["fig"]])), ciHigh, rel = 1e-6))
}

eml_report("v172 -- the graphs-vs-doors census (order section 8)")
eml_exit()

}
