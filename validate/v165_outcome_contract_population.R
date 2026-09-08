#!/usr/bin/env Rscript
# ============================================================================
# v165_outcome_contract_population.R -- every public non-draw entry point
# carries the uniform outcome contract
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE CONTRACT. Every public non-draw procedure sets three outputs:
#
#   .error$    empty on success, a message on failure
#   .warning$  empty, or a note that does not itself mean failure
#   .ok        derived ONCE, at the procedure's single final exit, as
#              .ok = (.error$ = "")
#
# The third clause is the one a piecemeal implementation gets wrong without
# looking wrong: a procedure that writes `.ok = 1` on a late success branch
# LOOKS like it reports success/failure correctly on every path anyone tests
# by hand -- it is only a THIRD path, added later, that forgets to touch one
# of the scattered `.ok = ...` seams, that silently reports the wrong outcome.
# The single-exit derivation has no such seam: the outcome is read fresh from
# `.error$` at the one exit. This file requires exactly one such derivation and
# forbids a competing `.ok = 1` success seam beside it. A bare `.ok = 0` entry
# initializer, alongside the `.error$`/`.warning$` inits, is tolerated: the
# derivation always overwrites it, so it cannot report a stale outcome.
#
# THE FOURTEEN TYPE-DISPATCH DRAW ROWS ARE AUDITED TOO, SEPARATELY, FURTHER
# DOWN. They are excluded from the "non-draw" population this file's name
# still describes because, when this file was written, they carried no
# contract at all. A later wave gave each of the fourteen the identical
# single-exit contract this file enforces elsewhere, mirrored from the
# diagnostic text each procedure already emitted to the Info window and its
# on-figure disclosure box -- so a second population, audited with the exact
# same audit_body() and the same three questions, keeps that promise
# checked rather than merely made once and left unwatched. See "THE
# TYPE-DISPATCH DRAW POPULATION" below.
#
# ---------------------------------------------------------------------------
# THE POPULATION -- DERIVED FROM plugin_EML_StatsGraphs/REGISTRY.tsv, NOT
# HARDCODED
# ---------------------------------------------------------------------------
# A procedure is public iff it has a row in REGISTRY.tsv (that file's own
# header states the rule; see also validate/v155_public_registry.R, which
# enforces the registry against the tree). "Non-draw" excludes exactly the
# EML-Graphs type-dispatch draw rows: the emlDraw* procedures that are the
# branches of @emlGraphsDispatchDraw's `graph_type = N` chooser
# (graphs/eml-draw-procedures.praat, one row per EML Graphs figure type).
#
# THE CLASSIFIER READS THE REGISTRY'S OWN `sources` COLUMN -- it does not
# pattern-match procedure names and does not duplicate
# walkthrough/kit/build_coverage_map.py's classify_kind() (which sorts EVERY
# emlDraw* name, QQPlot included, into "drawing" for a different purpose --
# the paper's Table S2 -- and is not this file's canon). REGISTRY.tsv's own
# header documents `sources` as "which of the ruling's three seed sources
# admitted this row": 2 = a user-facing drawing/graph entry point, 3 = the
# recorder emits a literal call to it. The fourteen type-dispatch rows are
# exactly the rows whose sources set is {2,3} -- admitted BOTH as a
# menu/wizard-presented drawing operation AND as something the recorder
# emits verbatim, because @emlGraphsDispatchDraw's branches are both at
# once. emlDrawQQPlot is the registry's own worked counter-example: its
# sources set is {2} alone, and its description says explicitly, in the
# registry's own words, that it is "Drawn directly from the normality-check
# door and the wizard, not through the EML Graphs type dispatch ... unlike
# the thirteen graph types, never recorded." A name-prefix test
# (name starts with "emlDraw") would misclassify it as dispatch and land on
# 30 non-draw rows, not 31; requiring the sources SET to equal {2,3} -- not
# just "contains 2" -- is what keeps QQPlot in the non-draw population,
# which is where the ruling puts it: it IS a draw procedure by name, and it
# is NOT part of the type-dispatch set this file exists to exclude, and
# nothing about that requires typing "emlDrawQQPlot" anywhere in this file.
#
# The ruling calls the resulting non-draw public population 31 rows. This
# file computes it fresh, from REGISTRY.tsv, every run, and reports the
# count it gets -- it does not assert 31 as a floor and stop looking; a
# registry edit that changes the population is exactly the kind of drift
# this file exists to keep visible, so the 31 is CHECKED, not baked in.
#
# ---------------------------------------------------------------------------
# WHAT "COMPLIES" MEANS, MECHANICALLY, PER ROW
# ---------------------------------------------------------------------------
# The row's (file, name) resolves to exactly one `procedure NAME:` header in
# the plugin tree (the same resolution v155 CHECK 1 performs, reused here in
# miniature) with a matching `endproc`; the procedure's body, read as the
# lines between them, is then asked three questions:
#
#   (a) does it initialize .error$ to "" -- a line, not inside a comment,
#       matching (whitespace aside) `.error$ = ""` exactly, anchored so a
#       READ (`if .error$ = ""`, `elsif .consumed = 1 and .error$ = ""`) is
#       never mistaken for the write: the pattern requires the statement's
#       FIRST token to be `.error$` itself, which no read-in-a-condition
#       ever is.
#   (b) the same, for .warning$.
#   (c) every assignment to `.ok` in the body (same first-token anchoring,
#       so `if .ok = 1` -- a comparison -- is not counted) is inventoried;
#       the row complies only if there is EXACTLY ONE such assignment and
#       its right-hand side is, whitespace aside, `(.error$ = "")`. Zero
#       assignments, more than one, or one that reads `0`/`1`/anything else
#       are all named as violations -- multiplicity is itself the defect
#       this file is asked to catch (the "piecemeal ... at interior seams"
#       language in the task this file answers), not just wrong content.
#
# A row failing (a), (b) or (c) is reported by name, with which field and
# why. Concurrent work is landing in plugin_EML_StatsGraphs/ as this file is
# written and run (this file touches only validate/), so some rows are
# expected to still be non-compliant on a given run -- that is what makes
# the per-row, per-field report useful rather than a single pass/fail bit.
#
# ---------------------------------------------------------------------------
# THE SEEDED SELF-CHECK
# ---------------------------------------------------------------------------
# Because the population is derived from source text rather than driven
# through Praat, the demonstration that the detector actually fires does not
# need a copied tree or a live run (the mechanism v134 and v148 use for a
# call-site lint) -- it needs the SAME audit function applied to a synthetic
# procedure body that never touches disk. Three bodies are built in memory:
# a compliant one (must PASS), one missing its `.warning$` init (must FAIL,
# naming .warning$ and nothing else), and one with a piecemeal `.ok = 0` /
# `.ok = 1` pair instead of the single-exit derivation (must FAIL, naming
# .ok and reporting two assignments). Each is asserted to be classified
# correctly, so a change to the detector that stopped it firing would go red
# here before it could go quiet on the real population.
#
#     PRAAT=/usr/local/bin/praat6630 EML_PLUGIN_DIR=/path/to/plugin_EML_StatsGraphs \
#         Rscript validate/v165_outcome_contract_population.R
#
# Input: the plugin source itself (static text) and REGISTRY.tsv. No Praat
#        is driven -- PRAAT in the invocation above is accepted, like every
#        other validator's env, and simply unused. $EML_PLUGIN_DIR overrides
#        the tree read, matching v155/v162's convention.
#
# Base R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V <- "v165"

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
check_true(V, "the plugin tree is where this file expects it", dir.exists(plug))

