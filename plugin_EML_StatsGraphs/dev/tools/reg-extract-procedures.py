#!/usr/bin/env python3
# reg-extract-procedures.py -- enumerate every `procedure` definition in the
# plugin tree and write dev/tools/procs.json.
#
# This is the ground-truth instrument behind the EML_PROCEDURE_REGISTRY.md
# reconciliation. A registry row is only defensible if a real definition backs
# it; this walks the tree and records (name, line) per file so the claim can be
# regenerated on demand instead of remembered.
#
# Paths resolve from this file's location, so the tool works from wherever the
# plugin tree is checked out.

import os, re, json, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
# Praat procedure definition: "procedure name: args" or "procedure name"
# must be at line start (possibly indented) and not inside a comment.
pat = re.compile(r'^\s*procedure\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::|$)')
res = {}
for dirpath, dirnames, filenames in os.walk(ROOT):
    for fn in sorted(filenames):
        if not fn.endswith(".praat"):
            continue
        p = os.path.join(dirpath, fn)
        rel = os.path.relpath(p, ROOT)
        names = []
        for i, line in enumerate(open(p, encoding="utf-8", errors="replace"), 1):
            s = line.strip()
            if s.startswith("#") or s.startswith(";"):
                continue
            m = pat.match(line)
            if m:
                names.append((m.group(1), i))
        if names:
            res[rel] = names
json.dump(res, open(os.path.join(HERE, "procs.json"), "w"), indent=1)
print("root: %s" % ROOT)
print("procedure-bearing files: %d" % len(res))
for k in sorted(res):
    print("  %-52s %3d" % (k, len(res[k])))
for rel in sorted(res):
    ns = res[rel]
    internal = [n for n, _ in ns if n.startswith("eml_") or n.startswith("_")]
    print("%-52s %3d  (internal-by-name: %d)" % (rel, len(ns), len(internal)))
