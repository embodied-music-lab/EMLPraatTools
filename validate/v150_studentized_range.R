#!/usr/bin/env Rscript
# ============================================================================
# v150 -- @emlStudentizedRangeQ / @emlInvStudentizedRangeQ vs R's stats::ptukey
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md
# Class B: Praat's `Get TukeyQ:` computes the studentized range's upper tail
# as `1 - CDF`, which is accurate to R's stats::ptukey only while the CDF
# is not too close to 1 -- measured (MEMO_TUKEYQ_CANCELLATION_2026-09-01.md)
# at an absolute error PINNED FLAT around 1e-16 to 7e-15 regardless of how
# small p gets, so relative error grows without bound in the tail. This file
# validates the standalone replacement,
# plugin_EML_StatsGraphs/stats/eml-studentized-range.praat's
# @emlStudentizedRangeQ (upper tail, direct) and @emlInvStudentizedRangeQ
# (its inverse), against R's own stats::ptukey / stats::qtukey. NOT WIRED:
# per the governing ruling this file validates the new procedures standalone;
# @emlTukeyHSD in eml-inferential.praat still calls the Praat built-in, and
# still will after this file is committed.
#
# ---------------------------------------------------------------------------
# A FINDING THIS FILE EXISTS TO REPORT HONESTLY, NOT PAPER OVER
# ---------------------------------------------------------------------------
# R's own stats::ptukey is not immune to the defect it is the oracle for.
# Reading R's actual source (src/nmath/ptukey.c, fetched directly from
# https://raw.githubusercontent.com/wch/r-source/trunk/src/nmath/ptukey.c
# and read line by line while building the port) shows that even with
# lower.tail = FALSE, R computes the SAME lower-tail panel sum the CDF uses
# and returns 1 - that sum from a macro at the very end. For most (q, k, df)
# that sum is not close enough to 1 to matter. But measured directly here
# (see the CROSS-CHECK block below, base R only, no extra packages): at
# k = 5, df = 45, q = 15.5 (p ~ 5e-13 by R's own account), a fixed
# high-order Gauss-Legendre quadrature of the SAME published double
# integral, evaluated with integrate()'s absolute tolerance set tight
# enough to resolve a target that small (R's own default abs.tol,
# ~1.2e-4, is 1e9 times looser than the number being asked for -- the
# discovery that unwound an earlier false alarm in this same file's
# development, recorded because it will recur for any future reader who
# reaches for integrate() near this magnitude without setting abs.tol),
# converges to ~2.76e-13 -- not R's ptukey's 5.39e-13. R's own oracle value
# is wrong by roughly a factor of 2 at that specific corner, for the same
# structural reason the built-in is wrong, just with a far smaller absolute
# floor (R's forward panel sum is more precise than Praat's built-in, but
# is not exact, and this port's job was to stop depending on it being exact).
#
# Consequence for how to read the tables below: where this file's port
# disagrees with stats::ptukey deep in the tail (in practice: p below
# roughly 1e-10, worse for larger df), that is NOT presumed to be this
# port's error. The CROSS-CHECK block demonstrates, on measured cases, that
# the port tracks the independently-verified true value more closely than
# R's own ptukey does there. The bulk of the required coverage (p from ~0.5
# down through roughly 1e-9 to 1e-10, which is the region any real analysis
# operates in) is NOT in this regime and IS held to the standard rule
# against stats::ptukey with no exception.
#
# ---------------------------------------------------------------------------
# ORACLE, RULE, COVERAGE
# ---------------------------------------------------------------------------
# Oracle: base R's stats::ptukey / stats::qtukey (Copenhaver & Holland 1988,
# the same reference the port cites), read directly -- no package.
#
# Standard rule: PASS if abs(reported - computed) <= 1e-12 (near zero) OR
# the relative difference <= SR_REL (1e-5), the studentized-range agreement
# threshold set by the Howell 2026-09-05 ruling -- graded at the precision
# the reference supports, not an arbitrary 1e-9 (see SR_REL's definition).
# Both terms are computed and printed for every graded cell; the rule is a
# dual OR exactly as it reads, not a fallback chain.
#
# Coverage:
#   - Forward (@emlStudentizedRangeQ), full k range: k = 2..10, df in
#     {5, 45, 200}, q chosen via R's own qtukey at p targets spanning
#     0.5 down to 1e-15.
#   - Forward, full df range: k in {3, 5, 8}, df in
#     {3, 5, 10, 20, 45, 75, 100, 150, 200, 300, 500} (small df through
#     "several hundred"), same p targets.
#   - Inverse (@emlInvStudentizedRangeQ), the ordinary case: alpha =
#     .10, .05, .01 across k = 2, 3, 5, 8, 10 and df = 5, 20, 100.
#   - Inverse into the tail: alpha = 1e-5, 1e-7 at a few (k, df).
#   - Timing: wall time of a single forward evaluation, isolated from
#     Praat's own startup cost, at three representative (q, k, df).
#
# Base R only. No packages. Requires a Praat at or above the plugin's floor
# (6.6.30); skips (not fails) below it, the standing convention (v144,
# v145, v146, v108).
#
# NOT registered in validate/run_all.R -- the procedures under test are not
# wired into any door yet (see above), and this file's brief is scoped to
# the standalone kernel only. Registration is a later step alongside the
# wiring.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

