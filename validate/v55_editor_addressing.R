# ============================================================================
# v55_editor_addressing.R -- the editor deletes the column you picked
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE IS ABOUT. plugin/scripts/eml-edit-table.praat is the only
# entry point in the plugin that WRITES to a user's table. Everything else
# reads one and produces a report, a figure or a new object; this one changes
# the thing the user has been typing into. So its failure mode is not a wrong
# number in an artefact somebody can re-run -- it is the loss of data that has
# no other copy.
#
# THE FAILURE, EXACTLY. Praat's Table commands address columns by LABEL:
# `Remove column: name$`, `Get value: row, name$`, `Set string value: row,
# name$, v$`. Labels are not unique and Praat does not make them so --
# measured on 6.6.30, `Rename column (by number)`, `Append column` and
# `Insert column` all accept a name a sibling column already carries, and a
# CSV read off disk can arrive holding duplicates before the editor is ever
# opened. The editor's menus, on the other hand, are POSITIONAL: an optionmenu
# hands back the index of the entry the user clicked. Until 15 August 2026
# every operation here threw that index away and passed the label, so with two
# columns named "colA" the editor honoured the SELECTION in the dialog and
# operated on the FIRST LABEL MATCH. The audit's verifier built id/colA/colB,
# renamed colB to colA, picked the third menu entry -- the B-data column --
# and pressed Delete. The A-data column died. Cell read, cell write, Find and
# Replace All were blind to the second duplicate in exactly the same way, so
# it was not reachable by any operation the editor offers.
#
# WHAT IT LOOKS LIKE WHEN IT HAPPENS, and this is the part that makes it a
# severity 1 rather than an annoyance: nothing. No error, no warning, no undo.
# The table that comes out is well-formed, has the column count you expect,
# the header you expect, and a plausible value in every cell. It is a
# different dataset than the one on the screen a moment ago and there is no
# artefact anywhere that says so. A user who saves it has lost the column and
# will not find out from the file.
#
# THE SIBLING, same mechanism, opposite symptom. Delete Column's guard read
# `if .nCols < 1`. Praat will not hold a Table with no columns at all -- it
# refuses to create one -- so `< 1` guarded a state that cannot exist and let
# the state that can, one column, straight through to Praat's own hard error,
# "cannot remove my only column". Under a script that is fatal: the session
# ends mid-dialog and leaves the read-only TableEditor open with the recovery
# text pointing at a pause window that is already gone.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF IT. This is worth being precise about,
# because the editor was not un-covered by oversight. It was covered by four
# things that are blind to this defect by construction.
#
#   A SOURCE-READING CHECK SEES A CORRECT CALL. `Remove column:
#   column_to_delete$` is a real command with a real argument of the right
#   type, derived from the right dialog field. There is no misspelling, no
#   missing argument, no wrong order -- v35's census and harness/wrappers'
#   parse both pass on it, correctly, and would pass on it forever. The
#   defect is not in the call, it is in the choice of which of the dialog's
#   two output variables to pass.
#
#   A MENU-WALKING CHECK SEES A WORKING MENU. harness/tabwalk opens the
#   editor's dialogs and confirms they come up and respond. Every one of them
#   does. The delete completes, the loop returns, the column count drops by
#   one, and the editor is ready for the next press. Everything a menu walk
#   can observe is exactly right.
#
#   A SCHEMA CHECK SEES A VALID TABLE. Any check on the artefact's SHAPE --
#   column count, header names, row count, cell types -- passes on the wrong
#   table as readily as the right one. The two differ only in which values
#   sit under a header, and the header is identical either way because the
#   two columns had the same name. That is the whole trap: the defect
#   requires duplicate labels to fire, and duplicate labels are what make the
#   evidence look normal.
#
#   A SINGLE-COLUMN-NAME FIXTURE SEES NOTHING AT ALL. Every table in every
#   other harness in this tree has unique column names, because that is what
#   a sane table has. On such a table the old code and the new code are
#   indistinguishable -- `Get column index` resolves the label to the index
#   the user picked, so name-addressing and position-addressing are the same
#   operation. A fixture has to be built deliberately WRONG for the
#   difference to exist, and nothing here had ever built one.
#
# So the only thing that can hold this is a table with two columns of the same
# name and DIFFERENT CONTENTS, operated on through the shipped code, and then
# read back and compared cell by cell. harness/edittable/run.sh builds exactly
# that, eleven ways, and this file reads what came out.
#
# HOW THE EDITOR IS RUN AT ALL, and the one thing that costs. `beginPause:`
# hard-crashes under `praat --run`, and this script is nothing but dialogs --
# twenty pause stanzas, with the editing loop, the find/replace loop and the
# structure menu built out of them. harness/batch/run.sh met the same wall and
# answered it by cutting its two dialog stanzas out by line number and hashing
# what was left against the shipped file; harness/edittable does the same
# thing generalised to all twenty. Section 1 below holds that hash, and holds
# it first, because every behavioural check in this file is a claim about the
# shipped editor only for as long as it is true.
#
# The cost is that the WORDING of a refusal is the part that was cut. So the
# refusal messages are read out of out/EXCISED.txt statically, in section 3,
# while the behaviour around them -- that the refusal fired, that nothing was
# deleted, that the loop came back instead of dying -- is measured in section
# 4. Neither half substitutes for the other: a refusal with perfect prose that
# does not stop the delete is the original defect wearing a hat, and a silent
# refusal that does stop it is the next bug report.
#
#     bash harness/edittable/run.sh
#     Rscript validate/v55_editor_addressing.R
#
# Input: harness/edittable/out/. $EML_EDITTABLE_DIR overrides that folder and
#        $EML_EDITTABLE_FILE the source under test, so a break test drives a
#        damaged copy -- or the pre-fix file straight out of `git show` -- and
#        never goes near the shipped one. The same two names harness/batch and
#        v52 use, for the same reason.
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

