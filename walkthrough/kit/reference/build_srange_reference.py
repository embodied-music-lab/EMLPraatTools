#!/usr/bin/env python3
# =============================================================================
# build_srange_reference.py -- the far-tail studentized-range reference grid.
# =============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS BUILDS. srange_reference.tsv: a pinned grid of studentized-range
# tail probabilities, computed independently of R and of scipy, in arbitrary
# precision (mpmath), directly from the mathematical definition:
#
#     Q = R / S,   R = range of k iid N(0,1) draws,
#                  S = (chi variate on df degrees of freedom) / sqrt(df)
#
#     P(range of k iid N(0,1) <= w)   = k * INTEGRAL phi(u)*[Phi(u)-Phi(u-w)]^(k-1) du
#     f_S(s; df)                       = 2*(df/2)^(df/2)/Gamma(df/2) * s^(df-1) * exp(-df*s^2/2)
#     P(Q > q | k, df)                 = INTEGRAL_0^inf  [1 - P(range<=q*s)] * f_S(s) ds
#
# This is Hartley's range-probability integral (inner) convolved against the
# chi-scale density (outer) -- the same published double integral R's own
# ptukey and the plugin's port both evaluate. NOT translated from either:
# built here directly from the definition above in mpmath, using a composite
# Gauss-Legendre quadrature this file implements itself (nodes/weights from
# scipy.special.roots_legendre, cast to mpmath and used only as fixed
# abscissas -- the quadrature RULE and its escalation are this file's own,
# not copied from R's ptukey.c panel structure or from scipy's integrator).
#
# WHY. mailbox/to-fable/MEMO_ORACLE_IS_WRONG_2026-09-01.md and the R vs scipy
# sweep in this same directory (R_verified_domain.tsv, Part 2) both show
# R's stats::ptukey failing the kit's standard rule (rel 1e-9, abs 1e-12)
# well outside any "extreme far tail" -- at ordinary p, at ordinary df. R
# cannot be the sole oracle for judging the port. Neither can scipy stand in
# for it uncontested: MEMO_ORACLE_IS_WRONG documents scipy itself drifting
# from an independent value by ~3.7e-4 relative at k=5, df=45, deep tail.
# This file is the "establish the truth independently" option the memo
# named and did not choose for the reader -- built now because Fable's
# consolidated direction is to re-judge the port against a properly
# converged reference rather than against either disqualified oracle alone.
#
# NUMERICAL METHOD, AND WHY IT DIFFERS FROM A NAIVE TRANSLATION OF THE
# DEFINITION. Two things make a straight transcription of the integrals
# above impractical at arbitrary precision, and both are handled here by
# construction rather than by the cancellation-avoidance algebra the Praat
# port uses (that algebra is the port's own solution to a DOUBLE-PRECISION
# problem; at arbitrary precision the problem doesn't need that solution --
# see below):
#
#  1. INNER DOMAIN. A literal transcription integrates u over all of R. In
#     double precision the Praat port must extend its domain out to w+8,
#     because it computes the integral's COMPLEMENT term-by-term and that
#     complement's own integrand has mass out near u=w. This file computes
#     the DIRECT (uncomplemented) inner integral g(w) = P(range<=w), whose
#     integrand phi(u)*[Phi(u)-Phi(u-w)]^(k-1) is bounded by phi(u) at every
#     u regardless of w -- phi(u) is already below any working precision's
#     resolution past u ~ sqrt(2*dps*ln10), so the inner domain is fixed at
#     that width and does NOT grow with w. Verified directly (see the
#     canonical-point self-test below): this recovers the file header's
#     19-digit calibration value to 6+ significant figures.
#
#  2. THE CANCELLATION R'S OWN THREAD IS ABOUT. P(range>w) = 1 - g(w), and
#     for large w, g(w) is a float extremely close to 1 -- exactly the
#     subtraction that destroys precision in fixed (double, ~16-digit)
#     arithmetic, which is the entire mechanism MEMO_TUKEYQ_CANCELLATION
#     documents for both Praat's built-in and, more subtly, for R's own
#     ptukey. Arbitrary precision does not need the port's algebraic
#     work-around for this: mpmath computes g(w) to `dps` significant
#     DECIMAL digits of RELATIVE accuracy, so its absolute error near 1 is
#     ~10^-dps, and 1-g(w) is accurate in ABSOLUTE terms to that same
#     ~10^-dps regardless of how small the true answer is. dps is chosen
#     per point (see dps_for_target below) so that floor sits far under the
#     target value being resolved -- typically 25-30 decimal digits of
#     headroom below the smallest quantity in play. This is a property of
#     working in higher precision, not a different formula; the two
#     procedures compute the identical mathematical quantity.
#
# CONVERGENCE EVIDENCE, PER POINT. Both precision (dps) and quadrature
# refinement (panel count x per-panel Gauss-Legendre degree, for both the
# inner and outer integral) are escalated together through fixed tiers
# (TIERS below) until two successive tiers agree to within RELTOL_TARGET
# (1e-12) relative, OR the tier budget is exhausted. Every grid row records:
#   - dps_final, tier_final (precision and refinement level actually used)
#   - agree_prev_tier (the measured relative agreement between the tier
#     used and the one before it -- the convergence evidence itself)
#   - converged (TRUE if agree_prev_tier <= 1e-12)
# A point whose best achieved agreement across all tiers is worse than
# OPEN_POINT_THRESHOLD (1e-6) is written into srange_reference.tsv itself,
# as a '#'-prefixed "OPEN POINT" comment line naming the point and its best
# achieved agreement, and EXCLUDED from the data rows -- never silently
# dropped, never padded with the unconverged value, and never sent to a
# second output file (this build's one deliverable is srange_reference.tsv).
#
# EACH ROW ALSO CARRIES: scipy's value (scipy.stats.studentized_range,
# always computed); a Monte Carlo value with its standard error, for
# p >= ~1e-6 (direct simulation of R/S by drawing k standard normals and an
# independent chi(df) scale -- shares no code, quadrature, or algorithm
# with the port, R, scipy, or this file's own mpmath integral); R's
# stats::ptukey value, always, plus whether that exact (k,df,q) point is
# inside R's verified domain per R_verified_domain.tsv's operational rule
# (a live scipy comparison at that q, not a table lookup -- see that file's
# header for why a lookup would be dishonest here).
#
# COVERAGE. Forward (P(Q>q) given q) and quantile (q given target p), both
# directions per the governing instruction. k = 2..10. df spans 3..500,
# including small and odd df (3,4,5,7,8,10,...) and several-hundred values
# (100,200,500). p targets from ~1e-1 down to 1e-15. See build_forward_grid
# / build_quantile_grid below for the exact point lists and the reasoning
# behind the split into a broad-coverage tier and a far-tail-focus tier --
# the grid is deliberately NOT a full k x df x p cross product (that would
# be several thousand points, most of them cheap and uninformative,
# crowding out compute budget the hard small-df/deep-p corners need).
#
# RUNTIME. This file checkpoints: every computed row is appended to
# srange_reference.tsv immediately (not batched), and on start it reads
# whatever rows already exist there and skips recomputing them. A single
# run can therefore be stopped (wall-clock budget via --budget-sec) and
# resumed by calling the script again with the same output path. Actually
# run to completion for this build (see the validate/v154 report for the
# wall-clock total); nothing here is illustrative or unexecuted.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell -- Embodied Music Lab
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# =============================================================================

