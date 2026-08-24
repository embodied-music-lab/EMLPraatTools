# ============================================================================
# v113 — the escape hatch reads nothing the user typed
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE RULING, 24 August 2026. A dialog whose `endPause` ends in a NON-ZERO
# argument designates one of its buttons as the escape hatch: window-close
# maps to that button, and the plugin has twenty-odd such dialogs where that
# is a safe "never mind". They stay. The rule is AMENDED to:
#
#   THE ESCAPE HATCH IS PERMITTED ONLY WHERE ITS PATH READS NO TYPED FIELD
#   VALUES.
#
# WHY. Pressing the designated button DISCARDS THE WHOLE FORM. That is the
# measured behaviour (PKB APPENDIX_C §C.2, the field-variable caveat, quoted
# in v54: a zero cancel argument "ensures field variables are always updated
# regardless of which button is clicked" — a non-zero one therefore leaves
# them holding their PRIOR values on that one path out of the dialog). The
# discard is the reason the escape hatch is safe at all, and it stays safe
# only while the path taken on that press reads nothing the user typed. A
# cancel path that reads a field value is reading a variable THE FORM DID NOT
# COMMIT: whatever some earlier page, or the same page's previous pass, left
# in that global.
#
# Field variables are globals nothing unsets (v99's subject), so "reads no
# typed value" means, precisely: the cancel path reaches no read of THIS
# page's own field names before something reassigns them — either the page's
# own code, or the next dialog that declares them, which is where this
# check's walk stops.
#
# ---------------------------------------------------------------------------
# WHAT IS WALKED, AND WHAT THAT PROVES
# ---------------------------------------------------------------------------
# For every dialog block whose endPause carries a non-zero trailing argument
# C, and which stores the press in a variable, this walks the code after the
# endPause under the assumption `<returned> = C` and reports every read of one
# of that page's field names it can reach.
#
# The walk is CONSERVATIVE, in the only direction a safety check may be: a
# condition it cannot decide is treated as possibly-taken, so a read under it
# is reported. It can decide conditions that test the returned button —
# `clicked = 1`, `clicked <> 2`, `clicked = 3 or clicked = 4` — and nothing
# else. It follows `goto` to its `label`, stops on `exitScript`, and stops at
# the next `beginPause`/`form`, because a dialog that declares the name is
# what reassignment means here.
#
# CONDITIONS ARE READ WHOLE. MEASURED on 6.6.30, headless:
#
#     clicked = 1
#     if clicked = 4 and neverDeclaredVariable = 1
#     -> Error: Unknown variable
#
# and the same for `or`. Praat evaluates EVERY term of a condition before it
# decides the branch, so a field read in the second conjunct of a condition
# whose first conjunct is false on the cancel path IS PERFORMED on the cancel
# path. This is not the check being pessimistic; it is the language.
#
# Procedure calls on the cancel path are followed into their bodies, because
# an undotted name inside a procedure is the main-script global — the field
# variable itself.
#
# ---------------------------------------------------------------------------
# THE RESOLVER IS v98's, NOT A SECOND COPY
# ---------------------------------------------------------------------------
# Praat derives a field's variable name from its label by a rule that is not
# the tidying-up a reader expects, and v98_field_names.R implements it against
# measured probes. Re-deriving it here would give this check its own private
# idea of what a page's fields are called, and the two would drift.
#
# So v98's definitions are LOADED FROM v98's OWN TEXT at run time — parsed,
# and only the named function and constant assignments evaluated, so none of
# v98's own checks or output run. What is imported is listed in V98_IMPORTS
# and asserted below: if v98 renames one of them this file says so instead of
# quietly resolving nothing.
#
# That also brings in v98's block scanner, which matters for a reason beyond
# tidiness: A PROCEDURE CALLED FROM INSIDE A DIALOG BLOCK CONTRIBUTES ITS OWN
# FIELD ROWS TO THE CALLING PAGE. @emlWrapperCommonFields declares
# `boolean: "Clear Info window"` in one file and the row renders on ten
# wrapper pages. Those rows are part of the page, so they are part of this
# check's subject, and a scan that stopped at the lexical edge of the block
# would call a page clean that it had not finished reading.
#
# ---------------------------------------------------------------------------
# THE ANTI-VACUITY GATES — this check's own failure mode, named
# ---------------------------------------------------------------------------
# A conformance check that analyses nothing passes. Four gates, all asserted:
#
#   1. The v98 import produced every name in V98_IMPORTS.
#   2. The sweep found EXPECTED_SITES cancel-designated endPause sites and
#      WALKED every one of them. The count is printed, not only asserted.
#   3. The pages carry field names to look for — a resolver returning empty
#      name sets would make "reads none of them" true everywhere.
#   4. A SEEDED VIOLATION, planted in a COPY of the tree and audited through
#      the same code by the same door v98 uses (EML_DIALOG_SRC), goes red.
#
# Base R only. No packages.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V98_FILE <- repo_path("validate", "v98_field_names.R")

