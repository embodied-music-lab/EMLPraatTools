# ===========================================================================
# v109 — the three remaining report intervals vs R, at two alphas
# ===========================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. Three confidence intervals the plugin prints take their
# quantile from the alpha in force rather than from a constant, and each
# states in its own printed label the level it used:
#
#   1. "N% CI of diff" in the two-group comparison report
#      (@emlReportTwoGroupComparison, graphs/eml-annotation-procedures.praat)
#   2. the "N% CI" column of the regression coefficient table
#      (@emlReportRegressionAnalysis, same file)
#   3. the Feldt (1965) interval on Cronbach's alpha
#      (@emlCronbachAlpha, stats/eml-psychometrics.praat)
#
# The first two read the graph dialog's Alpha through @emlCIAlphaInForce, the
# same control the stars and the error bars obey. The third is a stats-layer
# kernel with no dialog behind it, so its level is an ARGUMENT, the way
# @emlCI and @emlWilsonInterval take theirs.
#
# WHY A SEARCH FOR 1.96 COULD NOT FIND THEM. All three spelled the level as
# a TAIL PROBABILITY -- invStudentQ (0.025, df), invFisherQ (0.025, ...) --
# so the constant that fixed the level was never the constant a reader looks
# for. This validator therefore asserts the BEHAVIOUR, not the source text:
# it drives the shipped reporters twice at two different alphas and requires
# the printed numbers to move.
#
# THE ORACLES ARE R'S OWN, not a re-derivation of the plugin's arithmetic.
# The difference of means is settled against t.test(conf.level = 1 - alpha)
# on the same two vectors; the coefficient rows against confint(lm(), level)
# on the same twelve points; the Feldt interval against its published form,
# 1 - (1 - a) * qf on (n-1, (n-1)(k-1)) df, which is the construction
# psych::alpha reports.
#
# WHAT IS ASSERTED AT EACH ALPHA
#   - every printed bound agrees with R to half a printed unit
#   - the printed LABEL names the level actually used (95 / 99), so the
#     label is evidence rather than decoration
#   - the alpha = .01 interval is strictly wider than the alpha = .05 one at
#     both ends, which is the assertion a hardcoded quantile fails
#   - the headless path -- annotAlpha never assigned, which an API caller
#     reaches -- falls back to the documented 0.05 and prints the 95% label
#
# Negative controls, one per site: a scratch copy of each source with the
# quantile seeded back to the constant it carried is driven at alpha = .01,
# and the run asserts the bounds DIFFER from the oracle while the label
# still claims 99% -- the defect, reproduced on demand. Set EML_CIALPHA_RED=1
# to run the standard agreement checks against the seeded builds instead and
# watch the named checks go red.
#
# Base R only. No packages. Requires a Praat at or above the plugin's floor.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ===========================================================================

V <- "v109"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

red_mode <- nzchar(Sys.getenv("EML_CIALPHA_RED", unset = ""))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
plug <- normalizePath(plug, mustWork = FALSE)

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

# ---------------------------------------------------------------------------
# THE FIXTURES
# ---------------------------------------------------------------------------
# Two groups whose difference is large enough that neither bound straddles
# zero at either alpha, so "wider" is a statement about both ends and not
# about a sign change.
G1 <- c(5.1, 5.6, 4.9, 6.2, 5.8, 5.3, 6.0, 5.5)
G2 <- c(4.2, 4.8, 3.9, 4.5, 4.1, 4.7, 4.4, 4.0)

# Twelve points with a strong but not perfect linear relation: the slope's
# interval excludes zero at both alphas, the intercept's contains it at both,
# so the table is read in both directions.
RX <- 1:12
RY <- c(2.1, 1.4, 4.2, 3.3, 6.1, 5.4, 8.2, 9.1, 7.3, 12.4, 10.2, 13.1)

# A 10-respondent 5-item scale, alpha near .96.
CR <- matrix(c(4,4,3,4,5, 3,3,2,3,3, 5,5,5,4,5, 2,3,2,2,3, 4,3,4,4,4,
               5,4,5,5,5, 1,2,1,2,1, 3,4,3,3,4, 4,5,4,5,4, 2,2,3,2,2),
             nrow = 10, byrow = TRUE)

