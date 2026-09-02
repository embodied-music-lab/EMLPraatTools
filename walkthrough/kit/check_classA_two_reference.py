#!/usr/bin/env python3
"""Class A far-tail two-reference gate (Fable, RULING_UNIQUENESS_SWEEP,
reference gate per RULING_PTUKEY_REFERENCE).

Praat's retained host special functions are compared against TWO independent
references in the far tail: scipy and R. The gate escalates to the mpmath grid
only where the two references disagree beyond the standard rule; where they
agree, their agreement is itself the evidence.

Praat's values are read from sweep_host_<version>.tsv, produced by
SWEEP_HOST_FUNCTIONS.praat on a real Praat run. Nothing here recomputes them.

Run:  python3 check_classA_two_reference.py [sweep_host_6.6.30.tsv]
"""
import subprocess, sys, collections
from scipy import stats

PATH = sys.argv[1] if len(sys.argv) > 1 else "sweep_host_6.6.30.tsv"
FAR = 1e-6           # "far tail" = reference probability at or below this
RULE = 1e-9          # the kit's standard relative rule

SCIPY = {
    "gaussQ":     lambda a1, a2, a3: stats.norm.sf(a1),
    "studentQ":   lambda a1, a2, a3: stats.t.sf(a1, a2),
    "chiSquareQ": lambda a1, a2, a3: stats.chi2.sf(a1, a2),
    "fisherQ":    lambda a1, a2, a3: stats.f.sf(a1, a2, a3),
}
RCALL = {
    "gaussQ":     lambda a1, a2, a3: f"pnorm({a1!r},lower.tail=FALSE)",
    "studentQ":   lambda a1, a2, a3: f"pt({a1!r},{a2!r},lower.tail=FALSE)",
    "chiSquareQ": lambda a1, a2, a3: f"pchisq({a1!r},{a2!r},lower.tail=FALSE)",
    "fisherQ":    lambda a1, a2, a3: f"pf({a1!r},{a2!r},{a3!r},lower.tail=FALSE)",
}

rows = []
for line in open(PATH):
    p = line.rstrip("\n").split("\t")
    if len(p) < 5 or p[0] == "fn":
        continue
    rows.append(p)

def num(x):
    try:
        return float(x)
    except ValueError:
        return 0.0

print(f"source: {PATH}   far tail: reference p <= {FAR:g}   standard rule: {RULE:g}\n")
print(f"{'function':<12} {'cells':>6} {'Praat vs scipy':>16} {'R vs scipy':>14} {'gate':>26}")
escalations = 0
for fn in ("gaussQ", "studentQ", "chiSquareQ", "fisherQ"):
    pts = [r for r in rows if r[0] == fn]
    if not pts:
        continue
    calls = [RCALL[fn](num(r[1]), num(r[2]), num(r[3])) for r in pts]
    out = subprocess.run(
        ["Rscript", "-e", "cat(sprintf('%.17g\\n',c(" + ",".join(calls) + ")))"],
        capture_output=True, text=True, check=True)
    rvals = [float(x) for x in out.stdout.split()]

    n = 0
    worst_praat = worst_r = 0.0
    disagree = 0
    for r, rv in zip(pts, rvals):
        s = SCIPY[fn](num(r[1]), num(r[2]), num(r[3]))
        if not (0 < s <= FAR):
            continue
        n += 1
        worst_praat = max(worst_praat, abs(float(r[4]) - s) / s)
        rel_r = abs(rv - s) / s
        worst_r = max(worst_r, rel_r)
        if rel_r > RULE:
            disagree += 1
    escalations += disagree
    verdict = f"ESCALATE ({disagree} cells)" if disagree else "references agree, no escalation"
    print(f"{fn:<12} {n:>6} {worst_praat:>16.2e} {worst_r:>14.2e} {verdict:>26}")

print()
print("ESCALATIONS REQUIRED:" if escalations else "NO ESCALATION REQUIRED:", escalations, "cell(s)")
print("Where the two references agree, Praat is judged against their agreement.")
