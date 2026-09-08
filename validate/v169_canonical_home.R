#!/usr/bin/env Rscript
# ============================================================================
# v169 -- CANONICAL-HOME: a code line that duplicates a canon procedure's job
# outside the file or procedure meant to own it
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. Fable's ORDER_DRY_LINT_AND_AUDIT_FIXES, part A, check
# A2: a driven lint that reads validate/canon/helper_homes.tsv (pattern,
# canonical_procedure, allowed_files, reason) and fails any CODE line in
# plugin_EML_StatsGraphs/{stats,graphs,scripts}/**/*.praat or setup.praat
# that matches a pattern outside the file or procedure that pattern names as
# the pattern's one legitimate home. AUDIT_PROCEDURES_2026-09-08 (Fable/PM,
# 8 Sep 2026, /tmp/AUDIT_PROCEDURES.md) is the census this lint mechanises:
# 65 findings, 43 confirmed, most of them exactly this shape -- the same job
# done twice because the second site never called the first site's
# procedure.
#
# WHAT "CODE" MEANS HERE. A line whose trimmed text starts with "#" or ";"
# is a whole-line comment and contributes nothing. An inline comment --
# "  .x = 1  # note" -- is real Praat syntax (the manual's rule: a "#" or
# ";" preceded by whitespace starts a comment; ATTACHED to a token, as in
# the vector sigil ".keep#" or "selected#()", it is not one) and is
# stripped up to but not including that marker, so vector-typed variables
# survive intact. A "#" or ";" INSIDE A QUOTED STRING is neither -- masked
# out before the marker search runs, so a label like "AS 89 for Spearman;
# exact enumeration ..." is not truncated mid-string.
#
# WHAT "CANONICAL HOME" MEANS HERE, MECHANICALLY. Each helper_homes.tsv row
# is a (pattern, allowed_files) pair. allowed_files is semicolon-separated
# and each token is EITHER a plugin-relative file path (the pattern's home
# is a whole file, e.g. stats/eml-core-descriptive.praat) OR "proc:NAME"
# (the pattern's home is one procedure's body, anywhere it is defined --
# tracked here by a plain "procedure NAME" / "endproc" scan, not by file,
# because a home procedure and its callers routinely live in different
# files). A matched code line is IN its home when the file it is in is
# listed verbatim, OR the procedure it currently sits inside (by lexical
# nesting -- Praat procedures do not nest, so "currently inside" is
# unambiguous) is named by a proc: token. Anywhere else, it is a bypass.
#
# WHY SOME PATTERNS ARE NARROWER THAN THEIR ONE-LINE DESCRIPTION IN THE
# ORDER. "fileReadable inside a counter loop" and "Get column label used in
# an existence walk" are described, not given as exact regexes, in the
# order -- unlike fixed$/sum-mean-stdev/sqrt-SD/splitter/underscore/quote,
# which the order spells out character for character. A bare `fileReadable`
# or `Get column label` regex would also fire on write-probe checks, config
# lookups, CSV-header collection and quote-stripping -- real code, doing a
# DIFFERENT job that happens to call the same Praat primitive. Both of the
# confirmed duplicate sites (stats/eml-record.praat's and
# stats/eml-output.praat's free-stem collision loops; eml-extract.praat's
# eight column-existence walks) turn out to share a distinctive local
# variable name across every copy -- ".try$" for the first, ".checkName$"
# for the second -- and NOTHING ELSE IN THE TREE uses that name for anything
# else (checked by grep before committing to it, not assumed; see the task
# report). The pattern is scoped to that signature so it catches the actual
# duplicate and does not also flag unrelated, correct code that happens to
# share a Praat built-in. helper_homes.tsv's reason column says this at each
# of those two rows.
#
# THE ALLOWLIST (validate/canon/helper_homes_allowlist.tsv, file + line +
# reason) is the ONE OTHER PLACE a match can pass: a specific (file, line)
# that matches a pattern, is NOT in that pattern's home, and is nonetheless
# accepted -- always with a reason, always printed (never silently), never
# used to launder a site this file's own header calls a confirmed bypass in
# stats/. It carries exactly two kinds of debt:
#   (a) every stats/ site matching the sum/mean/stdev pattern outside
#       eml-core-descriptive.praat -- AUDIT_PROCEDURES_2026-09-08 section 2
#       row 5 says the summation canon is UNDECIDED, not that these sites
#       are wrong, so red here would be asserting an answer nobody has
#       given yet;
#   (b) every graphs/ and scripts/ site any pattern matches -- section 6
#       defers "every graphs/ and scripts/ row in sections 1-4" to a later
#       round explicitly, so failing them here would be re-litigating a
#       disposition this wave does not own.
# A stats/ match of any OTHER pattern is NOT in that list and is NOT
# supposed to be: those are the confirmed, undisposed bypasses this check
# exists to keep red until a wave with standing to change plugin code fixes
# them. See the task report for the full fired-on list.
#
# THE SELF-TEST (validate/fixtures/canonical_home/{red,green}_demo.praat,
# modelled on v163's red-demo convention) proves the mechanism both ways,
# scanning ONLY those two fixture files, never the tree: red_demo.praat
# plants a bare `fixed$ (x, 4)` outside every allowed home and asserts this
# file flags it -- so a scan engine silently broken (a regex typo, a
# comment-stripper that eats too much) fails loudly here rather than
# reporting a quiet, meaningless "0 violations" on the real tree. green_demo
# .praat mirrors @eml_fixed's own body -- the same call, inside a procedure
# literally named eml_fixed -- and asserts this file does NOT flag it, which
# is the other half: a scanner that flagged everything containing "fixed$"
# would also pass the red assertion while being useless, and this is what
# rules that out.
#
# HOW TO RUN
#
#     cd /tmp/eml-repo && Rscript validate/vNNN_canonical_home.R
#
# No Praat required -- this is a static, comments-stripped text scan of the
# shipped .praat sources, not a driven probe.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v169"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# ----------------------------------------------------------------------------
# strip_code -- one line, comments removed, per the header's rule.
# ----------------------------------------------------------------------------
strip_code <- function(line) {
    t <- trimws(line)
    if (!nzchar(t) || substr(t, 1, 1) %in% c("#", ";")) return("")
    n <- nchar(line)
    if (n == 0) return(line)
    chars <- strsplit(line, "", fixed = TRUE)[[1]]
    in_str <- FALSE
    masked <- chars
    for (i in seq_along(chars)) {
        if (identical(chars[i], "\"")) {
            in_str <- !in_str
        } else if (in_str) {
            masked[i] <- "x"
        }
    }
    masked_s <- paste(masked, collapse = "")
    # An inline comment marker is a "#" or ";" preceded by whitespace, OUTSIDE
    # any quoted string (masked above). Not preceded by whitespace, it is a
    # vector sigil (.keep#, selected#()) or ordinary punctuation, not a
    # comment -- Praat's own rule, not a simplification of it.
    m <- regexpr("(?<=\\s)[#;]", masked_s, perl = TRUE)
    if (m > 0) substr(line, 1, m - 1) else line
}

