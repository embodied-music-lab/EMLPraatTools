#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# WHERE THE INK BELOW THE PLOT ACTUALLY IS.
#
#   harness/legend/measure_bands.py <figure.png> <panelBot> \
#       <matrixTop> <matrixBot> <legendTop> <legendBot>
#
# All five geometry arguments are ROWS OF THE SAVED PNG, and -1 means "this
# band does not exist in this figure". Prints one tab-separated line:
#
#   matrixInk legendInk strayInk belowInk inkTop inkBot
#
# WHY THIS EXISTS ALONGSIDE measure.py. measure.py answers "where is the plot
# frame and how much ink escaped it". The question here is a different one and
# it is the one the comparison-matrix work turns on: a figure can carry a
# matrix panel below the plot AND a legend band below the plot, and the two
# must not be the same pixels. measure.py's four bands are defined relative to
# the FRAME, so both of those land in `below` together and cancel out.
#
# THE BANDS, and the fact that they are disjoint by construction:
#
#   matrixInk  dark pixels in rows [matrixTop, matrixBot)
#   legendInk  dark pixels in rows [max(legendTop, panelBot), legendBot) --
#              clamped to the region below the plot panel, so a placement
#              whose legend is INSIDE the plot (1) or absent (5) reports 0
#              here rather than counting the plot's own ink
#   strayInk   dark pixels in rows >= panelBot that are in NEITHER band. Ink
#              below the plot that belongs to nothing that reported itself is
#              ink nobody made room for
#   belowInk   dark pixels in rows >= panelBot, total. matrixInk + legendInk
#              + strayInk == belowInk is an identity when the bands do not
#              overlap, and the driver records all four so the validator can
#              check that identity rather than assume it
#   inkTop     first row >= panelBot carrying any ink, -1 if none
#   inkBot     last such row, -1 if none. inkBot against the image height is
#              how "the band ran off the bottom of the file" would look
#
# A ROW THAT FALLS IN BOTH BANDS IS COUNTED AS MATRIX. The bands are
# horizontal strips, so that can only happen if they OVERLAP -- and this
# script deliberately does not adjudicate that, because a counting rule that
# tried to would be reporting its own opinion of where the legend is. Overlap
# is settled twice over by the validator instead: on the reported rectangles,
# which is arithmetic, and on matrixInk against the legend-free control,
# which is pixels.
#
# HOW COLLISION IS DETECTED, and why it is not detected here. This script
# reports one figure. Whether the LEGEND put ink inside the MATRIX band is
# answered by comparing matrixInk between a figure and the same figure drawn
# with no legend at all -- harness/legend/run.sh renders that control for
# every matrix case, and validate/v32_legend_geometry.R does the comparison.
# Measured on 8 August 2026 the two agree EXACTLY when the bands are disjoint
# (17621 px both ways on the 6 x 4 four-group case) and differ by 11636 px
# when the legend is drawn through the panel, so the comparison needs no
# tolerance and gets none.
#
# Stdlib only, ImageMagick for the decode, same as measure.py.
# ---------------------------------------------------------------------------
import subprocess
import sys

DARK = 128          # 8-bit grey below this counts as ink, as in measure.py


def load_gray(path):
    dim = subprocess.run(["identify", "-format", "%w %h", path],
                         capture_output=True, text=True, check=True)
    w, h = (int(v) for v in dim.stdout.split())
    raw = subprocess.run(["convert", path, "-colorspace", "Gray",
                          "-depth", "8", "gray:-"],
                         capture_output=True, check=True).stdout
    if len(raw) != w * h:
        raise SystemExit("measure_bands.py: %s decoded to %d bytes, "
                         "expected %d" % (path, len(raw), w * h))
    return w, h, raw


def main():
    if len(sys.argv) != 7:
        raise SystemExit("usage: measure_bands.py <figure.png> <panelBot> "
                         "<matrixTop> <matrixBot> <legendTop> <legendBot>")
    path = sys.argv[1]
    panel_bot, m_top, m_bot, l_top, l_bot = (int(v) for v in sys.argv[2:7])
    w, h, raw = load_gray(path)

    panel_bot = max(0, min(panel_bot, h))
    # An absent band is an EMPTY range rather than a special case, so the
    # counting loop below has one shape.
    if m_top < 0 or m_bot < 0:
        m_top = m_bot = 0
    if l_top < 0 or l_bot < 0:
        l_top = l_bot = 0
    else:
        l_top = max(l_top, panel_bot)
    m_top, m_bot = max(0, min(m_top, h)), max(0, min(m_bot, h))
    l_top, l_bot = max(0, min(l_top, h)), max(0, min(l_bot, h))

    matrix_ink = legend_ink = stray_ink = below_ink = 0
    ink_top = ink_bot = -1
    for y in range(panel_bot, h):
        base = y * w
        n = 0
        for x in range(w):
            if raw[base + x] < DARK:
                n += 1
        if n == 0:
            continue
        below_ink += n
        if ink_top < 0:
            ink_top = y
        ink_bot = y
        in_m = m_top <= y < m_bot
        in_l = l_top <= y < l_bot
        if in_m:
            matrix_ink += n
        elif in_l:
            legend_ink += n
        else:
            stray_ink += n

    print("\t".join(str(v) for v in (
        matrix_ink, legend_ink, stray_ink, below_ink, ink_top, ink_bot)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
