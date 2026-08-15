# ============================================================================
# v56_save_guards.R -- the two guards that keep a Save from ending the session,
#                      the receipt that could not draw what it was handed, and
#                      the probe that assumed instead of classifying
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. The audit of 14 August 2026 put four defects on this
# plugin's save path, three of them severity 2 and every one of them ending
# the user's session at the last step of a completed analysis. They are one
# family: in each, a value the user is entitled to supply reaches a Praat
# command that raises on it, and Praat has no try/catch, so the raise stops
# the script INSIDE @emlSavePanel. The panel therefore never draws its
# receipt, never returns, and the caller's Done | Save | Draw | New loop --
# a `repeat ... until` around that return -- never runs again. The analysis is
# still computed and completely unreachable, and Praat's recovery text points
# the user at a window that has closed.
#
#   NEW-G2-1, sev 2      `pre/post` typed into the Base name field. Praat:
#                        "Cannot create file ... Hint: one of the folders in
#                        this file path does not exist."
#   NEW-G12-5, sev 2     an unwritable target folder. Praat: "Not-so-useful
#                        hint: unexpected error 30." An unwritable PARENT dies
#                        one line earlier still, on the panel's own bare
#                        `createFolder:`, with "Cannot create folder".
#   SAVED-OVERPRINT, 4   `comment:` RESERVES the height of one line and DRAWS
#                        whatever it is handed, so a path longer than the
#                        dialog is wrapped by the toolkit into two or three
#                        drawn lines inside one line's height and prints its
#                        tail over the path below. Five independent sightings
#                        in the audit, one cause.
#   NEW-G12-1, sev 2     the wrapper's numeric probe raised on the
#                        all-undefined "row" column that coercion
#                        manufactures -- before the wrapper's dialog opened --
#                        on every Matrix and on every TableOfReal whose row
#                        labels are missing or partial.
#
# WHAT THE FAILURE LOOKS LIKE FROM THE USER'S CHAIR, which is the only place
# it was ever visible: an analysis finishes, the modal offers Save, the Save
# panel comes up correctly with sensible defaults, the user edits one field,
# presses Save -- and every window belonging to the analysis is gone. No file
# is written. Nothing in the Info window says what happened. The plugin looks
# like it crashed at random, because from outside it did.
#
# WHAT COULD NOT HAVE CAUGHT THIS, AND WHY. This is the part worth keeping,
# because the answer is "almost everything in the tree, and each for a good
# reason".
#
#   v46 is static and reads CALL SITES. It proves @emlSavePanel is called from
#   every path that should call it, and every claim it makes was true
#   throughout. A call site cannot tell you what the callee does with a
#   string.
#
#   harness/wrappers runs each wrapper headless and asks whether it PARSES.
#   `writeFile: folder$ + "/" + stem$ + "_tidy.csv", text$` parses perfectly.
#   So does the probe that raised.
#
#   v48 and harness/savepaths press the Save button on all eleven non-graphing
#   paths, and they are the reason this file could be written at all -- but
#   they press it on the DEFAULTS. The default base name is
#   `<table>_<analysis>_<stamp>`, which contains no hostile character, and the
#   default folder is $HOME, which is writable by construction. Every leg
#   passed, every leg was right to pass, and the defect lives one keystroke
#   past where they stop. A harness that only ever accepts what a dialog
#   proposes is testing the proposal.
#
#   The overprint is worse than untested: it was UNTESTABLE. Its only symptom
#   is ink on a screen. No file records it, no exit code changes, and
#   harness/savepaths' own legs -- which write into
#   out/work/<leg>/home, 70-odd characters before a file name is added -- have
#   been drawing an overprinted receipt on every run since the panel shipped,
#   photographing the Save panel but not the Saved one. The fix for that is
#   half structural: the receipt's lines are now BUILT by
#   @eml_saveReceiptLines and only then drawn, so the number this file checks
#   is a number in a file rather than a thing someone has to look at.
#
#   And the probe: nothing in the tree had ever selected a Matrix and pressed
#   a stats button. setup.praat registers EML items on Matrix and TableOfReal,
#   so eleven menu entries led straight into it.
#
# WHAT THIS FILE ASKS, in four sections. Static first, because the static half
# is what pins the SHAPE of the guard -- which characters, which order, which
# width -- and live second, because only running can prove the guard is wired
# to the panel rather than merely present. The distinction is not academic
# here: the outage of 14 August 2026 on this same panel was a correct
# procedure with an unbound argument, and every static check passed.
#
#     bash harness/savepaths/guards.sh
#     Rscript validate/v56_save_guards.R
#
# Input: harness/savepaths/guards_out/GUARDS.tsv (headless, procedure-level),
#        guards_out/<leg>.dialogs.tsv and <leg>.artefacts.tsv (two GUI legs),
#        and the plugin source. $EML_GUARDS_DIR overrides the evidence and
#        $EML_OUTPUT_FILE / $EML_WRITER_FILE override the source under test,
#        for break tests.
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

