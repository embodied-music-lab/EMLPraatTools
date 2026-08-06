# Validation registry — EML Praat Tools

Ian Howell — Embodied Music Lab — GPL-3.0-or-later

> **If you just want to check that the statistics are right, read
> [`README.md`](README.md) instead.** It is one page, it names the exact
> command, and it walks one number end to end by hand. This file is the full
> reference: what every script covers, the conventions chosen where
> statisticians disagree, the tolerance reasoning, the red-path cases, and an
> honest statement of what is *not* covered. It is long on purpose.

This folder is the validation record for the EML Praat Tools statistics
layer. It exists so that the plugin's arithmetic can be checked by someone
with no access to the audit session, the sandbox, or the GUI harness.

**Nothing in this project counts as validated until a script in this folder
tests it.** Values quoted in an audit log or a chat transcript are not
validation. If a statistic is not covered by a script here, treat it as
unvalidated regardless of what any other document claims.

---

## Running it

```
Rscript validate/run_all.R
```

Requires **R only** — tested on 4.3.3. No packages are installed, loaded, or
needed; every quantity the plugin reports that base R does not provide
directly is implemented from its standard definition in `helpers.R`. This is
deliberate, so the suite runs on a stock R installation with no network
access.

Exit status is 0 if every check passes and 1 otherwise, so it can be wired
to CI unchanged. Individual scripts are also runnable on their own:

```
Rscript validate/v03_rm_anova_greenhouse_geisser.R
```

**The suite exits 0.** It exited 1 by design until 6 August 2026, when the
last undriven red-path case (R7) was driven. See "Reproducing this, as a
reviewer" below for what a passing run does and does not establish.

---

## What is being compared against what

Each check pairs a value the plugin **printed** with a value R **computes**.

**The printed value is read out of a committed capture, not typed into the
script.** `evidence/info/*.txt` holds the Info-window text, taken with
`info$()` written to a file — never transcribed from a screenshot — and
`helpers.R` provides the accessors that read it:

| | |
|---|---|
| `printed(cap, label, field, occurrence)` | a number in the plugin's column format |
| `printed_str(...)` | the raw text, for `p < .001`, `exact`, `---` |
| `printed_cell(cap, section, row, col)` | one cell of a printed matrix, addressed by **column name** |
| `printed_eq(cap, key, which, occurrence)` | the Stats Wizard's `label = value` format |
| `check_floored(...)` | asserts the capture really says `< .001` **and** that R agrees |

They fail loudly on a label that is absent, on an occurrence past the last
match, and on a value that is no longer numeric. They do **not** fail on an
ambiguous label — several matches resolve to the first, silently. This
paragraph claimed otherwise until 6 August 2026, and the ambiguity is real:
"Soprano" matches 5 lines in the v09 capture and 7 in v10, "voice type" and
"task" 2 each in v11. Those reads are correct only because block order is
stable. Call sites that depend on a label matching a known number of lines now
say so with `expect_hits`, which turns a wrong belief into a halt; the reads in
v09, v10 and v11 are pinned that way.

A capture that drifts out of step with a script must break the suite, not
quietly stop testing anything.

This matters more than it may look. Until 5 August every printed value
reached the comparison as a literal typed in by hand, which put an
unwitnessed step in the middle of the chain:

```
Praat prints X  ->  [transcription]  ->  literal in the script  ->  R  ->  compare
```

Running the suite verified the right-hand half only. Had a literal been
copied from R's own output instead of from Praat's, every check would pass
and the suite would validate nothing — the exact failure that
`plugin/dev/tests/REFERENCE_PROVENANCE.md` exists to prevent on the other
side. Six literals remain and each is labelled where it sits:

- **three in `v07`** — `441.0000`, `0.0023`, `0.5000` at lines 249–251. These
  are not properties of the table, as this paragraph said until 6 Aug 2026:
  they are the values the plugin *printed* on the 5 August drive of R2,
  transcribed by hand and compared against R's recompute of the same
  constructed table. **No capture of that drive is committed** —
  `evidence/info/rp_r2_rmanova_info.txt` is the 6 August re-drive, on a
  different table (see the R2 row below). So the transcription is unwitnessed:
  R reproduces all three to the stated tolerance, which is what the checks
  assert and what makes the arithmetic safe, but a reviewer cannot verify from
  this repository that the plugin ever printed them. Treat them as a recorded
  observation, not as evidence.