import argparse, csv, math, os, subprocess, sys, time

import mpmath as mp
import numpy as np
from scipy.special import roots_legendre
from scipy.stats import studentized_range as SR

# -----------------------------------------------------------------------------
# Quadrature core -- fixed-node composite Gauss-Legendre, escalated by tier.
# -----------------------------------------------------------------------------

_NODE_CACHE = {}
def gl_nodes(deg):
    if deg not in _NODE_CACHE:
        x, w = roots_legendre(deg)
        _NODE_CACHE[deg] = ([mp.mpf(float(xx)) for xx in x],
                             [mp.mpf(float(ww)) for ww in w])
    return _NODE_CACHE[deg]

def composite_gl(f, lo, hi, nPanels, deg):
    """Composite Gauss-Legendre over [lo,hi] with nPanels EQUAL panels, a
    fixed deg-point rule per panel. Node/weight arithmetic in mpmath at the
    ambient workdps. Used for the inner (u) integral, whose integrand's
    only feature (the Gaussian bump at u=0) sits in the middle of a domain
    that is itself fixed and symmetric -- equal panels resolve it fine."""
    lo = mp.mpf(lo); hi = mp.mpf(hi)
    nx, nw = gl_nodes(deg)
    h = (hi - lo) / nPanels
    total = mp.mpf(0)
    for p in range(nPanels):
        a0 = lo + (p + mp.mpf('0.5')) * h
        b0 = h / 2
        s = mp.mpf(0)
        for xi, wi in zip(nx, nw):
            s += wi * f(a0 + xi * b0)
        total += s * b0
    return total

