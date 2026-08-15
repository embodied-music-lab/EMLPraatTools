# ============================================================================
# v60_wrapper_paths.R -- the buttons after the result, and the verdict on a file
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Two findings from the 14 August 2026 audit, and they
# are the same finding told about two different surfaces: a path the suite
# never walked, and a sentence that spoke for more than had been checked.
#
#   NEW-G3-1, sev 2. Compare Paired Observations offers Done | Save | Draw |
#   New after a result. Press Draw, then press New, and the entry form comes
#   back offering Subject, Condition and Value -- the ROLE names of the
#   wide-to-long reshape the spaghetti plot is drawn from, on a reshape that
#   has already been removed. Run then dies with "Column not found:
#   Condition", Back returns to the same form, and only quitting Praat
#   recovers. The mechanism is one shared array: the entry form's option lists
#   are built from emlTableColumnNames.name$[], @emlGraphsWorkflow re-reads
#   that array for whatever object it is handed, and the object it is handed
#   here is the reshape. The wrapper filled the array once, before the loop,
#   and then trusted it.
#
#   NEW-G10-4, sev 3. Check & repair data, file mode, on a CSV whose rows are
#   not all the same width: "No import problems found". Praat's own reader
#   then refuses the identical file with "Row 3 incomplete" and produces no
#   Table at all. The check was not wrong -- it checked doubled-quote escapes
#   and the header delimiter and found neither -- but the sentence it printed
#   was about the FILE, and row-length consistency had never been looked at.
#
# WHAT THE FAILURE LOOKS LIKE FROM THE USER'S CHAIR. In the first, an analysis
# that was numerically perfect, exported correctly, and drew a correct figure,
# followed by a "New" that cannot be recovered from without losing the session.
# In the second, a green light from the one tool whose entire job is to give a
# red one, followed by a refusal from Praat that the user now has no way to
# interpret.
#
# WHAT COULD NOT HAVE CAUGHT EITHER, AND WHY. This is the part worth keeping.
#
#   * Nothing that reads NUMBERS. Every statistic on the paired path matched
#     scipy to the ulp, before the Draw and after it. The defect is in what the
#     form OFFERS, which is not a number and is not in any export.
#
#   * Nothing that reads FILES. Both analyses exported correctly; the figure
#     was written; the file check wrote no file at all. v46 proves @emlSavePanel
#     is called from every wrapper, v48 proves one press writes one stamp, v16
#     and v17 prove the CSV shapes. All true, all green, none of them looking at
#     a dialog.
#
#   * harness/wrappers. It asks whether a wrapper PARSES. Both of these parse.
#
#   * harness/savepaths. It drives nine wrappers through a real GUI and presses
#     Save. It stops there. The post-analysis row is Done | Save | Draw | New
#     and no harness in the tree had ever pressed New -- still less pressed New
#     after a Draw, which is the only order in which the array is wrong.
#
#   * harness/gui_e2e. It drives the graphs form, from the graphs form. It
#     never arrives through a wrapper, so the wrapper it would have corrupted
#     is not in the picture.
#
#   * Any static check on eml-check-data.praat. The file-mode verdict was a
#     true statement about the two checks behind it. There is no reading of
#     that source that shows the gap; the gap is between the source and PRAAT'S
#     READER, and the only way to see it is to ask the reader.
#
#   * The plugin's own test corpus. Every fixture in this repository is a
#     well-formed CSV, because they are written by scripts that write CSV. A
#     ragged file had to be built on purpose to exist at all.
#
# So the evidence this file reads is a DRIVE, harness/newpath/run.sh, and the
# ground truth it compares against is Praat's reader itself:
#
#     bash harness/newpath/run.sh
#     Rscript validate/v60_wrapper_paths.R
#
# THE RULE THE PLUGIN NOW IMPLEMENTS WAS MEASURED, NOT ASSUMED. Praat 6.6.30's
# `Read Table from comma-separated file` takes the header's field count as the
# column count and then pulls exactly that many fields per row out of one
# continuous stream in which a newline ends a field. Too few fields on a row
# stops the read ("Row N incomplete", "Last row incomplete") and produces no
# Table; too many leaves the surplus in the stream so the NEXT row runs out
# early and the read is refused with the following row's number; on the FINAL
# row there is no next row, so the surplus is discarded silently and the read
# succeeds with data missing. A header with nothing under it is refused with
# "No rows". Two of those three arms are undocumented, which is exactly why
# they are re-established by the harness on every run rather than pinned here
# as a claim about Praat.
#
# WHAT IS DELIBERATELY NOT CHECKED, AND MUST NOT BE "FIXED". The paired
# wrapper sets emlGraphsPresetGroupCol$ to the literal "Group" (map candidate
# D15). That reads like a hardcoded column name and it is not: it targets the
# wrapper's OWN reshape, which always has a column of exactly that name, and
# the audit's verifier refuted the finding against it. It is pinned below so
# that a later reader tidying up "hardcoded strings" has to argue with a
# failing check rather than with a comment.
#
# Input: harness/newpath/out. $EML_NEWPATH_DIR overrides it, and
#        $EML_PAIRED_FILE / $EML_CHECKDATA_FILE override the two sources under
#        test, for break tests.
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

