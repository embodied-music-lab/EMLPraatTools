#!/usr/bin/env Rscript
# ============================================================================
# recompute_r_verified_domain.R -- the ONE place r_in_verified_domain is
# computed from srange_reference.tsv's own stored columns.
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR. RULING_PORT_ACCEPTANCE_2026-09-02.md, point 5a: the grid
# file (srange_reference.tsv) carries a recorded r_in_verified_domain column
# per row, written once at build time by build_srange_reference.py's
# r_in_domain(). validate/v154_srange_against_reference.R previously
# recomputed a SECOND copy of that flag at run time by re-querying scipy
# live and comparing it against the grid's r_ptukey_p -- and that live copy
# disagreed with the recorded copy on 3 of 130 rows, with v154 silently
# preferring the live one. A recorded flag and a live re-check that can
# disagree are not one flag; they are two, and the ruling calls that a canon
# violation. This file ends the duplication: there is now exactly one
# formula for the flag, defined here, and v154 calls it against the grid's
# OWN stored columns rather than querying anything live.
#
# THE FORMULA, identical to r_in_domain() in build_srange_reference.py and
# to R_verified_domain.tsv's own header ("PASS if abs(scipy-R) <= 1e-12 OR
# abs(scipy-R)/abs(scipy) <= 1e-9" -- scipy in the denominator, not R):
#
#   absErr = abs(scipy_p - r_ptukey_p)
#   relErr = absErr / abs(scipy_p)   [if scipy_p != 0, else relErr = absErr]
#   in_domain = is.finite(scipy_p) & is.finite(r_ptukey_p) &
#               (absErr <= 1e-12 | relErr <= 1e-9)
#
# WHY THE PRIOR LIVE CHECK DRIFTED ON 3 ROWS, MEASURED (see this file's own
# comparison below, and the report that shipped alongside this change for
# the full table): all 3 are forward rows at k in {2,5,10}, df=3,
# p_target=1e-10, where R's stats::ptukey underflows to EXACTLY 0 at that
# (k,df,q) rather than resolving the true ~1e-10 tail. With r_ptukey_p==0,
# the prior live check's denominator convention put R (not scipy) on the
# bottom, so relErr fell back to plain absErr (~1.2e-10, 6.2e-11, 6.2e-11)
# under a 1e-9 threshold -- and PASSED, certifying "R is trustworthy here"
# at three points where R reports exactly zero against a true probability
# near 1e-10, i.e. R is wrong by essentially 100% of its value. The
# recorded flag (denominator = scipy, matching R_verified_domain.tsv's own
# stated rule) correctly says False at all three. This was a bug in the
# live re-check's zero-handling, not evidence that the recorded flag needed
# correcting -- confirmed by recomputing the recorded flag from the grid's
# own stored scipy_p/r_ptukey_p columns under the CORRECT (scipy-denominator)
# formula: 0/130 rows disagree with what is on file.
#
# USAGE.
#   - Sourced (as v154 does): defines recompute_r_verified_domain(scipy_p,
#     r_ptukey_p), a vectorized pure function, and does nothing else --
#     guarded by sys.nframe() so sourcing never re-runs the CLI check below.
#   - Run directly (`Rscript recompute_r_verified_domain.R [grid.tsv]`):
#     reads the grid (default: srange_reference.tsv beside this file),
#     recomputes the flag for every row from its own stored columns, prints
#     a summary, and exits 1 with the full drifted-row table if recorded and
#     recomputed disagree anywhere -- 0 on a clean grid. This is what v154
#     also does at runtime; running this file by hand reproduces the same
#     check the validator applies, standalone.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

recompute_r_verified_domain <- function(scipy_p, r_ptukey_p) {
    absErr <- abs(scipy_p - r_ptukey_p)
    relErr <- ifelse(scipy_p != 0, absErr / abs(scipy_p), absErr)
    is.finite(scipy_p) & is.finite(r_ptukey_p) &
        (absErr <= 1e-12 | (is.finite(relErr) & relErr <= 1e-9))
}

if (sys.nframe() == 0) {
    argv <- commandArgs(trailingOnly = TRUE)
    gridPath <- if (length(argv) >= 1) argv[1] else file.path(dirname(sub("^--file=", "",
        commandArgs(FALSE)[grep("^--file=", commandArgs(FALSE))])), "srange_reference.tsv")

    lines <- readLines(gridPath)
    lines <- lines[!grepl("^#", lines)]
    grid <- read.delim(text = paste(lines, collapse = "\n"), stringsAsFactors = FALSE)

    recordedBool <- grid$r_in_verified_domain %in% c("True", "TRUE", "true", "1")
    recomputedBool <- recompute_r_verified_domain(grid$scipy_p, grid$r_ptukey_p)
    drift <- which(recordedBool != recomputedBool)

    cat(sprintf("recompute_r_verified_domain: %d/%d rows agree (recorded == recomputed), %d drift\n",
                sum(recordedBool == recomputedBool), nrow(grid), length(drift)))

    if (length(drift) > 0) {
        cat("DRIFTED ROWS (recorded r_in_verified_domain != recomputed from scipy_p/r_ptukey_p):\n")
        print(data.frame(
            type = grid$type[drift], k = grid$k[drift], df = grid$df[drift],
            p_target = grid$p_target[drift], q = grid$q[drift],
            scipy_p = grid$scipy_p[drift], r_ptukey_p = grid$r_ptukey_p[drift],
            recorded = recordedBool[drift], recomputed = recomputedBool[drift]
        ))
        quit(status = 1)
    } else {
        quit(status = 0)
    }
}
