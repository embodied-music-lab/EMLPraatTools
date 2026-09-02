# Retiring Praat's built-in Tukey commands: the exact repoint plan

Status: plan only. Nothing in this document has been applied. Every file
this plan edits lives under `plugin_EML_StatsGraphs/`, which a separate
serial pass owns; this plan hands that pass the exact patches instead of
touching the files itself.

Scope: tracker items A.3 and A.5
(`mailbox/to-opus/TRACKER_KIT_AND_1p0.md`, line 20 and the re-pointing
grep-check at line 57), ordered by `RULING_WAVE_THREE_2026-09-01.md`
("The tracked item, upgraded to a check") and
`RULING_PROVENANCE_AND_CANCELLATION_2026-09-01.md` §3.

## 0. Precondition this plan does not resolve

`setup.praat` line 434 currently carries the port under `not-in-barrel`
with the reason: measured against a converged mpmath reference it is 64
percent low at k=10, df=3 near p=1e-6, and "wrong by smaller but
systematic amounts across df 3 to 5. Nothing calls it yet ... It joins
the table when it passes validate/v154." Tracker item A.2 records the
port as QUARANTINED, currently 91/107 against the (at-time-of-writing)
unconverged reference grid. **This plan is the re-pointing step for
after the port is accepted.** Applying these patches before v154 goes
clean would wire a known-defective routine into every ANOVA, Games-Howell
and two-way-marginal Tukey/Scheffe post hoc in the plugin. Order of
operations, restated at the end of this document.

## 1. The port's real signatures, read from the file, not guessed

`plugin_EML_StatsGraphs/stats/eml-studentized-range.praat`:

```
procedure emlStudentizedRangeQ: .q, .k, .df, .nranges      (line 542)
  outputs: .p   .ok   .error$   .warning$

procedure emlInvStudentizedRangeQ: .p, .k, .df, .nranges   (line 943)
  outputs: .q   .ok   .error$   .warning$
```

The argument order is identical to the two Praat builtins it replaces
(`Get TukeyQ: q, k, df, nranges` → p; `Get invTukeyQ: p, k, df, nranges`
→ q), so every call site's argument LIST is unchanged. What changes is
the call form: a builtin call assigns its return value directly
(`x = Get TukeyQ: ...`); the port is a `@`-called procedure whose result
is read back off its own name afterward (`emlStudentizedRangeQ.p`,
`emlInvStudentizedRangeQ.q`).

Two behavioral differences the six call sites do not currently handle,
because the builtin never exercises them:

- **Refusal.** The port sets `.ok = 0` and a populated `.error$` when
  `df < 2`, `k < 2`, or `nranges < 1`, leaving `.p`/`.q` undefined. The
  builtin never refuses. None of the six call sites below currently
  check an `.ok` flag after the call — the patches in §2 preserve that
  (read `.p`/`.q` unconditionally), which reproduces today's behavior
  exactly (an undefined result propagates the same way an out-of-domain
  builtin result would have) but does not surface the refusal reason.
  Whether to wire `.error$` into `.warning$`/`.nUndefined` at each site
  is a design decision for whoever applies this patch, not resolved
  here.
- **Fractional df.** `stats/eml-inferential.praat`'s own doc comment at
  line 7305 states the two builtins being retired "accept a fractional
  df" and names the caller: `emlGamesHowell`'s per-pair
  Welch–Satterthwaite df, which is not generally an integer. The port's
  own header (line 519-524) motivates its panel-1 fix specifically for
  "an error df in an ANOVA," i.e. an integer df, and the file contains
  no comment, branch, or test acknowledging a fractional df anywhere
  (`grep -n "fractional" plugin_EML_StatsGraphs/stats/eml-studentized-range.praat`
  → one line, the ANOVA-integer-df justification, not a fractional-df
  handling note). `validate/v154_srange_against_reference.R`'s own grid
  (checked: no fractional `df` value appears in its oracle-comparison
  rows) does not exercise this path either. **Flag, not blocker:** sites
  5 and 6 below (Games-Howell) are the two call sites this repoint sends
  fractional df through for the first time under the port's own claimed
  accuracy regime. Confirm the port's panel-1 branch-point fix still
  holds at fractional df — or accept the un-fixed slow-convergence path
  there — before landing those two sites, and say which in the commit
  that applies this plan.

