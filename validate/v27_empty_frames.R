# ============================================================================
# v27_empty_frames.R -- what the ten Table-consuming draw procedures do when
#                       there is no usable data.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# D111. Given a table with nothing usable in it, every draw procedure must
# fall back to a unit axis and render the LABELLED EMPTY FRAME -- title, axis
# names, tick labels, box -- and must say on the Info channel that it did so.
# Before this was ruled, four different behaviours coexisted, and
# @emlDrawHistogram `goto HIST_END`-ed straight past its own `Axes:` call and
# wrote a 1800x1200 PNG of one single colour: a blank white page.
#
#     harness/stress_graphs.sh          regenerate the inputs to this script
#     Rscript validate/v27_empty_frames.R
#
# Input:  <stress>/RESULTS.tsv      case, verdict, ink %, chromatic px
#         <stress>/<case>.png       the rendered figure
#         <stress>/<case>.log       the Info-window transcript
#         plugin/graphs/eml-draw-procedures.praat   read here, statically
#
#   <stress> is $EML_STRESS_DIR, default harness/stress_out (IN-REPO, like
#   harness/stress_graphs.sh writes. A missing artefact is a HARD STOP, not a
#   skip: "the driver never ran this" is precisely the failure a silently
#   shrinking suite would hide.
#
# WHY THE FIGURE IS JUDGED BY CHROMATIC PIXELS
# --------------------------------------------
# Base R cannot decode a PNG without a package, so this script does not touch
# pixels; it reads the two numbers harness/stress_graphs.sh measured with
# ImageMagick. Chromatic pixel count -- saturated AND not near-white -- is the
# harness's own blank-frame detector, and it is the right one here: the plugin
# draws DATA in a coloured series palette and CHROME (box, ticks, text) in
# grey and black, which antialiases to a small, stable chromatic residue. So
# "a labelled empty frame" scores a few thousand, "a blank page" scores 0, and
# "a figure with data in it" scores hundreds of thousands.
#
# The predecessor rule, ink fraction < 2%, is NOT used and must not come back:
# it condemned violin_zerovar and violin_n1, both of which are CORRECT
# figures. A violin of a constant is a line at that constant and a violin of
# n = 1 is a tick at the value, and two thin lines in a 1800x1200 frame are a
# tenth of a percentage point. See the comment block in stress_graphs.sh.
#
# WHAT "NO TWO FAMILIES DISAGREE" MEANS HERE
# ------------------------------------------
# The ten empty frames are not pixel-identical and should not be: a
# categorical x-axis prints no tick numbers where a continuous one prints
# eleven, and the categorical types additionally print "No data to plot" in
# the panel. So the agreement asserted is one of MAGNITUDE -- every family's
# empty frame lands in the same narrow band -- rather than of identity. The
# band is derived from the ten measurements themselves (max/min ratio), not
# from a hard-coded expected count, so it fails on divergence rather than on
# any future theme change that moves all ten together.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

stress_dir <- Sys.getenv("EML_STRESS_DIR", unset = repo_path("harness", "stress_out"))
# Flat layout, matching harness/qq_out which v23 reads: PNGs, logs and
# RESULTS.tsv sit together in one directory.
out_dir    <- stress_dir
res_p      <- file.path(stress_dir, "RESULTS.tsv")
draw_p     <- repo_path("plugin", "graphs", "eml-draw-procedures.praat")
cases_dir  <- repo_path("harness", "stress_cases")

if (!file.exists(res_p))
    stop(sprintf("v27: %s missing -- run harness/stress_graphs.sh first", res_p))

res <- read.delim(res_p, header = FALSE, stringsAsFactors = FALSE,
                  col.names = c("case", "verdict", "ink", "chrom", "first"))
res$ink   <- suppressWarnings(as.numeric(sub("%$", "", res$ink)))
res$chrom <- suppressWarnings(as.numeric(res$chrom))