registry_path <- file.path(plug, "REGISTRY.tsv")
check_true(V, "REGISTRY.tsv exists", file.exists(registry_path))

# ----------------------------------------------------------------------------
# Load the registry -- same convention v155 uses: strip `#`-prefixed and
# blank lines (the hand-written header block), read.delim the rest with
# quote = "" because the description column carries literal double quotes.
# ----------------------------------------------------------------------------
reg <- data.frame(name = character(0), file = character(0),
                   signature = character(0), description = character(0),
                   sources = character(0), stringsAsFactors = FALSE)
if (file.exists(registry_path)) {
    raw_lines <- readLines(registry_path, warn = FALSE)
    data_lines <- raw_lines[!grepl("^#", raw_lines) & nzchar(trimws(raw_lines))]
    reg <- read.delim(text = paste(data_lines, collapse = "\n"),
                       stringsAsFactors = FALSE, quote = "",
                       colClasses = "character")
}
check_true(V, "registry has the five columns the ruling asks for",
           identical(names(reg), c("name", "file", "signature", "description", "sources")))
check_true(V, "registry has at least one row", nrow(reg) >= 1)
check_true(V, "registry names are unique (no duplicate procedure rows)",
           !any(duplicated(reg$name)))

cat(sprintf("\nv165: REGISTRY.tsv: %d public rows total\n", nrow(reg)))

