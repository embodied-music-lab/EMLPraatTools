# ============================================================================
# v44_tab_walk.R -- where Tab goes in a Praat pause dialog, measured
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. harness/gui_e2e stopped at the column-mapping dialog
# for two days, and the reason it gave for stopping contradicted the reason it
# gave for its own tab counts. Its header: Praat's pause dialogs are "walked
# with Tab -- which visits every focusable widget, not just the buttons, so
# the count differs with each dialog's field count". Sixty lines below, its
# case table: "Tab walks the button row exactly: Tab x0 -> button 1, x1 -> 2".
#
# Those are different laws and neither had been measured. The four counts in
# that table were never exercised either, because the harness returned before
# reaching a dialog that needed one -- so the file was simultaneously the only
# statement of the law and unable to test it.
#
# WHAT THE MEASUREMENT FOUND. The header was right and the table was wrong,
# and the table was wrong in the way that does not announce itself:
#
#   * Tab visits every FIELD before it reaches a button. The table's
#     "Column Mapping tabs=4" lands on Go Back, not Draw -- the harness would
#     have looped that dialog forever.
#   * Return in a text entry or on a checkbox presses the DEFAULT button, not
#     the focused widget. So an off-by-one does not hang; it silently presses
#     something else and the run looks like it worked.
#   * Return on an optionmenu opens its dropdown and dismisses nothing.
#   * `folder:` is not an entry. It is a multi-line GtkTextView with a Browse
#     button, and GTK text views swallow Tab AS A LITERAL TAB CHARACTER. On
#     the Save Figure shape NO forward count from 0 to 13 reaches a button,
#     and every Tab sent is appended to the output folder path.
#   * Return on that Browse button opens a modal "Choose folder" which then
#     eats every subsequent key.
#
# AND WHAT REPLACED IT. Focus starts at ring position 0, so ONE shift+Tab
# wraps backward to the LAST widget, which is the last button. shift+Tab xN
# presses the Nth button FROM THE END -- on every shape, with or without
# fields, whatever the widgets are, and without ever entering a field. The
# count then comes from the endPause: list in the source, which is static per
# dialog. That is what let harness/gui_e2e reach Save, Export CSV, Redraw and
# teardown.
#
#     bash harness/tabwalk/run.sh          regenerate the input
#     Rscript validate/v44_tab_walk.R
#
# Input: <dir>/TABWALK_JOINED.tsv, five fields, no header:
#            case  k  outcome  detail  clicked
#        outcome is CLOSED | NOCLOSE | CHOOSER; clicked is NA unless CLOSED,
#        because a dialog the measured press did not close was closed by the
#        recovery instead. <dir> is $EML_TABWALK_DIR, default
#        harness/tabwalk/out. A missing artefact is a HARD STOP, not a skip.
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

tw_dir <- Sys.getenv("EML_TABWALK_DIR", unset = "")
if (!nzchar(tw_dir)) tw_dir <- repo_path("harness", "tabwalk", "out")
tw_p <- file.path(tw_dir, "TABWALK_JOINED.tsv")

if (!file.exists(tw_p)) {
    stop("tab-walk artefact not found: ", tw_p,
         "\n  Run: bash harness/tabwalk/run.sh")
}

tw <- read.delim(tw_p, header = FALSE, stringsAsFactors = FALSE,
                 quote = "", comment.char = "",
                 col.names = c("case", "k", "outcome", "detail", "clicked"))
tw$k <- as.integer(tw$k)
tw$clicked <- suppressWarnings(as.integer(tw$clicked))

CASES <- c(paste0("nofields4_k", 0:5), paste0("fields2_k", 0:4),
           paste0("fields6_k", 0:5), paste0("nofields1_k", 0:2),
           paste0("bools3_k", 0:5), paste0("folder2_k", 0:5),
           paste0("deftest_k", 0:1),
           "nofields4_r1", "nofields4_r2", "fields2_r1", "fields2_r2",
           "fields6_r1", "fields6_r2", "bools3_r1",
           "folder2_r1", "folder2_r2", "nofields1_r1")
