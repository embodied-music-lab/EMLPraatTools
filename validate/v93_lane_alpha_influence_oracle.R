# ===========================================================================
# v93 — respondent influence on alpha vs a base-R LOO oracle (survey lane)
# ===========================================================================
# Drives @emlAlphaInfluence (plugin/stats/eml-psychometrics.praat) LIVE on
# four committed fixtures and settles the full alpha, every leave-one-out
# alpha and delta, the original-row mapping, and the dominant-delta report
# against an oracle computed IN THIS RUN from base R alone: the same
# covariance-matrix alpha as v90's oracle, looped over leave-one-out row
# subsets. No packages — psych has no direct equivalent of this jackknife,
# so the oracle is base-R-only by nature.
#
# The relay's two named pins are here: (1) .alphaFull must equal
# @emlCronbachAlpha.alpha on the same matrix, driven in the same probe;
# (2) on the missing-before-deviant fixture the dominant delta must be
# reported under its ORIGINAL row number (17), not its surviving index
# (15) — the mapping disclosure the feature exists to get right.
#
# Negative control: a scratch copy of the kernel with a seeded wrong
# baseline (deltas measured against 0.99 * alphaFull) is driven on the
# deviant fixture, and the run asserts the defective delta DIFFERS from
# the oracle. Set EML_LANE_RED=1 to watch the named agreement check go
# red (exit status 1).
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
    cat(paste0("      SKIP: v93 needs Praat >= 6.6.30 to drive the kernel;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true("v93",
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v93")
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

    drive_influence <- function(stats_dir_rel, m, tag) {
        probe <- file.path(work, "scripts", paste0("v93-", tag, ".praat"))
        writeLines(c(
            paste0("include ../", stats_dir_rel, "/eml-psychometrics.praat"),
            "",
            'writeInfoLine: "v93"',
            sprintf("d## = %s", mat_literal(m)),
            "@emlAlphaInfluence: d##",
            'appendInfo: "res|", emlAlphaInfluence.alphaFull, "|",',
            '... emlAlphaInfluence.k, "|", emlAlphaInfluence.n, "|",',
            '... emlAlphaInfluence.nExcluded, "|",',
            '... emlAlphaInfluence.deltaMax, "|",',
            '... emlAlphaInfluence.deltaMaxRow, "|",',
            '... emlAlphaInfluence.error$',
            'appendInfoLine: ""',
            "n = emlAlphaInfluence.n",
            "if emlAlphaInfluence.error$ = \"\"",
            "    for j from 1 to n",
            '        appendInfoLine: "row", j, "|",',
            '        ... emlAlphaInfluence.rowIndex# [j], "|",',
            '        ... emlAlphaInfluence.alphaWithout# [j], "|",',
            '        ... emlAlphaInfluence.delta# [j]',
            "    endfor",
            "endif",
            "@emlCronbachAlpha: d##",
            'appendInfoLine: "alpharef|", emlCronbachAlpha.alpha'),
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

    # Base-R oracle: v90's covariance-matrix alpha, looped leave-one-out.
    base_alpha <- function(cc) {
        k <- ncol(cc)
        C <- stats::cov(cc)
        (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
    }
    oracle_influence <- function(m) {
        keep <- stats::complete.cases(m)
        cc <- m[keep, , drop = FALSE]
        n <- nrow(cc)
        full <- base_alpha(cc)
        aw <- vapply(seq_len(n), function(i)
            base_alpha(cc[-i, , drop = FALSE]), numeric(1))
        dl <- aw - full
        list(full = full, aw = aw, dl = dl,
             rowIndex = which(keep), n = n,
             nExcluded = nrow(m) - n,
             dmax = max(abs(dl)),
             dmaxRow = which(keep)[which.max(abs(dl))])
    }

    fixtures <- list(
        clean   = as.matrix(read_input("lane_survey_alpha_clean.csv")),
        deviant = as.matrix(read_input("lane_survey_influence_deviant.csv")),
        missdev = as.matrix(read_input("lane_survey_influence_missdev.csv")),
        n3      = as.matrix(read_input("lane_survey_influence_n3.csv")))

    for (name in names(fixtures)) {
        m <- fixtures[[name]]
        out <- drive_influence("stats", m, name)
        ran <- !any(grepl("^Error", out)) && length(fld(out, "res")) >= 6
        check_true("v93", sprintf("the %s-fixture probe ran", name), ran)
        if (!ran) {
            cat(sprintf("      v93 %s probe output: %s\n", name,
                        paste(utils::tail(out, 8), collapse = " / ")))
            next
        }
        o <- oracle_influence(m)
        check("v93", sprintf("[%s] alphaFull vs base-R oracle", name),
              num(out, "res", 1), o$full, tol = 1e-10)
        check("v93", sprintf("[%s] alphaFull equals @emlCronbachAlpha.alpha", name),
              num(out, "res", 1), num(out, "alpharef", 1), tol = 1e-12)
        check("v93", sprintf("[%s] n after listwise deletion", name),
              num(out, "res", 3), o$n, tol = 0)
        check("v93", sprintf("[%s] nExcluded disclosure", name),
              num(out, "res", 4), o$nExcluded, tol = 0)
        okIdx <- TRUE; okAw <- TRUE; okDl <- TRUE
        for (j in seq_len(o$n)) {
            if (num(out, sprintf("row%d", j), 1) != o$rowIndex[j]) okIdx <- FALSE
            if (abs(num(out, sprintf("row%d", j), 2) - o$aw[j]) > 1e-10) okAw <- FALSE
            if (abs(num(out, sprintf("row%d", j), 3) - o$dl[j]) > 1e-10) okDl <- FALSE
        }
        check_true("v93", sprintf("[%s] rowIndex# maps every survivor to its original row", name), okIdx)
        check_true("v93", sprintf("[%s] every leave-one-out alpha matches the oracle at 1e-10", name), okAw)
        check_true("v93", sprintf("[%s] every delta matches the oracle at 1e-10", name), okDl)
        check("v93", sprintf("[%s] deltaMax vs oracle", name),
              num(out, "res", 5), o$dmax, tol = 1e-10)
        check("v93", sprintf("[%s] deltaMaxRow is the ORIGINAL row number", name),
              num(out, "res", 6), o$dmaxRow, tol = 0)
    }

    # The relay's named pins, asserted against fixed expectations too
    # (not only against the oracle, so a fixture regression is loud).
    o_dev <- oracle_influence(fixtures$deviant)
    check("v93", "planted deviant dominates: deltaMaxRow = 14 on the deviant fixture",
          o_dev$dmaxRow, 14, tol = 0)
    check_true("v93", "planted deviant dominates by margin (runner-up below 2/3 of max)",
               sort(abs(o_dev$dl), decreasing = TRUE)[2] < (2 / 3) * o_dev$dmax)
    o_md <- oracle_influence(fixtures$missdev)
    check("v93", "mapping pin: dominant delta reported as original row 17, exclusions sit before it",
          o_md$dmaxRow, 17, tol = 0)
    check_true("v93", "mapping pin is non-trivial: surviving index differs from original row",
               which.max(abs(o_md$dl)) != o_md$dmaxRow)

    # Refusal: n = 2 after deletion.
    m2 <- matrix(c(1, 2, 3, 4), 2, 2)
    out2 <- drive_influence("stats", m2, "refusal")
    check_true("v93", "n below the floor is refused with a message",
               is.na(num(out2, "res", 5)) && nzchar(fld(out2, "res")[7]))

    # -----------------------------------------------------------------------
    # NEGATIVE CONTROL — seeded wrong baseline (0.99 * alphaFull)
    # -----------------------------------------------------------------------
    mut <- file.path(work, "mutant")
    dir.create(mut, showWarnings = FALSE)
    src <- readLines(file.path(plug, "stats", "eml-psychometrics.praat"))
    needle <- ".delta# [.j] = .alphaWithout# [.j] - .alphaFull"
    hit <- grepl(needle, src, fixed = TRUE)
    check_true("v93", "the negative-control seed site exists in source", sum(hit) == 1)
    mut_src <- sub(needle,
                   ".delta# [.j] = .alphaWithout# [.j] - .alphaFull * 0.99",
                   src, fixed = TRUE)
    writeLines(mut_src, file.path(mut, "eml-psychometrics.praat"))
    tgt2 <- file.path(work, "mutant_link")
    if (!file.exists(tgt2)) file.symlink(mut, tgt2)

    out_mut <- drive_influence("mutant_link", fixtures$deviant, "mutant")
    mut_d1 <- num(out_mut, "row1", 3)
    if (red_mode) {
        cat("      EML_LANE_RED: running the standard agreement check against\n")
        cat("      the defective build — the next check is EXPECTED to FAIL.\n")
        check("v93", "[RED] seeded wrong-baseline delta vs oracle (must go red)",
              mut_d1, o_dev$dl[1], tol = 1e-10)
    } else {
        check("v93", "seeded wrong-baseline delta DIFFERS from the oracle",
              mut_d1, o_dev$dl[1], tol = 1e-10, expect = "differ")
    }
}

if (!exists("EML_SUITE")) { eml_report("v93 alpha respondent-influence oracle"); eml_exit() }