src <- Sys.getenv("EML_EDITTABLE_FILE", unset = "")
if (!nzchar(src)) src <- repo_path(file.path("plugin", "scripts",
                                             "eml-edit-table.praat"))
ed <- Sys.getenv("EML_EDITTABLE_DIR", unset = "")
if (!nzchar(ed)) ed <- repo_path(file.path("harness", "edittable", "out"))

tsvPath <- file.path(ed, "EDIT.tsv")
have <- check_true("v55",
                   "the editor drive was run (bash harness/edittable/run.sh)",
                   file.exists(tsvPath))
if (!have) {
    if (!exists("EML_SUITE")) {
        eml_report("v55 editor addressing: NO EVIDENCE -- run bash harness/edittable/run.sh")
        eml_exit()
    }
}

# ---------------------------------------------------------------------------
# Readers
# ---------------------------------------------------------------------------
# A MISSING FACT IS NA AND NA FAILS. The artefact under test is exactly the
# thing that is allowed to be wrong -- under a break test whole cases go
# missing, because the pre-fix editor ABORTS and writes no CSV at all. A
# validator that stops on the missing file has reported nothing, which is
# strictly worse than a red line: there is no count, and "it errored" is a
# sentence somebody has to interpret. Same reasoning as v53's one().
E <- list()
if (have) {
    .x <- read.delim(tsvPath, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE)
    E <- setNames(as.list(trimws(as.character(.x[[2]]))),
                  trimws(as.character(.x[[1]])))
}
es <- function(k) if (is.null(E[[k]])) NA_character_ else E[[k]]

lines_of <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
log_of  <- function(case) lines_of(file.path(ed, paste0(case, ".log")))
csv_of  <- function(case) lines_of(file.path(ed, paste0(case, ".csv")))
srcLines <- lines_of(src)
excised  <- lines_of(file.path(ed, "EXCISED.txt"))

# The DLG trace is the ordered list of dialogs the run actually reached. It is
# the only way to tell "the refusal fired and the user came back" apart from
# "the operation quietly did nothing", and those have identical tables.
trace_of <- function(case) {
    t <- es(paste0(case, "_dlg_trace"))
    if (is.na(t) || !nzchar(t)) character(0) else strsplit(t, ",", fixed = TRUE)[[1]]
}
probe_of <- function(case, kind) {
    g <- grep(paste0("^PROBE\\|", kind, "\\|"), log_of(case), value = TRUE)
    if (length(g) == 0) NA_character_ else g[1]
}
header_of <- function(case) {
    h <- csv_of(case)
    if (length(h) == 0) NA_character_ else h[1]
}
labels_of <- function(case) {
    h <- header_of(case)
    if (is.na(h)) character(0) else strsplit(h, ",", fixed = TRUE)[[1]]
}

