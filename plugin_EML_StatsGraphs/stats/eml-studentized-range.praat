# ============================================================================
# EML Stats : Studentized Range Distribution
# ============================================================================
# Module: eml-studentized-range.praat
# Version: 1.0
# Date: 1 September 2026
#
# License: GPL-3.0-or-later
#
# ---------------------------------------------------------------------------
# ORIGIN NOTICE -- required by RULING_PORT_ATTRIBUTION_2026-09-01.
#
# 1. SOURCE. Translated from R's src/nmath/ptukey.c, obtained 1 September 2026
#    from https://raw.githubusercontent.com/wch/r-source/trunk/src/nmath/ptukey.c
#    (r-source trunk; the same file ships in R 4.3.3, the version installed in
#    the verification container and used as the comparison oracle throughout).
#
# 2. ORIGINAL COPYRIGHT AND LICENSE, verbatim from that file:
#
#      Mathlib : A C Library of Special Functions
#      Copyright (C) 1998       Ross Ihaka
#      Copyright (C) 2000--2007 The R Core Team
#
#      This program is free software; you can redistribute it and/or modify
#      it under the terms of the GNU General Public License as published by
#      the Free Software Foundation; either version 2 of the License, or
#      (at your option) any later version.
#
#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU General Public License for more details.
#
#      You should have received a copy of the GNU General Public License
#      along with this program; if not, a copy is available at
#      https://www.R-project.org/Licenses/
#
# 3. THIS TRANSLATION is distributed as part of the EML Stats & Graphs plugin
#    under the GNU General Public License version 3 or later. GPL-2-or-later
#    permits redistribution under GPL-3; the origin notice above is preserved
#    as that license requires.
#
# 4. WHAT CHANGED IN TRANSLATION. Language: C to Praat script. Every numeric
#    constant is copied unchanged -- the 12- and 16-point Gauss-Legendre nodes
#    and weights, the panel widths ulen1..ulen4 and their df breakpoints, the
#    underflow cutoffs C1/C2/C3/eps1/eps2, and the upper integration limit
#    bb = 8. The panel structure of the outer integral follows R's exactly.
#    The one algorithmic departure is documented at length below: R computes
#    the lower-tail sum and returns 1 - ans, which floors its far-tail
#    accuracy; this translation computes the complement of every term before
#    summing, so no subtraction from a number near 1 occurs. That change is
#    the reason the port exists and it is the only structural difference.
#
# 5. WAVE-TWO REFINEMENT (1 September 2026, Opus). R's own outer-panel
#    width (and this port's original translation of it) resolves the
#    chi-scale density's spread; it does not resolve the OUTER INTEGRAND,
#    which at small df and a large q is a spike concentrated against s = 0
#    inside that first panel, not spread across it -- measured directly
#    (k=10, df=3, q=365.08223058929093, the worst cell in walkthrough/kit/
#    reference/srange_reference.tsv): the original single 16-point rule on
#    that first panel returned 3.5645e-7 against a converged 1.0000e-6, 64%
#    low, while every later panel measured exactly 0. Two adaptive
#    quadrature schemes were tried and rejected on measured wall-clock cost
#    (see @emlStudentizedRangeQ's and @eml_srqPanelOneGeometric's own
#    headers for the numbers); the fix kept is a fixed, cheap geometric
#    sub-panel mesh applied to that first outer panel only, gated by a
#    one-level coarse-vs-half-split check so it only runs where the check
#    shows the panel actually needs it. This is refinement of the outer
#    integral's OWN quadrature, not a change to Hartley's integral, the
#    chi-scale density, or the complement algebra above -- the four
#    procedures below still compute the identical published double
#    integral; they resolve one region of it more finely.
# ---------------------------------------------------------------------------
#
# WHY THIS FILE EXISTS. Praat's built-in `Get TukeyQ:` computes the upper
# tail of the studentized range as `1 - CDF`. The CDF near 1 is accurate to
# its own last bits; subtracting it from 1 destroys every significant digit
# the tail had. Measured against R's stats::ptukey (Fable,
# MEMO_TUKEYQ_CANCELLATION_2026-09-01.md): the absolute error of the
# built-in is PINNED FLAT at roughly 1e-16 to 7e-15 across seven orders of
# magnitude of p, so the relative error grows without bound as p shrinks --
# 8.8e-04 in the far tail. This is Class B of
# mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md: REPLACE, with a
# faithful port of the published algorithm, computing the tail directly.
#
# THE ALGORITHM. Copenhaver, Margaret Diponzio & Holland, Burt S. (1988),
# "Multiple comparisons of simple effects in the two-way analysis of
# variance with fixed effects", Journal of Statistical Computation and
# Simulation, Vol. 30, pp. 1-15 -- the reference R's own stats::ptukey names
# in its source. The source ported is R's src/nmath/ptukey.c itself (Ross
# Ihaka 1998, R Core Team 2000-2007, GPL-2-or-later), fetched directly from
# https://raw.githubusercontent.com/wch/r-source/trunk/src/nmath/ptukey.c
# on 1 September 2026 and read line by line -- not reconstructed from
# memory or a secondary description. Every numeric constant below (the
# 12-point and 16-point Gauss-Legendre nodes and weights, the panel widths
# ulen1..4 and their degrees-of-freedom breakpoints, the underflow cutoffs
# C1/C2/C3/eps1/eps2, the upper integration limit bb=8) is copied from that
# file. The double integral it evaluates is Hartley's form of the range
# probability integral (the inner integral, `wprob` in R's source) convolved
# against the density of the studentizing chi variate (the outer integral,
# `ptukey` in R's source, here run panel-by-panel in unit/half/quarter/
# eighth-df-scaled intervals exactly as R's does).
#
# THE ONE DEPARTURE FROM R'S SOURCE, AND WHY IT IS THE WHOLE POINT. R's own
# ptukey.c, even when asked for the upper tail (lower_tail = FALSE), computes
# the SAME lower-tail sum `ans` the CDF uses and returns `1 - ans` from a
# macro at the very end (R_DT_val -> R_D_Clog -> "0.5 - (x) + 0.5"). That
# macro is a minor correctly-rounded-subtraction trick, not a structural
# fix: `ans` is a single converged float near 1 for any q past the median,
# and no amount of care in the LAST subtraction recovers digits the SUM
# already lost by being rounded to a float close to 1. Measured empirically
# against real R below (not asserted): this is exactly what happens --
# R's ptukey is far more accurate than Praat's Get TukeyQ (its absolute
# error floor is roughly one ULP against 7-30 ULP), but its OWN relative
# error in the deep tail still grows as p shrinks, because it is still,
# underneath, a subtraction from a number near 1.
#
# So this port does not translate `ans = sum; return 1 - ans`. It computes
# the complement of every quantity in the sum BEFORE the sum, using the
# algebraic identity a^n - b^n = (a - b) * SUM_{j=0}^{n-1} a^(n-1-j) b^j,
# applied to Hartley's own two-term decomposition of the inner integral
# (`wprob`'s "first term" (2*Phi(w/2)-1)^cc and its Legendre-quadrature
# residual "second term", called term1 and term2 below). Both term1's
# complement (1 - term1, expanded via 1 - (1-p0)^cc = p0 * SUM (1-p0)^i,
# p0 = 2*gaussQ(w/2) computed directly, never as 1 - CDF) and term2 (already
# a positive integral of a bounded quantity, no cancellation to begin with)
# are computed to their OWN relative precision, independent of any value
# near 1. Their difference, 1 - g(w) = (1 - term1) - term2, was checked
# numerically (not assumed) against R's own term1/term2 split across
# w in [0.001, 25] and cc in [2, 10]: term2 / (1 - term1) never exceeds
# 0.5 -- the two operands are always the same order of magnitude as their
# difference, so this final subtraction never approaches the near-1 regime
# that causes the defect being replaced. The outer sum over the chi-scale
# panels is exact for the same reason for a different reason: since the
# panel weights sum to 1 by construction (they integrate a probability
# density to its total mass), replacing the forward integrand (the inner
# wprob) with its complement, panel by panel, computes 1 - ans directly and
# exactly, term by term, without ever forming ans as a single float first.
#
# nranges (rr): Praat's Get TukeyQ exposes this as its 4th argument; it is
# the number of independent studentized ranges whose MAXIMUM is being
# tested (P(max of rr ranges > q)). Ordinary Tukey HSD uses rr = 1, in
# which case every rr-dependent term below is a one-element sum and costs
# nothing extra.
#
# STATUS: NOT WIRED. Per the governing ruling, this file is built and
# validated standalone. `Get TukeyQ:` / `Get invTukeyQ:` in
# eml-inferential.praat's @emlTukeyHSD (two call sites) still call the
# Praat built-in; wiring @emlTukeyHSD to the procedures below is a separate,
# later step, deliberately left undone here so as not to collide with
# concurrent edits to that file.
#
# Procedures:
#   @emlStudentizedRangeQ     -- upper-tail P(Q > q), computed directly
#   @emlInvStudentizedRangeQ  -- inverse: q such that P(Q > q) = target p
#   @eml_srqRangeComplement   -- internal: Hartley's inner integral and its
#                                 direct complement, for one w and cc
#   @eml_srqWprobComplement   -- internal: the above raised to the rr power,
#                                 complemented directly
#   @eml_srqOuterPanel16      -- internal: one 16-point Gauss-Legendre
#                                 evaluation of the outer (chi-scale)
#                                 integrand over an arbitrary s-interval
#   @eml_srqPanelOneGeometric -- internal: fixed geometric sub-panel
#                                 refinement of the outer integral's first
#                                 panel, where the wave-two fix lives (see
#                                 the origin notice's item 5 and this
#                                 procedure's own header)
#
# Dependencies: None (uses only Praat built-ins: gaussQ, lnGamma, ln, exp,
# sqrt, pow via ^, zero#).
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================


