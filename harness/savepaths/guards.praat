# ---------------------------------------------------------------------------
# savepaths/guards.praat -- the save panel's four guards, driven headless
# ---------------------------------------------------------------------------
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY A SECOND DRIVE IN THIS HARNESS RATHER THAN A HARNESS OF ITS OWN. The
# thing under test is @emlSavePanel, which harness/savepaths already presses on
# every path that has a Save button. What the GUI legs cannot do is put HOSTILE
# input in front of it: a base name with a slash in it has to be typed into a
# field, an unwritable target has to exist, and a Matrix has to be selected
# before a wrapper opens. Two of those the legs can now do (see run.sh's
# hostilename and coercion sections) and the rest are procedure-level questions
# with exact answers, which is what this file asks.
#
# THE FOUR, all confirmed live at HEAD before the fixes were written (audit of
# 14 Aug 2026, §3 S4 and §6):
#
#   NEW-G2-1     a "/" in the Base name field reached writeFile: verbatim.
#                Praat: "Cannot create file ... Hint: one of the folders in
#                this file path does not exist", inside @emlSavePanel -- so
#                the receipt never drew, the panel never returned and the
#                caller's Done|Save|Draw|New loop went with it.
#   NEW-G12-5    an unwritable target folder did the same one step later,
#                with "unexpected error 30" for a message; an unwritable
#                PARENT did it one step earlier, on the panel's own bare
#                createFolder:.
#   OVERPRINT    the "Saved" receipt reserved one line per comment: and the
#                toolkit drew several when a path was longer than the dialog.
#   NEW-G12-1    the wrapper's numeric probe raised on the all-undefined
#                "row" column that coercion manufactures, before the dialog
#                opened, on every Matrix and every unlabelled or partially
#                labelled TableOfReal.
#
# WHAT IT WRITES. One TSV of key<TAB>value pairs at $EML_GUARDS_OUT/GUARDS.tsv,
# read by validate/v56_save_guards.R. Every row is a MEASUREMENT, not a
# verdict: the R file decides what is a pass, so a change of expectation is a
# change in one place.
#
# THE UNWRITABLE FOLDER IS SUPPLIED, NOT MADE. $EML_GUARDS_RO names a folder
# that exists and cannot be written; run.sh makes one with a read-only tmpfs
# because this sandbox runs Praat as root and chmod is therefore no probe at
# all -- the audit's own G12 leg recorded chmod 555 as USELESS for this reason.
# If the mount is unavailable the key is written empty and v56 reports the
# evidence MISSING rather than passing over it.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------

# THE MODULES BY NAME, NOT THE BARREL, and it is Praat's rule that decides
# this rather than taste: a relative `include` inside an included file resolves
# against the TOP-LEVEL script's folder. eml-lib-stats.praat's own lines read
# "../stats/..." because it is written from plugin/scripts', so including the
# barrel from here would look for harness/stats/. leg.praat is the file that
# loads the shipped barrel -- it uses runScript:, which re-bases -- and this
# one is deliberately the other kind of drive: procedure-level, headless, and
# fast enough to run on every change. The two are complementary and the
# harness runs both.
#
# EML_INCLUDE_ROOT lets a break test point these lines at a deliberately
# broken copy of the tree; unset, it is the shipped plugin. Praat has no
# variable expansion inside `include`, so the override is done by run.sh
# copying this file next to the tree under test.
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat

out$ = environment$ ("EML_GUARDS_OUT")
if out$ = ""
    out$ = "."
endif
ro$ = environment$ ("EML_GUARDS_RO")
# THE SCRATCH FOLDER GOES UNDER work/, not beside the evidence. guards_out/ is
# one flat directory of things a human reads -- the same doctrine
# harness/savepaths' own out/ follows -- and a folder of probe files sitting in
# it reads as output. work/ is not evidence and is not committed.
createFolder: out$ + "/work"
rw$ = out$ + "/work/rw"
createFolder: rw$

tsv$ = out$ + "/GUARDS.tsv"
writeFile: tsv$, ""

procedure emit: .key$, .value$
    appendFile: tsv$, .key$, tab$, .value$, newline$
endproc

procedure emitN: .key$, .value
    @emit: .key$, string$ (.value)
endproc

@emit: "praat_version", "'praatVersion$'"

