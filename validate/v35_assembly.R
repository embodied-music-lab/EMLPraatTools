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

# ...AND THE FLOOR IS NOT ENOUGH, which is worth saying because it read like
# enough. 26 wrappers ship and the floor is 20, so SIX could be deleted and
# this file would still pass while reporting that every entry point parses.
# The population is therefore named. The list is the contents of
# plugin/scripts/, which is what harness/wrappers/run.sh globs, so a wrapper
# added or removed has to be dealt with here on purpose.
WRAPPERS_EXPECTED <- c(
  # The sixteen menu commands.
  "eml-batch-process.praat", "eml-check-data.praat",
  "eml-check-normality.praat", "eml-compare-groups.praat",
  "eml-compare-k-groups.praat", "eml-compare-kw.praat",
  "eml-compare-paired.praat", "eml-compare-twoway.praat",
  "eml-correlate.praat", "eml-create-demo.praat",
  "eml-describe-table.praat", "eml-graphs.praat", "eml-lmm.praat",
  "eml-pairwise.praat", "eml-regress.praat", "eml-wizard.praat",
  # The table editor, which is three files because the launcher and the
  # editor are separate entry points.
  "eml-edit-table-editor.praat", "eml-edit-table-launch.praat",
  "eml-edit-table.praat",
  # The library barrels. eml-lib.praat is the one no harness had ever loaded
  # before 11 Aug 2026 and the one the duplicate include killed.
  "eml-lib.praat", "eml-lib-graphs.praat", "eml-lib-lmm.praat",
  "eml-lib-stats.praat",
  # Tabled by the author, still shipped, still has to parse.
  "eml-quick-start.praat", "eml-stats-demo.praat", "eml-tutorial.praat",
  # The workflow recorder, wired to the menu 12 Aug 2026. Two commands and
  # no checkbox on any dialog -- the recorder accumulates a SEQUENCE across
  # menu invocations, which a per-analysis boolean cannot express, and a row
  # on twenty dialogs is a row Praat gives no scrollbar for.
  # Three record commands since 13 Aug 2026, each named for what it does:
  # 'Record script', 'Stop recording and open', 'Stop recording and save...'.
  # The open one raises the script in a ScriptEditor rather than printing it,
  # because the Info window holds the analysis reports and is what Save Info
  # writes -- a script in there destroys the deliverable.
  "eml-record-start.praat", "eml-record-open.praat",
  "eml-record-save.praat",
  # NOT A MENU COMMAND, and it lives in plugin/scripts because of where
  # Praat resolves a relative name from. eml-edit-table.praat hands each
  # committed change to it with `runScript: "eml-record-edit-step.praat"`,
  # which Praat resolves against the CALLING script's folder -- so the two
  # files have to be siblings. setup.praat registers no button for it, and
  # v107's census reads setup.praat rather than this list, so it is counted
  # here only as a file that must parse, which is all this file asks.
  "eml-record-edit-step.praat")
eml_census("v35", "entry point", wr$wrapper, WRAPPERS_EXPECTED)
# Declared for validate/coverage.R (§19).
eml_claim("v35", "wrappers_out", WRAPPERS_EXPECTED)

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
# FOUR COLUMNS SINCE 13 AUG 2026. The harness used to press Return at every
# dialog and record only the title; it now presses a NAMED button chosen by a
# reverse shift+Tab count, and records which and how many. The extra columns
# are v45's; the assertions below are unchanged and read the same two fields.
dl <- read.delim(dl_p, header = FALSE, stringsAsFactors = FALSE,
                 quote = "", comment.char = "",
                 col.names = c("step", "title", "button", "rev"))

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

# The step column must be the sequence it claims to be, or the ordering check
# above is reading something other than the order it was walked in. NOT
# `identical(step, seq_len(n))` any more: a Done press that finds three
# buttons instead of four retries at a different count and records a second
# row under the SAME step number, which is deliberate -- the retry is evidence,
# not noise, and a strictly-consecutive check would have forbidden recording it.
check_true("v35", "dialog steps start at 1 and never go backwards",
           dl$step[1] == 1L && !is.unsorted(dl$step))

if (!exists("EML_SUITE")) {
    eml_report("v35 assembly: every entry point parses, and the workflow advances")
    eml_exit()
}
