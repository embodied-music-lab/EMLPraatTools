# Phase One audit — EML Praat Tools

Ian Howell — Embodied Music Lab — 6 August 2026

Every claim in this document was checked against the code in this repository
on the date above. Nothing is carried over from a status column, a fix
comment, or a previous summary. Where a claim could not be settled by reading
the code, it says so instead of guessing.

**Phase Two is multiple regression and linear mixed models. Nothing else.**
Everything in this document is Phase One work.

---

## 1. State, verified

```
HEAD                    eaeec4a  (origin/main e813573 + this audit)
working tree            clean
validation suite        893 checks, 893 passed, 0 FAILED, exit 0
                        7 attestations, excluded from the count
registry counter        0 mismatches against a live run
check_wired.sh          1 unreachable module (eml-result-writer.praat)
check_calls.py          1 script with unresolvable @calls (eml-tutorial.praat)
mutation driver         7 mutations, 7 detected, clean restoration
graph stress            38 cases, 0 aborts, 1 BLANK_FRAME (violin_zerovar)
NIST StRD               11 of 11 ANOVA datasets, plugin matches or beats base R
```

The statistics layer is in good shape and the evidence for that is strong.
Everything below concerns the layers around it: what gets printed, what gets
exported, what gets drawn, and what the forms do.

---

## 2. Two false closures, in opposite directions

This audit was triggered by a closure that turned out to be false. Checking it
produced a second error in the other direction. Both are recorded here because
the pattern matters more than either instance.

**D99** was closed with the note "procedure name gone from user-facing text".
The fix touched `@emlOneWayAnova`. **Thirty-nine other sites still leak it**,
including `emlKruskalWallis: need >= 2 groups, got 1`. The finding was written
about the codebase; the test touched one call site.

**Fifteen CSV findings** were then reopened wholesale, on the belief that "the
CSV rewrite" meant `eml-result-writer.praat` — which no shipping script
reaches. That was wrong. There were two pieces of CSV work dated the same day:

- **Rewrite A** rewrote `@emlCSVInit` / `@emlCSVAdd` / `@emlCSVWrite` in
  `stats/eml-output.praat` to the schema `table,analysis,term,term_type,field,value`,
  and rewrote every call site with them. It is live and reachable.
- **Rewrite B** is `eml-result-writer.praat`, the broom-style writer. It is
  reachable only from a test harness, and is a deferred enhancement rather
  than evidence for anything.

Re-verified one by one against rewrite A: **nine are genuinely fixed**
(D19 D23 D24 D34 D45 D46 D54 D55 D76); **six are not** (D18 D37 D39 D41 D65 D66).

**Two comments in the shipped code assert fixes that were never made** —
`eml-output.praat:991-993` and `eml-annotation-procedures.praat:3946`. Both are
now filed as defects in their own right (D105, D106), because a reader
auditing this repo would otherwise trust them.

### The standard

A finding is resolved only when a user running the shipped plugin cannot
reproduce it, demonstrated against the emitting code. Not against a fix
comment. Not against a module existing. Not against a test that touches one
call site of many.

`validate/tools/check_wired.sh` and `validate/tools/check_calls.py` enforce the
mechanical half — nothing unreachable, and no `@call` that resolves to nothing
at run time. They would not have caught either error above. Nothing mechanical
would have.

---

## 3. The count

```
findings on file                                        109
  resolved, re-verified against the emitting code        23
  LIVE                                                   80
  misfiled / not defects (D2, D14, D31, D80, D81)         5
  needs a rendered figure to settle (D84)                 1
```

**Eighty live.** Eight of them (D102–D109) were found during this pass and had
no finding covering them. D92 and D93 sit inside the resolved 23 but are
flagged in their rows as not re-verifiable by static inspection — one needs a
rendered figure, the other a GUI walk.

Every one of the 69 rows previously marked LIVE was re-read against the current
code. **None had been incidentally fixed.** One (D83) is half fixed.

---

## 4. The work, clustered by what you touch

