# Report — acceptance rules and forest-plot script, committed before the run

Opus, 2 September 2026. Tracker item A.8. Both files are on disk, in the
working tree, uncommitted per this job's instructions:

- `walkthrough/kit/ACCEPTANCE_RULES.md` (287 lines)
- `walkthrough/kit/forest_plot.R` (201 lines)

## The rules, in brief

Two agreement regimes, decided by `matrix.tsv`'s `study` column, never by
quantity name:

- **Tier B (`options` + `sweep`).** Standard rule already in force in
  `compare.R`: relative difference `< 1e-9`, or absolute `< 1e-12` when
  both magnitudes are near zero. A small `DECLARED[]` list may substitute
  a named, numerically bounded clause for specific quantity patterns.
  **At the authoritative run only D-WORDING should remain** as a
  both-sides-present `diff` clause — RULING_CONSOLIDATED_KERNELS orders
  D-TWOWAY-PRECISION, D-PTUKEY and D-PTUKEY-MID retired with the two-way
  and ptukey rebuilds. If any of those three still appear, or any other
  `diff`-bucket `DECLARED` row does, that's a finding, not a pass.
- **NIST.** One family, two branches, per RULING_NIST_CRITERION: the 22
  between/within df are scored by exact integer equality; every other
  certified quantity — `residual_sd` included, under the *same* rule as
  everything else, never a separate assertion — is scored by LRE, and the
  plugin passes when its LRE trails base R's own LRE by no more than 1.0
  digit (`NIST_SLACK`).

Pass/fail/out-of-scope is spelled out per regime in the rules file
(section 4), plus the cell-level refusal handling (section 5) and what
"the reference is unavailable" means in four distinct situations — see
below, one of which I did **not** resolve.

The Tier B verdict is measured against `compare.R`'s own GREEN gate (nine
conditions: zero unexplained, zero missing, zero contract violations,
balance holds overall and per-study, refusal-set three-way equality
holds, no stale cells, no un-retired declared clause, not a filtered
run) — **not** against a fixed count. Both `WORK_ORDER_NIST_UNIFICATION`
and `RULING_NIST_CRITERION` say this explicitly ("counts are outputs, not
inputs"); the 311-quantity and 98-check figures currently in the tracker
are measured expectations from the prior run, carried into the rules
file as sanity checks, not thresholds.

## Flagged loudly — NOT decided here, needs your ruling

**1. NIST cell where base R's own value is unavailable on an LRE-branch
field.** `compare.R`'s current code does not distinguish this from an
ordinary LRE shortfall: if `r_lre` isn't finite, the row is written to
`NIST_DISAGREE` under status "FAIL (LRE below base R − SLACK)" — which
would mislabel the reason if it ever fires, since there'd be no yardstick
to fall short of. No ruling I read settles whether this should be
OUT-OF-SCOPE, a FAIL under corrected wording, or something else. I wrote
the rules file's section 5 to state the current code behavior plainly and
marked it **OPEN** rather than deciding it myself or silently endorsing
the mislabeled status text as intentional.

**2. Whether NIST cells belong in the forest plot at all, and if so how.**
Not addressed by any ruling I read. NIST cells have no "percent
agreement" the way Tier B cells do — they're scored by LRE margin against
a certified constant. I made a call I'm flagging rather than treating as
settled: `forest_plot.R` plots **Tier B only**, excludes NIST rows, and
says so both on the console and inline in the script's own header
comment. Whether the paper additionally wants a NIST panel (e.g. digit
margin over the certified floor, per quantity, which would actually be a
natural forest-plot shape — point = margin, whisker = the slack band) is
your call, not mine. If you want that panel, it's a small addition to the
existing script, not a rewrite.

Everything else in the rules file traces to a specific ruling or to
`compare.R`'s own code/comments, cited by filename throughout.

## The forest-plot script — state

`forest_plot.R` needs no package (same discipline as `compare.R`). It
reads `results/agreement_by_procedure.tsv` — compare.R's own generated
per-procedure summary — computes a Wilson 95% CI per (procedure, post-hoc
arm, study) from `agreeing`/`quantities_compared`, and draws one PNG with
one panel per Tier B study, point size scaled to `n`.

**Ran to completion on today's real (interim) comparison output** —
not synthetic; this is the kit's actual output from the last time
`compare.R` ran (2026-08-31), which is what the job specified to test
against:

    $ cd walkthrough/kit && Rscript forest_plot.R
    *** Excluding 2 nist-study row(s) from the forest plot -- NIST is scored by LRE, not agreement rate. See this file's header.
    null device
              1

    Wrote /home/claude/repo/walkthrough/kit/results/forest_plot_agreement.png
    Rows plotted: 25, across 1 study panel(s) (options).

Only the `options` panel appears because every `sweep` row in today's
`agreement_by_procedure.tsv` currently carries `quantities_compared = 0`
(the R oracle wasn't run against `sweep` in the snapshot this file was
generated from) — the script's own `> 0` filter correctly drops those
rather than plotting a division by zero or a fake 0/0 rate. That will
fill in with real `sweep` rows once `compare.R` is re-run on a
`sweep`-inclusive pass.

I also verified the **synthetic fallback path** separately (moved
`agreement_by_procedure.tsv` aside, ran the script, confirmed it
generates labeled synthetic data, writes
`results/SYNTHETIC_agreement_by_procedure.tsv`, stamps "SYNTHETIC DATA"
on the plot title and in a red banner, prints a "do not cite this"
reminder, and exits 0) — then restored the real file (`git diff` on it
is empty) and re-ran the script so the file left on disk,
`walkthrough/kit/results/forest_plot_agreement.png`, is the real-data
plot, not the synthetic one. The synthetic byproduct TSV was deleted
after the test; nothing synthetic is left in the tree.

Both runs' console output above and the resulting PNG are the
verification artifacts; I looked at the rendered image both times before
calling either "runs to completion" — the real-data one shows a sensible
forest plot (24 procedures clustered near 1.0, Two Way Analysis visibly
low at ~0.65 with a wide CI, `n=54` — consistent with
`RULING_CONSOLIDATED_KERNELS`' framing of the two-way path as the one
still carrying a real precision gap before its rebuild lands).

## Files

- `walkthrough/kit/ACCEPTANCE_RULES.md` — 287 lines.
- `walkthrough/kit/forest_plot.R` — 201 lines.
- `walkthrough/kit/results/forest_plot_agreement.png` — output of the real
  run, left on disk (139,913 bytes).

Neither of the two hard-rule constraints on this job (no edits under
`plugin_EML_StatsGraphs/`, no git operations) needed to be tested against
an actual conflict — neither file touches the plugin tree, and nothing
was committed.

— Opus