# ----------------------------------------------------------------------------
# THE CLASSIFIER -- sources set == {"2","3"} marks a type-dispatch draw row.
# See the header comment for why this is the registry's own column, not a
# name-prefix guess and not a copy of build_coverage_map.py's classify_kind.
# ----------------------------------------------------------------------------
source_set <- function(s) sort(unique(trimws(strsplit(s, ",", fixed = TRUE)[[1]])))

is_type_dispatch_draw <- function(name, sources) {
    identical(source_set(sources), c("2", "3"))
}

reg$is_dispatch <- mapply(is_type_dispatch_draw, reg$name, reg$sources)

dispatch_rows <- reg[reg$is_dispatch, , drop = FALSE]
nondraw_rows  <- reg[!reg$is_dispatch, , drop = FALSE]

check_true(V,
           sprintf("every type-dispatch row this classifier found is actually named emlDraw* (%d found)",
                   nrow(dispatch_rows)),
           nrow(dispatch_rows) == 0L || all(grepl("^emlDraw", dispatch_rows$name)))

cat(sprintf("v165: type-dispatch draw rows excluded (sources == {2,3}): %d\n", nrow(dispatch_rows)))
if (nrow(dispatch_rows)) cat(paste0("v165:   - ", dispatch_rows$name, "\n"), sep = "")

cat(sprintf("v165: NON-DRAW PUBLIC POPULATION: %d rows\n", nrow(nondraw_rows)))

check_true(V,
           sprintf("the non-draw public population is exactly the ruling's 31 rows (found %d)",
                   nrow(nondraw_rows)),
           nrow(nondraw_rows) == 31L)

# emlDrawQQPlot is the worked counter-example named in the header comment:
# it must survive the exclusion (sources == {2} alone, not {2,3}).
check_true(V,
           "emlDrawQQPlot (source {2} alone, explicitly NOT the type dispatch) stays IN the non-draw population",
           "emlDrawQQPlot" %in% nondraw_rows$name)

# ============================================================================
# THE PER-ROW, PER-FIELD AUDIT -- reusable on real source text or a
# synthetic in-memory body (the seeded self-check below uses the same
# function).
# ============================================================================

is_full_comment <- function(s) grepl("^\\s*[#;]", s) | !nzchar(trimws(s))
norm_ws <- function(s) trimws(gsub("\\s+", " ", s))

CANON_OK_RHS <- '(.error$ = "")'

# extract_body -- read plug/file, find the one `procedure NAME:` header and
# its `endproc`, return the lines between them inclusive. Mirrors v155's
# resolve_one, extended to capture the whole body rather than just the
# header line.
extract_body <- function(plug, file, name) {
    path <- file.path(plug, file)
    if (!file.exists(path))
        return(list(ok = FALSE, why = "file does not exist", lines = character(0)))
    lines <- readLines(path, warn = FALSE)
    hdr_pat <- paste0("^\\s*procedure\\s+", name, "\\s*(:|$)")
    hit <- which(grepl(hdr_pat, lines))
    if (length(hit) == 0L)
        return(list(ok = FALSE, why = "no `procedure` line found", lines = character(0)))
    if (length(hit) > 1L)
        return(list(ok = FALSE, why = sprintf("defined %d times (lines %s)",
                    length(hit), paste(hit, collapse = ", ")), lines = character(0)))
    start <- hit[1]
    rest  <- if (start < length(lines)) (start + 1L):length(lines) else integer(0)
    end_hit <- which(grepl("^\\s*endproc\\b", lines[rest]))
    if (length(end_hit) == 0L)
        return(list(ok = FALSE, why = "no matching `endproc` found", lines = character(0)))
    end <- rest[end_hit[1]]
    list(ok = TRUE, why = "", lines = lines[start:end], start = start, end = end)
}