# The pieces of v98 this check stands on. FIELD_KINDS and praat_field_prefix
# are the derivation; scan_dialog_blocks / index_procedures / proc_fields are
# what make a page mean "everything rendered on it"; plugin_files is the
# EML_DIALOG_SRC door the seeded demonstration goes through.
V98_IMPORTS <- c("FIELD_KINDS", "praat_field_prefix", "FIELD_RE", "CALL_RE",
                 "branch_step", "stack_branch", "read_field",
                 "index_procedures", "proc_fields", "scan_dialog_blocks",
                 "plugin_files")

V98 <- new.env(parent = globalenv())
for (.e in parse(V98_FILE)) {
    if (is.call(.e) && length(.e) >= 3L &&
        identical(as.character(.e[[1]]), "<-")) {
        .nm <- as.character(.e[[2]])
        if (length(.nm) == 1L && .nm %in% V98_IMPORTS) eval(.e, V98)
    }
}
V98_MISSING <- setdiff(V98_IMPORTS, ls(V98))

# ---------------------------------------------------------------------------
# The readable form of a field name. v98's praat_field_prefix returns the
# stored name WITHOUT the "$" a string field appends; which suffixes exist is
# a property of the field's KIND, measured in v98's header: word / sentence /
# text / infile / outfile / folder bind name$; boolean / integer / real /
# positive / natural bind name; choice and optionmenu bind BOTH.
# ---------------------------------------------------------------------------
TEXT_KINDS <- c("word", "sentence", "text", "infile", "outfile", "folder")
DUAL_KINDS <- c("choice", "optionmenu")

readable_names <- function(prefix, kind) {
    if (kind %in% TEXT_KINDS) paste0(prefix, "$")
    else if (kind %in% DUAL_KINDS) c(prefix, paste0(prefix, "$"))
    else prefix
}

strip_literals <- function(s) gsub("\"[^\"]*\"", "\"\"", s)
is_comment <- function(s) grepl("^\\s*[#;]", s) || !nzchar(trimws(s))

STRUCT_RE <- paste0("^\\s*(if|elsif|elif|else|endif|for|endfor|while|endwhile",
                    "|repeat|until|procedure|endproc|label|goto|form|endform)\\b")

# The right-hand side of an assignment is the read; the left-hand side is a
# write. Splitting them is what lets `figure_width = left_Figure_size` be
# reported as a read of left_Figure_size and not of figure_width, and what
# lets a page that reassigns its own field before reading it come out clean.
split_assignment <- function(code) {
    if (grepl(STRUCT_RE, code)) return(list(rhs = code, lhs = NA_character_))
    m <- regexec("^\\s*([A-Za-z_.][A-Za-z0-9_.]*\\$?)(\\s*\\[[^]]*\\])?\\s*=(?!=)",
                 code, perl = TRUE)
    r <- regmatches(code, m)[[1]]
    if (length(r) >= 2L) list(rhs = substring(code, nchar(r[1]) + 1L), lhs = r[2])
    else list(rhs = code, lhs = NA_character_)
}

# A name is read when it appears as a whole identifier: not preceded by a
# letter, digit, underscore or dot (so `.folder$`, a procedure's own local,
# is not the form's `folder$`), and not continued by one (so `left_Value`
# does not match inside `left_Value_range`).
reads_in <- function(code, names) {
    if (!length(names)) return(character(0))
    keep <- logical(length(names))
    for (i in seq_along(names)) {
        n <- names[i]
        pat <- paste0("(^|[^A-Za-z0-9_.$])", gsub("\\$", "\\\\$", n),
                      if (grepl("\\$$", n)) "(?![A-Za-z0-9_])"
                      else "(?![A-Za-z0-9_$])")
        keep[i] <- grepl(pat, code, perl = TRUE)
    }
    names[keep]
}

# ---------------------------------------------------------------------------
# Is this condition true when the dialog returned the cancel button?
# TRUE / FALSE / NA, and NA means "this check cannot say", which the walker
# treats as possibly-taken.
#
# `and` and `or` are decomposed only so far as their TERMS: a term that names
# the returned button decides, anything else is NA. Parentheses anywhere in a
# term make it NA rather than guessed at.
# ---------------------------------------------------------------------------
term_truth <- function(term, retvar, cancel) {
    term <- trimws(term)
    v <- gsub("([.$])", "\\\\\\1", retvar)
    m <- regmatches(term, regexec(
        paste0("^", v, "\\s*(<>|>=|<=|==|=|>|<)\\s*([0-9]+)$"), term))[[1]]
    if (length(m) != 3L) return(NA)
    n <- as.integer(m[3])
    switch(m[2], "=" = cancel == n, "==" = cancel == n, "<>" = cancel != n,
           ">" = cancel > n, "<" = cancel < n, ">=" = cancel >= n,
           "<=" = cancel <= n, NA)
}

