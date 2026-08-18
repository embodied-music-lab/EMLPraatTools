#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# harness/linestyle/stroke.py -- THE INK ALONG THE STROKE, not the ink on the
#                                page.
#
#   harness/linestyle/stroke.py <figure.png>
#
# Prints key<TAB>value lines on stdout, one measurement per line, and exits 1
# with `frame frame_not_found` if no plot frame could be located -- so a
# driver records a verdict rather than a row of NAs that reads like a
# measurement. harness/legend/measure.py made that choice first; this file
# imports its frame-finding and its decoder rather than writing a second one.
#
# WHY A COUNT OF PIXELS IS NOT ENOUGH.
#
# The four styles differ in HOW MUCH ink is on the page -- a dotted line lays
# down less than a solid one -- and validate/v95 already measures that. But a
# count cannot tell Dashed from Dashed-dotted reliably, and it cannot tell a
# style that was honoured from a series that simply drew fewer points: two
# figures with the same total can be a dashed line and a shorter solid one.
# What separates the four pens is the PATTERN: where the ink stops and starts
# along the path.
#
# SO THE MEASUREMENT IS A RUN STRUCTURE, taken column by column across the
# plot interior. For each column strictly inside the frame, is there any dark
# pixel in it? That gives a binary vector along the horizontal axis, and:
#
#   ink_cols        how many columns carry ink at all
#   ink_runs        how many maximal runs of inked columns there are
#   ink_gaps        how many maximal runs of BLANK columns lie between the
#                   first and last inked column -- the holes in the stroke
#   longest_gap     the longest of those holes, in pixels
#   longest_ink_run the longest unbroken stretch of stroke
#
# A solid line crosses every column: one run, no gaps. A dotted line is
# hundreds of short runs separated by short gaps. A dashed line is fewer,
# longer runs separated by longer gaps. Dashed-dotted alternates the two, so
# its longest run is a dash while its run COUNT sits near the dotted end.
# Four pens, four signatures, and no two of them are the same shape.
#
# THE FRAME IS MEASURED TOO, and that is the other half of this file's job.
# Praat's line style is a property of the PICTURE WINDOW, so a pen left set
# does not only dash the series -- it dashes the inner box and every tick mark
# drawn after it. frame_top_run and frame_left_run are the longest dark runs
# along the frame's own top edge and left edge: on a correct figure they are
# the full width and the full height of the box, whatever the series' pen, and
# a pen that leaked collapses them to a dash.
#
# TWO THRESHOLDS, AND THE SECOND ONE IS NOT OPTIONAL. harness/legend's DARK
# is 50% grey, which is the right threshold for a frame and for a series drawn
# in a palette ink. IT CANNOT SEE THE SPAGHETTI PLOT'S STRANDS: those are
# drawn through @emlLightenColor at 0.6, which puts them at about 190 of 255 --
# lighter than DARK, so a dark-pixel count of a dotted spaghetti figure and a
# solid one comes back the same to within three pixels while three thousand
# pixels of the image have changed. So interior_any_px counts every interior
# pixel that is not paper, and that is the measurement the strand is judged on.
#
# THE RUN SIGNATURE STAYS ON THE DARK THRESHOLD, deliberately. Gridlines are
# {0.85} and {0.90}; they are not paper, so at the light threshold a vertical
# gridline fills its column from top to bottom and every figure reports every
# column inked. A count survives that -- the gridlines are identical in the
# two figures being compared -- and a run structure does not.
#
# MARKERS ARE PART OF THE STROKE'S SIGNATURE AND ARE NOT SUBTRACTED. The line
# chart draws a marker at every vertex, and a marker fills the columns it
# covers whatever the pen is doing there -- which is why a dotted line still
# reports a few hundred inked columns rather than none, and why the four
# signatures are compared with each other rather than against an ideal.
#
# Stdlib only, and no image library: ImageMagick decodes the PNG and
# harness/legend/measure.py reads the bytes.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "legend"))
import measure  # noqa: E402  -- harness/legend/measure.py


def runs(flags):
    """(count, longest) of maximal True runs in a list of booleans."""
    n = best = cur = 0
    for f in flags:
        if f:
            cur += 1
            if cur == 1:
                n += 1
            if cur > best:
                best = cur
        else:
            cur = 0
    return n, best


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: stroke.py <figure.png>")
    path = sys.argv[1]
    w, h, raw = measure.load_gray(path)
    D = measure.DARK
    # Not paper. Praat's page is 255; the lightest thing it draws on this
    # figure is a {0.90} gridline at 230.
    LIGHT = 250

    # The frame, found exactly the way harness/legend/measure.py finds it:
    # the longest dark run in each row and column, kept where it spans at
    # least half the image. Nothing else in a figure is a straight dark run
    # that long.
    rows = measure.longest_run_rows(w, h, raw, h)
    cols = measure.longest_run_cols(w, h, raw, h)
    ys = [y for y, r in enumerate(rows) if r >= measure.FRAME_FRACTION * w]
    xs = [x for x, c in enumerate(cols) if c >= measure.FRAME_FRACTION * h]
    if not ys or not xs:
        print("frame\tframe_not_found")
        return 1
    ft, fb = ys[0], ys[-1]
    fl, fr = xs[0], xs[-1]

    # The interior, strictly inside the box: the frame's own four lines are
    # not part of any series and would give every figure one full-width run.
    x0, x1 = fl + 2, fr - 1
    y0, y1 = ft + 2, fb - 1
    ink = 0
    anyink = 0
    colhit = [False] * max(0, x1 - x0)
    for y in range(y0, y1):
        base = y * w
        for x in range(x0, x1):
            v = raw[base + x]
            if v < LIGHT:
                anyink += 1
                if v < D:
                    ink += 1
                    colhit[x - x0] = True

    n_ink, longest_ink = runs(colhit)
    first = next((i for i, f in enumerate(colhit) if f), None)
    last = len(colhit) - 1 - next((i for i, f in enumerate(reversed(colhit))
                                   if f), 0) if first is not None else None
    if first is None:
        n_gap = longest_gap = 0
    else:
        inner = colhit[first:last + 1]
        n_gap, longest_gap = runs([not f for f in inner])

    out = [
        ("img_w", w), ("img_h", h),
        ("frame_l", fl), ("frame_t", ft), ("frame_r", fr), ("frame_b", fb),
        ("frame_w", fr - fl), ("frame_h", fb - ft),
        ("interior_ink_px", ink),
        ("interior_any_px", anyink),
        ("ink_cols", sum(1 for f in colhit if f)),
        ("ink_runs", n_ink),
        ("longest_ink_run", longest_ink),
        ("ink_gaps", n_gap),
        ("longest_gap", longest_gap),
        # THE FURNITURE. The frame's own edges, measured on the rows and
        # columns the frame was found on: a leaked pen breaks these.
        ("frame_top_run", rows[ft]),
        ("frame_bottom_run", rows[fb]),
        ("frame_left_run", cols[fl]),
        ("frame_right_run", cols[fr]),
    ]
    for k, v in out:
        print("%s\t%s" % (k, v))
    return 0


if __name__ == "__main__":
    sys.exit(main())