# ---------------------------------------------------------------------------
# The ten. `family` is the RESULTS.tsv prefix the harness derives with
# ${name%%_*}, so it is also how populated siblings are found below. `says` is
# the disclosure the procedure must make on the Info channel -- the exact
# house wording, not merely "some warning", so that a procedure which quietly
# stops explaining itself fails here.
# ---------------------------------------------------------------------------
ten <- rbind(
  data.frame(family = "ts",        proc = "emlDrawTimeSeries",
             says = "NOTE: Time series — no usable (time, value) pair; empty axes drawn."),
  data.frame(family = "tsci",      proc = "emlDrawTimeSeriesCI",
             says = "NOTE: Time series (with CI) — no usable (time, value) pair; empty axes drawn."),
  data.frame(family = "spaghetti", proc = "emlDrawSpaghettiPlot",
             says = "NOTE: Spaghetti plot — no usable value; empty axes drawn."),
  data.frame(family = "bar",       proc = "emlDrawBarChart",
             says = "NOTE: Bar chart — no usable value; empty axes drawn."),
  data.frame(family = "violin",    proc = "emlDrawViolinPlot",
             says = "NOTE: Violin plot — no usable value; empty axes drawn."),
  data.frame(family = "box",       proc = "emlDrawBoxPlot",
             says = "NOTE: Box plot — no usable value; empty axes drawn."),
  data.frame(family = "gviolin",   proc = "emlDrawGroupedViolin",
             says = "NOTE: Grouped violin — no usable value; empty axes drawn."),
  data.frame(family = "gbox",      proc = "emlDrawGroupedBoxPlot",
             says = "NOTE: Grouped box plot — no usable value; empty axes drawn."),
  # The two that already carried a warning before D111 keep their own words.
  # The ruling was "keep the existing text", so these are pinned as they are.
  data.frame(family = "scatter",   proc = "emlDrawScatterPlot",
             says = "WARNING: Fewer than 2 valid data points for scatter plot."),
  data.frame(family = "hist",      proc = "emlDrawHistogram",
             says = "WARNING: No valid data for histogram."),
  stringsAsFactors = FALSE)

ten$case <- paste0("empty_", ten$family)

# WHAT THIS FILE COVERS, declared for validate/coverage.R (§19). The ten
# empty frames and nothing else -- the other 29 stress cases are v36's, and
# saying so here is what lets the coverage pass tell "deliberately scoped"
# apart from "nobody is looking". Claimed from ten$case itself, so a case
# dropped from the fixture above stops being claimed in the same edit.
eml_claim("v27", "stress_out", ten$case)

# The set itself is an assertion. Ten Table-consuming draw procedures, ten
# empty cases; if a procedure is added or a case deleted, this is where it
# surfaces rather than in a quietly smaller pass count.
check("v27", "one empty case per Table-consuming draw procedure",
      nrow(ten), 10, tol = 0)
check("v27", "no duplicate family key", length(unique(ten$family)), 10, tol = 0)

draw_src <- readLines(draw_p, warn = FALSE)

# ---------------------------------------------------------------------------
# Static reading of the source: nobody may jump past their own Axes:.
#
# Praat's `goto` is unconditional and forward jumps are unrestricted, so a
# guard written as `goto <end>` silently skips every drawing command between
# it and the label -- which is exactly how the histogram came to write a blank
# page. Rather than re-verify that one procedure, assert the general property
# over the whole library: no executable goto, no label, in any of it.
#
# Comments are stripped first: the histogram's fix is DOCUMENTED with the word
# goto in prose, and a naive grep would fail on its own changelog.
# ---------------------------------------------------------------------------
code_only <- sub("[#;!].*$", "", draw_src)          # strip comments
code_only <- trimws(code_only)
n_goto  <- sum(grepl("(^|[^[:alnum:]_.])goto[[:space:]]+[[:alnum:]_]", code_only))
n_label <- sum(grepl("^label[[:space:]]+[[:alnum:]_]", code_only))
check("v27", "no goto anywhere in the draw library", n_goto, 0, tol = 0)
check("v27", "no jump label anywhere in the draw library", n_label, 0, tol = 0)

