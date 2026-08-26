# ============================================================================
# v145 — @emlHodgesLehmannTwoSample and the 3.8 wiring: HL shift + interval
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. docs/WORK_ORDER_INTERVALS_2026-08-26.md (item 3) adds
# @emlHodgesLehmannTwoSample (plugin/stats/eml-inferential.praat) and wires
# the pairwise-Wilcoxon orchestrator (@emlPairwiseWilcoxon /
# @emlReportPairwiseComparison, plugin/stats/eml-analysis.praat) to compute,
# on every row:
#
#   * the point estimate -- the Hodges-Lehmann shift, the median of the
#     n1 * n2 cross-differences -- every row, every correction;
#   * the interval, ONLY when the correction in force defines one --
#     Bonferroni at .level = 1 - alpha/m per pair; Holm and BH define none.
#
# As with item 2 (v144), docs/RULING_INTERVALS_2026-08-26.md's "Language"
# section gates the strings that would PRINT these on Ian's en-bloc
# approval. The shipped code therefore computes both quantities and stores
# them as outputs of @emlReportPairwiseComparison -- .hlEstFlat#,
# .hlLowFlat#, .hlHighFlat#, .hlMethod$[] -- and no appendInfoLine anywhere
# in that procedure reads any of them. This file verifies both halves: the
# numbers are right, and they are dark.
#
# ---------------------------------------------------------------------------
# THE ORACLE, AND WHICH R IT IS
# ---------------------------------------------------------------------------
# R's wilcox.test(x, y, conf.int = TRUE, conf.level = 1 - alpha/m), read
# directly. The plugin's interval is a PORT of that function's two branches,
# not an independent derivation that happens to agree:
#
#   exact branch -- the critical rank is qwilcox(alpha/2, n1, n2) with R's
#     "if (qu == 0) qu <- 1" bump, and the bounds are the sorted
#     cross-differences at k and n1*n2 + 1 - k. The plugin reads the rank off
#     the SAME dynamic-programming U null distribution its exact p-value
#     comes from (@eml_mannWhitneyExactP), which is why .dp## and .total are
#     part of that helper's documented contract.
#
#   approximation branch -- R's continuity-corrected z inversion: W(d), the
#     root() endpoint returns, and Brent's zeroin at R's own tol.root = 1e-4.
#
# THE POINT ESTIMATE IS ORACLED AGAINST median(outer(x, y, "-")), NOT
# AGAINST wilcox.test's $estimate, and the difference is not a slackening.
# On the EXACT branch R's own $estimate IS median(diffs) and this file
# asserts the two agree there. On the APPROXIMATION branch R's $estimate is
# something else -- a root of W with the continuity correction switched off,
# found by uniroot -- while Fable's work order pins the plugin's estimate to
# the median of the cross-differences on BOTH branches. So on approximation
# cells the median is the specified quantity and R's $estimate is a
# different estimator of the same shift; asserting the plugin against
# $estimate there would be asserting it against a number the order does not
# ask it to produce. Both are reported below, so the gap is visible rather
# than hidden by the choice of oracle.
#
# ---------------------------------------------------------------------------
# THE BATTERY -- ALL FOUR CELLS THE WORK ORDER NAMES
# ---------------------------------------------------------------------------
# The order asks for {two-sample, paired} x {exact, approximation}, in the
# three shapes that force the branches: small untied, tied, large-n. PART 3
# below is the paired half, and it is deliberately NOT written yet (item 4);
# it is a stated gap with a tripwire, not a stub that passes.
#
# The two-sample half is driven twice over, because the branch and the
# wiring are separate claims:
#
#   PART 1 -- @emlHodgesLehmannTwoSample called DIRECTLY on five fixtures
#     (two untied-small, one tied-small, one tied-large, one untied-large)
#     at four confidence levels each -- 0.95 and the Bonferroni levels
#     1 - .05/6, 1 - .01/6, 1 - .05/3. Twenty cells. Every cell asserts the
#     estimate, both bounds, and THE BRANCH: .method$ must equal both the
#     branch R took and the branch @emlMannWhitneyU takes on the same two
#     vectors. That last assertion is the point of copying the gate verbatim
#     rather than re-deriving it -- an interval built on the exact null
#     distribution printed beside a p-value built on the normal
#     approximation is a self-contradicting report in which neither number
#     looks wrong on its own.
#
#   PART 2 -- the same quantities through the shipped
#     @emlRunPairwiseAnalysis -> @emlPairwiseWilcoxon ->
#     @emlReportPairwiseComparison chain, end to end, exactly as the menu
#     item runs it: three 3-group fixtures (untied-small, tied, large-n) at
#     two alphas, Bonferroni, plus a Holm canary that must show the estimate
#     present and the interval absent.
#
# ---------------------------------------------------------------------------
# THE THREE RED DEMONSTRATIONS Fable's order requires, built the way v108's
# negative control and v144's three are: the shipped source is copied to a
# scratch file, ONE line is changed or inserted, and the mutant is driven
# exactly like the real thing. In normal mode each asserts the mutant's
# numbers DIFFER from the correct oracle -- proof this validator would have
# caught the defect had it shipped. Set the matching EML_*_RED variable to
# watch any one of them go red against the correct oracle instead.
#
#   A. AN OFF-BY-ONE IN THE CRITICAL RANK k. One line, ".k = .k + 1", is
#      inserted after the "if (qu == 0) qu <- 1" bump and before the bounds
#      are taken, so the exact interval is read at ranks k+1 and
#      n1*n2 - k instead of k and n1*n2 + 1 - k. THIS IS THE DEFECT THAT
#      LOOKS RIGHT: the interval is still an interval, still centred near
#      the estimate, still narrower for smaller alpha -- it is simply the
#      wrong coverage, by one order statistic. The mutant is asserted to
#      differ from the correct oracle AND to match the off-by-one bounds
#      computed in R from the same sorted differences, which names the
#      defect exactly rather than merely detecting movement.
#      EML_RANK_RED=1 makes this the standard agreement check.
#
#   B. AN INTERVAL AT 1 - ALPHA, not 1 - alpha/m. The level formula in
#      @emlReportPairwiseComparison's Wilcoxon branch is mutated from
#      "1 - .alpha / emlPairwiseWilcoxon.nPairs" to "1 - .alpha" -- R's
#      wilcox.test default, the uncorrected interval, printed as though it
#      were the Bonferroni one. The mutant's bounds differ from the
#      m-corrected oracle, match the plain 1 - alpha oracle, and are
#      narrower. EML_ALPHA_RED=1 makes this the standard check.
#
#   C. A HOLM ROW PRINTING ONE. The interval guard in the Wilcoxon branch is
#      widened to admit "holm" too. Driven with adjMethod "holm", the mutant
#      DEFINES .hlLowFlat#/.hlHighFlat# where the shipped code leaves them
#      undefined -- Holm has no defined interval level at all, so there is
#      no "wrong number" here, only a number where there must be none.
#      EML_HOLM_RED=1 makes this the standard check.
#
# ---------------------------------------------------------------------------
# THE DARK-KEEPING CLAIM. Every driven run's full Info-window text is
# grepped for the drafted strings -- "Hodges-Lehmann shift", "Mean
# difference (", "simultaneous intervals", and a bracketed "[low, high]"
# rendering appended to a per-pair row -- and none may appear. A green run
# here is the evidence for the work order's "report how you kept them dark".
#
# Base R only. No packages. Requires a Praat at or above the plugin's floor;
# skips (not fails) below it, the same convention v108, v143 and v144 use.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v145"

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
    cat(paste0("      SKIP: v145 needs Praat >= 6.6.30 to drive the procedure;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v145")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    INF <- file.path(plug, "stats", "eml-inferential.praat")
    ANA <- file.path(plug, "stats", "eml-analysis.praat")

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

    drive <- function(probe_path, secs = "240") {
        suppressWarnings(system2("timeout",
            c(secs, "env", "-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
            stdout = TRUE, stderr = TRUE))
    }

    # Round-trip-exact literals: %.17g reproduces the identical double on
    # the Praat side, so neither implementation is reading different data
    # from the other.
    vec_lit <- function(v) paste0("{", paste(sprintf("%.17g", v), collapse = ", "), "}")

    DARK_STRINGS <- c("Hodges-Lehmann shift", "Mean difference (",
                      "simultaneous intervals")
    DARK_BRACKET <- "\\[\\s*-?[0-9.]+\\s*,\\s*-?[0-9.]+\\s*\\]"
    assert_dark <- function(tag, out) {
        for (s in DARK_STRINGS) {
            check_true(V, sprintf("[%s] the drafted string '%s' never printed", tag, s),
                       !any(grepl(s, out, fixed = TRUE)))
        }
        check_true(V, sprintf("[%s] no bracketed [low, high] rendering printed", tag),
                   !any(grepl(DARK_BRACKET, out, perl = TRUE)))
    }

    num <- function(s) if (identical(s, "--undefined--")) NA_real_ else as.numeric(s)

    # -------------------------------------------------------------------
    # PART 0 -- THE GATE IS ONE TEXT, IN TWO PLACES.
    #
    # Fable's order says the branch gate is COPIED VERBATIM from
    # @emlMannWhitneyU, not reimplemented. A copied canon in this tree is
    # required to carry a text check that the copies still agree
    # (CLAUDE.md, "DRY here", v105 is the model) -- a procedure records a
    # rule, it does not enforce it, and the two copies drifting apart is
    # precisely the failure the behavioural cells above cannot see: they
    # would each still be internally consistent, and would each pick a
    # branch, and the two branches would differ.
    #
    # The window compared is the rationale comment plus the three nested
    # ifs -- the comment because the reason the gate is per-group n and
    # not combined n is the part a future edit is most likely to lose.
    # -------------------------------------------------------------------
    gate_src <- readLines(INF, warn = FALSE)
    GATE_HEAD <- "        .useExact = 0"
    gate_at <- which(gate_src == GATE_HEAD)
    check_true(V,
        sprintf("the two-sample exact gate appears in exactly two procedures (%d found)",
                length(gate_at)),
        length(gate_at) == 2)
    if (length(gate_at) == 2) {
        window <- function(i) gate_src[(i - 6):(i + 7)]
        check_true(V,
            "the gate @emlHodgesLehmannTwoSample uses is character-for-character the gate @emlMannWhitneyU uses, comment included",
            identical(window(gate_at[1]), window(gate_at[2])))
        # And it is the gate it is supposed to be, not two copies of
        # something else that happen to match each other.
        blk <- paste(window(gate_at[1]), collapse = "\n")
        check_true(V, "that shared gate is n1 < 50, n2 < 50, no ties, as three nested ifs",
            grepl("if .n1 < 50", blk, fixed = TRUE) &&
            grepl("if .n2 < 50", blk, fixed = TRUE) &&
            grepl("if .hasTies = 0", blk, fixed = TRUE))
        # The procedures the two copies live in, named -- so a gate that
        # migrated into some third procedure is not silently accepted as
        # "still two".
        owner <- function(i) {
            heads <- grep("^procedure ", gate_src[seq_len(i)])
            sub("^procedure ([A-Za-z_0-9]+).*$", "\\1", gate_src[max(heads)])
        }
        check_true(V, sprintf("the two copies live in @emlMannWhitneyU and @emlHodgesLehmannTwoSample (found %s, %s)",
                              owner(gate_at[1]), owner(gate_at[2])),
                   identical(sort(c(owner(gate_at[1]), owner(gate_at[2]))),
                             c("emlHodgesLehmannTwoSample", "emlMannWhitneyU")))
    }

    # -------------------------------------------------------------------
    # PART 1 -- the procedure itself, all four two-sample cells.
    # -------------------------------------------------------------------
    set.seed(2145)
    fixtures <- list(
        # small, untied -> exact
        ts_small_a = list(x = c(5.1, 4.2, 6.3, 5.8, 7.1),
                          y = c(3.2, 4.9, 2.8, 3.9, 5.5, 4.1),
                          branch = "exact"),
        ts_small_b = list(x = round(rnorm(12, 10, 2), 6),
                          y = round(rnorm(15, 8.5, 2), 6),
                          branch = "exact"),
        # tied -> normal approximation, whatever the n
        ts_tied_small = list(x = c(5, 4, 6, 5, 7, 4),
                             y = c(3, 5, 3, 4, 5, 4),
                             branch = "normal approximation"),
        ts_tied_large = list(x = sample(1:10, 40, TRUE),
                             y = sample(1:10, 45, TRUE),
                             branch = "normal approximation"),
        # large n, untied -> normal approximation by the n >= 50 gate
        ts_large = list(x = round(rnorm(55, 10, 2), 6),
                        y = round(rnorm(52, 9, 2), 6),
                        branch = "normal approximation")
    )
    levels_ <- c(plain95 = 0.95,
                 bonf6_05 = 1 - 0.05 / 6,
                 bonf6_01 = 1 - 0.01 / 6,
                 bonf3_05 = 1 - 0.05 / 3)

    direct_lines <- c(prelude(ANA, INF), "",
        "procedure v145direct: .tag$, .a#, .b#, .lev",
        "    @emlHodgesLehmannTwoSample: .a#, .b#, .lev",
        "    .est$ = fixed$ (emlHodgesLehmannTwoSample.estimate, 12)",
        "    .lo$ = fixed$ (emlHodgesLehmannTwoSample.low, 12)",
        "    .hi$ = fixed$ (emlHodgesLehmannTwoSample.high, 12)",
        "    .hlm$ = emlHodgesLehmannTwoSample.method$",
        "    .err$ = emlHodgesLehmannTwoSample.error$",
        "    @emlMannWhitneyU: .a#, .b#, 2",
        "    .mwm$ = emlMannWhitneyU.method$",
        "    appendInfoLine: \"DIRECT \", .tag$, \" \", .est$, \" \", .lo$, \" \", .hi$,",
        "    ... \" [\", .hlm$, \"] [\", .mwm$, \"] [\", .err$, \"]\"",
        "endproc", "")
    for (fxTag in names(fixtures)) {
        fx <- fixtures[[fxTag]]
        direct_lines <- c(direct_lines,
            sprintf("x# = %s", vec_lit(fx$x)),
            sprintf("y# = %s", vec_lit(fx$y)))
        for (lvTag in names(levels_)) {
            direct_lines <- c(direct_lines,
                sprintf('@v145direct: "%s", x#, y#, %.17g',
                        paste(fxTag, lvTag, sep = "|"), levels_[[lvTag]]))
        }
    }
    direct_path <- file.path(work, "v145-direct.praat")
    writeLines(c('writeInfoLine: "v145 direct"', direct_lines), direct_path)
    outD <- drive(direct_path)
    ranD <- !any(grepl("^Error", outD))
    check_true(V, "the direct-call probe ran with no Praat error", ranD)

    parse_direct <- function(out) {
        got <- list()
        for (ln in grep("^DIRECT ", out, value = TRUE)) {
            m <- regmatches(ln, regexec(
                "^DIRECT (\\S+) (\\S+) (\\S+) (\\S+) \\[([^]]*)\\] \\[([^]]*)\\] \\[(.*)\\]$",
                ln))[[1]]
            if (length(m) == 8) {
                got[[m[2]]] <- list(est = num(m[3]), lo = num(m[4]), hi = num(m[5]),
                                    hlm = m[6], mwm = m[7], err = m[8])
            }
        }
        got
    }

    nDirect <- 0L
    if (ranD) {
        gotD <- parse_direct(outD)
        for (fxTag in names(fixtures)) {
            fx <- fixtures[[fxTag]]
            for (lvTag in names(levels_)) {
                key <- paste(fxTag, lvTag, sep = "|")
                cell <- gotD[[key]]
                check_true(V, sprintf("[%s] a direct cell was printed at all", key),
                           !is.null(cell))
                if (is.null(cell)) next
                lvl <- levels_[[lvTag]]
                w <- suppressWarnings(wilcox.test(fx$x, fx$y, conf.int = TRUE,
                                                  conf.level = lvl))
                med <- median(outer(fx$x, fx$y, "-"))

                check(V, sprintf("[%s] HL estimate vs median of the cross-differences", key),
                      cell$est, med, tol = 1e-8)
                check(V, sprintf("[%s] interval low vs wilcox.test conf.int", key),
                      cell$lo, w$conf.int[1], tol = 1e-8)
                check(V, sprintf("[%s] interval high vs wilcox.test conf.int", key),
                      cell$hi, w$conf.int[2], tol = 1e-8)
                check_true(V, sprintf("[%s] .error$ is empty on a well-formed sample", key),
                           identical(cell$err, ""))

                # THE BRANCH, asserted three ways: what the fixture was
                # built to force, what R took, and what the p-value's own
                # procedure takes on the identical vectors.
                rBranch <- if (grepl("exact", w$method)) "exact" else "normal approximation"
                check_true(V, sprintf("[%s] .method$ is the branch the fixture forces (%s)",
                                      key, fx$branch), identical(cell$hlm, fx$branch))
                check_true(V, sprintf("[%s] .method$ is the branch R's wilcox.test took (%s)",
                                      key, rBranch), identical(cell$hlm, rBranch))
                check_true(V, sprintf("[%s] the interval's branch is the p-value's branch (@emlMannWhitneyU said '%s')",
                                      key, cell$mwm), identical(cell$hlm, cell$mwm))

                # On the exact branch R's own $estimate IS median(diffs);
                # asserted, so the divergence on the other branch is a
                # measured fact rather than an assumption.
                if (identical(rBranch, "exact")) {
                    check(V, sprintf("[%s] on the exact branch R's own $estimate is that same median", key),
                          as.numeric(w$estimate), med, tol = 1e-9)
                }
                nDirect <- nDirect + 1L
            }
        }
        check(V, "direct cells checked (5 fixtures x 4 levels)", nDirect, 20, tol = 0)
        assert_dark("direct", outD)
    } else {
        cat("      v145 direct probe output:\n      ",
            paste(utils::tail(outD, 30), collapse = "\n      "), "\n", sep = "")
    }

    # -------------------------------------------------------------------
    # PART 1b -- THE CRITICAL RANK ITSELF, against R's qwilcox.
    #
    # The bounds above are order statistics, so a wrong rank shows up in
    # them -- but only as a number that still looks like an interval. The
    # rank is the quantity, so it is asserted as the quantity: the
    # procedure's own .k is read back and compared to R's
    # qwilcox(alpha/2, n1, n2) with R's "if (qu == 0) qu <- 1" bump, over
    # a grid of group sizes and levels chosen to straddle the bump (tiny
    # n at a tight level gives qu = 0 and must come back 1) and the
    # ordinary case. This is the one assertion that would still be red if
    # the DP, the fuzz and the bump conspired to give plausible bounds.
    # -------------------------------------------------------------------
    set.seed(4145)
    rank_grid <- list(c(3, 5), c(4, 4), c(5, 6), c(8, 7), c(12, 15), c(20, 18))
    rank_alphas <- c(0.05, 0.01, 0.05 / 6, 0.01 / 6, 0.05 / 3)
    rank_cases <- list()
    rlines <- c(prelude(ANA, INF), "",
        "procedure v145rank: .tag$, .a#, .b#, .lev",
        "    @emlHodgesLehmannTwoSample: .a#, .b#, .lev",
        "    appendInfoLine: \"RANK \", .tag$, \" \", emlHodgesLehmannTwoSample.k,",
        "    ... \" [\", emlHodgesLehmannTwoSample.method$, \"]\"",
        "endproc", "")
    for (ns in rank_grid) {
        # Untied by construction on both sides -- one continuous draw,
        # split -- so every cell lands on the exact branch.
        pool <- round(rnorm(ns[1] + ns[2], 0, 3), 8)
        while (anyDuplicated(pool)) pool <- round(rnorm(ns[1] + ns[2], 0, 3), 8)
        xs <- pool[seq_len(ns[1])]; ys <- pool[-seq_len(ns[1])]
        rlines <- c(rlines, sprintf("x# = %s", vec_lit(xs)),
                             sprintf("y# = %s", vec_lit(ys)))
        for (al in rank_alphas) {
            tag <- sprintf("n%d_%d_a%s", ns[1], ns[2], format(al, digits = 6))
            rank_cases[[tag]] <- list(x = xs, y = ys, alpha = al, n = ns)
            rlines <- c(rlines, sprintf('@v145rank: "%s", x#, y#, %.17g',
                                        tag, 1 - al))
        }
    }
    rank_path <- file.path(work, "v145-rank.praat")
    writeLines(c('writeInfoLine: "v145 rank"', rlines), rank_path)
    outR <- drive(rank_path)
    ranR <- !any(grepl("^Error", outR))
    check_true(V, "the critical-rank probe ran with no Praat error", ranR)
    if (ranR) {
        gotR <- list()
        for (ln in grep("^RANK ", outR, value = TRUE)) {
            m <- regmatches(ln, regexec("^RANK (\\S+) (\\S+) \\[([^]]*)\\]$", ln))[[1]]
            if (length(m) == 4) gotR[[m[2]]] <- list(k = num(m[3]), meth = m[4])
        }
        nBumped <- 0L
        for (tag in names(rank_cases)) {
            rc <- rank_cases[[tag]]
            cell <- gotR[[tag]]
            check_true(V, sprintf("[rank %s] a rank was printed", tag), !is.null(cell))
            if (is.null(cell)) next
            check_true(V, sprintf("[rank %s] the cell is on the exact branch", tag),
                       identical(cell$meth, "exact"))
            qu <- qwilcox(rc$alpha / 2, rc$n[1], rc$n[2])
            if (qu == 0) { qu <- 1; nBumped <- nBumped + 1L }
            check(V, sprintf("[rank %s] critical rank k vs R's qwilcox(alpha/2, n1, n2)", tag),
                  cell$k, qu, tol = 0)
        }
        check_true(V,
            sprintf("the grid actually straddles R's qu == 0 bump (%d cell(s) needed it)", nBumped),
            nBumped > 0L)
        assert_dark("critical rank", outR)
    } else {
        cat("      v145 rank probe output:\n      ",
            paste(utils::tail(outR, 20), collapse = "\n      "), "\n", sep = "")
    }

    # -------------------------------------------------------------------
    # PART 2 -- the 3.8 wiring, end to end through the orchestrator.
    # -------------------------------------------------------------------
    GLAB <- c("A", "B", "C")
    pair_idx <- list(c(1, 2), c(1, 3), c(2, 3))
    nPairs <- length(pair_idx)

    set.seed(3145)
    wire_fx <- list(
        w_small = list(A = round(rnorm(6, 10, 2), 6), B = round(rnorm(7, 12, 2), 6),
                       C = round(rnorm(8, 8, 2), 6)),
        w_tied  = list(A = c(5, 4, 6, 5, 7, 4, 6), B = c(3, 5, 3, 4, 5, 4),
                       C = c(8, 7, 8, 9, 7, 8, 9)),
        w_large = list(A = round(rnorm(52, 10, 2), 6), B = round(rnorm(55, 11, 2), 6),
                       C = round(rnorm(51, 9, 2), 6))
    )
    alphas <- c(a05 = 0.05, a01 = 0.01)

    build_fixture <- function(tag, fx) {
        rows <- do.call(rbind, lapply(GLAB, function(g) data.frame(
            value = fx[[g]], group = g, stringsAsFactors = FALSE)))
        c(sprintf('procedure build%s', tag),
          sprintf('  .id = Create Table with column names: "%s", 0, "value group"', tag),
          vapply(seq_len(nrow(rows)), function(i) sprintf(
            '  Append row\n  .r = Get number of rows\n  Set string value: .r, "value", "%s"\n  Set string value: .r, "group", "%s"',
            sprintf("%.17g", rows$value[i]), rows$group[i]), character(1)),
          sprintf('  %s_id = .id', tag),
          "endproc")
    }

    build_probe <- function(runs, analysis_file, inferential_file, name) {
        lines <- c(prelude(analysis_file, inferential_file), "",
                   "emlGroupSortAlphabetical = 0",
                   unlist(lapply(names(wire_fx), function(tag)
                       build_fixture(tag, wire_fx[[tag]]))),
                   sprintf("@build%s", names(wire_fx)), "")
        for (r in runs) {
            lines <- c(lines,
                sprintf("emlAlpha = %.17g", r$alpha),
                sprintf('@emlRunPairwiseAnalysis: %s_id, "value", "group", "wilcoxon", "%s"',
                        r$fixture, r$adj),
                sprintf("for .k from 1 to %d", nPairs),
                sprintf('  appendInfoLine: "CELL %s ", .k, " ", fixed$ (emlReportPairwiseComparison.hlEstFlat# [.k], 12), " ", fixed$ (emlReportPairwiseComparison.hlLowFlat# [.k], 12), " ", fixed$ (emlReportPairwiseComparison.hlHighFlat# [.k], 12), " [", emlReportPairwiseComparison.hlMethod$ [.k], "]"',
                        r$tag),
                "endfor")
        }
        probe_path <- file.path(work, paste0("v145-", name, ".praat"))
        writeLines(c('writeInfoLine: "v145"', lines), probe_path)
        probe_path
    }

    parse_cells <- function(out) {
        got <- list()
        for (ln in grep("^CELL ", out, value = TRUE)) {
            m <- regmatches(ln, regexec(
                "^CELL (\\S+) (\\d+) (\\S+) (\\S+) (\\S+) \\[([^]]*)\\]$", ln))[[1]]
            if (length(m) == 7) {
                got[[paste(m[2], m[3])]] <- list(est = num(m[4]), lo = num(m[5]),
                                                 hi = num(m[6]), meth = m[7])
            }
        }
        got
    }

    oracle_pair <- function(fx, p, alpha) {
        gi <- fx[[GLAB[p[1]]]]; gj <- fx[[GLAB[p[2]]]]
        lvl <- 1 - alpha / nPairs
        w <- suppressWarnings(wilcox.test(gi, gj, conf.int = TRUE, conf.level = lvl))
        list(est = median(outer(gi, gj, "-")),
             lo = w$conf.int[1], hi = w$conf.int[2],
             meth = if (grepl("exact", w$method)) "exact" else "normal approximation")
    }

    runs <- list()
    for (fxTag in names(wire_fx)) {
        for (aTag in names(alphas)) {
            runs[[length(runs) + 1]] <- list(
                fixture = fxTag, adj = "bonferroni", alpha = alphas[[aTag]],
                tag = paste(fxTag, aTag, sep = "_"))
        }
    }
    # BOTH correction-without-a-level arms, not just one. The work order
    # names "Holm and BH rows: estimate yes, interval no", and the two
    # reach the guard by different routes through @emlPairwiseWilcoxon's
    # adjustment switch.
    holmTag <- "w_small_holm_a05"
    runs[[length(runs) + 1]] <- list(fixture = "w_small", adj = "holm",
                                      alpha = 0.05, tag = holmTag)
    bhTag <- "w_small_bh_a05"
    runs[[length(runs) + 1]] <- list(fixture = "w_small", adj = "bh",
                                      alpha = 0.05, tag = bhTag)

    probe_path <- build_probe(runs, ANA, INF, "battery")
    out <- drive(probe_path)
    ran <- !any(grepl("^Error", out))
    check_true(V, "the wiring battery probe ran with no Praat error", ran)
    if (!ran) {
        cat("      v145 battery probe output:\n      ",
            paste(utils::tail(out, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        got <- parse_cells(out)
        nWired <- 0L
        for (r in runs) {
            if (identical(r$tag, holmTag) || identical(r$tag, bhTag)) next
            for (k in seq_len(nPairs)) {
                cell <- got[[paste(r$tag, k)]]
                check_true(V, sprintf("[%s pair %d] a cell was printed at all", r$tag, k),
                           !is.null(cell))
                if (is.null(cell)) next
                oc <- oracle_pair(wire_fx[[r$fixture]], pair_idx[[k]], r$alpha)
                check(V, sprintf("[%s pair %d] HL estimate vs median cross-difference", r$tag, k),
                      cell$est, oc$est, tol = 1e-8)
                check(V, sprintf("[%s pair %d] interval low vs wilcox.test at 1 - alpha/m", r$tag, k),
                      cell$lo, oc$lo, tol = 1e-8)
                check(V, sprintf("[%s pair %d] interval high vs wilcox.test at 1 - alpha/m", r$tag, k),
                      cell$hi, oc$hi, tol = 1e-8)
                check_true(V, sprintf("[%s pair %d] the branch recorded is R's branch (%s)",
                                      r$tag, k, oc$meth), identical(cell$meth, oc$meth))
                nWired <- nWired + 1L
            }
        }
        check(V, "wired cells checked (3 fixtures x 2 alphas x 3 pairs)", nWired, 18, tol = 0)

        # -- the Holm and BH canaries: estimate present, interval absent -
        for (cTag in c(holm = holmTag, bh = bhTag)) {
            nm <- names(which(c(holm = holmTag, bh = bhTag) == cTag))
            for (k in seq_len(nPairs)) {
                cell <- got[[paste(cTag, k)]]
                check_true(V, sprintf("[%s canary pair %d] a cell was printed", nm, k),
                           !is.null(cell))
                if (is.null(cell)) next
                check_true(V, sprintf("[%s canary pair %d] the HL estimate IS computed", nm, k),
                           is.finite(cell$est))
                check_true(V, sprintf("[%s canary pair %d] the interval is NOT computed", nm, k),
                           is.na(cell$lo) && is.na(cell$hi))
                # And the estimate is the same number Bonferroni reports:
                # the point estimate does not depend on the correction,
                # only the interval does.
                oc <- oracle_pair(wire_fx$w_small, pair_idx[[k]], 0.05)
                check(V, sprintf("[%s canary pair %d] that estimate is the correction-free median", nm, k),
                      cell$est, oc$est, tol = 1e-8)
            }
        }

        assert_dark("wiring battery", out)
    }

    # -------------------------------------------------------------------
    # PART 3 -- THE PAIRED HALF. STATED, NOT WRITTEN.
    #
    # Fable's order builds this file to cover items 3 AND 4, and item 4 --
    # @emlHodgesLehmannPaired (the median of the n(n+1)/2 Walsh averages,
    # the T+ DP for the exact critical rank, the one-sample form of the
    # same ported inversion) plus the 3.7 wiring of @emlRMPostHoc's
    # signed-rank branch -- is not built yet. The paired cells this file
    # will need are the mirror of PART 1's:
    #
    #   paired x exact               -- small untied differences, n < 50
    #   paired x normal approximation -- ties among |differences|, and n >= 50
    #
    # oracled against wilcox.test(x, y, paired = TRUE, conf.int = TRUE,
    # conf.level = 1 - alpha/m), with the same three red demonstrations
    # re-aimed at the paired critical rank, the paired level, and a Holm
    # row on the repeated-measures post-hoc.
    #
    # WRITING A STUB THAT PASSES HERE WOULD BE WORSE THAN WRITING NOTHING:
    # the suite would report coverage of a procedure that does not exist.
    # So there is no paired assertion below -- only a TRIPWIRE. The moment
    # @emlHodgesLehmannPaired lands in the tree, this check goes red until
    # the section above it is written, so item 4 cannot ship uncovered by
    # the check that was built for it.
    # -------------------------------------------------------------------
    inf_src <- readLines(INF, warn = FALSE)
    paired_landed <- any(grepl("^procedure emlHodgesLehmannPaired", inf_src))
    if (paired_landed) {
        cat("      v145: @emlHodgesLehmannPaired is now in the tree. PART 3 of this\n")
        cat("      file (the paired half of the battery and its red demos) is still\n")
        cat("      unwritten -- write it; do not delete this tripwire.\n")
    }
    check_true(V,
        "PART 3 (paired) is an unwritten, stated gap and @emlHodgesLehmannPaired has not landed yet -- when it does, this reds until PART 3 is written",
        !paired_landed)

    # -------------------------------------------------------------------
    # RED DEMO A -- an off-by-one in the critical rank k.
    # -------------------------------------------------------------------
    rank_red <- nzchar(Sys.getenv("EML_RANK_RED", unset = ""))
    needleA <- "            .low = .sortedDiffs#[.k]"
    hitA <- which(inf_src == needleA)
    check_true(V, "red demo A's seed site (the exact lower bound) exists, exactly once",
               length(hitA) == 1)
    if (length(hitA) == 1) {
        mutA_dir <- file.path(work, "mutantA"); dir.create(mutA_dir, showWarnings = FALSE)
        mutA <- file.path(mutA_dir, "eml-inferential.praat")
        writeLines(append(inf_src, "            .k = .k + 1", after = hitA - 1), mutA)

        fxA <- fixtures$ts_small_a          # small, untied -> the exact branch
        lvlA <- levels_[["bonf6_05"]]
        linesA <- c(prelude(ANA, mutA), "",
            sprintf("x# = %s", vec_lit(fxA$x)),
            sprintf("y# = %s", vec_lit(fxA$y)),
            sprintf("@emlHodgesLehmannTwoSample: x#, y#, %.17g", lvlA),
            'appendInfoLine: "REDA ", fixed$ (emlHodgesLehmannTwoSample.low, 12), " ", fixed$ (emlHodgesLehmannTwoSample.high, 12), " [", emlHodgesLehmannTwoSample.method$, "]"')
        probeA <- file.path(work, "v145-redA.praat")
        writeLines(c('writeInfoLine: "v145 redA"', linesA), probeA)
        outA <- drive(probeA)
        ranA <- !any(grepl("^Error", outA))
        check_true(V, "[red A] the mutant probe ran", ranA)
        if (ranA) {
            mA <- regmatches(grep("^REDA ", outA, value = TRUE), regexec(
                "^REDA (\\S+) (\\S+) \\[([^]]*)\\]$",
                grep("^REDA ", outA, value = TRUE)))
            check_true(V, "[red A] the mutant printed a bound pair",
                       length(mA) == 1 && length(mA[[1]]) == 4)
            if (length(mA) == 1 && length(mA[[1]]) == 4) {
                mutLo <- num(mA[[1]][2]); mutHi <- num(mA[[1]][3])
                wA <- suppressWarnings(wilcox.test(fxA$x, fxA$y, conf.int = TRUE,
                                                   conf.level = lvlA))
                # The off-by-one bounds, computed in R from the same
                # sorted differences and the same qwilcox rank.
                diffsA <- sort(outer(fxA$x, fxA$y, "-"))
                nn <- length(fxA$x) * length(fxA$y)
                quA <- qwilcox((1 - lvlA) / 2, length(fxA$x), length(fxA$y))
                if (quA == 0) quA <- 1
                offLo <- diffsA[quA + 1]; offHi <- diffsA[nn - quA]
                if (rank_red) {
                    cat("      EML_RANK_RED: asserting the off-by-one mutant's lower bound\n")
                    cat("      equals the correct oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED A] mutant lower bound vs correct wilcox.test bound (must go red)",
                          mutLo, wA$conf.int[1], tol = 1e-8)
                } else {
                    check(V, "[red A] mutant lower bound DIFFERS from the correct wilcox.test bound",
                          mutLo, wA$conf.int[1], tol = 1e-8, expect = "differ")
                    check(V, "[red A] mutant upper bound DIFFERS from the correct wilcox.test bound",
                          mutHi, wA$conf.int[2], tol = 1e-8, expect = "differ")
                    check(V, "[red A] mutant lower bound is exactly the rank-k+1 order statistic -- the defect, named",
                          mutLo, offLo, tol = 1e-8)
                    check(V, "[red A] mutant upper bound is exactly the mirrored rank-k+1 order statistic",
                          mutHi, offHi, tol = 1e-8)
                    check_true(V, "[red A] and it still looks like a perfectly reasonable interval -- narrower, centred, ordered",
                               mutLo < mutHi &&
                               (mutHi - mutLo) < (wA$conf.int[2] - wA$conf.int[1]))
                }
            }
        } else {
            cat("      v145 red-demo-A probe output:\n      ",
                paste(utils::tail(outA, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO B -- a Bonferroni interval at 1 - alpha, not 1 - alpha/m.
    # -------------------------------------------------------------------
    alpha_red <- nzchar(Sys.getenv("EML_ALPHA_RED", unset = ""))
    ana_src <- readLines(ANA, warn = FALSE)
    needleB <- "        .hlLevel = 1 - .alpha / emlPairwiseWilcoxon.nPairs"
    hitB <- which(ana_src == needleB)
    check_true(V, "red demo B's seed site (the Wilcoxon level formula) exists, exactly once",
               length(hitB) == 1)
    if (length(hitB) == 1) {
        mutB_dir <- file.path(work, "mutantB"); dir.create(mutB_dir, showWarnings = FALSE)
        mutB <- file.path(mutB_dir, "eml-analysis.praat")
        srcB <- ana_src
        srcB[hitB] <- "        .hlLevel = 1 - .alpha"
        writeLines(srcB, mutB)

        runB <- list(fixture = "w_small", adj = "bonferroni", alpha = 0.05, tag = "redB")
        probeB <- build_probe(list(runB), mutB, INF, "redB")
        outB <- drive(probeB)
        ranB <- !any(grepl("^Error", outB))
        check_true(V, "[red B] the mutant probe ran", ranB)
        if (ranB) {
            gotB <- parse_cells(outB)
            cellB <- gotB[[paste("redB", 1)]]
            check_true(V, "[red B] the mutant probe printed a cell", !is.null(cellB))
            if (!is.null(cellB)) {
                gi <- wire_fx$w_small$A; gj <- wire_fx$w_small$B
                corrected <- oracle_pair(wire_fx$w_small, pair_idx[[1]], 0.05)
                plain <- suppressWarnings(wilcox.test(gi, gj, conf.int = TRUE,
                                                      conf.level = 1 - 0.05))$conf.int
                if (alpha_red) {
                    cat("      EML_ALPHA_RED: asserting the mutant's interval equals the\n")
                    cat("      m-corrected oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED B] mutant interval vs 1 - alpha/m oracle (must go red)",
                          cellB$lo, corrected$lo, tol = 1e-8)
                } else {
                    check(V, "[red B] mutant interval DIFFERS from the 1 - alpha/m oracle",
                          cellB$lo, corrected$lo, tol = 1e-8, expect = "differ")
                    check(V, "[red B] mutant interval instead matches the plain 1 - alpha oracle",
                          cellB$lo, plain[1], tol = 1e-8)
                    check_true(V, "[red B] the mutant interval is NARROWER than the correct one",
                               (cellB$hi - cellB$lo) < (corrected$hi - corrected$lo))
                    check(V, "[red B] and the point estimate is untouched -- only the interval moved",
                          cellB$est, corrected$est, tol = 1e-8)
                }
            }
        } else {
            cat("      v145 red-demo-B probe output:\n      ",
                paste(utils::tail(outB, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO C -- a Holm row printing an interval.
    # -------------------------------------------------------------------
    holm_red <- nzchar(Sys.getenv("EML_HOLM_RED", unset = ""))
    needleC <- '                    if .hlError$ = "" and (.adjMethod$ = "bonferroni")'
    hitC <- which(ana_src == needleC)
    check_true(V, "red demo C's seed site (the Wilcoxon interval guard) exists, exactly once",
               length(hitC) == 1)
    if (length(hitC) == 1) {
        mutC_dir <- file.path(work, "mutantC"); dir.create(mutC_dir, showWarnings = FALSE)
        mutC <- file.path(mutC_dir, "eml-analysis.praat")
        srcC <- ana_src
        srcC[hitC] <- paste0('                    if .hlError$ = "" and ',
                             '(.adjMethod$ = "bonferroni" or .adjMethod$ = "holm")')
        writeLines(srcC, mutC)

        runC <- list(fixture = "w_small", adj = "holm", alpha = 0.05, tag = "redC")
        probeC <- build_probe(list(runC), mutC, INF, "redC")
        outC <- drive(probeC)
        ranC <- !any(grepl("^Error", outC))
        check_true(V, "[red C] the mutant probe ran", ranC)
        if (ranC) {
            gotC <- parse_cells(outC)
            cellC <- gotC[[paste("redC", 1)]]
            # There is no wrong NUMBER for this defect: Holm defines no
            # interval level at all, so an interval appearing under Holm is
            # the whole defect, whatever value it holds. The battery's Holm
            # canary established that the SHIPPED code leaves it undefined.
            if (holm_red) {
                cat("      EML_HOLM_RED: asserting the mutant leaves a Holm row's\n")
                cat("      interval undefined, as correct code must -- EXPECTED to FAIL.\n")
                check_true(V, "[RED C] mutant Holm row's interval is undefined (must go red)",
                           !is.null(cellC) && is.na(cellC$lo) && is.na(cellC$hi))
            } else {
                check_true(V, "[red C] the mutant DEFINES an interval for a Holm row -- the defect, reproduced on demand",
                           !is.null(cellC) && is.finite(cellC$lo) && is.finite(cellC$hi))
            }
        } else {
            cat("      v145 red-demo-C probe output:\n      ",
                paste(utils::tail(outC, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # THE REFUSAL PATHS, direct. Every one must set .error$, leave every
    # numeric output undefined, and COMPLETE -- the probe finishing inside
    # the timeout is half the evidence, as it is in v144's hang guard.
    # -------------------------------------------------------------------
    guard_lines <- c(prelude(ANA, INF), "",
        "e# = zero# (0)",
        "g# = {1, 2, 3}",
        '@emlHodgesLehmannTwoSample: e#, g#, 0.95',
        'appendInfoLine: "GUARD empty1 ", emlHodgesLehmannTwoSample.estimate, " ", emlHodgesLehmannTwoSample.low, " [", emlHodgesLehmannTwoSample.error$, "]"',
        '@emlHodgesLehmannTwoSample: g#, e#, 0.95',
        'appendInfoLine: "GUARD empty2 ", emlHodgesLehmannTwoSample.estimate, " ", emlHodgesLehmannTwoSample.low, " [", emlHodgesLehmannTwoSample.error$, "]"',
        '@emlHodgesLehmannTwoSample: g#, g#, 1',
        'appendInfoLine: "GUARD level1 ", emlHodgesLehmannTwoSample.estimate, " ", emlHodgesLehmannTwoSample.low, " [", emlHodgesLehmannTwoSample.error$, "]"',
        "t1# = {4, 4, 4, 4, 4}",
        "t2# = {4, 4, 4, 4, 4, 4}",
        '@emlHodgesLehmannTwoSample: t1#, t2#, 0.95',
        'appendInfoLine: "GUARD alltied ", fixed$ (emlHodgesLehmannTwoSample.estimate, 6), " ", emlHodgesLehmannTwoSample.low, " [", emlHodgesLehmannTwoSample.error$, "]"')
    guard_path <- file.path(work, "v145-guard.praat")
    writeLines(c('writeInfoLine: "v145 guard"', guard_lines), guard_path)
    outG <- drive(guard_path)
    ranG <- !any(grepl("^Error", outG))
    check_true(V, "the refusal probe ran (completed -- did not hang) with no Praat error", ranG)
    if (ranG) {
        one <- function(tag) grep(paste0("^GUARD ", tag, " "), outG, value = TRUE)
        for (tag in c("empty1", "empty2", "level1")) {
            ln <- one(tag)
            check_true(V, sprintf("[%s] refused: .error$ set, estimate and low undefined", tag),
                       length(ln) == 1 &&
                       grepl("--undefined-- --undefined--", ln, fixed = TRUE) &&
                       !grepl("[]", ln, fixed = TRUE))
        }
        # All-tied is the one refusal that still HAS an estimate: the
        # median cross-difference of two constant samples is a number,
        # and it is only the interval that cannot be built. R warns and
        # then errors on this input; the plugin refuses the interval and
        # keeps the estimate.
        lnT <- one("alltied")
        check_true(V, "[alltied] the interval is refused with a reason",
                   length(lnT) == 1 && grepl("--undefined--", lnT, fixed = TRUE) &&
                   !grepl("[]", lnT, fixed = TRUE))
        # Praat's fixed$ is a MINIMUM-significance formatter, so an exact
        # zero comes back as a bare "0" however many decimals were asked
        # for (the reason this tree has @eml_fixed at all). The token is
        # read as a number rather than matched as text.
        estT <- if (length(lnT) == 1)
            num(strsplit(trimws(lnT), " +")[[1]][3]) else NA_real_
        check(V, "[alltied] but the estimate survives -- it is a defined median (0)",
              estT, 0, tol = 1e-12)
    } else {
        cat("      v145 refusal probe output:\n      ",
            paste(utils::tail(outG, 20), collapse = "\n      "), "\n", sep = "")
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v145 @emlHodgesLehmannTwoSample and the 3.8 wiring")
    eml_exit()
}
