# ============================================================================
# v29_figure_disclosure.R -- what the ten Table-consuming draw procedures say
#                            about what they did to the data, and WHERE.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# The author's ruling, 7 Aug 2026: "Let's draw the image as the image unless
# someone asks to annotate." Three channels, one rule each.
#
#   Info window   ALWAYS. Every disclosure, unconditionally.
#   The figure    ONLY when the user ticked Annotate, and through the
#                 existing annotation block.
#   emlSubtitle$  NEVER. It is the user's field: the graphs form asks for it
#                 ("Subtitle") and persists it to config.
#
# Three defects, one shape -- a good disclosure written for one chart and
# never propagated:
#
#   1. @emlDrawTimeSeries appended " | Mean per time point" to emlSubtitle$
#      and @emlDrawBarChart appended an error-bar caption to it. Both saved
#      and restored the global, so it was never permanently corrupted, but
#      the DRAWN figure carried the user's own words with a machine tail
#      after " | ", whether or not Annotate was ticked.
#   2. Only @emlDrawViolinPlot and @emlDrawBoxPlot disclosed dropped rows.
#      Measured 7 Aug 2026 on a 20-row table with 6 undefined values:
#      @emlDrawHistogram printed "Histogram: 10 bins, bin width = 1.8000 /
#      Groups: 1" and nothing else, drawing 14 rows while the reader
#      believed 20.
#   3. Four procedures plot a MEAN rather than raw values; one said so.
#
# THE OVER-CAP HALF (added 7 Aug 2026, second pass). The disclosure work above
# turned up three more of the same shape, each one a procedure hitting a limit
# it holds and not mentioning it. They are driven by
# harness/disclosure/overcap.praat and asserted in the section at the foot of
# this file:
#
#   4. @emlDrawScatterPlot's grouped path wrote three annotation lines per
#      group straight into annotBlockN, past @emlDisclose and past its
#      20-line budget. Eight groups = 24 lines and the box left the figure.
#   5. @emlMeasureBarData seeded a missing group's mean to 0 instead of
#      undefined, so a group with nothing in it drew the same bar a measured
#      zero draws, and @emlDrawBarChart's guards against exactly that were
#      dead code.
#   6. The grouped violin and grouped box drop sub-groups past the cap and
#      said nothing, while the legend went on listing the one that was not
#      drawn.
#
# THE STYLE HALF (added 7 Aug 2026, third pass). Defect 6 was closed by making
# the drop audible, and the cap was left at ten because the palette declared
# ten fill/line pairs. IT DID NOT HAVE TEN. Slots 9 and 10 were literal
# duplicates of 1 and 2 -- .fill$[9] and .fill$[1] both "{0.70, 0.83, 0.91}",
# .fill$[10] and .fill$[2] both "{0.97, 0.89, 0.70}", the line colours
# duplicating identically -- and the cycling rule above ten was `mod 8`, which
# says outright that it was an eight-colour palette. So a nine- or
# ten-sub-group figure drew two PAIRS of sub-groups in indistinguishable
# colours, on the figure and in the legend, silently (D127). That is worse
# than the drop closed as defect 6: a reader could not tell two violins apart,
# rather than merely missing one, and nothing said so.
#
# The palette now carries a second dimension -- 8 hues x 3 fill patterns
# (solid, diagonal hatch, dots) = 24 distinguishable styles -- and the cap is
# 24, on the author's ruling of 7 Aug 2026 that the boundary be set "in excess
# of what we think is reasonable" because a user may render very wide.
#
# THE CHECK THAT WOULD HAVE CAUGHT D127. Everything that read the palette
# TABLE agreed there were ten pairs, because there were ten assignments. The
# only check that can answer "can a reader tell these two apart" is one that
# reads the RENDERED IMAGE. harness/patterns/run.sh renders each of the 24
# styles as its own figure -- as a violin, as a box, and as a legend swatch,
# in colour and in greyscale, 144 figures -- and measures each mark's pixels;
# the section at the foot of this file asserts on those measurements. Fed the
# old palette it fails on the very first pair it reaches, because slot 9 and
# slot 1 render identically.
#
# THE MARKER HALF (added 8 Aug 2026, fourth pass). The fill pattern fixed the
# marks that have an AREA. Scatter, line chart, spaghetti and time series draw
# dots and lines, which do not, so all four went on cycling eight hues in
# silence above eight groups -- D127 unfixed, in four more chart types. On the
# author's ruling of 7 Aug 2026 their second dimension is the marker SHAPE:
# circle, square, triangle, on the same slot arithmetic, giving the same 24.
# Native Praat primitives, not sprites; the reasoning, and why the sprite
# array cannot carry it, is in the block comment above @emlDrawMarker and is
# checked in the marker section at the foot of this file. The 24 marker styles
# are asserted pairwise distinguishable FROM THE RENDERED IMAGE, and the
# legend key is required to show the shape and not merely the hue.
#
# WHAT GREYSCALE ACHIEVES: 24, the same as colour. The B/W branch used to
# declare ten fills between 0.82 and 0.96 -- fifteen thousandths of luminance
# apart at the closest pair. v1.23 replaced that with eight greys from 0.90
# down to 0.25, measured 0.090 apart on the renders; v1.24 widens it again, on
# the author's ruling of 7 Aug 2026 that the range be wide "across the entire
# potential palette", to 0.94 down to 0.10 -- a span of 0.84, and 0.1176 apart
# measured on the renders. What had been holding it narrow was not the eye but
# the stroke, which was derived from the fill as fill - 0.30 and collapsed
# below a fill of 0.30; the two ramps are now independent and the mark's ink
# flips to white or black when it would otherwise disappear into its own fill.
# Colour is unchanged at 0.078, and styles with different patterns are
# separated by the pattern whatever their colours do. The full argument, the
# before and after, and the hatch-at-both-ends check are in the greyscale
# section at the foot of this file.
#
# WHERE READABILITY ACTUALLY BREAKS DOWN -- rendered and looked at, 7 Aug
# 2026, three categories on a 12 x 7 inch figure:
#     8 sub-groups   comfortable; solid hues only, nothing to learn
#    12 sub-groups   comfortable; the hatch band is unmistakable
#    16 sub-groups   readable, but the sub-violins are ~0.10" wide and the
#                    pattern is carried by two or three stripes
#    24 sub-groups   the LEGEND is still perfectly legible and the styles are
#                    still distinct under magnification, but the violins are
#                    ~0.07" wide and 24 x nCats marks crowd the panel; the
#                    figure has to be printed large before a reader can match
#                    a violin to its key
# On the DEFAULT 6 x 4 inch figure the practical limit is nearer 10-12. The
# cap is 24 anyway, deliberately: that is the author's call, and the drawing
# code is correct at every count up to it.
#
# The emlSubtitle$ ban is also widened here from one file to all of
# plugin/graphs/; see the three rules at that check for why it cannot simply
# be "no file assigns to it".
#
#     harness/disclosure/run.sh         regenerate the inputs to this script
#     harness/patterns/run.sh           regenerate the fill-pattern renders
#     harness/markers/run.sh            regenerate the point-marker renders
#     Rscript validate/v29_figure_disclosure.R
#
# Input:  <disc>/RESULTS.tsv    chart, annotate, dirty, verdict, info, fig
#         <disc>/OVERCAP.tsv    case, annotate, verdict, info, fig, signature
#         harness/patterns/out/STYLES.tsv   one row per rendered fill style
#         harness/markers/out/MARKERS.tsv   one row per rendered marker style
#         harness/markers/out/LOOKS.tsv     the real-figure renders
#         <disc>/<case>.log     the Info-window transcript AND the ledger
#         <disc>/<case>.png     the rendered figure
#         plugin/graphs/*.praat                     read here, statically
#
#   <disc> is $EML_DISCLOSURE_DIR, default harness/disclosure/out. A missing
#   artefact is a HARD STOP, not a skip, for the reason v27 gives: "the
#   driver never ran this" is precisely the failure a silently shrinking
#   suite would hide.
#
# HOW THE FIGURE CHANNEL IS OBSERVED
# ----------------------------------
# Base R cannot decode a PNG without a package, and v27's chromatic-pixel
# trick answers "is there data in this frame", not "is there a sentence in
# the corner". So the figure channel is read from the DISCLOSURE LEDGER
# instead: @emlDisclose records every line it places on the figure in
# emlDiscloseFigN / emlDiscloseFigLabel$[], the harness case prints them as
# LEDGER and FIGLINE records, and this script reads those. That is driving
# the code, not grepping it: the counts come from a real render of a real
# table through the real procedure, and a procedure that stopped placing the
# line would report fig = 0 here.
#
# The wording and the COUNTS are read from the Info transcript, which is the
# channel the ruling makes unconditional.
#
# WHY "A CLEAN RUN SAYS NOTHING" IS ASSERTED PER FAMILY
# -----------------------------------------------------
# For the seven procedures that draw the observations themselves -- violin,
# box, grouped violin, grouped box, spaghetti, scatter, histogram -- a clean
# table gives a figure with NOTHING to confess, and this script requires
# exactly zero disclosures on both channels. That is the check that keeps
# normal figures untouched.
#
# The other three are the point of defect 3. A bar chart draws group means
# and a time series draws a mean per time point whether or not anything is
# missing, so on clean repeated-measures data they must still say so -- a
# silent bar chart of means is the defect, not the baseline. What they must
# NOT emit on clean data is a dropped-row disclosure, and that is asserted
# for all ten.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

disc_dir <- Sys.getenv("EML_DISCLOSURE_DIR",
                       unset = repo_path("harness", "disclosure", "out"))
res_p    <- file.path(disc_dir, "RESULTS.tsv")
draw_p   <- repo_path("plugin", "graphs", "eml-draw-procedures.praat")
case_p   <- repo_path("harness", "disclosure", "case.praat")

if (!file.exists(res_p))
    stop(sprintf("v29: %s missing -- run harness/disclosure/run.sh first", res_p))
if (!file.exists(case_p))
    stop(sprintf("v29: %s missing", case_p))

res <- read.delim(res_p, header = FALSE, stringsAsFactors = FALSE,
                  col.names = c("chart", "annotate", "dirty", "verdict",
                                "info", "fig"))
res$annotate <- suppressWarnings(as.integer(res$annotate))
res$dirty    <- suppressWarnings(as.integer(res$dirty))
res$info     <- suppressWarnings(as.integer(res$info))
res$fig      <- suppressWarnings(as.integer(res$fig))

# ---------------------------------------------------------------------------
# The ten. `chart` is the harness key; `proc` is the procedure it drives;
# `name` is the prose name the procedure prefixes its Info lines with --
# pinned as an exact string, so a procedure that quietly renames itself
# fails here rather than drifting apart from its nine siblings.
#
# `aggregates` marks the procedures that plot a summary rather than the
# observations. THE LINE CHART IS NOT A SEPARATE PROCEDURE: graph type 5 in
# eml-graphs-form.praat dispatches to @emlDrawTimeSeriesCI when the CI toggle
# is on and to @emlDrawTimeSeries when it is off. There is no
# @emlDrawLineChart; the four that plot a mean are time series, time series
# with CI, bar chart, and the line chart, which is the first of those.
# ---------------------------------------------------------------------------
ten <- rbind(
  data.frame(chart = "ts",        proc = "emlDrawTimeSeries",
             name = "Time series",           aggregates = TRUE),
  data.frame(chart = "tsci",      proc = "emlDrawTimeSeriesCI",
             name = "Time series (with CI)", aggregates = TRUE),
  data.frame(chart = "bar",       proc = "emlDrawBarChart",
             name = "Bar chart",             aggregates = TRUE),
  data.frame(chart = "spaghetti", proc = "emlDrawSpaghettiPlot",
             name = "Spaghetti plot",        aggregates = FALSE),
  data.frame(chart = "violin",    proc = "emlDrawViolinPlot",
             name = "Violin plot",           aggregates = FALSE),
  data.frame(chart = "scatter",   proc = "emlDrawScatterPlot",
             name = "Scatter plot",          aggregates = FALSE),
  data.frame(chart = "box",       proc = "emlDrawBoxPlot",
             name = "Box plot",              aggregates = FALSE),
  data.frame(chart = "hist",      proc = "emlDrawHistogram",
             name = "Histogram",             aggregates = FALSE),
  data.frame(chart = "gviolin",   proc = "emlDrawGroupedViolin",
             name = "Grouped violin",        aggregates = FALSE),
  data.frame(chart = "gbox",      proc = "emlDrawGroupedBoxPlot",
             name = "Grouped box plot",      aggregates = FALSE),
  stringsAsFactors = FALSE)

# The fixture blanks six of its twenty rows. Every one of the ten must
# report SIX -- not "some", not "a warning", six -- which is what makes this
# a test of the counter and not of the sentence.
N_BLANK <- 6L
SKIP_LINE <- sprintf("%d row(s) skipped (missing or non-numeric value).",
                     N_BLANK)
SENTINEL <- "SENTINEL-SUBTITLE"

check("v29", "one case per Table-consuming draw procedure",
      nrow(ten), 10, tol = 0)
check("v29", "no duplicate chart key", length(unique(ten$chart)), 10, tol = 0)
check("v29", "no duplicate procedure", length(unique(ten$proc)), 10, tol = 0)
check("v29", "four procedures plot a mean (line chart = time series)",
      sum(ten$aggregates) + 1L, 4, tol = 0)

