# Author rulings on the 8 remaining findings

**Ian Howell — Embodied Music Lab**
Responds to `audit/reviews/DESIGN_RULINGS_2026-08-06.md` (`9951fcf`). Rulings
issued in conversation with FABL and translated here into the document's
vocabulary. Where a ruling differs from the document's recommendation, that is
stated plainly. The factual corrections from the FABL adversarial review are
folded in where they bear on a ruling.

**These rulings are binding. This document supersedes the recommendations in
`DESIGN_RULINGS_2026-08-06.md`, which is retained as the analysis that
preceded them.**

---

## Ruling 1 — D20: conditional show-both. Differs from the recommendation.

Not (a), (b), (c) or (d) as listed. The ruled behaviour:

- Compute Brown–Forsythe always and print it in the ANOVA block — (a)'s line.
- **When BF rejects, additionally print Welch's *F* and Games–Howell beside
  the standard block.** Never replace, never auto-switch, never make the
  reported primary test depend on the data. Both blocks labelled, with one
  plain sentence saying which to prefer and why.
- When BF does not reject: single ANOVA, exactly as today.

Rationale: warn-only is warn-and-abandon (the document's own case-against),
and always-both confuses the majority of runs for the benefit of the minority.
Conditional-both shows one test to most users and two tests only when there is
a stated reason.

Wording constraint: the BF line is a smoke alarm, not a verdict — "your groups
differ in spread more than this test likes; here is the version that tolerates
that," never "your data failed." Small-n misses and large-n trivial flags are
why.

Cost accepted: Welch's *F* (k-sample) is new numerical code and gets a
v-script per the standing validation rule; the conditional block needs its own
driven capture on a designed heteroscedastic input — `c04`/`c11` already exist
for exactly this. Blast radius: none to existing captures on homoscedastic
inputs beyond the added BF line (named-line reads, per the document's own
breakage analysis).

Correction to carry: "zero of the four committed demo captures reject
Levene-median" is false — two of seven column-tests reject (`demo_3groups`
vibrato .0391; `dump_demo_twoway` SPL .0014, the latter itself an artifact of
pooling across a factor, which previews D33). Practical upside: out-of-the-box
demo data can exercise the new conditional path.

## Ruling 2 — D33/D63/D64: unify the graphing statistics. Differs from the recommendation — no refusal end-state.

History the options table lacked: the bridge computing its own statistics was
a deliberate design decision, made so the standalone graph doorway works for a
user who never ran an analysis. The defect is that the bridge's private
statistics drifted while the wrapper machinery advanced. So the ruling is
closest to (d), reframed:

- **The graphing door calls the same modern statistics machinery as the
  wrappers.** When an analysis launched the draw, its result passes through.
  When the user entered standalone, the bridge computes fresh — through the
  shared machinery, not its own. The figure and the Draw CSV state which of
  the two happened.
- The standalone doorway stays. Nothing refuses as an end-state; the two-way
  case gets its correct annotation through the shared machinery plus Ruling
  3's cell structures.
- **Audit every statistic the graphing layer produces**, treating D33 as the
  first of several until proven otherwise, and bring the layer under
  validation coverage — currently zero. Harness and R-side checks land with
  the unification, not after it.
- Criterion, in the author's words: whatever does not repeat itself and makes
  the code most elegant.

