# Door probe — stats/eml-anova-kernel.praat

Probe for the ruling `mailbox/to-fable/MEMO_THREE_DOORS_NOT_ONE_2026-09-02.md`
raised: `validate/v162_door_chain_population.R` finds `stats/eml-anova-
kernel.praat` in `setup.praat`'s module table but unreached by the
hand-maintained door include chain rooted at `scripts/eml-lib.praat`. This
probe drives the door, live, on Praat 6.6.30, and records what a user would
have hit.

## Classification: CRASHES

A registered menu door exists (`Compare two-way (ANOVA)...`), it calls the
orchestrator that reaches `@emlAnovaKernelTwoWay`, and that call fails at
run time with `Procedure "emlAnovaKernelTwoWay" not found.` — the include
chain never brings `stats/eml-anova-kernel.praat` into scope. Reproduced
independently below, matching the error text already on record in
`REPORT_RECORDER_COVERAGE_2026-09-01.md` section 4 and in v162's own header
comment.

## Step 1 — does a menu item exist, and what does it call

`plugin_EML_StatsGraphs/setup.praat:73`:

    Add menu command: "Objects", "New", "Compare two-way (ANOVA)...",
    "Compare k groups (Kruskal-Wallis)...", 1, "scripts/eml-compare-twoway.praat"

`scripts/eml-compare-twoway.praat:105` (the door's only non-error exit from
its form) calls:

    @emlRunTwoWayAnalysis: tableId, dataCol$, factor1$, factor2$

`emlRunTwoWayAnalysis` (`stats/eml-analysis.praat:2726`) calls
`@emlTwoWayAnova` (`stats/eml-inferential.praat:5162`), whose comment block
(line 5066) states plainly: "this procedure now calls (@emlAnovaKernelTwoWay,
via @eml_ak2_gather) ... the plugin's own kernel." The actual call site is
`stats/eml-inferential.praat:5259`:

    @emlAnovaKernelTwoWay: .tableId, .dataCol$, .factor1$, .factor2$, 3

So: a registered menu command exists, and its one success path dispatches
to `emlAnovaKernelTwoWay`, defined in `stats/eml-anova-kernel.praat`.

## Step 2 — does the include chain reach the module

Followed transitively from `scripts/eml-lib.praat` (the include the door
script uses):

    scripts/eml-lib.praat
      include eml-lib-stats.praat
        include ../stats/eml-core-utilities.praat
        include ../stats/eml-core-descriptive.praat
        include ../stats/eml-extract.praat
        include ../stats/eml-output.praat
        include ../stats/eml-inferential.praat      <- calls @emlAnovaKernelTwoWay
        include ../stats/eml-result-writer.praat
        include ../stats/eml-record.praat
        include ../stats/eml-demo-tables.praat
      include ../stats/eml-analysis.praat            <- defines emlRunTwoWayAnalysis
      include eml-lib-graphs.praat
        include ../graphs/eml-graph-procedures.praat
        include ../graphs/eml-annotation-procedures.praat
        include ../graphs/eml-draw-procedures.praat
        include ../graphs/eml-graphs-form.praat

Command, run in the repo:

    grep -rn "include.*eml-anova-kernel" /home/claude/repo/plugin_EML_StatsGraphs

Output: **empty**. No file anywhere in the plugin tree includes
`stats/eml-anova-kernel.praat`. `stats/eml-inferential.praat`, the chain
member that calls `@emlAnovaKernelTwoWay`, is the member that would have to
name it, and does not.

Corroborated by re-running the check named in the ruling:

    $ Rscript validate/v162_door_chain_population.R
    ...
    FAIL  v162    every module setup.praat's table and the door chain must agree on a check reads was actually rendered
    FAIL  v162      phantom module setup.praat's table and the door chain must agree on: stats/eml-anova-kernel.praat, stats/eml-psychometrics.praat, stats/eml-categorical.praat
    ------------------------------------------------------------------------------
    10 checks, 8 passed, 2 FAILED

`setup.praat`'s "not-in-barrel" exemption list (setup.praat:428-435, read
directly) also does not name `stats/eml-anova-kernel.praat` — its absence
from the chain is not a documented, reasoned exclusion the way
`eml-lmm.praat` or `eml-graphs-form.praat` are. It is the omission the
ruling describes.

## Step 3 — drive the door