- **one in `v11`** — an input row count.
- **two in `v13`** — degrees of freedom read off the printed label `F(1,23)`,
  with a separate check asserting that label exists.

The inputs are the exact tables the plugin analysed, committed under
`evidence/csv/`.

That last point is not incidental. **The plugin's demo tables are randomly
generated on each creation.** Creating a fresh `Three groups (N=45)` table
and re-running will not reproduce any number in this suite. Every script
reads a committed input file for that reason, and a reviewer should not
substitute freshly generated data.

Tolerances follow the precision the plugin prints at: 5e-4 against a
3-decimal display, 5e-5 against 4 decimals, and so on. Two kinds of check
need looser tolerances and say so at the call site — a value derived from
two already-rounded printed values absorbs both roundings, and a quantity
that is ill-conditioned in its inputs (a *t* recomputed from an *r* near 1)
cannot be asserted at display precision in that direction at all.

---

## Reproducing this, as a reviewer

**You need R and nothing else.** Tested on 4.3.3. No packages are installed,
loaded, or required.

```
git clone <repo> && cd EMLPraatTools
Rscript validate/run_all.R
```

**Expect exit status 0.** 1045 checks, all passing, plus 8 attestations
reported separately and not counted as checks.

Until 6 August 2026 this said "expect exit status 1", because R7 — the
small-range axis case — had never been driven and its placeholder failed on
purpose. R7 was described for a month as an axis case that had to be judged
from a rendered figure, and therefore belonged with the graphing work rather
than in an R suite. That was wrong: the draw procedures call no `beginPause:`,
so they run under `praat --run` with no X server, and an axis is a number. It
is driven now, and the suite has no designed failures left.

An **attestation** is a claim backed by a screenshot or a recorded
observation rather than by anything the script can evaluate. There are eight — seven in `v07`, and one in `v20` recording that its
five files came from the shipping orchestrator rather than a harness. They print as `ATST`, are excluded from the check count and
from the exit status, and are listed separately so that "1045 checks passed"
means 1045 things were tested.

D96 through D99 were failing here until 6 August. They now pass, and they
pass against captures re-driven after the fixes, not against the old ones.

### What a passing run establishes

That the values in the committed captures are correct for the committed
inputs, under the conventions named below, and that the plugin's report is
internally consistent — printed totals equal their printed parts, printed
matrices are symmetric or antisymmetric as their statistic requires, each
printed *t* equals its own printed estimate over its own printed SE.

### What it does not establish

**That the captures came from a real run.** Nothing in R can settle that;
only re-driving Praat can. If you want that assurance the package to ask for
is the plugin, Praat 6.6.30, and the GUI harness under `harness/` — the
suite is deliberately separable from it so that the arithmetic can be
reviewed without any of that apparatus.

It also says nothing about the graphing layer, the error paths, or anything
that is not a number in an Info window.

---

## The optional tiers

`run_all.R` needs **stock R and nothing else**, and that charter is
load-bearing: it is what lets a reviewer with a bare R installation check the
arithmetic without any of this project's apparatus. Three further tiers sit
outside it. None is required by `run_all.R`; each answers a question the base
suite cannot.

Contributed by an external audit (FABL-5) on 6 August 2026, after the response
to that audit asked for them: the claims they make had until then existed only
as assertions in a report, which is the same category of gap as the
unwitnessed transcription described above.

### `validate/tools/check_registry_counts.R` — stock R

Parses every per-script figure in the script table below, the `v07` row's
`N + M attested` composite, and the headline claim, and diffs each against a
live run. A row it cannot parse is a **failure, not a skip**.

This exists because two of the defects in this document were count claims that
I checked by eye and by `grep`, in a document whose subject is count accuracy —
including one where a line-based pattern missed a wrapped `TRUE)` and I
confidently contradicted a correct audit finding. Verified to fail correctly:
corrupting one table figure produces `FAIL v09 checks: claimed 41, live 40`.

```
Rscript validate/run_all.R | tee /tmp/suite.log
Rscript validate/tools/check_registry_counts.R /tmp/suite.log
```

Currently: **21 claims, 0 mismatches.**

### `validate/oracle/` — R for the dump, Python for the comparison

