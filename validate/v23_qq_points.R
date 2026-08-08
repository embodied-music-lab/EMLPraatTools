# ============================================================================
# v23_qq_points.R -- the Q-Q plot's points, against base R.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# What "Draw" produces on the Check Normality wrapper is a scatter of the
# ordered sample against normal order statistics. A figure cannot be read off
# a screen and checked, so harness/qq_drive.sh dumps the point pairs the
# figure was drawn from and this script recomputes them.
#
#     harness/qq_drive.sh              regenerate the inputs to this script
#     Rscript validate/v23_qq_points.R
#
# Input:  harness/qq_out/<case>_points.csv  the plotted pairs
#         harness/qq_out/<case>_status.csv  n, drops, refusal, fit line
#         the ORIGINAL data CSV, read here independently
#
# THE CONVENTION THIS SCRIPT PINS
# -------------------------------
# The theoretical axis comes from @emlShapiroWilk's own Blom normal scores,
#
#     m[i] = Phi^-1 ((i - 0.375) / (n + 0.25))
#
# which is qnorm(ppoints(n, a = 3/8)) at every n. R's qqnorm() uses
# ppoints(n), whose default `a` is 3/8 only for n <= 10 and 1/2 above it. So
# the plugin's theoretical axis equals qqnorm()'s EXACTLY at n <= 10 and
# differs from it at n > 10.
#
# Both halves are asserted, and the second is asserted as a DIFFERENCE
# (expect = "differ") rather than quietly widened into a tolerance. A check
# that let 3/8 and 1/2 agree "within tolerance" would pass equally if the
# plugin silently switched conventions, which is the thing worth knowing.
#
# DISCLOSURE (added 7 Aug 2026, D119)
# -----------------------------------
# @emlDrawQQPlot used to write "n = N, Blom plotting positions" into
# emlSubtitle$, saving and restoring the global around the call. The global
# survived, so nothing downstream could see it; the DRAWN figure did not.
# emlSubtitle$ is the user's own field -- the graphs form asks for it
# ("Subtitle") and persists it to config -- so a user who had typed a subtitle
# got a machine-generated tail appended after " | " on the figure, ticked or
# not. @emlDrawTimeSeries and @emlDrawBarChart carried the same defect (D112)
# and were fixed the day before; this file was written the day before that and
# repeated it.
#
# Three things are asserted here, and the second is the one that stops the
# defect recurring:
#
#   1. THE SENTINEL. harness/qq_cases/qq_drive.praat sets emlSubtitle$ to
#      SENTINEL-SUBTITLE before calling @emlDrawQQPlot and writes it back out
#      afterwards. Anything but the sentinel means the Q-Q path wrote to the
#      user's field. Asserted on every case, refusals included: a refusal that
#      scribbled on the subtitle before deciding not to draw would be just as
#      wrong. A save-and-restore would PASS this check, which is why it is not
#      the only thing checked -- see 3.
#
#   2. BOTH DIRECTIONS OF THE ANNOTATE GATE. The ruling is "draw the image as
#      the image unless someone asks to annotate": the Info window always, the
#      figure only when Annotate is ticked. Four cases are driven twice, once
#      with the tick and once without, and the OFF direction -- no line on the
#      figure -- is asserted as hard as the ON direction. It is checked three
#      ways, because two of them could be fooled alone: the ledger
#      @emlDiscloseBegin leaves behind (disclose_fig_n), the dump of what
#      reached the figure (<case>_disclosure.tsv), and the INK of the two
#      renders, which is the only one of the three that reads the PNG.
#
#   3. STATICALLY, that the assignment is gone from the source and that the
#      wording goes through @emlDisclose. Driving the code cannot catch a new
#      procedure adopting the idiom, and a save-and-restore round-trips
#      invisibly; reading the file does catch both. Same construct-level ban
#      validate/v29_figure_disclosure.R applies to the draw library, applied
#      here to the one graphs file that was outside its reach when it was
#      written.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

qq_dir <- repo_path("harness", "qq_out")