# ---------------------------------------------------------------------------
# STATIC READING OF THE SOURCE
#
# The construct is how the defect got in, so the construct is banned outright,
# the way v27 statically bans `goto` from the same file. An assignment to
# emlSubtitle$ is legal Praat, it type-checks, it round-trips through a save
# and restore, and it still puts words the user did not write onto the
# figure. No amount of driving the code catches a NEW procedure adopting the
# idiom; reading the file does.
#
# Comments are stripped first, for the reason v27 gives about `goto`: this
# defect is DOCUMENTED in the file's own changelog and in the block comment
# on @emlDisclose, and a naive grep would fail on the fix's own description.
# ---------------------------------------------------------------------------
draw_src  <- readLines(draw_p, warn = FALSE)
code_only <- trimws(sub("[#;!].*$", "", draw_src))

# Praat continues a statement onto the next line with a leading "...", and
# this file uses it heavily -- a disclosure typically reads
#
#     @emlDisclose: string$ (.nSkippedRows)
#     ... + " row(s) skipped (missing or non-numeric value).", ""
#
# so the line carrying the sentence and the line carrying the call are
# different lines. Any assertion about a whole STATEMENT has to fold them
# first; an earlier draft did not, and reported ten false failures.
fold_continuations <- function(x) {
  out <- character(0)
  for (ln in x) {
    if (startsWith(ln, "...") && length(out))
      out[length(out)] <- paste(out[length(out)], sub("^\\.\\.\\.", "", ln))
    else
      out <- c(out, ln)
  }
  out
}
code_stmt <- fold_continuations(code_only)

SUB_ASSIGN_RE <- "(^|[^[:alnum:]_.])emlSubtitle\\$[[:space:]]*=[^=]"

n_sub_assign <- sum(grepl(SUB_ASSIGN_RE, code_stmt))
check("v29", "no draw procedure assigns to emlSubtitle$ (the user's field)",
      n_sub_assign, 0, tol = 0)

# ...AND THE SAME BAN OVER THE WHOLE GRAPHS DIRECTORY.
#
# Widened 7 Aug 2026. The check above reads eml-draw-procedures.praat and
# nothing else, which was right when that was the only file the defect had
# been found in and wrong the moment a second file drew a figure. The ruling
# is about the FIELD, not about one file: emlSubtitle$ is what the user typed
# into the graphs form's "Subtitle" box and what the form persists to config,
# and any file in plugin/graphs/ that appends to it puts words on the figure
# that the user did not write and cannot remove. eml-draw-qq.praat, the QQ
# family's own draw file, is exactly the kind of sibling that inherits an
# idiom without inheriting the ruling: it carried the same hijack until today.
#
# THE FIELD HAS TO BE WRITABLE BY SOMEBODY. Four assignments in this
# directory are not the defect and must not be broken by the ban:
# @emlInitializeDrawingDefaults declares the default (""), and eml-graphs-form.praat
# — the form that OWNS the field — sets it three times from the user's own
# form input and from config. A ban that forbade those would forbid the user
# having a subtitle at all. So the ban is stated as three rules, two of which
# admit no exemption whatever:
#
#   A. No SELF-REFERENTIAL assignment, anywhere. "emlSubtitle$ = emlSubtitle$
#      + ..." is the hijack verbatim -- @emlDrawTimeSeries appended
#      " | Mean per time point" that way, and @emlDrawBarChart an error-bar
#      caption. No legitimate write needs to read the field it is setting.
#   B. No assignment inside a DRAWING procedure (@emlDraw*), anywhere. A
#      procedure whose job is to render a figure has no business writing the
#      user's caption, whatever it writes.
#   C. The inventory of assignment sites is PINNED by file and by enclosing
#      procedure. A new one anywhere in plugin/graphs/ fails here and has to
#      be argued for in this list rather than merged in silence.
#
# The scan is ANCHORED at the start of the statement, unlike the draw-file
# check above. Praat spells equality "=" as well, and @emlDrawTitle in
# eml-graph-procedures.praat legitimately tests "if .title$ = "" and
# emlSubtitle$ = """; an unanchored scan over the whole directory reports that
# comparison as an assignment. Anchoring loses nothing, because a Praat
# assignment is always the first token of its statement.
graphs_dir <- repo_path("plugin", "graphs")
graphs_files <- sort(list.files(graphs_dir, pattern = "\\.praat$",
                                full.names = TRUE))
check_true("v29", "plugin/graphs/ holds the files this ban covers",
           length(graphs_files) >= 4)

# One row per assignment site: file, enclosing procedure (or "<top level>"),
# source line, and the right-hand side.
sub_sites <- data.frame(file = character(0), proc = character(0),
                        line = integer(0), rhs = character(0),
                        stringsAsFactors = FALSE)
for (gf in graphs_files) {
  g_src  <- readLines(gf, warn = FALSE)
  g_code <- trimws(sub("[#;!].*$", "", g_src))
  # Enclosing procedure per SOURCE line, walked before folding so the
  # continuation lines inherit their statement's scope.
  encl <- character(length(g_code))
  cur  <- "<top level>"
  for (i in seq_along(g_code)) {
    if (grepl("^procedure[[:space:]]+", g_code[i]))
      cur <- sub("^procedure[[:space:]]+([A-Za-z0-9_]+).*$", "\\1", g_code[i])
    encl[i] <- cur
    if (grepl("^endproc[[:space:]]*$", g_code[i])) cur <- "<top level>"
  }
  # Fold for the same reason as above, keeping the source line each folded
  # statement started on.
  starts <- which(!startsWith(g_code, "..."))
  g_stmt <- fold_continuations(g_code)
  hits   <- which(grepl("^emlSubtitle\\$[[:space:]]*=[^=]", g_stmt))
  for (h in hits) {
    ln <- if (h <= length(starts)) starts[h] else NA_integer_
    sub_sites <- rbind(sub_sites, data.frame(
      file = basename(gf),
      proc = if (is.na(ln)) "<unknown>" else encl[ln],
      line = ln,
      rhs  = trimws(sub("^emlSubtitle\\$[[:space:]]*=", "", g_stmt[h])),
      stringsAsFactors = FALSE))
  }
}

# Rule A -- no exemption.
selfref <- grepl("emlSubtitle\\$", sub_sites$rhs)
check("v29",
      sprintf("plugin/graphs/: nothing appends to emlSubtitle$ [%s]",
              if (any(selfref))
                  paste(sprintf("%s:%d", sub_sites$file[selfref],
                                sub_sites$line[selfref]), collapse = ", ")
              else "clean"),
      sum(selfref), 0, tol = 0)

# Rule B -- no exemption. This is the one eml-draw-qq.praat was failing.
in_draw <- grepl("^emlDraw", sub_sites$proc)
check("v29",
      sprintf("plugin/graphs/: no @emlDraw* procedure assigns emlSubtitle$ [%s]",
              if (any(in_draw))
                  paste(sprintf("%s:%d in @%s", sub_sites$file[in_draw],
                                sub_sites$line[in_draw],
                                sub_sites$proc[in_draw]), collapse = ", ")
              else "clean"),
      sum(in_draw), 0, tol = 0)

# Rule C -- the pinned inventory. Sorted so the comparison does not depend on
# where in a file the assignments happen to sit.
SUB_ALLOWED <- sort(c(
  # The declared default. @emlInitializeDrawingDefaults seeds every drawing global,
  # and an unset emlSubtitle$ makes @emlDrawTitle fail on "Unknown variable".
  "eml-graph-procedures.praat @emlInitializeDrawingDefaults",
  # The form owns the field: from config when the advanced page is not shown,
  # and from the user's own "Subtitle" box when it is. Three sites, all in
  # @emlGraphsWorkflow, none of them a drawing procedure.
  "eml-graphs-form.praat @emlGraphsWorkflow",
  "eml-graphs-form.praat @emlGraphsWorkflow",
  "eml-graphs-form.praat @emlGraphsWorkflow"))
sub_found <- sort(sprintf("%s %s%s", sub_sites$file,
                          ifelse(sub_sites$proc == "<top level>", "", "@"),
                          sub_sites$proc))
check_true("v29",
           sprintf("plugin/graphs/: emlSubtitle$ writers are the four pinned sites [found: %s]",
                   if (length(sub_found)) paste(sub_found, collapse = " | ")
                   else "none"),
           identical(sub_found, SUB_ALLOWED))
# The two known sites, named so a reviewer can see what is being excluded:
# @emlDrawTimeSeries wrote " | Mean per time point" and @emlDrawBarChart an
# error-bar caption. Neither string may survive anywhere in the code either.
check("v29", "the 'Mean per time point' caption is gone from the code",
      sum(grepl("Mean per time point", code_stmt, fixed = TRUE)), 0, tol = 0)

# The helpers exist and are defined once each.
proc_starts <- grep("^procedure[[:space:]]+", draw_src)
proc_names  <- sub("^procedure[[:space:]]+([A-Za-z0-9_]+).*$", "\\1",
                   draw_src[proc_starts])
endprocs    <- grep("^endproc[[:space:]]*$", draw_src)
for (h in c("emlDiscloseBegin", "emlDisclose", "emlDiscloseEnd"))
    check("v29", sprintf("@%s defined exactly once", h),
          sum(proc_names == h), 1, tol = 0)

# The 20-line budget @emlDrawAnnotationBlock documents and does not enforce.
# @emlDisclose enforces it; if that guard is deleted the box can grow taller
# than the panel and hide the data it is about.
check_true("v29", "@emlDisclose caps the block at 20 lines",
           any(grepl("annotBlockN[[:space:]]*<[[:space:]]*20", code_stmt)))

# @emlDiscloseEnd must take the legend's corner as an argument and must
# consult the form's bracket/omnibus state. Both are how it keeps the
# disclosure box off the two boxes it cannot move.
end_i <- which(proc_names == "emlDiscloseEnd")
if (check_true("v29", "@emlDiscloseEnd body located", length(end_i) == 1L)) {
  ef <- proc_starts[end_i]
  et <- endprocs[endprocs > ef][1]
  end_body <- fold_continuations(code_only[ef:et])
  check_true("v29", "@emlDiscloseEnd takes the legend's corner",
             any(grepl("\\.legendCorner\\$", end_body)))
  check_true("v29", "@emlDiscloseEnd reads annotBracketN (the form's corner)",
             any(grepl("annotBracketN", end_body, fixed = TRUE)))
  check_true("v29", "@emlDiscloseEnd still lets @emlPlaceElements choose",
             any(grepl("@emlPlaceElements:", end_body, fixed = TRUE)))
}

# Per procedure, statically.
for (i in seq_len(nrow(ten))) {
  nm  <- ten$proc[i]
  lab <- sprintf("%s [%s]", nm, ten$chart[i])
  hit <- which(proc_names == nm)
  if (!check_true("v29", paste(lab, "procedure defined once"),
                  length(hit) == 1L)) next
  from <- proc_starts[hit]
  to   <- endprocs[endprocs > from][1]
  if (!check_true("v29", paste(lab, "procedure body is closed"), !is.na(to)))
      next
  body <- fold_continuations(code_only[from:to])

  check_true("v29", paste(lab, "opens a disclosure batch"),
             any(grepl("@emlDiscloseBegin:", body, fixed = TRUE)))
  check_true("v29", paste(lab, "makes at least one disclosure"),
             any(grepl("@emlDisclose:", body, fixed = TRUE)))
  check("v29", paste(lab, "does not assign to emlSubtitle$"),
        sum(grepl("(^|[^[:alnum:]_.])emlSubtitle\\$[[:space:]]*=[^=]", body)),
        0, tol = 0)

  # Every dropped-row sentence in the library must go through @emlDisclose.
  # A bare appendInfoLine would reach the Info window and never the figure,
  # which is precisely the half-fix this ruling replaces.
  bad <- body[grepl("row(s) skipped", body, fixed = TRUE) &
              !grepl("@emlDisclose", body, fixed = TRUE)]
  check("v29", paste(lab, "routes its dropped-row line through @emlDisclose"),
        length(bad), 0, tol = 0)

  # Nine of the ten render the block themselves. @emlDrawScatterPlot is the
  # documented exception: it already owns an annotation block and already
  # renders it, so its disclosures join the correlation and formula lines in
  # the SAME box and a second render call would draw a second box.
  if (nm == "emlDrawScatterPlot") {
    check("v29", paste(lab, "does NOT call @emlDiscloseEnd (owns its block)"),
          sum(grepl("@emlDiscloseEnd:", body, fixed = TRUE)), 0, tol = 0)
    check_true("v29", paste(lab, "renders the block it owns"),
               any(grepl("@emlDrawAnnotationBlock:", body, fixed = TRUE)))
  } else {
    check_true("v29", paste(lab, "renders its disclosure block"),
               any(grepl("@emlDiscloseEnd:", body, fixed = TRUE)))
  }
}

# The harness case must set the sentinel and must drive all ten, or the
# driven half below is measuring a fixture that drifted off the target.
case_src <- readLines(case_p, warn = FALSE)
check_true("v29", "harness case sets the emlSubtitle$ sentinel",
           any(grepl(sprintf('emlSubtitle\\$ = "%s"', SENTINEL), case_src)))
for (i in seq_len(nrow(ten)))
    check_true("v29", sprintf("harness case calls @%s", ten$proc[i]),
               any(grepl(paste0("@", ten$proc[i], ":"), case_src, fixed = TRUE)))

# ---------------------------------------------------------------------------
# THE DRIVEN EVIDENCE. Ten charts x {Annotate off, on} x {clean, six blanks}.
# ---------------------------------------------------------------------------
check("v29", "driver ran forty cases", nrow(res), 40, tol = 0)