# ----------------------------------------------------------------------------
# proc_scope_for_lines -- which procedure (by name) each already-stripped
# line lexically sits inside, NA outside every procedure. Praat procedures
# do not nest, so this is a flat open/close scan, not a stack.
# ----------------------------------------------------------------------------
PROC_RE <- "^\\s*procedure\\s+([A-Za-z_][A-Za-z0-9_]*)"
END_RE  <- "^\\s*endproc\\b"

proc_scope_for_lines <- function(code) {
    n <- length(code)
    scope <- rep(NA_character_, n)
    cur <- NA_character_
    for (i in seq_len(n)) {
        mm <- regmatches(code[i], regexec(PROC_RE, code[i]))[[1]]
        if (length(mm) == 2) {
            cur <- mm[2]
            scope[i] <- cur
            next
        }
        if (grepl(END_RE, code[i], perl = TRUE)) {
            scope[i] <- cur
            cur <- NA_character_
            next
        }
        scope[i] <- cur
    }
    scope
}

# ----------------------------------------------------------------------------
# is_home -- is (rel_path, proc_name) inside one of this pattern's allowed
# homes (semicolon-separated file paths and/or "proc:NAME" tokens)?
# ----------------------------------------------------------------------------
is_home <- function(rel_path, proc_name, allowed_files) {
    toks <- trimws(strsplit(allowed_files, ";", fixed = TRUE)[[1]])
    for (tok in toks) {
        if (!nzchar(tok)) next
        if (startsWith(tok, "proc:")) {
            want <- sub("^proc:", "", tok)
            if (!is.na(proc_name) && identical(proc_name, want)) return(TRUE)
        } else if (identical(rel_path, tok)) {
            return(TRUE)
        }
    }
    FALSE
}

