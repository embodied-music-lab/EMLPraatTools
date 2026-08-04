#!/usr/bin/env python3
# scan-assertion-vacuity.py -- classify every numeric assertion in a Praat test
# directory by how much discriminating power it actually has.
#
# An absolute-tolerance assertion whose expected value is no larger than its
# own tolerance cannot tell the true value from zero. Such a site is green by
# construction. This scanner measures |expected| / tolerance at every call and
# reports:
#   CLASS A  ratio <= 1     vacuous     (fails the run)
#   CLASS B  ratio < 10     weak
#   CLASS C  expected == 0  intentional zero target
#   CLASS D  relative-tolerance site
#   CLASS E  relative tolerance with expected == 0 -- harness misuse (fails)
#   CLASS F  expected is runtime-valued (symmetry / passthrough assertion):
#            vacuity is not statically decidable, reported not failed
#
# It also reports its own parse coverage: an assertion it could not parse is
# counted as a failure, not skipped silently, because an unparsed site is
# indistinguishable from a vacuous one. A tolerance token it cannot resolve to
# a number is likewise a failure -- an unresolved tolerance hides exactly the
# ratio this scanner exists to measure.
#
# Tolerance resolution: every top-level `name = <numeric literal>` assignment in
# the file is harvested, not just names containing "toler" (the earlier rule
# silently missed tsTol / tsExact / tsTolZero in test-theilsen.praat and left
# 28 sites unmeasured). A name assigned twice with DIFFERENT values is treated
# as unresolvable rather than guessed at.
#
# Usage: scan-assertion-vacuity.py [directory]   (default: dev/tests/phase2)
# Exit:  0 = clean   1 = vacuous / unparsed / unresolved-tol / misuse present
#
import re, glob, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGIN = os.path.abspath(os.path.join(HERE, "..", ".."))
D = sys.argv[1] if len(sys.argv) > 1 else os.path.join(PLUGIN, "dev", "tests", "phase2")
totN=0; totR=0; parsed=0; unmatched=[]; badtol=[]; runtime_exp=[]
subtol=[]; weak=[]; zero_target=[]; relsites=[]; relmisuse=[]

def logical_lines(src):
    out=[]; buf=None; start=0
    for i, raw in enumerate(src, 1):
        s = raw.rstrip()
        cont = re.match(r"\s*\.\.\.\s?(.*)$", s)
        if cont:
            if buf is None: buf, start = cont.group(1), i
            else: buf = buf + " " + cont.group(1)
        else:
            if buf is not None: out.append((start, buf)); buf=None
            buf, start = s, i
    if buf is not None: out.append((start, buf))
    return out

for path in sorted(glob.glob(os.path.join(D, "*.praat"))):
    base=os.path.basename(path)
    src=open(path,encoding="utf-8",errors="replace").read().splitlines()
    # Harvest EVERY numeric scalar assignment, not only names containing
    # "toler" -- the tolerance slot is filled by whatever name the suite
    # author chose (tsTol, tsExact, tsTolZero, ...). Conflicting reassignment
    # makes a name unresolvable; it must not be silently guessed.
    tol={}; conflicted=set()
    for ln in src:
        m=re.match(r"\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*([0-9.eE+-]+)\s*(?:;.*)?$", ln)
        if not m: continue
        try: v=float(m.group(2))
        except ValueError: continue
        name=m.group(1)
        if name in tol and tol[name]!=v: conflicted.add(name)
        tol[name]=v
    for name in conflicted: tol.pop(name, None)
    for lineno, ln in logical_lines(src):
        if ln.lstrip().startswith("#"): continue
        isRel = "AssertEqualRel" in ln
        isNum = "AssertEqualNum" in ln
        if not (isRel or isNum): continue
        kw = "Rel" if isRel else "Num"
        if isRel: totR+=1
        else: totN+=1
        m=re.match(r'\s*@emlTestAssertEqual'+kw+r':\s*"([^"]*)"\s*,\s*(.+?)\s*,\s*(.+)\s*,\s*([^,;]+?)\s*(?:;.*)?$', ln)
        if not m: unmatched.append((base,lineno,ln.strip())); continue
        parsed+=1
        label, exp_s, actual, tol_s = m.groups()
        # Resolve the tolerance FIRST: it is reportable even when the expected
        # value is runtime-valued, and an unresolved tolerance is a blind spot
        # regardless of which side of the comparison is static.
        t=tol.get(tol_s.strip())
        if t is None:
            try: t=float(tol_s.strip())
            except ValueError:
                reason = ("reassigned with conflicting values"
                          if tol_s.strip() in conflicted else "never assigned a literal")
                badtol.append((base,lineno,label,tol_s.strip(),reason)); continue
        try: exp=float(exp_s)
        except ValueError:
            # Symmetry / passthrough site: expected is another runtime quantity.
            # |expected|/tol cannot be computed statically. Report with its
            # tolerance so the ratio can be judged by hand; do not fail.
            runtime_exp.append((base,lineno,label,exp_s,t,kw)); continue
        a=abs(exp)
        if isRel:
            # A relative band is vacuous only if expected == 0 (misuse) -- @emlTestAssertEqualRel
            # fails such a call by design. Record band for reporting; no vacuity possible otherwise.
            if a==0.0: relmisuse.append((base,lineno,label,t))
            else: relsites.append((base,lineno,label,exp,t))
            continue
        if a==0.0: zero_target.append((base,lineno,label,t))
        elif a<=t:  subtol.append((base,lineno,label,exp,t,a/t))
        elif a<10*t: weak.append((base,lineno,label,exp,t,a/t))