for (i in seq_len(nrow(ten))) {
 for (ann in c(0L, 1L)) {
  for (dirty in c(0L, 1L)) {

    ch   <- ten$chart[i]
    nm   <- ten$name[i]
    case <- sprintf("%s_a%d_d%d", ch, ann, dirty)
    lab  <- sprintf("%s [%s]", case, ten$proc[i])
    j    <- which(res$chart == ch & res$annotate == ann & res$dirty == dirty)

    if (!check_true("v29", paste(lab, "row in RESULTS.tsv"), length(j) == 1L))
        next

    png_p <- file.path(disc_dir, paste0(case, ".png"))
    log_p <- file.path(disc_dir, paste0(case, ".log"))
    check_true("v29", paste(lab, "figure written"),
               file.exists(png_p) && file.info(png_p)$size > 0)
    check_true("v29", paste(lab, "driver verdict is OK"),
               identical(res$verdict[j], "OK"))
    if (!check_true("v29", paste(lab, "log written"), file.exists(log_p)))
        next
    lg <- readLines(log_p, warn = FALSE)
    check_true("v29", paste(lab, "no Praat error in the transcript"),
               !any(grepl("^Error|not completed|Unknown variable", lg)))
    check_true("v29", paste(lab, "wrote the PNG it reported"),
               any(grepl("^SAVED ", lg)))

    # --- emlSubtitle$ is the user's. Set to a sentinel before the call,
    #     read back after. This is the check that stops the recurrence: a
    #     save-and-restore hijack would pass every count above and fail here
    #     only if it forgot to restore, so the sentinel is checked on all
    #     forty runs and the STATIC ban above covers the restoring kind.
    check_true("v29", paste(lab, "emlSubtitle$ came back untouched"),
               any(lg == sprintf("SUBTITLE [%s]", SENTINEL)))
    check("v29", paste(lab, "emlSubtitle$ was not appended to"),
          sum(grepl("^SUBTITLE \\[.*\\|", lg)), 0, tol = 0)

    # --- The Info channel. Unconditional: it must not depend on Annotate.
    skip_full <- sprintf("%s: %s", nm, SKIP_LINE)
    n_skip <- sum(trimws(lg) == skip_full)
    if (dirty == 1L) {
      check("v29", paste(lab, "discloses SIX dropped rows, in house wording"),
            n_skip, 1, tol = 0)
    } else {
      check("v29", paste(lab, "clean data: no dropped-row disclosure"),
            sum(grepl("row(s) skipped", lg, fixed = TRUE)), 0, tol = 0)
    }

    # --- The figure channel. THE LOAD-BEARING DIRECTION IS "off".
    # @emlDrawScatterPlot's block was already drawn with no reference to
    # `annotate` -- verified 7 Aug 2026, annotate = 0 with
    # scatterShowFormula = 1 renders the formula box -- so "the block exists"
    # never meant "the user asked for it", and this is the assertion that
    # pins the ruling.
    fig <- res$fig[j]
    check_true("v29", paste(lab, "figure-line count is a real number"),
               is.finite(fig))
    if (ann == 0L) {
      check("v29", paste(lab, "ANNOTATE OFF: nothing on the figure"),
            fig, 0, tol = 0)
      check("v29", paste(lab, "ANNOTATE OFF: no FIGLINE recorded"),
            sum(grepl("^FIGLINE ", lg)), 0, tol = 0)
    } else {
      # With Annotate on, whatever went to the Info window goes on the
      # figure too -- the same lines, capped at the block's 20.
      check("v29", paste(lab, "ANNOTATE ON: figure carries every disclosure"),
            fig, min(res$info[j], 20L), tol = 0)
      check("v29", paste(lab, "ANNOTATE ON: FIGLINE count matches ledger"),
            sum(grepl("^FIGLINE ", lg)), fig, tol = 0)
      if (dirty == 1L)
          check_true("v29",
                     paste(lab, "the dropped-row line is ON THE FIGURE"),
                     any(grepl(paste0("^FIGLINE [0-9]+: ",
                                      gsub("([().\\\\])", "\\\\\\1", SKIP_LINE),
                                      "$"), lg)))
    }

    # --- Clean data leaves the seven raw-observation figures untouched.
    if (dirty == 0L && !ten$aggregates[i]) {
      check("v29", paste(lab, "clean data: no disclosure at all (Info)"),
            res$info[j], 0, tol = 0)
      check("v29", paste(lab, "clean data: no disclosure at all (figure)"),
            fig, 0, tol = 0)
    }
  }
 }
}

# ---------------------------------------------------------------------------
# DEFECT 3: the four that plot a mean must all say so, on clean data, where
# there is no missing value to hide behind. @emlDrawTimeSeries already did;
# @emlDrawTimeSeriesCI, @emlDrawBarChart and the line chart (= time series)
# did not. The sentence is asserted by its distinguishing phrase rather than
# in full, because the counts differ between the three and the advice tail
# is Info-only.
# ---------------------------------------------------------------------------
mean_says <- list(
  ts   = "Time series: Line shows the mean per time point.",
  tsci = "Time series (with CI): Line shows the mean; band shows the 95% CI.",
  bar  = "Bar chart: Bars show the group mean, not individual values.")

for (ch in names(mean_says)) {
  for (dirty in c(0L, 1L)) {
    case  <- sprintf("%s_a1_d%d", ch, dirty)
    log_p <- file.path(disc_dir, paste0(case, ".log"))
    if (!check_true("v29", paste(case, "log written"), file.exists(log_p)))
        next
    lg  <- readLines(log_p, warn = FALSE)
    lab <- sprintf("%s [%s]", case, ten$proc[ten$chart == ch])
    # The Info line begins with the sentence and continues with the count
    # and the advice, so it is matched as a prefix.
    check_true("v29", paste(lab, "says the figure plots a mean (Info)"),
               any(startsWith(trimws(lg), mean_says[[ch]])))
    # ...and the same sentence, alone, on the figure.
    check_true("v29", paste(lab, "says the figure plots a mean (figure)"),
               any(grepl("^FIGLINE [0-9]+: ", lg) &
                   endsWith(lg, sub("^[^:]+: ", "", mean_says[[ch]]))))
  }
}

# The two time-series procedures collapse the SAME table, so they must agree
# on how many observations that cost. They did not before v1.21: an undefined
# row inside a time point's run left @emlDrawTimeSeries flushing that point's
# mean at an undefined x, which both undercounted the collapse and drew
# nothing. Identical input, identical count, is the assertion that pins it.
collapsed <- function(ch, dirty) {
  lg <- readLines(file.path(disc_dir, sprintf("%s_a1_d%d.log", ch, dirty)),
                  warn = FALSE)
  m  <- regmatches(lg, regexpr("[0-9]+ repeated observation\\(s\\)", lg))
  m  <- m[nzchar(m)]
  if (!length(m)) return(NA_integer_)
  as.integer(sub(" .*$", "", m[1]))
}
for (dirty in c(0L, 1L)) {
  a <- collapsed("ts", dirty)
  b <- collapsed("tsci", dirty)
  check("v29",
        sprintf("ts and tsci collapse the same count (dirty = %d)", dirty),
        a, b, tol = 0)
  check_true("v29",
             sprintf("the collapse count is positive (dirty = %d)", dirty),
             isTRUE(a > 0))
}
# Clean: twenty rows over five time points = fifteen absorbed. Dirty: six
# rows gone, fourteen rows over five time points = nine absorbed. Pinned as
# arithmetic on the fixture, so a change to either the fixture or the
# collapse shows up here rather than as a quietly different number.
check("v29", "clean fixture: 20 rows - 5 time points = 15 absorbed",
      collapsed("ts", 0L), 15, tol = 0)
check("v29", "dirty fixture: 14 usable rows - 5 time points = 9 absorbed",
      collapsed("ts", 1L), 9, tol = 0)

# ---------------------------------------------------------------------------
# TWO BOXES, TWO CORNERS.
#
# On an annotated categorical figure the graphs form renders a SECOND
# floating box after the draw procedure returns -- its bracket comparisons
# and omnibus line -- and it does not consult @emlPlaceElements: it uses
# "bottom-right" when there are brackets and "top-right" when there are not.
# Drawn 7 Aug 2026 without a guard, an annotated violin plot with two
# significance brackets put BOTH boxes in the bottom-right corner and the
# Kruskal-Wallis line was painted straight over "6 row(s) skip...". Neither
# the Info transcript nor the ledger showed anything wrong: both boxes had
# the right contents and the right counts, and the figure was unreadable.
#
# harness/disclosure/probe_formpath.praat replays the form's sequence around
# a real @emlDrawViolinPlot call and records where each box landed.
# ---------------------------------------------------------------------------
fp_p <- file.path(disc_dir, "formpath.log")
if (check_true("v29", "form-path probe ran", file.exists(fp_p))) {
  fp <- readLines(fp_p, warn = FALSE)
  check_true("v29", "form-path probe: no Praat error",
             !any(grepl("^Error|not completed|Unknown variable", fp)))
  for (variant in c("brackets", "nobrackets")) {
    ln <- grep(sprintf("^FORMCORNER %s ", variant), fp, value = TRUE)
    if (!check_true("v29", paste("form-path probe recorded", variant),
                    length(ln) == 1L)) next
    disc <- sub("^.*disclosure=([a-z-]+) .*$", "\\1", ln)
    omni <- sub("^.*omnibus=([a-z-]+)$", "\\1", ln)
    check_true("v29", sprintf("form path [%s]: both corners named", variant),
               nzchar(disc) && nzchar(omni) && disc != ln && omni != ln)
    check_true("v29",
               sprintf("form path [%s]: disclosure and omnibus differ", variant),
               !identical(disc, omni))
  }
}

# ===========================================================================
# THE OVER-CAP HALF -- three limits a procedure holds, and what it says when
# it hits one. Driven by harness/disclosure/overcap.praat via run.sh; the
# artefacts are <disc>/oc_<case>_a<0|1>.{png,log} and <disc>/OVERCAP.tsv.
#
# The three defects share the shape the ten above shared: the procedure knew
# what it was doing and did not say so.
#
#   1. @emlDrawScatterPlot's grouped path writes three annotation lines PER
#      GROUP -- Pearson, Spearman, fitted formula -- straight into
#      annotBlockN, bypassing @emlDisclose and therefore its 20-line budget.
#      Measured 7 Aug 2026 at eight groups: annotBlockN = 24 and the box ran
#      from the top of the panel, across the x-axis, off the bottom edge of
#      the figure. The dropped-row disclosure that came after it was refused
#      by the budget and never appeared, so the figure that overflowed was
#      also the figure that stopped confessing.
#   2. @emlMeasureBarData seeded emlBarData_mean[] and emlBarData_error[] to
#      0, never undefined, so @emlDrawBarChart's "<> undefined" guards -- and
#      the .nSkippedBars / .nSkippedErrors counters behind them -- were dead
#      code. A group with no usable observation drew as a bar of height zero,
#      the same mark a measured zero draws, and an undefined error bar drew
#      no whisker in silence.
#   3. @emlDrawGroupedViolin and @emlDrawGroupedBoxPlot cap sub-groups,
#      correctly, at what the palette can draw distinguishably -- and the
#      dropped sub-group vanished with no message while the legend still
#      listed it. The cap was ten and is now 24; see the STYLE HALF note in
#      the header for why ten was the wrong number in both directions.
#
# WHAT THIS SECTION ASSERTS THAT A DISCLOSURE COUNT CANNOT
# --------------------------------------------------------
# For the bar chart, "a missing group is distinguishable from a measured
# zero" is a claim about the PICTURE, so it is measured on the picture:
# barmix and barzero are the same table but for G3's three cells (blank vs a
# genuine 0.0), and the driver records ImageMagick's pixel-content signature
# of each render. Equal signatures mean the two claims drew the same figure,
# which is the defect verbatim. Asserted with Annotate OFF as well as on --
# with Annotate off the ruling puts no words on the figure at all, so if the
# two are to differ there it can only be in the marks.
# ===========================================================================
oc_p <- file.path(disc_dir, "OVERCAP.tsv")
if (!file.exists(oc_p))
    stop(sprintf("v29: %s missing -- run harness/disclosure/run.sh first",
                 oc_p))
oc_case_p <- repo_path("harness", "disclosure", "overcap.praat")
if (!file.exists(oc_case_p)) stop(sprintf("v29: %s missing", oc_case_p))

oc <- read.delim(oc_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("case", "annotate", "verdict", "info", "fig",
                               "sig"))
oc$annotate <- suppressWarnings(as.integer(oc$annotate))
oc$info     <- suppressWarnings(as.integer(oc$info))
oc$fig      <- suppressWarnings(as.integer(oc$fig))

OC_CASES <- c("scatter8", "scatter21", "barmix", "barzero",
              "gviolin25", "gbox25")
check("v29", "over-cap driver ran twelve cases", nrow(oc), 12, tol = 0)
check_true("v29", "over-cap driver ran every case, both Annotate settings",
           identical(sort(paste(oc$case, oc$annotate)),
                     sort(paste(rep(OC_CASES, each = 2), c(0L, 1L)))))
check("v29", "no over-cap case failed to draw",
      sum(oc$verdict != "OK"), 0, tol = 0)

# The fixture must still be the fixture. If overcap.praat stops driving one
# of the three procedures the counts below would pass vacuously.
oc_src <- readLines(oc_case_p, warn = FALSE)
check_true("v29", "over-cap case sets the emlSubtitle$ sentinel",
           any(grepl(sprintf('emlSubtitle\\$ = "%s"', SENTINEL), oc_src)))
for (pr in c("emlDrawScatterPlot", "emlDrawBarChart", "emlDrawGroupedViolin",
             "emlDrawGroupedBoxPlot"))
    check_true("v29", sprintf("over-cap case calls @%s", pr),
               any(grepl(paste0("@", pr, ":"), oc_src, fixed = TRUE)))