Organised by the file and mechanism a fix lands in, **not** by severity. A
severity list defers the small items forever; a cluster list gets them done in
the same pass as the large one beside them, because they are the same edit
session. Every live finding appears in exactly one cluster. Nothing is parked.

### C1 · Finish the CSV export — 7 findings

`stats/eml-output.praat`, `graphs/eml-annotation-procedures.praat`, `scripts/eml-wizard.praat`

Rewrite A fixed the schema and nine findings with it. Six survive, and they are
the ones about *reaching* the exporter rather than its format.

| | |
|---|---|
| **D66** | `emlRunPairwiseAnalysis`, `emlRunRepeatedMeasuresAnalysis` and `emlRunFriedmanAnalysis` call `@emlCSVInit` and never add a row (`eml-analysis.praat:422, 1535, 1613`). Export from those three is structurally incapable of succeeding. The truthful failure message was added to `@emlWrapperExportCSV` only; the wizard still says "Could not write CSV file." (`eml-wizard.praat:1775`) |
| **D65** | Draw on a k≥3 parametric result routes through `@emlReportAnovaComparison` regardless of what the user actually ran (`eml-annotation-procedures.praat:2481, 2521`), so a Pairwise-Welch user's export is ANOVA/Tukey |
| **D41** | The three two-way rows emit no `effect_label` (`:3963, 3972, 3981`) |
| **D37** | The two-way Info block prints no N of any kind (`:3870`); only the CSV got it |
| **D18** | Draw path proposes `<table>_results` from the intermediate table (`eml-graphs-form.praat:5801`) |
| **D39** | The Stats Wizard still defaults exports to `defaultDirectory$` (`eml-wizard.praat:1762`) — the plugin's own install folder |
| **D104** | `@emlCSVInit` runs once per orchestrator but the correlation reporter is re-invoked per group without re-init, so grouped exports accumulate overall + per-group rows in one file |

**Not in this cluster:** wiring `eml-result-writer.praat`. That is a format
migration, it is validated by v17's 48 checks, and it can wait. The seven above
cannot, because three of them mean the user gets no file or the wrong file.

### C2 · The `emlShowExplanations` gate — 4 findings

`stats/eml-output.praat:63`, `graphs/eml-graphs-form.praat:794`

One variable, defaulting to 0, that wrappers never set and the graphs workflow
sets to 1 and **never resets**.

| | |
|---|---|
| **D102** | *(new)* Because it is never reset, every analysis report after any Draw becomes verbose for the rest of the session. **Report content is order-dependent.** |
| **D44** | R² is printed only when the gate is open, so the regression report usually omits it |
| **D42** | Two-way prints without glosses while the graph-path two-group block prints with them |
| **D13** | The mean-difference direction sentence is gated, so `Mean difference` prints bare with no `(G1 − G2)` |

D102 is the root and makes the other three intermittent rather than absent,
which is worse. Fix the reset and the gate default together.

### C3 · p-value formatting — 5 findings

`stats/eml-output.praat` (`@emlFormatP`), `stats/eml-analysis.praat`, `graphs/eml-annotation-procedures.praat`

| | |
|---|---|
| **D85** | The whole repeated-measures path bypasses `@emlFormatP` and uses `fixed$ (p, 4)` at `eml-analysis.praat:1549, 1553, 1626, 1733, 1737`, which is why p-values print as 25–29 place decimal strings |
| **D35** | 5.8e-07, 2.1e-13 and 3.0e-04 all render `p < .001` in the two-way block — nine orders of magnitude flattened to one string |
| **D28** | Same flooring in Kruskal-Wallis, with no exact-p line anywhere |
| **D9** | The p row prints its label twice, at 10 sites, because `@emlFormatP` returns a string already prefixed `"p = "` and has no bare form |
| **D56** | Regression coefficient table puts that same prefixed string under a numeric-aligned `p` column header |

One change to `@emlFormatP` — add a `.bare$` output and an exact-value
companion — plus routing the RM path through it, closes all five. **Note:** not
a token swap; the five RM sites need restructuring because of the prefix.

### C4 · The graph annotation bridge — 9 findings

