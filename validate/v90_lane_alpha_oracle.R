# ===========================================================================
# v90 — Cronbach's alpha kernel vs a BASE-R oracle (survey-stats lane)
# ===========================================================================
# Drives @emlCronbachAlpha (plugin/stats/eml-psychometrics.praat) LIVE on
# the four committed fixtures and settles alpha, the Feldt 95% CI, every
# alpha-if-deleted value, and the listwise-deletion disclosure against an
# oracle computed IN THIS RUN from base R alone: raw alpha from the
# covariance matrix (k/(k-1) * (1 - tr(C)/sum(C))), the Feldt (1965) CI
# from qf on (n-1, (n-1)(k-1)) df, and alpha-if-deleted from each
# leave-one-out covariance submatrix. Base R only — the suite's charter.
#
# SECOND OPINION, OPPORTUNISTIC (the v17/broom pattern): when the psych
# package happens to be installed, the base-R oracle is ADDITIONALLY
# asserted against psych::alpha at 1e-12 on every quantity, and the run
# says which mode it ran in. When psych is absent, the base-R oracle
# stands alone; nothing is skipped silently and nothing extra is required.
# (The port was cross-verified against psych 2.4.1 at exactly 0 difference
# on every fixture and on fresh-seed data, 17 Aug 2026.)
#
# Negative control: a scratch copy of the kernel with a seeded wrong
# variance denominator (n instead of n - 1) is driven on the clean
# fixture, and the run asserts the defective alpha DIFFERS from the
# oracle — proof the agreement checks are capable of failing. Set
# EML_LANE_RED=1 to instead run the standard agreement check against
# the defective build and watch it go red (exit status 1).
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

# ---------------------------------------------------------------------------
# 0. THE BINARY — same floor and the same refusal as the other driving files
# ---------------------------------------------------------------------------
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

havePsych <- requireNamespace("psych", quietly = TRUE)
cat(sprintf("      v90 oracle mode: base R%s\n",
            if (havePsych) " + psych cross-check" else
            " alone (psych not installed; cross-check not run)"))