CASES <- c("A_rename_dup", "B_delete_dup", "C_cell_dup", "D_repall_dup",
           "E_onecol", "F_add_dup", "G_insert_dup", "H_plain", "I_findnav",
           "J_rename_back", "K_autolabel", "L_stalecell", "M_movedtyped")

# ---------------------------------------------------------------------------
# 1. THE TWIN IS THE EDITOR
# ---------------------------------------------------------------------------
# FIRST, AND UNCONDITIONALLY. Every behavioural check below is a statement
# about plugin/scripts/eml-edit-table.praat only while the thing that ran was
# that file with its dialogs replaced and nothing else touched. The driver
# hashes the shipped file minus its pause stanzas against the twin minus the
# lines the driver injected; if those differ, the rest of this file is
# measuring some other program and its greenness would be a lie about the
# plugin rather than a fact about it.
check_true("v55", "the drive ran to completion", identical(es("completed"), "1"))
check_true("v55",
           sprintf("the drive used the target Praat (%s)", es("praat_version")),
           grepl("^Praat 6\\.6\\.30", es("praat_version")))
check_true("v55",
           "the twin's body is byte-identical to the shipped editor's body",
           identical(es("twin_body_identical"), "1"))
check_true("v55",
           "the twin was cut only where dialogs are (every stanza excised)",
           suppressWarnings(as.numeric(es("stanza_count"))) >= 19)

# THE STANZA MAP IS ASSERTED, NOT JUST COUNTED. The driver names each cut
# region by its dialog title. A refactor that moved the delete confirmation
# into some other dialog, or dropped the refusal, would keep the count and
# change the map -- and the case tapes below, which address dialogs by these
# names, would then be pressing buttons on something else.
stanzaKeys <- unname(unlist(E[grep("^stanza_[0-9]+_key$", names(E))]))
for (k in c("eml_table_editor#3", "table_structure#1", "delete_column#1",
            "rename_column#1", "add_column#2", "insert_column#1",
            "find_replace#1", "cannot_delete_column#1",
            "cannot_use_that_column_name#1", "nothing_was_written#1")) {
    check_true("v55", sprintf("the editor still has the dialog '%s'", k),
               k %in% stanzaKeys)
}

# ---------------------------------------------------------------------------
# 2. THE SOURCE: NAME-ADDRESSING IS CONFINED TO ONE SECTION
# ---------------------------------------------------------------------------
# THE BEHAVIOURAL CHECKS COVER THE PATHS THE HARNESS WALKS. This section
# covers the ones it does not, and the ones nobody has written yet. Praat has
# no positional form of the three commands that matter -- settled by running
# every plausible spelling on 6.6.30: "Remove column (by number)", "(index)",
# "(by index)", "Get value (by number)" and "Set string value (by number)" are
# all "not available for current selection" -- so the editor reaches a column
# by giving it a private name for the length of one operation. That shim lives
# in exactly one place, and the invariant that keeps the defect closed is that
# NOTHING ELSE in the file calls those three commands. A new menu item written
# next year with a bare `Remove column:` in it reopens the severity 1, and
# this is the check that says so before a user finds out.
anchor <- grep("^# PROCEDURES: column addressing$", srcLines)
haveAnchor <- check_true("v55",
                         "the addressing procedures are a named section of the editor",
                         length(anchor) == 1)

nameAddressed <- grep("^\\s*(Get value:|Set string value:|Remove column:)",
                      srcLines)
if (haveAnchor) {
    stray <- nameAddressed[nameAddressed < anchor[1]]
    check_true("v55",
               "no menu path calls Get value:/Set string value:/Remove column: by name",
               length(stray) == 0)
    if (length(stray) > 0) {
        check_true("v55",
                   sprintf("  stray name-addressed calls at line(s) %s",
                           paste(utils::head(stray, 6), collapse = ", ")),
                   FALSE)
    }
} else {
    check_true("v55",
               "no menu path calls Get value:/Set string value:/Remove column: by name",
               FALSE)
}

