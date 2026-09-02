#!/usr/bin/env Rscript
# ============================================================================
# arbitrate_v154.R -- deciding who is wrong when the port and R disagree
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES
#
# v154 judges our studentized-range replacement cell by cell. Where R's
# ptukey is verified accurate for a cell, v154 uses R as the oracle; elsewhere
# it uses the arbitrary-precision grid. Its quantile cells inherit that
# choice: where the cell is in R's verified domain, v154 compares our inverse
# against R's qtukey.
#
# That inheritance is the thing this script tests. R's verified domain was
# established for ptukey, the FORWARD function. qtukey is a different
# function, and R's own qtukey does not invert R's own ptukey to better than
# about 4e-8 at ordinary alpha. So a quantile cell that "fails against R"
# may be a cell where R is the inaccurate party.
#
# The arbiter is neither party. srange_reference.tsv already carries an
# arbitrary-precision q for every quantile row, solved by mpmath directly
# from the range/chi definition with recorded convergence evidence. This
# script puts the port's answer and R's answer side by side against it.
#
# WHAT A VERDICT MEANS
#
#   PORT_CLOSER  the port is nearer the arbitrary-precision answer than R is.
#                A v154 failure on this cell is R's error, not ours.
#   R_CLOSER     R is nearer. The port has a real defect on this cell.
#   TIE          the two are within a factor of two of each other.
#
# HOW TO RUN
#
#   Rscript validate/v154_srange_against_reference.R     # writes the cells
#   Rscript walkthrough/kit/audit/arbitrate_v154.R
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

here    <- dirname(normalizePath(sub("^--file=", "",
             commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])))
repoRoot <- normalizePath(file.path(here, "..", "..", ".."))

cellsFile <- file.path(repoRoot, "walkthrough", "kit", "audit", "v154_cells.tsv")
refFile   <- file.path(repoRoot, "walkthrough", "kit", "reference",
                       "srange_reference.tsv")

for (f in c(cellsFile, refFile)) {
    if (!file.exists(f)) {
        cat(sprintf("arbitrate_v154: missing input %s\n", f))
        cat("Run validate/v154_srange_against_reference.R first.\n")
        quit(status = 1)
    }
}

cells <- read.delim(cellsFile, stringsAsFactors = FALSE)
ref   <- read.delim(refFile, comment.char = "#", stringsAsFactors = FALSE)

qt <- cells[cells$kind == "quantile", ]
fw <- cells[cells$kind == "forward", ]
if (nrow(qt) == 0) { cat("arbitrate_v154: no quantile cells.\n"); quit(status = 1) }

key <- function(k, df, p) sprintf("%d|%g|%.10e", k, df, p)
ref$.key <- key(ref$k, ref$df, ref$p_target)
qt$.key  <- key(qt$k,  qt$df,  qt$target)

out <- data.frame()
for (i in seq_len(nrow(qt))) {
    r  <- qt[i, ]
    rr <- ref[ref$.key == r$.key, ]
    if (nrow(rr) != 1) next
    if (!isTRUE(as.logical(rr$mpmath_converged[1]))) next

    arbiter <- as.numeric(rr$q[1])            # mpmath-solved q, the arbiter
    portQ   <- as.numeric(r$port)
    rQ      <- tryCatch(qtukey(r$target, nmeans = r$k, df = r$df,
                               lower.tail = FALSE),
                        error = function(e) NA_real_)

    dPort <- abs(portQ - arbiter) / abs(arbiter)
    dR    <- abs(rQ    - arbiter) / abs(arbiter)

    verdict <- if (!is.finite(dPort) || !is.finite(dR)) "INDETERMINATE"
               else if (dPort < dR / 2) "PORT_CLOSER"
               else if (dR < dPort / 2) "R_CLOSER"
               else "TIE"

    out <- rbind(out, data.frame(
        k = r$k, df = r$df, alpha = r$target,
        oracle_source = r$oracle_source, v154_pass = r$pass,
        arbiter_q = arbiter, port_q = portQ, r_q = rQ,
        port_relerr_vs_arbiter = dPort, r_relerr_vs_arbiter = dR,
        verdict = verdict, stringsAsFactors = FALSE))
}