src <- Sys.getenv("EML_OUTPUT_FILE", unset = "")
if (!nzchar(src)) src <- repo_path(file.path("plugin", "stats", "eml-output.praat"))
wsrc <- Sys.getenv("EML_WRITER_FILE", unset = "")
if (!nzchar(wsrc)) wsrc <- repo_path(file.path("plugin", "stats",
                                               "eml-result-writer.praat"))
gd <- Sys.getenv("EML_GUARDS_DIR", unset = "")
if (!nzchar(gd)) gd <- repo_path(file.path("harness", "savepaths", "guards_out"))

check_true("v56", "the save panel's module is present", file.exists(src))
if (!file.exists(src)) {
    if (!exists("EML_SUITE")) { eml_report("v56 save guards"); eml_exit() }
}

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND KEEP THE COMMENTS OUT
# ---------------------------------------------------------------------------
# Every guard in this panel is written across two or more lines with "..."
# continuations, and the file's comments quote the very strings being checked
# -- the header names `/ \ : * ? " < > |` in prose twice. A line-at-a-time
# grep over the raw file would find the sanitiser's character set inside a
# comment describing it and pass on a file where the code had been deleted.
# That is not hypothetical: it is the first break test this file was given.
.load <- function(p) {
    raw <- readLines(p, warn = FALSE)
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
    norm[!grepl("^[#;]", norm)]
}
code <- .load(src)

.body <- function(lines, procname) {
    i <- grep(paste0("^procedure ", procname, "\\b"), lines)
    if (!length(i)) return(character(0))
    j <- grep("^endproc\\b", lines)
    j <- j[j > i[1]]
    if (!length(j)) return(character(0))
    lines[seq(i[1], j[1])]
}

# ===========================================================================
# 1. THE BASE NAME -- static
# ===========================================================================
san <- .body(code, "eml_saveSafeBaseName")
check_true("v56", "@eml_saveSafeBaseName exists in the panel's own module",
           length(san) > 0)

# THE NINE CHARACTERS, EACH NAMED SEPARATELY. One assertion per character
# rather than one over the set, because a set check reports "the set is wrong"
# and a per-character check reports which one went missing -- and the failure
# mode being guarded against is a future edit trimming the list to what this
# sandbox's filesystem happens to refuse, which is "/" alone.
hostile <- list(
    list(ch = "/",  why = "POSIX and macOS path separator",     pat = '"/"'),
    list(ch = "\\", why = "Windows path separator",             pat = '"\\\\"'),
    list(ch = ":",  why = "Windows reserved; classic Mac separator", pat = '":"'),
    list(ch = "*",  why = "refused by Windows filesystems",     pat = '"\\*"'),
    list(ch = "?",  why = "refused by Windows filesystems",     pat = '"\\?"'),
    list(ch = "<",  why = "refused by Windows filesystems",     pat = '"<"'),
    list(ch = ">",  why = "refused by Windows filesystems",     pat = '">"'),
    list(ch = "|",  why = "refused by Windows filesystems",     pat = '"\\|"'),
    list(ch = '"',  why = "Windows, and it closes the recorder's own string",
         pat = '""""')
)
for (h in hostile) {
    check_true("v56",
               sprintf("the base name sanitiser replaces %s (%s)", h$ch, h$why),
               any(grepl(paste0("replace\\$ \\( ?\\.result\\$, ", h$pat),
                         san)))
}

# LEADING AND TRAILING DOTS AND SPACES. A name beginning with "." is hidden on
# every POSIX desktop -- the save works and the files are invisible -- and
# Windows silently strips a trailing "." or " ", so the name on disk stops
# matching the name the receipt printed.
check_true("v56", "the sanitiser strips leading dots and spaces",
           any(grepl("while startsWith \\(\\.result\\$, \"\\.\"\\)", san)))
check_true("v56", "the sanitiser strips trailing dots and spaces",
           any(grepl("while endsWith \\(\\.result\\$, \"\\.\"\\)", san)))

