#!/usr/bin/env python3
# ============================================================================
# banner_historical.py -- one mechanical line at the top of every historical
# record, saying that it is one.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULE, 18 August 2026. audit/FINDINGS_MACHINE.json is the only surface
# that states current finding status. Everything else dated in audit/ is a
# HISTORICAL RECORD: true at its date, never updated afterwards. That is a
# better discipline than keeping ten documents current -- nobody ever did, and
# the failure mode of trying is a stale sentence sitting beside its own
# correction looking equally authoritative.
#
# But a document that is only historical BY CONVENTION reads exactly like a
# document that is current, and a reader four hundred lines in has no way to
# tell. So each one says so on line 1, in the same words, applied by script,
# so that the claim cannot be made unevenly and cannot be forgotten on the
# next file somebody adds.
#
# THE DATE. Taken from the filename when the filename carries one -- those are
# the documents whose own name asserts what they are about -- and otherwise
# from the file's last commit date, which is the last moment anybody stood
# behind its contents. Never from mtime: a checkout sets mtime and asserts
# nothing.
#
# IDEMPOTENT. A file that already carries the banner is left alone, so this
# can be re-run after adding a document without churning the other nine.
#
# USAGE
#   python3 validate/tools/banner_historical.py           # apply
#   python3 validate/tools/banner_historical.py --check   # report, don't write
# ============================================================================

import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

# The ten. Every dated document at the top of audit/ except the register view
# and the narrative, plus the plugin's own history ledger. Listed rather than
# globbed: a glob would silently pick up the next file somebody drops in
# audit/, which might be a live document, and banner it as history.
TARGETS = [
    "audit/AUDIT_RESPONSE_STATUS_20260815.md",
    "audit/AUTHOR_RULINGS_ADDENDUM_2026-08-14.md",
    "audit/DRIVE_FINDINGS_2026-08-04.md",
    "audit/EML_AUDIT_REPORT_2026-08-14.md",
    "audit/GRAPHING_PUSH_REMAINING.md",
    "audit/PHASE_ONE_AUDIT_2026-08-06.md",
    "audit/PROPOSAL_factor_post_dispatch.md",
    "audit/TODO_REMOTE_CLEANUP.md",
    "audit/VERIFICATION_2026-08-06.md",
    "plugin_EML_StatsGraphs/dev/HISTORY_LEDGER.md",
]

MARK = "**Historical record ("
TMPL = ("> **Historical record (%s).** Current finding status lives in "
        "`audit/FINDINGS_MACHINE.json`.")

DATE_IN_NAME = re.compile(r"(20\d{2})[-_]?(\d{2})[-_]?(\d{2})")


def date_for(rel):
    m = DATE_IN_NAME.search(os.path.basename(rel))
    if m:
        return "%s-%s-%s" % m.groups()
    r = subprocess.run(["git", "-C", ROOT, "log", "-1", "--format=%ad",
                        "--date=short", "--", rel],
                       capture_output=True, text=True, timeout=30)
    d = r.stdout.strip()
    if not d:
        raise SystemExit("banner_historical: no date for %s (not committed?)" % rel)
    return d


def main():
    check = "--check" in sys.argv[1:]
    changed, already, missing = [], [], []
    for rel in TARGETS:
        full = os.path.join(ROOT, rel)
        if not os.path.exists(full):
            missing.append(rel)
            continue
        with open(full, encoding="utf-8") as fh:
            text = fh.read()
        first = text.split("\n", 1)[0]
        if MARK in first:
            already.append(rel)
            continue
        banner = TMPL % date_for(rel)
        if not check:
            with open(full, "w", encoding="utf-8") as fh:
                fh.write(banner + "\n\n" + text)
        changed.append(rel)

    for rel in already:
        print("OK      already bannered  %s" % rel)
    for rel in changed:
        print("%s %s" % ("NEEDS   banner       " if check else "BANNERED             ", rel))
    for rel in missing:
        print("MISSING              %s" % rel)

    if missing:
        print("\n%d target(s) missing -- the list names a file that is not there"
              % len(missing))
        return 1
    if check and changed:
        print("\n%d file(s) lack the banner" % len(changed))
        return 1
    print("\n%d of %d bannered" % (len(already) + len(changed), len(TARGETS)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
