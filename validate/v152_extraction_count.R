#!/usr/bin/env Rscript
# ============================================================================
# v152 -- one extraction per group per case (@eml_getGroupData call count)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. RULING_CONSOLIDATED_KERNELS_2026-09-01.md §5,
# ONE-EXTRACTION-PER-CASE: "one analysis per case AND ONE EXTRACTION per
# case." The defect was DATA EXTRACTION, not computation -- @eml_getGroupData
# (a full interpreted re-scan of the whole table, normalising every row's
# group label before filtering) was called far more than once per group
# inside a single ANOVA case: once in a size-check pass, again in the raw-
# score pass, again in the shift-corrected pass, again inside @emlTukeyHSD's
# own descriptives pass, and twice per pair again inside @emlTukeyHSD's
# pairwise loop. MEASURED CONSEQUENCE: a 189-row ANOVA took about 4 seconds
# through the public route; an 18,009-row one had not returned after twelve
# minutes.
#
# THIS FILE DOES NOT RE-DERIVE ANY STATISTIC. It instruments the plugin's
# OWN @eml_getGroupData (a one-line counter added at the top of the
# procedure body, nothing else touched) and counts how many times a single
# case invokes it, for a synthetic table with a known number of groups. The
# bound asserted is Fable's own acceptance line: "one ANOVA case performs at
# most one extraction pass per group."
#
# THE BOUND IS GATED ON @emlOneWayAnova CALLED DIRECTLY -- the kernel this
# session's file boundary (eml-inferential.praat) owns and fixed, and where
# the law is fully met: exactly one @eml_getGroupData call per group, shared
# by the ANOVA pass and the Tukey pairwise pass alike. The FULL public-route
# orchestrator, @emlRunAnovaAnalysis, is ALSO measured below, but only as an
# informational attestation, not a pass/fail gate: it calls onward into
# @emlReportAnovaComparison in graphs/eml-annotation-procedures.praat, a file
# outside this session's file boundary, which re-runs the whole ANOVA a
# second time and carries its own separate, unfixed extraction loops. See
# the comment above that section for the full account.
#
# METHOD. The counter is added to a TEMPORARY COPY of
# plugin_EML_StatsGraphs/stats/eml-extract.praat (the repo file this session
# edited), installed over the live plugin at ~/.praat-dir/plugin_EML_Stats-
# Graphs/ alongside the repo's current eml-inferential.praat and eml-
# analysis.praat -- the same install-then-run step CLAUDE.md's Praat section
# requires before any measurement, and the same "public route" entry point
# (`include ~/.praat-dir/plugin_EML_StatsGraphs/scripts/eml-lib-user.praat`)
# RUN_ME_FIRST.praat itself uses. The three ORIGINAL installed files are
# backed up first and restored afterward NO MATTER HOW THE PROBE ENDS (R's
# on.exit, not a code path that can be skipped by an error or a timeout) --
# this script must never leave the user's installed plugin instrumented or
# stale.
#
# WHY THE BOUND CANNOT BE MET BY ACCIDENT. A cache that leaked one case's
# data into another's would UNDER-count real extractions, not over-count --
# so a bound this script proves ("no more calls than groups") is the
# correct-direction test for the failure mode RULING_ONE_RUN_PER_CASE rev 2
# names ("you must show how you know it cannot serve one case's data to
# another"): each probed case uses a FRESH table object and a FRESH group
# count, so if the plugin ever served a smaller case extra, stale, higher-
# indexed vectors left by a larger PRIOR case, the corresponding cell values
# below would not simply be slow -- the F, p and Cohen's d values checked
# against v19/v09's own independent computation would be wrong. They are not:
# see the value-identity note at the foot of this file.
#
#     Rscript validate/v152_extraction_count.R
#
# Input:  none (synthetic tables, built in the probe script itself)
# Output: none persisted; this is a call-count and value-identity probe
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V <- "v152"