# ---------------------------------------------------------------------------
# AND IT IS WIRED, IN THE RIGHT ORDER
# ---------------------------------------------------------------------------
# ORDER, not mere presence, and this is the check that carries the panel's
# design contract. AUTHOR RULING, 14 August 2026: every file saved in one
# press carries exactly the same stamp, and by extension the same base name.
# The panel keeps that by uniquing the STEM once, in the `label STEM_FREE`
# walk, and then writing every file under it. Sanitising AFTER that walk would
# hand the walk one name and the writes another -- the collision check would
# be run against a name that never reaches disk -- so the call has to sit
# before it. A "the call exists" check cannot see that; this one can.
panel <- .body(code, "emlSavePanel")
iSan <- grep("@eml_saveSafeBaseName:", panel)
iWalk <- grep("^label STEM_FREE", panel)
iWrite <- grep("@emlExportResultFiles:|Save as 300-dpi PNG file:|@emlSaveInfoToFile:",
               panel)
check_true("v56", "@emlSavePanel calls the sanitiser", length(iSan) == 1)
check_true("v56",
           "the sanitiser runs BEFORE the stem-uniquing walk (one stamp, one name)",
           length(iSan) == 1 && length(iWalk) == 1 && iSan[1] < iWalk[1])
check_true("v56", "and before anything is written",
           length(iSan) == 1 && length(iWrite) > 0 && iSan[1] < min(iWrite))

# ONE @emlFileStamp BEFORE THE DIALOG, still. The guards added two new reasons
# to want a timestamp -- the writability probe's file name is stamped, and the
# empty-name fallback re-stamps -- so this is re-pinned here rather than left
# to v48: a stamp taken per file would put two seconds on one analysis.
check_true("v56",
           "the panel stamps once before its dialog, so the probe borrows that stamp",
           any(grepl("@eml_saveFolderWritable: \\.folder\\$, emlFileStamp\\.result\\$",
                     panel)))

# ===========================================================================
# 2. THE TARGET FOLDER -- static
# ===========================================================================
fw <- .body(code, "eml_saveFolderWritable")
check_true("v56", "@eml_saveFolderWritable exists", length(fw) > 0)

# `nocheck` IS THE WHOLE MECHANISM. Praat has no try/catch, so a guard that
# asks the question with a bare command aborts on the answer -- which is the
# defect, moved. Both raising commands must carry the prefix.
check_true("v56", "the probe's createFolder: is nocheck-prefixed",
           any(grepl("^nocheck createFolder:", fw)))
check_true("v56", "the probe's writeFile: is nocheck-prefixed",
           any(grepl("^nocheck writeFile:", fw)))
check_true("v56", "the probe cleans up after itself (nocheck deleteFile:)",
           sum(grepl("^nocheck deleteFile:", fw)) >= 2)
check_true("v56",
           "the verdict is read from fileReadable, not assumed from the write",
           any(grepl("if fileReadable \\(\\.probe\\$\\)", fw)))
check_true("v56", "the probe file carries the press's stamp, so it cannot collide",
           any(grepl("eml_write_test_\" \\+ \\.stamp\\$", fw)))

# NO BARE createFolder: LEFT IN THE PANEL. The line the audit called "the
# pattern to follow" was itself the earliest kill site: under an unwritable
# parent it raises before any tickbox is honoured.
check_true("v56",
           "@emlSavePanel no longer calls createFolder: unguarded",
           !any(grepl("^createFolder:", panel)))
check_true("v56", "@emlSavePanel asks the writability question",
           any(grepl("@eml_saveFolderWritable:", panel)))

# AND IT RETURNS RATHER THAN CONTINUING. A guard that detects and then falls
# through writes into the folder it just proved unwritable.
iGuard <- grep("@eml_saveFolderWritable:", panel)
iBail <- grep("goto SAVE_PANEL_DONE", panel)
check_true("v56", "a failed writability check leaves the panel by its normal exit",
           length(iGuard) == 1 && any(iBail > iGuard[1] & iBail < min(iWrite)))
check_true("v56", "and the check happens before any write",
           length(iGuard) == 1 && iGuard[1] < min(iWrite))

# ===========================================================================
# 3. THE RECEIPT -- static
# ===========================================================================
rec <- .body(code, "eml_saveReceiptLines")
check_true("v56", "@eml_saveReceiptLines exists, separate from the drawing",
           length(rec) > 0)
# EVERY SOURCE OF TEXT, NAMED SEPARATELY. Three strings reach the receipt and
# each is a path to the same defect: the file list splits on newline$ into
# .one$ per line, .rest$ is whatever follows the last newline (a list that
# does not end in one), and .note$ is the adjusted-name disclosure. A count
# would let any one of them lose its wrap while the other two kept the number
# up -- and the first break test written against this check did exactly that.
for (site in c("\\.one\\$", "\\.rest\\$", "\\.note\\$")) {
    check_true("v56",
               sprintf("the receipt wraps %s through @emlWrapText",
                       gsub("\\\\", "", site)),
               any(grepl(paste0("@emlWrapText: ", site, ", "), rec)))
}