## 2. Every call site, and its exact patch

Measured with:

```
$ grep -rn "Get TukeyQ\|Get invTukeyQ" plugin_EML_StatsGraphs/stats/eml-anova-kernel.praat plugin_EML_StatsGraphs/stats/eml-inferential.praat
```

Six executable call sites, two files. (The full grep also returns
seven comment/doc-string lines in these same two files; §3 covers those
separately since they are not calls.)

### Site 1 — `stats/eml-anova-kernel.praat:1625`

Procedure: `emlAnovaKernelTwoWayPostHoc` (starts line 1502), branch
`.adjMethod$ = "tukey"`.

```
-            .qCritical = Get invTukeyQ: .alpha, .k, .dfError, 1
+            @emlInvStudentizedRangeQ: .alpha, .k, .dfError, 1
+            .qCritical = emlInvStudentizedRangeQ.q
```

### Site 2 — `stats/eml-anova-kernel.praat:1647`

Same procedure, the per-pair p-value loop, `.adjMethod$ = "tukey"`
branch, guarded by `.sed > 0`.

```
-                    .p = Get TukeyQ: .qForQ, .k, .dfError, 1
+                    @emlStudentizedRangeQ: .qForQ, .k, .dfError, 1
+                    .p = emlStudentizedRangeQ.p
```

### Site 3 — `stats/eml-inferential.praat:4451`

Procedure: `eml_tukeyPairwiseFromGroups` (starts line 4380), called
from `emlTukeyHSD` (line 4222). Guarded by `.q <> undefined` and
`.q > 0`.

```
-                        .p = Get TukeyQ: .q, .nGroups, .dfWithin, 1
+                        @emlStudentizedRangeQ: .q, .nGroups, .dfWithin, 1
+                        .p = emlStudentizedRangeQ.p
```

### Site 4 — `stats/eml-inferential.praat:4481`

Same procedure, the critical-q line outside the pair loop.

```
-        .qCritical = Get invTukeyQ: .alpha, .nGroups, .dfWithin, 1
+        @emlInvStudentizedRangeQ: .alpha, .nGroups, .dfWithin, 1
+        .qCritical = emlInvStudentizedRangeQ.q
```

### Site 5 — `stats/eml-inferential.praat:7476`

Procedure: `emlGamesHowell` (starts line 7312). `.df` here is the
per-pair Welch–Satterthwaite df, **not integer in general** — see §1's
flag before applying.

```
-                        .pVal = Get TukeyQ: .q, .nGroups, .df, 1
+                        @emlStudentizedRangeQ: .q, .nGroups, .df, 1
+                        .pVal = emlStudentizedRangeQ.p
```

### Site 6 — `stats/eml-inferential.praat:7480`

Same procedure, the per-pair critical-q line (same fractional-df flag).

```
-                    .qCrit = Get invTukeyQ: .alpha, .nGroups, .df, 1
+                    @emlInvStudentizedRangeQ: .alpha, .nGroups, .df, 1
+                    .qCrit = emlInvStudentizedRangeQ.q
```

## 3. Comment and doc-string sites in the same two files

A plain `grep` for the retired strings does not distinguish code from
prose, and the completeness check in §7 does not either, so these seven
lines need rewording too, in the same patch that lands §2 (all still
inside files this plan cannot touch):

