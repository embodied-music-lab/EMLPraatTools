#!/usr/bin/env python3
# reg-list-names.py -- print the procedure NAMES per registry-documented file,
# from procs.json (run reg-extract-procedures.py first).
#
# Counts alone cannot catch the Wizard-style drift where the documented count
# is right by accident while the names are a superseded architecture. Names are
# the only level at which registry rows reconcile against the source tree.

import json, os
import json
HERE = os.path.dirname(os.path.abspath(__file__))
d = json.load(open(os.path.join(HERE, "procs.json")))
for f in ["scripts/eml-wizard.praat","stats/eml-inferential.praat",
          "stats/eml-core-descriptive.praat","stats/eml-extract.praat",
          "stats/eml-output.praat","graphs/eml-draw-procedures.praat",
          "graphs/eml-annotation-procedures.praat","graphs/eml-graphs-form.praat",
          "dev/tests/eml-test-helpers.praat","stats/eml-core-utilities.praat",
          "scripts/eml-batch-process.praat","graphs/eml-graph-procedures.praat"]:
    ns = d.get(f)
    if ns is None:
        print("%s :: ABSENT" % f); continue
    print("\n== %s  (%d)" % (f, len(ns)))
    print("   " + ", ".join(n for n,_ in ns))
