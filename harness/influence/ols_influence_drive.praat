# ============================================================================
# ols_influence_drive.praat -- drive @emlOLSInfluence over the committed
# regression input and over designed cases, headlessly, and emit every number
# so R can check all of it.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Nothing is compared here. Comparison is R's job in
# validate/v24_influence.R, so the two halves cannot quietly agree by
# sharing code.
#
#     praat --run harness/influence/ols_influence_drive.praat
#
# from anywhere. The default output is evidence/influence, resolved as
# ../../evidence/influence relative to THIS FILE's directory rather than to
# the working directory -- the same rule Praat's `include` follows. Override
# with EML_INFL_OUT, but give it an ABSOLUTE path: a relative one is
# resolved against this directory too, and
# EML_INFL_OUT=evidence/influence would try to create
# harness/influence/evidence/influence.
#
# Outputs, all under EML_INFL_OUT:
#   data/<case>.csv      the input table, BARE HEADER (see below)
#   rows.csv             per-row: used, fitted, resid, hat, std.resid, cooksd,
#                        and the OLD uncorrected resid/s, so the size of the
#                        correction is in the evidence and not only in prose
#   fits.csv             per-case scalars: n, p, sigma, slope, intercept,
#                        n.singular, error
#
# BARE HEADERS. Praat's "Read Table from comma-separated file..." does NOT
# strip quotes from HEADER cells: a header written as "x" becomes a column
# literally named  "x"  , quote marks included, and every subsequent
# Get value: r, "x" fails to find it. Praat's own
# "Save as comma-separated file..." writes bare headers, which is why the
# data files here are written by Praat rather than assembled as text.
#
# CASES
#   committed   evidence/csv/v13_regression_input.csv -- the regression case
#               the shipping suite drives, practice_hrs_wk -> the response.
#               This is the before/after case: the correction on .std.resid
#               is whatever it is on real data, and it is recorded, not
#               argued about.
#   leverage    25 points on a line plus ONE point pushed far out in x. The
#               designed high-leverage case: h for that row is an order of
#               magnitude above the others, so std.resid and cooksd
#               separate sharply from the uncorrected form.
#   outlier     high leverage AND a large residual at the same row -- the
#               case Cook's D exists for. Leverage alone is not influence.
#   missing     the committed data with two cells blanked, one in x and one
#               in y, in different rows. Tests that the row alignment
#               survives listwise deletion: R gets the complete-case frame
#               and its row i must line up with the table row this reports.
#   tiny        n = 3, p = 2. One residual degree of freedom, the smallest
#               fit that is not a refusal.
#
# RED-PATH CASES -- these must REFUSE, and R checks the refusal is warranted
#   red_n2        n = 2. n <= p: no residual df, so sigma does not exist.
#   red_const     predictor is a constant. SSxx = 0, slope undefined.
#   red_perfect   y is an exact linear function of x. sigma = 0, so every
#                 standardised quantity is 0/0. R returns NaN for all rows.
#   red_lev1      23 points at one x value, one point elsewhere. Leverage is
#                 EXACTLY 1 at that row. This is NOT a refusal -- the other
#                 23 rows are fine -- so it is the case that proves the per
#                 row undefined, and that the answer does not depend on
#                 which side of 1 the last bit falls.
#   red_nocol     a column name that is not in the table.
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-linalg.praat
include ../../plugin/stats/eml-optimizer.praat
include ../../plugin/stats/eml-lmm.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_INFL_OUT")
if outDir$ = ""
    outDir$ = "../../evidence/influence"
endif
createDirectory: outDir$
createDirectory: outDir$ + "/data"

rows$ = "case,row,x,y,used,fitted,resid,hat,std.resid,cooksd,old.std.resid"
... + newline$
# sigma.lr is @emlLinearRegression's OWN residual standard error, the one the
# glance frame reports. @emlOLSInfluence computes its sigma from sum(e^2)
# instead, because the fit's SSyy - b*SSxy form cancels catastrophically on a
# near-perfect fit. Both are recorded so v24 can assert they agree everywhere
# they should, and measure the gap where they do not.
fits$ = "case,xcol,ycol,n,nrows,p,sigma,sigma.lr,slope,intercept,"
... + "n.singular,error" + newline$

# ---------------------------------------------------------------------------
# @num$: .v  -- 17 significant digits, "NA" for undefined.
#   string$(), NOT fixed$(v, 17). fixed$ counts DECIMAL PLACES, so on a
#   quantity of order 1e-8 it keeps nine significant digits and throws the
#   rest away. string$() round-trips a double at any magnitude.
# ---------------------------------------------------------------------------
procedure num: .v
    if .v = undefined
        .out$ = "NA"
    else
        .out$ = string$ (.v)
    endif
