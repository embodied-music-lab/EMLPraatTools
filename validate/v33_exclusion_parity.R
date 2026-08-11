# ============================================================================
# v33_exclusion_parity.R -- the figure excludes the rows the analysis excludes
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS PINS. Until 11 August 2026 the two halves of the plugin read
# a cell differently. The stats path used @eml_readCell, which keeps a cell
# only if it is exactly the number it looks like -- written that way under D96
# because Praat coerces "1,5" to 1, so a European decimal comma did not drop a
# row, it put a DIFFERENT NUMBER into the mean with nothing in the report to
# say so. Every draw procedure used `number (Get value: ...)`, which is that
# same lenient numericiser.
#
# Measured on a fixture with one awkward cell per row: @eml_getGroupData
# reported group A as n=2 while @emlDrawViolinPlot drew four points, because
# "1,5" was dropped by the analysis and plotted as 1, and "30%" was dropped
# and plotted as 0.3. So the omnibus line the form paints onto a figure
# described a different data set from the figure, and the disclosure line --
# this plugin's own promise that what was dropped is stated -- was true of the
# figure and false of the analysis printed beside it. See §2d of
# audit/GRAPHING_PUSH_REMAINING.md.
#
# WHY THE CHECK IS A RELATIONSHIP AND NOT A RECOMPUTATION. Both numbers are
# produced in Praat, by the plugin's own procedures, and written to
# harness/parity/out/PARITY.tsv. This script compares them and never
# classifies a cell itself. An R-side copy of the classification rules would
# be a second implementation that drifts, and a drifted copy agreeing with
# neither reader would look like a failure of the plugin.
#
#     bash harness/parity/run.sh          regenerate the input
#     Rscript validate/v33_exclusion_parity.R
#
# Input: <parity>/PARITY.tsv, five fields, no header:
#            name  dirty  figureSkipped  statsExcluded  MATCH|MISMATCH
#        <parity> is $EML_PARITY_DIR, default harness/parity/out. A missing
#        artefact is a HARD STOP, not a skip -- for v27's reason: "the driver
#        never ran this" is exactly the failure a silently shrinking suite
#        would hide.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

par_dir <- Sys.getenv("EML_PARITY_DIR", unset = "")
if (!nzchar(par_dir)) par_dir <- repo_path("harness", "parity", "out")
par_p <- file.path(par_dir, "PARITY.tsv")

if (!file.exists(par_p)) {
    stop("parity artefact not found: ", par_p,
         "\n  Run: bash harness/parity/run.sh")
}

pt <- read.delim(par_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("name", "dirty", "figure", "stats", "verdict"))

# ---------------------------------------------------------------------------
# 1. The artefact is the shape this script expects
# ---------------------------------------------------------------------------
# Checked before anything is asserted on the contents, because every check
# below reads a column by name and would otherwise fail for the wrong reason.
check_true("v33", "parity artefact has rows", nrow(pt) > 0L)
check_true("v33", "parity artefact has the five expected fields",
           identical(names(pt), c("name", "dirty", "figure", "stats", "verdict")))
check_true("v33", "parity counts are integers",
           all(!is.na(suppressWarnings(as.integer(pt$figure)))) &&
           all(!is.na(suppressWarnings(as.integer(pt$stats)))))

pt$dirty  <- as.integer(pt$dirty)
pt$figure <- as.integer(pt$figure)
pt$stats  <- as.integer(pt$stats)

# ---------------------------------------------------------------------------
# 2. Every draw procedure that discloses a skipped count agrees with the
#    analysis layer on the same data
# ---------------------------------------------------------------------------
# This is the whole point of the file. One number against one number, per
# procedure, per fixture.
for (i in seq_len(nrow(pt))) {
    r <- pt[i, ]
    lbl <- sprintf("%s [%s]", r$name, if (r$dirty == 1L) "dirty" else "clean")
    check("v33", paste(lbl, "-- figure skipped == analysis excluded"),
          reported = r$figure, computed = r$stats, tol = 0)
    # The harness writes its own verdict; if it ever disagrees with the two
    # numbers next to it, the harness is broken and this file's other checks
    # cannot be trusted either.
    check_true("v33", paste(lbl, "-- harness verdict agrees with its own numbers"),
               identical(r$verdict == "MATCH", r$figure == r$stats))
}

# ---------------------------------------------------------------------------
# 3. The dirty half actually excludes something
# ---------------------------------------------------------------------------
# WITHOUT THIS THE WHOLE FILE PASSES ON A BROKEN PLUGIN. Two readers that both
# drop every row, or both drop none, agree perfectly. A parity check that only
# ever compares 0 to 0 is not a check, and the harness hit exactly that on its
# first run: the case script aborted before the dirty pass, the TSV held only
# clean rows, and everything "passed".
dirty <- pt[pt$dirty == 1L, ]
clean <- pt[pt$dirty == 0L, ]

check_true("v33", "the dirty fixture was rendered at all", nrow(dirty) > 0L)
check_true("v33", "the clean fixture was rendered at all", nrow(clean) > 0L)
check_true("v33", "every dirty case excludes at least one row",
           nrow(dirty) > 0L && all(dirty$figure > 0L))
check_true("v33", "every clean case excludes nothing",
           nrow(clean) > 0L && all(clean$figure == 0L))

# ---------------------------------------------------------------------------
# 4. Coverage is what it claims to be
# ---------------------------------------------------------------------------
# A parity suite that quietly stopped covering a procedure would pass. The
# seven names are the seven draw procedures that publish .nSkippedRows; if one
# is added or removed, this fails and the list has to be revisited on purpose.
expected <- c("violin", "box", "gviolin", "gbox", "spaghetti", "ts", "scatter")
check_true("v33", "all seven disclosing procedures are covered, clean",
           setequal(clean$name, expected))
check_true("v33", "all seven disclosing procedures are covered, dirty",
           setequal(dirty$name, expected))
check_true("v33", "each procedure appears once per fixture",
           !any(duplicated(paste(pt$name, pt$dirty))))

if (!exists("EML_SUITE")) {
    eml_report("v33 exclusion parity: the figure and the analysis drop the same rows")
    eml_exit()
}