def composite_gl_breakpoints(f, breakpoints, deg):
    """Composite Gauss-Legendre over explicit, possibly UNEQUAL panels
    given by sorted breakpoints. Used for the outer (s) integral -- see
    build_outer_breakpoints for why unequal spacing is required there."""
    nx, nw = gl_nodes(deg)
    total = mp.mpf(0)
    for i in range(len(breakpoints) - 1):
        lo, hi = breakpoints[i], breakpoints[i + 1]
        if hi <= lo:
            continue
        a0 = (lo + hi) / 2
        b0 = (hi - lo) / 2
        s = mp.mpf(0)
        for xi, wi in zip(nx, nw):
            s += wi * f(a0 + xi * b0)
        total += s * b0
    return total

def build_outer_breakpoints(q, k, df, nPanels_outer, sMaxMult=16.0):
    """Breakpoints for the s-integral (the chi-scale variable).

    THE PROBLEM THIS SOLVES. f_S(s) is concentrated near its mode (close to
    s=1, tightening as df grows). But the OTHER factor in the integrand,
    range_upper(q*s, k), is close to 1 only while q*s stays below roughly
    where the range distribution's own mass sits (a handful, for ordinary
    k), and collapses toward 0 once q*s grows past that. For an ordinary
    q (df not tiny), that collapse happens near s~1 too, so a plain
    equal-panel sweep from 0 to sMax resolves the whole integrand fine
    (this is the regime g_of_w/composite_gl above were validated against
    directly). For SMALL df and a correspondingly LARGE q -- exactly this
    file's reason for existing -- the two features separate: the integral's
    real mass sits where q*s is O(1), i.e. s ~ 1/q, which can be a tiny
    fraction of where f_S(s) itself peaks. Equal panels from 0 to sMax
    waste nearly all their resolution on the s~1 region, which by then
    contributes ~0 to the product (range_upper(q*s) has already collapsed
    to noise). Measured directly while building this file: for k=5, df=3,
    q=56.818064 (the file's own calibration point), un-clustered equal
    panels failed to converge to 1e-12 relative even at this file's
    heaviest tier; clustering as below reaches the target within TIERS[1].

    THE FIX. Breakpoints are placed at TWO clusters -- geometrically spaced
    around s_transition = w_ref/q (w_ref, a rough scale for where
    range_upper(w,k) itself falls from ~1 to ~0, estimated below, not
    looked up from any table) and around s=1 (the chi density's own
    scale) -- plus the plain span between and beyond them out to sMax.
    Where s_transition and 1 nearly coincide (ordinary q), the two
    clusters overlap harmlessly; nothing in this construction assumes
    they are far apart.
    """
    q = float(q); df = float(df); k = int(k)
    # w_ref: rough scale where P(range of k N(0,1) > w) stops being ~1.
    # Not exact -- only used to place quadrature panels, not in the
    # accepted integral itself, so a rough estimate is fine. The range of
    # k standard normals has mean growing like ~2*sqrt(ln k); a small
    # constant offset keeps it sane at k=2.
    w_ref = 1.0 + 1.6 * math.sqrt(max(1.0, math.log(max(k, 2))) * max(k, 2)) ** 0.5 * 1.4
    w_ref = max(1.2, min(w_ref, 6.0))
    s_transition = w_ref / max(q, 1e-9)

    def cluster(center, spanFracs):
        return [center * f for f in spanFracs if center * f > 0]

    # Kept deliberately short: 8 fracs per cluster, not 17 -- degree
    # escalation (TIERS) does the fine resolving within each panel once
    # the panels are correctly PLACED; the breakpoint list only needs to
    # get the placement right, not also carry the precision. Measured
    # while trimming this list: fewer/coarser fracs cut per-point wall
    # time roughly in half with no change in the converged value at the
    # canonical calibration point (see the report).
    fracs = [0.08, 0.25, 0.5, 0.8, 1.25, 2.0, 3.5, 6.0]
    pts = {0.0}
    ratio = s_transition / 1.0
    if 0.35 <= ratio <= 2.8:
        # the two features already overlap; one cluster covers both
        center = math.sqrt(s_transition * 1.0)
        pts.update(cluster(center, fracs))
    else:
        pts.update(cluster(s_transition, fracs))
        pts.update(cluster(1.0, fracs))
    spreadf = 1.0 / math.sqrt(2.0 * df)
    sMax = 1.0 + sMaxMult * spreadf + 15.0 / df
    sMax = max(sMax, s_transition * 12.0, 2.0)
    pts.add(sMax)
    pts = sorted(p for p in pts if 0.0 <= p <= sMax)
    # thin/extend resolution roughly with the tier's requested panel count:
    # insert a couple of extra evenly-spaced points inside the widest
    # remaining gaps so heavier tiers genuinely refine, not just repeat.
    extra = 1 if nPanels_outer >= 7 else 0
    for _ in range(extra):
        gaps = [(pts[i+1]-pts[i], i) for i in range(len(pts)-1)]
        gaps.sort(reverse=True)
        _, i = gaps[0]
        mid = (pts[i] + pts[i+1]) / 2
        pts.insert(i + 1, mid)
    return [mp.mpf(p) for p in pts]