| File | Line | Current text (excerpt) | Fix |
|---|---|---|---|
| `stats/eml-anova-kernel.praat` | 108 | "its Tukey and Scheffe legs use the same Praat builtins (Get TukeyQ:/Get invTukeyQ:, fisherQ/invFisherQ)" | Name `@emlStudentizedRangeQ`/`@emlInvStudentizedRangeQ` in place of the builtins |
| `stats/eml-anova-kernel.praat` | 151 | "Praat functions used: ... Get TukeyQ:, Get invTukeyQ:, floor, abs, sqrt." | Drop the two builtin names from this list; add the two port procedure names if this comment is meant to enumerate everything the file calls |
| `stats/eml-anova-kernel.praat` | 1406 | "Praat's own Get TukeyQ:/Get invTukeyQ:/invFisherQ (the same builtins ... already use elsewhere in this plugin)" | Same rename |
| `stats/eml-anova-kernel.praat` | 1432 | "referred to the studentized range distribution via Get TukeyQ:/Get invTukeyQ: with the family size k ..." | Same rename |
| `stats/eml-inferential.praat` | 4160 | "using Praat's native studentized range distribution functions (Get TukeyQ: / Get invTukeyQ:) for p-values and critical values." | Rename to the port procedures; drop "native" |
| `stats/eml-inferential.praat` | 4214 | "Uses Get TukeyQ: (Goodies) for p-values and Get invTukeyQ: for critical q — no Report parsing or Table side effects" | Same rename |
| `stats/eml-inferential.praat` | 7305 | "Uses Get TukeyQ: for p-values and Get invTukeyQ: for critical q, both of which accept a fractional df" | Same rename, and see §1 — do not carry the "accept a fractional df" claim forward unverified for the port |

## 4. Does the caller's file already load the port module? Measured: no

```
$ grep -n "studentized-range" plugin_EML_StatsGraphs/setup.praat
434:# not-in-barrel: stats/eml-studentized-range.praat -- The studentised-range port (ptukey/qtukey). ...
```

The port is explicitly OUT of the barrel (`setup.praat`'s
`emlSetupModule$` table, lines 392-407, 15 rows) — its whole reason for
being out is "nothing calls it yet ... a barrel line would make a
procedure with a known accuracy defect loadable from any script." Once
the six sites in §2 call it, that reason is gone and the module has to
move from the not-in-barrel list into the table, in front of every
module that calls it.

Confirmed the port has no dependencies of its own that would constrain
where it can sit:

```
$ grep -n "^\s*@eml[A-Za-z_]*" plugin_EML_StatsGraphs/stats/eml-studentized-range.praat | grep -v "emlStudentizedRangeQ\|emlInvStudentizedRangeQ\|eml_srq"
(no output)
```

Its only callers after this repoint are `stats/eml-anova-kernel.praat`
(current table row 5) and `stats/eml-inferential.praat` (row 6). Per
setup.praat's own rule ("THE MODULE ORDER IS THE DEPENDENCY ORDER"), the
port must load before both. Proposed edit to the table at
`plugin_EML_StatsGraphs/setup.praat` lines 392-407:

```
 emlSetupNModules = 15                                    emlSetupNModules = 16
 emlSetupModule$ [ 1] = "stats/eml-core-utilities.praat"   emlSetupModule$ [ 1] = "stats/eml-core-utilities.praat"
 emlSetupModule$ [ 2] = "stats/eml-core-descriptive.praat" emlSetupModule$ [ 2] = "stats/eml-core-descriptive.praat"
 emlSetupModule$ [ 3] = "stats/eml-extract.praat"          emlSetupModule$ [ 3] = "stats/eml-extract.praat"
 emlSetupModule$ [ 4] = "stats/eml-output.praat"           emlSetupModule$ [ 4] = "stats/eml-output.praat"
                                                          + emlSetupModule$ [ 5] = "stats/eml-studentized-range.praat"
 emlSetupModule$ [ 5] = "stats/eml-anova-kernel.praat"     emlSetupModule$ [ 6] = "stats/eml-anova-kernel.praat"
 emlSetupModule$ [ 6] = "stats/eml-inferential.praat"      emlSetupModule$ [ 7] = "stats/eml-inferential.praat"
 emlSetupModule$ [ 7] = "stats/eml-psychometrics.praat"    emlSetupModule$ [ 8] = "stats/eml-psychometrics.praat"
 emlSetupModule$ [ 8] = "stats/eml-categorical.praat"      emlSetupModule$ [ 9] = "stats/eml-categorical.praat"
 emlSetupModule$ [ 9] = "stats/eml-result-writer.praat"    emlSetupModule$ [10] = "stats/eml-result-writer.praat"
 emlSetupModule$ [10] = "stats/eml-record.praat"           emlSetupModule$ [11] = "stats/eml-record.praat"
 emlSetupModule$ [11] = "graphs/eml-graph-procedures.praat"emlSetupModule$ [12] = "graphs/eml-graph-procedures.praat"
 emlSetupModule$ [12] = "graphs/eml-annotation-procedures.praat" ... [13] = same
 emlSetupModule$ [13] = "graphs/eml-draw-procedures.praat" emlSetupModule$ [14] = "graphs/eml-draw-procedures.praat"
 emlSetupModule$ [14] = "stats/eml-analysis.praat"         emlSetupModule$ [15] = "stats/eml-analysis.praat"
 emlSetupModule$ [15] = "stats/eml-demo-tables.praat"      emlSetupModule$ [16] = "stats/eml-demo-tables.praat"
```

