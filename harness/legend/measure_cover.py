#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# DOES THE KEY SIT ON THE DATA. Measured between two renders, on the pixels.
#
#   harness/legend/measure_cover.py <control.png> <treatment.png> \
#       <frameL> <frameT> <frameR> <frameB>
#
# The four frame bounds are the plot rectangle measured off the CONTROL by
# harness/legend/measure.py, and the count is taken STRICTLY INSIDE them. See
# THE COUNT IS TAKEN INSIDE THE PLOT FRAME below for why.
#
# Prints one tab-separated line:
#
#   dataPx coverPx diffPx
#
#     dataPx   pixels in the CONTROL that carry data ink
#     coverPx  of those, how many the treatment changed — the legend landed
#              on them. THIS IS THE NUMBER. Zero means the key covers nothing
#              it names.
#     diffPx   pixels changed anywhere in the image, data or not. Recorded as
#              the denominator that makes coverPx interpretable: a legend
#              draws a lot of new ink, and coverPx has to be read against how
#              much ink moved in total. coverPx <= diffPx is an identity, and
#              the validator checks it rather than assuming it.
#
# Exits 1 with DIM_MISMATCH on stdout if the two files are not the same size,
# because a pixel-for-pixel comparison between images of different shape is
# not a comparison. The two renders are the same figure at the same placement
# geometry, so a size difference is itself the finding.
#
# WHY A CONTROL RENDER AND NOT THE REPORTED RECTANGLES. @emlDrawLegend reports
# the box it believes it drew, and harness/legend/case.praat converts that
# report into pixels with the same arithmetic the procedure used — which is
# the right check for containment and the wrong one for OVERLAP, because if
# the drawing and the arithmetic disagree both sides move together. v1.23 of
# this same procedure measured itself at one font size and drew itself at
# another. So the question is asked of the ink: render the figure twice, once
# with the legend and once without, and look at what changed.
#
# WHAT COUNTS AS DATA INK, and why it is CHROMA and not darkness.
#
# The figure's furniture is achromatic by construction: the frame is
# {0.3, 0.3, 0.3}, the gridlines {0.85,...} and {0.90,...}, the legend's own
# border {0.7, 0.7, 0.7}, the title and every label pure black, the page
# white. The DATA is the only thing on the page drawn in a palette colour. So
# a pixel is data ink when its channels disagree — max(R,G,B) - min(R,G,B)
# above CHROMA — and no amount of grey furniture can be mistaken for it.
#
# measure.py's darkness threshold cannot answer this question: it would count
# the axis frame, every tick label and the legend's own border as "ink", and
# a legend drawn over the title would score the same as a legend drawn over
# the data.
#
# THIS IS A COLOUR-MODE MEASUREMENT AND IT SAYS SO. In greyscale mode the
# data IS achromatic and the rule above finds nothing, so a greyscale figure
# reports dataPx = 0 rather than a small wrong number. The driver renders the
# coverage cases in colour; the greyscale ink rules are measured, on their own
# terms, by case.praat's bw variants.
#
# THE COUNT IS TAKEN INSIDE THE PLOT FRAME, and that is not a convenience.
# Praat renders TEXT with subpixel antialiasing: a black glyph on white comes
# out with orange and blue fringes along its edges, and those fringe pixels
# are strongly chromatic — measured 9 Aug 2026 on the "20" of a y-axis tick
# label, (87,144,200), a chroma of 113, which is more than an antialiased
# data line. The fringes also move by a subpixel between two renders of the
# same figure, so a whole-image count reports the tick labels and the title
# as "data ink the legend covered". Two hundred and one such pixels on the
# 6 x 4 five-group line chart, none of them data and none of them near the
# legend.
#
# Inside the frame there is no text in the control — the title, both axis
# labels and every tick label are outside it — so the rule has nothing to
# catch but the data. And the data area is the only place the question is
# about: a legend at placement 1 is drawn inside the frame, and a legend that
# printed over the title would be a different defect with a different name.
#
# THE CHANGE TEST is a per-channel absolute difference above DELTA, which
# tolerates the anti-aliasing that moves by a value or two between two
# renders of the same geometry and catches anything a legend actually painted
# over. Measured 9 Aug 2026 on a five-group line chart at 6 x 4: the control
# and a placement-5 re-render of itself differ in 0 pixels, so the floor is
# exact and DELTA is protecting against nothing that happens — it is there so
# that a future anti-aliasing change does not turn a green check red for a
# reason that has nothing to do with legends.
#
# coverPx IS A LOWER BOUND WHILE THE LEGEND'S BACKGROUND IS TRANSLUCENT, and
# as of 9 August 2026 it is. eml-graph-procedures.praat draws an on-figure
# box's background at alpha 0.702 — an alpha sprite where the platform has
# one, and a STIPPLE screen on Linux, which is what this harness renders on.
# So a legend sitting on a violin leaves roughly seven pixels in ten changed
# and three still showing the data through the dots. This measure counts the
# seven.
#
# That is the right direction for every use it is put to. A count of ZERO
# still means no overlap at all: any real overlap changes the large majority
# of the pixels under it, so zero cannot be reached by a translucent box
# sitting on data. And a translucent legend is not a legend that covers less
# — the reader has a key printed over the data and data printed through the
# key — so a metric that gave it credit for the pixels it let through would
# be measuring the wrong thing in the other direction. If the background ever
# becomes fully opaque again, every number here rises and nothing about what
# they mean changes.
#
# Stdlib only; ImageMagick decodes the PNG, as in measure.py.
# ---------------------------------------------------------------------------
import subprocess
import sys