# THE WIDTH IS 62, MEASURED. A pause form was driven on 6.6.30 under Xvfb on
# 15 Aug 2026 with comments of 55 to 68 characters and photographed: 65 draws
# on one line, 66 wraps. 62 is what @emlErrorDialog already uses, so the panel
# and the error surface break in the same place, and the three characters of
# margin cover a different font on macOS or Windows. Pinned because a width
# that drifts up produces no error and no missing file -- just ink over ink.
widths <- as.integer(sub(".*@emlWrapText: .*, (\\d+).*", "\\1",
                         grep("@emlWrapText: ", rec, value = TRUE)))
check_true("v56",
           sprintf("every receipt line is wrapped to 62 characters (found: %s)",
                   paste(unique(widths), collapse = ", ")),
           length(widths) > 0 && all(widths == 62))
check_true("v56", "the measured toolkit budget of 65 is not exceeded",
           length(widths) > 0 && all(widths <= 65))

# THE PANEL DRAWS WHAT THE BUILDER BUILT, and nothing else. A `comment:` in
# the Saved block that takes a raw string instead of a built line is the
# defect returning by the door it came in.
iSaved <- grep('^beginPause: "Saved"', panel)
iEndSaved <- grep('^endPause: "OK", 1, 0', panel)
if (check_true("v56", "the Saved receipt block is locatable",
               length(iSaved) == 1 && any(iEndSaved > iSaved[1]))) {
    blk <- panel[seq(iSaved[1], min(iEndSaved[iEndSaved > iSaved[1]]))]
    comments <- grep("^comment: ", blk, value = TRUE)
    fromBuilder <- grepl("^comment: eml_saveReceiptLines\\.line\\$", comments)
    literal <- grepl('^comment: "', comments)
    check_true("v56",
               sprintf("every receipt comment is a built line or a fixed literal (%d comment(s))",
                       length(comments)),
               length(comments) > 0 && all(fromBuilder | literal))
    check_true("v56", "the file list is drawn from the builder's lines",
               any(fromBuilder))
}

# ===========================================================================
# 4. THE COERCION PROBE -- static
# ===========================================================================
aud <- .body(code, "eml_auditLabelColumn")
check_true("v56", "@eml_auditLabelColumn exists", length(aud) > 0)

# "?" IS THE POINT. Praat renders an undefined Table cell as the one-character
# string "?" -- measured on 6.6.30 -- and that is neither of the two forms
# @eml_strictNumericColumn's scan recognises, which is exactly why the
# numericiser behind it raised. A classifier that does not know that string
# classifies nothing.
check_true("v56", "the classifier recognises Praat's \"?\" for an undefined cell",
           any(grepl('\\.cell\\$ = "\\?"', aud)))
check_true("v56", "and the empty string and --undefined-- as well",
           any(grepl('\\.cell\\$ = ""', aud)) &&
           any(grepl('\\.cell\\$ = "--undefined--"', aud)))
check_true("v56",
           "an unlabelled cell is rewritten to the empty string, which every EML reader handles",
           any(grepl('Set string value: \\.r, \\.columnName\\$, ""', aud)))
# IDEMPOTENT. It must be safe to run over a column somebody else has already
# filled, because the conversion-side default row labels are a separate piece
# of work and neither half may depend on running first.
check_true("v56", "a cell that is already empty is not written to again",
           any(grepl('if \\.cell\\$ <> ""', aud)))
check_true("v56", "the classifier returns a verdict rather than a bare flag",
           all(sapply(c('"empty"', '"partial"', '"labelled"'),
                      function(v) any(grepl(v, aud, fixed = TRUE)))))

# BOTH ARMS CALL IT, and the Matrix arm calls it on the RENAMED column. The
# Matrix arm renames column 1 to "OriginalRowLabel" when a data column is
# already called "row"; auditing the literal "row" after that rename would
# audit the user's own data.
init <- .body(code, "emlWrapperInit")
check_true("v56", "both coercion arms classify the label column they create",
           sum(grepl("@eml_auditLabelColumn:", init)) == 2)
check_true("v56",
           "the Matrix arm audits the column by its real name, after the collision rename",
           any(grepl("@eml_auditLabelColumn: \\.tableId, \\.labelCol\\$", init)))
