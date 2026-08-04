#!/usr/bin/env python3
"""Apply the EML_PROCEDURE_REGISTRY.md corrections as guarded passes.

Every edit is a single-occurrence text substitution with an assertion
before (the anchor text exists exactly once) and after (the replacement
landed, and where applicable the anchor is gone). Nothing is retyped by
hand at delivery time: the "not yet documented" table and the grand
totals are generated from procs.json, the same ground truth that
reg-reconcile.py checks against.

Usage: reg-apply-edits.py <registry.md>
Rewrites the file in place. Idempotency is NOT claimed -- run once on a
clean baseline; the guards will fail loudly on a second run.
"""
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROCS = os.path.join(HERE, "procs.json")

# The prose note that must survive byte-identical through every pass.
WIZ_NOTE = (
    "All wizard helpers set `emlWizardExplain$` which is consumed by the "
    "next `@emlReportLine` or `@emlReportLineString` call. They are no-ops "
    "when `emlWizardMode = 0` (callers gate on the flag before calling)."
)

DOCUMENTED = [
    "stats/eml-core-descriptive.praat",
    "stats/eml-core-utilities.praat",
    "stats/eml-extract.praat",
    "stats/eml-output.praat",
    "stats/eml-inferential.praat",
    "graphs/eml-graph-procedures.praat",
    "graphs/eml-draw-procedures.praat",
    "graphs/eml-annotation-procedures.praat",
    "graphs/eml-graphs-form.praat",
    "scripts/eml-wizard.praat",
    "scripts/eml-batch-process.praat",
    "dev/tests/eml-test-helpers.praat",
    "scripts/eml-graphs.praat",          # present on disk, 0 procedures
]

_n = 0


def replace_once(src, old, new, label):
    """Substitute `old` -> `new` exactly once. `old` must not survive."""
    global _n
    _n += 1
    c = src.count(old)
    assert c == 1, "[%02d %s] anchor occurs %d times, expected 1" % (_n, label, c)
    assert old not in new, "[%02d %s] anchor reappears in replacement" % (_n, label)
    out = src.replace(old, new)
    assert new in out, "[%02d %s] replacement not present after edit" % (_n, label)
    assert old not in out, "[%02d %s] anchor survived edit" % (_n, label)
    assert WIZ_NOTE in out, "[%02d %s] wizard prose note damaged" % (_n, label)
    print("  [%02d] %s" % (_n, label))
    return out


def insert_after(src, anchor, addition, label):
    """Append `addition` immediately after `anchor` (which is preserved)."""
    global _n
    _n += 1
    c = src.count(anchor)
    assert c == 1, "[%02d %s] anchor occurs %d times, expected 1" % (_n, label, c)
    assert addition not in src, "[%02d %s] addition already present" % (_n, label)
    out = src.replace(anchor, anchor + addition)
    assert addition in out, "[%02d %s] addition not present after edit" % (_n, label)
    assert out.count(anchor) == 1, "[%02d %s] anchor duplicated" % (_n, label)
    assert WIZ_NOTE in out, "[%02d %s] wizard prose note damaged" % (_n, label)
    print("  [%02d] %s" % (_n, label))
    return out