Answers "is `helpers.R` right?" against scipy, pingouin, scikit-posthocs and
statsmodels, for the 25 quantities base R does not provide.

The two-file split is the point. `oracle_dump.R` has **`helpers.R` itself**
compute the values and write `oracle_values.csv`; `oracle_check.py` compares
that file against the independent libraries. An oracle that re-implements the
formulas in another language is a transcription, and a transcription can
silently correct the thing it copies. This one tests the functions that ship.
It also fails on a dumped value with no oracle counterpart *and* on an oracle
value with no dump counterpart, so the two halves cannot drift apart quietly.

```
Rscript validate/oracle/oracle_dump.R
python3 -m pip install -r validate/oracle/requirements.txt
python3 validate/oracle/oracle_check.py
```

Currently: **25 statistics, 25 agree**, worst disagreement 8.8e-10 (a
Shapiro-Wilk *p*; every other value agrees to 1e-11 or better).

`oracle_values.csv` **is committed**, as a pinned reference. The dump is
deterministic on committed inputs, so regenerating it must produce no diff —
which makes it a regression detector rather than stale output:

```
Rscript validate/oracle/oracle_dump.R
git diff --exit-code validate/oracle/oracle_values.csv
```

A diff there means `helpers.R` or a committed input changed. That is a
finding, and it is the reason this file is committed rather than ignored.

### `validate/mutation/mutate_drive.sh` — bash, git and R

Answers "would this suite notice if a capture were wrong?" It corrupts one
committed evidence file at a time, re-runs the suite, and requires the suite
to respond — either by gaining a failure over the baseline or by halting. A
suite that stays green under a corrupted capture is validating nothing.

It is baseline-relative rather than count-hardcoded, so it survives the suite
growing. It refuses to run on a dirty `evidence/` tree, restores through
`git checkout --`, and verifies the restoration at the end. A `sed` pattern
that no longer matches reports `SKIP`, never a false `OK`.

```
bash validate/mutation/mutate_drive.sh
```

Currently: **7 mutations, 7 detected, clean restoration.** Six raise a failure
count; deleting the `Cohen's dz` label halts the harness, which is the
behaviour the accessors promise.

### CI order

```
Rscript validate/run_all.R | tee /tmp/suite.log
Rscript validate/tools/check_registry_counts.R /tmp/suite.log
Rscript validate/oracle/oracle_dump.R
git diff --exit-code validate/oracle/oracle_values.csv
python3 -m pip install -r validate/oracle/requirements.txt
python3 validate/oracle/oracle_check.py
bash    validate/mutation/mutate_drive.sh
```

The first two need only R. The mutation driver needs a clean tree and a git
checkout. Only the third pair needs Python, and it is the only step that may
be skipped without weakening a claim made in this document.

---

## The scripts