# case | source CSV, relative to the repo root | column | expectation |
# annotate (the user's tick, as harness/qq_drive.sh drove it)
#
# The four _annot rows are the SAME data and the SAME column as the row above
# them, drawn a second time with Annotate on. Every numeric check below runs
# on them too -- a figure whose points moved when the user ticked a checkbox
# would be a defect of its own -- and the disclosure block at the end pairs
# each with its Annotate-off twin.
cases <- rbind(
  data.frame(case = "v15_f0",        src = "evidence/csv/v15_normality_input.csv",  col = "F0_Hz",       expect = "draw",   annot = 0L),
  data.frame(case = "v15_shimmer",   src = "evidence/csv/v15_normality_input.csv",  col = "shimmer_pct", expect = "draw",   annot = 0L),
  data.frame(case = "v15_jitter",    src = "evidence/csv/v15_normality_input.csv",  col = "jitter_pct",  expect = "draw",   annot = 0L),
  data.frame(case = "r1_na_soft",    src = "validate/redpath/r1_incomplete_cases.csv", col = "SPL_soft",   expect = "draw",   annot = 0L),
  data.frame(case = "r1_na_medium",  src = "validate/redpath/r1_incomplete_cases.csv", col = "SPL_medium", expect = "draw",   annot = 0L),
  data.frame(case = "r1_na_loud",    src = "validate/redpath/r1_incomplete_cases.csv", col = "SPL_loud",   expect = "draw",   annot = 0L),
  data.frame(case = "qq_n3",         src = "harness/qq_cases/qq_n3.csv",            col = "value",       expect = "draw",   annot = 0L),
  data.frame(case = "qq_n10",        src = "harness/qq_cases/qq_n10.csv",           col = "value",       expect = "draw",   annot = 0L),
  data.frame(case = "qq_skewed",     src = "harness/qq_cases/qq_skewed.csv",        col = "value",       expect = "draw",   annot = 0L),
  data.frame(case = "r2_n2",         src = "validate/redpath/r2_two_subjects.csv",  col = "SPL_soft",    expect = "refuse", annot = 0L),
  data.frame(case = "r3_constant",   src = "validate/redpath/r3_zero_variance.csv", col = "SPL_medium",  expect = "refuse", annot = 0L),
  data.frame(case = "qq_na_below_3", src = "harness/qq_cases/qq_na_below_3.csv",    col = "value",       expect = "refuse", annot = 0L),
  data.frame(case = "v15_f0_annot",       src = "evidence/csv/v15_normality_input.csv",     col = "F0_Hz",      expect = "draw", annot = 1L),
  data.frame(case = "r1_na_medium_annot", src = "validate/redpath/r1_incomplete_cases.csv", col = "SPL_medium", expect = "draw", annot = 1L),
  data.frame(case = "qq_n3_annot",        src = "harness/qq_cases/qq_n3.csv",               col = "value",      expect = "draw", annot = 1L),
  data.frame(case = "qq_skewed_annot",    src = "harness/qq_cases/qq_skewed.csv",           col = "value",      expect = "draw", annot = 1L),
  stringsAsFactors = FALSE)

# The Annotate-off twin of each annotated case, by name. Used at the end for
# the ink comparison, which is the only assertion here that reads a pixel.
twin_of <- c(v15_f0_annot       = "v15_f0",
             r1_na_medium_annot = "r1_na_medium",
             qq_n3_annot        = "qq_n3",
             qq_skewed_annot    = "qq_skewed")

# The exact on-figure wording, rebuilt from n and the drop count rather than
# copied out of the artefact. A test that read the plugin's own string back
# and compared it with itself would pass whatever the plugin wrote.
qq_fig_lines <- function(n, ndrop) {
  out <- sprintf("n = %d, Blom plotting positions (a = 3/8).", n)
  if (ndrop > 0)
    out <- c(out, sprintf("%d row(s) excluded as missing.", ndrop))
  out
}

# A missing artefact is a hard stop, not a skip. "The driver did not produce
# this" is exactly the failure a silently-shrinking suite would hide.
read_case <- function(cs, suffix) {
  p <- file.path(qq_dir, paste0(cs, suffix))
  if (!file.exists(p))
    stop(sprintf("v23: %s missing -- run harness/qq_drive.sh first", p))
  read.csv(p, stringsAsFactors = FALSE)
}