def main():
    if len(sys.argv) != 2:
        print("usage: reg-apply-edits.py <registry.md>", file=sys.stderr)
        return 2
    path = sys.argv[1]
    truth = json.load(open(PROCS))

    src = open(path, encoding="utf-8").read()
    assert WIZ_NOTE in src, "baseline is missing the wizard prose note"
    shutil.copyfile(path, path + ".bak")
    print("baseline backed up to %s.bak (%d bytes)" % (path, len(src)))

    # -- 1. preamble ------------------------------------------------------
    src = replace_once(
        src,
        "Generated: 8 April 2026 | Source: plugin_EMLTools v1.0 pre-release "
        "| 251 procedures (246 public, 5 internal)",
        "Generated: 8 April 2026 | Revised: 3 August 2026 against the "
        "plugin_EML_Praat_Tools working tree\n"
        "241 procedures (228 public, 13 internal) across the 13 documented "
        "files present in the tree. Counts and version tags in this file are "
        "reconciled by procedure NAME against the source tree by "
        "`dev/tools/reg-reconcile.py`, not by count alone.",
        "preamble totals + provenance",
    )

    # -- 2. Stats: Descriptive -------------------------------------------
    src = replace_once(
        src,
        "**File:** `stats/eml-core-descriptive.praat` (v1.0) — 18 procedures",
        "**File:** `stats/eml-core-descriptive.praat` (v1.2) — 21 procedures "
        "(19 public, 2 internal)",
        "descriptive header v1.0->1.2, 18->21",
    )
    src = insert_after(
        src,
        "| `@emlDescribe` | Full descriptive summary (all stats in one call) "
        "| .data# | public |",
        "\n| `@emlShapiroWilk` | Shapiro-Wilk normality test (W statistic and "
        "p-value) | .data# | public |"
        "\n| `@eml_hasUndefined` | Test whether a vector contains any undefined "
        "element (internal helper) | .v# | internal |"
        "\n| `@eml_swPoly` | Evaluate the Shapiro-Wilk weight polynomial "
        "(internal helper) | .c#, .x | internal |",
        "descriptive +3 rows",
    )

    # -- 3. Stats: Extraction --------------------------------------------
    src = replace_once(
        src,
        "**File:** `stats/eml-extract.praat` (v1.2) — 13 procedures "
        "(12 public, 1 internal)",
        "**File:** `stats/eml-extract.praat` (v1.5) — 19 procedures "
        "(13 public, 6 internal)",
        "extract header v1.2->1.5, 13->19",
    )
    src = insert_after(
        src,
        "| `@eml_getGroupData` | Extract one group's data from Table by label "
        "(internal helper) | .tableId, .dataCol$, .groupCol$, .groupLabel$ | "
        "internal |",
        "\n| `@emlGuessColumnRoles` | Infer likely data and grouping column "
        "roles from a Table | .tableId | public |"
        "\n| `@eml_normalizeLabel` | Normalize a group label for matching "
        "(internal helper) | .raw$ | internal |"
        "\n| `@eml_strictNumericColumn` | Verify a column is strictly numeric "
        "(internal helper) | .tableId, .columnName$ | internal |"
        "\n| `@eml_groupSubset` | Build the row-index subset for one group "
        "label (internal helper) | .tableId, .groupCol$, .groupLabel$ | "
        "internal |"
        "\n| `@eml_getGroupPairedData` | Extract paired columns for one group "
        "(internal helper) | .tableId, .colX$, .colY$, .groupCol$, "
        ".groupLabel$ | internal |"
        "\n| `@eml_kwScan` | Scan a column into the Kruskal-Wallis working "
        "list (internal helper) | .colName$, .kwList$ | internal |",
        "extract +6 rows",
    )

    # -- 4. Stats: Output -------------------------------------------------
    src = replace_once(
        src,
        "**File:** `stats/eml-output.praat` (v1.3) — 21 procedures",
        "**File:** `stats/eml-output.praat` (v1.8) — 42 procedures",
        "output header v1.3->1.8, 21->42",
    )
    src = insert_after(
        src,
        "| `@emlWizardExplainKurtosis` | Kurtosis tail weight label | .kurt | "
        "public |",
        "\n| `@emlWizardExplainEffectG` | Hedges g magnitude interpretation | "
        ".g | public |"
        "\n| `@emlWrapperInit` | Initialize stats-wrapper state with a minimum "
        "column guard | .minCols | public |"
        "\n| `@emlWrapperExportCSV` | Export the active wrapper Table to CSV | "
        ".tableName$ | public |",
        "output +3 rows",
    )

    # -- 5. Stats: Inferential -------------------------------------------
    src = replace_once(
        src,
        "**File:** `stats/eml-inferential.praat` (v1.2) — 25 procedures "
        "(22 public, 3 internal)",
        "**File:** `stats/eml-inferential.praat` (v1.3) — 28 procedures "
        "(24 public, 4 internal)",
        "inferential header v1.2->1.3, 25->28",
    )
    src = replace_once(
        src,
        "| `@emlTheilSen` | Theil-Sen robust median-based regression (Conover "
        "intercept, scipy-verified) | .x#, .y# | public |",
        "| `@emlTheilSen` | Theil-Sen robust median-based regression, Conover "
        "intercept. Verified against scipy by "
        "`dev/tests/phase2/test-theilsen.praat` (47 checks) over margins built "
        "by `dev/tools/theilsen-build-margins.py` — measured agreement 0.0 "
        "across 27 margins, with 6/6 negative controls from "
        "`dev/tools/theilsen-negative-controls.py` (re-verified 3 August 2026) "
        "| .x#, .y# | public |"
        "\n| `@eml_pearsonCore` | Core Pearson r computation with tail "
        "selection (internal helper) | .x#, .y#, .tails | internal |",
        "TheilSen claim -> named artifacts; +eml_pearsonCore",
    )

    # -- 6. Graphs: Core --------------------------------------------------
    src = replace_once(
        src,
        "**File:** `graphs/eml-graph-procedures.praat` (v3.20) — 45 procedures",
        "**File:** `graphs/eml-graph-procedures.praat` (v3.22) — 45 procedures",
        "graph-procedures header v3.20->3.22",
    )

    # -- 7. Graphs: Draw --------------------------------------------------
    src = replace_once(
        src,
        "**File:** `graphs/eml-draw-procedures.praat` (v1.16) — 14 procedures",
        "**File:** `graphs/eml-draw-procedures.praat` (v1.19) — 15 procedures",
        "draw header v1.16->1.19, 14->15",
    )
    src = insert_after(
        src,
        "| `@emlDrawGroupedBoxPlot` | Draw side-by-side box plots for grouped "
        "data | .objectId, .title$, .xLabel$, .yLabel$, .vpW, .vpH, "
        ".colorMode$, .gridMode, .catCol$, .subCol$, .valueCol$, .vMin, .vMax "
        "| public |",
        "\n| `@emlDrawLMMForest` | Draw a forest plot of LMM fixed effects with "
        "Wald confidence intervals | — (reads `emlLMM.*` and `emlWaldCI.*`) | "
        "public |",
        "draw +1 row",
    )

    # -- 8. Graphs: Annotation -------------------------------------------
    src = replace_once(
        src,
        "**File:** `graphs/eml-annotation-procedures.praat` (v3.15) — "
        "23 procedures",
        "**File:** `graphs/eml-annotation-procedures.praat` (v3.18) — "
        "25 procedures",
        "annotation header v3.15->3.18, 23->25 (rows already reconciled)",
    )

    # -- 9. Graphs: Form --------------------------------------------------
    src = replace_once(
        src,
        "**File:** `graphs/eml-graphs-form.praat` (v1.4) — 8 procedures",
        "**File:** `graphs/eml-graphs-form.praat` (v2.2) — 9 procedures",
        "graphs-form header v1.4->2.2, 8->9",
    )
    src = insert_after(
        src,
        "| `@emlGraphsWorkflow` | Unified graph creation workflow (standalone "
        "and stats-wrapper entry) | .objectId | public |",
        "\n| `@emlAdjustMethodName` | Map a p-value adjustment index to its "
        "method name | .idx | public |",
        "graphs-form +1 row",
    )

    # -- 10. Scripts: Wizard (structural) ---------------------------------
    src = replace_once(
        src,
        "**File:** `scripts/eml-wizard.praat` (v1.4) — 15 procedures",
        "**File:** `scripts/eml-wizard.praat` (v2.3) — 8 procedures",
        "wizard header v1.4->2.3, 15->8",
    )
    wiz_old = (
        "| `@wizardNormDiag` | Run normality diagnostics (skewness, kurtosis) "
        "for wizard | .data#, .label$ | public |\n"
        "| `@wizardRunIndepT` | Execute independent t-test from wizard "
        "selections | .g1#, .g2#, .label1$, .label2$, .dataCol$, .groupCol$ | "
        "public |\n"
        "| `@wizardRunMWU` | Execute Mann-Whitney U test from wizard "
        "selections | .g1#, .g2#, .label1$, .label2$, .dataCol$, .groupCol$ | "
        "public |\n"
        "| `@wizardRunPairedT` | Execute paired t-test from wizard selections "
        "| .v1#, .v2#, .col1$, .col2$ | public |\n"
        "| `@wizardRunWilcoxonSR` | Execute Wilcoxon signed-rank test from "
        "wizard selections | .v1#, .v2#, .col1$, .col2$ | public |\n"
        "| `@wizardRunAnova` | Execute one-way ANOVA from wizard selections | "
        ".tableId, .dataCol$, .groupCol$ | public |\n"
        "| `@wizardRunKW` | Execute Kruskal-Wallis test from wizard selections "
        "| .tableId, .dataCol$, .groupCol$ | public |\n"
        "| `@wizardRunTwoWay` | Execute two-way ANOVA from wizard selections | "
        ".tableId, .dataCol$, .factor1$, .factor2$ | public |\n"
        "| `@wizardRunPearson` | Execute Pearson correlation from wizard "
        "selections | .x#, .y#, .col1$, .col2$ | public |\n"
        "| `@wizardRunSpearman` | Execute Spearman correlation from wizard "
        "selections | .x#, .y#, .col1$, .col2$ | public |\n"
        "| `@wizardRunDescribe` | Execute descriptive stats from wizard "
        "selections | .data#, .col$ | public |\n"
        "| `@wizardRunDescribeByGroup` | Execute grouped descriptive stats "
        "from wizard selections | .tableId, .dataCol$, .groupCol$ | public |\n"
        "| `@wizardReportPairwise` | Report pairwise post-hoc results from "
        "wizard | .nGroups, .method$ | public |\n"
        "| `@wizardCreateExample` | Create example Table for wizard demo | "
        ".hint$ | public |\n"
        "| `@wizardStub` | Placeholder for unimplemented wizard branches | "
        ".analysis$, .batch$ | public |"
    )
    wiz_new = (
        "| `@wizardNormDiag` | Run normality diagnostics (skewness, kurtosis) "
        "for wizard | .data#, .label$ | public |\n"
        "| `@wizardNormCheck` | Check normality for one or two columns and set "
        "wizard state | .mode$, .tableId, .col1$, .col2$ | public |\n"
        "| `@wizardNormLabel` | Build the normality summary label for the "
        "wizard plan | .normChecked, .summary$, .testApproach | public |\n"
        "| `@wizardPrepareTable` | Prepare and select the working Table for "
        "the wizard run | .hint$ | public |\n"
        "| `@wizardReportPlan` | Report the chosen analysis plan before "
        "execution | .design$, .normality$, .test$, .posthoc$, .col1$, .col2$, "
        ".col3$, .table$ | public |\n"
        "| `@wizardRunDescribeByGroup` | Execute grouped descriptive stats "
        "from wizard selections | .tableId, .dataCol$, .groupCol$ | public |\n"
        "| `@wizardCreateExample` | Create example Table for wizard demo | "
        ".hint$ | public |\n"
        "| `@wizardStub` | Placeholder for unimplemented wizard branches | "
        ".analysis$, .batch$ | public |\n"
        "\n"
        "Registry note (3 August 2026): eleven rows previously listed here — "
        "`@wizardRunIndepT`, `@wizardRunMWU`, `@wizardRunPairedT`, "
        "`@wizardRunWilcoxonSR`, `@wizardRunAnova`, `@wizardRunKW`, "
        "`@wizardRunTwoWay`, `@wizardRunPearson`, `@wizardRunSpearman`, "
        "`@wizardRunDescribe`, `@wizardReportPairwise` — documented a per-test "
        "dispatch architecture that has no `procedure` definition in "
        "`scripts/eml-wizard.praat` in this tree. They were removed rather "
        "than retained, because a documented call target that does not exist "
        "is worse than an undocumented one. The count was right by accident "
        "(15 claimed, 15 rows) while the names were a superseded "
        "architecture — which is why this registry is reconciled by name."
    )
    src = replace_once(src, wiz_old, wiz_new, "wizard table -11/+4 rows + drift note")

    # -- 11/12. files absent from the tree --------------------------------
    src = insert_after(
        src,
        "**File:** `vibrato/eml-vibrato-procedures.praat` (v2.0) — "
        "11 procedures",
        " — NOT PRESENT IN THIS PLUGIN TREE\n\n"
        "The `vibrato/` directory does not exist in this working tree. These "
        "rows are retained as a record of the procedure set, are unverified "
        "against any source file, and are excluded from the totals below.",
        "vibrato marked absent",
    )
    src = insert_after(
        src,
        "**File:** `tutorial/eml-demo-procedures.praat` (v1.2) — 31 procedures",
        " — NOT PRESENT IN THIS PLUGIN TREE\n\n"
        "The `tutorial/` directory does not exist in this working tree. These "
        "rows are retained as a record of the procedure set, are unverified "
        "against any source file, and are excluded from the totals below.",
        "demo window marked absent",
    )

    # -- 13. Dev: Test Harness -------------------------------------------
    src = replace_once(
        src,
        "**File:** `dev/tests/eml-test-helpers.praat` (v1.0) — 9 procedures",
        "**File:** `dev/tests/eml-test-helpers.praat` (v1.2) — 11 procedures",
        "test-helpers header v1.0->1.2, 9->11",
    )
    src = insert_after(
        src,
        "| `@emlTestSummary` | Print pass/fail summary and exit with status | "
        "— | public |",
        "\n| `@emlTestAssertEqualRel` | Assert numeric equality within a "
        "relative tolerance | .name$, .expected, .actual, .relTolerance | "
        "public |"
        "\n| `@emlTestSkip` | Record a skipped test with a stated reason | "
        ".name$, .reason$ | public |",
        "test-helpers +2 rows",
    )

    # -- 14. footer: totals + generated "not yet documented" table ---------
    undoc = sorted(
        ((f, len(v)) for f, v in truth.items() if f not in DOCUMENTED),
        key=lambda x: (-x[1], x[0]),
    )
    n_undoc = sum(n for _, n in undoc)
    n_doc = sum(len(truth[f]) for f in DOCUMENTED if f in truth)
    grand = sum(len(v) for v in truth.values())
    assert n_doc + n_undoc == grand, "documented + undocumented != grand total"
    assert n_doc == 241 and n_undoc == 163 and grand == 404, (
        "ground truth moved: doc=%d undoc=%d grand=%d" % (n_doc, n_undoc, grand)
    )

    rows = "\n".join("| `%s` | %d |" % (f, n) for f, n in undoc)
    footer = (
        "**Documented and present in this tree: %d procedures** "
        "(228 public, 13 internal) across %d files.\n"
        "\n"
        "The Vibrato and Demo Window sections above document a further "
        "42 procedures in files that are not present in this plugin tree. "
        "They are excluded from the %d.\n"
        "\n"
        "## Not yet documented\n"
        "\n"
        "These procedure-bearing files exist in the tree but have no registry "
        "section, accounting for %d procedures. No rows are fabricated for "
        "them here — each file needs a documentation pass. This table is "
        "generated from `dev/tools/procs.json`.\n"
        "\n"
        "| File | Procedures |\n"
        "|------|------------|\n"
        "%s\n"
        "\n"
        "**Tree total: %d procedures** across %d procedure-bearing files "
        "(%d documented + %d not yet documented).\n"
        % (n_doc, len(DOCUMENTED), n_doc, n_undoc, rows, grand,
           len(truth), n_doc, n_undoc)
    )
    src = replace_once(
        src,
        "**Total: 251 procedures** (246 public, 5 internal) across 15 files",
        footer,
        "footer totals + generated not-yet-documented table",
    )

    # -- final invariants -------------------------------------------------
    assert WIZ_NOTE in src, "wizard prose note lost"
    assert "scipy-verified" not in src, "unbacked scipy claim survived"
    assert "@wizardRunIndepT` | Execute" not in src, "removed wizard row survived"
    open(path, "w", encoding="utf-8").write(src)
    print("\n%d guarded passes applied. %s now %d bytes." % (_n, path, len(src)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