oc_log <- function(cs, ann)
    readLines(file.path(disc_dir, sprintf("oc_%s_a%d.log", cs, ann)),
              warn = FALSE)

# One numeric field out of one of the probe's own records, e.g.
#   SUBSTAT nSubs=11 drawn=10 dropped=1 ... -> fld(lg, "SUBSTAT", "drawn") = 10
fld <- function(lg, rec, key) {
  ln <- grep(paste0("^", rec, " "), lg, value = TRUE)
  if (!length(ln)) return(NA_integer_)
  m <- regmatches(ln[1], regexpr(paste0("(?<=[ ]", key, "=)[^ ]*"), ln[1],
                                 perl = TRUE))
  if (!length(m)) NA_integer_ else suppressWarnings(as.integer(m))
}
# The bracketed name list, e.g. names=[G3] -> "G3".
fld_names <- function(lg, rec) {
  ln <- grep(paste0("^", rec, " "), lg, value = TRUE)
  if (!length(ln)) return(NA_character_)
  m <- regmatches(ln[1], regexpr("(?<=names=\\[)[^]]*", ln[1], perl = TRUE))
  if (!length(m)) "" else m
}

# --- The floor every over-cap case stands on ------------------------------
for (i in seq_len(nrow(oc))) {
  cs   <- oc$case[i]
  ann  <- oc$annotate[i]
  lab  <- sprintf("oc_%s_a%d", cs, ann)
  png_p <- file.path(disc_dir, paste0(lab, ".png"))
  log_p <- file.path(disc_dir, paste0(lab, ".log"))
  check_true("v29", paste(lab, "figure written"),
             file.exists(png_p) && file.info(png_p)$size > 0)
  if (!check_true("v29", paste(lab, "log written"), file.exists(log_p))) next
  lg <- readLines(log_p, warn = FALSE)
  check_true("v29", paste(lab, "no Praat error in the transcript"),
             !any(grepl("^Error|not completed|Unknown variable", lg)))
  check_true("v29", paste(lab, "wrote the PNG it reported"),
             any(grepl("^SAVED ", lg)))
  # The user's field, on these cases too.
  check_true("v29", paste(lab, "emlSubtitle$ came back untouched"),
             any(lg == sprintf("SUBTITLE [%s]", SENTINEL)))
  check("v29", paste(lab, "emlSubtitle$ was not appended to"),
        sum(grepl("^SUBTITLE \\[.*\\|", lg)), 0, tol = 0)
  # THE GATE, both directions, for every over-cap case. The "off" direction
  # is the ruling: whatever the procedure has to confess, none of it is on
  # the figure unless the user ticked Annotate.
  if (ann == 0L) {
    check("v29", paste(lab, "ANNOTATE OFF: nothing on the figure"),
          oc$fig[i], 0, tol = 0)
    check("v29", paste(lab, "ANNOTATE OFF: no FIGLINE recorded"),
          sum(grepl("^FIGLINE ", lg)), 0, tol = 0)
  } else {
    check("v29", paste(lab, "ANNOTATE ON: figure carries every disclosure"),
          oc$fig[i], min(oc$info[i], 20L), tol = 0)
    check("v29", paste(lab, "ANNOTATE ON: FIGLINE count matches ledger"),
          sum(grepl("^FIGLINE ", lg)), oc$fig[i], tol = 0)
  }
  # And the Info channel is unconditional: identical count either way.
  #
  # scatter8 is the ONE case excluded, and for a reason that is about the
  # procedure, not about the ruling: `annotate` is an argument of
  # @emlDrawScatterPlot and it gates whether the per-group CORRELATIONS are
  # computed at all. With Annotate off the eight groups contribute their
  # formula line only, eight lines, which fit -- so there is no over-cap to
  # disclose. The count differs because the WORK differs, not because a
  # disclosure was withheld. scatter21 turns correlations off entirely
  # (annotCorrType$ = "") so its work is identical on both settings, and it
  # carries this assertion for the scatter family.
  j0 <- which(oc$case == cs & oc$annotate == 0L)
  j1 <- which(oc$case == cs & oc$annotate == 1L)
  if (ann == 1L && cs != "scatter8")
      check("v29", paste(cs, "Info disclosure count does not depend on Annotate"),
            oc$info[j1], oc$info[j0], tol = 0)
}

# ---------------------------------------------------------------------------
# DEFECT 1: the over-cap scatter.
#
# 20 is @emlDisclose's block budget; the commit site reserves two lines of it
# for the disclosures that follow the per-group stats, so eighteen is what the
# stats themselves may claim. Three lines per group at Correlation type =
# Both, so six groups fit and seven do not.
#
# The behaviour chosen is ALL OR NONE, and "none" is asserted as hard as
# "all": a box holding six of eight groups is indistinguishable from a
# complete one, so a reader counting names in the corner would be misled by a
# truncation that no count in this file would catch.
# ---------------------------------------------------------------------------
OC_SCAT_SHORT8  <- "Per-group stats (8 groups): Info window only."
OC_SCAT_SHORT21 <- "Per-group stats (21 groups): Info window only."

for (ann in c(0L, 1L)) {
  lg  <- oc_log("scatter8", ann)
  lab <- sprintf("oc_scatter8_a%d [emlDrawScatterPlot]", ann)
  check("v29", paste(lab, "drove eight groups"),
        fld(lg, "SCATSTAT", "nGroups"), 8, tol = 0)
  check("v29", paste(lab, "eighteen lines of block budget for group stats"),
        fld(lg, "SCATSTAT", "room"), 18, tol = 0)
  # THE ASSERTION THE DEFECT IS ABOUT: whatever the procedure decided, the
  # block it handed @emlDrawAnnotationBlock is within the budget the block
  # documents. Before the fix this was 24 and the box left the figure.
  check_true("v29", paste(lab, "annotation block stays inside its 20 lines"),
             isTRUE(fld(lg, "SCATSTAT", "annotBlockN") <= 20))
  if (ann == 1L) {
    # Annotate on: Pearson + Spearman + formula per group = 24 buffered.
    check("v29", paste(lab, "buffers 3 lines x 8 groups"),
          fld(lg, "SCATSTAT", "buffered"), 24, tol = 0)
    # ALL OR NONE: the block holds the two disclosures and NOT ONE group
    # line. 24 > 18, so none of them may be committed.
    check("v29", paste(lab, "over cap: block holds the disclosures only"),
          fld(lg, "SCATSTAT", "annotBlockN"), 2, tol = 0)
    check("v29", paste(lab, "over cap: no group line reached the figure"),
          sum(grepl("^FIGLINE [0-9]+: Group[0-9]+:", lg)), 0, tol = 0)
    check_true("v29", paste(lab, "the over-cap note IS on the figure"),
               any(grepl(paste0("^FIGLINE [0-9]+: ",
                                gsub("([().\\\\])", "\\\\\\1", OC_SCAT_SHORT8),
                                "$"), lg)))
    # The dropped-row line survived the over-cap. It did not before: the
    # 24-line block had already spent the budget and @emlDisclose refused it.
    check_true("v29", paste(lab, "the dropped-row line ALSO reached the figure"),
               any(grepl("^FIGLINE [0-9]+: 3 row\\(s\\) skipped", lg)))
    # Info window: the note, with the group count and the line count in it...
    check("v29", paste(lab, "Info: the over-cap note, with both counts"),
          sum(grepl(paste0("^Scatter plot: ",
                           gsub("([().\\\\])", "\\\\\\1", OC_SCAT_SHORT8),
                           " 24 line\\(s\\) do not fit"), lg)), 1, tol = 0)
    # ...and NOTHING IS LOST: all twenty-four lines are printed there.
    check("v29", paste(lab, "Info: all 8 Pearson lines"),
          sum(grepl("^  Group[0-9]+: r = ", lg)), 8, tol = 0)
    check("v29", paste(lab, "Info: all 8 Spearman lines"),
          sum(grepl("^  Group[0-9]+: rs = ", lg)), 8, tol = 0)
    check("v29", paste(lab, "Info: all 8 fitted-line formulas"),
          sum(grepl("^  Group[0-9]+: OLS: y = ", lg)), 8, tol = 0)
  } else {
    # Annotate off contributes the formula line only, one per group: eight
    # lines, which FIT. So scatter8 cannot show the over-cap note being kept
    # off the figure -- that is what scatter21 is for.
    check("v29", paste(lab, "Annotate off: 8 buffered lines (formula only)"),
          fld(lg, "SCATSTAT", "buffered"), 8, tol = 0)
    check("v29", paste(lab, "under cap: all 8 committed to the block"),
          fld(lg, "SCATSTAT", "annotBlockN"), 8, tol = 0)
    check("v29", paste(lab, "under cap: no over-cap note"),
          sum(grepl("Info window only", lg, fixed = TRUE)), 0, tol = 0)
  }
}

# scatter21 -- twenty-one formula lines, so the over-cap note fires whether or
# not Annotate is ticked. THIS is the gate probe for the note itself.
for (ann in c(0L, 1L)) {
  lg  <- oc_log("scatter21", ann)
  lab <- sprintf("oc_scatter21_a%d [emlDrawScatterPlot]", ann)
  check("v29", paste(lab, "drove twenty-one groups"),
        fld(lg, "SCATSTAT", "nGroups"), 21, tol = 0)
  check("v29", paste(lab, "buffers one formula line per group"),
        fld(lg, "SCATSTAT", "buffered"), 21, tol = 0)
  check_true("v29", paste(lab, "annotation block stays inside its 20 lines"),
             isTRUE(fld(lg, "SCATSTAT", "annotBlockN") <= 20))
  # Info: ALWAYS, on both settings, with the group count in it.
  check("v29", paste(lab, "Info: the over-cap note fires regardless"),
        sum(grepl(paste0("^Scatter plot: ",
                         gsub("([().\\\\])", "\\\\\\1", OC_SCAT_SHORT21),
                         " 21 line\\(s\\) do not fit"), lg)), 1, tol = 0)
  check("v29", paste(lab, "Info: all 21 fitted-line formulas"),
        sum(grepl("^  Group[0-9]+: OLS: y = ", lg)), 21, tol = 0)
  if (ann == 1L) {
    check("v29", paste(lab, "ANNOTATE ON: the note is on the figure"),
          sum(grepl(paste0("^FIGLINE [0-9]+: ",
                           gsub("([().\\\\])", "\\\\\\1", OC_SCAT_SHORT21),
                           "$"), lg)), 1, tol = 0)
    check("v29", paste(lab, "over cap: block holds the disclosures only"),
          fld(lg, "SCATSTAT", "annotBlockN"), 2, tol = 0)
  } else {
    # The load-bearing direction. Same note, same count, NOT on the figure.
    check("v29", paste(lab, "ANNOTATE OFF: the note is NOT on the figure"),
          sum(grepl("^FIGLINE ", lg)), 0, tol = 0)
    check("v29", paste(lab, "ANNOTATE OFF: nothing at all in the block"),
          fld(lg, "SCATSTAT", "annotBlockN"), 0, tol = 0)
  }
}

# ---------------------------------------------------------------------------
# DEFECT 2: no data is not zero.
# ---------------------------------------------------------------------------
OC_BAR_MISSING <- "1 bar(s) not drawn (no usable observation): G3."
OC_BAR_NOERR   <- "1 error bar(s) not drawn (error undefined)."

for (ann in c(0L, 1L)) {
 for (cs in c("barmix", "barzero")) {
  lg  <- oc_log(cs, ann)
  lab <- sprintf("oc_%s_a%d [emlDrawBarChart]", cs, ann)
  check("v29", paste(lab, "four groups"),
        fld(lg, "BARSTAT", "nGroups"), 4, tol = 0)

  # THE INVARIANT, per group, read off a real render: the flag and the
  # stored value agree. valid[g] = 0 must mean mean[g] is undefined, and
  # errorDefined[g] = 0 must mean error[g] is undefined. Before v3.23 the
  # left side of each pair was set and the right side was 0, which is what
  # made the consumers' guards dead code.
  bg <- grep("^BARGROUP ", lg, value = TRUE)
  check("v29", paste(lab, "one BARGROUP record per group"),
        length(bg), 4, tol = 0)
  v_flag <- as.integer(sub("^.* valid=([0-9]+) .*$", "\\1", bg))
  v_val  <- as.integer(sub("^.* meanDefined=([0-9]+) .*$", "\\1", bg))
  e_flag <- as.integer(sub("^.* errorDefined=([0-9]+) .*$", "\\1", bg))
  e_val  <- as.integer(sub("^.* errorSlotDefined=([0-9]+)$", "\\1", bg))
  check("v29", paste(lab, "mean is defined exactly when valid[g] = 1"),
        sum(v_flag != v_val), 0, tol = 0)
  check("v29", paste(lab, "error is defined exactly when errorDefined[g] = 1"),
        sum(e_flag != e_val), 0, tol = 0)

  # G2 holds a single observation, so its SE is undefined by definition and
  # its whisker is not drawn. That half of the defect was still silent after
  # the v1.21 partial fix. Both fixtures carry it.
  check("v29", paste(lab, "G2's single observation leaves SE undefined"),
        e_flag[2], 0, tol = 0)
  check("v29", paste(lab, "the missing whisker is counted"),
        fld(lg, "BARSTAT", "skippedErrors"), 1, tol = 0)
  check("v29", paste(lab, "Info: the missing whisker is disclosed"),
        sum(startsWith(trimws(lg), paste("Bar chart:", OC_BAR_NOERR))),
        1, tol = 0)

  if (cs == "barmix") {
    # G3 has no usable observation.
    check("v29", paste(lab, "G3 is invalid"), v_flag[3], 0, tol = 0)
    check("v29", paste(lab, "G3's mean is undefined, not zero"),
          sum(grepl("^BARGROUP 3 .* mean=undefined ", lg)), 1, tol = 0)
    check("v29", paste(lab, "the bar is NOT drawn"),
          fld(lg, "BARSTAT", "skippedBars"), 1, tol = 0)
    check("v29", paste(lab, "the dead counter now agrees with the measurement"),
          fld(lg, "BARSTAT", "invalidGroups"),
          fld(lg, "BARSTAT", "skippedBars"), tol = 0)
    check_true("v29", paste(lab, "the disclosure NAMES the missing group"),
               identical(fld_names(lg, "BARSTAT"), "G3"))
    check("v29", paste(lab, "Info: the missing group is disclosed, by name"),
          sum(startsWith(trimws(lg), paste("Bar chart:", OC_BAR_MISSING))),
          1, tol = 0)
  } else {
    # G3 measured zero. It is a datum: drawn, valid, and NOT disclosed.
    check("v29", paste(lab, "G3 is valid"), v_flag[3], 1, tol = 0)
    check("v29", paste(lab, "G3's mean is a defined zero"),
          sum(grepl("^BARGROUP 3 .* mean=0 ", lg)), 1, tol = 0)
    check("v29", paste(lab, "the bar IS drawn"),
          fld(lg, "BARSTAT", "skippedBars"), 0, tol = 0)
    # Anchored, not a fixed-string search: "N error bar(s) not drawn" is a
    # DIFFERENT disclosure and G2 legitimately raises it in this fixture too.
    check("v29", paste(lab, "a measured zero is not disclosed as missing"),
          sum(grepl("^Bar chart: [0-9]+ bar\\(s\\) not drawn", trimws(lg))),
          0, tol = 0)
  }

  if (ann == 1L) {
    check_true("v29", paste(lab, "the missing-whisker line is ON the figure"),
               any(lg == paste0("FIGLINE 3: ", OC_BAR_NOERR)))
    if (cs == "barmix")
        check_true("v29", paste(lab, "the missing-group line is ON the figure"),
                   any(grepl(paste0("^FIGLINE [0-9]+: ",
                                    gsub("([().\\\\])", "\\\\\\1",
                                         OC_BAR_MISSING), "$"), lg)))
    else
        check("v29", paste(lab, "no missing-group line on the figure"),
              sum(grepl("^FIGLINE [0-9]+: [0-9]+ bar\\(s\\) not drawn", lg)),
              0, tol = 0)
  }
 }
}

