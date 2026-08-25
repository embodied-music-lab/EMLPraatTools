# ============================================================================
# v116 — the frozen-choice conformance lint
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# PUNCH LIST 8.4 / RISK REGISTER R4. THE RULE, in the punch list's own words:
#
#   An argument passed as a literal from a dialog into an analysis engine is
#   RED when any sibling door passes a user-bound choice for the same
#   parameter -- unless the fixed value is disclosed in the output.
#
# The disclosure carve-out is the important half: a frozen value is
# legitimate when the output states it. THIS CHECK TESTS FOR THE DISCLOSURE,
# NOT FOR THE FREEZE -- which doors freeze which parameter is not this
# file's question to answer. It is answered once, reviewed, and committed as
# docs/frozen-choice-map/correspondence-map.tsv (built and reviewed under
# R4's guard: author is never verifier on that fixture; this lint is a
# separate build consuming it, not the thing that produced it).
#
# ---------------------------------------------------------------------------
# THE MAP'S SHAPE, AS BUILT AND AS THIS CHECK CONSUMES IT
# ---------------------------------------------------------------------------
# Tab-separated, one row per (engine, parameter, door) correspondence:
#
#   engine   the shared procedure (orchestrator tier) or primitive (bridge
#            tier) that more than one door calls
#   param    the parameter name in that procedure's signature, or the
#            emlGraphsPreset*/annot* global standing in for it on the bridge
#            tier -- may carry a parenthetical annotation ("(4th positional
#            arg)", "(read from annotCorrectionMethod$)") which this check
#            strips before using the name to search source
#   tier     orchestrator | bridge
#   door     menu | wizard:<branch> | bridge:<draw path>
#   site     file:line of the call
#   binding  bound | literal
#   literal  the fixed value passed, or "-" when bound -- may carry a
#            trailing parenthetical annotation ("0 (Welch, always)") this
#            check also strips before matching
#   note     the map author's observations; NOT consumed by this check as a
#            ruling -- the map's own header says so explicitly, and this file
#            re-derives "disclosed" from source rather than trusting a note
#            written before the lint existed
#
# This file was written against that documented shape before the map landed,
# per the work order ("build against its shape ... say clearly what you
# assumed"). It landed complete (31 rows) while this check was being built;
# the assumed column set and ordering matched exactly, so nothing here is a
# guess reconciled after the fact. Stated for the record anyway, per the
# instruction to say so rather than silently adapt.
#
# ---------------------------------------------------------------------------
# STEP 1 -- WHICH ROWS ARE CANDIDATES AT ALL
# ---------------------------------------------------------------------------
# Grouping every row by (engine, normalized param): a row is a FROZEN
# CANDIDATE when its binding is "literal" AND at least one OTHER row in the
# same group, on the SAME invocation path (see door_kind below), binds the
# same parameter to a user choice ("bound"). This is the rule's own trigger
# condition, mechanically applied -- a literal that is frozen on EVERY door
# on its path (no sibling on that path ever binds it) sits outside 8.4 by
# the rule's own wording, and is excluded here exactly as the map's own
# notes exclude it (emlTTest's .equalVariances and emlOneWayAnova's .tukey,
# each literal on its one draw door with no draw-path sibling to disagree
# with, even though the SAME engine name also appears, unrelatedly, on an
# always-bound analysis path).
#
# The parameter name is NORMALIZED (base_name, defined below) before
# grouping rather than compared as the raw map cell -- the map's own three
# corrType$ rows write the parameter's annotation inconsistently
# (".corrType$ (read from annotCorrType$)" on one row, plain ".corrType$" on
# its sibling), and grouping on the raw string would silently split one
# correspondence into two one-row groups, neither able to trigger. That
# would have been this check's own blind spot, not the map's -- normalizing
# is this file's job.
#
# ---------------------------------------------------------------------------
# STEP 2 -- IS THE FROZEN VALUE DISCLOSED
# ---------------------------------------------------------------------------
# "Disclosed in the output" is tested as a DATA-FLOW question against the
# shipped source, not a documentation question against the map's notes:
# does the frozen parameter's own value -- or a value derived from it one
# call-hop away -- ever reach a call that WRITES TO THE READER (a raw text
# primitive, or one of the plugin's own @emlReport* family)?
#
# Three tiers, all textual, all recorded with their evidence site:
#
#   TIER A (direct).   A write-call's argument is a bare variable whose base
#     name (leading dots and trailing "$" stripped) equals the parameter's
#     own base name. The value itself is handed to the thing that prints.
#
#   TIER B (one hop).  Some assignment reads a called procedure's output
#     (`V = someProc.field$`), and within the same file, shortly before that
#     assignment, `@someProc:` was called with an argument whose base name
#     is the parameter's own -- exactly the plugin's own idiom for a
#     display-label transform (@emlAdjustMethodDisplay: .adjMethod$ then
#     .adjLabel$ = emlAdjustMethodDisplay.name$). If V then reaches a
#     write-call (Tier A applied to V), the parameter's value reached the
#     reader through one named, verifiable transform.
#
#   TIER C (literal text). A write-call's argument is a quoted string that
#     itself contains the frozen literal's own token, whole-word,
#     case-insensitive (`@emlReportLineString: "p adjustment", "Scheffe
#     (familywise, built in)"` discloses a frozen test$="scheffe" by simply
#     saying so). Skipped for a purely-numeric literal ("0", "1") -- a bare
#     digit inside quoted report text is noise, not evidence, and treating
#     it as a hit would be the unsafe direction.
#
# A candidate is DISCLOSED iff some tier hits; otherwise it is RED.
#
# ---------------------------------------------------------------------------
# WHAT THIS CANNOT SEE -- STATED PLAINLY, PER R4
# ---------------------------------------------------------------------------
# R4 names this check's own failure mode: a wrong map makes it noisy, an
# incomplete map makes it blind, and only blindness escapes the vacuity
# gate. The bias below is deliberately toward NOISE, never toward blindness,
# mirroring v113's own rule ("a condition it cannot decide is treated as
# possibly-taken"):
#
#   * ALL THREE TIERS ARE TREE-WIDE, NOT BRANCH-AWARE. A parameter disclosed
#     on the branch some OTHER door's call reaches, but silently dropped on
#     the branch THIS candidate's own call reaches, reads as disclosed here
#     on both. (Concretely: emlRunPairwiseAnalysis.adjMethod$="none" on the
#     Scheffe branch, which the map's own note says never reads .adjMethod$
#     at all, can still be found "disclosed" by this check because the
#     Welch/Student branch elsewhere in the same procedure does read it.)
#     This is a real blind spot. It is bounded in the SAFE direction only
#     when the sibling branch's disclosure is genuine; it is not proof for
#     the specific call this candidate names.
#   * TIER B IS ONE HOP ONLY, SAME FILE. A transform of a transform, or one
#     reached from a different file, is invisible to this check and will
#     read as undisclosed (the safe, noisy direction) even if a human
#     reader would call it disclosed.
#   * ARGUMENT SPLITTING is a plain comma split after the call's leading
#     colon -- a literal string argument containing a comma
#     (`@x: "a, b", y`) would be split wrong. None of the 31 shipped rows'
#     call sites do this (checked by hand while building this file), but a
#     future row could and this check would not notice the misparse.
#   * NOTHING HERE JUDGES WHETHER A DISCLOSURE IS ADEQUATE PROSE -- only
#     whether the value reaches a write call at all. "Adjustment: bh" would
#     count exactly as much as a full sentence explaining the freeze.
#
# Base R only. No packages.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