`graphs/eml-graphs-form.praat`, `graphs/eml-annotation-procedures.praat`

The bridge cannot carry a second factor, and cannot carry which test or
correction was actually run. Everything here follows from those two facts.

| | |
|---|---|
| **D33** | Draw annotates a two-way design with a two-group Welch *t* on one marginal and labels it a Two-Group block |
| **D32** | The preset bridge has no `emlGraphsPresetSubgroupCol$`, so the second factor is silently dropped |
| **D107** | *(new)* The D32 column-guessing fix landed in the non-preset branch (`:4422`) but not the preset branch (`:4396`) — which is the branch the two-way wrapper takes |
| **D63** | `@emlBridgeGroupComparison` takes no result or method, so a Welch+Bonferroni analysis draws as ANOVA/Tukey |
| **D64** | `.correction$` is consumed only in the Dunn branch (`:2001`); the parametric branch never reads it |
| **D108** | *(new)* `emlGraphsPresetCorrection$` was added so wrappers could carry their adjustment method through, and does seed the dialog — but on the parametric path the seeded value is never read. The wrapper advertises fidelity it does not have |
| **D103** | *(new)* `prev_scatterRegressionLine` overwrites the preset at `:3345` *after* the bridge sets it at `:1021`, so the second and later scatter in a session silently discards the wrapper's choice. Same clobber for dot size, formula, dots |
| **D25** | `Adjustment method` is offered unconditionally at 6 dialog sites but is inert for parametric k≥3 |
| **D26** | `eml-compare-kw.praat:68` hardcodes both post-hoc arguments; the form has no field for them |

This is the largest cluster and the one most likely to produce a wrong figure
in front of a reviewer. D33 and D107 together mean a two-way design gets drawn
and annotated as something it is not.

### C5 · Repeated measures in the Stats Wizard — 4 findings

`scripts/eml-wizard.praat`, `stats/eml-analysis.praat`

A single chain a user hits in order.

| | |
|---|---|
| **D82** | `Condition 1/2/3` default to option indices 2/3/4 against a list whose item 1 is "(none)", so they take table columns 1–3 — typically the subject ID column first. No type filter, no `@emlGuessColumnRoles` call (`eml-wizard.praat:971, 976, 981`) |
| **D83** | Which then fails with "Need at least 2 complete-case subjects" on complete data (`eml-analysis.praat:1232`). *Half fixed:* the session is no longer discarded (`eml-wizard.praat:1068`), but the `goto` returns to the same page with the same broken defaults, so accepting them again reproduces it |
| **D87** | RM and Friedman set `wizCanDraw = 0`, and CSV export shares that one flag, so repeated-measures results can be neither graphed nor exported (`:1730-1755`) |
| **D86** | No effect size at all on the RM path: `emlRMAnovaTest` computes `.ssCond`/`.ssErr` but exposes no η², and there is no Kendall's W anywhere |

D82 and D83 must be fixed together; fixing the message without the defaults
leaves a loop.

### C6 · Values already computed but never printed — 10 findings

Almost all of these are report plumbing over numbers the engine already has.
Cheap, and each one is a thing a reviewer will notice is missing.

| | |
|---|---|
| **D36** | No cell or marginal means on a significant interaction — `@emlTwoWayAnova` already builds `.cellLabel$[]`, `.cellN[]`, `.cellMean[]` (`eml-inferential.praat:2793-2832`) |
| **D22** | Tukey prints p only; `.qCritical` (`:2178`) and signed `meanDiff##` (`:2157`) already exist, so the CI needs no new numerics |
| **D69** | Pairwise prints adjusted p only; `emlPairwiseT.rawP#` exists (`:3611`) and is never printed |
| **D68** | Pairwise prints no t and no df — and this one *is* engine work: `emlPairwiseT` never stores per-pair df |
| **D67** | Pairwise reports no n, mean or SD per group |
| **D70** | No significance marker and no alpha echoed |
| **D71** | Cohen's d matrix is antisymmetric with no row-minus-column note |
| **D12** | No CI on the mean difference; `emlTTest` exposes no `.ciLower`/`.ciUpper` |
| **D50** | No CI on r; no Fisher-z anywhere |
| **D57** | No CI on regression coefficients — now additive (two `@emlCSVAdd` rows) since the schema change |

