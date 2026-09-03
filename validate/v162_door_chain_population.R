# ============================================================================
# v162_door_chain_population.R -- setup.praat's module table and the door
# chain's resolved includes are two copies of "which modules exist," and
# this is the check that asserts they agree
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS
#
# RULING_RECORDER_AND_WIRING_2026-09-02.md, "The two-way door": v88 pins
# setup.praat's module table against the stats/+graphs/ folder on disk, and
# goes green. But setup.praat's table feeds only the GENERATED user barrel
# (scripts/eml-lib-user.praat, written by setup.praat at Praat launch) --
# not the plugin's OWN menu doors. Those doors carry a second, separate,
# hand-maintained module list: scripts/eml-compare-twoway.praat (and every
# other analysis door) includes scripts/eml-lib.praat, which chains through
# eml-lib-stats.praat, ../stats/eml-analysis.praat and eml-lib-graphs.praat.
# That chain never gained stats/eml-anova-kernel.praat. Two lists, one
# check, pointed at the wrong copy: v88 says the barrel is fully accounted
# for while the interactive door for two-way ANOVA crashes before dispatch
# with "Procedure 'emlAnovaKernelTwoWay' not found" (REPORT_RECORDER_
# COVERAGE_2026-09-01.md section 4, reproduced there live against
# /usr/local/bin/praat6630). This file is the check ordered to close that
# gap: it reads setup.praat's table exactly as v88 does, resolves
# scripts/eml-lib.praat's includes transitively off disk, and asserts the
# two sets name the same modules.
#
# WHY A SIBLING TO v88 AND NOT AN EXTENSION OF IT. v88's own header states
# its scope in the negative, deliberately: "WHAT IT DOES NOT DO. It does not
# judge WHETHER an exclusion is right... and it does not re-check the
# order, the generated file or the recorder's agreement with it, all of
# which are v82's. It asks one question: is every module accounted for [in
# the barrel table vs the stats/+graphs/ folder]." That is a population
# comparison against DISK. This file makes a different comparison -- the
# barrel table against a second HAND-MAINTAINED list, scripts/eml-lib.praat's
# own resolved includes -- which is a distinct axis v88 explicitly disclaims
# ("a second hand-maintained list somewhere else is how MANIFEST.txt and the
# tree came apart for twelve days in August" is v88's own warning about
# exactly this shape of drift, applied here to the chain v88 does not read).
# Bolting a third population onto a file whose header promises one question
# would make the promise false; a named sibling keeps both questions legible
# on their own.
#
# WHAT "THE DOOR CHAIN" MEANS HERE, and why it is scripts/eml-lib.praat and
# not each menu script separately. Every analysis door but the graphs/data/
# batch/record scripts reaches its statistics through the single line
# `include eml-lib.praat` (confirmed: scripts/eml-compare-twoway.praat:34,
# and REPORT_RECORDER_COVERAGE_2026-09-01.md section 4 traces the same
# chain from the same probe). eml-lib.praat is "one include to rule them
# all" by its own header -- the hand-maintained counterpart to the
# generated barrel, read by the plugin's OWN doors rather than by a user's
# script. Resolving it, not each door script individually, is what the
# ruling's own wording names: "the actual door scripts include a
# hand-maintained chain through scripts/eml-lib.praat."
#
# TRANSITIVE, BECAUSE `include` IS A PARSE-TIME PASTE. eml-lib.praat itself
# names three files; each of those can name more. A module can arrive
# through another module (eml-lib-stats.praat and eml-lib-graphs.praat are
# exactly that -- neither is itself a stats/ or graphs/ module, both are
# chain plumbing that pulls modules in). This file walks the chain to a
# fixed point rather than reading one level, for the same reason v88 walks
# stats/+graphs/ off disk rather than trusting a retyped list: a module
# could be reachable only through a second hop, and a check that stopped at
# the first hop would miss it exactly as silently as the barrel gap did.
#
# PRAAT'S OWN RESOLUTION RULE, WHICH THIS FILE MUST MATCH TO WALK THE CHAIN
# CORRECTLY. eml-lib-stats.praat's own header states it: "A relative path
# inside an included file resolves against the TOP-LEVEL script's
# directory, not against the file the line is written in." scripts/
# eml-lib.praat is the top-level script for this walk, so every relative
# include target this file finds -- at any depth -- is resolved against
# plugin_EML_StatsGraphs/scripts/, never against the directory of the file
# that wrote the include line. Resolving against the wrong directory would
# silently under- or over-count the chain.
#
# THE POPULATION BOUNDARY IS THE SAME ONE v88 USES, FOR THE SAME REASON:
# stats/ and graphs/ hold modules (procedure libraries an include pulls in);
# scripts/ holds entry points and chain plumbing. eml-lib.praat,
# eml-lib-stats.praat and eml-lib-graphs.praat are chain plumbing, not
# modules to account for -- they are HOW the chain is walked, not something
# the chain is checked against.
#
# THE ONE SANCTIONED ASYMMETRY, AND WHY IT IS NOT HARDCODED HERE. Setup.
# praat's own not-in-barrel table already carries a row for
# graphs/eml-graphs-form.praat whose stated reason is that "the plugin's
# own wrappers reach it through scripts/eml-lib-graphs.praat" -- i.e. a
# module can be legitimately absent from the generated barrel and present
# in the door chain at once, and setup.praat says so, with a reason, in one
# place. This file parses that SAME table (identically to v88, so the two
# readings of setup.praat cannot themselves disagree) and treats a
# not-in-barrel module as accounted for if the door chain actually reaches
# it -- it does not retype which module that is. Nothing else is exempted:
# a module the door chain reaches that setup.praat says nothing about at
# all is reported, and a barrel-table module the door chain does not reach
# is reported, by name, whatever its name is.
#
#     Rscript validate/v162_door_chain_population.R
#
# Input: the plugin source itself. No harness run and no Praat -- an
#        include never taken produces no artefact to read, which is the
#        same argument v88 makes for reading its population off disk.
#        $EML_PLUGIN_DIR overrides the tree read, for break tests.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
if (!dir.exists(plug)) stop("plugin tree not found: ", plug)

