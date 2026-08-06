#!/usr/bin/env python3
# ============================================================================
# check_calls.py -- every @procedure a script can reach must be defined.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Praat resolves a procedure name at CALL time, not at parse time. A script
# can therefore include the wrong set of modules and look perfectly healthy
# until a user walks the one branch that calls the missing procedure -- which
# is exactly what D100 and D101 were. This generalises both of them.
#
# For every script under plugin/scripts/, it flattens the include graph
# (expanding the eml-lib*.praat barrels), collects every procedure defined
# anywhere in that set, collects every @call, and reports the difference.
#
#     python3 validate/tools/check_calls.py
#
# Run from the repository root. Exit code is not set; read the last line.
# ============================================================================

import os,re,glob
SD='plugin/scripts'
def flatten(path, seen=None, out=None):
    out = [] if out is None else out
    seen = set() if seen is None else seen
    for ln in open(path, encoding='utf-8', errors='replace').read().split('\n'):
        if ln.startswith('include '):
            t = os.path.normpath(os.path.join(SD, ln[8:].strip()))
            if t in seen: continue
            seen.add(t)
            if os.path.basename(t).startswith('eml-lib'):
                flatten(t, seen, out)
            elif os.path.exists(t):
                out.append(t)
    return out

def procs(f):
    return set(re.findall(r'^procedure\s+([A-Za-z_][A-Za-z0-9_]*)', 
               open(f,encoding='utf-8',errors='replace').read(), re.M))
def calls(f):
    return set(re.findall(r'^\s*\@\s*([A-Za-z_][A-Za-z0-9_]*)',
               open(f,encoding='utf-8',errors='replace').read(), re.M))

bad = 0
for s in sorted(glob.glob(SD+'/*.praat')):
    if os.path.basename(s).startswith('eml-lib'): continue
    mods = flatten(s)
    defined = procs(s)
    for m in mods: defined |= procs(m)
    used = calls(s)
    for m in mods: used |= calls(m)
    missing = sorted(used - defined)
    if missing:
        bad += 1
        print(f"{os.path.basename(s)}")
        for x in missing: print(f"    @{x}  -- called, never defined in anything it loads")
print(f"\nscripts with unresolvable calls: {bad}")
