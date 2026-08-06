#!/usr/bin/env Rscript
# ============================================================================
# check_registry_counts.R — machine-verify every count REGISTRY.md claims
# against a live run of the suite.  (FABL P5: the checker itself must live
# in the repository, not in a report about the repository.)
#
# Stock R only. Verifies:
#   1. every per-script figure in the REGISTRY script table
#   2. the v07 row's "N + M attested" composite against the R1..R7 rows
#   3. the headline "<N> checks, all passing, plus <M> attestations"
#
# Usage:
#   Rscript validate/tools/check_registry_counts.R [suite-log]
#
# With no argument it runs the suite itself. In CI, pass the log of the
# run_all.R invocation you already made, so the suite runs once:
#   Rscript validate/run_all.R | tee /tmp/suite.log
#   Rscript validate/tools/check_registry_counts.R /tmp/suite.log
#
# Exit 0 iff every claimed figure matches the live run. A REGISTRY row or a
# headline this script cannot parse is a FAILURE, not a skip — a checker
# that silently stops reading a drifted document is the defect class this
# whole exchange has been about.
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
.a <- commandArgs(FALSE)
.f <- sub("^--file=", "", .a[grep("^--file=", .a)])
HERE <- if (length(.f)) dirname(normalizePath(.f)) else getwd()
VAL  <- dirname(HERE)                       # .../validate
REG  <- file.path(VAL, "REGISTRY.md")

fail_n <- 0L
say <- function(ok, what, detail = "") {
    if (!ok) fail_n <<- fail_n + 1L
    cat(sprintf("%-4s  %-58s %s\n", if (ok) "OK" else "FAIL", what, detail))
}

# --- 1. the live run --------------------------------------------------------
if (length(args) >= 1) {
    log <- readLines(args[1], warn = FALSE)
} else {
    log <- suppressWarnings(
        system2("Rscript", file.path(VAL, "run_all.R"),
                stdout = TRUE, stderr = TRUE))
}
live_checks <- sum(grepl("^(PASS|FAIL)\\b", log))
live_atst   <- sum(grepl("^ATST\\b", log))
live_fails  <- sum(grepl("^FAIL\\b", log))

# per-script table out of the run summary: "  <id>  <p>/<n>  <attested>"
agg <- grep("^\\s*\\S+\\s+\\d+/\\d+\\s+\\d+\\s*$", log, value = TRUE)
if (!length(agg)) stop("could not find the by-script aggregate in the run output")
m <- regmatches(agg, regexec("^\\s*(\\S+)\\s+(\\d+)/(\\d+)\\s+(\\d+)\\s*$", agg))
live <- do.call(rbind, lapply(m, function(x)
    data.frame(id = x[2], passed = as.integer(x[3]), total = as.integer(x[4]),
               attested = as.integer(x[5]))))
# a script may report under sub-ids ("v15", "v15:F0_Hz", ...): sum them all
per_id <- function(id) {
    sel <- live$id == id | startsWith(live$id, paste0(id, ":"))
    if (!any(sel)) integer(0) else sum(live$total[sel])
}
v07_ids <- paste0("R", 1:7)
v07_checks <- sum(vapply(v07_ids, function(i) {
    v <- per_id(i); if (length(v)) v else 0L }, integer(1)))
v07_atst <- sum(live$attested[live$id %in% v07_ids])

# --- 2. the REGISTRY script table -------------------------------------------
reg <- readLines(REG, warn = FALSE)
rows <- grep("^\\|\\s*`v\\d+", reg, value = TRUE)
if (!length(rows)) stop("could not find the script table in REGISTRY.md")
for (r in rows) {
    cells <- trimws(strsplit(r, "\\|")[[1]])
    cells <- cells[nzchar(cells)]
    script <- sub("^`([^`]+)`.*$", "\\1", cells[1])
    id     <- sub("^(v\\d+).*$", "\\1", script)
    claim  <- cells[length(cells)]
    if (grepl("attested", claim)) {
        # the v07 composite row: "<N> + <M> attested"
        nm <- regmatches(claim, regexec("(\\d+)\\s*\\+\\s*(\\d+)\\s*attested", claim))[[1]]
        if (length(nm) < 3) { say(FALSE, paste0(id, " row"), paste0("unparseable: '", claim, "'")); next }
        say(as.integer(nm[2]) == v07_checks,
            paste0(id, " (R1-R7) checks: claimed ", nm[2]),
            paste0("live ", v07_checks))
        say(as.integer(nm[3]) == v07_atst,
            paste0(id, " attested: claimed ", nm[3]),
            paste0("live ", v07_atst))
    } else {
        n <- suppressWarnings(as.integer(claim))
        if (is.na(n)) { say(FALSE, paste0(id, " row"), paste0("unparseable count: '", claim, "'")); next }
        lv <- per_id(id)
        if (!length(lv)) { say(FALSE, paste0(id, " row"), "id absent from live run"); next }
        say(n == lv, paste0(id, " checks: claimed ", n), paste0("live ", lv))
    }
}

# --- 3. the headline --------------------------------------------------------
hl <- grep("\\d+\\s+checks,\\s*all passing,\\s*plus\\s+\\d+\\s+attestation", reg, value = TRUE)
if (!length(hl)) {
    say(FALSE, "headline", "no '<N> checks, all passing, plus <M> attestations' line found")
} else {
    nm <- regmatches(hl[1], regexec("(\\d+)\\s+checks,\\s*all passing,\\s*plus\\s+(\\d+)", hl[1]))[[1]]
    say(as.integer(nm[2]) == live_checks,
        paste0("headline checks: claimed ", nm[2]), paste0("live ", live_checks))
    say(as.integer(nm[3]) == live_atst,
        paste0("headline attestations: claimed ", nm[3]), paste0("live ", live_atst))
    say(live_fails == 0, "headline 'all passing'", paste0("live failures: ", live_fails))
}

# --- 4. README.md's expect-line (headline claims live in more than one doc) --
rmd <- file.path(dirname(VAL), "README.md")
if (file.exists(rmd)) {
    rl <- grep("Expect\\s*`?\\d+\\s+checks", readLines(rmd, warn = FALSE), value = TRUE)
    if (!length(rl)) {
        say(FALSE, "README expect-line", "no 'Expect <N> checks' line found")
    } else {
        n <- as.integer(regmatches(rl[1], regexec("(\\d+)\\s+checks", rl[1]))[[1]][2])
        say(n == live_checks, paste0("README expect-line: claimed ", n),
            paste0("live ", live_checks))
    }
}

cat(sprintf("\n%s: %d mismatch(es)\n",
            if (fail_n) "MISMATCH" else "clean", fail_n))
quit(status = if (fail_n) 1L else 0L)
