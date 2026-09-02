# Claims-to-evidence ledger — EML validation paper

2 September 2026. One row per paper claim in `TRACKER_KIT_AND_1p0.md`
section B, plus the R-side findings-taxonomy entries carried in
`briefs/FACTS_STATE_DIGEST.md`. Backing artifacts and re-run commands are
quoted only where the record names them; nothing here is invented. Source
for every row is cited inline; the digest (`briefs/FACTS_STATE_DIGEST.md`)
is cited as DIGEST and is itself the established record, not re-derived.

## Summary — flagged rows

**GAP (artifact not yet named anywhere): 2**
1. Row 8 — Table S2 / registry generation wiring (docs, barrel, Table S2
   generated FROM the registry) has no committed generator script named in
   the record; only the *coverage-map* generator (`build_coverage_map.py`)
   exists. The registry→Table S2 generation step itself is described as
   "currently honest attestations say not wired" (tracker line 63-64).
2. Row 11 — "possible upstream R bug report": CLOSED TO
   EXISTS-UNCOMMITTED same day (Fable, 2 Sep) — the draft now exists at
   `planning/DRAFT_R_BUG_REPORT_2026-09-02.md` with two bracketed
   [INSERT exact values from the committed grid] placeholders to fill
   at filing time. Ian's go/no-go on actually filing remains open.

**AWAITING_RUN: 4**
1. Row 1 — Two-way rewrite as correctness fix: kernel not yet built
   (DIGEST: "kernel rewritten... wired for kit route" but interactive
   door fix + barrel-agreement check still ordered; authoritative run
   not done).
2. Row 3 — ptukey story's grid + Monte Carlo evidence for the paper
   figure: individual measurements are committed and re-runnable, but the
   port itself has two unresolved far-tail misses pending "one
   diagnostic pass then fix-or-named-bound" (DIGEST), so the paper's
   final ptukey numbers are not settled.
3. Row 6 — Table S2 = 42 canonical rows generated from the registry:
   generation step gated by v159 (settlement wave, mechanical half),
   not yet run (DIGEST: "currently 1 passing").
4. Row 9 — version assertion as provenance: ruled (wording settled) but
   only takes effect as an actual run record at the authoritative run
   (A.8), which DIGEST states is "NOT RUN."

All other rows are EXISTS-COMMITTED or EXISTS-UNCOMMITTED, cited below.

---

## Ledger

