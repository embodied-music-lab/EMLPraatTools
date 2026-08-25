# ============================================================================
# v133 -- a dialog field's read must not crash the caller that never dialogs
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE DEFECT THIS FILE WOULD HAVE CAUGHT. @emlWrapperCommonFields
# (stats/eml-output.praat) injects two boolean fields into a wrapper's own
# beginPause/endPause dialog. @emlHandleCommonFields, the one procedure that
# reads them, ran both reads unconditionally. Praat does not have an unset
# reads-as-default fallback for a form variable: reading one that was never
# bound with "Unknown variable" and stops the script dead, not a wrong
# number. Every real wrapper is safe -- all ten call @emlWrapperCommonFields
# inside their own dialog first -- but harness/runblock's "callsite" case
# exists BECAUSE a caller standing in for a wrapper's own repeat-loop
# boundary (@emlHandleCommonFields called twice in one script scope, no
# dialog, exactly what a wrapper's "New" button does) is real: every other
# no-dialog driver in this tree (explaingate, explainwiring, routingsplit's
# doors and permute) presets both fields by hand before calling, because
# each was written or touched at the same round that added the field it
# presets. "callsite" was not -- it predates the explanations field, presets
# only clear_Info_window ("The form variable @emlHandleCommonFields reads is
# set here because a form would have set it" -- singular, written when there
# was only one) -- and a later field added to the same procedure with no
# guard reintroduced exactly the crash the guard idiom exists to prevent.
#
# THE CLASS, NOT THE LINE. This file does not hardcode "annotate_results_
# with_explanations is the field to check". It DERIVES the field population
# from @emlWrapperCommonFields's own body -- every dialog-declaring command
# in it, its label put through Praat's own field-name derivation (v98's
# rule: lowercase the first character, spaces to underscores) -- so a third
# field added to that procedure later is in scope by construction, the same
# argument v128 makes for the wizard's label set and v87 makes for a run's
# variable census.
#
# TWO INDEPENDENT ANTI-VACUOUS FLOORS, because a check that examined nothing
# and a check that passed are the same four letters on a terminal.
#
#   FIELD POPULATION. Fails if @emlWrapperCommonFields declares zero fields --
#   a parser that stopped matching would make every field vacuously "not
#   found unguarded", passing behind nobody's back.
#
#   CALL-SITE POPULATION. Every line across the plugin and every harness
#   driver (excluding generated /out/ copies, which are the plugin's own
#   files re-hosted, not distinct call sites) that CALLS @emlHandleCommonFields
#   (a line beginning "@emlHandleCommonFields", not a comment naming it) is
#   gathered by grep, not listed by hand. Fails if that walk finds zero --
#   the whole point is examining every site that reaches the procedure, and
#   a walk of zero means the grep broke, not that the tree got safer.
#
# THE GUARD-STATE PARSE. @emlHandleCommonFields's own body is walked line by
# line with a small nesting stack: a line matching exactly
# `if variableExists ("<field>")` pushes a frame that adds <field> to the set
# of fields GUARANTEED to exist for every line nested under it (inherited
# through further nesting, e.g. the inner "if clear_Info_window" that reads
# the value once existence is guaranteed); "else" and "endif" pop back out.
# A bare reference to a declared field -- matched as a whole word, so a
# dotted local or a longer identifier sharing a prefix does not false-hit --
# found on a line whose active frame does not already guarantee that field
# is an UNGUARDED READ.
#
# THE CALL-SITE JUDGEMENT. A file that also calls @emlWrapperCommonFields
# runs the dialog and both fields are bound by Praat itself; every field is
# safe there regardless of the guard parse. A file with NO such call is
# judged per declared field: safe if the guard parse found it guarded in
# @emlHandleCommonFields, OR if the driver itself presets the field with a
# plain assignment before its call (the pattern explaingate, explainwiring
# and routingsplit all use) -- unsafe otherwise, named by file and field.
#
# RED, ON THE REAL PRE-FIX TREE, NOT A SYNTHETIC SEED. `git show HEAD` is
# the commit this repository held before this round's fix (mutation-standard
# demonstrations elsewhere seed a synthetic copy of a defect; here the actual
# defect is what HEAD already carries, becaue it has not been committed
# over yet, so the red demonstration reads the real pre-fix source rather
# than a fabricated one). Section 1 runs the whole analysis against that
# text and asserts the known failure appears, by name, at the known site.
# Section 2 runs the same analysis against the working tree and asserts
# the whole tree is clean.
#
# WHAT THIS DOES NOT DO. It is a static source check, not a Praat replay --
# harness/runblock + validate/v87 is the dynamic proof (every step of
# "callsite" comes back recorded and replays byte-identical). This file is
# cheaper, general over the field-and-guard SHAPE rather than one harness's
# output, and is what should have existed before this round's regression
# rather than after it.
#
# THIS FILE IS NOT WIRED INTO validate/run_all.R. That file is not edited as
# part of this change (see the repository's own instruction on how entries
# are inserted); wiring this in is a one-line addition for whoever next
# touches that list, following its own documented comma convention.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".",
                      "helpers.R"))
}