print("AssertEqualNum logical lines : %d" % totN)
print("AssertEqualRel logical lines : %d" % totR)
print("parsed                       : %d / %d" % (parsed, totN+totR))
print("MISSED (unparsed)            : %d" % len(unmatched))
for r in unmatched[:15]: print("   %s:%d %s" % (r[0],r[1],r[2][:110]))
print("UNRESOLVED TOLERANCE         : %d" % len(badtol))
for r in badtol: print("   %s:%d %-32s tol=%-14s (%s)" % r)
print()
print("== CLASS A: nonzero expected <= ABSOLUTE tolerance  (0 would also pass) ==")
for b,i,l,e,t,r in sorted(subtol,key=lambda x:x[5]):
    print("  %-30s:%-4d %-32s exp=%-13.6g tol=%-9g ratio=%.3f"%(b,i,l[:32],e,t,r))
print("  count: %d"%len(subtol))
print()
print("== CLASS B: nonzero expected < 10x ABSOLUTE tolerance (weak) ==")
for b,i,l,e,t,r in sorted(weak,key=lambda x:x[5]):
    print("  %-30s:%-4d %-32s exp=%-13.6g tol=%-9g ratio=%.2f"%(b,i,l[:32],e,t,r))
print("  count: %d"%len(weak))
print()
print("== CLASS C: expected == 0 with absolute tol (legitimate zero-target) ==  count: %d"%len(zero_target))
print("== CLASS D: relative-tolerance sites (not vacuity-capable) ==  count: %d"%len(relsites))
print("== CLASS E: MISUSE - relative tolerance with expected == 0 ==  count: %d"%len(relmisuse))
for r in relmisuse: print("   %s:%d %s band=%g"%r)
print()
print("== CLASS F: expected is runtime-valued (vacuity not statically decidable) ==")
for b,i,l,e,t,k in sorted(runtime_exp,key=lambda x:(x[0],x[1])):
    print("  %-30s:%-4d %-32s exp=%-34s tol=%-9g [%s]"%(b,i,l[:32],e[:34],t,k))
print("  count: %d"%len(runtime_exp))
print("  NOTE: both sides are computed at run time, so |expected|/tol cannot be")
print("        formed here. Each site's tolerance is printed above for hand review.")

bad = len(subtol) + len(unmatched) + len(relmisuse) + len(badtol)
print()
print("VERDICT: %s  (vacuous=%d unparsed=%d misuse=%d unresolved-tol=%d)"
      % ("CLEAN" if not bad else "DEFECTS PRESENT",
         len(subtol), len(unmatched), len(relmisuse), len(badtol)))
sys.exit(1 if bad else 0)
