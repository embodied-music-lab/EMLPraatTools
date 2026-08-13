# ---------------------------------------------------------------------------
# WHICH WIDGET DOES TAB VISIT IN A PRAAT PAUSE DIALOG?
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# harness/gui_e2e/run.sh contains BOTH answers to this question and no
# measurement of either. Its file header says Praat's pause dialogs are
# "walked with Tab -- which visits every focusable widget, not just the
# buttons, so the count differs with each dialog's field count", and names
# that as the reason the harness stops at the column-mapping dialog. Sixty
# lines further down, its own case table says "Tab walks the button row
# exactly: Tab x0 -> button 1, x1 -> 2, x2 -> 3, x3 -> wraps to 1."
#
# Those are different laws. Under the first, a dialog with 30 fields needs
# 30-odd tabs to reach a button; under the second it needs at most four. The
# table in that file is written as though the second were true, and the four
# counts in it were never exercised, because the harness returns before
# reaching a dialog that needs one.
#
# Guessing which is right and running until the suite goes green is the
# failure mode that whole harness exists to end. So this measures it.
#
# THE SHAPES ARE THE REAL ONES. Four dialogs, chosen to span every button-row
# shape @emlGraphsWorkflow actually raises, and to isolate the one variable
# that matters:
#
#   nofields4  2 comments,  0 editable fields, 4 buttons  ("Graph Complete")
#   fields2    2 editable fields,               2 buttons  ("Save Figure")
#   fields6    6 editable fields,               4 buttons  ("... Column Mapping")
#   nofields1  1 comment,   0 editable fields, 1 button   ("Save Complete")
#
# nofields4 against fields6 isolates Praat's PREPENDED REVERT BUTTON: Praat
# adds one to any pause that has an editable field, and nothing else changes
# the row. nofields4 against nofields1 shows the row length has no other
# effect. If comments were focusable, nofields4 and nofields1 would disagree
# with each other by two.
#
# ONE DIALOG PER PRESS. The shell sweeps k = 0, 1, 2 ... tabs, and each k
# gets a FRESH dialog, because a press that lands on Revert does not close
# the dialog and a press that lands on a button does — one instance can only
# answer for one k.
#
# Output: RESULT lines, appended as each dialog closes:
#     RESULT <case> clicked=<n>
# The shell records its own outcome line per case. A case the shell reports
# as NOCLOSE has a RESULT line too -- from the recovery press, not the
# measured one -- and the validator ignores it on that basis.
# ---------------------------------------------------------------------------
outPath$ = environment$ ("EML_TABWALK_OUT")
if outPath$ = ""
    outPath$ = "out/RAW.txt"
endif
writeFileLine: outPath$, "TABWALK BEGIN"

# The sweep, as one flat list so the shell and this file cannot disagree
# about it: shape, and how many tabs the shell will send before Return.
nCase = 0
procedure addCase: .shape$, .k
    nCase = nCase + 1
    caseShape$ [nCase] = .shape$
    caseK [nCase] = .k
    caseId$ [nCase] = .shape$ + "_k" + string$ (.k)
endproc

# THE REVERSE WALK. `_r<n>` tells the shell to send shift+Tab n times instead
# of Tab. It is a separate law and a far more useful one: focus starts at ring
# position 0, so ONE shift+Tab wraps backwards to the LAST widget -- which on
# every dialog in @emlGraphsWorkflow is the button the happy path wants
# (Draw on every column-mapping page, Save on Save Figure and Export
# Results). It also never enters a field, which on the folder shape is the
# difference between pressing Save and silently corrupting the folder path.
procedure addRev: .shape$, .n
    nCase = nCase + 1
    caseShape$ [nCase] = .shape$
    caseK [nCase] = .n
    caseId$ [nCase] = .shape$ + "_r" + string$ (.n)
endproc

for k from 0 to 5
    @addCase: "nofields4", k
endfor
for k from 0 to 4
    @addCase: "fields2", k
endfor
for k from 0 to 5
    @addCase: "fields6", k
