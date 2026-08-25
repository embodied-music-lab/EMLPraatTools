#!/usr/bin/env python3
"""Probe the EML statistics library with degenerate inputs, one isolated
Praat process per case.

Each case is emitted as its own tiny script and run under a timeout, so a
case that kills the interpreter cannot hide the cases after it -- which is
precisely what a single monolithic probe would do. Three outcomes are
distinguished and they are NOT the same thing:

  CONTRACT  the procedure set .error$ and returned -- the documented path
  VALUE     the procedure returned a number (possibly --undefined--)
  CRASH     the interpreter died, or the process had to be killed

A CRASH is always a defect. A VALUE on a degenerate input is a defect only
if the value is fabricated -- i.e. it reads as a completed test when no test
was possible (the audit-item-9 failure mode: Dunn's z = 0, p = 1 on a
zero-variance input). This tool reports; it does not judge.
"""
import os, re, subprocess, sys, tempfile

# this file lives at <plugin>/dev/tools/, so the plugin root is three up
PLUGIN = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if not os.path.isdir(os.path.join(PLUGIN, "stats")):
    sys.exit("cannot locate <plugin>/stats from %s" % PLUGIN)
# $PRAAT wins; then the build beside the repository; then PATH. Never one
# machine's absolute path as the only answer.
import shutil as _shutil
from pathlib import Path as _Path
_adjacent = _Path(__file__).resolve().parents[3]
PRAAT = (os.environ.get("PRAAT")
         or next((str(p) for p in (_adjacent / "praat_barren",
                                   _adjacent / "praat") if p.exists()), None)
         or _shutil.which("praat_barren") or _shutil.which("praat"))
TIMEOUT = 25

INCLUDES = """include {p}/stats/eml-core-utilities.praat
include {p}/stats/eml-core-descriptive.praat
include {p}/stats/eml-extract.praat
include {p}/stats/eml-output.praat
include {p}/stats/eml-inferential.praat
""".format(p=PLUGIN)

TABLE_HELPER = """
procedure mkTable: .vals#, .grp$#
    .n = size (.vals#)
    .tid = Create Table with column names: "probe", .n, "Value Group"
    for .i from 1 to .n
        Set numeric value: .i, "Value", .vals# [.i]
        Set string value: .i, "Group", .grp$# [.i]
    endfor
    .tableId = .tid
endproc
"""

