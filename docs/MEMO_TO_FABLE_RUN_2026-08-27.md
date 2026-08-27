# Memo to Fable — the fresh run, and the three families it leaves you

27 August 2026. Run on Ian's machine against the installed plugin at
`afcc7154`. Praat and R both current; `compare.R` re-run here against those
result files.

## The run

    cells declared                 630
    value comparisons made      10,871
    AGREE                       10,801   relative difference < 1e-9
    contract completeness       22,317 expected, 22,317 reported, 0 missing
    refusals                    24 both sides, 0 declared refusals missed
    balance invariant           HOLDS, 12,685 counted two independent ways

Every quantity the contract requires is present on both sides, across all 17
procedures. Nothing fell out of the accounting.

## One regression, caught by the kit and fixed

`spearman_p_asymptotic` had been carrying the exact p since item 3.10 landed.
The dispatch writes the routed p back into `emlSpearmanCorrelation.p`, and the
kit still read `.spearP` for the quantity whose whole purpose is to hold the
t-approximation. At cell `c0404` the plugin reported 6.34e-07 where R had
1.93e-17.

That quantity is the evidence D-SPEARMAN rests on: both sides computing the
same approximation is what pins the Spearman disagreement to tail choice
rather than arithmetic. Reading the routed value destroyed it.

The kit now reads `.pAsymptotic`, which the dispatch captures before routing.
Ten rows closed; `c0404` agrees to 5e-14.

## Clauses rebuilt from the fresh measurement

Written from this run, not copied from the retired list. Four families
matched a clause shape and carry the number measured here:

| Clause | Rows | Basis |
|---|---|---|
| `D-TWOWAY-PRECISION` | 18 | measured max 1.223e-8, bound 2e-8, asserted and holds |
| `D-WORDING` | 17 | refusal wording; same cells refuse |
| `D-ALPHA2ITEM` | 6 | undefined at k = 2, two spellings |
| `D-ALPHADROP` | 2 | the n = 3 fixture divergence you ruled |

Residue after rebuilding: **294 rows, in three families.**

## 1. The wilcoxest family has no clause, and never had one

258 rows, `posthoc_*_diff_wilcoxest`, R-only, plus 3 more in the `_undefined`
form. The nearest retired clause, `D-NODIFF`, matches `posthoc_.*_diff$` and
does not reach `_diff_wilcoxest`.

This family was carried as unruled out of the bare run and is still unruled.
It is the largest single block of residue and the one thing standing between
this run and green.

## 2. The Tukey far-tail bound is exceeded, by about thirty times

`D-PTUKEY` carried `maxrel = 1e-4`, on a family the clause described as
differing by roughly 4e-5. Measured in this run:

    1.2740e-03   c0069, c0070   posthoc_paired__perfect_padj
                 P = 5.671796365902537e-12
                 R = 5.6645799162424737e-12

Fourteen rows. The clause's own text says the bound is asserted, not assumed,
so I have not restored it: an exceeded bound is a finding, and raising it to
fit would make the clause describe whatever it meets.

I have not diagnosed why it moved. Both sides still evaluate the studentised
range distribution; the disagreement is at p ≈ 5.7e-12, where quadrature
differences are largest.

## 3. The parse fixture is in the run list your audit says it left

19 rows across `c0459` and `c0501`, both on
`rp_r6_parse_conditions_input`. Your corpus audit records that fixture as
"already ruled out of the kit". It is still in `matrix.tsv`, running two
cells.

The retired `D-PARSE` clause would absorb these rows. I have not restored it,
because if the fixture is out of the run list the rows should not exist at
all, and a clause that explains rows a ruling has already removed is the
wrong repair.

The measured content, for the record: the plugin excludes the comma-decimal
cell and reports n = 3; R reads 73.4 and reports n = 4; every descriptive
statistic and the two CI bounds differ downstream. R holds the correct
reading.

## What each needs

1. **wilcoxest** — a ruling. No clause shape exists to re-apply.
2. **Tukey far tail** — a ruling on an exceeded bound, and a decision on
   whether to diagnose the change before setting a new one.
3. **Parse fixture** — not a ruling but a correction: either the cells leave
   `matrix.tsv`, or the audit's "ruled out" needs restating.

With those three settled the run goes green. Nothing else is outstanding.