# ===========================================================================
# 1. THE BASE NAME -- @eml_saveSafeBaseName
# ===========================================================================
# EVERY CHARACTER THE PANEL CLAIMS TO HANDLE, one call each, so a set that
# quietly shrinks is a named failure and not a silent one. "/" is the one this
# sandbox's filesystem actually refuses -- measured, 33 characters driven
# through writeFile: on 6.6.30 -- and the other eight are refused by Windows,
# by macOS, or by the recorder's own quoting.
hostile$ [1] = "/"
hostile$ [2] = "\"
hostile$ [3] = ":"
hostile$ [4] = "*"
hostile$ [5] = "?"
hostile$ [6] = "<"
hostile$ [7] = ">"
hostile$ [8] = "|"
hostile$ [9] = """"
nHostile = 9
@emitN: "basename_chars_tested", nHostile

survived = 0
for h to nHostile
    @eml_saveSafeBaseName: "pre" + hostile$ [h] + "post"
    if index (eml_saveSafeBaseName.result$, hostile$ [h]) > 0
        survived = survived + 1
    endif
    @emit: "basename_char_" + string$ (h), eml_saveSafeBaseName.result$
endfor
@emitN: "basename_chars_surviving", survived

# THE AUDIT'S OWN STRING, end to end.
@eml_saveSafeBaseName: "pre/post"
@emit: "basename_prepost", eml_saveSafeBaseName.result$
@emitN: "basename_prepost_changed", eml_saveSafeBaseName.changed

# AN ORDINARY NAME MUST COME BACK UNTOUCHED. A sanitiser that also rewrites
# good names would silently rename every study in the plugin, and the proposed
# default -- stem + "_" + stamp -- is the name nine wrappers in ten will use.
@eml_saveSafeBaseName: "save_demo_two-group_20260815_034322"
@emit: "basename_ordinary", eml_saveSafeBaseName.result$
@emitN: "basename_ordinary_changed", eml_saveSafeBaseName.changed

# LEADING DOT: hidden on every POSIX desktop, so the save would work and the
# files would be invisible. TRAILING DOT: silently stripped by Windows, so the
# name on disk would differ from the name the receipt printed.
@eml_saveSafeBaseName: ".hidden"
@emit: "basename_leading_dot", eml_saveSafeBaseName.result$
@eml_saveSafeBaseName: "trailing."
@emit: "basename_trailing_dot", eml_saveSafeBaseName.result$

# AND THE WRITE ITSELF. The static answer is that the string changed; the only
# proof that matters is that a file lands under it. The unsanitised original is
# NOT attempted here -- it aborts the script, which is the whole finding.
@eml_saveSafeBaseName: "pre/post"
path$ = rw$ + "/" + eml_saveSafeBaseName.result$ + "_tidy.csv"
nocheck deleteFile: path$
nocheck writeFile: path$, "term,estimate" + newline$
@emitN: "basename_write_landed", fileReadable (path$)

# ===========================================================================
# 2. THE TARGET FOLDER -- @eml_saveFolderWritable
# ===========================================================================
@emlFileStamp
stamp$ = emlFileStamp.result$

@eml_saveFolderWritable: rw$, stamp$
@emitN: "folder_writable_ok", eml_saveFolderWritable.ok
@emit: "folder_writable_reason", eml_saveFolderWritable.reason$

@eml_saveFolderWritable: rw$ + "/newstudy", stamp$
@emitN: "folder_created_ok", eml_saveFolderWritable.ok
@emitN: "folder_created_exists", folderExists (rw$ + "/newstudy")

@eml_saveFolderWritable: "", stamp$
@emitN: "folder_empty_ok", eml_saveFolderWritable.ok

if ro$ <> ""
    @emit: "ro_folder", ro$
    @emitN: "ro_folder_exists", folderExists (ro$)
    # THE FOLDER EXISTS AND CANNOT BE WRITTEN. This is the shape that produced
    # "unexpected error 30" at HEAD.
    @eml_saveFolderWritable: ro$, stamp$
    @emitN: "folder_readonly_ok", eml_saveFolderWritable.ok
    @emit: "folder_readonly_reason", eml_saveFolderWritable.reason$
    # A NEW FOLDER UNDER AN UNWRITABLE PARENT, which at HEAD died one line
    # earlier still, on the panel's bare createFolder:.
    @eml_saveFolderWritable: ro$ + "/study1", stamp$
    @emitN: "folder_readonly_child_ok", eml_saveFolderWritable.ok
    @emit: "folder_readonly_child_reason", eml_saveFolderWritable.reason$
    # NO LITTER. The probe writes a file to find out and must take it away
    # again; on the read-only folder nothing can have landed at all.
    @emitN: "probe_litter_rw",
    ... fileReadable (rw$ + "/eml_write_test_" + stamp$ + ".tmp")
    @emitN: "probe_litter_ro",
    ... fileReadable (ro$ + "/eml_write_test_" + stamp$ + ".tmp")
else
    @emit: "ro_folder", ""
endif

# THE SCRIPT IS STILL RUNNING, which is the finding. Every line above ran
# against a target that aborted Praat at HEAD.
@emitN: "folder_probe_survived", 1

# ===========================================================================
# 3. THE RECEIPT -- @eml_saveReceiptLines
# ===========================================================================
# THE PATHS ARE PINNED, AND THEY ARE THE AUDIT'S OWN. These three strings are
# read off aud51_out_shots_g1.24_saved_confirm.png -- the receipt that shipped,
# three paths drawn as five lines of overlapping ink. Pinned rather than built
# from this run's folder because $EML_GUARDS_OUT can be short: a receipt check
# on short paths passes on a machine where the fault cannot occur, which is the
# shape of a check that proves nothing. 73 and 74 characters, against a
# measured budget of 62, so the wrap is exercised whatever the sandbox is
# called.
#
# harness/savepaths' own legs write into out/work/<leg>/home, 70-odd characters
# before a file name is added, so every leg of this harness had been drawing an
# overprinted receipt since the panel shipped. Their receipts are photographed
# now (<leg>.receipt.png) and that is the human-readable half of this.
list$ = ""
list$ = list$
... + "/tmp/aud51/out/normsave/demo_normality_normality_20260814_224419_tidy.csv"
... + newline$
list$ = list$
... + "/tmp/aud51/out/normsave/demo_normality_normality_20260814_224419_glance.csv"
... + newline$
list$ = list$
... + "/tmp/aud51/out/normsave/demo_normality_normality_20260814_224419_report.txt"
... + newline$

@eml_saveReceiptLines: list$, ""
@emitN: "receipt_paths", 3
@emitN: "receipt_lines", eml_saveReceiptLines.nLines
longest = 0
for l to eml_saveReceiptLines.nLines
    if length (eml_saveReceiptLines.line$ [l]) > longest
        longest = length (eml_saveReceiptLines.line$ [l])
    endif
    @emit: "receipt_line_" + string$ (l), eml_saveReceiptLines.line$ [l]
endfor
@emitN: "receipt_longest_line", longest

# NOTHING INSERTED, NOTHING ELIDED. The drawn lines of one path must
# concatenate back to that path exactly, or the receipt has stopped being a
# thing the user can paste -- which §6 of the audit named as worth keeping.
joined$ = ""
for l to eml_saveReceiptLines.nLines
    joined$ = joined$ + eml_saveReceiptLines.line$ [l]
endfor
flat$ = replace$ (list$, newline$, "", 0)
@emitN: "receipt_roundtrip", (joined$ = flat$)

# THE ADJUSTED-NAME NOTE, which is the panel's disclosure that it renamed
# something. It must also be wrapped: it is longer than the budget.
@eml_saveReceiptLines: list$,
... "The base name was adjusted to ""pre-post"" -- a file name cannot "
... + "contain / \ : * ? "" < > |."
@emitN: "receipt_note_lines", eml_saveReceiptLines.nLines
longestNote = 0
for l to eml_saveReceiptLines.nLines
    if length (eml_saveReceiptLines.line$ [l]) > longestNote
        longestNote = length (eml_saveReceiptLines.line$ [l])
    endif
endfor
@emitN: "receipt_note_longest_line", longestNote

# ===========================================================================
# 4. THE COERCION PROBE -- @eml_auditLabelColumn, through @emlWrapperInit
# ===========================================================================
# FOUR SHAPES, and the fourth is the regression guard: a fully labelled
# TableOfReal converted correctly before this work and must still.
#
# Each arm is driven through @emlWrapperInit ITSELF, not through the audit
# procedure alone, because the finding is that the wrapper's ENTRY died --
# @emlGuessColumnRoles and @emlCheckDataScheme are what raised, and they run
# from inside the entry.

# -- a Matrix, which never has row labels ------------------------------------
mat = Create simple Matrix: "guardmat", 6, 3, "row*3+col"
selectObject: mat
@emlWrapperInit: 2
@emitN: "coerce_matrix_survived", 1
@emitN: "coerce_matrix_ncols", emlWrapperInit.nCols
@emitN: "coerce_matrix_converted", emlWrapperInit.converted

# -- a TableOfReal with no row labels at all ---------------------------------
tor = Create TableOfReal: "guardtor", 4, 2
selectObject: tor
for r to 4
    for c to 2
        Set value: r, c, r * 10 + c
    endfor
endfor
selectObject: tor
@emlWrapperInit: 2
@emitN: "coerce_tor_survived", 1
@emitN: "coerce_tor_ncols", emlWrapperInit.nCols

# -- a TableOfReal with SOME row labels --------------------------------------
# This one died a second way at HEAD: @eml_strictOneCell copies the cell
# literal into a probe table called "v", and "?" round-trips back to undefined
# when it is set, so the raise came back naming "v" instead of "row".
tor2 = Create TableOfReal: "guardpart", 4, 2
selectObject: tor2
Set row label (index): 1, "alpha"
Set row label (index): 2, "beta"
for r to 4
    for c to 2
        Set value: r, c, r * 10 + c
    endfor
endfor
selectObject: tor2
@emlWrapperInit: 2
@emitN: "coerce_partial_survived", 1
@emitN: "coerce_partial_ncols", emlWrapperInit.nCols

# -- a fully labelled TableOfReal, which must be unchanged -------------------
tor3 = Create TableOfReal: "guardfull", 3, 2
selectObject: tor3
Set row label (index): 1, "alpha"
Set row label (index): 2, "beta"
Set row label (index): 3, "gamma"
for r to 3
    for c to 2
        Set value: r, c, r * 10 + c
    endfor
endfor
selectObject: tor3
@emlWrapperInit: 2
@emitN: "coerce_full_survived", 1
fullTable = emlWrapperInit.tableId
selectObject: fullTable
lab1$ = Get value: 1, "row"
lab3$ = Get value: 3, "row"
@emit: "coerce_full_label1", lab1$
@emit: "coerce_full_label3", lab3$

# -- the classification itself, on each shape --------------------------------
selectObject: mat
matTable = To TableOfReal
matTable2 = To Table: "row"
@eml_auditLabelColumn: matTable2, "row"
@emit: "audit_matrix_verdict", eml_auditLabelColumn.verdict$
@emitN: "audit_matrix_unlabelled", eml_auditLabelColumn.nUnlabelled
# AND IT IS IDEMPOTENT: run twice, the second pass finds nothing left to do
# except count. That is what lets the conversion side add default row labels
# later without this having to be revisited.
@eml_auditLabelColumn: matTable2, "row"
@emit: "audit_matrix_verdict_2", eml_auditLabelColumn.verdict$
# AND THE COLUMN IS NOW CLASSIFIABLE RATHER THAN FATAL. This is the exact
# call that raised at HEAD.
@eml_strictNumericColumn: matTable2, "row"
@emitN: "audit_matrix_strict", eml_strictNumericColumn.strict
@emitN: "audit_matrix_unreadable", eml_strictNumericColumn.unreadable
@emitN: "audit_matrix_probe_survived", 1

selectObject: tor2
partTable = To Table: "row"
@eml_auditLabelColumn: partTable, "row"
@emit: "audit_partial_verdict", eml_auditLabelColumn.verdict$
@emitN: "audit_partial_labelled", eml_auditLabelColumn.nLabelled
@emitN: "audit_partial_unlabelled", eml_auditLabelColumn.nUnlabelled

selectObject: tor3
fullT = To Table: "row"
@eml_auditLabelColumn: fullT, "row"
@emit: "audit_full_verdict", eml_auditLabelColumn.verdict$
@emitN: "audit_full_unlabelled", eml_auditLabelColumn.nUnlabelled

# NO STRANDED PROBE TABLES. The raise at HEAD left "Table eml_numericProbe"
# behind on every crash -- three of them on the canonical Matrix leg -- and a
# stranded temp object is the next thing a user selects.
strays = numberOfSelected ()
select all
nObjects = numberOfSelected ()
strandedProbe = 0
for o to nObjects
    nm$ = selected$ (o)
    if index (nm$, "eml_numericProbe") > 0 or index (nm$, "eml_oneCellProbe") > 0
        strandedProbe = strandedProbe + 1
    endif
endfor
@emitN: "stranded_probe_tables", strandedProbe

@emitN: "completed", 1