# (family, case name, praat body). Body must print lines beginning "OUT: ".
CASES = [

# ---- constant / zero-variance inputs -------------------------------------
("t-test", "identical constant groups (all 5.0 vs all 5.0)", """
a# = {5,5,5,5,5}
b# = {5,5,5,5,5}
@emlTTest: a#, b#, 2, 1
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t, " p=", emlTTest.p, " df=", emlTTest.df
"""),

("t-test", "one group constant, other varied", """
a# = {5,5,5,5,5}
b# = {1,2,3,4,5}
@emlTTest: a#, b#, 2, 1
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t, " p=", emlTTest.p
"""),

("t-test", "n=1 per group", """
a# = {5}
b# = {7}
@emlTTest: a#, b#, 2, 1
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t, " p=", emlTTest.p
"""),

("t-test", "n=2 per group, Welch", """
a# = {5,6}
b# = {7,9}
@emlTTest: a#, b#, 2, 0
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t, " p=", emlTTest.p, " df=", emlTTest.df
"""),

("paired t", "all differences zero", """
a# = {1,2,3,4,5}
b# = {1,2,3,4,5}
@emlTTestPaired: a#, b#, 2
appendInfoLine: "OUT: error=", emlTTestPaired.error$
appendInfoLine: "OUT: t=", emlTTestPaired.t, " p=", emlTTestPaired.p
"""),

("paired t", "n=1 pair", """
a# = {3}
b# = {5}
@emlTTestPaired: a#, b#, 2
appendInfoLine: "OUT: error=", emlTTestPaired.error$
appendInfoLine: "OUT: t=", emlTTestPaired.t
"""),

("Cohen d", "both groups constant (pooled SD = 0)", """
a# = {4,4,4,4}
b# = {9,9,9,9}
@emlCohenD: a#, b#
appendInfoLine: "OUT: error=", emlCohenD.error$
appendInfoLine: "OUT: d=", emlCohenD.d
"""),

# ---- correlation / regression --------------------------------------------
("Pearson", "x constant", """
x# = {2,2,2,2,2}
y# = {1,2,3,4,5}
@emlPearsonCorrelation: x#, y#, 2
appendInfoLine: "OUT: error=", emlPearsonCorrelation.error$
appendInfoLine: "OUT: r=", emlPearsonCorrelation.r, " p=", emlPearsonCorrelation.p
"""),

("Pearson", "n=2 (r is +/-1 by construction)", """
x# = {1,2}
y# = {3,9}
@emlPearsonCorrelation: x#, y#, 2
appendInfoLine: "OUT: error=", emlPearsonCorrelation.error$
appendInfoLine: "OUT: r=", emlPearsonCorrelation.r, " p=", emlPearsonCorrelation.p
"""),

("Spearman", "all values tied in both vectors", """
x# = {3,3,3,3,3}
y# = {7,7,7,7,7}
@emlSpearmanCorrelation: x#, y#, 2
appendInfoLine: "OUT: error=", emlSpearmanCorrelation.error$
appendInfoLine: "OUT: rho=", emlSpearmanCorrelation.rho
"""),

("regression", "x constant (zero predictor variance)", """
x# = {4,4,4,4,4}
y# = {1,2,3,4,5}
@emlLinearRegression: x#, y#
appendInfoLine: "OUT: error=", emlLinearRegression.error$
appendInfoLine: "OUT: slope=", emlLinearRegression.slope, " r2=", emlLinearRegression.rSquared
"""),

("regression", "n=2 (residual df = 0, perfect fit)", """
x# = {1,2}
y# = {3,9}
@emlLinearRegression: x#, y#
appendInfoLine: "OUT: error=", emlLinearRegression.error$
appendInfoLine: "OUT: slope=", emlLinearRegression.slope, " r2=", emlLinearRegression.rSquared
"""),

("Theil-Sen", "n=2", """
x# = {1,2}
y# = {3,9}
@emlTheilSen: x#, y#
appendInfoLine: "OUT: error=", emlTheilSen.error$
appendInfoLine: "OUT: slope=", emlTheilSen.slope
"""),

("Theil-Sen", "all points identical", """
x# = {2,2,2,2}
y# = {5,5,5,5}
@emlTheilSen: x#, y#
appendInfoLine: "OUT: error=", emlTheilSen.error$
appendInfoLine: "OUT: slope=", emlTheilSen.slope
"""),

# ---- rank tests, maximal ties --------------------------------------------
("Mann-Whitney", "every value tied across both groups", """
a# = {4,4,4,4}
b# = {4,4,4,4}
@emlMannWhitneyU: a#, b#, 2
appendInfoLine: "OUT: error=", emlMannWhitneyU.error$
appendInfoLine: "OUT: u1=", emlMannWhitneyU.u1, " p=", emlMannWhitneyU.p
"""),

("Mann-Whitney", "n=1 vs n=1", """
a# = {2}
b# = {8}
@emlMannWhitneyU: a#, b#, 2
appendInfoLine: "OUT: error=", emlMannWhitneyU.error$
appendInfoLine: "OUT: u1=", emlMannWhitneyU.u1, " p=", emlMannWhitneyU.p
"""),

("Wilcoxon", "all differences zero (every pair dropped)", """
a# = {1,2,3,4,5}
b# = {1,2,3,4,5}
@emlWilcoxonSignedRank: a#, b#, 2
appendInfoLine: "OUT: error=", emlWilcoxonSignedRank.error$
appendInfoLine: "OUT: tPlus=", emlWilcoxonSignedRank.tPlus, " p=", emlWilcoxonSignedRank.p
"""),

("Wilcoxon", "one nonzero difference, rest zero", """
a# = {1,2,3,4,5}
b# = {1,2,3,4,9}
@emlWilcoxonSignedRank: a#, b#, 2
appendInfoLine: "OUT: error=", emlWilcoxonSignedRank.error$
appendInfoLine: "OUT: tPlus=", emlWilcoxonSignedRank.tPlus, " p=", emlWilcoxonSignedRank.p
"""),

# ---- normality / moments --------------------------------------------------
("Shapiro-Wilk", "n=2 (below the n>=3 minimum)", """
d# = {3,7}
@emlShapiroWilk: d#
appendInfoLine: "OUT: error=", emlShapiroWilk.error$
appendInfoLine: "OUT: W=", emlShapiroWilk.w, " p=", emlShapiroWilk.p
"""),

("Shapiro-Wilk", "constant vector, n=6", """
d# = {5,5,5,5,5,5}
@emlShapiroWilk: d#
appendInfoLine: "OUT: error=", emlShapiroWilk.error$
appendInfoLine: "OUT: W=", emlShapiroWilk.w, " p=", emlShapiroWilk.p
"""),

("moments", "SD/variance of n=1", """
d# = {5}
@emlSD: d#
appendInfoLine: "OUT: sd=", emlSD.result
@emlVariance: d#
appendInfoLine: "OUT: var=", emlVariance.result
"""),

("moments", "skewness/kurtosis of a constant vector", """
d# = {5,5,5,5,5,5}
@emlSkewness: d#
appendInfoLine: "OUT: skew=", emlSkewness.result
@emlKurtosis: d#
appendInfoLine: "OUT: kurt=", emlKurtosis.result
"""),

# ---- magnitude extremes ---------------------------------------------------
("magnitude", "values near 1e300 (sum of squares overflows)", """
a# = {1e300, 2e300, 3e300}
b# = {1.5e300, 2.5e300, 3.5e300}
@emlTTest: a#, b#, 2, 1
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t, " p=", emlTTest.p
"""),

("magnitude", "values near 1e-300 (underflow)", """
a# = {1e-300, 2e-300, 3e-300}
b# = {1.5e-300, 2.5e-300, 3.5e-300}
@emlTTest: a#, b#, 2, 1
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t, " p=", emlTTest.p
"""),

("magnitude", "large mean, tiny variance (catastrophic cancellation)", """
a# = {1000000.1, 1000000.2, 1000000.3}
b# = {1000000.4, 1000000.5, 1000000.6}
@emlTTest: a#, b#, 2, 1
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t, " p=", emlTTest.p
"""),

# ---- undefined propagation ------------------------------------------------
("undefined", "vector containing undefined", """
d# = {1, 2, undefined, 4}
@emlSD: d#
appendInfoLine: "OUT: sd=", emlSD.result
@emlMedian: d#
appendInfoLine: "OUT: median=", emlMedian.result
"""),

# ---- table-driven: ANOVA / KW / posthoc -----------------------------------
("one-way ANOVA", "all three groups identical constant", """
v# = {5,5,5,5,5,5,5,5,5}
g$# = {"A","A","A","B","B","B","C","C","C"}
@mkTable: v#, g$#
@emlOneWayAnova: mkTable.tableId, "Value", "Group", 0
appendInfoLine: "OUT: error=", emlOneWayAnova.error$
appendInfoLine: "OUT: F=", emlOneWayAnova.fValue, " p=", emlOneWayAnova.p
removeObject: mkTable.tableId
"""),

("one-way ANOVA", "one group has n=1", """
v# = {1,2,3,4,5,6,9}
g$# = {"A","A","A","B","B","B","C"}
@mkTable: v#, g$#
@emlOneWayAnova: mkTable.tableId, "Value", "Group", 0
appendInfoLine: "OUT: error=", emlOneWayAnova.error$
appendInfoLine: "OUT: F=", emlOneWayAnova.fValue, " p=", emlOneWayAnova.p
removeObject: mkTable.tableId
"""),

("one-way ANOVA", "every group has n=1 (within-df = 0)", """
v# = {1,5,9}
g$# = {"A","B","C"}
@mkTable: v#, g$#
@emlOneWayAnova: mkTable.tableId, "Value", "Group", 0
appendInfoLine: "OUT: error=", emlOneWayAnova.error$
appendInfoLine: "OUT: F=", emlOneWayAnova.fValue, " p=", emlOneWayAnova.p
removeObject: mkTable.tableId
"""),

("one-way ANOVA", "extreme imbalance, n=1 vs n=40", """
v# = zero# (41)
for i from 1 to 40
    v# [i] = i
endfor
v# [41] = 500
g$# = empty$# (41)
for i from 1 to 40
    g$# [i] = "A"
endfor
g$# [41] = "B"
@mkTable: v#, g$#
@emlOneWayAnova: mkTable.tableId, "Value", "Group", 0
appendInfoLine: "OUT: error=", emlOneWayAnova.error$
appendInfoLine: "OUT: F=", emlOneWayAnova.fValue, " p=", emlOneWayAnova.p
removeObject: mkTable.tableId
"""),

("Kruskal-Wallis", "all values tied across all groups", """
v# = {7,7,7,7,7,7,7,7,7}
g$# = {"A","A","A","B","B","B","C","C","C"}
@mkTable: v#, g$#
@emlKruskalWallis: mkTable.tableId, "Value", "Group"
appendInfoLine: "OUT: error=", emlKruskalWallis.error$
appendInfoLine: "OUT: H=", emlKruskalWallis.h, " p=", emlKruskalWallis.p
removeObject: mkTable.tableId
"""),

("Kruskal-Wallis", "singleton group among two larger", """
v# = {1,2,3,4,5,6,99}
g$# = {"A","A","A","B","B","B","C"}
@mkTable: v#, g$#
@emlKruskalWallis: mkTable.tableId, "Value", "Group"
appendInfoLine: "OUT: error=", emlKruskalWallis.error$
appendInfoLine: "OUT: H=", emlKruskalWallis.h, " p=", emlKruskalWallis.p
removeObject: mkTable.tableId
"""),

("Tukey HSD", "singleton group among two larger", """
v# = {1,2,3,4,5,6,99}
g$# = {"A","A","A","B","B","B","C"}
@mkTable: v#, g$#
@emlTukeyHSD: mkTable.tableId, "Value", "Group", 0.05
appendInfoLine: "OUT: error=", emlTukeyHSD.error$
appendInfoLine: "OUT: nPairs=", emlTukeyHSD.nPairs, " p12=", emlTukeyHSD.pMatrix## [1,2], " q12=", emlTukeyHSD.qMatrix## [1,2]
removeObject: mkTable.tableId
"""),

("Tukey HSD", "all groups identical constant", """
v# = {5,5,5,5,5,5,5,5,5}
g$# = {"A","A","A","B","B","B","C","C","C"}
@mkTable: v#, g$#
@emlTukeyHSD: mkTable.tableId, "Value", "Group", 0.05
appendInfoLine: "OUT: error=", emlTukeyHSD.error$
appendInfoLine: "OUT: nPairs=", emlTukeyHSD.nPairs, " p12=", emlTukeyHSD.pMatrix## [1,2], " q12=", emlTukeyHSD.qMatrix## [1,2]
removeObject: mkTable.tableId
"""),

("Dunn", "all values tied (audit item 9 regression guard)", """
v# = {7,7,7,7,7,7,7,7,7}
g$# = {"A","A","A","B","B","B","C","C","C"}
@mkTable: v#, g$#
@emlDunnTest: mkTable.tableId, "Value", "Group", "bonferroni"
appendInfoLine: "OUT: error=", emlDunnTest.error$
appendInfoLine: "OUT: z11=", emlDunnTest.zMatrix## [1,2]
removeObject: mkTable.tableId
"""),

("pairwise t", "one group constant, others varied", """
v# = {5,5,5,1,2,3,7,8,9}
g$# = {"A","A","A","B","B","B","C","C","C"}
@mkTable: v#, g$#
@emlPairwiseT: mkTable.tableId, "Value", "Group", "holm", "student"
appendInfoLine: "OUT: error=", emlPairwiseT.error$
appendInfoLine: "OUT: p12=", emlPairwiseT.pMatrix## [1,2]
removeObject: mkTable.tableId
"""),

# ---- empty / malformed ----------------------------------------------------
("empty", "zero-length vectors to t-test", """
a# = zero# (0)
b# = zero# (0)
@emlTTest: a#, b#, 2, 1
appendInfoLine: "OUT: error=", emlTTest.error$
appendInfoLine: "OUT: t=", emlTTest.t
"""),

("empty", "single group only, ANOVA needs >= 2", """
v# = {1,2,3}
g$# = {"A","A","A"}
@mkTable: v#, g$#
@emlOneWayAnova: mkTable.tableId, "Value", "Group", 0
appendInfoLine: "OUT: error=", emlOneWayAnova.error$
appendInfoLine: "OUT: F=", emlOneWayAnova.fValue
removeObject: mkTable.tableId
"""),
]


