#!/usr/bin/env bash
# ============================================================================
# wrappers/run.sh — does every menu entry point still PARSE?
# ============================================================================
# Runs each plugin/scripts/*.praat headless and fails on a STRUCTURAL error:
# a duplicate label, an unknown symbol, a script that could not be read. It
# does NOT care that a wrapper then refuses for want of a selected object, or
# dies for want of a display — those mean it parsed, which is all this asks.
#
# WHY THIS EXISTS, AND IT IS NOT A HYPOTHETICAL.
#
# On 11 August 2026, FIFTEEN of the plugin's entry points were dead:
#
#     Error: Duplicate label "END_RECORD_SOURCE" on lines 29445 and 13332.
#     Script ".../scripts/eml-graphs.praat" not completed.
#     Command "EML Graphs..." not executed.
#
# EML Graphs, the wizard, the LMM path and every analysis wrapper. Not on one
# version — on 6.6.30 and 7.0 alike. The plugin was unusable from its own
# menu, and 8221 R checks, 39/39 stress, 52/52 disclosure, 357/357 phase1 and
# both round trips were all green.
#
# THE CAUSE was one duplicated include. eml-lib.praat loads eml-lib-stats
# (which includes eml-record.praat) and then eml-lib-graphs (which included it
# again). `include` is a textual paste and eml-record.praat contains `label`
# statements, so the second paste defined every label twice. Praat rejects
# that at PARSE time, before a single line runs.
#
# THE REASON NOTHING CAUGHT IT is the part worth keeping. Every harness in
# this tree includes the individual plugin files -- harness/stress_cases/_prelude.praat
# names nine of them one by one. Nothing anywhere loaded scripts/eml-lib.praat,
# which is what the shipped wrappers actually load. The suites were exercising
# a composition of the plugin that no user ever runs, and the composition every
# user runs had never been loaded once.
#
# It was found by driving the plugin's own menu under Xvfb and reading the
# error dialog. This script is that finding, made cheap.
#
# Run from anywhere:  bash harness/wrappers/run.sh
# Exit 0 = every wrapper parses.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1
OUT="$SCRIPT_DIR/out"
PREFS="$SCRIPT_DIR/prefs"
mkdir -p "$OUT" "$PREFS"

WRAPDIR="$EML_ROOT/plugin/scripts"

# A STRUCTURAL failure -- the script could not be built. Anything else (a
# refusal for want of a Table, a missing display) means it parsed.
#
# Matched as a set of literal phrases rather than "any error", because a
# wrapper refusing cleanly IS an error message and is the correct behaviour
# with nothing selected. Adding to this list is how the check gets stricter;
# it must never be loosened to make a run go green.
STRUCTURAL='Duplicate label|Unknown symbol|Unknown variable|Unknown parameter|not performed or completed|Formula not run|Include file .* not read|Unknown function'

# A machine-readable summary beside the human one, so validate/v35 can assert
# on this without re-implementing the structural-error rule. The per-wrapper
# logs stay out of the repository (they are large and re-made every run); this
# one line per wrapper is the evidence.
TSV="$OUT/WRAPPERS.tsv"
: > "$TSV"

printf '%-34s %s\n' "wrapper" "verdict"
fail=0
n=0
for f in "$WRAPDIR"/*.praat; do
    nm="$(basename "$f")"
    n=$((n + 1))
    log="$OUT/${nm%.praat}.log"
    # SIGTRAP is expected and is not a failure. `beginPause:` hard-crashes
    # under `praat --run` (Trace/breakpoint trap, exit 133) because there is
    # no display -- documented in harness/GUI_HARNESS_RECIPE.md §0. Reaching
    # beginPause: means the script parsed and ran, which is what is asked
    # here. The subshell swallows the shell's own job-control notice so the
    # report reads cleanly.
    ( cd "$WRAPDIR" && timeout 90 env -u DISPLAY "$PRAAT" $PRAAT_TRUST \
        --pref-dir="$PREFS" --run "$nm" >"$log" 2>&1 ) 2>/dev/null
    if grep -qE "$STRUCTURAL" "$log"; then
        why=$(grep -oE "$STRUCTURAL" "$log" | head -1)
        printf '%-34s %s\n' "$nm" "PARSE FAIL  $why"
        printf '%s\t%s\t%s\n' "$nm" "PARSEFAIL" "$why" >> "$TSV"
        fail=$((fail + 1))
    else
        printf '%-34s %s\n' "$nm" "parses"
        printf '%s\t%s\t\n' "$nm" "parses" >> "$TSV"
    fi
done

# A suite that quietly stopped covering a wrapper would pass. The count is
# asserted so that a deleted or renamed entry point has to be dealt with on
# purpose rather than by silence.
EXPECTED_MIN=20
echo
if [[ "$n" -lt "$EXPECTED_MIN" ]]; then
    echo "wrappers: FAIL — only $n wrapper(s) found, expected at least $EXPECTED_MIN."
    echo "          A missing entry point is the failure this count exists to catch."
    exit 1
fi

if [[ $fail -eq 0 ]]; then
    echo "wrappers: PASS — $n/$n parse"
    echo "          (Praat $("$PRAAT" --version 2>&1 | head -1))"
    exit 0
fi
echo "wrappers: FAIL — $fail of $n do not parse. Logs in harness/wrappers/out/."
echo "          A wrapper that does not parse is a menu command that does"
echo "          nothing when the user clicks it."
exit 1