ID <- "v116"
MAP_FILE <- repo_path("docs", "frozen-choice-map", "correspondence-map.tsv")

# ---------------------------------------------------------------------------
# plugin_files -- the shipped tree, or a copy pointed at by EML_DIALOG_SRC,
# exactly the door v98/v113/v117 already use for their red demonstrations.
# ---------------------------------------------------------------------------
plugin_files <- function() {
    root <- Sys.getenv("EML_DIALOG_SRC", unset = "")
    if (!nzchar(root)) root <- repo_path("plugin_EML_StatsGraphs")
    if (!dir.exists(root)) stop("dialog source tree not found: ", root)
    f <- list.files(root, pattern = "\\.praat$", recursive = TRUE,
                    full.names = TRUE)
    f[!grepl("/dev/", f, fixed = TRUE)]
}

# ---------------------------------------------------------------------------
# parse_map -- the fixture, read as data, never edited by this file.
# ---------------------------------------------------------------------------
parse_map <- function(path) {
    if (!file.exists(path)) stop("correspondence map not found: ", path)
    raw <- readLines(path, warn = FALSE)
    body <- raw[!grepl("^#", raw) & nzchar(trimws(raw))]
    if (!length(body)) stop("correspondence map has no data rows: ", path)
    hdr <- strsplit(body[1], "\t", fixed = TRUE)[[1]]
    expect_hdr <- c("engine", "param", "tier", "door", "site", "binding",
                    "literal", "note")
    if (!identical(hdr, expect_hdr)) {
        stop(sprintf(
            "correspondence map header is %s; this check expects %s -- shape changed underneath it",
            paste(hdr, collapse = "|"), paste(expect_hdr, collapse = "|")))
    }
    rows <- lapply(body[-1], function(ln) {
        f <- strsplit(ln, "\t", fixed = TRUE)[[1]]
        if (length(f) != length(expect_hdr)) {
            stop(sprintf("malformed map row (%d fields, expected %d): %s",
                         length(f), length(expect_hdr), ln))
        }
        as.list(setNames(f, expect_hdr))
    })
    do.call(rbind.data.frame, c(rows, stringsAsFactors = FALSE))
}

