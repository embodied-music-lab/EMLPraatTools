# ============================================================================
# v51_advanced_mode.R -- the two fixes that rested on my having read the code
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Two changes shipped on 13 August 2026 and were carried
# for a day on nothing but a reading of the source. Both are invisible in the
# ordinary sense: when they fail, nothing errors, nothing is missing from the
# file list, and no warning is printed. They fail as SILENCE.
#
#   1. THE ANNOTATE PRESET SURVIVING A BEGINNER DRAW. A wrapper hands the
#      graphs form emlGraphsPresetAnnotate = 1. The beginner Draw commit sets
#      annotate = 0 -- correctly: author ruling of 13 Aug, beginner mode draws
#      only what its own dialog offers. The preset is consumed ONCE before the
#      outer repeat and was never written to the advanced stash, so a user who
#      asked a wrapper to annotate, drew in beginner mode, pressed Redraw and
#      switched to Advanced found the box unticked with nothing to say it had
#      ever been set. The fix is an elsif arm on six restore branches.
#
#   2. THE ANNOTATION BRIDGE DECLARING. @emlReportBridgeStats opens with
#      @emlCSVInit, which zeroes emlResult_declared -- so it DESTROYS whatever
#      declaration the calling wrapper's orchestrator made and must re-declare
#      or the export writes the legacy single file.
#
# WHAT COULD NOT CATCH THEM:
#
#   * harness/gui_e2e draws in BEGINNER mode. annotate is forced to 0 there, so
#     the bridge never runs and the restore branch is never entered. Both fixes
#     are outside its journey BY CONSTRUCTION.
#   * v46 and v49 are static. Neither the tickbox state nor which procedure
#     made a declaration is a property of the source.
#   * A file-set check cannot separate them either, and this is the subtle
#     part: an annotated draw and an unannotated one BOTH leave tidy and glance
#     on disk. In the annotated case the bridge wrote them, having wiped and
#     re-declared; in the unannotated case the driver's own orchestrator wrote
#     them, untouched. Same filenames, same shapes, different author.
#
# WHAT DOES SEPARATE THEM is the Info report. "Two-Group Comparison" is emitted
# by @emlReportHeader, and on this journey it appears ONCE if the preset was
# lost (only the driver's orchestrator reported) and TWICE if it survived (the
# bridge reported on top). Measured 14 Aug 2026 by driving the harness with the
# violin restore arm disabled and then restored: 1 section / 1833 bytes broken,
# 2 sections / 3627 bytes fixed. One integer separates the fix from its absence.
#
# THE ORDER OF THE DRIVE IS ITSELF LOAD-BEARING, and the first version of this
# harness got it wrong in a way that is worth recording. It toggled straight to
# Advanced without drawing first. That proves NOTHING: emlGraphsPresetAnnotate
# is read before the outer repeat and sets annotate = 1 directly, so on the
# first pass the box is ticked whether the restore arm exists or not. The break
# test PASSED. A drive that cannot fail is not evidence, and a harness is not
# trustworthy because it is green -- only because it has been shown to go red.
#
#     bash harness/gui_adv/run.sh
#     Rscript validate/v51_advanced_mode.R
#
# Input: harness/gui_adv/out/{BRIDGE.tsv,DIALOGS.tsv,ARTEFACTS.tsv}.
#        $EML_GUIADV_DIR overrides, for break tests.
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

ga <- Sys.getenv("EML_GUIADV_DIR", unset = "")
if (!nzchar(ga)) ga <- repo_path(file.path("harness", "gui_adv", "out"))

check_true("v51", "the advanced-mode artefact exists (bash harness/gui_adv/run.sh)",
           dir.exists(ga))
if (!dir.exists(ga)) {
    if (!exists("EML_SUITE")) { eml_report("v51 advanced mode"); eml_exit() }
}

.kv <- function(path) {
    if (!file.exists(path)) return(list())
    x <- read.delim(path, header = FALSE, sep = "\t", quote = "",
                    stringsAsFactors = FALSE, fill = TRUE)
    setNames(as.list(trimws(as.character(x[[2]]))), trimws(as.character(x[[1]])))
}
b <- .kv(file.path(ga, "BRIDGE.tsv"))
check_true("v51", "the bridge evidence was recorded", length(b) > 0)

