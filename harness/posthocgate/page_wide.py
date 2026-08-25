#!/usr/bin/env python3
# ============================================================================
# harness/posthocgate/page_wide.py — coldstart's page reader, one band wider
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Input and output are harness/coldstart/page.py's, exactly: a PNG of one
# pause window's client area in, two lines out —
#
#     combos <y> <y> ...      the vertical centre of each optionmenu
#     buttons <x> <x> ...     the horizontal centre of each button
#
# THE BUTTON ROW IS NOT REIMPLEMENTED HERE. It is imported from
# harness/coldstart/page.py, so there is one copy of that measurement in the
# tree and this rig cannot drift away from the one v111 depends on.
#
# WHY THE COMBO BAND MOVES, MEASURED. coldstart's reader scans the 14px band
# ending 12px from the right edge, on the strength of the pages it reaches:
# on those, an optionmenu is stretched to the window and its drop arrow lands
# there. This rig walks two pages coldstart never reaches, and on one of them
# that is false. Measured on Praat 6.6.30 under Xvfb + matchbox, 25 Aug 2026:
#
#     Three or More Groups — Test      748 x 523   arrow at x = 722..736
#     Three+ groups — Select columns   524 x 467   arrows at x = 484..512
#
# The second page is narrow and its combos stop 12 to 40 pixels short of the
# right edge, so the 14px band is EMPTY there and the reader returns "combos"
# with nothing after it. That is not a page without optionmenus — it is a page
# with two, and a walk that believes the reader accepts whatever the two
# menus happened to be seeded with and calls it the user's answer.
#
# So the band here is (w - 40, w - 12), and a run taller than 20px is
# discarded: the arrow glyph is about 5px tall, and the wider band is close
# enough to the page's text column that a long right-aligned label could
# otherwise be read as a control.
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
    lo, hi = max(0, w - 40), max(1, w - 12)
    dark = (im[:, lo:hi] < 120).sum(axis=1)
    out = []
    for a, b in cspage.runs_of(dark > 0):
        if b - a <= 20:
            out.append((a + b) // 2)
    return out


def main():
    im = np.array(Image.open(sys.argv[1]).convert("L")).astype(int)
    print("combos " + " ".join(str(v) for v in combos(im)))
    print("buttons " + " ".join(str(v) for v in cspage.buttons(im)))


if __name__ == "__main__":
    main()