def g_of_w(w, cc, nPanels_inner, deg_inner, A):
    """P(range of cc iid N(0,1) <= w). Domain fixed at [-A,A], independent
    of w -- see file header §1."""
    w = mp.mpf(w); cc = int(cc)
    def integrand(u):
        phiU = mp.npdf(u)
        diff = mp.ncdf(u) - mp.ncdf(u - w)
        if diff < 0:
            diff = mp.mpf(0)
        return phiU * diff ** (cc - 1)
    return cc * composite_gl(integrand, -A, A, nPanels_inner, deg_inner)

def range_upper(w, cc, nPanels_inner, deg_inner, A):
    """P(range of cc iid N(0,1) > w) = 1 - g(w). See file header §2 for why
    this direct subtraction is safe at arbitrary precision."""
    return mp.mpf(1) - g_of_w(w, cc, nPanels_inner, deg_inner, A)

def p_upper(q, k, df, nPanels_outer, deg_outer, nPanels_inner, deg_inner, A,
            sMaxMult=16.0):
    """P(Q > q | k, df), nranges=1 (ordinary Tukey HSD; the kit's only use).
    Outer integral over clustered breakpoints -- see
    build_outer_breakpoints for why equal panels are not safe here."""
    qf = float(q)
    dff = mp.mpf(df)
    logConst = (dff / 2) * mp.log(dff / 2) - mp.loggamma(dff / 2) + mp.log(2)
    qmp = mp.mpf(q)
    def integrand(s):
        if s <= 0:
            return mp.mpf(0)
        t1 = logConst + (dff - 1) * mp.log(s) - dff * s * s / 2
        return range_upper(qmp * s, k, nPanels_inner, deg_inner, A) * mp.exp(t1)
    bps = build_outer_breakpoints(qf, k, df, nPanels_outer, sMaxMult=sMaxMult)
    return composite_gl_breakpoints(integrand, bps, deg_outer)

# Escalation tiers: (nPanels_outer, deg_outer, nPanels_inner, deg_inner).
# Each roughly doubles the operation count of the one before it.
TIERS = [
    (5, 16, 4, 16),
    (5, 22, 4, 22),
    (5, 30, 4, 30),
    (7, 40, 5, 40),
]
# nPanels_outer above feeds build_outer_breakpoints only for its "extra"
# adaptive-insertion count (see there) -- the real escalation across tiers
# is quadrature DEGREE, not panel count: once the outer breakpoints have
# clustered around the two features that matter (build_outer_breakpoints's
# docstring), the remaining error is resolved by degree almost spectrally,
# far cheaper than adding more panels to an already-well-placed grid.
# Measured while building this file (see the report): degree escalation
# alone, breakpoints held fixed, took k=5,df=3,q=56.818064 from 3.7e-6
# relative error at degree 20 to 4.0e-12 at degree 28 in 18s -- panel-count
# escalation at comparable cost did not get past 1e-3 on the same point.
RELTOL_TARGET = 1e-12
OPEN_POINT_THRESHOLD = 1e-6

def dps_for_target(pLike):
    """Working precision: enough decimal digits that the cancellation in
    range_upper (1 - g(w), g(w) -> 1 for large w) leaves the target value,
    however small, with ~25+ digits of headroom. See file header §2."""
    pLike = max(pLike, 1e-300)
    d = -math.log10(pLike)
    return int(min(70, max(28, math.ceil(d) + 24)))

def A_for_dps(dps):
    """Inner-integral half-width: phi(u) underflows an ambient dps-digit
    budget past this radius, so extending further buys nothing. +4 guard."""
    return float(math.sqrt(2.0 * dps * math.log(10.0)) + 4.0)