# ---------------------------------------------------------------------------
# 1. THE RUN REALLY WENT INTO ADVANCED MODE
# ---------------------------------------------------------------------------
# Checked before anything is concluded from it. A run that silently stayed in
# beginner mode would produce a perfectly clean chain and prove nothing, which
# is the failure this whole file is about.
d <- file.path(ga, "DIALOGS.tsv")
if (check_true("v51", "the dialog chain was recorded",
               file.exists(d) && file.info(d)$size > 0)) {
    tsv <- read.delim(d, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE)
    titles <- trimws(as.character(tsv[[2]]))
    labels <- trimws(as.character(tsv[[3]]))

    check("v51", "the toggle to Advanced was pressed exactly once", 1L,
          sum(labels == "Advanced"), tol = 0)

    # THREE VISITS TO THE MAPPING PAGE, and the count is the journey: draw in
    # beginner, come back, toggle, draw in advanced. Two would mean the
    # beginner draw never happened and the preset was never zeroed -- the
    # no-op experiment the first version of this harness ran.
    nmap <- sum(grepl("Column Mapping", titles))
    check("v51", "the mapping page was visited three times (beginner, toggle, advanced)",
          3L, nmap, tol = 0)

    # The beginner draw comes FIRST. If the toggle were pressed on visit 1 the
    # preset would still be live and the test would be vacuous.
    mapLabels <- labels[grepl("Column Mapping", titles)]
    check_true("v51",
               sprintf("the beginner draw precedes the toggle (%s)",
                       paste(mapLabels, collapse = " -> ")),
               length(mapLabels) >= 2 && mapLabels[1] == "Draw" &&
               mapLabels[2] == "Advanced")

    check_true("v51", "the run reached teardown", any(labels == "Done"))
    check_true("v51", "the workflow was not asked for an object it was handed",
               !any(grepl("No .* selected", titles)))
}

# ---------------------------------------------------------------------------
# 2. THE PRESET SURVIVED, AND THE BRIDGE DECLARED
# ---------------------------------------------------------------------------
# One number carries both, for the reason set out in the header: the second
# report section can only exist if annotate was 1 at the draw, and annotate can
# only be 1 after a beginner draw if the restore arm put it back.
sections <- suppressWarnings(as.integer(b[["report_sections"]]))
check("v51",
      "the Info report carries TWO analysis sections, not one (the bridge ran)",
      2L, if (length(sections) && !is.na(sections)) sections else -1L, tol = 0)

# THE SIZE IS A SECOND WITNESS, deliberately independent of the string match.
# A change that renamed the report header would break the count above while
# leaving the behaviour correct; this one would not follow it, and the pair
# disagreeing is itself informative.
rbytes <- suppressWarnings(as.integer(b[["report_bytes"]]))
check_true("v51",
           sprintf("the report is the annotated size, not the bare one (%s bytes)",
                   b[["report_bytes"]]),
           length(rbytes) && !is.na(rbytes) && rbytes > 2500)

# ---------------------------------------------------------------------------
# 3. THE EXPORT TOOK THE DECLARED ARM
# ---------------------------------------------------------------------------
# Necessary but NOT sufficient on its own -- see the header. It is checked
# because the bridge re-declaring is only useful if the export then wrote the
# broom shape, and because a regression that made the bridge declare nothing
# would show here as the legacy single file.
a <- file.path(ga, "ARTEFACTS.tsv")
if (check_true("v51", "an artefact list was written", file.exists(a))) {
    art <- read.delim(a, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE)
    nm <- trimws(as.character(art[[1]]))
    check_true("v51", "the tidy frame was written", any(grepl("_tidy\\.csv$", nm)))
    check_true("v51", "the glance frame was written",
               any(grepl("_glance\\.csv$", nm)))
    check_true("v51", "the figure was written", any(grepl("\\.png$", nm)))
    # The advanced dialog was photographed BEFORE Draw. That picture is the
    # human-readable half of the preset evidence -- the tickbox itself.
    check_true("v51", "the advanced dialog was photographed",
               any(grepl("^ADVANCED_DIALOG\\.png$", nm)))
    # ONE STAMP for the whole press, as everywhere else the panel writes.
    st <- regmatches(nm, regexpr("[0-9]{8}_[0-9]{6}", nm))
    check_true("v51",
               sprintf("every saved file shares one timestamp (%s)",
                       paste(unique(st), collapse = " | ")),
               length(unique(st)) == 1)
}

if (!exists("EML_SUITE")) {
    eml_report("v51 advanced mode: the annotate preset survived and the bridge declared")
    eml_exit()
}