endproc

# ---------------------------------------------------------------------------
# @runCase: .case$, .tid, .xCol$, .yCol$
#   Call the procedure, save the input, record everything it exposed.
#   The input is saved AFTER the call, not before, so what R reads is
#   provably the table the procedure saw.
# ---------------------------------------------------------------------------
procedure runCase: .case$, .tid, .xCol$, .yCol$
    @emlOLSInfluence: .tid, .xCol$, .yCol$

    selectObject: .tid
    Save as comma-separated file: outDir$ + "/data/" + .case$ + ".csv"

    @num: emlOLSInfluence.sigma
    .sig$ = num.out$
    # Only meaningful when the fit itself ran; @emlLinearRegression leaves
    # .seResidual from a PREVIOUS call otherwise, which would be a stale read.
    .siglr$ = "NA"
    if emlOLSInfluence.n > 0
        @num: emlLinearRegression.seResidual
        .siglr$ = num.out$
    endif
    @num: emlOLSInfluence.slope
    .slp$ = num.out$
    @num: emlOLSInfluence.intercept
    .int$ = num.out$
    fits$ = fits$ + .case$ + "," + .xCol$ + "," + .yCol$ + ","
    ... + string$ (emlOLSInfluence.n) + ","
    ... + string$ (emlOLSInfluence.nRows) + ","
    ... + string$ (emlOLSInfluence.p) + ","
    ... + .sig$ + "," + .siglr$ + "," + .slp$ + "," + .int$ + ","
    ... + string$ (emlOLSInfluence.nSingular) + ","
    ... + """" + emlOLSInfluence.error$ + """" + newline$

    if emlOLSInfluence.error$ = ""
        for .r from 1 to emlOLSInfluence.nRows
            selectObject: .tid
            .xv = Get value: .r, .xCol$
            .yv = Get value: .r, .yCol$
            @num: .xv
            .xs$ = num.out$
            @num: .yv
            .ys$ = num.out$
            @num: emlOLSInfluence.fitted# [.r]
            .fs$ = num.out$
            @num: emlOLSInfluence.resid# [.r]
            .rs$ = num.out$
            @num: emlOLSInfluence.hat# [.r]
            .hs$ = num.out$
            @num: emlOLSInfluence.stdResid# [.r]
            .ss$ = num.out$
            @num: emlOLSInfluence.cooksd# [.r]
            .cs$ = num.out$
            # The OLD emission: resid / s, no leverage term. Recorded so the
            # before/after is in the evidence file.
            .old = undefined
            if emlOLSInfluence.used# [.r] = 1
                .old = emlOLSInfluence.resid# [.r] / emlOLSInfluence.sigma
            endif
            @num: .old
            .os$ = num.out$
            rows$ = rows$ + .case$ + "," + string$ (.r) + ","
            ... + .xs$ + "," + .ys$ + ","
            ... + string$ (emlOLSInfluence.used# [.r]) + ","
            ... + .fs$ + "," + .rs$ + "," + .hs$ + "," + .ss$ + ","
            ... + .cs$ + "," + .os$ + newline$
        endfor
    endif
endproc

# ---------------------------------------------------------------------------
# CASE: committed -- the shipping regression input
# ---------------------------------------------------------------------------
committed = Read Table from comma-separated file:
... "../../evidence/csv/v13_regression_input.csv"
Rename: "committed"
@runCase: "committed", committed, "practice_hrs_wk", "vibrato_regularity_pct"

# The same table with a second predictor, to show the procedure is not
# hard-wired to one column pair.
selectObject: committed
copyExp = Copy: "committed_exp"
@runCase: "committed_exp", copyExp, "experience_yrs", "vibrato_regularity_pct"

# ---------------------------------------------------------------------------
# CASE: missing -- listwise deletion, holes in DIFFERENT rows of x and y
# ---------------------------------------------------------------------------
selectObject: committed
miss = Copy: "missing"
Set string value: 4, "practice_hrs_wk", ""
Set string value: 17, "vibrato_regularity_pct", ""
Set string value: 22, "practice_hrs_wk", ""
@runCase: "missing", miss, "practice_hrs_wk", "vibrato_regularity_pct"

# ---------------------------------------------------------------------------
# CASE: leverage -- one point far out in x, on the line
# ---------------------------------------------------------------------------
random_initializeWithSeedUnsafelyButPredictably: 20260807
lev = Create Table with column names: "leverage", 26, "x y"
for r from 1 to 25
    xv = r * 0.4
    Set numeric value: r, "x", xv
    Set numeric value: r, "y", 3 + 1.7 * xv + randomGauss (0, 1.2)
endfor
Set numeric value: 26, "x", 60
Set numeric value: 26, "y", 3 + 1.7 * 60 + 0.5
@runCase: "leverage", lev, "x", "y"

# ---------------------------------------------------------------------------
# CASE: outlier -- high leverage AND a big residual in the same row
# ---------------------------------------------------------------------------
selectObject: lev
out = Copy: "outlier"
Set numeric value: 26, "y", 3 + 1.7 * 60 - 45
@runCase: "outlier", out, "x", "y"

# ---------------------------------------------------------------------------
# CASE: tiny -- n = 3, one residual degree of freedom
# ---------------------------------------------------------------------------
tiny = Create Table with column names: "tiny", 3, "x y"
Set numeric value: 1, "x", 1
Set numeric value: 1, "y", 2.5
Set numeric value: 2, "x", 2
Set numeric value: 2, "y", 3.1
Set numeric value: 3, "x", 5
Set numeric value: 3, "y", 9.4
@runCase: "tiny", tiny, "x", "y"

# ---------------------------------------------------------------------------
# RED: n = 2
# ---------------------------------------------------------------------------
r2 = Create Table with column names: "red_n2", 2, "x y"
Set numeric value: 1, "x", 1
Set numeric value: 1, "y", 4
Set numeric value: 2, "x", 3
Set numeric value: 2, "y", 9
@runCase: "red_n2", r2, "x", "y"

# ---------------------------------------------------------------------------
# RED: constant predictor
# ---------------------------------------------------------------------------
rc = Create Table with column names: "red_const", 8, "x y"
for r from 1 to 8
    Set numeric value: r, "x", 7
    Set numeric value: r, "y", r * 1.3 + 2
endfor
@runCase: "red_const", rc, "x", "y"

# ---------------------------------------------------------------------------
# RED: perfect fit -- sigma = 0
# ---------------------------------------------------------------------------
rp = Create Table with column names: "red_perfect", 9, "x y"
for r from 1 to 9
    Set numeric value: r, "x", r
    Set numeric value: r, "y", 2 * r + 1
endfor
@runCase: "red_perfect", rp, "x", "y"

# ---------------------------------------------------------------------------
# nearperfect -- the OTHER side of the sigma = 0 refusal. One point off the
# line by 1e-9. sigma is tiny but genuinely positive, so this is NOT refused
# and the standardised residuals are large. R does exactly the same, and v24
# asserts the two agree; the case exists so that widening the sigma refusal
# to a tolerance would break something visible.
# ---------------------------------------------------------------------------
np = Create Table with column names: "nearperfect", 9, "x y"
for r from 1 to 9
    Set numeric value: r, "x", r
    Set numeric value: r, "y", 2 * r + 1
endfor
Set numeric value: 5, "y", 2 * 5 + 1 + 1e-9
@runCase: "nearperfect", np, "x", "y"

# ---------------------------------------------------------------------------
# RED: leverage exactly 1 -- NOT a refusal, one undefined row
# 23 points share an x value, one point sits elsewhere. h for that row is
# 1/n + (x-xbar)^2/SSxx = 1 exactly, in real arithmetic. In floating point it
# lands a few ulp either side of 1, which is the whole reason for the clamp.
# x24 = 1.4 is the value that lands just BELOW 1 and that made the bare
# `if h < 1` test in @emlLMMInfluence report a Cook's D of 46.56.
# ---------------------------------------------------------------------------
rl = Create Table with column names: "red_lev1", 24, "x y"
for r from 1 to 23
    Set numeric value: r, "x", 0
    Set numeric value: r, "y", (r mod 5) * 0.6 + 1
endfor
Set numeric value: 24, "x", 1.4
Set numeric value: 24, "y", 5.5
@runCase: "red_lev1", rl, "x", "y"

# The same shape one ulp the other way, to show the answer does not move.
selectObject: rl
rl2 = Copy: "red_lev1b"
Set numeric value: 24, "x", 0.7
@runCase: "red_lev1b", rl2, "x", "y"

# ---------------------------------------------------------------------------
# RED: column not in the table
# ---------------------------------------------------------------------------
selectObject: tiny
rn = Copy: "red_nocol"
@runCase: "red_nocol", rn, "not_a_column", "y"

# ---------------------------------------------------------------------------
writeFile: outDir$ + "/rows.csv", rows$
writeFile: outDir$ + "/fits.csv", fits$
writeInfoLine: "ols_influence_drive: wrote ", outDir$, "/rows.csv and fits.csv"
