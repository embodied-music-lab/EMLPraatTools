#!/usr/bin/env Rscript
# ============================================================================
# check_registry_counts.R -- no document in this repository may state this
# suite's totals, and the suite's own two presentations of a run must agree
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT CHANGED, AND WHY (15 August 2026)
#
# This file used to verify that the totals printed in REGISTRY.md and README.md
# matched a live run. It was correct, it worked, and it was failing -- because
# verifying a written-down total against reality only tells you the total has
# drifted; it does not stop the drift, and it costs a full suite run (several
# minutes) to say so, which is exactly why nobody ran it. On 14 August an audit
# found four documents carrying four different totals for the same suite --
# 6,486 · 4,058 (at four separate sites) · 8,221 · 9,877 -- against a live
# 10,063 that was 10,291 two days later. The checker had been right about all
# of them for weeks and had changed nothing.
#
# So the rule this file enforces is no longer "the written total must be
# right". It is:
#
#     THE ONLY NUMBER ABOUT THIS SUITE THAT MAY BE WRITTEN DOWN IS ZERO.
#
# Zero failures is a contract, not a measurement: a run that violates it is
# broken by definition, so the sentence "expect 0 FAILED and exit status 0"
# cannot become false through the passage of time. Every other figure -- how
# many checks ran, how many attestations, how many each script contributed --
# is a photograph of one moment, and is generated on demand by
# `validate/tools/gen_counts.R`, stamped with its date and its commit.
#
# THE PROPERTY THAT MATTERS: this checker never needs to know the true total.
# It asserts the ABSENCE of a total, which is decidable from the documents
# alone, in about a second, with no Praat, no suite run, and no dependence on
# a figure that six concurrent branches are moving underneath it. An
# enforcement that has to know the right answer is one more thing that can be
# out of date; this one cannot.
#
# TWO MODES
#
#   Rscript validate/tools/check_registry_counts.R
#       LINT only. Reads the front-door documents. No suite run. Fails if any
#       of them states a non-zero suite total.
#
#   Rscript validate/run_all.R | tee /tmp/suite.log
#   Rscript validate/tools/check_registry_counts.R /tmp/suite.log
#       LINT plus AGREEMENT. Additionally checks that the run's own two
#       presentations of itself agree -- the headline against the PASS/FAIL
#       lines it summarises, and against the by-script aggregate -- and that
#       the failure count is zero. That is P4 of 6 August 2026 made permanent:
#       the aggregate once summed to 460 against a headline of 454, and two
#       presentations of one run must not disagree. Like the lint, it needs no
#       external number: it compares the run against itself.
#
#   Rscript validate/tools/check_registry_counts.R --run
#       As above, but runs the suite itself. Slow. Prefer handing it a log.
#
# THE ESCAPE HATCH, AND WHY IT IS DELIBERATELY UGLY. Some counts in these
# documents are legitimately about something else -- v18's headless sweep,
# the primitives suite under `plugin/dev/tests/`. A line carrying
# `<!-- count-scope: ... -->` is exempt, and the comment must say what the
# number counts. It renders as nothing and reads as a declaration, so a
# reviewer sees the claim of scope next to the number making it. On 6 August
# 2026 a global search-and-replace aimed at this file's stale figures
# overwrote the primitives suite's 409 + 33 split with the validate/ headline;
# the marker exists so that number is visibly not ours.
#
# Exit 0 iff clean. Stock R only.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
.a   <- commandArgs(FALSE)
.f   <- sub("^--file=", "", .a[grep("^--file=", .a)])
HERE <- if (length(.f)) dirname(normalizePath(.f)) else getwd()
VAL  <- dirname(HERE)                       # .../validate
ROOT <- dirname(VAL)

fail_n <- 0L
say <- function(ok, what, detail = "") {
    if (!ok) fail_n <<- fail_n + 1L
    cat(sprintf("%-4s  %-58s %s\n", if (ok) "OK" else "FAIL", what, detail))
}

# ---------------------------------------------------------------------------
# THE FRONT-DOOR DOCUMENTS. These are the ones a reviewer reads before running
# anything, so these are the ones whose numbers mislead. `audit/` is excluded
# on purpose: a dated session report is a record of what was true that day and
# is supposed to keep saying so.
# ---------------------------------------------------------------------------
DOCS <- c("README.md", "START_HERE.md",
          file.path("validate", "README.md"),
          file.path("validate", "REGISTRY.md"))

# The vocabulary a suite total is stated in. A numeral touching any of these
# words is a claim about how much was tested.
#
# The numeral must not be preceded by a letter or digit, or `v09 checks:` and
# `v14 checks` -- script IDENTIFIERS, not counts -- read as claims. The
# spelled-out form is checked for attestations only: "one", "two" and their
# neighbours are ordinary English before "checks" ("one checks helpers.R
# against scipy") and a pattern that cries wolf there gets switched off.
NUM  <- "(?<![A-Za-z0-9_])[0-9][0-9,]*"
WORD <- paste0("(?:checks?|passed|passing|FAILED|failures?|mismatch(?:es)?|",
               "attestations?|times)")