pairedSrc <- Sys.getenv("EML_PAIRED_FILE", unset = "")
if (!nzchar(pairedSrc)) pairedSrc <- repo_path(file.path("plugin", "scripts",
                                                         "eml-compare-paired.praat"))
checkSrc <- Sys.getenv("EML_CHECKDATA_FILE", unset = "")
if (!nzchar(checkSrc)) checkSrc <- repo_path(file.path("plugin", "scripts",
                                                       "eml-check-data.praat"))

check_true("v60", "the paired wrapper is present", file.exists(pairedSrc))
check_true("v60", "the check & repair wrapper is present", file.exists(checkSrc))

# A MISSING SOURCE IS REPORTED, NOT CRASHED ON. Everything below reads these
# two files, so an absent one would abort R before the report printed -- and a
# validator that dies without a report is indistinguishable, to anything
# reading its output, from a validator that was never run. Found by the break
# test that deletes the file: it took the whole run down instead of turning one
# line red.
if (!file.exists(pairedSrc) || !file.exists(checkSrc)) {
    if (!exists("EML_SUITE")) { eml_report("v60 wrapper paths"); eml_exit() }
}

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS FIRST
# ---------------------------------------------------------------------------
# Both files write long calls and long strings across "..." continuation lines.
# A line-at-a-time regex matches the head of a statement and never sees the
# part that matters, which is the shape of a check that passes while proving
# nothing. Comments are kept in a separate vector rather than thrown away: a
# check that a phrase is ABSENT from the code must not be satisfied by the
# phrase merely having moved into a comment about it.
.read_code <- function(path) {
    raw <- readLines(path, warn = FALSE)
    joined <- character(0)
    for (ln in raw) {
        if (grepl("^\\s*\\.\\.\\.", ln) && length(joined)) {
            joined[length(joined)] <- paste0(joined[length(joined)], " ",
                                             sub("^\\s*\\.\\.\\.\\s*", "", ln))
        } else {
            joined <- c(joined, ln)
        }
    }
    norm <- gsub("\\s+", " ", trimws(joined))
    code <- norm[!grepl("^(#|;)", norm)]
    # PROSE IS WHAT THE USER READS, and it is not what the source says. A
    # sentence in this plugin is written as adjacent string literals joined by
    # `" + "` so it can be wrapped, and a phrase check against the source
    # therefore fails wherever the author happened to break the line -- which
    # is a check that reports on the formatting rather than on the words.
    # Undoing the joins reconstructs the printed sentence. Only the literal
    # `" + "` is collapsed, so `tableName$ + "_long"` is untouched.
    list(all = norm, code = code, prose = gsub('" \\+ "', "", code))
}

paired <- .read_code(pairedSrc)
checkd <- .read_code(checkSrc)

