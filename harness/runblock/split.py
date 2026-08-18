# ---------------------------------------------------------------------------
# runblock/split.py -- cut an emitted recording at its own step headings
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# An emitted script draws every figure onto one picture: there is no
# `Erase all` between steps, because a user running the whole file is running
# one workflow. Replaying ONE step therefore means rebuilding the file around
# it -- the prefix (the include block and the editable block) plus that step's
# body and nothing else -- which is what this does.
#
#   python3 split.py <emitted.praat> <cutdir>
#
# Writes cutdir/prefix.praat and cutdir/step_<N>.body, and prints
# "<N> <kind>" per step on stdout.
# ---------------------------------------------------------------------------
import sys, os, re

emitted, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
lines = open(emitted, encoding="utf-8").read().split("\n")
idx = [i for i, l in enumerate(lines) if re.match(r'^# --- Step \d+ \(', l)]
prefix = "\n".join(lines[:idx[0]]) if idx else "\n".join(lines)
open(os.path.join(outdir, "prefix.praat"), "w", encoding="utf-8").write(
    prefix + "\n")
bounds = idx + [len(lines)]
for a, b in zip(bounds, bounds[1:]):
    m = re.match(r'^# --- Step (\d+) \((\w+)\)', lines[a])
    open(os.path.join(outdir, "step_%s.body" % m.group(1)), "w",
         encoding="utf-8").write("\n".join(lines[a:b]) + "\n")
    print(m.group(1), m.group(2))
