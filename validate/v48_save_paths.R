# ============================================================================
# v48_save_paths.R -- the Save button, pressed on every path that has one
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. @emlSavePanel has TEN call sites: the graphs form's
# Graph Complete dialog, eight stats wrappers, and the wizard. Until 14 August
# 2026 exactly ONE had ever been pressed by a harness -- the graphs one, by
# harness/gui_e2e. The other nine were covered by v46, which is static: it
# reads the source and proves the call site exists, names the panel, and no
# longer names the superseded @emlWrapperExportCSV. Every claim v46 makes is
# true and none of them is enough.
#
# WHAT A STATIC CHECK CANNOT SEE, demonstrated on the first press:
#
#     @emlSavePanel: 0, tableName$ + "_two-group", emlLastCSVFolder$
#
# Nothing seeded emlLastCSVFolder$. Its seed had lived INSIDE
# @emlWrapperExportCSV -- the procedure the panel superseded -- so it was
# deleted along with the call. Praat evaluates a procedure's arguments before
# entering it, so all nine non-graphing paths aborted with "Unknown variable"
# on the FIRST press of Save in a session, and took the user's analysis with
# them. The call site was present and correct throughout. harness/wrappers
# passed too: it asks only whether a wrapper parses, and an unbound variable
# parses.
#
# So this file's population is not a set of call sites -- v46 has those -- and
# not a set of artefacts either. It is the set of JOURNEYS: for each caller,
# did the panel come up, did it write, and did what it wrote arrive as one set
# under one folder and one stem, which is the whole reason the panel exists.
#
# THE COVERAGE CHECK IS THE IMPORTANT ONE. The leg list is compared against
# the call sites read out of the plugin source, so a tenth wrapper that gains
# a Save button fails this file until somebody drives it. That is the property
# whose absence let the Exp CSV button go unpressed for a year.
#
#     bash harness/savepaths/run.sh
#     Rscript validate/v48_save_paths.R
#
# Input: harness/savepaths/out/<leg>/{DIALOGS.tsv,ARTEFACTS.tsv} plus the
#        plugin source. $EML_SAVEPATHS_DIR and $EML_PLUGIN_DIR override, for
#        break tests.
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
sp <- Sys.getenv("EML_SAVEPATHS_DIR", unset = "")
if (!nzchar(sp)) sp <- repo_path(file.path("harness", "savepaths", "out"))

check_true("v48", "the savepaths artefact exists (bash harness/savepaths/run.sh)",
           dir.exists(sp))
if (!dir.exists(sp)) {
    if (!exists("EML_SUITE")) { eml_report("v48 save paths"); eml_exit() }
}

legs <- sort(list.dirs(sp, recursive = FALSE, full.names = FALSE))
check_true("v48", sprintf("the run produced legs (%s)",
                          paste(legs, collapse = ", ")),
           length(legs) > 0)

# ---------------------------------------------------------------------------
# 1. COVERAGE: every non-graphing caller of the panel was driven
# ---------------------------------------------------------------------------
# Read the callers out of the SOURCE, not out of a list kept here. A list kept
# here would agree with itself forever; the source is the thing that changes.
scr <- list.files(file.path(plug, "scripts"), pattern = "\\.praat$",
                  full.names = TRUE)
callers <- character(0)
for (p in scr) {
    x <- readLines(p, warn = FALSE)
    x <- x[!grepl("^\\s*[#;]", x)]
    if (any(grepl("@emlSavePanel:", x, fixed = TRUE)))
        callers <- c(callers, sub("\\.praat$", "", basename(p)))
}
callers <- sort(callers)
check_true("v48", sprintf("the plugin has non-graphing save callers (%d)",
                          length(callers)),
           length(callers) >= 9)

missing <- setdiff(callers, legs)
check_true("v48",
           sprintf("every caller of the panel was driven (undriven: %s)",
                   if (length(missing)) paste(missing, collapse = ", ") else "none"),
           length(missing) == 0)

# THE GRAPHS CALLER IS NOT DRIVEN HERE, and must not be: it is the one with
# offerFigure = 1 and harness/gui_e2e owns it. Named so the division of labour
# is a checked fact rather than a convention.
gf <- file.path(plug, "graphs", "eml-graphs-form.praat")
if (file.exists(gf)) {
    x <- readLines(gf, warn = FALSE)
    check_true("v48", "the graphs form is the tenth caller, covered by gui_e2e",
               any(grepl("@emlSavePanel:", x[!grepl("^\\s*[#;]", x)],
                         fixed = TRUE)))
}