SPELLED <- paste0("(?:one|two|three|four|five|six|seven|eight|nine|ten|",
                  "eleven|twelve|thirteen|fourteen|fifteen|twenty|thirty|forty|fifty)")

PATTERNS <- c(
    # "10291 checks", "10291 passed", "0 FAILED", "8 attestations"
    paste0(NUM, "\\s+", WORD),
    # "checks: 10291"
    paste0(WORD, "\\s*[:=]\\s*", NUM),
    # "10291/10291 checks", "39/39 passed"
    paste0(NUM, "\\s*/\\s*[0-9][0-9,]*\\s+", WORD),
    # "eight attestations" -- spelling it does not make it a different claim
    paste0("\\b", SPELLED, "\\s+attestations?\\b")
)

# A match is allowed iff every numeral in it is zero. "0 FAILED" and
# "0 mismatches" survive; "10291 checks" does not, and neither does the
# 10,291 it will be tomorrow.
all_zero <- function(txt) {
    nums <- regmatches(txt, gregexpr("[0-9][0-9,]*", txt))[[1]]
    length(nums) > 0 && all(gsub(",", "", nums) == "0")
}

scan_text <- function(txt) {
    hits <- character(0)
    for (p in PATTERNS) {
        mm <- regmatches(txt, gregexpr(p, txt, perl = TRUE))[[1]]
        hits <- c(hits, mm)
    }
    hits <- unique(hits[nzchar(hits)])
    hits[!vapply(hits, all_zero, logical(1))]
}

marked <- function(ln) grepl("<!--\\s*count-scope:", ln)

lint_doc <- function(rel) {
    path <- file.path(ROOT, rel)
    if (!file.exists(path)) { say(FALSE, paste0(rel), "missing"); return(invisible()) }
    lines <- readLines(path, warn = FALSE)
    bad <- character(0)
    for (i in seq_along(lines)) {
        ln <- lines[i]
        nx <- if (i < length(lines)) lines[i + 1L] else ""
        # A claim declared as counting something other than this suite.
        this_line <- if (marked(ln)) character(0) else scan_text(ln)
        # PROSE WRAPS, AND A TOTAL DOES NOT CARE WHERE THE LINE BREAKS. The
        # first version of this lint read one line at a time and walked past
        # "the same move repeated 4058 / times" in validate/README.md because
        # the numeral and its noun were on opposite sides of a newline. A
        # two-line window catches the wrap; hits wholly inside either line are
        # already reported there, so only the genuinely straddling ones are
        # added here.
        spanning <- character(0)
        if (nzchar(nx) && !marked(ln) && !marked(nx)) {
            spanning <- setdiff(scan_text(paste(ln, nx)),
                                c(scan_text(ln), scan_text(nx)))
        }
        hits <- unique(c(this_line, spanning))
        if (length(hits)) {
            bad <- c(bad, sprintf("%s:%d  %s", rel, i,
                                  paste(hits, collapse = " | ")))
        }
    }
    say(length(bad) == 0,
        paste0(rel, ": states no suite total"),
        if (length(bad)) paste0(length(bad), " site(s)") else "")
    if (length(bad)) for (b in bad) cat("        ", b, "\n", sep = "")
    invisible()
}

cat("-- lint: no document may state a non-zero suite total ------------------\n")
for (d in DOCS) lint_doc(d)

# A TABLE COLUMN IS A TOTAL WITH A HEADER ON IT. REGISTRY.md's script table
# carried a `Checks` column until 15 August 2026: thirty-nine hand-maintained
# per-script figures, invisible to the prose lint because a bare `| 41 |` cell
# touches none of the vocabulary, and stale for the same reason everything else
# was. Prose is not the only place a number can be written down, so the column
# header is checked too.
lint_table_headers <- function(rel) {
    path <- file.path(ROOT, rel)
    if (!file.exists(path)) return(invisible())
    lines <- readLines(path, warn = FALSE)
    hits <- grep("^\\|.*\\|\\s*(Checks?|Passed|Count|Attestations?)\\s*\\|",
                 lines, ignore.case = TRUE)
    hits <- hits[!vapply(lines[hits], marked, logical(1))]
    say(length(hits) == 0,
        paste0(rel, ": no table counts checks in a column"),
        if (length(hits)) paste(paste0("line ", hits), collapse = ", ") else "")
}
for (d in DOCS) lint_table_headers(d)