# THE THREE CALL SITES THAT MATTER, PINNED BY NAME. The delete is the severity
# 1's own line: column_to_delete is the entry the user clicked,
# column_to_delete$ is only its label, and a label is not an address.
check_true("v55", "Delete Column passes the menu INDEX to @columnRemove",
           any(grepl("^\\s*@columnRemove: column_to_delete\\s*$", srcLines)))
check_true("v55", "Delete Column does not pass the menu LABEL anywhere",
           !any(grepl("column_to_delete\\$", srcLines[!grepl("^\\s*#", srcLines)])))
check_true("v55", "the cell read goes through @cellRead",
           any(grepl("^\\s*@cellRead: prevRow, prevCol\\s*$", srcLines)))
check_true("v55", "the cell write goes through @cellWrite",
           any(grepl("^\\s*@cellWrite: row, column, value\\$\\s*$", srcLines)))

# THE GUARD BOUND. `< 1` guards a state Praat cannot hold and lets the state
# it can hold through; `<= 1` is the bound that matches what Praat does.
delGuard <- grep("^\\s*if \\.nCols <= 1\\s*$", srcLines)
check_true("v55", "Delete Column refuses at <= 1 column, not < 1",
           length(delGuard) == 1)
check_true("v55", "the refusal is the editor's own dialog, not Praat's error",
           any(grepl("^\\s*@refuseLastColumn: \\.nCols\\s*$", srcLines)))

# THE PREVENTION LAYER, all three ways a duplicate can be created from the UI.
# Rename is the one the audit named; Append and Insert accept a duplicate name
# just as readily (measured), and a fix that closed only the named one would
# leave two open doors into the same room.
check_true("v55", "the rename is gated on @labelInUse",
           any(grepl("@labelInUse: new_name\\$, column_to_rename", srcLines)))
check_true("v55", "add and insert column are gated on @labelInUse too",
           sum(grepl("@labelInUse: column_name\\$, 0", srcLines)) == 2)
check_true("v55", "the invented name for an unlabeled column is checked for collision",
           any(grepl("^\\s*@labelInUse: \\.try\\$, \\.idx\\s*$", srcLines)))

# ---------------------------------------------------------------------------
# 3. THE REFUSALS SAY SOMETHING
# ---------------------------------------------------------------------------
# READ OUT OF THE EXCISED TEXT, because the wording is the one thing the twin
# cannot run. The standard is the plugin's own: the singleton-group refusal in
# eml-inferential.praat names the offending groups, gives the n, states the
# rule and keeps the user's selections on Back. A refusal that says only
# "cannot do that" is a dead end, and a user with a table they cannot edit and
# no sentence explaining why will go around the editor with a text editor,
# which is the outcome the whole file exists to prevent.
refusalBlock <- function(title) {
    i <- grep(paste0('^\\s*beginPause: "', title, '"'), excised)
    if (length(i) == 0) return(character(0))
    j <- grep("endPause", excised)
    j <- j[j > i[1]]
    if (length(j) == 0) return(character(0))
    excised[i[1]:j[1]]
}
dupRefusal  <- refusalBlock("Cannot Use That Column Name")
lastRefusal <- refusalBlock("Cannot Delete Column")

check_true("v55", "the duplicate-name refusal exists in the shipped dialogs",
           length(dupRefusal) > 0)
check_true("v55", "it names the column that already holds the name",
           any(grepl("already has a column named", dupRefusal)) &&
           any(grepl("\\.shown\\$", dupRefusal)))
check_true("v55", "it gives the offending column's position and the count",
           any(grepl('string\\$ \\(\\.at\\)', dupRefusal)) &&
           any(grepl('string\\$ \\(\\.total\\)', dupRefusal)))
check_true("v55", "it states the rule rather than only the refusal",
           any(grepl("must be unique", dupRefusal)))
check_true("v55", "it says the selections are kept and offers Back",
           any(grepl("selections are kept", dupRefusal)))

