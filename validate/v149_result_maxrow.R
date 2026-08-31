# ============================================================================
# v149 — Result-store row cap: emlResult_MAXROW
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Regression test for the cap @emlAugmentFrom enforces before writing a
# result store augment table (eml-result-writer.praat).
#
# RAISED FROM 4000 TO 25000 ON 31 AUGUST 2026. The NIST StRD datasets
# SmLs03, SmLs06 and SmLs09 export 18,009 rows each, and the old 4000 cap
# aborted the export before the result store could write anything — the
# failure looked like a missing export rather than a refused one.
#
# This pins two things:
#   * the constant itself is at least 18009, so those three datasets clear it
#   * a real 18,009-row table actually goes through @emlAugmentFrom and
#     @emlResultWrite without hitting the exitScript abort
#
# Evidence is a HARNESS PROBE, not a GUI capture, because this is a boundary
# condition (an exact row count against a compile-time constant), not a
# number a dialog prints. harness/resultmaxrow/probe.praat builds an
# 18,009-row table, calls @emlResultBegin / @emlAugmentFrom / @emlResultWrite
# for real, and writes down what happened; harness/resultmaxrow/run.sh drives
# it. The probe measures — it asserts nothing — and this file is what
# asserts, same split as harness/resultstore/probe.praat and v138.
#
# Driven 31 August 2026:
#   harness/resultmaxrow/run.sh
# Evidence:
#   harness/resultmaxrow/out/MAXROW.tsv
#   harness/resultmaxrow/out/maxrow_probe_augment.csv
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# The NIST StRD row count this cap exists to clear. Named, not just used
# inline, so the arithmetic below reads as "at least the dataset" rather
# than as an arbitrary literal.
NIST_ROWS <- 18009L

tsv_path <- repo_path("harness", "resultmaxrow", "out", "MAXROW.tsv")
if (!file.exists(tsv_path)) {
    stop("evidence not found: ", tsv_path,
         " — run harness/resultmaxrow/run.sh first")
}
tsv <- read.delim(tsv_path, stringsAsFactors = FALSE)
val <- function(field) {
    row <- tsv[tsv$field == field, "value"]
    if (length(row) != 1L) {
        stop("field '", field, "' not found (or not unique) in ", tsv_path)
    }
    row
}

maxrow_constant <- as.numeric(val("maxrow_constant"))
augment_nRows   <- as.numeric(val("augment_nRows"))
files_written   <- as.numeric(val("files_written"))

# --- the constant itself ----------------------------------------------------
check_true("v149", "emlResult_MAXROW is at least the NIST StRD row count (18009)",
           maxrow_constant >= NIST_ROWS)

# --- the actual export, driven for real -------------------------------------
# augment_nRows is emlAugment_nRows as @emlAugmentFrom left it. If the cap
# had rejected the table, @emlAugmentFrom would have called exitScript before
# this line was reached and the probe would never have written it — so its
# mere presence in the capture is already evidence against an abort; the
# value check pins that the FULL 18,009 rows were accepted, not a truncated
# subset.
check_true("v149", "an 18009-row table is accepted by @emlAugmentFrom (no abort)",
           isTRUE(!is.na(augment_nRows)) && augment_nRows == NIST_ROWS)

# The export must have actually written the augment file, not merely
# accepted the row count and stopped short at write time.
check_true("v149", "@emlResultWrite wrote the augment file for the 18009-row table",
           isTRUE(!is.na(files_written)) && files_written >= 1)

# --- the exported artefact, checked independently of the probe's own count --
# Read the CSV @emlResultWrite actually produced and count its data rows
# directly, rather than trusting only the probe's self-report of nRows.
csv_path <- repo_path("harness", "resultmaxrow", "out", "maxrow_probe_augment.csv")
if (!file.exists(csv_path)) {
    stop("evidence not found: ", csv_path,
         " — run harness/resultmaxrow/run.sh first")
}
csv_data_rows <- length(readLines(csv_path, warn = FALSE)) - 1L  # minus header
check_true("v149", "the exported augment CSV itself contains 18009 data rows",
           csv_data_rows == NIST_ROWS)

if (!exists("EML_SUITE")) { eml_report("v20 result-store row cap"); eml_exit() }
