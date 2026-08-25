#!/usr/bin/env python3
# ============================================================================
# harness/wizardback/page_wb.py — the page reader, one band wider again
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Same contract as harness/coldstart/page.py and harness/posthocgate/
# page_wide.py: a PNG of one pause window's client area in, two lines out —
#
#     combos <y> <y> ...      the vertical centre of each optionmenu
#     buttons <x> <x> ...     the horizontal centre of each button
#
# THE BUTTON ROW IS IMPORTED, NOT REIMPLEMENTED. It comes from coldstart's
# page.py, so there is one copy of that measurement in the tree.
#
# WHY THE BAND MOVES AGAIN. coldstart scans 14 px ending 12 px from the right
# edge; posthocgate widened that to 40 px because the wizard's narrow
# select-columns page puts its arrows 12 to 40 px short of the edge. Neither is
# wide enough for the pages lane 4 changed. Measured on Praat 6.6.30 under
# Xvfb + matchbox, 25 Aug 2026, on "Two independent groups — Choose test":
#
#     Test          combo stretched to about 10 px from the right edge
#     Group order   combo stops about 40 px further in, because its longest
#                   option ("Alphabetical") is much shorter than the test rows
#
# A 40 px band sees the first and misses the second, so the page reads as
# having ONE optionmenu. A walk that then asks for the second is told the page
# does not have it, records a plan_miss, and answers nothing — which is how a
# leg about the Group order control can pass through the page without ever
# touching the control. Widening to 70 px sees both.
#
# THE WIDER THE BAND, THE MORE IT COULD MISTAKE SOMETHING ELSE FOR A CONTROL,
# so three filters stay. A run taller than 20 px is discarded (the arrow glyph
# is about 5 px tall). Only the right half of the window is scanned at all --
# every wizard page puts its prose in a left-hand column. And the bottom 70 px
# are excluded, because at this width the band reaches the BUTTON ROW and
# reads a button border as an arrow: measured, the two-group column page came
# back with a third "optionmenu" at y = 432 on a 467 px page, which is the
# Undo/Quit/Back/Continue row. coldstart's buttons() scans 40 to 64 px from the
# bottom, so 70 clears it with room.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
import importlib.util
import os
import sys

import numpy as np
from PIL import Image

_cs = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "coldstart", "page.py")
_spec = importlib.util.spec_from_file_location("cspage", _cs)
cspage = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cspage)


def combos(im):
    h, w = im.shape
    lo, hi = max(w // 2, int(w * 0.74)), max(1, w - 8)
    dark = (im[:, lo:hi] < 120).sum(axis=1)
    floor = max(1, h - 70)
    # AN ARROW IS SOLID; TEXT IS NOT. At this width the band reaches the tail
    # of a right-hand label -- "Check normality", "Clear Info window" -- and a
    # run-of-dark test alone reads those as controls, which shifts every index
    # after them. The drop arrow is a filled triangle about nine pixels across,
    # so somewhere in it there is a row of at least SOLID consecutive dark
    # pixels; a line of text at this size has almost none. That is the test.
    SOLID = 7
    band = im[:, lo:hi] < 120
    out = []
    for a, b in cspage.runs_of(dark > 0):
        if b - a > 20 or b >= floor:
            continue
        solid = False
        for y in range(a, b + 1):
            run = 0
            for v in band[y]:
                run = run + 1 if v else 0
                if run >= SOLID:
                    solid = True
                    break
            if solid:
                break
        if solid:
            out.append((a + b) // 2)
    # ONE ARROW CAN COME BACK AS TWO RUNS. The glyph is antialiased and on some
    # pages its middle row falls just above the darkness threshold, so a single
    # optionmenu reads as two "controls" six pixels apart -- which shifts every
    # later index by one and makes a plan ask the wrong menu for the wrong row.
    # Centres closer together than a row of text are therefore one control.
    merged = []
    for y in out:
        if merged and y - merged[-1] <= 12:
            merged[-1] = (merged[-1] + y) // 2
        else:
            merged.append(y)
    return merged


def main():
    im = np.array(Image.open(sys.argv[1]).convert("L")).astype(int)
    print("combos " + " ".join(str(v) for v in combos(im)))
    print("buttons " + " ".join(str(v) for v in cspage.buttons(im)))


if __name__ == "__main__":
    main()