ID <- "v133"
ROOT <- repo_path()

# ---------------------------------------------------------------------------
# Derive a Praat form variable name from a dialog field's label (v98's rule,
# restated only for the pieces this file needs: no field here carries a
# parenthetical, so step 1 of v98's derivation never triggers).
# ---------------------------------------------------------------------------
derive_var_name <- function(label) {
    label <- sub("\\s*\\(.*$", "", label)          # v98 step 1 (unused here)
    label <- gsub(" ", "_", label)                  # v98 step 3
    substr(label, 1, 1) <- tolower(substr(label, 1, 1))  # v98 step 2
    label
}

# ---------------------------------------------------------------------------
# Pull one procedure's body (the lines strictly between "procedure NAME" and
# the next "endproc") out of a file's already-read lines.
# ---------------------------------------------------------------------------
extract_proc <- function(lines, name) {
    start <- grep(sprintf("^\\s*procedure\\s+%s\\b", name), lines)
    if (length(start) == 0L) return(NULL)
    start <- start[1]
    rest <- which(grepl("^\\s*endproc\\b", lines[(start + 1):length(lines)]))
    if (length(rest) == 0L) return(NULL)
    end <- start + rest[1]
    lines[(start + 1):(end - 1)]
}

# ---------------------------------------------------------------------------
# The dialog-declaring commands this tree's field derivation understands
# (v98 §5): the ones that can appear inside a beginPause/endPause block and
# bind a plain-named variable from a quoted label.
# ---------------------------------------------------------------------------
FIELD_CMDS <- "(boolean|real|positive|integer|natural|word|sentence|choice|optionmenu)"

derive_fields <- function(body) {
    m <- regmatches(body, regexec(
        sprintf("^\\s*%s\\s*:\\s*\"([^\"]+)\"", FIELD_CMDS), body))
    labels <- vapply(m, function(x) if (length(x) >= 3) x[3] else NA_character_,
                      character(1))
    labels <- labels[!is.na(labels)]
    vapply(labels, derive_var_name, character(1), USE.NAMES = FALSE)
}

