#!/usr/bin/env python3
"""
Static check: every procedure a Praat script calls must be defined somewhere
in that script's own include closure.

Why this exists
---------------
On 6 August the describe wrapper was changed to call
@emlReportDescriptiveAnalysis, which lives in stats/eml-analysis.praat. The
wrapper does not include that module. Praat resolves procedure names at CALL
time, not at parse time, so:

  - the parse check passed;
  - the menu item opened normally;
  - "Procedure not found" was raised at line 9434 the instant Run was clicked.

Only driving the GUI found it. This script finds the same class of defect
without a display, in under a second, and is meant to run before any drive.

Usage:  python3 harness/check_includes.py [plugin-dir]
Exit:   0 clean, 1 if any call is unresolved.
"""
import os
import re
import sys

DEF = re.compile(r'^\s*procedure\s+([A-Za-z_][A-Za-z0-9_]*)', re.M)
CALL = re.compile(r'@\s*([A-Za-z_][A-Za-z0-9_]*)')
INC = re.compile(r'^\s*include\s+(\S.*?)\s*$', re.M)
# A "@" inside a string literal or a comment is not a call.
COMMENT = re.compile(r'^\s*#.*$', re.M)
STRING = re.compile(r'"[^"\n]*"')


def strip_noise(src):
    src = COMMENT.sub('', src)
    return STRING.sub('""', src)


def closure(path, seen=None):
    """Resolve include: directives depth-first. Praat resolves a relative
    include against the INCLUDING file's directory."""
    if seen is None:
        seen = []
    path = os.path.realpath(path)
    if path in seen or not os.path.isfile(path):
        return seen
    seen.append(path)
    src = open(path, encoding='utf-8', errors='replace').read()
    for rel in INC.findall(src):
        closure(os.path.join(os.path.dirname(path), rel), seen)
    return seen


# Entry points whose unresolved calls are a KNOWN, documented state rather
# than a defect. Each needs a reason and a way back; an entry here is a
# promise that the call is unreachable, not that it is harmless.
KNOWN = {
    'eml-tutorial.praat':
        'include of tutorial/eml-demo-procedures.praat deliberately '
        'neutralised (v0.19 item 4); restoring the include restores '
        'the calls',
}


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else 'plugin'
    entries = []
    for sub in ('scripts', ''):
        d = os.path.join(root, sub) if sub else root
        if os.path.isdir(d):
            entries += [os.path.join(d, f) for f in sorted(os.listdir(d))
                        if f.endswith('.praat')]
    problems = 0
    for entry in entries:
        files = closure(entry)
        defined = set()
        for f in files:
            defined |= set(DEF.findall(
                open(f, encoding='utf-8', errors='replace').read()))
        called = set()
        for f in files:
            called |= set(CALL.findall(strip_noise(
                open(f, encoding='utf-8', errors='replace').read())))
        missing = sorted(called - defined)
        if missing:
            base = os.path.basename(entry)
            if base in KNOWN:
                print('KNOWN in %s: %d unresolved call(s) — %s'
                      % (base, len(missing), KNOWN[base]))
                continue
            problems += 1
            print('UNRESOLVED in %s (%d file(s) in closure):'
                  % (os.path.relpath(entry, root), len(files)))
            for m in missing:
                # Report where it IS defined, if anywhere in the tree, so the
                # fix is one line rather than a search.
                where = []
                for dirpath, _, names in os.walk(root):
                    for n in names:
                        if not n.endswith('.praat'):
                            continue
                        p = os.path.join(dirpath, n)
                        if m in DEF.findall(
                                open(p, encoding='utf-8',
                                     errors='replace').read()):
                            where.append(os.path.relpath(p, root))
                print('    @%s%s' % (
                    m, ('  [defined in ' + ', '.join(where) + ']')
                    if where else '  [not defined anywhere]'))
    if problems == 0:
        print('include closure: every @call resolves, %d entry script(s)'
              % len(entries))
        return 0
    print('\n%d entry script(s) with unresolved calls' % problems)
    return 1


if __name__ == '__main__':
    sys.exit(main())