# THE PICTURE. Same table but for G3's three cells; the fixture puts a
# negative group in so the zero baseline lifts off the axis floor and a
# measured zero has somewhere visible to draw. If these signatures match, the
# figure is making the same two claims with the same marks -- which is the
# defect, and no count above would notice.
for (ann in c(0L, 1L)) {
  s_mix  <- oc$sig[oc$case == "barmix"  & oc$annotate == ann]
  s_zero <- oc$sig[oc$case == "barzero" & oc$annotate == ann]
  check_true("v29", sprintf("bar signatures were recorded (annotate = %d)", ann),
             length(s_mix) == 1L && length(s_zero) == 1L &&
             nzchar(s_mix) && s_mix != "NA" && nzchar(s_zero) &&
             s_zero != "NA")
  check_true("v29",
             sprintf("a missing group DRAWS DIFFERENTLY from a measured zero (annotate = %d)",
                     ann),
             !identical(s_mix, s_zero))
}
# ...and the two are not different merely because everything is different:
# every other case's own two renders differ only by the annotation box, so a
# signature that never repeats would prove nothing. Annotate off vs on must
# differ for barmix (the box appears) and the disclosure counts must differ
# between the two fixtures in the way the fixtures do.
check("v29", "barmix discloses two things barzero does not",
      oc$info[oc$case == "barmix" & oc$annotate == 1L] -
      oc$info[oc$case == "barzero" & oc$annotate == 1L], 2, tol = 0)

# ---------------------------------------------------------------------------
# DEFECT 3: the twenty-fifth sub-group.
#
# CHANGED BY DESIGN, 7 Aug 2026. This block used to read:
#
#     check_true("@emlSetColorPalette declares a tenth fill/line pair", ...)
#     check("@emlSetColorPalette declares no ELEVENTH pair (the cap is real)")
#     check("both grouped procedures hold the cap at ten", ..., 2)
#
# and it was pinning the wrong number. The tenth pair it insisted on was a
# literal duplicate of the second (D127), so the check was actively defending
# a defect: it would have failed anyone who removed the duplication. It is
# replaced, not weakened -- the three checks below are STRICTER, because they
# pin the eight hues, the three patterns, the arithmetic that maps a slot to
# a (hue, pattern) pair, and the cap, where the old ones pinned only a count
# of assignments.
# ---------------------------------------------------------------------------
pal_src  <- readLines(repo_path("plugin", "graphs",
                                "eml-graph-procedures.praat"), warn = FALSE)
pal_code <- trimws(sub("[#;!].*$", "", pal_src))
check("v29", "@emlSetColorPalette declares exactly eight literal hues",
      sum(grepl("^\\.line\\$\\[[0-9]+\\][[:space:]]*=[[:space:]]*\"\\{",
                pal_code)),
      8, tol = 0)
check("v29", "@emlSetColorPalette declares NO ninth hue (the duplicate is gone)",
      sum(grepl("^\\.(fill|line|lightLine)\\$\\[(9|1[0-9]|2[0-4])\\][[:space:]]*=",
                pal_code)),
      0, tol = 0)
check("v29", "the style space is 8 hues x 3 patterns = 24",
      sum(grepl("^\\.nStyles[[:space:]]*=[[:space:]]*\\.nHues[[:space:]]*\\*[[:space:]]*\\.nPatterns$",
                pal_code)),
      1, tol = 0)
check_true("v29", "slot -> hue is (slot - 1) mod 8, slot -> pattern is div 8",
           any(grepl("^\\.hIdx = \\(\\(\\.i - 1\\) mod \\.nHues\\) \\+ 1$",
                     pal_code)) &&
           any(grepl("^\\.pattern\\[\\.i\\] = \\(\\(\\(\\.i - 1\\) div \\.nHues\\) mod \\.nPatterns\\) \\+ 1$",
                     pal_code)))
check("v29", "both grouped procedures hold the cap at 24",
      sum(grepl("^\\.maxSubs[[:space:]]*=[[:space:]]*24$", code_stmt)),
      2, tol = 0)
check("v29", "no grouped procedure still holds the old ten",
      sum(grepl("^\\.maxSubs[[:space:]]*=[[:space:]]*10$", code_stmt)),
      0, tol = 0)
# Both primitives and the legend must actually TAKE the pattern; a palette
# that carries one and a draw procedure that ignores it is D127 again.
# Read from pal_src, NOT pal_code: the comment stripper cuts at the first
# "#", and a Praat vector parameter is spelled .data# -- stripping the
# signature at that character was enough to make this check fail on a
# signature that was correct.
for (pr in c("emlDrawViolin", "emlDrawBox"))
  check_true("v29", sprintf("@%s takes a .pattern argument", pr),
             any(grepl(sprintf("^procedure %s:.*, \\.pattern$", pr),
                       trimws(pal_src))))
check("v29", "every call to the two primitives passes a palette pattern",
      sum(grepl("@emlDraw(Violin|Box):", code_stmt)) -
      sum(grepl("@emlDraw(Violin|Box):.*emlSetColorPalette\\.pattern\\[",
                code_stmt)),
      0, tol = 0)

oc_sub <- list(gviolin25 = c(proc = "emlDrawGroupedViolin",
                             name = "Grouped violin"),
               gbox25    = c(proc = "emlDrawGroupedBoxPlot",
                             name = "Grouped box plot"))
OC_SUB_SHORT <- "1 sub-group(s) not drawn (palette holds 24)."

for (cs in names(oc_sub)) {
 for (ann in c(0L, 1L)) {
  lg  <- oc_log(cs, ann)
  lab <- sprintf("oc_%s_a%d [%s]", cs, ann, oc_sub[[cs]]["proc"])
  check("v29", paste(lab, "the fixture really has twenty-five sub-groups"),
        fld(lg, "SUBSTAT", "nSubs"), 25, tol = 0)
  check("v29", paste(lab, "24 are drawn -- the cap is not exceeded"),
        fld(lg, "SUBSTAT", "drawn"), 24, tol = 0)
  check("v29", paste(lab, "one is dropped"),
        fld(lg, "SUBSTAT", "dropped"), 1, tol = 0)
  check("v29", paste(lab, "16 rows went with it"),
        fld(lg, "SUBSTAT", "droppedRows"), 16, tol = 0)
  # The legend no longer advertises a sub-group with no violin anywhere on
  # the figure. That was half the silence: the reader had a swatch and a
  # name for something that was not drawn.
  check("v29", paste(lab, "the legend lists only what was drawn"),
        fld(lg, "SUBSTAT", "legendN"), 24, tol = 0)
  check_true("v29", paste(lab, "the dropped sub-group is named"),
             identical(fld_names(lg, "SUBSTAT"), "P25"))
  # Info: ALWAYS, with the count.
  check("v29", paste(lab, "Info: the drop is disclosed, with the count"),
        sum(startsWith(trimws(lg),
                       paste0(oc_sub[[cs]]["name"], ": ", OC_SUB_SHORT))),
        1, tol = 0)
  # ...and the Info line names the sub-group and its row count in the advice.
  check("v29", paste(lab, "Info: the advice names P25 and its 16 rows"),
        sum(grepl("Not drawn: P25 (16 row(s)).", lg, fixed = TRUE)),
        1, tol = 0)
  # ...and it says WHAT the ceiling is made of, not just how big it is.
  check("v29", paste(lab, "Info: the advice names the 8 x 3 style space"),
        sum(grepl("8 hues x 3 fill patterns (solid, diagonal hatch, dots)",
                  lg, fixed = TRUE)),
        1, tol = 0)
  # The gate, both directions.
  if (ann == 1L) {
      check("v29", paste(lab, "ANNOTATE ON: the drop is on the figure"),
            sum(lg == paste0("FIGLINE 1: ", OC_SUB_SHORT)), 1, tol = 0)
  } else {
      check("v29", paste(lab, "ANNOTATE OFF: the drop is NOT on the figure"),
            sum(grepl("^FIGLINE ", lg)), 0, tol = 0)
  }
 }
}

# ===========================================================================
# THE 24 SUB-GROUP STYLES, MEASURED ON THE RENDERED PIXELS
# ===========================================================================
# Driven by harness/patterns/run.sh, which renders each palette slot as its
# own figure -- 24 styles x {violin, box, legend swatch} x {colour, bw} = 144
# figures -- and measures a crop of the drawn mark. The crop rectangle is
# computed by the Praat case in world coordinates and printed as a CROP
# record, so the shell never guesses where the mark is.
#
# WHY THIS SECTION EXISTS. Everything that read the palette TABLE agreed that
# there were ten distinct fill/line pairs, because there were ten assignment
# statements. Slots 9 and 10 were byte-for-byte copies of 1 and 2 (D127), so
# for as long as that held, a nine- or ten-sub-group figure drew two pairs of
# sub-groups identically and no check noticed. A claim about what a reader
# can tell apart can only be settled on the image.
#
# HOW A MARK IS DESCRIBED. A drawn mark is exactly TWO colours -- its fill and
# its pattern ink -- so the per-channel (min, max) pair describes it
# completely. The mean does not: on the greyscale ramp a light fill under dark
# ink and a dark fill under light ink can average to nearly the same grey
# while looking nothing alike, and a mean-only comparison would call them
# confusable when a reader would not.
#
# HOW THE PATTERN IS RECOVERED. Two scale-free numbers, per channel, taken on
# the channel that carries the most variation:
#   sd            ~0 for a solid fill, large for any pattern.
#   rowSD / sd    a 45-degree hatch puts the same ink in every row, so its row
#                 profile is nearly flat (measured: 0.04-0.13); a dot grid
#                 leaves whole rows empty, so its row profile swings
#                 (measured: 0.53-0.59). The gap is four-fold and the split is
#                 taken at 0.30.
# The recovered class is then required to EQUAL the pattern the palette
# declared for that slot -- for all 144 renders. That is the assertion that
# says the pattern reached the paper, in both primitives and in the key.
#
# TWO STYLES ARE DISTINGUISHABLE IF their recovered pattern differs, or their
# colour pair differs by at least STYLE_COLOUR_MIN on a 0-1 channel scale.
# Styles 9 (blue hatched) and 17 (blue dotted) have IDENTICAL colour pairs by
# construction -- same hue, same ink -- and are told apart by the pattern
# alone, which is exactly what the second dimension is for.
# ===========================================================================
sty_p <- repo_path("harness", "patterns", "out", "STYLES.tsv")
if (!file.exists(sty_p))
    stop(sprintf("v29: %s missing -- run harness/patterns/run.sh first",
                 sty_p))
sty <- read.delim(sty_p, header = FALSE, stringsAsFactors = FALSE,
                  col.names = c("mode", "shape", "style", "hue", "pattern",
                                "verdict", "cw", "ch",
                                "mr", "mg", "mb",
                                "sdR", "sdG", "sdB",
                                "rwR", "rwG", "rwB",
                                "clR", "clG", "clB",
                                "mnR", "mnG", "mnB",
                                "mxR", "mxG", "mxB"))
for (cc in setdiff(names(sty), c("mode", "shape", "verdict")))
    sty[[cc]] <- suppressWarnings(as.numeric(sty[[cc]]))

STY_MODES  <- c("color", "bw")
STY_SHAPES <- c("violin", "box", "swatch")
N_STYLES   <- 24L

