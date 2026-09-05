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


# ===========================================================================
# LEG 4 -- THE SELF-INCLUDING PROBES
# ---------------------------------------------------------------------------
# A fourth copy of "which modules exist" lives in validate/ itself. Eleven
# checks do not load the plugin through any door: each builds its own Praat
# script and its own `include` block, naming module files one at a time --
# 69 include lines across the eleven. Nothing pinned those blocks against
# anything, and on 4 September that cost the whole marginal-means battery.
# The Tukey re-pointing moved the studentized-range quantile behind
# @emlInvStudentizedRangeQ; the marginal-means block never gained
# stats/eml-studentized-range.praat; the probe died at its first Tukey call
# and the file reported ONE failure while all 2,352 of its results came back
# NA. A dead battery and a passing one differ by one line in a summary.
#
# THIS IS A LEG AND NOT A SIBLING because the ruling ordering it says so
# (ANSWER_MODULE_LISTS section 2, confirmed by CONFIRMATION_CANON_BARREL:
# "one new leg on the door-chain check"). The sibling argument in this
# file's own header above is about v88 and is not re-litigated here.
#
# WHAT IT ASSERTS. For each such check: resolve its include block
# transitively off disk, close over the plugin's call graph from every
# @procedure the check names, and require the defining module of every
# reached procedure to be in the resolved set.
#
# TWO THINGS IT HAD TO LEARN, both measured rather than assumed:
#   * The defect is TRANSITIVE. A first version scanned only the procedures
#     a check names directly and PASSED the seeded historical omission --
#     the marginal-means probe names @emlAnovaKernelTwoWayPostHoc, and it is
#     the KERNEL that calls @emlInvStudentizedRangeQ.
#   * A call behind `if variableExists (...)` is NOT an edge. The recorder
#     hooks in every analysis door sit inside that guard and never run for a
#     caller that did not load the recorder. Counting them reported every
#     recorder procedure as unloadable for eleven checks that run clean.
# ---- 1. which checks build their own include block -------------------------
# THE VALIDATE FOLDER IS THIS FILE'S OWN FOLDER. v162 resolves the plugin
# through EML_PLUGIN_DIR and never needed a repo root before this leg; using
# .here keeps the leg working under the shadow-tree runs that set that
# variable to a copy.
r_files <- list.files(repo_path("validate"), pattern = "^v[0-9]+.*\\.R$",
                      full.names = TRUE)
builds_block <- function(path) {
    any(grepl('paste0("include ", file.path(plug', readLines(path, warn = FALSE),
              fixed = TRUE))
}
# THIS FILE IS NOT A PROBE, and it matches its own filter because the filter
# string appears in the line above as a literal. Without this exclusion the
# leg treats v162 as a probe with an empty include block and reports every
# procedure named anywhere in it as unloadable -- measured: 593 of them.
probes <- r_files[vapply(r_files, builds_block, logical(1))]
probes <- probes[basename(probes) != "v162_door_chain_population.R"]

check_true("v162", "there are self-including probes to account for",
           length(probes) > 0)

# ---- 2. the module each procedure is defined in, and who calls whom ---------
# NORMALISED ON BOTH SIDES. This file reaches the plugin through the
# repository's `plugin` symlink, while the include seeds below resolve to the
# real `plugin_EML_StatsGraphs` path. Comparing one against the other matches
# nothing and reports every probe as broken -- measured: 593 false failures
# across all eleven.
mods <- normalizePath(c(
    list.files(file.path(plug, "stats"), pattern = "\\.praat$", full.names = TRUE),
    list.files(file.path(plug, "graphs"), pattern = "\\.praat$", full.names = TRUE)),
    mustWork = FALSE)
defs <- list()
for (m in mods) {
    ln <- readLines(m, warn = FALSE)
    hits <- sub("^procedure[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*$", "\\1",
                grep("^procedure[[:space:]]", ln, value = TRUE))
    for (h in hits) defs[[h]] <- c(defs[[h]], m)
}
check_true("v162", "the plugin defines procedures to resolve against",
           length(defs) > 0)

# THE CALL GRAPH, because the defect is transitive and a direct scan misses it.
# Measured on the exact historical failure: v156 names @emlAnovaKernelTwoWayPostHoc,
# and it is the KERNEL that calls @emlInvStudentizedRangeQ. A check that only
# looked at the procedures the probe names itself passed the seeded omission --
# which is the omission that killed the battery. What a probe must be able to
# load is the closure of what it names, not the surface of it.
#
# COMMENT STRIPPING IS NOT COSMETIC HERE. A Praat comment starts with # or ;
# at the start of the line; a # in the MIDDLE of a line is the vector-type
# suffix. The same call-graph walk in v162 was wrong for one wave because a
# commented-out call was read as an edge.
calls <- list()
for (m in mods) {
    ln <- readLines(m, warn = FALSE)
    ln <- ln[!grepl("^[[:space:]]*[#;]", ln)]
    cur <- NA_character_
    # OPTIONAL-MODULE CALLS ARE NOT EDGES. The plugin's idiom for a module a
    # caller may not have loaded is `if variableExists ("emlRecordLoaded")`,
    # and the recorder hooks in every analysis door sit inside one. Those
    # calls never execute for a caller that did not load the recorder, so
    # requiring the probe to load it would fail eleven checks that work.
    # Measured: without this, the guard reported every recorder procedure as
    # unloadable for probes that run clean.
    skip <- 0L; depth <- 0L
    for (l in ln) {
        if (grepl("^procedure[[:space:]]", l)) {
            cur <- sub("^procedure[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*$", "\\1", l)
            if (is.null(calls[[cur]])) calls[[cur]] <- character(0)
            skip <- 0L; depth <- 0L
            next
        }
        opens <- grepl("^[[:space:]]*(if|for|while)[[:space:]]", l)
        closes <- grepl("^[[:space:]]*(endif|endfor|endwhile)\\b", l)
        if (opens) {
            depth <- depth + 1L
            if (skip == 0L && grepl("variableExists", l)) skip <- depth
        }
        if (skip == 0L && !is.na(cur)) {
            hits <- unlist(regmatches(l, gregexpr("@[A-Za-z_][A-Za-z0-9_]*", l)))
            if (length(hits)) calls[[cur]] <- unique(c(calls[[cur]], sub("^@", "", hits)))
        }
        if (closes) {
            if (skip == depth) skip <- 0L
            depth <- max(0L, depth - 1L)
        }
    }
}
check_true("v162", sprintf("the call graph has edges to close over (%d procedures)",
                           length(calls)), length(calls) > 0)

