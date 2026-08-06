# SESSION CHECKPOINT — EML Praat Tools

> **HISTORICAL RECORD.** This document describes the state of the project on
> the date in its title. It is kept for provenance and is **not** a status
> surface. Do not resume work from it and do not treat its queue, its counts,
> or its instructions as current.
>
> **Current status lives in exactly one place: `audit/FINDINGS_INDEX.md`
> (the rows, not the header prose), with the reasoning in
> `audit/PHASE_ONE_AUDIT_2026-08-06.md`.**

Read THIS after a compact. Do not re-read the large artifacts to
re-establish state; re-run the harness instead and trust its exit code.

## Read discipline (this is what caused three compact-thrash cycles)

- Never full-read: `reg/EML_PROCEDURE_REGISTRY.md` (39 KB),
  `dev/tools/reg-apply-edits.py` (19 KB), `dev/tools/reg-reconcile.py`,
  `dev/tools/procs.json` (17 KB), `PRAAT_DEFINITIVE_CATALOGUE.txt`.
- Query them with grep / line-slice reads only.
- Proof of registry correctness = `reg-reconcile.py` exit status, not
  inspection of the registry.
- Redirect harness output to a file and capture `$?` immediately;
  never `| tail` before `echo "exit=$?"` (that reports tail's status).

## Standing user constraints

- "Save all to disk and verify only against what is saved."
- No deletion of project-knowledge docs without explicit authorization.
- No excessive follow-up questions; no reflexive compliments.

## Task #55 / item #50(e) — registry rewrite

Steps (a) persist input, (b) guarded edits, (c) reconcile: COMPLETE.
Step (d) upload to project: BLOCKED on project capacity.

Verify state in one command (cwd /home/claude/reg):

    python3 /root/eml_audit/plugin_EML_Praat_Tools/dev/tools/reg-reconcile.py \
        EML_PROCEDURE_REGISTRY.md > reconcile.out 2>&1; echo "exit=$?"

Expected: exit=0, "total documented rows: 283", "sections with defects: 0".

Fingerprints:
- reg/EML_PROCEDURE_REGISTRY.md  md5 1da527e84c30621d40602b6a2739042a
  418 lines, 39448 bytes
- reg/EML_PROCEDURE_REGISTRY.md.bak (pristine project baseline)
  md5 4cc10c2110a236353ad9a2ed153cb10e, 35305 bytes
- dev/tools/procs.json  md5 8803d8072e4291452f4d30e235e3e807

Ground truth: 241 documented (228 public, 13 internal) across 13 files
present in the tree + 163 undocumented across 15 files = 404 total
across 27 procedure-bearing files.

## Blocker detail (step d)

`project_write` refused: knowledge base 1,994,710 / 2,000,000 tokens;
the write is ~9,862 tokens. Cause is duplication, not volume: 142 docs =
24 `claude/` session docs (stored once) + TWO identical 59-file
reference batches (2026-06-03T21:31 and 2026-06-04T01:35). Removing one
batch frees roughly half the base.

Caveats: both copies of a duplicated file share one `path`, so it is
unverified whether the older copy can be deleted independently —
deletion may require re-upload from a local copy. `project_info`
exposes no per-doc sizes, so exact reclaim is not computable in advance.

AWAITING USER AUTHORIZATION. Nothing has been deleted.

## Drawing-defects handoff review (delivered 2026-08-03)

Assessment written to `/home/claude/ASSESSMENT_drawing_defects_handoff.md`.
Verdict: Defect A real (sole bare `Marks` in tree, at
graphs/eml-draw-procedures.praat:3941, v1.19; handoff cited 3551/v1.18 PKB
copy). Handoff WRONG on two points: (i) `emlDrawLMMForest` (3883-3949) sets
no Font size and never calls @emlSetAdaptiveTheme — it is the only one of 15
draw procedures without the theme prologue; (ii) the proposed one-line fix
errors at runtime because @emlDrawAlignedMarksBottom reads emlShowTicksX /
emlShowAxisValuesX / emlSetAdaptiveTheme.tickColor$, none of which
scripts/eml-lmm.praat initializes. Sandbox-verified: undefined global in
`if` → "Unknown variable", exit 255. Defect B not actionable — no
*vibrato* file in tree (corroborates registry annotation).

## Defect A fix — COMPLETE (2026-08-03), v1.19 → v1.20

`graphs/eml-draw-procedures.praat` now 4016 lines, header line 7
`# Version: 1.20`, md5 d370f12c0ff65f8c7ffe8dd5dd426cc3.
`procedure emlDrawLMMForest` at 3909 (comment block from 3894).
20-line v1.20 history entry inserted at lines 8-26.
`scripts/eml-lmm.praat` UNMODIFIED — signature unchanged, no registry
row moves, handoff §6.3 needs no declaration.

Changes: (1) Rule 1 — bare `Marks bottom: 5` → `@emlDrawAlignedMarksBottom`
with theme tick targets. (2) Rule 2 — theme prologue added
(@emlSetAdaptiveTheme / @emlSetColorPalette); it was the only one of 15
draw procedures without it. (3) `variableExists (...) = 0` guard seeds
emlShow* via @emlInitDrawingDefaults and defaults colorMode$ — without
it the new marks call aborts "Unknown variable" on the shipped path.
(4) Rule 34 — line widths, marker size, tick/text/series colour from
theme+palette; four inlined `replace$` → `@emlSanitizeLabel`.
DEFERRED deliberately: @emlDrawTitle (would require converting the
figure from outer-viewport to the theme's inner-viewport model).

Harness at /home/claude/fv/ (common.inc, state.inc, run_a/run_b.praat,
old_forest.praat + old_run_a/old_run_b.praat counterfactual).

    run_a.png (cold, nothing initialized)   dd6db65a5bbbc041bf205c769ba9b547
    run_b.png (warm, prior 2.4x1.8 figure)  dd6db65a5bbbc041bf205c769ba9b547
    old_a.png (v1.19, cold)   84f9c7573990a0d2cd76cdefdfcbcd47  62947 B
    old_b.png (v1.19, warm)   ed1e8c56e85b7cc7b37aa1db6bdf6558  48017 B

Fixed = byte-identical across cold/warm. Pre-fix = differs by ~15 KB,
which is what proves the Rule 2 exposure was real and the test sensitive.
Cold run logged `emlShowTicksX defined at entry: 0` — the guard fires.
Both fixed runs: figW=6.5 figH=3.6, xlo=-0.820708 xhi=1.440308.

## Finding — the theme initialization contract (REFRAMED 4 Aug 2026)

DESIGN RULING FROM THE LIBRARY AUTHOR, 4 August 2026: "Many procedures
call other procedures... I notice concern about the procedures having
dependencies…? It's designed this way." Cross-procedure calls and
shared-global reads are INTENTIONAL ARCHITECTURE, NOT A DEFECT. Do not
re-raise the dependency chain as an exposure; do not recommend adding
self-heals — that would push the library toward per-procedure
independence and away from its own model. RETRACTED: the earlier
recommendation to extend @emlSetAdaptiveTheme's variableExists guards to
emlSubtitle$ / emlFont$, and the phrase "a partial self-heal is worse
than none."

Established by the guard-stripped cold probe (adversarial probe 7,
`/home/claude/fv2/noguard_run.praat`). @emlSetAdaptiveTheme reads four
`eml*` globals, two behind variableExists guards:

    emlPanelOriginX  :366  guarded (variableExists)
    emlPanelOriginY  :369  guarded (variableExists)
    emlSubtitle$     :411  unguarded   <- aborts first when called cold
    emlFont$         :460, :461  unguarded

All four are seeded by @emlInitDrawingDefaults; callers are expected to
initialize. The map (53 call sites across 5 files vs one tree-wide call
to @emlInitDrawingDefaults, scripts/eml-stats-demo.praat:54) is a
picture of the contract's REACH, not an exposure metric.

What survives is one DOCUMENTATION point: @emlSetAdaptiveTheme's header
declares `Arguments:` and a 30-item `Outputs:` list and NO `Requires:`
line, against the convention its own tree uses 14 times in
eml-draw-procedures.praat. On the same reasoning the two existing guards
at :366/:369 are the anomaly, not the missing pair.

Corrects PRAATGEN_RETURN §3, which named `emlShowTicksX` at
eml-graph-procedures.praat:1209 (@emlDrawAlignedMarksBottom) as the
abort point. That transcript came from an isolated one-line snippet.
On the real path execution dies ~800 lines earlier and never reaches
the marks call. §3's conclusion (cold path aborts without the guard)
stands and is broader than stated. Recorded as PRAATGEN_RETURN §3A
plus a new §6 owner row; §3's original evidence relabelled "isolated
snippet" rather than rewritten.

Does not affect the shipped plugin: @emlDrawLMMForest's guard calls
@emlInitDrawingDefaults, which seeds all four.

## Adversarial check — COMPLETE, 7 probes, all passed (2026-08-04)

1. Full-suite re-baseline holds. `run-tests.py` exit 0: PASS=20, XFAIL=1;
   1232 checks declared, 0 failed, 0 skipped; 1 negative-control suite
   (4 checks, 4 failed by design). No NO-SENTINEL line (was 8 pre-conversion).
2. Manifest drift detection is real: probe line appended -> `--check`
   exit 1 "STALE"; stripped -> exit 0 "current", MANIFEST.txt md5 back to
   11bd1f95e4adfe605efba2f364766568. `grep -c "| TODO:"` = 0.
3. `reg-reconcile.py` exit 0 — 15 undocumented files, 163 procedures,
   283 documented rows, 0 sections with defects.
4. Runner sentinel enforcement survives two hostile suites: silent-green
   (exit 0, "ALL TESTS PASSED", no sentinel) -> runner exit 1, NO-SENTINEL;
   lying sentinel (status=PASS passed=99 then exitScript:) -> runner exit 1,
   FAIL [contract_mismatch]. Probe file removed.
5. PRAATGEN_RETURN fingerprints re-verified against disk (v1.20, 4016
   lines, md5 d370f12c0ff65f8c7ffe8dd5dd426cc3, forest at 3909, guards
   3944/3947). `git status` -> fatal: not a git repository.
6. Four-PNG order-dependence experiment re-derived from scratch in a
   fresh dir `/home/claude/fv2` with fresh pref dirs: all four md5s
   reproduce bit-for-bit, all four arms exit 0, all stderr 0 bytes.
7. Guard-stripped cold probe — see the @emlSetAdaptiveTheme section above.
   exit 124, marker stops at "about to call", stdout carries
   `Unknown variable: « emlSubtitle$` at eml-graph-procedures.praat:411.

### Vacuity scanner — CLOSED 4 August 2026

Two holes, both now fixed in `dev/tools/scan-assertion-vacuity.py`
(md5 0fc9ebef7e0ea02a33d910b2d885596a, 145 lines):

1. The tolerance harvester filtered on `"toler" in name`, so the names
   `tsTol` / `tsTolZero` / `tsExact` (test-theilsen.praat:64-66) never
   resolved and their sites went unmeasured. It now harvests every
   top-level `name = <numeric literal>` assignment, and a name bound
   twice to DIFFERENT literals is treated as unresolvable rather than
   guessed at.
2. Unevaluable sites were printed but excluded from the `bad` total, so
   the scanner could not go red on its own admitted blind spot — which
   contradicted its docstring. Unresolved tolerances now fail; sites
   whose *expected* value is runtime-valued are separated into a new
   CLASS F, reported with their tolerance, and do not fail (the ratio
   cannot be formed statically).

**Correction to the record.** Both this document and
ADVERSARIAL_CHECK_2026-08-04.md previously said "27 tolerance sites
(15x tsTol, 11x tsExact, 1x tsTolZero) + 1 expression-valued expected."
The true pre-fix figures were **28 tol-unresolved and 20
runtime-valued-expected**, 48 unevaluable in total.

Post-fix run against dev/tests/phase2 (exit 0):

    AssertEqualNum 618, AssertEqualRel 31, parsed 649/649
    MISSED 0   UNRESOLVED TOLERANCE 0
    CLASS A 0  CLASS B 0  CLASS C 39  CLASS D 31  CLASS E 0  CLASS F 21
    VERDICT: CLEAN

The 28 formerly-unresolved theilsen sites resolve as: 4 into CLASS C
(zero-target), 1 into CLASS F (`tsExpectedChecks`, the coverage
assertion), and the remainder fall out as well-separated — smallest
nonzero expected in that file is 0.1 against a largest tolerance of
5e-11, ~2e9x. The blind spot was real; nothing was hiding in it.

**Red path now proven.** `dev/tools/vacuity-negative-controls.py`
(md5 e18a4823080d80c4d6fe3d0a799baa91, 238 lines) copies the phase2
tree to scratch, injects one defect per run, and requires the scanner
to catch each. The shipped tree is never written to — it is fingerprinted
before and after and the comparison is reported. 7 / 7 as expected:

    NC-0   no injection                          exit 0  CLEAN
    NC-1a  tol == expected      (ratio 1.00)     exit 1  vacuous=1
    NC-1b  tol just under       (ratio 1.04)     exit 0  CLEAN, weak=1
    NC-2   AssertEqualRel with expected 0        exit 1  misuse=1
    NC-3   tolerance token never assigned        exit 1  unresolved-tol=1
    NC-4   tsTol rebound to a second literal     exit 1  unresolved-tol=15
    NC-5   malformed assertion (regex miss)      exit 1  unparsed=1

NC-1a/NC-1b are the load-bearing pair: a 4% move in tolerance flips the
verdict, so the scanner is tracking the ratio and not merely reacting to
an edit. NC-4 confirms the `conflicted` guard invalidates every site
using the ambiguous name (15), not just the reassignment.

First run of the controls came back 2 / 7 — the driver's own
`VERDICT: (\S+)` regex could not match `DEFECTS PRESENT` (space in the
token), so it read every red run as "no verdict line". The scanner had
been correct in all seven. Fixed to a lazy match; the failure is left
recorded here because a control driver that silently succeeds only on
the green path is the exact defect these controls exist to prevent.

## Demo-window wireframe — CLOSED 4 August 2026

`dev/tutorial-wireframes-v09.praat:582: demo Marks left: 4, "yes", "no", "no"`
was the last bare `Marks` in the tree — Defect A class, Demo window rather
than Picture window. Authorized by the author ("Yes change that demo example
commands") and fixed at v0.10.

The EML aligned-marks procedures are Picture-window only
(`@emlDrawAlignedMarksLeft/Right/Bottom`, eml-graph-procedures.praat:1208ff,
emit un-prefixed `One mark …`), so they cannot be dropped into a Demo context.
The bare call is replaced by three explicit `demo One mark left:` calls at
150 / 200 / 250 — nice numbers interior to the computed 120-260 range, step 50,
carrying the original `"yes", "no", "no"` flags and the surrounding
`faint$` colour and 0.5 -> 1 line-width restore.

`demo One mark left:` is NOT documented in COMMANDS_DemoWindow.txt. It was
verified empirically under Xvfb on 4 August 2026: signature identical to the
Picture-window form — `demo One mark left: position, writeNumber$, drawTick$,
drawDottedLine$, text$` (5 args). Probe exit 0, all markers written,
stdout/stderr empty. A page-8 harness (the file minus its interactive main
loop, `@pageAnimation` called directly) then ran the real procedure: exit 0,
"pageAnimation returned OK" / "DONE".

    dev/tutorial-wireframes-v09.praat   6c50c66a85e506357caba0efc7dda0a6
                                        869 lines, v0.10

Tree-wide sweep after the fix returns no live bare `Marks` anywhere (only
comment references at eml-draw-procedures.praat:9, :106, :4000).

MANIFEST row 72's description had inherited "…Wireframes v0.9" against a
version column reading 0.10 — not a regeneration bug, the description column
is curated and inherited by path, never overwritten by build-manifest.py.
Hand-edited to drop the version suffix entirely so it cannot drift again.

## Queue

0. CLOSED. Both items returned to PraatGen in
   /home/claude/PRAATGEN_RETURN_2026-08-03.md (§1 resync notice,
   §4 Defect B scope question), plus §2 font-state, §3/§3A guard,
   §5 three further PKB findings, §6 owner table.
   Vibrato / Defect B DEFERRED by the author 4 Aug 2026 ("for now").
   The §4 authoritative-source question is no longer blocking; the
   §6 row is marked deferred rather than owed.
SCOPE RULING, 4 August 2026: "you are just serving the plug in." The
PraatGen side is NOT this session's concern. Items 1 and 2 below were
pg-side and are closed on that basis, not on completion. The
PRAATGEN_RETURN document remains a finished hand-over artifact — deliver
it, do not keep tracking its rows as work.

1. CLOSED (out of scope) — #55 step (d), uploading the reconciled
   registry to project knowledge. That is a pg/PKB concern. The
   reconciled reg/EML_PROCEDURE_REGISTRY.md is correct on disk
   (reg-reconcile.py exit 0) and has been delivered via SendUserFile,
   so nothing is stranded. Historical blocker, for the record:
   project_write refused, ~9,862 tokens vs ~1,700 headroom; freeing
   capacity would mean deleting a duplicate 59-file reference batch,
   which was never authorized and never done.
2. CLOSED (does not apply) — the author confirms the plugin registry
   does not go into the Master Prompt; there is a separate procedures
   registry document. The "14 files / 255 procedures" line needs no
   action from this session.
3. CLOSED — #56 / item #51, the test runner (dev/tools/run-tests.py),
   plus the counter-bridge conversion of six legacy suites.
4. CLOSED — safety zip rebuilt.

## Delivered this session

- safety/EML_Praat_Tools_session_safety_2026-08-04.zip
  116 files, md5 49ff8b3f1089f3d6a942a22820de641c, 680715 bytes,
  MANIFEST.txt at root, `testzip()` clean. Carries the
  design-ruling-reframed PRAATGEN_RETURN (md5
  c0926343ad41fd6dd521be2e04e6046c), this CHECKPOINT,
  ADVERSARIAL_CHECK_2026-08-04.md (md5
  fae934465fa9d8c1494e3cb6ae0f5566, 253 lines — its
  "What the check did not clear" section rewritten as a closure note
  with the corrected 28/20 figures and the 7/7 control result) and
  ASSESSMENT_drawing_defects_handoff.md.
  The 116th member is the new dev/tools/vacuity-negative-controls.py;
  also updated since the previous zip: scan-assertion-vacuity.py
  (both blind spots closed), MANIFEST.txt
  (md5 490dac06ae40ccf80267b3f10a8cffdd) and
  dev/tutorial-wireframes-v09.praat (v0.10, md5
  6c50c66a85e506357caba0efc7dda0a6).
  Supersedes: 115-file 9853aa9997d633b38974ba6bbea4892b,
  115-file 619fefebd3e6e9f496251b58457158ac (pre-ruling),
  113-file 142b7337f208842e81bd67abeeebd016, and 104-file
  2b40a96cd90b20e21d9d6515cee4f987 (2026-08-03).
  Rebuild with: python3 /home/claude/safety/build.py
  A zip cannot contain its own md5, so the CHECKPOINT.md staged inside
  lags this file by exactly this paragraph. Everything else matches.

## External-reference (Rule 32) validation — 4 August 2026

Recorded in full at /home/claude/RVALIDATION_2026-08-04.md; raw outputs
in /home/claude/rval/. First R/scipy run recorded on disk this session —
the artifacts were authored 2–3 August and had not been re-executed here
until asked.

- 8 R scripts (R 4.3.3): **409 passed, 0 failed, 34 skipped.**
  Exits 2/0/0/0/2/2/2/0 — exit 2 encodes INCOMPLETE (skips present),
  never FAILED.
- `verify-inferential-batch7-dunn.py` (scikit-posthocs): **33 / 33, exit 0.**
  Closes the Dunn's-test gap that verify-inferential-batch7.R explicitly
  refused to claim.
- 6 scipy reference generators: exit 0 each.
- Combined external checks passing: **442, zero failures.**

Correction to an interim in-session tally: "276 passed" was wrong — it
dropped batch4 (29) and batch5 (104) because those two emit
`TOTAL: n PASS, n FAIL, n SKIP` instead of the
`R Verification: n passed, ...` format the grep matched. Correct: 409.

Same-day re-runs from disk, all exit 0: run-tests.py (PASS=20, XFAIL=1,
1232 declared checks, 0 failed, 0 skipped); scan-assertion-vacuity.py
(VERDICT CLEAN, 649/649); build-manifest.py --check (current);
reg-reconcile.py (283 documented rows, 0 sections with defects — takes
/home/claude/reg/EML_PROCEDURE_REGISTRY.md as an argument; no copy of the
registry exists inside the plugin tree).

Remaining coverage gap: the 9 eta-squared / partial-eta-squared checks in
batch6 have no external reference (R `effectsize` absent, CRAN
unreachable, no scipy equivalent). They are longhand re-implementations,
not external validation. This is the only unclosed item of its kind.

## Degenerate-input stress run — 4 August 2026

Full record at /home/claude/STRESS_DEGENERATE_2026-08-04.md; raw output
/home/claude/rval/stress_out.txt; scipy 1.17.1 cross-check
/home/claude/rval/scipy_xcheck.py -> scipy_xcheck.txt; existing-coverage
census /home/claude/rval/keyword_census.txt.

Tool: dev/tools/stress-degenerate-inputs.py — one isolated
`praat_barren --run` process per case, 25 s timeout, so a case that kills
the interpreter cannot mask later cases.

    cases=38  CONTRACT=18  UNSET=2  VALUE=17  CRASH=1

Four-outcome classification: CONTRACT = .error$ set AND outputs nulled to
undefined (guardable); UNSET = .error$ set but outputs unassigned (reading
one aborts); VALUE = a number came back; CRASH = interpreter died with no
error string.

Probe-defect discipline: five first-run "crashes" were my own wrong output
names (.u/.w/.f/.nComparisons/.r2 rather than
.u1/.tPlus/.fValue/.nPairs/.rSquared) and one was an invalid argument
("pooled" where emlPairwiseT accepts only welch/student — the library's
rejection was correct). Every eml*.var reference in the probe is now
validated against parsed procedure source before each run (/tmp/valref.py,
last result: refs checked 47, bad 0). Mandatory before reporting.

Findings, none applied to the library:
1. **Kruskal-Wallis all-tied returns H=0, p=1** (eml-inferential.praat
   tie-correction block, hardcoded `# All values identical — H must be 0`).
   scipy returns nan/nan. This is the audit-item-9 fabricated-result
   pattern, and it is internally inconsistent with @emlDunnTest, which
   propagates undefined on the identical input. Highest value.
2. **`sort#` at eml-core-descriptive.praat:101 (@emlMedian) aborts the
   interpreter** on any undefined element — no .error$, no guardable outcome.
   Reachable from real data (unvoiced frames in a pitch track).
   CORRECTION: first written as ":931". No such line — the file is 870 lines.
   Praat tracebacks number the FLATTENED INCLUDE STREAM, not the source file.
   Always resolve a Praat line number back to a file line before recording it.
   The fix is not new code: @eml_hasUndefined already exists at
   eml-core-descriptive.praat:62 and is applied at 4 of 14 sort# sites
   (183/416/454/495). Unguarded and caller-data-exposed: emlMedian:101,
   emlMode:133, emlShapiroWilk:737, emlUniqueValues (utilities):345,
   emlFrequency (utilities):395, emlTheilSen (inferential):4038/4050/4058.
   Safe by construction: emlBootstrapCI (lmm):3747/3772 both filter
   `<> undefined` into the vector before sorting. Internal-only:
   emlLMMSummary (lmm):4192 sorts model residuals, not caller data.
3. **emlLinearRegression sets .error$ but leaves .slope unassigned** (×2:
   zero predictor variance, n=2). Only holdout against the 18 CONTRACT
   procedures.
4. Silent undefined with empty .error$ — ANOVA all-constant, 1e300 overflow.
   Safe but undiagnosable.
5. Misattributed diagnostic — 1e-300 underflow reports "Both groups have
   zero variance"; the values are distinct, the variance underflowed.
6. Tukey HSD answers on a singleton group (n=3,3,1) where scipy refuses,
   while this library's own one-way ANOVA rejects singleton groups. ANOVA
   and its post-hoc disagree.

Exonerated by scipy (looked like defects, are not): Mann-Whitney all-tied
(u1=8 p=1) and n=1 vs n=1 (u1=0 p=1) match scipy exactly; Wilcoxon
one-nonzero-difference agrees to float noise; ANOVA all-constant agrees;
Tukey all-constant agrees; catastrophic cancellation agrees to ~9 sig figs.
The library is **safer than scipy** at both magnitude extremes (undefined
where scipy returns -0.0/p=1.0 at 1e300 and -inf/p=0.0 at 1e-300).

Coverage census over the 15 phase2 suites: ties 14 files, n=1 7, identical
6, undefined 6, empty 5, zero variance 3, degenerate 3, constant 2, all
equal 1. **Zero occurrences** of singleton, single value, insufficient,
overflow, underflow, cancellation, imbalance, 1e300/1e-300. The three
families named in the question are the best-covered part of the suite;
three of the six findings came from the families nobody named.

Not written to project knowledge — the project is at its size ceiling and
refused the write. Deleting docs to make room requires author authorization
and none was given.

---

## ACTIONABLE_2026-08-04.md — the work order (4 Aug 2026)

Written and delivered. `/home/claude/ACTIONABLE_2026-08-04.md`. Converts the
six stress findings + the regression-suite obligation into a ranked 7-item
work order with exact file:line and exact prescribed edit per item.

Ranking (reachability from real data first, severity of the wrong answer
second):

1. `sort#` aborts on undefined — 8 sites, mechanical. Apply the existing
   `@eml_hasUndefined` (eml-core-descriptive.praat:62). Reference pattern is
   `emlPercentile` 183-195. emlTheilSen takes **one** entry guard, not three
   (4038/4050/4058 all trace to `.x#`/`.y#`).
2. **AUTHOR DECISION** — Kruskal-Wallis all-tied returns H=0, p=1.
   Propagate undefined (matching @emlDunnTest and scipy) or leave and
   document. Only item that can survive into print.
3. emlLinearRegression leaves outputs unassigned on both error paths —
   mechanical. Null at 3879, copying @emlTheilSen 4000-4001, 121 lines below
   in the same file.
4. Misattributed underflow diagnostic — mechanical, 1 site.
5. **AUTHOR DECISION** — ANOVA rejects singleton groups, Tukey answers on
   them. Three coherent dispositions listed; I chose none, because choosing
   is a statistics-methodology opinion.
6. Silent undefined with empty .error$ — mechanical, 2 sites.
7. New `dev/tests/phase2/test-degenerate-inputs.praat`, sections A-D.
   Section C (exonerations) matters more than A — it closes the zero-coverage
   gap. Explicit CLASS-F warning: no assertion whose expected value is
   computed at runtime from the code path under test.

Do-not-edit list recorded in the report so a future pass doesn't re-file
them: emlBootstrapCI (lmm):3747/3772 already filter `<> undefined`;
emlLMMSummary:4192 is internal; eml-core-descriptive 195/428/466 already
guarded.

Post-edit protocol (all five, in order, after ANY library edit):

    python3 dev/tools/run-tests.py
    python3 dev/tools/scan-assertion-vacuity.py
    python3 dev/tools/build-manifest.py --check
    python3 dev/tools/reg-reconcile.py /home/claude/reg/EML_PROCEDURE_REGISTRY.md
    python3 /home/claude/safety/build.py

**Nothing in the report has been applied to the library.** Two items are the
author's to decide and the other five await authorization.

## CORRECTION — external-validation coverage (4 Aug 2026)

The "5% externally validated" figure stated in conversation on 4 August
2026 is **withdrawn**. It came from grepping Praat procedure *names*
inside `verify-*.R` / `verify-*.py`. Those scripts emit reference
*values* that the Praat suites assert against; the procedure name has no
reason to appear in an R file. The grep measured mentions, not oracles.
The denominator (317, all eml-prefixed procedures including graphs and
drawing) was also a category error. Same defect class as the 276->409 R
miscount, this time in my own measurement.

Corrected measurement, from `dev/tests/REFERENCE_PROVENANCE.md`'s
generator->suite table plus `@eml*` call sites in the eleven
externally-fed suites:

- `stats/eml-inferential.praat` 28 procedures: 24 directly externally
  oracled, 4 private helpers reached transitively -> **28/28**.
- `stats/eml-core-descriptive.praat` 21: 1 external (Shapiro-Wilk); the
  other 20 asserted against closed-form analytic values, which is the
  stronger oracle for those quantities.
- `stats/eml-core-utilities.praat` 15: 2 external; rest structural.
- 442 external checks pass (409 R + 33 Dunn), 0 failures.

**The real gap: 49 procedures with no test of any kind.**
`eml-lmm.praat` (31), `eml-linalg.praat` (10), `eml-optimizer.praat` (8).
Verified by grepping every `@procName` across all of `dev/tests/` — zero
matches. Plus 14 of 21 in `eml-analysis.praat`, including
`emlFriedmanTest`, `emlGGEpsilon`, `emlRMAnovaTest`, `emlRMPostHoc`.

Full record: `reports/CORRECTION_coverage_2026-08-04.md` in the safety zip.
**Do not carry the 5% number into any future document.**

## AUTHOR RULING — LMM module tabled (4 Aug 2026)

User: "We're tabling LMM module."

The ruling is larger than its name. `eml-lmm.praat` is the **sole
consumer** of `eml-linalg.praat` (10 procedures) and `eml-optimizer.praat`
(8). Verified by tracing all 18 for call sites outside their own file:
every caller is `./stats/eml-lmm.praat`, and 12 of the 18 have no caller
anywhere in the plugin at all (`emlLogDeterminant`, `emlForwardSolve`,
`emlBackSolve`, `emlCholeskySolveMulti`, `emlCholeskyInverse`,
`emlForwardSolveMulti`, `emlBackSolveMulti`, `emlProjectOntoBounds`,
`emlBOBYQAUpdate`, `emlBOBYQATrsbox`, `emlBOBYQAAltmov`, `emlBOBYQAInit`,
`emlBOBYQARescue`).

Therefore tabling LMM tables all **49** procedures from the section above,
not 31. `emlRunLMMAnalysis` in `eml-analysis.praat` goes with them.
**Do not re-raise LMM / linalg / optimizer as an open validation gap.**
They are deferred by author ruling, not overlooked.

### Residual gap after tabling — CLOSED 4 August 2026

The four repeated-measures procedures in `stats/eml-analysis.praat` that
had no oracle and no test of any kind now have both:

- `emlFriedmanTest` :1222-1272 — own chi-square, p via `chiSquareQ`
- `emlGGEpsilon` :1278-1339 — Greenhouse-Geisser epsilon from scratch,
  no internal calls at all
- `emlRMAnovaTest` :1346-1391 — own F, p via `fisherQ`, calls `@emlGGEpsilon`
- `emlExtractConditionMatrix` :1142-1214 — the row-wise complete-case
  reshape all three depend on

Three artifacts, all in `dev/tests/phase2/`:

- `repeatedmeasures_refs.py` (291 lines) — the [EXT] generator.
  Friedman -> `scipy.stats.friedmanchisquare`; RM-ANOVA F/df/p ->
  `statsmodels AnovaRM`; GG epsilon -> `pingouin`. The GG oracle has to
  be Python: base R has no Greenhouse-Geisser routine, neither `ez` nor
  `afex` is installed, CRAN is unreachable, and
  `REFERENCE_PROVENANCE.md` forbids `library()`/`require()` in the `.R`
  generators.
- `test-repeated-measures.praat` (451 lines) — **90 passed / 0 failed /
  6 skipped / 96 total, status=INCOMPLETE by design.**
- `verify-repeated-measures.R` (578 lines) — v2.0 architecture
  (asserts, does not `cat`). **101 passed / 0 failed / 10 skipped,
  EXIT=2 (INCOMPLETE, not FAILED).** Friedman and RM-ANOVA are [EXT];
  GG epsilon is [LH] longhand from `cov()` only. `EXPECTED_CHECKS <-
  111` coverage guard at the bottom.

Six datasets span working and known-broken input as the audit requires:
RM_A clean k=3 n=6; RM_B k=4 n=5 sphericity violated (epsilon 0.33673,
just above the 1/(k-1)=0.33333 clamp); RM_C heavy within-row ties;
RM_D every observation identical; RM_E n=2 with epsilon exactly ON the
clamp; RM_F perfectly additive, zero residual.

**Substantive finding: zero disagreements.** All 101 base-R checks
agreed with the literals transcribed from scipy/statsmodels/pingouin.
No transcription error exists in the suite.

**Six quantities are asserted in neither file — pending AUTHOR
DECISION.** They are three new instances of the audit-item-2/9
fabricated-result class:

| Input | Library returns | Oracle returns |
|---|---|---|
| RM_D `emlFriedmanTest` | chiSq 0, p 1 (clamps `.c <= 0` to 1) | scipy `nan` |
| RM_D `emlGGEpsilon` | 1 (`.den <= 0` branch) | pingouin `nan` |
| RM_D `emlRMAnovaTest` | F `undefined` (msErr 0) | statsmodels F 0, p 1 |
| RM_F `emlGGEpsilon` | 1 | pingouin `nan` |
| RM_F `emlRMAnovaTest` | — | statsmodels 3.09e31 vs pingouin 8.58e15; **no reference value exists** |

Do not "fix" a skip by adopting the library's own output — that
converts the suite from a test into a regression lock
(`REFERENCE_PROVENANCE.md`).

Not gaps: `emlRMPostHoc` :1514-1620 delegates entirely to already-oracled
procedures (`@emlTTestPaired`, `@emlWilcoxonSignedRank`, `@emlBonferroni`,
`@emlHolm`, `@emlBenjaminiHochberg`). `emlRunReliabilityAnalysis`
:1129-1131 is a declared Phase 4 stub with no call sites, documented as
such in the code.

### Post-edit protocol — all five green (4 August 2026)

    python3 dev/tools/run-tests.py                 # INCOMPLETE=1 PASS=20 XFAIL=1
                                                   # 1328 declared, 0 failed, 6 skipped
    python3 dev/tools/scan-assertion-vacuity.py    # VERDICT: CLEAN
    python3 dev/tools/build-manifest.py --check    # MANIFEST.txt is current.
    python3 dev/tools/reg-reconcile.py /home/claude/reg/EML_PROCEDURE_REGISTRY.md
                                                   # 283 rows, 0 defects
    python3 /home/claude/safety/build.py           # 148 files, 0 missing, 754568 bytes

Zip listing verified by enumeration, not by trusting the "0 missing"
line (which only checks that *listed* sources exist).