# ---------------------------------------------------------------------------
# Walk @emlHandleCommonFields's body and report, per declared field, whether
# every reference to it is nested under its own "if variableExists (...)".
# Returns a named logical vector: TRUE = guarded everywhere it is read;
# also returns the first unguarded line's text for the report.
# ---------------------------------------------------------------------------
analyse_guards <- function(body, fields) {
    guarded <- setNames(rep(TRUE, length(fields)), fields)
    first_bad_line <- setNames(rep(NA_character_, length(fields)), fields)
    stack <- list(character(0))

    word_hit <- function(line, field) {
        grepl(paste0("(^|[^A-Za-z0-9_.$])", field, "([^A-Za-z0-9_$]|$)"), line) &&
            !grepl(paste0("variableExists\\s*\\(\\s*\"", field, "\""), line)
    }

    is_comment <- function(line) grepl("^\\s*[;#]", line)

    for (line in body) {
        frame <- stack[[length(stack)]]
        for (f in fields) {
            if (!is_comment(line) && word_hit(line, f) && !(f %in% frame)) {
                if (guarded[[f]]) {
                    guarded[[f]] <- FALSE
                    first_bad_line[[f]] <- trimws(line)
                }
            }
        }
        gm <- regmatches(line, regexec(
            "^\\s*if\\s+variableExists\\s*\\(\\s*\"([^\"]+)\"\\s*\\)\\s*$", line))[[1]]
        if (length(gm) == 2L) {
            stack[[length(stack) + 1L]] <- union(frame, gm[2])
        } else if (grepl("^\\s*if\\b", line)) {
            stack[[length(stack) + 1L]] <- frame
        } else if (grepl("^\\s*else\\b", line)) {
            if (length(stack) >= 2L) stack[[length(stack)]] <- stack[[length(stack) - 1L]]
        } else if (grepl("^\\s*endif\\b", line)) {
            if (length(stack) > 1L) stack[[length(stack)]] <- NULL
        }
    }
    list(guarded = guarded, first_bad_line = first_bad_line)
}

# ---------------------------------------------------------------------------
# Every *.praat file under the tree, EXCLUDING generated /out/ copies (the
# plugin re-hosted by a harness driver, not a distinct call site).
# ---------------------------------------------------------------------------
all_praat_files <- function(root) {
    f <- list.files(root, pattern = "\\.praat$", recursive = TRUE, full.names = TRUE)
    f[!grepl("(^|/)out/", f)]
}

# A file CALLS @emlHandleCommonFields on a line that, trimmed, begins with
# the call -- not a comment merely naming it.
calls_handler <- function(lines) {
    grepl("^@emlHandleCommonFields\\b", trimws(lines))
}
calls_dialog <- function(lines) {
    any(grepl("^@emlWrapperCommonFields\\b", trimws(lines)))
}
presets_field <- function(lines, field) {
    any(grepl(sprintf("^%s\\s*=", field), trimws(lines)))
}

# ---------------------------------------------------------------------------
# The whole analysis, over one source tree, so it can be run against HEAD's
# text (red) and the working tree (green) identically.
# ---------------------------------------------------------------------------
run_analysis <- function(output_lines, tree_root) {
    common_body <- extract_proc(output_lines, "emlWrapperCommonFields")
    handle_body <- extract_proc(output_lines, "emlHandleCommonFields")
    fields <- if (is.null(common_body)) character(0) else derive_fields(common_body)

    guard <- if (is.null(handle_body) || length(fields) == 0L) {
        list(guarded = setNames(rep(FALSE, length(fields)), fields),
             first_bad_line = setNames(rep(NA_character_, length(fields)), fields))
    } else analyse_guards(handle_body, fields)

    files <- all_praat_files(tree_root)
    call_sites <- character(0)
    unsafe <- list()
    for (fp in files) {
        fl <- readLines(fp, warn = FALSE)
        hits <- which(calls_handler(fl))
        if (length(hits) == 0L) next
        for (h in hits) call_sites <- c(call_sites, sprintf("%s:%d", fp, h))
        if (calls_dialog(fl)) next   # dialog-driven: Praat itself binds both fields
        for (f in fields) {
            safe <- isTRUE(guard$guarded[[f]]) || presets_field(fl, f)
            if (!safe) {
                unsafe[[length(unsafe) + 1L]] <- list(file = fp, field = f)
            }
        }
    }
    list(fields = fields, guard = guard, call_sites = call_sites, unsafe = unsafe)
}

output_path <- file.path(ROOT, "plugin_EML_StatsGraphs", "stats", "eml-output.praat")

# ===========================================================================
# SECTION 1 -- RED, against the real pre-fix tree (git HEAD's committed text)
# ===========================================================================
head_text <- tryCatch(
    system2("git", c("-C", shQuote(ROOT), "show", "HEAD:plugin_EML_StatsGraphs/stats/eml-output.praat"),
            stdout = TRUE, stderr = FALSE),
    error = function(e) character(0))

