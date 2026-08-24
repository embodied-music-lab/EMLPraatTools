#!/usr/bin/env python3
# ============================================================================
# harness/coldstart/page.py — read the CONTROLS off a Praat pause window
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Input:  a PNG of one pause window's CLIENT AREA (`import -window <id>`).
# Output: two lines on stdout, both in window-relative pixels —
#
#     combos <y> <y> ...      the vertical centre of each optionmenu, in the
#                             order they appear down the page
#     buttons <x> <x> ...     the horizontal centre of each button in the
#                             bottom row, left to right
#
# WHY THIS IS MEASURED AND NOT ASSUMED. The first version of the driver
# pressed "the last button" at (W-45, H-36), on the strength of the wizard's
# first page, where the button row happens to fill the window and Continue's
# right edge lands 24px from the right. It does not generalise: the buttons
# are LEFT-packed at a fixed size, so on the 719px-wide "Compare — Observation
# type" page Continue ends at x=500 and (W-45)=674 is empty window. The walk
# clicked nothing, saw no new page, and reported the branch as stalled — a
# false RED on a branch that works. Read the row; do not predict it.
#
# HOW. Two facts about this GTK theme, measured on Praat 6.6.30 under Xvfb +
# matchbox on 24 August 2026:
#
#   * A combo's drop arrow is the only DARK thing in the 14px-wide band that
#     ends 12px from the window's right edge. Every optionmenu has one; no
#     comment, field, label or button puts ink there.
#   * Across the button row's TOP BORDER the row is mostly border grey, and
#     the only breaks in it are the gaps BETWEEN buttons and the margins at
#     each end. So the buttons are the complement of those gaps. The exact
#     height of that border varies with the window, so the rows near the
#     bottom are scanned and the one that resolves the most buttons wins,
#     rather than one row being hard-coded.
#
# Base Python plus PIL and numpy, both already required by the tree's other
# image checks.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
import sys

import numpy as np
from PIL import Image


def runs_of(mask):
    out, i, n = [], 0, len(mask)
    while i < n:
        if mask[i]:
            s = i
            while i < n and mask[i]:
                i += 1
            out.append((s, i - 1))
        else:
            i += 1
    return out


def combos(im):
    h, w = im.shape
    lo, hi = max(0, w - 26), max(1, w - 12)
    dark = (im[:, lo:hi] < 120).sum(axis=1)
    return [(a + b) // 2 for a, b in runs_of(dark > 0)]


def buttons(im):
    h, w = im.shape
    best = []
    for dy in range(40, 64):
        y = h - dy
        if y < 0:
            continue
        row = im[y, :]
        bg = np.bincount(row).argmax()
        gaps = [r for r in runs_of(row != bg) if r[1] - r[0] > 12]
        if len(gaps) < 2:
            continue
        # The buttons are what the gaps leave behind.
        cand, prev = [], 0
        for a, b in gaps:
            if a - prev > 30:
                cand.append((prev, a - 1))
            prev = b + 1
        if w - prev > 30:
            cand.append((prev, w - 1))
        if len(cand) > len(best):
            best = cand
    return [(a + b) // 2 for a, b in best]


def main():
    im = np.array(Image.open(sys.argv[1]).convert("L")).astype(int)
    print("combos " + " ".join(str(v) for v in combos(im)))
    print("buttons " + " ".join(str(v) for v in buttons(im)))


if __name__ == "__main__":
    main()
