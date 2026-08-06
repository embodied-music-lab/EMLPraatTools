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
    "v16_csv_export.R"
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
    cat("\nBy script id:\n")
    agg <- aggregate(pass ~ id, data = df,
                     FUN = function(x) sprintf("%d/%d", sum(x), length(x)))
    names(agg) <- c("id", "passed")
    print(agg, row.names = FALSE)
}

eml_exit()
