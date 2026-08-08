#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# GEOMETRY FROM THE RENDERED PIXELS.
#
#   harness/legend/measure.py <figure.png> [frame-search-row-limit]
#
# Prints one tab-separated line:
#
#   imgW imgH frameL frameT frameR frameB \
#   inkLeft inkRight inkAbove inkBelow edgeR edgeB inkDark
#
# and exits 1 with FRAME_NOT_FOUND on stdout if no plot frame could be
# located, so the driver records a verdict rather than a row of NAs that
# reads like a measurement.
#
# WHY THIS EXISTS RATHER THAN READING THE SCRIPT'S OWN NUMBERS.
# harness/stress_cases/legend_cap.praat converts @emlDrawLegend's reported box
# into pixels with the same world-to-inch arithmetic the procedure used to
# compute it, which is the right check for CONTAINMENT and the wrong one for
# GEOMETRY: if the drawing and the arithmetic disagree, both sides of that
# comparison move together and it stays green. That disagreement is not
# hypothetical -- v1.23 of @emlDrawLegend measured itself at one font size and
# drew itself at another, so the box the caller was told about was not the box
# on the page, and it "looked right" because the whole legend moved together.
# So the frame here is found by looking at the ink.
#
# HOW THE FRAME IS FOUND. @emlDrawAxes draws the inner box as four lines in
# the theme's axis colour ({0.3, 0.3, 0.3} -> 76/255), and nothing else in the
# figure is a straight dark run more than half the image wide. So: threshold
# at 50% grey, take the LONGEST RUN of dark pixels in each row and in each
# column, and keep the rows/columns whose longest run is at least half the
# image's width/height. The first and last of those are the frame's edges.
#
# THE OPTIONAL ROW LIMIT, and why it exists. "At least half the image" is a
# statement about a figure whose image IS the plot panel, and every figure in
# blocks 1 and 2 is one. A figure carrying a comparison-matrix panel is not:
# the saved image is the panel PLUS the matrix band, so on a 6 x 4 with a
# four-group matrix the image is 2072 px tall while the frame's vertical edges
# are still 934 px, and the frame stops being found at all. The row limit
# confines the frame SEARCH to the plot panel — the caller passes the panel's
# own height in pixels — so the fraction goes on measuring the same thing it
# always measured. Passing no limit searches the whole image, which is what
# every case without a matrix does, so those numbers are untouched.
#
# The ink bands below are ALWAYS counted over the whole image, limit or not.
# The matrix band's ink belongs in `below`, and a measurement that quietly
# stopped at the limit would report a figure with a matrix as a figure
# without one.
#
# Thresholding at 50% rather than at "not white" is deliberate. The gridlines
# are {0.85, ...} and {0.90, ...} and the legend border is {0.7, 0.7, 0.7};
# all three are lighter than the threshold, so a full-width gridline cannot be
# mistaken for the frame. The greyscale palette's darkest fill is 0.10, which
# IS dark -- but a violin body is a fraction of an inch wide and never
# approaches half the image.
#
# INK is counted with the same dark threshold, in four bands OUTSIDE the frame
# rectangle, made disjoint so that each pixel is counted once:
#
#     above   y < frameT                          (title lives here)
#     below   y > frameB                          (x label, tick labels)
#     left    x < frameL, frameT <= y <= frameB    (y label, tick labels)
#     right   x > frameR, frameT <= y <= frameB    (nothing, today)
#
# The right band is the one that carries the argument. Today the plugin draws
# the legend INSIDE the plot frame, so the strip to the right of the frame is
# blank in every figure that does not trip D135 -- and is not blank in the two
# that do.
#
# edgeR / edgeB are dark pixels in the image's last column and last row: ink
# against the edge of the canvas is ink that was CLIPPED, which is what a box
# running off the page looks like once the PNG is written.
#
# Stdlib only, and no image library: ImageMagick decodes the PNG to raw 8-bit
# grey on stdout and this reads the bytes. The repo already depends on
# ImageMagick for every other pixel measurement.
# ---------------------------------------------------------------------------
import subprocess
import sys

DARK = 128          # 8-bit grey below this counts as ink
FRAME_FRACTION = 0.5  # a frame edge spans at least this much of the image


def load_gray(path):
    dim = subprocess.run(["identify", "-format", "%w %h", path],
                         capture_output=True, text=True, check=True)
    w, h = (int(v) for v in dim.stdout.split())
    raw = subprocess.run(["convert", path, "-colorspace", "Gray",
                          "-depth", "8", "gray:-"],
                         capture_output=True, check=True).stdout
    if len(raw) != w * h:
        raise SystemExit("measure.py: %s decoded to %d bytes, expected %d"
                         % (path, len(raw), w * h))
    return w, h, raw


def longest_run_rows(w, h, raw, limit):
    """Longest run of dark pixels in each row, rows [0, limit)."""
    out = []
    for y in range(limit):
        row = raw[y * w:(y + 1) * w]
        best = run = 0
        for v in row:
            if v < DARK:
                run += 1
                if run > best:
                    best = run
            else:
                run = 0
        out.append(best)
    return out


def longest_run_cols(w, h, raw, limit):
    """Longest run of dark pixels in each column, rows [0, limit)."""
    run = [0] * w
    best = [0] * w
    for y in range(limit):
        base = y * w
        for x in range(w):
            if raw[base + x] < DARK:
                run[x] += 1
                if run[x] > best[x]:
                    best[x] = run[x]
            else:
                run[x] = 0
    return best


def main():
    if len(sys.argv) not in (2, 3):
        raise SystemExit("usage: measure.py <figure.png> [row-limit]")
    path = sys.argv[1]
    w, h, raw = load_gray(path)
    limit = int(sys.argv[2]) if len(sys.argv) == 3 else h
    limit = max(1, min(limit, h))

    rows = longest_run_rows(w, h, raw, limit)
    cols = longest_run_cols(w, h, raw, limit)
    ys = [y for y, r in enumerate(rows) if r >= FRAME_FRACTION * w]
    xs = [x for x, c in enumerate(cols) if c >= FRAME_FRACTION * limit]
    if not ys or not xs:
        print("FRAME_NOT_FOUND")
        return 1
    frame_t, frame_b = ys[0], ys[-1]
    frame_l, frame_r = xs[0], xs[-1]

    ink_above = ink_below = ink_left = ink_right = ink_dark = 0
    edge_r = edge_b = 0
    for y in range(h):
        base = y * w
        for x in range(w):
            if raw[base + x] >= DARK:
                continue
            ink_dark += 1
            if x == w - 1:
                edge_r += 1
            if y == h - 1:
                edge_b += 1
            if y < frame_t:
                ink_above += 1
            elif y > frame_b:
                ink_below += 1
            elif x < frame_l:
                ink_left += 1
            elif x > frame_r:
                ink_right += 1

    print("\t".join(str(v) for v in (
        w, h, frame_l, frame_t, frame_r, frame_b,
        ink_left, ink_right, ink_above, ink_below,
        edge_r, edge_b, ink_dark)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
