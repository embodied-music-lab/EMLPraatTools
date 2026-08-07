# Design questions requiring a ruling — 8 remaining findings

**EML Praat Tools · Phase One audit · 6 August 2026**
**Repository state:** `4394c5b`. Suite `1045 checks, 1045 passed, 0 FAILED`, exit 0.
**Live findings:** 8 of 101. Every other finding is closed against emitting code.

---

## Why this document exists

Ninety-three findings were closed by fixing code. These eight cannot be, because
each one asks for a behaviour the plugin does not currently have, and the shape
of that behaviour is a judgement call rather than a bug fix. Implementing any of
them the wrong way costs more than leaving them open.

Each section below gives:

1. **What the finding claims** — quoted or paraphrased from
   `audit/DRIVE_FINDINGS_2026-08-04.md`.
2. **What is actually true** — verified against the repository at `4394c5b`,
   with file:line. In three places the finding is wrong, and one of those is
   wrong in its central factual claim.
3. **Options, with honest cost.**
4. **What each option breaks in the validation suite.** This is the part that
   makes some of these expensive in a way that is not obvious from the
   finding text.
5. **A recommendation, and the case against it.**

The audit was adversarial by design and the findings should be read that way.
So should this document. Where I am arguing for the cheap option, the reason
may be that it is cheap.

**Scope note.** Phase Two is multiple regression and linear mixed models.
Nothing here is deferred to Phase Two by default; the question is ship / fix /
drop for Phase One.

---

# 1. D20 — variance homogeneity

> **D20 (high).** *No variance-homogeneity check anywhere, and the plugin's own
> demo data violates the assumption.*

## What is actually true

**The first half is correct. The second half is wrong, and it is wrong in a way
that changes the ruling.**

**Correct:** there is no Levene, Bartlett, Brown–Forsythe, Welch's *F*, or
Games–Howell anywhere in `plugin/`. Grep returns nothing. `@emlOneWayAnova`
computes Student's pooled *F* unconditionally. `@emlTTest` does carry a Welch
correction (`eml-inferential.praat:185–194`), but that is the two-sample
Welch–Satterthwaite df, not the *k*-sample formula, and it is not reused
anywhere else.

**Wrong:** the demo generator is *designed* near-homoscedastic.
`plugin/scripts/eml-create-demo.praat:78–101`:

```praat
Set numeric value: i, "SPL_dB", randomGauss (92, 4)   ; Soprano
Set numeric value: i, "SPL_dB", randomGauss (88, 5)   ; Mezzo
Set numeric value: i, "SPL_dB", randomGauss (85, 4)   ; Alto
```

Population variance ratio (5/4)² = **1.5625**. The `vibrato_rate_Hz` column
(σ = 0.6 / 0.7 / 0.5) is **1.96**. Both are inside any conventional rule of
thumb.

The finding cites observed SDs of 5.18 / 5.94 / 2.98 — a ratio of ~4:1. That is
**one unseeded draw** from a distribution designed at 1.56:1, landing in roughly
the 9% tail of the sampling distribution of the max/min variance ratio at
n = 15. It is not a property of the plugin.

**And the exhibit passes the test the finding proposes.** Median-centred Levene
on that exact committed capture returns **p = .0628**. Of the four committed
demo captures in `evidence/csv/`, **zero reject Levene-median at α = .05**. The
finding's own evidence, run through the finding's own remedy, says the data are
fine.

That does not make the gap harmless. A user's real data can easily be 10:1. It
means the *urgency* argument in the finding is unsupported, and it means we
should not build an auto-switching mechanism to rescue a dataset that does not
need rescuing.

## What is assemblable today

- **Games–Howell: yes.** `Get TukeyQ:` is already in use
  (`eml-inferential.praat:2145`), and Games–Howell is Tukey's *q* distribution
  with Welch pairwise SE and Welch–Satterthwaite df. The pieces exist.
- **Welch's *F* (k-sample): no.** Needs a new statistic and a new df formula.
  Not hard, but it is new numerical code, and new numerical code needs a v-script.
