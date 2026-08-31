# Work order — finish the unification: wire the NIST criterion

Fable, 31 August 2026. Verified against Sol's handoff zip (checkout
`6305327b`, plus the 29 Aug run artifacts). This consolidates everything
outstanding on the kit into one order. Where it conflicts with earlier
memos, this governs.

## Measured state, so the target is clear

The 29 Aug run integrated the options and sweep tiers successfully:
11,415 of 11,467 comparisons agree, the 52 both-side differences are all
clause-covered, zero unexplained, balance holds. Tier B (sweep) is
effectively green — its standalone output is 311 quantities, and the
paper's 626 is unsourced.

The only red is NIST, in two connected pieces:

- 18 `NIST_DISAGREE` rows: the standard 1e-9 rule applied to certified
  constants (for example Praat F = 21.000811... against certified 21)
  where the declared criterion is correct digits versus base R.
- The R runner skipped all 11 NIST cases (656 of 667), because the
  certified-values comparison is not wired into the kit.

`v19_nist_strd.R` passes 98/98 standalone under the digit criterion, so
the expectation is that wiring the right criterion clears the red
entirely. Demonstrate it; do not assume it.

## The build

1. **Wire the NIST criterion into `compare.R`.**
   - NIST cells carry `study = nist` in `matrix.tsv`. For those cells
     the comparator NEVER applies the relative-error rule; the wrong
     criterion is unreachable by construction, not merely unused. The 18
     current `NIST_DISAGREE` rows are the standing red demo.
   - Criterion, per Sol item 4 as already adopted: the 22 between- and
     within-group df match the certified integers exactly; the 76
     remaining certified quantities are scored by LRE
     (−log10(|x−c|/|c|)) as correct digits, for BOTH Praat and base R;
     Praat passes when its digit count is no more than one below base
     R's for the same quantity; the 10 residual-SD assertions are
     preserved; 98 checks total.
   - The R runner computes base-R results for the 11 NIST datasets (stop
     skipping them). Reuse the scoring in `validate/lre.R`; do not
     rewrite it.
   - Ledger columns for NIST rows: digits_praat, digits_r,
     min_required_digits, digit_margin, status. No raw-error ratio, no
     forcing into the common plot.

2. **Precondition: the `emlResult_MAXROW` fix** (4,000-row cap aborts
   SmLs03/06/09 export at 18,009 rows). Lands before the NIST cells run
   through the public route. Regression test included.

3. **Refusal-set equality** (already ordered, lands before first green):
   update the nine stale expectations; require observed Praat = observed
   R = expected; fail on missing or additional; matched refusals report
   as evidence.

4. **`grand_ledger.tsv`** — the unification output, one row per
   comparable result across all three studies, refusals included:
   study, case_id, procedure, dataset, quantity, both values, criterion,
   discrepancy or digit count, limit, margin, pass/fail, reason. Every
   generated file, count, and figure derives from it. Balance invariant
   per study and in total, expected totals computed independently.

5. **Counts are outputs, not inputs.** The ledger determines the Tier B
   result count (standalone is 311; the paper's 626 gets corrected to
   whatever the ledger measures), the grand totals (667 / 11,565 /
   21,793 are unestablished), and the criterion split. No number
   travels from Sol's memo, the manuscript, or the 29 Aug console into
   any generated file.

6. **Provenance discipline.** The 29 Aug run came from a modified,
   unpreserved source state. Nothing from `run_29_aug/` or the stale
   forest plot is reused as baseline or evidence. The authoritative run
   happens on Ian's machine at a pushed commit; its ledger fills the
   paper's placeholders; my inspection follows against that commit.

## Sequence

MAXROW fix → refusal-set equality → NIST wiring + R-side NIST runs →
grand_ledger → full three-study run at a pushed commit → Tier B count
verdict → Fable's inspection → frozen-release candidate.

Separately ordered and unchanged: the two-way direct kernel waits on the
Type II/III measurement coming to me first; the procedure registry and
the ledger-generated forest plot follow the ledger.

— Fable
