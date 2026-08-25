#!/usr/bin/env python3
# vacuity-negative-controls.py -- prove that scan-assertion-vacuity.py can fail.
#
# scan-assertion-vacuity.py exits 0 on the shipped suite. That is a reproduction
# claim, not an enforcement claim: a scanner whose red path has never executed
# is indistinguishable from a scanner that always returns 0. This driver injects
# one defect at a time and requires the scanner to catch each one, and pairs the
# ratio controls so the A/B boundary is bracketed rather than merely tripped.
#
#   NC-0   no injection                                  -> exit 0, CLEAN
#   NC-1a  absolute tol == expected  (ratio 1.00)        -> exit 1, vacuous=1
#   NC-1b  absolute tol just under   (ratio 1.04)        -> exit 0, CLASS B only
#   NC-2   AssertEqualRel with expected 0                -> exit 1, misuse=1
#   NC-3   tolerance token never assigned a literal      -> exit 1, unresolved>=1
#   NC-4   tolerance name reassigned to a DIFFERENT value-> exit 1, unresolved>=2
#          (proves the `conflicted` guard: a name with two literals must become
#           unresolvable, not silently take the last one)
#   NC-5   malformed assertion the regex cannot parse    -> exit 1, unparsed=1
#
# NC-1a/NC-1b are the load-bearing pair. Individually either could be explained
# by "the scanner reacts to any edit"; together they show the verdict tracks the
# |expected|/tolerance ratio across a boundary two percent wide.
#
# Isolation: the phase2 tree is COPIED to a scratch directory and every mutation
# is applied to the copy, because scan-assertion-vacuity.py takes its input
# directory as argv[1]. The shipped tree is therefore never written to at all --
# a stronger guarantee than mutate-and-restore. The run still fingerprints the
# real tree before and after and reports the comparison, so "never touched" is
# proved rather than asserted.
#
# Exit: 0 = every control behaved as specified   1 = at least one did not
#
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.abspath(os.path.join(HERE, "..", ".."))
PHASE2 = os.path.join(PLUGIN, "dev", "tests", "phase2")
SCANNER = os.path.join(HERE, "scan-assertion-vacuity.py")

# Anchor site, chosen because it is a plain literal-expected absolute-tolerance
# assertion with a named tolerance -- the exact shape every class turns on.
ANCHOR_FILE = "test-theilsen.praat"
ANCHOR = '@emlTestAssertEqualNum: "TS-1 slope", 2.5, emlTheilSen.slope, tsTol'


def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()


def tree_fingerprint(d):
    return {f: md5(os.path.join(d, f))
            for f in sorted(os.listdir(d)) if f.endswith(".praat")}


def run_scanner(d):
    r = subprocess.run([sys.executable, SCANNER, d],
                       capture_output=True, text=True)
    out = r.stdout + r.stderr
    # The verdict token contains a space ("DEFECTS PRESENT"), so it must be
    # matched lazily up to the counter block -- \S+ silently fails the red path
    # while matching the green one, which is precisely the asymmetry a control
    # driver must not have.
    m = re.search(r"VERDICT: (.+?)\s+\(vacuous=(\d+) unparsed=(\d+) "
                  r"misuse=(\d+) unresolved-tol=(\d+)\)", out)
    if not m:
        return r.returncode, None, out
    counts = {"verdict": m.group(1), "vacuous": int(m.group(2)),
              "unparsed": int(m.group(3)), "misuse": int(m.group(4)),
              "unresolved": int(m.group(5))}
    cb = re.search(r"weak\) ==\n((?:.*\n)*?)  count: (\d+)", out)
    counts["weak"] = int(cb.group(2)) if cb else -1
    return r.returncode, counts, out


# --- mutators: each takes the scratch directory, returns a description --------

def mutate_none(d):
    return "unmodified copy of the shipped phase2 tree"


def _rewrite_anchor(d, newline):
    p = os.path.join(d, ANCHOR_FILE)
    src = open(p, encoding="utf-8").read()
    if ANCHOR not in src:
        sys.exit("anchor line not found in %s -- fixture drifted:\n  %s"
                 % (ANCHOR_FILE, ANCHOR))
    open(p, "w", encoding="utf-8").write(src.replace(ANCHOR, newline, 1))


def _append(d, fname, text):
    with open(os.path.join(d, fname), "a", encoding="utf-8") as fh:
        fh.write("\n" + text + "\n")


def mutate_ratio_at_boundary(d):
    # expected 2.5, tolerance 2.5 -> ratio exactly 1.00 -> CLASS A (vacuous):
    # a true value of 0 would pass this assertion.
    _rewrite_anchor(d, ANCHOR.replace(", tsTol", ", 2.5"))
    return "anchor tolerance 5e-11 -> 2.5 (ratio 1.00, at the vacuity boundary)"


def mutate_ratio_just_inside(d):
    # Same site, tolerance 2.4 -> ratio 1.0417 -> CLASS B (weak, not vacuous).
    # 4% away from NC-1a and the verdict must flip back to CLEAN.
    _rewrite_anchor(d, ANCHOR.replace(", tsTol", ", 2.4"))
    return "anchor tolerance 5e-11 -> 2.4 (ratio 1.04, just clear of vacuity)"


def mutate_rel_zero(d):
    _append(d, ANCHOR_FILE,
            '@emlTestAssertEqualRel: "NC-2 injected misuse", 0, '
            'emlTheilSen.slope, 1e-9')
    return "appended an AssertEqualRel whose expected value is 0"