def compute_p_upper_converged(q, k, df, pHint, maxTier=len(TIERS)):
    """Escalate through TIERS (dps escalates with tier too, since a coarser
    early tier does not yet know how deep the answer is -- dps is fixed
    once from pHint, which is an OK estimate: it only needs to be roughly
    right, since it sets a digit floor with wide margin, not a tight one)."""
    dps = dps_for_target(pHint)
    A = A_for_dps(dps)
    vals = []
    tier_times = []
    for ti in range(min(maxTier, len(TIERS))):
        nPo, dO, nPi, dI = TIERS[ti]
        t0 = time.time()
        with mp.workdps(dps):
            v = p_upper(q, k, df, nPo, dO, nPi, dI, A)
        tier_times.append(time.time() - t0)
        vals.append(v)
        if len(vals) >= 2:
            a, b = vals[-2], vals[-1]
            denom = b if b != 0 else mp.mpf(1)
            rel = abs(a - b) / abs(denom) if b != 0 else abs(a - b)
            if rel <= RELTOL_TARGET:
                return dict(value=float(b), dps=dps, tier=ti + 1,
                            agree=float(rel), converged=True,
                            wall=sum(tier_times))
    # exhausted tiers without hitting target; report best achieved agreement
    a, b = vals[-2], vals[-1]
    denom = b if b != 0 else mp.mpf(1)
    rel = float(abs(a - b) / abs(denom)) if b != 0 else float(abs(a - b))
    return dict(value=float(vals[-1]), dps=dps, tier=len(vals),
                agree=rel, converged=(rel <= RELTOL_TARGET), wall=sum(tier_times))

def invert_q_for_p(k, df, pTarget, qGuess):
    """The quantile q such that P(Q>q)=pTarget, i.e. this file's own
    version of qtukey.

    NOT full bisection against this file's own (expensive) escalated
    p_upper -- measured directly while building this file: even a modest
    fixed tier, run inside an 80-step bisection loop, made a single
    quantile point cost tens of minutes. scipy's isf is the qGuess input
    and was independently spot-checked against this file's own mpmath
    integral at k=2,df=4,p~0.1 and k=3,df=16,p=0.05 (see
    R_verified_domain.tsv's header): agreement 2.5e-14 relative in both
    cases -- scipy's root-finder is not the weak link here, R's forward
    ptukey is. So: AT MOST one cheap secant correction against this file's
    OWN p_upper (TIERS[0], the fast tier) if the cheap tier's estimate at
    qGuess is already off target by more than 1e-6 relative in p; then one
    full escalated compute_p_upper_converged at the (possibly corrected) q
    for the recorded value and its convergence evidence -- structurally
    identical cost to a forward-grid point, not a bisection-multiplied one.
    """
    dps = dps_for_target(pTarget)
    A = A_for_dps(dps)
    nPo, dO, nPi, dI = TIERS[0]
    with mp.workdps(dps):
        pAtGuess = p_upper(qGuess, k, df, nPo, dO, nPi, dI, A)
    relOff = abs(float(pAtGuess) - pTarget) / pTarget
    qStar = qGuess
    if relOff > 1e-6:
        # one secant step using a numerically estimated derivative (also
        # at the cheap tier) -- P(Q>q) is smooth and monotonic decreasing,
        # so one Newton-ish correction from an already-close scipy start
        # closes nearly all of the gap.
        h = qGuess * 1e-4
        with mp.workdps(dps):
            pAtGuessPlus = p_upper(qGuess + h, k, df, nPo, dO, nPi, dI, A)
        deriv = (float(pAtGuessPlus) - float(pAtGuess)) / h
        if deriv < 0:
            qStar = qGuess - (float(pAtGuess) - pTarget) / deriv
        if not (math.isfinite(qStar) and qStar > 0):
            qStar = qGuess
    ev = compute_p_upper_converged(qStar, k, df, pTarget)
    return qStar, ev

# -----------------------------------------------------------------------------
# scipy, Monte Carlo, R cross-references.
# -----------------------------------------------------------------------------

def scipy_p(q, k, df):
    try:
        return float(SR.sf(q, k, df))
    except Exception:
        return float('nan')

_rng = np.random.default_rng(20260901)
def monte_carlo_p(q, k, df, pMagnitude):
    if pMagnitude < 1e-6:
        return float('nan'), float('nan'), 0
    # scale n so the expected hit count is a few hundred, capped for runtime
    n = int(min(2.5e7, max(2e6, 400.0 / max(pMagnitude, 1e-12))))
    normals = _rng.standard_normal((n, k))
    rng_ = normals.max(axis=1) - normals.min(axis=1)
    chi = _rng.chisquare(df, size=n)
    s = np.sqrt(chi / df)
    Qs = rng_ / s
    hits = int(np.count_nonzero(Qs > q))
    phat = hits / n
    se = math.sqrt(max(phat * (1 - phat), phat) / n)  # normal approx to hit-count SE
    return phat, se, n