| Script | Covers | Input | Checks |
|---|---|---|---|
| `helpers.R` | Shared harness and the statistics base R lacks: Cohen's *d* and *d*z, *r* from *t*, matched-pairs rank-biserial, RM-ANOVA with Greenhouse-Geisser, Kendall's *W* | — | — |
| `v01_pairwise_welch_bonferroni.R` | *Pairwise comparisons* wrapper: Welch *t*, Bonferroni, Cohen's *d* | `evidence/csv/demo_3groups_input.csv` | 15 |
| `v02_pairwise_holm_differential.R` | The same wrapper run twice, one control apart, to separate an applied adjustment from a labelled one. Also asserts, rather than assumes, that the two captures differ only in the adjustment | `evidence/csv/demo_3groups_b_input.csv` | 24 |
| `v03_rm_anova_greenhouse_geisser.R` | Stats Wizard RM-ANOVA: *F*, GG ε, condition means, Holm post-hoc | `evidence/csv/demo_rm3_input.csv` | 21 |
| `v04_friedman.R` | Stats Wizard Friedman: χ², rank sums, Wilcoxon post-hoc, Holm on ties | `evidence/csv/demo_rm3_input.csv` | 14 |
| `v05_paired_t.R` | *Compare paired/repeated*: paired *t*, descriptives, and the graphs-side CSV export row | `evidence/csv/demo_paired_input.csv`, `evidence/csv/pairedLong_results_5aug.csv` | 21 |
| `v06_D15_effect_size_defect.R` | D15, now resolved: each paired test reports its own effect size | `evidence/csv/demo_paired_input.csv` | 9 |
| `v07_redpath_degenerate_inputs.R` (reported per case as R1–R7) | Red path: inputs that should fail or sit on a boundary. **All seven driven** as of 6 Aug 2026 | generated into `validate/redpath/` by the script itself | 55 + 7 attested |
| `v08_twogroup_orchestrator.R` | *Compare two groups*: Welch *t*, Mann-Whitney, Cohen's *d*, Hedges' *g*, rank-biserial | `evidence/csv/v08_twogroup_input.csv` | 26 |
| `v09_anova_tukey_orchestrator.R` | *Compare k groups (ANOVA)*: ANOVA table, eta-squared, Tukey matrix, pairwise *d* matrix | `evidence/csv/v09_anova_tukey_input.csv` | 40 |
| `v10_kruskal_dunn_orchestrator.R` | *Compare k groups (Kruskal-Wallis)*: *H*, epsilon-squared, mean ranks, Dunn *z* and adjusted *p*, rank-biserial matrix | `evidence/csv/v10_kw_dunn_input.csv` | 34 |
| `v11_twoway_orchestrator.R` | *Compare two-way (ANOVA)*: main effects, interaction, partial eta-squared | `evidence/csv/v11_twoway_input.csv` | 31 |
| `v12_correlation_orchestrator.R` | *Correlate two columns*: Pearson and Spearman with their *t* and df | `evidence/csv/v12_correlation_input.csv` | 16 |
| `v13_regression_orchestrator.R` | *Linear regression*: model, overall *F*, coefficient table, direction | `evidence/csv/v13_regression_input.csv` | 30 |
| `v14_descriptive_orchestrator.R` | *Describe Table column*: central tendency, dispersion, quartiles, shape, CI | `evidence/csv/v14_descriptive_input.csv` | 29 |
| `v15_normality_orchestrator.R` | *Check normality (all columns)*: three columns, and the parametric/nonparametric recommendation | `evidence/csv/v15_normality_input.csv` | 43 |
| `v16_csv_export.R` | The CSV export: every number against R, plus the structural assertions that make the file unambiguous to pivot | `evidence/csv_export/*.csv` | 45 |
| `v17_broom_parity.R` | The broom-shaped export: tidy / glance / augment / post-hoc / effect size against R, structurally and numerically | `evidence/csv_export/broom/` | 48 |
| `v20_shipping_anova_broom.R` | **CSV migration checkpoint 1.** The SHIPPING one-way ANOVA path (`@emlRunAnovaAnalysis`) in broom's three-file shape: tidy / glance / augment, plus post-hoc and effect sizes as their own frames. Column names AND order asserted against broom's documented contract; every value against base R | `evidence/csv_export/broom/shipping_anova_*` | 55 |
| `v21_shipping_paths_broom.R` | **CSV migration, paths 2-11.** The other ten shipping orchestrators in broom's three-file shape, every file written by the orchestrator the menu calls. Asserts that htest paths write NO augment, since broom has none for them | `evidence/csv_export/broom/ship_*` | 97 |
| `v19_nist_strd.R` | **Tier C.** The plugin against NIST StRD certified values, scored in log relative error. Contributes checks only when the `.dat` files have been ingested; prints a loud SKIP otherwise | `evidence/nist/` | 98 |
| `v18_sweep_parity.R` | **Tier B.** One-way ANOVA, Tukey-Kramer and Kruskal-Wallis over a 16-case designed grid: k = 2/3/5, n per cell 3-200, balanced and 6:1 unbalanced, tie-free to heavily tied, 1:1 and 10:1 variance ratios | `evidence/sweep/` | 294 |

### Notes on individual scripts

**`v02`** is the load-bearing one for the adjustment logic. On that data the
Soprano–Mezzo contrast is `0.0527` under Bonferroni and `0.0228` under Holm —
opposite sides of .05. A control that relabelled the adjustment without
applying it could not produce that difference. It also checks Holm's
monotonicity constraint, which is the specific behaviour a naive step-down
implementation gets wrong.

**`v03`** cross-checks the RM-ANOVA twice: against the closed-form sums of
squares in `helpers.R`, and against base R's `aov()` with an `Error()`
stratum, which is an independent implementation. Both must agree with the
plugin.

