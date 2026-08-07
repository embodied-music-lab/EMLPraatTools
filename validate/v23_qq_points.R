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
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

qq_dir <- repo_path("harness", "qq_out")

# case | source CSV, relative to the repo root | column | expectation
cases <- rbind(
  data.frame(case = "v15_f0",        src = "evidence/csv/v15_normality_input.csv",  col = "F0_Hz",       expect = "draw"),
  data.frame(case = "v15_shimmer",   src = "evidence/csv/v15_normality_input.csv",  col = "shimmer_pct", expect = "draw"),
  data.frame(case = "v15_jitter",    src = "evidence/csv/v15_normality_input.csv",  col = "jitter_pct",  expect = "draw"),
  data.frame(case = "r1_na_soft",    src = "validate/redpath/r1_incomplete_cases.csv", col = "SPL_soft",   expect = "draw"),
  data.frame(case = "r1_na_medium",  src = "validate/redpath/r1_incomplete_cases.csv", col = "SPL_medium", expect = "draw"),
  data.frame(case = "r1_na_loud",    src = "validate/redpath/r1_incomplete_cases.csv", col = "SPL_loud",   expect = "draw"),
  data.frame(case = "qq_n3",         src = "harness/qq_cases/qq_n3.csv",            col = "value",       expect = "draw"),
  data.frame(case = "qq_n10",        src = "harness/qq_cases/qq_n10.csv",           col = "value",       expect = "draw"),
  data.frame(case = "qq_skewed",     src = "harness/qq_cases/qq_skewed.csv",        col = "value",       expect = "draw"),
  data.frame(case = "r2_n2",         src = "validate/redpath/r2_two_subjects.csv",  col = "SPL_soft",    expect = "refuse"),
  data.frame(case = "r3_constant",   src = "validate/redpath/r3_zero_variance.csv", col = "SPL_medium",  expect = "refuse"),
  data.frame(case = "qq_na_below_3", src = "harness/qq_cases/qq_na_below_3.csv",    col = "value",       expect = "refuse"),
  stringsAsFactors = FALSE)

# A missing artefact is a hard stop, not a skip. "The driver did not produce
# this" is exactly the failure a silently-shrinking suite would hide.
read_case <- function(cs, suffix) {
  p <- file.path(qq_dir, paste0(cs, suffix))
  if (!file.exists(p))
    stop(sprintf("v23: %s missing -- run harness/qq_drive.sh first", p))
  read.csv(p, stringsAsFactors = FALSE)
}

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

  check_true("v23", paste(lab0, "status file holds exactly one run"),
             nrow(st) == 1L)

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

if (!exists("EML_SUITE")) { eml_report("v23 Q-Q plot points"); eml_exit() }