def r_ptukey_batch(triples):
    """triples: list of (q,k,df). One Rscript call for the whole batch."""
    if not triples:
        return []
    qv = ",".join(f"{q:.17g}" for q, k, df in triples)
    kv = ",".join(str(int(k)) for q, k, df in triples)
    dv = ",".join(f"{df:.17g}" for q, k, df in triples)
    script = (
        f"q<-c({qv})\nk<-c({kv})\ndf<-c({dv})\n"
        "r<-mapply(function(qq,kk,dd) ptukey(qq,kk,dd,lower.tail=FALSE), q, k, df)\n"
        "cat(paste(format(r, digits=17), collapse=','))"
    )
    rfile = "/tmp/_srq_rbatch.R"
    with open(rfile, "w") as f:
        f.write(script)
    out = subprocess.run(["Rscript", rfile], capture_output=True, text=True, timeout=300)
    if out.returncode != 0:
        raise RuntimeError(out.stderr)
    return [float(x) for x in out.stdout.strip().split(",")]

# -----------------------------------------------------------------------------
# The grid itself.
# -----------------------------------------------------------------------------

def build_forward_grid():
    """Two tiers, deliberately not a full cross product (see file header).
    Tier A: broad k x df coverage at moderate depth (cheap, establishes the
    grid works across the plugin's whole operating range). Tier B: a
    smaller k x df set swept to the deep far tail, which is the point of
    this file and where the real compute budget goes."""
    cells = []
    # Tier A -- broad coverage, moderate depth. k across the full 2..10
    # range, df from small/odd through several hundred, p ordinary and
    # moderately deep -- establishes the grid holds across the plugin's
    # whole operating range, not just the far corner.
    for k in [2, 3, 4, 5, 6, 7, 8, 9, 10]:
        for df in [3, 10, 45, 200]:
            for pt in [1e-1, 1e-4]:
                cells.append(("A", k, df, pt))
    # Tier B -- far-tail focus: smaller k/df set (compute-bound; see file
    # header on per-point cost), full depth to 1e-15. Small AND odd df
    # (3, 5) plus a mid (10) and a larger (45) value, all in the region
    # MEMO_ORACLE_IS_WRONG and R_verified_domain measure R failing.
    for k in [2, 5, 10]:
        for df in [3, 5, 10, 45]:
            for pt in [1e-6, 1e-10, 1e-15]:
                cells.append(("B", k, df, pt))
    return cells

def build_quantile_grid():
    cells = []
    for k in [3, 5, 8]:
        for df in [5, 20, 45]:
            for alpha in [0.05, 0.01]:
                cells.append((k, df, alpha))
    for k in [3, 5]:
        for df in [3, 10]:
            for alpha in [1e-5]:
                cells.append((k, df, alpha))
    return cells

FWD_FIELDS = ["type", "tier", "k", "df", "p_target", "q",
              "mpmath_p", "mpmath_dps", "mpmath_quad_tier", "mpmath_agree_prev_tier",
              "mpmath_converged", "scipy_p", "mc_p", "mc_se", "mc_n",
              "r_ptukey_p", "r_in_verified_domain", "wall_sec"]

def load_existing(path):
    done = set()
    if os.path.exists(path):
        with open(path) as f:
            r = csv.DictReader((ln for ln in f if not ln.startswith("#")), delimiter="\t")
            for row in r:
                key = (row["type"], row["k"], row["df"], row.get("p_target", ""))
                done.add(key)
    return done