# ---- forward cells -------------------------------------------------------
# The forward arbiter is mpmath_p, the same grid's arbitrary-precision
# probability. scipy_p is carried alongside as an independent corroboration
# of the arbiter itself: where scipy and mpmath agree, the arbiter is not
# resting on a single implementation.
fwOut <- data.frame()
for (i in seq_len(nrow(fw))) {
    r  <- fw[i, ]
    rr <- ref[ref$.key == key(r$k, r$df, r$target), ]
    if (nrow(rr) < 1) next
    rr <- rr[1, ]
    if (!isTRUE(as.logical(rr$mpmath_converged))) next

    arbiter <- as.numeric(rr$mpmath_p)
    if (!is.finite(arbiter) || arbiter == 0) next
    portP  <- as.numeric(r$port)
    rP     <- as.numeric(r$oracle)
    scipyP <- suppressWarnings(as.numeric(rr$scipy_p))

    dPort  <- abs(portP - arbiter) / abs(arbiter)
    dR     <- abs(rP    - arbiter) / abs(arbiter)
    dScipy <- if (is.finite(scipyP)) abs(scipyP - arbiter) / abs(arbiter) else NA_real_

    verdict <- if (!is.finite(dPort) || !is.finite(dR)) "INDETERMINATE"
               else if (dPort < dR / 2) "PORT_CLOSER"
               else if (dR < dPort / 2) "R_CLOSER"
               else "TIE"

    fwOut <- rbind(fwOut, data.frame(
        k = r$k, df = r$df, p_target = r$target,
        oracle_source = r$oracle_source, v154_pass = r$pass,
        arbiter_p = arbiter, port_p = portP, r_p = rP, scipy_p = scipyP,
        port_relerr_vs_arbiter = dPort, r_relerr_vs_arbiter = dR,
        scipy_relerr_vs_arbiter = dScipy,
        verdict = verdict, stringsAsFactors = FALSE))
}

if (nrow(fwOut) > 0) {
    fwFile <- file.path(repoRoot, "walkthrough", "kit", "audit",
                        "v154_arbitration_forward.tsv")
    write.table(fwOut, fwFile, sep = "\t", row.names = FALSE, quote = FALSE)
    cat("\n  ============ v154 forward arbitration ============\n")
    cat(sprintf("  %d forward cells arbitrated against the mpmath grid.\n",
                nrow(fwOut)))
    for (v in c("PORT_CLOSER", "R_CLOSER", "TIE", "INDETERMINATE")) {
        n <- sum(fwOut$verdict == v)
        if (n > 0) cat(sprintf("    %-14s %d\n", v, n))
    }
    ffail <- fwOut[!as.logical(fwOut$v154_pass), ]
    if (nrow(ffail) > 0) {
        cat(sprintf("\n  The %d forward cells v154 marks FAILING:\n", nrow(ffail)))
        cat("    k   df    p        port err     R err        scipy err    verdict\n")
        for (i in seq_len(nrow(ffail))) {
            f <- ffail[i, ]
            cat(sprintf("    %-3d %-5g %.0e  %.3e   %.3e   %.3e   %s\n",
                        f$k, f$df, f$p_target, f$port_relerr_vs_arbiter,
                        f$r_relerr_vs_arbiter, f$scipy_relerr_vs_arbiter,
                        f$verdict))
        }
    }
    cat(sprintf("\n  written: %s\n", fwFile))
    cat("  ==================================================\n")
}

if (nrow(out) == 0) {
    cat("arbitrate_v154: no quantile cell could be matched to a converged\n")
    cat("reference row. Nothing arbitrated.\n")
    quit(status = 1)
}

outFile <- file.path(repoRoot, "walkthrough", "kit", "audit",
                     "v154_arbitration.tsv")
write.table(out, outFile, sep = "\t", row.names = FALSE, quote = FALSE)

cat("\n  ============ v154 quantile arbitration ============\n")
cat(sprintf("  %d quantile cells arbitrated against the mpmath grid.\n", nrow(out)))
for (v in c("PORT_CLOSER", "R_CLOSER", "TIE", "INDETERMINATE")) {
    n <- sum(out$verdict == v)
    if (n > 0) cat(sprintf("    %-14s %d\n", v, n))
}

fail <- out[!as.logical(out$v154_pass), ]
if (nrow(fail) > 0) {
    cat(sprintf("\n  The %d cells v154 marks FAILING:\n", nrow(fail)))
    cat("    k   df   alpha     port err     R err       verdict\n")
    fail <- fail[order(-fail$port_relerr_vs_arbiter), ]
    for (i in seq_len(nrow(fail))) {
        f <- fail[i, ]
        cat(sprintf("    %-3d %-4g %.0e  %.3e   %.3e   %s\n",
                    f$k, f$df, f$alpha, f$port_relerr_vs_arbiter,
                    f$r_relerr_vs_arbiter, f$verdict))
    }
}
cat(sprintf("\n  written: %s\n", outFile))
cat("  ===================================================\n\n")
