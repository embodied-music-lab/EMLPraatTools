# ============================================================================
# v145 — the Hodges-Lehmann shift and its interval, two-sample and paired
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. docs/WORK_ORDER_INTERVALS_2026-08-26.md builds this one
# file to cover items 3 AND 4, and both halves are now written.
#
# Item 3 adds @emlHodgesLehmannTwoSample (plugin/stats/eml-inferential.praat)
# and wires the pairwise-Wilcoxon orchestrator (@emlPairwiseWilcoxon /
# @emlReportPairwiseComparison, plugin/stats/eml-analysis.praat). Item 4 adds
# @emlHodgesLehmannPaired -- the median of the n(n+1)/2 Walsh averages, the
# T+ subset-sum DP for the exact critical rank, and the ONE-SAMPLE form of
# the same ported inversion -- and wires BOTH branches of @emlRMPostHoc: the
# paired-t branch through @emlTTestInterval at df = n - 1, and the
# signed-rank branch through @emlHodgesLehmannPaired. Every arm computes, on
# every row:
#
#   * the point estimate -- a mean difference on a t arm, a Hodges-Lehmann
#     shift on a rank arm -- every row, every correction;
#   * the interval, ONLY when the correction in force defines one --
#     Bonferroni at .level = 1 - alpha/m per pair; Holm and BH define none.
#
# As with item 2 (v144), docs/RULING_INTERVALS_2026-08-26.md's "Language"
# section gates the strings that would PRINT these on Ian's en-bloc
# approval. The shipped code therefore computes every quantity and stores it
# as an output -- @emlReportPairwiseComparison's .hlEstFlat#, .hlLowFlat#,
# .hlHighFlat#, .hlMethod$[], and @emlRMPostHoc's .meanDiffFlat#, .lowFlat#,
# .highFlat#, .hlEstFlat#, .hlLowFlat#, .hlHighFlat#, .hlMethod$[] -- and no
# appendInfoLine in either procedure reads any of them. This file verifies
# both halves: the numbers are right, and they are dark.
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
# THE PAIRED ORACLE is the same function with paired = TRUE, and the
# paired-t branch is oracled against t.test(paired = TRUE,
# conf.level = 1 - alpha/m). Its exact rank comes from qsignrank, which is
# NOT qwilcox with different counts: qsignrank multiplies each count by
# f = exp(-n * M_LN2) where qwilcox divides by choose(m+n, n), and its
# approximation branch has an alpha-doubling loop where the two-sample one
# has endpoint early-returns. PART 3 asserts both differences rather than
# assuming the two forms mirror each other.
#
# WHICH R THE PORT IS FROM: the 4.3.3 TAG, not trunk. Trunk's wilcox.test.R
# defaults digits.rank to 7L where 4.3.3 defaults it to Inf, which would
# signif() the ranks and disagree with the installed oracle.
#
# ---------------------------------------------------------------------------
# THE BATTERY -- ALL FOUR CELLS THE WORK ORDER NAMES
# ---------------------------------------------------------------------------
# The order asks for {two-sample, paired} x {exact, approximation}, in the
# three shapes that force the branches: small untied, tied, large-n. PARTS 1
# and 2 are the two-sample half; PART 3 is the paired half, which adds a
# fourth shape the two-sample gate has no clause for -- ZERO differences,
# which push a small untied sample onto the approximation branch on their own.
#
# Each half is driven twice over, because the branch and the wiring are
# separate claims:
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
#   D, E, F. THE SAME THREE, RE-AIMED AT THE PAIRED HALF, as the work order
#      requires: an off-by-one in the PAIRED critical rank k (the T+
#      distribution, not the U one; EML_PRANK_RED=1); a repeated-measures
#      interval at 1 - alpha instead of 1 - alpha/m, which is ONE line and
#      moves BOTH branches because @emlRMPostHoc builds the level once and
#      hands it to the paired t and to the Hodges-Lehmann alike
#      (EML_PALPHA_RED=1); and a Holm row on the repeated-measures post-hoc
#      defining an interval Holm has no level for (EML_PHOLM_RED=1).
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
    # PART 3 -- THE PAIRED HALF (work order item 4).
    #
    # @emlHodgesLehmannPaired is the one-sample form of PART 1's
    # procedure and NOT a re-parameterisation of it. Three things
    # separate them, and each produces a plausible wrong number:
    #
    #   * THE SET. The estimate is the median of the n(n+1)/2 WALSH
    #     AVERAGES (d[i] + d[j])/2 for i <= j -- including i = j -- of
    #     the within-subject differences, not of n1*n2 cross-differences
    #     between two samples.
    #   * THE NULL DISTRIBUTION. The exact critical rank is a quantile of
    #     the T+ subset-sum distribution in @eml_wilcoxonExactP, read off
    #     the same DP the exact signed-rank p-value comes from, and R
    #     inverts it with qsignrank -- which MULTIPLIES each count by
    #     f = exp(-n * M_LN2) where qwilcox DIVIDES by choose(m+n, n).
    #     Those are different roundings; PART 3b settles the rank as a
    #     quantity against R rather than inferring it from the bounds.
    #   * THE APPROXIMATION BRANCH'S SHAPE. R's one-sample root() has no
    #     endpoint early-returns; in their place it WIDENS alpha by
    #     doubling until the interval is bracketable, and returns
    #     median(x) twice if alpha reaches 1. The two-sample form has the
    #     early returns and no doubling loop. Reusing the two-sample
    #     root() here would substitute one structure for the other and
    #     still return an interval.
    #
    # What IS shared, and is asserted to be shared, is Brent's zeroin:
    # @eml_hlZeroin exists once, takes a .form switch where R's C takes a
    # function pointer, and both branches iterate through it.
    #
    # THE ORACLE for the interval is wilcox.test(x, y, paired = TRUE,
    # conf.int = TRUE, conf.level = 1 - alpha/m). The estimate is oracled
    # against median of the Walsh averages, for PART 1's reason: on the
    # exact branch R's own $estimate IS that median (asserted below), and
    # on the approximation branch R's $estimate is a root of W with the
    # continuity correction switched off, while Fable's order pins the
    # plugin's estimate to the median on BOTH branches.
    # -------------------------------------------------------------------
    inf_src <- readLines(INF, warn = FALSE)

    # -- PART 3.0: the PAIRED gate is one text, in two places -----------
    #
    # The same claim PART 0 makes about the two-sample gate, about the
    # other one. The paired gate has a third clause the two-sample gate
    # does not (.nZero = 0), and it sits at a different indentation, so
    # the two windows cannot be confused for one another.
    PGATE_HEAD <- "            .useExact = 0"
    pgate_at <- which(inf_src == PGATE_HEAD)
    check_true(V,
        sprintf("the paired exact gate appears in exactly two procedures (%d found)",
                length(pgate_at)),
        length(pgate_at) == 2)
    if (length(pgate_at) == 2) {
        pwindow <- function(i) inf_src[(i - 5):(i + 7)]
        check_true(V,
            "the gate @emlHodgesLehmannPaired uses is character-for-character the gate @emlWilcoxonSignedRank uses, comment included",
            identical(pwindow(pgate_at[1]), pwindow(pgate_at[2])))
        pblk <- paste(pwindow(pgate_at[1]), collapse = "\n")
        check_true(V, "that shared gate is n_nonzero < 50, no ties, no zero differences, as three nested ifs",
            grepl("if .nNonzero < 50", pblk, fixed = TRUE) &&
            grepl("if .hasTies = 0", pblk, fixed = TRUE) &&
            grepl("if .nZero = 0", pblk, fixed = TRUE))
        powner <- function(i) {
            heads <- grep("^procedure ", inf_src[seq_len(i)])
            sub("^procedure ([A-Za-z_0-9]+).*$", "\\1", inf_src[max(heads)])
        }
        check_true(V, sprintf("the two copies live in @emlWilcoxonSignedRank and @emlHodgesLehmannPaired (found %s, %s)",
                              powner(pgate_at[1]), powner(pgate_at[2])),
                   identical(sort(c(powner(pgate_at[1]), powner(pgate_at[2]))),
                             c("emlHodgesLehmannPaired", "emlWilcoxonSignedRank")))
    }

    # -- PART 3.0b: zeroin was REUSED, not re-ported ---------------------
    #
    # Fable's item 4 says in terms: "THE ZEROIN PORT IS GENERAL ... REUSE,
    # do not re-port ... re-porting R's zeroin a second time would be the
    # clearest possible violation." A second copy of Brent's method would
    # be invisible behaviourally -- it would agree with the first on every
    # cell in this file until one of them was edited -- so it is asserted
    # as a text fact: the loop exists once, and both W's reach it.
    check_true(V, "Brent's zeroin exists exactly once in the tree (@eml_hlZeroin)",
               sum(grepl("^procedure eml_hlZeroin:", inf_src)) == 1 &&
               !any(grepl("^procedure eml_hlTwoSampleZeroin", inf_src)))
    check_true(V, "the one zeroin dispatches to BOTH W's -- two-sample and paired -- at R's single function-pointer site",
               any(grepl("@eml_hlTwoSampleW: .v1#, .v2#, .b, .correct", inf_src, fixed = TRUE)) &&
               any(grepl("@eml_hlPairedW: .v1#, .b, .correct", inf_src, fixed = TRUE)))
    check_true(V, "the acceptance test that decides zeroin's iterates appears exactly once",
               sum(grepl("0.75 * .cb * .q", inf_src, fixed = TRUE)) == 1)
    # And the paired procedure reaches it, rather than @eml_hlTwoSampleRoot
    # -- whose endpoint early-returns are the two-sample structure.
    hlp_at <- grep("^procedure emlHodgesLehmannPaired", inf_src)
    hlp_end <- if (length(hlp_at) == 1)
        hlp_at + which(inf_src[hlp_at:length(inf_src)] == "endproc")[1] - 1 else NA
    check_true(V, "@emlHodgesLehmannPaired calls @eml_hlZeroin directly and never @eml_hlTwoSampleRoot",
        !is.na(hlp_end) &&
        any(grepl("@eml_hlZeroin: 2,", inf_src[hlp_at:hlp_end], fixed = TRUE)) &&
        !any(grepl("eml_hlTwoSampleRoot", inf_src[hlp_at:hlp_end], fixed = TRUE)))

    # -- PART 3a: the procedure itself, both paired cells ----------------
    set.seed(3345)
    pfx <- list(
        # small, untied, no zeroes -> exact
        pr_small_a = list(x = c(5.1, 4.2, 6.3, 5.8, 7.1, 6.6, 4.4, 5.9),
                          y = c(3.2, 4.9, 2.8, 3.9, 5.5, 4.1, 3.3, 5.0),
                          branch = "exact"),
        pr_small_b = list(x = round(rnorm(11, 10, 2), 6),
                          y = round(rnorm(11, 8.5, 2), 6),
                          branch = "exact"),
        # ties among |differences| -> normal approximation, whatever the n
        pr_tied    = list(x = c(5, 4, 6, 5, 7, 4, 6, 8),
                          y = c(3, 5, 3, 4, 5, 4, 5, 6),
                          branch = "normal approximation"),
        # ZERO differences -> normal approximation by the third clause,
        # the one the two-sample gate does not have
        pr_zero    = list(x = c(5, 4, 6, 5, 7, 4, 6, 8, 9, 3),
                          y = c(5, 5, 3, 4, 5, 4, 5, 6, 9, 2),
                          branch = "normal approximation"),
        # large n, untied -> normal approximation by the n >= 50 gate
        pr_large   = list(x = round(rnorm(55, 10, 2), 6),
                          y = round(rnorm(55, 9, 2), 6),
                          branch = "normal approximation"),
        pr_tiedbig = list(x = sample(1:12, 52, TRUE),
                          y = sample(1:12, 52, TRUE),
                          branch = "normal approximation")
    )
    plevels <- c(plain95 = 0.95,
                 bonf3_05 = 1 - 0.05 / 3,
                 bonf3_01 = 1 - 0.01 / 3,
                 bonf6_05 = 1 - 0.05 / 6)

    walsh <- function(d) {
        m <- outer(d, d, `+`)
        sort(m[!lower.tri(m)]) / 2
    }

    pdirect <- c(prelude(ANA, INF), "",
        "procedure v145paired: .tag$, .a#, .b#, .lev",
        "    @emlHodgesLehmannPaired: .a#, .b#, .lev",
        "    .est$ = fixed$ (emlHodgesLehmannPaired.estimate, 12)",
        "    .lo$ = fixed$ (emlHodgesLehmannPaired.low, 12)",
        "    .hi$ = fixed$ (emlHodgesLehmannPaired.high, 12)",
        "    .hlm$ = emlHodgesLehmannPaired.method$",
        "    .err$ = emlHodgesLehmannPaired.error$",
        "    @emlWilcoxonSignedRank: .a#, .b#, 2",
        "    .wsm$ = emlWilcoxonSignedRank.method$",
        "    appendInfoLine: \"PAIRED \", .tag$, \" \", .est$, \" \", .lo$, \" \", .hi$,",
        "    ... \" [\", .hlm$, \"] [\", .wsm$, \"] [\", .err$, \"]\"",
        "endproc", "")
    for (fxTag in names(pfx)) {
        fx <- pfx[[fxTag]]
        pdirect <- c(pdirect,
            sprintf("x# = %s", vec_lit(fx$x)),
            sprintf("y# = %s", vec_lit(fx$y)))
        for (lvTag in names(plevels)) {
            pdirect <- c(pdirect,
                sprintf('@v145paired: "%s", x#, y#, %.17g',
                        paste(fxTag, lvTag, sep = "|"), plevels[[lvTag]]))
        }
    }
    pdirect_path <- file.path(work, "v145-paired.praat")
    writeLines(c('writeInfoLine: "v145 paired"', pdirect), pdirect_path)
    outP <- drive(pdirect_path)
    ranP <- !any(grepl("^Error", outP))
    check_true(V, "the paired direct-call probe ran with no Praat error", ranP)

    nPaired <- 0L
    if (ranP) {
        gotP <- list()
        for (ln in grep("^PAIRED ", outP, value = TRUE)) {
            m <- regmatches(ln, regexec(
                "^PAIRED (\\S+) (\\S+) (\\S+) (\\S+) \\[([^]]*)\\] \\[([^]]*)\\] \\[(.*)\\]$",
                ln))[[1]]
            if (length(m) == 8) {
                gotP[[m[2]]] <- list(est = num(m[3]), lo = num(m[4]), hi = num(m[5]),
                                     hlm = m[6], wsm = m[7], err = m[8])
            }
        }
        for (fxTag in names(pfx)) {
            fx <- pfx[[fxTag]]
            for (lvTag in names(plevels)) {
                key <- paste(fxTag, lvTag, sep = "|")
                cell <- gotP[[key]]
                check_true(V, sprintf("[%s] a paired cell was printed at all", key),
                           !is.null(cell))
                if (is.null(cell)) next
                lvl <- plevels[[lvTag]]
                w <- suppressWarnings(wilcox.test(fx$x, fx$y, paired = TRUE,
                                                  conf.int = TRUE, conf.level = lvl))
                wa <- walsh(fx$x - fx$y)

                check(V, sprintf("[%s] HL estimate vs median of the n(n+1)/2 Walsh averages", key),
                      cell$est, median(wa), tol = 1e-8)
                check(V, sprintf("[%s] paired interval low vs wilcox.test(paired = TRUE) conf.int", key),
                      cell$lo, w$conf.int[1], tol = 1e-8)
                check(V, sprintf("[%s] paired interval high vs wilcox.test(paired = TRUE) conf.int", key),
                      cell$hi, w$conf.int[2], tol = 1e-8)
                check_true(V, sprintf("[%s] .error$ is empty on a well-formed sample", key),
                           identical(cell$err, ""))

                rBranch <- if (grepl("exact", w$method)) "exact" else "normal approximation"
                check_true(V, sprintf("[%s] .method$ is the branch the fixture forces (%s)",
                                      key, fx$branch), identical(cell$hlm, fx$branch))
                check_true(V, sprintf("[%s] .method$ is the branch R's wilcox.test took (%s)",
                                      key, rBranch), identical(cell$hlm, rBranch))
                check_true(V, sprintf("[%s] the interval's branch is the p-value's branch (@emlWilcoxonSignedRank said '%s')",
                                      key, cell$wsm), identical(cell$hlm, cell$wsm))

                if (identical(rBranch, "exact")) {
                    check(V, sprintf("[%s] on the exact branch R's own $estimate is that same Walsh median", key),
                          as.numeric(w$estimate), median(wa), tol = 1e-9)
                }
                nPaired <- nPaired + 1L
            }
        }
        check(V, "paired direct cells checked (6 fixtures x 4 levels)", nPaired, 24, tol = 0)
        # THE SET IS THE WALSH SET, NOT THE CROSS-DIFFERENCE SET. On a
        # paired fixture both sets exist and both have a median; asserting
        # only against the right one leaves the wrong one untested, and
        # "median of some plausible set of differences" is exactly the
        # defect the work order warns about. So the alternative is
        # computed and shown to be a DIFFERENT number the plugin does not
        # report.
        fxW <- pfx$pr_small_a
        cellW <- gotP[[paste("pr_small_a", "plain95", sep = "|")]]
        if (!is.null(cellW)) {
            cross <- median(outer(fxW$x, fxW$y, "-"))
            check(V, "the paired estimate is NOT the median cross-difference -- the two-sample set is a different number here",
                  cellW$est, cross, tol = 1e-8, expect = "differ")
        }
        assert_dark("paired direct", outP)
    } else {
        cat("      v145 paired probe output:\n      ",
            paste(utils::tail(outP, 30), collapse = "\n      "), "\n", sep = "")
    }

    # -- PART 3b: the paired critical rank, against R's qsignrank --------
    #
    # PART 1b's claim, about the other distribution. qsignrank is NOT
    # qwilcox with different counts: its cumulative scan multiplies each
    # count by exp(-n * M_LN2) where qwilcox divides by choose(m+n, n),
    # and exp(-n * ln 2) is not the same double as 2^-n for most n. The
    # grid straddles R's "if (qu == 0) qu <- 1" bump, which is the one
    # step between a coverage-bearing interval and an off-by-one.
    set.seed(5145)
    prank_ns <- c(2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 40, 49)
    prank_alphas <- c(0.05, 0.01, 0.05 / 3, 0.01 / 3, 0.05 / 6, 0.001)
    prank_cases <- list()
    prlines <- c(prelude(ANA, INF), "",
        "procedure v145prank: .tag$, .a#, .b#, .lev",
        "    @emlHodgesLehmannPaired: .a#, .b#, .lev",
        "    appendInfoLine: \"PRANK \", .tag$, \" \", emlHodgesLehmannPaired.k,",
        "    ... \" [\", emlHodgesLehmannPaired.method$, \"]\"",
        "endproc", "")
    for (nn in prank_ns) {
        # Untied |differences| and no zero difference, by construction,
        # so every cell lands on the exact branch.
        d <- round(rnorm(nn, 1, 3), 8)
        while (anyDuplicated(abs(d)) || any(d == 0)) d <- round(rnorm(nn, 1, 3), 8)
        yv <- round(rnorm(nn, 0, 1), 8)
        xv <- yv + d
        prlines <- c(prlines, sprintf("x# = %s", vec_lit(xv)),
                              sprintf("y# = %s", vec_lit(yv)))
        for (al in prank_alphas) {
            tag <- sprintf("pn%d_a%s", nn, format(al, digits = 6))
            prank_cases[[tag]] <- list(n = nn, alpha = al)
            prlines <- c(prlines, sprintf('@v145prank: "%s", x#, y#, %.17g',
                                          tag, 1 - al))
        }
    }
    prank_path <- file.path(work, "v145-prank.praat")
    writeLines(c('writeInfoLine: "v145 prank"', prlines), prank_path)
    outPR <- drive(prank_path)
    ranPR <- !any(grepl("^Error", outPR))
    check_true(V, "the paired critical-rank probe ran with no Praat error", ranPR)
    if (ranPR) {
        gotPR <- list()
        for (ln in grep("^PRANK ", outPR, value = TRUE)) {
            m <- regmatches(ln, regexec("^PRANK (\\S+) (\\S+) \\[([^]]*)\\]$", ln))[[1]]
            if (length(m) == 4) gotPR[[m[2]]] <- list(k = num(m[3]), meth = m[4])
        }
        nPBump <- 0L
        for (tag in names(prank_cases)) {
            pc <- prank_cases[[tag]]
            cell <- gotPR[[tag]]
            check_true(V, sprintf("[prank %s] a rank was printed", tag), !is.null(cell))
            if (is.null(cell)) next
            check_true(V, sprintf("[prank %s] the cell is on the exact branch", tag),
                       identical(cell$meth, "exact"))
            qu <- qsignrank(pc$alpha / 2, pc$n)
            if (qu == 0) { qu <- 1; nPBump <- nPBump + 1L }
            check(V, sprintf("[prank %s] critical rank k vs R's qsignrank(alpha/2, n)", tag),
                  cell$k, qu, tol = 0)
        }
        check_true(V,
            sprintf("the paired grid actually straddles R's qu == 0 bump (%d cell(s) needed it)", nPBump),
            nPBump > 0L)
        # AND IT IS NOT QWILCOX. If the paired branch had been given the
        # two-sample inversion, most of these cells would still return a
        # number; this names at least one grid point where the two
        # distributions disagree, so "it matched qsignrank" is a claim
        # with content.
        crossed <- sum(vapply(names(prank_cases), function(tg) {
            pc <- prank_cases[[tg]]
            a <- qsignrank(pc$alpha / 2, pc$n); if (a == 0) a <- 1
            b <- qwilcox(pc$alpha / 2, pc$n, pc$n); if (b == 0) b <- 1
            as.integer(a != b)
        }, integer(1)))
        check_true(V,
            sprintf("qsignrank and qwilcox disagree on %d of the %d grid cells -- the oracle is discriminating",
                    crossed, length(prank_cases)),
            crossed > 0L)
        assert_dark("paired critical rank", outPR)
    } else {
        cat("      v145 paired rank probe output:\n      ",
            paste(utils::tail(outPR, 20), collapse = "\n      "), "\n", sep = "")
    }

    # -- PART 3b2: the alpha-WIDENING branch, which only the one-sample
    #    form has.
    #
    # R's one-sample asymptotic branch cannot always deliver the level it
    # was asked for, and when it cannot it does not refuse: it DOUBLES
    # alpha until the interval is bracketable, warns "requested conf.level
    # not achievable", and returns bounds at the wider level. On small
    # samples at a Bonferroni-corrected level this is the common case, not
    # the exotic one -- 2914 of 4000 randomly drawn n <= 8 integer
    # difference vectors at 1 - .05/3 came back widened when this was
    # measured. The two-sample form has no such loop, so a port that
    # reused the two-sample root() would return a DIFFERENT interval on
    # every one of those cells while still returning an interval.
    #
    # The cells below are selected BY THE ORACLE: R is asked first, and
    # only vectors where R's returned conf.level differs from the one
    # requested are kept. So this part cannot silently degenerate into
    # testing the ordinary path.
    set.seed(8145)
    widen_cases <- list()
    widenLevel <- 1 - 0.05 / 3
    tries <- 0
    while (length(widen_cases) < 30 && tries < 20000) {
        tries <- tries + 1
        nw <- sample(2:9, 1)
        dw <- sample(c(-2, -1, 0, 1, 2, 3), nw, TRUE)
        if (all(dw == 0)) next
        rw <- tryCatch(suppressWarnings(wilcox.test(dw, rep(0, nw), paired = TRUE,
                                                    conf.int = TRUE,
                                                    conf.level = widenLevel)),
                       error = function(e) NULL)
        if (is.null(rw)) next
        clw <- attr(rw$conf.int, "conf.level")
        if (is.na(clw) || clw <= 0) next
        if (abs(clw - widenLevel) < 1e-12) next
        if (!all(is.finite(rw$conf.int))) next
        widen_cases[[sprintf("wide%02d", length(widen_cases) + 1)]] <-
            list(d = dw, lo = rw$conf.int[1], hi = rw$conf.int[2], cl = clw)
    }
    check_true(V,
        sprintf("the oracle actually produced widened-level cells to test (%d found)",
                length(widen_cases)),
        length(widen_cases) >= 20)
    if (length(widen_cases) > 0) {
        wlines <- c(prelude(ANA, INF), "",
            "procedure v145widen: .tag$, .a#, .b#, .lev",
            "    @emlHodgesLehmannPaired: .a#, .b#, .lev",
            "    appendInfoLine: \"WIDE \", .tag$, \" \", fixed$ (emlHodgesLehmannPaired.low, 12),",
            "    ... \" \", fixed$ (emlHodgesLehmannPaired.high, 12),",
            "    ... \" [\", emlHodgesLehmannPaired.error$, \"]\"",
            "endproc", "")
        for (tg in names(widen_cases)) {
            wc <- widen_cases[[tg]]
            wlines <- c(wlines,
                sprintf("x# = %s", vec_lit(wc$d)),
                sprintf("y# = %s", vec_lit(rep(0, length(wc$d)))),
                sprintf('@v145widen: "%s", x#, y#, %.17g', tg, widenLevel))
        }
        widen_path <- file.path(work, "v145-widen.praat")
        writeLines(c('writeInfoLine: "v145 widen"', wlines), widen_path)
        outW <- drive(widen_path)
        ranW <- !any(grepl("^Error", outW))
        check_true(V, "the alpha-widening probe ran with no Praat error", ranW)
        if (ranW) {
            gotW <- list()
            for (ln in grep("^WIDE ", outW, value = TRUE)) {
                m <- regmatches(ln, regexec("^WIDE (\\S+) (\\S+) (\\S+) \\[(.*)\\]$", ln))[[1]]
                if (length(m) == 5) gotW[[m[2]]] <- list(lo = num(m[3]), hi = num(m[4]),
                                                         err = m[5])
            }
            nWide <- 0L
            for (tg in names(widen_cases)) {
                wc <- widen_cases[[tg]]
                cell <- gotW[[tg]]
                check_true(V, sprintf("[%s] a widened cell was printed", tg), !is.null(cell))
                if (is.null(cell)) next
                check(V, sprintf("[%s] widened lower bound vs wilcox.test's own widened bound (requested %.6f, R achieved %.6f)",
                                 tg, widenLevel, wc$cl),
                      cell$lo, wc$lo, tol = 1e-8)
                check(V, sprintf("[%s] widened upper bound vs wilcox.test's own widened bound", tg),
                      cell$hi, wc$hi, tol = 1e-8)
                nWide <- nWide + 1L
            }
            check_true(V, sprintf("every widened cell was checked (%d)", nWide),
                       nWide == length(widen_cases))
            assert_dark("alpha widening", outW)
        } else {
            cat("      v145 widening probe output:\n      ",
                paste(utils::tail(outW, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -- PART 3c: the 3.7 wiring, BOTH branches of @emlRMPostHoc ---------
    #
    # Fable's order wires the paired-t branch to @emlTTestInterval with
    # df = n - 1 and the signed-rank branch to @emlHodgesLehmannPaired.
    # The two branches are reached through the two repeated-measures
    # doors -- @emlRunRepeatedMeasuresAnalysis for the parametric one and
    # @emlRunFriedmanAnalysis for the nonparametric one -- and both are
    # driven here, exactly as the menu items run them.
    #
    # NO WELCH/STUDENT SPLIT EXISTS ON A PAIRED BRANCH and mathematically
    # none can: Welch reconciles unequal variances across two INDEPENDENT
    # samples, and a paired test works on the differences, which is one
    # sample with one variance. The order says so to keep one from being
    # built; the code says so at the site; and this file asserts the
    # sentence is still there, because a comment is the only thing
    # standing between the between-subjects arm's genuine split and a
    # fabricated copy of it here.
    rm_pairs <- list(c(1, 2), c(1, 3), c(2, 3))
    rmPairs <- length(rm_pairs)
    CLAB <- c("c1", "c2", "c3")

    set.seed(6145)
    rm_fx <- list(
        r_cont = data.frame(c1 = round(rnorm(9, 10, 2), 6),
                            c2 = round(rnorm(9, 12, 2), 6),
                            c3 = round(rnorm(9, 9, 2), 6)),
        r_tied = data.frame(c1 = sample(1:8, 12, TRUE),
                            c2 = sample(1:8, 12, TRUE),
                            c3 = sample(1:8, 12, TRUE)),
        r_big  = data.frame(c1 = round(rnorm(52, 10, 2), 6),
                            c2 = round(rnorm(52, 11, 2), 6),
                            c3 = round(rnorm(52, 9, 2), 6)),
        # r_zeroeff: all three pairs share the SAME raw n (16), but a
        # different number of exact zero differences per pair -- the
        # paired cache (.cacheN[]) is keyed on the effective n after
        # zero-difference removal, and Fable's pin asks for at least
        # three distinct effective n's forced by ties within one run.
        # pair(c1,c2): 0 zero diffs  -> effective n 16
        # pair(c1,c3): 4 zero diffs  -> effective n 12
        # pair(c2,c3): 7 zero diffs  -> effective n  9
        r_zeroeff = local({
            n <- 16
            z1 <- round(rnorm(n, 10, 2), 6)
            z2 <- round(rnorm(n, 12, 2), 6)
            while (any(z1 == z2)) z2 <- round(rnorm(n, 12, 2), 6)
            z3 <- numeric(n)
            z3[1:4]  <- z1[1:4]
            z3[5:11] <- z2[5:11]
            rest <- round(rnorm(5, 9, 2), 6)
            while (any(rest %in% z1[12:16]) || any(rest %in% z2[12:16]))
                rest <- round(rnorm(5, 9, 2), 6)
            z3[12:16] <- rest
            data.frame(c1 = z1, c2 = z2, c3 = z3)
        })
    )
    rm_alphas <- c(a05 = 0.05, a01 = 0.01)

    build_rm_fixture <- function(tag, df) {
        c(sprintf('procedure buildrm%s', tag),
          sprintf('  .id = Create Table with column names: "%s", %d, "c1 c2 c3"',
                  tag, nrow(df)),
          unlist(lapply(seq_len(nrow(df)), function(i)
              vapply(1:3, function(j) sprintf(
                  '  Set string value: %d, "c%d", "%s"', i, j,
                  sprintf("%.17g", df[i, j])), character(1)))),
          sprintf('  %s_id = .id', tag),
          "endproc")
    }

    rm_emit <- function(tag) c(
        sprintf("for .p from 1 to %d", rmPairs),
        sprintf('  appendInfoLine: "RMCELL %s ", .p, " ", fixed$ (emlRMPostHoc.meanDiffFlat# [.p], 12), " ", fixed$ (emlRMPostHoc.lowFlat# [.p], 12), " ", fixed$ (emlRMPostHoc.highFlat# [.p], 12), " ", fixed$ (emlRMPostHoc.hlEstFlat# [.p], 12), " ", fixed$ (emlRMPostHoc.hlLowFlat# [.p], 12), " ", fixed$ (emlRMPostHoc.hlHighFlat# [.p], 12), " [", emlRMPostHoc.hlMethod$ [.p], "]"',
                tag),
        "endfor")

    build_rm_probe <- function(runs, analysis_file, inferential_file, name) {
        lines <- c(prelude(analysis_file, inferential_file), "",
                   unlist(lapply(names(rm_fx), function(tg)
                       build_rm_fixture(tg, rm_fx[[tg]]))),
                   sprintf("@buildrm%s", names(rm_fx)), "")
        for (r in runs) {
            lines <- c(lines, sprintf("emlAlpha = %.17g", r$alpha))
            if (identical(r$arm, "parametric")) {
                lines <- c(lines, sprintf(
                    '@emlRunRepeatedMeasuresAnalysis: %s_id, "s", "c1|c2|c3", 1, "%s"',
                    r$fixture, r$adj))
            } else {
                lines <- c(lines, sprintf(
                    '@emlRunFriedmanAnalysis: %s_id, "s", "c1|c2|c3", 1, "%s"',
                    r$fixture, r$adj))
            }
            lines <- c(lines, rm_emit(r$tag))
        }
        probe_path <- file.path(work, paste0("v145-", name, ".praat"))
        writeLines(c('writeInfoLine: "v145 rm"', lines), probe_path)
        probe_path
    }

    parse_rm <- function(out) {
        got <- list()
        for (ln in grep("^RMCELL ", out, value = TRUE)) {
            m <- regmatches(ln, regexec(
                paste0("^RMCELL (\\S+) (\\d+) (\\S+) (\\S+) (\\S+) (\\S+) (\\S+) (\\S+)",
                       " \\[([^]]*)\\]$"), ln))[[1]]
            if (length(m) == 10) {
                got[[paste(m[2], m[3])]] <- list(
                    md = num(m[4]), lo = num(m[5]), hi = num(m[6]),
                    he = num(m[7]), hlo = num(m[8]), hhi = num(m[9]), meth = m[10])
            }
        }
        got
    }

    rm_runs <- list()
    for (fxTag in names(rm_fx)) {
        for (aTag in names(rm_alphas)) {
            for (arm in c("parametric", "nonparametric")) {
                rm_runs[[length(rm_runs) + 1]] <- list(
                    fixture = fxTag, arm = arm, adj = "bonferroni",
                    alpha = rm_alphas[[aTag]],
                    tag = paste(fxTag, aTag, substr(arm, 1, 4), sep = "_"))
            }
        }
    }
    rmHolmT <- "r_cont_holm_para"
    rmHolmW <- "r_cont_holm_nonp"
    rmBhW   <- "r_cont_bh_nonp"
    rm_runs[[length(rm_runs) + 1]] <- list(fixture = "r_cont", arm = "parametric",
        adj = "holm", alpha = 0.05, tag = rmHolmT)
    rm_runs[[length(rm_runs) + 1]] <- list(fixture = "r_cont", arm = "nonparametric",
        adj = "holm", alpha = 0.05, tag = rmHolmW)
    rm_runs[[length(rm_runs) + 1]] <- list(fixture = "r_cont", arm = "nonparametric",
        adj = "bh", alpha = 0.05, tag = rmBhW)

    rm_probe <- build_rm_probe(rm_runs, ANA, INF, "rmbattery")
    outRM <- drive(rm_probe, secs = "600")
    ranRM <- !any(grepl("^Error", outRM))
    check_true(V, "the repeated-measures wiring probe ran with no Praat error", ranRM)
    if (!ranRM) {
        cat("      v145 RM probe output:\n      ",
            paste(utils::tail(outRM, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        gotRM <- parse_rm(outRM)
        nRMt <- 0L; nRMw <- 0L
        for (r in rm_runs) {
            if (r$tag %in% c(rmHolmT, rmHolmW, rmBhW)) next
            df <- rm_fx[[r$fixture]]
            lvl <- 1 - r$alpha / rmPairs
            for (k in seq_len(rmPairs)) {
                p <- rm_pairs[[k]]
                xv <- df[[CLAB[p[1]]]]; yv <- df[[CLAB[p[2]]]]
                cell <- gotRM[[paste(r$tag, k)]]
                check_true(V, sprintf("[%s pair %d] an RM cell was printed at all", r$tag, k),
                           !is.null(cell))
                if (is.null(cell)) next
                if (identical(r$arm, "parametric")) {
                    tt <- t.test(xv, yv, paired = TRUE, conf.level = lvl)
                    check(V, sprintf("[%s pair %d] mean difference vs t.test(paired = TRUE) estimate", r$tag, k),
                          cell$md, as.numeric(tt$estimate), tol = 1e-8)
                    check(V, sprintf("[%s pair %d] paired-t interval low vs t.test at 1 - alpha/m", r$tag, k),
                          cell$lo, tt$conf.int[1], tol = 1e-8)
                    check(V, sprintf("[%s pair %d] paired-t interval high vs t.test at 1 - alpha/m", r$tag, k),
                          cell$hi, tt$conf.int[2], tol = 1e-8)
                    # THE DF IS n - 1, and nothing else. A Welch-shaped df
                    # would be fractional and would move both bounds; the
                    # interval width is read back as the quantity that
                    # carries it.
                    halfW <- (tt$conf.int[2] - tt$conf.int[1]) / 2
                    seP <- as.numeric(tt$estimate) / as.numeric(tt$statistic)
                    check(V, sprintf("[%s pair %d] the half-width is |qt| at df = n - 1 times the paired SE", r$tag, k),
                          halfW, abs(qt((1 - lvl) / 2, length(xv) - 1)) * seP, tol = 1e-8)
                    check_true(V, sprintf("[%s pair %d] the Hodges-Lehmann arrays are undefined on a parametric run", r$tag, k),
                               is.na(cell$he) && is.na(cell$hlo) && is.na(cell$hhi) &&
                               identical(cell$meth, ""))
                    nRMt <- nRMt + 1L
                } else {
                    w <- suppressWarnings(wilcox.test(xv, yv, paired = TRUE,
                                                      conf.int = TRUE, conf.level = lvl))
                    check(V, sprintf("[%s pair %d] HL estimate vs median Walsh average", r$tag, k),
                          cell$he, median(walsh(xv - yv)), tol = 1e-8)
                    check(V, sprintf("[%s pair %d] paired HL interval low vs wilcox.test at 1 - alpha/m", r$tag, k),
                          cell$hlo, w$conf.int[1], tol = 1e-8)
                    check(V, sprintf("[%s pair %d] paired HL interval high vs wilcox.test at 1 - alpha/m", r$tag, k),
                          cell$hhi, w$conf.int[2], tol = 1e-8)
                    rb <- if (grepl("exact", w$method)) "exact" else "normal approximation"
                    check_true(V, sprintf("[%s pair %d] the branch recorded is R's branch (%s)", r$tag, k, rb),
                               identical(cell$meth, rb))
                    check_true(V, sprintf("[%s pair %d] the mean-difference arrays are undefined on a nonparametric run", r$tag, k),
                               is.na(cell$md) && is.na(cell$lo) && is.na(cell$hi))
                    nRMw <- nRMw + 1L
                }
            }
        }
        check(V, "paired-t wired cells checked (4 fixtures x 2 alphas x 3 pairs)", nRMt, 24, tol = 0)
        check(V, "signed-rank wired cells checked (4 fixtures x 2 alphas x 3 pairs)", nRMw, 24, tol = 0)

        # -- r_zeroeff: the raw n is one number (16); the effective n the
        # paired cache actually keys on is three, forced by the zero
        # differences built into the fixture above. A cache wrongly keyed
        # on raw n, or one that silently collapsed the three pairs onto a
        # single key, would not be caught by the identity checks above if
        # this assertion did not also confirm the keys really differ.
        zeroeff_df <- rm_fx$r_zeroeff
        rawN <- vapply(rm_pairs, function(p) nrow(zeroeff_df), integer(1))
        effN <- vapply(rm_pairs, function(p)
            sum(zeroeff_df[[CLAB[p[1]]]] != zeroeff_df[[CLAB[p[2]]]]), integer(1))
        check_true(V,
            "r_zeroeff: one raw n (16) across all three pairs, but three distinct effective n's from ties",
            all(rawN == 16) && length(unique(effN)) == 3)

        # -- the Holm and BH canaries, on BOTH branches ------------------
        for (k in seq_len(rmPairs)) {
            p <- rm_pairs[[k]]
            xv <- rm_fx$r_cont[[CLAB[p[1]]]]; yv <- rm_fx$r_cont[[CLAB[p[2]]]]
            cT <- gotRM[[paste(rmHolmT, k)]]
            check_true(V, sprintf("[holm paired-t pair %d] a cell was printed", k), !is.null(cT))
            if (!is.null(cT)) {
                check_true(V, sprintf("[holm paired-t pair %d] the mean difference IS computed", k),
                           is.finite(cT$md))
                check_true(V, sprintf("[holm paired-t pair %d] the interval is NOT computed", k),
                           is.na(cT$lo) && is.na(cT$hi))
                check(V, sprintf("[holm paired-t pair %d] and it is the same estimate Bonferroni reports", k),
                      cT$md, mean(xv - yv), tol = 1e-8)
            }
            for (cTag in c(holm = rmHolmW, bh = rmBhW)) {
                nm <- names(which(c(holm = rmHolmW, bh = rmBhW) == cTag))
                cW <- gotRM[[paste(cTag, k)]]
                check_true(V, sprintf("[%s signed-rank pair %d] a cell was printed", nm, k),
                           !is.null(cW))
                if (is.null(cW)) next
                check_true(V, sprintf("[%s signed-rank pair %d] the HL estimate IS computed", nm, k),
                           is.finite(cW$he))
                check_true(V, sprintf("[%s signed-rank pair %d] the interval is NOT computed", nm, k),
                           is.na(cW$hlo) && is.na(cW$hhi))
                check(V, sprintf("[%s signed-rank pair %d] that estimate is the correction-free Walsh median", nm, k),
                      cW$he, median(walsh(xv - yv)), tol = 1e-8)
            }
        }

        assert_dark("repeated-measures wiring", outRM)
    }

    # -- PART 3d: the sentence that stops a Welch/Student split ----------
    ana_src_p <- readLines(ANA, warn = FALSE)
    rmph_at <- grep("^procedure emlRMPostHoc:", ana_src_p)
    rmph_end <- if (length(rmph_at) == 1)
        rmph_at + which(ana_src_p[rmph_at:length(ana_src_p)] == "endproc")[1] - 1 else NA
    rmph_raw <- if (!is.na(rmph_end)) ana_src_p[rmph_at:rmph_end] else character(0)
    rmph_txt <- paste(rmph_raw, collapse = "\n")
    # The comment is read as PROSE, not as lines: strip the leading ";" or
    # "#" and the indentation and collapse the whitespace, so a sentence
    # that happens to wrap is still one sentence. Matching raw lines would
    # make this check fail on a re-wrap, which is the kind of red that
    # teaches people to delete checks.
    rmph_prose <- paste(sub("^\\s*[;#]\\s?", "", rmph_raw), collapse = " ")
    rmph_prose <- gsub("\\s+", " ", rmph_prose)
    check_true(V,
        "the paired-t interval site says why no Welch/Student split exists there -- unequal variances across two INDEPENDENT samples, versus one sample of differences with one variance",
        grepl("NO WELCH/STUDENT SPLIT EXISTS ON A PAIRED BRANCH", rmph_prose, fixed = TRUE) &&
        grepl("unequal variances across two INDEPENDENT samples", rmph_prose, fixed = TRUE) &&
        grepl("which is one sample with one variance", rmph_prose, fixed = TRUE))
    # And no split was in fact built: the only t-test @emlRMPostHoc runs is
    # the paired one, nothing in it reads a variance flag, and there is no
    # "welch"/"student" branch anywhere in the procedure's CODE. The
    # comment above is stripped out first so that saying the words does not
    # satisfy the check that no branch exists.
    rmph_code <- rmph_raw[!grepl("^\\s*[;#]", rmph_raw)]
    check_true(V,
        "and no Welch/Student branching was in fact built into @emlRMPostHoc",
        !any(grepl("welch|student|equalVariances", rmph_code, ignore.case = TRUE)) &&
        !any(grepl("@emlTTest:", rmph_code, fixed = TRUE)) &&
        sum(grepl("@emlTTestPaired:", rmph_code, fixed = TRUE)) == 1)
    check_true(V,
        "@emlRMPostHoc hands @emlTTestInterval the paired test's own df rather than recomputing one",
        any(grepl("@emlTTestInterval: .phDiff, .phT, .phDf, .phLevel", rmph_code, fixed = TRUE)) &&
        any(grepl(".phDf = emlTTestPaired.df", rmph_code, fixed = TRUE)))


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
    # RED DEMO D -- an off-by-one in the PAIRED critical rank k.
    # The mirror of red demo A, on the T+ distribution. One line,
    # ".k = .k + 1", is inserted after the "if (qu == 0) qu <- 1" bump and
    # before the Walsh bounds are taken.
    # -------------------------------------------------------------------
    prank_red <- nzchar(Sys.getenv("EML_PRANK_RED", unset = ""))
    needleD <- "                .low = .sortedWalsh#[.k]"
    hitD <- which(inf_src == needleD)
    check_true(V, "red demo D's seed site (the paired exact lower bound) exists, exactly once",
               length(hitD) == 1)
    if (length(hitD) == 1) {
        mutD_dir <- file.path(work, "mutantD"); dir.create(mutD_dir, showWarnings = FALSE)
        mutD <- file.path(mutD_dir, "eml-inferential.praat")
        writeLines(append(inf_src, "                .k = .k + 1", after = hitD - 1), mutD)

        fxD <- pfx$pr_small_a
        lvlD <- plevels[["bonf3_05"]]
        linesD <- c(prelude(ANA, mutD), "",
            sprintf("x# = %s", vec_lit(fxD$x)),
            sprintf("y# = %s", vec_lit(fxD$y)),
            sprintf("@emlHodgesLehmannPaired: x#, y#, %.17g", lvlD),
            'appendInfoLine: "REDD ", fixed$ (emlHodgesLehmannPaired.low, 12), " ", fixed$ (emlHodgesLehmannPaired.high, 12), " [", emlHodgesLehmannPaired.method$, "]"')
        probeD <- file.path(work, "v145-redD.praat")
        writeLines(c('writeInfoLine: "v145 redD"', linesD), probeD)
        outD2 <- drive(probeD)
        ranD2 <- !any(grepl("^Error", outD2))
        check_true(V, "[red D] the mutant probe ran", ranD2)
        if (ranD2) {
            mD <- regmatches(grep("^REDD ", outD2, value = TRUE), regexec(
                "^REDD (\\S+) (\\S+) \\[([^]]*)\\]$",
                grep("^REDD ", outD2, value = TRUE)))
            check_true(V, "[red D] the mutant printed a bound pair",
                       length(mD) == 1 && length(mD[[1]]) == 4)
            if (length(mD) == 1 && length(mD[[1]]) == 4) {
                mutLo <- num(mD[[1]][2]); mutHi <- num(mD[[1]][3])
                wD <- suppressWarnings(wilcox.test(fxD$x, fxD$y, paired = TRUE,
                                                   conf.int = TRUE, conf.level = lvlD))
                waD <- walsh(fxD$x - fxD$y)
                nnD <- length(waD)
                quD <- qsignrank((1 - lvlD) / 2, length(fxD$x))
                if (quD == 0) quD <- 1
                offLoD <- waD[quD + 1]; offHiD <- waD[nnD - quD]
                if (prank_red) {
                    cat("      EML_PRANK_RED: asserting the off-by-one paired mutant's lower\n")
                    cat("      bound equals the correct oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED D] mutant paired lower bound vs correct wilcox.test bound (must go red)",
                          mutLo, wD$conf.int[1], tol = 1e-8)
                } else {
                    check(V, "[red D] mutant paired lower bound DIFFERS from the correct wilcox.test bound",
                          mutLo, wD$conf.int[1], tol = 1e-8, expect = "differ")
                    check(V, "[red D] mutant paired upper bound DIFFERS from the correct wilcox.test bound",
                          mutHi, wD$conf.int[2], tol = 1e-8, expect = "differ")
                    check(V, "[red D] mutant lower bound is exactly the rank-k+1 Walsh order statistic -- the defect, named",
                          mutLo, offLoD, tol = 1e-8)
                    check(V, "[red D] mutant upper bound is exactly the mirrored rank-k+1 Walsh order statistic",
                          mutHi, offHiD, tol = 1e-8)
                    check_true(V, "[red D] and it still looks like a perfectly reasonable interval -- narrower, centred, ordered",
                               mutLo < mutHi &&
                               (mutHi - mutLo) < (wD$conf.int[2] - wD$conf.int[1]))
                }
            }
        } else {
            cat("      v145 red-demo-D probe output:\n      ",
                paste(utils::tail(outD2, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO E -- the repeated-measures interval at 1 - alpha.
    #
    # ONE line changed, and it moves BOTH branches: @emlRMPostHoc builds
    # .phLevel once and hands the same level to @emlTTestInterval and to
    # @emlHodgesLehmannPaired. That is the point of the mutation -- the
    # corrected level is a single fact about the family, and a defect in
    # it is a defect in every row of both arms at once.
    # -------------------------------------------------------------------
    palpha_red <- nzchar(Sys.getenv("EML_PALPHA_RED", unset = ""))
    needleE <- "    .phLevel = 1 - .phAlpha / .nPairs"
    hitE <- which(ana_src_p == needleE)
    check_true(V, "red demo E's seed site (the repeated-measures level formula) exists, exactly once",
               length(hitE) == 1)
    if (length(hitE) == 1) {
        mutE_dir <- file.path(work, "mutantE"); dir.create(mutE_dir, showWarnings = FALSE)
        mutE <- file.path(mutE_dir, "eml-analysis.praat")
        srcE <- ana_src_p
        srcE[hitE] <- "    .phLevel = 1 - .phAlpha"
        writeLines(srcE, mutE)

        runsE <- list(
            list(fixture = "r_cont", arm = "parametric", adj = "bonferroni",
                 alpha = 0.05, tag = "redEt"),
            list(fixture = "r_cont", arm = "nonparametric", adj = "bonferroni",
                 alpha = 0.05, tag = "redEw"))
        probeE <- build_rm_probe(runsE, mutE, INF, "redE")
        outE <- drive(probeE)
        ranE <- !any(grepl("^Error", outE))
        check_true(V, "[red E] the mutant probe ran", ranE)
        if (ranE) {
            gotE <- parse_rm(outE)
            xv <- rm_fx$r_cont$c1; yv <- rm_fx$r_cont$c2
            lvlC <- 1 - 0.05 / rmPairs
            ttC <- t.test(xv, yv, paired = TRUE, conf.level = lvlC)
            ttP <- t.test(xv, yv, paired = TRUE, conf.level = 0.95)
            wC <- suppressWarnings(wilcox.test(xv, yv, paired = TRUE, conf.int = TRUE,
                                               conf.level = lvlC))
            wP <- suppressWarnings(wilcox.test(xv, yv, paired = TRUE, conf.int = TRUE,
                                               conf.level = 0.95))
            cEt <- gotE[[paste("redEt", 1)]]; cEw <- gotE[[paste("redEw", 1)]]
            check_true(V, "[red E] the mutant probe printed a cell on both branches",
                       !is.null(cEt) && !is.null(cEw))
            if (!is.null(cEt) && !is.null(cEw)) {
                if (palpha_red) {
                    cat("      EML_PALPHA_RED: asserting the mutant's intervals equal the\n")
                    cat("      m-corrected oracles -- EXPECTED to FAIL.\n")
                    check(V, "[RED E] mutant paired-t interval vs 1 - alpha/m oracle (must go red)",
                          cEt$lo, ttC$conf.int[1], tol = 1e-8)
                    check(V, "[RED E] mutant HL interval vs 1 - alpha/m oracle (must go red)",
                          cEw$hlo, wC$conf.int[1], tol = 1e-8)
                } else {
                    check(V, "[red E] mutant paired-t interval DIFFERS from the 1 - alpha/m oracle",
                          cEt$lo, ttC$conf.int[1], tol = 1e-8, expect = "differ")
                    check(V, "[red E] mutant paired-t interval instead matches the plain 1 - alpha oracle",
                          cEt$lo, ttP$conf.int[1], tol = 1e-8)
                    check(V, "[red E] mutant HL interval DIFFERS from the 1 - alpha/m oracle",
                          cEw$hlo, wC$conf.int[1], tol = 1e-8, expect = "differ")
                    check(V, "[red E] mutant HL interval instead matches the plain 1 - alpha oracle",
                          cEw$hlo, wP$conf.int[1], tol = 1e-8)
                    check_true(V, "[red E] both mutant intervals are NARROWER than the correct ones -- one line, two arms",
                               (cEt$hi - cEt$lo) < (ttC$conf.int[2] - ttC$conf.int[1]) &&
                               (cEw$hhi - cEw$hlo) < (wC$conf.int[2] - wC$conf.int[1]))
                    check(V, "[red E] and the point estimates are untouched -- only the intervals moved",
                          cEt$md, as.numeric(ttC$estimate), tol = 1e-8)
                }
            }
        } else {
            cat("      v145 red-demo-E probe output:\n      ",
                paste(utils::tail(outE, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # RED DEMO F -- a Holm row on the repeated-measures post-hoc printing
    # an interval. The guard on the signed-rank branch is widened to admit
    # "holm" too; the paired-t branch's guard is the identical shape a few
    # lines above, and the Holm canaries above cover the shipped side of
    # both.
    # -------------------------------------------------------------------
    pholm_red <- nzchar(Sys.getenv("EML_PHOLM_RED", unset = ""))
    needleF <- '                if .hlErr$ = "" and .adjUsed$ = "bonferroni"'
    hitF <- which(ana_src_p == needleF)
    check_true(V, "red demo F's seed site (the repeated-measures HL interval guard) exists, exactly once",
               length(hitF) == 1)
    if (length(hitF) == 1) {
        mutF_dir <- file.path(work, "mutantF"); dir.create(mutF_dir, showWarnings = FALSE)
        mutF <- file.path(mutF_dir, "eml-analysis.praat")
        srcF <- ana_src_p
        srcF[hitF] <- paste0('                if .hlErr$ = "" and (.adjUsed$ = ',
                             '"bonferroni" or .adjUsed$ = "holm")')
        writeLines(srcF, mutF)

        runsF <- list(list(fixture = "r_cont", arm = "nonparametric", adj = "holm",
                           alpha = 0.05, tag = "redF"))
        probeF <- build_rm_probe(runsF, mutF, INF, "redF")
        outF <- drive(probeF)
        ranF <- !any(grepl("^Error", outF))
        check_true(V, "[red F] the mutant probe ran", ranF)
        if (ranF) {
            gotF <- parse_rm(outF)
            cellF <- gotF[[paste("redF", 1)]]
            if (pholm_red) {
                cat("      EML_PHOLM_RED: asserting the mutant leaves a Holm row's paired\n")
                cat("      interval undefined, as correct code must -- EXPECTED to FAIL.\n")
                check_true(V, "[RED F] mutant Holm row's paired interval is undefined (must go red)",
                           !is.null(cellF) && is.na(cellF$hlo) && is.na(cellF$hhi))
            } else {
                check_true(V, "[red F] the mutant DEFINES an interval for a Holm repeated-measures row -- the defect, reproduced on demand",
                           !is.null(cellF) && is.finite(cellF$hlo) && is.finite(cellF$hhi))
            }
        } else {
            cat("      v145 red-demo-F probe output:\n      ",
                paste(utils::tail(outF, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # THE PAIRED REFUSAL PATHS, direct. Same shape as the two-sample
    # refusals below: .error$ set, the numeric outputs undefined, and the
    # probe COMPLETING inside the timeout.
    # -------------------------------------------------------------------
    pguard_lines <- c(prelude(ANA, INF), "",
        "e# = zero# (0)",
        "g# = {1, 2, 3}",
        "h# = {1, 2, 3, 4}",
        '@emlHodgesLehmannPaired: g#, h#, 0.95',
        'appendInfoLine: "PGUARD length ", emlHodgesLehmannPaired.estimate, " ", emlHodgesLehmannPaired.low, " [", emlHodgesLehmannPaired.error$, "]"',
        '@emlHodgesLehmannPaired: e#, e#, 0.95',
        'appendInfoLine: "PGUARD empty ", emlHodgesLehmannPaired.estimate, " ", emlHodgesLehmannPaired.low, " [", emlHodgesLehmannPaired.error$, "]"',
        '@emlHodgesLehmannPaired: g#, g#, 1',
        'appendInfoLine: "PGUARD level1 ", emlHodgesLehmannPaired.estimate, " ", emlHodgesLehmannPaired.low, " [", emlHodgesLehmannPaired.error$, "]"',
        "z1# = {4, 5, 6, 7, 8}",
        '@emlHodgesLehmannPaired: z1#, z1#, 0.95',
        'appendInfoLine: "PGUARD allzero ", fixed$ (emlHodgesLehmannPaired.estimate, 6), " ", emlHodgesLehmannPaired.low, " [", emlHodgesLehmannPaired.error$, "]"',
        "t1# = {4, 5, 6, 7, 8}",
        "t2# = {2, 3, 4, 5, 6}",
        '@emlHodgesLehmannPaired: t1#, t2#, 0.95',
        'appendInfoLine: "PGUARD alltied ", fixed$ (emlHodgesLehmannPaired.estimate, 6), " ", emlHodgesLehmannPaired.low, " [", emlHodgesLehmannPaired.error$, "]"')
    pguard_path <- file.path(work, "v145-pguard.praat")
    writeLines(c('writeInfoLine: "v145 pguard"', pguard_lines), pguard_path)
    outPG <- drive(pguard_path)
    ranPG <- !any(grepl("^Error", outPG))
    check_true(V, "the paired refusal probe ran (completed -- did not hang) with no Praat error", ranPG)
    if (ranPG) {
        oneP <- function(tag) grep(paste0("^PGUARD ", tag, " "), outPG, value = TRUE)
        for (tag in c("length", "empty", "level1")) {
            ln <- oneP(tag)
            check_true(V, sprintf("[paired %s] refused: .error$ set, estimate and low undefined", tag),
                       length(ln) == 1 &&
                       grepl("--undefined-- --undefined--", ln, fixed = TRUE) &&
                       !grepl("[]", ln, fixed = TRUE))
        }
        # All-zero differences: the Walsh averages are all zero, so the
        # estimate is a defined 0 and only the interval is refused --
        # PART 1's all-tied case, in paired clothing.
        lnZ <- oneP("allzero")
        check_true(V, "[paired allzero] the interval is refused with a reason",
                   length(lnZ) == 1 && grepl("--undefined--", lnZ, fixed = TRUE) &&
                   !grepl("[]", lnZ, fixed = TRUE))
        estZ <- if (length(lnZ) == 1)
            num(strsplit(trimws(lnZ), " +")[[1]][3]) else NA_real_
        check(V, "[paired allzero] but the estimate survives -- it is a defined median (0)",
              estZ, 0, tol = 1e-12)
        # Every difference the SAME non-zero constant: SIGMA.CI is zero on
        # the approximation branch and R warns and returns NaN. The
        # estimate is that constant.
        lnT2 <- oneP("alltied")
        check_true(V, "[paired alltied] a constant difference refuses the interval and keeps the estimate",
                   length(lnT2) == 1 && grepl("--undefined--", lnT2, fixed = TRUE) &&
                   !grepl("[]", lnT2, fixed = TRUE))
        estT2 <- if (length(lnT2) == 1)
            num(strsplit(trimws(lnT2), " +")[[1]][3]) else NA_real_
        check(V, "[paired alltied] and that estimate is the constant difference (2)",
              estT2, 2, tol = 1e-12)
        assert_dark("paired refusals", outPG)
    } else {
        cat("      v145 paired refusal probe output:\n      ",
            paste(utils::tail(outPG, 20), collapse = "\n      "), "\n", sep = "")
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
    eml_report("v145 Hodges-Lehmann shift and interval, two-sample and paired")
    eml_exit()
}
