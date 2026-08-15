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

**Expect exit status 0, and expect the summary line to end `0 FAILED`.** All
checks passing, plus attestations reported separately on their own line and
not counted as checks.

**This document states no total, and that is the fix rather than an omission.**
Until 15 August 2026 this section opened with a figure, and so did the
repository README, `validate/README.md` at four separate sites, and the session
reports. On 14 August an audit found four of them carrying four different
numbers for this one suite — every one correct on the day it was typed, and all
four wrong against the live run, which had moved twice more by the end of that
week. A fifth correction would have restarted the same clock. A total is a
measurement of a thing that moves whenever a validator is added; zero failures
is a contract, which is why zero is the only figure this repository is now
allowed to write down. Everything else is generated from a specific run and
stamped with when it was measured:

```
Rscript validate/run_all.R | tee /tmp/suite.log
Rscript validate/tools/gen_counts.R /tmp/suite.log
```

`validate/tools/check_registry_counts.R` enforces it, and the shape of that
enforcement is the point: it fails on the *presence* of a total, which it can
decide from the documents alone in about a second, with no suite run and no
knowledge of what the right figure would be. The previous checker verified
written totals against a live run — correct, expensive, and powerless, since
knowing a document has drifted has never yet stopped a document from drifting.

Until 6 August 2026 this said "expect exit status 1", because R7 — the
small-range axis case — had never been driven and its placeholder failed on
purpose. R7 was described for a month as an axis case that had to be judged
from a rendered figure, and therefore belonged with the graphing work rather
than in an R suite. That was wrong: the draw procedures call no `beginPause:`,
so they run under `praat --run` with no X server, and an axis is a number. It
is driven now, and the suite has no designed failures left.

An **attestation** is a claim backed by a screenshot or a recorded
observation rather than by anything the script can evaluate. Most are in `v07`;
`v20` carries one, recording that its files came from the shipping
orchestrator rather than a harness. They print as `ATST`, are excluded from the
check count and from the exit status, and are listed separately so that a
report of *n* checks passed means *n* things were tested — not *n* minus
however many could never have failed.

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

This exists because two of the defects in this document were count claims that
I checked by eye and by `grep`, in a document whose subject is count accuracy —
including one where a line-based pattern missed a wrapped `TRUE)` and I
confidently contradicted a correct audit finding.

Its first version parsed every written total out of this document and the
repository README and diffed them against a live run. That version was correct
and it did not work. Diffing a written total against reality tells you the
document has drifted; it does not stop the drift, and it cost a full suite run
— several minutes — to say so, which is precisely why it was not run. By 14
August 2026 four documents carried four different figures and the checker had
been right about all of them for weeks.

It now enforces the opposite rule. **No front-door document may state a suite
total other than zero**, and the checker fails on the presence of one:

```
Rscript validate/tools/check_registry_counts.R
```

No suite run, no arguments, about a second. It reads `README.md`,
`START_HERE.md`, `validate/README.md` and this file, and reports the file, the
line and the offending text. The property that makes this different from what
it replaced is that **it never needs to know the true total** — it decides a
question about the documents, not about the suite, so it cannot itself fall out
of date while six branches are adding validators underneath it. It is
wrap-aware: the first draft walked past `the same move repeated 4058 / times`
in `validate/README.md` because the numeral and its noun sat on opposite sides
of a newline, so it now scans a two-line window as well as each line.

A line carrying `<!-- count-scope: ... -->` is exempt, and the comment has to
say what the number counts. That hatch is for the counts in this document that
are legitimately about something else — `v18`'s headless sweep, the primitives
suite under `plugin/dev/tests/`. It renders as nothing and reads as a
declaration, so a reviewer sees the claim of scope beside the number making it.
On 6 August 2026 a global search-and-replace aimed at this file's stale figures
overwrote the primitives suite's split with the `validate/` headline; the
marker is there so that number is visibly not ours.

Handed a run's log it does one thing more — it checks the run against itself:

```
Rscript validate/run_all.R | tee /tmp/suite.log
Rscript validate/tools/check_registry_counts.R /tmp/suite.log
```