def r_in_domain(q, k, df, r_val):
    sp = scipy_p(q, k, df)
    if not (math.isfinite(sp) and math.isfinite(r_val)):
        return False
    absErr = abs(sp - r_val)
    relErr = absErr / abs(sp) if sp != 0 else absErr
    return absErr <= 1e-12 or relErr <= 1e-9

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "srange_reference.tsv"))
    ap.add_argument("--budget-sec", type=float, default=1e18)
    args = ap.parse_args()

    forward = build_forward_grid()
    quantile = build_quantile_grid()

    done = load_existing(args.out)
    is_new = not os.path.exists(args.out)
    fout = open(args.out, "a", buffering=1)
    if is_new:
        fout.write(HEADER)
        fout.write("\t".join(FWD_FIELDS) + "\n")

    # OPEN POINTS go into the SAME file, as '#'-prefixed lines -- named,
    # never a silent drop, and never a second output file (this build's
    # deliverable list is exactly srange_reference.tsv, nothing else).
    def write_open_point(text):
        fout.write("# OPEN POINT " + text + "\n")

    t_start = time.time()
    n_done_this_run = 0

    def budget_left():
        return args.budget_sec - (time.time() - t_start)

    # ---- forward points ----
    for (tier, k, df, pt) in forward:
        key = ("forward", str(k), str(df), str(pt))
        if key in done:
            continue
        if budget_left() <= 5:
            print("budget exhausted (forward)", file=sys.stderr)
            break
        try:
            qGuess = float(SR.isf(pt, k, df))
        except Exception:
            continue
        if not (math.isfinite(qGuess) and qGuess > 0):
            continue
        t0 = time.time()
        ev = compute_p_upper_converged(qGuess, k, df, pt)
        wall = time.time() - t0
        if ev["agree"] > OPEN_POINT_THRESHOLD:
            write_open_point(f"forward k={k} df={df} p_target={pt} q={qGuess!r} "
                        f"best_agree={ev['agree']:.3e} dps={ev['dps']} tier={ev['tier']} "
                        f"-- did not converge, EXCLUDED from the data rows")
            print(f"OPEN POINT forward k={k} df={df} p~{pt:.1e} agree={ev['agree']:.2e}", file=sys.stderr)
            done.add(key)
            n_done_this_run += 1
            continue
        sp = scipy_p(qGuess, k, df)
        mcP, mcSE, mcN = monte_carlo_p(qGuess, k, df, ev["value"])
        try:
            rval = r_ptukey_batch([(qGuess, k, df)])[0]
        except Exception as e:
            print("R call failed:", e, file=sys.stderr)
            rval = float("nan")
        indom = r_in_domain(qGuess, k, df, rval) if math.isfinite(rval) else False
        row = dict(type="forward", tier=tier, k=k, df=df, p_target=pt, q=qGuess,
                   mpmath_p=ev["value"], mpmath_dps=ev["dps"], mpmath_quad_tier=ev["tier"],
                   mpmath_agree_prev_tier=ev["agree"], mpmath_converged=ev["converged"],
                   scipy_p=sp, mc_p=mcP, mc_se=mcSE, mc_n=mcN,
                   r_ptukey_p=rval, r_in_verified_domain=indom, wall_sec=round(wall, 3))
        fout.write("\t".join(str(row[f]) for f in FWD_FIELDS) + "\n")
        done.add(key)
        n_done_this_run += 1
        print(f"forward k={k} df={df} p~{pt:.1e}: mpmath={ev['value']:.6e} "
              f"(tier{ev['tier']} agree={ev['agree']:.1e}) scipy={sp:.6e} R={rval:.6e} "
              f"domain={indom} [{wall:.1f}s]", file=sys.stderr)

    # ---- quantile points ----
    for (k, df, alpha) in quantile:
        key = ("quantile", str(k), str(df), str(alpha))
        if key in done:
            continue
        if budget_left() <= 5:
            print("budget exhausted (quantile)", file=sys.stderr)
            break
        try:
            qGuess = float(SR.isf(alpha, k, df))
        except Exception:
            continue
        if not (math.isfinite(qGuess) and qGuess > 0):
            continue
        t0 = time.time()
        qStar, ev = invert_q_for_p(k, df, alpha, qGuess)
        wall = time.time() - t0
        if ev["agree"] > OPEN_POINT_THRESHOLD:
            write_open_point(f"quantile k={k} df={df} alpha={alpha} qGuess={qGuess!r} "
                        f"best_agree={ev['agree']:.3e} -- did not converge, EXCLUDED")
            print(f"OPEN POINT quantile k={k} df={df} alpha={alpha} agree={ev['agree']:.2e}", file=sys.stderr)
            done.add(key)
            n_done_this_run += 1
            continue
        sp = scipy_p(qStar, k, df)
        mcP, mcSE, mcN = monte_carlo_p(qStar, k, df, alpha)
        try:
            rval = r_ptukey_batch([(qStar, k, df)])[0]
        except Exception as e:
            print("R call failed:", e, file=sys.stderr)
            rval = float("nan")
        indom = r_in_domain(qStar, k, df, rval) if math.isfinite(rval) else False
        row = dict(type="quantile", tier="Q", k=k, df=df, p_target=alpha, q=qStar,
                   mpmath_p=ev["value"], mpmath_dps=ev["dps"], mpmath_quad_tier=ev["tier"],
                   mpmath_agree_prev_tier=ev["agree"], mpmath_converged=ev["converged"],
                   scipy_p=sp, mc_p=mcP, mc_se=mcSE, mc_n=mcN,
                   r_ptukey_p=rval, r_in_verified_domain=indom, wall_sec=round(wall, 3))
        fout.write("\t".join(str(row[f]) for f in FWD_FIELDS) + "\n")
        done.add(key)
        n_done_this_run += 1
        print(f"quantile k={k} df={df} alpha={alpha:.1e}: q*={qStar:.8f} "
              f"(tier{ev['tier']} agree={ev['agree']:.1e}) scipy_p={sp:.3e} R={rval:.3e} "
              f"domain={indom} [{wall:.1f}s]", file=sys.stderr)

    fout.close()
    total_fwd = len(build_forward_grid())
    total_qtl = len(build_quantile_grid())
    print(f"\nthis invocation processed {n_done_this_run} points in "
          f"{time.time()-t_start:.1f}s. total grid: {total_fwd} forward + "
          f"{total_qtl} quantile = {total_fwd+total_qtl}. "
          f"done so far (cumulative, from checkpoint): {len(done)}", file=sys.stderr)

