# External reference provenance

Every numeric literal asserted in `dev/tests/` was transcribed from an
**external** reference implementation — R or scipy — never from the EML
library's own output. That rule is what makes the suites a test of the
library rather than a photograph of it.

The reference generators live beside the suites they feed. Until now none
of them recorded the version of the tool that produced its numbers (Test
Inventory, 2 August 2026, finding 7), which makes a reference value
unfalsifiable: if scipy changes a tie-correction or R changes a default,
a literal that no longer reproduces is indistinguishable from a literal
that was mistyped. This file closes that gap.

## Environment of record

Versions below were captured on **3 August 2026** in the audit sandbox
(Ubuntu 24.04 x86_64) by running the interpreters directly.

| Tool | Version |
|---|---|
| Python | 3.11.15 |
| scipy | 1.17.1 |
| numpy | 2.4.4 |
| pandas | 3.0.2 |
| scikit-posthocs | 0.14.0 |
| statsmodels | 0.14.6 |
| pingouin | 0.6.1 |
| R | 4.3.3 |

The `.R` generators call no `library()` or `require()` — they use base R
`stats` only (bundled, version tracks R itself, 4.3.3). No third-party R
package is a dependency, so R reference values are reproducible from a
bare R install.

**The versions in force when each literal was *originally* generated are
not recoverable.** They were never recorded, and the tree is not under
version control. The table above is therefore a forward commitment, not a
retroactive attestation: it states the environment under which the
literals are known to be reproducible as of this date, and any future
divergence is attributable to a version change that can now be named.

## Generators and the suites they feed

| Generator | Suite | Tool |
|---|---|---|
| `phase2/regression_scipy_refs.py` | `test-regression.praat` | scipy |
| `phase2/theilsen_scipy_refs.py` | `test-theilsen.praat` | scipy |
| `phase2/batch2_scipy_refs.py` | `test-inferential-batch2.praat` (plus the batch7 Dunn-1 \|z\| literals) | scipy |
| `phase2/batch3_scipy_refs.py` | `test-inferential-batch3.praat` | scipy |
| `phase2/batch6b_scipy_refs.py` | `test-inferential-batch6b.praat` | scipy |
| `phase2/batch7_scipy_refs.py` | `test-inferential-batch7.praat` | scipy |
| `phase2/verify-inferential-batch7-dunn.py` | `test-inferential-batch7.praat` (Dunn's post-hoc) | scikit-posthocs |
| `phase2/verify-inferential-batch1.R` | `test-inferential-batch1.praat` | R (base `stats`) |
| `phase2/verify-inferential-batch3.R` | `test-inferential-batch3.praat` | R (base `stats`) |
| `phase2/verify-inferential-batch4.R` | `test-inferential-batch4.praat` | R (base `stats`) |
| `phase2/verify-inferential-batch5.R` | `test-inferential-batch5.praat` | R (base `stats`) |
| `phase2/verify-inferential-batch6.R` | `test-inferential-batch6.praat` | R (base `stats`) |
| `phase2/verify-inferential-batch6b.R` | `test-inferential-batch6b.praat` | R (base `stats`) |
| `phase2/verify-inferential-batch7.R` | `test-inferential-batch7.praat` | R (base `stats`) |
| `phase2/verify-shapiro-wilk.R` | `test-shapiro-wilk.praat` | R (base `stats`) |
| `phase2/repeatedmeasures_refs.py` | `test-repeated-measures.praat` | scipy, statsmodels, pingouin |
| `phase2/verify-repeated-measures.R` | `test-repeated-measures.praat` | R (base `stats`) |

Four suites carry cross-checked literals — `test-inferential-batch3`,
`batch6b`, `batch7` and `test-repeated-measures` each have both an R and a
Python generator. Where the two disagree on a tie or continuity
correction, the suite's comments record which convention the library
follows and why.

`test-repeated-measures` splits its oracles across the two generators for
a reason worth stating. Base R's `stats` has no Greenhouse–Geisser
routine, neither `ez` nor `afex` is installed, and CRAN is unreachable
from the sandbox — so the genuine external GG oracle is pingouin, and it
lives in the Python generator. The `.R` file re-derives epsilon longhand
from `cov()` and labels those checks `[LH]`, not `[EXT]`: a longhand
re-derivation catches transcription and arithmetic slips but not a shared
misunderstanding of the estimator. The Friedman and RM-ANOVA literals are
`[EXT]` in both files (`stats::friedman.test`; `aov` with an
`Error(subject/condition)` stratum). Six quantities are asserted in
neither file — the RM_D all-identical and RM_F zero-residual degeneracies,
where the library and the external oracles disagree and no reference value
exists. Both suites therefore report INCOMPLETE by design; see the skip
reasons printed by each run.

## Re-verification procedure

1. Record the current versions of the tools in the table above.
2. Re-run the generator for the suite in question and compare its printed
   values against the literals in the `.praat` file.
3. If they differ, the disagreement is between **two external references**
   (old tool version vs new), not between the library and reality. Decide
   which convention the library should follow, update the literal *and*
   the comment recording the convention, and note the version change here.
4. Re-run `python3 dev/tools/run-tests.py`.

Do **not** resolve a disagreement by reading the EML library's output and
adopting it. That converts the suite from a test into a regression lock.

## Scope note

Recording versions does not by itself make an assertion meaningful — an
assertion whose tolerance exceeds its own expected value is a false green
regardless of where the number came from. That is a separate property,
audited by `dev/tools/scan-assertion-vacuity.py` and governed by the
ASSERTION VACUITY rule (v1.2) in `dev/tests/eml-test-helpers.praat`.