# ---------------------------------------------------------------------------
# base_name -- the plain identifier a variable or a `param` cell's leading
# token names, stripped of leading dots, a trailing "$", and any
# parenthetical annotation the map cell carries.
# ---------------------------------------------------------------------------
base_name <- function(s) {
    s <- sub("\\s*\\(.*$", "", trimws(s))
    s <- sub("^\\.+", "", s)
    s <- sub("\\$$", "", s)
    tolower(s)
}

# literal_token -- the fixed value's own text, parenthetical annotation
# stripped, for Tier C's whole-word text search.
literal_token <- function(s) sub("\\s*\\(.*$", "", trimws(s))

# ---------------------------------------------------------------------------
# WRITE_RE -- a call that puts text in front of the reader: the plugin's own
# @emlReport* family, or a raw Praat text primitive.
# ---------------------------------------------------------------------------
WRITE_RE <- "(@\\w*[Rr]eport\\w*\\s*:|appendInfoLine\\s*:|writeInfoLine\\s*:|appendInfo\\s*:|\\bText\\s*:|Draw string\\s*:)"

strip_comment <- function(s) sub("(^|[^\\\\])#.*$", "\\1", s)

# call_args -- the arguments of one `@proc: a, b, c` / `Verb: a, b, c` call,
# split on top-level commas. A comma inside a quoted string is protected;
# nested parentheses/brackets are not, per this file's own stated limit.
call_args <- function(line) {
    rhs <- sub(paste0("^.*?", WRITE_RE, "\\s*"), "", line)
    if (!nchar(rhs)) return(character(0))
    out <- character(0); buf <- ""; in_str <- FALSE
    for (ch in strsplit(rhs, "")[[1]]) {
        if (ch == '"') in_str <- !in_str
        if (ch == "," && !in_str) { out <- c(out, buf); buf <- "" }
        else buf <- paste0(buf, ch)
    }
    out <- c(out, buf)
    trimws(out)
}

is_quoted <- function(a) grepl('^".*"$', a)
is_bare_id <- function(a) grepl("^[.A-Za-z_][A-Za-z0-9_.]*\\$?$", a)

