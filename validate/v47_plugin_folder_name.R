# ============================================================================
# v47_plugin_folder_name.R -- the install folder name, agreed everywhere
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. A recorded script is only useful if it runs, and it
# runs only if its eleven `include` lines point at the folder the plugin was
# actually installed into. Praat's rule is that the folder under
# preferencesDirectory$ is `plugin_` + a name of the author's choosing, so the
# name is a CONVENTION -- it cannot be derived from anything in this tree,
# because the source folder is called `plugin/`.
#
# The installed folder is `plugin_EML_StatsGraphs`. Praat gives a script no
# way to learn its own plugin folder, so the name is a constant the plugin
# carries -- and it carries it in ONE place, @emlPluginFolder in
# stats/eml-record.praat, which everything that builds a path or prints an
# instruction asks. A recorder that spelled it differently from the folder
# Praat installed would emit eleven `include` lines naming a folder that does
# not exist, and EVERY RECORDED SCRIPT WOULD BE UNRUNNABLE -- the recorder's
# whole output, worthless, on every platform. A single misspelling is all it
# takes, which is why there is a single place to misspell.
#
# NOTHING CAUGHT IT, and there were three separate reasons, each of which this
# file closes:
#
#   1. plugin/dev/tests/phase1/test-record.praat ASSERTED THE WRONG STRING.
#      The test agreed with the defect, so the defect read as correct. Its
#      only assertion touching the include lines was that the root is
#      non-empty (:92-93), which passes for any string at all.
#   2. harness/record/roundtrip.sh -- the one harness that RUNS the emitted
#      script and byte-diffs the result, so the one thing that would have
#      failed instantly -- OVERRIDES emlRecordPluginRoot$ at :76 and :79 so
#      the round trip compares this build against itself. That override is
#      correct for its purpose and it makes the production literal untestable
#      by construction.
#   3. Nothing read the folder name out of a RENDERED artefact at all.
#
# So the population that needed checking was the rendered output of the one
# harness that does NOT override -- harness/record_e2e -- compared against an
# oracle. This file is that comparison.
#
# THE ORACLE IS EXECUTABLE, not another literal. harness/walks/rig.sh and the
# two walk libs INSTALL the plugin by symlinking it to `plugin_<name>` under a
# scratch pref dir. That is the repo's only machine-checkable statement of the
# folder name -- a rig that names it wrongly produces a Praat that cannot find
# the plugin, and those harnesses fail. Checking the recorder against the rigs
# means the two cannot drift without something breaking.
#
#     Rscript validate/v47_plugin_folder_name.R
#
# Input: harness/record_e2e/out/recorded.praat -- rendered by the UNMODIFIED
#        production path (harness/record_e2e/run.sh sets emlRecordPluginRoot$
#        nowhere) -- plus the source tree. $EML_PLUGIN_DIR and $EML_RECORDED
#        override, for break tests.
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
harn <- repo_path("harness")

# ---------------------------------------------------------------------------
# 1. THE ORACLE: what the rigs actually install
# ---------------------------------------------------------------------------
# `ln -sfn <src> <prefs>/plugin_NAME`. Read the NAME out of every rig and
# require them to agree, because an oracle that disagrees with itself is not
# an oracle.
rigs <- list.files(harn, pattern = "\\.sh$", recursive = TRUE,
                   full.names = TRUE)
rig_lines <- unlist(lapply(rigs, function(p) {
    x <- readLines(p, warn = FALSE)
    x[grepl("ln -sfn.*plugin_", x)]
}))
check_true("v47", "some rig installs the plugin by name", length(rig_lines) > 0)

rig_names <- unique(sub(".*/plugin_([A-Za-z0-9_]+).*", "\\1", rig_lines))
check("v47", "every rig installs the SAME folder name", 1L, length(rig_names),
      tol = 0)
NAME <- rig_names[1]
FOLDER <- paste0("plugin_", NAME)
check_true("v47", sprintf("the installed folder name is readable (%s)", FOLDER),
           nzchar(NAME) && nchar(NAME) > 2)

# ---------------------------------------------------------------------------
# 2. THE RENDERED ARTEFACT AGREES -- the check that was missing
# ---------------------------------------------------------------------------
# recorded.praat is emitted by the production literal with no override. Its
# include lines are the thing a user's Praat will actually try to read.
rec <- Sys.getenv("EML_RECORDED", unset = "")
if (!nzchar(rec)) rec <- file.path(harn, "record_e2e", "out", "recorded.praat")
check_true("v47", "the rendered recording exists", file.exists(rec))