# ---------------------------------------------------------------------------
# THE FELDT ORACLE, pinned against its published form before it judges
# anything. invFisherQ takes an UPPER-tail probability and qf a lower-tail
# one, so the lower bound of alpha reads qf at 1 - tail.
# ---------------------------------------------------------------------------
feldt_ci <- function(m, conf) {
    cc <- m[stats::complete.cases(m), , drop = FALSE]
    k <- ncol(cc); n <- nrow(cc)
    C <- stats::cov(cc)
    a <- (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
    df1 <- n - 1; df2 <- (n - 1) * (k - 1)
    tail <- (1 - conf) / 2
    list(alpha = a,
         lo = 1 - (1 - a) * stats::qf(1 - tail, df1, df2),
         hi = 1 - (1 - a) * stats::qf(tail, df1, df2))
}
# At conf = 0.95 the published tails are exactly .025 and .975; asserting
# that here means the general form cannot have drifted from the special case
# every reference states.
f95 <- feldt_ci(CR, 0.95)
{
    cc <- CR; k <- ncol(cc); n <- nrow(cc); C <- stats::cov(cc)
    a <- (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
    df1 <- n - 1; df2 <- (n - 1) * (k - 1)
    check(V, "Feldt oracle vs the .025/.975 special case, lower",
          f95$lo, 1 - (1 - a) * stats::qf(0.975, df1, df2), tol = 1e-12)
    check(V, "Feldt oracle vs the .025/.975 special case, upper",
          f95$hi, 1 - (1 - a) * stats::qf(0.025, df1, df2), tol = 1e-12)
}

if (!canDrive) {
    cat(paste0("      SKIP: v109 needs Praat >= 6.6.30 to drive the reporters;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v109")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    vec <- function(v) paste0("{", paste(format(v, digits = 17), collapse = ", "), "}")
    mat <- function(m) paste0("{", paste(apply(m, 1, function(r)
        paste0("{", paste(format(r, digits = 17), collapse = ", "), "}")),
        collapse = ", "), "}")

    # Same include set as harness/stress_cases/_prelude.praat, minus the
    # interactive wrapper: the annotation layer is not self-contained, so the
    # stats layer comes along.
    prelude <- function(annot_file, psych_file) c(
        paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
        paste0("include ", file.path(plug, "stats", "eml-output.praat")),
        paste0("include ", file.path(plug, "stats", "eml-inferential.praat")),
        paste0("include ", psych_file),
        paste0("include ", annot_file),
        paste0("include ", file.path(plug, "graphs", "eml-draw-procedures.praat")))

    ANNOT <- file.path(plug, "graphs", "eml-annotation-procedures.praat")
    PSYCH <- file.path(plug, "stats", "eml-psychometrics.praat")

    # alpha = NA drives the headless path: annotAlpha is never assigned, and
    # the Cronbach level is passed as 0.95 because that kernel has no global
    # to fall back to -- its level is always the caller's.
    drive <- function(alpha, tag, annot_file = ANNOT, psych_file = PSYCH) {
        conf <- if (is.na(alpha)) 0.95 else 1 - alpha
        probe <- file.path(work, paste0("v109-", tag, ".praat"))
        writeLines(c(
            prelude(annot_file, psych_file),
            "",
            "emlShowExplanations = 0",
            if (is.na(alpha)) "# annotAlpha deliberately unset"
            else sprintf("annotAlpha = %s", format(alpha, digits = 17)),
            'writeInfoLine: "v109"',
            "",
            sprintf(".g1# = %s", vec(G1)),
            sprintf(".g2# = %s", vec(G2)),
            "@emlTTest: .g1#, .g2#, 2, 0",
            "@emlCohenD: .g1#, .g2#",
            "@emlCSVInit",
            paste0('@emlReportTwoGroupComparison: "T", "value", "grp", "A", "B", ',
                   '8, mean (.g1#), stdev (.g1#), 0, ',
                   '8, mean (.g2#), stdev (.g2#), 0, "parametric"'),
            "",
            sprintf(".rx# = %s", vec(RX)),
            sprintf(".ry# = %s", vec(RY)),
            "@emlLinearRegression: .rx#, .ry#",
            "@emlCSVInit",
            '@emlReportRegressionAnalysis: "T", "y", "x", 12, 0',
            "",
            sprintf(".cr## = %s", mat(CR)),
            sprintf("@emlCronbachAlpha: .cr##, %s", format(conf, digits = 17)),
            'appendInfoLine: "feldt|", emlCronbachAlpha.confidence, "|",',
            '... emlCronbachAlpha.alpha, "|", emlCronbachAlpha.ciLow, "|",',
            '... emlCronbachAlpha.ciHigh, "|", emlCronbachAlpha.error$'),
            probe)
        suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
    }

    # ---- readers. Each pulls the LEVEL out of the plugin's own label. ----
    NA3 <- list(level = NA_real_, lo = NA_real_, hi = NA_real_)

    parse_diff <- function(out) {
        h <- grep("% CI of diff", out, value = TRUE)
        if (!length(h)) return(NA3)
        m <- regmatches(h[1], regexec(
            "([0-9.]+)% CI of diff\\s+\\[\\s*(-?[0-9.]+),\\s*(-?[0-9.]+)\\]",
            h[1]))[[1]]
        if (length(m) < 4) return(NA3)
        list(level = as.numeric(m[2]), lo = as.numeric(m[3]),
             hi = as.numeric(m[4]))
    }

    # The coefficient table's level lives in the column heading, and the two
    # rows carry the bounds; the heading is read once and applied to both.
    parse_coef <- function(out, term) {
        hdr <- grep("^\\s+Term\\s.*% CI\\s*$", out, value = TRUE)
        lvl <- NA_real_
        if (length(hdr)) {
            mm <- regmatches(hdr[1], regexec("([0-9.]+)% CI\\s*$", hdr[1]))[[1]]
            if (length(mm) >= 2) lvl <- as.numeric(mm[2])
        }
        h <- grep(paste0("^\\s+", term, "\\s"), out, value = TRUE)
        if (!length(h)) return(NA3)
        m <- regmatches(h[1], regexec(
            "\\[\\s*(-?[0-9.]+),\\s*(-?[0-9.]+)\\]\\s*$", h[1]))[[1]]
        if (length(m) < 3) return(NA3)
        list(level = lvl, lo = as.numeric(m[2]), hi = as.numeric(m[3]))
    }

    parse_feldt <- function(out) {
        h <- grep("^feldt\\|", out, value = TRUE)
        if (!length(h)) return(list(conf = NA_real_, alpha = NA_real_,
                                    lo = NA_real_, hi = NA_real_, err = NA_character_))
        f <- strsplit(sub("^feldt\\|", "", h[1]), "|", fixed = TRUE)[[1]]
        n <- function(i) if (length(f) < i || f[i] == "--undefined--") NA_real_
                         else suppressWarnings(as.numeric(f[i]))
        list(conf = n(1), alpha = n(2), lo = n(3), hi = n(4),
             err = if (length(f) >= 5) f[5] else "")
    }

    # The report prints 4 decimals, so the tolerance is half a printed unit.
    # The Feldt bounds are printed unrounded and are settled far tighter.
    tolp <- 5e-5
    tolf <- 1e-9

    got <- list()
    cases <- list(list(a = 0.05, tag = "a05", lvl = 95),
                  list(a = 0.01, tag = "a01", lvl = 99),
                  list(a = NA,   tag = "unset", lvl = 95))

    for (cs in cases) {
        out <- drive(cs$a, cs$tag)
        dd <- parse_diff(out); ii <- parse_coef(out, "\\(Intercept\\)")
        ss <- parse_coef(out, "x"); ff <- parse_feldt(out)
        ran <- !any(grepl("^Error", out)) && is.finite(dd$lo) &&
               is.finite(ss$lo) && is.finite(ff$lo)
        check_true(V, sprintf("the %s probe ran and printed all three intervals",
                              cs$tag), ran)
        if (!ran) {
            cat(sprintf("      v109 %s probe output: %s\n", cs$tag,
                        paste(utils::tail(out, 12), collapse = " / ")))
            next
        }
        got[[cs$tag]] <- list(diff = dd, int = ii, slope = ss, feldt = ff)

        aeff <- if (is.na(cs$a)) 0.05 else cs$a
        conf <- 1 - aeff

        # --- 1. the difference of means, against t.test ---
        tt <- stats::t.test(G1, G2, var.equal = FALSE, conf.level = conf)$conf.int
        check(V, sprintf("[%s] CI of diff, printed level", cs$tag),
              dd$level, cs$lvl, tol = 0)
        check(V, sprintf("[%s] CI of diff lower vs t.test", cs$tag),
              dd$lo, tt[1], tol = tolp)
        check(V, sprintf("[%s] CI of diff upper vs t.test", cs$tag),
              dd$hi, tt[2], tol = tolp)

        # --- 2. the coefficient table, against confint(lm) ---
        ci <- stats::confint(stats::lm(RY ~ RX), level = conf)
        check(V, sprintf("[%s] coefficient column, printed level", cs$tag),
              ii$level, cs$lvl, tol = 0)
        check(V, sprintf("[%s] intercept CI lower vs confint(lm)", cs$tag),
              ii$lo, ci[1, 1], tol = tolp)
        check(V, sprintf("[%s] intercept CI upper vs confint(lm)", cs$tag),
              ii$hi, ci[1, 2], tol = tolp)
        check(V, sprintf("[%s] slope CI lower vs confint(lm)", cs$tag),
              ss$lo, ci[2, 1], tol = tolp)
        check(V, sprintf("[%s] slope CI upper vs confint(lm)", cs$tag),
              ss$hi, ci[2, 2], tol = tolp)

        # --- 3. the Feldt interval, against its published form ---
        fo <- feldt_ci(CR, conf)
        check(V, sprintf("[%s] Feldt level echoed back", cs$tag),
              ff$conf, conf, tol = 1e-12)
        check(V, sprintf("[%s] Cronbach's alpha itself", cs$tag),
              ff$alpha, fo$alpha, tol = tolf)
        check(V, sprintf("[%s] Feldt lower vs the published form", cs$tag),
              ff$lo, fo$lo, tol = tolf)
        check(V, sprintf("[%s] Feldt upper vs the published form", cs$tag),
              ff$hi, fo$hi, tol = tolf)
    }

    # -----------------------------------------------------------------------
    # THE CONTROL THE USER SET ACTUALLY MOVES ALL THREE INTERVALS.
    # This is the assertion a hardcoded quantile fails, whatever it is
    # spelled as, and it is stated per bound rather than per interval so a
    # one-sided change cannot pass.
    # -----------------------------------------------------------------------
    if (!is.null(got$a05) && !is.null(got$a01)) {
        wider <- list(
            c("CI of diff", "diff"),
            c("intercept CI", "int"),
            c("slope CI", "slope"),
            c("Feldt interval", "feldt"))
        for (w in wider) {
            lo05 <- got$a05[[w[2]]]$lo; lo01 <- got$a01[[w[2]]]$lo
            hi05 <- got$a05[[w[2]]]$hi; hi01 <- got$a01[[w[2]]]$hi
            check_true(V, sprintf("alpha = .01 widens the %s downward", w[1]),
                       isTRUE(lo01 < lo05))
            check_true(V, sprintf("alpha = .01 widens the %s upward", w[1]),
                       isTRUE(hi01 > hi05))
        }
        check_true(V, "the headless path reproduces the alpha = .05 report",
                   isTRUE(all.equal(unlist(got$unset), unlist(got$a05))))
    }

    # -----------------------------------------------------------------------
    # NEGATIVE CONTROLS — one per site, each seeding back the constant that
    # site carried. At alpha = .01 every seeded build prints a 95% interval
    # under a 99% label, which is the defect this validator exists to refuse.
    # -----------------------------------------------------------------------
    seed <- function(src_path, needle, replacement, out_name) {
        src <- readLines(src_path, warn = FALSE)
        hit <- sum(grepl(needle, src, fixed = TRUE))
        check_true(V, sprintf("the seed site '%s' exists exactly once in source",
                              needle), hit == 1)
        if (hit != 1) return(NULL)
        d <- file.path(work, "mutant", out_name)
        dir.create(dirname(d), showWarnings = FALSE, recursive = TRUE)
        writeLines(sub(needle, replacement, src, fixed = TRUE), d)
        d
    }

    mut_annot_diff <- seed(ANNOT,
        ".tCritDiff = invStudentQ (.ciAlpha / 2, emlTTest.df)",
        ".tCritDiff = invStudentQ (0.025, emlTTest.df)",
        "diff/eml-annotation-procedures.praat")
    mut_annot_coef <- seed(ANNOT,
        ".ciWidth = invStudentQ (.ciAlpha / 2, emlLinearRegression.dfRes)",
        ".ciWidth = invStudentQ (0.025, emlLinearRegression.dfRes)",
        "coef/eml-annotation-procedures.praat")
    mut_psych <- seed(PSYCH,
        ".ciLow = 1 - (1 - .alpha) * invFisherQ (.tail, .df1, .df2)",
        ".ciLow = 1 - (1 - .alpha) * invFisherQ (0.025, .df1, .df2)",
        "feldt/eml-psychometrics.praat")

    tt99 <- stats::t.test(G1, G2, var.equal = FALSE, conf.level = 0.99)$conf.int
    ci99 <- stats::confint(stats::lm(RY ~ RX), level = 0.99)
    fo99 <- feldt_ci(CR, 0.99)

    if (red_mode) {
        cat("      EML_CIALPHA_RED: running the standard agreement checks against\n")
        cat("      the seeded builds — the next three checks are EXPECTED to FAIL.\n")
    }

    if (!is.null(mut_annot_diff)) {
        m <- parse_diff(drive(0.01, "mut_diff", annot_file = mut_annot_diff))
        check_true(V, "the seeded CI-of-diff probe ran", is.finite(m$lo))
        if (red_mode) {
            check(V, "[RED] seeded CI of diff vs t.test at .01 (must go red)",
                  m$lo, tt99[1], tol = tolp)
        } else if (is.finite(m$lo)) {
            check(V, "seeded CI of diff DIFFERS from t.test at alpha = .01",
                  m$lo, tt99[1], tol = tolp, expect = "differ")
            check(V, "seeded CI of diff still prints the 99% label",
                  m$level, 99, tol = 0)
            if (!is.null(got$a05)) {
                check(V, "seeded CI of diff equals the alpha = .05 interval",
                      m$lo, got$a05$diff$lo, tol = tolp)
            }
        }
    }

    if (!is.null(mut_annot_coef)) {
        m <- parse_coef(drive(0.01, "mut_coef", annot_file = mut_annot_coef), "x")
        check_true(V, "the seeded coefficient-column probe ran", is.finite(m$lo))
        if (red_mode) {
            check(V, "[RED] seeded slope CI vs confint(lm) at .01 (must go red)",
                  m$lo, ci99[2, 1], tol = tolp)
        } else if (is.finite(m$lo)) {
            check(V, "seeded slope CI DIFFERS from confint(lm) at alpha = .01",
                  m$lo, ci99[2, 1], tol = tolp, expect = "differ")
            check(V, "seeded coefficient column still prints the 99% heading",
                  m$level, 99, tol = 0)
            if (!is.null(got$a05)) {
                check(V, "seeded slope CI equals the alpha = .05 interval",
                      m$lo, got$a05$slope$lo, tol = tolp)
            }
        }
    }

    if (!is.null(mut_psych)) {
        m <- parse_feldt(drive(0.01, "mut_feldt", psych_file = mut_psych))
        check_true(V, "the seeded Feldt probe ran", is.finite(m$lo))
        if (red_mode) {
            check(V, "[RED] seeded Feldt lower vs the published form at .01 (must go red)",
                  m$lo, fo99$lo, tol = tolf)
        } else if (is.finite(m$lo)) {
            check(V, "seeded Feldt lower DIFFERS from the published form at 0.99",
                  m$lo, fo99$lo, tol = tolf, expect = "differ")
            check(V, "seeded Feldt still echoes the 0.99 level it did not use",
                  m$conf, 0.99, tol = 1e-12)
            if (!is.null(got$a05)) {
                check(V, "seeded Feldt lower equals the 0.95 bound",
                      m$lo, got$a05$feldt$lo, tol = tolf)
            }
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v109 report confidence intervals honour the alpha in force")
    eml_exit()
}