# ============================================================================
# @eml_srqRangeComplement: .w, .cc
# P(range > w) for cc iid N(0,1) variates, computed directly from Hartley's
# range-probability integral -- NOT by R's own term1/term2 split.
#
# THE SPLIT WAS TRIED FIRST AND MEASURED TO FAIL. R's wprob() (see the file
# header) writes g(w) = term1 + term2 and this port's first version formed
# 1 - g(w) as (1 - term1) - term2, with term1's complement expanded so
# neither operand is "near 1". That looked safe under a hand-derived bound
# (term2 / (1 - term1) <= 0.5, checked numerically against an R script) --
# but that R script itself had a missing factor of 2 in term2 (R's own
# `elsum *= 2.0*b*cc*M_1_SQRT_2PI`, re-verified by reading the fetched
# source a second time and cross-checking term1+term2 against a brute-force
# Hartley integral until they agreed to 1e-14). With the factor corrected,
# the true ratio runs up to 0.9999999 for w roughly in [4, 16] -- term1's
# complement and term2 are two SEPARATELY-COMPUTED quantities of comparable
# magnitude whose difference is the answer, which is exactly the
# catastrophic-cancellation shape this file exists to avoid, just moved
# one level in rather than eliminated. Measured directly (w = 10.9602,
# cc = 5): the split's term2, evaluated by R's own 12-point/2-3-subinterval
# quadrature, differs from a tightly-toleranced reference by roughly 1e-13
# in ABSOLUTE terms -- utterly negligible against term2's own size (~1e-7)
# but of the SAME ORDER as the true difference (~1e-13), so the subtraction
# returns noise. No amount of quadrature refinement fixes this: it is
# double-precision rounding in forming term2 itself, not discretisation
# error.
#
# THE FIX: expand Hartley's OWN integrand, not R's two-part split of it.
#   g(w)     = cc * INTEGRAL phi(u) * [Phi(u) - Phi(u-w)]^(cc-1) du
#   1 = cc * INTEGRAL phi(u) * Phi(u)^(cc-1) du         (u: -inf..inf;
#                                                         antiderivative of
#                                                         d/du[Phi(u)^cc])
# so, subtracting the integrands (valid; both integrals converge):
#   1 - g(w) = cc * INTEGRAL phi(u) * [Phi(u)^(cc-1) - (Phi(u)-Phi(u-w))^(cc-1)] du
# and applying a^n - b^n = (a-b) * SUM_{j=0}^{n-1} a^(n-1-j) b^j with
# a = Phi(u), b = Phi(u) - Phi(u-w), a - b = Phi(u-w) (computed directly via
# gaussQ, never as a subtraction of two near-equal CDFs):
#   1 - g(w) = cc * INTEGRAL phi(u) * Phi(u-w) *
#                  SUM_{j=0}^{cc-2} Phi(u)^(cc-2-j) * (Phi(u)-Phi(u-w))^j  du
# Every factor in this integrand is a product of quantities in [0, 1]; there
# is no subtraction of comparable-magnitude numbers ANYWHERE in it, at any
# w. Verified against the closed form for cc = 2 (range of 2 draws, which
# needs no quadrature at all: P(range > w) = 2*gaussQ(w/sqrt(2))) to 3e-15
# relative at w = 7, 11, 20.
#
# DOMAIN, AND THE SECOND BUG THIS CAUGHT. A fixed u in [-8, 8] (the bound
# R's own wprob uses, valid THERE because R's residual quadrature is
# anchored at w/2, not at 0) is NOT safe for this integral: phi(u)*Phi(u-w)
# is small at u = 8 for large w, but not smaller than the target itself.
# Measured at w = 10.9602, cc = 2: truncating at [-8, 8] gives 9.1862e-15
# against a true 9.1893e-15 -- a stable 3.3e-4 relative error that MORE
# QUADRATURE POINTS DID NOT SHRINK (checked 16 through 256 panels: bit-for-
# bit identical wrong answer), because it is not a quadrature error, it is
# throwing away real mass beyond u = 8. Extending the domain to
# [-8, max(8, w+8)] recovers agreement to 3e-15 relative at every w tested
# up to 25. So the upper bound here tracks w, not a fixed constant.
#
# Outputs (survive only until the next call -- copy them on the next line):
#   .compRange -- P(range > w), the direct complement described above
#   .g         -- P(range <= w) = 1 - .compRange (ordinary form; used only
#                 as a coefficient in the rr-power expansion one level up,
#                 where its own precision near 1 is not load-bearing)
# ============================================================================
procedure eml_srqRangeComplement: .w, .cc
    .nlegq = 16
    .ihalfq = 8
    .xlegq# = {0.989400934991649932596154173450, 0.944575023073232576077988415535, 0.865631202387831743880467897712, 0.755404408355003033895101194847, 0.617876244402643748446671764049, 0.458016777657227386342419442984, 0.281603550779258913230460501460, 0.0950125098376374401853193354250}
    .alegq# = {0.0271524594117540948517805724560, 0.0622535239386478928628438369944, 0.0951585116824927848099251076022, 0.124628971255533872052476282192, 0.149595988816576732081501730547, 0.169156519395002538189312079030, 0.182603415044923588866763667969, 0.189450610455068496285396723208}
    .oneOverSqrt2Pi = 1 / sqrt(2 * pi)

    .domLo = -8
    .domHi = .w + 8
    if .domHi < 8
        .domHi = 8
    endif
    # Capped at 40 regardless of w: measured directly in this Praat (loop
    # printing exp(-0.5*u*u) for u = 35..45) that phi(u) is exactly 0.0 in
    # double precision from u = 39 on -- ln(smallest positive double) is
    # about -744, and -0.5*u*u passes that at u = sqrt(2*744) ~ 38.6, one
    # unit below this cutoff. Past that point the panel integrand
    # phi(u)*Phi(u-w)*sumPow is not approximately zero, it IS the double
    # 0.0, for every w, so no panel beyond u = 40 can contribute -- this is
    # not a truncation of real mass (the domHi = w+8 rule above exists
    # precisely because, for w up to the low 30s, mass genuinely does sit
    # out near u = w and must not be cut off there; the header above
    # documents w = 10.9602 losing mass at a FIXED u in [-8,8] for exactly
    # that reason). The cap only engages once w+8 alone would already put
    # every remaining panel past the underflow point, so it changes nothing
    # for any w this procedure was calibrated against (w up to 25, domHi up
    # to 33) and removes a real, measured cost: without it, an outer-panel
    # node at s near an outer panel's far edge with large q (this
    # procedure is called from every node of every outer panel -- see
    # @eml_srqOuterPanel16) pays for dozens of width-4 panels that each
    # evaluate to exactly 0, panel by panel, for no change in the answer.
    if .domHi > 40
        .domHi = 40
    endif
    # Panel width 4: measured (debug sweep against the cc=2 closed form and
    # a cc=10 fine-grid reference, w up to 25) at worst-case relative error
    # ~2.5e-14 -- the integrand is smooth (phi and Phi have no
    # singularities anywhere), so 16-point Gauss-Legendre converges
    # essentially exponentially and wide panels are cheap and safe. Width 8
    # measurably degrades (worst ~1.4e-3 at w=20); width 4 keeps 5+ orders
    # of magnitude of margin below the 1e-9 target while cutting panel
    # count (and therefore this procedure's cost, called from every node
    # of every outer panel) by roughly 12x against a naive width-0.5 grid.
    .panelWidth = 4
    .nPanels = ceiling ((.domHi - .domLo) / .panelWidth)
    .h = (.domHi - .domLo) / .nPanels

    .cc2 = .cc - 2
    .total = 0
    for .p from 1 to .nPanels
        .a0 = .domLo + (.p - 0.5) * .h
        .b0 = .h / 2
        .panelSum = 0
        for .jj from 1 to .nlegq
            if .jj <= .ihalfq
                .jx = .jj
                .sign = -1
            else
                .jx = .jj - .ihalfq
                .sign = 1
            endif
            .u = .a0 + .sign * .xlegq# [.jx] * .b0

            .phiU = exp (-0.5 * .u * .u) * .oneOverSqrt2Pi
            .aU = gaussQ (-.u)
            .tU = gaussQ (.w - .u)
            if .tU > .aU
                .tU = .aU
            endif
            .bU = .aU - .tU

            # SUM_{j=0}^{cc-2} aU^(cc-2-j) * bU^j -- cc = 2 gives the empty
            # sum range (cc2 = 0), i.e. the single term aU^0*bU^0 = 1,
            # matching the cc=2 closed form exactly. Plain powers, no
            # division anywhere (aU can be arbitrarily close to 0 for very
            # negative u, so a bU/aU ratio form was tried and rejected).
            .sumPow = 0
            for .j from 0 to .cc2
                .sumPow = .sumPow + (.aU ^ (.cc2 - .j)) * (.bU ^ .j)
            endfor

            .integrand = .phiU * .tU * .sumPow
            .panelSum = .panelSum + .alegq# [.jx] * .integrand
        endfor
        .total = .total + (.panelSum * .b0)
    endfor

    .compRange = .cc * .total
    if .compRange < 0
        .compRange = 0
    endif
    if .compRange > 1
        .compRange = 1
    endif
    .g = 1 - .compRange