if (file.exists(rec)) {
    em <- readLines(rec, warn = FALSE)
    inc <- em[grepl("^include ", em)]
    check_true("v47", "the rendered recording carries include lines",
               length(inc) > 0)

    # EVERY line, not "some line". One module left behind under the old name
    # is one module that fails to load, and Praat stops at the first bad
    # include -- so a partial rename is as fatal as no rename.
    bad <- inc[!grepl(FOLDER, inc, fixed = TRUE)]
    check_true("v47",
               sprintf("every include line names %s (%d line(s), %d wrong)",
                       FOLDER, length(inc), length(bad)),
               length(bad) == 0)

    # AND NO INCLUDE NAMES A DIFFERENT plugin_ FOLDER. The check above passes
    # if a line names both the right folder and a stale one; this one does
    # not. It is also what catches a half-applied rename.
    other <- unique(unlist(regmatches(inc,
                gregexpr("plugin_[A-Za-z0-9_]+", inc))))
    check_true("v47",
               sprintf("no include names another plugin_ folder (%s)",
                       paste(setdiff(other, FOLDER), collapse = ", ")),
               all(other == FOLDER))

    # THE HEADER BLOCK TOO. Those four platform lines are what a user reads
    # and edits when the include fails, so a stale name there sends them to a
    # folder that does not exist -- and they were stale in a committed
    # artefact until 14 Aug 2026 with nothing objecting.
    hdr <- em[grepl("plugin_", em) & grepl("^#", em)]
    check_true("v47", "the header block names the folder for the user",
               length(hdr) >= 4)
    hbad <- hdr[!grepl(FOLDER, hdr, fixed = TRUE)]
    check_true("v47",
               sprintf("every header line names %s (%d of %d wrong)", FOLDER,
                       length(hbad), length(hdr)),
               length(hbad) == 0)
}

# ---------------------------------------------------------------------------
# 3. NO COMMITTED ARTEFACT ANYWHERE CARRIES A STALE NAME
# ---------------------------------------------------------------------------
# The defect's second life: harness/record/graph_out/emitted.praat kept the
# old string in four header lines for a day after the fix, because the
# harness that renders it overrides the root and so nothing regenerated it.
# A stale artefact reads as evidence, which is worse than no artefact.
arte <- list.files(harn, pattern = "\\.praat$", recursive = TRUE,
                   full.names = TRUE)
arte <- arte[grepl("/(out|graph_out|qq_out|stress_out)/", arte)]
stale <- character(0)
for (p in arte) {
    x <- readLines(p, warn = FALSE)
    hits <- unlist(regmatches(x, gregexpr("plugin_[A-Za-z0-9_]+", x)))
    wrong <- setdiff(unique(hits), FOLDER)
    if (length(wrong)) stale <- c(stale, sprintf("%s: %s",
        sub(paste0("^", harn, "/"), "", p), paste(wrong, collapse = ",")))
}
check_true("v47", sprintf("no rendered artefact carries a stale folder name (%s)",
                          paste(stale, collapse = "; ")),
           length(stale) == 0)

# ---------------------------------------------------------------------------
# 4. THE SHIPPING SOURCE AGREES WITH THE RIGS
# ---------------------------------------------------------------------------
# Praat gives a script no way to learn its own plugin folder, so the name is a
# constant the plugin carries. Every mention of it anywhere in the shipped
# tree -- prose and code alike, .praat and .md -- has to be the name the rigs
# install.
src <- list.files(plug, pattern = "\\.(praat|md)$", recursive = TRUE,
                  full.names = TRUE)
src <- src[!grepl("/dev/", src, fixed = TRUE)]
src_bad <- character(0)
src_n <- 0
for (p in src) {
    x <- readLines(p, warn = FALSE)
    hits <- unlist(regmatches(x, gregexpr("plugin_[A-Za-z0-9_]+", x)))
    src_n <- src_n + length(hits)
    wrong <- setdiff(unique(hits), FOLDER)
    if (length(wrong)) src_bad <- c(src_bad, sprintf("%s: %s",
        sub(paste0("^", plug, "/"), "", p), paste(wrong, collapse = ",")))
}
check_true("v47", "the shipping tree names the folder at all", src_n >= 6)
check_true("v47", sprintf("every shipping literal agrees with the rigs (%s)",
                          paste(src_bad, collapse = "; ")),
           length(src_bad) == 0)