# ----------------------------------------------------------------------------
# scan_file -- every (pattern, line) hit in one file, with home/allow status
# left for the caller to resolve (the allowlist is a separate, shared
# concern, not folded in here, so the self-test can reuse this on a fixture
# with no allowlist involved at all).
# ----------------------------------------------------------------------------
scan_file <- function(path, rel_path, homes) {
    raw <- readLines(path, warn = FALSE, encoding = "UTF-8")
    code <- vapply(raw, strip_code, character(1), USE.NAMES = FALSE)
    scope <- proc_scope_for_lines(code)
    rows <- list()
    for (p in seq_len(nrow(homes))) {
        pat <- homes$pattern[p]
        hits <- grep(pat, code, perl = TRUE)
        for (ln in hits) {
            rows[[length(rows) + 1L]] <- data.frame(
                file = rel_path, line = ln,
                pattern_idx = p,
                canonical = homes$canonical_procedure[p],
                proc = if (is.na(scope[ln])) "" else scope[ln],
                text = trimws(code[ln]),
                home = is_home(rel_path, scope[ln], homes$allowed_files[p]),
                stringsAsFactors = FALSE)
        }
    }
    if (length(rows)) do.call(rbind, rows) else NULL
}

# ----------------------------------------------------------------------------
# load helper_homes.tsv and its companion allowlist
# ----------------------------------------------------------------------------
homes_path <- repo_path("validate", "canon", "helper_homes.tsv")
allow_path <- repo_path("validate", "canon", "helper_homes_allowlist.tsv")

homes <- NULL
ok_homes <- file.exists(homes_path)
check_true(V, sprintf("canon table exists (%s)", homes_path), ok_homes)
if (ok_homes) {
    homes <- read.delim(homes_path, sep = "\t", quote = "", stringsAsFactors = FALSE,
                        colClasses = "character", encoding = "UTF-8")
    check_true(V, "canon table has the four required columns (pattern, canonical_procedure, allowed_files, reason)",
              all(c("pattern", "canonical_procedure", "allowed_files", "reason") %in% names(homes)))
    check_true(V, sprintf("canon table has at least one pattern row (found %d)", nrow(homes)),
              nrow(homes) >= 1)
}

allowlist <- data.frame(file = character(0), line = integer(0), reason = character(0),
                        stringsAsFactors = FALSE)
if (file.exists(allow_path)) {
    allowlist <- read.delim(allow_path, sep = "\t", quote = "", stringsAsFactors = FALSE,
                            colClasses = "character", encoding = "UTF-8")
    allowlist$line <- as.integer(allowlist$line)
}
allow_key <- paste(allowlist$file, allowlist$line, sep = "")

allowlisted_reason <- function(rel_path, line) {
    k <- paste(rel_path, line, sep = "")
    i <- match(k, allow_key)
    if (is.na(i)) NA_character_ else allowlist$reason[i]
}