# ===========================================================================
# 1. THE PAIRED FORM IS REBOUND TO THE USER'S TABLE, INSIDE THE LOOP
# ===========================================================================
# POSITION IS THE WHOLE PROPERTY. @emlWrapperInit already calls
# @emlTableColumnNames once, before the loop, and that call is what the broken
# version relied on -- so a check that merely asks whether the wrapper ever
# reads its table's column names passes on the defect. What has to be true is
# that the read happens BETWEEN the top of the entry loop and the beginPause
# that builds the option lists, on every pass.
iRepeat  <- grep("^repeat$", paired$code)
iForm    <- grep('^beginPause: "Compare Paired Observations"', paired$code)
iRebind  <- grep("^@emlTableColumnNames: tableId$", paired$code)
iNCols   <- grep("^nCols = emlTableColumnNames\\.nCols$", paired$code)

landmarksOk <- check_true("v60",
           "the paired entry form and its enclosing repeat are both found",
           length(iRepeat) >= 1 && length(iForm) == 1)

# THE LANDMARKS ARE THE COORDINATE SYSTEM for every positional check below, so
# losing them is not one red line among many -- it means the rest of this
# section is measuring against nothing. Reported once, and the positional
# checks are skipped rather than evaluated against an NA index, which is how
# the first draft of this file turned a renamed dialog into an R traceback.
inLoopHead <- function(i) landmarksOk && any(i > iRepeat[1] & i < iForm[1])

check_true("v60",
           "the paired form re-reads the user's table's column names on every pass",
           length(iRebind) >= 1 && inLoopHead(iRebind))
check_true("v60",
           "and refreshes nCols from the same read, so no stale name survives past the end",
           length(iNCols) >= 1 && inLoopHead(iNCols))

# THE OPTION LISTS ARE STILL BUILT FROM THAT ARRAY. If a future edit stopped
# using emlTableColumnNames.name$[] in the form, the rebind above would be
# checking something the form no longer reads -- a check passing over a
# property that has ceased to exist.
formSpan <- if (landmarksOk) {
    paired$code[iForm[1]:min(length(paired$code), iForm[1] + 40)]
} else character(0)
check_true("v60",
           "the form's column menus are built from the array that rebind fills",
           sum(grepl("emlTableColumnNames\\.name\\$ \\[iCol\\]", formSpan)) >= 4)

# ---------------------------------------------------------------------------
# 2. THE RESHAPE IS NAMED AFTER THE USER'S TABLE
# ---------------------------------------------------------------------------
# The graph layer composes a figure's automatic title and its save stem from
# the name of the object it draws, and here that object is the reshape. Named
# for its own internals it produced "... (pairedLong)" over the user's data and
# saved it as pairedLong_Spaghetti_Plot_<stamp>.
creates <- grep("Create Table with column names:", paired$code, value = TRUE)
check_true("v60", "the paired wrapper creates its reshape table",
           length(creates) >= 1)
check_true("v60",
           "the reshape is named from the user's table, not from a literal",
           length(creates) >= 1 &&
           all(grepl("Create Table with column names: [a-zA-Z]", creates)) &&
           !any(grepl('Create Table with column names: "', creates)))
check_true("v60",
           "and the name it is built from is the user's table name",
           any(grepl('^longName\\$ = tableName\\$ \\+ "', paired$code)))
check_true("v60",
           'the internal name "pairedLong" is gone from the code',
           !any(grepl("pairedLong", paired$code)))

# ---------------------------------------------------------------------------
# 3. THE REFUTED FINDING, PINNED
# ---------------------------------------------------------------------------
# Map candidate D15. The literal is correct: it names a column of the reshape
# built four lines above it, which always has one. Removing it would break the
# grouped spaghetti plot, silently, for the users who set a group column.
check_true("v60",
           'the "Group" preset targeting the wrapper\'s own reshape is left alone (D15 refuted)',
           any(grepl('^emlGraphsPresetGroupCol\\$ = "Group"$', paired$code)) &&
           any(grepl('"Subject", "Condition", "Value", "Group"', paired$code)))

# ===========================================================================
# 4. FILE MODE SCANS ROW LENGTHS, AND SAYS SO
# ===========================================================================
check_true("v60", "file mode scans row lengths",
           any(grepl("^@emlCheckFileRowLengths: path\\$$", checkd$code)))