# audit_body -- the three questions, on a body already extracted (real or
# synthetic). Returns a list with per-field verdicts and enough detail to
# print a useful FAIL line.
ERROR_INIT_RE   <- '^\\s*\\.error\\$\\s*=\\s*""\\s*$'
WARNING_INIT_RE <- '^\\s*\\.warning\\$\\s*=\\s*""\\s*$'
OK_ASSIGN_RE    <- '^\\s*\\.ok\\s*=\\s*(.+?)\\s*$'

audit_body <- function(body_lines) {
    code <- body_lines[!is_full_comment(body_lines)]

    has_error_init   <- any(grepl(ERROR_INIT_RE, code))
    has_warning_init <- any(grepl(WARNING_INIT_RE, code))

    ok_hits <- regmatches(code, regexec(OK_ASSIGN_RE, code))
    ok_lens <- vapply(ok_hits, length, integer(1))
    ok_idx  <- which(ok_lens == 2L)
    ok_rhs  <- vapply(ok_hits[ok_idx], `[`, character(1), 2)

    # The contract: exactly one single-exit derivation `.ok = (.error$ = "")`,
    # and no success-seam assignment (`.ok = 1` on a late branch) that competes
    # with it. A bare `.ok = 0` entry initializer, alongside the `.error$`/
    # `.warning$` inits, is tolerated: the single-exit derivation always
    # overwrites it, so it cannot report a stale outcome. Any other right-hand
    # side (a `.ok = 1`, or a value that is not the derivation or the "0" init)
    # is the piecemeal pattern this check catches.
    n_ok <- length(ok_idx)
    is_canon <- vapply(ok_rhs, function(x) identical(norm_ws(x), CANON_OK_RHS), logical(1))
    n_canon  <- sum(is_canon)
    others   <- norm_ws(ok_rhs[!is_canon])
    init_only_others <- all(others == "0")
    ok_canonical <- n_canon == 1L && init_only_others

    ok_why <- if (n_ok == 0L) {
        "no assignment to .ok found"
    } else if (n_canon == 0L) {
        sprintf("no single-exit derivation `.ok = %s` found; assignments: %s",
                CANON_OK_RHS, paste(sprintf("`.ok = %s`", ok_rhs), collapse = "; "))
    } else if (n_canon > 1L) {
        sprintf("%d single-exit derivations found, expected exactly 1", n_canon)
    } else if (!init_only_others) {
        sprintf("a competing .ok assignment sits beside the single-exit derivation (only a bare `.ok = 0` init is allowed): %s",
                paste(sprintf("`.ok = %s`", others[others != "0"]), collapse = "; "))
    } else ""

    list(error_ok = has_error_init, warning_ok = has_warning_init,
         ok_ok = ok_canonical, ok_why = ok_why, n_ok = n_ok, ok_rhs = ok_rhs,
         compliant = has_error_init && has_warning_init && ok_canonical)
}

# ----------------------------------------------------------------------------
# RUN THE AUDIT OVER THE REAL NON-DRAW POPULATION
# ----------------------------------------------------------------------------
nondraw_rows <- nondraw_rows[order(nondraw_rows$name), , drop = FALSE]
n_compliant <- 0L
n_resolved  <- 0L

for (k in seq_len(nrow(nondraw_rows))) {
    r <- nondraw_rows[k, ]
    body <- extract_body(plug, r$file, r$name)
    check_true(V, sprintf("[%s] resolves to exactly one procedure body in %s", r$name, r$file),
               body$ok)
    if (!body$ok) {
        cat(sprintf("v165:   %s: %s\n", r$name, body$why))
        next
    }
    n_resolved <- n_resolved + 1L
    a <- audit_body(body$lines)

    check_true(V, sprintf("[%s] initializes .error$ = \"\"", r$name), a$error_ok)
    check_true(V, sprintf("[%s] initializes .warning$ = \"\"", r$name), a$warning_ok)
    check_true(V, sprintf("[%s] derives .ok once via the single-exit form .ok = (.error$ = \"\")", r$name),
               a$ok_ok)

    missing <- character(0)
    if (!a$error_ok)   missing <- c(missing, ".error$ (no `.error$ = \"\"` init found)")
    if (!a$warning_ok) missing <- c(missing, ".warning$ (no `.warning$ = \"\"` init found)")
    if (!a$ok_ok)      missing <- c(missing, sprintf(".ok (%s)", a$ok_why))

    if (length(missing)) {
        cat(sprintf("v165: FAIL %s (%s:%d-%d) -- missing/non-compliant: %s\n",
                    r$name, r$file, body$start, body$end, paste(missing, collapse = "; ")))
    } else {
        n_compliant <- n_compliant + 1L
    }
}