check_true("v55", "the last-column refusal exists in the shipped dialogs",
           length(lastRefusal) > 0)
check_true("v55", "it names the column that would have gone",
           any(grepl("\\.only\\$", lastRefusal)))
check_true("v55", "it states Praat's rule about the last column",
           any(grepl("at least one", lastRefusal)))
check_true("v55", "it offers a way forward, not just a refusal",
           any(grepl("delete its rows instead", lastRefusal)))

# S0A AND S0B, on the new dialogs as on every other. The trailing 0 suppresses
# Praat's own Stop button; the exit button reads Quit.
for (nm in list(c("duplicate-name", "dupRefusal"), c("last-column", "lastRefusal"))) {
    blk <- get(nm[2])
    check_true("v55",
               sprintf("APPENDIX_F S0A: the %s refusal suppresses the Stop button", nm[1]),
               any(grepl('endPause: "Quit", "Back", 2, 0', blk)))
}
check_true("v55",
           "APPENDIX_F S0-WRAP: no refusal comment concatenates an unbounded name",
           any(grepl("^procedure ellipsize: \\.s\\$, \\.max$", srcLines)) &&
           any(grepl("@ellipsize: \\.name\\$, 40", srcLines)))

# ---------------------------------------------------------------------------
# 4. THE BEHAVIOUR
# ---------------------------------------------------------------------------
# Every case exited cleanly and handed control back. Before 15 August 2026
# E_onecol did neither: Praat's "cannot remove my only column" is fatal under
# a script, so the exit code was 255 and there was no table to read.
for (cs in CASES) {
    check_true("v55", sprintf("%s: the editor exited cleanly (not an abort)", cs),
               identical(es(paste0(cs, "_exit")), "0"))
    check_true("v55", sprintf("%s: control returned from the editor", cs),
               identical(es(paste0(cs, "_returned")), "1"))
}

# -- B_delete_dup: THE SEVERITY 1 ITSELF -------------------------------------
# The fixture is id / colA(A-data) / colA(B-data), the third menu entry is
# selected, Delete is pressed. What must survive is the A-data column, because
# the entry the user picked was the B one. The audit's verifier got
# "id,colA / S1,B1 / S2,B2 / S3,B3" -- the surviving values are the ones that
# were NOT selected for deletion, which is the whole finding in four lines of
# CSV. This check is written against the full file rather than the header
# because the header is IDENTICAL either way: both columns were called colA.
b <- csv_of("B_delete_dup")
check_true("v55", "B_delete_dup: one column was removed, not two and not none",
           identical(header_of("B_delete_dup"), "id,colA"))
check_true("v55",
           "B_delete_dup: the column the user SELECTED is the one that went",
           identical(b, c("id,colA", "S1,A1", "S2,A2", "S3,A3")))
check_true("v55",
           "B_delete_dup: the surviving data is not the wrong column's (the audit's finding)",
           !identical(b, c("id,colA", "S1,B1", "S2,B2", "S3,B3")))

# -- C_cell_dup: read and write reach the second duplicate -------------------
# The Read press navigates to menu entry 3, row 2. The value the editor then
# prepopulates the field with is what it BELIEVES is in that cell, and before
# the fix it believed "A2" -- entry 2's value. The write that follows lands
# where the read looked, so the two are checked together: a fix that corrected
# only one of them would leave the editor showing one cell and changing
# another, which is worse than either failure alone.
check_true("v55", "C_cell_dup: the cell read reaches menu entry 3, not entry 2",
           identical(probe_of("C_cell_dup", "read"), "PROBE|read|B2"))
check_true("v55", "C_cell_dup: the cell write lands in menu entry 3",
           identical(csv_of("C_cell_dup"),
                     c("id,colA,colA", "S1,A1,B1", "S2,A2,WROTE", "S3,A3,B3")))

