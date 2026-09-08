#!/usr/bin/env Rscript
# ============================================================================
# v167 -- DUPLICATE-BODY check: near-identical procedure bodies
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. Fable's ORDER_DRY_LINT_AND_AUDIT_FIXES, part A, check
# A1: walk plugin_EML_StatsGraphs/{stats,graphs,scripts}/*.praat and
# setup.praat at RUN TIME, extract every `procedure ... endproc` body, and
# flag pairs of DISTINCT-NAMED procedures whose normalised bodies are
# near-identical by 6-token-shingle Jaccard similarity: >= 0.80 is a FAIL
# (unless the pair is named in the allowlist), 0.50-0.80 is reported as
# informational only.
#
# THE NORMALISATION IS NOT RE-DESIGNED HERE. validate/tools/duplicate_
# bodies.py copies norm()/shingles()/the Jaccard arithmetic verbatim from
# /tmp/census_procedures.py -- the audit's own script -- including its
# comment-stripping rule (a line starting with # or ; is blank; an inline
# "# ..." tail is dropped via code.split("#", 1)). This file drives that
# script and turns its output into checks; it does not reimplement it.
#
# WHY THIS IS EXPECTED TO BE RED TODAY. AUDIT_PROCEDURES.md section 1 names
# concrete duplicated procedures already shipped (eml_wciW2 vs.
# eml_hlTwoSampleW; eml_wciZeroin vs. eml_hlZeroin; among others). Those are
# real, committed duplicates that later waves are ordered to fix -- being
# red here IS the correct, intended signal for this check on today's tree,
# not a defect in the check. The allowlist (validate/canon/duplicate_
# allowlist.tsv) ships EMPTY and stays that way until a pair is deliberately
# reviewed and accepted as NOT worth merging; nothing found by this run is
# added to it by this file.
#
# THE SELF-TEST (below, before the tree scan) is the red demo: a fixture
# under validate/fixtures/duplicate_bodies/ holds two procedures with the
# same 40+-token computation, differing only in a numeric literal and local
# variable names -- exactly what the normalisation is supposed to see
# through. The python tool is run against JUST that fixture directory (a
# separate invocation from the main tree scan, never mixed into it) and the
# self-test asserts the pair comes back FAIL. If a future edit silently
# broke detection (a botched regex, an accidentally-inverted threshold), the
# self-test would go red and the tree scan would go misleadingly green --
# so the self-test is what stands between "no real duplicates" and "the
# checker stopped checking".
#
# HOW TO RUN
#
#     Rscript validate/v167_duplicate_bodies.R
#
# Input: the source tree only (validate/tools/duplicate_bodies.py, the
# fixture, the allowlist, and plugin_EML_StatsGraphs/). No Praat needed.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v167"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

py <- Sys.which("python3")
if (!nzchar(py) && file.exists("/usr/bin/python3")) py <- "/usr/bin/python3"
have_py <- nzchar(py) && file.exists(py)
check_true(V, sprintf("python3 is available to drive duplicate_bodies.py (found %s)",
                      if (have_py) py else "none"), have_py)

TOOL <- repo_path("validate", "tools", "duplicate_bodies.py")
check_true(V, sprintf("duplicate_bodies.py exists (%s)", TOOL), file.exists(TOOL))

ALLOWLIST <- repo_path("validate", "canon", "duplicate_allowlist.tsv")
check_true(V, sprintf("the allowlist exists (%s)", ALLOWLIST), file.exists(ALLOWLIST))

# ---------------------------------------------------------------------------
# run_dup_tool -- invoke duplicate_bodies.py against ROOT with ALLOW as its
# allowlist and parse the tab-separated LEVEL/jaccard/proc_a/loc_a/proc_b/
# loc_b lines it prints. Returns a data.frame (possibly zero-row) plus the
# raw exit status / lines for diagnostics.
# ---------------------------------------------------------------------------
run_dup_tool <- function(root, allow) {
    out <- suppressWarnings(system2(py, c(shQuote(TOOL), shQuote(root), shQuote(allow)),
                                    stdout = TRUE, stderr = TRUE))
    st <- attr(out, "status"); st <- if (is.null(st)) 0L else as.integer(st)
    lines <- out[grepl("^(FAIL|ALLOW|INFO)\t", out)]
    if (!length(lines)) {
        df <- data.frame(level = character(0), jaccard = numeric(0),
                         proc_a = character(0), loc_a = character(0),
                         proc_b = character(0), loc_b = character(0),
                         stringsAsFactors = FALSE)
    } else {
        parts <- strsplit(lines, "\t", fixed = TRUE)
        parts <- lapply(parts, function(p) { length(p) <- 6; ifelse(is.na(p), "", p) })
        m <- do.call(rbind, parts)
        df <- data.frame(level = m[, 1], jaccard = suppressWarnings(as.numeric(m[, 2])),
                         proc_a = m[, 3], loc_a = m[, 4], proc_b = m[, 5], loc_b = m[, 6],
                         stringsAsFactors = FALSE)
    }
    list(status = st, raw = out, df = df)
}