# ---------------------------------------------------------------------------
# 4b. THE NAME IS WRITTEN ONCE, AND THE REST ASK FOR IT
# ---------------------------------------------------------------------------
# Section 4 requires the shipped mentions to AGREE. That is the weaker half of
# the guarantee, and on its own it is a promise kept by hand: every mention
# has to be found and edited together, and a rename that reaches all but one
# of them leaves a plugin that agrees with itself everywhere the editor
# looked. The failure is silent in the worst way -- setup.praat writing its
# barrel to a folder computed from a stale copy of the name produces no file,
# no error and no clue, because that write is deliberately unchecked so a
# read-only install still gets its menus.
#
# So the executable name is written in exactly ONE place, @emlPluginFolder in
# stats/eml-record.praat, and every consumer asks. That is what this section
# pins: not "the copies agree today" but "there are no copies".
#
# WHAT IS COUNTED IS EXECUTABLE TEXT. Praat comments open with "#", ";" or
# "!"; a header line saying which folder a file belongs to is a note to a
# reader, is evaluated by nothing, and cannot send a write anywhere. Those are
# left to section 4, which requires them to be right. What can misdirect the
# plugin is a name the interpreter reads, and there is one of those.
praat_src <- list.files(plug, pattern = "\\.praat$", recursive = TRUE,
                        full.names = TRUE)
praat_src <- praat_src[!grepl("/dev/", praat_src, fixed = TRUE)]
code_hits <- list()
for (p in praat_src) {
    x <- readLines(p, warn = FALSE)
    x <- x[!grepl("^\\s*[#;!]", x)]
    n <- length(unlist(regmatches(x, gregexpr("plugin_[A-Za-z0-9_]+", x))))
    if (n) code_hits[[sub(paste0("^", plug, "/"), "", p)]] <- n
}
total_code <- sum(unlist(code_hits))
check_true("v47",
           sprintf("the folder name is executable text in exactly one place (%s)",
                   if (length(code_hits))
                       paste(sprintf("%s x%d", names(code_hits),
                                     unlist(code_hits)), collapse = ", ")
                   else "nowhere"),
           total_code == 1L)
check_true("v47", "and that place is stats/eml-record.praat",
           identical(names(code_hits), "stats/eml-record.praat"))

# THE ONE PLACE IS THE DEFINITION, not some incidental line that happens to be
# the last survivor. It has to be the assignment inside @emlPluginFolder, and
# @emlPluginFolder has to exist to be asked.
recsrc <- file.path(plug, "stats", "eml-record.praat")
if (file.exists(recsrc)) {
    x <- readLines(recsrc, warn = FALSE)
    hits <- unlist(regmatches(x, gregexpr("plugin_[A-Za-z0-9_]+", x)))
    check_true("v47", sprintf("eml-record.praat names the folder (%d time(s))",
                              length(hits)),
               length(hits) >= 1)
    check_true("v47", "and every one of them is the installed name",
               length(hits) > 0 && all(hits == FOLDER))
    check_true("v47", "eml-record.praat defines @emlPluginFolder exactly once",
               sum(grepl("^procedure emlPluginFolder\\s*$", x)) == 1L)
    check_true("v47",
               sprintf("and the single executable name is that procedure's .name$ (= %s)",
                       FOLDER),
               sum(grepl(sprintf('^\\s*\\.name\\$\\s*=\\s*"%s"\\s*$', FOLDER),
                         x)) == 1L)
}

# EVERY SHIPPED FILE THAT NEEDS THE NAME ASKS FOR IT. Named
# one by one, because "no file spells it" is satisfied by a consumer that
# stopped using the name altogether -- a sprite loader that lost its plugin
# strategy, a quick start that stopped telling the user where the README is.
# Each of these has to reach the shared answer, and the way it reaches it is
# the check.
asks <- list(
    "setup.praat" = "emlPluginRoot\\.abs\\$",
    "graphs/eml-graph-procedures.praat" = "emlPluginRoot\\.abs\\$",
    "scripts/eml-tutorial.praat" = "emlPluginRoot\\.abs\\$",
    "scripts/eml-quick-start.praat" = "emlPluginFolder\\.name\\$")
for (rel in names(asks)) {
    p <- file.path(plug, rel)
    x <- if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
    x <- x[!grepl("^\\s*[#;!]", x)]
    check_true("v47",
               sprintf("%s asks the shared procedure for the folder", rel),
               any(grepl(asks[[rel]], x)))
}

# ---------------------------------------------------------------------------
# 5. THE INSTALL INSTRUCTION AGREES
# ---------------------------------------------------------------------------
# A user who follows the README makes the folder. If the README says one name
# and the recorder emits another, the recorder is wrong for every user who
# did as they were told.
rd <- file.path(plug, "README.md")
if (file.exists(rd)) {
    x <- readLines(rd, warn = FALSE)
    hits <- unlist(regmatches(x, gregexpr("plugin_[A-Za-z0-9_]+", x)))
    check_true("v47", "the README tells the user the folder name",
               length(hits) > 0)
    check_true("v47", "and it is the name the recorder emits",
               length(hits) > 0 && all(hits == FOLDER))
}

if (!exists("EML_SUITE")) {
    eml_report("v47 plugin folder name: the recorder, the rigs and the README agree")
    eml_exit()
}