# -- L_stalecell / M_movedtyped: the box and the menus can disagree ----------
# A Praat dialog is static. The Value box is filled once, when the page is
# built, from the cell the previous pass ended on, and it cannot follow the
# Column and Row menus while the page is open. So the box and the menus CAN
# name different cells, and before the guard a Set in that state wrote one
# cell's contents into another -- silently, with no undo, leaving a table that
# reads as an ordinary CSV and says the wrong thing. That is the same class of
# harm as B_delete_dup and is checked as hard.
#
# The two cases are the two halves of one rule, and neither is evidence alone.
# L moves the selection and hands back the box UNTOUCHED (the tape assigns
# value$ = currentValue$, which is exactly what an unedited field returns):
# nothing may be written, the refusal must be reached, and the page must come
# back showing the cell the user actually chose. M moves the selection and
# TYPES: that write must go through on the first press, with no refusal in the
# trace, because a guard that charges the ordinary edit an extra press would
# be paid for on every cell a user fills in.
check_true("v55", "L_stalecell: the box was holding the previous cell's value",
           identical(probe_of("L_stalecell", "held"), "PROBE|held|A1"))
check_true("v55",
           "L_stalecell: the stale write was refused, not performed",
           identical(csv_of("L_stalecell"),
                     c("id,colA,colB", "S1,A1,B1", "S2,A2,B2", "S3,A3,B3")))
check_true("v55",
           "L_stalecell: the refusal was shown -- the write did not just quietly do nothing",
           "nothing_was_written#1" %in% trace_of("L_stalecell"))
check_true("v55",
           "L_stalecell: the page came back showing the cell the user chose",
           identical(probe_of("L_stalecell", "after"), "PROBE|after|A3"))
check_true("v55",
           "M_movedtyped: typing into a newly chosen cell still writes on the first press",
           identical(csv_of("M_movedtyped"),
                     c("id,colA,colB", "S1,A1,B1", "S2,A2,B2", "S3,TYPED,B3")))
check_true("v55",
           "M_movedtyped: the guard did not fire on an edit the user meant",
           !("nothing_was_written#1" %in% trace_of("M_movedtyped")))

staleRefusal <- refusalBlock("Nothing was written")
check_true("v55", "the stale-value refusal exists in the shipped dialogs",
           length(staleRefusal) > 0)
check_true("v55", "it says plainly that nothing was written",
           any(grepl("Nothing was written", staleRefusal)))
check_true("v55", "it names the cell the page is now showing",
           any(grepl("colName\\$\\[column\\]", staleRefusal)) &&
           any(grepl("string\\$ \\(row\\)", staleRefusal)))
check_true("v55", "it says what to do next rather than only refusing",
           any(grepl("press Set to write", staleRefusal)))
check_true("v55",
           "APPENDIX_F S0A: the stale-value refusal suppresses the Stop button",
           any(grepl('endPause: "OK", 1, 0', staleRefusal)))

# -- D_repall_dup: Replace All scoped to the second duplicate ----------------
# "B" occurs only in the B-data column, so before the fix this reported zero
# replacements and changed nothing while telling the user it had looked.
check_true("v55", "D_repall_dup: Replace All rewrites the scoped column",
           identical(csv_of("D_repall_dup"),
                     c("id,colA,colA", "S1,A1,Z1", "S2,A2,Z2", "S3,A3,Z3")))

# -- I_findnav: Find reports where it actually looked ------------------------
check_true("v55", "I_findnav: Find lands on the second duplicate, row 2",
           identical(probe_of("I_findnav", "found"), "PROBE|found|col=3|row=2"))
check_true("v55", "I_findnav: Find did not report 'no match' for a value that is there",
           is.na(probe_of("I_findnav", "nomatch")))

# -- A / F / G: the duplicate state cannot be made from the UI ---------------
# Three doors into the same room. Each is checked twice: the table is
# unchanged, AND the refusal dialog was reached -- because a silent no-op
# leaves exactly the same table as a refusal, and one of those is a fix.
for (cs in c("A_rename_dup", "F_add_dup", "G_insert_dup")) {
    check_true("v55", sprintf("%s: no duplicate label was created", cs),
               identical(header_of(cs), "id,colA,colB"))
    check_true("v55", sprintf("%s: the user was told why, not silently ignored", cs),
               "cannot_use_that_column_name#1" %in% trace_of(cs))
}

