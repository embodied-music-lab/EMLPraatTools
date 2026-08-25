# Punch list — doors, wizard parity, and the road to unification

Verification session, 25 Aug 2026. REVISION 2, re-derived against the
real remote head `3e34b1a` after the push (the first revision was written
against a stale `2b9ef78`). Items already built and pushed are marked
BUILT — they leave the build queue and enter the verification queue; my
acceptance legs still run on every one of them. Every item is
adjudicated: the intended behavior is ruled, nothing here is open. Opus
subcontracts items to agents as written; a conflict between this list and
the code is resolved in favor of this list, and a conflict this list does
not cover comes back to Ian through the verification session rather than
being decided in place.

Every item ships with an acceptance check that is demonstrated red against
the pre-fix behavior (mutation standard). The acceptance protocol is at the
end. Author is never verifier throughout.

---

## Lane 1 — result store (continues; Opus holds it)

- **1.1 Fingerprint, builds 4-5. BUILT and pushed** (`eba7d4c`, merged
  `f389db7`). My acceptance probes run against the pushed tree with
  reorder inverted to "must invalidate."
- **1.2 Reprint rule.** The store keeps the report text beside the key —
  in CANONICAL form: rendered with explanation-routed lines suppressed, so
  the comparison sees numbers and disclosures only. Without this, flipping
  the explanations toggle would change the text and trigger a false "data
  changed" reprint. Key mismatch → re-run → reprint only if the new
  CANONICAL report differs from the stored one, with one line above it:
  "Data changed since this analysis was last run; re-measured." Identical
  canonical report → silent, key updated; what the user sees still renders
  per their own display settings. Settings that are analysis identity
  (item 1.4 — alpha, correction, sort order) are compared as identity, not
  as text. Acceptance: reorder-only under alphabetical ordering → silent;
  cell edit → reprint with the line; explanations toggled between draws →
  silent. Red demo: reprint on identical canonical report.

  STATUS: the reprint rule as ruled is BUILT (`21c651d`) — but it predates
  the canonical-form amendment above, which exists because lane 6's
  explainer wiring would otherwise cause false "data changed" reprints.
  The canonical comparison is the remaining build on this item and must
  land with or before lane 6.
- **1.3 Two-way stays keyless. BUILT and pushed** — stated refusal naming
  the columns confirmed in the fingerprint merge. Verification leg only.
- **1.4 Stored-result identity.** A stored result carries, beside the key:
  column names, test type, correction method, alpha, and group sort order.
  The settings census this list derives from is BUILT (`6a041dd`); the
  identity wiring itself lands with the store's write site (1.6).
- **1.5 Fingerprint legs join the main suite. BUILT and pushed.**
  Verification leg only.
- **1.6 Store write site, bridge consumption, and announcement** remain
  sequenced behind the door-agreement census fixtures (items 6.x), per the
  standing direction — the store must not enshrine an unaudited door.

## Lane 2 — group ordering and direction

- **2.1 Table order stays the default.** It is a display control built for
  ordinal conditions; no default change.
- **2.2 Every comparison report names its ordering and direction.**
  HALF BUILT (`095dddb`): the direction half is done, and in a better
  shape than first specified — the subtraction is named on the line
  carrying each signed number ("Mean diff (C1 − C2)"), with convention
  notes on all four signed matrices, rather than one summary line.
  That shape is adopted; language batch item 10 is revised to match.
  REMAINING: the ordering clause — one line stating the group order in
  force ("Group order: table order (pre, post)") on grouped comparison
  reports. Acceptance: ordering clause present through menu, wizard, and
  graph doors; direction naming verified on every signed line; red demo:
  a signed statistic with no named subtraction.
- **2.3 Session-only persistence.** The graphs form keeps the choice across
  draws within a session and seeds table order at launch; the `groupSort`
  line leaves the config file (the "Erase page first" pattern). Menu
  dialogs, as fresh script runs, open at the default. Acceptance: set
  alphabetical, draw, relaunch → dropdown back on table order; red demo:
  the current config-file carryover.

