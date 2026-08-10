#!/usr/bin/env python3
# theilsen-negative-controls.py -- prove that test-theilsen.praat can fail.
#
# A green suite proves reproduction, not enforcement. Three separate claims
# need three separate paired controls, and this driver runs all six:
#   NC-0   no injection                              -> must PASS
#   NC-1a  perturb one expected literal ABOVE tol    -> must FAIL
#   NC-1b  perturb the same literal BELOW tol        -> must PASS   (brackets tol)
#   NC-2   swap the implementation to joint intercept-> must FAIL   (convention pin)
#   NC-3a  delete call sites, coverage assertion ON  -> must FAIL
#   NC-3b  same deletion, coverage assertion OFF     -> PASSES = the false green
#
# Mutations are applied in place against md5-verified snapshots and restored in
# a finally block; the run reports the post-restore md5 so cleanup is proved,
# not assumed. A missing EMLTEST-RESULT sentinel is treated as FAIL.
#
# The Praat binary resolves from $EML_PRAAT, then PATH, then common locations --
# never hardcoded (dependency-currency house rule).
#
#!/usr/bin/env python3
# Negative-control driver for test-theilsen.praat.
#
# A suite that passes 47/47 with every measured margin at exactly 0.0 has
# proven that Praat reproduces scipy bit-for-bit. It has NOT proven that any
# assertion is capable of failing, nor that tsTol is enforced at the size it
# claims, nor that the intercept-convention pinning in Section 2 actually
# discriminates. Those are separate claims and each needs its own control.
#
# Every mutation is applied programmatically to the committed file, run, and
# then reverted with an md5 check. No literal is retyped: perturbations are
# emitted as `(<original literal> + delta)` so Praat evaluates the arithmetic.

import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.abspath(os.path.join(HERE, "..", ".."))
PHASE2 = PLUGIN + "/dev/tests/phase2"
SUITE = PHASE2 + "/test-theilsen.praat"
IMPL = PLUGIN + "/stats/eml-inferential.praat"
def _find_praat():
    import shutil
    c = os.environ.get("EML_PRAAT")
    if c and os.path.exists(c):
        return c
    for name in ("praat_barren", "praat"):
        w = shutil.which(name)
        if w:
            return w
        for d in (os.path.expanduser("~"),
                  str(Path(__file__).resolve().parents[3]),
                  "/usr/local/bin"):
            p = os.path.join(d, name)
            if os.path.exists(p):
                return p
    raise SystemExit("Praat binary not found. Set $EML_PRAAT.")
PRAAT = _find_praat()

PRISTINE = {}


def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()


def snapshot():
    for p in (SUITE, IMPL):
        PRISTINE[p] = md5(p)
        shutil.copy2(p, p + ".ncbak")


def restore():
    bad = []
    for p in (SUITE, IMPL):
        shutil.copy2(p + ".ncbak", p)
        if md5(p) != PRISTINE[p]:
            bad.append(p)
    if bad:
        sys.exit("RESTORE FAILED: " + ", ".join(bad))


def cleanup():
    for p in (SUITE, IMPL):
        if os.path.exists(p + ".ncbak"):
            os.remove(p + ".ncbak")


def run():
    r = subprocess.run([PRAAT, "--run", SUITE], cwd=PHASE2,
                       capture_output=True, text=True)
    out = r.stdout + r.stderr
    m = re.search(r"EMLTEST-RESULT: status=(\w+) passed=(\d+) failed=(\d+) "
                  r"skipped=(\d+) total=(\d+)", out)
    sent = m.groups() if m else None
    fails = [ln.strip() for ln in out.split("\n") if "FAIL" in ln.upper()
             and "EMLTEST-RESULT" not in ln]
    return r.returncode, sent, fails, out


def report(tag, expect, code, sent, fails, show_fails=0):
    if sent is None:
        status = "NO-SENTINEL"
        detail = "(treated as FAIL)"
    else:
        status = sent[0]
        detail = "passed=%s failed=%s skipped=%s total=%s" % sent[1:]
    verdict = "as expected" if status == expect else "*** UNEXPECTED ***"
    print("\n%s" % ("-" * 72))
    print("%-10s expect %-10s got %-11s exit=%d  %s   %s"
          % (tag, expect, status, code, detail, verdict))
    if show_fails and fails:
        for f in fails[:show_fails]:
            print("     %s" % f)
    return status == expect


# --- mutators ---------------------------------------------------------------

def perturb_expected(name, delta_src):
    """Wrap the expected literal of one assertion in (<lit> + delta)."""
    src = open(SUITE).read()
    pat = re.compile(r'(@emlTestAssertEqualNum:\s*"%s"\s*,\s*)([^,\n]+)'
                     % re.escape(name))
    m = pat.search(src)
    if not m:
        sys.exit("could not locate assertion: " + name)
    lit = m.group(2).strip()
    new = src[:m.start(2)] + "(%s + %s)" % (lit, delta_src) + src[m.end(2):]
    open(SUITE, "w").write(new)
    return lit


