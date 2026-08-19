# ============================================================================
# v98 — every dialog field's label derives the variable name the code reads
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Praat does not let a script name a form field's variable. It DERIVES the
# name from the label: the label is truncated at the first "(", lowercased,
# spaces become underscores, and the name is then the leading run of
# [a-z][a-z0-9_]* — so the first character that is not a letter, digit,
# space or underscore silently ends the name.
#
# The failure this pins is silent and total. A label of "Right-hand axis"
# derives `right`, not `right_hand_axis`, because the hyphen truncates it.
# The code that reads `right_hand_axis` then aborts with "Unknown variable"
# on every press — and nothing about the label looks wrong. That shipped
# once: every two-measurement line chart refused to draw until the label was
# changed to "Right hand axis".
#
# Two assertions, both static, both cheap:
#
#   1. NO TRUNCATION. Every field label in the shipped tree derives its
#      whole name — the derived name equals the fully sanitized name. A
#      label containing a hyphen, slash, comma, apostrophe or any other
#      punctuation before its end fails here.
#   2. NO COLLISION. Within one form or beginPause block, no two fields
#      derive the same name. Two fields sharing a name means the second
#      silently overwrites the first, which is a wrong value rather than an
#      error, and therefore worse.
#
# Base R only. No packages.

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

FIELD_KINDS <- c("boolean", "integer", "real", "positive", "natural",
                 "word", "sentence", "text", "choice", "optionmenu")

# Praat's derivation, reimplemented.
derive_name <- function(label) {
    s <- trimws(sub("\\(.*$", "", label))
    # Praat lowercases only the FIRST character; the rest keeps its case.
    # Verified in 6.6.30: "Voice Type" binds voice_Type, not voice_type, and
    # "left Time range (s)" binds left_Time_range.
    if (nchar(s) > 0L) {
        s <- paste0(tolower(substr(s, 1, 1)), substr(s, 2, nchar(s)))
    }
    s <- gsub(" ", "_", s)
    m <- regmatches(s, regexpr("^[A-Za-z][A-Za-z0-9_]*", s))
    if (length(m) == 0L) "" else m
}

# The name the label plainly intends: same fold, but punctuation becomes
# underscore instead of ending the name.
intended_name <- function(label) {
    s <- trimws(sub("\\(.*$", "", label))
    if (nchar(s) > 0L) {
        s <- paste0(tolower(substr(s, 1, 1)), substr(s, 2, nchar(s)))
    }
    s <- gsub(" ", "_", s)
    s <- gsub("[^A-Za-z0-9_]", "_", s)
    gsub("^_+|_+$", "", s)
}

plugin_files <- function() {
    root <- repo_path("plugin_EML_StatsGraphs")
    f <- list.files(root, pattern = "\\.praat$", recursive = TRUE,
                    full.names = TRUE)
    f[!grepl("/dev/", f, fixed = TRUE)]
}

field_re <- paste0("^\\s*(", paste(FIELD_KINDS, collapse = "|"),
                   ")\\s*:\\s*\"([^\"]*)\"")

truncated <- list()
collisions <- list()
n_fields <- 0L

for (f in plugin_files()) {
    code <- readLines(f, warn = FALSE)
    block <- list()
    for (i in seq_along(code)) {
        if (grepl("^\\s*(beginPause|form)[:\\s(]", code[i])) block <- list()
        m <- regmatches(code[i], regexec(field_re, code[i]))[[1]]
        if (length(m) == 3L) {
            lab <- m[3]
            d <- derive_name(lab)
            w <- intended_name(lab)
            n_fields <- n_fields + 1L
            if (!identical(d, w)) {
                truncated[[length(truncated) + 1L]] <-
                    sprintf("%s:%d  \"%s\" -> %s (intended %s)",
                            basename(f), i, lab, d, w)
            }
            block[[length(block) + 1L]] <- list(line = i, label = lab, name = d)
        }
        if (grepl("^\\s*(endPause|endform)", code[i]) && length(block) > 0L) {
            nm <- vapply(block, function(x) x$name, character(1))
            dup <- unique(nm[duplicated(nm)])
            for (d in dup) {
                which_ones <- Filter(function(x) identical(x$name, d), block)
                collisions[[length(collisions) + 1L]] <- sprintf(
                    "%s: %s <- %s", basename(f), d,
                    paste(vapply(which_ones,
                                 function(x) sprintf("line %d \"%s\"",
                                                     x$line, x$label),
                                 character(1)), collapse = " ; "))
            }
            block <- list()
        }
    }
}

if (length(truncated) > 0L) {
    cat("TRUNCATED FIELD NAMES:\n"); cat(paste0("  ", unlist(truncated), "\n"))
}
if (length(collisions) > 0L) {
    cat("COLLIDING FIELD NAMES:\n"); cat(paste0("  ", unlist(collisions), "\n"))
}

check_true("v98", "the sweep found dialog fields to check", n_fields > 100L)
check_true("v98", "no field label is truncated before its full name",
           length(truncated) == 0L)
check_true("v98", "no two fields in one dialog derive the same name",
           length(collisions) == 0L)

# The specific label that shipped broken, kept by name so the regression
# cannot return quietly under a different guise.
form_src <- readLines(repo_path("plugin_EML_StatsGraphs", "graphs",
                                "eml-graphs-form.praat"), warn = FALSE)
check_true("v98", "the right-hand axis field carries no hyphen",
           !any(grepl("optionmenu:\\s*\"Right-hand", form_src)) &&
               any(grepl("optionmenu:\\s*\"Right hand axis\"", form_src)))

if (!exists("EML_SUITE")) { eml_report("v98 dialog field names derive what the code reads"); eml_exit() }