- **Levene / Brown–Forsythe: trivially yes.** Both are a one-way ANOVA on
  absolute deviations from the group mean (Levene) or median (Brown–Forsythe).
  `@emlOneWayAnova` already does the hard part; this is a data transform plus a
  recursive call.

## Options

| | Behaviour | Cost |
|---|---|---|
| **(a)** | Compute Brown–Forsythe, print it in the ANOVA block, warn if p < .05. Do not change the test. | **Small.** One transform + one existing call + one report line. |
| **(b)** | (a), plus a printed recommendation naming Welch/Games–Howell as the alternative the user should consider, without offering it. | **Small–medium.** (a) plus wording, plus the honesty problem of naming a test we do not provide. |
| **(c)** | Auto-switch to Welch's *F* + Games–Howell when the homogeneity test rejects. | **Large.** See below. |
| **(d)** | Add a `Method` optionmenu — pooled / Welch — and let the user choose. | **Large,** plus a new dialog control on a form that is already dense. |

## What (c) and (d) break

This is the load-bearing part. A switch **inside `@emlOneWayAnova`** breaks:

- **`v09`** — 40 checks, and it asserts `grepl("^eta-squared")` on the printed
  effect-size label explicitly. Welch's *F* has no η².
- **`v16`**, **`v20`** (55 checks, asserts broom column names *and order*),
  **`v21`** (97 checks).
- **`v18`** — cases **c04** and **c11** are the 10:1-variance designed cases.
  They exist precisely to exercise heteroscedasticity. An auto-switch fires on
  them and every parity assertion against `aov()` fails.
- **Tier A property A1** — `F = t²` at *k* = 2. This is an identity, not a
  tolerance. Welch's *F* equals **Welch** *t*², not Student *t*². A1 fails the
  moment the switch is reachable at k = 2.

Option (d) has the same blast radius unless the default is pinned to pooled and
every existing capture is re-driven at the default — which is possible, but it
means re-driving `v09`, `v16`, `v20`, `v21` through the GUI and re-committing
the captures.

Options (a) and (b) break nothing: they add a line to the report, and the
v-scripts read named lines rather than positions.

## Recommendation

**(a).** Print Brown–Forsythe in the ANOVA block. Warn on rejection. Do not
switch, do not offer a switch, in Phase One.

The reason is not cost. It is that the current behaviour has no *silent* error:
the plugin prints Student's *F* and calls it Student's *F*. Adding a
homogeneity line converts an undisclosed assumption into a disclosed one, which
is the whole of the actual defect. An auto-switch would additionally make the
reported test depend on the data in a way the user did not ask for and might
not notice — which is a *new* class of the exact problem D33/D63 are about.

**The case against (a):** it is warn-and-abandon. We tell a user their
assumption is violated and then hand them no tool that copes with it, in a
plugin whose stated audience is practitioners who will not go write their own
Welch ANOVA. There is a real argument that (a) is worse than silence, because
silence at least does not stop the user mid-analysis with a problem they cannot
act on. If that argument wins, the honest alternatives are (c)/(d) or leaving
D20 open and documented — not (a).

**Question for ruling:** (a), or accept the cost of (d), or hold D20 open with a
REGISTRY entry naming the gap?

---

# 2. D33 / D63 / D64 — the annotation bridge

These three are one defect wearing three hats. Ruling on the bridge rules on all
three.

> **D33 (high).** Draw annotates a two-way design with a two-group Welch *t* on
> one marginal.
> **D63.** The figure and the exported CSV report a different test family than
> the analysis that launched them, with no disclosure on any screen.
> **D64.** The `Adjustment method` optionmenu on the graphing dialog is inert
> whenever `Test type = Parametric` and *k* ≥ 3.

## What is actually true

All three are **confirmed exactly as written**, and the mechanism is single.

`@emlBridgeGroupComparison` (`plugin/graphs/eml-annotation-procedures.praat:1799`)
takes 9 arguments and **receives no analysis result**. Four call sites:
`eml-graphs-form.praat:5996, 6004, 6014, 6022`. It **recomputes from the table
under its own fixed method**:

