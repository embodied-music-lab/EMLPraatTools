#!/usr/bin/env Rscript
# ============================================================================
# v160 -- the claims-to-evidence ledger
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES
#
# grand_ledger reports what the kit MEASURES. This file checks the ledger that
# runs the other way: it starts from what the paper ASSERTS and traces each
# assertion to the artifact and command backing it. A claim with no backing
# artifact is a GAP row, and a GAP row is how a paper ends up stating something
# nothing measured.
#
# The ledger is planning/CLAIMS_EVIDENCE_LEDGER_2026-09-02.md. Its CONTENT is
# Fable's, maintained at every ruling, same custody as the tracker. This file
# is the MECHANISM: it checks the ledger's shape and reports its GAP rows. The
# split is set by RULING_PROTOCOL_ARTIFACTS_2026-09-02.md.
#
# SEVERITY, AND WHEN IT CHANGES
#
# GAP rows REPORT today and do not fail this file. They join the blocking set
# at the authoritative run, per that ruling and per
# INSPECTION_PROTOCOL section 3, which requires zero GAP rows at inspection.
# To promote them, set BLOCK_ON_GAP below to TRUE; do that when the run is
# scheduled, not before.
#
# The ledger is keyed to tracker section B until Sol's draft exists. It then
# RE-KEYS to the draft's own assertions -- every sentence stating a number or
# a finding gets a row -- and the zero-GAP bar applies to the re-keyed ledger.
# Two stages, one mechanism, so this file does not hardcode the row count.
#
# HOW TO RUN
#
#   Rscript validate/v160_claims_evidence.R
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v160"
BLOCK_ON_GAP <- FALSE

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

STATUSES <- c("EXISTS-COMMITTED", "AWAITING_RUN", "GAP")

ledger <- repo_path("planning", "CLAIMS_EVIDENCE_LEDGER_2026-09-02.md")
check_true(V, "the claims-to-evidence ledger exists", file.exists(ledger))
if (!file.exists(ledger)) {
    if (!exists("EML_SUITE")) { eml_report("v160 -- the claims ledger"); eml_exit() }
}

lines <- readLines(ledger, warn = FALSE)
rowLines <- grep("^\\|\\s*[0-9]+\\s*\\|", lines, value = TRUE)
check_true(V, "the ledger holds at least one claim row", length(rowLines) > 0)

cells <- lapply(rowLines, function(l) trimws(strsplit(sub("^\\|", "", sub("\\|\\s*$", "", l)), "|", fixed = TRUE)[[1]]))

# ---- schema ---------------------------------------------------------------
# Parsed defensively: the FIRST cell is the number and the LAST is the status,
# with everything between treated as content. A claim's text can contain a
# literal "|", which naive splitting turns into extra columns -- and which also
# breaks the table where a person reads it, so it is reported rather than
# silently absorbed.
cat("\n  ---- schema ----\n")
NCOL <- 5   # number, claim, backing artifact(s), re-run command, status

wide <- which(vapply(cells, length, integer(1)) != NCOL)
check_true(V, "no claim row contains an unescaped pipe", length(wide) == 0)
if (length(wide)) {
    cat("      These rows render wrong wherever the table is read. Escape the\n")
    cat("      pipe as \\| in the ledger:\n")
    for (i in wide)
        cat(sprintf("        row %s splits into %d cells, expected %d\n",
                    cells[[i]][1], length(cells[[i]]), NCOL))
}

nums <- suppressWarnings(as.integer(vapply(cells, `[`, character(1), 1)))
check_true(V, "claim numbers are a gapless run from 1",
           !anyNA(nums) && identical(sort(nums), seq_along(nums)))

# The status token, however the cell is punctuated around it.
statusOf <- function(cs) {
    last <- cs[length(cs)]
    hit <- STATUSES[vapply(STATUSES, function(s)
        grepl(s, last, fixed = TRUE), logical(1))]
    if (length(hit)) hit[1] else paste0("UNRECOGNISED(", substr(last, 1, 24), ")")
}
st <- vapply(cells, statusOf, character(1))
bad <- grep("^UNRECOGNISED", unique(st), value = TRUE)
check_true(V, "every status is one of the three allowed values", length(bad) == 0)
if (length(bad)) for (b in bad) cat(sprintf("      %s\n", b))

emptyClaim <- which(nchar(vapply(cells, `[`, character(1), 2)) < 10)
check_true(V, "every row states a claim", length(emptyClaim) == 0)
emptyBack <- which(nchar(vapply(cells, function(c) c[3], character(1))) < 10)
check_true(V, "every row names a backing artifact", length(emptyBack) == 0)

# ---- the tally ------------------------------------------------------------
cat("\n  ---- claim status ----\n")
for (s in STATUSES)
    cat(sprintf("      %-18s %d\n", s, sum(st == s)))
cat(sprintf("      %-18s %d\n", "TOTAL", length(st)))

# ---- GAP rows -------------------------------------------------------------
gaps <- which(st == "GAP")
cat(sprintf("\n  ---- GAP rows: %d ----\n", length(gaps)))
for (i in gaps)
    cat(sprintf("      %s. %s\n", cells[[i]][1], substr(cells[[i]][2], 1, 100)))

if (BLOCK_ON_GAP) {
    check_true(V, "no claim is a GAP row", length(gaps) == 0)
} else {
    cat("\n      GAP rows report and do not fail this file today. They join the\n")
    cat("      blocking set at the authoritative run: set BLOCK_ON_GAP to TRUE\n")
    cat("      when the run is scheduled. INSPECTION_PROTOCOL section 3 requires\n")
    cat("      zero GAP rows at inspection.\n")
}

if (!exists("EML_SUITE")) { eml_report("v160 -- the claims ledger"); eml_exit() }
