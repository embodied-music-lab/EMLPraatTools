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
#     straight to @emlGraphsWorkflow. The graphs layer fills the CSV buffer
#     only when the ANNOTATION BRIDGE runs, and this run is in beginner mode
#     where annotate = 0 -- so emlCSV_n was 0 and "Graph Complete" came up
#     with THREE buttons instead of four, no "Exp CSV" at all. The harness was
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

# ONE SAVE PANEL SINCE 13 AUG 2026. The four dialogs this list used to name
# -- Save Figure, Save Complete, Export Results, Export Complete -- were two
# separate save journeys, one per artefact, each with its own folder memory
# and naming. They are now one "Save" panel and one "Saved" confirmation, and
# a single press writes the figure, the result frames and the Info report
# under one folder and one stem.
STAGES <- c("EML Graphs", "Violin Plot -- Column Mapping", "Graph Complete",
            "Save", "Saved")
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
# is above zero. In beginner mode the annotation bridge never runs, so on this
# path the buffer can only have been filled upstream. Its presence is the
# evidence that the driver came in by the wrapper's route.
# THE PANEL IS REACHED, and it is the only save journey now. There is no
# separate Exp CSV button to check for: the panel offers the results
# alongside the figure and the report, and what it wrote is asserted below on
# the files themselves rather than on which button was available.
check_true("v45", "the save panel was opened", any(dl$button == "Save"))

# ---------------------------------------------------------------------------
# 2. THE SEQUENCE, not just the population
# ---------------------------------------------------------------------------
check_true("v45", "column mapping came after the main form",
           .first("Column Mapping") > .first("EML Graphs"))
check_true("v45", "the post-draw dialog came after column mapping",
           .first("Graph Complete") > .first("Column Mapping"))
check_true("v45", "the save panel came after the post-draw dialog",
           .first("Save") > .first("Graph Complete"))
check_true("v45", "the save was confirmed after the panel",
           .first("Saved") > .first("Save"))

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
# THREE VISITS, NOT FOUR. One save journey instead of two: Save, then
# Redraw, then Done. The row is also a fixed three buttons now, which is what
# retired the Done retry the harness used to carry.
check("v45", "the post-draw dialog was visited three times", 3L,
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
           all(dl$rev <= 3))
check_true("v45", "the single-button notice took exactly one step",
           all(dl$rev[dl$title == "Saved"] == 1))

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
# A HEADER-ONLY FRAME is about 40 bytes; a real one carries a data row too.
# NOT a single threshold across all of them: the effect-size frame is two
# short numeric rows and is legitimately smaller than the tidy frame, which
# is what a flat "> 100 bytes" check called a failure when the graphs button
# started writing broom's shape instead of one long file.
check_true("v45", "every exported frame carries more than a header",
           nrow(csv) >= 1 && all(csv$bytes > 45))

# ---------------------------------------------------------------------------
# 6b. THE EXPORT IS BROOM'S SHAPE, which is the whole point of the conversion
# ---------------------------------------------------------------------------
# The graphs form's Exp CSV button called @emlExportStatsCSV directly until
# 13 August 2026 -- the LEGACY writer, one long file of
# table,analysis,term,term_type,field,value -- while the stats wrappers' CSV
# button wrote tidy/glance/augment for the very same analysis. v20 and v21
# enumerate the stats-menu orchestrators, so neither could see it, and no
# harness had ever pressed this button. Both now go through
# @emlExportResultFiles.
check_true("v45", "a tidy frame was written",
           any(grepl("_tidy\\.csv$", csv$file)))
check_true("v45", "a glance frame was written",
           any(grepl("_glance\\.csv$", csv$file)))

# THE EXTRAS ARE SEPARATE MODEL OBJECTS, as they are in R -- effect sizes and
# post-hoc contrasts are their own frames, not extra rows on the model's tidy.
check_true("v45", "effect sizes were written as their own frame",
           any(grepl("_effectsize_tidy\\.csv$", csv$file)))

# ---------------------------------------------------------------------------
# 6c. ONE PRESS, ONE STEM -- the point of the panel
# ---------------------------------------------------------------------------
# Before this the figure and the numbers were two journeys with two folder
# memories and two naming rules, and the Info report could not be saved at
# all. One Save now writes all three, and they share a stem, which is what
# makes them findable as a set six months later.
txt <- ar[grepl("\\.txt$", ar$file), ]
check_true("v45", "the Info window report was written", nrow(txt) >= 1)
check_true("v45", "the report has real content, not just a header",
           nrow(txt) >= 1 && all(txt$bytes > 200))
stems <- sub("(_tidy|_glance|_augment|_effectsize_tidy|_report)?\\.[a-z]+$", "",
             ar$file)
check("v45", "every artefact shares one stem", 1L,
      length(unique(stems)), tol = 0)
check_true("v45", "and the stem is the table plus the graph type",
           unique(stems)[1] == "e2e_demo_Violin_Plot")

# NO AUGMENT, AND THAT IS CORRECT. This run is a two-group t-test, an htest,
# and broom has no augment for htests -- @emlResultWrite reports it skipped
# rather than writing an empty file. v21 asserts the same for the wrapper
# paths; asserting it here keeps the two exports honest about being the same
# shape.
check_true("v45", "no augment frame for an htest",
           !any(grepl("_augment\\.csv$", csv$file)))

# AND THE LEGACY FILE IS GONE. The defect's signature was a single CSV whose
# name carried no broom suffix at all. Its absence is the assertion that the
# fork actually fired rather than the run happening to write extra files.
check_true("v45", "no legacy single long-format file was written",
           !any(grepl("^[^.]*\\.csv$", csv$file) &
                !grepl("_(tidy|glance|augment)\\.csv$", csv$file)))

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