**`v04`** covers the tied case: all three post-hoc raw p-values are
identical, so Holm must give all three the same adjusted value rather than
three different step values.

**`v05`** validates the Info window and the exported CSV separately. They
disagree in precision — the CSV carries `0.0000003` where the Info window
prints `< .001` — and checking only one surface would miss that.

---

## Expected failures

One check fails on purpose. Two more used to, and the record of what they
were is kept rather than deleted — a suite that quietly drops its failures
as they are fixed leaves no way to tell a fix from a deletion.

### 1. ~~`v06` pins a defect~~ — RESOLVED 5 August 2026

Finding **D15** was: under the heading *Paired t-test*, the plugin printed
`Matched-pairs r  0.971`. That value is the matched-pairs rank-biserial
correlation of the **Wilcoxon signed-rank** test. The correlation derived
from the paired *t* is **0.871**. Both are plausible and nothing on screen
distinguished them.

The plugin now reports Cohen's *d*z and *r*-from-*t* under the paired *t*,
and the rank-biserial *r* under Wilcoxon. `v06` was rewritten to assert the
corrected behaviour and **passes**; it retains a guard check that the two
effect sizes stay numerically distinct, so a future regression that routes
the rank statistic back under the parametric heading would fail the suite.

### 2. ~~`v07` fails on four open findings, and one undriven case~~
### — RESOLVED 6 August 2026, all seven cases driven

Six of the seven cases were driven on 5 August 2026, loaded into Praat
unchanged and taken through a wrapper. Four of them exposed defects — D96,
D97, D98, D99 — and all four were fixed on 6 August and the cases re-driven.
The seventh, R7, was driven headlessly on 6 August (see its row below), so
the red path is now complete. The table below records both states, because the fix is only
believable next to what it replaced.

| Case | Verdict | What happened |
|---|---|---|
| R1 | **Passes** (was partial) | States "complete cases n = 4" and "4 row(s) excluded for missing data" — the requirement, met twice. But every complete case was exactly linear, so the RM-ANOVA error term is identically zero, and the omnibus printed `F(2, 6) = 21110623253299200.0000` with a 48-place *p*, while its own post-hoc caught the same condition and refused. **D97 — FIXED 6 Aug**: the omnibus refuses too. The floor is relative (`ssErr <= 1e-10 * ssTot`); the residual sits at ~1e-16 of the total, so an equality test against zero would not have fired. |
| R2 | **Passes** (was failing) | **Two drives on two different tables — read the numbers with that in mind.** On 5 Aug, on the table `v07` constructs (70/72, 80/83, 90/94), the plugin computed *F*(2, 2) = 441.0000, *p* = 0.0023, GG epsilon = 0.5000 and three post-hoc *p*-values from two subjects with no comment of any kind. That is the defect, D98. The epsilon is itself the tell: 0.5 is exactly the 1/(*k*−1) floor forced by *n* = 2, and the plugin has that value in hand at print time. **FIXED 6 Aug**, and re-driven on a different two-subject table (10/14/21, 12/17/22) which gives *F*(2, 2) = 111.0000, *p* = 0.0089 — the numbers in `evidence/info/rp_r2_rmanova_info.txt`. A caution now prints directly under the GG line; the suite asserts its POSITION as well as its text, since at the foot of the report it would read as being about the post-hoc. The input changed between drives, so this row is a before/after on the *behaviour*, not on the *numbers*. |
| R3 | **Passes** | Refuses and names it: "All differences are identical (zero variance)". Fabricates no statistic. |
| R4 | **Passes** | Refuses and names the group and its *n*: "Group ""Soprano"": n=6, group ""Alto"": n=1". |
| R5 | **Passes** (was partial) | Refused before computing, which was the important half, but named only the first offending group — six singletons, six attempts — and leaked the internal procedure name. **D99 — FIXED 6 Aug**: "Group column ""singer_id"" has 6 groups for 6 rows - one per row. This is an identifier column, not a grouping column." |
| R6 | **Passes** (was partial) | First recorded as a silent row-drop. That was **wrong** — the plugin printed `N (valid) 4` and `N (undefined) 1`. What it could not do was tell an empty cell from an unparseable string from a European decimal comma. Worse than the report suggested: `Get value:` returns 1 for `"1,5"`, so the comma cell was not dropped at all, it entered the mean as a different number. **D96 — FIXED 6 Aug**: one classifier, `@eml_classifyCell`, used by every extraction path including the row-wise ones; the three conditions are reported separately with row and value named, and the comma cell is excluded rather than guessed at. |
| R7 | **Passes** (was not driven) | The small-range measure, D88 as a data case: contact quotient in 0.401–0.548, where a `roundTo` of 10 gives a 0–10 axis and the data occupies 1.5% of the panel. **Driven 6 Aug 2026**, headlessly — the draw procedures call no `beginPause:`, so the whole objection that this case "had to be judged from a figure" was never true; the axis is a number and can be read like any other. `@emlDrawSpaghettiPlot` on the reshaped table gives an axis of 0.380–0.580, so the data occupies **73.5%** of the panel. Capture: `evidence/info/v07_r7_axis_info.txt`. Figure: `evidence/figures/r7_small_range_axis.png`. |