CHROMA = 40         # max-min channel spread above which a pixel is data ink
DELTA = 24          # per-channel change above which a pixel counts as changed


def load_rgb(path):
    dim = subprocess.run(["identify", "-format", "%w %h", path],
                         capture_output=True, text=True, check=True)
    w, h = (int(v) for v in dim.stdout.split())
    raw = subprocess.run(["convert", path, "-depth", "8", "rgb:-"],
                         capture_output=True, check=True).stdout
    if len(raw) != w * h * 3:
        raise SystemExit("measure_cover.py: %s decoded to %d bytes, "
                         "expected %d" % (path, len(raw), w * h * 3))
    return w, h, raw


def main():
    if len(sys.argv) != 7:
        raise SystemExit("usage: measure_cover.py <control.png> "
                         "<treatment.png> <frameL> <frameT> <frameR> "
                         "<frameB>")
    cw, ch, ctl = load_rgb(sys.argv[1])
    tw, th, trt = load_rgb(sys.argv[2])
    if (cw, ch) != (tw, th):
        print("DIM_MISMATCH")
        return 1
    fl, ft, fr, fb = (int(v) for v in sys.argv[3:7])
    # Strictly inside: the frame's own stroked edges belong to the furniture.
    x0, x1 = max(0, fl + 1), min(cw, fr)
    y0, y1 = max(0, ft + 1), min(ch, fb)
    if x0 >= x1 or y0 >= y1:
        print("EMPTY_FRAME")
        return 1

    data_px = cover_px = diff_px = 0
    for y in range(y0, y1):
        base = y * cw * 3
        for x in range(x0, x1):
            i = base + x * 3
            cr, cg, cb = ctl[i], ctl[i + 1], ctl[i + 2]
            tr, tg, tb = trt[i], trt[i + 1], trt[i + 2]
            changed = (abs(cr - tr) > DELTA or abs(cg - tg) > DELTA
                       or abs(cb - tb) > DELTA)
            if changed:
                diff_px += 1
            hi = cr if cr > cg else cg
            if cb > hi:
                hi = cb
            lo = cr if cr < cg else cg
            if cb < lo:
                lo = cb
            if hi - lo > CHROMA:
                data_px += 1
                if changed:
                    cover_px += 1

    print("\t".join(str(v) for v in (data_px, cover_px, diff_px)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