check("v29", "style driver rendered 24 styles x 3 shapes x 2 modes",
      nrow(sty), length(STY_MODES) * length(STY_SHAPES) * N_STYLES, tol = 0)
check("v29", "no style render failed",
      sum(sty$verdict != "OK"), 0, tol = 0)
check_true("v29", "style driver covered every (mode, shape, style) cell",
           identical(sort(paste(sty$mode, sty$shape, sty$style)),
                     sort(paste(rep(STY_MODES, each = length(STY_SHAPES) * N_STYLES),
                                rep(rep(STY_SHAPES, each = N_STYLES),
                                    times = length(STY_MODES)),
                                seq_len(N_STYLES)))))

# The slot -> (hue, pattern) map the palette reports, read back off the
# renders. Hue cycles first: 1-8 solid, 9-16 hatched, 17-24 dotted.
check_true("v29", "slot -> hue is (slot - 1) mod 8 + 1, in both modes",
           all(sty$hue == ((sty$style - 1L) %% 8L) + 1L))
check_true("v29", "slot -> pattern is (slot - 1) div 8 + 1, in both modes",
           all(sty$pattern == ((sty$style - 1L) %/% 8L) + 1L))

# ImageMagick reports the standard deviation of a perfectly uniform region as
# NaN; the driver already normalises that to 0, and this is the belt.
sty_num <- function(v) ifelse(is.finite(v), v, 0)

STYLE_SOLID_SD   <- 0.02   # below this the mark is a flat fill
STYLE_ROW_SPLIT  <- 0.30   # rowSD/sd: hatch below, dots above
STYLE_COLOUR_MIN <- 0.05   # per-channel separation that counts as a difference

sty_class <- function(r) {
  sd  <- max(sty_num(c(r$sdR, r$sdG, r$sdB)))
  row <- max(sty_num(c(r$rwR, r$rwG, r$rwB)))
  if (sd < STYLE_SOLID_SD) return(1L)
  if (row / sd < STYLE_ROW_SPLIT) return(2L)
  3L
}
sty_pair <- function(r)
  as.numeric(c(r$mnR, r$mnG, r$mnB, r$mxR, r$mxG, r$mxB))

worst_same <- c()
for (m in STY_MODES) {
  for (sh in STY_SHAPES) {
    x <- sty[sty$mode == m & sty$shape == sh, ]
    x <- x[order(x$style), ]
    lab <- sprintf("%s/%s", m, sh)
    if (!check("v29", sprintf("%s: all 24 styles present", lab),
               nrow(x), N_STYLES, tol = 0)) next

    # 1. THE PATTERN REACHED THE PAPER. The class recovered from the pixels
    #    equals the class the palette declared, for every slot.
    got <- vapply(seq_len(N_STYLES), function(i) sty_class(x[i, ]), integer(1))
    check("v29", sprintf("%s: rendered pattern matches the declared pattern, all 24", lab),
          sum(got == x$pattern), N_STYLES, tol = 0)
    check("v29", sprintf("%s: exactly 8 solid, 8 hatched, 8 dotted on the page", lab),
          sum(tabulate(got, 3L) == c(8L, 8L, 8L)), 3L, tol = 0)

    # 2. ALL 24 PAIRWISE DISTINGUISHABLE. Different pattern, or a colour pair
    #    that differs by at least STYLE_COLOUR_MIN.
    prs <- t(vapply(seq_len(N_STYLES), function(i) sty_pair(x[i, ]),
                    numeric(6)))
    n_confusable <- 0L
    min_same <- Inf
    for (i in seq_len(N_STYLES - 1L)) {
      for (j in (i + 1L):N_STYLES) {
        cd <- max(abs(prs[i, ] - prs[j, ]))
        if (got[i] == got[j]) {
          min_same <- min(min_same, cd)
          if (cd < STYLE_COLOUR_MIN) n_confusable <- n_confusable + 1L
        }
      }
    }
    check("v29", sprintf("%s: no two of the 24 styles render confusably", lab),
          n_confusable, 0, tol = 0)
    # ...and the margin is reported, not just the verdict, so a palette edit
    # that halves it is visible in the log before it becomes a failure.
    check_true("v29",
               sprintf("%s: closest same-pattern pair is %.4f apart (>= %.2f)",
                       lab, min_same, STYLE_COLOUR_MIN),
               min_same >= STYLE_COLOUR_MIN)
    worst_same <- c(worst_same, min_same)
  }
}
check_true("v29",
           sprintf("greyscale reaches the SAME 24 as colour (worst margin %.4f)",
                   min(worst_same)),
           min(worst_same) >= STYLE_COLOUR_MIN)

# 3. THE LEGEND SWATCH IS THE MARK. A solid swatch beside a hatched violin is
#    D127 relocated into the key, so the swatch is measured with the same
#    pipeline as the violin and required to agree with it -- same pattern, and
#    the same two colours. Both primitives are checked against the swatch, so
#    a legend that matched the violin and not the box would still fail.
for (m in STY_MODES) {
  v <- sty[sty$mode == m & sty$shape == "violin", ]; v <- v[order(v$style), ]
  b <- sty[sty$mode == m & sty$shape == "box",    ]; b <- b[order(b$style), ]
  w <- sty[sty$mode == m & sty$shape == "swatch", ]; w <- w[order(w$style), ]
  cv <- vapply(seq_len(N_STYLES), function(i) sty_class(v[i, ]), integer(1))
  cb <- vapply(seq_len(N_STYLES), function(i) sty_class(b[i, ]), integer(1))
  cw <- vapply(seq_len(N_STYLES), function(i) sty_class(w[i, ]), integer(1))
  check("v29", sprintf("%s: the legend swatch's PATTERN matches its violin's, all 24", m),
        sum(cw == cv), N_STYLES, tol = 0)
  check("v29", sprintf("%s: the legend swatch's PATTERN matches its box's, all 24", m),
        sum(cw == cb), N_STYLES, tol = 0)
  dv <- vapply(seq_len(N_STYLES),
               function(i) max(abs(sty_pair(w[i, ]) - sty_pair(v[i, ]))),
               numeric(1))
  db <- vapply(seq_len(N_STYLES),
               function(i) max(abs(sty_pair(b[i, ]) - sty_pair(v[i, ]))),
               numeric(1))
  check_true("v29",
             sprintf("%s: the legend swatch's COLOURS match its violin's (worst %.4f)",
                     m, max(dv)),
             max(dv) < 0.01)
  check_true("v29",
             sprintf("%s: the box draws the same two colours as the violin (worst %.4f)",
                     m, max(db)),
             max(db) < 0.01)
}

# 4. THE FIXTURE MUST STILL BE THE FIXTURE. If style_case.praat stopped
#    calling the primitives, or started optimising the palette (which permutes
#    hues and would make "slot N" mean something else), everything above would
#    pass on the wrong evidence.
sty_case <- readLines(repo_path("harness", "patterns", "style_case.praat"),
                      warn = FALSE)
for (pr in c("emlDrawViolin", "emlDrawBox", "emlDrawLegend"))
  check_true("v29", sprintf("style fixture calls @%s", pr),
             any(grepl(paste0("@", pr, ":"), sty_case, fixed = TRUE)))
# Comment lines dropped first: the fixture SAYS in a comment why it does not
# optimise, and a naive grep would read its own explanation as the call.
sty_code <- trimws(sty_case)
sty_code <- sty_code[!startsWith(sty_code, "#")]
check("v29", "style fixture does NOT optimise the palette",
      sum(grepl("@emlOptimizePaletteContrast", sty_code, fixed = TRUE)),
      0, tol = 0)
check_true("v29", "style fixture reads the pattern out of the palette",
           any(grepl("emlSetColorPalette.pattern[style]", sty_case,
                     fixed = TRUE)))

# ===========================================================================
# THE 24 POINT-MARKER STYLES, MEASURED ON THE RENDERED PIXELS
# ===========================================================================
# The other half of the palette, and the half that had the hole for longer.
#
# A fill PATTERN needs an area to live in. Scatter, line chart, spaghetti and
# time series draw dots and lines; there is no area, so the 8 x 3 style space
# that fixed the violins and boxes did nothing for them and they went on
# cycling eight hues in silence above eight groups -- D127's exact shape, in
# four more chart types. The author's ruling of 7 Aug 2026 adds the second
# dimension those charts can carry: marker SHAPE. Circle, square, triangle,
# on the same slot arithmetic, so the ceiling is 24 for both families.
#
# NOT SPRITES, and the reasoning is in the block comment above @emlDrawMarker.
# The short version, checked statically below: @emlSetColorPalette's
# .sprite$[] array is dead (read only by @emlDrawAlphaDot and
# @emlDrawAlphaRect, both gated on emlInitAlphaSprites.available, which is 0
# on every platform this repo runs on because plugin/sprites/ has never
# existed AND Praat has no cairo image branch), and a raster marker would
# therefore have rendered as nothing at all on the machine that measures it.
#
# WHY A PROFILE AND NOT AN AREA. The square is sized for EQUAL AREA with the
# circle on purpose, so any "how much ink" summary calls the two identical --
# measured, 0.369 against 0.364 of the same crop. What differs is WHERE the
# ink is, so harness/markers/run.sh reduces each crop to a binary ink mask
# and averages it to 16 rows and 16 columns, and this section classifies the
# resulting profile.
#
# TWO CLASSIFIERS, deliberately, because they answer different questions.
#
#   TEMPLATE      the observed row profile against the three profiles the
#                 declared geometry predicts (a circle of radius r, a square
#                 of half-side 0.8862 r, an equilateral triangle of
#                 circumradius 1.45 r, in a crop of half-height 1.5 r).
#                 Answers "is the thing on the page the shape the code says
#                 it draws" -- an absolute claim, with no reference to the
#                 other renders. A triangle drawn ten pixels too high fails
#                 this and passes everything else; that is not hypothetical,
#                 it is how the first draft's missing aspect correction on
#                 the base offset was found.
#   NEAREST       leave-one-out nearest-centroid among the renders themselves.
#                 Answers "can the three classes be told apart on the page",
#                 which is the reader's question, and it survives the legend
#                 key for a LINE chart, where a line segment is drawn through
#                 the marker and perturbs the absolute profile.
#
# WHERE READABILITY BREAKS DOWN -- rendered at 12 x 7 inches and looked at,
# 8 Aug 2026 (harness/markers/out/look_*.png, regenerated by the driver):
#     8 groups    trivial; one shape, eight hues
#    16 groups    comfortable; circles and squares are never confusable
#    24 groups    still comfortable, and easier than 24 FILL patterns: shape
#                 is a stronger cue than hatch-vs-dots, and a triangle at
#                 the plugin's dot sizes is 40-110 pixels across
# The shapes themselves stop being separable long below the palette's floor:
# @emlDrawMarker's smallest triangle is 8 slices tall, and the smallest
# marker any of the four chart types asks for is the small scatter dot at
# 0.035 inches, i.e. 21 pixels across at 300 dpi. The cap is 24 and the
# drawing is correct at every count up to it.
# ===========================================================================
mk_p <- repo_path("harness", "markers", "out", "MARKERS.tsv")
lk_p <- repo_path("harness", "markers", "out", "LOOKS.tsv")
for (pp in c(mk_p, lk_p))
    if (!file.exists(pp))
        stop(sprintf("v29: %s missing -- run harness/markers/run.sh first", pp))

MK_ROWCOLS <- paste0("row", sprintf("%02d", 1:16))
MK_COLCOLS <- paste0("col", sprintf("%02d", 1:16))
mk <- read.delim(mk_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("mode", "shape", "style", "hue", "marker",
                               "verdict", "cw", "ch", "ink",
                               "mr", "mg", "mb", "mnR", "mnG", "mnB",
                               MK_ROWCOLS, MK_COLCOLS))
for (cc in setdiff(names(mk), c("mode", "shape", "verdict")))
    mk[[cc]] <- suppressWarnings(as.numeric(mk[[cc]]))

MK_MODES  <- c("color", "bw")
MK_SHAPES <- c("point", "key", "keyline")

check("v29", "marker driver rendered 24 styles x 3 shapes x 2 modes",
      nrow(mk), length(MK_MODES) * length(MK_SHAPES) * N_STYLES, tol = 0)
check("v29", "no marker render failed",
      sum(mk$verdict != "OK"), 0, tol = 0)
check_true("v29", "marker driver covered every (mode, shape, style) cell",
           identical(sort(paste(mk$mode, mk$shape, mk$style)),
                     sort(paste(rep(MK_MODES, each = length(MK_SHAPES) * N_STYLES),
                                rep(rep(MK_SHAPES, each = N_STYLES),
                                    times = length(MK_MODES)),
                                seq_len(N_STYLES)))))

# The slot -> (hue, marker) map, read back off the renders. Same arithmetic
# as the fill patterns: hue cycles first, so 1-8 are circles, 9-16 squares,
# 17-24 triangles, and ADJACENT sub-groups differ in the stronger cue.
check_true("v29", "marker slot -> hue is (slot - 1) mod 8 + 1, in both modes",
           all(mk$hue == ((mk$style - 1L) %% 8L) + 1L))
check_true("v29", "marker slot -> shape is (slot - 1) div 8 + 1, in both modes",
           all(mk$marker == ((mk$style - 1L) %/% 8L) + 1L))

