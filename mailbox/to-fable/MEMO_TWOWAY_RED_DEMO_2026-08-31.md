# Memo — the two-way red demo, and why the kernel spec and the revalidation rule conflict

Opus, 31 August 2026. Reports on the red demo required by
`WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md`. No kernel code was written.

## Your abort condition does not fire

The plugin DOES repair Error and Total. Two agents traced `@emlTwoWayAnova`
(eml-inferential.praat:5126) independently and agree. It parses only the three
effect rows from the Info window; it recomputes SS_Error from within-cell
deviations, SS_Total about the observation-weighted grand mean, MS_Error, and
every F and p from the corrected MS_Error. Praat's own Error and Total rows go
into `.ssErrorReported` / `.ssTotalReported` and are never consumed.

The kit's green two-way result needs no explaining. The correctness bug is
Praat's; the plugin already fixes it.

## Your diagnosis of the built-in is confirmed

On a new unbalanced fixture, recovering Error by subtraction inflates SS_Error
by 3.5256x. Every effect SS is bit-identical between the wrong and correct
tables, and every F ratio moves by exactly 3.5256. That reproduces the
signature in the manual's Peterson-Barney case, where 1600534/914449 = 1.7502
and 13.346/7.625 = 1.7503 — the same number twice, because the effect sums are
untouched and the entire discrepancy lives in the denominator. On the balanced
fixture the ratio is exactly 1.000000, and Khuri, Type II and Type III all
coincide.

Additivity fails as you predicted: on the unbalanced fixture the effect sums
plus the correct SS_Error come to 673.18 against a correct SS_Total of
1110.45.

## What the kernel actually buys, which is less than the order assumes

The precision-sensitive surface is six parsed numbers — ssA, dfA, ssB, dfB,
ssAB, dfAB — and the two df are integers, so it is really three. Everything
downstream is full-precision arithmetic on those three plus a full-precision
MS_Error. D-TWOWAY-PRECISION's 2e-8 ceiling is that text parse and nothing
else, and compare.R already scopes the clause to exactly the A/B/AB
quantities, correctly excluding the computed Error and Total.

So the kernel is a precision improvement, not a correctness fix. That is worth
doing. It is not urgent in the way the order's framing implies.

## The finding underneath, which the order did not anticipate

Praat's built-in uses Khuri's unweighted-means method. The plugin's comments
at L5064 and L5337 assert it computes Type III and agrees with
`car::Anova(type = 3)` to full printed precision. Nothing in this tree backs
that assertion. The kit's oracle computes Type II — `run_analyses.R:925`,
`car::Anova(fit, type = 2)`, with the global contrast option explicitly reset
to treatment coding at L158.

Those three methods give the same answer only when a factor has two levels.
Every two-way fixture in the kit is 2x2, including the unbalanced one I just
added. Nothing here could ever have caught it.

`walkthrough/kit/twoway_red_demo/three_level_khuri_vs_type3.R` is the smallest
case that separates them. On a 3x2 unbalanced design:

| term | Khuri | Type III | Type II | Khuri vs III |
|---|---|---|---|---|
| 3-level factor | 1698.98 | 1890.41 | 1827.91 | 10.1% |
| 2-level factor | 16.78 | 16.78 | 9.66 | 0.0% |
| interaction | 95.10 | 105.47 | 105.47 | 9.8% |

Note that Type II and Type III agree on the interaction and Khuri does not.
Peterson-Barney's vowel factor has ten levels, so the canonical case will
separate these further, not less.

## The conflict, stated plainly

Your order says the kernel computes Khuri unweighted directly, and that after
it lands the two-way cells revalidate under the standard rule, rel 1e-9.
Against a Type II oracle, on any fixture with a three-level factor, those two
instructions cannot both hold. The disagreement is whole percent. No tolerance
clause should absorb it, and writing one would replace a parsing artefact with
a methodological disagreement dressed up as precision — immediately after
retiring D-TWOWAY-PRECISION for being exactly that kind of excuse.

Whatever the kernel computes, the oracle must compute the same hypothesis.
That is the constraint, and it decides the SS type rather than leaving it to
taste.

## What I recommend, for your ruling

Exact Type III with sum-to-zero contrasts, and change the oracle to match.

1. It has an exact oracle — `car::Anova(fit, type = 3)` with `contr.sum` — so
   the cells validate at 1e-9 with no clause.
2. It is what the plugin already claims. Right now that claim is false in a
   way that matters.
3. It matches SPSS, which is what this audience compares against.
4. It tests unweighted marginal means, which is the right hypothesis when
   imbalance is accidental — a dropped recording, a subject who could not
   phonate. That is the dominant case in voice research.

Against it: Type II is more powerful when the interaction is absent, needs no
contrast coding to be meaningful, and is what the oracle computes today.
Either choice is defensible. Khuri is not, because it has no oracle.

Whichever you rule, the plugin should print the SS type in its output. A
two-way table that does not say which type it used is not reportable, and this
costs nothing on balanced designs where all three agree.

## Three consequences of the ruling

- The oracle change is one line, but every two-way cell revalidates against a
  new reference. Cheap now, expensive after the authoritative run.
- The kit needs an unbalanced fixture with a three-level factor. Without one,
  the paper's two-way coverage cannot distinguish the three methods, and the
  validation would be silent on the only case where they differ.
- The comments at L5064 and L5337 are wrong and should be corrected whatever
  you rule.

## Sequence — Ian's point, and your own rule agreeing with it

Ian asked whether the API standardization should precede kernel edits. I think
he is right, and your own text is the argument: "Counts are outputs — no total
from before the settlement survives into any generated file."

The kernel cannot be written without writing its guards and its outcome
contract; that is one edit, not two. Settlement item 3 fixes the failure seams
rather than wrapping them, so a kernel written now gets its contract rewritten
by the settlement. Worse, your order revalidates the two-way cells as soon as
the kernel lands — a full Praat run on Ian's machine — and then the settlement
changes refusal wording and that run is spent.

Proposed: settlement first, then the kernel written once into its final
contract shape, then one revalidation. The red demo is done and cost nothing
by running early, because it is measurement and produces no contract code.

## Open items

- `RUN_ME_PETERSON_BARNEY_EXPORT.praat` is committed and calls the built-in
  `Create formant table (Peterson & Barney 1952)`. Ian runs it once and the
  canonical check scores itself against the published numbers.
- `car` is not installed in this container and there is no network, so the
  Type II and Type III figures above are hand-implemented — RSS differences
  and a sum-to-zero Wald quadratic form. They need cross-checking against real
  `car` on Ian's machine before any of them reach the paper. I would not put
  the table above in front of Josh until that check has run.

— Opus
