#!/usr/bin/env python3
# ============================================================================
# harness/linetree/palette.py — how many series are actually on the page
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE QUESTION THIS ANSWERS. "Seven series were drawn" is a claim about ink,
# not about a variable. The plugin's colour palette gives each series its own
# hue -- eight of them, Okabe-Ito, in @emlSetColorPalette -- so counting the
# DISTINCT CHROMATIC COLOURS on a figure counts the series that reached the
# page. A dropped seventh column changes that count by one, and nothing else
# on the figure is chromatic: the frame, the gridlines, the ticks and every
# label are neutral grey or black.
#
# WHY "CHROMATIC" AND NOT A LIST OF HEXES. The exact 8-bit value a palette
# entry lands on is Praat's rounding of a float triple and then the PNG
# writer's, and this file has no business asserting what that arithmetic
# produces. It asserts the property that matters -- a pixel whose channels
# differ from one another is series ink -- and REPORTS the hexes it found so
# the reader can see them. A threshold of 25 on (max - min) clears
# anti-aliasing of black text on white, which is neutral by construction.
#
# MIN_PX exists because anti-aliasing along a coloured stroke produces a long
# tail of one-off blends. A series stroked across a 6-inch panel at 300 dpi
# is thousands of pixels of its own colour; a blend is tens.
#
# Output: TSV on stdout, key<TAB>value, one row per fact.
# ============================================================================
import sys

MIN_PX = 300
CHROMA = 25


def main(path):
    try:
        from PIL import Image
    except ImportError:
        print("palette_error\tPIL missing")
        return 1
    im = Image.open(path).convert("RGB")
    w, h = im.size
    # getcolors() rather than getdata(): one pass in C, no Python-level
    # tuple stream, and no deprecation. maxcolors is generous enough that a
    # 300-dpi figure never overflows it and returns None.
    counts = im.getcolors(maxcolors=1 << 22)
    if counts is None:
        print("palette_error\ttoo many colours")
        return 1
    chromatic = {}
    for n, (r, g, b) in counts:
        if max(r, g, b) - min(r, g, b) >= CHROMA and n >= MIN_PX:
            chromatic["#%02X%02X%02X" % (r, g, b)] = n
    print("png_px\t%dx%d" % (w, h))
    print("chromatic_colours\t%d" % len(chromatic))
    for hexv, n in sorted(chromatic.items(), key=lambda kv: -kv[1]):
        print("colour_%s\t%d" % (hexv, n))
    # WHERE THE INK IS, IN TEN HORIZONTAL BANDS. The series fixtures put each
    # series in its own value band, so a band with no chromatic ink in it is a
    # series that is not on the page -- which is how "the seventh is drawn" is
    # checked without trusting the colour census alone.
    px = im.load()
    bands = [0] * 10
    for y in range(h):
        b = min(9, y * 10 // h)
        for x in range(w):
            r, g, bl = px[x, y]
            if max(r, g, bl) - min(r, g, bl) >= CHROMA:
                bands[b] += 1
    print("chromatic_bands\t%s" % ",".join(str(v) for v in bands))
    print("chromatic_bands_nonempty\t%d" % sum(1 for v in bands if v > 200))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