- *k* = 2 → Welch *t*, always.
- *k* ≥ 3 parametric → `@emlOneWayAnova` + Tukey HSD, hardcoded, with
  `annotMatrixPosthoc$ = "Tukey HSD"` written flat (`:2149–2173`). The
  `Adjustment method` menu is never read on this branch → **D64**.
- Two-way design → the bridge sees one factor column, pools across the other,
  and labels the result `"Two-Group Comparison"` → **D33**.

D63 follows: the annotation and the Draw-path CSV describe the bridge's
recomputation, not the wrapper's analysis, and nothing on screen says so.

## The constraint that shapes the fix

**Draw is reachable standalone.** `setup.praat:97` → `eml-graphs.praat:28`
(`@emlGraphsWorkflow: 0`), plus 8 action-button entries. A user can open a
Table, draw a grouped violin, and never have run an analysis.

So "just pass the wrapper's result through" is **not sufficient on its own**.
The bridge must retain a compute path for the standalone case. Any fix is
"prefer the passed result, fall back to recomputation, and *say which*."

The precedent for passing exists and is cited in the finding: the regression
preset at `eml-regress.praat:96–106` hands over eight settings. And
`eml-draw-procedures.praat:2414–2427` already carries a v1.19 fix that keeps the
drawn line and the printed report coherent when OLS was reported — the codebase
does do this deliberately, in one place.

## Can the new tidy/glance/augment collectors carry the result?

Partly. This matters because if they could, the fix is nearly free.

**They can carry the omnibus.** `glance` has a usable row for ANOVA and KW.

**They cannot yet carry the post-hoc pairs**, for four reasons:

1. Post-hoc pairs are staged as **rendered CSV text**, not cells —
   `@emlResultStageExtra` stores `emlResult_extra1Text$`. The bridge would have
   to re-parse its own output format.
2. `@emlCSVInit` at `eml-annotation-procedures.praat:2513` **destroys the flag
   and the extras** before the bridge could read them.
3. **Dunn emits no `effect.size`** — the annotation layer draws effect markers.
4. Group labels are **fused into `"A-B"`**. A voice-type level literally named
   `mezzo-soprano` is unparseable. This is not hypothetical for this user base.
5. The two-way path **declares no contrasts at all**, so there is nothing to
   pass for the case D33 is actually about.

The **pairwise wrapper is a complete fit** — it has the pairs, the adjustment,
and the effect sizes. That is the one wrapper where a pass-through fixes D64
cleanly today.

Separately: `emlGraphsPresetDotSize` and `emlGraphsPresetShowDots` are **read
but never set** anywhere. Latent, unrelated, worth a line in the fix.

## Options

| | Behaviour | Cost | Fixes |
|---|---|---|---|
| **(a)** | Label honestly. The annotation and the Draw CSV state the test the bridge actually ran, and when it differs from the launching analysis, say so on the figure. Grey out `Adjustment method` when inert. | **Small.** Strings + one dialog-state change. | D63 fully. D64 fully. D33 partially — the figure would say `"Welch t, factor2 pooled across factor1"` instead of lying, but still shows the wrong thing. |
| **(b)** | (a), plus pass-through for the **pairwise wrapper only** (the complete fit), falling back to recompute. | **Medium.** New preset variables + a fallback branch + one new v-script. | D64 fully and correctly. D63 fully. D33 unchanged. |
| **(c)** | (a) + (b), plus **refuse** to bridge a two-way design into a single-factor annotation — draw the figure, decline to annotate, and say why. | **Medium.** (b) plus one guard. | D33 fully, by refusal. |
| **(d)** | Full result-passing for all wrappers: structured cells for post-hoc pairs, delimiter-safe labels, `effect.size` for Dunn, two-way contrasts. | **Large.** Touches the collectors, the writer, every orchestrator, and every Draw path. Post-CSV-migration, this is the second-largest change in the audit. | Everything, properly. |

## What breaks

(a) breaks nothing — no numbers move. (b) and (c) break nothing in
`v01`–`v21` either: the annotation layer is **not covered by the suite at all**
(`validate/README.md`: *"Still uncovered: the graphing layer"*). That cuts both
ways — it is why these are cheap, and it is why they would ship unvalidated
unless we write the harness alongside, which the standing validation rule
requires:

