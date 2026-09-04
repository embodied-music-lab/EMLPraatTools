# Tracker — kit freeze and plugin 1.0

Source of truth from 1 September 2026; last folded 2 September 2026
(wave 4: MEMO_ORACLE_POLICY, MEMO_RECORDER_NAME_BINDING, and the four
ordered reports — recorder coverage, RM subjectCol, punch intersection,
error propagation — answered by RULING_PORT_ACCEPTANCE,
RULING_RECORDER_AND_WIRING, RULING_PUNCHLIST_AND_ERRORS, all 2 Sep).
Maintained by Fable at every
ruling; Opus corrects statuses by memo, and each correction is folded
here with the memo named. An item's authority is the newest ruling
cited on its line. States: DONE (verified), IN-FLIGHT (with owner),
DECIDED-NOT-STARTED, BLOCKED-ON (named), UNMEASURED (status must be
reported, not assumed).

## A. Kit critical path to the frozen release, in order

1. Reference grid regenerated to its own convergence criterion —
   DONE (reported: 130/130 converged, float64 precision cap fixed;
   re-verified at the gate inspection). Two k=10, df=3 quantile rows
   whose solved q does not reach the stated target must be re-solved
   or relabeled with a NAMED grid floor. [RULING_WAVE_THREE Q1;
   MEMO_ORACLE_POLICY p5b; RULING_PORT_ACCEPTANCE]