def run_case(tmpdir, idx, body):
    path = os.path.join(tmpdir, "case%02d.praat" % idx)
    with open(path, "w") as fh:
        fh.write(INCLUDES + TABLE_HELPER + "\nwriteInfoLine: \"BEGIN\"\n"
                 + body + "\nappendInfoLine: \"END\"\n")
    try:
        pr = subprocess.run([PRAAT, "--run", path], capture_output=True,
                            text=True, timeout=TIMEOUT)
        return pr.returncode, pr.stdout, pr.stderr
    except subprocess.TimeoutExpired:
        return "TIMEOUT", "", ""


def classify(rc, out, err):
    """Four outcomes.

    CONTRACT  .error$ set AND the output variables are readable (nulled to
              undefined). A caller that reads outputs before checking
              .error$ still gets a guardable value.
    UNSET     .error$ set but the output variables were never assigned, so
              reading one aborts the interpreter with "Unknown variable".
              The error contract is honoured; the output contract is not.
              A caller must check .error$ FIRST or the script dies.
    VALUE     a number came back.
    CRASH     the interpreter died with no error string at all.
    """
    if rc == "TIMEOUT":
        return "CRASH", "process hung; killed at %ds" % TIMEOUT
    lines = [l[5:].strip() for l in out.splitlines() if l.startswith("OUT: ")]
    errline = next((l for l in lines if l.startswith("error=")), None)
    vals = " ; ".join(l for l in lines if not l.startswith("error="))
    if "END" not in out:
        raw = (err.strip() or out.strip()).replace("\n", " / ")
        unknown = "Unknown variable" in raw
        if errline and errline != "error=" and unknown:
            m = re.search(r"« appendInfoLine: \"OUT: [^\"]*\", ([A-Za-z_][\w.#]*)", raw)
            which = m.group(1) if m else "an output variable"
            return "UNSET", "%s  ->  %s never assigned" % (errline[6:], which)
        return "CRASH", "interpreter died: %s" % raw[:200]
    if errline and errline != "error=":
        return "CONTRACT", errline[6:] + ("  ->  " + vals if vals else "")
    return "VALUE", vals or "(no output captured)"


