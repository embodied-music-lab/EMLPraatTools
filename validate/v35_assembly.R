# ============================================================================
# v35_assembly.R -- the plugin ASSEMBLED, not its parts
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 11 August 2026 four defects were found by
# installing the plugin and clicking its own menu:
#
#   - fifteen of its entry points were dead at parse time, so EML Graphs, the
#     wizard, the LMM path and every analysis did nothing when clicked;
#   - every figure's auto-composed title had lost its special characters;
#   - the Draw branch of every analysis threw away the Table it had been
#     handed and asked the user to pick it again;
#   - an export dialog painted its OK button over its own output.
#
# None was visible to 8274 R checks, 39/39 stress cases, 52/52 disclosure
# cases, 357/357 phase1 assertions or two byte-exact round trips. Every one of
# those exercises the plugin's PARTS. Nothing assembled it: no harness had
# ever loaded scripts/eml-lib.praat, which is what all sixteen shipped
# wrappers load, and nothing had ever raised one of its dialogs.
#
# So this file asserts on two artefacts that only exist because something
# assembled the plugin and ran it:
#
#   harness/wrappers/out/WRAPPERS.tsv   every entry point parses
#   harness/gui_e2e/out/DIALOGS.tsv     the workflow advances through its
#                                       real dialogs when handed a Table
#
#     bash harness/wrappers/run.sh      regenerate the first
#     bash harness/gui_e2e/run.sh       regenerate the second
#     Rscript validate/v35_assembly.R
#
# Both artefacts are HARD STOPS when missing, not skips -- "the driver never
# ran this" is exactly the failure a silently shrinking suite would hide, and
# it is the failure that let the dead entry points ship.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# ---------------------------------------------------------------------------
# 1. Every menu entry point parses
# ---------------------------------------------------------------------------
wr_p <- Sys.getenv("EML_WRAPPERS_TSV", unset = "")
if (!nzchar(wr_p)) {
    wr_p <- repo_path("harness", "wrappers", "out", "WRAPPERS.tsv")
}
if (!file.exists(wr_p)) {
    stop("wrapper artefact not found: ", wr_p,
         "\n  Run: bash harness/wrappers/run.sh")
}
wr <- read.delim(wr_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("wrapper", "verdict", "why"))

check_true("v35", "wrapper artefact has rows", nrow(wr) > 0L)

# A COUNT, because a suite that quietly stopped covering an entry point would
# otherwise pass. The plugin ships 16 menu commands plus the library barrels;
# 20 is a floor that a deletion has to be deliberate to cross.
check_true("v35", "at least 20 entry points were checked", nrow(wr) >= 20L)

bad <- wr[wr$verdict != "parses", , drop = FALSE]
check("v35", "entry points that fail to parse",
      reported = 0, computed = nrow(bad), tol = 0)
if (nrow(bad) > 0) {
    for (i in seq_len(nrow(bad))) {
        check_true("v35", sprintf("%s parses (%s)", bad$wrapper[i], bad$why[i]),
                   FALSE)
    }
}

# The barrel itself. This is the file that was broken, and the one no harness
# had ever loaded; naming it means a future run cannot pass by covering only
# the leaf wrappers.
check_true("v35", "the library barrel eml-lib.praat is among those checked",
           "eml-lib.praat" %in% wr$wrapper)
check_true("v35", "the graphs entry point eml-graphs.praat is among those checked",
           "eml-graphs.praat" %in% wr$wrapper)

# ---------------------------------------------------------------------------
# 2. The workflow advances when a wrapper hands it a Table
# ---------------------------------------------------------------------------
# @emlGraphsWorkflow takes an object id, and a second @emlDetectContext used
# to read the Objects-window selection on the first pass and discard it. After
# an analysis the selection is no longer the source Table, so every wrapper's
# Draw branch asked the user to pick the Table it had just analysed.
dl_p <- Sys.getenv("EML_DIALOGS_TSV", unset = "")
if (!nzchar(dl_p)) {
    dl_p <- repo_path("harness", "gui_e2e", "out", "DIALOGS.tsv")
}
if (!file.exists(dl_p)) {
    stop("dialog artefact not found: ", dl_p,
         "\n  Run: bash harness/gui_e2e/run.sh")
}
dl <- read.delim(dl_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("step", "title"))

check_true("v35", "dialog artefact has rows", nrow(dl) > 0L)
check_true("v35", "the main form opened",
           any(grepl("EML Graphs", dl$title, fixed = TRUE)))

# THE ASSERTION THIS FILE WAS BUILT FOR.
check_true("v35", "the workflow never asked for an object it was handed",
           !any(grepl("No .* selected", dl$title)))

check_true("v35", "the workflow advanced to the column-mapping stage",
           any(grepl("Column Mapping", dl$title, fixed = TRUE)))

# ORDER, not just presence. A run that reached column mapping and then fell
# back to the main form is not the same as one that advanced, and a
# presence-only check cannot tell them apart.
i_form <- which(grepl("EML Graphs", dl$title, fixed = TRUE))[1]
i_map  <- which(grepl("Column Mapping", dl$title, fixed = TRUE))[1]
check_true("v35", "column mapping came after the main form",
           !is.na(i_form) && !is.na(i_map) && i_map > i_form)

# The step column must be the 1..n it claims to be, or the ordering check
# above is reading something other than the sequence it was walked in.
check_true("v35", "dialog steps are consecutive from 1",
           identical(as.integer(dl$step), seq_len(nrow(dl))))

if (!exists("EML_SUITE")) {
    eml_report("v35 assembly: every entry point parses, and the workflow advances")
    eml_exit()
}
