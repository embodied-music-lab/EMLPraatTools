# Actionable work order — EML Praat Tools

**Date:** 4 August 2026
**Source of findings:** `STRESS_DEGENERATE_2026-08-04.md` (38-case degenerate-input
probe, scipy 1.17.1 cross-check), plus a complete `sort#`-guard census taken
against disk on the same day.
**State of the tree:** nothing below has been applied. Full suite currently
exit 0 — PASS=20, XFAIL=1, 1232 declared checks, 0 failed, 0 skipped, negative
control failing 4/4 by design. Every item here is additive to a green tree.

Two items are marked **AUTHOR DECISION**. They are methodology calls, not
compiler calls, and I have not made them. Everything else is mechanical: the
correct behavior is already established elsewhere in the same library, and the
edit makes an outlier match it.

---

## Ranking

| # | Item | Class | Sites | Risk if left |
|---|---|---|---|---|
| 1 | `sort#` aborts on `undefined` | mechanical | 8 | interpreter death on real pitch data |
| 2 | KW all-tied returns `H=0, p=1` | **AUTHOR DECISION** | 1 | fabricated result reaches a paper |
| 3 | `emlLinearRegression` leaves outputs unassigned | mechanical | 1 proc, 2 paths | `Unknown variable` abort in a caller |
| 4 | Misattributed underflow diagnostic | mechanical | 1 | sends a user hunting a bug that isn't there |
| 5 | ANOVA / Tukey disagree on singleton groups | **AUTHOR DECISION** | 2 procs | internally inconsistent admissibility |
| 6 | Silent `undefined` with empty `.error$` | mechanical | 2 | undiagnosable null result |
| 7 | Regression suite for all of the above | new file | — | findings decay back into the tree |

Ordering is by *reachability from real data* first, *severity of the wrong
answer* second. Item 1 outranks item 2 because item 1 kills the script — the
user cannot miss it — whereas item 2 is only dangerous when it succeeds. Item 2
outranks the rest because it is the one that can survive into print.

---

## 1. Apply the guard the library already has — `sort#` on `undefined`

**Class:** mechanical. No methodology content, no new code, no new procedure.