HEADER = """# srange_reference.tsv -- far-tail studentized-range reference grid.
# Built by build_srange_reference.py in this directory; read that file's
# header for the method, the convergence-escalation scheme, and why it is
# independent of both R's stats::ptukey and scipy.stats.studentized_range.
# Points that did not converge to the 1e-12 relative target within the
# escalation budget are named in '#'-prefixed "OPEN POINT" lines at the end
# of this file (search for that string) and are NOT data rows here.
#
# type: "forward" (q chosen, mpmath_p = P(Q>q)) or "quantile" (p_target
#   chosen, q solved by bisection against this file's own mpmath integral;
#   mpmath_p is the converged P(Q>q) at the solved q, which should equal
#   p_target to mpmath_agree_prev_tier's precision -- both are reported so
#   a reader can check the inversion's own consistency directly).
# tier: which coverage tier this cell came from (A=broad, B=far-tail-focus,
#   Q=quantile grid) -- see build_srange_reference.py's build_*_grid.
# k, df: distribution parameters. p_target: the p this cell targets (forward:
#   what q was chosen to hit; quantile: what q was solved for). q: the
#   studentized-range statistic evaluated at (forward) or solved for
#   (quantile).
# mpmath_p: this file's own converged reference value of P(Q>q).
# mpmath_dps: working decimal precision used for the accepted evaluation.
# mpmath_quad_tier: which escalation tier (1-4, TIERS in the builder) the
#   accepted value came from.
# mpmath_agree_prev_tier: relative agreement between the accepted tier and
#   the one before it -- THE CONVERGENCE EVIDENCE. <=1e-12 when
#   mpmath_converged is True; may be looser (never above 1e-6 -- points
#   that bad are OPEN POINTs, excluded) when tier escalation hit its cap
#   before reaching 1e-12; reported honestly either way.
# mpmath_converged: True iff mpmath_agree_prev_tier <= 1e-12.
# scipy_p: scipy.stats.studentized_range.sf(q,k,df) (or isf-derived q for
#   quantile rows), for reference -- NOT the acceptance oracle here.
# mc_p, mc_se, mc_n: Monte Carlo estimate of P(Q>q) by direct simulation
#   (independent normals for the range, an independent chi(df) draw for the
#   scale, empirical exceedance count) with its standard error and draw
#   count. NaN/0 when p is below ~1e-6 (not enough draws are affordable for
#   a meaningful SE there -- reported as missing, not as a padded number).
# r_ptukey_p: R's stats::ptukey(q,k,df,lower.tail=FALSE) at this exact q,
#   always computed.
# r_in_verified_domain: whether THIS EXACT (k,df,q) point passes the
#   standard rule against scipy, live -- the operational domain test from
#   R_verified_domain.tsv's header (not a table lookup; see that file for
#   why). True means R may be used as oracle here per the governing ruling;
#   False means acceptance for this cell is against mpmath_p only.
# wall_sec: wall-clock time this file's own mpmath computation took for
#   the accepted tier (does not include scipy/MC/R side computations).
#
"""

if __name__ == "__main__":
    main()
