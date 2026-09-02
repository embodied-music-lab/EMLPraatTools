# Study design module — planning document

Verification session, 25 Aug 2026. This document cuts the study-design
vision from the 17 August suite direction into a buildable phase with a
contract, dependencies, oracles, and gates, in the roadmap's own format.
It is a plan for Ian's approval, not a work order; nothing here is
scheduled until it enters `ROADMAP.md`.

## What the module is

The study design module moves the plugin's help from after data collection
to before it. Today every door begins with a table that already exists;
every design mistake — too few subjects, replicates that get averaged away,
a directional hypothesis adopted after the fact — has already happened by
the time the plugin sees the data. The module adds a planning wizard that
asks the design questions first, computes the sample size the plan needs,
and writes the plan to disk as a small set of CSV files. Analysis then
reads the plan back: the wizard arrives pre-filled with the tests the plan
named, and the report states whether the analysis followed the plan.

Pre-registration falls out as a byproduct, not a ceremony: the file the
planning wizard writes IS the pre-registration record, created because it
is useful for running the study, not as paperwork.

## Who it serves

The plugin's audience runs studies of exactly the shape this helps most:
pre/post designs, small samples, repeated measures, voice tokens nested in
subjects. These are the designs where sample-size planning is most often
skipped and where replicate handling silently changes the effective n.

## Design principles, inherited

- The wizard shows evidence and never decides. Power curves, detectable
  effects, and assumption trade-offs are displayed; the user chooses.
- Overrides are never silent. An analysis that departs from the plan runs
  — the module never blocks — but the report says plainly what the plan
  named and what ran instead.
- Impossible by construction where possible. The plan file's schema cannot
  express an invalid design (a within-subject factor with one level, a
  direction on a test that has none).
- Validity the software can check is checked; validity it cannot check is
  stated, not implied. See the pre-registration honesty section.

## The artifact set

Three CSV files, human-readable, diff-able, and committed to wherever the
user keeps their study:

- `study.csv` — the plan. One row per declared element: design type,
  factors and their levels (in the terminology rulings' vocabulary:
  condition, within-subject, token, measurement), the measurement
  column(s), planned test family, alpha, the directional hypothesis if
  one is declared, target power, and the planned n the power engine
  produced, with the assumptions it rests on.
- `roster.csv` — collection tracking. One row per subject or session:
  identifier, date, status. Written and updated during collection so the
  corpus folder always states how far the study has progressed against
  the planned n.
- `manifest.csv` — the corpus map. One row per data file: path, subject,
  session, checksum. This is the batch layer's index; a corpus folder
  plus its manifest is the module's unit of analysis.

The schema ships as a documented, versioned format with a validator —
the same standard as everything else: a check that reads a plan file and
refuses a malformed one with the teaching-message contract.

## The flow

**Plan.** The planning wizard asks the design questions in the analysis
wizard's own style — what is measured, on whom, under how many
conditions, between or within subjects, how many tokens per cell — then
the hypothesis questions: which comparison matters, is a direction
declared, what alpha, what power. It computes required n (Phase 1p
engine), shows the power curve and the detectable-effect trade-off, and
writes `study.csv`. For repeated designs it also asks the token question
and records the planned aggregation, so the reliability statistics
(Phase 1 ICC work) have their declared home.

**Collect.** The user fills the corpus folder; `roster.csv` tracks
progress against planned n. The module offers a status command: planned
40, collected 28, 12 remaining.

**Analyze.** The analysis wizard, offered a table or corpus whose folder
holds a `study.csv`, opens pre-filled: the planned test selected, alpha
set, direction applied if declared, condition columns mapped by the
plan's names. Every pre-filled value is visible and changeable — the
plan is a default, never a lock.

**Report.** The report gains a plan block: "Planned: Welch t, alpha .05,
directional (post > pre), n = 40 planned / 38 analyzed. Departures:
none." A departure — different test, different alpha, direction dropped,
n short — is listed by name. The block is disclosure, not judgment: the
module states the departure and never scolds.

## Where one-tailed tests live

The direction question is asked exactly once, at planning time, where
declaring a direction means something. The analysis layer's one-tailed
entry points (built, oracled by the committed one-tailed direction
check) are invoked only when a plan declares a direction; no bare
one-tailed toggle appears on any analysis dialog. The report's plan
block always restates the declared direction beside the result.

## Pre-registration honesty

The module makes the commitment recordable, not provable. `study.csv`
carries its creation date and the analysis report cites it, but the
plugin cannot prove the file predates the data — that guarantee requires
an external timestamp, and the documentation says so plainly, pointing
users who need provable pre-registration to deposit the plan file with
their registry of choice (OSF or equivalent). The module's claim is
narrower and true: the plan was written as a file, the analysis read it,
and the report states every departure.

## Dependencies

1. **Phase 1p, classical power** — the computational core. Already
   contracted in `ROADMAP.md`: power, sample size, and detectable effect
   for t (one-sample, paired, two-sample), one-way and factorial ANOVA,
   correlation, and proportions; oracles R `pwr` and `MBESS`, G*Power
   reference cases; not gated on mixed models.
2. **Phase 1 aggregation and ICC** — required for the token question:
   planned aggregation, reliability, and effective n disclosed where the
   collapse happens.
3. **Wizard parity (current round)** — the planning wizard reuses the
   analysis wizard's page machinery, language conventions, and the
   flow-invariant check; building it before parity lands would copy the
   pre-parity idioms.
4. **The result store** — the plan block joins the stored result's
   identity so a figure drawn from a planned analysis carries the plan
   linkage.

## Oracles and checks

- Power numbers: `pwr`/`MBESS` to printed precision; G*Power screenshots
  archived for the reference cases (machine-bound evidence rules apply).
- Schema round trip: a plan written by the wizard, read back, re-renders
  the identical wizard state — byte-stable across a write-read-write
  cycle.
- Deviation detection: seeded departures (test swapped, alpha changed,
  direction dropped, n short) must each produce their named line in the
  plan block; a run with no departures must say "none" (anti-vacuous:
  the block states what it compared).
- Direction wiring: a declared direction must reach the one-tailed entry
  point and the report; the known-direction fixture from the direction
  line's acceptance check is reused.
- Malformed plans: the validator refuses with the rule, the reason, and
  the correct form; red demos seeded per the mutation standard.

## Explicit non-goals

- Not an OSF replacement and not a provable timestamp (stated in-product).
- No mixed-model or simulation-based power until Phase 4; a plan
  declaring a mixed design gets a plain refusal naming Phase 4, never a
  wrong number from a classical formula.
- No enforcement. The plan pre-fills and discloses; it never locks a
  control or blocks an analysis.
- No new statistics. Every test the planning wizard can name is a test
  the analysis layer already ships with a passing oracle.

## Sequencing and gate

After 1.0, after Phase 1p, after Phase 1 aggregation, alongside or after
the survey workflow phase (they share the corpus/manifest layer — build
that layer once). Entry condition: the door and unification round closed
and the release tagged, so the plan block lands on stable report text.

## Deliverables when scheduled

1. Schema specification and validator for the three files.
2. The planning wizard (pages, language batch through Ian, photographed
   evidence per house standard).
3. Analysis-side plan reading, pre-fill, and the plan block.
4. Roster/status command.
5. The oracle and check set above, red-demonstrated.
6. Documentation: one user page (plan a study), one reference page (the
   schema), one honesty page (what pre-registration here does and does
   not prove).
