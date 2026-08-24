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
# A procedure's own line, and the line that closes it. Praat's `endproc` sits
# at column zero in this tree, but the opener may be indented in generated
# fragments, so the opener is matched loosely and the closer strictly.
PROC_OPEN = re.compile(r'^\s*procedure\s+([A-Za-z_][A-Za-z0-9_]*)')
PROC_CLOSE = re.compile(r'^\s*endproc\s*$')
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


def top_level_calls(path):
    """Calls made by a file's own statements, outside any procedure body.

    An entry script's execution starts here: whatever it calls at the top
    level, plus whatever those calls reach, is the whole of what it can run.
    A `procedure` body is skipped -- it runs only if something calls it, which
    is the question this function's caller is asking.
    """
    out = []
    depth = 0
    src = open(path, encoding='utf-8', errors='replace').read()
    for lineno, raw in enumerate(src.splitlines(), 1):
        code = strip_noise(raw)
        if PROC_OPEN.match(code):
            depth = 1
            continue
        if depth and PROC_CLOSE.match(code):
            depth = 0
            continue
        if depth:
            continue
        for name in CALL.findall(code):
            out.append((name, lineno))
    return out


def procedure_bodies(files):
    """name -> [(called name, defining file, line), ...] over a whole closure.

    One pass, so the walk below is a lookup rather than a re-read per step.
    """
    bodies = {}
    for path in files:
        src = open(path, encoding='utf-8', errors='replace').read()
        cur = None
        for lineno, raw in enumerate(src.splitlines(), 1):
            code = strip_noise(raw)
            m = PROC_OPEN.match(code)
            if m:
                cur = m.group(1)
                bodies.setdefault(cur, [])
                continue
            if cur is not None and PROC_CLOSE.match(code):
                cur = None
                continue
            if cur is None:
                continue
            for name in CALL.findall(code):
                bodies[cur].append((name, path, lineno))
    return bodies


def reachable_calls(entry, files):
    """Every call an entry script can actually make, with where it is made.

    WHY REACHABILITY AND NOT TEXT.
    
    A module is included whole. stats/eml-record.praat is the only one that
    can be included from three different top-level folders -- it carries no
    relative include of its own -- so setup.praat, the quick start and the
    editor's recording hand-off all pull it in for one small procedure each.
    It brings @emlRecordReplaySave with it, which is what a REPLAYED script
    uses to write its files, and that procedure calls six others from modules
    none of those three entry points has any reason to parse.
    
    Reading the closure's TEXT reports those six as unresolved in all three,
    and the answer has been three near-identical exemptions naming the same
    six procedures for the same reason -- a table that grows by one entry
    every time somebody includes the recorder for a different small reason.
    
    Reading the CALL GRAPH answers it once: none of the three can reach
    @emlRecordReplaySave, so its calls are not theirs. What remains reported
    is what an entry script can genuinely run into.
    
    The walk starts at the file's own top-level statements and follows only
    procedures whose bodies are in the closure. A call to something the
    closure does not define is a leaf AND a finding -- that is the defect
    this file exists for.
    """
    bodies = procedure_bodies(files)
    found = []
    seen = set()
    frontier = [(n, entry, ln) for n, ln in top_level_calls(entry)]
    while frontier:
        name, site, lineno = frontier.pop()
        found.append((name, site, lineno))
        if name in seen:
            continue
        seen.add(name)
        for inner, ipath, iline in bodies.get(name, ()):
            frontier.append((inner, ipath, iline))
    return found


# Entry points whose unresolved calls are a KNOWN, documented state rather
# than a defect. Each needs a reason and a way back; an entry here is a
# promise that the call is unreachable, not that it is harmless.
#
# A value may be a reason alone, which exempts the whole file, or a (reason,
# names) pair, which exempts EXACTLY those names. The pair form is the one to
# reach for: a blanket exemption also hides the next unresolved call somebody
# adds to that file, and an entry script with a partial closure for one stated
# reason is not an entry script that may call anything at all.
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
    # AN EXEMPTION THAT MATCHES NOTHING IS REPORTED, not quietly kept. This
    # table is a list of promises that a named call is unreachable; a promise
    # about a call the tree no longer makes tells its reader the tree still
    # holds something it does not, and the next person to read it believes the
    # exemption is doing work. Emptied as each entry is consulted.
    unused_known = set(KNOWN)
    for entry in entries:
        if is_barrel(entry):
            barrels.append(os.path.relpath(entry, root))
            continue
        files = closure(entry)
        defined = set()
        for f in files:
            defined |= defs_in(f)
        # THE EXISTENCE-GUARDED CALLS ARE COUNTED OVER THE WHOLE CLOSURE, and
        # deliberately so: a call on the true arm of `if variableExists (...)`
        # is optional wherever it sits, and the count is a population figure
        # that would drop silently if it were narrowed to the reachable set.
        guarded_names = set()
        for f in files:
            for name, lineno, is_guarded in calls_in(f):
                if is_guarded and name not in defined:
                    guarded_names.add(name)
                    optional += 1

        # WHAT AN ENTRY SCRIPT CAN RUN INTO, not what its closure contains.
        missing = {}
        for name, site, lineno in reachable_calls(entry, files):
            if name in defined or name in guarded_names:
                continue
            missing.setdefault(name, (os.path.relpath(site, root), lineno))
        if missing:
            base = os.path.basename(entry)
            if base in KNOWN:
                unused_known.discard(base)
                entry_known = KNOWN[base]
                if isinstance(entry_known, tuple):
                    reason, allowed = entry_known
                else:
                    reason, allowed = entry_known, None
                # A named exemption covers what it names and nothing else, so
                # a call that arrives later is still reported. An exemption
                # that has stopped matching anything is reported too: it tells
                # its reader the tree still holds a call it does not.
                if allowed is None or set(missing) == allowed:
                    print('KNOWN in %s: %d unresolved call(s) — %s'
                          % (base, len(missing), reason))
                    continue
                print('KNOWN SET CHANGED in %s: exempted %s, found %s'
                      % (base, ' '.join(sorted(allowed)),
                         ' '.join(sorted(missing))))
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
        if unused_known:
            print('STALE EXEMPTION: %s exempts a call the tree no longer '
                  'makes. Delete the entry -- an exemption nobody consults '
                  'reads as protection that is not there.'
                  % ', '.join(sorted(unused_known)))
            return 1
        print('include closure: every @call resolves, %d entry script(s), '
              '%d existence-guarded optional call(s) allowed'
              % (len(entries) - len(barrels), optional))
        return 0
    print('\n%d entry script(s) with unresolved calls' % problems)
    return 1


if __name__ == '__main__':
    sys.exit(main())
