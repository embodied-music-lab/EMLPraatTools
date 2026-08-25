#!/usr/bin/env python3
# ============================================================================
# harness/wizardback/popup.py — where the rows of an open optionmenu popup are
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#     python3 popup.py closed.png open.png
#     rows <x> <y1> <y2> ...          root coordinates, top to bottom
#     none                            no popup found between the two shots
#
# WHY CLICKING THE ROW IS THE ONLY RECIPE THAT WORKS FOR A SECOND OPTIONMENU.
#
# Measured on this Praat/GTK build, 25 Aug 2026, driving the wizard's two-group
# column page, one root capture per keystroke:
#
#   1. Clicking an optionmenu's arrow opens its popup. Clicking again closes
#      it, and the combo then takes Home / Down as DIRECT value changes with
#      the popup shut. Return does not commit — it RE-OPENS the popup, and the
#      next click lands inside it instead of on Continue. That is the "pointer
#      grab" harness/posthocgate documents and works around by not driving this
#      page at all.
#   2. That keyboard recipe drives the FIRST optionmenu on a page and no other.
#      Photographed: set Data column to row 3 (Loud) — correct — then run the
#      identical recipe on the Group column asking for row 2, and what changes
#      is DATA COLUMN, to Pitch. Group column never moves. Clicking a second
#      optionmenu opens and closes its popup without ever taking keyboard
#      focus, so every arrow key still reaches the first one.
#
# A page with two column menus is exactly what this rig has to answer, so the
# keyboard is abandoned for a mouse click on the row itself. Nothing else on
# the page can then be moved by accident, and no focus is involved.
#
# HOW THE ROWS ARE FOUND, WITHOUT PREDICTING A GEOMETRY. The popup cannot be
# photographed through `import -window <id>` while it holds the pointer grab,
# but `import -window root` DOES answer during it — measured in the same
# session. So: one root capture with the popup shut, one with it open, and the
# popup is the rectangle where they differ. Inside that rectangle a row is a
# band of pixels that are not the popup's own background — which catches an
# ordinary row by its text and the highlighted row by its fill — and the bands,
# in order, are the items. No row height, item count or popup origin is assumed
# anywhere; a theme change moves the pixels this reads, not the logic.
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

MIN_POPUP_W = 40     # a popup is at least this wide and tall; a repainted
MIN_POPUP_H = 24     # caret or a focus ring is not
MIN_ROW_PX = 8       # a row needs this many non-background pixels to count
MIN_ROW_H = 4        # and this many rows of them


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

    # THE POPUP'S OWN BACKGROUND, not the page's: the modal value inside the
    # changed rectangle. A menu is mostly background, so the mode is it.
    box = b[y0:y1 + 1, x0:x1 + 1]
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
    if not bands:
        print("none")
        return
    xmid = (x0 + x1) // 2
    print("rows %d %s" % (xmid,
                          " ".join(str(y0 + (a0 + a1) // 2) for a0, a1 in bands)))


if __name__ == "__main__":
    main()