2. Port re-accepted — CLOSED 2 Sep night (re-verified at the gate
   inspection like everything else): mesh-width fix (0.005→0.0005)
   converged both k=10, df=3 cells to ~2.7e-10 at no measurable
   cost; v154 grid-only reads 121/121 acceptance cells + 9 labeled
   characterization cells, ZERO failures. Grid forward-row finding
   ruled (RULING_GRID_RELABEL_AND_V150): forward q's were SEEDED
   from scipy's inverse, never solved — every (q,p) pair is TRUE,
   the labels lied → RELABEL all forward rows to actual p +
   provenance header + tier coverage recomputed from actual p +
   root-solve (full-evaluation verified) only where a tier is empty;
   generator's false-convergence self-check replaced as standard.
   v150 → R-CHARACTERIZATION file (option 3): 449 measurements kept
   as the paper's R map, out of the pass/fail tally, header citing
   RULING_PORT_ACCEPTANCE. [MEMO_GRID_ROWS_NEVER_SOLVED;
   MEMO_V150_SUPERSEDED]
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
     45 public rows — DECIDED-NOT-STARTED
   - survey rows JOIN HERE (RULING_SURVEY_ROWS_ACCEPTED, 3 Sep; Ian
     accepted line-by-line): three FROZEN signatures —
     emlRunReliabilityAnalysis (.tableId, .itemCols$#, .confidence,
     .doInfluence; no measure selector — siblings later, Praat
     positional args), emlRunCategoricalAnalysis (.tableId, .rowCol$,
     .colCol$, .countCol$, .correction), emlRunProportionAnalysis
     (.tableId, .col$, .successValue$, .countCol$, .confidence;
     Wilson option 2). .countCol$ convention: empty = raw rows,
     named = pre-aggregated counts (weight-cases/xtabs analog).
     Kernel cells (22/8/8/27) stay; each row gains doorway kit cells
     pre-freeze (missing-data listwise case; low-expected-count +
     pre-aggregated cases; raw + pre-aggregated cases). Old stub
     skeleton kept, .raterCols$/pipe signature dies.
     STATUS 3 Sep midday: ALL THREE DOORWAYS BUILT to the frozen
     signatures; registry AT 45 committed as the one settlement
     change; doorway cells c0676-c0689 green vs independent scipy
     oracle; settlement gate 118/118, door-chain check 10/10
     (computed exemption now EMPTY — psychometrics + categorical
     each lost theirs by gaining a door); record_e2e 38/38 PASS
     incl. twoway. RULING_SETTLEMENT_QUESTIONS (3 Sep) added:
     influence vector exported onto reliability doorway namespace
     (not printed) + k=2 doorway fixture with properly-worded
     when-clause; LMM dead block in eml-wizard.praat:2865 = 4c
     documented exemption for the freeze (expiry: navigation
     returns or block removed; fate decided post-1.0);
     .countCol$ lives in matrix.tsv col_c (accepted); absd prints
     UNSIGNED under any sort order (settings/probe +7.07 accepted,
     old −7.07 was display defect). Task 4: 24/28 live dirs
     regenerated (snapshots + break outputs correctly keep retired
     names — three-populations reading accepted); open: linetree,
     secondaxis, replay.sh retarget diagnosis. NEW 1.0-round item:
     unseeded-form-globals sweep as a CHECK (scatterCorrScope
     class), error-sweep pattern, not blocking freeze.
   - annotation bridge unified onto the Family A dispatch,
     equivalence probes before/after + red demo
     [RULING_REGISTRY_VERDICTS §4]
   - recorder hooks: census DONE (REPORT_RECORDER_COVERAGE — the two
     ruled gaps are the ONLY gaps among 43 rows; emitting site named
     per row); the two hooks themselves are settlement-packet Task 3
     [RULING_REGISTRY_VERDICTS §2; RULING_RECORDER_AND_WIRING]
   - recorder binding: v159 §E promoted to FAILING checks (every row
     reachable or documented unreachable-by-kind; no retired name in
     recorder strings; explicit exemption table — first entry
     emlRunReliabilityAnalysis with the census §2 proof). Generation
     from the registry filed post-1.0. [RULING_RECORDER_AND_WIRING]
   - LMM exclusion entry (implemented, doors withdrawn, public
     post-1.0); registry at 45 rows (42 + three survey rows)
     [RULING_REGISTRY_VERDICTS §1; RULING_SURVEY_ROWS_ACCEPTED]
   - registry wiring: docs, barrel, Table S2 GENERATED from the
     registry (currently honest attestations say not wired)
     [RULING_PUBLIC_SURFACE mechanism 3]
   - RM signature — SETTLED BY IAN 2 Sep, one edit in the judgment
     half [RULING_RM_FORMATS]: RM + Friedman accept WIDE AND LONG
     (Ian: match how users format tables); .subjectCol$ is WIRED as
     the long path's subject column (remove-vs-wire CLOSED); string
     vector for conditionCols; pipe form ceases to exist (Ian: no
     backward compatibility). Both shapes converge to the one kernel
     via the reshape canon, per the series-door melt/pivot precedent;
     recorder replays the real conversion; long path gains
     completeness/duplicate refusals; equivalence probe + red demo +
     long-form R-oracle leg ordered. Opus proposes the exact final
     signature against the pins; Fable accepts; then it freezes.
   - RM .subjectCol$: report DELIVERED (REPORT_RM_SUBJECTCOL: dead
     from the first commit, read nowhere, every caller passes "";
     same for Friedman) — WITH IAN for wire-or-remove; natural
     removal moment is the string-vector resettling, which changes
     the signature anyway [RULING_REGISTRY_VERDICTS §3]
   - punch-list items 7+ ∩ waves intersection: DELIVERED and RULED —
     fold-ins: 8.1 leg1 + 8.4's Dunn literal into the bridge
     unification acceptance (v127 + v116 re-run there); 68
     wave-surface lint sites sequenced with the outcome contract;
     LMM lint sites into EXEMPT_SITES in the exclusion-entry commit.
     The "8.5" citation was Fable's error — struck (no such item).
     [RULING_PUNCHLIST_AND_ERRORS]
   - two-way kernel: kit route WIRED and matching car (v88 14/14) —
     but the INTERACTIVE DOOR is broken (census §4: the hand-maintained
     door barrel never gained eml-anova-kernel; v88 checks the wrong
     copy). Fix + barrel-agreement check ordered in the two-way lane;
     acceptance = TWOWAY_OK through the real door chain + record_e2e's
     twoway op completes. [RULING_RECORDER_AND_WIRING]
   - one-extraction-per-case: DONE (743 assertions, values unchanged)
   - EMMs, post-hoc on EMMs, simple effects: LANDED (2345/2352,
     pooled error = emmeans::joint_tests) — wiring state verified at
     the gate inspection
   - result-state/LMM stale export (v153): DONE (redone properly)
   - Wilcoxon H-L interval, approx branch = port of R's corrected-z
     inversion (intervals item 3.8, IN 1.0 by Ian's completeness
     ruling) — REPORTED BUILT with tests registered (commit e21b7b6,
     2 Sep); artifact citation to be confirmed at the gate; carries
     the port-attribution header rule
   - re-pointing grep-check: Get TukeyQ / Get invTukeyQ nowhere
     outside the port's file at landing [RULING_WAVE_THREE §track]
