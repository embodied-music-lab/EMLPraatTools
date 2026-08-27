# Memo to Fable — the kit is not ready, and the residue file cannot say whether it is

27 August 2026. Ian asked whether the item 22 build closes the kit. It does
not. This states what remains, measured.

## The reconciliation file on disk is stale

`walkthrough/kit/out/reconciliation.tsv` is the bare run, written 26 August
at 21:22. Thirty-seven commits have landed since. It cannot describe the
kit's current state, and two of its own entries prove it:

- One row family says Spearman's p disagrees because the plugin computes
  the large-sample t-approximation while `cor.test` returns the exact
  permutation p. Item 3.10 fixed that. Five rows, now obsolete.
- One row family says Hedges' g uses the approximate correction
  `J = 1 - 3/(4*df-1)` and calls it a plugin defect. The exact form now
  ships at `eml-inferential.praat:563`:
  `exp(lnGamma(df/2) - 0.5*ln(df/2) - lnGamma((df-1)/2))`, documented as
  agreeing with `effectsize::hedges_g`. Twenty-four rows, now obsolete.

The current residue is unknown. Nobody has measured it since the fixes
landed.

## What stands between here and a kit that ships green

**A fresh full run.** Nothing else establishes the residue. Every rule
below is derived from it, so this comes first.

**The rule set, rebuilt against that run.** You have ruled on the
alpha-influence deltas. The `wilcoxest` family, the two-way precision
ceiling, the Tukey far-tail family, and the refusal-wording rows were all
shaped against the old residue. Each needs re-deriving, and some may have
disappeared.

**The locale parse defect.** The fixture cell `73,4` reads as 73 in
`@emlRunNormalityAnalysis`, which accepts it, and is refused by
`@emlRunDescriptiveAnalysis`. Neither reads 73.4. Two procedures disagree
about one cell, and both are wrong. Nineteen rows. Ian stopped the parse
canon by scope call, so this is open, and it is the kind of thing a
statistician reading the reports will find.

**Baseline re-capture.** The explanations flip changes report text on every
captured report. The whole baseline set moves. This is the standing batched
re-drive you already named.

**Language batch items 1 through 21.** Item 22 is approved. The other
twenty-one are not, and nothing in the batch prints until they are.

**Your gate inspection** of the item 22 build now running.

## The honest sequence

1. Finish the item 22 build.
2. Run the kit in full.
3. Read the residue and bring the unruled families to you.
4. Rebuild the rules from your answers.
5. Re-run at the gate.

Step 3 is another round of rulings, not a formality. The estimate that this
build closes the kit was wrong, and it was wrong because it read a residue
file older than the work it was describing.

## One standing constraint worth restating

Ian's rule for this kit is that it ships green: a disagreement Josh finds
is more likely a defect in our validation than a defect in R. Two entries
in the current file name plugin defects outright. Until a fresh run says
otherwise, the kit is not in a state to hand to a coauthor.
