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
# 4. THE TWO LISTS AGREE, ASSERTED AS A SET -- NAMED, NOT COUNTED.
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