if (!canDrive) {
    cat(paste0("      SKIP: v90 needs Praat >= 6.6.30 to drive the kernel;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true("v90",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    # -----------------------------------------------------------------------
    # 1. Sandbox: scratch outside the tree being measured
    # -----------------------------------------------------------------------
    work <- file.path(tempdir(), "v90")
    unlink(work, recursive = TRUE)
    dir.create(file.path(work, "scripts"), showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)
    unlink(file.path(prefs, c("pid", "message")))
    tgt <- file.path(work, "stats")
    if (!file.exists(tgt)) file.symlink(normalizePath(file.path(plug, "stats")), tgt)

    mat_literal <- function(m) {
        rows <- apply(m, 1, function(r) {
            cells <- ifelse(is.na(r), "undefined", format(r, digits = 17))
            paste0("{", paste(cells, collapse = ", "), "}")
        })
        paste0("{", paste(rows, collapse = ", "), "}")
    }

    drive_alpha <- function(stats_dir_rel, m, tag) {
        probe <- file.path(work, "scripts", paste0("v90-", tag, ".praat"))
        writeLines(c(
            paste0("include ../", stats_dir_rel, "/eml-psychometrics.praat"),
            "",
            'writeInfoLine: "v90"',
            sprintf("d## = %s", mat_literal(m)),
            "@emlCronbachAlpha: d##",
            'appendInfo: "res|", emlCronbachAlpha.alpha, "|",',
            '... emlCronbachAlpha.ci95low, "|", emlCronbachAlpha.ci95high, "|",',
            '... emlCronbachAlpha.k, "|", emlCronbachAlpha.n, "|",',
            '... emlCronbachAlpha.nExcluded, "|", emlCronbachAlpha.error$',
            'appendInfoLine: ""',
            "k = emlCronbachAlpha.k",
            "for j from 1 to k",
            '    appendInfoLine: "drop", j, "|", emlCronbachAlpha.alphaIfDeleted# [j]',
            "endfor"),
            probe)
        out <- suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
        out
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

    # The oracle: base R only. Raw alpha from the covariance matrix; Feldt
    # (1965) CI; alpha-if-deleted from leave-one-out covariance submatrices.
    # At k = 2 the leave-one-out "scale" has one item and no alpha: NA, which
    # is the kernel's documented undefined-by-design.
    oracle_alpha <- function(m, label) {
        cc <- m[stats::complete.cases(m), , drop = FALSE]
        k <- ncol(cc); n <- nrow(cc)
        C <- stats::cov(cc)
        a <- (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
        df1 <- n - 1; df2 <- (n - 1) * (k - 1)
        lo <- 1 - (1 - a) * stats::qf(0.975, df1, df2)
        hi <- 1 - (1 - a) * stats::qf(0.025, df1, df2)
        drop <- vapply(seq_len(k), function(j) {
            kk <- k - 1
            if (kk < 2) return(NA_real_)
            Cj <- C[-j, -j, drop = FALSE]
            (kk / (kk - 1)) * (1 - sum(diag(Cj)) / sum(Cj))
        }, numeric(1))
        o <- list(alpha = a, lo = lo, hi = hi, drop = drop,
                  n = n, nExcluded = nrow(m) - nrow(cc))
        # Opportunistic second opinion: the base-R oracle itself against
        # psych, when psych is around. Guards the port, not the kernel.
        # alpha and the Feldt CI cross-check at every k; the drop vector
        # only at k >= 3, because psych's 2-item alpha.drop prints a
        # covariance ratio, not an alpha (kernel header, decision 5).
        if (havePsych) {
            p <- suppressWarnings(psych::alpha(as.data.frame(cc),
                                               check.keys = FALSE,
                                               warnings = FALSE))
            check("v90", sprintf("[%s] base-R oracle vs psych::alpha (cross-check)", label),
                  o$alpha, p$total$raw_alpha, tol = 1e-12)
            check("v90", sprintf("[%s] base-R Feldt lower vs psych (cross-check)", label),
                  o$lo, p$feldt$lower.ci[[1]], tol = 1e-12)
            check("v90", sprintf("[%s] base-R Feldt upper vs psych (cross-check)", label),
                  o$hi, p$feldt$upper.ci[[1]], tol = 1e-12)
            if (k >= 3) {
                check("v90", sprintf("[%s] base-R alpha-if-deleted vs psych (cross-check, max)", label),
                      max(abs(o$drop - p$alpha.drop$raw_alpha)), 0, tol = 1e-12)
            }
        }
        o
    }

    oracles <- list()
    fixtures <- list(
        clean  = as.matrix(read_input("lane_survey_alpha_clean.csv")),
        revnot = as.matrix(read_input("lane_survey_alpha_revnotrev.csv")),
        two    = as.matrix(read_input("lane_survey_alpha_2item.csv")),
        miss   = as.matrix(read_input("lane_survey_alpha_missing.csv")))
    # Conditioning case (18 Aug stress round): the clean fixture riding a
    # large common offset. Alpha is translation-invariant, so the oracle
    # values are unchanged — but a sum-of-squares implementation loses
    # them to cancellation at this scale, which is exactly what this leg
    # pins. Derived from the committed fixture, so it is re-runnable.
    fixtures$offset <- fixtures$clean + 1e8

    for (name in names(fixtures)) {
        m <- fixtures[[name]]
        out <- drive_alpha("stats", m, name)
        ran <- !any(grepl("^Error", out)) && length(fld(out, "res")) >= 6
        check_true("v90", sprintf("the %s-fixture probe ran", name), ran)
        if (!ran) {
            cat(sprintf("      v90 %s probe output: %s\n", name,
                        paste(utils::tail(out, 8), collapse = " / ")))
            next
        }
        o <- oracle_alpha(m, name)
        oracles[[name]] <- o
        check("v90", sprintf("[%s] alpha vs base-R oracle", name),
              num(out, "res", 1), o$alpha, tol = 1e-10)
        check("v90", sprintf("[%s] Feldt CI lower vs base-R oracle", name),
              num(out, "res", 2), o$lo, tol = 1e-8)
        check("v90", sprintf("[%s] Feldt CI upper vs base-R oracle", name),
              num(out, "res", 3), o$hi, tol = 1e-8)
        check("v90", sprintf("[%s] k", name), num(out, "res", 4), ncol(m), tol = 0)
        check("v90", sprintf("[%s] n after listwise deletion", name),
              num(out, "res", 5), o$n, tol = 0)
        check("v90", sprintf("[%s] nExcluded disclosure", name),
              num(out, "res", 6), o$nExcluded, tol = 0)
        if (ncol(m) >= 3) {
            for (j in seq_len(ncol(m))) {
                check("v90", sprintf("[%s] alpha-if-deleted, item %d", name, j),
                      num(out, sprintf("drop%d", j), 1), o$drop[j], tol = 1e-10)
            }
        } else {
            # k = 2: a one-item scale has no alpha; the kernel returns
            # undefined by design (psych prints a covariance ratio here,
            # which is not an alpha — divergence stated in the header).
            check_true("v90", sprintf("[%s] alpha-if-deleted undefined at k = 2", name),
                       is.na(num(out, "drop1", 1)) && is.na(num(out, "drop2", 1)))
        }
    }

    # Direction pin the brief asks for: the unreversed item must DROP alpha.
    # (Reuses the loop's oracle; recomputing would re-emit its cross-checks.)
    o_clean <- if (!is.null(oracles$clean)) oracles$clean else
               oracle_alpha(fixtures$clean, "clean-fallback")
    out_rev <- drive_alpha("stats", fixtures$revnot, "revdir")
    check_true("v90", "alpha drops when a reverse-scored item is left unreversed",
               num(out_rev, "res", 1) < o_clean$alpha - 0.3)

    # -----------------------------------------------------------------------
    # 2. NEGATIVE CONTROL — seeded wrong variance denominator (n for n - 1)
    # -----------------------------------------------------------------------
    mut <- file.path(work, "mutant")
    dir.create(mut, showWarnings = FALSE)
    src <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    needle <- "/ (.n - 1)"
    hit <- grepl(needle, src, fixed = TRUE)
    check_true("v90", "the negative-control seed site exists in source", sum(hit) == 1)
    mut_src <- sub(needle, "/ .n", src, fixed = TRUE)
    writeLines(mut_src, file.path(mut, "eml-psychometrics.praat"))
    tgt2 <- file.path(work, "mutant_link")
    if (!file.exists(tgt2)) file.symlink(mut, tgt2)

    out_mut <- drive_alpha("mutant_link", fixtures$clean, "mutant")
    mut_alpha <- num(out_mut, "res", 1)
    if (red_mode) {
        cat("      EML_LANE_RED: running the standard agreement check against\n")
        cat("      the defective build — the next check is EXPECTED to FAIL.\n")
        check("v90", "[RED] seeded-defect alpha vs base-R oracle (must go red)",
              mut_alpha, o_clean$alpha, tol = 1e-10)
    } else {
        check("v90", "seeded wrong-denominator alpha DIFFERS from the oracle",
              mut_alpha, o_clean$alpha, tol = 1e-10, expect = "differ")
    }
}

if (!exists("EML_SUITE")) { eml_report("v90 Cronbach's alpha oracle"); eml_exit() }
