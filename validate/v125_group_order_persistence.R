# ============================================================================
# v125_group_order_persistence.R -- the ordering clause, and the choice that
#                                    must not survive a fresh script
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR. Punch list 2026-08-25, lane 2, items 2.2 (the remaining
# half) and 2.3. Both were built and pushed (095dddb, and the groupSort
# session-only wiring in graphs/eml-graphs-form.praat) but their red
# demonstrations ran in scratch drivers that were deleted with the session
# that wrote them. Nothing in validate/ has asserted the string
# "Group order:" since. This file is that assertion, standing on its own.
#
# THE ORDERING CLAUSE (2.2, LANGUAGE BATCH ITEM 10). Every report that prints
# a comparison across more than one group must carry one line stating the
# group order in force -- not a claim this file takes on faith, but read
# straight off the wording:
#
#     Group order: table order (pre, post).
#
# alphabetical runs print "alphabetical" in place of "table order", and the
# parenthesised list is the order actually used for the numbers above it --
# never re-derived by the reporter, always the caller's own resolved array.
#
# THE POPULATION IS DERIVED, not listed, for the same reason v111 and v112
# derive theirs: a hand-typed list of "the grouped reports" is a list that
# drifts the day someone adds one. Every report procedure in this plugin that
# prints a multi-group comparison builds its group list the same way -- the
# identical three-line idiom appears at all five known sites:
#
#     if .iGroup > 1
#         .groupList$ = .groupList$ + ", "
#     endif
#     .groupList$ = .groupList$ + <group name array>[.iGroup]
#
# A procedure whose body contains that idiom IS a grouped-comparison report by
# construction -- it has resolved an ordered list of group names to print --
# and so a procedure added tomorrow that builds one falls into the population
# tomorrow without anyone remembering to add a name here.
#
# THE PERSISTENCE HALF (2.3, "Erase page first" pattern). config_groupSort
# must never round-trip through eml-graphs-config.txt: @emlLoadConfig must
# read no "groupSort" key, @emlSaveConfig must write no config_groupSort
# line, and the session-only memory (sessionGroupSort, restored immediately
# after every @emlLoadConfig call) must be the only thing that survives a
# second Draw within the same script session. A menu dialog, as a fresh
# script run, has no sessionGroupSort of its own to restore from and so opens
# on the form's own default -- asserted here as the absence of any earlier
# assignment to selGroupOrder in the four standalone group-order dialogs,
# which is what "opens at the default" reduces to when nothing seeds it.
#
# THE RED DEMONSTRATION. $EML_ORDER_SRC points the whole file at another
# plugin tree, exactly the mechanism v98 uses (EML_DIALOG_SRC) and v111/v112
# use under their own names. harness/orderpersist/seed_*.sh build two seeded
# copies -- one with the ordering clause calls stripped, one with the
# groupSort key restored to the config load/save paths and the session
# restore removed -- and this file, run unmodified against each with
# $EML_ORDER_SRC pointed at it, goes red. See that harness for the captured
# failing output; it is quoted in the commit message and in OPEN_ITEMS.md.
#
# Base R only. Reads plugin source; drives nothing.
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

V <- "v125"

ROOT <- Sys.getenv("EML_ORDER_SRC", unset = "")
if (!nzchar(ROOT)) ROOT <- repo_path("plugin_EML_StatsGraphs")
if (!dir.exists(ROOT)) stop("v125: no plugin tree at ", ROOT)

rd <- function(rel) {
    p <- file.path(ROOT, rel)
    if (!file.exists(p)) return(character(0))
    readLines(p, warn = FALSE)
}

# ---------------------------------------------------------------------------
# Procedure-boundary scanner: name -> body lines, for every `procedure
# NAME ... endproc` block in a set of files. Praat procedures do not nest, so
# a flat stack-free walk is enough -- the same assumption v122's static half
# makes of `if`/`endif`.
# ---------------------------------------------------------------------------
scan_procedures <- function(files) {
    out <- list()
    for (f in files) {
        lines <- rd(f)
        if (!length(lines)) next
        cur <- NULL; body <- character(0)
        for (ln in lines) {
            m <- regmatches(ln, regexec("^procedure\\s+([A-Za-z0-9_]+)", ln))[[1]]
            if (length(m) == 2L) {
                cur <- m[2]; body <- character(0)
            } else if (grepl("^endproc", ln) && !is.null(cur)) {
                out[[cur]] <- list(file = f, body = body)
                cur <- NULL
            } else if (!is.null(cur)) {
                body <- c(body, ln)
            }
        }
    }
    out
}

SRC_REL <- c(
    "stats/eml-analysis.praat", "stats/eml-inferential.praat",
    "stats/eml-output.praat", "stats/eml-extract.praat",
    "graphs/eml-annotation-procedures.praat", "graphs/eml-graph-procedures.praat"
)
procs <- scan_procedures(SRC_REL)

IDIOM <- "\\.groupList\\$\\s*=\\s*\\.groupList\\$\\s*\\+"
population <- names(procs)[vapply(procs, function(p) any(grepl(IDIOM, p$body)), logical(1))]

check_true(V,
           sprintf("RESOLVER: the group-list idiom was found in at least one procedure (%d)",
                   length(population)),
           length(population) >= 3L)

# ---------------------------------------------------------------------------
# 1. EVERY MEMBER OF THE DERIVED POPULATION CARRIES THE ORDERING CLAUSE
# ---------------------------------------------------------------------------
CALL <- "@emlReportGroupOrderLine:\\s*\\.groupList\\$"
missing_call <- character(0)
literal_arg  <- character(0)
for (nm in population) {
    body <- procs[[nm]]$body
    if (!any(grepl(CALL, body))) {
        missing_call <- c(missing_call, nm)
    }
    # A caller that passes anything other than its own resolved .groupList$
    # is re-deriving or hard-coding the list rather than naming the order it
    # actually used -- red either way.
    calls <- grep("@emlReportGroupOrderLine:", body, value = TRUE)
    if (length(calls) && any(!grepl(CALL, calls))) {
        literal_arg <- c(literal_arg, nm)
    }
}
check_true(V,
           sprintf("every grouped-comparison report calls @emlReportGroupOrderLine (%d of %d)%s",
                   length(population) - length(missing_call), length(population),
                   if (length(missing_call))
                       paste0(" -- SILENT: ", paste(missing_call, collapse = ", "))
                   else ""),
           length(missing_call) == 0)
check_true(V,
           sprintf("every call names its OWN .groupList\\$, not a literal or a re-derivation%s",
                   if (length(literal_arg))
                       paste0(" -- ", paste(literal_arg, collapse = ", ")) else ""),
           length(literal_arg) == 0)

# ---------------------------------------------------------------------------
# 2. THE CANON IS STATED ONCE, AND ITS WORDING IS THE LANGUAGE BATCH'S
# ---------------------------------------------------------------------------
out_lines <- rd("stats/eml-output.praat")
def_at <- grep("^procedure emlReportGroupOrderLine\\b", out_lines)
check_true(V, sprintf("@emlReportGroupOrderLine is defined exactly once (%d)", length(def_at)),
           length(def_at) == 1L)

if (length(def_at) == 1L) {
    end_at <- grep("^endproc", out_lines)
    end_at <- end_at[end_at > def_at][1]
    body <- out_lines[def_at:end_at]

    check_true(V, "table order is named when emlGroupSortAlphabetical is not 1",
               any(grepl('\\.orderLabel\\$\\s*=\\s*"table order"', body)))
    check_true(V, "alphabetical is named when emlGroupSortAlphabetical is 1",
               any(grepl('\\.orderLabel\\$\\s*=\\s*"alphabetical"', body)) &&
               any(grepl("emlGroupSortAlphabetical\\s*=\\s*1", body)))
    check_true(V, "the printed line matches language batch item 10, verbatim",
               any(grepl('"  Group order: "\\s*\\+\\s*\\.orderLabel\\$\\s*\\+\\s*" \\("\\s*\\+\\s*\\.groupList\\$\\s*\\+\\s*"\\)\\."',
                         body)))
    check_true(V, "the line is unconditional -- a DISCLOSURE, not gated by emlShowExplanations",
               !any(grepl("emlShowExplanations", body)))
} else {
    check_true(V, "the ordering clause's wording could be verified", FALSE)
}

# ---------------------------------------------------------------------------
# 3. THE groupSort KEY IS ABSENT FROM BOTH DISK PATHS
# ---------------------------------------------------------------------------
form_procs <- scan_procedures("graphs/eml-graphs-form.praat")

load_body <- form_procs[["emlLoadConfig"]]$body
save_body <- form_procs[["emlSaveConfig"]]$body

check_true(V, "@emlLoadConfig and @emlSaveConfig were both located",
           !is.null(load_body) && !is.null(save_body))

if (!is.null(load_body)) {
    # The comment explaining the absence names the key too ('NO "groupSort"
    # KEY, ON PURPOSE'), so the code-level comparison is what is asserted,
    # not the bare string -- a comment mentioning the key must not itself
    # trip this check.
    check_true(V, "@emlLoadConfig reads no \"groupSort\" key from disk",
               !any(grepl('\\.key\\$\\s*=\\s*"groupSort"', load_body)))
    check_true(V, "@emlLoadConfig still sets the table-order default (config_groupSort = 1)",
               any(grepl("config_groupSort\\s*=\\s*1\\b", load_body)))
}
if (!is.null(save_body)) {
    check_true(V, "@emlSaveConfig writes no config_groupSort line to disk",
               !any(grepl("(appendFileLine|writeFileLine).*config_groupSort", save_body)))
}

# ---------------------------------------------------------------------------
# 4. THE SESSION-LEVEL RESTORE IS PRESENT, AND RUNS AFTER THE LOAD
# ---------------------------------------------------------------------------
wf_body <- form_procs[["emlGraphsWorkflow"]]$body
check_true(V, "@emlGraphsWorkflow was located", !is.null(wf_body))
if (!is.null(wf_body)) {
    i_load    <- which(grepl("@emlLoadConfig\\b", wf_body))[1]
    i_exists  <- which(grepl('variableExists\\s*\\(\\s*"sessionGroupSort"\\s*\\)', wf_body))[1]
    i_restore <- which(grepl("config_groupSort\\s*=\\s*sessionGroupSort\\b", wf_body))[1]
    check_true(V, "sessionGroupSort is restored only after @emlLoadConfig has run",
               !is.na(i_load) && !is.na(i_exists) && !is.na(i_restore) &&
               i_load < i_exists && i_exists <= i_restore)
    check_true(V, "the restore is guarded by variableExists, not assumed on the first call",
               !is.na(i_exists) && !is.na(i_restore) &&
               (i_restore - i_exists) <= 3L)
}

# The write side of the session memory: every "Group order" dropdown on the
# draw form must write its answer back into sessionGroupSort as well as
# config_groupSort, or the memory this section just proved gets restored
# would have nothing current to restore.
n_dropdowns <- sum(grepl('optionmenu:\\s*"Group order"', rd("graphs/eml-graphs-form.praat")))
n_writes    <- sum(grepl("^\\s*prev_groupSort\\s*=\\s*group_order\\s*$",
                         rd("graphs/eml-graphs-form.praat")))
check_true(V,
           sprintf("every 'Group order' dropdown on the draw form has a matching write-back (%d dropdowns, %d writes)",
                   n_dropdowns, n_writes),
           n_dropdowns >= 3L && n_writes >= n_dropdowns)

# ---------------------------------------------------------------------------
# 5. MENU DIALOGS OPEN AT THE DEFAULT -- A FRESH SCRIPT SEEDS NOTHING
# ---------------------------------------------------------------------------
# Praat globals do not survive between separate `--run` invocations (CLAUDE.md:
# "Form variables are globals nothing can unset"), so a standalone script that
# never assigns selGroupOrder before its own `optionmenu: "Group order",
# selGroupOrder` line cannot open on anything but that menu's own first
# option -- "Table order". Asserted as the absence of any such assignment;
# its presence would be exactly the config-file carryover 2.3 forbids, smuggled
# in through a variable instead of a file.
MENU_DOORS <- c("scripts/eml-pairwise.praat", "scripts/eml-compare-k-groups.praat",
                "scripts/eml-compare-groups.praat", "scripts/eml-compare-kw.praat")
seeded <- character(0)
no_dropdown <- character(0)
no_seed <- character(0)
for (rel in MENU_DOORS) {
    lines <- rd(rel)
    dd_at <- which(grepl('optionmenu:\\s*"Group order"\\s*,\\s*selGroupOrder', lines))[1]
    if (is.na(dd_at)) { no_dropdown <- c(no_dropdown, rel); next }
    # Praat requires an optionmenu's variable to be pre-assigned to get a
    # default selection at all -- that is a LITERAL, once, before the
    # dialog, not a read of a persisted setting. Any assignment reading a
    # config_ or session-memory variable instead of a bare integer is the
    # config-file carryover 2.3 forbids, arriving through a different door.
    pre <- lines[seq_len(dd_at - 1L)]
    assigns <- grep("^\\s*selGroupOrder\\s*=\\s*(.+)$", pre, value = TRUE)
    if (!length(assigns)) { no_seed <- c(no_seed, rel); next }
    rhs <- trimws(sub("^\\s*selGroupOrder\\s*=\\s*", "", assigns))
    rhs <- trimws(sub("[#;].*$", "", rhs))
    if (any(rhs != "1")) seeded <- c(seeded, rel)
}
check_true(V,
           sprintf("every standalone group-order door declares the dropdown (%d of %d)%s",
                   length(MENU_DOORS) - length(no_dropdown), length(MENU_DOORS),
                   if (length(no_dropdown))
                       paste0(" -- MISSING: ", paste(no_dropdown, collapse = ", ")) else ""),
           length(no_dropdown) == 0)
check_true(V,
           sprintf("each one seeds selGroupOrder with a literal default, not a read (%d checked)%s",
                   length(MENU_DOORS) - length(no_dropdown),
                   if (length(no_seed))
                       paste0(" -- NO DEFAULT SEED: ", paste(no_seed, collapse = ", ")) else ""),
           length(no_seed) == 0)
check_true(V,
           sprintf("none of them seeds selGroupOrder from anywhere but a literal%s",
                   if (length(seeded))
                       paste0(" -- SEEDED FROM SOMETHING PERSISTED: ",
                              paste(seeded, collapse = ", ")) else ""),
           length(seeded) == 0)

# ---------------------------------------------------------------------------
# 6. THE RESOLVER GATE
# ---------------------------------------------------------------------------
eml_census(V, "grouped-comparison report procedure",
           present   = population,
           accounted = setdiff(population, missing_call))

if (!exists("EML_SUITE")) {
    eml_report("v125 the ordering clause and its persistence")
    eml_exit()
}
