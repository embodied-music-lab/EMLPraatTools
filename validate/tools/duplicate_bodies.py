#!/usr/bin/env python3
"""
validate/tools/duplicate_bodies.py
============================================================================
Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later

DUPLICATE-BODY check (governance ORDER_DRY_LINT_AND_AUDIT_FIXES, part A,
check A1): walk the EML plugin's .praat files, extract every
`procedure ... endproc` body, normalise it, and report pairs of
DISTINCT-NAMED procedures whose bodies are near-identical by 6-token-shingle
Jaccard similarity.

THE NORMALISATION, SHINGLING AND JACCARD LOGIC BELOW ARE COPIED VERBATIM
FROM /tmp/census_procedures.py (the audit's own script) -- this file does
not invent a second definition of "near-duplicate". Only the file-walking,
CLI surface and allowlist handling are new; norm(), shingles() and the
Jaccard arithmetic reproduce census_procedures.py exactly, including its
"only mask ONE leading '#'" comment-stripping rule:
    code = raw.split("#", 1)[0] if not raw.lstrip().startswith("#") else ""
    (and a line whose stripped text starts with ";" is also blanked)

USAGE
    python3 validate/tools/duplicate_bodies.py [PLUGIN_ROOT] [ALLOWLIST_TSV]

    PLUGIN_ROOT     defaults to plugin_EML_StatsGraphs relative to the repo
                    root (this file's grandparent directory).
    ALLOWLIST_TSV   defaults to validate/canon/duplicate_allowlist.tsv
                    relative to the repo root.

PLUGIN_ROOT is walked as: setup.praat (if present directly under it) plus
every *.praat file under its stats/, graphs/ and scripts/ subdirectories
(if present) -- exactly the file set the governance order names. A
PLUGIN_ROOT that IS a fixture directory (no setup.praat, no stats/graphs/
scripts/ subdirectories) falls back to every *.praat file found anywhere
under it, so the self-test can point this script at a small fixture
directory without reproducing the plugin's directory layout.

OUTPUT (stdout, tab-separated, one line per reported pair):
    LEVEL<TAB>jaccard<TAB>proc_a<TAB>a_file:line<TAB>proc_b<TAB>b_file:line

    LEVEL is one of:
      FAIL   jaccard >= 0.80 and the pair is NOT in the allowlist
      ALLOW  jaccard >= 0.80 but the pair IS in the allowlist (informational)
      INFO   0.50 <= jaccard < 0.80 (informational, never a failure)

Only pairs of DISTINCT procedure names, each with >= 40 normalised tokens,
are compared. Exit status is always 0 -- this script only reports; the R
validator that drives it decides pass/fail from the LEVEL column.
"""
import re
import os
import sys
import itertools

# ---------------------------------------------------------------------------
# Copied verbatim from /tmp/census_procedures.py -- do not re-derive.
# ---------------------------------------------------------------------------

def_re = re.compile(r'^\s*procedure\s+([A-Za-z_][\w]*)\s*[:(]?\s*(.*)$')
call_re = re.compile(r'(?<![\w.])@([A-Za-z_]\w*)')
end_re = re.compile(r'^\s*endproc\b')


def norm(body):
    toks = []
    for ln in body:
        if not ln:
            continue
        ln = re.sub(r'"[^"]*"', '"S"', ln)
        ln = re.sub(r'\b\d+(\.\d+)?([eE][-+]?\d+)?\b', 'N', ln)
        ln = re.sub(r'\.[A-Za-z_]\w*', '.V', ln)       # local vars
        toks.extend(re.findall(r'[A-Za-z_]\w*|[^\sA-Za-z_]', ln))
    return toks


def shingles(toks, k=6):
    return set(tuple(toks[i:i + k]) for i in range(max(0, len(toks) - k + 1)))


# ---------------------------------------------------------------------------
# File discovery and procedure extraction (new, but following
# census_procedures.py's own comment-stripping and def/endproc scanning).
# ---------------------------------------------------------------------------