> nothing is validated until there's an authored R script that tests the output
> (with the red path input as well).

So the real cost of (b)/(c) includes a first R-side check of the Draw CSV, which
does not exist yet. Call it **medium** honestly rather than small.

(d) is large and, in my read, Phase Two shaped even though it is not multiple
regression or LMM.

## Recommendation

**(c).** Honest labelling everywhere, pass-through for the one wrapper where it
fits cleanly, and a **refusal** on the two-way→single-factor bridge.

The refusal is the important part. D33 is the worst finding of the eight,
because the figure is confidently wrong in a way a reader cannot detect: a
two-violin plot annotated `"Two-Group Comparison"` with a real *p*-value, in a
design where the suppressed factor had the *larger* effect (F = 107.67,
partial η² = .71). Refusing to annotate is not a workaround — it is the correct
behaviour under this plugin's own precedent, which already refuses rather than
guesses elsewhere (Tier A properties A10–A12 assert refusals by name).

**The case against (c):** refusing is a capability regression from the user's
point of view. Today they get an annotated two-way figure; after (c) they get a
bare one and an explanation. Someone who does not read the explanation will read
it as the plugin breaking. And (c) leaves the *actual* wanted behaviour —
annotate the two-way design correctly — unimplemented, so D33 closes on a
technicality rather than on a fix. A reviewer could fairly say (c) is (d)
postponed with better manners.

**Question for ruling:** (c), or commit to (d) in Phase One, or (a) alone and
document?

---

# 3. D38 / D40 — the two-way follow-up gap

> **D38 (medium).** No simple effects, no post-hoc, and no caution that the
> interaction qualifies the main effects.
> **D40 (medium).** No interaction plot among the 14 graph types.

## What is actually true

Confirmed, with three corrections.

**Everything needed for simple effects is already exposed.** `@emlTwoWayAnova`
computes and retains `.cellMean[]`, `.cellN[]`, `.cellLabel$[]`, `.cellOf[]`,
`.yValue[]`, `.lev1$[]`, `.lev2$[]`, `.msError`, `.dfError`. The reporter
already demonstrates the exact traversal at `eml-analysis.praat:4225–4331`.
Simple effects are a loop over what is already in memory, tested against
`.msError`. There is no new numerical machinery.

**Correction 1 — the finding's line reference is stale.** The graph-type
registry is at `eml-graphs-form.praat:188–203`, not `:139–152`.

**Correction 2 — only 13 of the 14 registered types are selectable.**
`nGraphTypes = 14`, but type 13 (`Time Series (with CI)`) has no form page. A
15th type is therefore being added to a registry that already has a hole in it,
and that hole should be ruled on at the same time: fix 13, or drop it to 13
types.

**Correction 3 — there is a documented bypass for adding a plot.** Adding a
registry type costs **16 edit sites + a ~330–390 line form block + a 200–300
line draw procedure**. But `@emlDrawLMMForest` is called **directly** from
`eml-lmm.praat:82–89` with no registry work at all, and
`eml-compare-twoway.praat:99–130` already has the identical post-analysis-button
shape. An interaction plot offered as a button on the two-way *result* — which
is where a user wants it — costs a fraction of a registry type and lands in a
better place.

**Also found, unfiled:** `emlTwoWayAnova.warning$` is written to the CSV and
**never printed to the Info window**. A user reading the report never sees it.
That is a one-line fix and should go in regardless of the ruling.

**Caveat precedent exists:** `"Caution: "` + `@emlWrapText` at
`eml-analysis.praat:2194–2202`, with an explicit prior ruling on placement.
D38's caveat half can follow it exactly.

## Options

