# Error-propagation census — measured, not fixed

Fable — 2 September 2026. Answers tracker section D's "Error-propagation
sweep... status UNMEASURED, must be reported before the tag," against
current HEAD `73a37dc4`. **No code was changed to produce this report.**
Every number below is either the direct output of a script already
committed in this repo (`validate/v134_error_read_lint.R`), or a source
quotation with file:line. Where I could not establish safety by reading,
I say so and recommend a runtime check rather than guessing.

## Headline

The tracker's line reads: *"4 hand fixes + error$-read lint + all 63
sites fixed or adjudicated-safe."* Measured against the current tree:

- The 4 hand fixes **did land** (commit `b0675ce`, 26 Aug) — I re-verified
  three of the four at their current locations; see "What was actually
  fixed" below.
- The error$-read lint **exists and runs** (`validate/v134_error_read_lint.R`,
  committed). It **fails today**.
- The "63 sites" is **not** the count this lint produces at HEAD. Its
  current output:

```
$ cd validate && Rscript v134_error_read_lint.R
v134: population 1 -- 110 procedures error-producing (of 684 procedures indexed).
v134: population 2 -- 355 call sites to a producer; 296 of those go on to use a
v134: numeric output of that call, and are the ones this check audits.
v134:   NO-OUTPUT-USED     59
v134:   OK                 161
v134:   UNCHECKED          112
v134:   USED-BEFORE-CHECK  23

v134: 135 violating call site(s) found (before exemptions) [121 unique
site-keys -- see "the 135 vs 121" below]

FAIL  v134    every violating call site is either fixed or in the adjudicated exempt
              set (121 unadjudicated of 135 violating)
------------------------------------------------------------------------------
12 checks, 11 passed, 1 FAILED
```

`EXEMPT_SITES` -- the list where an adjudicated-safe site's reasoning
would be pinned, per the lint's own design -- **is empty**: zero sites
currently carry the required adjudication. So as measured today: **not
63, not fixed, not adjudicated. 135 raw violations (121 distinct), 0
pinned exempt, gate red.** The claim in the tracker does not hold against
the current tree, full stop -- see "Where 63 came from" for why the
number moved, which is a real, defensible reason and not a regression by
itself.

My own read of all 135, reported in full below, finds:

| My verdict | Count | Meaning |
|---|--:|---|
| **SAFE** (checked or provably equivalent) | 31 | reasoning given per site/cluster |
| **UNSAFE** | 76 | a real defect: wrong message, or an undefined/wrong value can reach output |
| **Untraced / needs a runtime check** | 9 | I could not close the argument by reading alone |
| **Out of scope for 1.0** | 19 | code with menu/wizard doors withdrawn; not on the shipped surface |
| *(mechanically CHECKED by the lint, not independently re-audited by me)* | *161* | *v134's OK bucket -- see caveat below* |

135 = 31 + 76 + 9 + 19. The 161 "OK" sites are the lint's own passing
population; I did not re-derive each of those independently -- auditing
296 sites end to end was out of the time this census had, and the brief
asked me to measure the failing tail, not re-prove the passing majority.

## Reproducing this

```
cd validate
Rscript v134_error_read_lint.R
```
No arguments, no fixtures beyond the plugin tree itself. Base R only
(same "no packages" discipline as the rest of `validate/`). Runs in a
few seconds. This IS the artifact -- rerun it, don't take my counts on
faith.

For the per-site classification below, the exact source lines I read are
quoted inline; anyone can `sed -n '<line>,<line>p' <file>` to check them.

---

## Where "63" came from, and why it no longer matches

`docs/ERROR_CENSUS_2026-08-25.md` + `docs/error-census/*.tsv` (249
rows total: 6 graphs, 58 scripts, 185 stats) give these verdict counts:

| Verdict | Count |
|---|--:|
| RAISED | 129 |
| SWALLOWED-DISCLOSED | 22 |
| SWALLOWED-SILENT | 19 |
| UNCHECKED | 44 |
| NOT-APPLICABLE | 35 |

**19 + 44 = 63.** That is the only combination in the TSVs that produces
63, and it is a defensible definition: SWALLOWED-SILENT + UNCHECKED are
exactly the verdicts where the real error text never reaches the user at
all (SWALLOWED-DISCLOSED at least prints something, even if generic).
I take this as the intended definition of "the 63 sites," though the
disposition paragraph in that document never states the arithmetic
directly -- worth Ian/Fable confirming that reading is the one meant.

That population was measured against commit `3e34b1a` (24 Aug). Between
then and HEAD (`73a37dc`) there have been **29 commits touching
`plugin_EML_StatsGraphs/`** (+13,065/-1,625 lines -- `git diff --stat
3e34b1a..HEAD -- plugin_EML_StatsGraphs/`), including the six-rename
wave, the two-way kernel rewrite, the fingerprint/result-store work, and
the LMM module landing. File:line references from the 25 Aug census do
not resolve to the same code any more -- I did not attempt a line-level
reconciliation of the old 63 against the new 121; the numbers are not
comparable at that grain. What IS comparable, and what I did check, is
whether the specific *named* defects from the 25 Aug census's
"Individually serious" section still exist. See below.

