# ============================================================================
# v42_legend_room.R -- the form's two-pass headroom loop, driven
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. @emlGraphsDrawWithLegendRoom draws the figure, asks
# @emlLegendHeadroomAfterDraw whether the legend needs y-axis room, and if so
# THROWS THE FIRST PASS AWAY and draws again on the widened axis. It sits at
# file scope in eml-graphs-form.praat with a comment saying it was extracted
# so that a probe could drive it.
#
# NO PROBE EVER DID. Until 13 August 2026 the loop, its pass counter, its
# per-type axis read-back and @emlGraphsDispatchDraw had never executed
# outside a live dialog on a real display -- part of the whole span of
# @emlGraphsWorkflow from the draw commit onward that nothing had run.
#
# harness/legend covers the headroom ARITHMETIC by reimplementing the two-pass
# in its own fixture, with room=0 and room=1 arms. That is a statement about
# the maths. It is not a statement about this procedure, which is where the
# maths is actually used.
#
# WHAT DRIVING IT COST, and the cost is itself the finding:
# @emlGraphsDispatchDraw is a flat dispatch on graph_type in which EVERY
# argument is a form global, and it selects an outer viewport of
# figure_width x totalCanvasHeight -- a variable @emlGraphsWorkflow computes
# in a pre-dispatch block, from the comparison-matrix panel geometry, that
# nothing outside the dialog had ever run either. The probe has to supply
# that state by hand. It also has to know each global's exact name: the
# spaghetti path reads sp*, not spaghetti*, which the dispatcher discovered
# by refusing them.
#
#     bash harness/legendroom/run.sh      regenerate the input
#     Rscript validate/v42_legend_room.R
#
# Input: <dir>/LEGENDROOM.tsv, seven fields, no header:
#            case  type  placement  passes  axisMode  baseMin  baseMax
#        <dir> is $EML_LEGENDROOM_DIR, default harness/legendroom/out. A
#        missing artefact is a HARD STOP, not a skip.
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

lr_dir <- Sys.getenv("EML_LEGENDROOM_DIR", unset = "")
if (!nzchar(lr_dir)) lr_dir <- repo_path("harness", "legendroom", "out")
lr_p <- file.path(lr_dir, "LEGENDROOM.tsv")

if (!file.exists(lr_p)) {
    stop("legend-room artefact not found: ", lr_p,
         "\n  Run: bash harness/legendroom/run.sh")
}

lr <- read.delim(lr_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("case", "type", "placement", "passes",
                               "axisMode", "baseMin", "baseMax"))
for (col in c("type", "placement", "passes", "axisMode")) {
    lr[[col]] <- as.integer(lr[[col]])
}
for (col in c("baseMin", "baseMax")) lr[[col]] <- as.numeric(lr[[col]])

CASES <- c("scatter_inside", "scatter_right", "histogram_inside",
           "gviolin_inside", "spaghetti_inside")
eml_census("v42", "legend-room case", lr$case, CASES)
eml_claim("v42", "legendroom_out", CASES)
check("v42", "every declared case was driven", nrow(lr), length(CASES),
      tol = 0)

.g <- function(nm, col) lr[[col]][match(nm, lr$case)]

# ---------------------------------------------------------------------------
# 1. THE LOOP RAN, which is the whole point
# ---------------------------------------------------------------------------
# legendRoomPass is incremented inside the loop, so a value of at least 1 on
# every case is the loop having executed rather than been skipped.
check_true("v42", "every case drove the loop at least once",
           all(lr$passes >= 1))
check_true("v42", "no case ran away past the two passes the design allows",
           all(lr$passes <= 2))

# ---------------------------------------------------------------------------
# 2. TWO PASSES HAPPEN, AND ONE PASS HAPPENS
# ---------------------------------------------------------------------------
# Both outcomes are asserted, because a loop that ALWAYS redrew and a loop
# that NEVER redrew would each satisfy a one-sided check while being broken in
# opposite directions. Placement 1 is inside the plot -- the only placement
# that can force room into the axis. Placement 2 parks the legend beside the
# frame, where no axis room is needed.
check("v42", "a legend inside the plot forces the second pass", 2,
      .g("scatter_inside", "passes"), tol = 0)
check("v42", "the same figure with the legend outside needs only one", 1,
      .g("scatter_right", "passes"), tol = 0)
check_true("v42", "the second pass is not a property of one graph type",
           .g("gviolin_inside", "passes") == 2 &&
           .g("spaghetti_inside", "passes") == 2)

# ---------------------------------------------------------------------------
# 3. BOTH AXIS MODES, which is why the histogram is here
# ---------------------------------------------------------------------------
# legendRoomAxis is 1 for the value-axis types and 2 for the histogram, whose
# y-axis is FREQUENCY with a hard floor at 0 -- it takes room above and none
# below. Driving only mode 1 would leave that branch untouched, and the branch
# exists because choosing the wrong one used to fail at run time.
check("v42", "the histogram reports the frequency-axis mode", 2,
      .g("histogram_inside", "axisMode"), tol = 0)
check_true("v42", "the value-axis types report mode 1",
           all(lr$axisMode[lr$case != "histogram_inside"] == 1))
check_true("v42", "every case resolved an axis mode at all",
           all(lr$axisMode %in% c(1, 2)))

# ---------------------------------------------------------------------------
# 4. THE AXIS READ BACK IS A REAL AXIS
# ---------------------------------------------------------------------------
# legendRoomBaseMin/Max are read from the draw procedure that just ran -- the
# resolved extent, not a second opinion about it. An unset or collapsed axis
# would show up here as NA or as min >= max, which is what reading the wrong
# field name produced before every branch was moved to axisY*.
check_true("v42", "every case read back a defined axis",
           all(is.finite(lr$baseMin)) && all(is.finite(lr$baseMax)))
check_true("v42", "every axis has positive extent",
           all(lr$baseMax > lr$baseMin))
# The histogram's frequency floor is a hard 0 inside the draw procedure.
check("v42", "the histogram's frequency axis starts at zero", 0,
      .g("histogram_inside", "baseMin"), tol = 0)

if (!exists("EML_SUITE")) {
    eml_report("v42 legend room: the form's two-pass headroom loop, driven")
    eml_exit()
}
