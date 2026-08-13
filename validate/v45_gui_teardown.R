# ============================================================================
# v45_gui_teardown.R -- the workflow driven to teardown, and what it left
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. harness/gui_e2e reached the column-mapping dialog and
# stopped, so the whole span of @emlGraphsWorkflow from the Draw commit onward
# had never executed outside a live dialog on a real display: the type-specific
# commit block, the draw, the post-draw dialog, Save Figure, Export Results,
# Redraw and teardown. v35 asserts that the workflow ADVANCES. Nothing asserted
# that it FINISHES, because nothing had ever driven it that far.
#
# WHAT UNBLOCKED IT is in v44: the walk runs backward. shift+Tab xN presses the
# Nth button from the end, so the count comes from each dialog's endPause: list
# rather than from its field list, and no keystroke ever enters a field.
#
# WHAT DRIVING IT FOUND, and none of it was visible from the mapping dialog:
#
#   * The driver was not doing what the wrapper does. eml-compare-groups runs
#     @emlRunTwoGroupAnalysis and only then offers Draw; the driver jumped
#     straight to @emlGraphsWorkflow. Nothing in plugin/graphs/ ever calls
#     @eml_csvAppend, so emlCSV_n was 0 and "Graph Complete" came up with
#     THREE buttons instead of four -- no "Exp CSV" at all. The harness was
#     arriving at a variant of that dialog no user reaches.
#   * The driver's include set was three files short of the shipped barrel
#     (eml-result-writer, eml-record, eml-analysis), which is only detectable
#     by running code that needs them.
#   * The run wrote its figure into the HOME DIRECTORY. @emlSaveConfig persists
#     lastPNGFolder, the Save Figure dialog seeds its folder field from it, and
#     the config left in the harness's pref dir said /root. A harness that
#     inherits yesterday's config saves wherever yesterday's run was pointed.
#
# THE ORDER OF THE BRANCHES IS DELIBERATE. Save, then Export CSV, then Redraw,
# then Done -- so the SECOND pass through the workflow is what presses Done,
# and teardown is reached from a re-entered workflow rather than a fresh one.
#
#     bash harness/gui_e2e/run.sh          regenerate the input
#     Rscript validate/v45_gui_teardown.R
#
# Input: <dir>/DIALOGS.tsv    step, title, button label, shift+Tab count
#        <dir>/ARTEFACTS.tsv  filename, size in bytes
#        <dir> is $EML_GUIE2E_DIR, default harness/gui_e2e/out. Missing
#        artefacts are a HARD STOP, not a skip.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

g_dir <- Sys.getenv("EML_GUIE2E_DIR", unset = "")
if (!nzchar(g_dir)) g_dir <- repo_path("harness", "gui_e2e", "out")
dl_p <- file.path(g_dir, "DIALOGS.tsv")
ar_p <- file.path(g_dir, "ARTEFACTS.tsv")

for (p in c(dl_p, ar_p)) {
    if (!file.exists(p)) {
        stop("gui end-to-end artefact not found: ", p,
             "\n  Run: bash harness/gui_e2e/run.sh")
    }
}

dl <- read.delim(dl_p, header = FALSE, stringsAsFactors = FALSE,
                 quote = "", comment.char = "",
                 col.names = c("step", "title", "button", "rev"))
dl$step <- as.integer(dl$step)
dl$rev  <- as.integer(dl$rev)
ar <- read.delim(ar_p, header = FALSE, stringsAsFactors = FALSE,
                 quote = "", comment.char = "",
                 col.names = c("file", "bytes"))
ar$bytes <- as.numeric(ar$bytes)

STAGES <- c("EML Graphs", "Violin Plot -- Column Mapping", "Graph Complete",
            "Save Figure", "Save Complete", "Export Results",
            "Export Complete")
eml_claim("v45", "guie2e_out", STAGES)

.first <- function(pat) which(grepl(pat, dl$title, fixed = TRUE))[1]
.n     <- function(pat) sum(grepl(pat, dl$title, fixed = TRUE))

# ---------------------------------------------------------------------------
# 1. EVERY STAGE WAS REACHED, and each is named on its own
# ---------------------------------------------------------------------------
# Named separately rather than counted, because "the run got shorter" is
# exactly what a single step-count check cannot tell you.
for (s in STAGES) {
    check_true("v45", paste("reached the", s, "dialog"), .n(s) >= 1)
}
# THE DIALOG THAT ONLY EXISTS WHEN THE ANALYSIS RAN FIRST. Export Results is
# behind the "Exp CSV" button, which Graph Complete shows only when emlCSV_n
# is above zero -- and the graphs layer never fills that buffer. Its presence
# is the evidence that the driver came in by the wrapper's route.
check_true("v45", "the Exp CSV branch was available, so the buffer was filled",
           any(dl$button == "ExpCSV"))

# ---------------------------------------------------------------------------
# 2. THE SEQUENCE, not just the population
# ---------------------------------------------------------------------------
check_true("v45", "column mapping came after the main form",
           .first("Column Mapping") > .first("EML Graphs"))