# The disclosure dump is tab-separated, not comma-separated: the on-figure
# wording contains a comma ("n = 40, Blom plotting positions ...") and Praat's
# CSV reader does not strip quotes, so quoting would embed them in the value.
# quote = "" for the same reason -- nothing in the text is a delimiter, and R
# must not treat an apostrophe as one.
read_disc <- function(cs) {
  p <- file.path(qq_dir, paste0(cs, "_disclosure.tsv"))
  if (!file.exists(p))
    stop(sprintf("v23: %s missing -- run harness/qq_drive.sh first", p))
  read.delim(p, sep = "\t", quote = "", colClasses = "character",
             stringsAsFactors = FALSE)
}

# Praat continues a statement onto the next line with a leading "...", so a
# call and the sentence it carries are different LINES. Folded before any
# statement-level assertion, the way validate/v29_figure_disclosure.R does it.
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

# Comments are stripped first. This defect is DOCUMENTED at length in both
# files' own headers, and a naive grep would fail on the fix's description
# rather than on the defect. In Praat "#" opens a comment only at the start of
# a line and ";" anywhere, but "#" is also the array-type suffix (.theo#), so
# stripping from either only ever shortens a line -- it cannot manufacture a
# match for the patterns below.
praat_statements <- function(path) {
  fold_continuations(trimws(sub("[#;!].*$", "", readLines(path, warn = FALSE))))
}
SUBTITLE_WRITE <- "(^|[^[:alnum:]_.])emlSubtitle\\$[[:space:]]*=[^=]"