cond_truth <- function(cond, retvar, cancel) {
    if (is.na(retvar)) return(NA)
    cond <- trimws(sub("^\\s*(elsif|elif|if|while|until)\\s+", "", trimws(cond)))
    if (!nzchar(cond)) return(NA)
    ors <- strsplit(cond, "\\s+or\\s+")[[1]]
    ov <- vapply(ors, function(o) {
        ands <- strsplit(o, "\\s+and\\s+")[[1]]
        av <- vapply(ands, function(a)
            if (grepl("[()]", a)) NA else term_truth(a, retvar, cancel),
            logical(1))
        if (any(!is.na(av) & !av)) FALSE
        else if (all(!is.na(av))) all(av) else NA
    }, logical(1))
    if (any(!is.na(ov) & ov)) TRUE
    else if (all(!is.na(ov))) any(ov) else NA
}

# ---------------------------------------------------------------------------
# proc_reads — a procedure called on the cancel path, read for the page's
# field names. Not branch-aware inside the body, deliberately: a read
# anywhere in a procedure the cancel path calls is a read the cancel path can
# perform, and an undotted name in a procedure IS the main-script global.
# ---------------------------------------------------------------------------
proc_reads <- function(name, procs, danger, depth = 1L, chain = character(0)) {
    if (depth > 6L || name %in% chain)
        return(list(hits = list(), unresolved = character(0)))
    p <- procs[[name]]
    if (is.null(p)) return(list(hits = list(), unresolved = name))
    hits <- list(); unres <- character(0)
    for (k in seq_along(p$lines)) {
        raw <- p$lines[k]
        if (is_comment(raw)) next
        code <- strip_literals(raw)
        r <- reads_in(split_assignment(code)$rhs, danger)
        if (length(r))
            hits[[length(hits) + 1L]] <- list(
                file = p$file, line = p$first + k - 1L, names = r,
                text = trimws(raw), via = name)
        cm <- regmatches(code, regexec(V98$CALL_RE, code))[[1]]
        if (length(cm) == 3L) {
            s <- proc_reads(cm[3], procs, danger, depth + 1L, c(chain, name))
            hits <- c(hits, s$hits); unres <- c(unres, s$unresolved)
        }
    }
    list(hits = hits, unresolved = unres)
}