def discover_files(root):
    """Return a sorted list of .praat files to scan, relative to root."""
    setup = os.path.join(root, "setup.praat")
    dirs = ("stats", "graphs", "scripts")
    has_layout = os.path.isfile(setup) or any(
        os.path.isdir(os.path.join(root, d)) for d in dirs
    )
    if has_layout:
        files = []
        if os.path.isfile(setup):
            files.append("setup.praat")
        for d in dirs:
            dp = os.path.join(root, d)
            if os.path.isdir(dp):
                for f in sorted(os.listdir(dp)):
                    if f.endswith(".praat"):
                        files.append(os.path.join(d, f))
        return files
    # Fixture-style root: no plugin layout, so just take every .praat file
    # found anywhere under it (recursively), relative to root.
    out = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for f in sorted(filenames):
            if f.endswith(".praat"):
                out.append(os.path.relpath(os.path.join(dirpath, f), root))
    return sorted(out)


def extract_procedures(root, files):
    """Return list of dicts: name, file, line, body (list of code lines)."""
    defs = []
    for rel in files:
        path = os.path.join(root, rel)
        try:
            with open(path, encoding="utf-8", errors="replace") as fh:
                lines = fh.read().split("\n")
        except OSError:
            continue
        cur = None  # index into defs of the currently open procedure
        for i, raw in enumerate(lines, 1):
            code = raw.split("#", 1)[0] if not raw.lstrip().startswith("#") else ""
            if raw.lstrip().startswith(";"):
                code = ""
            m = def_re.match(code)
            if m:
                name = m.group(1)
                defs.append(dict(name=name, file=rel, line=i, body=[]))
                cur = len(defs) - 1
                continue
            if end_re.match(code):
                cur = None
                continue
            if cur is not None:
                defs[cur]["body"].append(code.strip())
    return defs


def load_allowlist(path):
    """Return a set of frozenset({proc_a, proc_b}) pairs, order-independent."""
    pairs = set()
    if not path or not os.path.isfile(path):
        return pairs
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.read().splitlines()
    if not lines:
        return pairs
    header = lines[0].split("\t")
    try:
        ia = header.index("proc_a")
        ib = header.index("proc_b")
    except ValueError:
        return pairs
    for ln in lines[1:]:
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        parts = ln.split("\t")
        if len(parts) <= max(ia, ib):
            continue
        a, b = parts[ia].strip(), parts[ib].strip()
        if a and b:
            pairs.add(frozenset((a, b)))
    return pairs


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(os.path.dirname(here))  # validate/tools -> validate -> repo root

    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(repo_root, "plugin_EML_StatsGraphs")
    allowlist_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
        repo_root, "validate", "canon", "duplicate_allowlist.tsv")

    root = os.path.abspath(root)
    allowlist = load_allowlist(allowlist_path)

    files = discover_files(root)
    defs = extract_procedures(root, files)

    items = []
    for d in defs:
        toks = norm(d["body"])
        if len(toks) >= 40:
            items.append((d["name"], d["file"], d["line"], shingles(toks)))

    rows = []  # (level_sort_key, jaccard, level, proc_a, loc_a, proc_b, loc_b)
    for a, b in itertools.combinations(items, 2):
        if a[0] == b[0]:
            continue
        inter = len(a[3] & b[3])
        uni = len(a[3] | b[3])
        if not uni:
            continue
        j = inter / uni
        if j < 0.50:
            continue
        allowlisted = frozenset((a[0], b[0])) in allowlist
        if j >= 0.80:
            level = "ALLOW" if allowlisted else "FAIL"
        else:
            level = "INFO"
        loc_a = "%s:%d" % (a[1], a[2])
        loc_b = "%s:%d" % (b[1], b[2])
        rows.append((j, level, a[0], loc_a, b[0], loc_b))

    # FAIL first, then ALLOW, then INFO; within a level, highest jaccard first.
    level_order = {"FAIL": 0, "ALLOW": 1, "INFO": 2}
    rows.sort(key=lambda r: (level_order[r[1]], -r[0]))

    for j, level, na, la, nb, lb in rows:
        print("%s\t%.4f\t%s\t%s\t%s\t%s" % (level, j, na, la, nb, lb))

    return 0


if __name__ == "__main__":
    sys.exit(main())