plug <- Sys.getenv("EML_INSTALLED_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- path.expand("~/.praat-dir/plugin_EML_StatsGraphs")

praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(Sys.which("praat6630"), Sys.which("praat_barren"), Sys.which("praat"))) {
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
barrel <- file.path(plug, "scripts", "eml-lib-user.praat")
canDrive <- pvnum >= 6630 && file.exists(barrel)

if (!canDrive) {
    reason <- if (!file.exists(barrel)) {
        paste("installed plugin barrel not found at", barrel)
    } else {
        paste0("needs Praat >= 6.6.30; found ", if (is.na(pv)) "none" else pv)
    }
    cat(paste0("      SKIP: v152 ", reason, "\n"))
    check_true(V, sprintf("a Praat at or above the plugin's floor, with an installed plugin, is available (%s)",
                           if (is.na(pv)) "none" else pv), FALSE)
} else {

extractSrc  <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-extract.praat")
infSrc      <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-inferential.praat")
anaSrc      <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-analysis.praat")
stopifnot(file.exists(extractSrc), file.exists(infSrc), file.exists(anaSrc))

extractLines <- readLines(extractSrc, warn = FALSE)
sig <- "procedure eml_getGroupData: .tableId, .dataCol$, .groupCol$, .groupLabel$"
hit <- which(extractLines == sig)
if (length(hit) != 1) {
    cat(sprintf("      SKIP: v152 expected exactly one @eml_getGroupData signature line, found %d\n", length(hit)))
    check_true(V, "found exactly one @eml_getGroupData definition to instrument", FALSE)
} else {

instrumented <- append(extractLines,
    "    emlProbeExtractionCount = emlProbeExtractionCount + 1",
    after = hit)

work <- file.path(tempdir(), "v152")
unlink(work, recursive = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)

installedStats <- file.path(plug, "stats")
backup <- file.path(work, "backup")
dir.create(backup, showWarnings = FALSE, recursive = TRUE)
targets <- c("eml-extract.praat", "eml-inferential.praat", "eml-analysis.praat")
for (f in targets) {
    src <- file.path(installedStats, f)
    if (file.exists(src)) file.copy(src, file.path(backup, f), overwrite = TRUE)
}
restored <- FALSE
restore_installed <- function() {
    if (restored) return(invisible(NULL))
    for (f in targets) {
        b <- file.path(backup, f)
        if (file.exists(b)) file.copy(b, file.path(installedStats, f), overwrite = TRUE)
    }
    restored <<- TRUE
}
on.exit(restore_installed(), add = TRUE)

# Install the instrumented extractor and the repo's current copies of the
# two files this session edited -- exactly CLAUDE.md's "edit the repo, then
# re-copy before testing" step, done here so the R suite carries its own
# evidence instead of depending on a prior manual cp.
writeLines(instrumented, file.path(installedStats, "eml-extract.praat"))
file.copy(infSrc, file.path(installedStats, "eml-inferential.praat"), overwrite = TRUE)
file.copy(anaSrc, file.path(installedStats, "eml-analysis.praat"), overwrite = TRUE)

run_praat <- function(lines, tag, timeoutSec = 120) {
    probe_path <- file.path(work, paste0("v152-", tag, ".praat"))
    writeLines(lines, probe_path)
    out <- suppressWarnings(system2("timeout",
        c(as.character(timeoutSec), "env", "-u", "DISPLAY", shQuote(praat), "--run", shQuote(probe_path)),
        stdout = TRUE, stderr = TRUE))
    out
}

# ----------------------------------------------------------------------------
# Builds a synthetic unbalanced table with .nGroups groups (A, B, C, ...),
# group sizes 6, 7, 8, ... so no two groups are the same size, and runs
# @emlRunAnovaAnalysis once with the given .doTukey. Prints
# "COUNT <calls> <nGroups> <error$>".
# ----------------------------------------------------------------------------
build_table_lines <- function(nGroups) {
    letters6 <- LETTERS[seq_len(nGroups)]
    rowLines <- c('Create Table with column names: "t", 0, "value group"')
    r <- 0
    set.seed(1)
    for (gi in seq_len(nGroups)) {
        n <- 5 + gi
        vals <- round(rnorm(n, mean = gi * 3, sd = 1.5), 4)
        for (v in vals) {
            r <- r + 1
            rowLines <- c(rowLines,
                sprintf('Insert row: %d', r),
                sprintf('Set numeric value: %d, "value", %s', r, format(v, digits = 15)),
                sprintf('Set string value: %d, "group", "%s"', r, letters6[gi]))
        }
    }
    c(rowLines, "tid = selected(\"Table\")")
}

# Drives @emlOneWayAnova DIRECTLY -- the kernel this session's file boundary
# (eml-inferential.praat) actually owns and fixed. This is the bound the
# ruling's law is gated on here: ONE @eml_getGroupData call per group, full
# stop, whether or not Tukey pairwise output is requested (the Tukey branch
# reads the SAME cache the ANOVA pass built, never re-extracts).
build_case <- function(nGroups, doTukey) {
    c(build_table_lines(nGroups),
      "emlProbeExtractionCount = 0",
      sprintf("@emlOneWayAnova: tid, \"value\", \"group\", %d", doTukey),
      "appendInfoLine: \"COUNT \", emlProbeExtractionCount, \" \", tid, \" <\", emlOneWayAnova.error$, \">\"",
      "removeObject: tid")
}

# Drives @emlRunAnovaAnalysis -- the FULL public-route orchestrator
# (eml-analysis.praat, also in this session's file boundary and also fixed
# internally). This is measured and reported, not gated: it calls onward
# into @emlReportAnovaComparison (graphs/eml-annotation-procedures.praat),
# a file OUTSIDE this session's file boundary, which re-runs
# @emlOneWayAnova a second time to build report text and carries its own,
# separate, unfixed per-pair @eml_getGroupData loops. See the note printed
# below the results table.
build_full_case <- function(nGroups, doTukey) {
    c(build_table_lines(nGroups),
      "emlProbeExtractionCount = 0",
      sprintf("@emlRunAnovaAnalysis: tid, \"value\", \"group\", %d", doTukey),
      "appendInfoLine: \"COUNT \", emlProbeExtractionCount, \" \", tid, \" <\", emlRunAnovaAnalysis.error$, \">\"",
      "removeObject: tid")
}

prelude <- c(paste0("include ", barrel))

parse_count <- function(out) {
    ln <- grep("^COUNT ", out, value = TRUE)
    if (length(ln) != 1) return(NULL)
    parts <- strsplit(ln, " ", fixed = TRUE)[[1]]
    list(calls = as.integer(parts[2]))
}

cases <- list(
    list(label = "6 groups, doTukey=0", nGroups = 6, doTukey = 0),
    list(label = "6 groups, doTukey=1", nGroups = 6, doTukey = 1),
    list(label = "3 groups, doTukey=1", nGroups = 3, doTukey = 1),
    list(label = "9 groups, doTukey=1", nGroups = 9, doTukey = 1)
)

for (cs in cases) {
    lines <- c(prelude, 'writeInfoLine: "v152"', build_case(cs$nGroups, cs$doTukey))
    out <- run_praat(lines, gsub("[^a-zA-Z0-9]+", "-", cs$label), timeoutSec = 60)
    parsed <- parse_count(out)
    if (is.null(parsed)) {
        cat(sprintf("      v152 %s: probe did not report; last lines:\n", cs$label))
        cat(paste("       ", tail(out, 15)), sep = "\n")
        check_true(V, paste("probe reported for", cs$label), FALSE)
    } else {
        calls <- parsed$calls
        cat(sprintf("      v152 %-24s: %d @eml_getGroupData call(s) for %d groups\n",
                    cs$label, calls, cs$nGroups))
        check_true(V, sprintf("%s: at most one extraction pass per group (%d calls <= %d groups)",
                               cs$label, calls, cs$nGroups),
                   calls <= cs$nGroups)
        attest(V, sprintf("%s: %d calls for %d groups (exactly one pass per group: %s)",
                           cs$label, calls, cs$nGroups, calls == cs$nGroups))
    }
}

# ----------------------------------------------------------------------------
# FULL PUBLIC-ROUTE ORCHESTRATOR, MEASURED AND REPORTED -- NOT GATED.
#
# @emlRunAnovaAnalysis (eml-analysis.praat, in this session's file boundary,
# and itself fixed so its OWN loops extract each group at most once) still
# shows an inflated count here, because it calls onward into
# @emlReportAnovaComparison in graphs/eml-annotation-procedures.praat -- a
# file this session's brief does NOT list as editable. Read-only inspection
# found that procedure (a) re-runs @emlOneWayAnova a second full time purely
# to render report text (a pre-existing comment in eml-analysis.praat already
# says so: "@emlReportAnovaComparison re-runs @emlOneWayAnova itself, so
# emlOneWayAnova.* here holds exactly what was PRINTED"), and (b) carries its
# own separate, unfixed per-pair @eml_getGroupData loops. Gating on this
# number would either assert a bound this session cannot make true without
# leaving its file boundary, or be quietly loosened to hide that -- both
# dishonest. So it is measured and printed, never used to pass or fail v152.
# ----------------------------------------------------------------------------
for (cs in cases) {
    lines <- c(prelude, 'writeInfoLine: "v152"', build_full_case(cs$nGroups, cs$doTukey))
    out <- run_praat(lines, paste0("full-", gsub("[^a-zA-Z0-9]+", "-", cs$label)), timeoutSec = 60)
    parsed <- parse_count(out)
    if (is.null(parsed)) {
        cat(sprintf("      v152 [full orchestrator, informational] %s: probe did not report\n", cs$label))
    } else {
        cat(sprintf("      v152 [full orchestrator, informational] %-24s: %d @eml_getGroupData call(s) for %d groups (kernel alone: %d) -- excess is @emlReportAnovaComparison, outside this session's file boundary\n",
                    cs$label, parsed$calls, cs$nGroups, cs$nGroups))
        attest(V, sprintf("full @emlRunAnovaAnalysis, %s: %d calls measured (informational only, not gated -- excess traced to graphs/eml-annotation-procedures.praat, outside this session's file boundary)",
                           cs$label, parsed$calls))
    }
}

# ----------------------------------------------------------------------------
# VALUE IDENTITY, briefly, in the same probe process: RULING_ONE_RUN_PER_CASE
# rev 2's "you must show how you know it cannot serve one case's data to
# another" is a claim about VALUES, not just counts. Two cases of DIFFERENT
# sizes are run back to back in ONE Praat process (so any stale cache would
# have the chance to leak), and the SMALLER case's F statistic is checked
# against R's own aov() on the identical data -- an independent oracle, the
# same standard v09/v19 use elsewhere in this suite. A leaked, wrong F would
# fail this, regardless of what the call count said.
# ----------------------------------------------------------------------------
mk_r_frame <- function(nGroups) {
    set.seed(1)
    do.call(rbind, lapply(seq_len(nGroups), function(gi) {
        n <- 5 + gi
        data.frame(group = LETTERS[gi], value = round(rnorm(n, mean = gi * 3, sd = 1.5), 4))
    }))
}
fOracle <- function(nGroups) {
    d <- mk_r_frame(nGroups)
    summary(aov(value ~ group, data = d))[[1]][["F value"]][1]
}

# ONE Praat process, two cases back to back, LARGER FIRST -- if a
# smaller-nGroups case ever read a higher, stale group index left behind by
# an earlier larger case (the exact failure mode the ruling names), it would
# show up here as a wrong F, not merely as an extra call. Drives
# @emlOneWayAnova directly (the same gated kernel above), reading its
# .fValue output.
without_count_line <- function(caseLines) Filter(function(x) !startsWith(x, "appendInfoLine"), caseLines)
leakLines <- c(prelude, 'writeInfoLine: "v152-leak"',
    without_count_line(build_case(8, 1)),
    "appendInfoLine: \"FVAL8 \", emlOneWayAnova.fValue",
    without_count_line(build_case(3, 1)),
    "appendInfoLine: \"FVAL3 \", emlOneWayAnova.fValue")
outLeak <- run_praat(leakLines, "leak-order", timeoutSec = 60)
get_fval <- function(out, tag) {
    ln <- grep(paste0("^", tag, " "), out, value = TRUE)
    if (length(ln) != 1) return(NA_real_)
    as.numeric(sub(paste0("^", tag, " "), "", ln))
}
fBigPraat   <- get_fval(outLeak, "FVAL8")
fSmallPraat <- get_fval(outLeak, "FVAL3")
if (is.na(fBigPraat) || is.na(fSmallPraat)) {
    cat("      v152 leak probe did not report both F values; last lines:\n")
    cat(paste("       ", tail(outLeak, 15)), sep = "\n")
}
check("v152", "F statistic, 8-group case, first in the process",
      fBigPraat, fOracle(8), tol = 1e-6)
check("v152", "F statistic, 3-group case, run AFTER the 8-group case in the SAME Praat process",
      fSmallPraat, fOracle(3), tol = 1e-6)

restore_installed()

} # instrumentation site found
} # canDrive

if (!exists("EML_SUITE")) { eml_report("v152 one extraction per group per case"); eml_exit() }
