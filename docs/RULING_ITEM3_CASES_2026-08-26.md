# Ruling — the four cases item 3 reported

Fable, 26 August 2026. Answers the four cases the executing session reported
rather than decided.

## 1. All-tied — confirmed, with the oracle shape pinned

The guard-shape refusal is correct on all three counts. A hard error tearing
down the run is the exact failure class the error-propagation law exists to
kill. Refusals are results. And the estimate is a defined number, so it
survives under the estimate-is-descriptive ruling.

**Where R errors, we do not imitate R — we refuse legibly.**

Pin the disclosure text into the language batch:

    No confidence interval: all observations are tied

**Pin the kit leg for this cell as A RED-PATH ASSERTION.** It asserts our
named refusal, NOT a comparison against an R value that does not exist.

## 2. Approximation-branch estimate — confirmed, definition over implementation

The Hodges-Lehmann estimator is the median of the cross-differences. R's
approximation-branch `$estimate` is an artefact of its uniroot shortcut, about
4e-5 off its own exact branch's answer for the same data. Matching the artefact
would be fidelity to an implementation over the published definition — the
same call as Hedges exact.

v145's shape is right: assert against `median(outer(x, y, "-"))`, and report
R's value beside it.

**One addition: this is the kit's FIRST DOCUMENTED DELIBERATE DIVERGENCE, and
it gets a named rule in the quantity contract** — definition-over-implementation,
citing the measured 4e-5 case — so Josh meets it as a decision with a reason,
never as a discrepancy he has to diagnose.

**The interval bounds still port R's inversion.** Bounds are defined by test
inversion; only the estimate has a definition that outranks the port.

## 3. Holm and BH compute-and-discard — stands as built

The order's sentence was followed, and the uniform code path is worth more
than the saved arithmetic, given case 4's fix below, which makes the discarded
computation nearly free.

**No `.level`-absent convention gets invented.**

**One store pin so this cannot leak:** the store publishes interval quantities
ONLY for rows whose correction defines them. On Holm and BH rows the interval
slots publish ABSENT, which is true there — unlike the diff-matrix case.
**Computed-and-discarded values exist in no published name.**

## 4. The double DP build — refactor ordered, one build serves both consumers

The DP constructs the full null distribution. The p-value and the critical
rank are TWO READS OF ONE OBJECT, and building it twice is the same object
computed twice.

**Refactor: one build per (n1, n2), held and read by both consumers. Since the
build is keyed by the two sample sizes alone, HOLD IT ACROSS THE PAIR LOOP**,
so a balanced design computes it once for all pairs rather than once per pair.

**No behavioural change is permitted.** Acceptance is byte-identical p-values,
ranks and bounds on the existing kit rows before and after the refactor.

The 5.8-second figure is DIAGNOSIS, NOT THE ACCEPTANCE CRITERION. The
criterion is one build per distinct size pair.
