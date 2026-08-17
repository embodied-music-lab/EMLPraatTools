#!/usr/bin/env python3
# ============================================================================
# menu_label_ocr.py -- read a Praat menu photograph, including the row the
#                      walk has highlighted
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. A GTK menu item has no X window and no queryable
# property, so a harness that walks the New menu can report which DIALOG it
# arrived at and nothing about the label it passed through. The label exists
# in exactly one machine-readable place: the pixels. tesseract reads them --
# but tesseract's page segmentation drops the SELECTED row, and the selected
# row is the only one whose identity the walk is claiming. White text on the
# GTK selection blue is a block the layout analyser treats as an image, so a
# whole-page pass returns the twenty rows nobody is asking about and a line
# of noise where the answer is.
#
# So this reads the photograph twice. The whole page, which is the general
# transcript and is what a reader looks at; and then every horizontal band
# painted in the selection colour, cropped out and passed to tesseract on its
# own, where there is no competing layout to analyse and the row reads
# cleanly. The second pass is the stronger evidence of the two: it does not
# say "this label is somewhere on this screen", it says "this label is on the
# row the walk highlighted".
#
# Output is one text stream: the whole-page transcript, then a marker line,
# then one section per highlighted band with its pixel bounds. Both halves go
# into the committed MENU_OCR.txt, so a reader with no tesseract -- CI, for
# one -- has the same two readings the drive had.
#
#     python3 validate/tools/menu_label_ocr.py <png>            > MENU_OCR.txt
#
# Exit 0 on success. Exit 2 if tesseract or PIL is missing, so a caller can
# tell "the label was not there" from "nothing looked".
# ============================================================================
import subprocess
import sys
import tempfile
import os

# The GTK Adwaita selection colour, measured off the photographs this reads:
# every selected menu row in the 6.6.30 Xvfb captures is #3584E4 flat, with
# antialiasing only at the glyph edges. The tolerance is for the edges, and
# is far tighter than the distance to any other flat colour on the screen.
SEL = (0x35, 0x84, 0xE4)
TOL = 24

# A band has to be a MENU ROW rather than a few stray pixels of the same hue:
# the highlighted menubar title at the top left is 60-odd pixels wide, an
# open menu row is several hundred. 150 is between the two and not near
# either.
MIN_RUN = 150
PAD = 3

MARKER = "---- highlighted rows, cropped and read separately ----"


def die(msg):
    sys.stderr.write("menu_label_ocr: %s\n" % msg)
    sys.exit(2)


def tesseract(path):
    try:
        r = subprocess.run(["tesseract", path, "-"], capture_output=True)
    except FileNotFoundError:
        die("tesseract is not on PATH")
    if r.returncode != 0:
        die("tesseract failed on %s: %s"
            % (path, r.stderr.decode("utf-8", "replace").strip()))
    return r.stdout.decode("utf-8", "replace")


def bands(im):
    """Horizontal runs of the selection colour, as (y0, y1, x0, x1)."""
    w, h = im.size
    px = im.load()
    out = []
    cur = None
    for y in range(h):
        n = 0
        x0, x1 = w, -1
        for x in range(w):
            r, g, b = px[x, y]
            if (abs(r - SEL[0]) <= TOL and abs(g - SEL[1]) <= TOL
                    and abs(b - SEL[2]) <= TOL):
                n += 1
                if x < x0:
                    x0 = x
                if x > x1:
                    x1 = x
        if n >= MIN_RUN:
            if cur is None:
                cur = [y, y, x0, x1]
            else:
                cur[1] = y
                cur[2] = min(cur[2], x0)
                cur[3] = max(cur[3], x1)
        elif cur is not None:
            out.append(tuple(cur))
            cur = None
    if cur is not None:
        out.append(tuple(cur))
    return out


def main():
    if len(sys.argv) != 2:
        die("usage: menu_label_ocr.py <png>")
    png = sys.argv[1]
    if not os.path.isfile(png):
        die("no such file: %s" % png)
    try:
        from PIL import Image
    except ImportError:
        die("PIL is not importable")

    sys.stdout.write(tesseract(png))

    im = Image.open(png).convert("RGB")
    w, h = im.size
    found = bands(im)
    sys.stdout.write("\n%s\n" % MARKER)
    if not found:
        sys.stdout.write("(no row on this screen is painted the selection "
                         "colour)\n")
        return
    tmp = tempfile.mkdtemp(prefix="emlocr")
    try:
        for i, (y0, y1, x0, x1) in enumerate(found):
            cx0 = max(0, x0 - PAD)
            cy0 = max(0, y0 - PAD)
            cx1 = min(w, x1 + 1 + PAD)
            cy1 = min(h, y1 + 1 + PAD)
            crop = os.path.join(tmp, "band%d.png" % i)
            im.crop((cx0, cy0, cx1, cy1)).save(crop)
            sys.stdout.write("[band %d  %dx%d+%d+%d]\n"
                             % (i + 1, cx1 - cx0, cy1 - cy0, cx0, cy0))
            sys.stdout.write(tesseract(crop))
    finally:
        for f in os.listdir(tmp):
            os.unlink(os.path.join(tmp, f))
        os.rmdir(tmp)


if __name__ == "__main__":
    main()