6. Kit re-points to the canonical route; D-WORDING re-measures.
   DECIDED-NOT-STARTED. (Wrapper equivalence struck: the wrappers it
   named no longer exist, so there is nothing to probe for equivalence.)
7. grand_ledger BUILT (REPORT_GRAND_LEDGER 2 Sep): 8 counts MEASURED
   live, 7 AWAITING_RUN by design; refuses stale citations — the kit's
   current result files span THREE generations (praat_results 31 Aug <
   matrix.tsv 1 Sep; VERDICT.txt older than both; 667→669 cells), so
   NO number leaves VERDICT.txt until A.8. No interim re-drive
   (ruled). Ordered: run_all.R writes validate/RUN_ALL_SUMMARY.tsv.
   [RULING_SPLIT_AND_ACCEPTANCE]
8. Authoritative run on Ian's machine at a PUSHED commit; version
   asserted as PROVENANCE, build info recorded unasserted;
   environment capture DONE, run NOT RUN. Acceptance rules
   (ACCEPTANCE_RULES.md) + forest_plot.R BUILT 2 Sep — must be
   COMMITTED before the run (ordered). NIST R-unavailable cell =
   named R_UNAVAILABLE finding, blocks green until adjudicated;
   forest plot Tier B only, NIST margin panel = Ian/Sol at drafting.
   [RULING_SPLIT_AND_ACCEPTANCE]
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
- Table S2 = the 45 canonical rows (42 + survey), generated from
  the registry.
- Version assertion described as provenance, in those words.
- Census bright line: methods ours; host may supply special
  functions only under continuous kit measurement incl. far tail.