v134 also measures a *different, stricter, mechanical* population than
the human census did (documented in its own header): 110 producers
derived automatically (vs. 182 by human judgment), 355 call sites, 296
audited. It is not trying to reproduce 63 or 121 or any prior number --
it rebuilds the populations from the tree every run, which is the right
design, and the gap from the human census is itself named as an
expected, reportable fact rather than a bug (see the script's own
comments around `POPULATION 1` and the `check_true` "at least 50
error-producing procedures" gate).

## What was actually fixed (confirmed by reading, not by the commit message)

Commit `b0675ce` claims four hand fixes. I re-verified three:

1. **`emlRequireNumericColumn`'s missing else-branch** (the census's
   "a guard that passes a missing column"). Current source,
   `stats/eml-inferential.praat:5046-5056`:
   ```
   else
       ; A COLUMN THAT DOES NOT EXIST FAILS THE GATE. Without this branch
       ; .error$ stays "" from the top of the procedure and the gate reports
       ; success, which is the opposite of its own name. ...
       .error$ = emlAuditColumn.error$
   endif
   ```
   **Fixed, confirmed.**

2. **Effect-size zero-fill** (Cohen's d matrix printing 0.000 for a
   failed cell). Current source, `stats/eml-analysis.praat:596-614`:
   the failure branch now sets `.dMatrix##[.i,.j] = undefined` with a
   comment naming "Punch list 9.1" and stating the printer shows "n/a"
   for it. **Fixed, confirmed** -- and this specific call site is
   correctly gated on `emlCohenD.error$ = ""`, so it does not even
   appear in the 135 (it is one of the 161 "OK" sites).

3. **Shapiro-Wilk printed as undefined** (the standalone normality
   checker). Partially fixed, and this is where it gets interesting --
   see the `shapiro-wilk` cluster below: the fix landed at three of the
   four current call sites, and a structurally identical, previously
   uninspected fourth site (the two-way ANOVA assumption check) still
   has the gap, untraced by either the original hand-fix or this census.

4. The fourth ("both mode drops a single-test failure") I did not
   re-locate at HEAD; the pairwise "both" logic has moved substantially
   in the six-rename/kernel-consolidation wave and I did not trace it
   inside this census's budget. Flag for a follow-up read, not asserted
   either way.

## The full list, clustered by producer (135 sites)

Each cluster below states one shared reason; I read at least one
representative call site per cluster in full (file:line quoted), and for
clusters with more than ~5 sites I additionally spot-checked 3-4 more
before generalizing -- noted per cluster. The complete 135-row table (no
clustering) is in the appendix.

### UNSAFE -- 76 sites across 7 clusters

**`emlCountGroups`-proxy -- 20 sites, UNSAFE.**
`eml-analysis.praat:3552`, `eml-check-normality.praat:155`,
`eml-correlate.praat:268`, `eml-draw-procedures.praat:{2927,3061,3918,
4918,5581,5971,6484,6491,6882,6888}`, `eml-graph-procedures.praat:{7102,
7550}`, `eml-graphs-form.praat:5983`, `eml-wizard.praat:{383,622,1963,
2509}`.
`emlCountGroups` (`stats/eml-extract.praat:1713`) sets `.nGroups=0` at
entry and never changes it on the "column not found" path
(`stats/eml-extract.praat:1734-1735`). Every site in this cluster reads
`.nGroups`/`.groupLabel$[]` without ever reading `.error$`. Verified
concretely at `eml-draw-procedures.praat:2927-2936`: a missing/misspelled
condition column prints `"WARNING: Spaghetti plot requires at least 2
conditions. Found 0."` -- discarding "Column not found: X" entirely. Worse
at `eml-analysis.praat:3552` (`emlRunGroupedRegression`): `.pgTotal=0`
silently produces a report reading "Groups: 0, Analysed: 0" with **no
warning printed at all** -- I read the full loop
(`eml-analysis.praat:3551-3585`) and found no fallback message for
`.pgTotal=0`. Spot-checked 4 of 20 in full; the rest share the identical
producer contract and call shape (grep-confirmed same argument pattern).