| | Behaviour | Cost |
|---|---|---|
| **(a)** | Caveat only: when the interaction is significant, print the standard caution that main effects are qualified. Follow the `:2194` precedent. Plus print `.warning$`. | **Small.** Two report lines. |
| **(b)** | (a) + simple effects: for a significant interaction, test factor A at each level of B (and vice versa) against pooled `.msError`. | **Medium.** ~80 lines of loop, a report block, one v-script. No new algorithm. |
| **(c)** | Interaction plot as a **15th registry type**. | **Large.** 16 edit sites, form page, draw proc, and it inherits the type-13 hole. |
| **(c′)** | Interaction plot via the **`@emlDrawLMMForest` bypass** — a `Plot interaction` button on the two-way completion dialog. | **Medium.** One draw proc + one button. No registry work. |

## What breaks

Nothing, in all four. The two-way v-scripts read named lines; added blocks do
not move existing ones. (b) needs its own v-script under the validation rule —
simple effects are new printed numbers, so they need R-side parity against
`aov()` on the subsetted data plus the pooled-error variant.

## Recommendation

**(a) + (b) + (c′).** All three, in that order, and skip (c) entirely.

This is the cheapest *complete* answer in the document, and it is complete
because the data structures already exist. The two-way block is the one place in
the plugin where the report is materially harder to act on than the one-way
block, despite needing more help — the one-way path gives per-group
descriptives, pairwise follow-ups and a plot; the two-way path gives an F table
and stops.

Add: **fix or remove graph type 13** as part of this, so the registry stops
claiming 14.

**The case against:** (c′) puts an interaction plot outside the graph-type
registry, which means the plugin now has two ways to produce a figure and a user
browsing the graph menu will not find the interaction plot at all. That is a
discoverability cost we pay forever to save a few hundred lines once. The LMM
forest plot set that precedent, but one precedent is not a pattern, and the
right time to stop the pattern is before it is two. If the registry is the
canonical surface, (c) is the correct answer and the cost is just the cost.

**Question for ruling:** bypass (c′) or registry type (c)? And: fix type 13 or
drop `nGraphTypes` to 13?

---

# 4. D8 / D58 — visual diagnostics

> **D8 (high).** `Check normality` offers no `Draw` button — no visual check
> accompanies the numeric one. Same for `Describe Table column`.
> **D58.** No residual diagnostics in the one wrapper whose entire output is a
> model fit.

## What is actually true

Confirmed, with one correction and one substantial free lunch.

**Correction:** the finding says to change `eml-check-normality.praat:219` from
`endPause: "Done", "New", 2, 0`. The dialog is at **`:210`**, and separately
`eml-describe-table.praat` has **no completion dialog at all** — there is
nothing to add a button to; one has to be built. `eml-describe-table.praat` also
includes only `eml-lib-stats.praat`, so it has **no graph layer loaded**. That
half of D8 is meaningfully more expensive than the `Check normality` half.

**The free lunch on Q–Q:** `@emlShapiroWilk` **already computes the Blom order
statistics** internally (`.m#`, `.sorted#`). They are undocumented but readable
and verified present. A Q–Q plot can be drawn **today with no new drawing
code** — build a temp Table from `.m#` / `.sorted#` and call
`@emlDrawScatterPlot`. The expensive-sounding half of D8 is nearly free.

**The catch on `Check normality`:** it is **multi-column by construction**. A
Draw button needs a column picker, or it draws the wrong column silently — which
is the D33 failure mode again, in a new place.

**The free lunch on regression diagnostics:** `emlVocabAugment$` **already
reserves `.hat` and `.cooksd`**. `@emlLMMInfluence` (`eml-lmm.praat:3982`)
already computes hat values, Cook's D and DFBETAS — and is **dead code, zero
call sites**. `ssXX` is computed at `:4063`. Leverage for simple OLS is free.

**The thing that is not free, and should not be built:** a Durbin–Watson
statistic. Two independent reasons:

1. Its *p*-value needs eigenvalues, and `eml-linalg.praat` does not have an
   eigen routine.
2. More seriously, **DW is order-dependent and the plugin's Tables carry no
   ordering semantics.** On `practice_hrs_wk` it would report autocorrelation in
   *spreadsheet row order*. That is a number that looks meaningful and is not.
   This is a stronger reason than the arithmetic one and it does not go away if
   someone writes an eigen routine.

Diagnostics would go at `eml-annotation-procedures.praat:3711`.

## Options