# ---------------------------------------------------------------------------
# 2. EACH LEG REACHED THE PANEL AND CAME BACK
# ---------------------------------------------------------------------------
for (leg in legs) {
    d <- file.path(sp, leg, "DIALOGS.tsv")
    if (!check_true("v48", sprintf("%s: the dialog chain was recorded", leg),
                    file.exists(d) && file.info(d)$size > 0)) next
    tsv <- read.delim(d, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE)
    titles <- trimws(as.character(tsv[[2]]))
    labels <- if (ncol(tsv) >= 3) trimws(as.character(tsv[[3]])) else character(0)

    # NO ERROR ROW. The harness records one when Praat raises its own error
    # window -- which has NO window name, so a run that hits one otherwise
    # reports a short clean chain and no files, and a hard failure reads as a
    # mild one. This is the check that would have caught the unbound
    # emlLastCSVFolder$ without anyone screenshotting anything.
    check_true("v48", sprintf("%s: Praat raised no error (see %s/ERROR.png)",
                              leg, leg),
               !any(grepl("^ERROR", as.character(tsv[[1]]))))

    check_true("v48", sprintf("%s: the Save panel came up", leg),
               any(titles == "Save"))
    check_true("v48", sprintf("%s: the panel reported a completed save", leg),
               any(titles == "Saved"))
    # "Nothing saved" is the panel's other exit and it means every box was
    # unticked. Reaching it here would mean the defaults came up wrong.
    check_true("v48", sprintf("%s: the panel did not come up with nothing ticked",
                              leg),
               !any(titles == "Nothing saved"))
    check_true("v48", sprintf("%s: the run pressed Done rather than stopping",
                              leg),
               any(labels == "Done"))
}

# ---------------------------------------------------------------------------
# 3. ONE FOLDER, ONE STEM -- the panel's whole contract
# ---------------------------------------------------------------------------
# Before the panel, the figure, the CSV and the report each remembered a
# different folder and derived its own name, so one analysis scattered its
# outputs across three places. Checking that the files SHARE A STEM is the
# only way to check that promise; counting them is not.
for (leg in legs) {
    a <- file.path(sp, leg, "ARTEFACTS.tsv")
    if (!check_true("v48", sprintf("%s: an artefact list was written", leg),
                    file.exists(a))) next
    if (file.info(a)$size == 0) {
        check_true("v48", sprintf("%s: the save wrote at least one file", leg),
                   FALSE)
        next
    }
    art <- read.delim(a, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE)
    names <- trimws(as.character(art[[1]]))
    sizes <- suppressWarnings(as.numeric(art[[2]]))
    check_true("v48", sprintf("%s: the save wrote files (%d)", leg, length(names)),
               length(names) > 0)

    # The stem is everything before the first role suffix the panel appends.
    # THE EXTRAS COME OFF FIRST, and the order is the whole of it. An extra
    # frame is named <stem>_<role>_tidy.csv, so a rule that strips _tidy.csv
    # first leaves <stem>_effectsize behind and every leg reads as two stems.
    # That is what the first version of this check did, and it failed six legs
    # while the plugin was writing exactly one stem each.
    stems <- sub("_[a-z]+_tidy\\.csv$", "", names)
    stems <- sub("_(tidy|glance|augment|report|legend)\\.(csv|txt|png)$", "",
                 stems)
    stems <- sub("\\.png$", "", stems)
    check_true("v48",
               sprintf("%s: every file shares one stem (%s)", leg,
                       paste(unique(stems), collapse = " | ")),
               length(unique(stems)) == 1)

    # THE STAMP IS IDENTICAL TO THE SECOND ACROSS THE WHOLE PRESS. Author
    # ruling, 14 August 2026. It is what makes the outputs of one analysis a
    # set: a stamp taken per file would put two different seconds on one
    # analysis whenever a write straddled a tick, and a folder of results
    # would no longer group by run.
    #
    # Checked separately from the stem even though one implies the other,
    # because they can only both be true for one reason -- a single
    # @emlFileStamp call before the dialog -- and a future edit that moved the
    # call into the write loop would break this one first and by name.
    st <- regmatches(names, regexpr("[0-9]{8}_[0-9]{6}", names))
    check("v48", sprintf("%s: every file carries a timestamp", leg),
          length(names), length(st), tol = 0)
    check_true("v48",
               sprintf("%s: and every timestamp is the same second (%s)", leg,
                       paste(unique(st), collapse = " | ")),
               length(unique(st)) == 1)

    # TIDY AND GLANCE ARE THE FLOOR. Every declared analysis writes both; the
    # extras (augment, posthoc, effectsize) differ by analysis and are not
    # pinned here, because pinning them would make this file a second copy of
    # v20/v21's per-analysis knowledge.
    check_true("v48", sprintf("%s: the tidy frame was written", leg),
               any(grepl("_tidy\\.csv$", names)))
    check_true("v48", sprintf("%s: the glance frame was written", leg),
               any(grepl("_glance\\.csv$", names)))

    # THE REPORT, which is the output that existed nowhere before the panel.
    # @emlSaveInfoToFile had been in the tree since before the repo's history,
    # was called by nothing, and was broken (a bare `info$`) -- proof it had
    # never run.
    rep <- names[grepl("_report\\.txt$", names)]
    check("v48", sprintf("%s: exactly one Info report was written", leg),
          1L, length(rep), tol = 0)
    if (length(rep) == 1) {
        check_true("v48", sprintf("%s: the report has content (%d bytes)", leg,
                                  sizes[names == rep][1]),
                   sizes[names == rep][1] > 200)
    }

    # NO FIGURE. These are the offerFigure = 0 callers -- nine of the ten --
    # and nothing has been drawn at the end of an analysis. A PNG here would
    # mean the panel offered a figure that does not exist.
    check_true("v48", sprintf("%s: no figure was written on a non-drawing path",
                              leg),
               !any(grepl("\\.png$", names)))
}

if (!exists("EML_SUITE")) {
    eml_report("v48 save paths: the Save button, pressed on every path that has one")
    eml_exit()
}