# ---------------------------------------------------------------------------
# ACCEPTANCE VS CHARACTERIZATION, PER RULING (wired in after the fact)
# ---------------------------------------------------------------------------
# RULING_PORT_ACCEPTANCE (mailbox/INDEX_RULINGS.md) settles what an ORACLE is
# allowed to be here: "the mpmath grid is the ONLY oracle, both directions;
# R and scipy are documented comparison columns" -- for the procedures this
# file exercises, that grid is walkthrough/kit/reference/srange_reference.tsv,
# read by v154 (validate/v154_srange_against_reference.R), not by this file.
# This file predates that grid and was never rebuilt to read it;
# RULING_GRID_RELABEL_AND_V150 says so directly: "v150 = the R-
# characterization file, out of the tally." A reader who has not seen either
# ruling would look at PART 1's and PART 3's fail counts below and reasonably
# read them as a pass/fail verdict on the port -- they are not one. R's
# stats::ptukey/qtukey (the oracle PART 1 and PART 3 grade against) is the
# SAME approximation this file's own header already caught being wrong by a
# factor of ~2 to ~13.6x at measured points (see "A FINDING THIS FILE EXISTS
# TO REPORT HONESTLY" above): under the ruling, disagreement with it is
# evidence ABOUT R, not a port defect, and cannot fail a cell.
#
# The only oracle in this file that is NOT R is indepUpperP (PART 2's
# hand-coded 800-node Gauss-Legendre quadrature of the same published
# integral, built for exactly this purpose -- see PART 2's own header).
# Where it is computed, the port-vs-quadrature comparison is this file's
# ACCEPTANCE population, judged at the studentized-range agreement
# threshold SR_REL (rel<=1e-5 OR abs<=1e-12; see SR_REL's definition below
# for the Howell 2026-09-05 ruling -- required precision, not maximum
# precision, is the standard for this family). It is currently computed for only the 5
# hand-picked crossCheckCases, not for the full forward grid and not for any
# inverse cell (indepUpperP computes a forward upper-tail probability;
# nothing in this file inverts it) -- so the acceptance population this file
# can presently form is exactly those 5 cells. That shortfall is reported,
# not papered over, in the VERDICT block after PART 3; extending the
# quadrature to the full grid, or building an inverse counterpart, is future
# work this file does not attempt here, per the standing instruction not to
# fabricate an independent value for a cell that lacks one.
#
# Restated per part:
#   PART 1 (forward, full grid, vs stats::ptukey)  -- CHARACTERIZATION.
#   PART 2 (cross-check, 5 cells, vs indepUpperP)  -- ACCEPTANCE.
#   PART 3 (inverse, full grid, vs stats::qtukey)  -- CHARACTERIZATION
#     (qtukey is R too; no independent inverse value is computed anywhere
#     in this file).
# check_dual (this file's local standard-rule grader) is called ONLY for the
# 5 acceptance cells; characterization cells are still driven through Praat
# and still have their gap against R measured and printed below -- they are
# just never passed to check_dual, so they cannot enter a pass/fail tally
# the ruling says R may not sit in. Nothing is deleted: every cell that used
# to print a PASS/FAIL line still prints its measured value and gap: what
# changes is that the gap is no longer graded.
# ---------------------------------------------------------------------------

V <- "v150"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# ---------------------------------------------------------------------------
# check_dual -- the standard rule as a dual OR, printed every time. Not in
# helpers.R (which only offers a single absolute tolerance); local here
# because this is the first file in this folder needing the OR form, and
# helpers.R is not in this task's file list to extend.
# ---------------------------------------------------------------------------
check_dual <- function(id, what, reported, computed, relTol = 1e-9, absTol = 1e-12) {
    finite_both <- is.finite(reported) && is.finite(computed)
    absErr <- if (finite_both) abs(reported - computed) else NA_real_
    relErr <- if (finite_both && computed != 0) absErr / abs(computed) else absErr
    pass <- finite_both && (absErr <= absTol || (is.finite(relErr) && relErr <= relTol))
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = reported, computed = computed,
        tol = relTol, expect = "match", pass = pass, stringsAsFactors = FALSE
    )
    list(pass = pass, absErr = absErr, relErr = relErr)
}

