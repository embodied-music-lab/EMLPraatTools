#!/usr/bin/env Rscript
# ============================================================================
# v158 -- @emlWilcoxonIntervalApprox: the corrected-z inversion, against R
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. mailbox/to-opus/TRACKER_KIT_AND_1p0.md, section A.5,
# lists "Wilcoxon H-L interval, approx branch = port of R's corrected-z
# inversion (intervals item 3.8 ...)" as UNMEASURED. Before building
# anything, that branch was measured directly against R 4.3.3 on real data:
# @emlHodgesLehmannTwoSample and @emlHodgesLehmannPaired
# (plugin_EML_StatsGraphs/stats/eml-inferential.praat) ALREADY invert R's
# continuity-corrected z statistic on their normal-approximation branches,
# and their bounds already agree with wilcox.test(conf.int = TRUE) to full
# double precision. The one gap the measurement found is narrow: the
# PAIRED form's approximation branch can need R's alpha-widening loop
# (small n, a high requested level), and when it does, R issues
# `warning("requested conf.level not achievable")` and reports the
# ACHIEVED level -- the existing wired procedure computes the same
# (correct) bounds but has no channel to say so, only `.error$`, no
# `.warning$` and no achieved-level output.
#
# THIS FILE checks a NEW, STANDALONE module,
# plugin_EML_StatsGraphs/stats/eml-wilcoxon-interval.praat
# (@emlWilcoxonIntervalApprox), built per this task's brief to close that
# gap under the tracker's accepted-but-unapplied `.ok` / `.error$` /
# `.warning$` outcome contract (A.5), WITHOUT touching eml-inferential.praat
# (mid-flux under that same pending item) or wiring the new module into
# anything. It is scoped to the APPROXIMATION BRANCH ONLY -- it does not
# decide exact vs. approximation, so every fixture below drives R with
# `exact = FALSE` to force R onto the identical branch regardless of n or
# ties, per R's own documented escape hatch for that choice.
#
# THE ORACLE. R 4.3.3's wilcox.test(conf.int = TRUE, exact = FALSE), both
# forms:
#   two-sample:  wilcox.test(x, y, conf.int = TRUE, exact = FALSE,
#                             conf.level = L)
#   paired:      wilcox.test(x, y, paired = TRUE, conf.int = TRUE,
#                             exact = FALSE, conf.level = L)
# `exact = FALSE` is R's own parameter for forcing the approximation
# branch at any n -- this is not a workaround, it is the documented way to
# ask wilcox.test for the same branch this module always computes.
#
# THE ESTIMATE is not this file's subject (see the module's own header) and
# is not oracled against R's own $estimate on this branch -- that gap is
# separately documented and ruled to stay (validate/v145_hodges_lehmann_
# interval.R's header). What IS checked here is that the estimate equals
# the median of the cross-differences / Walsh averages directly computed in
# R, which is the quantity the module is specified to report.
#
# COVERAGE. "Both branches" in this file's brief means the module's own two
# computational branches -- two-sample (independent groups) and paired
# (matched pairs / one-sample) -- since the module itself has no
# exact-vs-approximation branch to compare (see above):
#   * a range of sample sizes for each form (n = 3 through 120, matched and
#     unequal group sizes), most with no ties;
#   * a tied fixture for each form, since the tie-corrected SIGMA.CI term
#     is exercised only when NTIES.CI actually has an entry above 1;
#   * the paired form's alpha-widening path, both where it still finds a
#     root (achieved level between 0 and the requested level) and where it
#     exhausts to R's `rep(median(x), 2)` fallback (achieved level 0);
#   * two refusal fixtures (all-tied two-sample; all-equal-pairs paired),
#     checked for a graceful .ok = 0 rather than a numeric oracle -- R
#     itself does not have one here: the two-sample case reproducibly
#     ERRORS inside R (`if (f.lower <= 0)` hits a missing value; measured
#     below, not asserted from memory) rather than returning a value, and
#     the paired case returns NaN/NaN with V = 0.
#
# STANDARD RULE: relative 1e-9, absolute 1e-12 near zero, i.e. a check
# passes when |reported - computed| <= max(1e-12, 1e-9 * |computed|).
#
# HOW TO RUN
#
#     Rscript validate/v158_wilcoxon_interval.R
#
# Requires a Praat at or above the plugin's floor (6.6.30); skips (not
# fails) below it, the v144-v151 convention.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v158"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

