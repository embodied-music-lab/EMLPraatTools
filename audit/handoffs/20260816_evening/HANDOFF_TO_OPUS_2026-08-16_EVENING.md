# Handoff to the executing session — 16 August 2026, evening

From the stress-test/verification session, after independent verification of your
latest push and of Sol 5.6's re-evaluation. This document is self-contained: it
answers your five waiting items, incorporates the full history-migration change
order (ruled, ready to execute), and restates the queue. Nothing here needs a
further ruling from Ian except where explicitly marked.

## 1. State, verified independently at 7d54026

Pulled the exact remote commit and re-ran everything here (full Praat 6.6.30 on
PATH, R 4.3.3):

- Suite: **12,400 checks, 12,398 passed, 2 FAILED** — both failures are v78's
  workflow-trigger checks ("triggers on push" / "triggers on pull_request"),
  exactly as Sol predicted. Manual-only `workflow_dispatch:` is the cause. Not a
  regression; a state/reporting inconsistency that self-resolves when the
  triggers are restored (§4, item 1).
- The four fast checks pass: manifest current; include closure green (26 entry
  scripts, 4 guarded optional calls); compileall clean; vacuity scan CLEAN
  (712/712 parsed, 0 vacuous).
- One-tailed repair verified in code and live: signed statistic, .pGreater/.pLess
  computed directly (not as complements), .alternative$ named, @...Alt
  procedures; v73 181/181, v77 122/122 against R oracles both directions.
  **Per Sol and author: do not revisit unless a new failing oracle appears.**
- Step-stamp consume-once read in full and verified against the ruled design,
  including stamp-reset-on-mismatch and unstamped-pair-treated-as-absent
  (v74 89/89). v75 56/56, v76 78/78. All six Sol closures are real.
- No deprecation/meaning-change notes found in shipped files — already conforms
  to the pre-release ruling in §3.

## 2. Your five waiting items — dispositions

**2a. FIX_NOTES.md.** Not ambiguous under the change order in §3: the sweep's
step-1 extractor captures it verbatim into dev/HISTORY_LEDGER.md and step 2
moves it out of the shipped root into dev/. You execute it as part of the sweep.
No division of labor — the change order is yours to run end to end.

**2b. Which stale evidence to re-run.** Use the redrive order already documented
in the repo's own status record: (1) graphseams, with the v61 prose corrected in
the same change; (2) markers and patterns after repairing their stale
identifiers; (3) gui_e2e; (4) legend, together with its pinned pixel constants;
(5) savepaths and api_export; (6) edittable; (7) normality only after it has an
actual validator. Release criterion: every load-bearing artifact has a
reproducible driver, with clock/path-dependent fields normalized explicitly —
not byte-identity on every machine.

**2c. Root README "coming soon."** Stays with Ian — it must be in his voice.
Author input required; do not draft over it. (The verification session may
supply a skeleton from the audit state for Ian to rewrite.)

**2d. dev/ ships to users.** Closed by Part 3 of the change order (§3): the
committed exclusion manifest plus the build-time check that opens the finished
zip and fails if any excluded path is present inside it.

**2e. Manifest claims two retired files don't ship while the release ships
them.** Same mechanism as 2d — this is exactly the class the build-time zip
check exists to catch. Once it's in place, the manifest and the artifact cannot
disagree silently. Fix the two files' packaging status in the same change that
lands the check, so the check is born green.

## 2f. New: API documentation does not travel with the install

Found while drafting the release README. docs/API_EXPORT.md lives at REPO
level, outside the plugin folder, and plugin/README.md points at it twice as
`../docs/API_EXPORT.md` (lines 92 and ~146). A user who installs the plugin
folder — the entire install instruction — gets a pointer to a file they do not
have; and under the Part-3 packaging boundary the file would not ship at all.
Fix: move it to plugin/docs/API_EXPORT.md, update both README references, and
it rides along with the install. Same class as the broken doc links Sol closed,
one level up. The build-time zip check should also assert that every relative
link in shipped docs resolves inside the artifact.

## 2g. New change order: recipes (plugin/docs/RECIPES.md)