i.e. insert one row at position 5, renumber 5-15 to 6-16, bump
`emlSetupNModules` 15 → 16. Delete the `not-in-barrel` row at line 434
(and its accuracy-defect reason, now stale — the port only belongs
out of the barrel while it is unaccepted; once it is accepted AND
called, both the exclusion and its justifying reason are wrong).

## 5. Copies that must be re-driven, not hand-edited

`git grep -l` finds the two retired strings as CODE (not just prose) in
eight more tracked files, all under `harness/*/out/` (confirmed
tracked, not scratch, one call per path with
`git ls-files --error-unmatch`):

```
$ git grep -l "Get TukeyQ\|Get invTukeyQ" -- 'harness/'
harness/dialogheight/out/menu/work/prefs/plugin_EML_StatsGraphs/stats/eml-inferential.praat
harness/dialogheight/out/wizard/work/prefs/plugin_EML_StatsGraphs/stats/eml-inferential.praat
harness/dialogheight/out/wizard_skew/work/prefs/plugin_EML_StatsGraphs/stats/eml-inferential.praat
harness/normalitycoverage/out/seed_standalone/stats/eml-inferential.praat
harness/normalitycoverage/out/seed_wizard/stats/eml-inferential.praat
harness/orderpersist/out/seed_ordering/stats/eml-inferential.praat
harness/orderpersist/out/seed_persist/stats/eml-inferential.praat
harness/penassert/out/shadow/plugin/stats/eml-inferential.praat
```

Eight files, seven matching lines each (`git grep -c` on the same
pathspec: every one of the eight reports `:7`) — the table below lists
all eight.

Every one of these is a byte-for-byte `cp -r "$ROOT/plugin_EML_StatsGraphs" "$OUT"`
snapshot taken by a harness seed/run script, not a hand-maintained
file — confirmed:

```
$ grep -n "cp -r" harness/orderpersist/seed_persist.sh
27:cp -r "$ROOT/plugin_EML_StatsGraphs" "$OUT"
```

Editing these directly would be immediately overwritten the next time
their seed script runs, and would leave them re-drifting from the real
source. **Do not patch them. Re-run their seed script after §2-§4 land**,
which regenerates them from the repointed plugin automatically:

| Tracked copy | Regenerated by |
|---|---|
| `harness/normalitycoverage/out/seed_wizard/` | `harness/normalitycoverage/seed_wizard.sh` |
| `harness/normalitycoverage/out/seed_standalone/` | `harness/normalitycoverage/seed_standalone.sh` |
| `harness/dialogheight/out/menu/` | `harness/dialogheight/menu.sh` |
| `harness/dialogheight/out/wizard/` | `harness/dialogheight/run.sh` (MODE=wizard) |
| `harness/dialogheight/out/wizard_skew/` | `harness/dialogheight/run.sh` (MODE=wizard_skew) |
| `harness/penassert/out/shadow/` | `harness/penassert/run.sh` |
| `harness/orderpersist/out/seed_persist/` | `harness/orderpersist/seed_persist.sh` |
| `harness/orderpersist/out/seed_ordering/` | `harness/orderpersist/seed_ordering.sh` |

