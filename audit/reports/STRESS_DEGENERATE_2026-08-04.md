# Degenerate-input stress run — 4 August 2026

> **HISTORICAL RECORD.** This document describes the state of the project on
> the date in its title. It is kept for provenance and is **not** a status
> surface. Do not resume work from it and do not treat its queue, its counts,
> or its instructions as current.
>
> **Current status lives in exactly one place: `audit/FINDINGS_INDEX.md`
> (the rows, not the header prose), with the reasoning in
> `audit/PHASE_ONE_AUDIT_2026-08-06.md`.**

Answer to the question "are there harder stress test cases you should run?",
gathered from a running probe rather than from opinion.

Tool: `dev/tools/stress-degenerate-inputs.py` (plugin tree).
Raw output: `/home/claude/rval/stress_out.txt`.
External reference: `/home/claude/rval/scipy_xcheck.py` → `scipy_xcheck.txt`
(scipy 1.17.1, Rule 32).
Existing-coverage census: `/home/claude/rval/keyword_census.txt`.

---

## Method

The probe emits one tiny Praat script per degenerate case and runs each in an
isolated `praat_barren --run` process with a 25 s timeout, so a case that kills
the interpreter cannot mask the cases after it. Each case reads the procedure's
`.error$` **and** its numeric outputs, which is what makes the four-outcome
classification possible:

| outcome | meaning |
|---|---|
| **CONTRACT** | `.error$` set *and* outputs nulled to `undefined`. A caller that reads an output before testing `.error$` still gets a guardable value. |
| **UNSET** | `.error$` set but outputs left unassigned. Reading one aborts the interpreter with `Unknown variable`. Error contract honored, output contract not. |
| **VALUE** | A number came back. Defect only if the number reads as a completed test when no test was possible. |
| **CRASH** | Interpreter died with no error string at all. Always a defect. |