if (length(head_text) == 0L) {
    check_true(ID, "git HEAD:eml-output.praat was readable for the red demonstration", FALSE)
} else {
    # HEAD's tree is analysed as it stood in the repo (harness drivers are
    # tracked files too, and callsite/body.praat is the one HEAD still has
    # with only clear_Info_window preset).
    tmp_root <- tempfile("v133_head_")
    dir.create(tmp_root)
    dir.create(file.path(tmp_root, "plugin_EML_StatsGraphs", "stats"), recursive = TRUE)
    writeLines(head_text, file.path(tmp_root, "plugin_EML_StatsGraphs", "stats", "eml-output.praat"))
    # Every OTHER *.praat file (the call sites) is read straight from the
    # working tree paths, since only eml-output.praat is the file this
    # round's fix touched; a call-site file is copied in place so the walk
    # sees the same driver text HEAD shipped.
    src_files <- all_praat_files(ROOT)
    for (fp in src_files) {
        rel <- sub(paste0("^", ROOT, "/?"), "", fp)
        if (rel == file.path("plugin_EML_StatsGraphs", "stats", "eml-output.praat")) next
        dest <- file.path(tmp_root, rel)
        dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
        file.copy(fp, dest, overwrite = TRUE)
    }
    red <- run_analysis(head_text, tmp_root)

    check_true(ID, "RED SETUP: field population from @emlWrapperCommonFields is non-empty (pre-fix tree)",
               length(red$fields) > 0)
    check_true(ID, "RED SETUP: call-site population is non-empty (pre-fix tree)",
               length(red$call_sites) > 0)
    if (length(red$call_sites) > 0)
        cat(sprintf("v133 (pre-fix): examined %d call site(s) across %d field(s): %s\n",
                    length(red$call_sites), length(red$fields),
                    paste(red$fields, collapse = ", ")))

    target_field <- "annotate_results_with_explanations"
    target_hit <- Filter(function(u) grepl("runblock/cases/callsite/body\\.praat$", u$file) &&
                             u$field == target_field, red$unsafe)
    check_true(ID, "RED: pre-fix tree reports harness/runblock/cases/callsite/body.praat unguarded for annotate_results_with_explanations",
               length(target_hit) == 1L)
    check_true(ID, "RED: pre-fix @emlHandleCommonFields's guard parse marks annotate_results_with_explanations unguarded",
               isFALSE(red$guard$guarded[[target_field]]))
    if (isFALSE(red$guard$guarded[[target_field]]))
        cat(sprintf("v133 (pre-fix): first unguarded line for %s: %s\n",
                    target_field, red$guard$first_bad_line[[target_field]]))

    unlink(tmp_root, recursive = TRUE)
}

# ===========================================================================
# SECTION 2 -- GREEN, against the working tree (this round's fix)
# ===========================================================================
working_lines <- readLines(output_path, warn = FALSE)
green <- run_analysis(working_lines, ROOT)

check_true(ID, "field population from @emlWrapperCommonFields is non-empty (working tree)",
           length(green$fields) > 0)
check_true(ID, "call-site population is non-empty (working tree)",
           length(green$call_sites) > 0)
if (length(green$call_sites) > 0)
    cat(sprintf("v133: examined %d call site(s) across %d field(s): %s\n",
                length(green$call_sites), length(green$fields),
                paste(green$fields, collapse = ", ")))

for (f in green$fields) {
    check_true(ID, sprintf("@emlHandleCommonFields guards every read of %s (or every no-dialog caller presets it)", f),
               isTRUE(green$guard$guarded[[f]]))
}

check_true(ID, "no no-dialog call site is left with an unguarded, unpreset field",
           length(green$unsafe) == 0L)
if (length(green$unsafe) > 0) {
    for (u in green$unsafe)
        check_true(ID, sprintf("  UNSAFE: %s reads %s with no dialog, no guard, no preset", u$file, u$field),
                   FALSE)
}

if (!exists("EML_SUITE")) {
    eml_report("v133 dialog field guard"); eml_exit()
}
