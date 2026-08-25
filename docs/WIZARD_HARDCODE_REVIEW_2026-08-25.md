# Wizard hardcode review — every frozen value, classified

Verification session, 25 Aug 2026, against `2b9ef78`. Complete read of
`scripts/eml-wizard.praat` (3,134 lines). Every literal that stands where a
user's choice, a shared constant, or a ruled policy belongs is listed;
literals verified to be legitimate design constants are listed last so the
review is auditable as complete, not merely as a defect list.

Classification: **A** = frozen user choice (parity build under Ian's
"same analyses" contract — the option exists on the menu door or in the
engine and the wizard cannot express it). **B** = embedded inference policy
(needs a ruling, not just a build). **C** = draw-handoff instance (the
family-substitution class already on the punch list; wizard-specific site).
**D** = verified legitimate; no action.

## A. Frozen user choices — parity builds

- **A1. Two-group: no "Both parametric and nonparametric" row.**
  `eml-wizard.praat:2193-2199` (row set); dispatch `:461-495` passes only
  "parametric"/"nonparametric". Menu door offers Both
  (`eml-compare-groups.praat:71`). Engine supports it.
- **A2. Paired: no "Both" row.** `:990-992`; dispatch `:1008-1024`. Menu:
  `eml-compare-paired.praat:114`.
- **A3. Correlation: no "Both" row.** `:1502-1504`; dispatch `:1520-1532`.
  Menu: `eml-correlate.praat:153`.
- **A4. Correlation: no per-group option.** `@emlRunCorrelationAnalysis`
  called with two columns only (`:1524, :1530`); the menu door offers a
  group column with the complete per-group pattern
  (`eml-correlate.praat:136-144`).
- **A5. Regression: no group column.** `:1319-1339` (page), `:1372` (call).
  Rides the per-group regression port already ruled into 1.0 — the wizard
  page gains the same group column the menu page has.
- **A6. Normality: mode frozen to "single".** `:1719` — the orchestrator
  itself supports all-columns and grouped modes (the menu wrapper uses
  them). Also no Q-Q draw: the branch never sets `wizCanDraw`, so the
  Draw button cannot appear (`:147` init, `:1730` sets export only).
- **A7. k-group parametric: post-hoc grid collapsed to three frozen rows.**
  Rows `:2258-2266`; dispatch `:700-715` calls the pairwise engine with two
  hardcoded pairings (`"scheffe","none"` at `:702-703`; `"welch","bh"` at
  `:709-710`). The standalone pairwise dialog offers 3 tests × 3
  adjustments × 2 t-variants (`eml-pairwise.praat:42-56`). Also: no
  "ANOVA, no post-hoc" row exists.
