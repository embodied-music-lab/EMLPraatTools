#!/usr/bin/env Rscript
# ============================================================================
# EML Praat Tools — validation suite runner
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#   Rscript validate/run_all.R
#
# Base R only. No packages are installed or loaded. Exits 1 if any check
# fails, so it can be wired to CI unchanged.
#
# Read REGISTRY.md first — it says what each script covers, which of them
# pin known defects (and therefore SHOULD fail once those defects are
# fixed), and which checks are still awaiting a GUI drive.
# ============================================================================

.a <- commandArgs(FALSE)
.f <- sub("^--file=", "", .a[grep("^--file=", .a)])
HERE <- if (length(.f)) dirname(normalizePath(.f)) else getwd()
Sys.setenv(EML_VALIDATE_DIR = HERE)

source(file.path(HERE, "helpers.R"))
EML_SUITE <- TRUE

scripts <- c(
    "v01_pairwise_welch_bonferroni.R",
    "v02_pairwise_holm_differential.R",
    "v03_rm_anova_greenhouse_geisser.R",
    "v04_friedman.R",
    "v05_paired_t.R",
    "v06_D15_effect_size_defect.R",
    "v07_redpath_degenerate_inputs.R",
    # Orchestrator suites, 5 August 2026. These cover stats/eml-analysis.praat
    # — the layer that assembles a report out of already-oracled primitives.
    "v08_twogroup_orchestrator.R",
    "v09_anova_tukey_orchestrator.R",
    "v10_kruskal_dunn_orchestrator.R",
    "v11_twoway_orchestrator.R",
    "v12_correlation_orchestrator.R",
    "v13_regression_orchestrator.R",
    "v14_descriptive_orchestrator.R",
    "v15_normality_orchestrator.R",
    "v16_csv_export.R",
    # v17 needs only stock R in BASE mode (it uses broom when broom is
    # installed and falls back to base R otherwise, and says which), so it
    # belongs in the runner like the rest. Added 6 Aug 2026 -- it had been
    # written standalone and was invisible to a reviewer following the
    # instructions in REGISTRY.
    "v17_broom_parity.R",
    # v18 is the Tier B grid: the shipping statistical procedures over 16
    # designed shapes rather than one GUI-driven table each. Stock R, and it
    # reads committed evidence like every other script, so it belongs in the
    # runner. It is DIFFERENT EVIDENCE from v01-v15, not more of it -- those
    # check the printed report, this checks the procedure behind it.
    "v18_sweep_parity.R",
    # v19 is the NIST StRD tier. It contributes checks only when the .dat
    # files have been ingested (they are not redistributable), and prints a
    # loud SKIP otherwise rather than silently contributing nothing.
    "v19_nist_strd.R",
    # v20 is the first CSV migration checkpoint: the SHIPPING ANOVA path in
    # broom's three-file shape. Distinct from v17, which checks the writer
    # called directly by a harness. A path is not converted until it has a
    # check at this level.
    "v20_shipping_anova_broom.R",
    # v21 is the rest of the CSV migration: the other ten shipping paths in
    # broom's three-file shape, every file written by the orchestrator the
    # menu calls. Includes the assertion that htest paths write NO augment,
    # since broom has none for them.
    "v21_shipping_paths_broom.R",
    # v22 covers the Ruling 1 numerics: Brown-Forsythe (median-centred
    # Levene), Welch's k-sample F, and Games-Howell. None of the three
    # existed before the ruling, so nothing above reaches them. Includes the
    # k = 2 identity -- Welch's F is Welch t-squared, which is what keeps
    # Tier A property A1 honest once these are reachable from the reporter.
    "v22_homogeneity.R",
    # v23 checks the Q-Q figure's own point pairs against qnorm/ppoints and
    # sort(x), so the figure and the reported W are bound to the same points.
    # Also pins the Blom-vs-qqnorm plotting-position difference above n = 10
    # rather than leaving it to be discovered.
    "v23_qq_points.R",
    # v24 checks leverage, Cook's distance and the leverage-corrected
    # standardised residual against hatvalues/cooks.distance/rstandard.
    # It pins the OLD .std.resid form as WRONG, so reverting the augment
    # site turns this red rather than passing quietly.
    "v24_influence.R",
    # v25 is Ruling 1 at the REPORT level -- two captures from the same input
    # file differing only in data column, so the conditional can be asserted
    # in BOTH directions. The absent case carries the ruling's real
    # constraint: on data that does not trip the check, a run must look as it
    # did before the feature existed, and the primary F must still be aov()'s
    # pooled F rather than oneway.test()'s.
    "v25_anova_showboth.R",
    # v26 is Ruling 3(a) at the report level, same two-direction shape as v25:
    # the interaction caveat must appear when the interaction is significant
    # and stay away when it is not, and the three F values must be identical
    # either way. Also pins that the caveat sits under the table it qualifies
    # rather than under the effect sizes, per the D98 placement ruling.
    "v26_twoway_caveat.R",
    # v27 is the D111 uniformity guard: every Table-consuming draw procedure,
    # given no usable data, must fall back to a unit axis and draw the
    # labelled empty frame. The histogram used to `goto` past its own `Axes:`
    # and write a blank white page. Includes a static check that no `goto`
    # returns to the draw library, which is how the defect got in.
    # Reads harness/stress_out/, so harness/stress_graphs.sh must run first --
    # same dependency shape as v23 on harness/qq_drive.sh.
    "v27_empty_frames.R",
    # v28 guards column TYPE. Praat has two column readers that disagree: the
    # row-wise one returns undefined for a text cell, which every other path
    # already drops, but `Report two-way anova:` numericises the column as a
    # whole and substitutes each value's ALPHABETICAL RANK. The two-way test
    # therefore reported F = 132.92, p = 6.9e-15 on a column of singers'
    # names. One bad cell is enough. Asserts the refusal by exact message AND
    # that every legitimate analysis still runs -- a guard that refused
    # everything would pass the first half alone.
    "v28_column_type_guard.R",
    # v29 is the figure-disclosure ruling: "draw the image as the image unless
    # someone asks to annotate". Info window always, the figure only when
    # Annotate is ticked, the user's subtitle never. The ANNOTATE-OFF direction
    # is the load-bearing half -- that is the ruling. Includes a static ban on
    # assigning to emlSubtitle$ in the draw library, the same shape as v27's
    # static ban on goto. Reads harness/disclosure/out/.
    "v29_figure_disclosure.R",
    # v30 pins that an error return in the wizard keeps the USER'S columns.
    # The wizard said "Nothing has been lost" and then re-rendered from a
    # column guess; a user who pressed Run without touching anything got a
    # different analysis reported as theirs. Asserts from before/after captures
    # that the fixed one never names a guessed column.
    "v30_wizard_state.R",
    # v31 pins the gridline-mode encoding. Two incompatible encodings shared
    # one persisted key, so drawing a scatter with gridlines off left a
    # histogram's dropdown blank and refusing to proceed -- on disk, so it
    # survived a restart. One canonical encoding now, translated at the
    # dialog. The registry checks are the load-bearing half: they fail at
    # INCLUDE time if a future graph type omits its entry, which is how the
    # bug got in.
    "v31_gridmode.R",
    # v32 pins the plot rectangle. The dimensions a user types describe the
    # DATA AREA, not the data area plus its furniture -- if a legend carves
    # space out of the 6 x 4 someone asked for, "make my figure square" stops
    # being satisfiable. So the plot rectangle must be identical in all five
    # legend placements, and a legend that needs room outside it has to grow
    # the SAVED IMAGE instead. 205 renders from two fixtures. The GEOMETRY
    # RIG (harness/legend/case.praat) holds the figure constant while the
    # legend sweeps: the legend matrix at three figure sizes with no placement
    # declared, which is what every existing caller supplies, the five
    # placements driven one render each, a real four-group comparison matrix
    # under the plot, and the red paths. The DEMONSTRATION
    # (harness/legend/series_case.praat) drives @emlDrawTimeSeries and
    # @emlDrawScatterPlot -- a multi-series line chart and a grouped scatter,
    # where the number of legend entries IS the number of series and the
    # corner is the one @emlPlaceElements scored rather than one the fixture
    # chose -- and measures how much DATA the key sits on at placement 1,
    # against a control render of the same figure on the same axis with the
    # legend suppressed. Every number is measured on the rendered PIXELS, not
    # read back from what the script believed it drew -- both sides of that
    # comparison are computed by the same arithmetic and move together. Also
    # pins the D135 over-wide label, both before and after it was closed, and
    # the static rule that a legend renderer draws into the rectangle it was
    # HANDED. Reads harness/legend/out/, so harness/legend/run.sh must run
    # first -- same dependency shape as v27 on harness/stress_graphs.sh.
    "v32_legend_geometry.R",
    # v33 pins EXCLUSION PARITY: the figure drops the rows the analysis drops.
    # They did not agree until 11 Aug 2026 -- the stats path read cells with
    # @eml_readCell and every draw procedure with Praat's own numericiser, so
    # "1,5" was dropped by an ANOVA and plotted as 1. The omnibus line painted
    # onto a figure then described a different data set from the figure. Both
    # counts are produced in Praat by the plugin's own procedures; this script
    # compares them and never classifies a cell itself.
    #     bash harness/parity/run.sh
    "v33_exclusion_parity.R"
)

