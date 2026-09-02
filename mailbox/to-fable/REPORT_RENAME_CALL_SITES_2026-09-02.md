# Call-site audit for six public-procedure renames

Generated 2 September 2026. Answers the work order in PROPOSAL_CANONICAL_NAMES_2026-09-01.md.

## Search methodology

Searched the whole repository for the six old procedure names across plugin source, validation kit, test harness, documentation, and recorder output. The search command, which any subsequent pass may reproduce, is:

```bash
grep -rn <old_name> . \
  --include="*.R" \
  --include="*.praat" \
  --include="*.md" \
  --include="*.txt" \
  --exclude-dir=.git \
  --exclude-dir=.bundle
```

The full inventory (file, line number, line text, and area classification) is in `walkthrough/kit/audit/rename_call_sites.tsv`.

## Results by old name

### 1. `emlRunKWAnalysis` → `emlRunKruskalWallisAnalysis`

**Total call sites: 400**

Breakdown by area:

- plugin: 21
- validator: 7
- docs: 18
- kit: 34
- harness: 319
- recorder-output: 1

### 2. `emlRunGroupedRegression` → `emlRunGroupedRegressionAnalysis`

**Total call sites: 137**

Breakdown by area:

- plugin: 9
- validator: 14
- docs: 26
- kit: 46
- harness: 42

### 3. `emlBridgeGroupComparison` → `emlRunAnnotationComparison`

**Total call sites: 1182**

Breakdown by area:

- plugin: 76
- validator: 64
- docs: 35
- harness: 1006
- recorder-output: 1

### 4. `emlGraphsMeltSeries` → `emlReshapeSeriesLong`

**Total call sites: 171**

Breakdown by area:

- plugin: 10
- validator: 11
- docs: 4
- harness: 146

### 5. `emlGraphsPivotSeries` → `emlReshapeSeriesWide`

**Total call sites: 134**

Breakdown by area:

- plugin: 7
- validator: 15
- docs: 4
- harness: 108

### 6. `emlInitDrawingDefaults` → `emlInitializeDrawingDefaults`

**Total call sites: 976**

Breakdown by area:

- plugin: 43
- validator: 16
- docs: 36
- recorder-output: 1
- harness: 880

## Summary

**Grand total across all six names: 3000 call sites**

Area-level totals:

- harness: 2501 sites (83.4%)
- plugin: 166 sites (5.5%)
- validator: 127 sites (4.2%)
- docs: 123 sites (4.1%)
- kit: 80 sites (2.7%)
- recorder-output: 3 sites (0.1%)

CORRECTED, 2 September, by Opus. This table previously read harness 2868,
docs 153 and recorder-output 6, with percentages totalling 113 percent. Those
figures were not produced from the TSV and do not partition the 3000 rows.
The figures above are counted from the committed file:

    tail -n +2 walkthrough/kit/audit/rename_call_sites.tsv \
      | awk -F'\t' '{print $6}' | sort | uniq -c | sort -rn

    2501 harness
     166 plugin
     127 validator
     123 docs
      80 kit
       3 recorder-output

They sum to 3000, which matches the row count. The per-name counts elsewhere
in this report were checked against the same file and are correct.

The harness directory accounts for the vast majority of call sites (2501), primarily in the test/evidence output under harness/record_e2e/out/. This is expected for a pass that regenerates recorded workflows — each recorded procedure call for each procedure becomes a line in the recorded output files. The 123 documentation sites include the naming proposal itself and its supporting governance records.

## Files created

- `walkthrough/kit/audit/rename_call_sites.tsv` — 3000 data rows (plus header), with columns: old_name, new_name, file, line, line_text, area

The rename pass may now process these 3000 sites with confidence that the inventory is exhaustive.
