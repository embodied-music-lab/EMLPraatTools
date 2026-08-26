# ============================================================================
# v144 — @emlTTestInterval and the 3.6 wiring: pairwise-t intervals, dark
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. docs/WORK_ORDER_INTERVALS_2026-08-26.md (item 2) adds
# @emlTTestInterval (plugin/stats/eml-inferential.praat) and wires the
# pairwise-t orchestrator (@emlPairwiseT / @emlReportPairwiseComparison,
# plugin/stats/eml-analysis.praat) to compute, on every row:
#
#   * the point estimate (mean difference), every row, every correction;
#   * the interval, ONLY when the correction in force defines one --
#     Bonferroni at .level = 1 - alpha/m per pair; Holm and BH define none.
#
# docs/RULING_INTERVALS_2026-08-26.md's "Language" section and the work
# order both say the report strings that would PRINT these ("Mean
# difference (C1 - C2): x.xx", the "[low, high]" bracket, the block header
# naming the level) are drafted but NOT approved: they print only after
# Ian's en-bloc approval. The shipped code therefore computes both
# quantities and stores them as new, undocumented-in-the-Info-window
# outputs of @emlReportPairwiseComparison -- .meanDiffFlat#, .lowFlat#,
# .highFlat# -- and no appendInfoLine anywhere in that procedure reads any
# of the three. This file verifies both halves: the numbers are right, and
# they are dark.
#
# THE ORACLE. R's t.test(x, y, var.equal =, conf.level = 1 - alpha/m), read
# directly -- var.equal = FALSE for "welch", TRUE for "student" -- against
# the SAME data driven through the shipped
# @emlRunPairwiseAnalysis -> @emlPairwiseT -> @emlReportPairwiseComparison
# chain, end to end, exactly as the menu item runs it. Nothing here re-
# implements the formula; the check is agreement with R's own test.
#
# THE BATTERY. Five 4-group fixtures (unequal n and unequal SD per group,
# so Welch and Student disagree meaningfully on both t and df) x two test
# types (welch, student) x two alphas (.05, .01), Bonferroni throughout.
# Four groups is C(4,2) = 6 pairs, so 5 fixtures x 6 pairs x 2 alphas = 60
# cells -- exactly Fable's "60 Welch + 60 Student kit cells", read off this
# validator's own battery rather than the 630-row master kit. Per the
# standing kit-discipline rule ("each commit drives its own named rows plus
# canaries; full kit at the gate only"), this is the commit's own battery,
# not a subset of the master kit run.
#
# THE THREE RED DEMONSTRATIONS Fable's order requires, all built the same
# way v108's negative control is: the shipped source is copied to a scratch
# file, ONE line is mutated, and the mutant is driven exactly like the real
# thing. In normal mode each asserts the mutant's numbers DIFFER from the
# correct oracle -- proof this validator would have caught the defect had
# it shipped. Set the matching EML_*_RED variable to watch any one of them
# actually go red against the correct oracle instead.
#
#   A. HOLM ROW PRINTING AN INTERVAL. The interval guard in
#      @emlReportPairwiseComparison ("if .adjMethod$ = "bonferroni"") is
#      widened to admit "holm" too. Driven with adjMethod "holm", the
#      mutant DEFINES .lowFlat#/.highFlat# where the shipped code leaves
#      them undefined -- Holm has no defined interval level at all.
#      EML_HOLM_RED=1 makes this the standard agreement check.
#
#   B. A STUDENT INTERVAL ON THE WELCH DF, AND THE MIRROR -- "the failure
#      that looks right". @emlPairwiseT's .eqVar assignment is followed by
#      one mutant line, ".eqVar = 1 - .eqVar", so a "welch"-labelled run
#      silently computes with Student's pooled variance and df while its
#      .method$ still reads "Welch t-test", and a "student"-labelled run
#      silently computes Welch's. Both directions come from the one flip.
#      Driven on a fixture with unequal n and unequal SD (f1), the mutant's
#      interval differs measurably from the correctly-labelled oracle in
#      BOTH directions. EML_DF_RED=1 makes this the standard check.
#
#   C. A BONFERRONI INTERVAL AT 1 - ALPHA, not 1 - alpha/m. The level
#      formula in @emlReportPairwiseComparison is mutated from
#      "1 - .alpha / emlPairwiseT.nPairs" to "1 - .alpha" -- R's t.test
#      default, uncorrected interval, printed as though it were the
#      Bonferroni one. The mutant's bounds differ from the m-corrected
#      oracle and instead match the plain uncorrected t.test(conf.level =
#      1 - alpha) interval, which is the defect named exactly.
#      EML_ALPHA_RED=1 makes this the standard check.
#
# THE DARK-KEEPING CLAIM ITSELF. Every driven run's FULL Info-window text
# (captured the same way system2() captures it for every other validator in
# this suite) is grepped for the drafted strings -- "Mean difference (",
# "Hodges-Lehmann shift", "simultaneous intervals", a bracketed
# "[low, high]" rendering appended to a per-pair row -- and none may appear.
# A green run here is therefore also the evidence for the work order's
# "report how you kept them dark": nothing the shipped procedure prints
# contains any of them, on any of the 60 + 60 + 3 mutant drives.
#
# Base R only. No packages. Requires a Praat at or above the plugin's
# floor; skips (not fails) below it, the same convention v108 and v143 use.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v144"

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
    cat(paste0("      SKIP: v144 needs Praat >= 6.6.30 to drive the orchestrator;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v144")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    # -------------------------------------------------------------------
    # THE BATTERY. Five 4-group fixtures, unequal n and unequal SD per
    # group so Welch and Student disagree in both t and df, not just in
    # name. Hand-seeded and rounded so both R and the Praat probe read the
    # identical literal numbers -- no re-derivation on either side.
    # -------------------------------------------------------------------
    mk <- function(seed, ns, means, sds) {
        set.seed(seed)
        Map(function(n, m, s) round(rnorm(n, m, s), 6), ns, means, sds)
    }
    fixtures <- list(
        f1 = mk(1001, c(4, 5, 6, 7),  c(10, 12, 15, 11),  c(1, 3, 0.5, 2)),
        f2 = mk(1002, c(5, 5, 5, 5),  c(0, 2, -1, 3),     c(1, 1, 1, 1)),
        f3 = mk(1003, c(3, 8, 4, 6),  c(5, 5.5, 4, 6),    c(0.3, 2, 1, 0.7)),
        f4 = mk(1004, c(6, 6, 4, 4),  c(20, 18, 22, 19),  c(2, 0.4, 3, 1)),
        f5 = mk(1005, c(4, 6, 5, 4),  c(-2, 3, 0, -5),    c(1.5, 0.8, 2.2, 0.6))
    )
    GLAB <- c("A", "B", "C", "D")
    for (fx in fixtures) names(fx) <- GLAB
    fixtures <- lapply(fixtures, setNames, GLAB)

    # Pair order MATCHES @emlPairwiseT's own nested loop (i from 1 to k-1,
    # j from i+1 to k): (1,2) (1,3) (1,4) (2,3) (2,4) (3,4).
    pair_idx <- list(c(1, 2), c(1, 3), c(1, 4), c(2, 3), c(2, 4), c(3, 4))
    nPairs <- length(pair_idx)   # 6, fixed by k = 4 groups every fixture

    alphas <- c(a05 = 0.05, a01 = 0.01)
    types  <- c(welch = FALSE, student = TRUE)   # names -> var.equal

    oracle_cell <- function(fx, p, type_equal, alpha) {
        gi <- fx[[GLAB[p[1]]]]; gj <- fx[[GLAB[p[2]]]]
        lvl <- 1 - alpha / nPairs
        tt <- t.test(gi, gj, var.equal = type_equal, conf.level = lvl)
        list(md = mean(gi) - mean(gj), lo = tt$conf.int[1], hi = tt$conf.int[2])
    }

    # -------------------------------------------------------------------
    # THE PROBE GENERATOR. `analysis_file` / `inferential_file` let the
    # three red demonstrations swap in a mutated copy of exactly one file
    # while everything else stays the shipped tree -- the same technique
    # v108's negative control and v143's seeded copy both use.
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
        df <- do.call(rbind, lapply(GLAB, function(g) data.frame(
            value = fx[[g]], group = g, stringsAsFactors = FALSE)))
        c(sprintf('procedure build%s', tag),
          sprintf('  .id = Create Table with column names: "%s", 0, "value group"', tag),
          fmt_row(df),
          sprintf('  %s_id = .id', tag),
          "endproc")
    }

    # One probe drives every (fixture, type, alpha) run named in `runs`,
    # each a list(fixture=, type=, adj=, alpha=, tag=). Every run prints
    # one CELL line per pair through .meanDiffFlat# / .lowFlat# /
    # .highFlat# -- never through appendInfoLine text the shipped reporter
    # itself composes, which is the whole point.
    build_probe <- function(runs, analysis_file, inferential_file) {
        lines <- c(prelude(analysis_file, inferential_file), "",
                   "emlGroupSortAlphabetical = 0",
                   unlist(lapply(names(fixtures), function(tag)
                       build_fixture(tag, fixtures[[tag]]))),
                   sprintf("@build%s", names(fixtures)), "")
        for (r in runs) {
            lines <- c(lines,
                sprintf("emlAlpha = %s", format(r$alpha, digits = 17)),
                sprintf('@emlRunPairwiseAnalysis: %s_id, "value", "group", "%s", "%s"',
                        r$fixture, r$type, r$adj),
                "for .k from 1 to 6",
                sprintf('  appendInfoLine: "CELL %s ", .k, " ", fixed$ (emlReportPairwiseComparison.meanDiffFlat# [.k], 10), " ", fixed$ (emlReportPairwiseComparison.lowFlat# [.k], 10), " ", fixed$ (emlReportPairwiseComparison.highFlat# [.k], 10)',
                        r$tag),
                "endfor")
        }
        probe_path <- file.path(work, paste0("v144-", runs[[1]]$probeName, ".praat"))
        writeLines(c('writeInfoLine: "v144"', lines), probe_path)
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
            got[[paste(tag, k)]] <- list(md = v(p[4]), lo = v(p[5]), hi = v(p[6]))
        }
        got
    }

    DARK_STRINGS <- c("Mean difference (", "Hodges-Lehmann shift",
                       "simultaneous intervals")
    # A bracketed interval rendering appended to a per-pair row: two numbers
    # separated by a comma inside square brackets.
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
    # THE MAIN BATTERY -- 60 Welch + 60 Student cells, Bonferroni.
    # -------------------------------------------------------------------
    runs <- list()
    for (fxTag in names(fixtures)) {
        for (aTag in names(alphas)) {
            for (tTag in names(types)) {
                cellTag <- paste(fxTag, tTag, aTag, sep = "_")
                runs[[length(runs) + 1]] <- list(
                    fixture = fxTag, type = tTag, adj = "bonferroni",
                    alpha = alphas[[aTag]], tag = cellTag,
                    probeName = "battery")
            }
        }
    }
    # One canary Holm run (fixture f1, welch, alpha .05): estimate present,
    # interval absent, in the SHIPPED (unmutated) code -- the baseline that
    # red demo A's mutant is measured against.
    holmTag <- "f1_welch_holm_a05"
    runs[[length(runs) + 1]] <- list(fixture = "f1", type = "welch",
        adj = "holm", alpha = 0.05, tag = holmTag, probeName = "battery")

    probe_path <- build_probe(runs, file.path(plug, "stats", "eml-analysis.praat"),
                               file.path(plug, "stats", "eml-inferential.praat"))
    out <- drive(probe_path)
    ran <- !any(grepl("^Error", out))
    check_true(V, "the main battery probe ran with no Praat error", ran)
    if (!ran) {
        cat("      v144 battery probe output:\n      ",
            paste(utils::tail(out, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        got <- parse_cells(out)
        nCellsWelch <- 0L; nCellsStudent <- 0L
        for (r in runs) {
            if (identical(r$tag, holmTag)) next
            eqv <- types[[r$type]]
            for (k in seq_len(nPairs)) {
                key <- paste(r$tag, k)
                cell <- got[[key]]
                check_true(V, sprintf("[%s pair %d] a cell was printed at all", r$tag, k),
                           !is.null(cell))
                if (is.null(cell)) next
                oc <- oracle_cell(fixtures[[r$fixture]], pair_idx[[k]], eqv, r$alpha)
                check(V, sprintf("[%s pair %d] mean difference vs group means", r$tag, k),
                      cell$md, oc$md, tol = 1e-8)
                check(V, sprintf("[%s pair %d] interval low vs t.test", r$tag, k),
                      cell$lo, oc$lo, tol = 1e-8)
                check(V, sprintf("[%s pair %d] interval high vs t.test", r$tag, k),
                      cell$hi, oc$hi, tol = 1e-8)
                if (r$type == "welch") nCellsWelch <- nCellsWelch + 1L
                else nCellsStudent <- nCellsStudent + 1L
            }
        }
        check(V, "Welch cells checked", nCellsWelch, 60, tol = 0)
        check(V, "Student cells checked", nCellsStudent, 60, tol = 0)

        # -- the Holm canary: estimate present, interval absent -----------
        for (k in seq_len(nPairs)) {
            cell <- got[[paste(holmTag, k)]]
            check_true(V, sprintf("[holm canary pair %d] a cell was printed", k),
                       !is.null(cell))
            if (is.null(cell)) next
            check_true(V, sprintf("[holm canary pair %d] mean difference IS computed",
                                  k), is.finite(cell$md))
            check_true(V, sprintf("[holm canary pair %d] interval is NOT computed",
                                  k), is.na(cell$lo) && is.na(cell$hi))
        }

        assert_dark("main battery", out)
    }

    # -------------------------------------------------------------------
    # RED DEMO A -- a Holm row printing an interval.
    # -------------------------------------------------------------------
    holm_red <- nzchar(Sys.getenv("EML_HOLM_RED", unset = ""))
    src_a <- readLines(file.path(plug, "stats", "eml-analysis.praat"), warn = FALSE)
    needleA <- 'if .adjMethod$ = "bonferroni"'
    hitA <- grepl(needleA, src_a, fixed = TRUE)
    check_true(V, "red demo A's seed site exists in source, exactly once", sum(hitA) == 1)
    if (sum(hitA) == 1) {
        mutA_dir <- file.path(work, "mutantA"); dir.create(mutA_dir, showWarnings = FALSE)
        mutA <- file.path(mutA_dir, "eml-analysis.praat")
        writeLines(sub(needleA, 'if .adjMethod$ = "bonferroni" or .adjMethod$ = "holm"',
                       src_a, fixed = TRUE), mutA)

        runA <- list(fixture = "f1", type = "welch", adj = "holm", alpha = 0.05,
                     tag = "redA", probeName = "redA")
        probeA <- build_probe(list(runA), mutA,
                               file.path(plug, "stats", "eml-inferential.praat"))
        outA <- drive(probeA)
        ranA <- !any(grepl("^Error", outA))
        check_true(V, "[red A] the mutant probe ran", ranA)
        if (ranA) {
            gotA <- parse_cells(outA)
            cellA <- gotA[[paste("redA", 1)]]
            # There is no "wrong number" for this defect -- it is a
            # presence/absence failure, not a miscomputed value: Holm
            # defines no interval level at all, so an interval appearing
            # under Holm is the whole defect, independent of what number
            # it happens to hold. The main battery's Holm canary already
            # established that the SHIPPED code leaves it undefined; the
            # mutant is checked against that same correct expectation.
            if (holm_red) {
                cat("      EML_HOLM_RED: asserting the mutant leaves a Holm row's\n")
                cat("      interval undefined, as correct code must -- EXPECTED to FAIL.\n")
                check_true(V, "[RED A] mutant Holm row's interval is undefined (must go red)",
                           !is.null(cellA) && is.na(cellA$lo) && is.na(cellA$hi))
            } else {
                check_true(V, "[red A] the mutant DEFINES an interval for a Holm row -- the defect, reproduced on demand",
                           !is.null(cellA) && is.finite(cellA$lo) && is.finite(cellA$hi))
            }
        } else {
            cat("      v144 red-demo-A probe output:\n      ",
                paste(utils::tail(outA, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO B -- a Student interval on the Welch df, and the mirror.
    # -------------------------------------------------------------------
    df_red <- nzchar(Sys.getenv("EML_DF_RED", unset = ""))
    src_b <- readLines(file.path(plug, "stats", "eml-inferential.praat"), warn = FALSE)
    # Located by line index rather than a multi-line fixed string, which
    # readLines' line splits would make fragile.
    idxEqVar <- which(src_b == "        .eqVar = 0")
    check_true(V, "red demo B's seed site (.eqVar assignment) exists, exactly once",
               length(idxEqVar) == 1)
    if (length(idxEqVar) == 1) {
        insertAt <- idxEqVar + 3   # the endif closing the if-block, itself
        check_true(V, "red demo B's seed site's endif is where expected",
                   src_b[insertAt] == "        endif")
        mutB_dir <- file.path(work, "mutantB"); dir.create(mutB_dir, showWarnings = FALSE)
        mutB <- file.path(mutB_dir, "eml-inferential.praat")
        writeLines(append(src_b, "        .eqVar = 1 - .eqVar", after = insertAt), mutB)

        # f1's A vs C pair: n = 4 vs 6, SD = 1 vs 0.5 -- Welch and Student
        # disagree meaningfully in df (and therefore in interval width) on
        # this pair, which is what makes the flip detectable.
        runB1 <- list(fixture = "f1", type = "welch", adj = "bonferroni", alpha = 0.05,
                      tag = "redB_welch", probeName = "redB")
        runB2 <- list(fixture = "f1", type = "student", adj = "bonferroni", alpha = 0.05,
                      tag = "redB_student", probeName = "redB")
        probeB <- build_probe(list(runB1, runB2), file.path(plug, "stats", "eml-analysis.praat"), mutB)
        outB <- drive(probeB)
        ranB <- !any(grepl("^Error", outB))
        check_true(V, "[red B] the mutant probe ran", ranB)
        if (ranB) {
            gotB <- parse_cells(outB)
            welchOracle <- oracle_cell(fixtures$f1, pair_idx[[2]], FALSE, 0.05)   # pair (1,3) = A vs C
            studentOracle <- oracle_cell(fixtures$f1, pair_idx[[2]], TRUE, 0.05)
            cellWelchMut <- gotB[[paste("redB_welch", 2)]]
            cellStudentMut <- gotB[[paste("redB_student", 2)]]
            check_true(V, "[red B] mutant welch-labelled cell printed", !is.null(cellWelchMut))
            check_true(V, "[red B] mutant student-labelled cell printed", !is.null(cellStudentMut))
            if (df_red) {
                cat("      EML_DF_RED: asserting the mutant's welch-labelled interval\n")
                cat("      equals the correct welch oracle -- EXPECTED to FAIL.\n")
                check(V, "[RED B] mutant welch-labelled interval vs correct welch oracle (must go red)",
                      cellWelchMut$lo, welchOracle$lo, tol = 1e-8)
            } else if (!is.null(cellWelchMut)) {
                check(V, "[red B] mutant welch-labelled interval DIFFERS from correct welch oracle",
                      cellWelchMut$lo, welchOracle$lo, tol = 1e-8, expect = "differ")
                check(V, "[red B] mutant welch-labelled interval instead matches the STUDENT oracle",
                      cellWelchMut$lo, studentOracle$lo, tol = 1e-8)
            }
            if (!is.null(cellStudentMut)) {
                check(V, "[red B] mirror: mutant student-labelled interval DIFFERS from correct student oracle",
                      cellStudentMut$lo, studentOracle$lo, tol = 1e-8, expect = "differ")
                check(V, "[red B] mirror: mutant student-labelled interval instead matches the WELCH oracle",
                      cellStudentMut$lo, welchOracle$lo, tol = 1e-8)
            }
        } else {
            cat("      v144 red-demo-B probe output:\n      ",
                paste(utils::tail(outB, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO C -- a Bonferroni interval at 1 - alpha, not 1 - alpha/m.
    # -------------------------------------------------------------------
    alpha_red <- nzchar(Sys.getenv("EML_ALPHA_RED", unset = ""))
    src_c <- readLines(file.path(plug, "stats", "eml-analysis.praat"), warn = FALSE)
    needleC <- "                    .pairLevel = 1 - .alpha / emlPairwiseT.nPairs"
    hitC <- src_c == needleC
    check_true(V, "red demo C's seed site (the level formula) exists, exactly once",
               sum(hitC) == 1)
    if (sum(hitC) == 1) {
        mutC_dir <- file.path(work, "mutantC"); dir.create(mutC_dir, showWarnings = FALSE)
        mutC <- file.path(mutC_dir, "eml-analysis.praat")
        writeLines(sub(needleC, "                    .pairLevel = 1 - .alpha",
                       src_c, fixed = TRUE), mutC)

        runC <- list(fixture = "f1", type = "welch", adj = "bonferroni", alpha = 0.05,
                     tag = "redC", probeName = "redC")
        probeC <- build_probe(list(runC), mutC,
                               file.path(plug, "stats", "eml-inferential.praat"))
        outC <- drive(probeC)
        ranC <- !any(grepl("^Error", outC))
        check_true(V, "[red C] the mutant probe ran", ranC)
        if (ranC) {
            gotC <- parse_cells(outC)
            cellC <- gotC[[paste("redC", 1)]]
            mCorrected <- oracle_cell(fixtures$f1, pair_idx[[1]], FALSE, 0.05)      # 1 - alpha/6
            uncorrected <- t.test(fixtures$f1$A, fixtures$f1$B, var.equal = FALSE,
                                   conf.level = 1 - 0.05)$conf.int
            check_true(V, "[red C] the mutant probe printed a cell", !is.null(cellC))
            if (!is.null(cellC)) {
                if (alpha_red) {
                    cat("      EML_ALPHA_RED: asserting the mutant's interval equals the\n")
                    cat("      m-corrected oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED C] mutant interval vs 1 - alpha/m oracle (must go red)",
                          cellC$lo, mCorrected$lo, tol = 1e-8)
                } else {
                    check(V, "[red C] mutant interval DIFFERS from the 1 - alpha/m oracle",
                          cellC$lo, mCorrected$lo, tol = 1e-8, expect = "differ")
                    check(V, "[red C] mutant interval instead matches the plain 1 - alpha oracle",
                          cellC$lo, uncorrected[1], tol = 1e-8)
                    check_true(V, "[red C] the mutant interval is NARROWER than the correct one",
                               (cellC$hi - cellC$lo) < (mCorrected$hi - mCorrected$lo))
                }
            }
        } else {
            cat("      v144 red-demo-C probe output:\n      ",
                paste(utils::tail(outC, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # THE HANG GUARD, direct. @emlTTestInterval is called with .t = 0 and
    # separately with .df undefined; both must set .error$ and leave every
    # numeric output undefined WITHOUT the process hanging -- the process
    # completing at all, inside the timeout above, is half the evidence.
    # -------------------------------------------------------------------
    guard_lines <- c(prelude(file.path(plug, "stats", "eml-analysis.praat"),
                              file.path(plug, "stats", "eml-inferential.praat")), "",
        '@emlTTestInterval: 5, 0, 10, 0.95',
        'appendInfoLine: "GUARD tzero ", emlTTestInterval.low, " ", emlTTestInterval.high, " [", emlTTestInterval.error$, "]"',
        '@emlTTestInterval: 5, 2, undefined, 0.95',
        'appendInfoLine: "GUARD dfundef ", emlTTestInterval.low, " ", emlTTestInterval.high, " [", emlTTestInterval.error$, "]"',
        '@emlTTestInterval: 4, 2.5, 17.3, 0.95',
        'appendInfoLine: "GUARD clean ", fixed$ (emlTTestInterval.low, 10), " ", fixed$ (emlTTestInterval.high, 10), " [", emlTTestInterval.error$, "]"')
    guard_path <- file.path(work, "v144-guard.praat")
    writeLines(c('writeInfoLine: "v144 guard"', guard_lines), guard_path)
    outG <- drive(guard_path)
    ranG <- !any(grepl("^Error", outG))
    check_true(V, "the guard probe ran (completed -- did not hang) with no Praat error", ranG)
    if (ranG) {
        tzero <- grep("^GUARD tzero", outG, value = TRUE)
        dfundef <- grep("^GUARD dfundef", outG, value = TRUE)
        clean <- grep("^GUARD clean", outG, value = TRUE)
        check_true(V, "t = 0 sets .error$ and leaves low/high undefined",
                   length(tzero) == 1 &&
                   grepl("--undefined--.*--undefined--", tzero) &&
                   !grepl("\\[\\]", tzero))
        check_true(V, "df undefined sets .error$ and leaves low/high undefined",
                   length(dfundef) == 1 &&
                   grepl("--undefined--.*--undefined--", dfundef) &&
                   !grepl("\\[\\]", dfundef))
        if (length(clean) == 1) {
            m <- regmatches(clean, regexec(
                "GUARD clean (-?[0-9.]+) (-?[0-9.]+) \\[(.*)\\]", clean))[[1]]
            check_true(V, "a clean call parsed", length(m) == 4)
            if (length(m) == 4) {
                # meanDiff = 4, t = 2.5 -> se = 1.6; independent closed-form
                # check against R's own qt, not against t.test (no data here).
                se <- 4 / 2.5
                tCrit <- qt(1 - (1 - 0.95) / 2, 17.3)
                lo <- 4 - abs(tCrit) * se; hi <- 4 + abs(tCrit) * se
                check(V, "clean call low bound vs closed-form qt", as.numeric(m[2]), lo, tol = 1e-8)
                check(V, "clean call high bound vs closed-form qt", as.numeric(m[3]), hi, tol = 1e-8)
                check_true(V, "clean call's .error$ is empty", identical(m[4], ""))
            }
        } else {
            check_true(V, "a clean call parsed", FALSE)
        }
    } else {
        cat("      v144 guard probe output:\n      ",
            paste(utils::tail(outG, 20), collapse = "\n      "), "\n", sep = "")
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v144 @emlTTestInterval and the 3.6 wiring")
    eml_exit()
}