cat("EML Praat Tools validation suite\n")
cat("R ", R.version$major, ".", R.version$minor, "  ",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")

for (s in scripts) {
    cat("\n>> ", s, "\n", sep = "")
    source(file.path(HERE, s), local = new.env(parent = globalenv()))
}

df <- eml_report("SUMMARY — all scripts")

if (!is.null(df)) {
    # P4, 6 Aug 2026. This aggregate counted attestations while the headline
    # did not, so the per-script column summed to 460 against a headline of
    # 454 and R7 read 8/8 with an ATST inside it. Two presentations of the
    # same run must not disagree. Attestations are excluded here and reported
    # in their own column instead.
    chk <- df[df$expect != "attested", , drop = FALSE]
    cat("\nBy script id:\n")
    agg <- aggregate(pass ~ id, data = chk,
                     FUN = function(x) sprintf("%d/%d", sum(x), length(x)))
    names(agg) <- c("id", "passed")
    att <- df[df$expect == "attested", , drop = FALSE]
    if (nrow(att)) {
        n_att <- as.data.frame(table(att$id), stringsAsFactors = FALSE)
        names(n_att) <- c("id", "attested")
        agg <- merge(agg, n_att, by = "id", all.x = TRUE)
        agg$attested[is.na(agg$attested)] <- 0L
    }
    print(agg, row.names = FALSE)
}

eml_exit()
