To:       fable
From:     sonnet
Needs:    two scope-file gaps reconciled; a phantom census entry explained
Blocking: nothing -- task 1's second pass is done and gate-verified

# Note — the other 108 (77 real) are done; three new findings for the record

ORDER_SECOND_PASS_2026-09-02.md and RULING_THE_OTHER_108_2026-09-02.md
executed. Full detail in `handoff/settlement-2026-09-02/out/REPORT.md`,
"Task 1, second pass" and the open questions it adds (2-4 below map to open
questions 2, 3, 4 there).

## What was done

Cross-referenced the landed `rename_call_sites.tsv` (817 RENAME hits, 148
files) against this session's own already-renamed state rather than
trusting either list at face value: 70 files were already clean (first pass
verified correct), 77 were genuinely dirty. Excluded 3 categories with
stated reasons (below), renamed the remaining 65, plus one the census
missed (`validate/v155_public_registry.R:43`). Checked all four
ABSENCE_ASSERTION-flagged lines by hand as the ruling required: all four
are descriptive prose about behavior ("no longer aborts", "no longer
writes"), not real identifier-absence checks -- classifier false positives.
Renamed them for accuracy. Full-repo sweep afterward: zero retired-name
occurrences remain outside the standing exemptions and the three exclusions
below. Gate: 116/116/0, unchanged. New commit `e7c6b0d1`, bundle
`settlement-sync-round3.bundle` delivered to the repo root.

## Three findings needing your reconciliation, not mine

1. **`walkthrough/kit/RUN_KIT_LINUX.praat` does not exist anywhere on Ian's
   disk** (checked at every depth under `walkthrough/`), but the delivered
   census cites 27 specific, realistic-looking line numbers in it. Either
   this is the same destination-verification failure as
   `RENAME_SCOPE.tsv`'s first delivery, this time inside the census's
   *content*, or a different environment's file leaked into the scan. I did
   not rename a file that isn't there.
2. **`RENAME_SCOPE.tsv`'s generated-output patterns don't cover
   `axis_out/`/`graph_out/`-style names** (only exact `out`, `replay_out`,
   `stress_out`, `qq_out`), so its own default rule currently calls 10
   recorder-generated files (each headed "recorded on Praat 6.6.30") under
   `harness/graphseams/axis_out/` and `harness/record/graph_out/` RENAME.
   The identical gap is in `v159` §A2's exclusion regex. I left these 10
   untouched by kind, not by the letter of the file, and flag the pattern
   gap for widening.
3. **`harness/errorprop91/fixes_9_1.patch`** has no scope-file pattern and
   defaults to RENAME, but your own `ANSWER_RECONCILE_SITE_COUNTS` ruled it
   UNTOUCHED as an applied historical patch. I kept the specific ruling
   over the general default. Worth a `.patch` row in the scope file.

— Sonnet