# -- J_rename_back: the refusal keeps the user's place -----------------------
# A refusal that loses your selection is its own defect. prevCol is the
# optionmenu's default on re-display and structureDialog.pending$ is the text
# field's, so this is the promise "your selections are kept" measured rather
# than read off a comment.
check_true("v55", "J_rename_back: Back re-displays the rename form",
           sum(trace_of("J_rename_back") == "rename_column#1") == 2)
check_true("v55", "J_rename_back: the column and the typed name are kept on Back",
           identical(probe_of("J_rename_back", "kept"), "PROBE|kept|col=3|name=colA"))
check_true("v55", "J_rename_back: a legal name still renames after a refusal",
           identical(header_of("J_rename_back"), "id,colA,colC"))

# -- E_onecol: the guard bound, measured -------------------------------------
check_true("v55", "E_onecol: the one-column table still has its column",
           identical(header_of("E_onecol"), "only"))
check_true("v55", "E_onecol: Praat's hard error was never reached",
           !any(grepl("cannot remove my only column", log_of("E_onecol"))))
check_true("v55", "E_onecol: the editor's own refusal was shown instead",
           "cannot_delete_column#1" %in% trace_of("E_onecol"))
check_true("v55", "E_onecol: Back returns to the editor rather than ending it",
           {
               tr <- trace_of("E_onecol")
               i <- which(tr == "cannot_delete_column#1")
               length(i) > 0 && any(tr[seq_len(length(tr)) > i[1]] == "eml_table_editor#3")
           })

# -- H_plain: the ordinary table is not collateral damage --------------------
# The shim renames a column to a private sentinel and back. If the restore is
# ever skipped, or a return path misses it, the user's column is left carrying
# a name from the plugin's internals -- which is a data-loss bug of its own
# shape. This is where that shows.
check_true("v55", "H_plain: set, rename and delete still do what they did",
           identical(csv_of("H_plain"),
                     c("id,newB", "S1,B1x", "S2,B2", "S3,B3")))

# -- K_autolabel: the editor's own invented name is checked too --------------
# Column 3 is unlabeled and column 1 is already called "Column_3". The
# snapshot whose entire job is to make a table addressable was the third way
# to make it ambiguous.
check_true("v55", "K_autolabel: the invented name does not collide with a real one",
           identical(header_of("K_autolabel"), "Column_3,b,Column_3_2"))

# -- across every case: the sentinel never survives, and no case invented a
# duplicate that its fixture did not already have ---------------------------
leaked <- CASES[vapply(CASES, function(cs) any(grepl("eml_col_lock", labels_of(cs))),
                       logical(1))]
check_true("v55", "the addressing sentinel never reaches a saved table",
           length(leaked) == 0)
if (length(leaked) > 0) {
    check_true("v55", sprintf("  sentinel left in: %s", paste(leaked, collapse = ", ")),
               FALSE)
}

# The duplicate-free cases must come out duplicate-free. The other four are
# built duplicate ON PURPOSE and must stay that way -- an editor that silently
# renamed a user's columns to make its own life easier would be a different
# and worse bug, so this is asserted in both directions.
for (cs in c("A_rename_dup", "F_add_dup", "G_insert_dup", "H_plain",
             "J_rename_back", "K_autolabel", "L_stalecell", "M_movedtyped")) {
    lb <- labels_of(cs)
    check_true("v55", sprintf("%s: the saved table has unique column names", cs),
               length(lb) > 0 && !any(duplicated(lb)))
}
for (cs in c("C_cell_dup", "D_repall_dup", "I_findnav")) {
    lb <- labels_of(cs)
    check_true("v55",
               sprintf("%s: the duplicate the table arrived with was left alone", cs),
               length(lb) == 3 && any(duplicated(lb)))
}

# ---------------------------------------------------------------------------
# COVERAGE
# ---------------------------------------------------------------------------
# Every case the driver ran is asserted on by something above. A case added to
# run.sh and forgotten here would be a drive producing evidence nothing reads
# -- green, and covering less than it did yesterday.
present <- sub("_exit$", "", grep("_exit$", names(E), value = TRUE))
eml_census("v55", "editor drive case", present, CASES)
eml_claim("v55", "edittable_out", CASES)

if (!exists("EML_SUITE")) {
    eml_report("v55 editor addressing: the column you picked is the column that changes")
    eml_exit()
}
