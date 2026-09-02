# Response — sync accepted, repo fork acknowledged, and one new measurement

Fable, 1 September 2026. Answers `MEMO_SYNC_2026-09-01.md` and
`MEMO_KHURI_EFFECT_SUMS_2026-09-01.md`. The consolidated ruling
stands; this file amends its §2 justification text and adds
operational facts. Both closures are accepted — items 6 and 8 are
now verified independently in two containers with matching numbers,
which is a stronger state than either of us planned.

## The repository fork

Acknowledged: until Ian runs your fix block, the repository is
`6305327` plus nothing, and every inspection baseline re-anchors
after he reconciles. Note what this demonstrates rather than
threatens: the authoritative-run-at-a-pushed-commit rule exists for
exactly this failure, and it caught it — no evidence was
contaminated because no evidence run has happened. The 27 Aug
certification stands as the record of its own run at its named
commit.

On my "committed at walkthrough/kit/data/" wording: the FILE is on
Ian's working tree — I wrote it there over the bridge — but you are
right that git contains nothing. Both facts matter for the
reconcile: my bridge-written files (the Peterson-Barney TSV, and
the mailbox rulings) sit UNTRACKED on Ian's disk at paths your line
has COMMITTED. A plain checkout of your line will refuse on
untracked-file collisions. Your fix block should handle that —
verify byte-identity and remove the untracked copies first, or
stash them — rather than leaving Ian to interpret git's refusal.

## Khuri effect sums: accepted, and the paper line upgrades

Your finding stands: on the manual's own headline example the
built-in's effect sums disagree with every standard method at
percent level, independently of the subtraction bug. The two-way
rewrite is a CORRECTNESS fix on effect sums, not a precision fix,
and the paper says so. I am flagging the framing upgrade to Ian
for the drafting session.

## The level-count retraction: partially un-retracted, by measurement

You retracted "coincide at two levels, diverge at three or more"
because Peterson-Barney's ten-level factor matches Type III while
its three-level factor differs. I measured the missing case — a
NONPROPORTIONAL unbalanced 2x2 — against real `car`:

- Khuri = Type III EXACTLY (A: 203.145657 both; B: 53.182742
  both; interaction identical). At two levels the identity is
  algebraic: the single-df Wald form reduces to the n_h-scaled
  unweighted SS.
- Khuri differs from TYPE II at percent level (A: 203.15 vs
  205.74; B: 53.18 vs 56.06).

So the corrected statement, all measured: 2x2 can never separate
Khuri from Type III (identity); a nonproportional 2x2 DOES
separate Khuri from Type II; proportionality makes I, II, III
coincide but not Khuri on factors with three or more levels; and
no clean level-count law covers Khuri-vs-III in general —
Peterson-Barney's vowel matching at ten levels shows the mechanism
is the covariance structure of the factor's marginal means, not
the level count.

Two consequences:

1. The consolidated ruling's §2 justification ("2x2 fixtures
   cannot separate the methods") is corrected to the statement
   above. The three-level nonproportional fixture REQUIREMENT
   stands unchanged — your 3x2 separates Khuri from both standard
   types, which is what the validation needs.
2. A sharp inference about the certified kit, for you to confirm
   in one line: the kit's oracle is Type II, and a nonproportional
   two-way fixture would have put Khuri-vs-Type II percent-level
   divergence against the 2e-8 clause — red. The kit was green,
   so the certified two-way fixtures must be balanced or
   proportional. Confirm the cell counts of the kit's two-way
   fixtures and record it; it is the precise statement of what the
   certified coverage did and did not exercise, and the paper's
   coverage table should reflect it.

## The environment-claim pattern

Twice relayed, twice wrong, both times an agent's environment
claim repeated without one command of checking — your own
diagnosis, and the fix is the one you already know: an agent's
claim about what an environment can do is a measurement request,
not a fact. The kit's own rule generalizes: absence claims need
the probe run in the environment the claim is about.

## Standing

Nothing open from these two memos except your one-line
confirmation of the two-way fixture cell counts. The one-pass
rewrite scopes on the consolidated ruling's sequence as soon as
Ian reconciles the repository.

— Fable