# AND THE CLAIM IS CONDITIONAL NOW. The TableOfReal arm used to announce
# "Row labels are in column ""row""" whatever it had just converted -- a false
# sentence on an unlabelled object, and the crash that followed was the user's
# first hint that it was false. The sentence must sit under the verdict.
iAudit <- grep("@eml_auditLabelColumn:", init)
iVerdict <- grep('eml_auditLabelColumn\\.verdict\\$ = "labelled"', init)
# SEAMS CLOSED BEFORE SEARCHING FOR PROSE. This check went red on 15 Aug
# against a tree where the ordering was entirely correct. The loader already
# joins `...` continuations and drops comments, but Praat prose is also broken
# across STRING CONCATENATION -- the arm now reads
#
#     ... """. Row labels are in "
#     ... + "column ""row""."
#
# which joins to `Row labels are in " + "column` and no longer contains the
# phrase as a substring. The sentence a user sees was unchanged; only where
# the author put the plus sign moved. A check that a reflow can turn red is a
# check that will one day be "fixed" by loosening it, and the loosening is
# what costs the coverage. So the seam is closed instead: the search runs on
# text with `" + "` joins removed, which is the string the user actually gets.
.seamless <- function(x) gsub('"\\s*\\+\\s*"', "", x)
iClaim <- grep("Row labels are in column", .seamless(init))
check_true("v56",
           "the TableOfReal arm claims row labels only when the classifier found some",
           length(iVerdict) == 1 && length(iClaim) >= 1 &&
           length(iAudit) == 2 && min(iAudit) < iVerdict[1] &&
           iVerdict[1] < min(iClaim))

# ===========================================================================
# 5. THE WRITER'S CONTRACT
# ===========================================================================
# The flush that both severity-2 defects landed on is in the result writer,
# and it is deliberately unguarded -- Praat has no try/catch, so a guard there
# could only refuse or repair, and repairing a path at the flush would give
# the frames a different base name from the figure and the report beside them.
# What the writer owes is that the contract is WRITTEN DOWN at the line where
# the failure appeared, so the next reader of that stack trace is sent to the
# panel instead of adding a second, disagreeing guard.
if (check_true("v56", "the result writer is present", file.exists(wsrc))) {
    wraw <- readLines(wsrc, warn = FALSE)
    iFlush <- grep("^procedure eml_writeTidyFile:", wraw)
    check_true("v56", "the flush procedure is where the audit said it is",
               length(iFlush) == 1)
    if (length(iFlush) == 1) {
        head <- wraw[max(1, iFlush - 32):iFlush]
        check_true("v56",
                   "the flush site records which guards protect it and where they live",
                   any(grepl("@eml_saveSafeBaseName", head)) &&
                   any(grepl("@eml_saveFolderWritable", head)) &&
                   any(grepl("@emlSavePanel", head)))
    }
}