`@eml_hasUndefined` is defined at `stats/eml-core-descriptive.praat:62`:

    procedure eml_hasUndefined: .v#
        .result = 0
        .nv = size (.v#)
        for .i from 1 to .nv
            if .v#[.i] = undefined
                .result = 1
            endif
        endfor
    endproc

It is called at 4 sites and missing from 8 that are exposed to caller data.
That ratio — 4 of 14 — is the finding. The header comment at line 22 already
states the intent: *"@eml_hasUndefined lets those procedures return undefined
instead."*

**The reference implementation is `@emlPercentile`, lines 183–195.** Every edit
below reproduces this shape:

    @eml_hasUndefined: .data#
    if .n = 0
        .result = undefined
    elsif eml_hasUndefined.result = 1
        .result = undefined
    ...
    else
        .sorted# = sort# (.data#)

Note the ordering constraint: `@eml_hasUndefined` must be called *before* the
`if` chain, because Praat has no short-circuit evaluation (`and`/`or` evaluate
both sides unconditionally) and a procedure call cannot appear inside an `elsif`
condition.

### Sites to edit

| file:line | procedure | sorts | outputs to null |
|---|---|---|---|
| `stats/eml-core-descriptive.praat:101` | `emlMedian` | `.data#` | `.result` |
| `stats/eml-core-descriptive.praat:133` | `emlMode` | `.data#` | `.result`, `.count`, `.isUnique` |
| `stats/eml-core-descriptive.praat:737` | `emlShapiroWilk` | `.data#` | via `.error$` — see below |
| `stats/eml-core-utilities.praat:345` | `emlUniqueValues` | `.data#` | `.values#`, `.nUnique` |
| `stats/eml-core-utilities.praat:395` | `emlFrequency` | `.data#` | `.values#`, `.counts#`, `.nUnique` |
| `stats/eml-inferential.praat:4038` | `emlTheilSen` | derived slopes | `.slope`, `.intercept` (already nulled at entry) |
| `stats/eml-inferential.praat:4050` | `emlTheilSen` | `.y#` | ditto |
| `stats/eml-inferential.praat:4058` | `emlTheilSen` | `.x#` | ditto |

`emlMedian` and `emlMode` currently guard emptiness only:

    .n = size (.data#)
    if .n = 0
        .result = undefined
    else
        .sorted# = sort# (.data#)

Adding one `elsif eml_hasUndefined.result = 1` branch to each is the whole fix.

`emlShapiroWilk` (line 730 onward) is different in kind — it already has an
`.error$` contract, so it gets an error string rather than a silent
`undefined`:

    if .n < 3
        .error$ = "Shapiro-Wilk requires n >= 3, got " + string$ (.n)
    elsif .n > 5000
        .error$ = "Shapiro-Wilk requires n <= 5000, got " + string$ (.n)
    elsif eml_hasUndefined.result = 1
        .error$ = "Shapiro-Wilk: data contains undefined elements"
    endif

with the `@eml_hasUndefined: .data#` call placed above the chain.

`emlTheilSen` needs the guard **once, at entry** (after line 4010), not three
times. All three of its `sort#` calls trace to the same two input vectors, and
it already nulls `.slope`/`.intercept` at 4000–4001, so it only needs the
`.error$` line:

    elsif eml_hasUndefined.result = 1
        .error$ = "emlTheilSen: x or y contains undefined elements"

Run `@eml_hasUndefined` on `.x#` and on `.y#` separately — the procedure takes
one vector, and its outputs are overwritten on the second call, so test the
first result before making the second call.

### Sites deliberately NOT edited

- `stats/eml-lmm.praat:3747` and `:3772` (`emlBootstrapCI`) — **already safe.**
  Both build their sort input through an explicit `if ... <> undefined` filter
  (3737, 3762). Adding a guard here would be redundant code, not defence.
- `stats/eml-lmm.praat:4192` (`emlLMMSummary`) — sorts
  `emlLMMResiduals.scaled#`, which is `emlLMM.residuals# * (1 / emlLMM.sigma)`.
  Internal model output, not caller data; it can only be `undefined` if the fit
  itself failed, which is a different bug. Flagged, deliberately deferred.
- `stats/eml-core-descriptive.praat:195/428/466` — already guarded.

**Blast radius:** each edit adds one branch to a procedure that already has an
`if .n = 0` branch. No signature changes, no call-site changes, no behavioral
change on any input that does not contain `undefined`. The existing 1232 checks
should be unaffected; if any moves, that is information.

---

## 2. AUTHOR DECISION — Kruskal-Wallis on all-tied input

**Site:** `stats/eml-inferential.praat`, tie-correction block, ~2985–3030.

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

The comment shows this is deliberate, so it is not a slip to be corrected —
it is a position to be confirmed or reversed. The case against it:

1. When every observation is identical, the rank-sum variance is zero and `H`
   is `0/0`. No test was performed. `H=0, p=1` reads to a caller as *tested, no
   difference*.
2. This is the exact pattern audit item 9 was raised to eliminate. From
   `test-inferential-batch7.praat` v1.1, 2 August 2026: *"The library used to
   emit z = 0 and p = 1, which reads as 'tested, no difference' when in fact no
   test was possible. It now propagates undefined for both, and callers must
   guard."*
3. scipy 1.17.1 returns `nan / nan` with an invalid-value divide warning.
4. **`@emlDunnTest` in this same file already propagates `undefined`** on the
   identical input (probe case 35). A one-way test and its post-hoc currently
   give opposite answers about whether the data was testable.

The case for leaving it: `H = 0` is arguably the correct limit — with zero
between-group dispersion there is no evidence of difference, and `p = 1` is not
misleading so much as trivially true. If that is the reading, the fix is
documentation, not code.

**If the decision is to propagate:** the edit is contained.

    if .tieCorrection <= 0
        .h = undefined
        .p = undefined
        .error$ = "Kruskal-Wallis: all values are tied; no test is possible"

with the downstream `if .h = 0 / .p = 1` branch guarded so it cannot re-assign
over the `undefined`. Blast radius is one procedure, but any existing test
asserting `H=0, p=1` on tied input will flip — that is the point, and those
assertions need updating in the same pass, not silencing.

**If the decision is to leave it:** it needs a comment upgrade at the site
saying explicitly that this diverges from scipy and from `@emlDunnTest`, and a
line in the procedure's header block, so the next auditor does not re-file it.

I have not made this call and will not.

---

## 3. `emlLinearRegression` — null its outputs on the error paths

**Class:** mechanical. **Site:** `stats/eml-inferential.praat:3878`.

    procedure emlLinearRegression: .x#, .y#
        .error$ = ""
        .n = size (.x#)

        if .n <> size (.y#)
            .error$ = "Vectors must be same length."
        elsif .n < 3
            .error$ = "Need at least 3 observations for regression."
        endif

`.slope` and `.intercept` are first assigned at 3914–3915, inside
`if .error$ = ""`. On any error path they are never assigned, so a caller that
reads `emlLinearRegression.slope` before testing `.error$` aborts with
`Unknown variable`. This is the run's only UNSET outcome and the single holdout
against 18 CONTRACT-compliant procedures.

**The fix template is 121 lines below, in the same file.** `@emlTheilSen`
opens:

    procedure emlTheilSen: .x#, .y#
        .slope = undefined
        .intercept = undefined
        .error$ = ""

Do the same at 3879. Outputs to null at entry: `.slope`, `.intercept`, `.r`,
`.rSquared`, `.fStat`, `.pF`, `.seSlope`, `.seIntercept`, `.tSlope`,
`.tIntercept`, `.pSlope`, `.pIntercept`, `.seResidual`, `.ssReg`, `.ssRes`,
`.msReg`, `.msRes`, `.dfReg`, `.dfRes`.

Note the second error path — `.ssXX = 0` at 3905 — is reached *after*
`.xMean`, `.yMean`, `.ssXX`, `.ssYY`, `.ssXY`, `.sumX2`, `.dx`, `.dy` are
already assigned at 3889–3903. Nulling at entry is still the right shape: those
get overwritten with real values on the way, and the coefficient outputs stay
`undefined`.

**Blast radius:** entry-block only. No existing success path changes, because
every nulled name is reassigned before use when `.error$` stays empty.

---

## 4. Misattributed underflow diagnostic

**Class:** mechanical. **Site:** the t-test zero-variance branch in
`stats/eml-inferential.praat` (`@emlTTest`, from :138).

At 1e-300 the probe gets `"Both groups have zero variance"`. The values are
distinct — `{1e-300, 2e-300, 3e-300}` vs `{4e-300, 5e-300, 6e-300}` — and the
variance underflowed to zero in the sum of squares. The message describes
duplicated data and would send someone looking for a duplication bug.

The distinguishing test is cheap: if the group's `min` and `max` differ but its
computed variance is 0, that is underflow, not constancy.

    if .var1 = 0 and min (.v1#) < max (.v1#)
        .error$ = "Group 1 variance underflowed to zero (values near the "
        ... + "limits of double precision)"

Same for group 2 and the both-groups case. Praat does not short-circuit `and`,
but both operands here are safe to evaluate unconditionally.

Worth noting for the record: at both magnitude extremes **this library is safer
than scipy.** At 1e300 scipy returns `t=-0.0, p=1.0` with an overflow warning;
at 1e-300 it returns `t=-inf, p=0.0`. The library returns `undefined` in both
cases. Only the wording is wrong.

---

## 5. AUTHOR DECISION — ANOVA and Tukey disagree about singleton groups

Groups of n=3, n=3, n=1:

- `@emlOneWayAnova` **rejects** — "group has fewer than 2 observations" (probe
  cases 28–30).
- `@emlTukeyHSD` **answers** — `nPairs=3, p12=0.0455, q12=5.196`.
- scipy's `tukey_hsd` **raises** `Input sample size must be greater than one`.

The Tukey number is not arithmetically wrong: MS-within is estimable from the
two larger groups, so a comparison involving the singleton has a defined
standard error. The problem is that a procedure and its own post-hoc disagree
about whether the design is analysable, and a caller that runs Tukey directly
gets an answer the caller's own ANOVA would have refused.

Three coherent dispositions, all defensible:

1. **Tukey adopts the ANOVA rule** — reject singleton groups, match scipy.
   Most conservative; loses a computation that is arguably valid.
2. **ANOVA relaxes to match Tukey** — allow singletons as long as residual df
   ≥ 1. Most permissive; diverges from scipy in the other direction.
3. **Keep both, document the asymmetry** — Tukey is the more permissive
   estimator by design. Requires a note in both procedure headers.

I have no basis for choosing among these that is not a statistics-methodology
opinion, so I am not choosing.

---

## 6. Silent `undefined` with an empty `.error$`

**Class:** mechanical, low priority.

`@emlOneWayAnova` on three identical constant groups returns
`F=undefined, p=undefined` with `.error$` empty. The value is *correct* — scipy
agrees at `nan/nan` — and a caller guarding on `undefined` behaves fine. But a
caller that reports `.error$` to the user has nothing to say about why the
analysis produced nothing. Same shape in the 1e300 overflow case.

The fix is to set a diagnostic string alongside the `undefined`, not to change
any number:

    .error$ = "One-way ANOVA: all values identical; F is undefined (0/0)"

Deferred behind items 1–4 because nothing breaks and no wrong number is
produced. It is a diagnosability improvement, not a correctness fix.

---

## 7. Regression suite

New file: `dev/tests/phase2/test-degenerate-inputs.praat`, built on the
existing helper API in `dev/tests/eml-test-helpers.praat` —
`emlTestInit` (:129), `emlTestSection:` (:154), `emlTestAssertTrue:` (:175),
`emlTestAssertEqualNum:` (:208), `emlTestAssertEqualRel:` (:303),
`emlTestAssertUndefined:` (:420), `emlTestSummary` (:602). It must emit the
v1.1 sentinel — `EMLTEST-RESULT: status=PASS passed=N failed=N skipped=N
total=N` — since absence of the sentinel counts as FAIL, not PASS.

Sections, in the order the fixes land:

**A. Undefined-element guards (locks item 1).** For each of the 8 edited sites:
pass `{1, 2, undefined, 4}`, assert the procedure returns rather than aborting,
and assert the documented output is `undefined` (or `.error$` non-empty for
`emlShapiroWilk` / `emlTheilSen`). These are the assertions that would have
caught the crash. Also assert `@emlBootstrapCI` still works on a vector
containing `undefined`, since it filters — a negative control proving the
filter, not the guard, is what protects it.

**B. Contract compliance (locks item 3).** For `emlLinearRegression` on both
error paths — mismatched lengths, and n=2 — read `.slope` *before* testing
`.error$` and assert `undefined`. This is the assertion that fails today with
`Unknown variable`, which is exactly why it belongs in the suite.

**C. Exonerations (locks the current, correct behavior).** These are the cases
that matched scipy and must not silently drift:
Mann-Whitney all-tied `u1=8 p=1`; MWU n=1 vs n=1 `u1=0 p=1`; Wilcoxon
one-nonzero-difference `tPlus=0`, p≈1 via `emlTestAssertEqualRel`; ANOVA
all-constant `undefined`; Tukey all-constant `undefined`; catastrophic
cancellation `t≈-3.6742346` at relative tolerance loose enough for the
documented ~9-sig-fig limit; 1e300 and 1e-300 both `undefined`.

**D. Whichever author decisions land (items 2 and 5).** Written after the
decision, asserting the decided behavior — not before.

**Do not** write section D speculatively, and do not write any assertion whose
expected value is computed at runtime from the same code path it is testing —
that is the CLASS F vacuity pattern, and there are already 21 such sites
carried as a known asterisk.

**Coverage note.** The keyword census over the 15 existing suites shows the
three families the question named — ties (14 files), identical (6), n=1 (7) —
are the *best*-covered part of the suite. Zero files mention singleton, single
value, insufficient, overflow, underflow, cancellation, imbalance, or the
magnitude literals. Three of the six findings came from exactly those
zero-coverage families. Section C above is what closes that gap; it matters
more than section A, which merely locks a fix.

---

## Sequencing and the post-edit protocol

1. Item 1 (8 sites) and item 3 (1 site) together — both mechanical, both in
   `stats/`, both zero-risk to the success paths.
2. Item 4, then item 6 — wording and diagnostics only.
3. Section A + B of the new suite, which now pass.
4. Section C of the new suite, independent of any edit; can be written first if
   preferred, since it asserts today's behavior.
5. Items 2 and 5 when the decisions come back, plus section D.

**After any library edit, all five, in order:**

    python3 dev/tools/run-tests.py
    python3 dev/tools/scan-assertion-vacuity.py
    python3 dev/tools/build-manifest.py --check
    python3 dev/tools/reg-reconcile.py /home/claude/reg/EML_PROCEDURE_REGISTRY.md
    python3 /home/claude/safety/build.py

The new test file arrives in `MANIFEST.txt` as `TODO:` and needs its
description hand-edited — the description column is curated and inherited by
path, so `--check` will pass with a placeholder in place and nothing will
complain.

The tree is not under version control (`git status` → `fatal: not a git
repository`), so any file that has to go away is moved to `dev/retired/`, never
deleted. None of the work above removes a file.

---

## What is deliberately absent

- **Vibrato / Defect B** — deferred by the author, "for now."
- **Cross-procedure dependency concerns** — ruled intentional architecture.
  The `@emlSetAdaptiveTheme` partial-guard framing is retracted and stays
  retracted.
- **Any PraatGen-side change** — out of scope; this session serves the plugin.
- **The 9 self-referential eta-squared checks and 21 CLASS F assertion sites** —
  known, carried, unchanged by anything here.