eml_census("v44", "tab-walk case", tw$case, CASES)
eml_claim("v44", "tabwalk_out", CASES)
check("v44", "every declared case was driven", nrow(tw), length(CASES), tol = 0)

.o <- function(nm) tw$outcome[match(nm, tw$case)]
.c <- function(nm) tw$clicked[match(nm, tw$case)]

# ---------------------------------------------------------------------------
# 1. THE FORWARD WALK, WITHOUT FIELDS: Tab really does walk the button row
# ---------------------------------------------------------------------------
# This is the half of gui_e2e's old case table that was true, and it is true
# only here -- on a dialog with no editable field, which of the plugin's
# dialogs means Graph Complete and the OK-only notices.
for (i in 0:3) {
    check("v44", sprintf("nofields4: Tab x%d presses button %d", i, i + 1),
          i + 1L, .c(paste0("nofields4_k", i)), tol = 0)
}
# AND IT WRAPS, which is the property that makes an over-count silent rather
# than loud: four buttons, so Tab x4 is back on button 1.
check("v44", "nofields4: the ring wraps rather than stopping at the end",
      1L, .c("nofields4_k4"), tol = 0)
check("v44", "nofields4: and keeps going round", 2L, .c("nofields4_k5"), tol = 0)
check_true("v44", "nofields1: a one-button ring answers 1 at every count",
           all(.c(paste0("nofields1_k", 0:2)) == 1L))

# ---------------------------------------------------------------------------
# 2. THE FORWARD WALK, WITH FIELDS: the count is NOT the button index
# ---------------------------------------------------------------------------
# THE REFUTATION. If Tab walked only the button row, k=0 would press button 1
# on these three shapes exactly as it does on nofields4. It does not press
# button 1 on any of them -- Tab is still down among the fields.
check_true("v44", "with fields, Tab x0 does not reach button 1",
           !identical(.c("fields2_k0"), 1L) &&
           !identical(.c("bools3_k0"), 1L) &&
           .o("fields6_k0") != "CLOSED")

# RETURN IN AN ENTRY OR ON A CHECKBOX PRESSES THE DEFAULT. This is why a wrong
# forward count is dangerous rather than merely wrong: it closes the dialog on
# a button nobody chose, and the run continues looking healthy.
check("v44", "fields2: Return in the first entry presses the default (2)",
      2L, .c("fields2_k0"), tol = 0)
check("v44", "fields2: and in the second entry, still the default",
      2L, .c("fields2_k1"), tol = 0)
check("v44", "bools3: Return on a checkbox presses the default (3)",
      3L, .c("bools3_k0"), tol = 0)
check("v44", "bools3: on the second checkbox too", 3L, .c("bools3_k1"), tol = 0)

# PRAAT PREPENDS AN UNDO BUTTON to any pause that has an editable field, and
# Undo does not dismiss. That is the whole reason the button index differs
# between two dialogs with the same endPause: list.
check_true("v44", "fields2: past the fields comes a widget that does not dismiss",
           .o("fields2_k2") == "NOCLOSE")
check_true("v44", "bools3: the same non-dismissing widget sits before button 1",
           .o("bools3_k2") == "NOCLOSE")
# ... and immediately after it, the real buttons, in order.
check("v44", "fields2: one past Undo is button 1", 1L, .c("fields2_k3"), tol = 0)
check("v44", "fields2: two past Undo is button 2", 2L, .c("fields2_k4"), tol = 0)
check("v44", "bools3: the button row follows Undo in order",
      1L, .c("bools3_k3"), tol = 0)
check("v44", "bools3: and continues", 2L, .c("bools3_k4"), tol = 0)
check("v44", "bools3: to the last button", 3L, .c("bools3_k5"), tol = 0)

# AN OPTIONMENU SWALLOWS RETURN by opening its dropdown. fields6's first and
# fourth fields are optionmenus and its second, third, fifth and sixth are
# entries, so the pattern of NOCLOSE against default-pressed reads the field
# list off the dialog.
check_true("v44", "fields6: Return on an optionmenu dismisses nothing",
           .o("fields6_k0") == "NOCLOSE" && .o("fields6_k3") == "NOCLOSE")