There are eight more untracked copies in the current working tree
(`harness/correlgroup/out/work/*`, `harness/corrscope/out/work_red/`,
`harness/wraptext/out/before/`, `harness/regressdoors/out/work/*`) —
confirmed untracked with `git ls-files --error-unmatch`, one call per
path. These are scratch output from harness runs already taken in this
container and are not part of the committed tree; §7's completeness
check must run as `git grep`, which only searches tracked content, so
these do not need re-driving for the check to pass, only for whichever
in-progress harness investigation is using them.

## 6. The 144 interval rows: verified, not the ruling's number alone

`TRACKER_KIT_AND_1p0.md` line 20-21 and
`RULING_PROVENANCE_AND_CANCELLATION_2026-09-01.md` §3 both state 144.
Traced the figure to its origin (`docs/RULING_INTERVALS_2026-08-26.md`
line 104-105: "864 + 432 + 60 + 144 rows," with line 85 naming the 144
as "the 144 Tukey rows moving from excused to compared") and then
re-measured it directly against the current kit output rather than
trusting the carried-forward number.

The 144 rows are `quantities.tsv`'s `emlRunAnovaAnalysis` `posthoc_<PAIR>_ci_low`
/ `_ci_high` quantities (lines 219-220: "printed ... in the Tukey HSD
Mean Differences block. Compared against `stats::TukeyHSD` lwr[/upr]")
— the ANOVA door's own Tukey HSD interval, distinct from the Bonferroni
intervals on the standalone pairwise-t/RM/Friedman doors (lines 244-247,
350-351, 361-362 of the same file), which are a different quantity
family and not part of this count.

Cell population: cells where `matrix.tsv`'s `procedure` is
`emlRunAnovaAnalysis` and `posthoc` is `1`:

```
$ awk -F'\t' '!/^#/ && $3=="emlRunAnovaAnalysis" && $9=="1"{print $1}' walkthrough/kit/matrix.tsv | sort -u | wc -l
36
```

Of those 36, 20 have a completed Praat-vs-R comparison in the last kit
run and 16 are incomplete `sweep`-study shapes (see the "not yet run in
this pass" note quoted below). Row count of ci_low/ci_high AGREEMENT
rows (i.e. both sides have a value) restricted to the 36 ANOVA-Tukey
cells:

```
$ awk -F'\t' '!/^#/ && $3=="emlRunAnovaAnalysis" && $9=="1"{print $1}' walkthrough/kit/matrix.tsv | sort -u > /tmp/anova_posthoc_cells.txt
$ cd walkthrough/kit/results
$ awk -F'\t' 'NR==FNR{c[$1];next} ($1 in c) && ($2 ~ /_ci_(low|high)$/)' /tmp/anova_posthoc_cells.txt agreements_all.tsv | wc -l
144
```

**144, confirmed.** (The same query against `disagreements_all.tsv`
returns 236 lines, but those are not numeric mismatches: every one of
them is one of the 16 incomplete `sweep`-study cells, each producing
one "value on the R side, nothing on the Praat side yet, documented as
incomplete" line and one paired "NOT DOCUMENTED" line — confirmed by
inspection of the matched rows, all tagged `sweep` and carrying the note
"the plugin side of this particular shape was not run in this pass ...
listed as incomplete, not as a documented difference between the two
programs." Distinct cell count in that set: 16, matching 36 − 20.)
Tracker A.3's 144 is correct and is now backed by a re-derivable
measurement rather than a carried-forward citation.

This count is unaffected by anything in §2-§5: it measures the LAST kit
run, not a live re-drive. Per the tracker's own language, these are the
rows that "revalidate" — i.e. must be re-measured, not that they are
predicted to fail — after the repoint lands (§8).

## 7. Every validator this repoint requires re-running

Located by grepping `validate/` for the procedures this repoint touches
(`emlTukeyHSD`, `eml_tukeyPairwiseFromGroups`, `emlGamesHowell`,
`emlAnovaKernelTwoWayPostHoc`) and for the port module itself:

```
$ grep -rl "emlTukeyHSD\|eml_tukeyPairwiseFromGroups" validate/
validate/v138_result_store.R
validate/v156_marginal_means.R
validate/v152_extraction_count.R
validate/run_all.R
validate/v150_studentized_range.R
validate/v122_posthoc_never_gated.R
validate/v22_homogeneity.R
validate/v154_srange_against_reference.R

$ grep -rl "emlGamesHowell\|Games.Howell" validate/
validate/v138_result_store.R
validate/v25_anova_showboth.R
validate/run_all.R
validate/v127_door_agreement_census.R
validate/v122_posthoc_never_gated.R
validate/v22_homogeneity.R

$ grep -rl "emlAnovaKernelTwoWayPostHoc" validate/
validate/v156_marginal_means.R
```

Plus the module-table validator, which the setup.praat edit in §4
directly changes the input of:

```
$ grep -n "emlSetupModule\$\|not-in-barrel" validate/v88_barrel_population.R | head -3
95:inc_lines <- grep('^\\s*emlSetupModule\\$\\s*\\[\\s*[0-9]+\\s*\\]\\s*=', code,
121:ex_lines <- grep("^\\s*#\\s*not-in-barrel:", src, value = TRUE)
128:           sprintf("setup.praat carries the not-in-barrel rows (%d)",
```

and `validate/v82_generated_barrel.R`, which pins the module table
against `@emlRecordRender`'s own include list (setup.praat's own
comment: "pinned against each other by validate/v82").

Full re-run list:

- `v22_homogeneity.R`
- `v25_anova_showboth.R`
- `v82_generated_barrel.R` — module table changed (§4)
- `v88_barrel_population.R` — not-in-barrel row removed, module count
  changed (§4)
- `v122_posthoc_never_gated.R`
- `v127_door_agreement_census.R`
- `v138_result_store.R`
- `v150_studentized_range.R` — its own comment names the retired
  builtin (§3-adjacent; this is the port's host-function characterization
  script, not a plugin caller, but its prose needs the same rename)
- `v152_extraction_count.R`
- `v154_srange_against_reference.R` — the port's own acceptance gate;
  must already be clean before this plan applies (§0)
- `v156_marginal_means.R`
- `run_all.R` — drives the full suite; run at the gate per the standing
  batched-re-drive rule, not per commit (`docs/RULING_INTERVALS_2026-08-26.md`,
  "Validation scoping")
- The walkthrough kit itself (`walkthrough/kit/matrix.tsv` /
  `compare.R`): re-drive at minimum the 36 `emlRunAnovaAnalysis`
  posthoc=1 cells (§6) and every Games-Howell / two-way Scheffe-or-Tukey
  posthoc cell, to regenerate `agreements_all.tsv` /
  `disagreements_all.tsv` against the port's numbers instead of the
  builtin's
- The eight seed/run scripts named in §5, to regenerate the eight
  tracked `harness/*/out/` copies

## 8. What "revalidate" should show, per the ruling's own measurement

`mailbox/to-fable/MEMO_HOST_SWEEP_RESULTS_2026-09-01.md` already
measured the 144-row region directly (k = 2..6, df = 45, alpha
0.10/0.05/0.01) against `qtukey` and found worst relative error 8.2e-15
(x64v3) / 1.0e-13 (intel64) — both "agree to every printed digit," four
to five orders inside the standard 1e-9 rule. That is evidence about
`invTukeyQ` vs `qtukey`, not about this port vs `invTukeyQ` — it predicts
the re-drive in §7 should reproduce the same 144 agreements, not that it
is exempt from being re-driven. State the re-driven result, not this
prediction, when §7 is executed.

## 9. The completeness check: exact command and expected output at landing

A plain `grep -r` over the whole repository is the wrong check: it also
matches (a) `mailbox/`, `docs/` and `audit/` — the correspondence and
ruling record, which must keep quoting `Get TukeyQ` / `Get invTukeyQ`
verbatim because that string IS the subject under discussion there, not
a live call; (b) `walkthrough/kit/SWEEP_HOST_FUNCTIONS.praat`, whose
entire purpose (`RULING_UNIQUENESS_SWEEP_2026-09-01.md`) is calling
Praat's OWN builtins on purpose, to characterize their cancellation
defect for the paper — retiring the PLUGIN's use of the builtins does
not and cannot retire the builtins themselves, and this file's two call
sites (lines 43 and 71) are the diagnostic evidence, not a leftover call
site; (c) untracked scratch copies under `harness/*/out/` from harness
runs already taken in this container (§5), which are not part of the
landed tree at all.

The check that matches the ruling's intent — "the re-pointing surface
cannot silently grow" — scopes to the plugin's own source, its harness
snapshot copies, and the kit/validator code that describes it, via
`git grep` (tracked content only, so untracked scratch is invisible to
it) with the port file and the deliberate diagnostic file excluded by
name:

```
git grep -n "Get TukeyQ\|Get invTukeyQ" -- \
  'plugin_EML_StatsGraphs' \
  ':(exclude)plugin_EML_StatsGraphs/stats/eml-studentized-range.praat' \
  'harness' \
  'validate' \
  'walkthrough' \
  ':(exclude)walkthrough/kit/SWEEP_HOST_FUNCTIONS.praat'
```

Measured now, before any patch in this plan is applied (proving the
check is live and would currently fail, as it should):

```
$ git grep -n "Get TukeyQ\|Get invTukeyQ" -- 'plugin_EML_StatsGraphs' ':(exclude)plugin_EML_StatsGraphs/stats/eml-studentized-range.praat' 'harness' 'validate' 'walkthrough' ':(exclude)walkthrough/kit/SWEEP_HOST_FUNCTIONS.praat' | wc -l
73
```

**Expected output at landing, once §2-§5 and the re-drives in §5 and
§7 are complete: no output, exit status 1** (`git grep` exits 1 when it
finds no match). That is the "named check in the suite" the ruling
orders — wire it into `run_all.R` or `v88_barrel_population.R` as a
hard failure on any output, not a manual grep someone remembers to run.

Two files remain matches BY DESIGN and are excluded from the check by
name rather than by being fixed: `eml-studentized-range.praat` itself
(the port, which legitimately names both retired builtins in its own
attribution and rationale prose) and `SWEEP_HOST_FUNCTIONS.praat` (the
permanent diagnostic exception, §9 above). If a future file needs a
similar exception, add it to this command's exclude list explicitly,
with a reason, the same way `setup.praat`'s not-in-barrel rows require
one.

## 10. Order of operations

1. `validate/v154_srange_against_reference.R` passes clean (tracker
   A.2) — precondition, not part of this plan.
2. Resolve the fractional-df flag in §1 for sites 5-6 (Games-Howell) —
   measure the port at a representative non-integer df, or accept the
   unfixed path there, and say which.
3. Apply the six code patches in §2 and the seven comment rewrites in
   §3 (13 edits, 2 files) inside `plugin_EML_StatsGraphs/`.
4. Apply the module-table edit and not-in-barrel deletion in §4 to
   `plugin_EML_StatsGraphs/setup.praat`.
5. Re-run the eight seed/run scripts in §5 to regenerate the eight
   tracked `harness/*/out/` copies.
6. Re-run every validator in §7; re-drive the walkthrough kit's 36
   `emlRunAnovaAnalysis` posthoc cells plus the Games-Howell and
   two-way Scheffe/Tukey posthoc cells; record the 144-row result
   against §8's prediction rather than assuming it.
7. Run the §9 grep check. Confirm empty output before calling A.3/A.5
   done.