Author-requested. The scripting API is real but underdocumented for the
audience: API_EXPORT.md covers the orchestrator+export path thoroughly and
nothing covers the direct-kernel path (Table → vectors → @emlTTest and kin).
The verification session drafted RECIPES_DRAFT.md (travels with this handoff)
with five worked recipes: R1 two-group direct-kernel (RUN 16 Aug on 6.6.30,
printed outputs are real), R2 paired/correlation (RUN 16 Aug), R3
orchestrator+export and R4 batch loop (condensed from API_EXPORT §3/§8, which
the api_export harness already runs), R5 Sound→Pitch→stats (DRAFT, untested).

Shipping requirements, per the v50 house rule (a documented example is a
tested example):
1. Ships INSIDE the plugin folder (plugin/docs/RECIPES.md), linked from both
   READMEs — closing the old "recipes.md promised but never existed" finding
   properly instead of narrowly.
2. A recipes harness runs every recipe verbatim; a validator pins the printed
   outputs. R5 must not ship undriven — and verify its field names against
   the procedure headers first; R1 and R2 each needed exactly that correction
   when written (extractor outputs are .group1#/.group2# and .data1#/.data2#,
   not the guessable names).
3. When roadmap Phase 1 (aggregation) ships, add R6: tokens → subject medians
   → paired comparison.

## 2h. New change order: setup.praat generates a user-facing barrel (author's design)

The shipped barrel (scripts/eml-lib.praat) cannot work from a user's folder:
Praat's include is parse-time text paste, so the barrel's relative internal
lines resolve against the USER's script folder, and a static file cannot
compute its own installed location. The author's fix: the file that CAN
compute it is setup.praat, which runs at every Praat launch.

Spec:
1. At startup, setup.praat resolves the plugin root (the same
   preferencesDirectory$ → home-relative rewrite the recorder already does,
   with the OS/version-gated fallbacks) and WRITES a generated barrel — e.g.
   scripts/eml-lib-user.praat — whose internal include lines are full,
   machine-correct paths. Header states it is generated, at launch, and that
   hand edits will be overwritten.
2. Write ONLY when the generated content differs from what is on disk
   (compare before writing) — Praat 7.0 challenges scripts that touch disk,
   and an unchanged launch must not write, let alone prompt.
3. Factor the path-resolution logic out of eml-record.praat into ONE shared
   procedure used by both the recorder and the generator, so they cannot
   drift.
4. A validator pins the generated file: regenerate via the shared procedure,
   compare to disk, and assert its include list matches the canonical module
   order (the same list the recorder emits).
5. Docs then collapse to one include line (the four per-platform variants of
   the single path). Recipes and API_EXPORT.md updated to lead with it; the
   full pasted block remains documented as the fallback. Recorded scripts
   MAY later emit the one line instead of eleven — separate decision, not
   part of this order; the current emitted block is correct and stays.
6. Self-healing property to preserve and test: plugin moved, or Praat 6→7
   prefs-directory change, regenerates a correct barrel on next launch.

## 3. Change order — development-history migration and the release boundary

Author ruling, 16 Aug 2026: pre-release, shipped files describe what the code
does, never what it used to do wrong. Defect and change history lives in git and
the dev ledger. The sweep is designed so completeness is proven by a lint, not
by attention — do not begin deleting until the extractor and the lint exist.
Sequencing condition (P0 one-tailed fix landed first) is now satisfied.

### Scope, measured at the pre-push tree

28 shipped (non-dev) .praat files carry version-history header blocks: ~219
lines of explicit v-numbered / item-numbered history, plus ~250 further header
lines in was/fixed/no-longer phrasing (overlapping sets; the lint patterns below
are the authoritative definition). FIX_NOTES.md sits in the shipped plugin root.
Largest carriers: eml-graph-procedures.praat (~63 history lines),
eml-inferential.praat (~51), eml-wizard.praat (~12); the long tail is 1–5 lines
per file across scripts/, stats/, graphs/, and setup.praat. Re-measure at HEAD
before starting — the 16 Aug push may have shifted counts.

### Part 1 — the ledger (FINDINGS_MACHINE.json extension)

Add three fields to every row; the schema applies to all future findings too:

- `fixedBy` — full git commit hash of the fix (empty string until fixed).
- `pinnedBy` — validator ID(s) that pin the corrected behavior (e.g. "v66"), or
  a dev-test ID where the pin lives in dev/tests. Empty means UNPINNED.
- `status` — open | fixed-unpinned | closed. `closed` requires BOTH fixedBy and
  pinnedBy non-empty. No other path to closed.

