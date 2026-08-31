# Work order — two-way ANOVA direct kernel, and what the frozen run must capture

Fable, 31 August 2026. Grounds: Ian's decision in the Sol thread ("let's
assume we will rewrite and rerun the anova procedure"), which I have now
read in full. This UNBLOCKS the two-way kernel that the unification
order left waiting, amends its sequence, and adds the provenance
requirements the paper depends on. Where this conflicts with
`WORK_ORDER_NIST_UNIFICATION_2026-08-31.md`, this governs.

## What the thread establishes (verify before building — see red demo)

Praat's built-in `Report two-way anova` computes the effect sums of
squares by Khuri's (1998) unweighted method, then recovers Error as
SS_E = SS_T − SS_A − SS_B − SS_AB and centers Total on the unweighted
mean of the cell means. That subtraction is valid only for balanced
orthogonal designs; Khuri's unweighted effect sums are not additive
components of the ordinary total when cell sizes differ. So on
unbalanced data both Error and Total are wrong, and the wrong MS_E
contaminates every F and p. The command entered Praat in 2012
(v5.3.32) as a hidden Table action guarded by one balanced-only test;
the official manual's Peterson–Barney example is itself wrong (manual
Error SS 1,600,534 vs correct 914,449; vowel F 7.625 vs 13.346).

The plugin's current two-way path repairs this — it keeps Praat's
Khuri effect rows and recomputes residual, total, MS_E, F, and p
directly — but it still parses the effect sums from the Info window,
which is where the D-TWOWAY-PRECISION 2e-8 ceiling comes from.

## Red demo, before any kernel code

1. On an unbalanced fixture, reproduce the built-in's wrong Error/Total
   against the correct direct computation (the Peterson–Barney
   reconstruction from Praat's bundled 1,520-row dataset is the
   canonical case). This confirms the diagnosis from disk, not from
   the thread.
2. Confirm from source that the plugin's current path does repair
   Error/Total as described. Abort condition: if it does not — if it
   passes the built-in's table through — stop and report; the kit's
   green two-way result would then need explanation before anything
   else happens.

## The kernel

Compute the entire two-way table internally; no call to the built-in
report, no Info-window parsing anywhere in the path.

- Effect sums: Khuri unweighted, computed directly —
  n_h = rs / Σ(1/n_ij); SS_A, SS_B, SS_AB from unweighted marginal and
  cell means per the equations the plugin already targets.
- Residual: SS_E = Σ_ijk (y_ijk − ȳ_ij)², equivalently
  Σy² − Σ_ij T_ij²/n_ij. df_E = N − rs; MS_E = SS_E/df_E.
- Total: conventional corrected total about the observation-weighted
  grand mean, Σy² − T²/N.
- F_A, F_B, F_AB against MS_E with the usual effect df; p from the F
  distribution.
- Public orchestrator name and signature unchanged — no renames before
  the paper freezes Table S2. Internal change only.
- If the plugin carries a comment dating Praat's two-way to ~2006,
  correct it to 2012 (verify the comment exists before editing).

## Oracle and revalidation

The kit's existing two-way R leg is the oracle. Before relying on its
label, verify from `run_analyses.R` that it computes Type III sums
with sum-to-zero contrasts; report what it actually does either way.

After the kernel lands: the two-way cells revalidate under the
STANDARD rule (rel 1e-9 / abs 1e-12 near zero). D-TWOWAY-PRECISION is
retired — the ceiling it excused no longer exists. If any measured
discrepancy still needs a clause, it is measured and declared fresh
with its own bound; nothing is inherited from the parsing era.

## Sequence amendment

The paper describes the rewritten two-way as the implementation under
validation, so the kernel is on the critical path, not parked:

MAXROW → refusal-set equality → NIST wiring + R-side NIST runs →
**two-way kernel + revalidation** → grand_ledger → full three-study
run at a pushed commit → Tier B count verdict → Fable's inspection →
frozen-release candidate.

The Type II/III measurement-first condition in the unification order
is satisfied by the red demo above; it no longer waits on a separate
report to me.

## What the authoritative run must capture (paper-critical)

1. Every acceptance rule — the standard rule, the declared clauses,
   the NIST exact-df and LRE criteria — is committed to the repo
   BEFORE the authoritative run, so the paper's "defined before the
   final validation run" is true by the commit history. The rulings
   already in the mailbox count only once they are committed.
2. The run emits its environment into the results: Praat build, R
   version and full sessionInfo (package versions), OS, and the repo
   commit. These fill the manuscript's frozen-release placeholders;
   a run without them is not the authoritative run.
3. The forest plot regenerates from `grand_ledger.tsv` only, and its
   generating script is committed. The prior plot's script was lost;
   that does not happen again.

— Fable
