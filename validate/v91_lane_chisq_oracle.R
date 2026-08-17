# ===========================================================================
# v91 — chi-square independence + Cramér's V vs R chisq.test (survey lane)
# ===========================================================================
# Drives @emlChiSquareIndependence (plugin/stats/eml-categorical.praat)
# LIVE on the four committed contingency-table fixtures, with the
# continuity correction BOTH on and off, and settles the statistic, df,
# p, Cramér's V, the smallest expected count, the below-5 cell count and
# the warning behaviour against R's chisq.test computed in this run.
# Cramér's V is hand-computed here from the uncorrected statistic,
# sqrt(X2 / (n * (min(r, c) - 1))) — the DescTools definition — because
# CRAN is unreachable from the validation sandbox.
#
# Negative control: a scratch copy of the kernel with a seeded wrong
# Cramér's V denominator (min(r, c) for min(r, c) - 1) is driven on the
# 3x4 fixture, and the run asserts the defective V DIFFERS from the
# oracle. Set EML_LANE_RED=1 to watch the named agreement check go red.
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

if (!canDrive) {
    cat(paste0("      SKIP: v91 needs Praat >= 6.6.30 to drive the kernel;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true("v91",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v91")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    unlink(file.path(prefs, c("pid", "message")))
    tgt <- file.path(work, "stats")
    if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, "stats")), tgt)

    mat_literal <- function(m) {
        rows <- apply(m, 1, function(r)
            paste0("{", paste(format(r, digits = 17), collapse = ", "), "}"))
        paste0("{", paste(rows, collapse = ", "), "}")
    }

    drive_chisq <- function(stats_dir_rel, m, correction, tag) {
        probe <- file.path(work, "scripts", paste0("v91-", tag, ".praat"))
        writeLines(c(
            paste0("include ../", stats_dir_rel, "/eml-categorical.praat"),
            "",
            'writeInfoLine: "v91"',
            sprintf("t## = %s", mat_literal(m)),
            sprintf("@emlChiSquareIndependence: t##, %d", correction),
            'appendInfo: "res|", emlChiSquareIndependence.chiSq, "|",',
            '... emlChiSquareIndependence.df, "|",',
            '... emlChiSquareIndependence.p, "|",',
            '... emlChiSquareIndependence.cramersV, "|",',
            '... emlChiSquareIndependence.minExpected, "|",',
            '... emlChiSquareIndependence.nCellsBelow5, "|",',
            '... emlChiSquareIndependence.n',
            'appendInfoLine: ""',
            'appendInfoLine: "warn|", emlChiSquareIndependence.warning$',
            'appendInfoLine: "err|", emlChiSquareIndependence.error$'),
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
    str1 <- function(out, tag) {
        h <- grep(sprintf("^%s\\|", tag), out, value = TRUE)
        if (!length(h)) return(NA_character_)
        sub(sprintf("^%s\\|", tag), "", h[1])
    }

    fixtures <- list(
        balanced = as.matrix(read_input("lane_survey_chisq_2x2_balanced.csv")),
        sparse   = as.matrix(read_input("lane_survey_chisq_2x2_sparse.csv")),
        t3x4     = as.matrix(read_input("lane_survey_chisq_3x4.csv")),
        zerocell = as.matrix(read_input("lane_survey_chisq_zerocell.csv")))

    for (name in names(fixtures)) {
        m <- fixtures[[name]]
        for (corr in c(1L, 0L)) {
            tag <- sprintf("%s_c%d", name, corr)
            out <- drive_chisq("stats", m, corr, tag)
            ran <- !any(grepl("^Error", out)) && length(fld(out, "res")) >= 7
            check_true("v91", sprintf("the %s probe ran", tag), ran)
            if (!ran) {
                cat(sprintf("      v91 %s probe output: %s\n", tag,
                            paste(utils::tail(out, 8), collapse = " / ")))
                next
            }
            r <- suppressWarnings(chisq.test(m, correct = corr == 1))
            r0 <- suppressWarnings(chisq.test(m, correct = FALSE))
            vOracle <- sqrt(unname(r0$statistic) /
                            (sum(m) * (min(dim(m)) - 1)))
            check("v91", sprintf("[%s] chi-square statistic", tag),
                  num(out, "res", 1), unname(r$statistic), tol = 1e-10)
            check("v91", sprintf("[%s] df", tag),
                  num(out, "res", 2), unname(r$parameter), tol = 0)
            check("v91", sprintf("[%s] p-value", tag),
                  num(out, "res", 3), r$p.value, tol = 1e-10)
            check("v91", sprintf("[%s] Cramér's V (uncorrected base)", tag),
                  num(out, "res", 4), vOracle, tol = 1e-10)
            check("v91", sprintf("[%s] smallest expected count", tag),
                  num(out, "res", 5), min(r$expected), tol = 1e-10)
            check("v91", sprintf("[%s] cells with expected below 5", tag),
                  num(out, "res", 6), sum(r$expected < 5), tol = 0)
            wantWarn <- any(r$expected < 5)
            gotWarn <- nzchar(str1(out, "warn")) && !is.na(str1(out, "warn"))
            check_true("v91",
                       sprintf("[%s] warning fires exactly when an expected count is below 5", tag),
                       gotWarn == wantWarn)
        }
    }

    # 2x2 corrected differs from uncorrected on the same table — the
    # correction parameter is live, not decorative.
    out1 <- drive_chisq("stats", fixtures$balanced, 1L, "livecheck1")
    out0 <- drive_chisq("stats", fixtures$balanced, 0L, "livecheck0")
    check("v91", "correction parameter changes the 2x2 statistic",
          num(out1, "res", 1), num(out0, "res", 1), tol = 1e-10,
          expect = "differ")

    # Zero-margin refusal: R returns NaN here; the kernel must refuse
    # with a message instead of computing nonsense.
    zm <- matrix(c(5, 7, 0, 0), 2, 2)
    outz <- drive_chisq("stats", zm, 0L, "zeromargin")
    check_true("v91", "zero row/column margin is refused with a message",
               nzchar(str1(outz, "err")) && is.na(num(outz, "res", 1)))

    # -----------------------------------------------------------------------
    # NEGATIVE CONTROL — seeded wrong Cramér's V denominator
    # -----------------------------------------------------------------------
    mut <- file.path(work, "mutant")
    dir.create(mut, showWarnings = FALSE)
    src <- readLines(file.path(plug, "stats", "eml-categorical.praat"))
    needle <- "(.n * (.minDim - 1))"
    hit <- grepl(needle, src, fixed = TRUE)
    check_true("v91", "the negative-control seed site exists in source", sum(hit) == 1)
    mut_src <- sub(needle, "(.n * .minDim)", src, fixed = TRUE)
    writeLines(mut_src, file.path(mut, "eml-categorical.praat"))
    tgt2 <- file.path(work, "mutant_link")
    if (!file.exists(tgt2)) file.symlink(mut, tgt2)

    m34 <- fixtures$t3x4
    r0 <- suppressWarnings(chisq.test(m34, correct = FALSE))
    vOracle <- sqrt(unname(r0$statistic) / (sum(m34) * (min(dim(m34)) - 1)))
    out_mut <- drive_chisq("mutant_link", m34, 0L, "mutant")
    if (red_mode) {
        cat("      EML_LANE_RED: running the standard agreement check against\n")
        cat("      the defective build — the next check is EXPECTED to FAIL.\n")
        check("v91", "[RED] seeded-defect Cramér's V vs oracle (must go red)",
              num(out_mut, "res", 4), vOracle, tol = 1e-10)
    } else {
        check("v91", "seeded wrong-denominator Cramér's V DIFFERS from the oracle",
              num(out_mut, "res", 4), vOracle, tol = 1e-10, expect = "differ")
    }
}

if (!exists("EML_SUITE")) { eml_report("v91 chi-square + Cramér's V oracle"); eml_exit() }