### C7 · Assumption checking — 3 findings

| | |
|---|---|
| **D20** | **No variance-homogeneity check anywhere.** No Levene, no Bartlett, no Brown-Forsythe, no Games-Howell. `@emlReportAnovaComparison` runs Fisher one-way + pooled Tukey unconditionally, and the plugin's own demo data violates the assumption. Welch exists only for two groups |
| **D58** | No regression diagnostics: no residual normality, no leverage, no Durbin-Watson |
| **D53** | Correlation offers Pearson/Spearman/Both with no normality check and no guidance; the one hint is post-hoc and gated behind `emlShowExplanations` |

D20 is the single most substantive statistical gap in the plugin and the one a
peer reviewer is most likely to raise.

### C8 · Column-role guessing — 3 findings

`stats/eml-extract.praat`

| | |
|---|---|
| **D77** | The time-role regex `pre\|post\|rep\|day\|…` claims a column before other roles are settled (`:2116, 2210`); all three consumers read it |
| **D78** | Fallback guard is `if .col <> .dataIdx and .groupIdx = 0` with no `.taken[]` consultation, and `groupIdx` is never marked taken (`:2245`) |
| **D47** | Correlation's Group column offers every column with no distinct-count or type filter, and does not exclude X and Y (`eml-correlate.praat:55`) |

### C9 · Display strings and typography — 12 findings

Individually one-line, collectively the thing that makes the output look
unfinished. Doing them as one pass costs a fraction of doing them one at a
time, which is exactly why they must not go on a low-priority list.

| | |
|---|---|
| **D6** | Underscores stripped for display at 78 call sites, so `F0_Hz` prints as `F0 Hz` and no longer names a real column |
| **D16** | `\_% prints %` help line, byte-identical at 13 sites, while `emlSanitizeLabel` uses the correct `"\% "` |
| **D79** | Bare `_sub` and `%F_0` in `comment:` at the same 13 sites |
| **D29** | `e2` printed for epsilon-squared with no `\ep`/superscript escape |
| **D30** | Grey `{0.55, 0.55, 0.55}` at ~3.3:1 on white — under WCAG AA |
| **D59** | `Y = slope x X + intercept` uses a letter `x` as the multiplication sign, in the form and in the Info equation |
| **D62** | `Variance explained` printed with the same layout as `R-squared`, so they read as two different quantities |
| **D73** | `emlCapitalizeLabel` has no unit-token heuristic, at ~14 label sites |
| **D74** | `--- Options ---` as a section marker |
| **D75** | Adjustment method interpolated raw and lowercase: `bonferroni`, `bh` |
| **D89** | Graph title defaults to empty and is never composed from the table and column names |
| **D90** | Reshaped long tables name their columns `Subject`/`Condition`/`Value` literally, and the axis labels are derived from those |

### C10 · Form state and navigation — 7 findings

| | |
|---|---|
| **D52** | `Clear Info window` is a literal `boolean: … , 0` in the shared form (`eml-output.praat:844`), so it resets on every `New` — 11 call sites in 9 wrappers |
| **D27** | Info window header carries no origin or correction, always appends, and every Draw re-reports |
| **D43** | `Title` field precedes the column mapping and is never composed |
| **D51** | `emlGraphsPresetRegressionLine` is never set by the correlate wrapper, and the line only appears when `AnalysisType >= 2` |
| **D61** | `eml-regress.praat:5` promises "with Theil-Sen robust alternative"; the file never calls it, and the only reachable path requires `spearman` while the wrapper hardcodes `pearson`. Separately the scatter menu labels `Both` ambiguously |
| **D60** | `@emlComputeAxisRange` takes `.isPercentage` and would clamp to 0–100, but **every** call site passes 0 |
| **D72** | The n.s. dash and the diagonal dash are both literal `—`; the legend that would disambiguate is gated on `annotShowEffect`, which defaults to 0 |