**`eml_getGroupData`/`eml_getGroupPairedData`-proxy -- 33 sites, UNSAFE.
This is the largest cluster and the most consequential finding of this
census.** Every pairwise/ANOVA/correlation kernel in
`eml-inferential.praat` extracts each group through this producer
(`TukeyHSD:4312, OneWayAnova:4636, KruskalWallis:5544, DunnTest:5775,
PairwiseT:6115, PairwiseWilcoxon:6370, Scheffe:6569, BrownForsythe:6852,
WelchAnova:7093, GamesHowell:7382`), plus `eml-annotation-procedures.praat`
(13 sites, drawing annotations), `eml-wizard.praat` (5 sites),
`eml-check-normality.praat` (1), `eml-correlate.praat` (2),
`eml-analysis.praat` (2, grouped regression). On failure
`eml_getGroupData` (`stats/eml-extract.praat:1920-1946`) sets `.n=0`,
`.data#=zero#(0)` -- never a stale nonzero value -- but **every one of
these 33 sites checks `.n` instead of `.error$`** (verified directly at
5 of them: `emlKruskalWallis:5544-5555`, `emlDunnTest:5775`,
`emlScheffe:6569`, `emlWelchAnova:7093`, `emlGamesHowell:7382`, all
share `if .groupN[.g] = 0` / `.gN < 2` gates, never `.error$`). The
practical failure mode: one bad cell in one group's data column (a
locale comma, a stray non-numeric value the column-exists check upstream
does not catch) is silently relabelled "Group X has 0 observations" or
folds the group into a singleton list -- the actual diagnosis (which cell,
why) is thrown away, in the CORE statistical engine, not a peripheral
script. The original 25 Aug census sampled this exact pattern
("checking by proxy") in 15/20 unchecked `scripts/` sites and called it
systemic; this census confirms it also runs through the entire
`eml-inferential.praat` kernel layer, which the 25 Aug census's own
stats-census.tsv did not flag at these specific lines (they have since
moved and, per the diff stat above, much of this file's content is
new/rewritten since 24 Aug).

**`skewness`/`kurtosis`-unguarded -- 10 sites, UNSAFE.**
`emlSkewness`/`emlKurtosis` (`stats/eml-core-descriptive.praat:294,328`)
reset `.result=undefined` on failure (n below minimum, or SD=0 -- a
column of identical values, which is a normal real-data state, not an
edge case). Confirmed live and reachable at
`eml-analysis.praat:3939-3941` inside `emlRunNormalityAnalysis`: unlike
the Shapiro-Wilk print two lines later in the SAME procedure (which IS
gated, see below), `.kurtosis`/`.skewness` are used unconditionally --
both to build the printed `.recResult$` string
(`eml-analysis.praat:4001-4003`, no `if emlKurtosis.error$=""` guard) and
as direct input to `@emlNormalityRecommendation`'s `.shapeSevere` boolean
(`eml-analysis.praat:3734-3735`, `abs(.kurtosis) >= threshold` --
comparison against `undefined` is false in Praat, so an incalculable
kurtosis is silently read as "not severe," which is a wrong answer
feeding a real recommendation, not just a cosmetic display gap). The
other 9 sites (`eml-core-descriptive.praat:645/647`,
`eml-check-normality.praat:190/192`, `eml-wizard.praat:2533/2535/
3593/3594`) share the identical producer and were not each individually
traced to their own terminal print -- flagged as sharing the same
confirmed defect shape, not independently reproduced at each line.

**`pearson`/`spearman`-unguarded, incl. one confirmed sibling-drift bug
-- 7 sites, UNSAFE.**
`emlPearsonCorrelation`/`eml_pearsonCore`/`emlSpearmanCorrelation` all
reset their numeric outputs to `undefined` before any guard (documented
explicitly at `eml-inferential.praat:808-814`, precisely to avoid the
stale-cross-call risk this whole census is about -- a real, deliberate
defense). But **`eml-analysis.praat:3126` (`emlRunCorrelationAnalysis`)
has a confirmed, concrete drift-between-siblings bug**: `.pearErr$` is
captured (`:3123-3131`) and even restored onto
`emlPearsonCorrelation.error$` (`:3148`), but `grep -n 'pearErr'
stats/eml-analysis.praat` shows it is **never read again anywhere in the
file** -- while its sibling `.spearErr$` (identical shape, `:3139`) IS
surfaced two lines later as `"Spearman correlation not computed: " +
.spearErr$` (`:3164-3165`). A Pearson-side failure (zero variance, n<3)
silently prints undefined r/t/p with no note, while the exact same
failure on the Spearman side is disclosed. This is the same
"drift-between-siblings" signature the 25 Aug census named as a general
pattern; this is a newly-confirmed concrete instance of it, not
previously catalogued. The other 6 sites
(`eml-annotation-procedures.praat:4654`, `eml-correlate.praat:384`,
`eml-inferential.praat:885/1049/1568`, `eml-wizard.praat:2039`) share the
producer's undefined-on-failure contract without a downstream display
gate that I could find.

