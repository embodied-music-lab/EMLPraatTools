#!/usr/bin/env python3
# ============================================================================
# harness/wizardback/selected_row.py — which row of an OPEN popup is the
#                                       CURRENTLY SELECTED one, read-only
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# popup.py answers "where are the rows" for a click. This answers a
# different, read-only question: of the rows a popup shows, which one is
# already selected -- with NOTHING clicked and nothing changed. The popup is
# opened, photographed, and then dismissed with Escape (which this GTK build
# closes on without picking a row -- unlike a click, which always lands on
# whatever row is under it). No optionmenu value is altered by asking.
#
# HOW A SELECTED ROW IS TOLD FROM AN ORDINARY ONE. An ordinary row is mostly
# the popup's own background with a run of dark text pixels across part of
# its width. The selected row is a full-width solid fill (the theme's
# selection colour) with the text drawn back out of it -- so, measured as
# "how much of this row's width differs from the popup background", the
# selected row comes back near 100% and every other row comes back a lot
# lower. The row with the highest fill fraction is reported as selected.
#
#     python3 selected_row.py closed.png open.png
#     selected <n>              1-based position among the rows found
#     none                      no popup found, or fewer than 2 rows found
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

MIN_POPUP_W = 40
MIN_POPUP_H = 24
MIN_ROW_PX = 8
MIN_ROW_H = 4


def load(p):
    return np.array(Image.open(p).convert("L")).astype(int)


def main():
    a, b = load(sys.argv[1]), load(sys.argv[2])
    if a.shape != b.shape:
        print("none")
        return
    diff = np.abs(a - b) > 24
    rows = np.where(diff.sum(axis=1) > 0)[0]
    cols = np.where(diff.sum(axis=0) > 0)[0]
    if rows.size == 0 or cols.size == 0:
        print("none")
        return
    y0, y1 = rows.min(), rows.max()
    x0, x1 = cols.min(), cols.max()
    if x1 - x0 < MIN_POPUP_W or y1 - y0 < MIN_POPUP_H:
        print("none")
        return

    box = b[y0:y1 + 1, x0:x1 + 1]
    width = box.shape[1]
    bg = np.bincount(box.ravel()).argmax()
    ink = (np.abs(box - bg) > 24).sum(axis=1)
    on = ink >= MIN_ROW_PX
    bands, start = [], None
    for i, v in enumerate(on):
        if v and start is None:
            start = i
        elif not v and start is not None:
            if i - start >= MIN_ROW_H:
                bands.append((start, i - 1))
            start = None
    if start is not None and len(on) - start >= MIN_ROW_H:
        bands.append((start, len(on) - 1))
    if len(bands) < 2:
        print("none")
        return

    # Fill fraction per band: the row whose CHANGED pixels span nearly the
    # full popup width is the solid-highlight one, not a text row.
    fracs = []
    for a0, a1 in bands:
        rowmax = max(ink[a0:a1 + 1].max(), 1)
        fracs.append(rowmax / float(width))
    best = int(np.argmax(fracs))
    print("selected %d" % (best + 1))
    print("fracs " + " ".join("%.2f" % f for f in fracs), file=sys.stderr)


if __name__ == "__main__":
    main()