The requirement each case was written against, stated before the drive so
the drive could fail:

| Case | Input | Behaviour the plugin must show |
|---|---|---|
| R1 | 8 subjects, 4 complete cases | Report the complete-case count it analysed, or refuse. Silently analysing 4 while the table shows 8 is a defect |
| R2 | n = 2 subjects, k = 3 | df error = 2. Compute or refuse, but say which; do not present a p-value from df 2 without comment |
| R3 | Zero variance throughout | Refuse, naming the zero variance |
| R4 | One group with n = 1 | Refuse, naming the group and its n |
| R5 | Grouping column unique per row | Refuse before running, naming group count against row count. 15 pairs would otherwise be attempted, none estimable |
| R6 | Non-numeric entry in a measure column | Reject the column **by type**, naming it. Not "incomplete data" — see D83. *This requirement was itself too strong: the 21 July complete-case convention says analyse and state the exclusion. What the case actually tests is whether the three causes of exclusion can be told apart* |
| R7 | Contact quotient, range 0.40–0.55 | After the D88 fix, an axis that fits the data. With `roundTo = 10` the axis is 0–10 and the data occupies 2% of the panel |

---

## Coverage, stated honestly

**Covered.** Twelve of the fourteen orchestrators in
`stats/eml-analysis.praat`, each driven through its real GUI and checked
against base R: two-group, *k*-group ANOVA with Tukey, Kruskal-Wallis with
Dunn, two-way, pairwise with Bonferroni and Holm, paired *t*, RM-ANOVA with
Greenhouse-Geisser, Friedman, correlation, regression, descriptive, and
normality including the parametric/nonparametric recommendation it issues.
Plus one CSV export row and all seven red-path cases.

### One dataset per test — say so plainly

Every orchestrator above is driven on **exactly one input table**, and this
is the single largest limit on what a green run means. The shapes:

| Script | Input | n | Design |
|---|---|---|---|
| v01 | `demo_3groups_input.csv` | 45 | 3 × 15, balanced |
| v02 | `demo_3groups_b_input.csv` | 45 | 3 × 15, balanced |
| v03, v04 | `demo_rm3_input.csv` | 20 | 3 within-subject levels, complete |
| v05, v06 | `demo_paired_input.csv` | 20 | complete pairs |
| v08 | `v08_twogroup_input.csv` | 40 | 2 × 20, balanced |
| v09 | `v09_anova_tukey_input.csv` | 45 | 3 × 15, balanced |
| v10 | `v10_kw_dunn_input.csv` | 45 | 3 × 15, balanced |
| v11 | `v11_twoway_input.csv` | 48 | 2 × 2 × 12, fully crossed and balanced |
| v12 | `v12_correlation_input.csv` | 30 | bivariate |
| v13 | `v13_regression_input.csv` | 25 | one predictor |
| v14 | `v14_descriptive_input.csv` | 45 | 3 × 15 |
| v15 | `v15_normality_input.csv` | 40 | three measured columns |
| v07, v16, v17 | constructed in-script | 2–8 | degenerate / export / broom parity |

What that table implies, stated as findings rather than left to be noticed:

- **Every between-groups design is balanced.** No unequal-*n* case reaches
  Tukey, Dunn, Games-Howell, or the two-way sums of squares. Type I vs
  Type III SS cannot diverge on a balanced crossed design, so v11 cannot
  distinguish them — the convention recorded above is asserted, not tested.