# ---------------------------------------------------------------------------
# walk_cancel — the cancel path of one dialog, from the line after its
# endPause to the point where the question stops being asked.
#
# STOP REASONS, all reported: the script exits; the next dialog opens (the
# fields are reassigned); the enclosing procedure ends; the walk leaves the
# `if` or the loop the endPause was written inside — beyond that the linear
# reading is no longer the cancel path and saying so is better than guessing;
# or the file ends.
# ---------------------------------------------------------------------------
walk_cancel <- function(code, start, retvar, cancel, fields, procs, file) {
    frames <- list(); danger <- fields; hits <- list(); unres <- character(0)
    seen_labels <- character(0)
    i <- start; stop_reason <- "the file ends"; nlines <- 0L

    outer_on <- function(upto) {
        if (upto < 1L) return(TRUE)
        !any(vapply(frames[seq_len(upto)],
                    function(f) identical(f$state, FALSE), logical(1)))
    }
    all_on   <- function() outer_on(length(frames))
    proven   <- function() length(frames) == 0L ||
        all(vapply(frames, function(f) isTRUE(f$state), logical(1)))

    while (i <= length(code)) {
        raw <- code[i]
        if (is_comment(raw)) { i <- i + 1L; next }
        st <- strip_literals(raw)

        if (grepl("(^|[^A-Za-z0-9_.])(beginPause|form)\\s*:", st)) {
            stop_reason <- "the next dialog opens and reassigns the fields"; break
        }
        if (grepl("^\\s*endproc\\b", st)) {
            stop_reason <- "the enclosing procedure ends"; break
        }
        if (grepl("^\\s*endif\\b", st)) {
            if (!length(frames)) {
                stop_reason <- "the walk left the endPause's own if-block"; break
            }
            frames[[length(frames)]] <- NULL; i <- i + 1L; next
        }
        if (grepl("^\\s*(until|endwhile|endfor)\\b", st)) {
            if (!length(frames)) {
                stop_reason <- "the walk left the endPause's own loop"; break
            }
            frames[[length(frames)]] <- NULL; i <- i + 1L; next
        }

        is_elsif <- grepl("^\\s*(elsif|elif)\\b", st)
        is_else  <- grepl("^\\s*else\\b", st)

        # An elsif's CONDITION runs only when no earlier arm was taken, so it
        # is judged against the frames outside it plus that fact — not against
        # the arm the frame is still carrying.
        on <- if (is_elsif || is_else)
            outer_on(length(frames) - 1L) &&
                (!length(frames) || !isTRUE(frames[[length(frames)]]$decided))
        else all_on()

        if (on) {
            nlines <- nlines + 1L
            sp <- split_assignment(st)
            r <- reads_in(sp$rhs, danger)
            if (length(r))
                hits[[length(hits) + 1L]] <- list(
                    file = file, line = i, names = r, text = trimws(raw),
                    via = NA_character_)
            cm <- regmatches(st, regexec(V98$CALL_RE, st))[[1]]
            if (length(cm) == 3L) {
                s <- proc_reads(cm[3], procs, danger)
                for (h in s$hits) { h$callsite <- i
                                    hits[[length(hits) + 1L]] <- h }
                unres <- c(unres, s$unresolved)
            }
            # Assigned here, so from the next line on it holds a value this
            # path put there — "before they are reassigned" made mechanical.
            if (!is.na(sp$lhs)) danger <- setdiff(danger, sp$lhs)

            if (proven() && !is_elsif && !is_else) {
                if (grepl("^\\s*exitScript\\b", st)) {
                    stop_reason <- "the cancel path exits the script"; break
                }
                g <- regmatches(st, regexec("^\\s*goto\\s+([A-Za-z0-9_]+)",
                                            st))[[1]]
                if (length(g) == 2L) {
                    if (g[2] %in% seen_labels) {
                        stop_reason <- "the cancel path's goto revisits a label"
                        break
                    }
                    seen_labels <- c(seen_labels, g[2])
                    tgt <- grep(paste0("^\\s*label\\s+", g[2], "\\s*$"), code)
                    if (!length(tgt)) {
                        stop_reason <- paste0("goto ", g[2], " names no label")
                        break
                    }
                    frames <- list(); i <- tgt[1] + 1L; next
                }
            }
        }

        if (is_elsif) {
            if (length(frames)) {
                f <- frames[[length(frames)]]
                t <- if (isTRUE(f$decided)) FALSE
                     else if (isTRUE(f$anyNA)) NA
                     else cond_truth(st, retvar, cancel)
                f$state <- t
                f$decided <- isTRUE(f$decided) || isTRUE(t)
                f$anyNA <- isTRUE(f$anyNA) || is.na(t)
                frames[[length(frames)]] <- f
            }
        } else if (is_else) {
            if (length(frames)) {
                f <- frames[[length(frames)]]
                f$state <- if (isTRUE(f$decided)) FALSE
                           else if (isTRUE(f$anyNA)) NA else TRUE
                frames[[length(frames)]] <- f
            }
        } else if (grepl("^\\s*if\\b", st)) {
            t <- cond_truth(st, retvar, cancel)
            frames[[length(frames) + 1L]] <-
                list(state = t, decided = isTRUE(t), anyNA = is.na(t))
        } else if (grepl("^\\s*repeat\\b", st)) {
            frames[[length(frames) + 1L]] <-
                list(state = TRUE, decided = FALSE, anyNA = TRUE)
        } else if (grepl("^\\s*(while|for)\\b", st)) {
            frames[[length(frames) + 1L]] <-
                list(state = NA, decided = FALSE, anyNA = TRUE)
        }
        i <- i + 1L
    }
    list(hits = hits, unresolved = unres, stop = stop_reason, lines = nlines)
}

# ---------------------------------------------------------------------------
# audit_files — the whole check over any set of Praat sources. The seeded
# demonstration runs through this same function, so a rule relaxed until the
# tree passes relaxes on the seed too, and the seed turns red.
# ---------------------------------------------------------------------------
audit_files <- function(files) {
    procs <- V98$index_procedures(files)
    sites <- list(); malformed <- character(0)
    n_endpause <- 0L; n_names <- 0L; n_fieldless <- 0L

    for (f in files) {
        sc <- V98$scan_dialog_blocks(f, procs)
        code <- readLines(f, warn = FALSE)
        for (b in sc$blocks) {
            ln <- code[b$end]
            st <- strip_literals(ln)
            if (!grepl("(^|[^A-Za-z0-9_.$])endPause\\s*:", st)) next
            n_endpause <- n_endpause + 1L
            args <- trimws(strsplit(sub("^.*endPause\\s*:", "", st), ",")[[1]])
            last <- args[length(args)]
            if (!grepl("^[0-9]+$", last)) {
                malformed <- c(malformed, sprintf("%s:%d  %s", basename(f),
                                                  b$end, trimws(ln)))
                next
            }
            cancel <- as.integer(last)
            if (cancel == 0L) next

            rv <- regmatches(ln, regexec(
                "^\\s*([A-Za-z_.][A-Za-z0-9_.]*)\\s*=\\s*endPause", ln))[[1]]
            retvar <- if (length(rv) == 2L) rv[2] else NA_character_
            nm <- unique(unlist(lapply(b$fields, function(x)
                readable_names(x$prefix, x$kind))))
            if (is.null(nm)) nm <- character(0)
            n_names <- n_names + length(nm)
            if (!length(nm)) n_fieldless <- n_fieldless + 1L

            w <- walk_cancel(code, b$end + 1L, retvar, cancel, nm, procs, f)
            sites[[length(sites) + 1L]] <- list(
                file = f, line = b$end, cancel = cancel, retvar = retvar,
                text = trimws(ln), names = nm, nfields = length(b$fields),
                hits = w$hits, stop = w$stop, walked = w$lines,
                unresolved = w$unresolved)
        }
    }
    list(sites = sites, n_endpause = n_endpause, n_names = n_names,
         n_fieldless = n_fieldless, malformed = malformed, procs = procs)
}

