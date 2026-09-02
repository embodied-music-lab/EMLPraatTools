# Per-registry-row kit coverage map

Answers `TRACKER_KIT_AND_1p0.md` section C's order: "a per-registry-row
kit-coverage map (row -> covered by which kit cells / not numerically
covered and why that is correct for its kind), so the claim is a table,
not a sentence."

## Where the table lives

- `walkthrough/kit/coverage_map.tsv` -- one row per
  `plugin_EML_StatsGraphs/REGISTRY.tsv` row (43 rows), columns
  `registry_name`, `kind`, `numerically_covered`, `covering_kit_cells`,
  `reason_if_not_covered`.
- `walkthrough/kit/build_coverage_map.py` -- the script that generates
  it from `REGISTRY.tsv` + `matrix.tsv` (+ a `validate/*.R` grep for the
  reason text). Regenerate with:
  ```
  python3 walkthrough/kit/build_coverage_map.py > walkthrough/kit/coverage_map.tsv
  ```
  The committed file is exactly that script's output -- verified by
  running it again and diffing:
  ```
  $ python3 walkthrough/kit/build_coverage_map.py > /tmp/reverify.tsv
  $ diff /tmp/reverify.tsv walkthrough/kit/coverage_map.tsv; echo "exit=$?"
  exit=0
  $ md5sum /tmp/reverify.tsv walkthrough/kit/coverage_map.tsv
  b0d396556cfeeb40f57e0781c198a021  /tmp/reverify.tsv
  b0d396556cfeeb40f57e0781c198a021  walkthrough/kit/coverage_map.tsv
  ```
  Row identity against `REGISTRY.tsv` was checked directly, not assumed:
  ```
  $ awk -F'\t' '!/^#/ && NF>1 && $1!="name" {print $1}' plugin_EML_StatsGraphs/REGISTRY.tsv > /tmp/reg_names.txt
  $ tail -n +5 walkthrough/kit/coverage_map.tsv | awk -F'\t' '{print $1}' > /tmp/cov_names.txt
  $ diff /tmp/reg_names.txt /tmp/cov_names.txt; echo "exit=$?"
  exit=0
  $ wc -l /tmp/reg_names.txt
  43 /tmp/reg_names.txt
  ```
  Same 43 names, same order, each once.

## What "numerically covered" means, defined once and applied mechanically

`walkthrough/kit/README.md`'s own scope line: "The EML procedures library
contains 17 procedures." Those 17 are the distinct values of
`matrix.tsv`'s `procedure` column -- every cell of which is run through
both `RUN_ME_FIRST.praat` and `run_analyses.R` and diffed by `compare.R`
against an R oracle. A registry row is `numerically_covered=yes` here iff
its name is one of those 17. That test is mechanical (string match against
`matrix.tsv`, not a hand-kept list), and the script re-derives it every
run.

```
$ grep -v '^#' walkthrough/kit/matrix.tsv | grep -v '^\s*$' | tail -n +2 | cut -f3 | sort -u | wc -l
17
```

