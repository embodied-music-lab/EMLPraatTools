#!/usr/bin/env Rscript
# ============================================================================
# v146 — @emlScheffeInterval and the 3.9 wiring: Scheffe intervals, dark
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. docs/WORK_ORDER_INTERVALS_2026-08-26.md (item 5, the
# last of the five interval items) adds @emlScheffeInterval
# (plugin/stats/eml-inferential.praat) and wires the Scheffe orchestrator
# (@emlScheffe / @emlReportPairwiseComparison, plugin/stats/eml-analysis.praat)
# to compute, on every row:
#
#   * the point estimate (the mean difference) -- already printed on every
#     row from @emlScheffe.diffMatrix##, unchanged by this item;
#   * the interval, AT ALPHA DIRECTLY, on every row -- never alpha/m.
#     Scheffe's multiplier sqrt((k-1) * F_crit) IS the simultaneity
#     correction; dividing alpha again on top of it corrects twice.
#
# UNLIKE THE OTHER TWO ARMS, THIS ONE HAS NO CORRECTION GATE. The welch/
# student and wilcoxon branches only populate their interval arrays when
# .adjMethod$ = "bonferroni" (Holm and BH define no level). Scheffe has no
# separate .adjMethod$ of its own -- its p is already familywise-controlled
# -- so .scheffeLowFlat#/.scheffeHighFlat# are populated on EVERY row this
# branch ever prints.
#
# docs/RULING_INTERVALS_2026-08-26.md's "Language" section and the work
# order both say the report strings that would PRINT this (the "[low, high]"
# bracket, the block header naming the level, "95% simultaneous intervals
# (Scheffe)") are drafted but NOT approved: they print only after Ian's
# en-bloc approval. The shipped code therefore computes the interval and
# stores it as a new, undocumented-in-the-Info-window output of
# @emlReportPairwiseComparison -- .scheffeLowFlat#, .scheffeHighFlat# -- and
# no appendInfoLine anywhere in that procedure reads either. This file
# verifies both halves: the numbers are right, and they are dark.
#
# A HEADER AMENDMENT RODE ALONG. @emlScheffe already computed the pairwise
# SE (sqrt(MSE * (1/n_i + 1/n_j))) to build its F statistic, but never
# published it -- @emlScheffeInterval needs it and cannot recompute it from
# .diffMatrix##/.fMatrix## alone (the sign of the diff is lost squaring
# through F). @emlScheffe therefore gains a new output, .seMatrix##
# (symmetric, mirroring .diffMatrix##'s shape but not its antisymmetry),
# and its Outputs header says so. This file's main battery exercises that
# output too: every .low/.high bound below is downstream of it.
#
# ---------------------------------------------------------------------------
# THE ORACLE
# ---------------------------------------------------------------------------
# CORE LEG -- base R's own qf() on the published definition, read directly,
# never against a packaged Scheffe implementation:
#
#   mse, dfWithin  from aov() on the fixture, exactly as @emlScheffe computes
#                  them (SSwithin / (N - k));
#   se             sqrt(mse * (1/n_i + 1/n_j)), the same formula
#                  @emlScheffe.seMatrix## now publishes;
#   F_crit         qf(1 - alpha, k - 1, dfWithin);
#   half-width     sqrt((k - 1) * F_crit) * se;
#   bounds         (mean_i - mean_j) -/+ half-width.
#
# This IS the definition Fable's ruling pins Scheffe to (docs/
# RULING_ITEM3_CASES_2026-08-26.md's sibling ruling on Hodges-Lehmann drew
# the definition-over-implementation line; the work order draws the same
# line here directly: "the core leg is the base-R definition through qf,
# and its header cites the definition and names itself definition-based").
# Nothing here is re-implementing @emlScheffeInterval's own arithmetic under
# a different name -- qf() is base R's independent F-quantile, not a copy
# of invFisherQ.
#
# OPTIONAL LEG -- DescTools::ScheffeTest, behind requireNamespace, per the
# work order. DescTools is NOT installed in this environment and CRAN is
# unreachable from this container (per the standing 26 August instruction);
# requireNamespace() returns FALSE immediately with no network attempt
# (measured: instantaneous, no CRAN reach-out), so this leg SKIPS CLEANLY,
# reports the skip with the package named via attest() (recorded, excluded
# from the pass/fail count and the exit status, per helpers.R's ATTEST
# convention -- exactly what "counts reported separately" means: the
# skip is visible in the report, not silently folded into either total),
# and does not attempt to install anything. If DescTools ever becomes
# available, the block runs for real and is wrapped in tryCatch so an API
# mismatch registers as a named skip rather than aborting the run --
# nothing here has been able to drive the real package to confirm its exact
# argument names.
#
# THE TWO RED DEMONSTRATIONS FABLE'S ORDER NAMES, built the same way v144
# and v145's are: the shipped source is copied to a scratch file, ONE line
# (or one argument) is mutated, and the mutant is driven exactly like the
# real thing.
#
#   A. MISSING MULTIPLIER -- "an interval at 1-alpha with plain t".
#      @emlScheffeInterval's own F-based half-width
#      (sqrt((k-1) * invFisherQ(alpha, k-1, dfWithin)) * se) is replaced by
#      a plain two-sided t half-width at the FULL alpha, with no (k-1)
#      factor and no F distribution at all: abs(invStudentQ(alpha/2,
#      dfWithin)) * se -- the same shape @emlTTestInterval would produce for
#      an UNCORRECTED interval. The mutant's bounds differ from the correct
#      Scheffe oracle and instead match a plain qt(1 - alpha/2, dfWithin)
#      interval. EML_MULT_RED=1 makes this the standard agreement check.
#
#   B. ALPHA/M SUBSTITUTED FOR ALPHA. The wiring's call site in
#      @emlReportPairwiseComparison passes emlScheffe's own .alpha argument
#      divided by its pair count, `.alpha / emlScheffe.nPairs`, instead of
#      `.alpha` -- the Bonferroni-style division item 2's call site applies
#      correctly for ITS OWN arm, misapplied here on top of a multiplier
#      that already spends the family-wise budget. The mutant's bounds
#      differ from the alpha-direct oracle and instead match
#      qf(1 - alpha/nPairs, k-1, dfWithin) fed through the SAME multiplier.
#      EML_ALPHAM_RED=1 makes this the standard agreement check.
#
# Directionality (narrower/wider) is NOT asserted for either demo: demo A
# omits the multiplier AND uses the full alpha, which narrows the interval
# by both routes; demo B keeps the multiplier and only shrinks the alpha fed
# to it, which WIDENS the interval (a smaller upper-tail probability finds a
# larger critical F) -- still wrong, just not narrower. What both demos
# share, and what both are checked against, is disagreement with the
# correct oracle and exact agreement with the specific wrong one each
# defect produces.
#
# THE DARK-KEEPING CLAIM. Every driven run's FULL Info-window text is
# grepped for the drafted strings -- "simultaneous intervals",
# "(Scheffe)" -- and for a bracketed "[low, high]" rendering appended to a
# per-pair row, and none may appear. A green run here is therefore also the
# evidence that nothing the shipped procedure prints contains any of them.
#
# THE HANG GUARD. invStudentQ(0, df) hangs (@emlTTestInterval's own
# comment); invFisherQ was DRIVEN at its boundaries for this item
# (p = 0, p = 1, df1 = 0, df2 = 0, df undefined, p undefined) and every one
# returned promptly (--undefined-- or 0, never a hang). @emlScheffeInterval's
# own guard is checked directly here, off the shipped procedure, for
# dfWithin undefined/<=0, k < 2, se undefined and alpha undefined -- each
# must set .error$ and leave .low/.high undefined, and the probe completing
# at all inside the timeout is half the evidence.
#
# Base R only. No packages required. Requires a Praat at or above the
# plugin's floor; skips (not fails) below it, the same convention v144 and
# v145 use.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v146"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

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

if (!canDrive) {
    cat(paste0("      SKIP: v146 needs Praat >= 6.6.30 to drive the orchestrator;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v146")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    # -------------------------------------------------------------------
    # THE BATTERY. Four fixtures spanning k = 3, 4 and 5 groups, unequal n
    # and unequal SD per group, so the pairwise SEs genuinely differ within
    # a fixture. Hand-seeded and rounded so both R and the Praat probe read
    # the identical literal numbers -- no re-derivation on either side.
    # -------------------------------------------------------------------
    mk <- function(seed, ns, means, sds) {
        set.seed(seed)
        Map(function(n, m, s) round(rnorm(n, m, s), 6), ns, means, sds)
    }
    fixtures <- list(
        f1 = mk(2001, c(5, 4, 6),          c(10, 14, 9),          c(1, 2, 1.5)),
        f2 = mk(2002, c(4, 5, 4, 6),       c(0, 3, -2, 1),        c(1, 1.5, 0.8, 2)),
        f3 = mk(2003, c(8, 8, 8),          c(5, 5.2, 4.8),        c(0.5, 0.6, 0.4)),
        f4 = mk(2004, c(3, 4, 3, 4, 3),    c(10, 20, 15, 12, 18), c(1, 1, 1, 1, 1))
    )
    glab_of <- function(k) LETTERS[seq_len(k)]
    for (tag in names(fixtures)) names(fixtures[[tag]]) <- glab_of(length(fixtures[[tag]]))

    alphas <- c(a05 = 0.05, a01 = 0.01)

    # Pair order MATCHES @emlScheffe's own nested loop (i from 1 to k-1, j
    # from i+1 to k), which is exactly combn(k, 2)'s column order.
    pair_idx_for <- function(k) {
        cm <- combn(k, 2)
        lapply(seq_len(ncol(cm)), function(j) cm[, j])
    }

    aov_fit <- function(fx) {
        vals <- unlist(fx, use.names = FALSE)
        grp <- factor(rep(names(fx), times = lengths(fx)), levels = names(fx))
        fit <- aov(vals ~ grp)
        s <- summary(fit)[[1]]
        list(mse = s["Residuals", "Mean Sq"], dfW = s["Residuals", "Df"])
    }

    oracle_cell <- function(fx, p, alpha, alphaForF = alpha) {
        gi <- fx[[glab_of(length(fx))[p[1]]]]
        gj <- fx[[glab_of(length(fx))[p[2]]]]
        a <- aov_fit(fx)
        k <- length(fx)
        se <- sqrt(a$mse * (1 / length(gi) + 1 / length(gj)))
        fcrit <- qf(1 - alphaForF, k - 1, a$dfW)
        hw <- sqrt((k - 1) * fcrit) * se
        diff <- mean(gi) - mean(gj)
        list(diff = diff, se = se, lo = diff - hw, hi = diff + hw,
             dfW = a$dfW, mse = a$mse, k = k)
    }

    # Demo A's wrong oracle: plain two-sided t at the FULL alpha, no
    # multiplier, no (k-1).
    oracle_plain_t <- function(fx, p, alpha) {
        gi <- fx[[glab_of(length(fx))[p[1]]]]
        gj <- fx[[glab_of(length(fx))[p[2]]]]
        a <- aov_fit(fx)
        se <- sqrt(a$mse * (1 / length(gi) + 1 / length(gj)))
        tcrit <- qt(1 - alpha / 2, a$dfW)
        diff <- mean(gi) - mean(gj)
        list(lo = diff - abs(tcrit) * se, hi = diff + abs(tcrit) * se)
    }

    # -------------------------------------------------------------------
    # THE PROBE GENERATOR.
    # -------------------------------------------------------------------
    prelude <- function(analysis_file, inferential_file) c(
        paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
        paste0("include ", file.path(plug, "stats", "eml-output.praat")),
        paste0("include ", inferential_file),
        paste0("include ", file.path(plug, "stats", "eml-result-writer.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-annotation-procedures.praat")),
        paste0("include ", analysis_file))

    fmt_row <- function(vals) {
        vapply(seq_len(nrow(vals)), function(i) sprintf(
            '  Append row\n  .r = Get number of rows\n  Set string value: .r, "value", "%s"\n  Set string value: .r, "group", "%s"',
            format(vals$value[i], digits = 17), vals$group[i]), character(1))
    }

    build_fixture <- function(tag, fx) {
        df <- do.call(rbind, lapply(names(fx), function(g) data.frame(
            value = fx[[g]], group = g, stringsAsFactors = FALSE)))
        c(sprintf('procedure build%s', tag),
          sprintf('  .id = Create Table with column names: "%s", 0, "value group"', tag),
          fmt_row(df),
          sprintf('  %s_id = .id', tag),
          "endproc")
    }

    # One probe drives every (fixture, alpha) run named in `runs`, each a
    # list(fixture=, alpha=, tag=). Every run prints one CELL line per pair
    # through .scheffeLowFlat# / .scheffeHighFlat# -- never through
    # appendInfoLine text the shipped reporter itself composes.
    build_probe <- function(runs, analysis_file, inferential_file) {
        lines <- c(prelude(analysis_file, inferential_file), "",
                   "emlGroupSortAlphabetical = 0",
                   unlist(lapply(names(fixtures), function(tag)
                       build_fixture(tag, fixtures[[tag]]))),
                   sprintf("@build%s", names(fixtures)), "")
        for (r in runs) {
            k <- length(fixtures[[r$fixture]])
            nPairs <- k * (k - 1) / 2
            lines <- c(lines,
                sprintf("emlAlpha = %s", format(r$alpha, digits = 17)),
                sprintf('@emlRunPairwiseAnalysis: %s_id, "value", "group", "scheffe", "bonferroni"',
                        r$fixture),
                sprintf("for .k from 1 to %d", nPairs),
                sprintf('  appendInfoLine: "CELL %s ", .k, " ", fixed$ (emlScheffe.diffMatrix## [1,1], 0), " ", fixed$ (emlScheffe.dfWithin, 0), " ", fixed$ (emlReportPairwiseComparison.scheffeLowFlat# [.k], 10), " ", fixed$ (emlReportPairwiseComparison.scheffeHighFlat# [.k], 10)',
                        r$tag),
                "endfor")
        }
        probe_path <- file.path(work, paste0("v146-", runs[[1]]$probeName, ".praat"))
        writeLines(c('writeInfoLine: "v146"', lines), probe_path)
        probe_path
    }

    drive <- function(probe_path) {
        suppressWarnings(system2("timeout",
            c("90", "env", "-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
            stdout = TRUE, stderr = TRUE))
    }

    parse_cells <- function(out) {
        got <- list()
        for (ln in grep("^CELL ", out, value = TRUE)) {
            p <- strsplit(ln, " ")[[1]]
            tag <- p[2]; k <- as.integer(p[3])
            v <- function(s) if (identical(s, "--undefined--")) NA_real_ else as.numeric(s)
            got[[paste(tag, k)]] <- list(dfW = v(p[5]), lo = v(p[6]), hi = v(p[7]))
        }
        got
    }

    DARK_STRINGS <- c("simultaneous intervals", "(Scheffe)")
    DARK_BRACKET <- "\\[\\s*-?[0-9.]+\\s*,\\s*-?[0-9.]+\\s*\\]"

    assert_dark <- function(tag, out) {
        for (s in DARK_STRINGS) {
            check_true(V, sprintf("[%s] the drafted string '%s' never printed", tag, s),
                       !any(grepl(s, out, fixed = TRUE)))
        }
        check_true(V, sprintf("[%s] no bracketed [low, high] rendering printed", tag),
                   !any(grepl(DARK_BRACKET, out, perl = TRUE)))
    }

    # -------------------------------------------------------------------
    # THE MAIN BATTERY -- 4 fixtures (k = 3, 4, 3, 5) x 2 alphas.
    # -------------------------------------------------------------------
    runs <- list()
    for (fxTag in names(fixtures)) {
        for (aTag in names(alphas)) {
            runs[[length(runs) + 1]] <- list(
                fixture = fxTag, alpha = alphas[[aTag]],
                tag = paste(fxTag, aTag, sep = "_"), probeName = "battery")
        }
    }

    probe_path <- build_probe(runs, file.path(plug, "stats", "eml-analysis.praat"),
                               file.path(plug, "stats", "eml-inferential.praat"))
    out <- drive(probe_path)
    ran <- !any(grepl("^Error", out))
    check_true(V, "the main battery probe ran with no Praat error", ran)
    if (!ran) {
        cat("      v146 battery probe output:\n      ",
            paste(utils::tail(out, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        got <- parse_cells(out)
        nCells <- 0L
        for (r in runs) {
            k <- length(fixtures[[r$fixture]])
            pidx <- pair_idx_for(k)
            a_ref <- aov_fit(fixtures[[r$fixture]])
            for (kk in seq_along(pidx)) {
                key <- paste(r$tag, kk)
                cell <- got[[key]]
                check_true(V, sprintf("[%s pair %d] a cell was printed at all", r$tag, kk),
                           !is.null(cell))
                if (is.null(cell)) next
                check(V, sprintf("[%s pair %d] dfWithin vs aov()", r$tag, kk),
                      cell$dfW, a_ref$dfW, tol = 1e-8)
                oc <- oracle_cell(fixtures[[r$fixture]], pidx[[kk]], r$alpha)
                check(V, sprintf("[%s pair %d] interval low vs base-R qf definition", r$tag, kk),
                      cell$lo, oc$lo, tol = 1e-6)
                check(V, sprintf("[%s pair %d] interval high vs base-R qf definition", r$tag, kk),
                      cell$hi, oc$hi, tol = 1e-6)
                nCells <- nCells + 1L
            }
        }
        check(V, "battery cells checked", nCells, 22 * 2, tol = 0)   # (3+6+3+10) pairs x 2 alphas
        assert_dark("main battery", out)
    }

    # -------------------------------------------------------------------
    # OPTIONAL LEG -- DescTools::ScheffeTest, requireNamespace-guarded.
    # -------------------------------------------------------------------
    HAVE_DESCTOOLS <- requireNamespace("DescTools", quietly = TRUE)
    if (!HAVE_DESCTOOLS) {
        cat("      SKIP: v146 optional leg -- package 'DescTools' is not installed\n")
        cat("            (CRAN unreachable from this container; not attempted).\n")
        attest(V, "optional leg (DescTools::ScheffeTest) skipped: package not installed",
               "requireNamespace(\"DescTools\", quietly = TRUE) == FALSE, checked directly")
    } else if (ran) {
        # Untested against the real package in this environment -- wrapped
        # so an API mismatch registers as a named skip, not an abort.
        okOptional <- tryCatch({
            r <- fixtures$f1
            vals <- unlist(r, use.names = FALSE)
            grp <- factor(rep(names(r), times = lengths(r)), levels = names(r))
            st <- DescTools::ScheffeTest(x = vals, g = grp, conf.level = 1 - 0.05)
            pidx <- pair_idx_for(3)
            g <- glab_of(3)
            nOK <- 0L
            for (kk in seq_along(pidx)) {
                p <- pidx[[kk]]
                rowName <- paste0(g[p[1]], "-", g[p[2]])
                rowNameAlt <- paste0(g[p[2]], "-", g[p[1]])
                tbl <- st[[1]]
                rn <- rownames(tbl)
                hit <- if (rowName %in% rn) rowName else if (rowNameAlt %in% rn) rowNameAlt else NA
                if (is.na(hit)) next
                oc <- oracle_cell(r, p, 0.05)
                lo <- tbl[hit, "lwr.ci"]; hi <- tbl[hit, "upr.ci"]
                if (hit == rowNameAlt) { tmp <- lo; lo <- -hi; hi <- -tmp }
                check(V, sprintf("[DescTools pair %d] low vs ScheffeTest", kk), lo, oc$lo, tol = 1e-4)
                check(V, sprintf("[DescTools pair %d] high vs ScheffeTest", kk), hi, oc$hi, tol = 1e-4)
                nOK <- nOK + 1L
            }
            nOK > 0
        }, error = function(e) e)
        if (!isTRUE(okOptional)) {
            msg <- if (inherits(okOptional, "error")) conditionMessage(okOptional) else "no rows matched"
            attest(V, "optional leg (DescTools::ScheffeTest) skipped: API mismatch",
                   sprintf("tryCatch error/no-match: %s", msg))
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO A -- missing multiplier: an interval at 1-alpha with plain t.
    # -------------------------------------------------------------------
    mult_red <- nzchar(Sys.getenv("EML_MULT_RED", unset = ""))
    src_a <- readLines(file.path(plug, "stats", "eml-inferential.praat"), warn = FALSE)
    needleA1 <- "        .fCrit = invFisherQ (.alpha, .k - 1, .dfWithin)"
    needleA2 <- "        .halfWidth = sqrt ((.k - 1) * .fCrit) * .se"
    hitA1 <- src_a == needleA1
    hitA2 <- src_a == needleA2
    check_true(V, "red demo A's seed site (F-based half-width, 2 lines) exists, exactly once each",
               sum(hitA1) == 1 && sum(hitA2) == 1 && which(hitA1) + 1 == which(hitA2))
    if (sum(hitA1) == 1 && sum(hitA2) == 1 && which(hitA1) + 1 == which(hitA2)) {
        mutA_dir <- file.path(work, "mutantA"); dir.create(mutA_dir, showWarnings = FALSE)
        mutA <- file.path(mutA_dir, "eml-inferential.praat")
        i1 <- which(hitA1)
        replA <- c("        .tCrit = invStudentQ (.alpha / 2, .dfWithin)",
                   "        .halfWidth = abs (.tCrit) * .se")
        srcMutA <- append(src_a[-c(i1, i1 + 1)], replA, after = i1 - 1)
        writeLines(srcMutA, mutA)

        runA <- list(fixture = "f1", alpha = 0.05, tag = "redA", probeName = "redA")
        probeA <- build_probe(list(runA), file.path(plug, "stats", "eml-analysis.praat"), mutA)
        outA <- drive(probeA)
        ranA <- !any(grepl("^Error", outA))
        check_true(V, "[red A] the mutant probe ran", ranA)
        if (ranA) {
            gotA <- parse_cells(outA)
            cellA <- gotA[[paste("redA", 1)]]   # f1 pair 1 = A vs B
            correctOc <- oracle_cell(fixtures$f1, c(1, 2), 0.05)
            wrongOc <- oracle_plain_t(fixtures$f1, c(1, 2), 0.05)
            check_true(V, "[red A] the mutant probe printed a cell", !is.null(cellA))
            if (!is.null(cellA)) {
                if (mult_red) {
                    cat("      EML_MULT_RED: asserting the mutant's interval equals the\n")
                    cat("      correct Scheffe oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED A] mutant interval vs correct Scheffe oracle (must go red)",
                          cellA$lo, correctOc$lo, tol = 1e-6)
                } else {
                    check(V, "[red A] mutant interval DIFFERS from the correct Scheffe oracle",
                          cellA$lo, correctOc$lo, tol = 1e-6, expect = "differ")
                    check(V, "[red A] mutant interval instead matches the plain-t, 1-alpha oracle",
                          cellA$lo, wrongOc$lo, tol = 1e-6)
                    check(V, "[red A] mirror on the high bound",
                          cellA$hi, wrongOc$hi, tol = 1e-6)
                }
            }
        } else {
            cat("      v146 red-demo-A probe output:\n      ",
                paste(utils::tail(outA, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO B -- alpha/m substituted for alpha.
    # -------------------------------------------------------------------
    alpham_red <- nzchar(Sys.getenv("EML_ALPHAM_RED", unset = ""))
    src_b <- readLines(file.path(plug, "stats", "eml-analysis.praat"), warn = FALSE)
    needleB <- "                    ... .nGroups, emlScheffe.dfWithin, .alpha"
    hitB <- src_b == needleB
    check_true(V, "red demo B's seed site (the call-site alpha argument) exists, exactly once",
               sum(hitB) == 1)
    if (sum(hitB) == 1) {
        mutB_dir <- file.path(work, "mutantB"); dir.create(mutB_dir, showWarnings = FALSE)
        mutB <- file.path(mutB_dir, "eml-analysis.praat")
        writeLines(sub(needleB,
            "                    ... .nGroups, emlScheffe.dfWithin, .alpha / emlScheffe.nPairs",
            src_b, fixed = TRUE), mutB)

        runB <- list(fixture = "f1", alpha = 0.05, tag = "redB", probeName = "redB")
        probeB <- build_probe(list(runB), mutB,
                               file.path(plug, "stats", "eml-inferential.praat"))
        outB <- drive(probeB)
        ranB <- !any(grepl("^Error", outB))
        check_true(V, "[red B] the mutant probe ran", ranB)
        if (ranB) {
            gotB <- parse_cells(outB)
            cellB <- gotB[[paste("redB", 1)]]   # f1 pair 1 = A vs B, nPairs = 3
            correctOc <- oracle_cell(fixtures$f1, c(1, 2), 0.05)
            wrongOc <- oracle_cell(fixtures$f1, c(1, 2), 0.05, alphaForF = 0.05 / 3)
            check_true(V, "[red B] the mutant probe printed a cell", !is.null(cellB))
            if (!is.null(cellB)) {
                if (alpham_red) {
                    cat("      EML_ALPHAM_RED: asserting the mutant's interval equals the\n")
                    cat("      correct alpha-direct oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED B] mutant interval vs correct alpha-direct oracle (must go red)",
                          cellB$lo, correctOc$lo, tol = 1e-6)
                } else {
                    check(V, "[red B] mutant interval DIFFERS from the correct alpha-direct oracle",
                          cellB$lo, correctOc$lo, tol = 1e-6, expect = "differ")
                    check(V, "[red B] mutant interval instead matches the alpha/nPairs oracle",
                          cellB$lo, wrongOc$lo, tol = 1e-6)
                    check(V, "[red B] mirror on the high bound",
                          cellB$hi, wrongOc$hi, tol = 1e-6)
                }
            }
        } else {
            cat("      v146 red-demo-B probe output:\n      ",
                paste(utils::tail(outB, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # THE HANG GUARD, direct against @emlScheffeInterval.
    # -------------------------------------------------------------------
    guard_lines <- c(prelude(file.path(plug, "stats", "eml-analysis.praat"),
                              file.path(plug, "stats", "eml-inferential.praat")), "",
        '@emlScheffeInterval: 5, 2, 3, undefined, 0.05',
        'appendInfoLine: "GUARD dfundef ", emlScheffeInterval.low, " ", emlScheffeInterval.high, " [", emlScheffeInterval.error$, "]"',
        '@emlScheffeInterval: 5, 2, 3, 0, 0.05',
        'appendInfoLine: "GUARD dfzero ", emlScheffeInterval.low, " ", emlScheffeInterval.high, " [", emlScheffeInterval.error$, "]"',
        '@emlScheffeInterval: 5, 2, 1, 9, 0.05',
        'appendInfoLine: "GUARD kunder ", emlScheffeInterval.low, " ", emlScheffeInterval.high, " [", emlScheffeInterval.error$, "]"',
        '@emlScheffeInterval: 5, undefined, 3, 9, 0.05',
        'appendInfoLine: "GUARD seundef ", emlScheffeInterval.low, " ", emlScheffeInterval.high, " [", emlScheffeInterval.error$, "]"',
        '@emlScheffeInterval: 5, 2, 3, 9, undefined',
        'appendInfoLine: "GUARD alphaundef ", emlScheffeInterval.low, " ", emlScheffeInterval.high, " [", emlScheffeInterval.error$, "]"',
        '@emlScheffeInterval: 5, 2, 3, 9, 0.05',
        'appendInfoLine: "GUARD clean ", fixed$ (emlScheffeInterval.low, 10), " ", fixed$ (emlScheffeInterval.high, 10), " [", emlScheffeInterval.error$, "]"')
    guard_path <- file.path(work, "v146-guard.praat")
    writeLines(c('writeInfoLine: "v146 guard"', guard_lines), guard_path)
    outG <- drive(guard_path)
    ranG <- !any(grepl("^Error", outG))
    check_true(V, "the guard probe ran (completed -- did not hang) with no Praat error", ranG)
    if (ranG) {
        get1 <- function(tag) grep(paste0("^GUARD ", tag), outG, value = TRUE)
        dfundef <- get1("dfundef"); dfzero <- get1("dfzero"); kunder <- get1("kunder")
        seundef <- get1("seundef"); alphaundef <- get1("alphaundef"); clean <- get1("clean")
        check_true(V, "dfWithin undefined sets .error$ and leaves low/high undefined",
                   length(dfundef) == 1 && grepl("--undefined--.*--undefined--", dfundef) &&
                   !grepl("\\[\\]", dfundef))
        check_true(V, "dfWithin <= 0 sets .error$ and leaves low/high undefined",
                   length(dfzero) == 1 && grepl("--undefined--.*--undefined--", dfzero) &&
                   !grepl("\\[\\]", dfzero))
        check_true(V, "k < 2 sets .error$ and leaves low/high undefined",
                   length(kunder) == 1 && grepl("--undefined--.*--undefined--", kunder) &&
                   !grepl("\\[\\]", kunder))
        check_true(V, "se undefined sets .error$ and leaves low/high undefined",
                   length(seundef) == 1 && grepl("--undefined--.*--undefined--", seundef) &&
                   !grepl("\\[\\]", seundef))
        check_true(V, "alpha undefined sets .error$ and leaves low/high undefined",
                   length(alphaundef) == 1 && grepl("--undefined--.*--undefined--", alphaundef) &&
                   !grepl("\\[\\]", alphaundef))
        if (length(clean) == 1) {
            m <- regmatches(clean, regexec(
                "GUARD clean (-?[0-9.]+) (-?[0-9.]+) \\[(.*)\\]", clean))[[1]]
            check_true(V, "a clean call parsed", length(m) == 4)
            if (length(m) == 4) {
                # meanDiff=5, se=2, k=3, dfWithin=9, alpha=0.05 -- independent
                # closed-form check against R's own qf, not against aov (no
                # data here, a direct-procedure call).
                fcrit <- qf(1 - 0.05, 3 - 1, 9)
                hw <- sqrt((3 - 1) * fcrit) * 2
                lo <- 5 - hw; hi <- 5 + hw
                check(V, "clean call low bound vs closed-form qf", as.numeric(m[2]), lo, tol = 1e-8)
                check(V, "clean call high bound vs closed-form qf", as.numeric(m[3]), hi, tol = 1e-8)
                check_true(V, "clean call's .error$ is empty", identical(m[4], ""))
            }
        } else {
            check_true(V, "a clean call parsed", FALSE)
        }
    } else {
        cat("      v146 guard probe output:\n      ",
            paste(utils::tail(outG, 20), collapse = "\n      "), "\n", sep = "")
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v146 @emlScheffeInterval and the 3.9 wiring")
    eml_exit()
}