# A site's fingerprint, for pinning. Line numbers are deliberately NOT in it —
# editing the file above a site must not turn this red — and neither is the
# read's own line. What identifies a site is the file, the endPause as
# written, and the exact set of field names its cancel path reaches.
site_key <- function(s) sprintf("%s|%s|%s", basename(s$file), s$text,
                                paste(sort(unique(unlist(
                                    lapply(s$hits, function(h) h$names)))),
                                    collapse = ","))

violating <- function(a) Filter(function(s) length(s$hits) > 0L, a$sites)

# ---------------------------------------------------------------------------
# THE TEACHING MESSAGE. The rule, the why, and the house idiom — at the site,
# in the ruling's own words, so a session that has read nothing else can act
# on it.
# ---------------------------------------------------------------------------
teach <- function(s) {
    out <- sprintf("%s:%d  cancel path reads %s\n", basename(s$file), s$line,
                   paste(sort(unique(unlist(lapply(s$hits, function(h) h$names)))),
                         collapse = ", "))
    out <- paste0(out, sprintf(
"  Rule: an endPause with a cancel designation (trailing %d, not 0) may take
        that path only where the path reads NO typed field value.
  Why:  pressing the designated button DISCARDS THE WHOLE FORM. On this
        path %s still holds what some earlier page left
        there — a variable the form did not commit.
  Fix:  put the cancel guard FIRST and let it leave —
            %s = endPause: ... , %d
            if %s = %d
                <go back / exitScript / goto>
            endif
        and move every read of a field below it. If the read must happen on
        both paths, it is not a cancel path: pass 0 as the trailing argument
        instead, which makes Praat commit the fields on every button.\n",
        s$cancel,
        if (is.na(s$retvar)) "the field" else "each name above",
        if (is.na(s$retvar)) "clicked" else s$retvar, s$cancel,
        if (is.na(s$retvar)) "clicked" else s$retvar, s$cancel))
    for (h in s$hits)
        out <- paste0(out, sprintf("      %s:%d  %s%s\n", basename(h$file),
                                   h$line, substr(h$text, 1, 78),
                                   if (is.na(h$via)) ""
                                   else sprintf("   [inside @%s]", h$via)))
    out
}

# ===========================================================================
# THE SHIPPED TREE
# ===========================================================================
shipped <- audit_files(V98$plugin_files())

cat(sprintf(
"v113: %d endPause sites; %d carry a cancel designation and ALL %d WERE WALKED.\n",
    shipped$n_endpause, length(shipped$sites), length(shipped$sites)))
cat(sprintf(
"v113: those pages declare %d field names; %d cancel paths reach none of them; %d do.\n",
    shipped$n_names,
    length(shipped$sites) - length(violating(shipped)),
    length(violating(shipped))))

for (s in shipped$sites)
    cat(sprintf("  %-24s:%-6d cancel=%d  fields=%-3d walked=%-4d reads=%-2d  stop: %s\n",
                basename(s$file), s$line, s$cancel, s$nfields, s$walked,
                length(s$hits), s$stop))

# ---------------------------------------------------------------------------
# HOW MANY THERE ARE. The 24 Aug ruling speaks of twenty-four such dialogs;
# the tree at the time this check was written carries TWENTY-THREE, and the
# gap is recorded here rather than rounded away. Pinned so that a dialog
# gaining or losing its escape hatch is a decision somebody makes on purpose.
# ---------------------------------------------------------------------------
RULING_SITES   <- 24L
EXPECTED_SITES <- 23L

check_true("v113", "the v98 field-name resolver was imported, entire",
           length(V98_MISSING) == 0L)
if (length(V98_MISSING))
    cat("v98 NO LONGER DEFINES:", paste(V98_MISSING, collapse = ", "), "\n")

check_true("v113",
           sprintf("the sweep walked at least one cancel path (%d walked)",
                   length(shipped$sites)),
           length(shipped$sites) > 0L)
check_true("v113",
           sprintf("every cancel-designated endPause in the tree was walked (%d of %d; the ruling counts %d)",
                   length(shipped$sites), EXPECTED_SITES, RULING_SITES),
           length(shipped$sites) == EXPECTED_SITES)

# Gate 3. Names to look for. Without this the whole check passes on a
# resolver that returns nothing.
check_true("v113",
           sprintf("the pages carrying a cancel designation declare field names to look for (%d)",
                   shipped$n_names),
           shipped$n_names >= 200L)

# eml-record-start's confirm page is comments and buttons only — no field,
# so nothing to read. It is the ONE such page, pinned: a second one is far
# more likely to be the scanner losing a page's rows than a second page of
# pure prose.
check_true("v113",
           sprintf("exactly one cancel-designated page declares no field at all (%d)",
                   shipped$n_fieldless),
           shipped$n_fieldless == 1L)