# The generator has to exist, or the documents point at nothing and the next
# person writes the number back into the prose because there is nowhere else
# to put it.
say(file.exists(file.path(HERE, "gen_counts.R")),
    "validate/tools/gen_counts.R exists", "the documents point at it")

# ---------------------------------------------------------------------------
# AGREEMENT MODE. Only when a run is available.
# ---------------------------------------------------------------------------
log <- NULL
if (length(args) >= 1 && nzchar(args[1])) {
    if (identical(args[1], "--run")) {
        log <- suppressWarnings(system2("Rscript", file.path(VAL, "run_all.R"),
                                        stdout = TRUE, stderr = TRUE))
    } else if (file.exists(args[1])) {
        log <- readLines(args[1], warn = FALSE)
    } else {
        say(FALSE, "suite log", paste0("no such file: ", args[1]))
    }
}

if (!is.null(log)) {
    cat("\n-- agreement: the run's two presentations of itself ------------------\n")
    n_pass <- sum(grepl("^PASS\\b", log))
    n_fail <- sum(grepl("^FAIL\\b", log))
    n_atst <- sum(grepl("^ATST\\b", log))

    hl <- grep("^\\d+ checks, \\d+ passed, \\d+ FAILED\\s*$", log, value = TRUE)
    if (!length(hl)) {
        say(FALSE, "headline present",
            "no '<N> checks, <N> passed, <N> FAILED' line -- run did not finish")
    } else {
        h <- as.integer(regmatches(hl[length(hl)],
                regexec("^(\\d+) checks, (\\d+) passed, (\\d+) FAILED",
                        hl[length(hl)]))[[1]][2:4])
        say(h[1] == n_pass + n_fail,
            paste0("headline total = its own PASS/FAIL lines (", h[1], ")"),
            paste0("lines ", n_pass + n_fail))
        say(h[2] == n_pass, paste0("headline passed = PASS lines (", h[2], ")"),
            paste0("lines ", n_pass))
        say(h[3] == n_fail, paste0("headline failed = FAIL lines (", h[3], ")"),
            paste0("lines ", n_fail))
        say(h[3] == 0L, "the contract: 0 FAILED", paste0("headline says ", h[3]))

        agg <- grep("^\\s*\\S+\\s+\\d+/\\d+\\s+\\d+\\s*$", log, value = TRUE)
        if (!length(agg)) {
            say(FALSE, "by-script aggregate present",
                "run_all.R prints one under 'By script id:'")
        } else {
            m <- regmatches(agg, regexec(
                "^\\s*(\\S+)\\s+(\\d+)/(\\d+)\\s+(\\d+)\\s*$", agg))
            per <- do.call(rbind, lapply(m, function(x)
                data.frame(id = x[2], passed = as.integer(x[3]),
                           total = as.integer(x[4]), attested = as.integer(x[5]),
                           stringsAsFactors = FALSE)))
            say(sum(per$total) == h[1],
                paste0("by-script totals sum to the headline (", sum(per$total), ")"),
                paste0("headline ", h[1]))
            say(sum(per$passed) == h[2],
                paste0("by-script passes sum to the headline (", sum(per$passed), ")"),
                paste0("headline ", h[2]))

            # Attestations are checked PER ID, not in aggregate, because
            # run_all.R builds the by-script table from the checks and merges
            # the attestations onto it: a script that recorded an attestation
            # and no check has no row to merge onto and vanishes from the
            # table while still counting in the ATST lines. A summed
            # comparison would report that as an arithmetic mismatch and send
            # the reader looking in the wrong place.
            atst_id <- sub("^ATST\\s+(\\S+).*$", "\\1",
                           grep("^ATST\\b", log, value = TRUE))
            tab <- table(atst_id)
            missing <- setdiff(names(tab), per$id)
            say(length(missing) == 0,
                "every id with an attestation has a by-script row",
                if (length(missing))
                    paste0("absent from the table: ", paste(missing, collapse = ", "),
                           " -- recorded an attestation and no check")
                else "")
            bad <- character(0)
            for (i in seq_len(nrow(per))) {
                seen <- if (per$id[i] %in% names(tab)) as.integer(tab[[per$id[i]]]) else 0L
                if (seen != per$attested[i])
                    bad <- c(bad, sprintf("%s table %d vs %d lines",
                                          per$id[i], per$attested[i], seen))
            }
            say(length(bad) == 0,
                "by-script attestations match the ATST lines, per id",
                paste(bad, collapse = "; "))
        }
    }
} else {
    cat("\n(no suite log given -- lint only. Hand me one, or pass --run, to\n",
        " check a run against itself as well.)\n", sep = "")
}

cat(sprintf("\n%s: %d problem(s)\n",
            if (fail_n) "MISMATCH" else "clean", fail_n))
quit(status = if (fail_n) 1L else 0L)