| # | Claim | Backing artifact(s) | Re-run command (if named) | Status |
|---|---|---|---|---|
| 1 | Two-way rewrite is a CORRECTNESS fix on effect sums, not merely precision (Khuri's built-in effect sums are percent-level wrong vs Type II/III on unbalanced data; not just the SS_Error subtraction bug). | `verify_against_car.R` (committed; hand-implemented Type II/III vs `car::Anova` across 4 fixtures incl. Peterson-Barney, worst rel diff 8.8e-15) — MEMO_KHURI_EFFECT_SUMS_2026-09-01.md, to-fable. `walkthrough/kit/twoway_red_demo/three_level_khuri_vs_type3.R` (3x2 unbalanced separator case) — MEMO_TWOWAY_RED_DEMO_2026-08-31.md. Kernel itself: rewritten per DIGEST but "wired for kit route" only; interactive-door fix + barrel-agreement check still ordered (DIGEST). | Not named for the kernel rebuild itself. `verify_against_car.R` re-run command not quoted in the memo (script named, invocation not given). | AWAITING_RUN (evidence for the correctness claim is committed; the rewritten kernel's own kit validation is not yet complete — DIGEST: barrel-agreement check ordered, authoritative run pending). |
| 2 | Coverage-table sentence: the certified two-way coverage (one balanced 2×2 fixture, two computing cells) could not have detected the Khuri/two-way defects. | MEMO_TUKEYQ_CANCELLATION_2026-09-01.md, to-fable ("the kit has three two-way cells, all on one fixture, `v11_twoway_input`... two cells actually compute a two-way table"). Corroborated by MEMO_TWOWAY_RED_DEMO_2026-08-31.md's fixture-imbalance analysis. | None named. | EXISTS-COMMITTED (the fixture facts are measured and stated in a committed memo; no script re-run command was quoted for the fixture-count measurement itself). |
| 3 | ptukey story: Praat's catastrophic-cancellation mechanism (named); R's far-tail inaccuracy (13.6× at low df, exact-zero underflow at k=10,df=3) with grid + Monte Carlo evidence; ordinary-alpha R≡scipy bit-identity; plugin exact at k=2 where R approximates (R-side NOTE). | Mechanism + build-sensitivity sweep: MEMO_TUKEYQ_CANCELLATION_2026-09-01.md (Get TukeyQ sweep table, no script filename given for that particular sweep). Two-reference gate (Class A clean, ptukey-specific): `walkthrough/kit/SWEEP_HOST_FUNCTIONS.praat` + `walkthrough/kit/check_classA_two_reference.py`, committed — MEMO_STATUS_A4_2026-09-01.md. Arbitration vs the 130-pt grid: `validate/v154_srange_against_reference.R`, `walkthrough/kit/audit/arbitrate_v154.R`, evidence files `walkthrough/kit/audit/v154_cells.tsv`, `v154_arbitration.tsv`, `v154_arbitration_forward.tsv` — MEMO_ORACLE_POLICY_2026-09-02.md. Monte Carlo (120M draws) and R-vs-scipy far-tail figures: `briefs/FACTS_R_BUG_REPORT.md` (fact sheet, cites the same underlying measurements; no separate MC script path given). k=2 exact identity note: `RULING_WAVE_THREE_2026-09-01.md`. | `$ cd walkthrough/kit && python3 check_classA_two_reference.py` (MEMO_STATUS_A4). `Rscript validate/v154_srange_against_reference.R` then `Rscript walkthrough/kit/audit/arbitrate_v154.R` (MEMO_ORACLE_POLICY). | AWAITING_RUN (component measurements are committed and re-runnable, but the port has two named far-tail misses at k=10,df=3 pending "one diagnostic pass then fix-or-named-bound" — DIGEST — so the ptukey story's final numbers for the paper are not yet frozen). |
| 4 | R's far-tail defect is specific to ptukey: the four natively-upper-tail Class A Q functions (gaussQ, studentQ, chiSquareQ, fisherQ) agree with scipy to 1e-14 in the same regime; one function, one construction (1−CDF), replaced. [MEMO_STATUS_A4] | `walkthrough/kit/SWEEP_HOST_FUNCTIONS.praat`, `walkthrough/kit/check_classA_two_reference.py` — both committed, MEMO_STATUS_A4_2026-09-01.md, to-fable. Status line: "A4: DONE (verified)." | `$ cd walkthrough/kit && python3 check_classA_two_reference.py` (quoted output in the memo: 0 cells requiring escalation across gaussQ/studentQ/chiSquareQ/fisherQ). | EXISTS-COMMITTED. |
| 5 | D-clause table: all clauses retire with the builds except D-WORDING (re-measures); R-side findings taxonomy = 2 errors, 1 non-error, + the k=2 approximation note. | Target-state clause list: RULING_SCOPE_CORRECTION_2026-09-01.md ("D-TWOWAY-PRECISION retires with the two-way build; D-WILCOXEST, D-ALPHA2ITEM, and D-ALPHADROP stay as R-side documentation; D-PTUKEY and D-PTUKEY-MID retire or get honest rewritten text per Ian's ptukey ruling; D-WORDING stays and re-measures"). Taxonomy write-up (2 errors, 1 non-error): `README.md` ("Errors this kit has found" — effectsize 0.8.6 paired rank-biserial sign loss; psych::alpha 2-item −3.0 vs −8/3; wilcox.test H-L uniroot ~4e-5, not an error). k=2 note: `briefs/FACTS_R_BUG_REPORT.md`. Underlying disagreement rows: `disagreements_all.tsv` (wilcox_r / *_diff_wilcoxest rows, "measured family is 261 rows"). | None named for regenerating the taxonomy write-up; `disagreements_all.tsv` is itself compare.R's output but the compare.R invocation is not quoted in these citations. | EXISTS-COMMITTED for the taxonomy (README.md, disagreements_all.tsv, both on disk from the 27 Aug certified record at 98729af per DIGEST). AWAITING_RUN for the D-clause table's final state, since D-TWOWAY-PRECISION/D-PTUKEY/D-PTUKEY-MID retirement depends on builds not yet through the authoritative run. |
| 6 | Table S2 = the 42 canonical rows, generated from the registry. | Row-count ruling: RULING_WAVE_TWO_2026-09-01.md ("44 rows minus the stub is the Table S2 row count"); RULING_PUBLIC_SURFACE_2026-09-01.md ("Table S2's row count is the registry's row count... docs, the barrel, and Table S2 are GENERATED from the registry"). Generation mechanism itself: **no script path is named** for the registry→Table S2 step; tracker (line 63-64) records it as ordered work, not yet wired: "registry wiring: docs, barrel, Table S2 GENERATED from the registry (currently honest attestations say not wired)." | Not named. | AWAITING_RUN (gated by v159, settlement wave mechanical half, DIGEST: "currently 1 passing"). |
| 7 | Version assertion described as provenance, in those words. | RULING_PROVENANCE_AND_CANCELLATION_2026-09-01.md ("the version assertion is a provenance record, not a reproducibility guarantee... the run additionally RECORDS whatever build-identifying information the environment exposes"). This is a ruling on wording, not yet an executed run record. | None (the assertion is written into the authoritative run's own output at run time; no separate script named). | AWAITING_RUN (DIGEST: "Authoritative run (A.8): NOT RUN"). |
| 8 | Census bright line: methods ours; host may supply special functions only under continuous kit measurement including far tail. | RULING_CONSOLIDATED_KERNELS_2026-09-01.md §1 ("Class A — elementary distribution tails: KEEP... Bright line: statistical METHODS are ours; special functions may come from the host, on condition of continuous measured agreement — which the kit provides by construction"), ratified by Ian per the same ruling. Measurement backing the "continuous... including far tail" clause: MEMO_STATUS_A4_2026-09-01.md's two-reference gate (row 4 above). | `$ cd walkthrough/kit && python3 check_classA_two_reference.py` (same as row 4). | EXISTS-COMMITTED. |
| 9 | Possible upstream R bug report (Ian's call; evidence ready). | `briefs/FACTS_R_BUG_REPORT.md` (fact sheet: findings 1 and 2, the k=2 note, style/format requirements for a Bugzilla submission). No drafted report file and no submission exist in the record. Ian's decision is explicitly open (RULING_SCOPE_CORRECTION_2026-09-01.md: ptukey disposition is "Ian's call... Both are defensible; neither is mine or Opus's to pick"). | None (no draft to re-run; underlying figures re-run via `validate/v154_srange_against_reference.R` / `arbitrate_v154.R`, see row 3). | GAP — the fact sheet exists, but the report artifact itself (the draft named in this delegation's own task list, "R bug report draft") is not yet written, and no file path for it exists anywhere in the record. |
| 10 | Coverage claim must name its subset (17 analysis procedures numerically validated, not all 42 registry rows); per-registry-row kit-coverage map ordered so the claim is a table. | `walkthrough/kit/coverage_map.tsv` (43 rows, one per REGISTRY.tsv row) + `walkthrough/kit/build_coverage_map.py` (generator) — REPORT_COVERAGE_MAP_2026-09-02.md, to-fable. Verified via diff/md5sum in the same report. | `python3 walkthrough/kit/build_coverage_map.py > walkthrough/kit/coverage_map.tsv` (REPORT_COVERAGE_MAP_2026-09-02.md). | EXISTS-COMMITTED (per the report; committed status not independently re-confirmed here — report states the file and script are on disk and reproducing bit-identically). |
| 11 | Table S2/registry generation wiring — no committed generator script named for the registry→Table S2/docs/barrel step. | None named. Tracker (TRACKER_KIT_AND_1p0.md line 63-64) records the step as ordered, unwired: "registry wiring: docs, barrel, Table S2 GENERATED from the registry (currently honest attestations say not wired) [RULING_PUBLIC_SURFACE mechanism 3]." | Not named. | GAP — would need a committed `generate_registry_outputs`-type script (docs + barrel + Table S2 from `REGISTRY.tsv`), analogous to `build_coverage_map.py` but for the registry surface itself; no such path exists yet in the record. |
| 12 | R-side findings taxonomy entry — `effectsize` 0.8.6 loses sign on paired rank-biserial correlation when all differences share one magnitude. | `README.md` ("Errors this kit has found," item 1). Underlying rows: `disagreements_all.tsv`. | None named. | EXISTS-COMMITTED. |
| 13 | R-side findings taxonomy entry — `psych::alpha` two-item alpha-if-deleted disagrees with definition (−3.0 vs −8/3 exactly). | `README.md` ("Errors this kit has found," item 2); ratified as R-side, nothing to build, in RULING_SCOPE_CORRECTION_2026-09-01.md. | None named. | EXISTS-COMMITTED. |
| 14 | R-side findings taxonomy entry — `wilcox.test` Hodges-Lehmann uniroot artifact on the approximation branch, ~4e-5 from the exact-branch definitional answer (not an error; documented). | `README.md` ("Errors this kit has found," item 3); `disagreements_all.tsv` rows tagged `*_diff_wilcoxest`, "reported by R only (documented)," family of 261 rows per the row's own annotation. | None named. | EXISTS-COMMITTED. |
| 15 | R-side findings taxonomy entry — R computes the exact studentized range at k=2 only via the plugin's own sqrt(2)·t identity; R's general algorithm approximates (3.2e-8 off). | `briefs/FACTS_R_BUG_REPORT.md` ("NOTE... at k=2 the exact identity range = sqrt(2)*|t| exists; R's general algorithm approximates and deviates ~3.2e-8 there"); ruled acceptance-reference status in RULING_WAVE_THREE_2026-09-01.md ("acceptance reference at k=2 becomes the exact sqrt(2)·qt form, not R's"). | None named. | EXISTS-COMMITTED (as a ruled, documented note; not framed as an error). |

---

## Notes on sourcing discipline

- Every artifact path above is quoted verbatim from a memo, report, or
  ruling in the record — none was inferred from repo layout or invented.
- Where a memo names a script but not its invocation, the "re-run
  command" column is left blank rather than guessed.
- "EXISTS-COMMITTED" here means the record states the file is committed
  (git-tracked) as of the memo's date; this ledger does not independently
  re-verify current tree state — that is the authoritative run's job.
- "EXISTS-UNCOMMITTED" is used where a report explicitly says a file is
  on disk but not committed per that job's own instructions
  (`ACCEPTANCE_RULES.md`, `forest_plot.R`, `results/forest_plot_agreement.png`
  — REPORT_ACCEPTANCE_AND_FOREST_2026-09-02.md, to-fable: "on disk, in the
  working tree, uncommitted per this job's instructions"). No section-B
  claim depends solely on these three files, so they are not given their
  own numbered row, but they are the backing evidence chain for row 1's
  eventual kernel validation and are flagged here for completeness.