if (have_py && file.exists(TOOL) && file.exists(ALLOWLIST)) {

# ---------------------------------------------------------------------------
# SELF-TEST (red demo): run the tool against the fixture directory alone --
# NOT the main plugin tree -- and prove it flags the known duplicate pair.
# A separate, permissive allowlist path (one that does not exist) is passed
# so the fixture's pair cannot be hidden by an allowlist entry meant for the
# real tree.
# ---------------------------------------------------------------------------
FIXTURE_DIR <- repo_path("validate", "fixtures", "duplicate_bodies")
check_true(V, sprintf("the duplicate-bodies fixture directory exists (%s)", FIXTURE_DIR),
           dir.exists(FIXTURE_DIR))

if (dir.exists(FIXTURE_DIR)) {
    selftest <- run_dup_tool(FIXTURE_DIR, file.path(tempdir(), "no-such-allowlist.tsv"))
    check_true(V, "[self-test] the tool ran against the fixture with no R error",
               selftest$status == 0L)
    fx <- selftest$df[selftest$df$level == "FAIL" &
                      ((selftest$df$proc_a == "fixtureAlphaCompute" &
                        selftest$df$proc_b == "fixtureBetaCompute") |
                       (selftest$df$proc_a == "fixtureBetaCompute" &
                        selftest$df$proc_b == "fixtureAlphaCompute")), , drop = FALSE]
    check_true(V,
        sprintf("[self-test, RED DEMO] the fixture's near-identical pair (fixtureAlphaCompute / fixtureBetaCompute) IS flagged FAIL (%s)",
                if (nrow(fx)) sprintf("jaccard=%.4f", fx$jaccard[1]) else "not found -- detection is silently broken"),
        nrow(fx) >= 1)
    if (!nrow(fx)) {
        cat("      v167 self-test raw tool output:\n")
        cat(paste("       ", utils::tail(selftest$raw, 20)), sep = "\n")
    }
} else {
    check_true(V, "[self-test, RED DEMO] the fixture pair is flagged FAIL", FALSE)
}

# ---------------------------------------------------------------------------
# THE REAL SCAN: plugin_EML_StatsGraphs/, the empty allowlist. This is
# EXPECTED to surface real FAIL pairs today (see file header) -- that is
# the work order the audit names, not a bug in this checker.
# ---------------------------------------------------------------------------
plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)
check_true(V, sprintf("the plugin root exists (%s)", plug), dir.exists(plug))

if (dir.exists(plug)) {
    scan <- run_dup_tool(plug, ALLOWLIST)
    check_true(V, "the tree scan ran with no R error", scan$status == 0L)

    if (scan$status == 0L) {
        d <- scan$df
        fails <- d[d$level == "FAIL", , drop = FALSE]
        allows <- d[d$level == "ALLOW", , drop = FALSE]
        infos <- d[d$level == "INFO", , drop = FALSE]

        # One check per pair examined, so the tally reflects how many pairs
        # were compared, not just a single pass/fail for the whole scan --
        # a silent drop of ALL but one FAIL pair would otherwise still read
        # as "1 check, 1 failed" and look no different from a clean near-miss.
        if (nrow(fails)) {
            for (i in seq_len(nrow(fails))) {
                r <- fails[i, ]
                check_true(V,
                    sprintf("no near-duplicate pair at or above 0.80 Jaccard: %s (%s) vs %s (%s), jaccard=%.4f",
                            r$proc_a, r$loc_a, r$proc_b, r$loc_b, r$jaccard),
                    FALSE)
            }
        } else {
            check_true(V, "no near-duplicate pair at or above 0.80 Jaccard was found in the tree",
                       TRUE)
        }

        if (nrow(allows)) {
            check_true(V,
                sprintf("%d pair(s) at or above 0.80 Jaccard are covered by the allowlist (informational, not a failure)",
                        nrow(allows)), TRUE)
            for (i in seq_len(nrow(allows))) {
                r <- allows[i, ]
                cat(sprintf("      ALLOWLISTED  jaccard=%.4f  %s (%s)  <->  %s (%s)\n",
                            r$jaccard, r$proc_a, r$loc_a, r$proc_b, r$loc_b))
            }
        }

        # INFO pairs (0.50-0.80) are reported for a human to look at, never
        # as checks -- the governance order is explicit that this band is
        # informational, not a failure condition.
        cat(sprintf("\n      v167: %d INFO pair(s) in the 0.50-0.80 Jaccard band (informational, not failures):\n",
                    nrow(infos)))
        if (nrow(infos)) {
            for (i in seq_len(nrow(infos))) {
                r <- infos[i, ]
                cat(sprintf("      INFO  jaccard=%.4f  %s (%s)  <->  %s (%s)\n",
                            r$jaccard, r$proc_a, r$loc_a, r$proc_b, r$loc_b))
            }
        }
        cat(sprintf("      v167: %d FAIL pair(s), %d ALLOW pair(s), %d INFO pair(s) total.\n",
                    nrow(fails), nrow(allows), nrow(infos)))
    } else {
        cat("      v167 tree-scan raw tool output:\n")
        cat(paste("       ", utils::tail(scan$raw, 30)), sep = "\n")
    }
}

}

if (!exists("EML_SUITE")) {
    eml_report("v167 duplicate-body check: near-identical procedure bodies")
    eml_exit()
}