if (length(shipped$malformed)) {
    cat("endPause SITES THIS CHECK COULD NOT READ:\n")
    cat(paste0("  ", shipped$malformed, "\n"))
}
check_true("v113", "every endPause site's trailing argument was readable",
           length(shipped$malformed) == 0L)

unres <- unique(unlist(lapply(shipped$sites, function(s) s$unresolved)))
if (length(unres)) {
    cat("PROCEDURES A CANCEL PATH CALLS AND THIS SWEEP COULD NOT READ:\n")
    cat(paste0("  @", unres, "\n"))
}
check_true("v113",
           "every procedure a cancel path calls was found and read",
           length(unres) == 0L)

# ===========================================================================
# THE CENSUS OF CANCEL PATHS THAT DO READ A FIELD VALUE
# ===========================================================================
# EVERY ONE OF THESE IS THE SANCTIONED REMAP BLOCK, and that is the finding,
# not an excuse. RULING_DIALOG_COMPACTION §1 requires each page to copy its
# label-derived names to its canonical variables "directly after endPause,
# before any commit logic". Written there, the copy runs on the cancel press
# too, and it reads exactly the values the cancel press discarded.
#
# SO THE TWO RULINGS DISAGREE, and this check is not the place to pick a
# winner. The change order's own device applies: the conflict is enumerated
# AS DATA, per site, with the reason, and marked PENDING ADJUDICATION, so its
# presence reads as a decision rather than a gap. Ian rules; the pin is then
# emptied or the sites are fixed, in the same commit.
#
# The fix, if the escape hatch wins, is one line of movement per page: put
# the remap block INSIDE the non-cancel arm — every one of these pages
# already has an `if <clicked> = 1` immediately below it, and every canonical
# variable the remap writes is re-seeded before it is used again.
#
# Two entries carry a second reason, and they are the ones to read first:
#
#   * the six pages that call `@emlComparisonFromMenu: comparison` before the
#     guard pass a discarded field value INTO A PROCEDURE on the cancel path;
#   * the multi-series page reads `colName$[time_column]` inside the second
#     conjunct of `if clicked = 4 and ...`. Praat evaluates both conjuncts —
#     measured, see the header — so that read happens on the cancel path even
#     though the branch is not taken.
#
# Keyed on file, endPause text and the names reached; NOT on line numbers.
# ---------------------------------------------------------------------------
PENDING_ADJUDICATION <- c(
# eml-graphs-form.praat, main page — figure size and panel origin remap
'eml-graphs-form.praat|clicked = endPause: "Quit", "Continue", 2, 1|left_Figure_size,left_Panel_origin,right_Figure_size,right_Panel_origin',
# F0 / pitch page
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1|left_Axis_labels$,left_Frequency,left_Pitch,left_Time,right_Axis_labels$,right_Frequency,right_Pitch,right_Time',
# waveform page
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1|left_Amplitude,left_Axis_labels$,left_Time,right_Amplitude,right_Axis_labels$,right_Time',
# spectrum page and LTAS page — same remap, two pages
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1|left_Axis_labels$,left_Frequency,left_Power,right_Axis_labels$,right_Frequency,right_Power',
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", toggleLabel$, "Draw", 4, 1|left_Axis_labels$,left_Frequency,left_Power,right_Axis_labels$,right_Frequency,right_Power',
# multi-series page — remap, plus the second-conjunct read of time_column
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", tsToggleLabel$, "Draw", 4, 1|left_Axis_labels$,left_Time,left_Value,right_Axis_labels$,right_Time,right_Value,time_column',
# bar, violin, box, histogram, grouped violin, grouped box — remap plus the
# comparison menu handed to @emlComparisonFromMenu before the guard
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", barToggleLabel$, "Draw", 4, 1|comparison,left_Axis_labels$,left_Value,right_Axis_labels$,right_Value',
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", violinToggleLabel$, "Draw", 4, 1|comparison,left_Axis_labels$,left_Value,right_Axis_labels$,right_Value',
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", boxToggleLabel$, "Draw", 4, 1|comparison,left_Axis_labels$,left_Value,right_Axis_labels$,right_Value',
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", histToggleLabel$, "Draw", 4, 1|comparison,left_Axis_labels$,left_Value,right_Axis_labels$,right_Value',
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", gvToggleLabel$, "Draw", 4, 1|comparison,left_Axis_labels$,left_Value,right_Axis_labels$,right_Value',
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", gbToggleLabel$, "Draw", 4, 1|comparison,left_Axis_labels$,left_Value,right_Axis_labels$,right_Value',
# scatter page
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", scatterToggleLabel$, "Draw", 4, 1|left_Axis_labels$,left_X,left_Y,right_Axis_labels$,right_X,right_Y',
# spaghetti page
'eml-graphs-form.praat|clicked = endPause: "Go Back", "Quit", spToggleLabel$, "Draw", 4, 1|left_Axis_labels$,left_Value,right_Axis_labels$,right_Value'
)

