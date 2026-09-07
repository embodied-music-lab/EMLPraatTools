# ============================================================================
# validate/tools/group_extraction_runner.R
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Shared plumbing for the @eml_getGroupData equivalence probe. Builds the
# tiny wrapper script that includes (1) the extractor under test, (2) the
# fixture builder, and (3) the probe driver, in that fixed order, then runs
# Praat headless and returns the TSV it wrote.
#
# ONE FUNCTION, TWO CALLERS: validate/tools/gen_group_extraction_oracle.R
# (a one-time, not-normally-run generator that produced the committed
# oracle) and validate/v164_group_extraction_equivalence.R (the validator
# that re-runs it every time and diffs against that oracle). Both must drive
# the identical probe the identical way, or a divergence between them would
# be indistinguishable from a real regression -- so the wrapper-building
# logic is written once, here, and sourced by both rather than copied.
#
# Praat's `include` directive takes a LITERAL path -- it is a textual
# preprocessing step, not subject to the interpreter's own variable
# interpolation (confirmed against Praat 6.6.30: `include 'var$'` opens a
# file literally named "'var$'"). So the paths below are written into the
# wrapper as plain text by R, exactly as every other Praat-driving validator
# in this suite already does (see v108, v143 for the same pattern) -- this
# is not a shortcut invented for this probe.
# ============================================================================

# gxr_locate_praat -- resolve the Praat binary the same way every other
# Praat-driving validator in this suite does: PRAAT env var first, then a
# short list of fallbacks. Returns "" if none is found.
gxr_locate_praat <- function() {
    praat <- Sys.getenv("PRAAT", unset = "")
    if (nzchar(praat)) return(praat)
    for (cand in c(Sys.which("praat6630"), Sys.which("praat_barren"), Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) return(cand)
    }
    ""
}

# gxr_praat_version_num -- "6.6.30" -> 6630, for the floor check every
# Praat-driving validator in this suite makes (>= 6630).
gxr_praat_version_num <- function(praat) {
    if (!nzchar(praat) || !file.exists(praat)) return(0L)
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE, stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (!length(m)) return(0L)
    p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
    p[1] * 1000L + p[2] * 100L + p[3]
}

# gxr_run_probe -- build the wrapper, run it, return the TSV lines.
#
#   plug      EML_PLUGIN_DIR -- directory containing stats/eml-extract.praat
#             for the extractor under test (today's shipped one, or a
#             rewrite's, unmodified otherwise)
#   praat     path to the Praat binary
#   fixtures_praat, probe_praat
#             absolute paths to the fixture builder and probe driver
#             (validate/fixtures/group_extraction/group_extraction_fixtures.praat
#             and validate/group_extraction_probe.praat)
#   work_dir  scratch directory (created if absent) to write the wrapper
#             script and the output TSV into
#
# Returns list(ok = TRUE/FALSE, lines = character() of Praat's stdout+stderr,
#              tsv_path = path to the TSV Praat was asked to write,
#              tsv_lines = its content if `ok` and the file exists, else NULL)
gxr_run_probe <- function(plug, praat, fixtures_praat, probe_praat, work_dir) {
    dir.create(work_dir, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work_dir, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    extract_praat <- file.path(plug, "stats", "eml-extract.praat")
    stopifnot(file.exists(extract_praat), file.exists(fixtures_praat), file.exists(probe_praat))

    out_tsv <- file.path(work_dir, "group_extraction_probe_output.tsv")
    if (file.exists(out_tsv)) unlink(out_tsv)

    wrapper <- c(
        'writeInfoLine: "group_extraction_probe"',
        paste0("include ", extract_praat),
        paste0("include ", fixtures_praat),
        paste0("include ", probe_praat),
        sprintf('@gxf_runProbe: "%s"', out_tsv),
        'appendInfoLine: "GXF_DONE"'
    )
    wrapper_path <- file.path(work_dir, "group_extraction_wrapper.praat")
    writeLines(wrapper, wrapper_path)

    out <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(wrapper_path)),
        stdout = TRUE, stderr = TRUE))

    ok <- any(grepl("^GXF_DONE$", out)) && !any(grepl("^Error", out)) && file.exists(out_tsv)
    tsv_lines <- if (ok) readLines(out_tsv, warn = FALSE) else NULL

    list(ok = ok, lines = out, tsv_path = out_tsv, tsv_lines = tsv_lines)
}