# Per procedure: it exists, it calls Axes:, and it contains no goto of its own.
# The body is everything between `procedure <name>` and the next `endproc`.
proc_starts <- grep("^procedure[[:space:]]+", draw_src)
proc_names  <- sub("^procedure[[:space:]]+([A-Za-z0-9_]+).*$", "\\1",
                   draw_src[proc_starts])
endprocs    <- grep("^endproc[[:space:]]*$", draw_src)

for (i in seq_len(nrow(ten))) {
  nm  <- ten$proc[i]
  lab <- sprintf("%s [%s]", nm, ten$case[i])

  hit <- which(proc_names == nm)
  if (!check_true("v27", paste(lab, "procedure defined once"), length(hit) == 1L))
      next
  from <- proc_starts[hit]
  to   <- endprocs[endprocs > from][1]
  if (!check_true("v27", paste(lab, "procedure body is closed"), !is.na(to)))
      next
  body <- code_only[from:to]

  # Every one of the ten owns an Axes: call. That is the statement the blank
  # page skipped, so it is the statement whose presence is worth pinning.
  check_true("v27", paste(lab, "calls Axes: itself"),
             any(grepl("^Axes:[[:space:]]", body)))
  check("v27", paste(lab, "contains no goto"),
        sum(grepl("(^|[^[:alnum:]_.])goto[[:space:]]+[[:alnum:]_]", body)),
        0, tol = 0)

  # The stress case that exercises it must exist and must call it. A case file
  # that drifted onto a different procedure would still render a figure, and
  # every measurement below would still pass, while testing nothing.
  cp <- file.path(cases_dir, paste0(ten$case[i], ".praat"))
  if (!check_true("v27", paste(lab, "stress case file present"), file.exists(cp)))
      next
  csrc <- readLines(cp, warn = FALSE)
  check_true("v27", paste(lab, "stress case calls this procedure"),
             any(grepl(paste0("@", nm, ":"), csrc, fixed = TRUE)))
  # An empty case must hand the procedure a table with nothing in it. Pinned
  # so the case cannot be "fixed" by giving it data when it starts failing.
  check_true("v27", paste(lab, "stress case builds a 0-row table"),
             any(grepl("Create Table with column names:[^,]*,[[:space:]]*0[[:space:]]*,",
                       csrc)))
}

# ---------------------------------------------------------------------------
# The rendered evidence, case by case.
# ---------------------------------------------------------------------------
m <- match(ten$case, res$case)
check_true("v27", "driver ran every empty case", !anyNA(m))

for (i in seq_len(nrow(ten))) {
  cs  <- ten$case[i]
  lab <- sprintf("%s [%s]", cs, ten$proc[i])
  j   <- m[i]
  if (is.na(j)) {
      check_true("v27", paste(lab, "row in RESULTS.tsv"), FALSE)
      next
  }

  png_p <- file.path(out_dir, paste0(cs, ".png"))
  log_p <- file.path(out_dir, paste0(cs, ".log"))
  check_true("v27", paste(lab, "figure written"),
             file.exists(png_p) && file.info(png_p)$size > 0)
  if (!check_true("v27", paste(lab, "log written"), file.exists(log_p))) next

  # The driver must not have caught a script error. NO_FIGURE and
  # DREW_THEN_FAILED both mean the empty table killed the procedure, which is
  # the pre-D111 failure mode for anything that handed undefined limits to
  # Axes:. BLANK_FRAME_ABS is what the driver reports for the empty_* cases
  # themselves -- they have no chrome-only baseline of their own to compare
  # against, so they fall through to the absolute ink rule and trip it BY
  # DESIGN. It is accepted here and the real judgement is made below.
  check_true("v27", paste(lab, "driver verdict is not a failure"),
             res$verdict[j] %in% c("OK", "BLANK_FRAME_ABS"))

  lg <- readLines(log_p, warn = FALSE)
  check_true("v27", paste(lab, "no Praat error in the transcript"),
             !any(grepl("^Error|not completed|Unknown variable", lg)))
  check_true("v27", paste(lab, "wrote the PNG it reported"),
             any(grepl("^SAVED ", lg)))

  # The disclosure, in the exact house wording. D111 required each procedure
  # to keep its existing warning or gain one in the same style; this is that
  # requirement, per procedure, as a string comparison.
  check_true("v27", paste(lab, "discloses the empty frame in house wording"),
             any(trimws(lg) == ten$says[i]))

  # A real frame. Zero chromatic pixels is the blank page D111 was filed for:
  # the histogram measured exactly 0 on a 2 160 000-pixel canvas, and one
  # unique colour in the whole file.
  check_true("v27", paste(lab, "chromatic pixel count is a real number"),
             is.finite(res$chrom[j]))
  check_true("v27", paste(lab, "frame is not a blank page (chromatic px > 0)"),
             isTRUE(res$chrom[j] > 0))
  check_true("v27", paste(lab, "frame carries ink"),
             isTRUE(is.finite(res$ink[j]) && res$ink[j] > 0))

  # ...and an EMPTY one. Every populated case in the same family must score
  # far higher, which is what rules out the opposite regression: an "empty"
  # case that quietly started drawing something. The tightest real margin in
  # the suite is violin_n1 at about +15% over empty_violin -- a single tick
  # mark -- so this is asserted as a strict inequality and not as a ratio.
  sib <- res[grepl(paste0("^", ten$family[i], "_"), res$case) &
             res$case != cs & is.finite(res$chrom), ]
  if (nrow(sib) > 0) {
    check_true("v27", paste(lab, "empty scores below every populated sibling"),
               all(sib$chrom > res$chrom[j]))
  }
}