found <- vapply(violating(shipped), site_key, character(1))
new_reads <- sort(setdiff(found, PENDING_ADJUDICATION))
gone <- sort(setdiff(PENDING_ADJUDICATION, found))

if (length(violating(shipped))) {
    cat(sprintf(
"\nCANCEL PATHS THAT READ A TYPED FIELD VALUE — %d of %d sites:\n\n",
        length(violating(shipped)), length(shipped$sites)))
    for (s in violating(shipped)) cat(teach(s), "\n")
}

# THE RULE ITSELF. Anything not in the pinned, pending-adjudication set is a
# plain violation of the amended ruling and goes red here.
if (length(new_reads)) {
    cat("CANCEL PATHS READING A FIELD VALUE OUTSIDE THE PENDING SET:\n")
    cat(paste0("  ", new_reads, "\n"))
}
check_true("v113",
           "no cancel path reads a typed field value except the sites pinned as pending adjudication",
           length(new_reads) == 0L)

# And the pin cannot rot the other way: a site that stops reading is a FIX,
# and a fix trims this list in the same commit that lands it.
if (length(gone)) {
    cat("PINNED SITES THAT NO LONGER READ A FIELD — DELETE THEM FROM THE PIN:\n")
    cat(paste0("  ", gone, "\n"))
}
check_true("v113",
           sprintf("the pending-adjudication set is exactly the sites that read (%d pinned, %d found)",
                   length(PENDING_ADJUDICATION), length(found)),
           length(gone) == 0L && length(found) == length(PENDING_ADJUDICATION))

# The nine that are already clean are the ruling's own standard, met. Named
# as a count so that a page falling out of it is visible in the summary line
# and not only in the census above.
check_true("v113",
           sprintf("%d cancel paths reach no read of their page's fields at all",
                   length(shipped$sites) - length(violating(shipped))),
           length(shipped$sites) - length(violating(shipped)) ==
               EXPECTED_SITES - length(PENDING_ADJUDICATION))

# ---------------------------------------------------------------------------
# WHERE THE WALK STOPS, AND WHAT THAT LEAVES UNSAID.
#
# A walk that ends on `exitScript`, on the next dialog, or at the end of the
# enclosing procedure has followed the cancel path to somewhere the question
# stops being asked. A walk that ends because it ran out of the `if` or the
# loop the endPause was written inside has NOT: control continues, and this
# check does not model where. Those sites are named rather than counted as
# clean-by-exhaustion, and the count is pinned so a page that starts relying
# on the unwalked remainder is visible.
#
# All five are graphs-form pages whose cancel arm sets a `...FormDone` flag
# and falls out of the page's own `repeat`. Four of them already appear in the
# pending set below, for reads found BEFORE the boundary, so nothing rests on
# the unwalked remainder there. The fifth — the second-axis page — reaches the
# boundary having read nothing, and is the one site counted clean on a walk
# that did not run to a decisive end. It is named here for that reason.
# ---------------------------------------------------------------------------
STRUCTURAL_STOPS <- c("the walk left the endPause's own if-block",
                      "the walk left the endPause's own loop")
partial <- Filter(function(s) s$stop %in% STRUCTURAL_STOPS, shipped$sites)
if (length(partial)) {
    cat("CANCEL PATHS WALKED ONLY TO A STRUCTURAL BOUNDARY:\n")
    for (s in partial)
        cat(sprintf("  %s:%d  %s  (%d read%s found before it)\n",
                    basename(s$file), s$line, s$stop, length(s$hits),
                    if (length(s$hits) == 1L) "" else "s"))
}
check_true("v113",
           sprintf("the walks that stop at a structural boundary are the %d known ones",
                   length(partial)),
           length(partial) == 5L)

# ---------------------------------------------------------------------------
# GATE 5 — "CLEAN" MUST MEAN THE GUARD WORKED, NOT THAT THERE WAS NOTHING TO
# FIND. For every site the walk cleared, look at the code just below it with
# the walk's branch reasoning switched OFF. A page whose fields are read a few
# lines under its cancel guard, and that still comes out clean, is a page
# where the guard is doing the work — which is the property being asserted.
# If none of the clean sites had a read below them at all, this check would be
# passing on nine pages that never touch their own fields, and the reader
# should know that.
# ---------------------------------------------------------------------------
guard_did_work <- 0L
guard_names <- character(0)
for (s in shipped$sites) {
    if (length(s$hits)) next
    code <- readLines(s$file, warn = FALSE)
    span <- seq(s$line + 1L, min(s$line + 80L, length(code)))
    got <- character(0)
    for (i in span) {
        if (is_comment(code[i])) next
        got <- c(got, reads_in(split_assignment(strip_literals(code[i]))$rhs,
                               s$names))
    }
    if (length(got)) {
        guard_did_work <- guard_did_work + 1L
        guard_names <- c(guard_names, sprintf("%s:%d reads %s below its guard",
                                              basename(s$file), s$line,
                                              paste(unique(got), collapse = ", ")))
    }
}
cat("CLEAN SITES WHOSE FIELDS ARE READ JUST BELOW THE CANCEL GUARD:\n")
cat(paste0("  ", guard_names, "\n"))
check_true("v113",
           sprintf("the cancel guard is what clears these pages, not an absence of reads (%d of %d clean sites read their fields below the guard)",
                   guard_did_work,
                   length(shipped$sites) - length(violating(shipped))),
           guard_did_work ==
               length(shipped$sites) - length(violating(shipped)) -
               shipped$n_fieldless)