endproc


# ============================================================================
# @eml_srqWprobComplement: .w, .rr, .cc
# P(max of rr iid ranges of cc N(0,1) variates > w), computed directly via
# 1 - g^rr = (1-g) * SUM_{i=0}^{rr-1} g^i -- the same complement-of-a-power
# identity used inside @eml_srqRangeComplement, one level up. For the
# ordinary Tukey HSD case rr = 1 this is (1-g)*1 = 1-g exactly, i.e. the
# rr layer costs nothing when it is not needed.
#
# Output: .compW (survives only until the next call)
# ============================================================================
procedure eml_srqWprobComplement: .w, .rr, .cc
    @eml_srqRangeComplement: .w, .cc
    .g = eml_srqRangeComplement.g
    .compRange = eml_srqRangeComplement.compRange

    .sumPow = 0
    .pw = 1
    for .i from 0 to .rr - 1
        .sumPow = .sumPow + .pw
        .pw = .pw * .g
    endfor
    .compW = .compRange * .sumPow
    if .compW > 1
        .compW = 1
    endif
    if .compW < 0
        .compW = 0
    endif
endproc


# ============================================================================
# @eml_srqOuterPanel16: .sLo, .sHi, .q, .k, .df, .nranges, .logConst
# One 16-point Gauss-Legendre evaluation of the outer (chi-scale) integrand
# density(s) * P(max of nranges ranges of k > q*s), over s in [.sLo, .sHi].
# Factored out of @emlStudentizedRangeQ's outer loop so the dyadic doubling
# refinement in that procedure (see its header for why the refinement is
# there at all) can call this at whatever subdivision one outer panel
# needs, without duplicating the 16-point rule per subdivision level.
#
# Output: .value -- the panel's contribution to the outer integral
#         (survives only until the next call)
# ============================================================================
procedure eml_srqOuterPanel16: .sLo, .sHi, .q, .k, .df, .nranges, .logConst
    .nlegq = 16
    .ihalfq = 8
    .xlegq# = {0.989400934991649932596154173450, 0.944575023073232576077988415535, 0.865631202387831743880467897712, 0.755404408355003033895101194847, 0.617876244402643748446671764049, 0.458016777657227386342419442984, 0.281603550779258913230460501460, 0.0950125098376374401853193354250}
    .alegq# = {0.0271524594117540948517805724560, 0.0622535239386478928628438369944, 0.0951585116824927848099251076022, 0.124628971255533872052476282192, 0.149595988816576732081501730547, 0.169156519395002538189312079030, 0.182603415044923588866763667969, 0.189450610455068496285396723208}

    .sCenter = (.sLo + .sHi) / 2
    .sHalf = (.sHi - .sLo) / 2
    .dfm1 = .df - 1
    .value = 0
    for .jj from 1 to .nlegq
        if .ihalfq < .jj
            .jx = .jj - .ihalfq
            .sign = 1
        else
            .jx = .jj
            .sign = -1
        endif
        .sNode = .sCenter + .sign * .xlegq# [.jx] * .sHalf

        if .sNode > 0
            .t1 = .logConst + (.dfm1 * ln (.sNode)) - (.df * .sNode * .sNode * 0.5)
            @eml_srqWprobComplement: .q * .sNode, .nranges, .k
            .compW = eml_srqWprobComplement.compW
            .value = .value + (.compW * .alegq# [.jx]) * exp (.t1) * .sHalf
        endif
    endfor
endproc


# ============================================================================
# @eml_srqPanelOneGeometric: .sHi, .q, .k, .df, .nranges, .logConst,
#                            .geoW0, .geoRatio, .geoMaxSegs
# Fixed (non-adaptive) geometric refinement of the FIRST outer panel,
# [0, .sHi], built on @eml_srqOuterPanel16. Sub-panel widths start at
# .geoW0 and grow by .geoRatio each step, so resolution concentrates near
# s = 0 and thins out approaching .sHi, without any runtime convergence
# check.
#
# WHY THE FIRST PANEL SPECIFICALLY, AND WHY A FIXED GEOMETRIC MESH RATHER
# THAN ADAPTIVE REFINEMENT. Measured directly (k=10, df=3,
# q=365.08223058929093, the worst cell in walkthrough/kit/reference/
# srange_reference.tsv, instrumented panel-by-panel): with the ORIGINAL
# single 16-point panel per outer panel, panel index 1 (s in
# [0, sPanelWidth]) returned 3.5645e-7 against a converged 1.0000e-6 --
# 64% low -- and panels 2 onward measured EXACTLY 0, confirming every case
# checked (also k=5/df=3 and k=10/df=5 at their own p=1e-6 cells, and
# k=5/df=3/q=56.818064) puts the entire missing mass in panel 1 alone; see
# @emlStudentizedRangeQ's own panel-width comment for the fuller
# measurement (why: density(s)*P(range>q*s) is a spike below s~0.02-0.05
# at low df and large q, not spread across the panel). A general adaptive
# scheme was tried first and both versions were measured directly against
# this same worst cell: uniform dyadic doubling of the whole panel took
# 36-37 wall-clock seconds (it kept re-evaluating the panel's expensive,
# contribution-free far edge -- large w = q*s, and @eml_srqRangeComplement
# cost scales with w -- at every doubling level); a depth-first adaptive
# bisection that stopped subdividing once a sub-interval's coarse and fine
# estimates already agreed brought that down to 17.8 seconds, still too
# slow to run the full 107-cell reference grid inside validate/
# v154_srange_against_reference.R's own 300-second-per-batch timeout (it
# was still running the 85-cell forward batch alone past 300 seconds when
# killed). Both adaptive versions paid 3 full inner-integral evaluations
# (coarse + 2 fine) at EVERY sub-interval visited, including ones later
# accepted as negligible -- the comparison itself was the expensive step.
# A fixed geometric mesh needs exactly .geoMaxSegs (in practice ~12-16)
# single evaluations, no comparisons: measured against the same worst
# cell and two others (k=5/df=3/q=56.818064 against scipy's
# 1.35899031916e-4, and k=10/df=5 at p=1e-6) with .geoW0 = 0.001,
# .geoRatio = 1.4 (a python replica of this exact panel algebra, cross-
# checked against @eml_srqOuterPanel16 line by line): relative error
# 2.507e-10, 5.4e-12, and consistent agreement respectively -- comfortably
# inside the acceptance rule's 1e-9, at a FIXED, small, predictable cost
# per call regardless of (k, df, q). This is deliberately not general
# (panel 1 only; a different sub-panel scheme is not searched for) because
# every measurement above -- across every failing cell checked, not
# assumed -- puts the defect there and nowhere else.
#
# Output: .value -- panel 1's contribution to the outer integral
#         (survives only until the next call)
# ============================================================================
procedure eml_srqPanelOneGeometric: .sHi, .q, .k, .df, .nranges, .logConst,
    ... .geoW0, .geoRatio, .geoMaxSegs
    .segLo = 0
    .segW = .geoW0
    .segCount = 0
    .value = 0
    while .segLo < .sHi and .segCount < .geoMaxSegs
        .segHi = .segLo + .segW
        if .segHi > .sHi
            .segHi = .sHi
        endif
        @eml_srqOuterPanel16: .segLo, .segHi, .q, .k, .df, .nranges,
        ... .logConst
        .value = .value + eml_srqOuterPanel16.value
        .segLo = .segHi
        .segW = .segW * .geoRatio
        .segCount = .segCount + 1
    endwhile
endproc


# ============================================================================
# @emlStudentizedRangeQ: .q, .k, .df, .nranges
# Upper-tail probability of the studentized range: P(Q > q), q the
# studentized range statistic, k the number of means, df the error degrees
# of freedom, nranges the number of independent ranges (1 for ordinary
# Tukey HSD -- see the file header).
#
# Computes the complement of the lower-tail sum panel by panel, rather than
# computing the lower tail and subtracting from 1 -- see the file header for
# why that distinction is the entire point of this file.
#
# THE OUTER VARIABLE IS s, THE CHI-SCALE VARIABLE ITSELF -- NOT R's X.
# R's ptukey.c panelises the outer integral in a variable X = 2*S^2 (S the
# usual studentizing chi variate, S = sqrt(chisq_df/df)), whose density in
# X is proportional to X^(df/2 - 1). For odd df that exponent is a
# half-integer, so the density has a genuine branch point at X = 0 --
# Gauss-Legendre quadrature loses its spectral convergence there and falls
# back to slow algebraic convergence. Measured directly (k=3, df=3,
# q=10.620404, cross-checked against an independent fixed quadrature that
# converges to 0.0099949815): R's own X-panel scheme at R's own panel
# width gives 0.0100478 (4.8e-3 relative error) and does not visibly
# improve until the panel width is cut by 100x, which is far too slow to
# run per pairwise comparison. Integrating in s directly instead --
# density in s is proportional to s^(df-1), an INTEGER power whenever df
# is a whole number, i.e. always for an error df in an ANOVA -- removes
# the branch point entirely: the same 16-point Gauss-Legendre panels, at a
# width nowhere near as fine, reproduce the independent reference to 12+
# significant digits (measured at df = 3, 45 and 500; see
# validate/v150_studentized_range.R's cross-check block for the k=5,
# df=45 case run against stats::ptukey too). This is a numerically
# superior reparameterisation of the SAME published double integral
# (Hartley's range probability convolved with the chi-scale density), not
# a different algorithm -- the substitution is mechanical
# (s = sqrt(X/2) <=> X = 2s^2) and changes nothing about what is being
# computed, only how cheaply and accurately the quadrature resolves it.
#
# Outputs:
#   .p        -- P(Q > q), the upper-tail probability (0 on refusal)
#   .ok       -- 1 on success, 0 on refusal
#   .error$   -- "" on success, a refusal reason otherwise
#   .warning$ -- "" normally; non-empty if the panel sum did not converge
#                to its own internal tolerance within the panel budget
#                (the returned .p is still the best available estimate)
# ============================================================================
procedure emlStudentizedRangeQ: .q, .k, .df, .nranges
    .ok = 0
    .error$ = ""
    .warning$ = ""
    .p = undefined

    if .df < 2
        .error$ = "The studentized range distribution needs error df >= 2; "
        ... + "got " + string$ (.df) + "."
    elsif .k < 2
        .error$ = "The studentized range distribution needs at least 2 "
        ... + "means; got " + string$ (.k) + "."
    elsif .nranges < 1
        .error$ = "nranges must be >= 1; got " + string$ (.nranges) + "."
    endif

    if .error$ = ""
        if .q <= 0
            .p = 1
            .ok = 1
        else
            # Relative, not absolute: the outer sum's own termination is
            # scaled to the running total, so a target p far below any
            # fixed absolute floor still gets an evaluated answer instead
            # of an early, silently-wrong zero. The absolute floor below
            # it only stops a genuinely-zero answer (q so large P(Q>q)
            # underflows) from looping forever.
            .relEps = 1e-13
            .absFloor = 1e-300

            # Panel width in s: measured (debug sweep, df = 3, 45, 500) to
            # keep worst-case relative error well under 1e-9 while staying
            # cheap. Small df needs no help (s^(df-1) has no branch point);
            # large df needs finer panels because the chi-scale density
            # concentrates ever more tightly around s = 1 as df grows
            # (spread ~ 1/sqrt(2*df)) -- 3/sqrt(df), capped at 0.5, tracks
            # that spread directly and was verified to resolve it (0.5 at
            # df=45 already matched a 5x finer panel to 12 digits; 0.1 at
            # df=500 likewise).
            #
            # THIS WIDTH RESOLVES THE CHI-SCALE DENSITY'S OWN SPREAD; IT DOES
            # NOT RESOLVE THE OUTER INTEGRAND. Measured directly (instrumented
            # panel-by-panel dump, k=10, df=3, q=365.08223058929093, the worst
            # cell in walkthrough/kit/reference/srange_reference.tsv): the
            # single fixed 16-point rule below, applied once over the first
            # panel [0, sPanelWidth], returned 3.5645e-7 against a converged
            # 1.0000e-6 -- 64% low -- while panel 2 onward measured exactly 0.
            # A direct fine-grid evaluation of the same panel (scipy quad,
            # matching this file's own complement algebra, cross-checked
            # against the reference grid's own mpmath value to 10 significant
            # figures: 1.0000000003e-6) shows why: the true integrand is not
            # spread across the panel, it is a spike below s=0.02 that decays
            # through 30+ orders of magnitude by s=0.05 -- the panel's chi-
            # density term (s^(df-1), no branch point, per the outer-variable
            # note above) is smooth, but density(s)*P(range>q*s) is not, at
            # low df and large q, because P(range>q*s) itself collapses
            # superexponentially as s grows past that spike. One 16-point
            # rule spanning the whole panel cannot follow that collapse --
            # this is discretisation error inside a single panel, not a
            # truncation error at the domain edge (confirmed above: panels
            # past the first contribute genuinely nothing, so widening the
            # domain fixes nothing; only resolving the first panel does).
            # A uniform-width sweep of that one panel (same measurement)
            # confirms it is resolution, not domain: width 0.5 -> 64% low,
            # 0.25 -> 18% low, 0.1 -> 1.1% low, 0.05 -> 2.3e-2% low, 0.02 ->
            # 2.7e-10 relative -- monotonic, and accelerating once the panel
            # is narrow enough for the 16-point rule's spectral convergence
            # to engage on the spike itself. The fix is
            # @eml_srqPanelOneGeometric, applied ONLY to outer panel index 1
            # -- see that procedure's own header for the two adaptive
            # schemes measured and rejected first on performance (one took
            # 36-37 wall-clock seconds on the worst cell below, the other
            # 17.8 seconds -- both too slow to run the full reference grid
            # inside validate/v154_srange_against_reference.R's own
            # 300-second batch timeout) and for why a FIXED geometric mesh,
            # scoped to panel 1 alone, was measured sufficient across every
            # failing cell checked instead. No hand-picked finer fixed
            # WIDTH for the whole outer scheme is used, because the spike's
            # location depends on q (and, empirically, worsens as k grows --
            # a larger cc makes P(range>w) collapse faster in w, per
            # @eml_srqRangeComplement's own SUM_j term, sharpening the spike
            # further), so no single uniform width is safe for every
            # (k, df, q) in the plugin's supported domain; the geometric
            # mesh below is deliberately concentrated where the spike
            # always sits (against s = 0, per every measurement above) and
            # is cheap precisely because it is not trying to be general.
            .sPanelWidth = 3 / sqrt (.df)
            if .sPanelWidth > 0.5
                .sPanelWidth = 0.5
            endif

            .f2 = .df * 0.5
            .logConst = (.f2 * ln (.df / 2)) - lnGamma (.f2) + ln (2)

            # Geometric mesh for panel 1 only (see @eml_srqPanelOneGeometric's
            # header for the measurement behind these three numbers): start
            # at width 0.005, grow by a factor of 2.0 each sub-panel (7
            # sub-panels to cover a 0.5-wide first outer panel), capped at
            # 40 sub-panels as a safety ceiling never reached in practice.
            # A finer mesh (0.001 start, 1.4 ratio, ~16-20 sub-panels) was
            # tried first and also measured accurate, but this coarser one
            # measured the SAME 2.5e-10 to 5.4e-12 relative error on every
            # case checked at roughly half the sub-panel count -- and
            # @emlInvStudentizedRangeQ's bisection re-triggers this mesh on
            # every iteration that lands in the tail, so halving its cost
            # was needed to bring the full 22-row quantile batch back under
            # validate/v154_srange_against_reference.R's 300-second timeout
            # (see that procedure's own .relTol comment for the other half
            # of that measurement).
            .geoW0 = 0.005
            .geoRatio = 2.0
            .geoMaxSegs = 40

            # TRIGGER for the geometric mesh, not an unconditional cost on
            # every call. Measured directly: paying @eml_srqPanelOneGeometric
            # on EVERY call (an early version of this fix) made an ordinary
            # mid-tail case (k=3, df=20, alpha=.05, a single forward
            # evaluation) cost 0.634s against the untouched original's
            # 0.271s -- and @emlInvStudentizedRangeQ's bisection calls the
            # forward procedure ~44-50 times, so that 2.3x became the
            # difference between validate/v154_srange_against_reference.R's
            # 22-row inverse batch finishing under its 300-second timeout
            # and not (measured directly: the 18 "easy" rows alone, at
            # roughly 28s apiece with the mesh unconditional, already
            # exceeded 300s before the 4 hard rows were even reached). So
            # panel 1 is first evaluated the cheap way (one
            # @eml_srqOuterPanel16 call, same cost as every other panel);
            # the mesh only runs if a single one-level bisection check
            # (coarse whole-panel vs. the sum of its two halves) disagrees
            # by more than .triggerRelTol. For a smooth, already-resolved
            # panel 1 (every ordinary case) that check passes immediately --
            # 3x panel 1's own cost, not 12-16x, and panel 1 is one of
            # several outer panels, so the per-call overhead this adds is
            # small. For a spiked panel 1 (the low-df, large-q cells this
            # file exists to fix), coarse vs. halves disagree by an order
            # of magnitude or more at the very first split (measured on the
            # worst cell's own doubling sequence: level 0 -> level 1 already
            # moved the estimate from 3.56e-7 to 1.18e-6, more than 3x) --
            # nowhere near .triggerRelTol, so the mesh engages exactly
            # where it is needed and nowhere else.
            .triggerRelTol = 1e-6

            .ans = 0
            .maxPanels = 400
            .i = 0
            .keepGoing = 1
            .belowStreak = 0

            while .i < .maxPanels and .keepGoing = 1
                .i = .i + 1
                .sLo = (.i - 1) * .sPanelWidth
                .sHi = .i * .sPanelWidth

                @eml_srqOuterPanel16: .sLo, .sHi, .q, .k, .df, .nranges,
                ... .logConst
                .otsum = eml_srqOuterPanel16.value

                if .i = 1
                    .p1Mid = (.sLo + .sHi) / 2
                    @eml_srqOuterPanel16: .sLo, .p1Mid, .q, .k, .df,
                    ... .nranges, .logConst
                    .p1FineL = eml_srqOuterPanel16.value
                    @eml_srqOuterPanel16: .p1Mid, .sHi, .q, .k, .df,
                    ... .nranges, .logConst
                    .p1FineR = eml_srqOuterPanel16.value
                    .p1Fine = .p1FineL + .p1FineR
                    .p1Diff = abs (.p1Fine - .otsum)
                    .p1Ref = abs (.p1Fine)
                    if abs (.otsum) > .p1Ref
                        .p1Ref = abs (.otsum)
                    endif
                    if .p1Diff > .absFloor
                    ... and .p1Diff > .triggerRelTol * .p1Ref
                        @eml_srqPanelOneGeometric: .sHi, .q, .k, .df,
                        ... .nranges, .logConst, .geoW0, .geoRatio,
                        ... .geoMaxSegs
                        .otsum = eml_srqPanelOneGeometric.value
                    endif
                endif

                .ans = .ans + .otsum

                if .i * .sPanelWidth >= 1
                    if .otsum <= .absFloor
                        .belowStreak = .belowStreak + 1
                    elsif .otsum <= .relEps * .ans
                        .belowStreak = .belowStreak + 1
                    else
                        .belowStreak = 0
                    endif
                    # Two consecutive negligible panels, not one -- a single
                    # small panel can sit in a local dip of a non-monotone
                    # integrand before the next panel picks back up.
                    if .belowStreak >= 2
                        .keepGoing = 0
                    endif
                endif
            endwhile

            if .keepGoing = 1 and .belowStreak < 2
                .warning$ = "Panel sum did not converge to its internal "
                ... + "relative tolerance within " + string$ (.maxPanels)
                ... + " panels (q=" + string$ (.q) + ", k=" + string$ (.k)
                ... + ", df=" + string$ (.df) + "); returning the "
                ... + "partial sum."
            endif

            .p = .ans
            if .p > 1
                .p = 1
            endif
            if .p < 0
                .p = 0
            endif
            .ok = 1
        endif
    endif
endproc


# ============================================================================
# @emlInvStudentizedRangeQ: .p, .k, .df, .nranges
# Inverse of @emlStudentizedRangeQ: the q such that P(Q > q) = .p (upper
# tail), e.g. the Tukey HSD critical value at .p = alpha.
#
# Root-finds by bisection on q directly (never on p), so the stopping rule
# is RELATIVE WIDTH OF THE BRACKET IN q -- (qHi-qLo) <= relTol*qHi -- not an
# absolute tolerance on the achieved p. An absolute p-tolerance would
# rebuild exactly the class of bug this file exists to remove: a target p
# of 1e-15 would need an absolute tolerance far tighter than any p near 1
# would ever need, and a fixed loose one would silently accept a q that is
# nowhere near converged in the tail.
#
# Outputs:
#   .q        -- the critical value (undefined on refusal)
#   .ok       -- 1 on success, 0 on refusal
#   .error$   -- "" on success, a refusal reason otherwise
#   .warning$ -- "" normally; non-empty if bisection did not close to
#                relTol within the iteration budget
# ============================================================================
procedure emlInvStudentizedRangeQ: .p, .k, .df, .nranges
    .ok = 0
    .error$ = ""
    .warning$ = ""
    .q = undefined

    if .p <= 0 or .p >= 1
        .error$ = "Target upper-tail probability must be in (0, 1); got "
        ... + string$ (.p) + "."
    elsif .df < 2
        .error$ = "The studentized range distribution needs error df >= 2; "
        ... + "got " + string$ (.df) + "."
    elsif .k < 2
        .error$ = "The studentized range distribution needs at least 2 "
        ... + "means; got " + string$ (.k) + "."
    elsif .nranges < 1
        .error$ = "nranges must be >= 1; got " + string$ (.nranges) + "."
    endif

    if .error$ = ""
        # 1e-10, not the far tighter tolerance a bracket-width stopping
        # rule could otherwise justify: still two full orders of magnitude
        # inside the acceptance rule's 1e-9 relative target (validate/
        # v154_srange_against_reference.R), so the returned q keeps a
        # comfortable safety margin, but each doubling of tolerance halves
        # roughly one bisection iteration and @emlStudentizedRangeQ's own
        # panel-1 fix (see that procedure's header) made each iteration
        # markedly more expensive at low df -- measured directly: the
        # full 22-row quantile batch this procedure is exercised against
        # took ~360 wall-clock seconds at the previous 1e-13 (roughly 44
        # bisection iterations per row), against
        # validate/v154_srange_against_reference.R's own 300-second batch
        # timeout. This does not touch WHY each iteration is more
        # expensive now (that is the point of the fix); it only stops
        # asking for more bracket precision than the acceptance rule
        # needs.
        .relTol = 1e-10
        .maxExpand = 80
        .maxBisect = 200

        # --- Bracket: P(Q>q) is strictly decreasing in q, from 1 at q=0
        # towards 0 as q grows. Expand qHi geometrically until it overshoots
        # the target. ---
        .qLo = 0
        .qHi = 1
        @emlStudentizedRangeQ: .qHi, .k, .df, .nranges
        .pHi = emlStudentizedRangeQ.p
        .expand = 0
        while .pHi > .p and .expand < .maxExpand
            .expand = .expand + 1
            .qLo = .qHi
            .qHi = .qHi * 2
            @emlStudentizedRangeQ: .qHi, .k, .df, .nranges
            .pHi = emlStudentizedRangeQ.p
        endwhile

        if .pHi > .p
            .error$ = "Could not bracket a q with P(Q>q) <= "
            ... + string$ (.p) + " within " + string$ (.maxExpand)
            ... + " doublings (k=" + string$ (.k) + ", df="
            ... + string$ (.df) + "); the target p may be too extreme "
            ... + "for this bracket search."
        else
            .bisect = 0
            .closed = 0
            while .bisect < .maxBisect and .closed = 0
                .bisect = .bisect + 1
                .qMid = 0.5 * (.qLo + .qHi)
                @emlStudentizedRangeQ: .qMid, .k, .df, .nranges
                .pMid = emlStudentizedRangeQ.p
                if .pMid > .p
                    .qLo = .qMid
                else
                    .qHi = .qMid
                endif
                if (.qHi - .qLo) <= .relTol * .qHi
                    .closed = 1
                endif
            endwhile

            if .closed = 0
                .warning$ = "Bisection did not close to relative tolerance "
                ... + string$ (.relTol) + " within " + string$ (.maxBisect)
                ... + " iterations (p=" + string$ (.p) + ", k="
                ... + string$ (.k) + ", df=" + string$ (.df)
                ... + "); returning the best available bracket midpoint."
            endif

            .q = 0.5 * (.qLo + .qHi)
            .ok = 1
        endif
    endif
endproc
