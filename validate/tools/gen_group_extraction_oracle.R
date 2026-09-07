#!/usr/bin/env Rscript
# ============================================================================
# validate/tools/gen_group_extraction_oracle.R
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# ONE-TIME GENERATOR, not part of the suite `run_all.R` runs and not itself
# a check. It runs validate/group_extraction_probe.praat once against the
# CURRENT (pre-rewrite) @eml_getGroupData and writes its output as the
# committed oracle, validate/group_extraction_oracle.tsv.
#
# Run this again ONLY to deliberately re-baseline the oracle against a new
# "intended" behaviour (e.g. once the group-extraction rewrite has been
# reviewed and its output has been hand-verified to be the intended new
# behaviour, not just different). Ordinarily the oracle is written once, and
# every later run compares against it with validate/
# v164_group_extraction_equivalence.R -- see that file, not this one, for
# the equivalence CHECK.
#
#     PRAAT=/usr/local/bin/praat6630 \
#     EML_PLUGIN_DIR=/tmp/eml-repo/plugin_EML_StatsGraphs \
#     Rscript validate/tools/gen_group_extraction_oracle.R
# ============================================================================

.a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
here <- if (length(.f)) dirname(normalizePath(.f)) else "."
validate_dir <- dirname(here)
source(file.path(here, "group_extraction_runner.R"))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- file.path(dirname(validate_dir), "plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)

praat <- gxr_locate_praat()
pvnum <- gxr_praat_version_num(praat)
if (pvnum < 6630) {
    stop(sprintf("needs Praat >= 6.6.30 to generate the oracle; found %s",
                 if (nzchar(praat)) praat else "none"))
}

fixtures_praat <- file.path(validate_dir, "fixtures", "group_extraction",
                            "group_extraction_fixtures.praat")
probe_praat <- file.path(validate_dir, "group_extraction_probe.praat")
oracle_path <- file.path(validate_dir, "group_extraction_oracle.tsv")

work <- file.path(tempdir(), "gen_group_extraction_oracle")
unlink(work, recursive = TRUE)

res <- gxr_run_probe(plug, praat, fixtures_praat, probe_praat, work)
if (!res$ok) {
    cat("probe did not complete cleanly; output:\n")
    cat(paste(" ", res$lines), sep = "\n")
    stop("oracle generation failed")
}

writeLines(res$tsv_lines, oracle_path)
cat(sprintf("wrote %d lines to %s\n", length(res$tsv_lines), oracle_path))