STD_REL <- 1e-9
STD_ABS <- 1e-12
std_tol <- function(computed) max(STD_ABS, STD_REL * abs(computed))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)

praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat6630"),
                   Sys.which("praat_barren"), Sys.which("praat"))) {
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

if (!canDrive) {
    cat(paste0("      SKIP: v158 needs Praat >= 6.6.30 to drive the module;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

work <- file.path(tempdir(), "v158")
unlink(work, recursive = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)
prefs <- file.path(work, "prefs")
dir.create(prefs, showWarnings = FALSE)

# ---------------------------------------------------------------------------
# FIXTURES. Each is a scenario id, paired flag, two vectors, and a level.
# Random fixtures are seeded once, up front, so this file's own oracle
# values and the Praat probe's are computed from the identical numbers.
# ---------------------------------------------------------------------------
set.seed(158158)

scenarios <- list()
add <- function(id, paired, x, y, level) {
    scenarios[[id]] <<- list(id = id, paired = paired, x = x, y = y, level = level)
}

# A range of sample sizes, both forms, no ties, at two levels.
for (n in c(3, 5, 8, 16, 32, 64, 120)) {
    x <- round(rnorm(n, 10, 3), 4)
    d <- round(rnorm(n, 0.4, 2), 4)
    add(sprintf("PR_n%d_L95", n), 1, x, x + d, 0.95)
    add(sprintf("PR_n%d_L90", n), 1, x, x + d, 0.90)
}
for (nn in list(c(6, 9), c(20, 25), c(55, 60), c(90, 47))) {
    n1 <- nn[1]; n2 <- nn[2]
    x <- round(rnorm(n1, 5, 2), 4)
    y <- round(rnorm(n2, 6, 2), 4)
    add(sprintf("TS_n%d_%d_L95", n1, n2), 0, x, y, 0.95)
    add(sprintf("TS_n%d_%d_L90", n1, n2), 0, x, y, 0.90)
}

# Tied fixtures, both forms.
add("TS_tied", 0, c(1, 2, 2, 3, 4, 4, 4, 5), c(2, 3, 3, 4, 5, 6, 1, 2), 0.95)
add("PR_tied", 1, c(1, 2, 2, 3, 4, 4, 4, 5), c(2, 3, 3, 4, 4, 4, 1, 2), 0.95)

# The paired alpha-widening path: small n, a high requested level, forcing
# R to double alpha before it can bracket the interval.
add("PR_widen_root", 1, c(-0.626, 0.184, -0.836), c(-0.446, 0.3, -0.777), 0.999)
add("PR_widen_median_fallback", 1, c(-0.626, 0.184), c(-0.568, 0.364), 0.999)

# Refusal fixtures -- checked for graceful .ok = 0, not a numeric oracle.
add("TS_alltied_refusal", 0, c(5, 5, 5), c(5, 5, 5), 0.95)
add("PR_allzero_refusal", 1, c(5, 5, 5), c(5, 5, 5), 0.95)

# ---------------------------------------------------------------------------
# R ORACLE, computed once per scenario (except the two refusal fixtures,
# which R cannot answer -- see the file header).
# ---------------------------------------------------------------------------
oracle <- list()
for (s in scenarios) {
    if (s$id %in% c("TS_alltied_refusal", "PR_allzero_refusal")) next
    r <- if (s$paired == 1) {
        suppressWarnings(wilcox.test(s$x, s$y, paired = TRUE, conf.int = TRUE,
                                      exact = FALSE, conf.level = s$level))
    } else {
        suppressWarnings(wilcox.test(s$x, s$y, conf.int = TRUE,
                                      exact = FALSE, conf.level = s$level))
    }
    oracle[[s$id]] <- list(
        low = r$conf.int[1], high = r$conf.int[2],
        achieved = attr(r$conf.int, "conf.level"),
        estimate = if (s$paired == 1) {
            d <- s$x - s$y
            allW <- outer(d, d, `+`) / 2
            median(allW[!lower.tri(allW)])
        } else {
            median(outer(s$x, s$y, `-`))
        }
    )
}

# The two-sample all-tied case genuinely errors inside R's own root() --
# measured, not assumed -- which is why it is a refusal fixture and not an
# oracled one.
ts_alltied_errors <- inherits(
    tryCatch(suppressWarnings(wilcox.test(c(5, 5, 5), c(5, 5, 5),
                                           conf.int = TRUE, exact = FALSE)),
             error = function(e) e),
    "error")
check_true(V, "[TS_alltied_refusal] R's OWN wilcox.test errors on this input (root() hits NA)",
           ts_alltied_errors)

# ---------------------------------------------------------------------------
# THE PROBE. One Praat run drives every scenario through
# @emlWilcoxonIntervalApprox and prints one RESULT line each. Vectors are
# written with 17 significant digits so the literal Praat parses is the
# identical double R already holds -- not a re-rounded copy of it.
# ---------------------------------------------------------------------------
prelude <- c(
    paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
    paste0("include ", file.path(plug, "stats", "eml-wilcoxon-interval.praat")))

vec_literal <- function(v) paste0("{", paste(sprintf("%.17g", v), collapse = ","), "}")

build_battery <- function() {
    lines <- c(prelude, "")
    for (s in scenarios) {
        lines <- c(lines,
            sprintf("x_%s# = %s", s$id, vec_literal(s$x)),
            sprintf("y_%s# = %s", s$id, vec_literal(s$y)),
            sprintf("@emlWilcoxonIntervalApprox: x_%s#, y_%s#, %d, %s",
                    s$id, s$id, s$paired, format(s$level, digits = 17)),
            paste0(
                'appendInfoLine: "RESULT ', s$id,
                ' ok=", emlWilcoxonIntervalApprox.ok,',
                ' " err=[", emlWilcoxonIntervalApprox.error$, "]",',
                ' " warn=[", emlWilcoxonIntervalApprox.warning$, "]",',
                ' " est=", fixed$ (emlWilcoxonIntervalApprox.estimate, 12),',
                ' " low=", fixed$ (emlWilcoxonIntervalApprox.low, 12),',
                ' " high=", fixed$ (emlWilcoxonIntervalApprox.high, 12),',
                ' " achieved=", fixed$ (emlWilcoxonIntervalApprox.achievedLevel, 12)'
            ))
    }
    probe_path <- file.path(work, "v158-battery.praat")
    writeLines(c('writeInfoLine: "v158"', lines), probe_path)
    probe_path
}

drive <- function(probe_path) {
    suppressWarnings(system2("timeout",
        c("120", "env", "-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
        stdout = TRUE, stderr = TRUE))
}

parse_kv <- function(line) {
    # "RESULT id ok=.. err=[..] warn=[..] est=.. low=.. high=.. achieved=.."
    # err$/warn$ are bracketed and may be empty; every other field is a
    # single space-free token, so splitting on the FIRST two "[...]" runs
    # separately from the rest keeps this simple and exact.
    m <- regmatches(line, regexec(
        '^RESULT (\\S+) ok=(\\S+) err=\\[([^]]*)\\] warn=\\[([^]]*)\\] est=(\\S+) low=(\\S+) high=(\\S+) achieved=(\\S+)$',
        line))[[1]]
    if (length(m) != 9) return(NULL)
    # On the two refusal fixtures est/low/high/achieved are Praat's
    # fixed$() of `undefined` (a non-numeric placeholder string), which
    # is expected -- those fields are never read for a refusal row (see
    # the "ok = 0" branch below) -- so the coercion warning is suppressed
    # rather than left to print for a value nothing consumes.
    list(id = m[2], ok = m[3], err = m[4], warn = m[5],
         est = suppressWarnings(as.numeric(m[6])),
         low = suppressWarnings(as.numeric(m[7])),
         high = suppressWarnings(as.numeric(m[8])),
         achieved = suppressWarnings(as.numeric(m[9])))
}

probe_path <- build_battery()
out <- drive(probe_path)
ran <- !any(grepl("^Error", out))
check_true(V, "the battery probe ran with no Praat error", ran)
if (!ran) {
    cat("      v158 battery probe output:\n      ",
        paste(utils::tail(out, 40), collapse = "\n      "), "\n", sep = "")
} else {
    results <- lapply(grep("^RESULT ", out, value = TRUE), parse_kv)
    results <- Filter(Negate(is.null), results)
    names(results) <- vapply(results, `[[`, character(1), "id")

    for (s in scenarios) {
        res <- results[[s$id]]
        check_true(V, sprintf("[%s] a RESULT line was printed and parsed", s$id),
                   !is.null(res))
        if (is.null(res)) next

        if (s$id %in% c("TS_alltied_refusal", "PR_allzero_refusal")) {
            check_true(V, sprintf("[%s] the module refuses gracefully (.ok = 0)", s$id),
                       identical(res$ok, "0"))
            check_true(V, sprintf("[%s] .error$ names a reason", s$id), nchar(res$err) > 0)
            next
        }

        check_true(V, sprintf("[%s] .ok = 1", s$id), identical(res$ok, "1"))
        check_true(V, sprintf("[%s] .error$ is empty", s$id), identical(res$err, ""))

        orc <- oracle[[s$id]]
        check(V, sprintf("[%s] .low vs wilcox.test(exact=FALSE)$conf.int[1]", s$id),
              res$low, orc$low, tol = std_tol(orc$low))
        check(V, sprintf("[%s] .high vs wilcox.test(exact=FALSE)$conf.int[2]", s$id),
              res$high, orc$high, tol = std_tol(orc$high))
        check(V, sprintf("[%s] .estimate vs the median of cross-differences/Walsh averages", s$id),
              res$est, orc$estimate, tol = std_tol(orc$estimate))
        check(V, sprintf("[%s] .achievedLevel vs R's reported conf.level attribute", s$id),
              res$achieved, orc$achieved, tol = std_tol(max(orc$achieved, s$level)))

        # A .warning$ appears if and only if R's achieved level fell short
        # of the requested one -- the exact condition the gap this file
        # closes is about.
        expectWarn <- orc$achieved < s$level - STD_ABS
        check_true(V, sprintf("[%s] .warning$ presence matches whether R's achieved level fell short", s$id),
                   (nchar(res$warn) > 0) == expectWarn)
    }

    # The two hand-picked alpha-widening fixtures are named explicitly so a
    # regression that silently stopped exercising the widening loop (e.g.
    # both fixtures accidentally landing on achieved = requested) would be
    # caught even if the loop above's tolerant "did a warning appear"
    # checks were somehow satisfied by coincidence.
    if (!is.null(results[["PR_widen_root"]])) {
        check_true(V, "[PR_widen_root] the widening loop actually widened (achieved < requested)",
                   results[["PR_widen_root"]]$achieved < 0.999 - STD_ABS)
    }
    if (!is.null(results[["PR_widen_median_fallback"]])) {
        r <- results[["PR_widen_median_fallback"]]
        check_true(V, "[PR_widen_median_fallback] alpha exhausted to the median-fallback (achieved = 0)",
                   abs(r$achieved - 0) <= STD_ABS)
        check(V, "[PR_widen_median_fallback] low == high == median(x - y) on the fallback",
              r$low, median(c(-0.626, 0.184) - c(-0.568, 0.364)), tol = STD_ABS)
        check(V, "[PR_widen_median_fallback] high == low (both bounds collapse to the median)",
              r$high, r$low, tol = STD_ABS)
    }
}

}  # canDrive

if (!exists("EML_SUITE")) {
    eml_report("v158 @emlWilcoxonIntervalApprox: the corrected-z inversion, against R")
    eml_exit()
}
