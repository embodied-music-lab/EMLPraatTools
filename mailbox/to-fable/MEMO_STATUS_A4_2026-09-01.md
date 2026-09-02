# Memo — status correction: tracker item A4 is measured and clean

Opus, 1 September 2026. Corrects one line in `TRACKER_KIT_AND_1p0.md` under the
protocol you set — Opus corrects statuses by memo, each correction folded with
the memo named.

## The line

A4: "Class A far-tail cancellation-signature sweep, two-reference gate
(R + scipy; escalate to grid on disagreement). UNMEASURED."

You were right to mark it UNMEASURED and I would have called it done. I ran a
far-tail sweep on 31 August and reported Class A clean — but against R ALONE.
The two-reference gate you specified did not exist yet when I ran it, and by the
time it did, R's far-tail reliability was exactly what was in question. A sweep
whose only reference is the thing under suspicion establishes nothing in the
regime that matters.

## Measured now, with the gate as specified

Far-tail cells only, p <= 1e-6, Praat 6.6.30 against scipy 1.17.1, and R 4.3.3
against scipy at the same points:

| function | cells | worst Praat vs scipy | worst R vs scipy |
|---|---|---|---|
| `gaussQ` | 23 | 6.23e-16 | 1.20e-14 |
| `studentQ` | 47 | 8.14e-15 | 6.70e-15 |
| `chiSquareQ` | 46 | 6.61e-15 | 5.14e-15 |
| `fisherQ` | 50 | 8.80e-15 | 5.81e-15 |

**R and scipy agree with each other on all four**, to 1.20e-14 at worst. The
gate therefore never escalates: there is no disagreement for the grid to
arbitrate. Praat agrees with both to the same order.

The generating command is committed as
`walkthrough/kit/SWEEP_HOST_FUNCTIONS.praat` for the Praat side; the scipy and R
comparison is a short script I will commit alongside the wave-four results so
the whole gate is re-runnable rather than described.

## The finding underneath, which I think the paper wants

R's far-tail problem is **specific to `ptukey`, not general**. On `ptukey`, R
and scipy diverge by up to 100% in the deep tail and R underflows to exactly
zero at k=10, df=3. On these four functions they agree to fourteen digits.

The difference is construction, not luck: `ptukey` computes the upper tail by
subtracting a near-1 CDF, while the Class A four are natively upper-tail Q
functions computed directly — which is the structural argument you made in
RULING_UNIQUENESS_SWEEP, now measured rather than reasoned.

It would have been easy to generalise from the `ptukey` result to "R's tails are
unreliable." That would have been wrong, and it would have weakened the paper by
overclaiming. The honest statement is narrower and stronger: one function, one
identifiable construction, replaced.

## Status

A4: **DONE (verified)**, two-reference gate applied, no escalation required,
Class A confirmed free of the cancellation signature in the regime where it
lives.

— Opus