### C11 · Disclosure and guidance in the reports — 9 findings

| | |
|---|---|
| **D5** | No estimator conventions disclosed anywhere — quartile method, ddof, tie handling |
| **D17** | `effect_label` absent from Pearson, Spearman, paired t, Wilcoxon and two-way, present in 9 other places |
| **D21** | `emlClassifyEffect` still classifies `omega_squared`, which nothing produces |
| **D11** | The passing branch of the normality gloss prints no criterion at all |
| **D1** | `Try:` lines in the demo-table creator paraphrase Wizard labels that no longer match, and never mention the direct menu entries |
| **D3** | Demo types 1–5 state no built-in effect, so a user cannot tell what the table is for |
| **D7** | `emlDescribe.summary$` is dead code with one test-only reference |
| **D48** | Skipped groups in a grouped correlation print bare lines past the closing rule |
| **D49** | Those skips are not accumulated into a summary line — fixing D49 largely closes D48 |

### C12 · Missing output that users will expect — 3 findings

| | |
|---|---|
| **D8** | `Check normality` offers no Draw, and there is no Q–Q plot anywhere in the plugin. `eml-describe-table.praat` has no completion dialog to add a button to |
| **D38** | No simple-effects analysis and no interaction caveat after a significant interaction |
| **D40** | No interaction or means plot among the 14 graph types |

These three are the only places in this document where I would accept "document
it as a known limitation" instead of building it — but that has to be a
decision you make explicitly, not a default.

### C13 · Packaging and provenance — 4 items

| | |
|---|---|
| **D99** | The procedure name leaks into user-facing error text at **39 sites** in `eml-inferential.praat` — `emlTwoWayAnova` ×11, `emlTukeyHSD` ×6, `emlPairwiseT` ×4, `emlDunnTest` ×4, `emlKruskalWallis` ×3, and 11 more |
| **D109** | `scripts/eml-tutorial.praat` calls 23 procedures nothing defines. Unregistered, so dead code rather than a live defect — delete or declare |
| **—** | **35 files credit Claude** — `# Development: Claude (Anthropic)` in 21, `# Code generation: Claude (Anthropic)` in 15, six longer variants. Contradicts the sole-authorship rule and is the first thing a reader of a published tool will see |
| **—** | Two executable bits (`harness/stress_graphs.sh`, `validate/mutation/mutate_drive.sh`) cannot be set through the GitHub web form |

---

## 5. What cannot be settled by reading code

Three items, and they are cheap once you are in front of the GUI:

- **D84** — the RM subject-count question overlaps the `Conditions:` optionmenu row. Needs a screenshot.
- **D92** — violin and box y-axes pinned to zero, tripling annotation headroom. Needs a rendered figure.
- **D93** — an error naming a different tool leaves no route to it. Needs a GUI walk.

D92 and D93 currently sit inside the resolved count with their rows flagged. If
they turn out unresolved they move to C10 and C12 respectively.

Separately, the graph stress harness reports one `BLANK_FRAME` — `violin_zerovar`
at 1.0% ink. That may be correct behaviour for a zero-variance violin, or it may
be a blank panel. Nobody has looked at the image.

---

## 6. What this means for the release

The statistics are validated to a standard that is unusual for a Praat plugin,
and that work is done. What is not done is everything the user sees around
them, and eighty live findings is not a polish list.

The four clusters that would most embarrass a release, in order:

1. **C4** — a two-way design drawn and annotated as a two-group Welch test
2. **C1** — three orchestrators whose export cannot succeed, and one that exports the wrong analysis
3. **C7 / D20** — no variance-homogeneity check anywhere, on demo data that violates the assumption
4. **C5** — the Wizard's repeated-measures path failing on complete data, then returning the user to the same broken defaults

C2's `emlShowExplanations` reset belongs beside them: it is one line, and until
it is fixed the reports are order-dependent within a session, which makes every
other report finding intermittent and hard to reproduce.

I am not proposing an order beyond that. Eighty findings is a real amount of
work and the sequencing is yours.

---

Ian Howell — Embodied Music Lab — GPL-3.0-or-later
