# ===========================================================================
# v92 — Wilson confidence interval vs R prop.test (survey-stats lane)
# ===========================================================================
# Drives @emlWilsonInterval (plugin/stats/eml-categorical.praat) LIVE on
# the nine committed cases (central, near 0, near 1, n = 5, n = 1000,
# x = 0, x = n, and two non-default confidence levels) and settles both
# bounds and the point estimate against R's prop.test(correct = FALSE),
# whose confidence interval is the Wilson score interval — the same
# numbers binom::binom.confint(method = "wilson") returns (binom is not
# installable in the validation sandbox; CRAN is unreachable). Two
# hand-pinned literature values (Newcombe 1998, Statistics in Medicine
# 17, 857–872, Table I: x = 81, n = 263 and x = 15, n = 148) pin the
# oracle itself against print.
#
# The endpoint cases are the point of Wilson: at x = 0 and x = n the
# run also asserts the interval has POSITIVE width, which the Wald
# interval fails (zero width) exactly there.
#
# Negative control: a scratch copy of the kernel with a seeded one-sided
# z (alpha instead of alpha/2) is driven on the central case, and the
# run asserts the defective bounds DIFFER from the oracle. Set
# EML_LANE_RED=1 to watch the named agreement check go red.
#
# NOT registered in validate/run_all.R: this is lane work; the merging
# session registers it after the release round closes.
# ===========================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

red_mode <- nzchar(Sys.getenv("EML_LANE_RED", unset = ""))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")

praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pv <- NA_character_
pvnum <- 0
if (nzchar(praat) && file.exists(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}
canDrive <- pvnum >= 6630

# The oracle pins itself against print before it judges the kernel:
# Newcombe (1998), Table I, method 3 (Wilson), 95%.
nc1 <- prop.test(81, 263, correct = FALSE)$conf.int
check("v92", "oracle vs Newcombe 1998 print, x=81 n=263, lower",
      round(nc1[1], 4), 0.2553, tol = 5e-5)
check("v92", "oracle vs Newcombe 1998 print, x=81 n=263, upper",
      round(nc1[2], 4), 0.3662, tol = 5e-5)
nc2 <- prop.test(15, 148, correct = FALSE)$conf.int
check("v92", "oracle vs Newcombe 1998 print, x=15 n=148, lower",
      round(nc2[1], 4), 0.0624, tol = 5e-5)
check("v92", "oracle vs Newcombe 1998 print, x=15 n=148, upper",
      round(nc2[2], 4), 0.1605, tol = 5e-5)

if (!canDrive) {
    cat(paste0("      SKIP: v92 needs Praat >= 6.6.30 to drive the kernel;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true("v92",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v92")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    unlink(file.path(prefs, c("pid", "message")))
    tgt <- file.path(work, "stats")
    if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, "stats")), tgt)

    drive_wilson <- function(stats_dir_rel, x, n, conf, tag) {
        probe <- file.path(work, "scripts", paste0("v92-", tag, ".praat"))
        writeLines(c(
            paste0("include ../", stats_dir_rel, "/eml-categorical.praat"),
            "",
            'writeInfoLine: "v92"',
            sprintf("@emlWilsonInterval: %s, %s, %s",
                    format(x, digits = 17), format(n, digits = 17),
                    format(conf, digits = 17)),
            'appendInfo: "res|", emlWilsonInterval.propHat, "|",',
            '... emlWilsonInterval.ciLow, "|", emlWilsonInterval.ciHigh, "|",',
            '... emlWilsonInterval.error$',
            'appendInfoLine: ""'),
            probe)
        suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
    }

    fld <- function(out, tag) {
        p <- sprintf("^%s\\|", tag)
        h <- grep(p, out, value = TRUE)
        if (!length(h)) return(character(0))
        strsplit(sub(p, "", h[1]), "|", fixed = TRUE)[[1]]
    }
    num <- function(out, tag, i) {
        f <- fld(out, tag)
        if (length(f) < i) return(NA_real_)
        v <- f[i]
        if (identical(v, "--undefined--")) return(NA_real_)
        suppressWarnings(as.numeric(v))
    }

    cases <- read_input("lane_survey_wilson_cases.csv")

    for (i in seq_len(nrow(cases))) {
        cs <- cases[i, ]
        tag <- as.character(cs$case)
        out <- drive_wilson("stats", cs$x, cs$n, cs$conf, tag)
        ran <- !any(grepl("^Error", out)) && length(fld(out, "res")) >= 3
        check_true("v92", sprintf("the %s probe ran", tag), ran)
        if (!ran) {
            cat(sprintf("      v92 %s probe output: %s\n", tag,
                        paste(utils::tail(out, 8), collapse = " / ")))
            next
        }
        ci <- prop.test(cs$x, cs$n, conf.level = cs$conf,
                        correct = FALSE)$conf.int
        check("v92", sprintf("[%s] point estimate x/n", tag),
              num(out, "res", 1), cs$x / cs$n, tol = 0)
        check("v92", sprintf("[%s] Wilson lower bound", tag),
              num(out, "res", 2), ci[1], tol = 1e-10)
        check("v92", sprintf("[%s] Wilson upper bound", tag),
              num(out, "res", 3), ci[2], tol = 1e-10)
        if (cs$x == 0 || cs$x == cs$n) {
            # Where Wilson earns its keep: the Wald interval has zero
            # width at the endpoints; Wilson must not.
            check_true("v92",
                       sprintf("[%s] interval has positive width at the endpoint", tag),
                       num(out, "res", 3) - num(out, "res", 2) > 0.01)
        }
    }

    # Refusals: non-integer successes, x > n, confidence outside (0, 1).
    outb <- drive_wilson("stats", 3.5, 5, 0.95, "bad_x")
    check_true("v92", "non-integer successes are refused",
               is.na(num(outb, "res", 2)))
    outb2 <- drive_wilson("stats", 7, 5, 0.95, "x_gt_n")
    check_true("v92", "successes above n are refused",
               is.na(num(outb2, "res", 2)))
    outb3 <- drive_wilson("stats", 3, 5, 95, "conf_pct")
    check_true("v92", "a confidence level of 95 (not 0.95) is refused",
               is.na(num(outb3, "res", 2)))

    # -----------------------------------------------------------------------
    # NEGATIVE CONTROL — seeded one-sided z (alpha where alpha/2 belongs)
    # -----------------------------------------------------------------------
    mut <- file.path(work, "mutant")
    dir.create(mut, showWarnings = FALSE)
    src <- readLines(file.path(plug, "stats", "eml-categorical.praat"))
    needle <- "invGaussQ ((1 - .confidence) / 2)"
    hit <- grepl(needle, src, fixed = TRUE)
    check_true("v92", "the negative-control seed site exists in source", sum(hit) == 1)
    mut_src <- sub(needle, "invGaussQ (1 - .confidence)", src, fixed = TRUE)
    writeLines(mut_src, file.path(mut, "eml-categorical.praat"))
    tgt2 <- file.path(work, "mutant_link")
    if (!file.exists(tgt2)) file.symlink(mut, tgt2)

    ci <- prop.test(10, 20, conf.level = 0.95, correct = FALSE)$conf.int
    out_mut <- drive_wilson("mutant_link", 10, 20, 0.95, "mutant")
    if (red_mode) {
        cat("      EML_LANE_RED: running the standard agreement check against\n")
        cat("      the defective build — the next check is EXPECTED to FAIL.\n")
        check("v92", "[RED] seeded-defect Wilson lower bound vs oracle (must go red)",
              num(out_mut, "res", 2), ci[1], tol = 1e-10)
    } else {
        check("v92", "seeded one-sided-z lower bound DIFFERS from the oracle",
              num(out_mut, "res", 2), ci[1], tol = 1e-10, expect = "differ")
    }
}

if (!exists("EML_SUITE")) { eml_report("v92 Wilson interval oracle"); eml_exit() }