word_in <- function(token, text) {
    if (!nchar(token)) return(FALSE)
    esc <- gsub("([.^$*+?()\\[\\]{}|\\\\])", "\\\\\\1", token, perl = TRUE)
    pat <- paste0("(^|[^A-Za-z0-9])", esc, "($|[^A-Za-z0-9])")
    grepl(pat, text, perl = TRUE, ignore.case = TRUE)
}

# ---------------------------------------------------------------------------
# index_writes -- every write-call in a set of files, with its arguments,
# for Tier A / Tier C, plus every `V = proc.field$` assignment paired with
# whatever `@proc:` call preceded it nearby, for Tier B.
# ---------------------------------------------------------------------------
index_writes <- function(files) {
    writes <- list()      # {file, line, text, args}
    hops    <- list()      # {var_base, via_proc, via_arg_base}
    for (f in files) {
        code <- readLines(f, warn = FALSE)
        for (i in seq_along(code)) {
            st <- strip_comment(code[i])
            if (grepl(WRITE_RE, st, perl = TRUE)) {
                writes[[length(writes) + 1L]] <- list(
                    file = f, line = i, text = trimws(code[i]),
                    args = call_args(st))
            }
            m <- regmatches(st, regexec(
                "^\\s*([.A-Za-z_][A-Za-z0-9_.]*\\$?)\\s*=\\s*([A-Za-z_][A-Za-z0-9_]*)\\.([A-Za-z_][A-Za-z0-9_]*\\$?)\\s*$",
                st))[[1]]
            if (length(m) == 4L) {
                v <- m[2]; proc <- m[3]
                lo <- max(1L, i - 20L)
                call_line <- NA_character_
                for (k in seq(i - 1L, lo)) {
                    if (grepl(paste0("@\\s*", proc, "\\s*:"), strip_comment(code[k]))) {
                        call_line <- strip_comment(code[k]); break
                    }
                }
                if (!is.na(call_line)) {
                    cargs <- strsplit(sub(paste0("^.*@\\s*", proc, "\\s*:\\s*"), "",
                                          call_line), ",", fixed = TRUE)[[1]]
                    cargs <- trimws(cargs)
                    arg_bases <- vapply(cargs[nzchar(cargs) & !is_quoted(cargs)],
                                        base_name, character(1))
                    if (length(arg_bases)) {
                        hops[[length(hops) + 1L]] <- list(
                            var_base = base_name(v), via_proc = proc,
                            via_arg_bases = arg_bases, file = f, line = i)
                    }
                }
            }
        }
    }
    list(writes = writes, hops = hops)
}

# disclosed_for -- Tiers A/B/C for one candidate row against one index.
disclosed_for <- function(param_base, literal_tok, idx) {
    numeric_literal <- grepl("^[0-9]+$", literal_tok)
    for (w in idx$writes) {
        for (a in w$args) {
            if (is_bare_id(a) && base_name(a) == param_base) {
                return(list(hit = TRUE, tier = "A",
                            evidence = sprintf("%s:%d  %s", basename(w$file), w$line, w$text)))
            }
            if (!numeric_literal && is_quoted(a) &&
                word_in(literal_tok, a)) {
                return(list(hit = TRUE, tier = "C",
                            evidence = sprintf("%s:%d  %s", basename(w$file), w$line, w$text)))
            }
        }
    }
    hop_vars <- Filter(function(h) param_base %in% h$via_arg_bases, idx$hops)
    if (length(hop_vars)) {
        hop_bases <- unique(vapply(hop_vars, function(h) h$var_base, character(1)))
        for (w in idx$writes) {
            for (a in w$args) {
                if (is_bare_id(a) && base_name(a) %in% hop_bases) {
                    h <- Filter(function(x) x$var_base == base_name(a), hop_vars)[[1]]
                    return(list(hit = TRUE, tier = "B",
                                evidence = sprintf(
                                    "%s:%d  %s  [%s <- %s.%s, called with %s at %s:%d]",
                                    basename(w$file), w$line, w$text,
                                    a, h$via_proc,
                                    "<field>", param_base, basename(h$file), h$line)))
                }
            }
        }
    }
    list(hit = FALSE, tier = NA_character_, evidence = NA_character_)
}