for (i in seq_len(nrow(cases))) {
  cs   <- cases$case[i]
  col  <- cases$col[i]
  lab0 <- sprintf("%s [%s]", cs, col)

  raw <- read.csv(repo_path(cases$src[i]), stringsAsFactors = FALSE)
  if (!col %in% names(raw))
    stop(sprintf("v23: column %s not in %s", col, cases$src[i]))
  x_all <- suppressWarnings(as.numeric(raw[[col]]))
  x     <- x_all[!is.na(x_all)]
  n     <- length(x)

  st <- read_case(cs, "_status.csv")
  pt <- read_case(cs, "_points.csv")
  ds <- read_disc(cs)
  log_txt <- readLines(file.path(qq_dir, paste0(cs, ".log")), warn = FALSE)

  check_true("v23", paste(lab0, "status file holds exactly one run"),
             nrow(st) == 1L)

  # ---- the user's subtitle is not the plugin's scratch space --------------
  # THE check that stops D119 recurring. The harness sets emlSubtitle$ to a
  # sentinel before the call; the Q-Q path must hand it back untouched.
  # Asserted on refusals too: a refusal that scribbled on the field before
  # deciding not to draw would be just as wrong, and would leave the damage
  # behind for the next figure.
  check_true("v23", paste(lab0, "emlSubtitle$ came back as the sentinel"),
             identical(st$subtitle_after[1], "SENTINEL-SUBTITLE"))
  # The same fact as a LENGTH, which is not redundant reporting: the defect
  # appended after " | ", so when this one fails the number says how many
  # characters the user did not type, and separates "appended to" from
  # "replaced with something else the same size".
  check("v23", paste(lab0, "nothing was appended to the user's subtitle"),
        nchar(st$subtitle_after[1]), nchar("SENTINEL-SUBTITLE"), tol = 0)

  # The run was driven in the Annotate state this row claims. Without this,
  # both directions of the gate below could be satisfied by the same run.
  check("v23", paste(lab0, "driven with the Annotate state under test"),
        st$annotate[1], cases$annot[i], tol = 0)

  # The temporary point Table @emlDrawQQPlot builds must not outlive the call.
  # The input Table is the only object the driver expects to survive it, so
  # anything above 1 is a leaked object -- a defect class this repo has hit
  # before, and one that shows up in the user's object list, not in a number.
  check("v23", paste(lab0, "no leaked Praat object"),
        st$objects_after_draw[1], 1, tol = 0)

  # Row count read independently of the plugin: what the CSV holds.
  check("v23", paste(lab0, "rows in source table"),
        st$nrows[1], nrow(raw), tol = 0)

  if (cases$expect[i] == "refuse") {
    # ---- RED PATH --------------------------------------------------------
    # A refusal is only correct if R agrees there is nothing to plot. Both
    # legitimate reasons are named here rather than accepting any refusal:
    # too few complete cases, or no variation to spread along an axis.
    warranted <- n < 3 || (n >= 3 && var(x) == 0)
    check_true("v23", paste(lab0, "refused"), st$refused[1] == 1L)
    check_true("v23", paste(lab0, "refusal is warranted by R"), warranted)
    check_true("v23", paste(lab0, "refusal names a reason"),
               nzchar(st$reason[1]) && st$reason[1] != "-")
    # A refusal must draw NOTHING. A refusal that still emitted points would
    # be the garbage figure the refusal exists to prevent.
    check("v23", paste(lab0, "no points plotted"), nrow(pt), 0, tol = 0)
    check_true("v23", paste(lab0, "no figure written"),
               !file.exists(file.path(qq_dir, paste0(cs, ".png"))))
    check("v23", paste(lab0, "reported n = complete cases"),
          st$n[1], n, tol = 0)
    # A refusal discloses nothing, to either channel. There is no figure for
    # a note to be about, and a note in the Info window claiming an n that was
    # never plotted would be worse than silence.
    check("v23", paste(lab0, "refusal discloses nothing to the Info window"),
          st$disclose_info_n[1], 0, tol = 0)
    check("v23", paste(lab0, "refusal discloses nothing to the figure"),
          st$disclose_fig_n[1], 0, tol = 0)
    check("v23", paste(lab0, "refusal wrote no disclosure lines"),
          nrow(ds), 0, tol = 0)
    next
  }

  # ---- GREEN PATH --------------------------------------------------------
  check_true("v23", paste(lab0, "drew"), st$refused[1] == 0L)
  check("v23", paste(lab0, "points plotted = complete cases"),
        nrow(pt), n, tol = 0)
  check("v23", paste(lab0, "reported n = complete cases"), st$n[1], n, tol = 0)
  check("v23", paste(lab0, "reported drops = incomplete cases"),
        st$ndropped[1], sum(is.na(x_all)), tol = 0)

  lab <- sprintf("%s [%s n=%d drop=%d]", cs, col, n, sum(is.na(x_all)))

  # No undefined ever reached the figure. This is the specific damage an
  # unfiltered NA would do: sort# would place it somewhere and pair it with a
  # normal score belonging to a different observation.
  check_true("v23", paste(lab, "no non-finite plotted value"),
             all(is.finite(pt$theoretical)) && all(is.finite(pt$sample)))

  # ---- the sample axis IS the data, in order -----------------------------
  check("v23", paste(lab, "sample axis = sorted complete cases (max dev)"),
        max(abs(pt$sample[order(pt$i)] - sort(x))), 0, tol = 1e-9)

  # ---- the theoretical axis ----------------------------------------------
  blom <- qnorm(ppoints(n, a = 3/8))
  check("v23", paste(lab, "theoretical = qnorm(ppoints(n, a=3/8)) (max dev)"),
        max(abs(pt$theoretical[order(pt$i)] - blom)), 0, tol = 1e-12)

  # R's own qqnorm, on the same column, sorted to the same order. qqnorm
  # returns its x in the ORDER OF THE INPUT, so it is sorted here rather than
  # assumed; a plugin that plotted unsorted scores would fail the pairing
  # check above, not this one.
  qq <- sort(qqnorm(x, plot.it = FALSE)$x)
  dev_qq <- max(abs(pt$theoretical[order(pt$i)] - qq))
  if (n <= 10) {
    check("v23", paste(lab, "theoretical = qqnorm()$x (max dev)"),
          dev_qq, 0, tol = 1e-12)
  } else {
    # DELIBERATE, DOCUMENTED DIFFERENCE. ppoints switches a from 3/8 to 1/2
    # above n = 10; the plugin does not, because these are the same normal
    # scores the reported Shapiro-Wilk W was built from. Asserted as a
    # difference so that a silent convention change fails here.
    check("v23", paste(lab, "theoretical differs from qqnorm()$x above n=10"),
          dev_qq, 0, tol = 1e-9, expect = "differ")
    # ...and bounded by the analytic gap between the two conventions, so the
    # difference is the CONVENTION and not an error hiding behind it.
    bound <- max(abs(qnorm(ppoints(n, a = 3/8)) - qnorm(ppoints(n, a = 1/2))))
    check("v23", paste(lab, "qqnorm gap = the 3/8 vs 1/2 gap"),
          dev_qq, bound, tol = 1e-12)
  }

  # ---- the reference line -------------------------------------------------
  # The drawn line is @emlDrawScatterPlot's OLS fit through the plotted
  # points. Checked against lm() on the points R reconstructed, not on the
  # points Praat dumped, so a wrong pairing would move the line.
  fit <- lm(sort(x) ~ blom)
  check("v23", paste(lab, "reference-line slope"),
        st$slope[1], unname(coef(fit)[2]), tol = 1e-8)
  check("v23", paste(lab, "reference-line intercept"),
        st$intercept[1], unname(coef(fit)[1]), tol = 1e-8)

  # ---- the figure and the test see the same points ------------------------
  # The wrapper prints Shapiro-Wilk beside the figure. If the two ever
  # disagreed about which values were in play, this is where it would show.
  sw <- shapiro.test(x)
  check("v23", paste(lab, "Shapiro-Wilk W of the plotted points"),
        st$sw_w[1], unname(sw$statistic), tol = 1e-6)

  # ---- the figure exists and is not an empty frame ------------------------
  # harness/qq_drive.sh does the ink comparison against each figure's own
  # chrome; here we assert only that both renders reached disk, so a green
  # numeric run cannot be reported without the visual evidence beside it.
  check_true("v23", paste(lab, "figure written"),
             file.exists(file.path(qq_dir, paste0(cs, ".png"))))
  check_true("v23", paste(lab, "chrome-only reference written"),
             file.exists(file.path(qq_dir, paste0(cs, "_chrome.png"))))

  # ---- the disclosure, and the gate on it ---------------------------------
  # The expected wording is REBUILT from n and the drop count, not read back
  # out of the artefact. A check that compared the plugin's string with itself
  # would pass whatever the plugin wrote.
  want <- qq_fig_lines(n, sum(is.na(x_all)))

  # The Info window: ALWAYS, whatever the user ticked. This is the half of the
  # ruling that costs the figure nothing, so it is not conditional on annot.
  check("v23", paste(lab, "Info window carried every disclosure"),
        st$disclose_info_n[1], length(want), tol = 0)
  # startsWith, not grepl: the wording contains "(", ")" and "." and would be
  # read as a regular expression, in which "(a = 3/8)" is a capture group that
  # matches the text WITHOUT its parentheses -- so a pattern built that way
  # fails on correct output and would have been "fixed" by loosening it.
  check_true("v23", paste(lab, "Info line names n and the plotting positions"),
             any(startsWith(log_txt, paste0("Normal Q-Q plot: ", want[1]))))
  # The load-bearing half of the note. validate/v23 asserts a few lines above
  # that this axis DIFFERS from qqnorm()$x past n = 10; a reader laying the
  # figure beside qqnorm() output has to be told that, or the difference this
  # script deliberately preserves reads as a bug in the plugin.
  check_true("v23", paste(lab, "Info line warns qqnorm() differs above n = 10"),
             any(grepl("qqnorm() uses a = 1/2 above n = 10", log_txt,
                       fixed = TRUE)))
  if (sum(is.na(x_all)) > 0)
    check_true("v23", paste(lab, "Info line reports the excluded rows"),
               any(startsWith(log_txt, paste0("Normal Q-Q plot: ", want[2]))))

  # On-figure lines are drawn into a corner box that does not wrap, so a long
  # one sits on the data whichever corner @emlPlaceElements picks.
  # @emlDisclose's contract puts the budget at about 50 characters.
  check_true("v23", paste(lab, "on-figure wording fits the 50-char budget"),
             all(nchar(want) <= 50))

  # The figure: ONLY when Annotate is ticked. The OFF direction is the ruling
  # -- "draw the image as the image unless someone asks to annotate" -- so it
  # is asserted as hard as the ON direction, and on the same two channels.
  if (cases$annot[i] == 1L) {
    check("v23", paste(lab, "Annotate ON: ledger counts every line"),
          st$disclose_fig_n[1], length(want), tol = 0)
    check("v23", paste(lab, "Annotate ON: that many lines reached the figure"),
          nrow(ds), length(want), tol = 0)
    check_true("v23", paste(lab, "Annotate ON: figure carries the exact wording"),
               identical(ds$text, want))
  } else {
    check("v23", paste(lab, "Annotate OFF: ledger is empty"),
          st$disclose_fig_n[1], 0, tol = 0)
    check("v23", paste(lab, "Annotate OFF: nothing reached the figure"),
          nrow(ds), 0, tol = 0)
  }
}

