# ============================================================================
# v88_barrel_population.R -- every module is either in the barrel or
# accounted for, and setup.praat is the only place that says which
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS
#
# setup.praat's module table is the whole of what a user's one include line
# loads. On 18 August 2026 stats/eml-psychometrics.praat and
# stats/eml-categorical.praat were found sitting outside it: four finished,
# oracled procedures -- @emlCronbachAlpha, @emlAlphaInfluence,
# @emlChiSquareIndependence, @emlWilsonInterval, driven against base R by
# v90 to v93 -- that no script a user could write was able to load. They had
# been outside it since they were written.
#
# NOTHING IN THIS SUITE COULD HAVE SAID SO, and it is worth being exact about
# why, because the gap is structural rather than an oversight in any one file:
#
#   * v82 pins the barrel against CANON, a module list retyped in that file,
#     and against the block @emlRecordRender emits. Both are statements about
#     the ORDER and the AGREEMENT of two writers. Drop a module from
#     setup.praat and from CANON in the same commit and both are satisfied.
#   * v78's include closure asks whether every `include` RESOLVES. A module
#     that is never included is not a dangling include.
#   * v79 counts include lines in the release artefact against the shipped
#     source. A module absent from the barrel is absent from both sides.
#   * Every other check reaches a procedure by CALLING it. A module drops out
#     of the barrel and the suite notices only if some validator happens to
#     call something defined in it -- which is coverage by coincidence.
#
# So the population that needed checking was never a list. It is the FOLDER:
# every .praat file under stats/ and graphs/, walked off disk, compared
# against what setup.praat says about it.
#
# THE TWO LISTS ARE ONE STATEMENT, IN ONE FILE. setup.praat carries the module
# table -- it has to, it is the generator -- and immediately beneath it the
# rows that name the modules deliberately left out, with a reason on each:
#
#     # not-in-barrel: <plugin-relative path> -- <why>
#
# A second hand-maintained list somewhere else is how MANIFEST.txt and the
# tree came apart for twelve days in August, so there is not one. This file
# retypes NEITHER list; it parses both out of setup.praat and walks the
# folders. Adding a module and forgetting the barrel is red. Deleting a module
# from the barrel is red. Excluding one without saying why is red. Naming a
# file that is not there is red.
#
# WHAT IT DOES NOT DO. It does not judge WHETHER an exclusion is right -- no
# check can, that is a reading -- and it does not re-check the order, the
# generated file or the recorder's agreement with it, all of which are v82's.
# It asks one question: is every module accounted for.
#
#     Rscript validate/v88_barrel_population.R
#
# Input: the plugin source itself. No harness run and no Praat, which is the
#        point -- an omission from the barrel produces no artefact to read.
#        $EML_PLUGIN_DIR overrides the tree read, for break tests.
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

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
if (!dir.exists(plug)) stop("plugin tree not found: ", plug)

setup_path <- file.path(plug, "setup.praat")
check_true("v88", "setup.praat is where the module table lives",
           file.exists(setup_path))