| | Behaviour | Cost |
|---|---|---|
| **(a)** | `Draw` on `Check normality` → Q–Q from the existing Blom stats, with an explicit column picker. | **Small–medium.** No new drawing code; the picker is the work. |
| **(b)** | (a) + histogram-with-normal-overlay. | **Medium.** New overlay drawing. |
| **(c)** | (a) + a completion dialog and graph layer for `Describe Table column`. | **Medium.** New dialog, new include, new picker. |
| **(d)** | Regression diagnostics: residuals-vs-fitted, Q–Q of residuals, leverage/Cook's D. Wire up the dead `@emlLMMInfluence`. | **Medium.** Mostly wiring; the numbers exist. |
| **(e)** | (d) + Durbin–Watson. | **Do not.** See above. |

**Also live and separable:** the exported `.std.resid` omits the
`sqrt(1 - h_i)` factor, so it is a numeric mismatch with broom's definition.
That is a straight bug, not a design question — it is listed here only so it is
not lost. It should be fixed regardless of any ruling, and once `h_i` is
available from (d) the fix is one expression.

## Recommendation

**(a) + (d), and the `.std.resid` fix.** Skip (b) for now, skip (c), refuse (e)
permanently and record the reason in `REGISTRY.md` so it does not come back.

(a) and (d) are both mostly *wiring code that already exists and is currently
dead or private*. That is the best cost/benefit ratio in this document. A Q–Q
plot next to a Shapiro–Wilk *p* is the single most useful figure this plugin
could add, because it is the one place where a *p*-value is genuinely a poor
summary of what the user needs to know — a Shapiro–Wilk on n = 200 rejects on
trivial deviations, and on n = 8 accepts almost anything.

**The case against:** (a) without (b) ships half of what D8 asked for. Q–Q
plots are harder for a non-specialist to read than a histogram with a normal
overlay, and this plugin's audience includes voice teachers who are not
statisticians. There is a real argument that the histogram is the *more*
valuable half for this audience and that shipping the specialist's plot without
the teacher's plot gets the priority backwards. If that argument wins, (b) is
not optional.

Skipping (c) also leaves `Describe Table column` — a high-traffic entry point —
with no visual output at all, which was half of what D8 asked for.

**Question for ruling:** is (b) in or out? Is (c) Phase One or documented-gap?

---

# 5. Summary of what is being asked

| # | Question | My answer | Cost if you agree |
|---|---|---|---|
| 1 | D20: warn-only, user-choice, or hold open? | **Warn only (Brown–Forsythe printed).** The demo-data claim in the finding is false and no auto-switch is warranted. | Small |
| 2 | D33/D63/D64: label + partial pass-through + refuse two-way bridge, or full result-passing? | **Label + pairwise pass-through + refuse.** | Medium (incl. first Draw-CSV R check) |
| 3 | D38/D40: interaction plot via bypass or as registry type 15? | **Bypass**, plus caveat and simple effects. | Medium |
| 3b | Graph type 13 has no form page — fix or drop to 13? | **Ruling needed.** | Small either way |
| 4 | D8/D58: is the histogram overlay in? Is `Describe Table` in? | **Q–Q + regression diagnostics in; histogram and `Describe Table` documented as gaps.** | Medium |

**Unconditional, no ruling needed** (queued regardless):

- `emlTwoWayAnova.warning$` is computed and never printed.
- `.std.resid` omits `sqrt(1 - h_i)`.
- `emlGraphsPresetDotSize` / `ShowDots` are read but never set.
- 35 files carry `# Development: Claude (Anthropic)` headers — contradicts sole
  authorship, publication blocker.
- Two executable bits (`harness/stress_graphs.sh`,
  `validate/mutation/mutate_drive.sh`) cannot be set through the web upload
  form.
- 18 scratch probes under `harness/probes/` to remove.

**Cannot be settled by static inspection** (need a rendered figure, a GUI walk,
or a screenshot): D92, D93, D84, and the one `BLANK_FRAME` in the graph stress
run (`violin_zerovar`, 1.0% ink — nobody has looked at the image yet).

---

Ian Howell — Embodied Music Lab — GPL-3.0-or-later
