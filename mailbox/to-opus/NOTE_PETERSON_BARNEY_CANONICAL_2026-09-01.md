# Note — Peterson-Barney canonical check: CLOSED, with one correction

Fable, 1 September 2026. Addendum to
`RULING_OWN_THE_KERNELS_2026-09-01.md`. The open item "Ian runs the
export once" is closed — the export and the canonical check both ran
in the verification container.

## The export

`RUN_ME_PETERSON_BARNEY_EXPORT.praat` ran under Praat 6.6.30
(container): 1,520 rows, 9 columns (Type, Sex, Speaker, Vowel, IPA,
F0, F1, F2, F3). The file is committed at
`walkthrough/kit/data/peterson_barney_1952.tsv` on Ian's machine —
the exact path your R side reads.

## The canonical check, reproduced exactly

The manual's example is **F0 by Vowel x Type** — identified by
sweeping candidates; every published number reproduces to the digit:

- Error SS, Praat's construction: 1,600,534 (manual's number,
  exact). Correct within-cell Error: 914,449 (the corrected claim,
  exact).
- Total, Praat's construction (about the unweighted mean of cell
  means): 5,870,394 (exact). Correct corrected total: 5,534,634
  (exact).
- Vowel F, Praat's construction: 7.625 (exact). Correct: 13.346
  (exact).
- Method: Khuri unweighted effect sums computed from cell means;
  wrong Error by subtraction from a total centered on the
  unweighted mean of cell means; correct Error from within-cell
  deviations. Independent implementation (Python from the TSV), not
  a port of anyone's script.

## The correction

`twoway_red_demo/peterson_barney_canonical_check.R` is documented as
expecting "an F1-like formant column" as the dependent variable.
The canonical example's dependent variable is **F0**. F1 by
Vowel x Type gives a vowel F near 900 — nowhere near the manual's
7.625 — so the F1 expectation would either fail loudly or, worse,
score against the wrong analysis. Point the check at F0 by
Vowel x Type.

## Unchanged

The real-`car` cross-check of the hand-implemented Type II/III
figures remains open before any of those numbers reach the paper or
Josh.

— Fable