- **`v10_kw_dunn_input.csv` has no ties**: 45 values, 45 distinct. The
  plugin's Dunn/Kruskal-Wallis tie correction has therefore never executed
  on a driven dataset. It is covered only by the primitives suite under
  `plugin/dev/tests/`. This is the sharpest single gap in the folder.
- **No missing data outside the red path.** Every green-path input is
  complete; the complete-case convention is exercised only by R1 and R6.
- **No ill-conditioned or wide-magnitude data.** Every measured column sits
  in an ordinary acoustic range (F0 in Hz, SPL in dB, jitter in percent).
  Nothing here would separate a numerically stable implementation from an
  unstable one — the class of failure the NIST StRD sets are built to find.

None of this makes a passing check wrong. It bounds what the checks are
evidence *of*: correct arithmetic on well-conditioned, balanced, complete
data, which is the common case and not the hard one.

### The tiers that answer it

`v18_sweep_parity.R` (added 6 August 2026) takes the first two of those
findings off the list for one-way ANOVA, Tukey and Kruskal-Wallis. It is a
different kind of evidence and is labelled as such: the cases are generated
headlessly by `harness/sweep/tierB_grid.praat`, which calls the shipping
procedures directly under `praat --run`, so there is no click-through
provenance behind any of its 294 checks. What it establishes is that the
procedure is right on 16 shapes the GUI drives never produced — including
6:1 unbalanced Tukey-Kramer and heavy ties in Kruskal-Wallis.

Two further tiers exist as harness rather than as committed evidence:

- `harness/sweep/tierA_properties.praat` — 22 invariance and refusal
  properties that hold whatever the data is (one-way *F* = *t*² at *k* = 2,
  location invariance, scale equivariance, group-label permutation
  invariance, rank invariance of *H* under a monotone transform, matrix
  symmetry, and eight malformed-input cases whose refusal must *name* what
  is wrong). No oracle and no certified value, so nothing is transcribed.

  A correction, recorded rather than quietly edited: an earlier version of
  this line called `lowerCase$` a portability defect Tier A had found. It is
  not one. The plugin floors at Praat **6.6.30** — enforced in `setup.praat`,
  which refuses to register any menu item below it — and `lowerCase$` exists
  there. What Tier A actually hit was the sandbox's Praat 6.4.06, which is
  below the supported floor. `eml_normalizeLabel` now uses an equivalent
  regex only so the harness runs wherever CI puts it.
- `validate/tools/nist_ingest.R` + `validate/lre.R` — the NIST StRD tier.
  The certified values are parsed out of NIST's published `.dat` files, never
  transcribed, and scored as **log relative error** (correct significant
  digits) rather than pass/fail, which is the convention StRD work is
  reported in. The `.dat` files are not redistributed here; `nist_ingest.R`
  documents the two `curl` lines that fetch them. **This is the only external
  authority anywhere in this folder** — every other check is ultimately "R
  agrees", and R is a peer, not a referee.

**Not covered, and why.** The LMM orchestrator (module tabled by author
ruling of 4 August) and the reliability orchestrator (a Phase 4 stub that
returns "not yet implemented").

### What this folder is NOT the only validation of

An earlier version of this section said a 2 August test inventory had found
coverage across the procedure library "uneven rather than complete". That
was superseded on 4 August and is withdrawn. It understated the plugin.

**The statistics themselves are already externally validated, and not by
this folder.** `plugin/dev/tests/` holds the library's own suites, and the
numeric literals in them were transcribed from R or scipy, never from the
plugin's own output — the rule that makes a suite a test rather than a
photograph. Provenance, including interpreter versions, is recorded in
`plugin/dev/tests/REFERENCE_PROVENANCE.md`.

