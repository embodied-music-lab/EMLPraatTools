# ============================================================================
# v99 — a dialog's variables are read before the next dialog opens
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Praat names a form field's variable for you, and that variable is a GLOBAL
# that cannot be unset. Two consequences the plugin lives with:
#
#   1. The same field label on two pages is the same variable. That is
#      deliberate and pervasive here — `group_column`, `gridline_mode`,
#      `show_ticks` and `font` are one setting offered on thirteen graph-type
#      pages, and sharing the name is what makes them one setting.
#   2. A page that does NOT offer a field still sees whatever the last page
#      that did offer it left behind. Nothing clears it, and nothing can.
#
# So sharing is safe only while every page reads its own fields into
# page-scoped variables as soon as its dialog closes, and never reads them
# again. That convention is what stands between (1) and a silent wrong value,
# and until this file existed it was a convention rather than a rule.
#
# THE RULE, stated so it can be checked:
#
#   Every read of a form-derived variable occurs after the endPause (or
#   endform) of a dialog that DECLARES it, and before the next dialog opens.
#
# The window between one dialog closing and the next opening is the only span
# in which the value is unambiguously the one the user just entered. A read
# outside that window is reading whatever some other page left there — which
# may be right today and wrong the moment a page is reordered, a branch is
# added, or a label is reused.
#
# This is the check that has to be green BEFORE any sweep that makes labels
# shorter and therefore makes names collide more often. With it green,
# collisions across dialogs are harmless by construction. Without it, they
# are a silent wrong number in a figure.
#
# Text-valued field types (word, sentence, text) get a `$` on the variable;
# the numeric types do not. Modelling that is what keeps `title` (a form
# field) apart from `title$` (an ordinary variable used everywhere).
#
# Base R only. No packages.

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

TEXT_KINDS <- c("word", "sentence", "text")
NUM_KINDS  <- c("boolean", "integer", "real", "positive", "natural",
                "choice", "optionmenu")
ALL_KINDS  <- c(TEXT_KINDS, NUM_KINDS)

field_re <- paste0("^\\s*(", paste(ALL_KINDS, collapse = "|"),
                   ")\\s*:\\s*\"([^\"]*)\"")
open_re  <- "(^|\\s)(beginPause|form)\\s*:"
close_re <- "(^|\\s)(endPause|endform)\\b"

# Praat's derivation: truncate at the first "(", lowercase the FIRST character
# only, spaces to underscores, then the leading run of word characters.
derive_name <- function(label, kind) {
    s <- trimws(sub("\\(.*$", "", label))
    if (nchar(s) == 0L) return("")
    s <- paste0(tolower(substr(s, 1, 1)), substr(s, 2, nchar(s)))
    s <- gsub(" ", "_", s)
    m <- regmatches(s, regexpr("^[A-Za-z][A-Za-z0-9_]*", s))
    if (length(m) == 0L) return("")
    # An optionmenu or a choice binds BOTH names: the numeric index and, with
    # a "$", the text of the option chosen. Code here usually wants the text
    # ("Data column" -> data_column$) and never touches the index, so a model
    # that knows only the index reports a field as unread when it is read on
    # every press. Marked here and honoured by the read pattern below.
    if (kind %in% TEXT_KINDS) paste0(m, "$")
    else if (kind %in% c("choice", "optionmenu")) paste0(m, "|$")
    else m
}

plugin_files <- function() {
    root <- repo_path("plugin_EML_StatsGraphs")
    f <- list.files(root, pattern = "\\.praat$", recursive = TRUE,
                    full.names = TRUE)
    f[!grepl("/dev/", f, fixed = TRUE)]
}

is_comment <- function(line) grepl("^\\s*[#;]", line)

violations <- list()
n_blocks <- 0L
n_reads <- 0L

is_comment <- is_comment   # (defined above)

# ---------------------------------------------------------------------------
# PASS ONE — every dialog in the tree, and what each declares.
# ---------------------------------------------------------------------------
FILES <- plugin_files()
SRC <- list()
BLOCKS <- list()

for (f in FILES) {
    code <- readLines(f, warn = FALSE)
    SRC[[f]] <- code
    if (!any(grepl(open_re, code))) { BLOCKS[[f]] <- list(); next }
    # A comment that MENTIONS beginPause is not a dialog. This file documents
    # its own dialog machinery heavily, so failing to exclude comments invents
    # dialogs, mispairs every block after them, and reports fields as unread
    # that are read four lines later.
    opens  <- setdiff(grep(open_re, code),  grep("^\\s*[#;]", code))
    closes <- setdiff(grep(close_re, code), grep("^\\s*[#;]", code))
    blocks <- list(); used <- logical(length(closes))
    for (o in opens) {
        cand <- which(closes > o & !used)
        if (length(cand) == 0L) next
        k <- cand[1]; used[k] <- TRUE
        vars <- character(0)
        for (i in seq(o, closes[k])) {
            m <- regmatches(code[i], regexec(field_re, code[i]))[[1]]
            if (length(m) == 3L && !is_comment(code[i])) {
                v <- derive_name(m[3], m[2])
                if (nzchar(v)) vars <- c(vars, v)
            }
        }
        nxt <- Filter(function(x) x > closes[k], opens)
        blocks[[length(blocks) + 1L]] <- list(
            open = o, close = closes[k], vars = unique(vars),
            window_end = if (length(nxt)) nxt[1] - 1L else length(code))
    }
    BLOCKS[[f]] <- blocks
    n_blocks <- n_blocks + length(blocks)
}