if (!file.exists(setup_path)) {
    if (!exists("EML_SUITE")) {
        eml_report("v88 barrel population")
        eml_exit()
    }
} else {

src <- readLines(setup_path, warn = FALSE)

# ---------------------------------------------------------------------------
# 1. THE TWO LISTS, READ OUT OF setup.praat
# ---------------------------------------------------------------------------
# THE TABLE. Only the assignment lines, and only outside a comment: the block
# of prose above the table quotes two of these paths, and a check that counted
# prose would be measuring how the table is described rather than what it is.
code <- src[!grepl("^\\s*[#;]", src)]
inc_lines <- grep('^\\s*emlSetupModule\\$\\s*\\[\\s*[0-9]+\\s*\\]\\s*=', code,
                  value = TRUE)
in_barrel <- sub('^[^"]*"', "", inc_lines)
in_barrel <- sub('".*$', "", in_barrel)

# THE COUNT THE GENERATOR'S OWN LOOP RUNS TO. A table of thirteen rows read by
# a loop that stops at twelve emits twelve lines, and every row after the
# count is a module that is written down and not shipped -- which looks exactly
# like a module that is in the barrel to anyone reading this file.
n_decl <- suppressWarnings(as.integer(sub(
    "^\\s*emlSetupNModules\\s*=\\s*([0-9]+).*$", "\\1",
    grep("^\\s*emlSetupNModules\\s*=", code, value = TRUE)[1])))

check_true("v88",
           sprintf("setup.praat's module table has rows in it (%d)",
                   length(in_barrel)),
           length(in_barrel) > 0L)
check("v88", "and emlSetupNModules is the number of rows, not a typed number",
      length(in_barrel), if (length(n_decl) && !is.na(n_decl)) n_decl else -1,
      tol = 0)
check_true("v88", "every row of the table names a module exactly once",
           !anyDuplicated(in_barrel))

# THE EXCLUSIONS. Rows in the same file, deliberately in comments -- Praat must
# not execute them, and a reader of setup.praat must meet them beside the
# table rather than in another file.
ex_lines <- grep("^\\s*#\\s*not-in-barrel:", src, value = TRUE)
ex_body  <- sub("^\\s*#\\s*not-in-barrel:\\s*", "", ex_lines)
out_path <- trimws(sub("\\s+--\\s+.*$", "", ex_body))
out_why  <- ifelse(grepl("\\s--\\s", ex_body),
                   trimws(sub("^.*?\\s--\\s", "", ex_body)), "")

check_true("v88",
           sprintf("setup.praat carries the not-in-barrel rows (%d)",
                   length(out_path)),
           length(out_path) > 0L)
check_true("v88", "no module is excluded twice", !anyDuplicated(out_path))
# THE REASON IS REQUIRED, AND A LENGTH IS THE ONLY PART OF IT A MACHINE CAN
# JUDGE. "Out of the barrel" with nothing beside it cannot be told from an
# oversight six months later, which is the state this whole file exists to end.
short <- out_path[nchar(out_why) < 40L]
check_true("v88",
           sprintf("every not-in-barrel row carries a reason%s",
                   if (length(short)) paste0(" -- bare: ",
                                             paste(short, collapse = ", "))
                   else ""),
           !length(short))

# ---------------------------------------------------------------------------
# 2. THE POPULATION, WALKED OFF DISK
# ---------------------------------------------------------------------------
# stats/ AND graphs/ AND NOTHING ELSE, and the boundary is not arbitrary.
# A module is a library of procedures that a script includes; those two
# folders hold all of them. scripts/ holds entry points -- files Praat runs
# from a menu registration, each with its own `form` -- and the shipped
# relative barrels, which are lists of includes rather than definitions of
# procedures. Including an entry point from the barrel would run a dialog at
# parse time. data/, docs/, dev/ and sprites/ hold no .praat a user loads.
mod_dirs <- c("stats", "graphs")
on_disk <- unlist(lapply(mod_dirs, function(d) {
    f <- list.files(file.path(plug, d), pattern = "\\.praat$")
    if (!length(f)) character(0) else file.path(d, f)
}), use.names = FALSE)
on_disk <- sort(on_disk)

check_true("v88",
           sprintf("the module folders hold files to account for (%d in %s)",
                   length(on_disk), paste(mod_dirs, collapse = ", ")),
           length(on_disk) > 0L)

# ---------------------------------------------------------------------------
# 3. THE THREE WAYS THE ACCOUNT CAN FAIL
# ---------------------------------------------------------------------------
# ONE: a module on disk that neither list names. This is the shape the survey
# kernels had. It is the check the whole file is for, and it names the files
# rather than reporting a count, because the fix is per file.
unaccounted <- setdiff(on_disk, c(in_barrel, out_path))
check_true("v88",
           sprintf("every module under stats/ and graphs/ is either in the barrel or excluded with a reason%s",
                   if (length(unaccounted))
                       paste0(" -- unaccounted: ",
                              paste(unaccounted, collapse = ", ")) else ""),
           !length(unaccounted))

# TWO: a name in one of the lists that is not a file. A rename that updates
# the table and not the folder, or the other way round, leaves the barrel
# emitting an include line for a file that is not there -- and Praat's
# `include` of a missing file is a parse error in the USER's script, which is
# the worst place for it to arrive.
missing_in <- setdiff(in_barrel, on_disk)
check_true("v88",
           sprintf("every module the barrel names is a file on disk%s",
                   if (length(missing_in))
                       paste0(" -- missing: ",
                              paste(missing_in, collapse = ", ")) else ""),
           !length(missing_in))
missing_out <- setdiff(out_path, on_disk)
check_true("v88",
           sprintf("every excluded module is a file on disk%s",
                   if (length(missing_out))
                       paste0(" -- missing: ",
                              paste(missing_out, collapse = ", ")) else ""),
           !length(missing_out))

# THREE: a module in both lists. The two lists are one statement, so a path in
# both is a contradiction rather than a duplication -- and the reader who
# meets it has no way to tell which half is the current decision.
both <- intersect(in_barrel, out_path)
check_true("v88",
           sprintf("no module is in the barrel and excluded from it at once%s",
                   if (length(both))
                       paste0(" -- both: ", paste(both, collapse = ", "))
                   else ""),
           !length(both))

# AND THE ACCOUNT BALANCES. Stated as an equation as well as a set difference
# so that the report carries the three numbers a reader would otherwise have
# to count by hand.
check("v88",
      sprintf("the two lists account for the folder exactly (%d in barrel + %d excluded)",
              length(in_barrel), length(out_path)),
      length(on_disk), length(in_barrel) + length(out_path), tol = 0)

# ---------------------------------------------------------------------------
# 4. AN EXCLUSION IS A CLAIM THAT THE BARREL DOES NOT REACH IT
# ---------------------------------------------------------------------------
# `include` is a parse-time text paste, so a module included BY a barrel module
# is in the barrel whatever this table says. A row claiming otherwise is a
# statement about the plugin that is simply false, and it would be false
# silently: the procedure resolves, the user never learns which line brought
# it in, and the exclusion reads as documentation of something that is not
# happening.
inc_of <- function(rel) {
    p <- file.path(plug, rel)
    if (!file.exists(p)) return(character(0))
    l <- readLines(p, warn = FALSE)
    l <- l[!grepl("^\\s*[#;]", l)]
    m <- regmatches(l, regexpr("^\\s*include\\s+\\S+", l))
    basename(trimws(sub("^\\s*include\\s+", "", m)))
}
pulled <- unique(unlist(lapply(in_barrel, inc_of), use.names = FALSE))
reached <- out_path[basename(out_path) %in% pulled]
check_true("v88",
           sprintf("no excluded module is pulled in by a barrel module anyway%s",
                   if (length(reached))
                       paste0(" -- reached: ", paste(reached, collapse = ", "))
                   else ""),
           !length(reached))

}

if (!exists("EML_SUITE")) {
    eml_report("v88 barrel population: every module accounted for")
    eml_exit()
}