check_true("v60", "the row-length scan is defined, not merely called",
           any(grepl("^procedure emlCheckFileRowLengths: ", checkd$code)))
check_true("v60",
           "the scan reads the file as TEXT, so a file the Table reader refuses can still be scanned",
           any(grepl("Read Strings from raw text file:", checkd$code)) &&
           !any(grepl("Read Table from comma-separated file", checkd$code)))
check_true("v60",
           "a comma inside a quoted field is not counted as a separator",
           any(grepl("^procedure emlCsvFieldCount: ", checkd$code)) &&
           any(grepl("replace_regex\\$ \\(\\.line\\$", checkd$code)))
check_true("v60",
           "a quoted field spanning a newline is joined before its fields are counted",
           any(grepl("^procedure emlCsvQuoteParity: ", checkd$code)))

# THE VERDICT MAY NOT OVERCLAIM. The old sentence is the finding; it must not
# survive anywhere the user can read it, and "anywhere" includes a comment,
# because a comment is not what the user reads but a check that ignores
# comments cannot tell a restored line from a documented one. The old wording
# is therefore banned from the CODE and required to be explained in the FILE.
check_true("v60",
           'the unqualified "No import problems found" verdict is gone from the code',
           !any(grepl("No import problems found", checkd$prose)))
check_true("v60",
           "the clean verdict names the checks it is the verdict of",
           any(grepl("Nothing found by the three checks", checkd$prose)))
check_true("v60",
           "and reports the row count and field count it actually established",
           any(grepl("emlCheckFileRowLengths\\.nDataRows", checkd$code)) &&
           any(grepl("emlCheckFileRowLengths\\.headerFields", checkd$code)))
check_true("v60",
           "and disclaims the thing it did NOT check -- the cell contents",
           any(grepl("it is not a verdict on the", checkd$prose)) &&
           any(grepl("CONTENTS", checkd$prose)))

# ---------------------------------------------------------------------------
# 5. NO RAW PRE-DIALOG REFUSAL LEFT IN THIS WRAPPER (NEW-G12-4)
# ---------------------------------------------------------------------------
# `exitScript: "some message"` is presented by Praat as its own error window
# with "Script exited. Script ... not completed. Command ... not executed."
# underneath -- interpreter stack in place of a refusal the plugin has a
# dialog for. `exitScript: ""` is not that: it is the silent, ordinary way a
# Praat script stops, and it is how Quit is honoured everywhere in this tree.
rawExits <- grep('^exitScript: "[^"]', checkd$code, value = TRUE)
check_true("v60",
           sprintf("no raw exitScript refusal remains in check & repair (%d found)",
                   length(rawExits)),
           length(rawExits) == 0)
if (length(rawExits)) cat(sprintf("      raw exit: %s\n", rawExits))
check_true("v60",
           "the Table-mode-with-no-Table refusal goes through @emlErrorDialog",
           any(grepl("^@emlErrorDialog: ", checkd$code)) &&
           any(grepl("emlErrorDialog\\.back", checkd$code)))

# ===========================================================================
# 6. THE LIVE DRIVE
# ===========================================================================
nd <- Sys.getenv("EML_NEWPATH_DIR", unset = "")
if (!nzchar(nd)) nd <- repo_path(file.path("harness", "newpath", "out"))

dialogsF <- file.path(nd, "DIALOGS.tsv")
readerF  <- file.path(nd, "READER.tsv")
filechkF <- file.path(nd, "FILECHECK.tsv")

drove <- check_true("v60",
                    "the drive was run (bash harness/newpath/run.sh)",
                    file.exists(dialogsF) && file.exists(readerF) &&
                    file.exists(filechkF))

