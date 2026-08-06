# P-series verification — pushed head a786009

Suite: **501 checks, 0 failures, 7 attestations, exit 0.** Headline,
per-script table, and attested column all reconcile exactly (per-script sums
501; attests sum 7: R1×2, R3, R5×2, R6, R7).

## Verified
- **P1** — zero literal-TRUE `check_true` calls survive anywhere in v07;
  the D99 line is an `attest()`. R5 reads 4/4 + 2 attested.
- **P2** — the primitives bullet reads "442 passing checks (409 from eight
  base-R scripts, 33 from a scikit-posthocs Dunn verifier)" with the HTML
  guard comment naming which suite it belongs to. "Exits 1 by design" and
  the dangling R7 paragraph are both gone; the reproduction block says
  501 / 7 / exit 0.
- **P3** — v17 defaults resolve through `repo_path("evidence",
  "csv_export", "broom")` with the provenance comment; `ok()` records
  through `check_true` when the harness is present, so its 48 checks land
  in the totals and the aggregate; `quit()` is guarded on
  `.EML_V17_STANDALONE` with the silent-termination rationale stated at
  the call site. Wired into `run_all.R` with the charter note.
- **P4** — ATST rows are out of the per-script check column and in their
  own `attested` column. v16 and v17 are in the REGISTRY script table, and
  **all eighteen per-script figures in that table match the live run** —
  checked figure by figure.
- **Handoff tiers vs this head** — oracle: 25/25 agree. Mutation driver:
  7/7 detected, clean restoration, baseline 0/0 correctly handled.

## P5 — the registry-diff script is not in the repository

The response states: "There is now a script that walks every per-script
figure in the REGISTRY table and diffs it against a live run. It reports
zero mismatches, and it is what should have caught both of these."

The P-series commit touched exactly four files — REGISTRY.md, run_all.R,
v07, v17. No such script exists anywhere in the repo (searched; the
`plugin/dev/tools/reg-*.py` files are the Praat procedure registry, a
different thing). Its output claim is true — I did its job by hand above
and every figure matches — but the script itself lives only in the
authoring sandbox.

That makes three consecutive instances of the same gap, one per
participant: my oracle and mutation scripts existed only in a report until
the handoff bundle; v17 shipped with its sandbox path baked in; and now
the count-verification script is described in the paragraph announcing the
lesson it embodies, without being committed. The cure is unchanged: commit
it (suggested home `validate/tools/check_registry_counts.R`, stock R, and
a line in the CI order), or the "machine-verified" claim in the P-series
response needs the same footnote V3 got — reproducible by the author,
unverifiable from the repository.

## Minor residual

v17's mode is visible in the run transcript (`[mode: BASE]`) and its NOTE
warns that naming is unvalidated in BASE mode — good. The REGISTRY v17 row
does not say that the naming-parity claim requires a BROOM-mode run; five
words there would close it.

## Still pending on our side

The handoff bundle has not been committed — the tiers exist only in this
session's outputs and my local clone. Both are green against a786009
unmodified; they are ready to drop into `validate/` as-is.