D64 dissolves — the Adjustment menu becomes real once the machinery is shared.
This is accepted as the largest work item of the five. If sequencing demands
an interim, honest labelling (the document's (a)) is acceptable as a stopgap
only with the unification committed as the destination.

## Ruling 3 — D38/D40: all three, with the plot in the results Draw flow.

- **(a) caution:** in, following the `:2194` precedent.
- **(b) simple effects:** in, with its own v-script (new printed numbers).
- **Interaction plot:** in, via the two-way **results screen's existing Draw
  flow** — not a registry type, not a separate button. Clicking Draw asks one
  three-choice question: *Interaction plot / Grouped violin / Both*, default
  **Both**. "Both" runs the standard single-figure flow twice, sequentially —
  each image keeps its own dimension prompt and its own save, no combined
  canvas. Both doorways that reach a two-way result (menu wrapper and Wizard)
  share the completion screen, so one implementation serves both.
- The graph-type registry is untouched by this ruling.
- Unconditional rider from the document, confirmed: print
  `emlTwoWayAnova.warning$`.

## Ruling 3b — drop `nGraphTypes` to 13.

The archaeology settles it: type 13's form section was deliberately removed
when the CI plot was folded into type 5 as the `tsShowCI` toggle (the code
comment at `eml-graphs-form.praat:5622` says so), and the menu entry is a
leftover sign. Removing it loses nothing — `@emlDrawTimeSeriesCI` remains
live and dispatched from type 5. Consider making the Line Chart toggle's
label carry the old name for discoverability.

## Ruling 4 — D8/D58: (a) + (d), matching the recommendation. (b) out; (c) documented gap; (e) refused permanently.

- **Q–Q plot** from the existing Blom order statistics: in. This follows R's
  own convention — the Q–Q is the normality figure in R's standard diagnostic
  set, and the pairing "Shapiro–Wilk number + Q–Q plot" is what R users and
  reviewers expect.
- **Histogram with normal overlay: out** for Phase One, by the same
  convention argument. If practitioner feedback asks for it later, it can be
  revisited; record it beside the (c) gap.
- **The Q–Q sits behind an explicit column picker** — the checker is multi-column,
  and a silently wrong column is the D33 disease in a new place. The picker is
  not optional.
- **(d) regression diagnostics: in** — wire `@emlLMMInfluence`, and **export
  `.hat` and `.cooksd`** (the vocabulary already reserves them; neither is
  exported today).
- Correction that binds here: `.std.resid` is currently plain `resid/s` — no
  leverage term at all, verified to 3.6e-15 against the committed export — so
  its fix **depends on (d)** and is not a separable unconditional. Land them
  together, or the file carries two columns under different conventions.
- **(c) Describe Table visuals: documented gap** for Phase One, with a
  REGISTRY entry.
- **(e) Durbin–Watson: refused permanently**, recorded in REGISTRY with the
  ordering-semantics reason as primary.

## Unconditional queue (no ruling required — corrected counts)

- Print `emlTwoWayAnova.warning$`.
- `.std.resid` fix — bundled with Ruling 4(d), see above.
- `emlGraphsPresetDotSize` / `ShowDots` read-never-set.
- Authorship headers: **23 files** (46 matching lines), not 35 — restate the
  count from the repository at fix time.
- Scratch probes: **19 files** under `harness/probes/`.
- Executable bits: no `.sh` in the tree is executable; the two named are the
  complete set.
- Additions: `harness/broom_cases/r7_axis_drive.praat` still includes its
  dependencies by absolute `/home/claude/...` paths — same class as the v17
  default-path leak, still unfixed.

## Unchanged

D84, D92, D93 and the `violin_zerovar` `BLANK_FRAME` remain
render/GUI-walk items. The parallel-rig recipe (three concurrent GUI
instances, verified) is available when that walk is scheduled.

---

# Addendum — counts restated from the repository

The rulings above instruct that the unconditional-queue counts be restated
from the repository at fix time. Done, at `9951fcf`. Three of the five do not
hold as written. This addendum records the measured values; it changes no
ruling.

**Authorship headers — 36 lines across 36 files, not 23 files / 46 lines.**

```
grep -rn "^# *\(Development\|Code generation\): Claude (Anthropic)" \
  --include=*.praat .          →  36 lines, 35 files
plugin/dev/tests/phase2/verify-inferential-batch6.R                   →  1 file
```

One `.praat` file carries both header variants, which is why the file count
and line count differ by one. Four further matches exist in `audit/*.md` —
`DRIVE_FINDINGS`, `PHASE_ONE_AUDIT`, `EDIT_TABLE_REVIEW`, and
`DESIGN_RULINGS` itself — but those are audit prose *quoting the string* and
are correctly excluded from the fix. The likeliest source of the 23/46 figure
is a pattern that counted differently across the `.md` quotations.

**Executable bits — four `.sh` files, not two.**

```
harness/stress_graphs.sh          non-executable
harness/gui.sh                    non-executable
validate/mutation/mutate_drive.sh non-executable
validate/tools/check_wired.sh     non-executable
```

The ruling's substantive point is correct and stronger than stated: *no* `.sh`
in the tree is executable. But `harness/gui.sh` and
`validate/tools/check_wired.sh` are in the same condition as the two named,
and a fix that sets only two leaves the tree inconsistent.

**Scratch probes — 19 files. Confirmed as ruled.**

**`r7_axis_drive.praat` absolute paths — confirmed**, 8 `include` lines at
`:11–18` under `/home/claude/EMLPraatTools/plugin/...`. Note this is a
*different* absolute root from the probes, which use
`/home/claude/drive/prefs/plugin_EML_Praat_Tools/...`; both are leaks but they
would not be fixed by the same substitution.

**Type-13 archaeology — confirmed verbatim** at `eml-graphs-form.praat:5622`:

```praat
# Type 13 (Time Series with CI) form section removed.
# CI is now a toggle within type 5 (Line Chart).
# The draw procedure @emlDrawTimeSeriesCI is still available
# and dispatched from type 5 when tsShowCI = 1.
```

**Not restated here:** the Levene correction in Ruling 1 (two of seven column
tests reject) is accepted as issued and is not re-derived — it comes from
FABL's independent computation, and re-deriving it in the same session that
got it wrong the first time would not add independence.

---

Ian Howell — Embodied Music Lab — GPL-3.0-or-later
