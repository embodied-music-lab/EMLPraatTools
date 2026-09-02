#!/usr/bin/env Rscript
# ============================================================================
# v154 -- judging the port against the far-tail reference grid, and ONLY it
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
# oracle itself measurably wrong in the far tail, and
# RULING_PTUKEY_REFERENCE_2026-09-01.md ordered a pinned arbitrary-precision
# reference grid built independently of both R and scipy
# (srange_reference.tsv / build_srange_reference.py, this directory's
# sibling under walkthrough/kit/reference/).
#
# A prior version of this file (retracted; see git history) then judged each
# cell against ONE of two oracles picked per row: the grid, or R directly
# where a recorded flag said R was trustworthy AT THAT POINT. RULING_PORT_
# ACCEPTANCE_2026-09-02.md (points 1-2) struck that down. The flag
# (r_in_verified_domain) is measured against R's FORWARD function, ptukey;
# quantile cells were inheriting it to select R's qtukey as their oracle --
# a DIFFERENT function, and R's own qtukey does not invert R's own ptukey
# past roughly 4e-8. Comparing the port to a second approximation (R) also
# quietly doubles the error budget on cells where both are correct but
# disagree in the ninth digit (the k=10, df=200 forward cell was failing
# for exactly that reason and no other).
#
# THE RULE NOW, PER THAT RULING: every cell, both directions, is judged
# against walkthrough/kit/reference/srange_reference.tsv ALONE, under the
# standard rule. R's stats::ptukey/qtukey and scipy.stats.studentized_range
# remain in the per-cell output as DOCUMENTED COMPARISON COLUMNS -- evidence
# about R and about scipy, for the paper's taxonomy of where each reference
# implementation is and is not trustworthy -- but neither one selects, and
# neither one can make a cell pass or fail. r_in_verified_domain (the
# recorded flag) keeps exactly one job: it is R's measured domain map, read
# straight from the grid file, never applied as a selector here.
#
# THE ABSOLUTE-FLOOR PROBLEM (point 3). The standard rule passes a cell when
# abs(port - oracle) <= 1e-12, with no further condition -- so once the
# grid's own true probability is itself below 1e-12, that limb is satisfied
# by ANY port answer, including zero, and demanding the relative limb
# (rel <= 1e-9) instead would fail cells the port gets right to within a
# fraction of a percent. Neither reading makes a cell in that regime assert
# anything as PASS/FAIL. Those cells (currently: the 9 forward rows whose
# grid probability sits below 1e-12, all at p_target=1e-15) are pulled out
# of the pass/fail tally entirely and reported as a separate CHARACTERIZATION
# population, with the MEASURED relative-error envelope per p-magnitude
# bucket -- structure in this file's output, not a comment, so the paper's
# far-tail claim rests on a measured envelope and not on a pass count that
# cannot fail.
#
# ONE DOMAIN FLAG (point 5a). srange_reference.tsv carries a recorded
# r_in_verified_domain column, written once by build_srange_reference.py's
# r_in_domain() from the grid's own stored scipy_p/r_ptukey_p columns. A
# prior version of this file ALSO recomputed that flag live, by re-querying
# scipy at run time -- and the live copy disagreed with the recorded copy on
# 3 of 130 rows, with this file silently preferring the live one. Two copies
# of one fact that can disagree is exactly the canon violation the ruling
# names. There is now exactly one formula
# (walkthrough/kit/reference/recompute_r_verified_domain.R, committed
# alongside the grid), and this file's only use of it is to assert that the
# grid's RECORDED flag equals what that formula recomputes FROM THE GRID'S
# OWN STORED COLUMNS -- no live external query, no silent preference,
# failing loudly (a normal check_true assertion, not a warning) on any
# drift. See that script's header for the measured, diagnosed cause of the
# 3-row disagreement the live re-check produced (it was a bug in the live
# check's zero-denominator handling, not a defect in the recorded flag: the
# recorded flag agrees with a from-the-grid recomputation on 130/130 rows).
#
# Both directions, exactly as the reference grid covers them: forward
# (@emlStudentizedRangeQ, P(Q>q) given q) and inverse
# (@emlInvStudentizedRangeQ, q given a target p).
#
# STANDARD RULE, UNCHANGED: PASS if abs(port - oracle) <= 1e-12 OR
# abs(port - oracle)/abs(oracle) <= 1e-9, oracle == the grid's mpmath_p
# (forward) or the grid's own converged q (quantile), always. Both computed
# and printed for every cell.
#
# WHAT THIS FILE DOES NOT DO. It does not regenerate srange_reference.tsv
# (that is build_srange_reference.py's job, run separately -- regenerating
# a multi-hour arbitrary-precision grid inside a validator that is supposed
# to run routinely is exactly the wrong shape). It does not re-run the
# R-vs-scipy domain sweep either (R_verified_domain.tsv is that job's own
# output) -- it only asserts that the grid's recorded per-row flag matches
# what recompute_r_verified_domain.R derives from that same row's own
# stored columns, per the "one domain flag" section above.
#
# STATUS: the procedures under test are STILL NOT WIRED into
# @emlTukeyHSD (eml-inferential.praat still calls Praat's built-in
# `Get TukeyQ:`/`Get invTukeyQ:`) -- unchanged from v150, and this file's
# brief is the same standalone-kernel scope v150's was.
#
# Base R only. No packages. Needs a Praat at or above the plugin's floor
# (6.6.30); skips (not fails) when it is absent, the standing convention
# (v144, v145, v146, v150). Does NOT need python3/scipy at run time -- the
# R-vs-scipy comparison this file prints is read from the grid's own
# pre-computed scipy_p/r_ptukey_p columns, never queried live (see the "one
# domain flag" note above for why a live external query was removed).
# python3 with mpmath is needed only to regenerate srange_reference.tsv
# itself, a separate, occasional step this file does not perform.
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

