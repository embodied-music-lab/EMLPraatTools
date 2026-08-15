#!/usr/bin/env python3
"""pngdiff.py -- compare two PNGs and print integers a validator can hold.

WHY THIS EXISTS RATHER THAN `cmp`. harness/record/roundtrip_graph.sh compares
recorded figures BYTE FOR BYTE and says, correctly, that a tolerance would
have to be justified. For the advanced figure it can be justified, and the
justification is measurable: the recorder emits a figure's resolved axis to
six decimal places, so a replayed draw maps world coordinates through an axis
that differs from the original's in the last bits. Every mark lands on the
same pixel; the ANTI-ALIASING on its edge does not. Measured on a jittered
2-group violin: 40 pixels -- one per jittered point -- differing by at most 7
of 255 in one channel, on a figure that is otherwise identical.

Byte equality therefore cannot be the test, and a byte-count comparison is
worse than none. What separates a faithful replay from one that lost its
bracket and its points is not subtle: those differ by thousands of pixels at
full contrast. So the number reported is the count of pixels differing by MORE
THAN a stated threshold, and the threshold sits in a two-order-of-magnitude
gap rather than being tuned to make a case pass.

STANDARD LIBRARY ONLY. validate/helpers.R makes the same promise for R and for
the same reason: a reviewer must be able to run this on a stock installation.
zlib and struct are enough for the 8-bit non-interlaced RGB that Praat writes.

    python3 pngdiff.py A.png B.png [threshold]
    -> "over<threshold> <n>  max <m>  pixels <total>"  on stdout, one line

Exit 0 whatever it finds. Deciding is validate/v58's job.
"""
import struct
import sys
import zlib


def read_png(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("not a PNG: %s" % path)
    pos = 8
    idat = []
    hdr = None
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if ctype == b"IHDR":
            hdr = struct.unpack(">IIBBBBB", body)
        elif ctype == b"IDAT":
            idat.append(body)
        elif ctype == b"IEND":
            break
        pos += 12 + length
    w, h, depth, colour, comp, filt, interlace = hdr
    if depth != 8 or interlace != 0 or colour not in (0, 2, 6):
        raise SystemExit("unsupported PNG shape in %s: depth=%d colour=%d "
                         "interlace=%d" % (path, depth, colour, interlace))
    channels = {0: 1, 2: 3, 6: 4}[colour]
    raw = zlib.decompress(b"".join(idat))
    stride = w * channels
    out = bytearray(h * stride)
    prev = bytearray(stride)
    pos = 0
    for y in range(h):
        ftype = raw[pos]
        pos += 1
        line = bytearray(raw[pos:pos + stride])
        pos += stride
        # The five PNG filters, undone in place. Written out rather than
        # looked up because a wrong one produces a plausible image and a
        # silently wrong comparison.
        if ftype == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif ftype == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        elif ftype != 0:
            raise SystemExit("unknown PNG filter %d in %s" % (ftype, path))
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return w, h, channels, bytes(out)


def main():
    if len(sys.argv) < 3:
        raise SystemExit("usage: pngdiff.py A.png B.png [threshold]")
    thr = int(sys.argv[3]) if len(sys.argv) > 3 else 32
    w1, h1, c1, a = read_png(sys.argv[1])
    w2, h2, c2, b = read_png(sys.argv[2])
    if (w1, h1, c1) != (w2, h2, c2):
        # A shape change is not a tolerance question. Reported as every pixel
        # differing, so a validator holding "over32 == 0" cannot pass on it.
        print("over%d %d  max 255  pixels %d" % (thr, w1 * h1, w1 * h1))
        return
    over = 0
    worst = 0
    npx = w1 * h1
    for i in range(0, len(a), c1):
        d = 0
        for k in range(min(c1, 3)):
            e = a[i + k] - b[i + k]
            if e < 0:
                e = -e
            if e > d:
                d = e
        if d > worst:
            worst = d
        if d > thr:
            over += 1
    print("over%d %d  max %d  pixels %d" % (thr, over, worst, npx))


if __name__ == "__main__":
    main()
