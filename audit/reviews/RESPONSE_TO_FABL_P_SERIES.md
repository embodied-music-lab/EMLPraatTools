# Response to FABL-5's post-pull verification (P1–P4)

Ian Howell — Embodied Music Lab — 6 August 2026

All four accepted, all four fixed, plus two more of the same class that the
P-series pointed me at. No disputes this round.

Suite: **501 checks, all passing, 7 attestations, exit 0.** Headline and
per-script table reconcile exactly.

---

## P1 — you were right and I was wrong

Your original audit said six never-failing checks. I "corrected" it to five
and told you that you had double-counted R5.

There is a sixth. It is in `v07` and it is wrapped:

```r
check_true("R5", "D99 FIXED: the refusal states groups-vs-rows, not one group",
           TRUE)
```

`TRUE)` sits on its own line with no preceding comma, so my
`grep -E ", TRUE\)"` could not match it. That is precisely the line-based
matching failure I had criticised in V4 — I made it myself, in the act of
contradicting you, and stated the result with more confidence than a grep
deserves. Re-running the search with a paren-balanced multiline pattern finds
it immediately.

Reclassified. 454 → 453 checks, 6 → 7 attestations. Your `−5` observation was
exactly right about why the ledger balanced.

## P2 — I broke a correct number while fixing V1

Confirmed in full. The bullet read:

```
442 passing checks (409 from eight base-R scripts, 33 from a
scikit-posthocs Dunn verifier)
```

442 = 409 + 33, internally consistent, and about the **primitives** suite
under `plugin/dev/tests/` — a figure no `validate/` event can move. My
search-and-replace for V1's stale counts overwrote it with the `validate/`
headline and destroyed the breakdown, leaving your orphaned
`( scikit-posthocs Dunn verifier)`.

Restored verbatim from `025c833`, with an HTML comment on it identifying which
suite it belongs to, so the next sweep does not do this again.

Chasing it turned up a second casualty of the same edit, which you did not see
because it is three sections away: the "Reproducing this" block had a dangling
paragraph asserting R7 "has not been driven… left failing so the gap stays
visible", sitting directly beneath the new sentence announcing that R7 *had*
been driven. And the top of the file still said "the suite currently exits 1
by design". Both repaired.

The lesson I have actually taken from P1 and P2 together is narrower than
"be careful": **I was verifying counts by eye and by grep in a document whose
entire subject is count accuracy.** There is now a script that walks every
per-script figure in the REGISTRY table and diffs it against a live run. It
reports zero mismatches, and it is what should have caught both of these.

## P3 — v17 was unrunnable, and is now in the runner

Confirmed. The defaults pointed at `/home/claude/stress/broom`, the authoring
sandbox. They now resolve through `repo_path("evidence", "csv_export",
"broom")`, so a bare `Rscript validate/v17_broom_parity.R` works from a fresh
clone. Positional overrides are kept for regenerating into a scratch
directory.

I took your first option and wired it into `run_all.R` rather than documenting
why it stands apart. Two things that needed handling, which are worth naming
since they were both silent failure modes:

- v17 kept its own `pass`/`fail` counters and printed its own lines, so
  sourcing it would have produced 48 checks that appeared nowhere in the
  totals or the aggregate. Its `ok()` now also records through `check_true`
  when the harness is present.
- Its terminal `quit(status = ...)` would have **terminated the whole suite**
  before `eml_report()` printed — with a status that looks like success on a
  clean run. Guarded on a standalone flag.

## P4 — the two presentations now agree

Confirmed: the aggregate counted attestations, the headline did not. `ATST`
rows are excluded from the per-script check column and reported in a separate
`attested` column. R7 reads `7/7  1` rather than `8/8`.

While there I found that `v16` and `v17` were absent from the REGISTRY script
table altogether, and that `v02`, `v03` and `v07`'s per-script figures were
stale. All corrected and now machine-verified.

---

## On the handoff tiers

**They have not reached me.** No oracle script, no mutation driver, no
`README_handoff.md` — nothing arrived in this session, so there is nothing for
me to commit. Your run of them against `3ee862a` is the only evidence they
exist and are green, and I have no way to reproduce it.

I would like them, for the reason I gave last round: the claim that every
nonstandard statistic agrees with an independent oracle to 1e-10, and that
the harness demonstrably bites under mutation, are currently assertions in a
report rather than things a reviewer can run. That is the same category of
gap as the unwitnessed transcription in V3. Send the files and they go in
`validate/` with the CI order documented.

One caveat when they land: the oracle tier needs scipy/pingouin/scikit-posthocs,
which puts it outside `run_all.R`'s stock-R charter. It should be a separate
entry point with its own dependency note, not folded into the runner — the
charter is load-bearing, since it is what lets a reviewer with a bare R
installation check the arithmetic at all.

---

## Ledger

| | |
|---|---|
| after your V-series verification | 454 checks, 6 attested |
| P1 — sixth attestation reclassified | −1 check, +1 attested |
| P3 — v17 wired into the runner | +48 checks |
| **now** | **501 checks, 7 attested, 0 failures, exit 0** |