cat(sprintf("\nv165: %d of %d non-draw public rows resolved; %d of those fully comply with the outcome contract.\n",
            n_resolved, nrow(nondraw_rows), n_compliant))

check_true(V,
           sprintf("every resolved row in the non-draw population was audited (%d audited)", n_resolved),
           n_resolved > 0L)

# ============================================================================
# THE TYPE-DISPATCH DRAW POPULATION -- the 14 emlDraw* rows this file's
# classifier excludes above (sources == {2,3}).
#
# WHY THIS IS HERE TOO, AND NOT JUST "NON-DRAW". The exclusion above exists
# because the ruling's 31-row population was, at the time this file was
# written, the only population that carried the contract: the fourteen
# graphs/eml-draw-procedures.praat type-dispatch branches wrote their
# diagnostics straight to the Info window and an on-figure disclosure box,
# with no .ok/.error$/.warning$ of their own. A wave since then gave each of
# the fourteen the identical single-exit contract, mirrored from the same
# diagnostic text they already emitted -- so the population this file
# audits is extended to match, rather than leaving the fourteen the one
# corner of the public surface this check never looks at again. The 31-row
# NON-DRAW assertion above is untouched: this is an ADDITIONAL population,
# audited with the identical audit_body(), not a redefinition of the first.
# ============================================================================

dispatch_rows <- dispatch_rows[order(dispatch_rows$name), , drop = FALSE]

check_true(V,
           sprintf("the type-dispatch draw population is exactly 14 rows (found %d)",
                   nrow(dispatch_rows)),
           nrow(dispatch_rows) == 14L)

n_draw_compliant <- 0L
n_draw_resolved  <- 0L

for (k in seq_len(nrow(dispatch_rows))) {
    r <- dispatch_rows[k, ]
    body <- extract_body(plug, r$file, r$name)
    check_true(V, sprintf("[%s] resolves to exactly one procedure body in %s", r$name, r$file),
               body$ok)
    if (!body$ok) {
        cat(sprintf("v165:   %s: %s\n", r$name, body$why))
        next
    }
    n_draw_resolved <- n_draw_resolved + 1L
    a <- audit_body(body$lines)

    check_true(V, sprintf("[%s] initializes .error$ = \"\"", r$name), a$error_ok)
    check_true(V, sprintf("[%s] initializes .warning$ = \"\"", r$name), a$warning_ok)
    check_true(V, sprintf("[%s] derives .ok once via the single-exit form .ok = (.error$ = \"\")", r$name),
               a$ok_ok)

    missing <- character(0)
    if (!a$error_ok)   missing <- c(missing, ".error$ (no `.error$ = \"\"` init found)")
    if (!a$warning_ok) missing <- c(missing, ".warning$ (no `.warning$ = \"\"` init found)")
    if (!a$ok_ok)      missing <- c(missing, sprintf(".ok (%s)", a$ok_why))

    if (length(missing)) {
        cat(sprintf("v165: FAIL %s (%s:%d-%d) -- missing/non-compliant: %s\n",
                    r$name, r$file, body$start, body$end, paste(missing, collapse = "; ")))
    } else {
        n_draw_compliant <- n_draw_compliant + 1L
    }
}

cat(sprintf("\nv165: %d of %d type-dispatch draw rows resolved; %d of those fully comply with the outcome contract.\n",
            n_draw_resolved, nrow(dispatch_rows), n_draw_compliant))

check_true(V,
           sprintf("every resolved row in the type-dispatch draw population was audited (%d audited)", n_draw_resolved),
           n_draw_resolved > 0L)

# ============================================================================
# THE SEEDED SELF-CHECK -- the audit function fires, on synthetic bodies
# that never touch disk.
# ============================================================================

seed_compliant <- c(
    "procedure v165_seed_ok: .x",
    '    .error$ = ""',
    '    .warning$ = ""',
    "    if .x < 0",
    '        .error$ = "x must be non-negative"',
    "    endif",
    "    .ok = (.error$ = \"\")",
    "endproc"
)