# ===========================================================================
# 6. THE LIVE EVIDENCE -- procedure level
# ===========================================================================
gf <- file.path(gd, "GUARDS.tsv")
if (check_true("v56",
               "the guards drive was run (bash harness/savepaths/guards.sh)",
               file.exists(gf) && file.info(gf)$size > 0)) {
    x <- read.delim(gf, header = FALSE, sep = "\t", quote = "",
                    stringsAsFactors = FALSE, fill = TRUE)
    m <- setNames(as.list(as.character(x[[2]])), trimws(as.character(x[[1]])))
    g <- function(k) if (is.null(m[[k]])) NA_character_ else m[[k]]
    gn <- function(k) suppressWarnings(as.numeric(g(k)))

    # THE DRIVE RAN TO THE END. At HEAD it could not: the first call in it is
    # to a procedure that did not exist, and the coercion section aborted
    # Praat outright.
    check_true("v56", "the guards drive completed", identical(g("completed"), "1"))
    check_true("v56", sprintf("it ran on the target Praat (%s)", g("praat_version")),
               identical(g("praat_version"), "6.6.30"))

    # -- the base name ------------------------------------------------------
    check("v56", "all nine hostile characters are tested",
          9, gn("basename_chars_tested"), tol = 0)
    check("v56", "and none of them survives the sanitiser",
          0, gn("basename_chars_surviving"), tol = 0)
    check_true("v56",
               sprintf("the audit's own `pre/post` becomes a file name (%s)",
                       g("basename_prepost")),
               !is.na(g("basename_prepost")) &&
               !grepl("/", g("basename_prepost"), fixed = TRUE) &&
               nzchar(g("basename_prepost")))
    # AN ORDINARY NAME IS NOT TOUCHED. The proposed default is the name nine
    # wrappers in ten will save under, and a sanitiser that rewrote it would
    # rename every study in the plugin without saying so.
    check_true("v56", "an ordinary stamped base name comes back unchanged",
               identical(g("basename_ordinary"), "save_demo_two-group_20260815_034322") &&
               identical(g("basename_ordinary_changed"), "0"))
    check_true("v56", "a leading dot is removed (the files would be invisible)",
               identical(g("basename_leading_dot"), "hidden"))
    check_true("v56", "a trailing dot is removed (Windows strips it silently)",
               identical(g("basename_trailing_dot"), "trailing"))
    check_true("v56", "and a file actually lands under the sanitised name",
               identical(g("basename_write_landed"), "1"))

    # -- the folder ---------------------------------------------------------
    check_true("v56", "a writable folder passes the probe",
               identical(g("folder_writable_ok"), "1"))
    check_true("v56", "a folder that does not exist yet is created and passes",
               identical(g("folder_created_ok"), "1") &&
               identical(g("folder_created_exists"), "1"))
    check_true("v56", "an empty folder string is refused rather than guessed at",
               identical(g("folder_empty_ok"), "0"))
    check_true("v56", "the probe leaves no test file behind on a writable folder",
               identical(g("probe_litter_rw"), "0"))
    check_true("v56",
               "the whole folder section ran without Praat raising",
               identical(g("folder_probe_survived"), "1"))

    # THE UNWRITABLE CASE, and it is reported MISSING rather than passed over
    # when the sandbox cannot produce one. This machine runs Praat as root, so
    # chmod is no probe at all -- the audit's own G12 leg recorded `chmod 555`
    # as USELESS and left NEW-G12-5 unreproduced for that reason. A read-only
    # mount is refused by the kernel for everyone.
    if (nzchar(g("ro_folder")) && !is.na(g("ro_folder"))) {
        check_true("v56", "the read-only target exists and is readable",
                   identical(g("ro_folder_exists"), "1"))
        check_true("v56",
                   sprintf("an unwritable folder is refused, with a sentence (%s)",
                           g("folder_readonly_reason")),
                   identical(g("folder_readonly_ok"), "0") &&
                   nzchar(g("folder_readonly_reason")))
        check_true("v56",
                   sprintf("a new folder under an unwritable parent is refused too (%s)",
                           g("folder_readonly_child_reason")),
                   identical(g("folder_readonly_child_ok"), "0") &&
                   nzchar(g("folder_readonly_child_reason")))
        check_true("v56", "nothing was left behind on the read-only folder",
                   identical(g("probe_litter_ro"), "0"))
    } else {
        cat(paste0("      NOTE v56: NEW-G12-5 live evidence MISSING -- this ",
                   "sandbox could not\n            provide a read-only ",
                   "folder (Praat runs as root here, so chmod is\n            ",
                   "no probe). Static checks above still hold.\n"))
        check_true("v56",
                   "the drive DECLARED the missing read-only target rather than skipping it",
                   file.exists(file.path(gd, "RO.txt")))
    }

    # -- the receipt --------------------------------------------------------
    # THE PINNED PATHS ARE THE AUDIT'S OWN, read off its overprinted receipt:
    # three paths of 73 and 74 characters. Pinned rather than taken from the
    # run's own folder because a short output path passes this check on a
    # machine where the fault cannot occur.
    check_true("v56", "the receipt was built from three long paths",
               identical(g("receipt_paths"), "3"))
    check_true("v56",
               sprintf("three 73-character paths become more than three drawn lines (%s)",
                       g("receipt_lines")),
               !is.na(gn("receipt_lines")) && gn("receipt_lines") > 3)
    check_true("v56",
               sprintf("and no drawn line exceeds the measured budget (longest %s)",
                       g("receipt_longest_line")),
               !is.na(gn("receipt_longest_line")) &&
               gn("receipt_longest_line") <= 62)
    # NOTHING INSERTED, NOTHING ELIDED. §6 of the audit named the receipt's
    # honest full-path listing as worth preserving; a wrap that shortened or
    # ellipsised a path would satisfy the line-length check and destroy the
    # property the check exists to protect.
    check_true("v56", "the drawn lines concatenate back to the paths exactly",
               identical(g("receipt_roundtrip"), "1"))
    check_true("v56",
               sprintf("the adjusted-name note is wrapped too (longest %s)",
                       g("receipt_note_longest_line")),
               !is.na(gn("receipt_note_longest_line")) &&
               gn("receipt_note_longest_line") <= 62 &&
               gn("receipt_note_lines") > gn("receipt_lines"))

    # -- the coercion probe -------------------------------------------------
    for (shape in c("matrix", "tor", "partial", "full")) {
        check_true("v56",
                   sprintf("@emlWrapperInit survives a %s selection",
                           c(matrix = "Matrix", tor = "TableOfReal with no row labels",
                             partial = "partially labelled TableOfReal",
                             full = "fully labelled TableOfReal")[[shape]]),
                   identical(g(paste0("coerce_", shape, "_survived")), "1"))
    }
    # THE REGRESSION GUARD. A fully labelled TableOfReal converted correctly
    # before this work and must still: the fix must not be "delete the column".
    check_true("v56", "real row labels survive the classifier untouched",
               identical(g("coerce_full_label1"), "alpha") &&
               identical(g("coerce_full_label3"), "gamma"))

    check_true("v56", "a Matrix's label column classifies as empty",
               identical(g("audit_matrix_verdict"), "empty") &&
               identical(g("audit_matrix_unlabelled"), "6"))
    check_true("v56", "and the classification is idempotent",
               identical(g("audit_matrix_verdict_2"), "empty"))
    check_true("v56", "a partially labelled column classifies as partial",
               identical(g("audit_partial_verdict"), "partial") &&
               identical(g("audit_partial_labelled"), "2") &&
               identical(g("audit_partial_unlabelled"), "2"))
    check_true("v56", "a fully labelled column classifies as labelled",
               identical(g("audit_full_verdict"), "labelled") &&
               identical(g("audit_full_unlabelled"), "0"))

    # THE RULING, LITERALLY. "Probe should classify column types, never assume
    # numeric" -- so the exact call that raised at HEAD must now RETURN, and
    # what it returns must be the classification "not numeric, not readable".
    check_true("v56",
               "the numeric probe now returns a classification on the column that aborted it",
               identical(g("audit_matrix_probe_survived"), "1") &&
               identical(g("audit_matrix_strict"), "0") &&
               identical(g("audit_matrix_unreadable"), "1"))
    # THE STRANDED OBJECTS GO WITH THE CRASH. Each raise left a temp table
    # named eml_numericProbe in the object list, and a stranded temp object is
    # the next thing a user selects (NEW-G12-2's secondary clause).
    check_true("v56", "no probe temp table is stranded in the object list",
               identical(g("stranded_probe_tables"), "0"))
}

