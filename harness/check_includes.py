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

What counts as a call (16 Aug 2026)
-----------------------------------
The first cut of this checker read "@name" anywhere outside a "#" comment.
That was wrong in three ways and the result was 22 red entry scripts, none of
which described a defect a user could reach:

  1. PRAAT HAS THREE COMMENT CHARACTERS, NOT ONE. A line whose first
     non-blank character is "#", ";" or "!" is a comment, and ";" is also a
     comment to end of line when it appears after a statement. Measured
     against Praat 6.6.30 -- `x = 1 ; trailing` assigns 1, while `x = 1 #
     trailing` is "Error: Unknown symbol". This tree writes 105 ";" comment
     lines in scripts/ alone, and the draw layer's design notes name
     procedures in prose. One such note (@thisProcedureDoesNotExist, in
     graphs/eml-draw-procedures.praat, recording the 10 Aug measurement that
     a guarded call to a nonexistent procedure is free) was reported as an
     unresolved call in 19 of the 22 entry scripts.

  2. AN INCLUDE LIST IS NOT AN ENTRY POINT. scripts/eml-lib*.praat are
     barrels: comments and `include` lines, nothing else. eml-lib-graphs.praat
     says in its own header that it is not usable alone. Checking a barrel as
     if it were a script asserts something the barrel never claimed, and the
     unresolved calls it produced were just the layers the barrel does not
     name. Barrels are listed as skipped, with the reason, rather than
     silently dropped.

  3. AN EXISTENCE-GUARDED CALL CANNOT RAISE. Praat only errors on an
     undefined procedure when it EXECUTES the call, so the draw layer calls
     the optional recorder inside `if variableExists ("emlRecordLoaded")`
     and a caller that never loaded the recorder executes nothing. That is a
     deliberate, documented shape (graphs/eml-draw-procedures.praat, and the
     note in scripts/eml-lib-graphs.praat about the duplicate-label failure
     it replaced). A call inside such a guard is optional by construction and
     is not a missing include.

The guard is recognised only on the TRUE arm: after `else` or `elsif` the
protection is gone, because that arm runs precisely when the variable is
absent.

Usage:  python3 harness/check_includes.py [plugin-dir]
Exit:   0 clean, 1 if any call is unresolved.
"""
import os
import re
import sys

DEF = re.compile(r'^\s*procedure\s+([A-Za-z_][A-Za-z0-9_]*)', re.M)
CALL = re.compile(r'@\s*([A-Za-z_][A-Za-z0-9_]*)')
INC = re.compile(r'^\s*include\s+(\S.*?)\s*$', re.M)

# Praat comments: a line whose first non-blank character is "#", ";" or "!".
FULL_LINE_COMMENT = re.compile(r'^\s*[#;!]')
# A string literal can hold a "@" or a ";" that is neither call nor comment.
STRING = re.compile(r'"[^"\n]*"')
# ";" after a statement comments out the rest of the line (unlike "#").
TRAILING_SEMI = re.compile(r';.*$')

# Block openers/closers, for tracking which lines sit inside a guard.
OPEN_IF = re.compile(r'^\s*if\b')
ELSE_IF = re.compile(r'^\s*(else|elsif|elif)\b')
END_IF = re.compile(r'^\s*endif\b')
# The existence guard: `if variableExists ("emlRecordLoaded")` and friends.
# Praat has no procedureExists, so a load-time flag variable is the idiom.
GUARD = re.compile(r'\bvariableExists\s*[:(]')


def strip_noise(line):
    """Return the executable part of one source line.

    Order matters: full-line comments go first (they are anchored at the
    start of the line, so no string literal can be mistaken for one), then
    string literals are blanked, then a trailing ";" comment is cut. Cutting
    the ";" before blanking strings would truncate any line holding a
    semicolon inside a quoted string.
    """
    if FULL_LINE_COMMENT.match(line):
        return ''
    return TRAILING_SEMI.sub('', STRING.sub('""', line))


def calls_in(path):
    """(name, line-number, guarded) for every @call in one file.

    `guarded` is True when the call sits on the true arm of an
    `if variableExists (...)` block, at any nesting depth.
    """
    out = []
    # One entry per open `if`: True while we are on a guarded true arm.
    stack = []
    src = open(path, encoding='utf-8', errors='replace').read()
    for lineno, raw in enumerate(src.splitlines(), 1):
        code = strip_noise(raw)
        if not code.strip():
            continue
        if END_IF.match(code):
            if stack:
                stack.pop()
            continue
        if ELSE_IF.match(code):
            # The false arm runs exactly when the variable is absent, so it
            # is not protected -- even if the `elsif` itself tests existence,
            # which would be a fresh guard we do not try to model.
            if stack:
                stack[-1] = False
            continue
        if OPEN_IF.match(code):
            stack.append(bool(GUARD.search(code)))
            # An `if` line can carry no call, so nothing else to do.
            continue
        guarded = any(stack)
        for name in CALL.findall(code):
            out.append((name, lineno, guarded))
    return out


def defs_in(path):
    return set(DEF.findall(
        open(path, encoding='utf-8', errors='replace').read()))


def is_barrel(path):
    """True for a file that is comments and `include` lines and nothing else.

    scripts/eml-lib.praat and its three siblings exist so the file list is
    written down once. They define no procedure and execute no statement, so
    "does every call in this closure resolve" is not a question they answer:
    the closure is a fragment by construction.
    """
    for raw in open(path, encoding='utf-8', errors='replace').read().splitlines():
        code = strip_noise(raw).strip()
        if not code:
            continue
        if not code.startswith('include '):
            return False
    return True


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
        'neutralised; restoring the include restores '
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
    barrels = []
    optional = 0
    for entry in entries:
        if is_barrel(entry):
            barrels.append(os.path.relpath(entry, root))
            continue
        files = closure(entry)
        defined = set()
        for f in files:
            defined |= defs_in(f)
        missing = {}
        for f in files:
            for name, lineno, guarded in calls_in(f):
                if name in defined:
                    continue
                if guarded:
                    optional += 1
                    continue
                missing.setdefault(name, (os.path.relpath(f, root), lineno))
        if missing:
            base = os.path.basename(entry)
            if base in KNOWN:
                print('KNOWN in %s: %d unresolved call(s) — %s'
                      % (base, len(missing), KNOWN[base]))
                continue
            problems += 1
            print('UNRESOLVED in %s (%d file(s) in closure):'
                  % (os.path.relpath(entry, root), len(files)))
            for m in sorted(missing):
                site, lineno = missing[m]
                # Report where it IS defined, if anywhere in the tree, so the
                # fix is one line rather than a search.
                where = []
                for dirpath, _, names in os.walk(root):
                    for n in names:
                        if not n.endswith('.praat'):
                            continue
                        p = os.path.join(dirpath, n)
                        if m in defs_in(p):
                            where.append(os.path.relpath(p, root))
                print('    @%s  called at %s:%d%s' % (
                    m, site, lineno,
                    ('  [defined in ' + ', '.join(sorted(where)) + ']')
                    if where else '  [not defined anywhere]'))
    for b in sorted(barrels):
        print('skipped %s: include list only — no procedure, no statement, '
              'so its closure is a fragment by design' % b)
    if problems == 0:
        print('include closure: every @call resolves, %d entry script(s), '
              '%d existence-guarded optional call(s) allowed'
              % (len(entries) - len(barrels), optional))
        return 0
    print('\n%d entry script(s) with unresolved calls' % problems)
    return 1


if __name__ == '__main__':
    sys.exit(main())