# standard_rule: the same abs<=1e-12 OR rel<=1e-9 test, vectorized, used
# below for the R/scipy COMPARISON columns (never for pass/fail).
standard_rule <- function(a, b) {
    ok <- is.finite(a) & is.finite(b)
    absErr <- ifelse(ok, abs(a - b), NA_real_)
    relErr <- ifelse(ok & b != 0, absErr / abs(b), absErr)
    list(absErr = absErr, relErr = relErr,
         pass = ok & (absErr <= 1e-12 | (is.finite(relErr) & relErr <= 1e-9)))
}

refDir <- repo_path("walkthrough", "kit", "reference")
refFile <- file.path(refDir, "srange_reference.tsv")
domainScript <- file.path(refDir, "recompute_r_verified_domain.R")

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

canDrive <- pvnum >= 6630 && file.exists(srqFile) && file.exists(refFile) && file.exists(domainScript)

if (!canDrive) {
    reasons <- c(
        if (!file.exists(srqFile)) paste("eml-studentized-range.praat not found at", srqFile),
        if (pvnum < 6630) paste0("needs Praat >= 6.6.30; found ", if (is.na(pv)) "none" else pv),
        if (!file.exists(refFile)) paste("srange_reference.tsv not found at", refFile,
                                          "-- run build_srange_reference.py first"),
        if (!file.exists(domainScript)) paste("recompute_r_verified_domain.R not found at", domainScript)
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
# Load the reference grid (comment lines start with '#'). This is the ONLY
# oracle: every judgement below is port vs this file's mpmath_p (forward) or
# this file's own converged q (quantile). Nothing here is conditional on R.
# ---------------------------------------------------------------------------
refLines <- readLines(refFile)
refLines <- refLines[!grepl("^#", refLines)]
ref <- read.delim(text = paste(refLines, collapse = "\n"), stringsAsFactors = FALSE)
cat(sprintf("      v154: loaded %d reference rows from %s\n", nrow(ref), refFile))
check_true(V, sprintf("srange_reference.tsv has at least one converged row (%d loaded)", nrow(ref)),
           nrow(ref) > 0)

# ---------------------------------------------------------------------------
# ONE DOMAIN FLAG (ruling point 5a). recompute_r_verified_domain.R is the
# single committed formula. It is sourced (not re-implemented here) and
# applied to the grid's OWN stored scipy_p/r_ptukey_p columns -- no live
# external query. The recorded flag must equal what that formula recomputes;
# any drift fails loudly, in the ordinary suite sense (check_true, counted),
# not a printed warning that can be scrolled past.
# ---------------------------------------------------------------------------
source(domainScript)
ref$r_in_verified_domain_bool <- ref$r_in_verified_domain %in% c("True", "TRUE", "true", "1")
ref$r_domain_recomputed <- recompute_r_verified_domain(ref$scipy_p, ref$r_ptukey_p)
domainDrift <- which(ref$r_in_verified_domain_bool != ref$r_domain_recomputed)
cat(sprintf("      v154: recorded r_in_verified_domain equals recompute_r_verified_domain.R's recomputation on %d/%d rows (%d drift)\n",
            nrow(ref) - length(domainDrift), nrow(ref), length(domainDrift)))
if (length(domainDrift) > 0) {
    cat("      DOMAIN FLAG DRIFT -- recorded and recomputed disagree on:\n")
    for (i in domainDrift) {
        cat(sprintf("        row %d: k=%d df=%g p_target=%.3e recorded=%s recomputed=%s scipy_p=%.6e r_ptukey_p=%.6e\n",
                    i, ref$k[i], ref$df[i], ref$p_target[i], ref$r_in_verified_domain[i],
                    ref$r_domain_recomputed[i], ref$scipy_p[i], ref$r_ptukey_p[i]))
    }
}
check_true(V, sprintf("recorded r_in_verified_domain matches recompute_r_verified_domain.R on every row (%d/%d, %d drift)",
                       nrow(ref) - length(domainDrift), nrow(ref), length(domainDrift)),
           length(domainDrift) == 0)
cat(sprintf("      (r_in_verified_domain's only remaining job: R's measured domain map for the paper -- %d/%d rows True)\n",
            sum(ref$r_in_verified_domain_bool), nrow(ref)))

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
# Judge -- against the grid ALONE, both directions (ruling points 1-2).
# Forward: port's P(Q>q) vs the grid's mpmath_p at that row's q.
# Quantile: port's solved q vs the grid's OWN converged q for that row's
# p_target (that q is itself the value build_srange_reference.py's iterative
# secant loop converged to; see that file's header).
#
# R's ptukey/qtukey and scipy are computed here too, PURELY as documented
# comparison columns (ruling point 1's ordered wording) -- judged against
# the SAME grid oracle under the SAME standard rule, but never feeding
# `pass`, which is the port-vs-grid result and only that.
#
# CHARACTERIZATION SPLIT (ruling point 3): a forward row whose grid
# probability (mpmath_p) is below the standard rule's absolute floor
# (1e-12) is pulled OUT of the pass/fail tally -- check_dual is not called
# for it -- and instead accumulated into a separate characterization table,
# reported below by its measured relative-error envelope, never by a pass
# count. No quantile row currently falls below that floor (p_target's
# smallest value, 1e-5, and the grid's own solved probabilities at those
# rows both sit far above 1e-12).
# ---------------------------------------------------------------------------
buckets <- c("[0.5,1e-2)", "[1e-2,1e-5)", "[1e-5,1e-9)", "[1e-9,1e-13)", "[1e-13,1e-16]")
bucket_of <- function(p) {
    if (is.na(p)) return(NA_character_)
    if (p >= 1e-2) buckets[1] else if (p >= 1e-5) buckets[2] else if (p >= 1e-9) buckets[3]
    else if (p >= 1e-13) buckets[4] else buckets[5]
}
CHAR_FLOOR <- 1e-12  # ruling point 3's absolute floor: grid p below this leaves the tally

resultRows <- list()
for (idx in fwdRows) {
    r <- ref[idx, ]
    g <- fwdGot[[idx]]
    if (is.null(g)) next
    gridP <- r$mpmath_p
    isChar <- is.finite(gridP) && gridP < CHAR_FLOOR
    population <- if (isChar) "characterization" else "acceptance"
    lab <- sprintf("forward[%s] k=%d df=%g q=%.6f p~%.0e", population, r$k, r$df, r$q, r$p_target)
    if (isChar) {
        # Not counted: compute the same statistic without recording a
        # pass/fail assertion (this row asserts nothing under the standard
        # rule -- see header).
        finite_both <- is.finite(g$val) && is.finite(gridP)
        absErr <- if (finite_both) abs(g$val - gridP) else NA_real_
        relErr <- if (finite_both && gridP != 0) absErr / abs(gridP) else absErr
        res <- list(pass = NA, absErr = absErr, relErr = relErr)
    } else {
        res <- check_dual(V, lab, g$val, gridP)
    }
    rComp <- standard_rule(r$r_ptukey_p, gridP)
    sComp <- standard_rule(r$scipy_p, gridP)
    resultRows[[length(resultRows) + 1]] <- data.frame(
        kind = "forward", population = population, k = r$k, df = r$df,
        target = r$p_target, q = r$q, oracle = gridP, port = g$val,
        absErr = res$absErr, relErr = res$relErr, pass = res$pass,
        r_value = r$r_ptukey_p, r_absErr = rComp$absErr, r_relErr = rComp$relErr, r_pass = rComp$pass,
        scipy_value = r$scipy_p, scipy_absErr = sComp$absErr, scipy_relErr = sComp$relErr, scipy_pass = sComp$pass,
        r_in_verified_domain = r$r_in_verified_domain_bool,
        bucket = bucket_of(gridP), stringsAsFactors = FALSE)
}
for (idx in qtlRows) {
    r <- ref[idx, ]
    g <- invGot[[idx]]
    if (is.null(g)) next
    gridQ <- r$q
    lab <- sprintf("quantile k=%d df=%g alpha=%.0e", r$k, r$df, r$p_target)
    res <- check_dual(V, lab, g$val, gridQ)
    # R comparison column: R's OWN qtukey inverse at this row's p_target
    # (documented evidence about R's qtukey, per the ruling's header note
    # that this is a different function from ptukey and must never select
    # the oracle) -- judged against the SAME grid q, same standard rule.
    rQ <- tryCatch(qtukey(r$p_target, nmeans = r$k, df = r$df, lower.tail = FALSE),
                    error = function(e) NA_real_)
    rComp <- standard_rule(rQ, gridQ)
    resultRows[[length(resultRows) + 1]] <- data.frame(
        kind = "quantile", population = "acceptance", k = r$k, df = r$df,
        target = r$p_target, q = gridQ, oracle = gridQ, port = g$val,
        absErr = res$absErr, relErr = res$relErr, pass = res$pass,
        r_value = rQ, r_absErr = rComp$absErr, r_relErr = rComp$relErr, r_pass = rComp$pass,
        scipy_value = NA_real_, scipy_absErr = NA_real_, scipy_relErr = NA_real_, scipy_pass = NA,
        r_in_verified_domain = r$r_in_verified_domain_bool,
        bucket = NA_character_, stringsAsFactors = FALSE)
}
resultTbl <- do.call(rbind, resultRows)

cat("\n      ===================== v154 VERDICT =====================\n")
if (is.null(resultTbl) || nrow(resultTbl) == 0) {
    cat("      No cells were judged (empty grid or Praat probe returned nothing).\n")
} else {
    accTbl <- resultTbl[resultTbl$population == "acceptance", ]
    charTbl <- resultTbl[resultTbl$population == "characterization", ]
    nAcc <- nrow(accTbl); nAccPass <- sum(accTbl$pass, na.rm = TRUE)
    cat(sprintf("      TWO POPULATIONS -- read both lines; neither substitutes for the other:\n"))
    cat(sprintf("      ACCEPTANCE:       %d/%d cells pass the standard rule against the grid (rel<=1e-9 OR abs<=1e-12).\n",
                nAccPass, nAcc))
    cat(sprintf("      CHARACTERIZATION: %d cells excluded from that tally (grid p < %.0e -- the absolute limb\n",
                nrow(charTbl), CHAR_FLOOR))
    cat("                         cannot fail there; see the measured envelope below instead of a pass count.\n")
    for (kind in c("forward", "quantile")) {
        sub <- accTbl[accTbl$kind == kind, ]
        if (nrow(sub) == 0) next
        cat(sprintf("      %s (acceptance): %d/%d pass\n", kind, sum(sub$pass, na.rm = TRUE), nrow(sub)))
    }
    cat("\n      R and scipy, AS COMPARISON EVIDENCE ONLY (never the acceptance oracle here):\n")
    for (kind in c("forward", "quantile")) {
        sub <- accTbl[accTbl$kind == kind, ]
        if (nrow(sub) == 0) next
        cat(sprintf("        %s: R %d/%d pass grid's rule", kind, sum(sub$r_pass, na.rm = TRUE), sum(is.finite(sub$r_pass))))
        if (kind == "forward") cat(sprintf("; scipy %d/%d pass grid's rule", sum(sub$scipy_pass, na.rm = TRUE), sum(is.finite(sub$scipy_pass))))
        cat("\n")
    }

    failing <- accTbl[!accTbl$pass & is.finite(accTbl$pass), ]
    if (nrow(failing) > 0) {
        cat(sprintf("\n      %d FAILING acceptance-population cells (worst 40 by relative error):\n", nrow(failing)))
        failing <- failing[order(-ifelse(is.finite(failing$relErr), failing$relErr, 0)), ]
        for (i in seq_len(min(40, nrow(failing)))) {
            fr <- failing[i, ]
            cat(sprintf("        %s k=%d df=%g target=%.3e oracle(grid)=%.6e port=%.6e absErr=%.3e relErr=%.3e  [R=%.6e scipy=%s]\n",
                        fr$kind, fr$k, fr$df, fr$target, fr$oracle, fr$port,
                        fr$absErr, fr$relErr, fr$r_value,
                        if (is.na(fr$scipy_value)) "n/a" else sprintf("%.6e", fr$scipy_value)))
        }
    } else {
        cat("\n      No failing cells in the acceptance population.\n")
    }

    # Per-cell evidence to disk. A verdict whose per-cell numbers exist only in
    # a scrolled terminal cannot be audited, and every cell below is the input
    # to the oracle-arbitration step (walkthrough/kit/audit/arbitrate_v154.R).
    outDir <- repo_path("walkthrough", "kit", "audit")
    dir.create(outDir, showWarnings = FALSE, recursive = TRUE)
    outFile <- file.path(outDir, "v154_cells.tsv")
    write.table(resultTbl, outFile, sep = "\t", row.names = FALSE,
                quote = FALSE, na = "NA")
    cat(sprintf("\n      per-cell evidence written: %s (%d rows: %d acceptance, %d characterization)\n",
                outFile, nrow(resultTbl), nAcc, nrow(charTbl)))

    # bucket breakdown for ACCEPTANCE forward cells only.
    fwdAcc <- accTbl[accTbl$kind == "forward" & !is.na(accTbl$bucket), ]
    if (nrow(fwdAcc) > 0) {
        cat("\n      forward (acceptance population), by p-magnitude bucket:\n")
        for (bk in buckets) {
            s3 <- fwdAcc[fwdAcc$bucket == bk, ]
            if (nrow(s3) == 0) next
            cat(sprintf("        %-14s n=%3d fail=%2d worst relErr=%.3e\n",
                        bk, nrow(s3), sum(!s3$pass), max(s3$relErr[is.finite(s3$relErr)], 0)))
        }
    }

    # CHARACTERIZATION population -- MEASURED envelope, per bucket, no
    # pass/fail column at all (ruling point 3: structure, not a comment).
    if (nrow(charTbl) > 0) {
        cat(sprintf("\n      CHARACTERIZATION population (%d cells, grid p < %.0e -- excluded from the tally above):\n",
                    nrow(charTbl), CHAR_FLOOR))
        for (bk in buckets) {
            s4 <- charTbl[charTbl$bucket == bk, ]
            if (nrow(s4) == 0) next
            relFin <- s4$relErr[is.finite(s4$relErr)]
            cat(sprintf("        %-14s n=%3d  port relErr vs grid: min=%.3e max=%.3e  [R relErr: min=%.3e max=%.3e]\n",
                        bk, nrow(s4),
                        if (length(relFin)) min(relFin) else NA, if (length(relFin)) max(relFin) else NA,
                        suppressWarnings(min(s4$r_relErr[is.finite(s4$r_relErr)])),
                        suppressWarnings(max(s4$r_relErr[is.finite(s4$r_relErr)]))))
        }
        cat("        (These 9-and-counting cells assert nothing as PASS/FAIL -- read the envelope above,\n")
        cat("         not a fail count, when citing the far tail.)\n")
    } else {
        cat("\n      CHARACTERIZATION population: empty (no grid row currently sits below the absolute floor).\n")
    }
}
cat("      ==========================================================\n\n")

} # canDrive
