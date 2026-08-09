#!/usr/bin/env bash
# ============================================================================
# check_phrases.sh — the two record-workflow assertions that must be STATIC
# ============================================================================
# §8.10 of TREATMENT_record_workflow.md asks for both directions:
#
#   1. every phrase key referenced in source exists in the CSV
#   2. every key in the CSV is referenced by something
#
# Both directions, because an orphaned phrase and a missing phrase fail
# differently and both are defects. A missing key renders as
# "[MISSING PHRASE: ...]" in a file the author may publish; an orphaned key
# is wording nobody can reach, which goes stale silently and then gets
# copied by whoever writes the next one.
#
# Neither is checkable at run time: a key is only exercised if its code path
# runs, and no test suite drives every branch of every wrapper. So this reads
# the source.
#
# Run from anywhere:  bash validate/tools/check_phrases.sh
# Exit 0 = clean, 1 = at least one defect.
# ============================================================================
set -uo pipefail

# Resolve the repo root from THIS script's own location rather than from the
# working directory. harness/stress_cases/_prelude.praat is the cautionary
# tale here: it hardcodes an absolute path back into one machine's tree, so a
# copy of the repo rendered anywhere else silently tests the ORIGINAL build.
# Nothing in this file may repeat that.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CSV="$ROOT/plugin/data/eml-record-phrases.csv"
FAIL=0

if [[ ! -f "$CSV" ]]; then
    echo "FAIL: phrase registry not found at $CSV"
    exit 1
fi

# Keys defined in the registry (skip the header row).
DEFINED=$(tail -n +2 "$CSV" | cut -d, -f1 | sed '/^$/d' | sort -u)

# Keys referenced in source: the first quoted argument of any @emlPhrase call.
# Searched across the whole plugin and test trees, because a phrase used only
# by a test is still a reference and must not be reported as orphaned.
REFERENCED=$(grep -rhoP '@emlPhrase:\s*"\K[^"]+' \
    "$ROOT/plugin" "$ROOT/harness" 2>/dev/null | sort -u)

# NEGATIVE PROBES. A key that exists in source precisely so a test can assert
# it is NOT found. Exempted by name rather than by pattern, so adding one is
# a deliberate act and a typo in a real key cannot hide behind the rule.
NEGATIVE_PROBES="no.such.key"
REFERENCED=$(comm -23 <(echo "$REFERENCED") \
    <(echo "$NEGATIVE_PROBES" | tr ' ' '\n' | sort -u))

echo "Phrase registry: $(echo "$DEFINED" | wc -l) keys defined,"\
     "$(echo "$REFERENCED" | grep -c . || true) referenced"
echo

# --- Direction 1: referenced but not defined --------------------------------
MISSING=$(comm -23 <(echo "$REFERENCED") <(echo "$DEFINED"))
if [[ -n "$MISSING" ]]; then
    echo "FAIL — referenced in source but NOT defined in the registry:"
    while IFS= read -r k; do
        [[ -z "$k" ]] && continue
        echo "    $k"
        grep -rn "@emlPhrase:[[:space:]]*\"$k\"" "$ROOT/plugin" "$ROOT/harness" \
            2>/dev/null | sed 's|'"$ROOT"'/|      |'
    done <<< "$MISSING"
    FAIL=1
else
    echo "OK — every referenced key is defined."
fi

# --- Direction 2: defined but never referenced ------------------------------
# The deliberate exception: a key a test only reaches by NOT finding it.
ORPHAN=$(comm -13 <(echo "$REFERENCED") <(echo "$DEFINED"))
if [[ -n "$ORPHAN" ]]; then
    echo
    echo "FAIL — defined in the registry but referenced by nothing:"
    while IFS= read -r k; do
        [[ -z "$k" ]] && continue
        echo "    $k"
    done <<< "$ORPHAN"
    FAIL=1
else
    echo "OK — every defined key is referenced."
fi

# --- Direction 3, not in §8.10 but free here --------------------------------
# A template whose highest placeholder exceeds {6} cannot be filled, because
# @emlPhrase has fixed arity. Praat gives no error for this: the placeholder
# simply survives into the emitted file as literal "{7}".
echo
BADPH=$(tail -n +2 "$CSV" | grep -oP '\{[0-9]+\}' | tr -d '{}' \
    | sort -un | awk '$1 > 6')
if [[ -n "$BADPH" ]]; then
    echo "FAIL — placeholders above {6} cannot be filled (@emlPhrase arity is 6):"
    echo "$BADPH" | sed 's/^/    {/;s/$/}/'
    FAIL=1
else
    echo "OK — no template uses a placeholder above {6}."
fi

echo
if [[ $FAIL -eq 0 ]]; then
    echo "check_phrases: PASS"
else
    echo "check_phrases: FAIL"
fi
exit $FAIL