Of those 17, 13 have a REGISTRY.tsv row; the other 4
(`emlWilsonInterval`, `emlCronbachAlpha`, `emlChiSquareIndependence`,
`emlAlphaInfluence`) are the survey-lane kernels that `REGISTRY.tsv`'s own
header deliberately keeps internal ("Kernels stay INTERNAL even where a
sophisticated user could legitimately call them... A kernel enters this
file only by a deliberate future decision, never by default"). They are
correctly outside this per-registry-row map's scope -- not a gap, by the
registry's own written policy.

## Headline numbers

```
$ python3 walkthrough/kit/build_coverage_map.py > /dev/null
build_coverage_map.py: 43 registry rows, 13 numerically_covered=yes, 30 numerically_covered=no
```

```
$ tail -n +5 walkthrough/kit/coverage_map.tsv | awk -F'\t' '{c[$2"/"$3]++} END{for (k in c) print k, c[k]}' | sort
analysis/no 2
analysis/yes 13
drawing/no 17
utility/no 11
```

- **43** registry rows total.
- **13 numerically covered** -- all `kind=analysis`, matching 13 of the
  17 kit procedures (the other 4 kit procedures are the internal kernels
  above, outside the registry). Cell counts per procedure, straight from
  `matrix.tsv` (e.g. `emlRunPairwiseAnalysis` 200 cells, `emlRunKWAnalysis`
  96, `emlRunAnovaAnalysis` 67, down to `emlRunTwoWayAnalysis` 5) --
  `covering_kit_cells` in the TSV carries the full cell-id list per row.
- **28 correctly not covered by kind** -- 17 `drawing` rows + 11
  `utility` rows. The kit compares scalar statistical output; a drawing
  procedure renders a figure (pixels, not a number an R function also
  produces) and a utility procedure does internal plumbing (reshaping,
  panel/global-state management, recorder replay) with no statistical
  result of its own. Each of these 28 rows' `reason_if_not_covered` names
  the specific `validate/*.R` files that check it structurally instead
  (geometry, dispatch, axis, disclosure, settings-census, etc.), grepped
  at build time. Two utility rows, `emlRecordReplayName` and
  `emlRecordReplayRead`, have **zero** `validate/*.R` hits by that grep --
  the TSV says so plainly ("No validate/*.R file references it by name").
  They are not silently untested, though: `mailbox/to-fable/`
  `REPORT_RECORDER_COVERAGE_2026-09-01.md` rows 40 and 42 code-trace both
  (recorder emits the call only after a read-then-rename / a recorded
  file-read; this repo's fixtures never exercise those paths) via
  `harness/record` and `harness/roundtrip`, not via `validate/*.R` -- a
  different kind of coverage (does the recorder emit the right call text)
  from the numeric-oracle coverage this map is about. Naming it here so
  the gap in the grep doesn't read as a gap in testing altogether.
- **2 GENUINE GAPS** -- `kind=analysis` rows with zero `matrix.tsv`
  cells, where "kind" does NOT excuse the absence the way it does for
  drawing/utility rows, because both compute real statistics with a
  ready R oracle available:

  1. **`emlRunLMMAnalysis`** -- fits a mixed-effects model and reports
     coefficients/CIs; `lme4`/`lmerTest` are installed in this
     environment (`Rscript -e 'requireNamespace("lme4")'` -> `TRUE`, and
     `dpkg -l | grep r-cran-lme4` shows `r-cran-lme4 1.1-35.1-4`
     installed), so nothing infrastructural blocks an oracle. Per Ian's
     ruling (`mailbox/to-opus/RULING_REGISTRY_VERDICTS_2026-09-01.md`
     #1), this row is ORDERED OUT of the registry for 1.0 (post-1.0;
     menu and wizard doors withdrawn) through the same exclusion-list
     mechanism used for `emlRunReliabilityAnalysis` -- but that removal
     has not executed. `REGISTRY.tsv` still carries the row today (43
     rows, 2026-09-01 compile per its own header) and
     `validate/v155_public_registry.R`'s `RUN_EXCLUSIONS` list does not
     yet name it -- that list carries exactly one entry today,
     `emlRunReliabilityAnalysis`, verified directly:
     ```
     $ python3 -c "
     import re
     text = open('validate/v155_public_registry.R').read()
     m = re.search(r'RUN_EXCLUSIONS <- c\((.*?)\n\)', text, re.S)
     print(re.findall(r'emlRun\w+', m.group(1)))
     "
     ['emlRunReliabilityAnalysis']
     ```
     (`emlRenderResultSettings` is a name on a *different* list in the
     same file -- the false-positive exemption list for the erosion
     regex scan, not `RUN_EXCLUSIONS`; noting the distinction so it
     isn't misread as a second `RUN_EXCLUSIONS` entry.) Until LMM's
     removal lands, this is a real, open gap in today's tree, not a
     by-design exclusion -- flagging it as such rather than quietly
     treating the ruling's intent as already done.
  2. **`emlBridgeGroupComparison`** -- runs the actual
     t-test/Mann-Whitney/ANOVA/Kruskal-Wallis (with Tukey/Dunn) behind a
     figure's annotation brackets; its own `REGISTRY.tsv` description
     calls it "the second path to the same statistics as the stats
     menu." It has zero `matrix.tsv` cells today because it currently
     carries its OWN duplicate implementation of those four tests rather
     than calling the Family A dispatch the kit's cells already
     exercise. Per Ian's ruling (same file, #4): "We absolutely need to
     fix that" -- unification onto Family A is ordered before the
     authoritative run, after which "the kit's canonical-route coverage
     picks up the unified path." Not yet done, so today this row is
     genuinely uncovered by the kit, though it does have its own
     extensive non-numeric validator coverage (16 `validate/*.R` files
     touch it -- consistency/reprint/settings/wiring checks, not a
     numeric oracle diff) and IS recorded live
     (`REPORT_RECORDER_COVERAGE_2026-09-01.md` row 30).

  Both gaps are already ordered fixes with named rulings, not unnoticed
  misses -- but as of this measurement they are open, and the coverage
  map says so rather than rounding them into "correct by kind."

13 + 28 + 2 = 43.

## What I could not measure

- Whether `emlBridgeGroupComparison`'s 16 referencing `validate/*.R`
  files, taken together, ever perform a genuine numeric comparison
  against an R-computed value (as opposed to internal
  consistency/wiring checks) was not exhaustively verified line-by-line
  for every file -- I read `v142_bridge_consumption.R`'s header and
  spot-checked grep contexts for all 16, which showed reprint/wiring/
  settings-census framing throughout, not oracle diffs, but I did not
  read every one of the 16 files in full. The `numerically_covered=no`
  call rests on the harder, mechanically-checked fact that the
  procedure has zero `matrix.tsv` cells, which is sufficient on its own
  for this map's definition of coverage.