def to_joint_intercept():
    """Replace separate-convention intercept with joint: median(y - slope*x)."""
    src = open(IMPL).read()
    old = "            .intercept = .medY - .slope * .medX"
    if old not in src:
        sys.exit("intercept line not found in implementation")
    new = (
        "            .resid# = zero# (.n)\n"
        "            for .r from 1 to .n\n"
        "                .resid# [.r] = .y# [.r] - .slope * .x# [.r]\n"
        "            endfor\n"
        "            .sortedR# = sort# (.resid#)\n"
        "            .midR = ceiling (.n / 2)\n"
        "            if .n mod 2 = 1\n"
        "                .intercept = .sortedR# [.midR]\n"
        "            else\n"
        "                .intercept = (.sortedR# [.midR]\n"
        "                ... + .sortedR# [.midR + 1]) / 2\n"
        "            endif"
    )
    open(IMPL, "w").write(src.replace(old, new))


def delete_call_site(tag, keep_coverage):
    """Remove one 3-assertion block; optionally also drop the coverage check."""
    lines = open(SUITE).read().split("\n")
    out, killed = [], 0
    i = 0
    while i < len(lines):
        ln = lines[i]
        if re.match(r'\s*@emlTestAssertEqualNum:\s*"%s ' % re.escape(tag), ln):
            killed += 1
            i += 1
            while i < len(lines) and lines[i].strip().startswith("..."):
                i += 1
            continue
        out.append(ln)
        i += 1
    src = "\n".join(out)
    if not keep_coverage:
        src = src.replace(
            '@emlTestAssertEqualNum: "coverage: all declared checks performed",',
            '# DISABLED FOR NC: @emlTestAssertEqualNum: "coverage",')
        src = src.replace(
            "... tsExpectedChecks, emlTestInit.count, tsExact",
            "# ... tsExpectedChecks, emlTestInit.count, tsExact")
    open(SUITE, "w").write(src)
    return killed


# --- run --------------------------------------------------------------------

snapshot()
ok = []
try:
    print("=" * 72)
    print("BASELINE (unmutated committed tree)")
    print("=" * 72)
    code, sent, fails, _ = run()
    ok.append(report("NC-0", "PASS", code, sent, fails))

    # NC-1a/b: bracket tsTol (5e-11) at one site. Above the band must fail,
    # below it must pass. Together these prove the tolerance is enforced AND
    # that it is the size the file says it is.
    lit = perturb_expected("TS-8 slope", "1e-10")
    code, sent, fails, _ = run()
    ok.append(report("NC-1a", "FAIL", code, sent, fails, show_fails=3))
    print("     perturbed literal was: %s  (+1e-10, tol 5e-11)" % lit)
    restore()

    perturb_expected("TS-8 slope", "1e-11")
    code, sent, fails, _ = run()
    ok.append(report("NC-1b", "PASS", code, sent, fails))
    print("     same site +1e-11 (inside the 5e-11 band) -- must NOT fail")
    restore()

    # NC-2: the convention control. Swap the implementation to the joint
    # intercept. If Section 2 and the intercept assertions genuinely pin
    # Conover-separate, exactly the sets where the conventions differ must
    # fail: TS-1, TS-2, TS-5, TS-8 intercepts plus the two Section 2 checks.
    to_joint_intercept()
    code, sent, fails, _ = run()
    ok.append(report("NC-2", "FAIL", code, sent, fails, show_fails=12))
    restore()

    # NC-3a/b: coverage assertion. Deleting a call site must be caught; with
    # the coverage assertion disabled the same deletion must sail through
    # green at a lower count -- which is the false-green shape this whole
    # work item exists to eliminate.
    n = delete_call_site("TS-5", keep_coverage=True)
    code, sent, fails, _ = run()
    ok.append(report("NC-3a", "FAIL", code, sent, fails, show_fails=3))
    print("     deleted %d TS-5 numeric assertions, coverage check ACTIVE" % n)
    restore()

    delete_call_site("TS-5", keep_coverage=False)
    code, sent, fails, _ = run()
    ok.append(report("NC-3b", "PASS", code, sent, fails))
    print("     same deletion, coverage check DISABLED -> green at a lower")
    print("     count. This is the false green the coverage assertion blocks.")
    restore()
finally:
    restore()
    print("\n" + "=" * 72)
    for p in (SUITE, IMPL):
        print("restored %-46s md5 %s %s"
              % (os.path.basename(p), md5(p),
                 "OK" if md5(p) == PRISTINE[p] else "MISMATCH"))
    cleanup()

print("=" * 72)
print("CONTROLS BEHAVING AS EXPECTED: %d / %d" % (sum(ok), len(ok)))
sys.exit(0 if all(ok) else 1)