**A CRASH in the probe is not automatically a defect in the library.** Five of
the first-run "crashes" were my own wrong output-variable names
(`.u`/`.w`/`.f`/`.nComparisons`/`.r2` instead of
`.u1`/`.tPlus`/`.fValue`/`.nPairs`/`.rSquared`), and one was an invalid
argument (`"pooled"` where `emlPairwiseT` accepts only `"welch"`/`"student"` —
the library's rejection was correct). Every `eml*.var` reference in the probe is
now validated against parsed procedure source before each run; the guard is
`/tmp/valref.py`, last result `refs checked: 47  bad: 0`. This validation step
is mandatory before reporting any finding from this tool.

---

## Result

    cases=38  CONTRACT=18  UNSET=2  VALUE=17  CRASH=1

Full per-case matrix in `/home/claude/rval/stress_out.txt`. Eighteen procedures
handle their degenerate case exactly right: error string set, outputs nulled to
`undefined`, no abort. That is the baseline the findings below deviate from.

---

## scipy 1.17.1 cross-check

| case | library | scipy | verdict |
|---|---|---|---|
| KW all values tied | `H=0  p=1` | `nan / nan` (invalid-value divide) | **DEFECT — fabricated result** |
| KW singleton among two larger | `5.142857142857142 / 0.07642628699076812` | identical to 16 sig figs | correct |
| MWU all tied, `{4,4,4,4}` vs `{4,4,4,4}` | `u1=8  p=1` | `8.0 / 1.0` | **exact match — not a defect** |
| MWU n=1 vs n=1, `{2}` vs `{8}` | `u1=0  p=1` | `0.0 / 1.0` | **exact match** |
| Wilcoxon, one nonzero difference | `tPlus=0  p=0.9999999999999999` | `0.0 / 1.0` | float-noise agreement |
| ANOVA all groups constant | `F=undefined  p=undefined`, empty `.error$` | `nan / nan` | agrees; silent but correct |
| t-test at 1e300 | `t=undefined  p=undefined` | `t=-0.0  p=1.0` (overflow warning) | **library safer than scipy** |
| t-test at 1e-300 | CONTRACT, `undefined` | `t=-inf  p=0.0` | **library safer than scipy** |
| catastrophic cancellation | `t=-3.674234614531215  p=0.021311641122079266` | `-3.6742346159570056 / 0.02131164109536937` | agree ~9 sig figs — documented precision limit, not a defect |
| Tukey all groups constant | `p12=undefined  q12=undefined` | `nan` | agrees |
| Tukey singleton group | `nPairs=3  p12=0.045464980976220426  q12=5.196152422706632` | raises `Input sample size must be greater than one` | **library answers where scipy refuses — see finding 6** |

Mann-Whitney and Wilcoxon are **exonerated**: their tied and n=1 outputs match
scipy exactly. They were the two cases that looked most like audit item 9 before
the cross-check.

---

## Findings

### 1. Kruskal-Wallis on all-tied input returns `H=0, p=1` — audit-item-9 class

`stats/eml-inferential.praat`, tie-correction block (~lines 2985–3030):

    .tieCorrection = 1 - .tieCorrSum / .denominator
    if .tieCorrection <= 0
        # All values identical — H must be 0
        .h = 0
        .tieCorrection = 0
    else
        .h = .hRaw / .tieCorrection
    endif
    ...
    if .h = 0
        .p = 1

This is deliberate, and it is the exact failure mode audit item 9 exists to
prevent: when every observation is identical the statistic is 0/0, no test is
possible, and emitting `H=0, p=1` reads to a caller as "tested, no difference."
scipy returns `nan/nan`. Worse, it is **internally inconsistent** — `@emlDunnTest`
on the same all-tied input correctly propagates `undefined` (probe case 35).
Two procedures in the same file, same degenerate input, opposite dispositions.

Highest-value finding. Disposition is a methodology call (see below).

### 2. `undefined` element in a data vector aborts the interpreter — an existing guard applied at 4 of 14 sites

Crash site: **`stats/eml-core-descriptive.praat:101`**, inside `@emlMedian`.

    .sorted# = sort# (.data#)

→ `Error: Vector contains one or more undefined elements. Cannot sort.` No
`.error$`, no guardable outcome, script dead. This is the run's only CRASH, and
it is reachable from real data — an unvoiced frame in a pitch track is
`undefined`, and a caller extracting F0 per interval and handing the vector to
`@emlMedian` hits it.

**Correction to an earlier draft of this file:** the crash was first cited as
`eml-core-descriptive.praat:931`. That line does not exist — the file is 870
lines. Praat's traceback numbers the *flattened include stream*, not the source
file. The `.sorted# = sort# (.data#)` in the trace is line 101. Any future
finding that quotes a Praat line number must be resolved back to a file line
before it is written down.

The fix is not new code. `@eml_hasUndefined` already exists at
`eml-core-descriptive.praat:62`. It is applied at 4 call sites (183, 416, 454,
495) and missing from the rest. Full census of the 14 `sort#` sites in
`stats/`:

| site | procedure | status |
|---|---|---|
| `eml-core-descriptive.praat:195` | `emlPercentile` | guarded (183) |
| `eml-core-descriptive.praat:428` | `emlTrimmedMean` | guarded (416) |
| `eml-core-descriptive.praat:466` | `emlWinsorizedMean` | guarded (454) |
| `eml-core-descriptive.praat:101` | `emlMedian` | **unguarded — the crash** |
| `eml-core-descriptive.praat:133` | `emlMode` | **unguarded** |
| `eml-core-descriptive.praat:737` | `emlShapiroWilk` | **unguarded** |
| `eml-core-utilities.praat:345` | `emlUniqueValues` | **unguarded** |
| `eml-core-utilities.praat:395` | `emlFrequency` | **unguarded** |
| `eml-inferential.praat:4050` | `emlTheilSen` (sorts `.y#`) | **unguarded** |
| `eml-inferential.praat:4058` | `emlTheilSen` (sorts `.x#`) | **unguarded** |
| `eml-inferential.praat:4038` | `emlTheilSen` (derived slopes) | **unguarded**, same input path |
| `eml-lmm.praat:3747` | `emlBootstrapCI` | safe — filters `<> undefined` into the vector first (3737) |
| `eml-lmm.praat:3772` | `emlBootstrapCI` | safe — same filter (3762) |
| `eml-lmm.praat:4192` | `emlLMMSummary` | unguarded but internal — sorts model residuals, not caller data |

`@eml_hasUndefined` is also called at 495 by `@emlMAD`, which reaches `sort#`
indirectly through `@emlMedian` — so `emlMAD` is protected while the procedure
it delegates to is not.

The 4-of-14 ratio is the actual finding. This is not a missing safety feature;
it is a written one applied unevenly.

### 3. `emlLinearRegression` sets `.error$` but leaves outputs unassigned (×2)

Cases 11 and 12 (zero predictor variance; n=2). The error string is right
("Predictor has zero variance." / "Need at least 3 observations for
regression.") but `.slope` is never assigned, so a caller that reads
`emlLinearRegression.slope` before testing `.error$` aborts with
`Unknown variable`. Every one of the 18 CONTRACT procedures nulls its outputs
to `undefined` on the error path. Regression is the only holdout.

An awk census of the procedure body confirms `.slope`, `.intercept`,
`.rSquared` etc. are genuinely assigned on the success path — so this is a real
contract inconsistency, not a probe artifact.

### 4. Silent `undefined` with no error string (softer)

One-way ANOVA on three identical constant groups returns `F=undefined,
p=undefined` with `.error$` empty. The value is correct and safe — a caller
guarding on `undefined` is fine — but a caller that reports `.error$` to the
user has nothing to say about why the analysis produced nothing. Same for the
1e300 overflow case.

### 5. Misattributed diagnostic on underflow (softer)

The 1e-300 case reports `"Both groups have zero variance"`. The values are
distinct; the variance underflowed to zero. The message describes identical
data and would send someone hunting for a duplication bug that isn't there.

### 6. Tukey HSD answers on a singleton group where scipy refuses

`nPairs=3, p12=0.0455, q12=5.196` for groups of n=3, n=3, n=1. scipy raises
`Input sample size must be greater than one`. The library's number is not
arithmetically wrong — MS-within is estimable from the two larger groups — but
one-way ANOVA in this same library *does* reject a singleton group
("group has fewer than 2 observations", cases 28–30). So ANOVA and its own
post-hoc disagree about whether n=1 is admissible. Worth a decision, not
necessarily a change.

---

## Coverage gap in the existing suite

Keyword census over the 15 suites in `dev/tests/phase2/*.praat`
(`/home/claude/rval/keyword_census.txt`):

| family | files mentioning |
|---|---|
| tie / ties | 14 |
| n=1 | 7 |
| identical | 6 |
| undefined | 6 |
| empty | 5 |
| zero variance | 3 |
| degenerate | 3 |
| constant | 2 |
| all equal | 1 |
| **singleton** | **0** |
| **single value** | **0** |
| **insufficient** | **0** |
| **overflow** | **0** |
| **underflow** | **0** |
| **cancellation** | **0** |
| **imbalance** | **0** |
| **1e300 / 1e-300** | **0** |

The three families the question named — ties, perfectly identical groups,
problematically low n — are already the *best*-covered part of the suite. The
zero-coverage families are the ones nobody thought to name: singleton groups
inside an otherwise adequate design, magnitude extremes, catastrophic
cancellation, and extreme group imbalance. Three of the six findings above came
from exactly those.

---

## Dispositions owed

1. **KW all-tied** — change `.h = 0 / .p = 1` to propagate `undefined`
   (matching the Dunn guard and scipy), or leave and document. Methodology
   decision; belongs to the author.
2. **`sort#` crash** — apply the existing `@eml_hasUndefined` at the 8
   caller-data-exposed sites. Straightforward defect fix, no methodology content.
3. **`emlLinearRegression` UNSET** — null `.slope`/`.intercept`/`.rSquared`
   on the error paths to match the other 18. The template is `@emlTheilSen`,
   12 lines below in the same file, which nulls at entry (4000–4001).
4. **ANOVA / Tukey singleton disagreement** — decide which is right.
5. Promote the settled behaviors into
   `dev/tests/phase2/test-degenerate-inputs.praat` via the `emlTest*` helper
   API so the findings become regression-protected, then add to MANIFEST.txt
   (arrives as `TODO:`, description needs hand-editing).

Nothing in this file has been applied to the library. The probe reports; it
does not judge, and it does not edit.