close_calls <- function(seeds) {
    seen <- character(0); todo <- seeds
    while (length(todo)) {
        n <- todo[1]; todo <- todo[-1]
        if (n %in% seen) next
        seen <- c(seen, n)
        todo <- c(todo, setdiff(calls[[n]], seen))
    }
    seen
}

# ---- 3. resolve one include block transitively ------------------------------
# `include` is a parse-time paste, so a listed module drags in whatever it
# lists. Paths inside a module are relative to the RUN script's folder, which
# for these probes is a scratch folder; the modules' own "../stats/x.praat"
# forms are resolved against the plugin root here, which is where they land.
resolve_block <- function(seed) {
    seen <- character(0)
    todo <- seed
    while (length(todo)) {
        f <- todo[1]; todo <- todo[-1]
        if (f %in% seen || !file.exists(f)) next
        seen <- c(seen, f)
        ln <- readLines(f, warn = FALSE)
        inc <- grep("^[[:space:]]*include[[:space:]]", ln, value = TRUE)
        inc <- sub("^[[:space:]]*include[[:space:]]+", "", inc)
        for (i in inc) {
            cand <- normalizePath(file.path(dirname(f), i), mustWork = FALSE)
            if (!file.exists(cand)) {
                cand <- normalizePath(file.path(plug, sub("^\\.\\./", "", i)),
                                      mustWork = FALSE)
            }
            todo <- c(todo, cand)
        }
    }
    seen
}

# ---- 4. the assertion, per probe --------------------------------------------
unloadable <- list()
comment_only <- list()

for (p in probes) {
    ln <- readLines(p, warn = FALSE)

    # THE SEED IS EVERY MODULE PATH THE FILE NAMES, not only the ones written
    # inline on an include line. Probes routinely bind a path to a variable
    # first -- v145 does exactly that with INF and ANA -- and reading only
    # `paste0("include ", file.path(plug, ...))` lines misses those and
    # reports a probe as unable to load a module it loads on the next line.
    # Measured: that mistake produced 30 false failures on checks the suite
    # records as passing.
    #
    # OVER-APPROXIMATION, DELIBERATE AND ONE-DIRECTIONAL. A path the file
    # names for some other reason is counted as loaded. That can only hide a
    # real omission, never invent one, so the check keeps the property that
    # matters: it never cries wolf, and a failure here is always real.
    blkm <- gregexpr('file\\.path\\(plug,[^)]*\\.praat"\\)', ln)
    blk <- unlist(regmatches(ln, blkm))
    seed <- vapply(blk, function(one) {
        q <- gsub('"', "", unlist(regmatches(one, gregexpr('"[^"]+"', one))))
        if (!length(q)) return(NA_character_)
        normalizePath(do.call(file.path, c(list(plug), as.list(q))), mustWork = FALSE)
    }, character(1), USE.NAMES = FALSE)
    seed <- seed[!is.na(seed)]
    loaded <- resolve_block(seed)

    code <- ln[!grepl("^[[:space:]]*#", ln)]
    called <- unique(unlist(regmatches(code, gregexpr("@[A-Za-z_][A-Za-z0-9_]*", code))))
    called <- sub("^@", "", called)
    commented <- setdiff(
        sub("^@", "", unique(unlist(regmatches(ln, gregexpr("@[A-Za-z_][A-Za-z0-9_]*", ln))))),
        called)

    called <- close_calls(called)
    for (nm in called) {
        home <- defs[[nm]]
        if (is.null(home)) next           # not a plugin procedure; Praat builtin or a local
        if (!any(home %in% loaded)) {
            unloadable[[length(unloadable) + 1]] <-
                sprintf("%s reaches @%s, defined in %s, which its include block does not load",
                        basename(p), nm, paste(basename(home), collapse = "/"))
        }
    }
    for (nm in commented) {
        home <- defs[[nm]]
        if (!is.null(home) && !any(home %in% loaded)) {
            comment_only[[length(comment_only) + 1]] <-
                sprintf("%s names @%s in comments only", basename(p), nm)
        }
    }
}

# THE OFFENDERS PRINT ABOVE THE CHECK, ONE PER LINE, and the check line
# carries only the count. A single check line holding thirty findings
# overflowed the report formatter outright, and a reader cannot act on a
# wall of semicolons anyway.
if (length(unloadable)) {
    cat("\n")
    for (u in unlist(unloadable)) cat("  UNLOADABLE  ", u, "\n", sep = "")
    cat("\n")
}

check_true("v162",
    sprintf("every self-including probe can load every procedure it reaches (%d probes, %d unloadable)",
            length(probes), length(unloadable)),
    length(unloadable) == 0)

if (!exists("EML_SUITE")) {
    eml_report("v162 door chain population: setup.praat's table vs the door chain's resolved includes")
    eml_exit()
}
