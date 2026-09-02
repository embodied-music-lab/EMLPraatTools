# Tracker — kit freeze and plugin 1.0

Source of truth from 1 September 2026. Maintained by Fable at every
ruling; Opus corrects statuses by memo, and each correction is folded
here with the memo named. An item's authority is the newest ruling
cited on its line. States: DONE (verified), IN-FLIGHT (with owner),
DECIDED-NOT-STARTED, BLOCKED-ON (named), UNMEASURED (status must be
reported, not assumed).

## A. Kit critical path to the frozen release, in order

1. Reference grid regenerated to its own convergence criterion
   (48 unconverged rows; 4 quantile cells re-solved) — DECIDED,
   Opus. [RULING_WAVE_THREE Q1]
2. Port re-accepted against the regenerated grid (v154 clean);
   inverse bisection tightened to the standard rule; k=2 exact
   special case (reference there = sqrt(2)·qt). Port currently
   repaired (91/107 vs the unconverged grid) and QUARANTINED.
   [RULING_WAVE_THREE Q2, Q3]
3. invTukeyQ replaced by the port's inverse; 144 interval rows
   revalidate. [RULING_PROVENANCE_AND_CANCELLATION]
4. Class A far-tail cancellation-signature sweep, two-reference gate —
   DONE (verified) [MEMO_STATUS_A4]: all four Q functions agree with
   scipy AND R to ~1e-14 in the far tail; gate never escalates; both
   halves committed and re-runnable (SWEEP_HOST_FUNCTIONS.praat +
   check_classA_two_reference.py). Class A confirmed free of the
   cancellation signature. [RULING_UNIQUENESS_SWEEP]
5. Pre-run settlement wave (one pass, all before the authoritative
   run) [RULING_CONSOLIDATED_KERNELS sequence; WORK_ORDER_API_SETTLEMENT]:
   - straight renames to the ACCEPTED canonical set (6 renames + 37
     unchanged; no wrappers) [NOTE_NAMES_ACCEPTED; MEMO_NO_WRAPPERS]
   - uniform outcome contract (.ok / .error$ / .warning$) across the
     42 public rows — DECIDED-NOT-STARTED
   - annotation bridge unified onto the Family A dispatch,
     equivalence probes before/after + red demo
     [RULING_REGISTRY_VERDICTS §4]
   - recorder hooks: emlRunGroupedRegression + emlDrawQQPlot fixed;
     measured recorder-coverage census over every registry row
     [RULING_REGISTRY_VERDICTS §2]
   - LMM exclusion entry (implemented, doors withdrawn, public
     post-1.0); registry at 42 rows [RULING_REGISTRY_VERDICTS §1]
   - registry wiring: docs, barrel, Table S2 GENERATED from the
     registry (currently honest attestations say not wired)
     [RULING_PUBLIC_SURFACE mechanism 3]
   - string-vector RM as canonical with pipe-delimited wrapper
     [WORK_ORDER_API_SETTLEMENT] — UNMEASURED
   - RM .subjectCol$: code-level report to Ian, then wire-or-remove
     [RULING_REGISTRY_VERDICTS §3] — report pending
   - punch-list items 7+ ∩ waves intersection: report to Fable, then
     fold-ins ruled [RULING_REGISTRY_VERDICTS §5] — pending
   - two-way kernel: WIRED and matching car (v88 14/14) — DONE
   - one-extraction-per-case: DONE (743 assertions, values unchanged)
   - EMMs, post-hoc on EMMs, simple effects: LANDED (2345/2352,
     pooled error = emmeans::joint_tests) — wiring state verified at
     the gate inspection
   - result-state/LMM stale export (v153): DONE (redone properly)
   - Wilcoxon H-L interval, approx branch = port of R's corrected-z
     inversion (intervals item 3.8, IN 1.0 by Ian's completeness
     ruling) — UNMEASURED; carries the port-attribution header rule
   - re-pointing grep-check: Get TukeyQ / Get invTukeyQ nowhere
     outside the port's file at landing [RULING_WAVE_THREE §track]
6. Kit re-points to the canonical route; wrapper equivalence one
   probe each; D-WORDING re-measures. DECIDED-NOT-STARTED.
7. grand_ledger built; all paper counts come from it (all current
   headline counts are placeholders). DECIDED-NOT-STARTED.
8. Authoritative run on Ian's machine at a PUSHED commit; version
   asserted as PROVENANCE, build info recorded unasserted;
   environment capture (runners record + assert, demonstrated) —
   capture DONE, run NOT RUN. Acceptance rules and forest-plot
   script committed BEFORE the run.
9. Tier B verdict (target derived from the 311 standalone
   quantities; NIST cells LRE-only; nothing from run_29_aug reused).