# door_kind -- which INVOCATION PATH a door's call travels. The map's own
# rows show the same engine name reused for two genuinely different calls
# under some params: the orchestrator/analysis path (door text carries "(via
# emlRun*Analysis)", never "draw") and the bridge/draw path (door text says
# "draw", or is prefixed "bridge:") that annotates a figure independently of
# the analysis run. A door on one path is not this rule's "sibling" of a
# door on the other -- the map's own notes say so by name for emlTTest and
# emlOneWayAnova ("no SIBLING door binds this parameter for the draw...
# outside 8.4's own trigger condition") and this function is what makes that
# reasoning mechanical instead of re-typed per row. Grouping WITHOUT this
# split would make emlTTest.equalVariances and emlOneWayAnova.tukey read as
# candidates on the strength of a menu/wizard door that binds a value for a
# call the literal row's door never reaches -- exactly the "wrong map is
# noisy" failure R4 names, self-inflicted rather than inherited from the
# fixture.
door_kind <- function(d) if (grepl("draw", d, ignore.case = TRUE) ||
                             grepl("^bridge:", d)) "draw" else "analysis"

# ---------------------------------------------------------------------------
# audit -- the whole check over one set of files, for one loaded map.
# ---------------------------------------------------------------------------
audit <- function(map, files) {
    idx <- index_writes(files)
    # Grouped on the NORMALIZED parameter name, not the raw cell text --
    # the map itself writes the same parameter's annotation inconsistently
    # across its own rows (".corrType$ (read from annotCorrType$)" on one
    # row, plain ".corrType$" on its sibling two rows down), and grouping on
    # the raw string would silently split one correspondence into two
    # groups of one, each with no sibling to trigger on. This is exactly
    # the kind of drift a hand-built fixture can carry even when reviewed;
    # normalizing here is this check's job, not a report against the map.
    key <- paste(map$engine, vapply(map$param, base_name, character(1)), sep = "")
    ukeys <- unique(key)
    candidates <- list()
    for (k in ukeys) {
        rows <- map[key == k, , drop = FALSE]
        lit_rows <- which(rows$binding == "literal")
        for (ri in lit_rows) {
            r <- rows[ri, ]
            rk <- door_kind(r$door)
            sib <- rows$door[rows$binding == "bound" &
                             vapply(rows$door, door_kind, character(1)) == rk]
            if (!length(sib)) next
            pb <- base_name(r$param)
            lt <- literal_token(r$literal)
            d <- disclosed_for(pb, lt, idx)
            candidates[[length(candidates) + 1L]] <- list(
                engine = r$engine, param = r$param, door = r$door,
                site = r$site, literal = r$literal,
                sibling_bound_doors = paste(sib, collapse = "; "),
                disclosed = d$hit, tier = d$tier, evidence = d$evidence)
        }
    }
    list(n_examined = nrow(map), candidates = candidates)
}

cand_key <- function(c) sprintf("%s|%s|%s|%s", c$engine, c$param, c$door, c$literal)

# ===========================================================================
# THE SHIPPED TREE
# ===========================================================================
eml_map <- parse_map(MAP_FILE)
shipped <- audit(eml_map, plugin_files())

n_examined  <- shipped$n_examined
n_frozen    <- length(shipped$candidates)
disclosed_n <- sum(vapply(shipped$candidates, function(c) c$disclosed, logical(1)))
red_n       <- n_frozen - disclosed_n

cat(sprintf(
"v116: %d correspondences examined (%s); %d are frozen-choice candidates (literal on one door, bound on a sibling).\n",
    n_examined, basename(MAP_FILE), n_frozen))
cat(sprintf(
"v116: of those %d candidates, %d are disclosed in the output and %d are NOT -- %d reddened.\n",
    n_frozen, disclosed_n, red_n, red_n))

