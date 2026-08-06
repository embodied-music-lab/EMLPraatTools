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
    "v18_sweep_parity.R"
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
