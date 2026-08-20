#!/usr/bin/env python3
"""
recorder_census.py -- which display settings a recorded script carries.

Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later

WHY THIS FILE EXISTS AT ALL. The recorder's coverage gap was quoted for weeks
as "41 settings seeded, 13 written, 28 not", and the numbers lived only in a
sentence of prose -- no script, no artefact, nothing to re-run. A number
nobody can reproduce cannot be checked, cannot go stale visibly, and cannot
be argued with. This is that measurement, committed, so the question is asked
of the tree instead of of a document.

WHAT IS COUNTED, exactly, because the boundary is the whole argument:

  SEEDED   one bare global assigned at four-space indent inside
           @emlInitDrawingDefaults. That block's job is to seed every global
           the draw layer reads, and it is kept honest by the draw layer
           crashing when one is missing -- which is what makes it a
           defensible frame. It is NOT the form's frame: `emlShowAxisNames`
           is one dialog field but two globals here, and this count follows
           the globals.

  EMITTED  the setting is ASSIGNED, at the start of a line, in a script the
           recorder actually produced.

THE SECOND HALF IS THE PART THAT WAS WRONG BEFORE. The original measurement
asked whether the RECORDER'S SOURCE mentions a name, which over-counts: the
recorder can name something it never writes. Measured from emitted scripts
instead, two names drop out -- emlDrawnMinX and emlLegendSepActive are spoken
of in eml-record.praat and appear in no emitted script -- and one that the
proxy missed appears. The totals happen to land one apart (13 against 14),
which is a coincidence and not a confirmation.

The population depends on which scripts are on disk: a setting only shows as
emitted if some committed recording exercised the figure that carries it. So
this measures a FLOOR, and the file says so rather than implying otherwise.

    python3 validate/tools/recorder_census.py
    python3 validate/tools/recorder_census.py --list
"""
import glob
import re
import sys

DEFAULTS = "plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat"
EMITTED_GLOBS = [
    "harness/linetree/out/*_emitted.utf8.praat",
    "harness/record*/out/**/*.praat",
]

# Bookkeeping rather than a choice the user made: the drawn extent the save
# panel reads back, the panel counter, and two internal keys. They are in the
# seeded population because they are seeded; they are not what the
# state-publication work is about.
BOOKKEEPING = {
    "emlDrawnMaxX", "emlDrawnMaxY", "emlDrawnMinX", "emlDrawnMinY",
    "emlPagePanelN", "emlBarData_key$", "emlCatMeasuredKey$",
    "emlAlphaBgDisclosed", "emlLegendSepActive",
}


def seeded():
    src = open(DEFAULTS, encoding="utf-8", errors="replace").read()
    m = re.search(r"procedure emlInitDrawingDefaults(.*?)\nendproc", src, re.S)
    if not m:
        sys.exit("recorder_census: @emlInitDrawingDefaults not found in "
                 + DEFAULTS + " -- it was renamed or reflowed; fix this "
                 "script rather than trusting a zero.")
    return sorted(set(re.findall(r"^\s{4}([A-Za-z][A-Za-z0-9_]*\$?)\s*=",
                                 m.group(1), re.M)))


def emitted_texts():
    out = []
    for g in EMITTED_GLOBS:
        for f in glob.glob(g, recursive=True):
            try:
                out.append(open(f, encoding="utf-8", errors="replace").read())
            except OSError:
                pass
    return out


def main():
    names = seeded()
    texts = emitted_texts()
    if not texts:
        sys.exit("recorder_census: no emitted scripts found -- drive "
                 "harness/linetree or harness/record first, or the answer "
                 "below would be 'nothing is emitted', which is a lie about "
                 "the recorder rather than a fact about it.")
    hit = {n for n in names
           if any(re.search(r"(?m)^\s*" + re.escape(n) + r"\s*=", t)
                  for t in texts)}
    miss = [n for n in names if n not in hit]
    choices = [n for n in miss if n not in BOOKKEEPING]

    print("recorder census -- read from %d emitted script(s)" % len(texts))
    print("  seeded in @emlInitDrawingDefaults : %d" % len(names))
    print("  assigned in an emitted script     : %d" % len(hit))
    print("  not emitted                       : %d" % len(miss))
    print("  of those, real user choices       : %d" % len(choices))
    if "--list" in sys.argv:
        print("\nEMITTED")
        for n in sorted(hit):
            print("   ", n)
        print("\nNOT EMITTED -- user choices")
        for n in sorted(choices):
            print("   ", n)
        print("\nNOT EMITTED -- bookkeeping")
        for n in sorted(set(miss) - set(choices)):
            print("   ", n)


if __name__ == "__main__":
    main()
