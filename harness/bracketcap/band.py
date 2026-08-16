#!/usr/bin/env python3
# ============================================================================
# harness/bracketcap/band.py — crop the caption band out of a rendered figure
#                              and measure the ink in it
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Called once per leg by bracketcap.sh. Takes the band the plugin SAYS it drew
# (in inches, off the extent tracker and the caption's own outputs) and the
# file that was actually written, converts inches to pixels with the scale the
# FILE implies rather than an assumed 300 dpi, and reports three things.
#
#   ink_px      how many dark pixels are inside the band. A band with the
#               right height and nothing in it makes the PNG taller and the
#               file bigger, and a size threshold reads a bigger file as more
#               evidence -- which is exactly how a 52 KB empty frame sailed
#               through a 20 KB gate elsewhere in this tree. Ink is counted
#               where the words are supposed to be.
#
#   ink_left    the leftmost and rightmost columns carrying ink, IN THE BAND.
#   ink_right   Both, because clipping takes the tail off the RIGHT: a caption
#               too wide for the canvas renders its opening words in exactly
#               the place a correct caption's opening words go, so first-ink
#               position is the one measurement that cannot see it and that
#               looks best on the worst case. ink_right against the image
#               width is the measurement that can.
#
# It also writes the cropped band as a PNG, upscaled, for tesseract. The
# upscale is not cosmetic: at 300 dpi an 8 pt caption is about 33 px tall and
# tesseract is materially worse below roughly 50.
#
# Usage: band.py <png> <extentMinYin> <extentMaxYin> <capTopIn> <capBottomIn>
#                <bandOutPng>
# Prints key<TAB>value lines on stdout.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
import sys
from PIL import Image


def num(s, default=0.0):
    try:
        return float(s)
    except (TypeError, ValueError):
        return default


def main():
    png, e0, e1, c0, c1, out = sys.argv[1:7]
    ext_min = num(e0)
    ext_max = num(e1)
    cap_top = num(c0)
    cap_bot = num(c1)

    im = Image.open(png).convert("L")
    w, h = im.size
    print("img_w\t%d" % w)
    print("img_h\t%d" % h)

    # NOTHING TO CROP IS NOT AN ERROR AND IS NOT SILENCE. A leg where no
    # caption was drawn (two groups, or a non-significant omnibus) has
    # cap_top == cap_bot, and the right answer is zero ink reported plainly --
    # not a crash, and not a band invented out of a default.
    if ext_max <= ext_min or cap_bot <= cap_top:
        print("ink_px\t0")
        print("ink_left\t-1")
        print("ink_right\t-1")
        print("band_top_px\t-1")
        print("band_bottom_px\t-1")
        return

    # Inches -> pixels from the scale the FILE implies. If the export were
    # cropping the band off, this scale would be wrong and the band would land
    # past the bottom of the image -- which is caught below rather than
    # clamped away into a passing zero.
    scale = h / (ext_max - ext_min)
    top = int(round((cap_top - ext_min) * scale))
    bot = int(round((cap_bot - ext_min) * scale))

    print("band_top_px\t%d" % top)
    print("band_bottom_px\t%d" % bot)

    if top >= h:
        # The band the plugin says it drew is not inside the image at all.
        # That is the export-cropping failure, and it must not be reported as
        # "no ink", which is what a clamped crop would produce.
        print("ink_px\t-1")
        print("ink_left\t-1")
        print("ink_right\t-1")
        return

    bot = min(bot, h)
    top = max(top, 0)
    band = im.crop((0, top, w, bot))
    px = band.load()
    bw, bh = band.size

    # 200 on a 0-255 grey. The caption is drawn at {0.40, 0.40, 0.40}, which
    # lands near 102, and antialiasing fills the gap between that and paper
    # white -- so the threshold has to be well above the ink and well below
    # the page, not halfway.
    ink = 0
    left = -1
    right = -1
    for y in range(bh):
        for x in range(bw):
            if px[x, y] < 200:
                ink += 1
                if left < 0 or x < left:
                    left = x
                if x > right:
                    right = x
    print("ink_px\t%d" % ink)
    print("ink_left\t%d" % left)
    print("ink_right\t%d" % right)

    if bw > 0 and bh > 0:
        band.resize((bw * 3, bh * 3), Image.LANCZOS).save(out)


if __name__ == "__main__":
    main()