Backfill the 41 existing rows from git log and the validator suite. Every row
that ends up fixed-unpinned is a real gap — list them in the status file as a
backfill queue rather than silently closing.

Commit convention, from now on: the subject line of any fix commit begins with
the finding ID it closes ("NEW-G5-2: ..."). Multi-finding commits list every ID.

### Part 2 — the migration sweep (extract, delete, prove)

Order is mandatory: capture verbatim FIRST, delete second, prove third.

**Step 1 — extractor** (dev/tools/): walks every shipped .praat file and copies
each header-history block verbatim into dev/HISTORY_LEDGER.md, prefixed with
`## <path> @ <commit>` and original line numbers. A history block is a maximal
run of comment lines matching the step-3 lint patterns plus their indented
continuation lines. Prints a per-file line count. Run it, commit
HISTORY_LEDGER.md alone, THEN proceed. The 13-item eml-inferential changelog,
the graph-procedures history, and FIX_NOTES.md all land here.

**Step 2 — deletion.** Remove the extracted blocks from shipped headers; move
FIX_NOTES.md into dev/. Three reconciliation invariants, all required:
(a) lines deleted == lines captured by the extractor;
(b) the diff touches ONLY comment lines (stripping all comments from before-
and after-trees yields byte-identical code), plus the FIX_NOTES.md move;
(c) full suite still passes at its current count, 0 failed.

**Step 3 — the lint (the completeness guarantee).** A new permanent validator
that fails if any SHIPPED file matches, in a comment line, any of:
`v\d+\.\d+:` as a history entry · `item \d+ -` · `no longer` · `used to` ·
`previously` · `was broken` · `changed meaning` · `deprecat` · `CHANGELOG` ·
`FIX_NOTES`. Exceptions go in an explicit allowlist file (path + line-pattern +
one-line justification) — legitimate prose that collides gets allowlisted
deliberately, never skipped silently. The sweep is DONE when this validator is
green. It then stands guard: any future fix that writes history into a shipped
header turns the suite red.

### Part 3 — the packaging boundary

The built artifact must exclude: plugin/dev/ (tests, tools, ledgers, design
docs, FIX_NOTES.md after its move), and at repo level audit/, harness/,
validate/, evidence/, and any *_LEDGER.md / findings JSON. Write the exclusion
list as a committed manifest (not flags in a build script), and add a build-time
check that opens the finished zip and fails if any excluded path or any
lint-pattern hit is present inside it. This closes items 2d and 2e above.
History in the repo, never in the product, enforced twice: at the source
(step-3 lint) and at the artifact.

### Part 4 — the release boundary rule

The day 1.0 ships, a user-facing CHANGELOG.md starts, empty, documenting only
differences between released versions from then on. Everything earlier is
development and lives in git, HISTORY_LEDGER.md, and FINDINGS_MACHINE.json.
This also confirms the one-tailed repair ships with no deprecation notes —
which, verified at 7d54026, is already the case.

### Sequencing

Run the sweep as its own commit series, not interleaved with behavior fixes —
the comment-only-diff invariant is only checkable if no code change shares the
commits.

## 4. Queue after this document

1. Finish the repository transfer; restore `push:` and `pull_request:` triggers
   (keep workflow_dispatch as a manual extra); run the exact final commit; v78
   goes green by the same change. Only then do "checked on every push" claims
   stand — reconcile README/manifest prose with the actual trigger state in the
   same commit.
2. Execute the history-migration change order (§3), closing 2a/2d/2e.
3. Redrive stale harness evidence in the 2b order, committing source, artifacts,
   and validator changes together.
4. Build and install-test the actual release artifact (permissions 0644, fresh
   Praat profile, menu enumeration, one path per registered input type, final
   folder name — Ian is actively renaming; don't treat naming churn as a
   defect). Linux automated; macOS/Windows need real machines.
5. README with Ian (2c).
6. Unification last, acceptance test "one result through every door": same
   rows, same test family and alternative, same estimate/effect size/df, same
   raw and adjusted p, same labels, same result in Info, CSV, figure, and
   recorded script. The audit's engine-agreement measurements are the free
   regression baseline.

Feature work (aggregation pathway → EMMs/contrasts → diagnostics → LMM v1) is
roadmapped separately and starts only after this queue closes.

— verification session, 16 Aug 2026
