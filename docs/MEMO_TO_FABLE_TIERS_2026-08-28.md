# Memo to Fable — three tiers in the kit, and how they report

28 August 2026. Ian's decision: the kit ships all three comparisons, not one.
This states what they are, why their sizes differ, and how they report
together without pretending to be the same thing.

## What exists today, and what Josh sees

| Body of evidence | Oracle | In the kit |
|---|---|---|
| 624 analyses | R packages | yes |
| `validate/v18_sweep_parity.R` | base R | no |
| `validate/v19_nist_strd.R` | NIST certified values | no |

Both validators are live. `v19` runs green now against the current plugin:
98 checks, 98 passed. Neither reaches a reader.

## Why the three are different sizes

Comparing their row counts is meaningless, because they have different
denominators.

**The 624 is combinatorial.** It enumerates the plugin's own option space --
nine axes, every lawful combination of test, post hoc, adjustment, variance
assumption, group order and confidence level. It is large because that space
is large.

**The NIST set is fixed from outside.** NIST publishes a finite number of
certified ANOVA datasets. 98 checks is the corpus, not a sample of it.

**The sweep is a designed grid** -- k in {2, 3, 5}, n per cell from 3 to 200,
balanced and 6:1 unbalanced. Sized to reach every corner of shape space.
More cases would be repetition, not coverage.

One measures option coverage, one measures numerical behaviour under hard
shapes, one measures agreement with external truth.

## The shape change Ian requires

Neither validator may drive Praat from R. Both adopt the kit's pattern: a
Praat script writes a table, an R script writes a table, `compare.R`
compares. Neither side drives the other.

This makes both simpler.

**NIST needs no R oracle at all.** The certified values are published
constants. They become a static `nist_certified.tsv`, and `compare.R`
compares the Praat column against it. The existing Praat harness already
produces the numbers.

**The sweep keeps base R as its oracle**, computed in `run_analyses.R` like
every other cell. Base R is not a weakness here: the kit already rests on
`stats` for most comparisons, and the packages wrap it.

Both become fixtures in `data/` plus rows in `matrix.tsv`. No new runner.

## How they report

A `tier` column in `matrix.tsv`. Every cell carries it. The Praat runner,
the R runner and `compare.R` already key on cells, so nothing else in the
harness changes.

Each generated file gains the same split:

- `agreement_by_procedure.tsv` -- a `tier` column, so the table reads per tier
- `exceptions.tsv` and `disagreements_all.tsv` -- a `tier` column, so a reader
  can filter
- `SUMMARY.md` -- three sections, each stating its own question, its own
  oracle, and its own count

## Coherence

One verdict, three claims. Green means all three tiers are fully accounted
for; a red anywhere is red overall. The balance invariant runs per tier and
in total, so a row cannot escape by being filed under the wrong tier.

## The line this adds to the summary

Today the kit says the plugin agrees with R. With the NIST tier it also says
the plugin matches values certified to fifteen significant digits by an
outside body -- and on the hardest cases carries more correct digits than
base R does. That is the strongest sentence available, and it is currently
invisible.