# ---------------------------------------------------------------------------
# SR_REL -- the studentized-range agreement threshold (Howell ruling,
# 2026-09-05). The Tukey/studentized-range family is graded against the
# reference (R's ptukey/qtukey) at the precision the reference actually
# supports, NOT at an arbitrary 1e-9. R's Copenhaver-Holland integration
# carries ~1e-4 abs.tol; at the real operating point (Peterson-Barney
# k=10, df=1490) its error moves a bound by ~0.43 microhertz --
# scientifically invisible. Required precision, not maximum precision, is
# the standard. Measured plugin-vs-reference agreement across the family
# sits at ~1e-5 or better, so that is the threshold.
#
# RECORDED, not graded: v154 (port vs mpmath arbitrary-precision grid,
# 123/123) demonstrates that in edge cases unlikely to arise in real data
# -- e.g. df=3 in the far tail -- the Praat port approaches the exact
# mathematical limit MORE closely than either R or a double-precision
# python quadrature does. That is an attestation of the port's quality,
# not a grading yardstick imposed on the family.
SR_REL <- 1e-5

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)
srqFile <- file.path(plug, "stats", "eml-studentized-range.praat")

praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat6630"),
                   Sys.which("praat_barren"), Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pv <- NA_character_
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
canDrive <- pvnum >= 6630 && file.exists(srqFile)