if (drove) {
    dl <- read.delim(dialogsF, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE,
                     col.names = c("step", "dialog", "button", "rev"))

    # ---- 6a. the chain -----------------------------------------------------
    # READ AS AN ORDER, NOT AS A SET. Every dialog in this chain appears in
    # the broken run too; what distinguishes them is what comes AFTER the
    # New. So the checks are positional.
    iDraw <- which(dl$button == "Draw" & dl$dialog == "Analysis complete")
    iNew  <- which(dl$button == "New")
    check_true("v60", "the drive pressed Draw, and then pressed New after it",
               length(iDraw) == 1 && length(iNew) == 1 && iNew[1] > iDraw[1])

    if (length(iNew) == 1) {
        after <- dl[dl$step > dl$step[iNew[1]], , drop = FALSE]
        check_true("v60",
                   "New reopened the wrapper's own entry form",
                   nrow(after) >= 1 &&
                   identical(after$dialog[1], "Compare Paired Observations"))
        check_true("v60",
                   "and Run on that form reached an analysis instead of dead-ending",
                   nrow(after) >= 2 &&
                   grepl("^Analysis [Cc]omplete$", after$dialog[2]))
        check_true("v60",
                   "no refusal dialog anywhere after the Draw",
                   !any(after$dialog == "Cannot run this analysis"))
    }

    # ---- 6b. what the reopened form offered --------------------------------
    # OCR of the photograph taken before the form was pressed. It is the only
    # record of what the option menus SHOWED; nothing the run writes to disk
    # carries it. The assertion is two-sided on purpose -- the user's columns
    # present AND the reshape's role names absent -- because a form that
    # offered both would satisfy either half alone.
    formF <- file.path(nd, "NEWFORM.txt")
    if (check_true("v60", "the reopened form was photographed and read",
                   file.exists(formF))) {
        ftxt <- paste(readLines(formF, warn = FALSE), collapse = "\n")
        check_true("v60",
                   "the reopened form offers the user's own columns",
                   grepl("jitter_pre", ftxt, fixed = TRUE) &&
                   grepl("jitter_post", ftxt, fixed = TRUE))
        check_true("v60",
                   "and offers none of the reshape's role names",
                   !grepl("Condition", ftxt, fixed = TRUE) &&
                   !grepl("\\bValue\\b", ftxt))
    }

    # ---- 6c. the second analysis actually ran ------------------------------
    infoF <- file.path(nd, "PAIRED_INFO.txt")
    if (check_true("v60", "the Info window was captured at the end of the leg",
                   file.exists(infoF))) {
        itxt <- readLines(infoF, warn = FALSE)
        nReports <- sum(grepl("EML Stats : Paired Comparison", itxt))
        check_true("v60",
                   sprintf("two paired analyses ran in one session (%d found)", nReports),
                   nReports == 2)
        # The report prints column names de-underscored, so this is what the
        # second analysis naming the user's own columns looks like in it.
        check_true("v60",
                   "both analyses were run on the user's table",
                   sum(grepl("^ +Table +np paired$", itxt)) == 2)
    }

    objF <- file.path(nd, "PAIRED_OBJECTS.txt")
    if (check_true("v60", "the object list was captured at the end of the leg",
                   file.exists(objF))) {
        otxt <- readLines(objF, warn = FALSE)
        otxt <- otxt[nzchar(otxt)]
        check_true("v60",
                   sprintf("the reshape was removed and only the user's table remains (%s)",
                           paste(otxt, collapse = "; ")),
                   length(otxt) == 1 && identical(otxt[1], "Table np_paired"))
    }

    # ---- 6d. the deliverables carry a name the user can place --------------
    artF <- file.path(nd, "ARTEFACTS.tsv")
    if (check_true("v60", "the Save panel wrote something", file.exists(artF))) {
        art <- read.delim(artF, header = FALSE, sep = "\t", quote = "",
                          stringsAsFactors = FALSE, fill = TRUE,
                          col.names = c("file", "bytes"))
        check_true("v60",
                   sprintf("the figure save stem names the user's table (%s)",
                           if (nrow(art)) art$file[1] else "-"),
                   nrow(art) >= 1 &&
                   all(grepl("^np_paired", art$file)) &&
                   !any(grepl("pairedLong", art$file)))
    }
    figF <- file.path(nd, "FIGURE_TITLE.txt")
    if (check_true("v60", "the figure was saved and read back", file.exists(figF))) {
        gtxt <- paste(readLines(figF, warn = FALSE), collapse = "\n")
        check_true("v60",
                   "the figure's automatic title does not name the wrapper's internals",
                   !grepl("pairedLong", gtxt) && !grepl("paired[Ll]ong", gtxt))
    }

    # ---- 6e. the file check against Praat's own reader ---------------------
    rd <- read.delim(readerF, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE,
                     col.names = c("case", "verdict", "message"))
    fc <- read.delim(filechkF, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE,
                     col.names = c("case", "verdict"))

    check_true("v60", "the reader probe and the drive covered the same cases",
               setequal(rd$case, fc$case) && nrow(rd) == nrow(fc))

    m <- merge(rd, fc, by = "case", suffixes = c(".reader", ".plugin"))
    m <- m[order(m$case), ]

    # THE CENTRAL CLAIM. Everything Praat refuses, the checker names. Stated
    # over the whole population rather than case by case so that a case
    # quietly dropped from the fixtures cannot pass by absence -- the census
    # below is the other half of that.
    refused <- m[m$verdict.reader == "REFUSED", ]
    check_true("v60",
               sprintf("every file Praat's reader refuses is flagged (%d case(s))",
                       nrow(refused)),
               nrow(refused) >= 4 && all(refused$verdict.plugin == "FLAGGED"))
    for (i in seq_len(nrow(refused))) {
        if (refused$verdict.plugin[i] != "FLAGGED") {
            cat(sprintf("      %s: reader %s, checker said %s\n",
                        refused$case[i], refused$message[i],
                        refused$verdict.plugin[i]))
        }
    }

    # AND THE CASE THE READER ACCEPTS ANYWAY. Surplus fields on the final row
    # are discarded without an error, so the reader is no guide here: this is
    # data loss that only the checker can report, and it is the one case where
    # "Praat accepts it" and "the file is fine" come apart.
    check_true("v60",
               "surplus fields on the final row are flagged even though the read succeeds",
               "05_long_last.csv" %in% m$case &&
               m$verdict.reader[m$case == "05_long_last.csv"] == "OK" &&
               m$verdict.plugin[m$case == "05_long_last.csv"] == "FLAGGED")

    # NO FALSE ALARM, which is the half that makes the other half worth
    # having. A checker that flagged everything would satisfy every assertion
    # above. 07 is the discriminating one: quoted commas and a quoted field
    # spanning a newline, both of which a naive comma count reads as ragged.
    clean <- c("01_clean.csv", "07_quoted_ok.csv")
    for (cs in clean) {
        check_true("v60",
                   sprintf("%s reads cleanly and is reported clean", cs),
                   cs %in% m$case &&
                   m$verdict.reader[m$case == cs] == "OK" &&
                   m$verdict.plugin[m$case == cs] == "CLEAN")
    }

    # The clean verdict as the user receives it, not as the source promises it.
    v1 <- file.path(nd, "verdict_01_clean.csv.txt")
    if (check_true("v60", "the clean case's report was captured", file.exists(v1))) {
        vtxt <- paste(readLines(v1, warn = FALSE), collapse = "\n")
        check_true("v60",
                   "the printed clean verdict enumerates the row-length check",
                   grepl("Nothing found by the three checks", vtxt, fixed = TRUE) &&
                   grepl("data row\\(s\\) carries the header's", vtxt))
        check_true("v60",
                   "and the printed verdict does not claim the file is problem-free",
                   !grepl("No import problems found", vtxt, fixed = TRUE))
    }

    # EVERY CASE THE DRIVE RENDERED IS LOOKED AT BY SOMETHING. Adding a ninth
    # fixture that no assertion names would otherwise leave every check above
    # passing, correctly, about a population that had quietly changed.
    eml_census("v60", "CSV case",
               present = rd$case,
               accounted = c(refused$case, "05_long_last.csv", clean))
    eml_claim("v60", "newpath_cases", rd$case)
}

if (!exists("EML_SUITE")) {
    eml_report(paste("v60 wrapper paths: New after Draw rebinds to the user's",
                     "table; the file verdict covers what Praat's reader refuses"))
    eml_exit()
}