# The driver's own verdicts, so a MISMATCH there cannot pass unnoticed when
# only this script is run.
res_p <- file.path(qq_dir, "RESULTS.tsv")
if (!file.exists(res_p))
  stop("v23: harness/qq_out/RESULTS.tsv missing -- run harness/qq_drive.sh")
res <- read.delim(res_p, header = FALSE, stringsAsFactors = FALSE,
                  col.names = c("case", "expect", "verdict", "ink", "agree"))
check("v23", "driver ran every case", nrow(res), nrow(cases), tol = 0)
check_true("v23", "driver verdicts all agree with expectation",
           all(res$agree == "OK"))

# ---------------------------------------------------------------------------
# THE GATE, IN PIXELS
#
# The ledger and the disclosure dump are both written by the same Praat run
# that drew the figure, so both would agree with each other if @emlDisclose
# recorded a line it never rendered. The ink fraction is measured from the
# PNG by harness/qq_drive.sh, after the fact, and is the only assertion here
# that has looked at the image. Each annotated case must carry strictly more
# ink than its Annotate-off twin -- same data, same dots, same fitted line,
# so the only thing that can differ is the disclosure box.
#
# The 0.05 margin is the driver's own blank-frame margin. Measured gaps on
# 7 Aug 2026 were 0.26 to 0.44 percentage points, so this is not a hairline.
# ---------------------------------------------------------------------------
ink_of <- function(nm) {
  r <- res$ink[res$case == nm]
  if (!length(r)) return(NA_real_)
  suppressWarnings(as.numeric(sub("/.*$", "", r[1])))
}
for (a in names(twin_of)) {
  p <- twin_of[[a]]
  check_true("v23", sprintf("%s: annotated render carries more ink than %s",
                            a, p),
             isTRUE(ink_of(a) > ink_of(p) + 0.05))
}