check_true("v44", "fields6: Return on the entries between them presses the default",
           all(.c(paste0("fields6_k", c(1, 2, 4, 5))) == 4L))

# ---------------------------------------------------------------------------
# 3. THE folder: TRAP, which is the finding with teeth
# ---------------------------------------------------------------------------
# "Save Figure" and "Export Results" are both folder: + word:. A forward walk
# on that shape reaches no button at any count, and every Tab it sends is
# inserted into the output folder path as literal whitespace -- so the failure
# is not a stuck harness, it is a corrupted save path.
check_true("v44", "folder2: Return at rest opens a modal chooser",
           .o("folder2_k0") == "CHOOSER")
check_true("v44", "folder2: and the chooser is GTK's folder picker",
           tw$detail[match("folder2_k0", tw$case)] == "Choose folder")
check_true("v44", "folder2: no forward count reaches a button at all",
           all(.o(paste0("folder2_k", 1:5)) == "NOCLOSE"))

# ---------------------------------------------------------------------------
# 4. WHICH TRAILING NUMBER IS THE DEFAULT
# ---------------------------------------------------------------------------
# Every endPause: in the plugin ends with two integers. deftest is
# `endPause: "Alpha", "Bravo", "Charlie", 3, 1` and Return in an entry presses
# the default, so the answer is 3 if the second-to-last names it and 1 if the
# last one does. Without this, section 2's expected values are a guess.
check("v44", "the default button is the SECOND-TO-LAST endPause integer",
      3L, .c("deftest_k0"), tol = 0)
check("v44", "confirmed from the second entry as well", 3L, .c("deftest_k1"),
      tol = 0)

# ---------------------------------------------------------------------------
# 5. THE REVERSE WALK, which is what the harness now uses
# ---------------------------------------------------------------------------
# ONE shift+Tab PRESSES THE LAST BUTTON. Asserted on every button-row shape at
# once -- 1, 2, 3 and 4 buttons; with and without fields; entries, checkboxes,
# optionmenus and the folder text view. A law that held on only the shapes
# without fields would be the old table's mistake in the other direction.
LAST <- c(nofields4_r1 = 4L, fields2_r1 = 2L, fields6_r1 = 4L,
          bools3_r1 = 3L, folder2_r1 = 2L, nofields1_r1 = 1L)
for (nm in names(LAST)) {
    check("v44", sprintf("%s: shift+Tab x1 presses the last button", nm),
          LAST[[nm]], .c(nm), tol = 0)
}

# AND IT IS A WALK, not a special case for the final widget.
SECOND <- c(nofields4_r2 = 3L, fields2_r2 = 1L, fields6_r2 = 3L,
            folder2_r2 = 1L)
for (nm in names(SECOND)) {
    check("v44", sprintf("%s: shift+Tab x2 presses the second-to-last", nm),
          SECOND[[nm]], .c(nm), tol = 0)
}

# THE PROPERTY THAT MAKES IT SAFE. Every reverse press closed its dialog on a
# real button. None opened a chooser, none landed on Undo, and none reached a
# field -- so none of them could corrupt a field value on the way past.
rev <- tw[grepl("_r[0-9]+$", tw$case), ]
check("v44", "every reverse case was driven", 10L, nrow(rev), tol = 0)
check_true("v44", "no reverse press ever failed to close its dialog",
           all(rev$outcome == "CLOSED"))
check_true("v44", "no reverse press ever opened a chooser",
           !any(rev$outcome == "CHOOSER"))
check_true("v44", "every reverse press returned a real button index",
           all(is.finite(rev$clicked)) && all(rev$clicked >= 1))

# THE DIRECT COMPARISON, on one shape, which is the whole argument in a line:
# forward reaches nothing on the Save Figure shape, backward reaches Save.
check_true("v44", "on the Save Figure shape, backward works where forward cannot",
           all(.o(paste0("folder2_k", 1:5)) == "NOCLOSE") &&
           .o("folder2_r1") == "CLOSED" && .c("folder2_r1") == 2L)

if (!exists("EML_SUITE")) {
    eml_report("v44 tab walk: the pause-dialog focus ring, measured")
    eml_exit()
}