- `stats/eml-inferential.praat` — **28 of 28 procedures under an external
  oracle**, 442 passing checks (409 from eight base-R scripts, 33 from a
  scikit-posthocs Dunn verifier).

  <!-- This 442 is the PRIMITIVES suite under plugin/dev/tests/. It is not
  the validate/ figure and does not move when validate/ changes. On 6 Aug
  2026 a global search-and-replace aimed at V1's stale validate/ counts
  overwrote it with the validate/ headline and destroyed the 409 + 33
  breakdown, leaving an orphaned parenthesis — in a document whose subject
  is count accuracy. Restored, and flagged here so the next sweep does not
  do it again. --> Welch and Student *t*, Mann-Whitney,
  one-way and two-way ANOVA, Tukey, Kruskal-Wallis, Dunn, Scheffé,
  Pearson and Spearman, linear regression, Theil-Sen, Shapiro-Wilk,
  Bonferroni, Holm, Benjamini-Hochberg, Cohen's *d*, rank-biserial. Four
  of the 28 are private helpers reached only through oracled callers.
- `stats/eml-core-descriptive.praat` — asserted against closed-form
  analytic values. For mean, median, variance, SD, percentile and MAD the
  closed form is the stronger oracle; R would only re-derive the same
  arithmetic. Validated, by a different and adequate method.

The measurement above is from `audit/reports/CORRECTION_coverage_2026-08-04.md`,
which also withdraws an earlier "5% externally validated" figure produced by
grepping Praat procedure names inside the `.R` files. That grep counted
*mentions*, not oracles, and was wrong.

### The gap this folder exists to close

**`stats/eml-analysis.praat` — 14 orchestrators, none with a direct
external oracle.** These procedures do no arithmetic. They pull columns
out of a Table, decide which already-validated primitive to call, hand it
arguments, and assemble the printed report. Seven are touched by
`dev/tests/phase2/test-workflow-verification.praat`, but that suite checks
that report procedures emit the expected *markers* — headings, spacing,
Info persistence — not that the right value lands under the right one.

That layer is where finding **D15** lived: Cohen's *d*z and the
matched-pairs rank-biserial were both individually R-validated and
passing, and the plugin still printed the rank statistic under the heading
*Paired t-test*. Every primitive green, the assembly wrong. A
primitive-level suite cannot reach that by construction, which is the
argument for this folder existing at all.

Scripts `v01`–`v06` cover four of the fourteen: pairwise, RM-ANOVA,
Friedman, and paired *t*. Scripts `v08`–`v15` cover the remaining eight —
two-group, ANOVA with Tukey, Kruskal-Wallis with Dunn, two-way,
correlation, regression, descriptive, and normality. Two of the fourteen
are out of scope: the LMM orchestrator (module tabled by author ruling of
4 August) and the reliability orchestrator (a Phase 4 stub that returns
"not yet implemented").

**Not a validation of the graphing layer.** Figure defects (D88, D89, D90)
are recorded in the audit log and are not testable from R.

---

## For an independent reviewer

The useful question is not whether the numbers agree — they do, and you can
confirm that in one command. It is whether the *comparisons are the right
ones*:

- Are the tolerances defensible given what the plugin displays?
- Is the Greenhouse-Geisser implementation in `helpers.R` the standard one,
  and does the `aov()` cross-check in `v03` genuinely constitute an
  independent path?
- Is the rank-biserial convention in `helpers.R` the one that makes the D15
  claim correct? The whole finding turns on that.
- Are the red-path cases in `v07` the ones worth having, and what is missing?

Four conventions in particular are asserted rather than derived, and each
would change numbers across several scripts if you disagree:

- **Rank-biserial sign.** `rank_biserial_indep` uses (*U*₁ − *U*₂)/(*n*₁*n*₂),
  positive when group 1 dominates, so its sign agrees with Cohen's *d*. The
  convention 1 − 2*U*₁/(*n*₁*n*₂) gives the opposite sign throughout v08 and
  v10.
- **Skewness and kurtosis.** The sample-corrected G1 and G2, matching what
  `@emlSkewness` and `@emlKurtosis` compute. Not the population moments,
  which differ in the second decimal on v14's data — inside the printed
  precision.
- **Quartiles.** R's `quantile` type 7. Type 6 differs in the third decimal
  on the same column.
- **Dunn's test.** Dunn (1964) with the standard tie correction. The
  plugin's own suite checks its Dunn against scikit-posthocs; `helpers.R` is
  a third path in base R, and all three agree to four decimals on v10.

The four failing checks in `v07` are also worth arguing with. Each asserts
that a plugin behaviour is wrong. If you think R2's uncommented *F*(2, 2) or
R6's silent row-drop is acceptable, say so — the finding, not the check, is
what would be wrong.

Disagreement on any of these is more valuable than a passing run.