# ---------------------------------------------------------------------------
# THE SOURCE, READ RATHER THAN DRIVEN
#
# A save-and-restore around a write to emlSubtitle$ passes the sentinel check
# above -- the global comes back correct and the DRAWN figure still carries
# the tail. That is exactly the shape the defect had. Driving the code cannot
# separate the two; reading it can, so the construct is banned outright, the
# way validate/v29_figure_disclosure.R bans it from the draw library.
#
# The harness driver is read too. It rebuilt the chrome reference and set the
# same caption on the way, so the reference figure carried a subtitle line the
# real figure no longer has.
# ---------------------------------------------------------------------------
qq_stmt <- praat_statements(repo_path("plugin", "graphs", "eml-draw-qq.praat"))
check("v23", "@emlDrawQQPlot does not assign to emlSubtitle$ (the user's field)",
      sum(grepl(SUBTITLE_WRITE, qq_stmt)), 0, tol = 0)
check_true("v23", "@emlDrawQQPlot opens a disclosure batch",
           any(grepl("@emlDiscloseBegin:", qq_stmt, fixed = TRUE)))
check_true("v23", "@emlDrawQQPlot makes at least one disclosure",
           any(grepl("@emlDisclose:", qq_stmt, fixed = TRUE)))
check_true("v23", "@emlDrawQQPlot renders its own disclosure block",
           any(grepl("@emlDiscloseEnd:", qq_stmt, fixed = TRUE)))
# Every statement carrying the plotting-position wording must be a disclosure.
# A bare Text: or an appendInfoLine would reach one channel and never the
# other, which is the half-fix this ruling replaces.
check("v23", "the plotting-position wording only ever goes through @emlDisclose",
      sum(grepl("Blom plotting positions", qq_stmt, fixed = TRUE) &
          !grepl("@emlDisclose", qq_stmt, fixed = TRUE)), 0, tol = 0)

drv_stmt <- praat_statements(repo_path("harness", "qq_cases", "qq_drive.praat"))
check("v23", "harness driver writes emlSubtitle$ exactly once",
      sum(grepl(SUBTITLE_WRITE, drv_stmt)), 1, tol = 0)
check("v23", "and that once is the sentinel, not a caption",
      sum(grepl(SUBTITLE_WRITE, drv_stmt) &
          !grepl("SENTINEL-SUBTITLE", drv_stmt, fixed = TRUE)), 0, tol = 0)

if (!exists("EML_SUITE")) { eml_report("v23 Q-Q plot points"); eml_exit() }
