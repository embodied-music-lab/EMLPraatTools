# External-reference validation run — 4 August 2026

Rule 32 cross-validation of the numeric literals baked into the Praat test
suite, run against independent implementations (R 4.3.3, scipy 1.17.1,
scikit-posthocs). Outputs saved to `/home/claude/rval/`.

This is the **first R/scipy run recorded on disk in this session.** The
`.R` artifacts were authored earlier in the program (2 and 3 August) and
had not been re-executed here until now.

---

## R artifacts — `dev/tests/phase2/verify-*.R`

| script | exit | passed | failed | skipped | covers |
|---|---|---|---|---|---|
| `verify-inferential-batch1.R` | 2 | 40 | 0 | 17 | t-tests, Cohen's d, Hedges' g |
| `verify-inferential-batch3.R` | 0 | 41 | 0 | 0 | `@emlMannWhitneyU`, `@emlWilcoxonSignedRank` |
| `verify-inferential-batch4.R` | 0 | 29 | 0 | 0 | `@emlRankBiserialR`, `@emlMatchedPairsR` |
| `verify-inferential-batch5.R` | 0 | 104 | 0 | 0 | Bonferroni / Holm / BH via `p.adjust()` |
| `verify-inferential-batch6.R` | 2 | 122 | 0 | 14 | one-way & two-way ANOVA, Tukey HSD, TableFromGroups |
| `verify-inferential-batch6b.R` | 2 | 44 | 0 | 2 | pairwise t, pairwise MWU, Scheffé |
| `verify-inferential-batch7.R` | 2 | 13 | 0 | 1 | Kruskal-Wallis (Dunn's explicitly NOT claimed) |
| `verify-shapiro-wilk.R` | 0 | 16 | 0 | 0 | `@emlShapiroWilk` |
| **total** | | **409** | **0** | **34** | |

**Exit 2 means INCOMPLETE, not FAILED.** These scripts refuse to report
green when coverage is partial; each incomplete run ends with "This run
does NOT constitute verification of the skipped checks." Zero failures
across all eight.

### Correction to an earlier in-session tally

An interim count of "276 passed" was wrong. It silently dropped
`batch4` (29) and `batch5` (104) because those two use
`TOTAL: n PASS, n FAIL, n SKIP` rather than the
`R Verification: n passed, n failed, n skipped` format the grep matched.
The correct figure is **409 passed**. The failure count was 0 either way,
but a summariser that pattern-matches one format and reports the union as
complete is the same defect class the vacuity work exists to catch.

### The 34 skips, by stated reason

- **batch1 (17)** — library-API contracts with no R counterpart: method
  label strings, error-string contracts, input-validation contracts,
  undefined-value semantics.
- **batch6 (14)** — assertions comparing two library outputs to each other
  (no numeric literal for R to verify); Praat Table construction
  round-trips (no statistical quantity); and **9 eta-squared /
  partial-eta-squared checks** that cannot be externally corroborated
  because the `effectsize` package is not installed and CRAN is
  unreachable. Those 9 remain longhand re-implementations, not external
  validation. This is the one substantive coverage gap.
- **batch6b (2)** — ties push `wilcox.test` off its exact path onto the
  normal approximation with continuity correction (R: 0.015971) while the
  library's no-tie exact null DP gives 0.007937. R cannot supply an
  independent exact reference here; the case is asserted against scipy
  inside `test-inferential-batch6b.praat`.
- **batch7 (1)** — the `dunn.test` R package is absent. The script names
  its own replacement and warns that "a runner reporting only this file's
  exit code has not checked Dunn's test." See below.

---

## Python sibling artifacts — `dev/tests/phase2/*.py`

| script | exit | result |
|---|---|---|
| `verify-inferential-batch7-dunn.py` | 0 | **33 passed, 0 failed, 0 skipped (of 33 expected)** — scikit-posthocs |
| `batch2_scipy_refs.py` | 0 | reference-value generator |
| `batch3_scipy_refs.py` | 0 | reference-value generator |
| `batch6b_scipy_refs.py` | 0 | reference-value generator (tied/zero cases) |
| `batch7_scipy_refs.py` | 0 | reference-value generator |
| `regression_scipy_refs.py` | 0 | reference-value generator |
| `theilsen_scipy_refs.py` | 0 | reference-value generator |

**Dunn's test is now externally verified** — the gap `verify-inferential-batch7.R`
explicitly declined to claim is closed by its named sibling, at the
precision shown (agreement to ~9 significant figures on |z| and on both
Bonferroni- and Holm-adjusted p).

Combined external checks passing: **409 (R) + 33 (scikit-posthocs) = 442,
zero failures.**

---

## Plugin state, same day, re-run from disk

    python3 dev/tools/run-tests.py                    -> exit 0
      Summary: PASS=20, XFAIL=1
      Checks:  1232 declared, 0 failed, 0 skipped
      Controls: 1 negative-control suite, 4 checks, 4 failed by design

    python3 dev/tools/scan-assertion-vacuity.py       -> exit 0
      VERDICT: CLEAN (vacuous=0 unparsed=0 misuse=0 unresolved-tol=0)

    python3 dev/tools/build-manifest.py --check       -> exit 0
      MANIFEST.txt is current.

    python3 dev/tools/reg-reconcile.py <registry>     -> exit 0
      OK — 15 undocumented files, 163 procedures
      total documented rows: 283 ; sections with defects: 0

Note: the registry lives at `/home/claude/reg/EML_PROCEDURE_REGISTRY.md`,
outside the plugin tree — `reg-reconcile.py` takes it as an argument and
there is no copy under `plugin_EML_Praat_Tools/`. Running the reconcile
from inside the plugin directory without a path fails with
`FileNotFoundError`, which is a usability wart, not a defect.

---

## Open items after this run

1. **9 eta-squared / partial-eta-squared checks** in batch6 have no
   external reference (R `effectsize` absent, CRAN unreachable). scipy has
   no direct equivalent either. Closing this needs either network access
   to CRAN or a hand-derived reference from the ANOVA sums of squares,
   computed independently of the library implementation.
2. **21 CLASS F assertion sites** (symmetry / passthrough, both sides
   computed at run time) remain statically unevaluable for vacuity. They
   are reported with tolerances for hand review, not failed.
3. **Vibrato / Defect B** — deferred by the author "for now."
