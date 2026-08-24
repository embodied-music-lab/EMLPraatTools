# ============================================================================
# harness/coldstart/probe_objects.praat — what is in the Objects window now
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Sent into a LIVE instance that is blocked inside a pause window, with
# `praat --send`. Praat processes it in the same event loop that is showing
# the dialog, so it answers about the state the user is looking at rather
# than about a fresh process.
#
# WHY THIS IS ASKED AT ALL. A wizard branch that reaches its column page has
# rendered a page; it has not necessarily MADE the example table that page
# claims to describe. Those are two claims and the second is the one the
# cold-start family is about, so it is read from the object list rather than
# inferred from a title.
#
# It deliberately writes NOTHING to the Info window: the Info window is
# evidence in some legs, and a probe that clears it destroys what it came to
# look at.
#
# /home/claude/repo/harness/coldstart/out/work/e_regress/objects.txt is replaced by run.sh with the file to write.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

csOut$ = "/home/claude/repo/harness/coldstart/out/work/e_regress/objects.txt"
csText$ = ""

nocheck select all
csN = numberOfSelected ()
if csN = 0
    csText$ = "(objects window empty)"
else
    for csI from 1 to csN
        csText$ = csText$ + selected$ (csI)
        if csI < csN
            csText$ = csText$ + newline$
        endif
    endfor
endif

# AND WHAT THE INFO WINDOW SAYS. A command that needs no table at all --
# 'Record script' is three of them -- answers the cold start by printing a
# sentence and finishing. With no dialog and no error there is nothing else
# to read, and "it exited" on its own is not evidence that it did the right
# thing. `info$ ()` returns the window's contents without disturbing them.
writeFile: csOut$, csText$ + newline$ + "== INFO ==" + newline$ + info$ ()