10. Fable's gate inspection (independent reproduction, buckets,
    bounds, evidence anchors).
11. FREEZE + tag. CI Lane 10 activates at the frozen release.

## B. Paper items riding the freeze (for Sol's drafting session)

- Two-way rewrite framed as a CORRECTNESS fix on effect sums (Khuri
  effect sums wrong at percent level on the manual's own example).
- Coverage-table sentence: one balanced 2×2 fixture, two computing
  cells, could not have detected the two-way defects.
- ptukey story: Praat's catastrophic cancellation (mechanism named);
  R's far-tail inaccuracy (13× at low df; exact-zero underflow at
  extreme cells) with the grid + Monte Carlo evidence; ordinary-alpha
  R≡scipy bit-identity as R's verified-domain map; plugin exact at
  k=2 where R approximates (R-side NOTE).
- R's far-tail defect is SPECIFIC to ptukey, measured: the four
  natively-upper-tail Q functions agree with scipy to fourteen
  digits in the same regime — one function, one identifiable
  construction (1 − CDF subtraction), replaced. The structural
  argument is now measurement. [MEMO_STATUS_A4]
- D-clause table: all retire with the builds except D-WORDING
  (re-measures); R-side findings taxonomy (2 errors, 1 non-error,
  + the k=2 approximation note).
- Table S2 = the 42 canonical rows, generated from the registry.
- Version assertion described as provenance, in those words.
- Census bright line: methods ours; host may supply special
  functions only under continuous kit measurement incl. far tail.
- Possible upstream R bug report (Ian's call; evidence ready).

## C. What "procedures tested" honestly means right now

- The 27 Aug certification record: 17 analysis procedures
  contract-complete, 624 cells, 10,841 comparisons on Ian's machine
  at 98729af. That number is the last CERTIFIED count.
- The public surface for 1.0 is 42 registry rows — but the kit
  numerically validates the ANALYSIS subset, not the 15 drawing
  rows or the utility rows. Table S2 documents the surface; the
  kit's coverage claim must name its subset, not imply 42.
- The paper's final counts (procedures, cells, comparisons) are set
  by grand_ledger at the authoritative run and nowhere else.
- ORDERED with this tracker: a per-registry-row kit-coverage map
  (row → covered by which kit cells / not numerically covered and
  why that is correct for its kind), so the claim is a table, not
  a sentence.

## D. Parked lanes (not kit; resurface on Ian's word or at freeze)

- Doors/unification punch list items 7+ — the post-kit unification
  round, except intersections folded per A.5.
- Language batch items 1-21: approval-ready, awaiting Ian en bloc.
- Wizard/door parity round (WIZARD_HARDCODE_REVIEW).
- Survey module lane (own gates; Stage 2 go, Stage 3 language
  approved; separate from the 1.0 tag).
- Error-propagation sweep: IN the 1.0 round pre-tag by Ian's
  emphatic ruling (4 hand fixes + error$-read lint + all 63 sites
  fixed or adjudicated-safe) — status UNMEASURED, must be reported
  before the tag.
- Plugin manager (separate repo, v0.7.0 shipped; catalog phase
  awaits kit freeze for its first real row).

## E. Immediate report requests to Opus (statuses, not work)

Fill by memo, measured: A.5 RM report; A.5
punch-intersection; A.5 string-vector RM status; A.5 Wilcoxon 3.8
status; D error-sweep status; the per-row coverage map (C).

## F. The existing registers this tracker indexes

This file is the roof, not a replacement. Detail-level authority for
each round stays in its own register, all at the EMLPraatTools root
unless noted:

- PUNCH_LIST_DOORS_UNIFICATION_2026-08-25.md — the adjudicated
  door/unification punch list; "items 7+" in section A.5 and D refer
  to ITS numbering. Item statuses there are UNMEASURED since the
  kit-only period began; the A.5 intersection report re-measures the
  relevant ones.
- ERROR_CENSUS_2026-08-25.md + TSVs — the 63-site error-propagation
  census behind the "not shipping 1.0 with errors" ruling (D).
- LANGUAGE_BATCH_2026-08-25.md — approved-language items 1-21 (+22),
  approval-ready, awaiting Ian en bloc.
- WIZARD_HARDCODE_REVIEW_2026-08-25.md — wizard parity items A1-A9,
  B, C.
- RISK_REGISTER_2026-08-25.md — standing risks.
- planning/SURVEY_MODULE_PLAN + STUDY_DESIGN_MODULE_PLAN — module
  lanes with their own gates.
- mailbox/to-opus/ rulings and work orders — per-topic authority,
  newest file wins; this tracker cites them by name.
- GitHub Issues on EMLPraatTools: enabled, unused (zero open) —
  not part of the system unless Ian adopts it.