for (c in shipped$candidates) {
    cat(sprintf("  %-28s %-14s door=%-38s literal=%-10s %s\n",
                c$engine, c$param, c$door, c$literal,
                if (c$disclosed) sprintf("DISCLOSED (tier %s)", c$tier) else "RED -- undisclosed"))
}

# ---------------------------------------------------------------------------
# GATE 1 -- THE VACUITY GATE R4 NAMES. A map that failed to load, or loaded
# empty, must not read as "nothing frozen" -- it must read as "this check
# examined nothing," which is a different and worse fact.
# ---------------------------------------------------------------------------
check_true(ID, sprintf("the correspondence map was read and examined at least one row (%d examined)",
                       n_examined),
           n_examined > 0L)

# ---------------------------------------------------------------------------
# GATE 2 -- the sweep found the frozen candidates the rule's own trigger
# condition defines. Zero here on a map that plainly documents seven frozen
# (engine,param) pairs would mean the grouping logic is broken, not that the
# plugin has no frozen choices.
# ---------------------------------------------------------------------------
check_true(ID, sprintf("the sweep found at least one frozen-choice candidate (%d found)", n_frozen),
           n_frozen > 0L)

# ---------------------------------------------------------------------------
# THE CENSUS OF UNDISCLOSED FROZEN CHOICES, PINNED
#
# Exactly v113's pattern: these are REAL, LIVE findings on the shipped tree
# as this check reads it today, not a hypothetical. They are pinned rather
# than asserted to zero because fixing them is not this lane's item --
# shipping the lint is. A site leaving this list is a fix and shrinks the
# pin in the same commit; a new site outside it is what turns the suite red.
# ---------------------------------------------------------------------------
PENDING_ADJUDICATION <- c(
    "emlDunnTest|.correction$|wizard:group draw (wizDrawSource$=\"group\")|holm (graphs form default)"
)

found_red <- vapply(Filter(function(c) !c$disclosed, shipped$candidates), cand_key, character(1))
new_red   <- sort(setdiff(found_red, PENDING_ADJUDICATION))
gone_red  <- sort(setdiff(PENDING_ADJUDICATION, found_red))

if (length(new_red)) {
    cat("UNDISCLOSED FROZEN CHOICES OUTSIDE THE PINNED SET:\n")
    cat(paste0("  ", new_red, "\n"))
}
check_true(ID, "every undisclosed frozen choice found is one already pinned for adjudication",
           length(new_red) == 0L)

if (length(gone_red)) {
    cat("PINNED SITES NO LONGER RED -- DELETE THEM FROM THE PIN (a fix landed):\n")
    cat(paste0("  ", gone_red, "\n"))
}
check_true(ID, sprintf("the pin matches what was actually found red (%d pinned, %d found)",
                       length(PENDING_ADJUDICATION), length(found_red)),
           length(gone_red) == 0L)

# ---------------------------------------------------------------------------
# GATE -- disclosure is not vacuous either: at least one candidate must
# actually be found disclosed on the shipped tree, or Tiers A/B/C would be
# proven dead code by the shipped tree's own shape.
# ---------------------------------------------------------------------------
check_true(ID, sprintf("at least one frozen candidate is found disclosed (%d of %d)",
                       disclosed_n, n_frozen),
           disclosed_n > 0L)