The headline must agree with the `PASS`/`FAIL` lines it summarises and with the
by-script table beneath it, and the failure count must be zero. That is P4 of 6
August 2026 made permanent: the aggregate once summed to 460 against a headline
of 454, because one presentation counted attestations and the other did not.
Two presentations of one run must not disagree — and asking whether they agree,
like asking whether a document states a total, needs no external number.

### `validate/tools/gen_counts.R` — stock R

The other half of the same decision. It turns a run's log into the totals block
— headline, attestations, per-script table — stamped with the date, the commit
and the R version it was measured at, and writes it to standard output. Nothing
in this repository stores its result, because a stored copy is a stale total
with extra steps. Generate it when a report needs it; regenerate it when the
report is next revised.

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
growing. It refuses to run on a dirty `evidence/` tree. A preflight pass applies
every case to a copy before any suite runs; a `sed` pattern that no longer
matches is a **DEAD CASE** and exits 3, because a mutation that cannot fire is
not a pass. A case may opt out only by declaring a named `SKIPPABLE:<reason>`.
Restoration is by file copy under a terminating signal trap — the driver runs no
git command that writes — and is verified by byte-comparing every touched file
with its pre-run copy.

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

| Script | Covers | Input |
|---|---|---|
| `helpers.R` | Shared harness and the statistics base R lacks: Cohen's *d* and *d*z, *r* from *t*, matched-pairs rank-biserial, RM-ANOVA with Greenhouse-Geisser, Kendall's *W* | — |
| `v01_pairwise_welch_bonferroni.R` | *Pairwise comparisons* wrapper: Welch *t*, Bonferroni, Cohen's *d* | `evidence/csv/demo_3groups_input.csv` |
| `v02_pairwise_holm_differential.R` | The same wrapper run twice, one control apart, to separate an applied adjustment from a labelled one. Also asserts, rather than assumes, that the two captures differ only in the adjustment | `evidence/csv/demo_3groups_b_input.csv` |
| `v03_rm_anova_greenhouse_geisser.R` | Stats Wizard RM-ANOVA: *F*, GG ε, condition means, Holm post-hoc | `evidence/csv/demo_rm3_input.csv` |
| `v04_friedman.R` | Stats Wizard Friedman: χ², rank sums, Wilcoxon post-hoc, Holm on ties | `evidence/csv/demo_rm3_input.csv` |
| `v05_paired_t.R` | *Compare paired/repeated*: paired *t*, descriptives, and the graphs-side CSV export row | `evidence/csv/demo_paired_input.csv`, `evidence/csv/pairedLong_results_5aug.csv` |
| `v06_D15_effect_size_defect.R` | D15, now resolved: each paired test reports its own effect size | `evidence/csv/demo_paired_input.csv` |
| `v07_redpath_degenerate_inputs.R` (reported per case as R1–R7) | Red path: inputs that should fail or sit on a boundary. **All seven driven** as of 6 Aug 2026 | generated into `validate/redpath/` by the script itself |
| `v08_twogroup_orchestrator.R` | *Compare two groups*: Welch *t*, Mann-Whitney, Cohen's *d*, Hedges' *g*, rank-biserial | `evidence/csv/v08_twogroup_input.csv` |
| `v09_anova_tukey_orchestrator.R` | *Compare k groups (ANOVA)*: ANOVA table, eta-squared, Tukey matrix, pairwise *d* matrix | `evidence/csv/v09_anova_tukey_input.csv` |
| `v10_kruskal_dunn_orchestrator.R` | *Compare k groups (Kruskal-Wallis)*: *H*, epsilon-squared, mean ranks, Dunn *z* and adjusted *p*, rank-biserial matrix | `evidence/csv/v10_kw_dunn_input.csv` |
| `v11_twoway_orchestrator.R` | *Compare two-way (ANOVA)*: main effects, interaction, partial eta-squared | `evidence/csv/v11_twoway_input.csv` |
| `v12_correlation_orchestrator.R` | *Correlate two columns*: Pearson and Spearman with their *t* and df | `evidence/csv/v12_correlation_input.csv` |
| `v13_regression_orchestrator.R` | *Linear regression*: model, overall *F*, coefficient table, direction | `evidence/csv/v13_regression_input.csv` |
| `v14_descriptive_orchestrator.R` | *Describe Table column*: central tendency, dispersion, quartiles, shape, CI | `evidence/csv/v14_descriptive_input.csv` |
| `v15_normality_orchestrator.R` | *Check normality (all columns)*: three columns, and the parametric/nonparametric recommendation | `evidence/csv/v15_normality_input.csv` |
| `v16_csv_export.R` | The CSV export: every number against R, plus the structural assertions that make the file unambiguous to pivot | `evidence/csv_export/*.csv` |
| `v17_broom_parity.R` | The broom-shaped export: tidy / glance / augment / post-hoc / effect size against R, structurally and numerically | `evidence/csv_export/broom/` |
| `v20_shipping_anova_broom.R` | **CSV migration checkpoint 1.** The SHIPPING one-way ANOVA path (`@emlRunAnovaAnalysis`) in broom's three-file shape: tidy / glance / augment, plus post-hoc and effect sizes as their own frames. Column names AND order asserted against broom's documented contract; every value against base R | `evidence/csv_export/broom/shipping_anova_*` |
| `v21_shipping_paths_broom.R` | **CSV migration, paths 2-11.** The other ten shipping orchestrators in broom's three-file shape, every file written by the orchestrator the menu calls. Asserts that htest paths write NO augment, since broom has none for them, and that the regression augment carries broom's `.hat`, `.cooksd` and leverage-corrected `.std.resid` | `evidence/csv_export/broom/ship_*` |
| `v19_nist_strd.R` | **Tier C.** The plugin against NIST StRD certified values, scored in log relative error. Contributes checks only when the `.dat` files have been ingested; prints a loud SKIP otherwise | `evidence/nist/` |
| `v18_sweep_parity.R` | **Tier B.** One-way ANOVA, Tukey-Kramer and Kruskal-Wallis over a 16-case designed grid: k = 2/3/5, n per cell 3-200, balanced and 6:1 unbalanced, tie-free to heavily tied, 1:1 and 10:1 variance ratios | `evidence/sweep/` |
| `v22_homogeneity.R` | **Ruling 1 numerics.** Brown-Forsythe (median-centred Levene), Welch's *k*-sample *F*, and Games-Howell, over a 17-case grid including the *k* = 2 identity (Welch *F* = Welch *t*²), a +1e6 offset case, a skewed case that would catch a mean-centred "Brown-Forsythe", and eight red paths asserted by exact refusal string | `harness/homogeneity/out/` |
| `v23_qq_points.R` | **The Q-Q figure's own points.** Theoretical axis against `qnorm(ppoints(n, a = 3/8))`, sample axis against `sort(x)`, reference line against `lm()`, and *W* against `shapiro.test()` — so the figure and the reported test are bound to the same points. Also pins the Blom-vs-`qqnorm` plotting-position difference above n = 10, and asserts no temp Table leaks | `harness/qq_out/` |
| `v24_influence.R` | **Ruling 4(d).** Leverage, Cook's distance and the leverage-corrected standardised residual from `@emlOLSInfluence` against `hatvalues()`, `cooks.distance()` and `rstandard()`. Pins the OLD `resid/sigma` form as wrong, so reverting the augment site turns this red. Red paths include a leverage-1 row at both ulp neighbours | `evidence/influence/` |
| `v25_anova_showboth.R` | **Ruling 1 at the report level.** Two captures from the same committed input differing only in data column, so the conditional is asserted in BOTH directions. The ABSENT case carries the constraint: on data that does not trip the check the report must look as it did before the feature existed, and the primary *F* must still be `aov()`'s pooled *F* rather than `oneway.test()`'s | `evidence/info/v25_showboth_*` |
| `v26_twoway_caveat.R` | **Ruling 3(a).** The interaction caveat asserted in both directions from two committed two-way inputs, plus its placement under the table it qualifies rather than under the effect sizes (D98), plus the assertion that the three *F* values are identical whether the caveat fires or not | `evidence/info/v26_caveat_*` |
| `v27_empty_frames.R` | **D111 uniformity guard.** Every Table-consuming draw procedure, given no usable data, must fall back to a unit axis and draw the labelled empty frame with its own disclosure line. The histogram used to `goto` past its own `Axes:` and write a blank white page. Includes a STATIC check that no `goto` returns to the draw library — that construct is how the defect got in. Reads `harness/stress_out/`, so `harness/stress_graphs.sh` must run first | `harness/stress_out/` |
| `v28_column_type_guard.R` | **Column TYPE guard, all twelve orchestrators.** Praat has two column readers that disagree: the row-wise one returns undefined for a text cell, but `Report two-way anova:` numericises the column as a whole and substitutes each value's ALPHABETICAL RANK — so the two-way test reported F = 132.92, p = 6.9e-15 on a column of singers' names, and one bad cell in 48 moved a real F from 34.11 to 0.7356. Asserts the refusal by exact message, that the printed output is EMPTY on refusal (the failure was an empty `error$` beside a full table), and that every legitimate analysis still runs | `harness/coltype/` |
| `v29_figure_disclosure.R` | **The figure-disclosure ruling**, all ten draw procedures: Info window always, the figure only when Annotate is ticked, the user's subtitle never. Asserts the exact skipped-row count in house wording, both directions of the Annotate gate (the OFF direction is the ruling), an `emlSubtitle$` sentinel unchanged across 40 renders, clean data producing no disclosure at all, and that the disclosure box and the form's omnibus box never share a corner. Includes a STATIC ban on `emlSubtitle$ =` across **every** file in `plugin/graphs/`, in three rules: no self-referential append anywhere, no assignment inside any `@emlDraw*` procedure, and a pinned inventory of the legitimate sites so a new one must be argued for. Also covers the three over-cap defects: the grouped-scatter annotation budget, a bar chart's missing group versus a measured zero, and the sub-group ceiling, now 24 = 8 hues x 3 fill patterns. All 24 styles are asserted pairwise distinguishable FROM THE RENDERED IMAGE, per channel, in colour and greyscale -- not from the palette table, which is what let two duplicate slots survive undetected. A negative control with the pattern dimension removed reports 24 confusable pairs | `harness/disclosure/out/` |
| `v30_wizard_state.R` | **An error return keeps the user's columns.** The wizard printed "Nothing has been lost" and re-rendered from a column guess; a user who pressed Run without touching anything had a different analysis reported as theirs. Asserts from before/after Info captures that the fixed one never names a guessed column and runs nothing after the return, plus three source guards: the helper is defined once, no hand-written copy survives, and all 16 call sites are present | `evidence/walks/d117/` |
| `v31_gridmode.R` | **One canonical gridline encoding.** Two incompatible encodings — `1 Both / 2 Horizontal / 3 Vertical / 4 Off` for the seven continuous types, `1 Horizontal / 2 Off` for the seven categorical — shared ONE persisted key, so a scatter drawn with gridlines off left a histogram's dropdown blank and refusing OK, on disk and surviving a restart. Three types clamped by INDEX, so "Horizontal only" silently became "Off". Now one canonical encoding translated at the dialog. The load-bearing checks are the registry ones: the plugin refuses to LOAD if a future graph type omits its entry | `evidence/walks/gridmode/` |
| `v32_legend_geometry.R` | **The plot rectangle is what the user asked for.** The dimensions typed into the graphs form describe the DATA AREA, not the data area plus its furniture: if a legend carves space out of the 6 x 4 someone asked for, "make my figure square" stops being satisfiable, because the plot goes oblong while the file stays square. So the plot rectangle must be IDENTICAL in all five legend placements, and a legend that needs room outside it must grow the SAVED IMAGE instead. **205 renders, from two fixtures.** 42 are the legend matrix — three figure sizes including a square (5 x 5) and a short-and-wide (10 x 3), entry counts 0/1/3/12/24, one label 480 characters wide, colour and greyscale, and a no-legend control at every size — all with no `emlLegendPlacement` declared, which is the calling convention all thirteen graph types still use. The other 15 drive the five placements directly. **A further 46 put a REAL four-group post-hoc comparison matrix under the plot** — the panel `@emlDrawMatrixPanel` renders, populated by `@emlBridgeGroupComparison` from a one-way ANOVA with Tukey HSD — because a matrix occupies a band BELOW the plot and placement 3 wants a band below the plot too. 36 of them are the five placements again at twelve and twenty-four entries per size, each with a legend-free control; 10 are the red paths. **Every number is measured on the rendered PIXELS** by `harness/legend/measure.py`, which finds the frame by thresholding at 50% grey and taking the rows and columns whose longest dark run spans half the image — not read back from what the script believed it drew, because both sides of that comparison are computed by the same arithmetic and move together (v1.23 of `@emlDrawLegend` measured itself at one font size and drew itself at another, and it looked right). PINS: the plot frame is the same rectangle in every placement and at every entry count, in inches exactly and in pixels to within the one-pixel rounding a fractional-inch canvas forces; the measured frame plus the theme's own four margins equals the requested rectangle, in position as well as size; placements 1, 4 and 5 save exactly the requested inches at 300 dpi while 2 widens and 3 heightens; declaring nothing renders the same file as declaring placement 1, pixel for pixel; the square request gives a square file while its frame is 1081 x 1239 px and is not square; nothing is clipped at the canvas edge in any placement. **DISJOINTNESS** is the load-bearing pin of the matrix half, and it is asserted twice on independent evidence: the rectangle `@emlDrawLegend` reported and the band `@emlDrawMatrixPanel` was drawn into do not overlap, AND the count of dark pixels inside the matrix band is EXACTLY the count in the same figure drawn with no legend call — 17621, 16365 and 26149 at the three sizes, both ways, with no tolerance. Red paths: zero entries, one entry, a label wider than the whole frame, and — where the defect was — a matrix set up by a caller that publishes no `totalCanvasHeight`, a matrix as deep as the figure above it, and a matrix measured and suppressed. `totalCanvasHeight` is a FORM local and `@emlInitDrawingDefaults` does not set it, so a standalone script or PraatGen companion asking for placement 3 drew its legend band straight through the panel: 11636 dark pixels of legend inside the matrix band on the default figure, 25564 on the twelve-group one, overprinting the omnibus line and the subtitle naming the correction. Closed in `eml-graph-procedures.praat` v3.29; the open numbers are kept as the guard, and the checks here go red against v3.28. **THE MISSING ASSERTION, ADDED 9 AUG 2026: does the key sit on the data.** Everything above is measured on a GEOMETRY RIG (`harness/legend/case.praat`) that draws two violins under a legend of up to twenty-four entries with the corner hardcoded to `"top-left"`. Every rectangle it measures is correct and none of it is a demonstration of a legend: the key named ten groups that were not in the figure, so "does the legend cover the data it names" was not merely untested but inexpressible; the forced corner meant no part of `@emlPlaceElements` was exercised, so no claim about which corner the product picks could be supported; and on a grouped violin the x-axis already carries the category labels, so the key is redundant furniture there anyway. `harness/legend/series_case.praat` is the fixture that can be wrong: **102 further renders** of a k-series LINE CHART (`@emlDrawTimeSeries`) and a k-group GROUPED SCATTER (`@emlDrawScatterPlot`), driven through the product's own graph-level procedures, where the lines cross so position does not name them, **the number of legend entries IS the number of series** (asserted on three independently produced numbers -- the table's k, the draw procedure's resolved `nGroups`, and the `legendN` `@emlDrawLegend` was handed), and the corner is whatever `@emlPlaceElements` scored -- the fixture names none, and that is checked in the source. Coverage is measured between TWO RENDERS: the figure, and the SAME figure ON THE SAME AXIS with `emlLegendPlacement = 5` so the legend is not drawn, then a count of pixels that are data-coloured in the control and changed in the treatment (`harness/legend/measure_cover.py`; data ink is identified by CHROMA, because every piece of the figure's furniture is achromatic, and the count is taken inside the plot frame because Praat subpixel-antialiases TEXT and the resulting orange/blue glyph fringes are more chromatic than an antialiased data line). PINS, recorded as numbers so a change moves a visible figure: on the 6 x 4 line chart, **1348 data pixels covered with no headroom pass and 0 with one** at five series; 20932 and 7385 at twelve. Where `@emlComputeAnnotationHeadroom` reports the band was afforded the overlap is required to be EXACTLY zero, and where it was capped the figure is required to SAY so and to name the way out; both populations are asserted non-empty. The headroom pass is required never to cover MORE than no pass, over every pair of arms, which holds whichever way that work lands. WHICH CORNER THE PRODUCT ACTUALLY CHOOSES is recorded rather than guessed: the line chart takes **top-left** at every size, the grouped scatter takes **bottom-right**, and the scatter moves to **bottom-left** when the headroom pass runs -- which is the left/right trade `@emlPlaceElements`' own comment predicts and bounds, and the bound (nothing crosses between top and bottom) is asserted over all eighteen pairs. The five placements are re-driven on this real path too, and placement 4 is required to change **nothing at all** in the main file. `harness/legend/` also stopped depending on `harness/stress_cases/_prelude.praat`, which names the plugin by ABSOLUTE path and so silently loaded `/home/claude/EMLPraatTools/plugin` from any tree it was copied into; it now has its own prelude with relative includes, plus an `EML_PLUGIN_ROOT` override that stages the cases against another tree. Static, in the shape of `v27`'s `goto` ban: every viewport a legend renderer selects is the rectangle it was HANDED — its own parameters or the theme's inner rectangle, never a page coordinate, never the figure-level drawn extent — plus the pinned inventory of the four procedures allowed to grow the saved figure, and `@emlAssertFullViewport` pinned as the one statement it is. **Written across the change**: the placement work landed in `eml-graph-procedures.praat` while this file was being written, so the fixture rendered the matrix twice, three hours apart, and both sets of numbers are in the file — what is asserted is the tree it runs against, what is recorded beside it is what the number was before. That is how D135 (the over-wide label overhanging the frame), the empty-legend box and the 30.96-inch layout estimate are pinned. **`harness/legend/run.sh` must run first**; the script HARD STOPS on a missing artefact rather than skipping, for the reason `v27` gives | `harness/legend/out/` |
| `v33_exclusion_parity.R` | **The two bridges exclude the same rows.** A figure and the analysis beside it are drawn from one table by two different readers, and if they disagree about which rows are usable the caption describes a different sample than the plot. One number against one number, per draw procedure, per fixture, both a clean and a dirty arm. The dirty arm is required to actually exclude something — two readers that both drop everything, or both drop nothing, agree perfectly, and the harness hit exactly that vacuous pass on its first run. Seven procedures x two arms are declared through `eml_census`, so a procedure dropped from the harness fails loudly instead of shrinking the check. `harness/parity/run.sh` first | `harness/parity/out/` |
| `v34_label_escape.R` | **A figure's auto-composed title keeps its special characters.** Praat's drawn text treats `%`, `#` and `^` as style escapes, so `@emlSanitizeLabel` escapes them — and it ran a second time over its own output, which destroyed the character instead of protecting it: `Jitter (%)` rendered as `Jitter ( )`. The procedure is now idempotent (normalise, then escape) and this pins the round trip | `harness/disclosure/out/` |
| `v35_assembly.R` | **The plugin ASSEMBLED, not its parts.** On 11 Aug 2026 fifteen menu entry points were dead at parse time — a duplicated `include` of a file containing `label` statements — while the whole R suite, the stress and disclosure harnesses and both round trips were green. Nothing had ever loaded `scripts/eml-lib.praat`, which is what all sixteen shipped wrappers load: the suites exercised a composition no user runs. Asserts every entry point parses, and that the graphs workflow advances through its real dialogs when handed a Table — in ORDER, not merely present. All 26 wrappers are declared through `eml_census`: the old ">= 20" floor passes while six are missing. `harness/wrappers/run.sh` and `harness/gui_e2e/run.sh` first | `harness/wrappers/out/`, `harness/gui_e2e/out/` |
| `v36_stress_output.R` | **The 29 stress cases that were exercised but not validated.** `v27` asserts on the ten `empty_*` cases because that is what it is about; the other 29 — the ones named after the pathologies — had only the driver's smoke-test verdict, "it rendered and Praat did not error". It could not have been written earlier: 22 of the 39 cases called `randomGauss` with no seed, so their ink and chroma churned every run and no value was pinnable. Seeding them (§14) is what unblocked this. Covers all 39 with a declared inventory, pins ink and chroma with a stated tolerance, and asserts what each case is NAMED for — the skipped-row count `violin_undefined` discloses, derived from the fixture rather than copied from the log; the bin count in `hist_1bin` / `hist_200bins` read off the case's own draw call; `violin_hugevalues` and `violin_tinyvalues` as each other's controls across twenty-one orders of magnitude; `legend_cap`'s four box slacks recomputed from the frame. Records two facts nothing had: eight violin pathologies disclose NOTHING (asserted as silence, not assumed), and `violin_longlabels` is the only case whose canvas exceeds 1200 px. `harness/stress_graphs.sh` first | `harness/stress_out/` |
| `v37_determinism.R` | **The harness no longer grades its own homework.** `harness/determinism/run.sh` renders each of the ten Table-consuming draw procedures twice in two separate Praat processes and compares the PNGs — and it was the one harness no R script read, so the 10/10 byte-identical figure was the harness reporting on itself. Determinism is what licenses reading a diff of two renders as a regression, so every byte-for-byte claim downstream inherited that. The driver now emits `DETERMINISM.tsv`; this asserts all ten types present by name, both passes non-empty and equal in size, the logs free of Praat errors — and **re-compares the two PNGs itself, byte for byte off disk**, rather than reading the driver's verdict column. Verified: one flipped byte in one PNG, file length unchanged, is invisible to the verdict and to every size check, and fails here | `harness/determinism/out/` |
| `coverage.R` (reported as `v38`) | **For everything a driver renders, is there some check on it?** Runs LAST in the suite and is the only file here whose unit is the ARTEFACT rather than the validator. Every other check is scoped to a subset its author named, so a population nothing named passes everything: on 12 Aug 2026 the stress artefact held 39 cases of which 29 were asserted on by nothing, for weeks, with the suite green. `eml_census` cannot see that -- `v27` reads all 39 rows and claims ten ON PURPOSE. The map of validator-to-cases is deliberately NOT written down, because a hand-maintained list is one more thing that can disagree with reality; each validator calls `eml_claim()` with the same vector its own checks loop over, and this file reads each artefact's population off disk itself, so both sides come from somewhere other than here. Distinguishes three failures: a case nothing claims, an artefact NO validator reads (the largest form, and what `harness/determinism/out` was until `v37`), and a validator claiming a case never rendered. Names the claimants, so "covered" reads as "covered by what". Verified by reproducing the history: with `v36` removed it fails and names the 29 | all five harness artefacts |

**This table had a fourth column, headed *Checks*, and it was removed on 15
August 2026 for the reason the headline total was removed.** Thirty-nine
hand-maintained figures, each true on the day it was written and each free to
drift the moment its script gained an assertion, in a document whose subject is
count accuracy. It is also the column that made the table look like an
inventory when it is not one: it stops at `v37`, and the validators added since
have no row here at all. **Treat this table as the narrative index — what each
script is *for*, and why the convention it encodes was chosen.** The inventory,
complete and current by construction, is what `validate/tools/gen_counts.R`
prints from a run: every script that reported, with its passes, its checks and
its attestations, stamped with the commit they were measured at.

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
provenance behind any of its checks. What it establishes is that the
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

**Not converted to the broom shape, but EXPORTABLE since 14 August 2026:
`@emlRunDescriptiveAnalysis`.**
Recorded here on 13 August 2026 because nothing said so and the omission reads
like an oversight. Two reasons, either sufficient. First, broom has no `tidy`
method for a summary of a vector, and eleven of the fifteen quantities the
procedure produces -- mean, median, sd, variance, sem, q1, q3, iqr, min, max,
range -- have no column in the vocabulary `eml-result-writer.praat` enforces;
declaring it would mean inventing eleven non-broom names and then defending
them in the parity check as broom-shaped. Second, and decisively:
`harness/broom_cases/contamination_probe.praat` uses this procedure as the
canonical UNCONVERTED path, to prove a converted analysis does not leak its
declaration into the next one. Converting it breaks that probe. The legacy
long format is the right container for a heterogeneous bag of named scalars.

**AUTHOR RULING, 14 August 2026, correcting the last clause of the above.**
That paragraph used to end "and its export is correctly gated off in the
wizard (`wizCanExport` stays 0)". Both reasons for not converting are still
right; the conclusion drawn from them was not. Describe and normality must be
able to save. `@emlRunDescriptiveAnalysis` now fills the LEGACY buffer through
`@emlCSVAddDescriptiveRow` -- sixteen statistics, no invented broom column
names -- and the wizard sets `wizCanExport = 1`. It still does not declare, so
`contamination_probe.praat` keeps its canonical unconverted subject and the
second reason above stands untouched.

A first attempt DID declare into tidy, and would have shipped a file carrying
`term` and `method` and nothing else: `@eml_orderedCols` walks `emlVocabTidy$`
as a WHITELIST and drops what is not in it, without comment. The first reason
recorded here on 13 August is what stopped that, which is the argument for
writing reasons down rather than conclusions.

`validate/v49_every_path_exports.R` now enumerates every terminal branch of
the wizard and every analysis wrapper out of the source, and fails if any of
them cannot reach the export step. It found a fourth gap nobody had named:
`scripts/eml-check-normality.praat`, the standalone menu wrapper, ran an
orchestrator that had declared correctly for weeks and then offered the user
no way to keep the result.

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
  oracle**, 442 passing checks (409 from eight base-R scripts, 33 from a <!-- count-scope: plugin/dev/tests primitives suite, not validate/ -->
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

**Only partly a validation of the graphing layer.** `v23` is the first
R-side check of anything drawn: it reads the Q-Q figure's own plotted point
pairs and binds them to the same numbers the reported *W* came from. The
annotation layer — `@emlBridgeGroupComparison` and everything it renders onto
a figure — is still uncovered, and is scheduled to gain coverage together
with the Ruling 2 unification, which requires the harness to land with the
change rather than after it. Purely visual defects (D88, D89, D90) remain
recorded in the audit log and are not testable from R.

### Refused permanently, with the reason on record

**Durbin–Watson.** Not implemented, and not to be implemented. Two reasons,
the second being the binding one:

1. Its *p*-value needs eigenvalues, and `stats/eml-linalg.praat` has no eigen
   routine.
2. **The statistic is order-dependent and the plugin's Tables carry no
   ordering semantics.** On `practice_hrs_wk` it would report autocorrelation
   in *spreadsheet row order* — a number that looks meaningful, is not, and
   gives no signal to the user that it is not. Adding an eigen routine would
   fix reason 1 and leave reason 2 exactly where it is.

### What a clean clone structurally cannot show — finding P1

**Finding P1 (file modes) cannot be validated from this repository, and it is
recorded here so that its absence from every green run is not read as its
absence from the product.** Thirteen of the twenty-one files in
`plugin/scripts/` were mode `0600` in the built tree, which makes the plugin
unreadable to any account other than the one that installed it. Git records
only the executable bit. The permission bits therefore do not survive a commit,
do not appear in a `git diff`, and cannot be asserted by anything in this
folder: a checker written here would read the modes of a checkout, which are
whatever the cloning umask made them, and would pass on a clone of a defective
package.

The 14 August 2026 audit confirmed both halves of that. The clone it examined
was clean — every file `0644` — and the audit's verdict was that the check
belongs to the packaging step rather than to the repository. So the discipline
is `chmod 0644` across the tree before zipping, and verification **on the built
artefact**, which is the only place the question is answerable. A green suite
here says nothing about it either way, and is not supposed to.

### Documented gaps, ruled out of Phase One rather than overlooked

- **Histogram with normal overlay** beside the Q-Q. Ruled out on the
  convention argument: the Q-Q is the normality figure in R's standard
  diagnostic set, and `Shapiro–Wilk` + Q-Q is the pairing a reviewer expects.
  Revisitable on practitioner feedback.
- **`Describe Table column` has no visual output** and no completion dialog
  to hang one on. Adding one means a new dialog, a new include of the graph
  layer, and a column picker. Ruled a Phase One gap, not a Phase One task.

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