# ---------------------------------------------------------------------------
# Cross-family agreement. The ten empty frames must be recognisably the same
# object. Measured 7 Aug 2026 at 1800x1200: 4609 (violin, box, gviolin, gbox)
# to 6969 (ts, tsci), a spread of 1.51x driven entirely by whether the x-axis
# prints tick numbers. A blank page pulls the minimum to 0 and the ratio to
# infinity, which is how the histogram would fail this.
# ---------------------------------------------------------------------------
#
# These four checks are deliberately UNGUARDED. An earlier draft wrapped them
# in `if (min(ec) > 0)`, which meant the one input that must fail them -- a
# blank family, scoring 0 -- made them not run at all, and the red path came
# back with four FEWER checks instead of four failures. A comparison that
# opts out on bad input is not a comparison. Non-finite and zero are coerced
# to values that fail rather than to values that skip.
ec <- res$chrom[m[!is.na(m)]]
ei <- res$ink[m[!is.na(m)]]
check("v27", "all ten empty frames measured", sum(is.finite(ec)), 10, tol = 0)
ec[!is.finite(ec)] <- 0
ei[!is.finite(ei)] <- 0

check_true("v27", "no family's empty frame is more than 2x another's",
           length(ec) > 0 && min(ec) > 0 && max(ec) / min(ec) <= 2)
# Ink is the cruder measure but it is the one that is comparable across
# themes, and it brackets the whole set inside a single percentage point.
check_true("v27", "every empty frame's ink lies in 0.4%-1.6%",
           length(ei) > 0 && all(ei >= 0.4 & ei <= 1.6))
check_true("v27", "ink spread across families is under 0.5 pp",
           length(ei) > 0 && (max(ei) - min(ei)) < 0.5)
# No family may be an outlier against the others' median. Stated separately
# from the ratio because a single blank family would drag the ratio without
# necessarily being visible in a min/max summary once more families exist.
med <- if (length(ec)) median(ec) else 0
check_true("v27", "no family deviates more than 60% from the median frame",
           med > 0 && all(abs(ec - med) / med <= 0.6))

# The driver must not have failed anything else while producing this evidence;
# a green D111 verdict on a run that broke six other figures is not a green
# run. Read from the same TSV so the two cannot disagree.
bad <- res[!res$verdict %in% c("OK", "BLANK_FRAME_ABS"), ]
check("v27", "no stress case failed to draw", nrow(bad), 0, tol = 0)

if (!exists("EML_SUITE")) { eml_report("v27 empty-frame uniformity (D111)"); eml_exit() }
