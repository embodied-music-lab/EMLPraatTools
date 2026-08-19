#!/usr/bin/env python3
# ============================================================================
# harness/linetree/pngdiff.py — two figures, compared in bytes and in pixels
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE CLAIM THIS EXISTS TO MEASURE. Meaning and storage are independent, so
# the same numbers under the same names must draw the same figure whether the
# file holds two measurements side by side or stacked in one column. That is
# not a claim about a variable and it is not a claim about a colour census: it
# is a claim about a file. So this compares the files.
#
# BYTES FIRST, AND THE BYTE ANSWER IS THE ONE THAT COUNTS. Two PNGs that are
# the same file are the same figure by any measure anyone could ask for. The
# pixel walk below is not a weaker substitute for it -- it is what turns a
# FAILED byte comparison into a sentence. "The two figures differ" is not a
# finding; "they differ in 9223 pixels, all of them in rows 54 to 97 of 1200,
# which is the title line" is, and it is what lets a reader see at a glance
# that the data drew identically and the caption did not.
#
# WHY THE ROW SPAN AND NOT A BOUNDING BOX. Every difference this pair can
# legitimately have is a line of text, and a line of text is a band of rows.
# A box would add two numbers that say nothing extra about the one case this
# comparison is for.
#
# Output: TSV on stdout, key<TAB>value, one row per fact. Missing PIL is
# reported as a row rather than as an exception, exactly as palette.py does:
# a harness that cannot measure must say so in the transcript, because a
# validator reading a transcript with no rows cannot tell "identical" from
# "not attempted".
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
import hashlib
import os
import sys


def digest(path):
    h = hashlib.md5()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def main(a, b):
    for p in (a, b):
        if not os.path.isfile(p) or os.path.getsize(p) == 0:
            print("diff_verdict\tMISSING")
            return 0
    da, db = digest(a), digest(b)
    print("diff_md5_a\t%s" % da)
    print("diff_md5_b\t%s" % db)
    print("diff_bytes_a\t%d" % os.path.getsize(a))
    print("diff_bytes_b\t%d" % os.path.getsize(b))
    with open(a, "rb") as fa, open(b, "rb") as fb:
        identical = fa.read() == fb.read()
    print("diff_verdict\t%s" % ("IDENTICAL" if identical else "DIFFERS"))
    if identical:
        # The pixel walk is skipped rather than run and reported as zero:
        # a byte-identical pair cannot differ in a pixel, and running it
        # anyway would invite a reader to treat the zero as the evidence.
        print("diff_pixels\t0")
        print("diff_rows\tnone")
        return 0
    try:
        from PIL import Image
    except ImportError:
        print("diff_pixels\tPIL missing")
        print("diff_rows\tPIL missing")
        return 0
    ia = Image.open(a).convert("RGB")
    ib = Image.open(b).convert("RGB")
    if ia.size != ib.size:
        print("diff_pixels\tSIZE %s vs %s" % (ia.size, ib.size))
        print("diff_rows\tSIZE")
        return 0
    pa, pb = ia.load(), ib.load()
    w, h = ia.size
    n = 0
    rows = []
    for y in range(h):
        hit = 0
        for x in range(w):
            if pa[x, y] != pb[x, y]:
                hit += 1
        if hit:
            n += hit
            rows.append(y)
    print("diff_pixels\t%d" % n)
    print("diff_total_px\t%d" % (w * h))
    if rows:
        print("diff_rows\t%d-%d of %d" % (rows[0], rows[-1], h))
        print("diff_row_count\t%d" % len(rows))
    else:
        print("diff_rows\tnone")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: pngdiff.py A.png B.png", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))