- Possible upstream R bug report (Ian's call; evidence ready).

## C. What "procedures tested" honestly means right now

- The 27 Aug certification record: 17 analysis procedures
  contract-complete, 624 cells, 10,841 comparisons on Ian's machine
  at 98729af. That number is the last CERTIFIED count.
- The public surface for 1.0 is 45 registry rows — but the kit
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
- Survey module — CLOSED by Ian, 3 Sep, single authority =
  RULING_SURVEY_FINAL ("Kit includes survey api. Plugin includes
  survey doorways"; supersedes all four earlier survey files):
  (1) KIT API INCLUDES THE SURVEY API — survey rows join the
  registry IN THE SETTLEMENT WAVE; registry leaves 42; S2 / gate
  row-count / docs generation / coverage map move with it; the four
  kernels are already among the kit's 17 validated procedures, any
  survey entry procedure's coverage stated per-row by the map.
  (2) PLUGIN 1.0 INCLUDES THE SURVEY DOORWAYS — built post-freeze in
  the doorway-reconciliation round (lane's wizard work reused, its
  gates binding); freeze-time state = rows public/callable, doors
  not yet. (3) Kit resolves first: freeze → doorway round → 1.0.
  (4) ONLY LMM defers past 1.0. The blocker RESOLVED 3 Sep:
  PROPOSAL_SURVEY_ROWS ruled via RULING_SURVEY_ROWS_ACCEPTED (Ian
  accepted line-by-line; three frozen signatures — see §A settlement
  wave; registry 42 → 45). Merge status closed by the proposal
  itself (survey code already in the plugin tree, module table
  indices 7/8); stub skeleton kept, signature rebuilt. Settlement
  registry work UNBLOCKED.
- Error-propagation sweep: IN the 1.0 round pre-tag by Ian's
  emphatic ruling — MEASURED, NOT DONE (REPORT_ERROR_PROPAGATION,
  2 Sep): 135 raw violations / 121 unique, EXEMPT_SITES empty, v134
  gate red. The old "63 sites" figure was the 25 Aug census at
  3e34b1a and is not comparable at line grain. Census verdicts:
  31 SAFE (pre-approved for EXEMPT_SITES with reasons), 9 need the
  named runtime checks, 76 UNSAFE (fix population — priority:
  eml_getGroupData proxy cluster ×33 in the core engine, the
  Pearson/Spearman sibling-drift one-liner, skew/kurtosis), LMM
  sites exempted with the exclusion entry. v134 green IS the
  acceptance; the tag does not ship over a red gate.
  [RULING_PUNCHLIST_AND_ERRORS]
- 8.1 leg4, NAMED so it cannot be lost: the spaghetti plot prints no
  inferential statistic while the paired door does — a silent
  disagreement. Post-kit (touches no wave surface); the unification
  round's business. [RULING_PUNCHLIST_AND_ERRORS]
- Plugin manager (separate repo, v0.7.0 shipped; catalog phase
  awaits kit freeze for its first real row).

## E. Immediate report requests to Opus (statuses, not work)

ALL FILLED as of 2 Sep second batch. Coverage map DONE
(REPORT_COVERAGE_MAP: 43 rows = 13 numerically covered + 28 correct
by kind + 2 genuine gaps, both already-ordered fixes; generated by
build_coverage_map.py, diff-verified). Error triage DONE
(REPORT_ERROR_TRIAGE: 82 FIX / 53 SAFE decision table for Ian;
3 root-finder sites upgraded to SAFE on full proof, 6 not-sure run
their named checks first per ruling). Rename inventory DONE
(3000 line-sites, 83% regenerated harness output; delegate
reconciles vs list_sites.sh before editing).

SETTLEMENT SPLIT RULED (RULING_SPLIT_AND_ACCEPTANCE): the wave may
run as two sessions — mechanical half delegated (renames, registry
42 + exclusion, two hooks, regeneration) AFTER Opus promotes v159 §E
to failing checks; judgment half held by Opus (outcome contract +
error fixes, bridge unification, RM signature edit once Ian rules
.subjectCol$). Packet awaits Ian's push.

IAN RULED 2 Sep (evening): melt approach APPROVED → RULING_RM_FORMATS
(both shapes; .subjectCol$ wired); 82/53 triage APPROVED →
RULING_ERROR_TRIAGE_APPROVED (fix 82 by priority; 6 unsure run named
checks first; 53 filed to EXEMPT_SITES with reasons; v134 green
before tag). WITH IAN still: the settlement-bundle push (pre-merge
`git add mailbox && git commit` now required — mailbox is tracked);
the upstream R bug report (draft delivered, filing = his call).

RM SIGNATURE ACCEPTED (RULING_RM_SIGNATURE_ACCEPTED, 2 Sep late):
.tableId, .format$("wide"/"long"), .subjectCol$, .conditionCols$#,
.conditionCol$, .valueCol$, .doPostHoc, .adjMethod$ — frozen; and
the reshape pair ALSO moves to string vectors (comma form dies with
the pipe form; one list convention on the public surface;
equivalence probes + red demo for the reshape pair).

PROTOCOL ARTIFACTS (RULING_PROTOCOL_ARTIFACTS): claims ledger EXISTS
(planning/CLAIMS_EVIDENCE_LEDGER_2026-09-02; keys to section B now,
re-keys to Sol's draft later; v160 + package_run.sh COMMITTED same
day; ledger's two defects — half-fixed row 9, unescaped pipes —
were Fable's, fixed and redelivered). Port work (grid-only
re-point, df=3 diagnostic, domain flag) IN-FLIGHT at Opus.

DELEGATE RAN AND STOPPED CORRECTLY 2 Sep night (out/REPORT.md;
RULING_SETTLEMENT_STOP): sync gate met its own stop condition —
local/origin diverged (same 14-file delivery committed twice;
local ⊇ origin). Nothing touched; read-only baselines taken.
Findings adjudicated: baseline docs update to 117/72/45 + stale §E
docstring (Opus); 13 E3 empty-filename rows = census's elided
":<line>" references taken literally in the TSV extraction — fill
with graphs/eml-draw-procedures.praat (Opus); run_all.R manifest
gains v158–v160 + RUN_ALL_SUMMARY.tsv in one edit (Opus); 222→227
touches = likely Fable's delivered historical docs — classify, and
extend the historical exclusion to dated planning/ records with
list_sites.sh and v159 sharing ONE scope (Opus). RELAUNCH after:
Ian's merge+push → Opus's four small fixes → same work order.

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