setup_path <- file.path(plug, "setup.praat")
check_true("v162", "setup.praat is where the module table lives",
           file.exists(setup_path))

root_rel  <- "scripts/eml-lib.praat"
root_path <- file.path(plug, root_rel)
check_true("v162",
           sprintf("the door chain's root is a file on disk (%s)", root_rel),
           file.exists(root_path))

if (!file.exists(setup_path) || !file.exists(root_path)) {
    if (!exists("EML_SUITE")) {
        eml_report("v162 door chain population")
        eml_exit()
    }
} else {

plug_abs <- normalizePath(plug, mustWork = TRUE)

# ---------------------------------------------------------------------------
# 1. THE BARREL TABLE AND THE NOT-IN-BARREL TABLE, READ EXACTLY AS v88 READS
#    THEM -- one parse of setup.praat, so the two files cannot disagree
#    about what setup.praat says.
# ---------------------------------------------------------------------------
src  <- readLines(setup_path, warn = FALSE)
code <- src[!grepl("^\\s*[#;]", src)]

inc_lines <- grep('^\\s*emlSetupModule\\$\\s*\\[\\s*[0-9]+\\s*\\]\\s*=', code,
                  value = TRUE)
in_barrel <- sub('^[^"]*"', "", inc_lines)
in_barrel <- sub('".*$', "", in_barrel)

ex_lines <- grep("^\\s*#\\s*not-in-barrel:", src, value = TRUE)
ex_body  <- sub("^\\s*#\\s*not-in-barrel:\\s*", "", ex_lines)
out_path <- trimws(sub("\\s+--\\s+.*$", "", ex_body))

check_true("v162",
           sprintf("setup.praat's module table has rows in it (%d)",
                   length(in_barrel)),
           length(in_barrel) > 0L)

# ---------------------------------------------------------------------------
# 2. THE DOOR CHAIN, WALKED TO A FIXED POINT OFF DISK.
# ---------------------------------------------------------------------------
# Every relative include target found anywhere in the walk resolves against
# plugin/scripts/ -- the directory of the ROOT file -- per Praat's own rule
# quoted above, never against the directory of the file that names it.
top_dir <- file.path(plug, "scripts")

include_targets <- function(file_abs) {
    if (!file.exists(file_abs)) return(character(0))
    l <- readLines(file_abs, warn = FALSE)
    l <- l[!grepl("^\\s*[#;]", l)]
    m <- regmatches(l, regexpr("^\\s*include\\s+\\S+", l))
    trimws(sub("^\\s*include\\s+", "", m))
}

visited   <- character(0)   # absolute paths already walked
resolved  <- character(0)   # absolute paths the chain names (files or not)
unresolved <- character(0)  # include targets that name no file on disk
queue     <- normalizePath(root_path, mustWork = TRUE)

while (length(queue) > 0) {
    cur <- queue[1]
    queue <- queue[-1]
    if (cur %in% visited) next
    visited <- c(visited, cur)
    targets <- include_targets(cur)
    for (t in targets) {
        abs_t <- normalizePath(file.path(top_dir, t), mustWork = FALSE)
        resolved <- c(resolved, abs_t)
        if (!file.exists(abs_t)) {
            unresolved <- c(unresolved, t)
        } else if (!(abs_t %in% visited)) {
            queue <- c(queue, abs_t)
        }
    }
}

check_true("v162",
           sprintf("the door chain found includes to follow (%d files walked from %s)",
                   length(visited), root_rel),
           length(visited) > 0L)

check_true("v162",
           sprintf("every include the door chain follows resolves to a file on disk%s",
                   if (length(unresolved))
                       paste0(" -- unresolved: ",
                              paste(unique(unresolved), collapse = ", "))
                   else ""),
           !length(unresolved))

# Reduce the walked files to plugin-relative paths, and keep only the
# modules under stats/ and graphs/ -- the same population boundary v88
# uses. scripts/eml-lib*.praat are the chain itself, not modules the chain
# is checked against.
resolved_rel <- unique(sub(paste0("^", plug_abs, "/"), "",
                            resolved[file.exists(resolved)]))
door_set <- sort(resolved_rel[grepl("^(stats|graphs)/", resolved_rel)])

check_true("v162",
           sprintf("the door chain resolves to modules under stats/ and graphs/ (%d)",
                   length(door_set)),
           length(door_set) > 0L)

# ---------------------------------------------------------------------------
# 3. THE ONE SANCTIONED ASYMMETRY: a not-in-barrel module the door chain
#    genuinely reaches is accounted for by that same setup.praat row, not
#    by this file inventing a second reason.
# ---------------------------------------------------------------------------
sanctioned <- intersect(out_path, door_set)
check_true("v162",
           sprintf("not-in-barrel module(s) the door chain legitimately reaches%s",
                   if (length(sanctioned))
                       paste0(": ", paste(sanctioned, collapse = ", "))
                   else " -- none"),
           TRUE)  # informational; setup.praat's own reason is the claim, not this file

accounted <- union(in_barrel, sanctioned)

# ---------------------------------------------------------------------------
# 3b. MODULES NO MENU NEEDS, COMPUTED FROM THE MENU BLOCK ITSELF.
# ---------------------------------------------------------------------------
# RULING_V162_INVARIANT_2026-09-02.md. setup.praat's module table and the door
# chain are DELIBERATELY different populations, which the table says in its own
# capitals at the site:
#
#   THEY ARE IN THE BARREL AND ON NO MENU. This list decides what a user's own
#   script can `include`; a menu entry is a separate registration above ...
#   What is listed here is loadable, not clickable.
#
# So a module with no menu behind it is not a defect, and the first draft of
# this file failed on two of them. Three door probes established the same thing
# independently: two-way ANOVA CRASHED, psychometrics and categorical had no
# door at all.
#
# THE EXEMPTION IS COMPUTED, NEVER LISTED. The ruling pins this: it is sourced
# from setup.praat's own menu-registration block, so a module that gains a menu
# entry loses its exemption in the same edit, by construction. A hand-kept list
# would be a second copy of the menus, free to drift from them -- the defect
# this whole wave exists to remove.
#
# Method: collect the door scripts the menu block registers, take every
# procedure they call, follow each into whichever module defines it, and keep
# going. A module none of that reaches is one no menu needs.
#
# THE CALL GRAPH IS BUILT FROM CODE, NOT FROM PROSE. A first version of this
# walk harvested `@name` from every line of every file, comments included, and
# one comment was enough to poison the result: eml-psychometrics.praat:93 names
# `@emlWilsonInterval` inside a sentence about a sibling procedure's default.
# The moment the reliability doorway made psychometrics genuinely menu-reachable,
# that sentence became an edge, eml-categorical.praat inherited a menu it has no
# door to, and the check failed on a module nothing calls. A comment cannot make
# a procedure reachable, so comments are stripped before any name is read --
# whole-line `#`/`;` comments the way the include walk already strips them, plus
# a trailing `;` comment outside string quotes. Mid-line `#` is left alone on
# purpose: in Praat it is the vector and matrix suffix (`.itemCols$#`, `t##`),
# not a comment marker.
#
# THE UNIVERSE IS THE SHIPPED TREE. dev/ is excluded. Nothing a menu registers
# includes a dev test, so a test can never make a module reachable; and because
# ownership here is one name to one file, a test that happens to define a name a
# production module also defines would silently reassign that name's owner and
# move the exemption. Three names are already defined twice inside dev/tests/.
menu_doors <- unique(sub('.*"(scripts/[^"]+\\.praat)".*', "\\1",
                  grep('Add menu command:.*"scripts/[^"]+\\.praat"',
                       src, value = TRUE)))
check_true("v162", "the menu block registers door scripts to trace from",
           length(menu_doors) > 0)

# Whole-line comments go first; then, on the lines that could still hide a call
# behind a trailing `;`, cut at the first `;` that follows whitespace outside a
# double-quoted string.
eml_code_lines <- function(ln) {
    ln <- ln[!grepl("^\\s*[#;]", ln)]
    hit <- grepl(";", ln, fixed = TRUE) & grepl("@", ln, fixed = TRUE)
    for (i in which(hit)) {
        ch <- strsplit(ln[i], "", fixed = TRUE)[[1]]
        q  <- FALSE
        for (j in seq_along(ch)) {
            if (ch[j] == '"') {
                q <- !q
            } else if (!q && ch[j] == ";" && j > 1L && grepl("\\s", ch[j - 1L])) {
                ln[i] <- substr(ln[i], 1L, j - 1L)
                break
            }
        }
    }
    ln
}

proc_defs <- list(); file_calls <- list()
tree_files <- list.files(plug, pattern = "\\.praat$", recursive = TRUE)
tree_files <- tree_files[!grepl("^dev/", tree_files)]
for (f in tree_files) {
    ln  <- tryCatch(readLines(file.path(plug, f), warn = FALSE),
                    error = function(e) character(0))
    ln  <- eml_code_lines(ln)
    dfs <- sub("^\\s*procedure\\s+([A-Za-z_][A-Za-z0-9_]*).*$", "\\1",
               grep("^\\s*procedure\\s+", ln, value = TRUE))
    if (length(dfs)) proc_defs[[f]] <- unique(dfs)
    cl <- unlist(regmatches(ln, gregexpr("@[A-Za-z_][A-Za-z0-9_]*", ln)))
    file_calls[[f]] <- unique(sub("^@", "", cl))
}
owner <- character(0)
for (f in names(proc_defs)) for (p in proc_defs[[f]]) owner[p] <- f

frontier <- unique(unlist(file_calls[intersect(menu_doors, names(file_calls))]))
seen <- character(0)
while (length(frontier)) {
    p <- frontier[1]; frontier <- frontier[-1]
    if (p %in% seen) next
    seen <- c(seen, p)
    # A called name with no definition in the tree is a Praat builtin or a
    # procedure defined in a file this walk does not index. Either way there
    # is nothing further to follow, so skip rather than subscript past the end.
    if (p %in% names(owner)) {
        m <- owner[[p]]
        if (!is.na(m) && m %in% names(file_calls))
            frontier <- c(frontier, file_calls[[m]])
    }
}
menu_needs <- unique(unname(owner[intersect(seen, names(owner))]))
no_menu    <- setdiff(accounted, menu_needs)

cat(sprintf("\n      modules no menu needs (computed from the menu block): %d\n",
            length(no_menu)))
for (m in no_menu) cat(sprintf("        %s\n", m))

accounted <- setdiff(accounted, no_menu)

# ---------------------------------------------------------------------------
# 4. THE TWO LISTS AGREE, ASSERTED AS A SET -- NAMED, NOT COUNTED.
#
# WHAT THIS FILE ACTUALLY CHECKS, AND WHAT IT DOES NOT.
#
# Checked here: every module setup.praat's table claims, MINUS the ones no menu
# needs, is reachable through the door chain.
#
# The true invariant, ruled as the target in RULING_V162_INVARIANT and filed as
# a post-1.0 refactor beside the recorder-generation one: every module a
# registered menu item transitively needs is reachable through the door chain.
# This file approximates it from the module-table side rather than walking the
# procedure graph as the acceptance test. The approximation catches the two-way
# defect exactly, which is what it was written for. A future reader should not
# re-derive today's confusion: the list comparison is the cheap stand-in, not
# the invariant.
# ---------------------------------------------------------------------------
# present   = what the door chain ACTUALLY resolves to, off disk -- ground
#             truth for what a click on a menu door can reach.
# accounted = what setup.praat's table CLAIMS is a module (plus the one
#             sanctioned exception above).
#
# A module in `accounted` and not in `present` is the exact shape of the
# two-way defect: setup.praat's table says the module exists and is
# reachable, but the hand-maintained chain the menu doors actually include
# does not carry it, and a user who clicks that door meets a parse-time
# "Procedure not found" instead of a result. eml_census names it, not just
# counts it, for the same reason the two-way defect was invisible to v88:
# a count that is off by one says nothing about WHICH module to fix.
eml_census("v162", "module setup.praat's table and the door chain must agree on",
           present = door_set, accounted = accounted)

}

if (!exists("EML_SUITE")) {
    eml_report("v162 door chain population: setup.praat's table vs the door chain's resolved includes")
    eml_exit()
}