# --- The three profiles the declared geometry predicts -----------------------
# Integrated over each of the 16 crop rows, then scaled so the widest row is
# 1 -- the observed profile is scaled the same way, so neither the marker's
# absolute size nor the ink threshold enters the comparison.
mk_template <- function(f) {
  ys <- seq(1.5, -1.5, length.out = 16 * 40 + 1)
  ys <- (ys[-length(ys)] + ys[-1]) / 2
  w  <- f(ys)
  dim(w) <- c(40L, 16L)
  v <- colMeans(w)
  v / max(v)
}
MK_TPL <- rbind(
  circle   = mk_template(function(y) ifelse(abs(y) <= 1, sqrt(pmax(0, 1 - y^2)), 0)),
  square   = mk_template(function(y) ifelse(abs(y) <= 0.8862, 0.8862, 0)),
  triangle = mk_template(function(y) ifelse(y >= -0.725 & y <= 1.45,
                                            1.2557 * (1.45 - y) / 2.175, 0)))

mk_rows <- as.matrix(mk[, MK_ROWCOLS])
mk_rows[!is.finite(mk_rows)] <- 0
mk_obs  <- mk_rows / pmax(apply(mk_rows, 1, max), 1e-9)

mk_rms <- vapply(1:3, function(k)
    sqrt(rowMeans((mk_obs - matrix(MK_TPL[k, ], nrow(mk_obs), 16L,
                                   byrow = TRUE))^2)),
    numeric(nrow(mk_obs)))
mk$tplGot    <- max.col(-mk_rms, ties.method = "first")
mk$tplBest   <- apply(mk_rms, 1, min)
mk$tplMargin <- apply(mk_rms, 1, function(r) diff(sort(r)[1:2]))

# 1. THE SHAPE ON THE PAGE IS THE SHAPE THE CODE DECLARES. Absolute, against
#    geometry, for the mark itself and for the scatter's legend key. The
#    line-chart key ("keyline") is excluded from THIS check only, because a
#    line segment is drawn through the marker by design and shifts the
#    profile; it is covered by the nearest-centroid check below, and by the
#    key-agrees-with-the-mark check after that.
for (m in MK_MODES) {
  for (sh in c("point", "key")) {
    x <- mk[mk$mode == m & mk$shape == sh, ]
    x <- x[order(x$style), ]
    lab <- sprintf("%s/%s", m, sh)
    if (!check("v29", sprintf("%s: all 24 marker styles present", lab),
               nrow(x), N_STYLES, tol = 0)) next
    check("v29",
          sprintf("%s: the rendered shape matches the declared geometry, all 24", lab),
          sum(x$tplGot == x$marker), N_STYLES, tol = 0)
    check("v29", sprintf("%s: exactly 8 circles, 8 squares, 8 triangles", lab),
          sum(tabulate(x$tplGot, 3L) == c(8L, 8L, 8L)), 3L, tol = 0)
    check_true("v29",
               sprintf("%s: worst fit to its own template is %.3f (< 0.15)",
                       lab, max(x$tplBest)),
               max(x$tplBest) < 0.15)
    check_true("v29",
               sprintf("%s: closest wrong template is %.3f further off (>= 0.03)",
                       lab, min(x$tplMargin)),
               min(x$tplMargin) >= 0.03)
  }
}

# 2. THE THREE CLASSES ARE SEPARABLE ON THE PAGE. Leave-one-out
#    nearest-centroid, per (mode, shape), including the line-chart key.
#    No template, no threshold: each render is classified by the other
#    fifteen of its own kind against the sixteen of each other kind.
mk_loo_margin <- c()
for (m in MK_MODES) {
  for (sh in MK_SHAPES) {
    idx <- which(mk$mode == m & mk$shape == sh)
    P   <- mk_obs[idx, , drop = FALSE]
    cls <- mk$marker[idx]
    got <- integer(length(idx))
    mrg <- numeric(length(idx))
    for (i in seq_along(idx)) {
      d <- vapply(1:3, function(cl) {
             j <- setdiff(which(cls == cl), i)
             sqrt(mean((P[i, ] - colMeans(P[j, , drop = FALSE]))^2))
           }, numeric(1))
      got[i] <- which.min(d)
      mrg[i] <- diff(sort(d)[1:2])
    }
    lab <- sprintf("%s/%s", m, sh)
    check("v29",
          sprintf("%s: every render lands in its own marker class, all 24", lab),
          sum(got == cls), N_STYLES, tol = 0)
    check_true("v29",
               sprintf("%s: closest wrong class is %.4f further off (>= 0.03)",
                       lab, min(mrg)),
               min(mrg) >= 0.03)
    mk_loo_margin <- c(mk_loo_margin, min(mrg))
  }
}

# 3. ALL 24 PAIRWISE DISTINGUISHABLE, the same rule the fill patterns use:
#    a different shape, or a colour that differs by at least
#    MARKER_COLOUR_MIN on a 0-1 channel scale. Styles 1 and 9 have the SAME
#    colour by construction -- same hue, different shape -- and are separated
#    by the shape alone, which is what the second dimension is for.
MARKER_COLOUR_MIN <- 0.05
mk_worst_same <- c()
for (m in MK_MODES) {
  for (sh in MK_SHAPES) {
    x <- mk[mk$mode == m & mk$shape == sh, ]
    x <- x[order(x$style), ]
    cols <- as.matrix(x[, c("mnR", "mnG", "mnB")])
    got  <- x$marker
    n_confusable <- 0L
    min_same <- Inf
    for (i in seq_len(N_STYLES - 1L)) {
      for (j in (i + 1L):N_STYLES) {
        cd <- max(abs(cols[i, ] - cols[j, ]))
        if (got[i] == got[j]) {
          min_same <- min(min_same, cd)
          if (cd < MARKER_COLOUR_MIN) n_confusable <- n_confusable + 1L
        }
      }
    }
    lab <- sprintf("%s/%s", m, sh)
    check("v29", sprintf("%s: no two of the 24 marker styles render confusably", lab),
          n_confusable, 0, tol = 0)
    check_true("v29",
               sprintf("%s: closest same-shape pair is %.4f apart (>= %.2f)",
                       lab, min_same, MARKER_COLOUR_MIN),
               min_same >= MARKER_COLOUR_MIN)
    mk_worst_same <- c(mk_worst_same, min_same)
  }
}
check_true("v29",
           sprintf("greyscale markers reach the SAME 24 as colour (worst margin %.4f)",
                   min(mk_worst_same)),
           min(mk_worst_same) >= MARKER_COLOUR_MIN)

# 4. THE LEGEND KEY IS THE MARK. A square series with a circular key is the
#    same defect class as a hatched violin with a solid swatch: the reader is
#    told two series differ only in hue when they do not. Both key variants
#    are required to agree with the mark on SHAPE and on COLOUR -- the
#    scatter's marker-only key and the line chart's marker-on-a-line key.
for (m in MK_MODES) {
  pt <- mk[mk$mode == m & mk$shape == "point",   ]; pt <- pt[order(pt$style), ]
  ky <- mk[mk$mode == m & mk$shape == "key",     ]; ky <- ky[order(ky$style), ]
  kl <- mk[mk$mode == m & mk$shape == "keyline", ]; kl <- kl[order(kl$style), ]
  check("v29", sprintf("%s: the scatter key's SHAPE matches its mark's, all 24", m),
        sum(ky$tplGot == pt$tplGot), N_STYLES, tol = 0)
  check("v29", sprintf("%s: the key shows all three shapes, not just the hue", m),
        length(unique(ky$tplGot)), 3, tol = 0)
  for (nm in list(c("scatter key", "ky"), c("line-chart key", "kl"))) {
    z <- get(nm[2])
    d <- vapply(seq_len(N_STYLES),
                function(i) max(abs(as.numeric(z[i, c("mnR", "mnG", "mnB")]) -
                                    as.numeric(pt[i, c("mnR", "mnG", "mnB")]))),
                numeric(1))
    check_true("v29",
               sprintf("%s: the %s's COLOUR matches its mark's (worst %.4f)",
                       m, nm[1], max(d)),
               max(d) < 0.01)
  }
}

# 5. THE LOOK RENDERS EXIST. Six group counts x two chart types, drawn
#    through the real procedures at 12 x 7 inches. They are what the
#    "where does it break down" note above was written from, and a claim
#    about what a human saw is worth nothing if the figures are not there
#    to be looked at again.
lk <- read.delim(lk_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("chart", "mode", "n", "verdict", "bytes"))
lk$n     <- suppressWarnings(as.integer(lk$n))
lk$bytes <- suppressWarnings(as.numeric(lk$bytes))
check("v29", "look renders: 2 charts x 2 modes x 3 group counts",
      nrow(lk), 12, tol = 0)
check("v29", "no look render failed", sum(lk$verdict != "OK"), 0, tol = 0)
check_true("v29", "look renders cover 8, 16 and 24 groups both ways",
           identical(sort(unique(lk$n)), c(8L, 16L, 24L)) &&
           identical(sort(unique(lk$mode)), c("bw", "color")))
check_true("v29", "every look render carries a figure",
           all(lk$bytes > 20000))

# 6. THE MARKER GEOMETRY, at the size the plugin actually asks for. The crop
#    is 3 x the marker radius by construction, so the render reports the
#    radius the fixture used: cw / 900 inches at 300 dpi. This is the number
#    the "is a triangle legible" question turns on, so it is stated rather
#    than assumed.
mk_pt_px <- mk$cw[mk$shape == "point"]
check_true("v29",
           sprintf("the measured mark is %.0f px across at the medium scatter dot size (>= 24)",
                   2 * mean(mk_pt_px) / 3),
           2 * min(mk_pt_px) / 3 >= 24)
mk_ky_px <- mk$cw[mk$shape == "key"]
check_true("v29",
           sprintf("the legend key's marker is %.0f px across (>= 12)",
                   2 * mean(mk_ky_px) / 3),
           2 * min(mk_ky_px) / 3 >= 12)

# 6b. WHERE THE SHAPES STOP BEING SEPARABLE. The author asked for the honest
#     number, so it is measured rather than argued: harness/markers/run.sh
#     walks one circle, one square and one triangle down a ladder of marker
#     widths in device pixels and this block classifies each rung against the
#     same geometry templates.
#
#     MEASURED, 8 Aug 2026:  5 px 2/3   6 px 1/3   8 px 3/3  10 px 1/3
#                           12 px 3/3  16 px 3/3  22 px 3/3  30 px 3/3
#     with the margin over the nearest wrong template rising monotonically
#     from 12 px up (0.026, 0.038, 0.070, 0.082). Below 12 px it is not a
#     clean threshold but a coin toss -- 8 px happens to land right and 10 px
#     does not -- because a 16-row profile over a 30-pixel crop is about two
#     pixels a row, and both the circle's taper and the triangle's ramp
#     disappear into the quantisation. The two failure modes below the floor
#     are circle-read-as-square and triangle-read-as-circle; the SQUARE is
#     the one that survives all the way down, which is the opposite of what
#     one would guess and the reason this is measured rather than reasoned.
#
#     SO: 12 PIXELS ACROSS is the floor, and that is asserted. What the
#     plugin actually asks for: the medium scatter dot is 39 px on a 6 x 4
#     figure and 111 px on a 12 x 7 one; spaghetti and time-series markers
#     are set in millimetres with a floor of 1.0 mm radius, so never below
#     24 px. The one place the floor can be reached is the SMALL scatter dot
#     on a small panel -- 0.008 x markerSize x the inner width -- which is
#     21 px on a 6 x 4 figure but about 8 px on a 3 x 3 one. At that size the
#     triangle still reads and the circle and the square do not reliably
#     separate. That is stated, not fixed: changing the small dot size is a
#     change to a setting the user chose, and the cap the author asked for is
#     24 regardless.
fl_p <- repo_path("harness", "markers", "out", "FLOOR.tsv")
if (!file.exists(fl_p))
    stop(sprintf("v29: %s missing -- run harness/markers/run.sh first", fl_p))
fl <- read.delim(fl_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("px", "style", "marker", "verdict", MK_ROWCOLS))
for (cc in setdiff(names(fl), "verdict"))
    fl[[cc]] <- suppressWarnings(as.numeric(fl[[cc]]))
check("v29", "the size ladder rendered 8 widths x 3 shapes",
      nrow(fl), 24, tol = 0)
check("v29", "no ladder render failed", sum(fl$verdict != "OK"), 0, tol = 0)
check_true("v29", "the ladder reaches below the plugin's smallest marker",
           min(fl$px) <= 8 && max(fl$px) >= 30)

fl_rows <- as.matrix(fl[, MK_ROWCOLS])
fl_rows[!is.finite(fl_rows)] <- 0
fl_obs  <- fl_rows / pmax(apply(fl_rows, 1, max), 1e-9)
fl_rms  <- vapply(1:3, function(k)
    sqrt(rowMeans((fl_obs - matrix(MK_TPL[k, ], nrow(fl_obs), 16L,
                                   byrow = TRUE))^2)),
    numeric(nrow(fl_obs)))
fl$got    <- max.col(-fl_rms, ties.method = "first")
fl$margin <- apply(fl_rms, 1, function(r) diff(sort(r)[1:2]))

MARKER_FLOOR_PX <- 12
for (p in sort(unique(fl$px[fl$px >= MARKER_FLOOR_PX]))) {
  x <- fl[fl$px == p, ]
  check("v29", sprintf("at %d px across, all three shapes are recovered", p),
        sum(x$got == x$marker), 3, tol = 0)
}
fl_ok <- fl[fl$px >= MARKER_FLOOR_PX, ]
check_true("v29",
           sprintf("above the %d px floor the worst margin is %.4f (>= 0.02)",
                   MARKER_FLOOR_PX, min(fl_ok$margin)),
           min(fl_ok$margin) >= 0.02)
# Which shape survives furthest down, stated as a fact rather than left to
# intuition: it is the square, at every rung including 5 px. The triangle and
# the circle both give way below the floor.
fl_sq <- fl[fl$marker == 2, ]
check("v29", "the square is recovered at every rung, down to 5 px across",
      sum(fl_sq$got == 2), nrow(fl_sq), tol = 0)