# ============================================================================
# PART 1 -- SELF-TEST. Scans ONLY the two fixture files, never the tree.
# ============================================================================
if (ok_homes) {
    red_fx   <- repo_path("validate", "fixtures", "canonical_home", "red_demo.praat")
    green_fx <- repo_path("validate", "fixtures", "canonical_home", "green_demo.praat")
    ok_fx <- file.exists(red_fx) && file.exists(green_fx)
    check_true(V, "both self-test fixtures exist (red_demo.praat, green_demo.praat)", ok_fx)

    if (ok_fx) {
        red_hits <- scan_file(red_fx, "FIXTURE/red_demo.praat", homes)
        fixed_row <- which(homes$canonical_procedure == "eml_fixed")
        red_fixed <- if (!is.null(red_hits)) red_hits[red_hits$pattern_idx %in% fixed_row, , drop = FALSE] else NULL

        check_true(V,
            "[self-test, red demo] the planted bare fixed$(x, 4) in red_demo.praat is MATCHED by the fixed$ pattern at all",
            !is.null(red_fixed) && nrow(red_fixed) >= 1)
        if (!is.null(red_fixed) && nrow(red_fixed) >= 1) {
            check_true(V,
                "[self-test, red demo] ... and it is OUTSIDE every allowed home (proc:eml_fixed / proc:emlReportAlpha / proc:emlMeasureMatrixLayout) -- i.e. this checker would flag it as a violation",
                !any(red_fixed$home))
        }

        green_hits <- scan_file(green_fx, "FIXTURE/green_demo.praat", homes)
        green_fixed <- if (!is.null(green_hits)) green_hits[green_hits$pattern_idx %in% fixed_row, , drop = FALSE] else NULL
        check_true(V,
            "[self-test, green demo] the fixed$ call inside procedure eml_fixed in green_demo.praat IS matched by the pattern",
            !is.null(green_fixed) && nrow(green_fixed) >= 1)
        if (!is.null(green_fixed) && nrow(green_fixed) >= 1) {
            check_true(V,
                "[self-test, green demo] ... and it IS recognised as inside its canonical home (proc:eml_fixed) -- proving the proc-scope mechanism discriminates rather than flagging every fixed$ line indiscriminately",
                all(green_fixed$home))
        }

        # A comment-stripping self-check: green_demo.praat's fixed$ line
        # carries a trailing inline "# ..." comment (see the fixture). If the
        # stripper mishandled it -- either failing to strip it (leaving stray
        # text that could confuse a future pattern) or over-stripping into
        # the CODE itself -- .home detection above would still have passed by
        # accident. This asserts the actual stripped text is exactly the
        # code, no more and no less.
        if (!is.null(green_fixed) && nrow(green_fixed) >= 1) {
            check_true(V,
                "[self-test] the inline '# ...' comment on green_demo.praat's fixed$ line is stripped to exactly the code, not left attached and not over-stripped",
                identical(green_fixed$text[1], ".result$ = fixed$ (.value, .decimals)"))
        }
    }
}

# ============================================================================
# PART 2 -- THE TREE SCAN.
# ============================================================================
plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)

ok_plug <- dir.exists(plug)
check_true(V, sprintf("plugin directory exists (%s)", plug), ok_plug)

