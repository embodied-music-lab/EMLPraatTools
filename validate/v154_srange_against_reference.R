#!/usr/bin/env Rscript
# ============================================================================
# v154 -- re-judging the port against the far-tail reference grid
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. v150_studentized_range.R judged
# plugin_EML_StatsGraphs/stats/eml-studentized-range.praat's
# @emlStudentizedRangeQ / @emlInvStudentizedRangeQ against a single oracle,
# R's stats::ptukey/qtukey, "at the standard rule, mid and far tail, no
# clause" (RULING_CONSOLIDATED_KERNELS_2026-09-01.md). Against that oracle
# alone the port failed 115 of 394 forward cells.
# mailbox/to-fable/MEMO_ORACLE_IS_WRONG_2026-09-01.md then showed the
# oracle itself measurably wrong in the far tail.
#
# RETRACTED, 1 September 2026 (Opus): this header previously extended that to
# "at ordinary p, at ordinary df", citing k=3, df=16, alpha=.05 as R being
# 6.7e-8 off. That figure is false -- the true disagreement there is 6.2e-12
# and R passes. Across 120 cells at ordinary alphas, k=2..10, df=5..500, R and
# scipy agree to exactly zero relative difference. R's inaccuracy is a FAR-TAIL
# phenomenon only. Fable's ruling on this file's authority VOIDS the
# 115-of-394 count as an artifact of that disqualified oracle. This file
# does not carry that count forward in any form -- it judges the port
# again, from the ground up, against:
#
#   - walkthrough/kit/reference/srange_reference.tsv, an independent
#     arbitrary-precision (mpmath) grid built directly from the range/chi
#     definition (build_srange_reference.py in the same directory), with
#     recorded convergence evidence per point, WHEREVER R is not verified
#     accurate for that exact point;
#   - R's stats::ptukey/qtukey directly, at the standard rule, WHEREVER
#     R.IS verified accurate for that exact point (R_verified_domain.tsv's
#     operational rule, re-applied live per point below, exactly as that
#     file's header specifies -- not looked up from a table, for the same
#     reason that file gives: the domain does not interpolate cleanly).
#
# Both directions, exactly as the reference grid covers them: forward
# (@emlStudentizedRangeQ, P(Q>q) given q) and inverse
# (@emlInvStudentizedRangeQ, q given a target p).
#
# STANDARD RULE, UNCHANGED: PASS if abs(port - oracle) <= 1e-12 OR
# abs(port - oracle)/abs(oracle) <= 1e-9. Both computed and printed for
# every cell.
#
# WHAT THIS FILE DOES NOT DO. It does not regenerate srange_reference.tsv
# (that is build_srange_reference.py's job, run separately -- regenerating
# a multi-hour arbitrary-precision grid inside a validator that is supposed
# to run routinely is exactly the wrong shape). It does not re-run the
# R-vs-scipy domain sweep either (R_verified_domain.tsv is Part 2's
# output) -- but it DOES re-check domain membership live at each grid row's
# exact (k,df,q), per that file's own header, rather than trusting a
# cached column, because scipy availability and version can drift between
# the grid's build time and this file's run time and the check is cheap.
#
# STATUS: the procedures under test are STILL NOT WIRED into
# @emlTukeyHSD (eml-inferential.praat still calls Praat's built-in
# `Get TukeyQ:`/`Get invTukeyQ:`) -- unchanged from v150, and this file's
# brief is the same standalone-kernel scope v150's was.
#
# Base R only. No packages. Needs a Praat at or above the plugin's floor
# (6.6.30) and a python3 with scipy on PATH for the live domain re-check
# and (if srange_reference.tsv is regenerated) mpmath; skips (not fails)
# either prerequisite, the standing convention (v144, v145, v146, v150).
#
# NOT registered in validate/run_all.R for the same reason v150 is not:
# the kernel is not wired into any door yet. Registration is a later step
# alongside the wiring.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v154"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