# ===========================================================================
# THE SEEDED VIOLATION
# ===========================================================================
# The disclosure mechanism itself is what a vacuous check would fake: a
# check that always says "disclosed" passes as surely as one that never
# looks. So a copy of the tree is seeded by REMOVING a disclosure this check
# currently finds real, and the same audit() is re-run against the copy
# through EML_DIALOG_SRC -- the same door v98/v113/v117 use -- unmodified.
#
# THE TARGET: emlRunPairwiseAnalysis.adjMethod$, wizard corrApproach=3
# (Welch-BH row), literal "bh". On the shipped tree this check finds it
# disclosed at Tier B: stats/eml-analysis.praat reads
#   .adjLabel$ = emlAdjustMethodDisplay.name$
# after calling `@emlAdjustMethodDisplay: .adjMethod$` (same base name,
# "adjMethod", as the frozen parameter), and .adjLabel$ then reaches
# `@emlReportLineString: "p adjustment", .adjLabel$` at both the
# Welch/Student pairwise-report call sites (:1247, :1406). Comment out both
# write-call lines in the copy: the parameter's value still gets a display
# label built, but that label no longer reaches anything that writes to the
# reader. Tier A does not apply here (.adjLabel$'s base is "adjLabel", not
# "adjMethod"); Tier C does not apply either ("bh" does not appear as
# literal report text anywhere in the tree, checked by hand). So Tier B is
# the only path to "disclosed" for this row, and removing its two sinks
# removes disclosure entirely -- this is not a check that happens to still
# pass some other way.
# ===========================================================================
seed_root <- file.path(tempdir(), "v116_seeded_tree")
unlink(seed_root, recursive = TRUE)

src_files <- plugin_files()
src_root  <- Sys.getenv("EML_DIALOG_SRC", unset = "")
if (!nzchar(src_root)) src_root <- repo_path("plugin_EML_StatsGraphs")
src_root  <- sub("/+$", "", src_root)
for (f in src_files) {
    rel <- sub(paste0("^", src_root, "/"), "", f)
    dst <- file.path(seed_root, rel)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    file.copy(f, dst, overwrite = TRUE)
}

seed_target <- file.path(seed_root, "stats", "eml-analysis.praat")
seed_ok <- FALSE
if (file.exists(seed_target)) {
    sl <- readLines(seed_target, warn = FALSE)
    hits <- grep('@emlReportLineString:\\s*"p adjustment",\\s*\\.adjLabel\\$', sl)
    if (length(hits) == 2L) {
        for (h in hits) sl[h] <- sub("@emlReportLineString", "# SEEDED-OUT @emlReportLineString", sl[h])
        writeLines(sl, seed_target)
        seed_ok <- TRUE
    }
}
check_true(ID, sprintf("the seeded tree's two disclosure sinks for .adjLabel$ were found and removed (%s)",
                       if (seed_ok) "ok" else "NOT FOUND -- source moved underneath this check"),
           seed_ok)

old_src <- Sys.getenv("EML_DIALOG_SRC", unset = NA)
Sys.setenv(EML_DIALOG_SRC = seed_root)
seeded <- audit(eml_map, plugin_files())
if (is.na(old_src)) Sys.unsetenv("EML_DIALOG_SRC") else
    Sys.setenv(EML_DIALOG_SRC = old_src)

check_true(ID, "EML_DIALOG_SRC pointed the same audit at the seeded copy",
           seeded$n_examined == shipped$n_examined)

TARGET_KEY <- "emlRunPairwiseAnalysis|adjMethod$|wizard:A2B (corrApproach=3, Welch-BH row)|bh"

ship_target <- Filter(function(c) cand_key(c) == TARGET_KEY, shipped$candidates)
seed_target_c <- Filter(function(c) cand_key(c) == TARGET_KEY, seeded$candidates)

check_true(ID, "the target correspondence is disclosed on the shipped tree before seeding",
           length(ship_target) == 1L && isTRUE(ship_target[[1]]$disclosed) &&
               identical(ship_target[[1]]$tier, "B"))

if (length(seed_target_c) == 1L) {
    cat(sprintf("\nSEEDED VIOLATION, CAUGHT:\n  %s\n  disclosed=%s (tier=%s)\n",
               TARGET_KEY, seed_target_c[[1]]$disclosed,
               if (is.na(seed_target_c[[1]]$tier)) "none" else seed_target_c[[1]]$tier))
}

check_true(ID, "the same correspondence is undisclosed -- RED -- on the seeded copy",
           length(seed_target_c) == 1L && isTRUE(!seed_target_c[[1]]$disclosed))

unlink(seed_root, recursive = TRUE)

if (!exists("EML_SUITE")) {
    eml_report("v116 the frozen-choice conformance lint"); eml_exit()
}