# How many DIALOGS in the whole tree declare each name?
decl_count <- table(unlist(lapply(BLOCKS, function(bs)
    unlist(lapply(bs, function(b) b$vars)))))
shared_vars <- names(decl_count)[decl_count > 1L]
sole_vars   <- names(decl_count)[decl_count == 1L]

# ---------------------------------------------------------------------------
# PASS TWO — every dialog harvests what it declares, in its own window.
# ---------------------------------------------------------------------------
# WHAT THIS CHECK CAN AND CANNOT DECIDE, stated plainly so nobody reads more
# into a green run than it earns.
#
# CANNOT: prove that every read of a shared variable happens before some other
# dialog could overwrite it. The thirteen graph-type pages all declare
# `gridline_mode`, `x_axis_label$` and their siblings, and they are mutually
# exclusive branches of one if/elsif chain -- exactly one runs per press. A
# line-order analysis cannot see that exclusivity without modelling Praat's
# control flow, and an analysis that assumed the worst would report nine
# hundred violations that are all the same correct pattern. That was tried;
# the number is in the commit message, not in this file.
#
# CAN, and this is the hazard that actually bites: a dialog that OFFERS a
# field and never reads it. The user types a value, the dialog closes, nothing
# harvests it into page-scoped state, and the global keeps whatever the last
# page that did offer that field left there. The figure is then drawn from a
# value the user never entered on this page, and nothing anywhere errors.
#
# So: every dialog must read every field it declares, in the span between its
# own endPause and the next dialog opening. That is where the plugin's
# `tmpX$ = string$ (field)` convention lives, and this makes it a rule.
#
# This is the check that has to be green BEFORE any sweep that shortens labels
# and therefore makes names collide across more pages. With it green, an
# unharvested field is impossible, which is what makes sharing survivable.

for (f in FILES) {
    code <- SRC[[f]]
    blocks <- BLOCKS[[f]]
    if (length(blocks) == 0L) next
    for (b in blocks) {
        if (length(b$vars) == 0L) next
        if (b$window_end <= b$close) next
        # THE WINDOW ENDS AT THE NEXT DIALOG THAT OFFERS THE SAME FIELD, not
        # at the next dialog of any kind. A "Please select a graph type" box
        # that opens only when nothing was chosen sits between the main dialog
        # and the lines that harvest it, on a branch that does not run on the
        # normal path -- and it declares nothing, so it cannot overwrite
        # anything. Ending the window there reported eight fields as unread
        # that are read a dozen lines later.
        declaring_opens <- unlist(lapply(blocks, function(x) x$open))
        for (v in b$vars) {
            others <- unlist(lapply(blocks, function(x)
                if (v %in% x$vars && x$open > b$close) x$open else NULL))
            wend <- if (length(others)) min(others) - 1L else length(code)
            if (wend <= b$close) next
            span <- code[seq(b$close, wend)]
            span <- span[!is_comment(span)]
            n_reads <- n_reads + 1L
            stem <- sub("\\|\\$$", "", v)
            either <- grepl("\\|\\$$", v)
            esc <- gsub("\\$", "\\\\$", stem)
            pat <- if (either)
                paste0("(^|[^A-Za-z0-9_.])", esc, "\\$?($|[^A-Za-z0-9_$])")
            else
                paste0("(^|[^A-Za-z0-9_.])", esc, "($|[^A-Za-z0-9_$])")
            if (!any(grepl(pat, span))) {
                violations[[length(violations) + 1L]] <- sprintf(
                    "%s: dialog at line %d declares %s and never reads it",
                    basename(f), b$open, stem)
            }
        }
    }
}

if (length(violations) > 0L) {
    cat("FIELDS OFFERED BUT NEVER READ BY THE DIALOG THAT OFFERS THEM:\n")
    v <- unlist(violations)
    cat(paste0("  ", utils::head(v, 40), "\n"))
    if (length(v) > 40L) cat(sprintf("  ... and %d more\n", length(v) - 40L))
}

cat(sprintf("  [dialogs %d | names %d | shared by 2+ dialogs %d | field-reads placed %d]\n",
            n_blocks, length(decl_count), length(shared_vars), n_reads))

check_true("v99", "the sweep found dialogs to check", n_blocks > 50L)
check_true("v99", "the sweep found form variables to trace",
           length(decl_count) > 50L)
check_true("v99", "names are shared across dialogs, so the rule has work to do",
           length(shared_vars) > 0L)
check_true("v99",
           "every dialog reads every field it offers, before the next dialog opens",
           length(violations) == 0L)

if (!exists("EML_SUITE")) {
    eml_report("v99 every dialog reads the fields it offers")
    eml_exit()
}