- **A8. Kruskal-Wallis: Dunn frozen on.** `doDunn = 1` literal at `:740`
  (own comment at `:721-722`: "Dunn runs on all pairs regardless of the KW
  p-value"). No "Kruskal-Wallis alone" row; the menu door has one
  (`eml-compare-kw.praat:78-80`).
- **A9. No Group order control on any wizard page.** Resolved by the parity
  contract: the group-based wizard pages gain the same "Table order /
  Alphabetical" dropdown as their menu siblings. Session-persistence rule
  applies; the wizard runs fresh per launch, so it opens at the default.
  (The RM/Friedman branch is untouched — condition order comes from column
  slots, not row order.)

## B. Embedded inference policy — needs one ruling each

- **B1. Post-hoc gating disagrees with itself across doors, and its alpha
  is a literal.** The wizard gates Scheffé and the liberal pairing on
  `emlOneWayAnova.p < 0.05` (`:700`) — a hardcoded level of exactly the
  class the alpha-in-force ruling eliminated elsewhere. Meanwhile: wizard
  Tukey is unconditional; wizard Dunn is unconditional; the menu pairwise
  dialog never gates; the graph bridge runs Dunn only on a significant
  omnibus (`eml-annotation-procedures.praat:2829`). Four policies for one
  question. Needs a single ruled policy (gate or don't, per family), the
  level taken from the alpha in force, and the choice disclosed in the
  report. The current row labels honestly state their own gating — the
  ruling decides what the labels should promise.
- **B2. A group too small to assess counts toward "normality reasonable".**
  `@wizardNormCheck` group mode `:2588-2594`: an n < 3 group prints
  "too few for normality test" but cannot set `.anyFail`, so the overall
  line still reads "Recommendation: parametric test is reasonable" — the
  same two-state defect as the standalone normality checker (Sol audit
  finding, confirmed). Needs a third state: "not fully assessed — k of n
  groups tested."
- **B3. The explanation mechanism is wired to the wrong door.** The
  explanation gate defaults ON for every door (`eml-output.praat:89-90`)
  and the report layer appends an explanation whenever one is loaded
  (`:618-645`) — but the only code that ever loads explanation text is the
  graph-side reporter (52 call sites in `eml-annotation-procedures.praat`;
  zero in `eml-analysis.praat`, zero in the wizard). So the wizard's
  "enable explanations" line (`eml-wizard.praat:40`) is a no-op for its own
  reports, and explanations appear only on figure-driven recomputed
  reports. Needs: wire the explain calls into the orchestrator reporters,
  and rule which doors show them (the gate already exists to differ by
  door; recommendation — on everywhere, since they are value-anchored and
  short, with the flag as the scripting off-switch).

## C. Draw-handoff instances (family-substitution class, wizard sites)

- **C1. Correlation/regression draw carries no test choice.** Presets
  `:2040-2052` pass columns and annotate-on only — not pearson/spearman.
  The scatter annotation recomputes with its own default, so a Spearman
  wizard run can draw a Pearson-annotated figure. Census leg;
  structurally closed by the store.
- **C2. Group draw preset frozen to violin** (`emlGraphsPresetType = 7`,
  `:2034`). Acceptable as a default only because the graphs form opens for
  editing; acceptance leg should confirm the user can change type there
  with presets intact.
- **C3. Paired spaghetti invents Subject and drops Group.** `:2071-2085`
  builds the long table with `Subject = row number` and no group column;
  the menu paired wrapper asks for both (`eml-compare-paired.praat:117-126`).
  Parity plus the Sol finding on spurious grouping.
- **C4. KW draw sets no correction preset.** The menu KW wrapper hands its
  adjustment to the figure (`eml-compare-kw.praat:471`); the wizard's group
  draw sets none (`:2033-2039`), so the figure's Dunn correction need not
  match the analysis. Same class, wizard site.

## D. Verified legitimate — no action

Welch as the seeded default (disclosed "default" in the row label,
`:2195`); the A3K condition-slot seeds (documented rationale `:1096-1104`);
RM adjustment default holm (`:1107`, user-changeable); the demo-table
generator parameters (`:2937-3115`, demo data); skew/kurtosis thresholds
routed through the shared constants rather than hardcoded (`:2455-2463`,
the file's own comment records the old hardcoding as repaired); two-way
`wizTestType$ = "parametric"` (`:848` — the only two-way engine is
parametric; when a rank-based alternative exists this becomes a menu);
the n ≥ 3 minimum for a normality diagnostic (statistical floor, message
printed); the LMM formula-page defaults (page unreachable by ruling,
kept parseable on purpose); `emlRunRepeatedMeasuresAnalysis` called with
subject `""` (`:1233` — wide format pairs by row; flagged for Opus only to
confirm the orchestrator makes no other use of a subject column).

## Sequencing note

A1-A3 are one pattern (add a Both row to a one-list menu — the header-guard
idiom is already in the file). A4-A6 and A9 are page fields plus argument
pass-through. A7-A8 wait on B1's ruling so the rows are built once with the
ruled gating in their labels. B3 touches the shared report layer and should
land before the language batch, so approved wizard wording and explainer
wording are one review. C1-C4 belong to the store/census lane and should
not be patched separately.
