# ============================================================================
# Demo window probe — run this from the Praat Script window, NOT with --run
# ============================================================================
# One question: on Praat 6.6/7.0, does demoWaitForInput() actually wait when
# a script is Run interactively?
#
# It matters because the implementation changed. Up to 6.4.x, demoWaitForInput
# ran a nested event loop and the C++ stack stayed inside the call. From 6.6 it
# instead halts the interpreter, unwinds all the way back to Praat's main event
# loop, and resumes from the top when a click or key arrives. That is fine
# interactively — but it means `praat --run script.praat` no longer waits at
# all: the interpreter returns, and --run quits when the interpreter returns.
# Confirmed on 6.6.30 in the sandbox: the script printed its first two lines
# and exited 0 without waiting.
#
# If interactive Run waits, a scripted spreadsheet editor in the Demo window is
# viable and we simply document "run from the Script window". If it does not,
# the whole direction is dead on 6.6+.
#
# HOW TO RUN
#   Praat > New Praat script (or open this file), then Run > Run.
#   Do NOT use praat --run.
#
# WHAT TO DO
#   A grid of nine boxes appears. Click three of them, then press any key.
#
# WHAT TO REPORT
#   The Info window text, verbatim. It records what it observed at each step.
# ============================================================================

writeInfoLine: "Demo window probe"
appendInfoLine: "Praat version: ", praatVersion$
appendInfoLine: "macintosh=", macintosh, " windows=", windows, " unix=", unix
appendInfoLine: ""

demo Erase all
demoWindowTitle: "EML probe — click three boxes, then press a key"
demo Select inner viewport: 0, 100, 0, 100
demo Axes: 0, 100, 0, 100

# --- draw a 3x3 grid -------------------------------------------------------
procedure drawGrid: .hlRow, .hlCol
    demo Erase all
    demo Select inner viewport: 0, 100, 0, 100
    demo Axes: 0, 100, 0, 100
    demo Times
    demo 18
    for .r from 1 to 3
        for .c from 1 to 3
            .x1 = 10 + (.c - 1) * 27
            .x2 = .x1 + 25
            .y1 = 70 - (.r - 1) * 27
            .y2 = .y1 + 25
            if .r = .hlRow and .c = .hlCol
                demo Paint rectangle: "{0.85, 0.93, 0.99}", .x1, .x2, .y1, .y2
            endif
            demo Colour: "Black"
            demo Draw rectangle: .x1, .x2, .y1, .y2
            demo Text: (.x1 + .x2) / 2, "centre", (.y1 + .y2) / 2, "half",
            ... "r" + string$ (.r) + "c" + string$ (.c)
        endfor
    endfor
    demo Text: 50, "centre", 92, "half", "click three boxes, then press a key"
endproc

@drawGrid: 0, 0
demoShow ()

appendInfoLine: "Window drawn. If you are reading this line and the Demo"
appendInfoLine: "window is visible and the script has NOT ended, the wait"
appendInfoLine: "is about to be tested."
appendInfoLine: ""

nClicks = 0
nKeys = 0
guard = 0

while nKeys = 0 and guard < 50
    guard = guard + 1
    demoWaitForInput ()
    if demoClicked ()
        # Re-establish the axes before reading coordinates: demoX/demoY map
        # through whatever graphics state is current at the moment you ask,
        # not the state at the moment of the click.
        demo Select inner viewport: 0, 100, 0, 100
        demo Axes: 0, 100, 0, 100
        x = demoX ()
        y = demoY ()
        col = 0
        row = 0
        for c from 1 to 3
            if x >= 10 + (c - 1) * 27 and x < 10 + (c - 1) * 27 + 25
                col = c
            endif
        endfor
        for r from 1 to 3
            if y >= 70 - (r - 1) * 27 and y < 70 - (r - 1) * 27 + 25
                row = r
            endif
        endfor
        nClicks = nClicks + 1
        appendInfoLine: "click ", nClicks, ": x=", fixed$ (x, 2),
        ... " y=", fixed$ (y, 2), "  -> cell r", row, "c", col
        @drawGrid: row, col
        demoShow ()
    elsif demoKeyPressed ()
        nKeys = nKeys + 1
        appendInfoLine: "key: """, demoKey$ (), """  unicode=",
        ... unicode (demoKey$ ())
    endif
endwhile

appendInfoLine: ""
appendInfoLine: "RESULT"
appendInfoLine: "  clicks seen: ", nClicks
appendInfoLine: "  keys seen:   ", nKeys
if nClicks = 0 and nKeys = 0
    appendInfoLine: "  VERDICT: demoWaitForInput did NOT wait. Demo-window"
    appendInfoLine: "           interaction is not usable on this build."
else
    appendInfoLine: "  VERDICT: demoWaitForInput waits and reports input."
    appendInfoLine: "           A scripted grid editor is viable here."
endif
appendInfoLine: ""
appendInfoLine: "Also worth noting: did clicking a box highlight the RIGHT box?"
appendInfoLine: "If the highlight tracked your clicks, hit-testing is accurate"
appendInfoLine: "and the cell-selection layer will work."

demo Erase all