check_true("v29",
           sprintf("below the floor %d of %d rungs mis-read, all of them circle or triangle",
                   sum(fl$px < MARKER_FLOOR_PX & fl$got != fl$marker),
                   sum(fl$px < MARKER_FLOOR_PX)),
           all(fl$marker[fl$px < MARKER_FLOOR_PX & fl$got != fl$marker] != 2))
# ...and the plugin's own medium dot sits well clear of the floor.
check_true("v29",
           sprintf("the medium scatter dot is %.0f px across, %.1fx the floor",
                   2 * min(mk_pt_px) / 3,
                   (2 * min(mk_pt_px) / 3) / MARKER_FLOOR_PX),
           2 * min(mk_pt_px) / 3 >= 2 * MARKER_FLOOR_PX)

# 7. NATIVE PRIMITIVES, NOT ASSETS. The author's instruction was conditional
#    -- "IF these are gonna be sprites" -- and they are not, so the code must
#    not have grown a raster path, and the dead sprite array must not have
#    been wired into the live one. @emlDrawMarker is read as a block.
mk_beg <- grep("^procedure emlDrawMarker:", trimws(pal_src))
check("v29", "@emlDrawMarker exists exactly once", length(mk_beg), 1, tol = 0)
if (length(mk_beg) == 1L) {
  mk_end <- grep("^endproc$", trimws(pal_src))
  mk_end <- min(mk_end[mk_end > mk_beg])
  mk_body <- trimws(pal_src[mk_beg:mk_end])
  mk_body <- mk_body[!startsWith(mk_body, "#")]
  check("v29", "@emlDrawMarker stamps no image file",
        sum(grepl("Insert picture from file", mk_body, fixed = TRUE)), 0, tol = 0)
  check("v29", "@emlDrawMarker consults no sprite state",
        sum(grepl("[Ss]prite", mk_body)), 0, tol = 0)
  for (prim in c("Paint circle:", "Paint rectangle:"))
    check_true("v29", sprintf("@emlDrawMarker draws with %s", prim),
               any(grepl(prim, mk_body, fixed = TRUE)))
}
# No NEW asset was committed for this. plugin/sprites/ already holds 204
# PNGs -- it does exist, whatever the 6 Aug audit note says -- but every one
# of them is a dot, a rectangle or a background, indexed by HUE. If the
# marker work had gone the sprite route it would have added a shape axis to
# that naming scheme, and the check that catches it is "the set still
# contains only the three stems it contained before".
mk_sprites <- list.files(repo_path("plugin", "sprites"), pattern = "\\.png$")
check_true("v29", "the sprite set is still the pre-existing alpha set",
           length(mk_sprites) > 0 &&
           all(grepl("^(dot|rect|bg)_", mk_sprites)))
check("v29", "no shape-indexed sprite was added",
      sum(grepl("(square|triangle|tri_|sq_)", mk_sprites)), 0, tol = 0)
check("v29", "no marker asset was committed under plugin/graphs/assets",
      length(list.files(repo_path("plugin", "graphs", "assets"),
                        pattern = "\\.png$")),
      0, tol = 0)
# ...and the one place the sprite branch could still swallow a shape is the
# scatter, which is the only point chart that has one. It must stand down
# once the hues run out, or on macOS and Windows -- the two platforms where
# Praat can actually stamp an image -- groups 9 and 1 would both draw
# translucent circles and be indistinguishable again, invisibly from here.
check("v29", "the scatter drops its circle-only sprites above eight groups",
      sum(grepl("^if \\.nGroups > emlSetColorPalette\\.nHues$",
                trimws(draw_src))),
      1, tol = 0)

# 8. THE PALETTE CARRIES THE SHAPE, AND EVERY POINT CHART READS IT. A palette
#    that declares a marker and a draw procedure that ignores it is D127
#    again, in the array that was added to fix it.
check("v29", "@emlSetColorPalette declares three markers",
      sum(grepl("^\\.nMarkers[[:space:]]*=[[:space:]]*3$", pal_code)),
      1, tol = 0)
check_true("v29", "slot -> marker is (slot - 1) div 8, the same as the pattern",
           any(grepl("^\\.marker\\[\\.i\\] = \\(\\(\\(\\.i - 1\\) div \\.nHues\\) mod \\.nMarkers\\) \\+ 1$",
                     pal_code)))
check("v29", "every call to @emlDrawMarker passes a palette marker",
      sum(grepl("@emlDrawMarker:", code_stmt)) -
      sum(grepl("@emlDrawMarker:.*emlSetColorPalette\\.marker\\[", code_stmt)),
      0, tol = 0)
# The four chart types the ruling names. Each must call the marker procedure
# inside its own body, which is what "the dots carry the shape" means.
mk_procs <- c(emlDrawScatterPlot = 1, emlDrawSpaghettiPlot = 1,
              emlDrawTimeSeries = 1, emlDrawTimeSeriesCI = 1)
draw_starts <- grep("^procedure ", trimws(draw_src))
for (pr in names(mk_procs)) {
  b <- grep(sprintf("^procedure %s[:[:space:]]", pr), trimws(draw_src))
  if (!check("v29", sprintf("@%s is declared once", pr), length(b), 1, tol = 0))
      next
  e <- draw_starts[draw_starts > b]
  e <- if (length(e)) min(e) - 1L else length(draw_src)
  body <- trimws(draw_src[b:e])
  body <- body[!startsWith(body, "#")]
  check_true("v29", sprintf("@%s draws its points through @emlDrawMarker", pr),
             any(grepl("@emlDrawMarker:", body, fixed = TRUE)))
  check_true("v29", sprintf("@%s sets the legend's marker key", pr),
             any(grepl("^legendMarkered = 1$", body)) &&
             any(grepl("^legendMarker\\[", body)))
}
# ...and the flags are CLEARED where every other legend flag is cleared, or a
# scatter drawn after a grouped violin in one session inherits its swatches.
check_true("v29", "@emlSetColorPalette clears the marker-key flags",
           any(grepl("^legendMarkered = 0$", pal_code)) &&
           any(grepl("^legendMarkerLine = 0$", pal_code)))

# ===========================================================================
# THE WIDENED GREYSCALE RAMP
# ===========================================================================
# Author's ruling, 7 Aug 2026: "It seems to me that you have a very narrow
# grayscale range that you are trying to cram a very large number of
# gradations into. Can we make sure that we have a wide range across the
# entire potential palette?"
#
# THE RANGE THAT WAS THERE. v1.22 and earlier: ten fills between 0.82 and
# 0.96 -- a span of 0.14, fifteen thousandths apart at the closest pair.
# v1.23 replaced that with eight fills from 0.90 down to 0.25, a span of
# 0.65, measured at 0.090 apart on the rendered pixels. That is the number
# this section replaces.
#
# WHAT BOUNDED IT, and it was not the eye. The stroke was DERIVED from the
# fill as fill - 0.30 clamped at zero, so a fill below 0.30 produced a stroke
# ramp that collapsed -- and at 0.25 it already had: the two darkest strokes
# were 0.043 and 0.000. A greyscale LINE chart draws in .line$ and never
# touches .fill$, so at eight groups two of its series were in
# indistinguishable ink. Widening the fills without decoupling the strokes
# would have made that worse.
#
# THE RANGE NOW. Two independent ramps: fills 0.94 down to 0.10 in steps of
# 0.12 (a span of 0.84, or 84% of everything between white and black), and
# strokes 0.63 down to 0.00 in steps of 0.09. The ends are where they are for
# reasons that can be stated: above 0.94 a fill stops separating from the
# page it is printed on, and below 0.10 it stops separating from the axis and
# text ink, which is {0.1, 0.1, 0.1}. A stroke paler than 0.63 stops reading
# as a 1-point line on white. Neither end is a round number chosen for looks;
# both are the last usable step.
#
# The cost of the wider fills is that a dark fill can swallow its own stroke,
# and that is paid by @emlMarkInk rather than by a narrower ramp: the mark's
# outline, median, whiskers and hatch flip to white on a dark fill and black
# on a light one, by the same rule the hatch already used. Slots 4-8 flip.
# ===========================================================================
GREY_OLD_SPAN <- 0.65      # 0.90 -> 0.25, v1.23
GREY_NEW_SPAN <- 0.84      # 0.94 -> 0.10, v1.24

# Read the ramp back off the SOURCE, so the span this section claims is the
# span the code declares...
grey_num <- function(pat) {
  hit <- grep(pat, pal_code, value = TRUE)
  if (!length(hit)) return(NA_real_)
  as.numeric(sub(".*=[[:space:]]*", "", hit[1]))
}
grey_fill_max <- grey_num("^\\.fillMax[[:space:]]*=")
grey_fill_min <- grey_num("^\\.fillMin[[:space:]]*=")
grey_ink_max  <- grey_num("^\\.inkMax[[:space:]]*=")
grey_ink_min  <- grey_num("^\\.inkMin[[:space:]]*=")
check("v29", "the greyscale fill ramp spans 0.94 down to 0.10",
      grey_fill_max - grey_fill_min, GREY_NEW_SPAN, tol = 1e-9)
check_true("v29",
           sprintf("the fill span widened from %.2f to %.2f (+%.0f%%)",
                   GREY_OLD_SPAN, grey_fill_max - grey_fill_min,
                   100 * ((grey_fill_max - grey_fill_min) / GREY_OLD_SPAN - 1)),
           grey_fill_max - grey_fill_min > GREY_OLD_SPAN)
check_true("v29", "the stroke ramp is declared separately, not derived from the fill",
           is.finite(grey_ink_max) && is.finite(grey_ink_min) &&
           grey_ink_max - grey_ink_min > 0.6)
# ...and that BOTH places that build the ramp use the same four endpoints.
# @emlOptimizePaletteContrast recomputes it for K groups, and until v1.23 the
# two disagreed silently.
for (nm in c("fillMax", "fillMin", "inkMax", "inkMin"))
  check("v29", sprintf("the %s endpoint is declared identically in both places", nm),
        length(unique(grep(sprintf("^\\.%s[[:space:]]*=", nm),
                           pal_code, value = TRUE))), 1, tol = 0)
check("v29", "the stroke is nowhere still derived as fill - 0.30",
      sum(grepl("^\\.lineVal = max \\(0, \\.fillVal - 0\\.30\\)$", pal_code)),
      0, tol = 0)

# THE MEASURED SEPARATION, on the pixels, not on the declared numbers.
# harness/patterns/run.sh renders each greyscale slot as a violin, a box and a
# legend swatch; the (min, max) pair per channel describes the mark
# completely, because a mark is exactly its fill and its ink.
grey_min_sep <- Inf
for (sh in STY_SHAPES) {
  x <- sty[sty$mode == "bw" & sty$shape == sh, ]
  x <- x[order(x$style), ]
  got <- vapply(seq_len(N_STYLES), function(i) sty_class(x[i, ]), integer(1))
  prs <- t(vapply(seq_len(N_STYLES), function(i) sty_pair(x[i, ]), numeric(6)))
  for (i in seq_len(N_STYLES - 1L))
    for (j in (i + 1L):N_STYLES)
      if (got[i] == got[j])
        grey_min_sep <- min(grey_min_sep, max(abs(prs[i, ] - prs[j, ])))
}
GREY_OLD_MEASURED <- 0.090   # v1.23, same measurement, same harness
check_true("v29",
           sprintf("MEASURED minimum greyscale separation is %.4f, was %.4f (+%.0f%%)",
                   grey_min_sep, GREY_OLD_MEASURED,
                   100 * (grey_min_sep / GREY_OLD_MEASURED - 1)),
           grey_min_sep > GREY_OLD_MEASURED)
check_true("v29",
           sprintf("...and it clears 0.110 (measured %.4f)", grey_min_sep),
           grey_min_sep >= 0.110)

# THE HATCH SURVIVES BOTH ENDS OF THE NEW RAMP. Widening the fills moves
# slots across @emlMarkInk's flip threshold, so the check is not "the ink
# rule exists" but "the two colours actually on the paper are far apart",
# taken at the LIGHTEST hatched slot (9, fill 0.94) and the DARKEST (16,
# fill 0.10) -- the two the widening created.
for (sh in STY_SHAPES) {
  x <- sty[sty$mode == "bw" & sty$shape == sh, ]
  for (sl in c(9L, 16L)) {
    r <- x[x$style == sl, ]
    sep <- max(abs(c(r$mxR - r$mnR, r$mxG - r$mnG, r$mxB - r$mnB)))
    check_true("v29",
               sprintf("bw/%s: slot %d's hatch stands %.3f off its fill (>= 0.25)",
                       sh, sl, sep),
               sep >= 0.25)
  }
}
# The same at the ends of the SOLID band, which is where a fill that has
# stopped separating from the white page would show first.
sv <- sty[sty$mode == "bw" & sty$shape == "violin", ]
check_true("v29",
           sprintf("the lightest greyscale fill renders at %.3f, clear of the page",
                   max(sv$mr[sv$style <= 8])),
           max(sv$mr[sv$style <= 8]) <= 0.95)
check_true("v29",
           sprintf("the darkest greyscale fill renders at %.3f, clear of the text ink",
                   min(sv$mr[sv$style <= 8])),
           min(sv$mr[sv$style <= 8]) >= 0.06)

# Finally: the driver must not have failed anything else while producing
# this evidence. Read from the same TSV so the two cannot disagree.
check("v29", "no disclosure case failed to draw",
      sum(res$verdict != "OK"), 0, tol = 0)

if (!exists("EML_SUITE")) { eml_report("v29 figure disclosure (Annotate ruling)"); eml_exit() }