def mutate_unresolved_tol(d):
    _append(d, ANCHOR_FILE,
            '@emlTestAssertEqualNum: "NC-3 injected unresolved tol", 2.5, '
            'emlTheilSen.slope, tsNeverAssigned')
    return "appended an assertion whose tolerance token is never assigned"


def mutate_conflicted_tol(d):
    # tsTol already == 5e-11 at line 64. A second, different literal must make
    # the name unresolvable for EVERY site that uses it -- not quietly rebind.
    _append(d, ANCHOR_FILE, "tsTol = 7e-11")
    return "reassigned tsTol to a second, different literal (7e-11)"


def mutate_unparsed(d):
    # Missing comma after the label: contains AssertEqualNum, so it is counted,
    # but the argument regex cannot match it.
    _append(d, ANCHOR_FILE,
            '@emlTestAssertEqualNum: "NC-5 malformed" 2.5, '
            'emlTheilSen.slope, tsTol')
    return "appended a malformed assertion (no comma after the label)"


# tag, mutator, expected exit, per-counter predicate, human-readable expectation
CONTROLS = [
    ("NC-0",  mutate_none, 0,
     lambda c: c["verdict"] == "CLEAN" and c["vacuous"] == 0
     and c["unparsed"] == 0 and c["misuse"] == 0 and c["unresolved"] == 0,
     "CLEAN, all counters 0"),
    ("NC-1a", mutate_ratio_at_boundary, 1,
     lambda c: c["vacuous"] == 1 and c["unparsed"] == 0
     and c["misuse"] == 0 and c["unresolved"] == 0,
     "vacuous=1, everything else 0"),
    ("NC-1b", mutate_ratio_just_inside, 0,
     lambda c: c["verdict"] == "CLEAN" and c["vacuous"] == 0
     and c["weak"] == 1,
     "CLEAN, vacuous=0, CLASS B count 1"),
    ("NC-2",  mutate_rel_zero, 1,
     lambda c: c["misuse"] == 1 and c["vacuous"] == 0
     and c["unparsed"] == 0 and c["unresolved"] == 0,
     "misuse=1, everything else 0"),
    ("NC-3",  mutate_unresolved_tol, 1,
     lambda c: c["unresolved"] == 1 and c["vacuous"] == 0
     and c["unparsed"] == 0 and c["misuse"] == 0,
     "unresolved-tol=1, everything else 0"),
    ("NC-4",  mutate_conflicted_tol, 1,
     lambda c: c["unresolved"] >= 2 and c["vacuous"] == 0
     and c["unparsed"] == 0 and c["misuse"] == 0,
     "unresolved-tol>=2 (every tsTol site), everything else 0"),
    ("NC-5",  mutate_unparsed, 1,
     lambda c: c["unparsed"] == 1 and c["vacuous"] == 0
     and c["misuse"] == 0 and c["unresolved"] == 0,
     "unparsed=1, everything else 0"),
]


def main():
    if not os.path.isdir(PHASE2):
        sys.exit("phase2 test directory not found: %s" % PHASE2)
    if not os.path.exists(SCANNER):
        sys.exit("scanner not found: %s" % SCANNER)

    before = tree_fingerprint(PHASE2)
    print("=" * 72)
    print("vacuity-negative-controls -- %d .praat fixtures fingerprinted"
          % len(before))
    print("scanner: %s" % SCANNER)
    print("=" * 72)

    ok = []
    scratch = tempfile.mkdtemp(prefix="vacnc-")
    try:
        for tag, mutate, want_code, predicate, expectation in CONTROLS:
            work = os.path.join(scratch, tag)
            shutil.copytree(PHASE2, work)
            desc = mutate(work)
            code, counts, out = run_scanner(work)

            if counts is None:
                good = False
                got = "NO VERDICT LINE (scanner died before reporting)"
            else:
                good = (code == want_code) and predicate(counts)
                got = ("%s vacuous=%d unparsed=%d misuse=%d unresolved-tol=%d "
                       "weak=%d" % (counts["verdict"], counts["vacuous"],
                                    counts["unparsed"], counts["misuse"],
                                    counts["unresolved"], counts["weak"]))
            ok.append(good)

            print("\n" + "-" * 72)
            print("%-6s %s" % (tag, desc))
            print("       expect exit=%d, %s" % (want_code, expectation))
            print("       got    exit=%d, %s" % (code, got))
            print("       %s" % ("as expected" if good
                                 else "*** UNEXPECTED ***"))
            if not good:
                for ln in out.strip().split("\n")[-6:]:
                    print("         | %s" % ln)
            shutil.rmtree(work)
    finally:
        shutil.rmtree(scratch, ignore_errors=True)

    after = tree_fingerprint(PHASE2)
    same = before == after
    print("\n" + "=" * 72)
    print("shipped tree unchanged: %s  (%d files compared by md5)"
          % ("YES" if same else "NO -- MUTATION LEAKED", len(after)))
    if not same:
        for f in sorted(set(before) | set(after)):
            if before.get(f) != after.get(f):
                print("   DIFFERS: %s" % f)
    print("CONTROLS BEHAVING AS EXPECTED: %d / %d" % (sum(ok), len(ok)))
    print("=" * 72)
    sys.exit(0 if (all(ok) and same) else 1)


main()