def main():
    if not os.path.exists(PRAAT):
        sys.exit("praat_barren not found at %s" % PRAAT)
    tally = {"CONTRACT": 0, "UNSET": 0, "VALUE": 0, "CRASH": 0}
    rows = []
    with tempfile.TemporaryDirectory() as tmp:
        for i, (fam, name, body) in enumerate(CASES, 1):
            rc, out, err = run_case(tmp, i, body)
            kind, detail = classify(rc, out, err)
            tally[kind] += 1
            rows.append((fam, name, kind, detail))
            print("[%2d/%d] %-9s %-16s %s" % (i, len(CASES), kind, fam, name))

    print("\n" + "=" * 78)
    for fam, name, kind, detail in rows:
        print("\n%-16s %s\n    %-9s %s" % (fam, name, kind, detail))
    print("\n" + "=" * 78)
    print("cases=%d  CONTRACT=%d  UNSET=%d  VALUE=%d  CRASH=%d"
          % (len(CASES), tally["CONTRACT"], tally["UNSET"], tally["VALUE"],
             tally["CRASH"]))
    print("CRASH is always a defect. UNSET is a contract inconsistency: the\n"
          "procedure set .error$ but left its outputs unassigned, so a caller\n"
          "that reads an output before testing .error$ aborts. VALUE needs\n"
          "eyes: a number on a degenerate input is a defect only if it reads\n"
          "as a completed test when none was possible.")
    sys.exit(1 if tally["CRASH"] else 0)


if __name__ == "__main__":
    main()