**`emlTTestInterval` -- 1 site, UNSAFE.** `eml-analysis.praat:2152`
(inside `emlReportPairwiseComparison`'s Bonferroni-interval branch).
`emlTTestInterval` (`eml-inferential.praat:628-636`) fails when `t=0`
exactly -- a real, reachable state (two groups/pairs with identical
means), not a glitch. `.low`/`.high` stay `undefined` and print
unexplained in a confidence-interval column.

**`emlSpearmanExactP` method-label -- 1 site, UNSAFE (low severity).**
`eml-inferential.praat:1618`. Traced in full
(`:1463-1469`, `:1618-1646`): a genuine `emlSpearmanExactP` failure
leaves `.method$=""`, which the exhaustive dispatch below turns into
`.error$ = "Internal: unrecognised Spearman method label from
@emlSpearmanExactP: "` -- the analysis DOES still refuse (no silent
success, no wrong number reaches output), but the message shown is a
confusing internal-sounding string rather than the true reason
("Need at least 2 pairs"). Real defect, low practical severity: this
branch requires ties to be absent AND n to have already passed an
earlier Spearman-eligibility gate, so I judge the underlying failure as
very unlikely to be reachable in practice, though I did not prove it
unreachable.

**Demo script -- 4 sites, UNSAFE (low priority).**
`eml-stats-demo.praat:{88,93,112,116}` (`emlTTest`, `emlCohenD`,
`emlPearsonCorrelation`, `emlWilcoxonSignedRank`, all fully unchecked).
This is a bundled example/teaching script, not reachable from the menu
or wizard. Same defect shape as the corresponding production clusters
above; listed separately because its severity is "sets a bad example,"
not "reaches a real user."

### SAFE -- 31 sites, with the specific reason for each cluster

**`emlCountGroups` + `.nBlankRows` precheck -- 5 sites, SAFE.**
`eml-analysis.praat:{120,534,957,1268,1826}`. v134 flags these
USED-BEFORE-CHECK because `.nBlankRows` is read one line before the
`.error$` test. But `.nBlankRows` is initialised to 0 at
`emlCountGroups`'s top (`eml-extract.praat:1718`) and only incremented
inside the row loop that runs on the SUCCESS path -- it cannot be
nonzero-and-wrong on a failure. The real gate, on `.nGroups`, correctly
reads `emlCountGroups.error$ <> ""` immediately after
(`eml-analysis.praat:120-124`, confirmed identical at all 5 sites).
Mechanically flagged, actually safe.

**p-adjustment trio (`emlBonferroni`/`emlHolm`/`emlBenjaminiHochberg`)
-- 15 sites, SAFE.** `eml-analysis.praat:{5166,5169,5172}`,
`eml-anova-kernel.praat:{1611,1617,1621}`,
`eml-inferential.praat:{5879,5882,5885, 6192,6195,6198, 6415,6418,6421}`.
Read all three producers in full (`eml-inferential.praat:3819-3852` for
Bonferroni, `:3888+` Holm, `:3987+` BH). Each has exactly two failure
modes: empty input vector, or every p-value undefined. The empty-vector
case is structurally unreachable at every one of these 15 call sites
because the input is always sized `nGroups*(nGroups-1)/2` with
`nGroups>=2` already guaranteed by an earlier gate in the same
procedure -- so `nInput>=1` always. The all-undefined case (every
pairwise test upstream failed) already produces a correctly
all-`undefined` `.adjusted#` on the error path -- identical to what a
caller checking `.error$` first would have produced by hand. Reading
`.error$` here is redundant, not merely omitted.

**Shapiro-Wilk, three of four sites -- 3 sites, SAFE.**
`eml-analysis.praat:3951`, `eml-check-normality.praat:186`,
`eml-wizard.praat:2529`. All three pass `emlShapiroWilk.error$` as an
explicit argument to `@emlNormalityRecommendation`
(`eml-analysis.praat:3966-3968`, `eml-check-normality.praat:207-208`,
`eml-wizard.praat:2538-2539`), which does the actual nested-if check
internally (`eml-analysis.praat:3737-3748`, `.swUsable` gate) -- this is
a deliberate, documented architecture (comment at
`eml-check-normality.praat:216-220` names it explicitly: "the shared
procedure guards it with a NESTED if"). And at `eml-analysis.praat`
specifically, the raw `"Shapiro-Wilk W=..."` print line is ALSO
independently gated: `if .swError$ = "" ... .recResult$ = "Shapiro-Wilk
W = "...` (`:3997-4000`) -- confirmed, this is the actual "4th hand fix"
working correctly. A mechanical text-order scanner cannot see a check
performed one procedure down; a human read confirms it is real.

**`emlDrawQQPlot` -- 2 sites, SAFE.**
`eml-check-normality.praat:520`, `eml-wizard.praat:3199`. The producer
documents `.drew` as an alternate success flag equivalent to
`.error$=""` (`graphs/eml-draw-qq.praat:123`: "`.error$` -- refusal
message, "" when `.drew` = 1"), set to 1 only on the true success path
(`:390`). Both call sites branch on `.drew=0` to show `.error$` and
`.drew=1` to show `.n`/`.nDropped` (`eml-check-normality.praat:519-528`)
-- functionally identical to checking `.error$` directly, and `.n`/
`.nDropped` are computed honestly on both paths regardless
(`graphs/eml-draw-qq.praat:167-175`).

**`emlRMAnovaTest` -- 1 site, SAFE.** `eml-analysis.praat:4597`.
`.degenerate` is set to 1 in lockstep with `.error$` in every branch of
the producer -- verified by reading every assignment site
(`grep '\.degenerate\|\.error\$' eml-analysis.praat` restricted to
4388-4590: `.degenerate=1` and `.error$=...` are set together, never
independently). Gating the recorder string on `.degenerate=0`
(`:4600`) is equivalent to gating on `.error$=""`, and the real
`.error$` check follows two lines later for the reporting path
(`:4616`).

**`eml_fpCompose` pass-through -- 3 sites, SAFE.**
`eml-extract.praat:{3660,3701,3745}`
(`emlDataFingerprint`/`emlGroupFingerprint`/`emlAnalysisFingerprint`).
All three are pure wrappers: fields are copied to same-named locals and
`.error$` is copied last (`:3660-3668`), then the WRAPPER's own
`.error$` is what its caller reads -- the same "propagates to the
caller's own `.error$`" shape the 25 Aug census counted 129 times as
RAISED. v134 flags these because the field-copy lines textually precede
the `.error$`-copy line, but nothing here computes or displays a value;
it is pure relay.

**`emlAuditColumn` prevalidated -- 2 sites, SAFE.**
`eml-extract.praat:140`, `eml-analysis.praat:4199`. Both call
`emlAuditColumn` only after the SAME column was already confirmed
present on the SAME unmutated table earlier in the SAME procedure
(`eml-extract.praat:107-113` checks `.colExists` before reaching :140;
`eml-analysis.praat:4196-4197` calls `@eml_openColumn` on the identical
column just above :4199) -- the one failure mode `emlAuditColumn` has
(column not found) is provably unreachable at these two calls.

### Untraced -- 9 sites, recommend a runtime check

**Two-way ANOVA assumption checks -- 2 sites.**
`eml-anova-kernel.praat:474` (`emlLeveneTest`), `:489`
(`emlShapiroWilk`), both inside `emlAnovaKernelTwoWay`. Deliberately NOT
folded into this procedure's own `.error$` -- an assumption check
failing does not fail the two-way ANOVA itself, and the two error
strings are exposed as this procedure's own named outputs
(`.leveneError$`, `.shapiroError$`, `eml-anova-kernel.praat:290-292`).
Whether the CALLER of `emlAnovaKernelTwoWay` reads those two fields
before printing `.leveneW`/`.shapiroW` is one hop further than this
census traced. **Recommend:** run a two-way ANOVA on a dataset with a
perfectly constant residual (a fully balanced design with zero cell
variance) and read the Info window -- either the assumption lines are
omitted/explained, or they print "undefined" bare, which settles it in
under a minute of Praat time.

**`emlExtractColumn` in the wizard's normality-check page -- 3 sites.**
`eml-wizard.praat:{3873,3884,3898}`. Proxy-checks `.n>=3` instead of
`.error$`. Column names here come from a live picker bound to the
current table rather than typed text, so "column not found" looks
unlikely -- but I did not trace whether the picker's list can go stale
between population and use (e.g. after a table swap mid-dialog).
**Recommend:** a runtime click-through, not a read.

**`emlExtractGroupVectors` -- 1 site.**
`eml-annotation-procedures.praat:4885`. Only failure mode read here is
"table is empty"; reached only after `@emlBridgeGroupComparison`
already computed statistics on the same table, which is very likely
impossible if it were empty. Plausible, not proven -- I did not trace
the full path into `emlBridgeGroupComparison`.

**`emlStudentizedRangeQ` inside the port's own root-finder -- 3 sites.**
`eml-studentized-range.praat:{827,834,850}`
(`emlInvStudentizedRangeQ`). **This file is owned by another agent and
under concurrent edit right now** (per this task's own exclusive-file
boundary) -- I read it for this census but did not verify it is still in
this state, and it may not be by the time this report is read. From
what I read: `df`/`k` are invariant across the bisection loop's own
iterations, so a failure would occur on the very first call inside the
loop rather than silently partway through -- a mild mitigating
structural fact, not a full safety proof. **Re-run `v134` fresh against
this file before relying on this cluster's count.**

## Out of scope for 1.0 -- 19 sites, not part of the tag decision

**All 19 sites in `eml-lmm.praat`** (`emlBOBYQA`, `emlNelderMead`,
`emlLMM`, `emlParseFormula`, `emlCholeskySolve`) are inside the linear
mixed-model module. Per `mailbox/to-opus/RULING_REGISTRY_VERDICTS_
2026-09-01.md` §1: *"emlRunLMMAnalysis... comes OUT of the registry for
1.0... menu and wizard doors withdrawn; public post-1.0."* I confirmed
by grep that nothing outside `eml-lmm.praat` itself calls into these
procedures on a reachable path (`grep -rn "emlLMM\b"` outside that file
turns up only comments and a forest-plot drawing procedure gated behind
the same withdrawn door). This matches the disposition the 25 Aug census
already gave the mixed-model findings ("tabled and menu-unreachable by
ruling -- filed, not queued") -- same call, still correct, now re-verified
against the current tree rather than assumed carried forward.

## Recommendation

The tracker's D-lane item should move from UNMEASURED to: **not done**.
121 unique unadjudicated violations stand (135 raw call-site
occurrences), `EXEMPT_SITES` is empty, and the lint's own gate is red.
My own classification narrows the population that actually needs
fixing before a defensible "adjudicated-safe" ruling can be written:

- **76 sites are real defects** (`eml_getGroupData`-proxy at 33 is the
  single highest-value target -- it is the core inferential engine, not
  a peripheral script; the confirmed Pearson/Spearman sibling-drift bug
  at `eml-analysis.praat:3126` is a one-line fix with a known-good
  sibling to copy).
- **31 sites can be adjudicated safe today**, each with the reasoning
  above ready to paste into `EXEMPT_SITES` and an `ERROR-READ EXEMPT`
  source comment, exactly as v134 already expects.
- **9 sites need a runtime check, not more reading**, and I named the
  specific check for each.
- **19 sites (the LMM module) should get an explicit exclusion-list
  entry in v134** itself (mirroring the registry's own LMM exclusion),
  so the lint's population stops mixing 1.0-relevant and post-1.0 code
  in the same red count.

None of this was fixed. That is the next pass's work, on top of this
measurement.

---

## Appendix -- all 135 sites, one row each

Columns: file:line, calling procedure, called (unchecked) producer,
v134's own status label, my cluster, my verdict.

| File:Line | Caller | Callee | v134 status | Cluster | Verdict |
|---|---|---|---|---|---|
| eml-lmm.praat:1487 | emlLMM | emlBOBYQA | USED-BEFORE-CHECK | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3261 | emlProfileCI | emlBOBYQA | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3365 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3381 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3414 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3430 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3487 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3503 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3530 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3546 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3585 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3601 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3624 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3640 | emlProfileCI | emlNelderMead | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3726 | emlBootstrapCI | emlLMM | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3813 | emlLikelihoodRatioTest | emlLMM | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3821 | emlLikelihoodRatioTest | emlParseFormula | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3826 | emlLikelihoodRatioTest | emlLMM | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-lmm.praat:3847 | emlLikelihoodRatioTest | emlCholeskySolve | UNCHECKED | LMM-out-of-scope | OUT-OF-SCOPE |
| eml-anova-kernel.praat:474 | emlAnovaKernelTwoWay | emlLeveneTest | USED-BEFORE-CHECK | assumption-check-two-way | UNTRACED |
| eml-anova-kernel.praat:489 | emlAnovaKernelTwoWay | emlShapiroWilk | USED-BEFORE-CHECK | assumption-check-two-way | UNTRACED |
| eml-analysis.praat:4199 | emlExtractConditionMatrix | emlAuditColumn | UNCHECKED | audit-column-prevalidated | SAFE |
| eml-extract.praat:140 | emlExtractColumn | emlAuditColumn | UNCHECKED | audit-column-prevalidated | SAFE |
| eml-stats-demo.praat:88 | (top-level) | emlTTest | UNCHECKED | demo-script | UNSAFE-LOW-PRIORITY |
| eml-stats-demo.praat:93 | (top-level) | emlCohenD | UNCHECKED | demo-script | UNSAFE-LOW-PRIORITY |
| eml-stats-demo.praat:112 | (top-level) | emlPearsonCorrelation | UNCHECKED | demo-script | UNSAFE-LOW-PRIORITY |
| eml-stats-demo.praat:116 | (top-level) | emlWilcoxonSignedRank | UNCHECKED | demo-script | UNSAFE-LOW-PRIORITY |
| eml-check-normality.praat:520 | (top-level) | emlDrawQQPlot | USED-BEFORE-CHECK | draw-qq | SAFE |
| eml-wizard.praat:3199 | (top-level) | emlDrawQQPlot | USED-BEFORE-CHECK | draw-qq | SAFE |
| eml-analysis.praat:3552 | emlRunGroupedRegression | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-check-normality.praat:155 | (top-level) | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-correlate.praat:268 | (top-level) | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:2927 | emlDrawSpaghettiPlot | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:3061 | emlDrawSpaghettiPlot | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:3918 | emlDrawViolinPlot | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:4918 | emlDrawScatterPlot | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:5581 | emlDrawBoxPlot | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:5971 | emlDrawHistogram | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:6484 | emlDrawGroupedViolin | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:6491 | emlDrawGroupedViolin | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:6882 | emlDrawGroupedBoxPlot | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-draw-procedures.praat:6888 | emlDrawGroupedBoxPlot | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-graph-procedures.praat:7102 | emlExtractUniqueValues | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-graph-procedures.praat:7550 | emlMeasureBarData | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-graphs-form.praat:5983 | emlGraphsWorkflow | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-wizard.praat:383 | (top-level) | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-wizard.praat:622 | (top-level) | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-wizard.praat:1963 | (top-level) | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-wizard.praat:2509 | (top-level) | emlCountGroups | UNCHECKED | emlCountGroups-proxy | UNSAFE |
| eml-analysis.praat:120 | emlRunTwoGroupAnalysis | emlCountGroups | USED-BEFORE-CHECK | emlCountGroups/nBlankRows-precheck | SAFE |
| eml-analysis.praat:534 | emlRunAnovaAnalysis | emlCountGroups | USED-BEFORE-CHECK | emlCountGroups/nBlankRows-precheck | SAFE |
| eml-analysis.praat:957 | emlRunKWAnalysis | emlCountGroups | USED-BEFORE-CHECK | emlCountGroups/nBlankRows-precheck | SAFE |
| eml-analysis.praat:1268 | emlRunPairwiseAnalysis | emlCountGroups | USED-BEFORE-CHECK | emlCountGroups/nBlankRows-precheck | SAFE |
| eml-analysis.praat:1826 | emlReportPairwiseDescriptives | emlCountGroups | USED-BEFORE-CHECK | emlCountGroups/nBlankRows-precheck | SAFE |
| eml-analysis.praat:3561 | emlRunGroupedRegression | eml_getGroupPairedData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-analysis.praat:3609 | emlRunGroupedRegression | eml_getGroupPairedData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:5525 | emlReportAnovaComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:5667 | emlReportAnovaComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:5670 | emlReportAnovaComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:5720 | emlReportAnovaComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:5724 | emlReportAnovaComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:5801 | emlReportAnovaComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:5804 | emlReportAnovaComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:6150 | emlReportKWComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:6154 | emlReportKWComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:6211 | emlReportKWComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:6215 | emlReportKWComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:6283 | emlReportKWComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-annotation-procedures.praat:6286 | emlReportKWComparison | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-check-normality.praat:179 | (top-level) | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-correlate.praat:277 | (top-level) | eml_getGroupPairedData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-correlate.praat:372 | (top-level) | eml_getGroupPairedData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:4312 | emlTukeyHSD | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:4636 | emlOneWayAnova | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:5544 | emlKruskalWallis | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:5775 | emlDunnTest | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:6115 | emlPairwiseT | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:6370 | emlPairwiseWilcoxon | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:6569 | emlScheffe | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:6852 | emlBrownForsythe | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:7093 | emlWelchAnova | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-inferential.praat:7382 | emlGamesHowell | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-wizard.praat:1972 | (top-level) | eml_getGroupPairedData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-wizard.praat:2031 | (top-level) | eml_getGroupPairedData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-wizard.praat:2521 | (top-level) | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-wizard.praat:3817 | wizardNormCheck | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-wizard.praat:4220 | wizardRunDescribeByGroup | eml_getGroupData | UNCHECKED | eml_getGroupData-proxy | UNSAFE |
| eml-wizard.praat:3873 | wizardNormCheck | emlExtractColumn | UNCHECKED | extract-column-wizard | LIKELY-SAFE-UNTRACED |
| eml-wizard.praat:3884 | wizardNormCheck | emlExtractColumn | UNCHECKED | extract-column-wizard | LIKELY-SAFE-UNTRACED |
| eml-wizard.praat:3898 | wizardNormCheck | emlExtractColumn | UNCHECKED | extract-column-wizard | LIKELY-SAFE-UNTRACED |
| eml-annotation-procedures.praat:4885 | emlReportBridgeStats | emlExtractGroupVectors | UNCHECKED | extract-group-vectors | LIKELY-SAFE-UNTRACED |
| eml-extract.praat:3660 | emlDataFingerprint | eml_fpCompose | USED-BEFORE-CHECK | fingerprint-passthrough | SAFE |
| eml-extract.praat:3701 | emlGroupFingerprint | eml_fpCompose | USED-BEFORE-CHECK | fingerprint-passthrough | SAFE |
| eml-extract.praat:3745 | emlAnalysisFingerprint | eml_fpCompose | USED-BEFORE-CHECK | fingerprint-passthrough | SAFE |
| eml-analysis.praat:5166 | emlRMPostHoc | emlBonferroni | UNCHECKED | p-adjustment-trio | SAFE |
| eml-analysis.praat:5169 | emlRMPostHoc | emlBenjaminiHochberg | UNCHECKED | p-adjustment-trio | SAFE |
| eml-analysis.praat:5172 | emlRMPostHoc | emlHolm | UNCHECKED | p-adjustment-trio | SAFE |
| eml-anova-kernel.praat:1611 | emlAnovaKernelTwoWayPostHoc | emlBonferroni | UNCHECKED | p-adjustment-trio | SAFE |
| eml-anova-kernel.praat:1617 | emlAnovaKernelTwoWayPostHoc | emlHolm | UNCHECKED | p-adjustment-trio | SAFE |
| eml-anova-kernel.praat:1621 | emlAnovaKernelTwoWayPostHoc | emlBenjaminiHochberg | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:5879 | emlDunnTest | emlBonferroni | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:5882 | emlDunnTest | emlHolm | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:5885 | emlDunnTest | emlBenjaminiHochberg | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:6192 | emlPairwiseT | emlBonferroni | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:6195 | emlPairwiseT | emlHolm | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:6198 | emlPairwiseT | emlBenjaminiHochberg | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:6415 | emlPairwiseWilcoxon | emlBonferroni | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:6418 | emlPairwiseWilcoxon | emlHolm | UNCHECKED | p-adjustment-trio | SAFE |
| eml-inferential.praat:6421 | emlPairwiseWilcoxon | emlBenjaminiHochberg | UNCHECKED | p-adjustment-trio | SAFE |
| eml-analysis.praat:3126 | emlRunCorrelationAnalysis | emlPearsonCorrelation | USED-BEFORE-CHECK | pearson-spearman-drift | UNSAFE |
| eml-annotation-procedures.praat:4654 | emlBridgeCorrelation | emlPearsonCorrelation | UNCHECKED | pearson-spearman-other | UNSAFE |
| eml-correlate.praat:384 | (top-level) | emlPearsonCorrelation | USED-BEFORE-CHECK | pearson-spearman-other | UNSAFE |
| eml-inferential.praat:885 | emlPearsonCorrelationAlt | eml_pearsonCore | USED-BEFORE-CHECK | pearson-spearman-other | UNSAFE |
| eml-inferential.praat:1049 | emlSpearmanCorrelationAlt | emlSpearmanCorrelation | USED-BEFORE-CHECK | pearson-spearman-other | UNSAFE |
| eml-inferential.praat:1568 | emlSpearmanCorrelationDispatch | emlSpearmanCorrelation | USED-BEFORE-CHECK | pearson-spearman-other | UNSAFE |
| eml-wizard.praat:2039 | (top-level) | emlPearsonCorrelation | USED-BEFORE-CHECK | pearson-spearman-other | UNSAFE |
| eml-analysis.praat:4597 | emlRunRepeatedMeasuresAnalysis | emlRMAnovaTest | USED-BEFORE-CHECK | rm-anova-degenerate | SAFE |
| eml-analysis.praat:3951 | emlRunNormalityAnalysis | emlShapiroWilk | USED-BEFORE-CHECK | shapiro-wilk | SAFE |
| eml-check-normality.praat:186 | (top-level) | emlShapiroWilk | USED-BEFORE-CHECK | shapiro-wilk | SAFE |
| eml-wizard.praat:2529 | (top-level) | emlShapiroWilk | USED-BEFORE-CHECK | shapiro-wilk | SAFE |
| eml-analysis.praat:3939 | emlRunNormalityAnalysis | emlSkewness | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-analysis.praat:3941 | emlRunNormalityAnalysis | emlKurtosis | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-check-normality.praat:190 | (top-level) | emlSkewness | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-check-normality.praat:192 | (top-level) | emlKurtosis | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-core-descriptive.praat:645 | emlDescribe | emlSkewness | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-core-descriptive.praat:647 | emlDescribe | emlKurtosis | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-wizard.praat:2533 | (top-level) | emlSkewness | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-wizard.praat:2535 | (top-level) | emlKurtosis | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-wizard.praat:3593 | wizardNormDiag | emlSkewness | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-wizard.praat:3594 | wizardNormDiag | emlKurtosis | UNCHECKED | skew-kurtosis | UNSAFE |
| eml-inferential.praat:1618 | emlSpearmanCorrelationDispatch | emlSpearmanExactP | UNCHECKED | spearman-exact-method-label | UNSAFE-LOW-SEVERITY |
| eml-studentized-range.praat:827 | emlInvStudentizedRangeQ | emlStudentizedRangeQ | UNCHECKED | studentized-range-internal | LIKELY-SAFE-UNTRACED |
| eml-studentized-range.praat:834 | emlInvStudentizedRangeQ | emlStudentizedRangeQ | UNCHECKED | studentized-range-internal | LIKELY-SAFE-UNTRACED |
| eml-studentized-range.praat:850 | emlInvStudentizedRangeQ | emlStudentizedRangeQ | UNCHECKED | studentized-range-internal | LIKELY-SAFE-UNTRACED |
| eml-analysis.praat:2152 | emlReportPairwiseComparison | emlTTestInterval | UNCHECKED | ttest-interval | UNSAFE |

*(All files are under `plugin_EML_StatsGraphs/`, mostly `stats/` -- `eml-draw-procedures.praat`, `eml-annotation-procedures.praat`, `eml-draw-qq.praat`, `eml-graph-procedures.praat` and `eml-graphs-form.praat` are under `graphs/`, `eml-correlate.praat`, `eml-check-normality.praat`, `eml-wizard.praat` and `eml-stats-demo.praat` are under `scripts/`.)*

## The 135 vs. 121

v134's own internal gate speaks of "121 unadjudicated of 135 violating."
The 135 is every raw call site the scanner finds; a handful of these
share an identical `(file, enclosing procedure, callee, call text)` key
-- e.g. two nearly-identical calls a few lines apart with the same
argument text -- and v134's `EXEMPT_SITES` bookkeeping (correctly)
dedupes on that key, since one adjudication note at one such key covers
both physical call sites. I did not separately re-derive which rows
collapse; it does not change any of the reasoning above, since I
addressed every one of the 135 physical rows individually or by
verified-identical cluster.
