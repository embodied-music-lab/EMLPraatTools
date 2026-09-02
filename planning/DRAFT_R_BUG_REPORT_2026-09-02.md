Summary: ptukey() upper-tail probabilities are badly inaccurate (and can
underflow to exactly 0) in the far tail, due to catastrophic cancellation
in the 1-CDF construction; qtukey() inversion of R's own ptukey() is also
imprecise at ordinary alpha (secondary)

Component: Distributions (stats)
Affected versions: R 4.3.3 (not yet checked on r-devel)

Provenance: Found while validating a phonetics statistics package's
studentized-range calculations against R.

## Summary

stats::ptukey(q, nmeans, df, lower.tail = FALSE) returns far-tail upper
probabilities that diverge substantially from the true studentized-range
distribution, including at least one ordinary post-hoc-comparison
magnitude. The error grows with tail depth and can reach an exact
underflow to 0.0. The defect appears specific to ptukey's internal
"1 - CDF" construction for the upper tail: R's other upper-tail
functions (pnorm, pt, pchisq, pf with upper.tail = TRUE) do not show
this problem in the same regime.

## Minimal reproducible example (self-contained, no external packages)

```r
# Case 1: k=5, df=3, q=56.8224 -- an ORDINARY post-hoc magnitude
ptukey(56.8224, 5, 3, lower.tail = FALSE)
# R returns a value ~13.6x LOWER than the true upper-tail probability
# (true p ~ 1.4e-4, established independently below)

# Case 2: k=10, df=3, deep tail -- underflows to exactly 0
# For q large enough that the true upper-tail probability is ~1e-10
# (observed at our reference grid's k=10, df=3 cells; exact q values
# ship with the grid), ptukey(q, 10, 3, lower.tail = FALSE) returns
# exactly 0.0, which cannot be correct for a continuous distribution.
# [INSERT exact q from the committed grid before filing]
```

Independent cross-check against scipy (Python, scipy 1.17.1):

```python
from scipy.stats import studentized_range
studentized_range.sf(56.8224, 5, 3)
# agrees with the arbitrary-precision reference (~1.4e-4); R's ptukey
# returns ~13.6x less. [INSERT exact R/scipy/reference values from the
# committed grid before filing]
```

Independent cross-check by Monte Carlo, from the definition (range of k
iid N(0,1) draws divided by an independent sqrt(chi2_df/df) draw),
sketch:

```r
# Chunked so it runs in bounded memory (the naive one-matrix version
# would allocate ~5 GB). ~120e6 draws total.
set.seed(1)
k <- 5; df <- 3; qcrit <- 56.8224
hits <- 0; total <- 0
for (chunk in 1:120) {
  n <- 1e6
  z <- matrix(rnorm(n * k), n, k)
  rng <- matrixStats::rowMaxs(z) - matrixStats::rowMins(z)  # or apply()
  q_stat <- rng / sqrt(rchisq(n, df) / df)
  hits <- hits + sum(q_stat > qcrit); total <- total + n
}
hits / total
# estimate sits ~118 SE from R's ptukey() value, ~0.2 SE from scipy's
```

## Observed vs expected

- Observed: ptukey(56.8224, 5, 3, lower.tail=FALSE) is ~13.6x LOW versus
  the true upper-tail probability (true p ~ 1.4e-4).
- Observed: ptukey(., 10, 3, lower.tail=FALSE) underflows to exactly 0.0
  in the deep tail, which is impossible for a continuous distribution.
- Observed (deep tail, measured against an arbitrary-precision reference
  grid): R and scipy diverge from that reference by up to ~100% relative
  error, worst case relative error 108.5 at k=2, df=45, true p = 2.269e-15
  (R returns 2.485e-13).
- Expected: agreement with the true studentized-range CDF to numerical
  precision, as R already achieves for pnorm/pt/pchisq/pf in the same
  far-tail regime (worst observed disagreement there: 1.2e-14, over 166
  far-tail cells checked).
- Independent checks agree with each other and disagree with R: a
  120-million-draw Monte Carlo estimate sits 118 standard errors from
  R's ptukey() value at the k=5, df=3, q=56.8224 case, and only 0.2 SE
  from scipy's value for the same case.

## Mechanism

ptukey computes the upper tail via a "1 - CDF" construction rather than
a direct upper-tail integral. When the true upper-tail probability is
small, this subtracts two near-1 quantities, producing catastrophic
cancellation and loss of relative precision -- eventually underflowing
to exactly 0 once the cancellation exhausts double precision. This
appears specific to ptukey: R's four natively upper-tail-aware functions
(pnorm, pt, pchisq, pf with upper.tail=TRUE) do NOT show this problem in
the same far-tail regime, agreeing with scipy to ~1e-14 (worst case
1.2e-14 across 166 far-tail cells checked).

## Scope / severity

Ordinary-alpha use is NOT affected: across 120 ordinary-alpha cells
checked, R's ptukey() is bit-identical to scipy. The defect is confined
to the far tail (small upper-tail probabilities), which nonetheless
includes at least one magnitude (p ~ 1.4e-4) that is an ordinary
post-hoc comparison result, not an exotic edge case. The most severe
symptom -- an exact 0.0 return at k=10, df=3 in the deep tail -- should
probably be treated as a correctness bug independent of accuracy grade,
since it silently reports "impossible" rather than "very small."

## Secondary issue: qtukey does not tightly invert ptukey

qtukey() does not invert R's own ptukey() to better than ~4e-8 relative
error even at ordinary alpha. Example: k=3, df=20, alpha=.05 -- qtukey's
answer sits 4.0e-8 relative from the true quantile, whereas an
arbitrary-precision inversion of the true distribution sits 1.1e-15 from
truth. This is far less severe than Finding 1 (ordinary-alpha use is
usable in practice) but is reported here as a related, lower-priority
item since both functions share the same underlying algorithm family.

## Reference methodology

Ground truth was established via arbitrary-precision numerical
integration (mpmath, 30+ decimal digits precision, refined until
successive values agree to 1e-12) across a 130-point grid of (q, k, df)
combinations, with per-point convergence evidence at that tolerance.

We are happy to share the full reference grid, the mpmath generation
scripts, and the Monte Carlo verification script on request.
