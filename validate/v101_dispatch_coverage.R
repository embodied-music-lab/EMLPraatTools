# ============================================================================
# v101 — every figure type is drawn through the form's own dispatch
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE HOLE THIS CLOSES. Thirteen figure types reach the page through
# @emlGraphsDispatchDraw. Every other harness in this suite either calls a
# draw procedure directly or drives one type through the dialogs, so until
# harness/dispatch existed nothing exercised the seam between the form and a
# draw procedure. A fault living in that seam -- a variable the draw reads
# that only the form sets, a recorder prelude assuming state the dispatch does
# not publish -- was reachable by a user and by nothing here.
#
# It was not hypothetical. A scatter drawn with recording OFF aborted on an
# uninitialised note variable and reached the author's machine; the suite
# could not have caught it, because no check drove a scatter through the
# dispatch at all. This file is the answer to that.
#
# WHAT A LEG PROVES, AND WHAT IT DOES NOT. It proves the dispatch returned,
# that ink reached the page, and that a file was written. It says nothing
# about what the figure LOOKS like -- v100 asserts the drawing rectangle and
# the per-type harnesses assert content. The failure this catches is an abort,
# and an abort is exactly what the seam produces when it breaks.
#
# RECORDED AND UNRECORDED ARE SEPARATE LEGS. The fault that shipped was
# invisible with recording on: the variable it read was initialised on the
# recorded path and not on the other, so a suite that only ever recorded would
# have stayed green through it.
#
# Base R only. No packages.

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V <- "v101"

dp_path <- repo_path("harness", "dispatch", "out", "DISPATCH.tsv")
check_true(V, "the dispatch harness has been driven", file.exists(dp_path))
if (!file.exists(dp_path)) {
    if (!exists("EML_SUITE")) { eml_report("v101 every figure type through the dispatch"); eml_exit() }
}

# EVERY COLUMN AS TEXT. Left to itself read.delim types `value` numeric
# because most rows are numbers, and then a comparison against "1" is a
# comparison against 1 and fails silently -- a validator that reports 29
# failures on evidence that is entirely correct is worse than no validator.
dp <- read.delim(dp_path, stringsAsFactors = FALSE, quote = "",
                 colClasses = "character")
val <- function(leg, key) {
    r <- dp$value[dp$leg == leg & dp$key == key]
    if (length(r) == 0L) NA_character_ else r[1]
}

# The thirteen types, by the internal id the form dispatches on.
TYPES <- list(
    "1"  = "pitch contour", "2"  = "waveform",     "3"  = "spectrum",
    "4"  = "LTAS",          "5"  = "line chart",   "6"  = "bar chart",
    "7"  = "violin",        "8"  = "scatter",      "9"  = "box plot",
    "10" = "histogram",     "11" = "grouped violin",
    "12" = "grouped box",   "13" = "spaghetti")

# EVERY TYPE, NOT A SAMPLE. A type missing from this list is a type that can
# abort in front of a user with nothing here to notice.
for (id in names(TYPES)) {
    nm <- TYPES[[id]]
    check_true(V, sprintf("the %s returns from the dispatch", nm),
               identical(val(id, "returned"), "1"))
    check_true(V, sprintf("the %s puts ink on the page", nm),
               {
                   x0 <- suppressWarnings(as.numeric(val(id, "drawnMinX")))
                   x1 <- suppressWarnings(as.numeric(val(id, "drawnMaxX")))
                   y0 <- suppressWarnings(as.numeric(val(id, "drawnMinY")))
                   y1 <- suppressWarnings(as.numeric(val(id, "drawnMaxY")))
                   isTRUE(!any(is.na(c(x0, x1, y0, y1))) && x1 > x0 && y1 > y0)
               })
    check_true(V, sprintf("the %s writes its file", nm),
               identical(val(id, "png"), "1"))
}

# THE UNRECORDED PATH IS THE ONE THAT SHIPPED BROKEN, so the recorded legs are
# additional rather than instead. Each records at least one step: a recorded
# draw that records nothing is a recorder that stopped seeing the draw layer.
REC <- c("5_rec" = "line chart", "7_rec" = "violin", "8_rec" = "scatter")
for (leg in names(REC)) {
    nm <- REC[[leg]]
    check_true(V, sprintf("the %s also returns with recording on", nm),
               identical(val(leg, "returned"), "1"))
    check_true(V, sprintf("and the recorder sees the %s draw", nm),
               {
                   n <- suppressWarnings(as.numeric(val(leg, "steps")))
                   isTRUE(!is.na(n) && n >= 1)
               })
}

# THE CENSUS. A leg present in the evidence that no check reads is a leg
# driven for nothing; a check reading a leg that was never driven is a check
# that cannot fail. Both are stated, because either one hollows the file out.
driven <- unique(dp$leg)
read_by_checks <- c(names(TYPES), names(REC))
check_true(V, "every dispatch leg is accounted for by some check",
           all(driven %in% read_by_checks))
check_true(V, "every leg a check reads was actually driven",
           all(read_by_checks %in% driven))

if (!exists("EML_SUITE")) {
    eml_report("v101 every figure type through the form's dispatch")
    eml_exit()
}
