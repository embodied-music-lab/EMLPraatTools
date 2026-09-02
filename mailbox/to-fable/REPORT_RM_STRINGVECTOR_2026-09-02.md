# Report: RM string-vector signature status

Tracker item A.5 status measure: `string-vector RM as canonical with pipe-delimited wrapper [WORK_ORDER_API_SETTLEMENT]`.

## 1. What signature does the code have today, exactly?

The procedure `emlRunRepeatedMeasuresAnalysis` in `/home/claude/repo/plugin_EML_StatsGraphs/stats/eml-analysis.praat` (line 4572):

```praat
procedure emlRunRepeatedMeasuresAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$
```

The `.conditionCols$` parameter is a single string, currently parsed as pipe-delimited. The parsing logic in `@emlExtractConditionMatrix` (line 4143–4162) splits on the pipe character:

```praat
procedure emlExtractConditionMatrix: .tableId, .conditionCols$
    .error$ = ""
    .parseNote$ = ""
    .nExcluded = 0
    .k = 0
    .rest$ = .conditionCols$ + "|"
    .barPos = index (.rest$, "|")
    while .barPos > 0
        .tok$ = left$ (.rest$, .barPos - 1)
        .tok$ = replace_regex$ (.tok$, "^ +", "", 0)
        .tok$ = replace_regex$ (.tok$, " +$", "", 0)
        if .tok$ <> ""
            .k = .k + 1
            .colLabel$ [.k] = .tok$
        endif
        .rest$ = mid$ (.rest$, .barPos + 1, length (.rest$) - .barPos)
        .barPos = index (.rest$, "|")
    endwhile
```

The wizard builds the condition list as a pipe-delimited string before passing it to the procedure:

```praat
# Build the "|"-delimited condition list and count non-empty slots.
condList$ = ""
nCond = 0
if condition_1$ <> "(none)"
    condList$ = condList$ + condition_1$ + "|"
    nCond = nCond + 1
endif
...
@emlRunRepeatedMeasuresAnalysis: tableId, "", condList$, ...
```

This is in `/home/claude/repo/plugin_EML_StatsGraphs/scripts/eml-wizard.praat` (lines 1423–1465).

## 2. Does a pipe-delimited wrapper exist? Where?

No. There is no separate pipe-delimited wrapper procedure. The current implementation takes pipe-delimited input only. The pipe-delimited form is the PRIMARY and ONLY implementation, not a wrapper.

## 3. What does REGISTRY.tsv record as its signature, and does that match the code?

REGISTRY.tsv entry (line 1 of repeated-measures section):

```
emlRunRepeatedMeasuresAnalysis	stats/eml-analysis.praat	procedure emlRunRepeatedMeasuresAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$	Parametric repeated-measures ANOVA (wide format) with Greenhouse-Geisser correction and an optional post-hoc. .subjectCol$ is reserved and currently unread.	1,3
```

The signature matches the code exactly. The same pipe-delimited `.conditionCols$` parameter appears in both.

The Friedman test uses the same signature:

```
emlRunFriedmanAnalysis	stats/eml-analysis.praat	procedure emlRunFriedmanAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$	Friedman test — nonparametric repeated measures, wide format — with an optional post-hoc.	1,3
```

## 4. Which validators exercise it, and do they pass right now? Run them and show the real output.

Two validators exercise the repeated-measures procedures:

### v03: RM-ANOVA with Greenhouse-Geisser

File: `/home/claude/repo/validate/v03_rm_anova_greenhouse_geisser.R`

Command run: `cd /home/claude/repo && Rscript validate/v03_rm_anova_greenhouse_geisser.R`

Output:
```
==============================================================================
v03 RM-ANOVA + Greenhouse-Geisser
==============================================================================
------------------------------------------------------------------------------ 
30 checks, 30 passed, 0 FAILED
```

**Status: PASS**

### v04: Friedman test

File: `/home/claude/repo/validate/v04_friedman.R`

Command run: `cd /home/claude/repo && Rscript validate/v04_friedman.R`

Output:
```
==============================================================================
v04 Friedman
==============================================================================
------------------------------------------------------------------------------ 
30 checks, 30 passed, 0 FAILED
```

**Status: PASS**

Both validators pass with the current pipe-delimited implementation.

## 5. What is the gap between today's state and the work order's target?

### Current state
- Repeated-measures procedures (`emlRunRepeatedMeasuresAnalysis` and `emlRunFriedmanAnalysis`) take a single string parameter (`.conditionCols$`)
- That string is internally parsed as pipe-delimited
- No string-vector (array `##`) overload exists
- No wrapper exists to abstract the pipe-delimited form
- Validators pass (30/30 for both RM-ANOVA and Friedman)

### Target state (per WORK_ORDER_API_SETTLEMENT_2026-08-31.md, item 1)

> String-vector repeated-measures signature ships in 1.0 as the canonical form; the pipe-delimited form becomes a compatibility wrapper.

The work order explicitly reverses the earlier RULING_RM_SIGNATURE_FREEZE (which had frozen the pipe-delimited form as the only form). The new directive is:

- **Canonical form**: String-vector signature (`.conditionCols##$` or equivalent array parameter)
- **Wrapper form**: Pipe-delimited string (`.conditionCols$`), as a compatibility layer

### The gap

**UNMEASURED implementation gap**: The string-vector procedure does not exist. The pipe-delimited wrapper does not exist. The current state is the OPPOSITE of the target:

- Current: pipe-delimited string is THE ONLY form (primary implementation)
- Target: string-vector is canonical, pipe-delimited is a wrapper

**Validators**: Both pass with the current pipe-delimited implementation. No validator exercises a string-vector form because it does not exist.

**Reconciliation with the work order's sequence**: The work order states this change happens "before the authoritative run" (after NIST wiring and the two-way kernel, before kit re-pointing). It remains unbuilt as of this measurement.