# ===========================================================================
# 7. THE LIVE EVIDENCE -- the panel, pressed
# ===========================================================================
# A PROCEDURE THAT WORKS AND A PANEL THAT CALLS IT ARE TWO CLAIMS. On
# 14 August 2026 this same panel went down at all nine non-graphing call sites
# with a correct procedure and an unbound argument, and every static check in
# the tree passed. So the guards are also pressed through a real analysis, in
# a real dialog, with the hostile value TYPED into the field a user types
# into.
.legcheck <- function(leg, wantFiles, wantTitle) {
    d <- file.path(gd, paste0(leg, ".dialogs.tsv"))
    if (!check_true("v56", sprintf("%s: the GUI leg ran", leg),
                    file.exists(d) && file.info(d)$size > 0)) return(invisible(NULL))
    tsv <- read.delim(d, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE)
    titles <- trimws(as.character(tsv[[2]]))
    labels <- if (ncol(tsv) >= 3) trimws(as.character(tsv[[3]])) else character(0)

    # NO ERROR ROW. Praat's error window carries no window name at all, so a
    # run that hits one otherwise reports a short clean chain and no files --
    # which is indistinguishable from "the script finished early". This is the
    # single row that separates the fix from the defect.
    check_true("v56",
               sprintf("%s: Praat raised no error window (see %s.error.png)",
                       leg, leg),
               !any(grepl("^ERROR", as.character(tsv[[1]]))))
    check_true("v56", sprintf("%s: the Save panel came up", leg),
               any(titles == "Save"))
    check_true("v56", sprintf("%s: the panel answered with \"%s\"", leg, wantTitle),
               any(titles == wantTitle))
    # THE SESSION SURVIVED. The whole severity of both findings is that the
    # post-analysis loop died with the save. Reaching "Analysis complete" a
    # SECOND time and pressing Done is the proof that it did not.
    check_true("v56",
               sprintf("%s: the analysis loop came back and was closed with Done", leg),
               sum(titles %in% c("Analysis complete", "Analysis Complete")) >= 2 &&
               any(labels == "Done"))

    a <- file.path(gd, paste0(leg, ".artefacts.tsv"))
    n <- if (file.exists(a) && file.info(a)$size > 0)
             nrow(read.delim(a, header = FALSE, sep = "\t", quote = "",
                             stringsAsFactors = FALSE, fill = TRUE)) else 0L
    invisible(list(n = n, a = a))
}