if (ok_homes && ok_plug) {
    all_files <- list.files(plug, pattern = "\\.praat$", recursive = TRUE, full.names = TRUE)
    plug_norm <- normalizePath(plug)
    rel_all <- substring(normalizePath(all_files, mustWork = FALSE), nchar(plug_norm) + 2L)
    # Scope, per the order: stats/, graphs/, scripts/ and setup.praat. dev/
    # (dev/tests, dev/retired, dev/tutorial-wireframes-v09.praat) is harness
    # material, explicitly excluded by AUDIT_PROCEDURES_2026-09-08's own
    # scope line, not the shipped plugin.
    keep <- grepl("^(stats|graphs|scripts)/", rel_all) | rel_all == "setup.praat"
    scan_files <- all_files[keep]
    scan_rel   <- rel_all[keep]
    ord <- order(scan_rel)
    scan_files <- scan_files[ord]; scan_rel <- scan_rel[ord]

    check_true(V, sprintf("scanned every stats/graphs/scripts/setup.praat file under the plugin (%d files)",
                          length(scan_files)), length(scan_files) > 0)

    all_hits <- list()
    for (i in seq_along(scan_files)) {
        h <- scan_file(scan_files[i], scan_rel[i], homes)
        if (!is.null(h)) all_hits[[length(all_hits) + 1L]] <- h
    }
    hits <- if (length(all_hits)) do.call(rbind, all_hits) else
        data.frame(file = character(0), line = integer(0), pattern_idx = integer(0),
                  canonical = character(0), proc = character(0), text = character(0),
                  home = logical(0), stringsAsFactors = FALSE)

    n_total <- nrow(hits)
    n_home  <- sum(hits$home)
    outside <- hits[!hits$home, , drop = FALSE]

    outside$allow_reason <- if (nrow(outside)) vapply(seq_len(nrow(outside)), function(i)
        allowlisted_reason(outside$file[i], outside$line[i]), character(1)) else character(0)
    is_allowlisted <- !is.na(outside$allow_reason)

    n_allowlisted <- sum(is_allowlisted)
    violations <- outside[!is_allowlisted, , drop = FALSE]
    debt       <- outside[is_allowlisted, , drop = FALSE]

    cat(sprintf(
        "      v169: %d pattern-match(es) across %d file(s): %d in a named canonical home, %d outside it (%d allowlisted as tracked debt, %d unresolved).\n",
        n_total, length(scan_files), n_home, nrow(outside), n_allowlisted, nrow(violations)))

    # Per-pattern summary, always printed (not a check, just an orientation
    # line -- the checks below are what actually count).
    for (p in seq_len(nrow(homes))) {
        sub <- hits[hits$pattern_idx == p, , drop = FALSE]
        cat(sprintf("        pattern %d (%s): %d match(es), %d in home, %d outside\n",
                    p, homes$canonical_procedure[p], nrow(sub), sum(sub$home), sum(!sub$home)))
    }

    # DEBT -- allowlisted, printed in full so it is never silently green.
    if (nrow(debt) > 0) {
        ord_d <- order(debt$file, debt$line)
        debt <- debt[ord_d, , drop = FALSE]
        for (i in seq_len(nrow(debt))) {
            check_true(V, sprintf("[ALLOWLISTED, %s] %s:%d -- %s outside its canonical home: %s",
                                  debt$allow_reason[i], debt$file[i], debt$line[i],
                                  debt$canonical[i], debt$text[i]),
                      TRUE)
        }
    }

    # VIOLATIONS -- the work order. Each is its own FAIL, naming file:line,
    # the canonical procedure the pattern belongs to, and the offending text.
    if (nrow(violations) > 0) {
        ord_v <- order(violations$file, violations$line)
        violations <- violations[ord_v, , drop = FALSE]
        for (i in seq_len(nrow(violations))) {
            where <- if (nzchar(violations$proc[i])) sprintf("inside @%s", violations$proc[i]) else "at top level"
            check_true(V, sprintf("%s:%d [%s] canonical home is %s, but this line (%s) is not in it: %s",
                                  violations$file[i], violations$line[i], where,
                                  violations$canonical[i], violations$canonical[i], violations$text[i]),
                      FALSE)
        }
    }

    check_true(V, sprintf("every canonical-home pattern match is either inside its home or in the tracked allowlist (0 unresolved bypasses; found %d)",
                          nrow(violations)), nrow(violations) == 0)
}

if (!exists("EML_SUITE")) {
    eml_report("v169 CANONICAL-HOME: a code line living outside the file or procedure meant to own it")
    eml_exit()
}
