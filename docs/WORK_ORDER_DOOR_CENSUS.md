# Work order — the door-agreement census

Verification session → executing session, 20 Aug 2026, on Ian's authority.
Born from the two-door regression exhibit and Ian's question "what else
has diverged?" — this converts that question from an anxiety into a suite.

## 0. The classification rule (new standing law, from Ian's correction)

**BEHAVIOR IS NOT INTENT.** When a census leg (or any finding) shows a
control's promise and the code's behavior disagreeing, the FIRST
determination is which side is the defect — settled by evidence: sibling
implementations, the label's own wording, dev history, design records.
Lowering a label to match behavior requires POSITIVE evidence that the
behavior is the design; absent it, the finding files as SUSPECTED
UNFINISHED IMPLEMENTATION and routes to Ian as scope, not to a wording
fix. (Case study: the regression group column — its "(none — overall
only)" wording and the correlate dialog's complete per-group pattern are
both evidence of intended per-group behavior; the first ruling missed
this and is revised in §3.)

## 1. The census

Enumerate every USER INTENT reachable through two or more doors; for
each, one committed ADVERSARIAL FIXTURE (built like the two-slope table:
divergent mappings must produce loudly different numbers, never
coincidentally equal ones); drive every door on the same fixture; assert
one of exactly two outcomes: (a) same model, same numbers, to oracle
tolerance; or (b) explicitly LABELED different models (as the correlate
dialog labels "(overall)" vs per level). Silent disagreement is the only
red.

Intent inventory (extend if the menu census finds more):

    ASSOCIATION      correlate dialog | regression dialog | scatter
                     annotation | wizard relationship branch
    GROUP COMPARISON compare-2 / compare-k dialogs | wizard compare
                     branch | bar/violin/box/histogram/grouped bridges |
                     pairwise + KW wrappers
    PAIRED / RM      compare-paired menu | wizard paired branch
    DESCRIPTIVES     describe dialogs | wizard describe | error bars &
                     interval bands in every figure type vs the
                     descriptive kernels
    ACOUSTICS        batch measures vs graph-door conversions (the
                     pitch-canon cross-door leg absorbs here)

Existing legs absorbed, not duplicated: the audit's engine-agreement
measurements (item 10 baseline), the pitch cross-door mean-F0 leg, item
10's acceptance matrix (the two-door regression drive is one of its
rows), the KW→violin duplicate scenario.

## 2. Findings already in hand (seed the census red/green board)

a. **Association family, model-mapping divergence (DRIVEN):** correlate
   dialog = overall + per-group, labeled — the REFERENCE implementation;
   regression dialog = overall only with a dead group control (§3);
   scatter annotation = per-group only when grouped, no overall.
   Census target state: all association doors report overall +
   per-group labeled, or state which one they show.
b. **Convention divergence (NEW, from source):** the correlation CI is
   Fisher-z with HARDCODED 1.96 (eml-annotation-procedures, the
   atanh/1.96 block) and therefore ignores annotAlpha, while error bars
   and mean CIs are t-based via invStudentQ honoring alpha — one figure
   can carry a 99% error bar beside a 95% correlation interval. Fix:
   the Fisher interval takes its quantile from annotAlpha
   (invGaussQ (annotAlpha/2) — it is correctly a z-interval, only the
   hardcoding is wrong). Oracle: cor.test at two alphas.
c. **Settings divergence:** already ordered (result store; pitch canon).
d. **Duplicate computation:** already ordered (result store).

## 3. Dead-controls ruling #2, REVISED under the classification rule

Evidence says per-group regression is UNFINISHED DESIGN, not a labeling
defect. Preferred fix: FINISH IT — port the correlate dialog's proven
pattern to the regression dialog: per-group loop over @emlLinearRegression,
per-group n guard (n >= 4 per group; below it, the group is named and
skipped, as correlate names its too-small groups), report = overall fit
first then per-group fits, each labeled; tidy export rows "(overall)" /
"<col> = <level>"; the drawn figure's per-group lines then MATCH the
per-group fits it reports, closing the two-door exhibit for this family
at the source. Oracles: R lm per group + overall, committed fixture.
RULED IN, 1.0 (Ian, 20 Aug): the port lands in this release; the
relabel is void. The census leg is written against the finished state
and is expected-red only until the port's commit.

## 4. Mechanics

- Census legs live with the validators, base-R oracles per the charter;
  driven doors use the GUI harness where the door is a dialog (the
  recipe's rig) and direct kernel calls where it is an API.
- Author ≠ verifier: you build the legs; verification re-drives a sample
  with fresh fixtures (different seeds, same adversarial structure).
- Every leg's fixture is committed; every red is a ledger row classified
  per §0 before any fix is proposed.
- Report the intent inventory back with any doors this order missed —
  the enumeration above is from the menu map and may be incomplete;
  completeness of the inventory is itself a deliverable.

DONE WHEN: the intent inventory is confirmed complete against the menu
census; every intent has its fixture and its legs; the board shows every
leg green or expected-red with a ledger row; the 1.96 fix is in with its
two-alpha oracle; and the §3 decision is recorded either way with its
leg in the matching state.

— verification session
