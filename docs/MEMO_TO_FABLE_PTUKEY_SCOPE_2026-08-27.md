# Memo to Fable — three families closed, one scope question left

27 August 2026. All three instructions carried out. One measurement puts a
question back to you, and I have not answered it myself.

## Diagnosis: branch (a), confirmed

Re-ran cell `c0069` in the container at `afcc715`. The container reproduces
the old value, so no commit changed the computation.

The statistic is identical on both machines:

    q      run machine  14.123877432410683
           container    14.12387743241068350

Only the CDF evaluation differs:

    padj   R            5.6645799162424737e-12
           container    5.66435787e-12            3.9e-5 relative
           run machine  5.671796365902537e-12     1.27e-3 relative

`q` matches and only `p` moves, so the spread is in `ptukey`'s quadrature and
depends on the Praat build. That is branch (a) exactly as you specified it.

## What is in the tree

`D-WILCOXEST` written from the measured pattern:
`^posthoc_.*_diff_wilcoxest(_undefined)?$`, R-side documented absence, citing
definition-over-implementation. It closes 261 rows, the figure the bare-run
adjudication recorded.

`D-PTUKEY` rewritten with the diagnosis, `maxrel = 5e-3`, `vmax = 1e-9`.
Implementing `vmax` needed a small mechanism addition: a clause may now name
the largest magnitude it speaks for, and outside that scope it does not apply.
Four rows close and the bound asserts as holding at 0.00127 against 0.005.

The parse fixture is gone: six cells left `matrix.tsv`, not two — `c0075`,
`c0156`, `c0459`, `c0501`, `c0564`, `c0565` all ran against it. The CSV is
deleted, the comma conversion at `run_analyses.R:168` is retired to
`as.numeric` alone, and the paragraph asserting the locale contract went with
it.

Struck as instructed, in both memos that carried it: the sentence adjudicating
between the two ingestion contracts.

## The question

Ten rows remain, and they are the same phenomenon above the scope you set:

| Cell | Quantity | padj | Relative |
|---|---|---|---|
| c0061, c0062 | `posthoc_control__patient_padj` | 7.2e-08 | 1.9e-7 |
| c0069, c0070 | `posthoc_welch__perfect_padj` | 2.79e-08 | 2.5e-7 |
| c0069, c0070 | `posthoc_paired__mwu_padj` | 8.61e-09 | 8.3e-7 |
| c0069, c0070 | `posthoc_welch__mwu_padj` | 4.47e-06 | 1.6e-9 |
| c0073, c0074 | `posthoc_b__x_padj` | 2.77e-06 | 2.5e-9 |

`vmax = 1e-9` excludes all of them. The disagreements out here are far
smaller — 8.3e-7 at worst against 1.27e-3 in the far tail — which is what the
diagnosis predicts, since quadrature error shrinks as the tail thickens.

I did not widen the scope. Widening a scope to admit the rows it currently
excludes is the same move as raising a bound to fit, and the rationale you
gave was "extreme tail", which 7.2e-06 arguably is not.

Two shapes, both yours to pick:

1. **One clause, wider scope.** Raise `vmax` to cover 1e-5. The 5e-3 bound
   then also governs rows disagreeing by 1e-9, which is loose by three orders
   of magnitude for that regime.
2. **Two tiers.** The far tail keeps 5e-3 below 1e-9; a second clause carries
   a tighter bound, around 1e-5, for padj between 1e-9 and 1e-5. Each bound
   then sits close to what it governs.

## State

Predicted at green except those ten: AGREE 10,798, balance holds at 12,655.
`matrix.tsv` changed, so the Praat and R sides both need re-running on Ian's
machine before any verdict counts as measured rather than projected.
