#!/usr/bin/env python3
"""Reconcile EML_PROCEDURE_REGISTRY.md against procs.json BY NAME.

Counts alone cannot catch the Wizard-style drift where the documented
count is right by accident while the names are a superseded
architecture. Names are the only level at which registry rows
reconcile against the source tree.

Three section shapes are recognised:

  1. Documented section — has a **File:** line for a file that exists
     on disk. Every name in procs.json for that file must appear as a
     row, every row must appear in procs.json, no duplicates, and the
     header count must equal the row count. A file that exists on disk
     but contributes no procedures (procs.json omits it) must document
     zero rows and claim zero.

  2. Declared-absent section — the **File:** line carries the marker
     "NOT PRESENT IN THIS PLUGIN TREE". Names are not reconciled (there
     is no source to reconcile against), but the annotation is verified
     against the filesystem in BOTH directions: an annotated file that
     is actually present is an error, and an un-annotated file that is
     actually missing is an error. The header count must still equal
     the row count.

  3. Informational section — no **File:** line and no `@procedure` rows.
     Carries prose or a file-level table rather than procedure rows.
     A section titled "Not yet documented" additionally has its
     `| path | count |` rows reconciled against procs.json.

Usage: reg-reconcile.py <registry.md>
Exit 0 iff every section satisfies the rules for its shape.
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROCS = os.path.join(HERE, "procs.json")
ROOT = os.path.dirname(os.path.dirname(HERE))

ABSENT_MARKER = "NOT PRESENT IN THIS PLUGIN TREE"

ROW = re.compile(r'^\|\s*`@([A-Za-z_][A-Za-z0-9_]*)`\s*\|')
FILEROW = re.compile(r'^\|\s*`([A-Za-z0-9_./-]+\.praat)`\s*\|\s*(\d+)\s*\|')
FILELINE = re.compile(
    r'^\*\*File:\*\*\s+`([^`]+)`\s+\(v([0-9.]+)\)\s+—\s+(\d+)\s+procedure')


def parse(path):
    secs = []
    cur = None
    for ln in open(path, encoding="utf-8"):
        ln = ln.rstrip("\n")
        if ln.startswith("## "):
            cur = {"title": ln[3:], "file": None, "ver": None, "claim": None,
                   "absent": False, "rows": [], "filerows": []}
            secs.append(cur)
        elif cur is not None:
            m = FILELINE.match(ln)
            if m:
                cur["file"], cur["ver"] = m.group(1), m.group(2)
                cur["claim"] = int(m.group(3))
                cur["absent"] = ABSENT_MARKER in ln
                continue
            m = ROW.match(ln)
            if m:
                cur["rows"].append(m.group(1))
                continue
            m = FILEROW.match(ln)
            if m:
                cur["filerows"].append((m.group(1), int(m.group(2))))
    return secs


def main():
    if len(sys.argv) != 2:
        print("usage: reg-reconcile.py <registry.md>", file=sys.stderr)
        return 2
    truth = {k: [n for n, _ in v] for k, v in json.load(open(PROCS)).items()}
    secs = parse(sys.argv[1])
    bad = 0
    total_rows = 0
    documented_files = set()

    for s in secs:
        rows, f = s["rows"], s["file"]
        total_rows += len(rows)
        print("== %s" % s["title"])

        # -- shape 3: informational -------------------------------------
        if f is None:
            if rows:
                print("   NO FILE LINE but %d procedure rows present"
                      % len(rows))
                bad += 1
                continue
            print("   informational (no file line, no procedure rows)")
            if "not yet documented" in s["title"].lower():
                claimed = dict(s["filerows"])
                expected = {k: len(v) for k, v in truth.items()
                            if k not in documented_files}
                if claimed != expected:
                    only_c = sorted(set(claimed) - set(expected))
                    only_e = sorted(set(expected) - set(claimed))
                    diff = sorted(k for k in set(claimed) & set(expected)
                                  if claimed[k] != expected[k])
                    print("   UNDOCUMENTED TABLE MISMATCH")
                    if only_c:
                        print("      listed but documented/unknown: %s"
                              % ", ".join(only_c))
                    if only_e:
                        print("      undocumented but not listed: %s"
                              % ", ".join(only_e))
                    for k in diff:
                        print("      %s: listed %d, truth %d"
                              % (k, claimed[k], expected[k]))
                    bad += 1
                else:
                    print("   OK — %d undocumented files, %d procedures, "
                          "reconcile against procs.json"
                          % (len(expected), sum(expected.values())))
            continue

        documented_files.add(f)
        present = os.path.isfile(os.path.join(ROOT, f))
        print("   file=%s claim=%s rows=%d on_disk=%s absent_marker=%s"
              % (f, s["claim"], len(rows), present, s["absent"]))

        if s["claim"] != len(rows):
            print("   COUNT MISMATCH: header claims %d, table has %d"
                  % (s["claim"], len(rows)))
            bad += 1

        # -- annotation verified against the filesystem, both ways -------
        if s["absent"] and present:
            print("   ANNOTATION WRONG: marked absent but the file EXISTS "
                  "on disk — reconcile it by name instead")
            bad += 1
            continue
        if not s["absent"] and not present:
            print("   FILE MISSING FROM TREE and not annotated as absent")
            bad += 1
            continue

        # -- shape 2: declared absent, verified absent ------------------
        if s["absent"]:
            print("   declared absent — verified not on disk; names not "
                  "reconciled (%d rows retained as a record)" % len(rows))
            continue

        # -- shape 1: documented, file present on disk ------------------
        t = truth.get(f, [])
        if f not in truth:
            print("   on disk, contributes 0 procedures")
        missing = [n for n in t if n not in rows]
        extra = [n for n in rows if n not in t]
        dup = sorted({n for n in rows if rows.count(n) > 1})
        if missing:
            print("   MISSING (%d): %s" % (len(missing), ", ".join(missing)))
            bad += 1
        if extra:
            print("   EXTRA   (%d): %s" % (len(extra), ", ".join(extra)))
            bad += 1
        if dup:
            print("   DUPLICATE ROWS: %s" % ", ".join(dup))
            bad += 1
        if not (missing or extra or dup) and s["claim"] == len(rows):
            print("   OK — %d names reconcile" % len(t))

    print("\ntotal documented rows: %d" % total_rows)
    print("sections with defects: %d" % bad)
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