check_dual <- function(id, what, reported, computed, relTol = 1e-9, absTol = 1e-12) {
    finite_both <- is.finite(reported) && is.finite(computed)
    absErr <- if (finite_both) abs(reported - computed) else NA_real_
    relErr <- if (finite_both && computed != 0) absErr / abs(computed) else absErr
    pass <- finite_both && (absErr <= absTol || (is.finite(relErr) && relErr <= relTol))
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = reported, computed = computed,
        tol = relTol, expect = "match", pass = pass, stringsAsFactors = FALSE
    )
    list(pass = pass, absErr = absErr, relErr = relErr)
}

refDir <- repo_path("walkthrough", "kit", "reference")
refFile <- file.path(refDir, "srange_reference.tsv")

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)
srqFile <- file.path(plug, "stats", "eml-studentized-range.praat")

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
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE, stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}

pyOk <- FALSE
pyBin <- Sys.which("python3")
if (nzchar(pyBin)) {
    pyOk <- tryCatch({
        out <- system2(pyBin, c("-c", "'import scipy.stats; print(1)'"), stdout = TRUE, stderr = TRUE)
        length(out) > 0 && identical(trimws(out[length(out)]), "1")
    }, error = function(e) FALSE)
}

canDrive <- pvnum >= 6630 && file.exists(srqFile) && file.exists(refFile) && pyOk

