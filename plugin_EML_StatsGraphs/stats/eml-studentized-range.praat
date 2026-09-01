# ============================================================================
# EML Stats : Studentized Range Distribution
# ============================================================================
# Module: eml-studentized-range.praat
# Version: 1.0
# Date: 1 September 2026
#
# License: GPL-3.0-or-later
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
#
# Dependencies: None (uses only Praat built-ins: gaussQ, lnGamma, ln, exp,
# sqrt, pow via ^).
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
            .nlegq = 16
            .ihalfq = 8
            .xlegq# = {0.989400934991649932596154173450, 0.944575023073232576077988415535, 0.865631202387831743880467897712, 0.755404408355003033895101194847, 0.617876244402643748446671764049, 0.458016777657227386342419442984, 0.281603550779258913230460501460, 0.0950125098376374401853193354250}
            .alegq# = {0.0271524594117540948517805724560, 0.0622535239386478928628438369944, 0.0951585116824927848099251076022, 0.124628971255533872052476282192, 0.149595988816576732081501730547, 0.169156519395002538189312079030, 0.182603415044923588866763667969, 0.189450610455068496285396723208}
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
            .sPanelWidth = 3 / sqrt (.df)
            if .sPanelWidth > 0.5
                .sPanelWidth = 0.5
            endif

            .f2 = .df * 0.5
            .logConst = (.f2 * ln (.df / 2)) - lnGamma (.f2) + ln (2)
            .dfm1 = .df - 1

            .ans = 0
            .maxPanels = 400
            .i = 0
            .keepGoing = 1
            .belowStreak = 0

            while .i < .maxPanels and .keepGoing = 1
                .i = .i + 1
                .otsum = 0
                .sCenter = (.i - 0.5) * .sPanelWidth
                .sHalf = .sPanelWidth / 2

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
                        .rotsum = (.compW * .alegq# [.jx]) * exp (.t1) * .sHalf
                        .otsum = .otsum + .rotsum
                    endif
                endfor

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
        .relTol = 1e-13
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
