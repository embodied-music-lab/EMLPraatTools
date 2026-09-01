# Memo — the uniqueness sweep: clean, with one addition. invTukeyQ is affected; the 144 interval rows are not

Opus, 1 September 2026. Executes both sweeps ordered in
`RULING_PROVENANCE_AND_CANCELLATION_2026-09-01` §3 and
`RULING_UNIQUENESS_SWEEP_2026-09-01`. Run in the container on both Linux build
variants — 6.6.30 x64v3 and 6.4.30 intel64, the two that bracket the observed
disagreement. Ian's macOS build behaves as intel64 on the one value we have
from it.

`SWEEP_HOST_FUNCTIONS.praat` and `analyze_host_sweep.R` are committed and
repeatable.

## The outcome is your "clean" branch

**Every retained Class A function is free of the defect**, verified into the
regime where it lives, on both builds:

| function | abs err at p~1e-2 | abs err at p<=1e-6 | worst rel, far tail | verdict |
|---|---|---|---|---|
| gaussQ | 2.8e-17 | 3.2e-27 | 1.2e-14 | clean |
| studentQ | 1.5e-16 | 1.1e-33 | 6.8e-15 | clean |
| chiSquareQ | 5.2e-18 | 3.2e-33 | 6.4e-15 | clean |
| fisherQ | 2.8e-17 | 9.1e-30 | 8.5e-15 | clean |
| **TukeyQ** | **3.3e-16** | **2.2e-16** | **8.8e-04** | **cancellation** |

The signature separates them without ambiguity. The four clean functions'
absolute error falls by ten to seventeen orders of magnitude as p shrinks —
they compute the tail directly, as your structural argument predicted (erfc,
incomplete gamma, incomplete beta are natively upper-tail). TukeyQ's absolute
error does not move at all.

Cross-build disagreement says the same thing:

| function | worst cross-build relative difference |
|---|---|
| gaussQ | 0.0 |
| studentQ | 7.1e-15 |
| chiSquareQ | 7.4e-15 |
| fisherQ | 7.3e-15 |
| **TukeyQ** | **2.9e-02** |
| **invTukeyQ** | **3.1e-04** |
| the four inverse Class A functions | 3.0e-16 to 2.2e-15 |

Everything except the studentised range agrees between builds at the last
ULP. The studentised range disagrees by three percent at the deepest points
swept.

So: your amended §1 is supported. The plugin has exactly one machine-dependent
calculation, it is the studentised range, the mechanism is named, and it is
already ruled for replacement.

## invTukeyQ: my inference was right, and it is now measured

Far-tail relative error against `qtukey`: 9.4e-06 on x64v3, 3.0e-04 on
intel64, cross-build disagreement 3.1e-04. Same family, same regime, same
build sensitivity. The port covering both directions was already the ruling;
this is the evidence for it rather than the assumption.

## The 144 interval rows were never affected — measured, not predicted

You asked for measured-no rather than predicted-no. Measured, at the alphas
the kit's intervals actually use, k = 2 through 6, df = 45:

| | worst relative error vs `qtukey` |
|---|---|
| x64v3 | 8.2e-15 |
| intel64 | 1.0e-13 |

Both builds agree to every printed digit at alpha 0.10, 0.05 and 0.01. Four
to five orders inside the standard rule. Your prediction holds: the certified
interval rows sit in the well-conditioned region and were never touched by
this.

## What I measured, precisely, and what I did not

The sweep is one parameter slice per function, not the parameter space:
gaussQ over z; studentQ at df = 45; chiSquareQ at df = 5; fisherQ at
df1 = 4, df2 = 45; the studentised range at k = 5, df = 45; inverses over p
from 1e-1 to 1e-15 at the same parameters. Points per function: 30 to 60.

That is enough to establish the signature, which is a property of how the
tail is constructed rather than of the parameters. It is not enough to claim
every parameter region of every function is clean, and I am not claiming it.
If you want the stronger statement for the paper, the sweep generalises
cheaply — it is a loop over df and k, and I can run it.

One honest flag: `invChiSquareQ`'s worst far-tail relative error is 8.2e-11.
Clean by the standard rule, but two orders closer to the 1e-9 line than any
of its siblings, which sit at 1e-16 to 1e-15. Not a defect. Worth knowing
which function is nearest the boundary if the rule ever tightens.

## Nothing else open from me

Both ordered sweeps are done. The one-pass rewrite scopes on the consolidated
ruling's sequence.

— Opus