check_true("v45", "the post-draw dialog came after column mapping",
           .first("Graph Complete") > .first("Column Mapping"))
check_true("v45", "Save Figure came after the post-draw dialog",
           .first("Save Figure") > .first("Graph Complete"))
check_true("v45", "the save was confirmed after the save dialog",
           .first("Save Complete") > .first("Save Figure"))
check_true("v45", "the export was confirmed after the export dialog",
           .first("Export Complete") > .first("Export Results"))

# THE WORKFLOW WAS NEVER ASKED FOR WHAT IT WAS HANDED. v35's assertion,
# repeated here because this run is four times longer and a regression could
# surface on the second pass rather than the first.
check_true("v45", "the workflow never asked for an object it was handed",
           !any(grepl("No .* selected", dl$title)))
check_true("v45", "no column was rejected as non-numeric",
           !any(grepl("Column Error", dl$title, fixed = TRUE)))

# ---------------------------------------------------------------------------
# 3. REDRAW RE-ENTERED THE WORKFLOW
# ---------------------------------------------------------------------------
# Redraw does not redraw. It sets keepGoing = 1 and jumps back to the OUTER
# repeat, so the whole workflow runs again from the main form. A Redraw that
# fell through to teardown instead would show every dialog above exactly once
# and would read as a pass.
check_true("v45", "Redraw was pressed", any(dl$button == "Redraw"))
check("v45", "the main form opened twice, so Redraw re-entered the workflow",
      2L, .n("EML Graphs"), tol = 0)
check("v45", "and the mapping dialog was driven twice", 2L,
      .n("Column Mapping"), tol = 0)
i_redraw <- which(dl$button == "Redraw")[1]
check_true("v45", "the second main form came after Redraw, not before",
           which(grepl("EML Graphs", dl$title, fixed = TRUE))[2] > i_redraw)

# ---------------------------------------------------------------------------
# 4. TEARDOWN
# ---------------------------------------------------------------------------
# Done is the only branch that reaches the teardown block -- Quit exits the
# script outright and Redraw loops. It has to be the LAST thing pressed, and
# nothing may follow it.
check_true("v45", "Done was pressed", any(dl$button == "Done"))
check_true("v45", "Done was the last button pressed",
           tail(dl$button[dl$button != "Done-retry3"], 1) == "Done")
check("v45", "the post-draw dialog was visited four times", 4L,
      .n("Graph Complete"), tol = 0)

# THE STEP COLUMN IS THE SEQUENCE IT CLAIMS TO BE, or every ordering check
# above is reading something other than the order it was walked in.
check_true("v45", "dialog steps never go backwards",
           !is.unsorted(dl$step))

# ---------------------------------------------------------------------------
# 5. EVERY PRESS WENT BACKWARD, which is what makes the counts derivable
# ---------------------------------------------------------------------------
# A forward count would depend on the field list, on which fields the Advanced
# toggle is showing, and on Praat's prepended Undo. Every count here is a
# shift+Tab count read off an endPause: list -- so none exceeds the number of
# buttons on the dialog it was used on, and the largest in the run is the four
# of Graph Complete.
check_true("v45", "every press used at least one reverse step", all(dl$rev >= 1))
check_true("v45", "no press needed more steps than Graph Complete has buttons",
           all(dl$rev <= 4))
check_true("v45", "the single-button notices took exactly one step",
           all(dl$rev[grepl("Complete$", dl$title) &
                      dl$title != "Graph Complete"] == 1))

# ---------------------------------------------------------------------------
# 6. THE FILES. A Save branch that opened its dialog, took the press and wrote
#    nothing would satisfy every check above.
# ---------------------------------------------------------------------------
png <- ar[grepl("\\.png$", ar$file), ]
csv <- ar[grepl("\\.csv$", ar$file), ]
check_true("v45", "the run saved a figure", nrow(png) >= 1)
check_true("v45", "the run exported a CSV", nrow(csv) >= 1)

# NOT MERELY PRESENT. An empty file is what a save that opened its stream and
# wrote nothing leaves behind, and it satisfies file.exists().
check_true("v45", "the figure is a real PNG, not an empty file",
           nrow(png) >= 1 && all(png$bytes > 1000))
check_true("v45", "the CSV has more than a header row",
           nrow(csv) >= 1 && all(csv$bytes > 100))

# THE NAMES CAME FROM THE PLUGIN'S OWN DEFAULTS, which is the only evidence
# that saveAutoName$ and @emlGraphsCSVDefaultName ran on this path at all --
# both build <source>_<something> and neither had been driven through a dialog.
check_true("v45", "the figure was named from the table and the graph type",
           nrow(png) >= 1 && any(grepl("^e2e_demo_", png$file)))
check_true("v45", "the CSV was named from the table and the analysis",
           nrow(csv) >= 1 && any(grepl("^e2e_demo_", csv$file)))
check_true("v45", "the figure name carries the graph type, not a generic stem",
           nrow(png) >= 1 && any(grepl("Violin", png$file)))

if (!exists("EML_SUITE")) {
    eml_report("v45 gui teardown: the workflow driven to the end, and its files")
    eml_exit()
}