seed_missing_warning <- c(
    "procedure v165_seed_bad_warning: .x",
    '    .error$ = ""',
    "    if .x < 0",
    '        .error$ = "x must be non-negative"',
    "    endif",
    "    .ok = (.error$ = \"\")",
    "endproc"
)

seed_piecemeal_ok <- c(
    "procedure v165_seed_bad_ok: .x",
    '    .error$ = ""',
    '    .warning$ = ""',
    "    .ok = 0",
    "    if .x < 0",
    '        .error$ = "x must be non-negative"',
    "        goto v165_seed_bad_ok_end",
    "    endif",
    "    .ok = 1",
    "    label v165_seed_bad_ok_end",
    "endproc"
)

# Reference pattern: a bare `.ok = 0` entry init alongside the single-exit
# derivation. Tolerated -- the derivation always overwrites the init.
seed_init_deriv <- c(
    "procedure v165_seed_init_deriv: .x",
    '    .error$ = ""',
    '    .warning$ = ""',
    "    .ok = 0",
    "    if .x < 0",
    '        .error$ = "x must be non-negative"',
    "    endif",
    "    .ok = (.error$ = \"\")",
    "endproc"
)

# A `.ok = 1` success seam beside the derivation. Forbidden.
seed_seam_deriv <- c(
    "procedure v165_seed_seam_deriv: .x",
    '    .error$ = ""',
    '    .warning$ = ""',
    "    if .x >= 0",
    "        .ok = 1",
    "    endif",
    "    .ok = (.error$ = \"\")",
    "endproc"
)

a_ok    <- audit_body(seed_compliant)
a_warn  <- audit_body(seed_missing_warning)
a_pw    <- audit_body(seed_piecemeal_ok)
a_init  <- audit_body(seed_init_deriv)
a_seam  <- audit_body(seed_seam_deriv)

check_true(V, "[seed] a compliant synthetic body PASSES (positive control)",
           a_ok$compliant)

check_true(V, "[seed] a synthetic body missing the .warning$ init FAILS, and ONLY on .warning$",
           !a_warn$compliant && a_warn$error_ok && !a_warn$warning_ok && a_warn$ok_ok)

check_true(V, "[seed] a synthetic body with piecemeal `.ok = 0` / `.ok = 1` FAILS on .ok, with both assignments named",
           !a_pw$compliant && a_pw$error_ok && a_pw$warning_ok && !a_pw$ok_ok &&
               a_pw$n_ok == 2L && setequal(a_pw$ok_rhs, c("0", "1")))

check_true(V, "[seed] a bare `.ok = 0` entry init alongside the single-exit derivation PASSES",
           a_init$compliant && a_init$ok_ok)

check_true(V, "[seed] a `.ok = 1` success seam alongside the single-exit derivation FAILS on .ok",
           !a_seam$compliant && a_seam$error_ok && a_seam$warning_ok && !a_seam$ok_ok)

if (!a_warn$compliant) {
    cat(sprintf("v165: SEEDED VIOLATION, CAUGHT (missing .warning$): %s\n",
                paste(c(".error$" = a_warn$error_ok, ".warning$" = a_warn$warning_ok,
                        ".ok" = a_warn$ok_ok), collapse = " ")))
}
if (!a_pw$compliant) {
    cat(sprintf("v165: SEEDED VIOLATION, CAUGHT (piecemeal .ok): %s\n", a_pw$ok_why))
}

attest(V,
       "the seeded self-check demonstrates the detector, not just its plumbing",
       paste("Three synthetic procedure bodies are built in memory (never written to",
             "the plugin tree, which this file does not touch) and run through the",
             "identical audit_body() the real population above uses. A compliant body",
             "passes; a body missing `.warning$ = \"\"` fails naming exactly that field",
             "(its .error$ and .ok verdicts stay green); a body with `.ok = 0` at entry",
             "and `.ok = 1` on a late success branch -- the piecemeal pattern the",
             "single-exit rule exists to forbid -- fails naming .ok, with both",
             "right-hand sides (0 and 1) reported. All three assertions are checked",
             "above, not merely printed."))

if (!exists("EML_SUITE")) {
    eml_report("v165 -- the outcome-contract population")
    eml_exit()
}
