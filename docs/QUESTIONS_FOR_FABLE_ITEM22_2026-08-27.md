# Questions for Fable — language batch item 22, the Spearman method disclosure

27 August 2026. Raised by Ian: who determines item 22, and on what evidence.

## What is already decided

Your branch-law ruling of 27 August named the third method phrase, and the
work order named the first two:

    exact method (AS 89)
    t approximation (ties present)
    t approximation (large sample)

The routing that produces them is settled and under test. `v147` passes
1458 checks, including boundary twins at n = 1290 and n = 1300 that
establish R's cutoff independently of the plugin.

## What is not decided

The work order said the report should name the method on its line, "the
same pattern the Mann-Whitney p already uses."

**There is no such pattern.** Measured, not recalled: no `.method$` in the
plugin reaches a printed line. Not one. The search covers `stats/`,
`graphs/` and `scripts/`, for `appendInfoLine`, `writeInfoLine`, and the
draw-time text calls.

So item 22 is not a question about how to follow an existing row. It is
the first one.

## The finding that widens the question

Three procedures carry a method tag, and all three are dark:

| Procedure | Tags | Prints |
|---|---|---|
| `@emlMannWhitneyU` | exact / normal approximation | no |
| `@emlWilcoxonSignedRank` | exact / normal approximation | no |
| `@emlSpearmanCorrelationDispatch` | exact / t approximation, with a reason | no |

Whatever row you write for Spearman is the row all three inherit. Ruling
on Spearman alone leaves two procedures with the same undisclosed
branching, and a second wording pass to reopen it.

Spearman is also the only one of the three whose approximation has two
distinct causes — ties, and a sample above R's cutoff — so it needs a
reason where the other two need only a method. A format that fits
Spearman fits the others; the reverse is not true. That argues for
deciding it here rather than at whichever procedure comes up next.

## The three questions

1. **One row or three.** Does the disclosure land as a suffix on the
   result line, as its own line beneath it, or somewhere else? This is the
   part with no precedent to copy.

2. **Scope.** Does the ruling cover all three procedures now, or Spearman
   only with the other two deferred?

3. **The em dash.** The ruling wrote the third phrase as
   "t approximation - large sample". The batch's standing convention is
   ASCII in anything reaching a saved report, which the em dash is not.
   Was the dash load-bearing, or is a comma or parenthesis acceptable?

## Disclosure

An earlier revision of item 22 carried three fully composed report rows, a
rationale, and a decision on the em dash — all authored here, none of it
ruled. That was mine to plumb, not to write. It has been removed. The
item now carries the phrases as ruled and these questions, nothing else.

---

## Ruled, 27 August 2026

Fable ruled all three questions and corrected the work order's premise
herself.

1. **Format.** A dedicated `p method` row directly beneath the p line,
   two-column shape, disclosure class -- always prints, independent of the
   explainer toggle.
2. **Scope.** All three procedures in this pass. Mann-Whitney and
   signed-rank print their existing tags; Spearman prints method plus
   reason. The Hodges-Lehmann interval disclosures reuse the row shape.
3. **ASCII.** Parentheses, no em dash.

Exact row texts are item 22 of the language batch, awaiting Ian.
Plumbing builds now; the strings print on his approval. Affected canonical
baselines ride the standing batched re-drive.

One question was carried forward to Ian rather than settled here: the
three values are not parallel, because Spearman names a cause and the
other two do not. It is marked in the item.