## Lane 3 — post-hoc policy (ruled: never gated)

- **3.1 Remove every omnibus gate.** A post-hoc the user chose always
  runs, on every door. Sites include the wizard's
  `emlOneWayAnova.p < 0.05` gate (`eml-wizard.praat:700`) and the graph
  bridge's significance-derived Dunn (`eml-annotation-procedures.praat:
  2829` and the bridge report's `.doDunn` derivation). The hardcoded .05
  disappears with the gates.
- **3.2 Labels state the new truth.** "if ANOVA significant" clauses come
  off the wizard's post-hoc rows; the rows name test + adjustment only.
- **3.3 Cautionary explainer.** When the omnibus is not significant and a
  post-hoc ran, the report (with explanations on) adds: "The overall test
  found no significant difference; interpret individual pairs cautiously."
- **3.4 Effect-size matrix caption.** With the post-hoc off, the pairwise
  effect-size matrix keeps printing and gains one line: "Effect sizes
  describe the size of each pairwise difference; no pairwise significance
  tests were run." Uncorrected pairwise p-values are never shown — if
  Fisher's LSD is ever added, it must bring its omnibus gate with it
  (recorded here so the rule survives).
- Acceptance for the lane: a fixture with a non-significant omnibus and a
  chosen post-hoc → post-hoc table present plus the caution line; red demo
  is the current wizard swallowing it.

## Lane 4 — wizard parity ("same analyses" contract)

Language first: the verification session drafts every new row label, page
sentence, and plan-report line as one batch; Ian approves en bloc; only
then does the build start. All labels obey the character law and the
one-list complete-choices pattern; the header-guard idiom is already in
the file.

- **4.1 "Both parametric and nonparametric" rows** on two-group, paired,
  and correlation pages; dispatch passes "both" as the menu door does.
- **4.2 "One-way ANOVA, no post-hoc" and "Kruskal-Wallis alone" rows.**
  The `doDunn = 1` literal becomes the row's choice.
- **4.3 Pairwise grid unfrozen — the WHOLE grid.** The wizard's post-hoc
  rows expand to every complete choice the standalone pairwise dialog
  offers, the rank-based cells included: pairwise Wilcoxon with Holm,
  Bonferroni, and Benjamini-Hochberg join the menu (three rows, decoded
  like the other twelve). The first wording of this item said "parametric
  post-hoc rows" and created a three-row gap the builder correctly
  stayed inside; the lane's acceptance — zero menu-only options on
  shared intents — was always the contract, and the item now says so.
  The two hardcoded `@emlRunPairwiseAnalysis` presets become row-decoded
  arguments.
- **4.4 Per-group correlation.** The wizard correlation page gains the
  menu door's group column (same 2..n/3 filter), passing through to the
  same per-group report.
- **4.5 Regression group column.** Rides the per-group regression port
  already ruled into 1.0; wizard and menu pages gain it together, and
  NOT before — a group column that colours the figure without entering
  the analysis is a new instance of the silent-override class (the
  census measured the cost: slopes of +1.98 and −1.99 pooled to a
  reported zero). The port lands in-round, so no interim colours-only
  control and no interim disclosure line are needed; the menu dialog's
  existing half-live control is closed by the same port.
- **4.6 Normality modes and Q-Q.** The wizard normality page offers
  single / all columns / by group (the orchestrator's own modes) and the
  branch sets `wizCanDraw` so the Q-Q draw is reachable, as on the menu
  door.
- **4.7 Group order dropdown** on the wizard's group-based pages (not the
  RM/Friedman branch, where condition order comes from column slots).
- **4.8 Paired spaghetti columns.** The wizard's paired draw asks for the
  subject column (and optional group column) as the menu wrapper does,
  instead of inventing Subject from row numbers.
- **4.9 Wizard flow-invariant check.** New conformance check: every label
  that is a goto target must have its preserve step (the `@wizardColIdx` /
  `@wizardCondSlot` write-back of the user's answers) between the label
  and its `beginPause`, so no jump can re-render a page showing the guess
  instead of the user's choices — the bug class this file has re-fixed at
  least three times. Red demo: remove one preserve step. The check covers
  the wizard's whole label set and reports how many it examined
  (anti-vacuous). The structural rewrite of the flow itself is out of this
  round; a state-machine restructure is a candidate phase after 1.0.
- Acceptance for the lane: the wizard-vs-menu capability matrix re-derived
  after the build shows zero menu-only options on shared intents; each new
  row drives to the same engine call its menu sibling makes (transcript
  equality on a shared fixture).

## Lane 5 — normality honesty

- **5.1 Coverage statement.** `@wizardNormCheck` group mode and the
  standalone checker both state coverage: "2 of 3 groups assessed;
  Alto (n = 2) too small to test." An incomplete assessment's summary and
  recommendation say "based on the groups large enough to test"; the
  standalone checker's "no group in this column shows a strong departure"
  is never printed over an unassessed group. Acceptance: fixture with one
  n = 2 group; red demo: current unconditional summary.

## Lane 6 — explanations (ruled routing)

- **6.1 The toggle.** Menu analysis dialogs gain "Annotate results with
  explanations," default off. The wizard is always on (no toggle). A
  figure launched from the wizard inherits on; a figure launched from a
  menu analysis inherits that dialog's toggle; a standalone graph that
  annotates stats is on.
- **6.2 The wiring.** Explanation calls join the orchestrator reporters in
  `eml-analysis.praat` (today the 52 call sites live only in the
  annotation layer, so the wizard's flag is a no-op for its own reports).
  Existing helper texts are reused; any measure lacking one gets its text
  in the language batch for Ian's approval.
- **6.3 Recording.** The toggle is a user choice: it is published to the
  recorder like any display setting, and a recorded script reproduces it.
- Acceptance: one fixture through wizard (explanations present), menu with
  toggle off (absent), menu with toggle on (present), each with identical
  statistics; red demo: wizard report with no explanation after wiring is
  reverted.

## Lane 7 — single-door defects (Sol audit, confirmed by source read)

- **7.1 Signed R.** Delete the `abs()` on the regression REPORT's R line —
  anchor at head `3e34b1a` is `eml-annotation-procedures.praat:5079`
  (drifted from 4997); R prints signed, agreeing with the Direction
  sentence and the explanation beside it. Scope note, checked against the
  bracket ruling (`b3b2a93`): NO CONFLICT — that ruling makes figure
  BRACKETS carry magnitude precisely because "the signed value stays in
  the report, on a line naming the subtraction," which is what this item
  delivers. 7.1 touches the report line only; brackets keep magnitude.
  Check: v13 gains a negative-slope fixture so its existing
  sign-agreement assertion can actually fire (today it only ever sees a
  positive slope).
- **7.2 Native missing values.** `@emlCheckNumericColumn`
  (`eml-graph-procedures.praat:6409-6505`) recognizes Praat's native
  missing cell as missing, per its own cell taxonomy; a column with
  missing values follows the plugin-wide complete-case-with-disclosure
  convention instead of vanishing. Disclosure at the wrapper.
- **7.3 Describe's column sniff.** `eml-describe-table.praat:129-146`
  scans every row, as the sibling guard's own header mandates
  ("SAMPLING IS NOT ENOUGH"); a column whose first rows are missing is
  offered and analyzed complete-case.
- Each ships with the committed check that would have caught it, red-
  demonstrated.

## Lane 8 — census and the frozen-choice ratchet

- **8.1 Census fixtures**, one adversarial fixture per multi-door intent,
  from the audit continuation's seed table: pairwise-vs-Draw (Sol's
  p = .052 → .037 fixture), unequal-spread ANOVA vs Draw, post-hoc opt-out
  vs Draw, paired vs spaghetti, grouped regression (Sol's Simpson fixture
  joins the two-door exhibit), correlation display scope. Each leg asserts
  agreement or a stated different-model line; silent disagreement is the
  only red.
- **8.2 Wizard draw-handoff sites** (correlation/regression draw dropping
  the test choice; the violin default; the missing correction preset) are
  closed by the store bridge, not patched separately; the census legs are
  their acceptance.
- **8.3 Grouped-correlation scope control** ships in 1.0: a three-way
  display choice (overall / per-group / both) on the scatter page, each
  drawn line labeled with its model; until it lands, the figure carries
  the one-line "per-group only" disclosure. Oracle: `cor.test` per scope.
- **8.4 Frozen-choice conformance check.** New lint: an argument passed as
  a literal from a dialog into an analysis engine, where any sibling door
  passes a user-bound choice for the same parameter, is red unless the
  fixed value is disclosed in the output. Ships with the vacuity kit
  (seeded violation red; analyzed-N gate) like the escape-hatch check.

## Lane 9 — error propagation (ruled in full, 25 Aug: nothing known-wrong
ships)

The census (`ERROR_CENSUS_2026-08-25.md`, row data in `error-census/`)
found 63 call sites that mishandle failure: 19 silent, 44 unchecked. All
of them are fixed before the tag. No remainder survives to 1.0.

- **9.1 The four hand fixes, first** (wrong output today):
  `emlRequireNumericColumn` gains its missing else so a missing column
  refuses (`eml-inferential.praat:3042-3078`); the effect-size matrices
  stop zero-filling failed cells — a failed cell prints as unavailable,
  never as 0 (`eml-analysis.praat:369, :652` and siblings); the
  standalone normality checker prints the producer's error text instead
  of undefined W and p; "both" mode discloses a single-arm failure the
  way the two-group report already does (`eml-analysis.praat:1729,
  :1735`).
- **9.2 The error-read lint.** A call to an error-producing procedure
  must be followed by a read of its `.error$` before any numeric output
  of that call is used. Red at every remaining bad site. The
  provably-cannot-fail sites are adjudicated in a committed list with
  the reason written at the site; the list is counted and shrinks-only.
  Ships with the vacuity kit; author is never verifier.
- **9.3 The sweep to zero.** Every site the lint reddens is fixed —
  mechanical, cheap-model work, one site at a time, each caught by the
  lint if done wrong. The proxy pattern (gating on `.n` or `.nGroups`
  instead of `.error$`) is replaced by reading the error and printing
  the producer's own text. The tag is not cut while the lint shows red.
- **9.4 Filed, with reasons stated:** the mixed-model sites live in code
  that is tabled and menu-unreachable by ruling (Phase 4 inherits them,
  named); the unused producer goes to the reachability checker; the
  skip-reason wiring rides item 4.3. Each of these is an adjudication
  with its reason committed, not an unfixed error.

## Sequencing

1. The push happened — remote is `3e34b1a`. One local commit (yesterday's
   pitch work) remains on Opus's side: push it. The legend-ordering
   amendment and the line-chart provisional targets also landed
   (`21c651d`) and leave the queue.
2. Language batch: verification session drafts all Lane 4 and Lane 6
   wording; Ian approves once.
3. Lanes 2, 3, 5, 7 are independent, small, and can fan out now; Lane 1
   continues in parallel; Lane 6 wiring follows its language.
4. Lane 8 fixtures land early (they are the store's acceptance); store
   write site and bridge (1.6) follow them; the unification acceptance
   matrix stays the final gate.
5. Photograph re-drives batch once at the end, per the batching ruling.
   Tab indices are re-measured, not re-derived by counting.

## Acceptance protocol ("buying a house")

The verification session does not watch the build. On Opus's completion
report: every item's acceptance leg is run independently by the
verification session; then one whole-house pass checks what per-item legs
cannot — interactions between fixes, and any behavior change not on this
list, which is flagged like an unpermitted renovation rather than merged
into the report. Sol's fixtures are the inspection instruments. The final
tagged tree is verified end to end as the round's last act.
