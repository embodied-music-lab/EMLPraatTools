#!/usr/bin/env Rscript
# ============================================================================
# v163 -- the Hodges-Lehmann paired disclosure: pinned end to end
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. RULING_HL_FIX_WIRED_2026-09-04 item 3, verbatim: "A
# driven check pins the disclosure: request an unachievable confidence
# level on the paired path, expect the warning and the ACHIEVED level in
# report and CSV; the silent case is the red demo. Oracle leg: R's
# behaviour at the same request." The delegation itself -- commit
# "Wire the Hodges-Lehmann paired confidence interval's normal-
# approximation branch to the corrected Wilcoxon interval module" -- gave
# @emlHodgesLehmannPaired (plugin_EML_StatsGraphs/stats/eml-inferential.
# praat) two new outputs, .achievedLevel and .warning$, fed from
# @emlWilcoxonIntervalApprox (eml-wilcoxon-interval.praat). This file
# pins that the two outputs actually reach a caller of the WRAPPER, not
# just the module v158 already measured directly.
#
# THE NAMED FIXTURE, AND WHY PART 1 DOES NOT DRIVE IT AS GIVEN. The
# task's fixture -- n = 3 paired, x = {-0.626, 0.184, -0.836},
# y = {-0.446, 0.3, -0.777}, level 0.999 -- is v158's own PR_widen_root
# case, measured there by calling @emlWilcoxonIntervalApprox directly,
# which has no exact/approximation branch of its own to choose (its own
# header: "does NOT decide exact vs. approximation"). @emlHodgesLehmannPaired
# does have that gate ("exact iff n_nonzero < 50 AND no ties AND no zero
# differences"), and this triple has three distinct, non-zero absolute
# differences -- MEASURED below in PART 0, not assumed -- so the real
# wrapper takes the EXACT branch on it and never reaches the delegation
# item 3 is about. PART 1 therefore drives a second, tied fixture built
# by construction from the same two differences (0.18 and 0.059, one of
# them repeated) so the wrapper's own gate lands on "normal
# approximation" the way the ruling's request needs -- and R's achieved
# level for THAT fixture is re-derived fresh in PART 1 rather than
# assumed to be the module's 0.488 (measured: it also comes to 0.488,
# by coincidence of the numbers chosen, not by construction).
#
# STANDARD RULE: relative 1e-9, absolute 1e-12 near zero, i.e. a check
# passes when |reported - computed| <= max(1e-12, 1e-9 * |computed|).
#
# THE RED DEMO (PART 2). A copy of eml-inferential.praat is written to a
# scratch file with the two lines that copy .achievedLevel and .warning$
# off @emlWilcoxonIntervalApprox stubbed to no-ops -- the delegation
# call and the bounds it returns are untouched, so .low/.high stay
# correct and .method$ stays "normal approximation"; only the disclosure
# is silenced, which is exactly the defect item 3 exists to catch. In
# normal mode the check asserts the mutant DIFFERS from the real
# disclosure (passes today, proving this file would catch the
# regression); set EML_HLDISCLOSE_RED=1 to flip the same comparison to
# "the mutant discloses too" and watch it go red naming the missing
# warning, the v145/v158 convention (EML_*_RED).
#
# THE END-TO-END LEG (PART 3) drives the shipped
# @emlRunFriedmanAnalysis -> @emlRMPostHoc -> @emlDeclareFriedmanPostHoc
# chain -- the repeated-measures nonparametric post-hoc door, exactly as
# the menu item runs it -- on a fixture whose first pair is the same tied
# differences PART 1 uses, at the Bonferroni-corrected level for three
# pairs (1 - 0.05/3), which R also cannot achieve for that pair (achieved
# 0.4667, re-derived below). @emlRMPostHoc calls @emlHodgesLehmannPaired
# per pair but reads only .error$, .estimate, .method$, .low and .high
# off it (confirmed by inspection of eml-analysis.praat's PostHoc loop,
# 2026-09-05) -- .warning$ and .achievedLevel are computed and simply
# never picked up, so neither the printed report nor the post-hoc
# tidy CSV (<base>_posthoc_tidy.csv) can say anything about them today.
# THIS LEG IS THEREFORE WRITTEN TO FAIL, ON PURPOSE, UNTIL A CALLER-SIDE
# WAVE OTHER THAN THIS ONE CARRIES .warning$ AND .achievedLevel FROM
# @emlHodgesLehmannPaired INTO THAT REPORT AND THAT CSV; it goes green
# the day that wiring lands, and not before -- eml-analysis.praat is
# held by another wave and is not touched here. The column name
# ("warning") and the report phrasing this leg searches for are the
# existing repeated-measures-caution vocabulary (@emlDeclareRMResult's
# own glance "warning" column and the "Caution: " print site), not a
# frozen new API -- the wiring wave may reasonably choose different
# spellings, in which case this leg's search strings are what need
# updating alongside it.
#
# HOW TO RUN
#
#     Rscript validate/v163_hl_paired_disclosure.R
#
# Requires a Praat at or above the plugin's floor (6.6.30); skips (not
# fails) below it, the v144-v158 convention.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v163"

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
    cat(paste0("      SKIP: v163 needs Praat >= 6.6.30 to drive the procedure;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v163")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    dir.create(file.path(work, "out"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    INF <- file.path(plug, "stats", "eml-inferential.praat")
    ANA <- file.path(plug, "stats", "eml-analysis.praat")

    prelude <- function(inferential_file, analysis_file = NULL) {
        base <- c(
            paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
            paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
            paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
            paste0("include ", file.path(plug, "stats", "eml-output.praat")),
            paste0("include ", file.path(plug, "stats", "eml-wilcoxon-interval.praat")),
            paste0("include ", inferential_file))
        if (is.null(analysis_file)) return(base)
        c(base,
          paste0("include ", file.path(plug, "stats", "eml-result-writer.praat")),
          paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
          paste0("include ", file.path(plug, "graphs", "eml-annotation-procedures.praat")),
          paste0("include ", analysis_file))
    }

    drive <- function(probe_path, secs = "120") {
        suppressWarnings(system2("timeout",
            c(secs, "env", "-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
            stdout = TRUE, stderr = TRUE))
    }

    vec_lit <- function(v) paste0("{", paste(sprintf("%.17g", v), collapse = ", "), "}")
    num <- function(s) if (identical(s, "--undefined--")) NA_real_ else as.numeric(s)

    # -------------------------------------------------------------------
    # THE TWO FIXTURES.
    #
    #   fxT -- the task's named triple, driven in PART 0 to MEASURE which
    #          branch the real wrapper takes on it (see file header).
    #   fxA -- built from the same pair of absolute differences (0.18,
    #          repeated, and 0.059) that make fxT's own diffs, so the
    #          numbers are the same shape and origin, with one tie added
    #          so @emlHodgesLehmannPaired's own exact/approximation gate
    #          lands on approximation. This is the fixture PARTS 1-3
    #          actually drive.
    # -------------------------------------------------------------------
    fxT_x <- c(-0.626, 0.184, -0.836)
    fxT_y <- c(-0.446, 0.300, -0.777)

    fxA_y <- c(-0.446, 0.300, -0.777, 0.500)
    fxA_x <- fxA_y + c(-0.18, -0.18, -0.059, 0.059)
    levelA <- 0.999

    oracleA <- suppressWarnings(wilcox.test(fxA_x, fxA_y, paired = TRUE,
                                            conf.int = TRUE, conf.level = levelA))
    achievedA <- unname(attr(oracleA$conf.int, "conf.level"))
    loA <- unname(oracleA$conf.int[1]); hiA <- unname(oracleA$conf.int[2])
    dA <- fxA_x - fxA_y
    allWA <- outer(dA, dA, `+`) / 2
    estA <- median(allWA[!lower.tri(allWA)])

    cat(sprintf("      v163 R oracle (re-derived, not assumed): achieved conf.level = %.10g at requested %.3f\n",
                achievedA, levelA))
    cat(sprintf("      v163 R oracle: conf.int = [%.10g, %.10g], estimate = %.10g\n",
                loA, hiA, estA))

    # -------------------------------------------------------------------
    # PART 0 -- MEASURE, DON'T ASSUME, WHICH BRANCH THE WRAPPER TAKES ON
    # THE NAMED TRIPLE. fxT's three differences (-0.180, -0.116, -0.059)
    # are pairwise distinct in absolute value and none is zero, so
    # @emlHodgesLehmannPaired's own gate (n_nonzero < 50, no ties, no
    # zero diffs) says EXACT -- a fact this drives and checks rather than
    # states from reading the source.
    # -------------------------------------------------------------------
    part0 <- c(prelude(INF), "",
        sprintf("x# = %s", vec_lit(fxT_x)),
        sprintf("y# = %s", vec_lit(fxT_y)),
        sprintf("@emlHodgesLehmannPaired: x#, y#, %.17g", 0.999),
        'appendInfoLine: "PART0 method=[", emlHodgesLehmannPaired.method$, "]"')
    part0_probe <- file.path(work, "v163-part0.praat")
    writeLines(c('writeInfoLine: "v163 part0"', part0), part0_probe)
    out0 <- drive(part0_probe)
    ran0 <- !any(grepl("^Error", out0))
    check_true(V, "[part 0] the named-triple probe ran", ran0)
    if (ran0) {
        m0 <- regmatches(grep("^PART0 ", out0, value = TRUE),
                         regexec("^PART0 method=\\[([^]]*)\\]$",
                                 grep("^PART0 ", out0, value = TRUE)))
        meth0 <- if (length(m0) == 1 && length(m0[[1]]) == 2) m0[[1]][2] else NA_character_
        check_true(V,
            "[part 0] MEASURED: the named triple (no ties, no zero diffs, n<50) takes the EXACT branch through the real wrapper, not approximation -- which is why PART 1 drives a tied companion fixture instead",
            identical(meth0, "exact"))
    } else {
        cat("      v163 part0 probe output:\n      ",
            paste(utils::tail(out0, 20), collapse = "\n      "), "\n", sep = "")
    }

    # -------------------------------------------------------------------
    # PART 1 -- THE DRIVEN LEG: @emlHodgesLehmannPaired at fxA/levelA,
    # against the REAL, delegated eml-inferential.praat.
    # -------------------------------------------------------------------
    part1 <- c(prelude(INF), "",
        sprintf("x# = %s", vec_lit(fxA_x)),
        sprintf("y# = %s", vec_lit(fxA_y)),
        sprintf("@emlHodgesLehmannPaired: x#, y#, %.17g", levelA),
        'appendInfoLine: "PART1 low=", fixed$ (emlHodgesLehmannPaired.low, 12),',
        '... " high=", fixed$ (emlHodgesLehmannPaired.high, 12),',
        '... " achieved=", fixed$ (emlHodgesLehmannPaired.achievedLevel, 12),',
        '... " method=[", emlHodgesLehmannPaired.method$, "]",',
        '... " warn=[", emlHodgesLehmannPaired.warning$, "]"')
    part1_probe <- file.path(work, "v163-part1.praat")
    writeLines(c('writeInfoLine: "v163 part1"', part1), part1_probe)
    out1 <- drive(part1_probe)
    ran1 <- !any(grepl("^Error", out1))
    check_true(V, "[part 1] the driven probe ran with no Praat error", ran1)
    r1 <- NULL
    if (ran1) {
        ln1 <- grep("^PART1 ", out1, value = TRUE)
        m1 <- regmatches(ln1, regexec(
            "^PART1 low=(\\S+) high=(\\S+) achieved=(\\S+) method=\\[([^]]*)\\] warn=\\[([^]]*)\\]$",
            ln1))
        if (length(m1) == 1 && length(m1[[1]]) == 6) {
            r1 <- list(low = num(m1[[1]][2]), high = num(m1[[1]][3]),
                       achieved = num(m1[[1]][4]), method = m1[[1]][5],
                       warn = m1[[1]][6])
        }
        check_true(V, "[part 1] a PART1 result line was printed and parsed", !is.null(r1))
        if (!is.null(r1)) {
            check_true(V, "[part 1] .method$ is still \"normal approximation\" on the delegated branch",
                       identical(r1$method, "normal approximation"))
            check_true(V, "[part 1] .warning$ is non-empty -- the disclosure item 3 wires",
                       nchar(r1$warn) > 0)
            check(V, "[part 1] .achievedLevel vs R's re-derived achieved conf.level",
                  r1$achieved, achievedA, tol = std_tol(achievedA))
            check(V, "[part 1] .low vs R's conf.int[1]",
                  r1$low, loA, tol = std_tol(loA))
            check(V, "[part 1] .high vs R's conf.int[2]",
                  r1$high, hiA, tol = std_tol(hiA))
        }
    } else {
        cat("      v163 part1 probe output:\n      ",
            paste(utils::tail(out1, 20), collapse = "\n      "), "\n", sep = "")
    }

    # -------------------------------------------------------------------
    # PART 2 -- THE RED DEMO. A scratch copy of eml-inferential.praat
    # with the two disclosure-copying lines stubbed out. .low/.high and
    # .method$ are untouched -- only .achievedLevel and .warning$ go
    # silent, which is the exact silent failure item 3 names.
    # -------------------------------------------------------------------
    inf_src <- readLines(INF)
    needleAchieved <- "                .achievedLevel = emlWilcoxonIntervalApprox.achievedLevel"
    needleWarning  <- "                .warning$ = emlWilcoxonIntervalApprox.warning$"
    hitAchieved <- which(inf_src == needleAchieved)
    hitWarning  <- which(inf_src == needleWarning)
    check_true(V, "[red demo] the disclosure seed site (.achievedLevel copy) exists, exactly once",
               length(hitAchieved) == 1)
    check_true(V, "[red demo] the disclosure seed site (.warning$ copy) exists, exactly once",
               length(hitWarning) == 1)

    if (length(hitAchieved) == 1 && length(hitWarning) == 1) {
        mutDir <- file.path(work, "mutant"); dir.create(mutDir, showWarnings = FALSE)
        mutInf <- file.path(mutDir, "eml-inferential.praat")
        mutSrc <- inf_src
        mutSrc[hitAchieved] <- "                ; red-demo stub: .achievedLevel disclosure suppressed"
        mutSrc[hitWarning]  <- "                ; red-demo stub: .warning$ disclosure suppressed"
        writeLines(mutSrc, mutInf)

        part2 <- c(prelude(mutInf), "",
            sprintf("x# = %s", vec_lit(fxA_x)),
            sprintf("y# = %s", vec_lit(fxA_y)),
            sprintf("@emlHodgesLehmannPaired: x#, y#, %.17g", levelA),
            'appendInfoLine: "PART2 low=", fixed$ (emlHodgesLehmannPaired.low, 12),',
            '... " high=", fixed$ (emlHodgesLehmannPaired.high, 12),',
            '... " achieved=", fixed$ (emlHodgesLehmannPaired.achievedLevel, 12),',
            '... " method=[", emlHodgesLehmannPaired.method$, "]",',
            '... " warn=[", emlHodgesLehmannPaired.warning$, "]"')
        part2_probe <- file.path(work, "v163-part2-mutant.praat")
        writeLines(c('writeInfoLine: "v163 part2 mutant"', part2), part2_probe)
        out2 <- drive(part2_probe)
        ran2 <- !any(grepl("^Error", out2))
        check_true(V, "[red demo] the silenced-mutant probe ran", ran2)
        if (ran2) {
            ln2 <- grep("^PART2 ", out2, value = TRUE)
            m2 <- regmatches(ln2, regexec(
                "^PART2 low=(\\S+) high=(\\S+) achieved=(\\S+) method=\\[([^]]*)\\] warn=\\[([^]]*)\\]$",
                ln2))
            r2 <- if (length(m2) == 1 && length(m2[[1]]) == 6)
                list(low = num(m2[[1]][2]), high = num(m2[[1]][3]),
                     achieved = num(m2[[1]][4]), method = m2[[1]][5],
                     warn = m2[[1]][6]) else NULL
            check_true(V, "[red demo] a PART2 result line was printed and parsed", !is.null(r2))
            if (!is.null(r2)) {
                # The mutant still computes the RIGHT bounds and branch --
                # only the disclosure is gone. Stated as its own check so a
                # reviewer sees the mutation is narrow and the numbers
                # themselves are not what is being pinned here. Checked
                # against the R oracle directly (not against PART 1's
                # parsed result) so this does not depend on PART 1 having
                # succeeded.
                check(V, "[red demo] the mutant's bounds are UNCHANGED -- only the disclosure is silenced",
                      r2$low, loA, tol = std_tol(loA))

                redFlag <- nzchar(Sys.getenv("EML_HLDISCLOSE_RED", unset = ""))
                if (redFlag) {
                    cat("      EML_HLDISCLOSE_RED: asserting the silenced mutant DISCLOSES\n")
                    cat("      the achieved level and warning anyway -- EXPECTED to FAIL.\n")
                    check_true(V, "[RED] mutant discloses .warning$ despite the stub (must go red)",
                               nchar(r2$warn) > 0)
                    check(V, "[RED] mutant's .achievedLevel matches R's achieved level despite the stub (must go red)",
                          r2$achieved, achievedA, tol = std_tol(achievedA))
                } else {
                    check_true(V, "[red demo] the silenced mutant's .warning$ IS empty -- the silent case, reproduced",
                               nchar(r2$warn) == 0)
                    check_true(V, "[red demo] and its .achievedLevel wrongly equals the REQUESTED level, not R's achieved one",
                               abs(r2$achieved - levelA) < 1e-9)
                    check_true(V, "[red demo] i.e. the mutant's disclosure DIFFERS from the correct, R-agreeing one PART 1 measured on the real wrapper -- this file would have caught the regression",
                               nchar(r2$warn) == 0 && abs(r2$achieved - achievedA) > 1e-9)
                }
            }
        } else {
            cat("      v163 part2 mutant probe output:\n      ",
                paste(utils::tail(out2, 20), collapse = "\n      "), "\n", sep = "")
        }
    }

    # -------------------------------------------------------------------
    # PART 3 -- THE END-TO-END LEG, WRITTEN AND EXPECTED RED (see file
    # header). @emlRunFriedmanAnalysis's post-hoc pairwise HL interval on
    # pair c1-c2 hits the same tied, unachievable-at-0.999-shaped request
    # PARTS 1-2 use, at the Bonferroni level for three pairs
    # (1 - 0.05/3); R's achieved level for that pair is re-derived below,
    # not assumed. GOES GREEN THE DAY eml-analysis.praat's
    # @emlRMPostHoc/@emlDeclareFriedmanPostHoc CARRY .warning$ AND
    # .achievedLevel FROM @emlHodgesLehmannPaired INTO THE PRINTED
    # REPORT AND THE POST-HOC TIDY CSV -- that wiring is held by another
    # wave and is not touched here.
    # -------------------------------------------------------------------
    rmAlpha <- 0.05
    rmPairs <- 3
    levelRM <- 1 - rmAlpha / rmPairs
    oracleRM <- suppressWarnings(wilcox.test(fxA_x, fxA_y, paired = TRUE,
                                             conf.int = TRUE, conf.level = levelRM))
    achievedRM <- unname(attr(oracleRM$conf.int, "conf.level"))
    cat(sprintf("      v163 PART 3 R oracle (re-derived): pair c1-c2 achieves conf.level = %.10g at Bonferroni level %.10g (m=%d)\n",
                achievedRM, levelRM, rmPairs))

    # c3 is filler, distinct from c1 and c2, so the omnibus test and the
    # OTHER two pairs are well-defined; only the c1-c2 pair's disclosure
    # is asserted on.
    rmTable <- data.frame(s = 1:4,
                          c1 = fxA_x[1:4], c2 = fxA_y[1:4],
                          c3 = c(0.0, 0.5, -0.2, 0.8))

    setCells <- unlist(lapply(seq_len(nrow(rmTable)), function(i)
        vapply(c("s", "c1", "c2", "c3"), function(col) sprintf(
            '    Set numeric value: %d, "%s", %.17g', i, col, rmTable[i, col]),
            character(1))))

    part3 <- c(prelude(INF, ANA), "",
        'Create Table with column names: "v163e2e", 4, "s c1 c2 c3"',
        '    tid = selected ("Table")',
        setCells,
        '    clearinfo',
        sprintf('    emlAlpha = %.17g', rmAlpha),
        '    @emlRunFriedmanAnalysis: tid, "s", "c1|c2|c3", 1, "bonferroni"',
        '    rep$ = info$ ()',
        sprintf('    @emlExportResultFiles: "%s", "v163e2e"', file.path(work, "out")),
        '    writeInfoLine: "v163 part3 resumed"',
        '    appendInfoLine: "REPORT|BEGIN|"',
        '    appendInfo: rep$',
        '    appendInfoLine: "REPORT|END|"')
    part3_probe <- file.path(work, "v163-part3.praat")
    writeLines(c('writeInfoLine: "v163 part3"', part3), part3_probe)
    out3 <- drive(part3_probe)
    ran3 <- !any(grepl("^Error", out3))
    check_true(V, "[part 3, PENDING on eml-analysis.praat's caller wiring] the end-to-end Friedman post-hoc probe ran",
               ran3)
    if (!ran3) {
        cat("      v163 part3 probe output:\n      ",
            paste(utils::tail(out3, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        b <- grep("^REPORT\\|BEGIN\\|$", out3)
        e <- grep("^REPORT\\|END\\|$", out3)
        report3 <- if (length(b) && length(e) && e[1] > b[1])
            paste(out3[(b[1] + 1):(e[1] - 1)], collapse = "\n") else NA_character_

        csv3 <- file.path(work, "out", "v163e2e_posthoc_tidy.csv")
        pt <- if (file.exists(csv3))
            read.csv(csv3, stringsAsFactors = FALSE, check.names = FALSE) else NULL
        rowIdx <- if (!is.null(pt) && "contrast" %in% names(pt))
            match("c1-c2", pt$contrast) else NA_integer_
        csvWarn <- if (!is.null(pt) && "warning" %in% names(pt) && !is.na(rowIdx))
            pt$warning[rowIdx] else NA_character_

        # -- CSV half ---------------------------------------------------
        check_true(V,
            "[part 3, PENDING] the post-hoc tidy CSV discloses the achieved level for pair c1-c2 (a non-empty \"warning\" cell) -- goes green when eml-analysis.praat's PostHoc loop reads .warning$/.achievedLevel off @emlHodgesLehmannPaired",
            !is.na(csvWarn) && nzchar(csvWarn))

        # -- Report half --------------------------------------------------
        reportDiscloses <- !is.na(report3) &&
            grepl("achiev", report3, ignore.case = TRUE) &&
            grepl("c1", report3, fixed = TRUE)
        check_true(V,
            "[part 3, PENDING] the printed report discloses the achieved level for pair c1-c2 -- goes green when the same wiring lands",
            reportDiscloses)

        # -- Both, and the same sentence -- only meaningful once BOTH
        # exist; guarded exactly as v71's identical-sentence check is,
        # so this does not double-count the two failures above as a
        # third one while the wiring is still absent.
        if (!is.na(csvWarn) && nzchar(csvWarn) && reportDiscloses) {
            check_true(V,
                "[part 3, PENDING] and the CSV cell is the SAME sentence the report prints for pair c1-c2",
                grepl(csvWarn, report3, fixed = TRUE))
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v163 Hodges-Lehmann paired disclosure: driven, red-demoed, and pinned end to end")
    eml_exit()
}