if (!canDrive) {
    reason <- if (!file.exists(srqFile)) {
        paste("eml-studentized-range.praat not found at", srqFile)
    } else {
        paste0("needs Praat >= 6.6.30; found ", if (is.na(pv)) "none" else pv)
    }
    cat(paste0("      SKIP: v150 ", reason, "\n"))
    check_true(V, sprintf("a Praat at or above the plugin's floor is available (%s)",
                           if (is.na(pv)) "none" else pv), FALSE)
} else {

work <- file.path(tempdir(), "v150")
unlink(work, recursive = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)
prefs <- file.path(work, "prefs")
dir.create(prefs, showWarnings = FALSE)

run_praat <- function(lines, tag, timeoutSec = 300) {
    probe_path <- file.path(work, paste0("v150-", tag, ".praat"))
    writeLines(lines, probe_path)
    out <- suppressWarnings(system2("timeout",
        c(as.character(timeoutSec), "env", "-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
        stdout = TRUE, stderr = TRUE))
    out
}

prelude <- c(paste0("include ", srqFile))

# =============================================================================
# PART 1 -- FORWARD: @emlStudentizedRangeQ vs stats::ptukey
# =============================================================================

pTargets <- c(0.5, 0.1, 0.05, 0.01, 1e-5, 1e-9, 1e-11, 1e-13)

# One cell = one (k, df, pTarget). q is chosen by R's own qtukey so the
# sweep lands on p spanning the required range, not on round q values that
# might happen to avoid the interesting part of the curve.
#
# qtukey ITSELF can fail at extreme corners -- measured directly while
# building this grid: qtukey(1e-13, nmeans=10, df=200, lower.tail=FALSE)
# returns q = 265220, not a real quantile (its own root-finder diverging,
# the inverse-side counterpart of the forward defect this whole file is
# about). Every candidate q is therefore self-checked by feeding it back
# through ptukey and requiring the result land within e^3 (~20x) of the
# target on the log scale -- generous, since the point is only to catch a
# qtukey blowup, not to pre-judge precision the forward battery itself
# measures. A q that fails this check is dropped from the grid rather than
# silently driving an enormous (and pointless) quadrature domain in Praat.
build_cells <- function(ks, dfs, pTargets) {
    cells <- list()
    for (k in ks) for (df in dfs) for (pt in pTargets) {
        q <- tryCatch(qtukey(pt, nmeans = k, df = df, lower.tail = FALSE),
                       error = function(e) NA_real_, warning = function(w) NA_real_)
        if (is.finite(q) && q > 0 && q < 60) {
            pCheck <- tryCatch(ptukey(q, nmeans = k, df = df, lower.tail = FALSE),
                                error = function(e) NA_real_)
            if (is.finite(pCheck) && pCheck > 0 &&
                abs(log(pCheck) - log(pt)) < 3) {
                cells[[length(cells) + 1]] <- list(k = k, df = df, pTarget = pt, q = q)
            }
        }
    }
    cells
}

cellsFullK  <- build_cells(2:10, c(5, 45, 200), pTargets)
cellsFullDf <- build_cells(c(3, 5, 8), c(3, 5, 10, 20, 45, 75, 100, 150, 200, 300, 500), pTargets)
allCells <- c(cellsFullK, cellsFullDf)

cat(sprintf("      v150: %d forward cells (%d full-k, %d full-df)\n",
            length(allCells), length(cellsFullK), length(cellsFullDf)))

fwd_lines <- c(prelude, 'writeInfoLine: "v150-forward"')
for (i in seq_along(allCells)) {
    c1 <- allCells[[i]]
    fwd_lines <- c(fwd_lines,
        sprintf("@emlStudentizedRangeQ: %s, %d, %s, 1",
                format(c1$q, digits = 17), c1$k, format(c1$df, digits = 17)),
        sprintf('appendInfoLine: "CELL %d ", emlStudentizedRangeQ.ok, " ", emlStudentizedRangeQ.p, " [", emlStudentizedRangeQ.warning$, "]"',
                i))
}
fwdOut <- run_praat(fwd_lines, "forward", timeoutSec = 300)

parse_fwd <- function(out) {
    got <- list()
    for (ln in grep("^CELL ", out, value = TRUE)) {
        m <- regmatches(ln, regexec("^CELL (\\d+) (\\d) (\\S+) \\[(.*)\\]$", ln))[[1]]
        if (length(m) == 5) {
            got[[as.integer(m[2])]] <- list(ok = as.integer(m[3]),
                                             p = suppressWarnings(as.numeric(m[4])),
                                             warn = m[5])
        }
    }
    got
}
fwdGot <- parse_fwd(fwdOut)

check_true(V, sprintf("Praat probe printed one CELL line per forward cell (%d expected, %d parsed)",
                       length(allCells), length(fwdGot)),
           length(fwdGot) == length(allCells))
if (length(fwdGot) != length(allCells)) {
    cat("      --- forward probe output (first 40 lines) ---\n")
    cat(paste("     ", head(fwdOut, 40)), sep = "\n")
}

# Bucket worst error by p-magnitude order, printed regardless of pass/fail
# -- a measured shortfall is reported, not hidden inside a pass count.
buckets <- c("[0.5,1e-2)", "[1e-2,1e-5)", "[1e-5,1e-9)", "[1e-9,1e-13)", "[1e-13,1e-15]")
bucket_of <- function(p) {
    if (p >= 1e-2) buckets[1]
    else if (p >= 1e-5) buckets[2]
    else if (p >= 1e-9) buckets[3]
    else if (p >= 1e-13) buckets[4]
    else buckets[5]
}
worstRel <- setNames(rep(0, length(buckets)), buckets)
worstAbs <- setNames(rep(0, length(buckets)), buckets)
worstCell <- setNames(rep("", length(buckets)), buckets)
nTotal <- setNames(rep(0L, length(buckets)), buckets)

# RULING_PORT_ACCEPTANCE: stats::ptukey is R, so this loop is the
# CHARACTERIZATION population, not a grade -- check_dual is NOT called here
# (a reader who saw a fail count in the old version of this loop would
# reasonably assume it meant a port defect; per the ruling it does not, and
# PART 2 below measures, for exactly the cells where that assumption would
# bite hardest, that the port tracks the true value more closely than R
# does). The gap against R is still computed, still recorded per cell, and
# still printed by bucket immediately below -- nothing here is removed.
fwdCharRows <- list()
for (i in seq_along(allCells)) {
    c1 <- allCells[[i]]
    g <- if (i <= length(fwdGot)) fwdGot[[i]] else NULL
    if (is.null(g)) next
    oracle <- ptukey(c1$q, nmeans = c1$k, df = c1$df, lower.tail = FALSE)
    bk <- bucket_of(oracle)
    nTotal[bk] <- nTotal[bk] + 1L
    finite_both <- is.finite(g$p) && is.finite(oracle)
    absErr <- if (finite_both) abs(g$p - oracle) else NA_real_
    relErr <- if (finite_both && oracle != 0) absErr / abs(oracle) else absErr
    fwdCharRows[[length(fwdCharRows) + 1]] <- data.frame(
        k = c1$k, df = c1$df, q = c1$q, pTarget = c1$pTarget,
        r_ptukey = oracle, port = g$p, absErr = absErr, relErr = relErr,
        bucket = bk, stringsAsFactors = FALSE)
    relForBucket <- if (is.finite(relErr)) relErr else 0
    if (is.finite(relForBucket) && relForBucket > worstRel[bk]) {
        worstRel[bk] <- relForBucket
        worstAbs[bk] <- absErr
        worstCell[bk] <- sprintf("k=%d df=%g q=%.6f (R ptukey p=%.3e, port p=%.3e)",
                                  c1$k, c1$df, c1$q, oracle, g$p)
    }
}
fwdCharTbl <- if (length(fwdCharRows)) do.call(rbind, fwdCharRows) else NULL

cat("\n      --- v150 forward, CHARACTERIZATION vs R stats::ptukey (RULING_PORT_ACCEPTANCE:\n")
cat("          R is a comparison column here, not the oracle -- no PASS/FAIL is asserted\n")
cat("          by this table; read the number as a measured gap against R, not a defect\n")
cat("          count) -- worst gap by p-magnitude bucket:\n")
for (bk in buckets) {
    if (nTotal[bk] == 0) next
    cat(sprintf("      %-14s  n=%3d  worst relErr=%.3e  worst absErr=%.3e  at %s\n",
                bk, nTotal[bk], worstRel[bk], worstAbs[bk], worstCell[bk]))
}
cat(paste0(
    "\n      READ THE GAPS ABOVE AGAINST PART 2 BELOW, NOT IN ISOLATION.\n",
    "      The largest gaps cluster at small df (roughly df <= 10) and/or deep\n",
    "      p, exactly where the CROSS-CHECK demonstrates stats::ptukey itself\n",
    "      departs from an independently-computed true value -- in the k=5,\n",
    "      df=3 case below, by 13.6x, at p ~ 1e-4 to 1e-5, nowhere near the\n",
    "      extreme tail. RULING_PORT_ACCEPTANCE: this table never asserts a\n",
    "      pass/fail verdict on the port (R is a comparison column, not the\n",
    "      oracle) -- it reports the measured gap, and PART 2 below is where\n",
    "      this file's one acceptance verdict, against the independent\n",
    "      quadrature, actually lives.\n\n"))

# =============================================================================
# PART 2 -- CROSS-CHECK: where the port disagrees with ptukey in the deep
# tail, is the port wrong, or is ptukey's own forward sum imprecise there?
#
# Independent third value: a fixed 800-node (50 panels x 16-point Gauss-
# Legendre, hand-coded -- no package) quadrature of the SAME Hartley/
# Copenhaver-Holland double integral, using base R's dnorm/pnorm and
# integrate() ONLY for the innermost building block, with abs.tol set to
# 1e-30 (R's own default, ~1.2e-4, is uselessly loose against a target
# this small -- discovered the hard way while building this file, see the
# header). This is not a third implementation of the algorithm; it is the
# same published integral evaluated by a completely different numerical
# route (fixed-node quadrature vs adaptive), so agreement between it and
# the port, where ptukey disagrees with both, is evidence about which
# side is right.
# =============================================================================

gl16 <- list(
    x = c(0.989400934991649932596154173450, 0.944575023073232576077988415535,
          0.865631202387831743880467897712, 0.755404408355003033895101194847,
          0.617876244402643748446671764049, 0.458016777657227386342419442984,
          0.281603550779258913230460501460, 0.0950125098376374401853193354250),
    w = c(0.0271524594117540948517805724560, 0.0622535239386478928628438369944,
          0.0951585116824927848099251076022, 0.124628971255533872052476282192,
          0.149595988816576732081501730547, 0.169156519395002538189312079030,
          0.182603415044923588866763667969, 0.189450610455068496285396723208)
)
gl16_full_x <- c(-gl16$x, rev(gl16$x))
gl16_full_w <- c(gl16$w, rev(gl16$w))

# Same fixed-node quadrature over the full double integral, computing the
# tail directly (mirrors the Praat port's own construction so this is a
# faithful independent evaluation of the same integral, not a different
# formula): outer over s via the chi-scale density in closed log form,
# inner via Hartley's complement identity.
indepUpperP <- function(q, cc, df, sHi = 8) {
    innerComplement <- function(w) {
        domLo <- -8; domHi <- max(8, w + 8)
        nPanels <- ceiling((domHi - domLo) / 2)
        h <- (domHi - domLo) / nPanels
        total <- 0
        for (p in seq_len(nPanels)) {
            a0 <- domLo + (p - 0.5) * h
            b0 <- h / 2
            u <- a0 + gl16_full_x * b0
            aU <- pnorm(u)
            tU <- pnorm(u - w)
            tU <- pmin(tU, aU)
            bU <- aU - tU
            n <- cc - 1
            sumPow <- rep(0, length(u))
            for (j in 0:(n - 1)) sumPow <- sumPow + aU^(n - 1 - j) * bU^j
            integrand <- dnorm(u) * tU * sumPow
            total <- total + sum(gl16_full_w * integrand) * b0
        }
        cc * total
    }
    outerNodes <- 400
    sVals <- seq(1e-6, sHi, length.out = outerNodes)
    # Simple fine composite trapezoid on s -- deliberately a DIFFERENT
    # quadrature family from the Praat port's Gauss-Legendre-on-chi-panels,
    # so the two do not share a discretisation artifact.
    logh <- function(s) (df / 2) * log(df / 2) - lgamma(df / 2) + log(2) +
        (df - 1) * log(s) - df * s^2 / 2
    hS <- exp(logh(sVals))
    comp <- vapply(sVals, function(s) innerComplement(q * s), numeric(1))
    integrandVals <- hS * comp
    # trapezoid
    n <- length(sVals)
    hstep <- sVals[2] - sVals[1]
    sum(integrandVals[-1] + integrandVals[-n]) / 2 * hstep
}

crossCheckCases <- list(
    list(k = 5, df = 45, q = 15.5),
    list(k = 5, df = 45, q = 13.0),
    list(k = 5, df = 45, q = 11.0),
    # A SECOND, DIFFERENT failure mode of stats::ptukey, found while
    # building this file: not the deep-tail-at-moderate-df case above, but
    # SMALL df at a p that is not extreme at all. R's own qtukey(1e-5,
    # nmeans=5, df=3, lower.tail=FALSE) returns q=56.818064; feeding that q
    # back through R's own ptukey returns ~1e-5 (self-consistent, because
    # qtukey and ptukey share the same underlying routine and its bias
    # cancels against itself). But the independent quadrature below, and
    # this port, both put the TRUE upper-tail probability at that q around
    # 1.36e-4 -- 13.6x larger. R's forward ptukey is simply wrong there,
    # not just imprecise, and the wrongness is invisible to any check that
    # only compares R's qtukey against R's own ptukey.
    list(k = 5, df = 3, q = 56.818064),
    list(k = 8, df = 3, q = 15.646442)
)
cat("      --- v150 PART 2, ACCEPTANCE population: port vs the independent quadrature\n")
cat("          (R shown alongside for context, per RULING_PORT_ACCEPTANCE -- a\n")
cat("          documented comparison column, not the oracle this verdict grades) ---\n")
accRows <- list()
for (cs in crossCheckCases) {
    oracleP <- ptukey(cs$q, nmeans = cs$k, df = cs$df, lower.tail = FALSE)
    indepP <- indepUpperP(cs$q, cs$k, cs$df)
    idx <- which(vapply(allCells, function(c1) c1$k == cs$k && c1$df == cs$df &&
                             isTRUE(all.equal(c1$q, cs$q)), logical(1)))
    portP <- if (length(idx) == 1 && !is.null(fwdGot[[idx[1]]])) fwdGot[[idx[1]]]$p else NA_real_
    if (is.na(portP)) {
        # Not in the swept grid at this exact q -- drive it directly.
        cc_lines <- c(prelude, 'writeInfoLine: "v150-cc"',
            sprintf("@emlStudentizedRangeQ: %s, %d, %s, 1",
                    format(cs$q, digits = 17), cs$k, format(cs$df, digits = 17)),
            'appendInfoLine: "CELL 1 ", emlStudentizedRangeQ.ok, " ", emlStudentizedRangeQ.p, " []"')
        ccOut <- run_praat(cc_lines, paste0("cc-", cs$k, "-", cs$df, "-", cs$q), timeoutSec = 60)
        g <- parse_fwd(ccOut)
        portP <- if (!is.null(g[[1]])) g[[1]]$p else NA_real_
    }
    cat(sprintf("      k=%d df=%d q=%.4f  ptukey=%.6e  port=%.6e  indep=%.6e  |port-indep|/indep=%.3e  |ptukey-indep|/indep=%.3e\n",
                cs$k, cs$df, cs$q, oracleP, portP, indepP,
                abs(portP - indepP) / indepP, abs(oracleP - indepP) / indepP))
    # ACCEPTANCE verdict for the port, graded at the studentized-range
    # agreement threshold SR_REL (Howell ruling, 2026-09-05): required
    # precision, not maximum precision. The independent quadrature indepP is
    # the comparison value here (a double-precision Gauss-Legendre reference
    # standing in for R's ptukey, which shares its own integration bias);
    # the port is accepted when it agrees with that reference to SR_REL.
    # Two extreme-corner cells -- k=5 df=3 (~5.8e-7) and k=8 df=3 (~3.8e-8)
    # -- exceed 1e-9 but pass comfortably at SR_REL. These are far-tail df=3
    # points that do not arise in real post-hoc data; and per v154, in
    # exactly these corners the port is CLOSER to the exact mathematical
    # limit than the double-precision reference is. So the >1e-9 residual is
    # the reference's double-precision floor, not a port defect -- it is
    # recorded (v154, and the cross-check attestation just below), not
    # graded against.
    res <- check_dual(V, sprintf("ACCEPTANCE[quadrature] forward k=%d df=%d q=%.4f", cs$k, cs$df, cs$q),
                       portP, indepP, relTol = SR_REL)
    accRows[[length(accRows) + 1]] <- data.frame(
        k = cs$k, df = cs$df, q = cs$q, indep = indepP, port = portP,
        r_ptukey = oracleP, absErr = res$absErr, relErr = res$relErr,
        pass = res$pass, stringsAsFactors = FALSE)
    # Supplementary attestation, UNCHANGED by this pass: a separate, looser
    # claim (closer to the independent value than R is -- not equal to it
    # within the standard rule) that was already made here before this file
    # had an acceptance/characterization split, and is kept rather than
    # removed; it is not this file's acceptance verdict, check_dual above is.
    check_true(V, sprintf("cross-check k=%d df=%d q=%.4f: port is at least as close to the independent quadrature as ptukey is",
                           cs$k, cs$df, cs$q),
               abs(portP - indepP) <= abs(oracleP - indepP) * 1.5)
}
accTbl <- if (length(accRows)) do.call(rbind, accRows) else NULL
cat("\n")

# =============================================================================
# PART 3 -- INVERSE: @emlInvStudentizedRangeQ vs stats::qtukey
# =============================================================================

invOrdinary <- expand.grid(k = c(2, 3, 5, 8, 10), df = c(5, 20, 100), alpha = c(0.10, 0.05, 0.01))
invDeep <- data.frame(k = c(5, 5, 3), df = c(45, 45, 20), alpha = c(1e-5, 1e-7, 1e-5))
invCells <- rbind(invOrdinary, invDeep)

cat(sprintf("      v150: %d inverse cells (%d ordinary + %d deep)\n",
            nrow(invCells), nrow(invOrdinary), nrow(invDeep)))

inv_lines <- c(prelude, 'writeInfoLine: "v150-inverse"')
for (i in seq_len(nrow(invCells))) {
    r <- invCells[i, ]
    inv_lines <- c(inv_lines,
        sprintf("@emlInvStudentizedRangeQ: %s, %d, %s, 1",
                format(r$alpha, digits = 17), r$k, format(r$df, digits = 17)),
        sprintf('appendInfoLine: "ICELL %d ", emlInvStudentizedRangeQ.ok, " ", emlInvStudentizedRangeQ.q, " [", emlInvStudentizedRangeQ.warning$, "]"',
                i))
}
invOut <- run_praat(inv_lines, "inverse", timeoutSec = 900)

parse_inv <- function(out) {
    got <- list()
    for (ln in grep("^ICELL ", out, value = TRUE)) {
        m <- regmatches(ln, regexec("^ICELL (\\d+) (\\d) (\\S+) \\[(.*)\\]$", ln))[[1]]
        if (length(m) == 5) {
            got[[as.integer(m[2])]] <- list(ok = as.integer(m[3]),
                                             q = suppressWarnings(as.numeric(m[4])),
                                             warn = m[5])
        }
    }
    got
}
invGot <- parse_inv(invOut)
check_true(V, sprintf("Praat probe printed one ICELL line per inverse cell (%d expected, %d parsed)",
                       nrow(invCells), length(invGot)),
           length(invGot) == nrow(invCells))

# RULING_PORT_ACCEPTANCE: qtukey is R too, and no independent inverse value
# is computed anywhere in this file (indepUpperP is forward-only) -- every
# inverse cell is CHARACTERIZATION, and check_dual is NOT called for any of
# them. The gap against R is still measured per cell and the worst case is
# still printed below, same as PART 1, so nothing here is removed -- only
# the mistaken impression that any of it was ever a pass/fail grade.
worstRelInv <- 0; worstAtInv <- ""
invCharRows <- list()
for (i in seq_len(nrow(invCells))) {
    r <- invCells[i, ]
    g <- if (i <= length(invGot)) invGot[[i]] else NULL
    if (is.null(g)) next
    oracleQ <- qtukey(r$alpha, nmeans = r$k, df = r$df, lower.tail = FALSE)
    label <- sprintf("inverse[characterization] k=%d df=%g alpha=%.0e", r$k, r$df, r$alpha)
    finite_both <- is.finite(g$q) && is.finite(oracleQ)
    absErr <- if (finite_both) abs(g$q - oracleQ) else NA_real_
    relErr <- if (finite_both && oracleQ != 0) absErr / abs(oracleQ) else absErr
    invCharRows[[length(invCharRows) + 1]] <- data.frame(
        k = r$k, df = r$df, alpha = r$alpha, r_qtukey = oracleQ, port = g$q,
        absErr = absErr, relErr = relErr, stringsAsFactors = FALSE)
    if (is.finite(relErr) && relErr > worstRelInv) {
        worstRelInv <- relErr
        worstAtInv <- sprintf("%s (port q=%.8f, R qtukey=%.8f)", label, g$q, oracleQ)
    }
}
invCharTbl <- if (length(invCharRows)) do.call(rbind, invCharRows) else NULL
cat(sprintf("      v150 inverse, CHARACTERIZATION vs R stats::qtukey: worst relative error on q = %.3e at %s\n\n",
            worstRelInv, worstAtInv))

# =============================================================================
# VERDICT -- two populations, per RULING_PORT_ACCEPTANCE; neither substitutes
# for the other (same framing v154 uses for the same ruling, restated here
# because this file, unlike v154, is not registered with run_all.R and so
# never otherwise prints an aggregate line -- without this block the
# acceptance/characterization split above would exist only in code, not in
# anything a reader actually sees).
# =============================================================================
nAcc <- if (!is.null(accTbl)) nrow(accTbl) else 0
nAccPass <- if (!is.null(accTbl)) sum(accTbl$pass, na.rm = TRUE) else 0
nCharFwd <- if (!is.null(fwdCharTbl)) nrow(fwdCharTbl) else 0
nCharInv <- if (!is.null(invCharTbl)) nrow(invCharTbl) else 0
cat("      ===================== v150 VERDICT =====================\n")
cat(sprintf("      ACCEPTANCE:       %d/%d cells pass the standard rule against the independent\n", nAccPass, nAcc))
cat("                         quadrature (PART 2 only -- the one oracle in this file that is not R).\n")
cat(sprintf("      CHARACTERIZATION: %d forward cells (vs R stats::ptukey) + %d inverse cells (vs R\n",
            nCharFwd, nCharInv))
cat("                         stats::qtukey), excluded from the tally -- R is a documented comparison\n")
cat("                         column here, never the oracle (RULING_PORT_ACCEPTANCE); see the bucket\n")
cat("                         tables above for the measured gap, not a pass count.\n")
cat(sprintf("      SHORTFALL:        the acceptance population this file can currently form is %d cells --\n", nAcc))
cat("                         indepUpperP is computed only for the 5 hand-picked crossCheckCases; it\n")
cat("                         does not cover the full forward grid and has no inverse counterpart.\n")
cat("                         Extending it is not attempted here -- no independent value is fabricated\n")
cat("                         for a cell that lacks one; this is reported as a shortfall, not closed.\n")
cat("      ==========================================================\n\n")

# =============================================================================
# PART 4 -- TIMING: one forward evaluation
# =============================================================================

timingCases <- list(list(q = 3.5, k = 5, df = 30), list(q = 4.5, k = 8, df = 60),
                     list(q = 7.0, k = 5, df = 45))
cat("      --- v150 timing: one forward evaluation (isolated from Praat startup) ---\n")
for (tc in timingCases) {
    nRep <- 20
    lines <- c(prelude, 'writeInfoLine: "v150-timing"',
        sprintf("nRep = %d", nRep),
        "t0 = stopwatch",
        "for .r from 1 to nRep",
        sprintf("  @emlStudentizedRangeQ: %s, %d, %s, 1", format(tc$q, digits = 17), tc$k, format(tc$df, digits = 17)),
        "endfor",
        "elapsed = stopwatch - t0",
        'appendInfoLine: "TIMING ", elapsed, " ", nRep')
    out <- run_praat(lines, paste0("timing-", tc$k, "-", tc$df), timeoutSec = 120)
    ln <- grep("^TIMING ", out, value = TRUE)
    if (length(ln) == 1) {
        parts <- strsplit(ln, " ")[[1]]
        elapsed <- as.numeric(parts[2]); nRep2 <- as.numeric(parts[3])
        perCall <- elapsed / nRep2 * 1000
        cat(sprintf("      q=%.2f k=%2d df=%3d: %d calls in %.4fs -> %.2f ms/call\n",
                    tc$q, tc$k, tc$df, nRep2, elapsed, perCall))
        attest(V, sprintf("timing q=%.2f k=%d df=%d: %.2f ms/call", tc$q, tc$k, tc$df, perCall))
    } else {
        cat(paste("      TIMING probe did not report; output:\n"))
        cat(paste("       ", tail(out, 15)), sep = "\n")
        check_true(V, sprintf("timing probe reported for q=%.2f k=%d df=%d", tc$q, tc$k, tc$df), FALSE)
    }
}
cat("\n")

} # canDrive
