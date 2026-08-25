#!/usr/bin/env python3
# relerr-convert-APPLIED.py -- ONE-SHOT in-place converter. ALREADY APPLIED.
#
# THIS SCRIPT IS NOT RE-RUNNABLE. It asserts that each target line still holds
# its PRE-conversion literal before rewriting it; the conversion has been
# applied, so re-running aborts with SITE MISMATCH. That abort is the guard
# working, not a defect.
#
# It is committed as provenance -- the executable record of exactly which
# lines were rewritten and how -- not as a maintenance tool. To audit the
# current state of the assertion sites, use scan-assertion-vacuity.py.
#
# Paths resolve from this file's location.
#
import re, sys, collections, os, importlib.util

# The provenance table lives in relerr-conversion-table.py. That filename is
# hyphenated and therefore NOT importable with a plain import statement --
# loading it by path is required, not stylistic. (The original /tmp copy was
# named table.py and was imported by module name; persisting it under the
# descriptive hyphenated name silently broke that import, which is why this
# loader exists. Persistence must preserve import graphs, not just paths.)
_HERE = os.path.dirname(os.path.abspath(__file__))
_TABLE = os.path.join(_HERE, "relerr-conversion-table.py")
if not os.path.exists(_TABLE):
    sys.exit("MISSING: %s -- the provenance table is required." % _TABLE)
_spec = importlib.util.spec_from_file_location("relerr_conversion_table", _TABLE)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
SITES = _mod.SITES

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.abspath(os.path.join(HERE, "..", ".."))
BASE = os.path.join(PLUGIN, "dev", "tests", "phase2", "test-inferential-%s.praat")

def fmt_band(b):
    return "1e-9" if b == 1e-9 else "1e-5"

by_file = collections.defaultdict(list)
for s in SITES:
    by_file[s[0]].append(s)

report = []
for fkey, sites in sorted(by_file.items()):
    path = BASE % fkey
    lines = open(path, encoding="utf-8").read().split("\n")
    for f, ln, lab, old, ext, band in sites:
        i = ln - 1
        cur = lines[i]
        head = '@emlTestAssertEqualNum: "%s", %s,' % (lab, old)
        assert cur.strip().startswith(head), "SITE MISMATCH %s:%d\n  want %r\n  got  %r" % (f, ln, head, cur)
        newlit = repr(ext)
        cur2 = cur.replace('@emlTestAssertEqualNum:', '@emlTestAssertEqualRel:', 1)
        cur2 = cur2.replace('"%s", %s,' % (lab, old), '"%s", %s,' % (lab, newlit), 1)
        assert cur2 != cur
        rest = cur2.strip()[len(head.replace('Num','Rel').replace(old,newlit)):].strip()
        if rest:                       # single-line form: tolerance on same line
            parts = cur2.rsplit(",", 1)
            assert len(parts) == 2
            lines[i] = parts[0] + ", " + fmt_band(band)
            touched = [(ln, lines[i])]
        else:                          # continuation form: tolerance on next line
            lines[i] = cur2
            j = i + 1
            assert lines[j].strip().startswith("..."), "no continuation at %s:%d -> %r" % (f, ln+1, lines[j])
            parts = lines[j].rsplit(",", 1)
            assert len(parts) == 2
            lines[j] = parts[0] + ", " + fmt_band(band)
            touched = [(ln, lines[i]), (ln+1, lines[j])]
        report.append((f, ln, lab, touched))
    open(path, "w", encoding="utf-8").write("\n".join(lines))

for f, ln, lab, touched in report:
    print("%-8s %4d  %s" % (f, ln, lab))
    for tln, txt in touched:
        print("        %4d | %s" % (tln, txt))
print("converted sites:", len(report))
