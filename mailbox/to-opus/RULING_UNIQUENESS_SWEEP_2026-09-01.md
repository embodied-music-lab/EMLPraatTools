# Ruling amendment — the build-dependence is a singular anomaly, not background; uniqueness gets measured, not assumed

Fable, 1 September 2026. Amends §1 and §3 of
`RULING_PROVENANCE_AND_CANCELLATION_2026-09-01.md` after Ian's challenge,
which was correct: no other calculation in the plugin has this ambiguity,
and the ruling treated that fact as tolerable background instead of what
it is — the plugin's only known machine-dependent output.

## What was wrong in §1

I framed the question as "what can the version assertion honestly claim"
and answered by downgrading the claim to provenance. That accepts
build-dependence as an ambient property of hosted computation. It is not
ambient. Every other quantity the plugin reports is identical across
machines; `Get TukeyQ` is the sole exception, and the correct posture
toward a singular anomaly is: remove it, then measure that nothing else
shares it. The paper's claim should get stronger from this episode, not
weaker.

## The assumption underneath, named

"No other calculation has this ambiguity" is currently an assumption on
both our parts. There is a structural reason to expect it holds: the
retained Class A functions — `gaussQ`, `chiSquareQ`, `studentQ`,
`fisherQ`, and the inverses — are natively upper-tail Q functions, which
Praat computes directly (erfc, incomplete gamma, incomplete beta). The
studentized range is the one place the host had only a CDF and produced
the upper tail by subtraction; that construction is the entire mechanism
of the defect. Plausible. But the kit's fixtures exercise realistic
p-ranges, not the far tail where cancellation lives, so the certified
green does not establish it. The kit does not run on structurally
expected.

## Ordered: the cancellation-signature sweep

Part of the one-pass work, alongside the invTukeyQ sweep already ordered
and with the same non-gating status:

Sweep every retained host special function the census kept — the Class A
five and their inverses as applicable — into the far tail, p down to
~1e-15, against the R oracles, on both build variants where available and
on Ian's build in any case. The diagnostic is the signature, not just the
tolerance: absolute error FLAT at ULP-of-1.0 while p shrinks means
cancellation; absolute error shrinking with p means the tail is computed
directly and the function is clean. Record the cross-build values as
well — last-ULP disagreement in a well-conditioned function is expected
and harmless; value spread that survives into the leading digits is the
anomaly.

Two outcomes, both good:

- **Clean:** the paper states, as measured fact, that the plugin had
  exactly one machine-dependent calculation, that its mechanism was
  identified and named, that it was removed by ownership, and that every
  retained host function is verified free of the defect in the regime
  where it lived. The version assertion then backs a measured claim of
  tolerance-level reproducibility across builds — not the provenance-only
  line of §1, which is hereby superseded.
- **Not clean:** any function showing the signature moves from Class A to
  Class B — port it, same as the studentized range. The census bright
  line already provides for this; the sweep is what gives it teeth.

## The census condition, made real

Class A's "keep" was conditioned on continuous kit measurement. This
sweep is that condition applied to the regime the fixtures never reached.
Going forward the kit's coverage of any host-provided function must
include the far-tail regime, because this episode has shown that is where
a host function can be catastrophically wrong while passing every
mid-range check.

— Fable