hn <- .legcheck("hostilename", TRUE, "Saved")
if (!is.null(hn)) {
    check_true("v56",
               sprintf("hostilename: the save wrote files under the sanitised name (%d)",
                       hn$n),
               hn$n > 0)
    if (hn$n > 0) {
        art <- read.delim(hn$a, header = FALSE, sep = "\t", quote = "",
                          stringsAsFactors = FALSE, fill = TRUE)
        names <- trimws(as.character(art[[1]]))
        # NOT ONE OF THE NINE, in any name that landed. The typed string
        # carried all nine.
        bad <- names[grepl('[\\\\:*?"<>|]', names)]
        check_true("v56",
                   sprintf("no saved file name carries a hostile character (%s)",
                           if (length(bad)) paste(bad, collapse = ", ") else "none"),
                   length(bad) == 0)
        # ONE STEM, STILL. The panel's whole contract, re-asserted on the path
        # where the name was rewritten under the user: sanitising must happen
        # once, above the walk, or the frames and the report diverge.
        stems <- sub("_[a-z]+_tidy\\.csv$", "", names)
        stems <- sub("_(tidy|glance|augment|report|legend)\\.(csv|txt|png)$", "",
                     stems)
        stems <- sub("\\.png$", "", stems)
        stems <- sub("\\.csv$", "", stems)
        check_true("v56",
                   sprintf("hostilename: every file still shares one stem (%s)",
                           paste(unique(stems), collapse = " | ")),
                   length(unique(stems)) == 1)
    }
}

# THE ORDINARY PATH, UNCHANGED. Two guards and a rebuilt receipt on the last
# step of every analysis in the plugin: the cost of that to a save that has
# nothing wrong with it has to be zero, and "zero" has to be a checked number
# rather than an expectation. This leg types nothing and takes the panel's
# proposal, so it is also the one whose file names still carry the stamp.
pn <- .legcheck("plainname", TRUE, "Saved")
if (!is.null(pn)) {
    check_true("v56",
               sprintf("plainname: an ordinary save still writes its files (%d)",
                       pn$n),
               pn$n > 0)
    if (pn$n > 0) {
        art <- read.delim(pn$a, header = FALSE, sep = "\t", quote = "",
                          stringsAsFactors = FALSE, fill = TRUE)
        names <- trimws(as.character(art[[1]]))
        # THE STAMP SURVIVED THE GUARDS. The sanitiser runs over the proposed
        # name on every press, and the proposed name IS the stamp -- a
        # sanitiser that trimmed or rewrote it would silently renumber every
        # study in the plugin, and the one-stamp-per-press rule would go with
        # it.
        st <- regmatches(names, regexpr("[0-9]{8}_[0-9]{6}", names))
        check("v56", "plainname: every file still carries a timestamp",
              length(names), length(st), tol = 0)
        check_true("v56",
                   sprintf("plainname: and it is the same second on all of them (%s)",
                           paste(unique(st), collapse = " | ")),
                   length(unique(st)) == 1)
        # THE PROPOSED NAME REACHED DISK UNALTERED. leg.praat's table is
        # `save_demo` and eml-compare-groups proposes
        # <table>_two-group_<stamp>, so the stem is known exactly. Asserted
        # against the literal rather than against "no hyphens appeared",
        # because the stem contains a hyphen of its own -- a check phrased
        # around the replacement character would have been satisfied by
        # anything.
        check_true("v56",
                   sprintf("plainname: the proposed stem reached disk unaltered (%s)",
                           paste(unique(sub("_[0-9]{8}_[0-9]{6}.*$", "", names)),
                                 collapse = " | ")),
                   all(grepl("^save_demo_two-group_[0-9]{8}_[0-9]{6}", names)))
    }
    check_true("v56",
               "plainname: the receipt was photographed (guards_out/plainname.receipt.png)",
               file.exists(file.path(gd, "plainname.receipt.png")))
}

if (file.exists(file.path(gd, "unwritable.dialogs.tsv"))) {
    uw <- .legcheck("unwritable", FALSE, "Cannot save there")
    if (!is.null(uw)) {
        # AND NOTHING WAS WRITTEN. A guard that refuses and then writes
        # anyway is worse than no guard: it reports a failure over a
        # half-saved set.
        check_true("v56",
                   sprintf("unwritable: nothing landed on disk (%d file(s))", uw$n),
                   uw$n == 0)
    }
} else {
    cat(paste0("      NOTE v56: the unwritable GUI leg did not run -- no ",
               "read-only mount\n            in this sandbox. See ",
               "guards_out/RO.txt.\n"))
}

if (!exists("EML_SUITE")) {
    eml_report(paste("v56 save guards: a hostile base name, an unwritable folder,",
                     "a receipt that fits, and a probe that classifies"))
    eml_exit()
}