`harness/doorcensus` and `harness/regressdoors` were read first. Both
avoid GUI entirely for this exact reason (doorcensus's header: "the kernel
calls are the door... the chrome does not change a number"), and
`harness/savepaths/leg.praat`'s technique — build a real `Table`, hand it to
a **shipped, unmodified** file via `include`, so include-resolution matches
the real menu path exactly — is the shape followed here, aimed at the
specific orchestrator the door's form calls at line 105.

**No plugin file was edited.** `plugin_EML_StatsGraphs/` was copied verbatim
to a scratch directory (verified byte-identical with `diff -rq`, empty
output), and one new file was added only inside that throwaway copy —
never inside the repo's plugin tree.

    $ cp -r /home/claude/repo/plugin_EML_StatsGraphs "$SCRATCH/plugin_probe"
    $ diff -rq /home/claude/repo/plugin_EML_StatsGraphs "$SCRATCH/plugin_probe"
    (no output — exact copy)

The added file, `$SCRATCH/plugin_probe/scripts/zz_probe_anovakernel.praat`:

    include eml-lib.praat

    Read Table from comma-separated file: "/home/claude/repo/harness/exportint/fixtures/demo_twoway.csv"
    tableId = selected ("Table")

    writeInfoLine: "PROBE begin"
    @emlRunTwoWayAnalysis: tableId, "SPL_dB", "voice_type", "task"
    appendInfoLine: "PROBE error$ = [", emlRunTwoWayAnalysis.error$, "]"
    ...

This is exactly the call the shipped door script makes at
`scripts/eml-compare-twoway.praat:105`, on the committed fixture
`harness/exportint/fixtures/demo_twoway.csv` (columns `subject, voice_type,
task, SPL_dB` — two factors, one numeric column, 48 rows), reached through
the unmodified `include eml-lib.praat` chain.

Run (Praat 6.6.30, `/home/claude/praat`, resolved via `harness/_env.sh`):

    $ "$PRAAT" $PRAAT_TRUST --run "$SCRATCH/plugin_probe/scripts/zz_probe_anovakernel.praat"
    exit code: 255
    === stdout ===
    PROBE begin
    === stderr ===
    Error: Procedure "emlAnovaKernelTwoWay" not found.
    Script line 17003 not performed or completed:
    « @emlAnovaKernelTwoWay: .tableId, .dataCol$, .factor1$, .factor2$, 3 »
    Script ".../zz_probe_anovakernel.praat" not completed.
    Praat: script command <.../zz_probe_anovakernel.praat> not completed.

The failing line Praat quotes is byte-for-byte the call at
`stats/eml-inferential.praat:5259`. "PROBE begin" printed and nothing after
it — the script died mid-orchestration, before `emlRunTwoWayAnalysis` could
return a value, let alone an `.error$` a user-facing dialog could show. A
user driving the real menu item to this point (Objects > New > Compare
two-way (ANOVA)..., a table with two factor columns and one numeric column,
Run) hits Praat's own uncaught-error dialog with this text, not the
plugin's `@emlErrorDialog`.

## What a user would have experienced

Selecting a table, choosing "Compare two-way (ANOVA)..." from the menu,
filling in the data/factor-1/factor-2 fields and pressing Run: the form
closes, the analysis begins, and Praat raises its own uncaught-script-error
dialog reading `Procedure "emlAnovaKernelTwoWay" not found.` with no result,
no plugin-authored explanation, and no path forward from that dialog except
to dismiss it. Every other analysis reachable from the door chain (one-way
ANOVA, Kruskal-Wallis, t-tests, correlation, regression, etc.) is
unaffected — only the two-way path, which is the one path in the whole
chain that calls into the unreached module.

## Evidence trail

- `plugin_EML_StatsGraphs/setup.praat:73` — menu registration
- `plugin_EML_StatsGraphs/setup.praat:397` — barrel table entry for the module
- `plugin_EML_StatsGraphs/setup.praat:428-435` — the barrel's own documented
  exclusions, which do not name this module
- `plugin_EML_StatsGraphs/scripts/eml-compare-twoway.praat:105` — the call
- `plugin_EML_StatsGraphs/stats/eml-analysis.praat:2726` — `emlRunTwoWayAnalysis`
- `plugin_EML_StatsGraphs/stats/eml-inferential.praat:5162,5259` — `emlTwoWayAnova`
  and the unresolved call
- `plugin_EML_StatsGraphs/scripts/eml-lib.praat` and its transitively
  included files — the chain that never names `stats/eml-anova-kernel.praat`
- `Rscript validate/v162_door_chain_population.R` — static confirmation,
  quoted above
- Live drive above — the reproduced crash, Praat 6.6.30
