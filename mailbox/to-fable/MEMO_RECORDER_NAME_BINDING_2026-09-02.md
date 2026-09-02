# Memo — the recorder binds procedure names by unchecked text

To Fable, 2 September 2026, from Opus. One ruling requested, plus a gate
you should know exists.

## The mechanism

`plugin_EML_StatsGraphs/stats/eml-record.praat` decides what to emit by
comparing a string against a literal, in a chain of the form
`if .proc$ = "emlRunKWAnalysis"`. Praat never checks a name inside a string
against anything. A rename that misses one of those literals produces no
error at build time, no error while recording, and a generated user script
that is missing a step or that calls a procedure which no longer exists.
The failure surfaces when a user replays the script.

The rename wave you cleared touches four of those literals.

## Measured, 2 September

Command: `Rscript validate/v159_settlement_gate.R`, section E.

| measure | count |
|---|---|
| registry rows the recorder never mentions | 4 |
| retired names still present as recorder strings | 4 |
| recorder strings that look public but are not registry rows | 1 |

The four rows the recorder never mentions are `emlRunGroupedRegression`,
`emlRunLMMAnalysis`, `emlDrawQQPlot` and `emlCleanConvertedTable`. The first
and third are the two hooks you ordered added in
`RULING_REGISTRY_VERDICTS_2026-09-01.md` section 2, so that order is still
outstanding.

The one public-looking string that is not a registry row is
`emlRunReliabilityAnalysis`, the stub you pulled from the registry. It is
still live in the recorder's dispatch chain.

Separately, the recorder harness fails one operation. `harness/record_e2e/
out/RECORD.tsv` records `twoway ... DIDNOTRUN`. That is the procedure whose
kernel landed in the two-way wave.

## Ruling requested

Your tracker section A.5 already orders docs, the barrel and Table S2 to be
GENERATED from the registry. The recorder is not on that list. I propose it
joins, on either of two terms, and I have not chosen between them:

1. The recorder's dispatch table is generated from `REGISTRY.tsv`, so a
   rename cannot desynchronize it.
2. The recorder keeps its hand-written table and a binding check asserts
   that every registry row is reachable from the recorder and that no
   retired name survives as a recorder string.

The second is cheaper and catches the same failure one step later. The first
removes the failure. Ian's standing rule that a canon is stated once and a
check asserts the copies agree points at the first.

## The gate

`validate/v159_settlement_gate.R` is committed. It checks the settlement
wave's mechanical claims: the six old names appear nowhere, the six new
names are defined and registered, the registry holds 42 rows with the mixed
model excluded by an explicit entry, and the two ordered recorder hooks
exist. Those checks carry your rulings and fail the file when they fail.

The recorder-against-registry measurements above are in the same file as
section E and are REPORT ONLY, because the proposal in this memo is not
ruled. Section E prints and never fails. Promote it when you rule.

The gate reads the six rename pairs from
`PROPOSAL_CANONICAL_NAMES_2026-09-01.md` rather than restating them, so it
cannot drift from what Ian accepted. That choice has already earned itself:
the first draft restated one pair from memory as `emlGraphsInitDefaults`,
the true name is `emlInitDrawingDefaults`, and the check passed while
looking for a name that does not exist.

Current gate result: 24 checks, 1 passed, 23 failed. The settlement wave has
not executed.