endfor
for k from 0 to 2
    @addCase: "nofields1", k
endfor
# THE TWO WIDGET KINDS THE FIRST SWEEP DID NOT COVER, and both are on the
# path this measurement exists to open. Every "... -- Column Mapping" page
# carries booleans, and "Save Figure" is a folder: and a word:. A law derived
# from entries and optionmenus alone would be applied to widgets it had never
# been tested on -- which is the shape of the mistake being corrected here.
for k from 0 to 5
    @addCase: "bools3", k
endfor
for k from 0 to 5
    @addCase: "folder2", k
endfor
# WHICH TRAILING NUMBER IS THE DEFAULT. Every endPause: in the plugin ends
# with TWO integers. Return on a text entry fires the default button, so a
# dialog whose two trailing numbers disagree names it: 3 means the
# second-to-last is the default, 1 means the last one is.
for k from 0 to 1
    @addCase: "deftest", k
endfor

# One reverse step on every shape, which is the claim "shift+Tab x1 presses
# the last button" tested against every button-row shape at once; then a
# second step on three of them, so the direction is shown to be a walk rather
# than a special case for the last widget.
@addRev: "nofields4", 1
@addRev: "nofields4", 2
@addRev: "fields2", 1
@addRev: "fields2", 2
@addRev: "fields6", 1
@addRev: "fields6", 2
@addRev: "bools3", 1
@addRev: "folder2", 1
@addRev: "folder2", 2
@addRev: "nofields1", 1

for c from 1 to nCase
    shape$ = caseShape$ [c]
    id$ = caseId$ [c]

    # THE TITLE IS ASCII ON PURPOSE. Praat sets WM_NAME only for a title that
    # is representable in Latin-1; the wizard pages carry em dashes and so
    # have no WM_NAME at all, which makes `xdotool search --name` blind to
    # them (GUI_HARNESS_RECIPE §11). A probe written with a non-ASCII title
    # would measure the lookup, not the law.
    beginPause: "TABWALK " + id$

    if shape$ = "nofields4"
        comment: "No editable field in this dialog."
        comment: "Four buttons."
    elsif shape$ = "fields2"
        sentence: "Output folder", "/tmp"
        word: "File name", "figure"
    elsif shape$ = "fields6"
        optionmenu: "Graph type", 1
            option: "Alpha"
            option: "Beta"
        sentence: "Title", ""
        sentence: "Subtitle", ""
        optionmenu: "Color mode", 1
            option: "Color"
            option: "Black and White"
        positive: "Figure width (inches)", "6.5"
        positive: "Figure height (inches)", "4.5"
    elsif shape$ = "bools3"
        boolean: "Annotate results on graph", 1
        boolean: "Show nonsignificant", 0
    elsif shape$ = "folder2"
        folder: "Output folder", "/tmp"
        word: "File name", "figure"
    elsif shape$ = "deftest"
        sentence: "Alpha", "a"
        sentence: "Beta", "b"
    else
        comment: "No editable field, one button."
    endif

    # The button rows mirror the real dialogs, defaults included, because the
    # default is the other candidate explanation for where Return lands.
    if shape$ = "nofields4"
        clicked = endPause: "Done", "Save", "Exp CSV", "Redraw", 4, 0
    elsif shape$ = "fields2"
        clicked = endPause: "Go Back", "Save", 2, 1
    elsif shape$ = "fields6"
        clicked = endPause: "Go Back", "Quit", "Advanced", "Draw", 4, 1
    elsif shape$ = "bools3"
        clicked = endPause: "Go Back", "Quit", "Draw", 3, 1
    elsif shape$ = "folder2"
        clicked = endPause: "Go Back", "Save", 2, 1
    elsif shape$ = "deftest"
        clicked = endPause: "Alpha", "Bravo", "Charlie", 3, 1
    else
        clicked = endPause: "OK", 1, 0
    endif

    appendFileLine: outPath$, "RESULT ", id$, " clicked=", clicked
endfor

appendFileLine: outPath$, "TABWALK DONE"