# ===========================================================================
# THE SEEDED VIOLATION
# ===========================================================================
# A vacuous pass is this check's failure mode, and the ruling says so. So the
# check is run, unmodified, over a COPY of the plugin with one field read
# planted on a cancel path that is clean in the shipped tree — through
# EML_DIALOG_SRC, the same door v98's red demonstrations use, so what is
# demonstrated is this file's own failure and not a rehearsal of it.
#
# The site: eml-check-data.praat's repair page. Shipped, its cancel arm is
#     if clicked = 1
#         exitScript: ""
#     endif
# and the walk ends there with nothing read. The seed puts a read of
# `repair_comma_cells` — a boolean declared on that very page — INSIDE the
# cancel arm. Nothing else in the tree is touched.
# ===========================================================================
seed_root <- file.path(tempdir(), "v113_seeded_tree")
unlink(seed_root, recursive = TRUE)

src_files <- V98$plugin_files()
# The root the copy is made FROM is whatever tree plugin_files() just read —
# the shipped one, or another EML_DIALOG_SRC already points at — so the
# relative layout of the copy matches the original either way.
src_root  <- Sys.getenv("EML_DIALOG_SRC", unset = "")
if (!nzchar(src_root)) src_root <- repo_path("plugin_EML_StatsGraphs")
src_root  <- sub("/+$", "", src_root)
for (f in src_files) {
    rel <- sub(paste0("^", src_root, "/"), "", f)
    dst <- file.path(seed_root, rel)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    file.copy(f, dst, overwrite = TRUE)
}

seed_target <- file.path(seed_root, "scripts", "eml-check-data.praat")
seed_ok <- FALSE
if (file.exists(seed_target)) {
    sl <- readLines(seed_target, warn = FALSE)
    at <- grep('^clicked = endPause: "Cancel", "Repair", 2, 1$', sl)
    if (length(at) == 1L && grepl("^if clicked = 1$", sl[at + 1L])) {
        sl <- append(sl, "    writeInfoLine: repair_comma_cells", after = at + 1L)
        writeLines(sl, seed_target)
        seed_ok <- TRUE
    }
}
check_true("v113",
           "the seeded violation was planted on a cancel path that is clean in the shipped tree",
           seed_ok)

old_src <- Sys.getenv("EML_DIALOG_SRC", unset = NA)
Sys.setenv(EML_DIALOG_SRC = seed_root)
seeded <- audit_files(V98$plugin_files())
if (is.na(old_src)) Sys.unsetenv("EML_DIALOG_SRC") else
    Sys.setenv(EML_DIALOG_SRC = old_src)

check_true("v113",
           "EML_DIALOG_SRC pointed the same sweep at the seeded copy",
           length(seeded$sites) == length(shipped$sites))

seed_site <- Filter(function(s)
    basename(s$file) == "eml-check-data.praat" && grepl('"Repair"', s$text),
    seeded$sites)
seed_hits <- if (length(seed_site) == 1L) seed_site[[1]]$hits else list()

if (length(seed_hits)) { cat("SEEDED VIOLATION, CAUGHT:\n"); cat(teach(seed_site[[1]]), "\n") }

check_true("v113",
           "the seeded read is caught on the seeded tree",
           length(seed_site) == 1L && length(seed_hits) == 1L &&
               identical(seed_hits[[1]]$names, "repair_comma_cells"))

seeded_new <- setdiff(vapply(violating(seeded), site_key, character(1)),
                      PENDING_ADJUDICATION)
check_true("v113",
           "the seeded tree fails the rule this check enforces",
           length(seeded_new) == 1L &&
               grepl("eml-check-data.praat", seeded_new[1], fixed = TRUE))

# The same site in the SHIPPED tree is clean — without this the demonstration
# would prove only that the site reads a field, not that seeding made it.
ship_site <- Filter(function(s)
    basename(s$file) == "eml-check-data.praat" && grepl('"Repair"', s$text),
    shipped$sites)
check_true("v113",
           "that same cancel path is clean before the seed is planted",
           length(ship_site) == 1L && length(ship_site[[1]]$hits) == 0L)

unlink(seed_root, recursive = TRUE)

if (!exists("EML_SUITE")) {
    eml_report("v113 the escape hatch reads nothing the user typed"); eml_exit()
}