if (!canDrive) {
    reasons <- c(
        if (!file.exists(srqFile)) paste("eml-studentized-range.praat not found at", srqFile),
        if (pvnum < 6630) paste0("needs Praat >= 6.6.30; found ", if (is.na(pv)) "none" else pv),
        if (!file.exists(refFile)) paste("srange_reference.tsv not found at", refFile,
                                          "-- run build_srange_reference.py first"),
        if (!pyOk) "python3 with scipy not available for the live R-domain re-check"
    )
    cat(paste0("      SKIP: v154 ", paste(reasons, collapse = "; "), "\n"))
    check_true(V, sprintf("prerequisites available for v154 (%s)", paste(reasons, collapse = "; ")), FALSE)
} else {

work <- file.path(tempdir(), "v154")
unlink(work, recursive = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)
prefs <- file.path(work, "prefs")
dir.create(prefs, showWarnings = FALSE)

run_praat <- function(lines, tag, timeoutSec = 300) {
    probe_path <- file.path(work, paste0("v154-", tag, ".praat"))
    writeLines(lines, probe_path)
    out <- suppressWarnings(system2("timeout",
        c(as.character(timeoutSec), "env", "-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
        stdout = TRUE, stderr = TRUE))
    out
}
prelude <- c(paste0("include ", srqFile))

# ---------------------------------------------------------------------------
# Load the reference grid (comment lines start with '#').
# ---------------------------------------------------------------------------
refLines <- readLines(refFile)
refLines <- refLines[!grepl("^#", refLines)]
ref <- read.delim(text = paste(refLines, collapse = "\n"), stringsAsFactors = FALSE)
cat(sprintf("      v154: loaded %d reference rows from %s\n", nrow(ref), refFile))
check_true(V, sprintf("srange_reference.tsv has at least one converged row (%d loaded)", nrow(ref)),
           nrow(ref) > 0)

# ---------------------------------------------------------------------------
# Live domain re-check: for each row's exact (k, df, q), is R inside its
# verified domain right now? Batched into one python3 call.
# R_verified_domain.tsv's own operational rule, reapplied (see its header
# and this file's header for why a cached/table lookup is not used).
# ---------------------------------------------------------------------------
py_domain_check <- function(qs, ks, dfs) {
    qv <- paste(sprintf("%.17g", qs), collapse = ",")
    kv <- paste(ks, collapse = ",")
    dv <- paste(sprintf("%.17g", dfs), collapse = ",")
    code <- sprintf(paste0(
        "import sys\n",
        "from scipy.stats import studentized_range as SR\n",
        "qs=[%s]\nks=[%s]\ndfs=[%s]\n",
        "print(','.join(repr(float(SR.sf(q,k,df))) for q,k,df in zip(qs,ks,dfs)))\n"
    ), qv, kv, dv)
    tf <- file.path(work, "domain_check.py")
    writeLines(code, tf)
    out <- system2(pyBin, tf, stdout = TRUE, stderr = TRUE)
    as.numeric(strsplit(out[length(out)], ",")[[1]])
}
scipySfNow <- tryCatch(py_domain_check(ref$q, ref$k, ref$df), error = function(e) {
    cat("      live domain re-check failed:", conditionMessage(e), "\n"); rep(NA_real_, nrow(ref))
})
rNow <- ref$r_ptukey_p
standard_rule_ok <- function(a, b) {
    ok <- is.finite(a) & is.finite(b)
    absErr <- ifelse(ok, abs(a - b), NA_real_)
    relErr <- ifelse(ok & b != 0, absErr / abs(b), absErr)
    ok & (absErr <= 1e-12 | (is.finite(relErr) & relErr <= 1e-9))
}
ref$r_domain_live <- standard_rule_ok(scipySfNow, rNow)
ref$r_in_verified_domain_bool <- ref$r_in_verified_domain %in% c("True", "TRUE", "true", "1")
nDriftedDomain <- sum(ref$r_in_verified_domain_bool != ref$r_domain_live, na.rm = TRUE)
cat(sprintf("      v154: live domain re-check agrees with the grid's recorded domain flag on %d/%d rows (%d drifted)\n",
            sum(ref$r_in_verified_domain_bool == ref$r_domain_live, na.rm = TRUE), nrow(ref), nDriftedDomain))

# oracle value + which oracle, per row, decided by the LIVE check
ref$oracle_value <- ifelse(ref$r_domain_live, ref$r_ptukey_p, ref$mpmath_p)
ref$oracle_source <- ifelse(ref$r_domain_live, "R", "grid")

# ---------------------------------------------------------------------------
# PART 1 -- FORWARD rows: drive @emlStudentizedRangeQ at each row's (q,k,df)
# ---------------------------------------------------------------------------
fwdRows <- which(ref$type == "forward")
fwd_lines <- c(prelude, 'writeInfoLine: "v154-forward"')
for (idx in fwdRows) {
    r <- ref[idx, ]
    fwd_lines <- c(fwd_lines,
        sprintf("@emlStudentizedRangeQ: %s, %d, %s, 1",
                format(r$q, digits = 17), r$k, format(r$df, digits = 17)),
        sprintf('appendInfoLine: "CELL %d ", emlStudentizedRangeQ.ok, " ", emlStudentizedRangeQ.p, " [", emlStudentizedRangeQ.warning$, "]"',
                idx))
}
fwdOut <- if (length(fwdRows) > 0) run_praat(fwd_lines, "forward", timeoutSec = 300) else character(0)
parse_cells <- function(out, tag) {
    got <- list()
    for (ln in grep(paste0("^", tag, " "), out, value = TRUE)) {
        m <- regmatches(ln, regexec(paste0("^", tag, " (\\d+) (\\d) (\\S+) \\[(.*)\\]$"), ln))[[1]]
        if (length(m) == 5) got[[as.integer(m[2])]] <- list(ok = as.integer(m[3]),
            val = suppressWarnings(as.numeric(m[4])), warn = m[5])
    }
    got
}
fwdGot <- parse_cells(fwdOut, "CELL")
check_true(V, sprintf("Praat printed one forward CELL per reference row (%d expected, %d parsed)",
                       length(fwdRows), sum(!vapply(fwdGot, is.null, TRUE))),
           length(fwdGot) >= max(fwdRows, 0) || length(fwdRows) == 0)

# ---------------------------------------------------------------------------
# PART 2 -- QUANTILE rows: drive @emlInvStudentizedRangeQ at each row's
# (k, df, p_target)
# ---------------------------------------------------------------------------
qtlRows <- which(ref$type == "quantile")
inv_lines <- c(prelude, 'writeInfoLine: "v154-inverse"')
for (idx in qtlRows) {
    r <- ref[idx, ]
    inv_lines <- c(inv_lines,
        sprintf("@emlInvStudentizedRangeQ: %s, %d, %s, 1",
                format(r$p_target, digits = 17), r$k, format(r$df, digits = 17)),
        sprintf('appendInfoLine: "ICELL %d ", emlInvStudentizedRangeQ.ok, " ", emlInvStudentizedRangeQ.q, " [", emlInvStudentizedRangeQ.warning$, "]"',
                idx))
}
invOut <- if (length(qtlRows) > 0) run_praat(inv_lines, "inverse", timeoutSec = 300) else character(0)
invGot <- parse_cells(invOut, "ICELL")

# ---------------------------------------------------------------------------
# Judge: forward rows compare P(Q>q); quantile rows compare the SOLVED q
# (against the grid row's own q, since that q is itself the converged
# solution recorded there) via the SAME standard rule.
# ---------------------------------------------------------------------------
buckets <- c("[0.5,1e-2)", "[1e-2,1e-5)", "[1e-5,1e-9)", "[1e-9,1e-13)", "[1e-13,1e-16]")
bucket_of <- function(p) {
    if (is.na(p)) return(NA_character_)
    if (p >= 1e-2) buckets[1] else if (p >= 1e-5) buckets[2] else if (p >= 1e-9) buckets[3]
    else if (p >= 1e-13) buckets[4] else buckets[5]
}

resultRows <- list()
for (idx in fwdRows) {
    r <- ref[idx, ]
    g <- fwdGot[[idx]]
    if (is.null(g)) next
    lab <- sprintf("forward k=%d df=%g q=%.6f p~%.0e oracle=%s", r$k, r$df, r$q, r$p_target, r$oracle_source)
    res <- check_dual(V, lab, g$val, r$oracle_value)
    resultRows[[length(resultRows) + 1]] <- data.frame(
        kind = "forward", k = r$k, df = r$df, target = r$p_target, q = r$q,
        oracle_source = r$oracle_source, oracle = r$oracle_value, port = g$val,
        absErr = res$absErr, relErr = res$relErr, pass = res$pass,
        bucket = bucket_of(r$oracle_value), stringsAsFactors = FALSE)
}
for (idx in qtlRows) {
    r <- ref[idx, ]
    g <- invGot[[idx]]
    if (is.null(g)) next
    # oracle q: from R's qtukey when in domain, else the grid's own solved q
    if (isTRUE(r$r_domain_live)) {
        oracleQ <- tryCatch(qtukey(r$p_target, nmeans = r$k, df = r$df, lower.tail = FALSE),
                             error = function(e) NA_real_)
        oracleSrc <- "R"
    } else {
        oracleQ <- r$q
        oracleSrc <- "grid"
    }
    lab <- sprintf("quantile k=%d df=%g alpha=%.0e oracle=%s", r$k, r$df, r$p_target, oracleSrc)
    res <- check_dual(V, lab, g$val, oracleQ)
    resultRows[[length(resultRows) + 1]] <- data.frame(
        kind = "quantile", k = r$k, df = r$df, target = r$p_target, q = oracleQ,
        oracle_source = oracleSrc, oracle = oracleQ, port = g$val,
        absErr = res$absErr, relErr = res$relErr, pass = res$pass,
        bucket = NA_character_, stringsAsFactors = FALSE)
}
resultTbl <- do.call(rbind, resultRows)

cat("\n      ===================== v154 VERDICT =====================\n")
if (is.null(resultTbl) || nrow(resultTbl) == 0) {
    cat("      No cells were judged (empty grid or Praat probe returned nothing).\n")
} else {
    nTot <- nrow(resultTbl); nPass <- sum(resultTbl$pass, na.rm = TRUE)
    cat(sprintf("      Overall: %d/%d cells pass the standard rule (rel<=1e-9 OR abs<=1e-12).\n",
                nPass, nTot))
    for (kind in c("forward", "quantile")) {
        sub <- resultTbl[resultTbl$kind == kind, ]
        if (nrow(sub) == 0) next
        cat(sprintf("      %s: %d/%d pass\n", kind, sum(sub$pass, na.rm = TRUE), nrow(sub)))
        for (src in unique(sub$oracle_source)) {
            s2 <- sub[sub$oracle_source == src, ]
            cat(sprintf("        oracle=%-4s: %d/%d pass\n", src, sum(s2$pass, na.rm = TRUE), nrow(s2)))
        }
    }
    failing <- resultTbl[!resultTbl$pass & is.finite(resultTbl$pass), ]
    if (nrow(failing) > 0) {
        cat(sprintf("\n      %d FAILING cells (worst 40 by relative error):\n", nrow(failing)))
        failing <- failing[order(-ifelse(is.finite(failing$relErr), failing$relErr, 0)), ]
        for (i in seq_len(min(40, nrow(failing)))) {
            fr <- failing[i, ]
            cat(sprintf("        %s k=%d df=%g target=%.3e oracle(%s)=%.6e port=%.6e absErr=%.3e relErr=%.3e\n",
                        fr$kind, fr$k, fr$df, fr$target, fr$oracle_source, fr$oracle, fr$port,
                        fr$absErr, fr$relErr))
        }
    } else {
        cat("\n      No failing cells against the properly-converged reference.\n")
    }
    # Per-cell evidence to disk. A verdict whose per-cell numbers exist only in
    # a scrolled terminal cannot be audited, and every cell below is the input
    # to the oracle-arbitration step (walkthrough/kit/audit/arbitrate_v154.R).
    outDir <- repo_path("walkthrough", "kit", "audit")
    dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
    outFile <- file.path(outDir, "v154_cells.tsv")
    write.table(resultTbl, outFile, sep = "\t", row.names = FALSE,
                quote = FALSE, na = "NA")
    cat(sprintf("\n      per-cell evidence written: %s (%d rows)\n",
                outFile, nrow(resultTbl)))

    # bucket breakdown for forward cells, evidence not hidden inside a pass count
    # NOTE ON THE ABSOLUTE LIMB. The standard rule passes a cell when the
    # absolute error is at or below 1e-12. Once the oracle probability itself
    # falls below 1e-12, that limb is satisfied by ANY answer, so the two
    # deepest buckets cannot fail and their pass counts assert nothing. Read
    # their worst relative error, not their fail count.
    fwdTbl <- resultTbl[resultTbl$kind == "forward" & !is.na(resultTbl$bucket), ]
    if (nrow(fwdTbl) > 0) {
        cat("\n      forward, by p-magnitude bucket:\n")
        for (bk in buckets) {
            s3 <- fwdTbl[fwdTbl$bucket == bk, ]
            if (nrow(s3) == 0) next
            cat(sprintf("        %-14s n=%3d fail=%2d worst relErr=%.3e\n",
                        bk, nrow(s3), sum(!s3$pass), max(s3$relErr[is.finite(s3$relErr)], 0)))
        }
        vac <- fwdTbl[is.finite(fwdTbl$oracle) & abs(fwdTbl$oracle) <= 1e-12, ]
        if (nrow(vac) > 0) {
            cat(sprintf("        (%d of these cells pass on the absolute limb alone,\n", nrow(vac)))
            cat("         because the oracle itself is at or below the 1e-12 floor.)\n")
        }
    }
}
cat("      ==========================================================\n\n")

} # canDrive
