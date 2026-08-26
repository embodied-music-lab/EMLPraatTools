#!/usr/bin/env bash
# ============================================================================
# harness/resultstore/seed_violation.sh -- the red demonstration for v138
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS PROVES, AND WHY THE CHECK IS NOT FINISHED WITHOUT IT.
#
# validate/v138_result_store.R is a census, and every assertion in it reads
# "for every X in the population ..." -- all of which are TRUE of an empty
# population. v138 answers part of that itself, with resolver gates that fail
# on zero and print the counts. This file answers the rest: it shows the check
# going RED when the plugin actually does the four things it forbids.
#
# AUTHOR IS NEVER VERIFIER, and this is the shape that rule takes for a
# check: the check is not evidence that it works. A seeded violation is.
#
# NOTHING IN THE SHIPPED TREE IS TOUCHED. The plugin and the measured artefact
# are COPIED, one violation is seeded into the copy, and v138 is pointed at
# the copy with $EML_STORE_SRC -- UNMODIFIED. What goes red is the check
# itself, not a rehearsal of it.
#
# THE FOUR LEGS, one per thing the store's contract forbids:
#
#   second_writer   a name beginning emlStore assigned somewhere other than
#                   @emlPublishAnalysisResult. Two writers is how published
#                   state stops meaning anything.
#   silent_door     a procedure that computes a group comparison and does not
#                   publish. The defect the single-writer contract exists to
#                   prevent, and the silent one: the figure still draws.
#   late_key        the key taken AFTER the run has read the data. The one
#                   failure the fingerprint's own arithmetic cannot see.
#   unclassified    a name published and classified nowhere. The census's
#                   ratchet, which is what keeps the vocabulary honest.
#
#   harness/resultstore/seed_violation.sh
#
# Exit status is 0 when EVERY leg went red as it should, and 1 if any leg
# stayed green -- because a red demonstration that quietly stops demonstrating
# is worse than none.
# ============================================================================
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_env.sh"

work="$(mktemp -d /tmp/resultstore-break-XXXXXX)"
trap 'rm -rf "$work"' EXIT

fails=0

# ---------------------------------------------------------------------------
# seed <leg> <expected phrase in the failing check>
# Builds a fresh copy, applies the leg's edit, runs v138 against it, and
# reports whether the named check went red.
# ---------------------------------------------------------------------------
run_leg () {
    local leg="$1" phrase="$2"
    local tree="$work/$leg"
    rm -rf "$tree"
    mkdir -p "$tree/harness/resultstore/out"
    cp -r "$EML_ROOT/plugin_EML_StatsGraphs" "$tree/"
    cp "$EML_ROOT/harness/resultstore/out/STORE.tsv" \
       "$tree/harness/resultstore/out/STORE.tsv"
    seed_"$leg" "$tree"

    local log="$work/$leg.log"
    EML_STORE_SRC="$tree" Rscript "$EML_ROOT/validate/v138_result_store.R" \
        > "$log" 2>&1

    if grep -q "^FAIL" "$log" && grep -qF "$phrase" "$log"; then
        echo "  RED as it should be: $leg"
        grep "^FAIL" "$log" | grep -F "$phrase" | head -1 | sed 's/^/      /'
    else
        echo "  STAYED GREEN -- the check does not catch: $leg"
        fails=$((fails + 1))
    fi
}

# --- leg 1: a second writer -------------------------------------------------
# The most direct violation there is: another procedure assigning a published
# name. Seeded into a reporter, which is where it would really happen -- a
# reporter that "just updates the correction it printed".
seed_second_writer () {
    local t="$1"
    python3 - "$t" <<'PY'
import sys, re
p = sys.argv[1] + "/plugin_EML_StatsGraphs/stats/eml-analysis.praat"
s = open(p).read()
a = "procedure emlAdjustMethodDisplay: .key$\n"
assert a in s
s = s.replace(a, a + '    emlStoreCorrection$ = .key$\n', 1)
open(p, "w").write(s)
PY
}

# --- leg 2: a door that computes and does not publish ------------------------
# A new group-comparison door, written the way one really would be: it calls
# the kernel, reports, and nobody remembers the store. It is not in the
# exemption table, so the derivation has to find it.
seed_silent_door () {
    local t="$1"
    cat >> "$t/plugin_EML_StatsGraphs/stats/eml-analysis.praat" <<'PRAAT'


procedure emlRunSeededQuietAnalysis: .tableId, .dataCol$, .groupCol$
    @emlOneWayAnova: .tableId, .dataCol$, .groupCol$, 1
    appendInfoLine: "F = ", emlOneWayAnova.fValue
endproc
PRAAT
}

# --- leg 3: the key taken after the read ------------------------------------
# The whole call moved below the kernel, which is exactly the mistake the
# fingerprint's header says nothing in it can detect. The publication still
# happens, the key is still a real key, and it describes the wrong instant.
seed_late_key () {
    local t="$1"
    python3 - "$t" <<'PY'
import sys, re
p = sys.argv[1] + "/plugin_EML_StatsGraphs/stats/eml-analysis.praat"
s = open(p).read()

# Work INSIDE @emlRunAnovaAnalysis only: the key take is the same block in
# every publisher, so a global replace would seed a different violation in a
# different door and the leg would be demonstrating something else.
start = s.index("procedure emlRunAnovaAnalysis:")
end = s.index("\nendproc", start) + len("\nendproc")
body = s[start:end]

take = re.search(r"\n    ; THE KEY, TAKEN IN THE SAME PASS THAT READS THE DATA.*?"
                 r"\n    \.stSort\$ = emlStoreKeyTake\.sort\$\n", body, re.S).group(0)
anchor = ('    if emlOneWayAnova.error$ <> ""\n'
          '        .error$ = emlOneWayAnova.error$\n'
          '        goto END_ANOVA\n'
          '    endif\n')
assert take in body and anchor in body
body = body.replace(take, "\n", 1)
body = body.replace(anchor, anchor + take, 1)
open(p, "w").write(s[:start] + body + s[end:])
PY
}

# --- leg 4: a published name nobody classified ------------------------------
seed_unclassified () {
    local t="$1"
    python3 - "$t" <<'PY'
import sys
p = sys.argv[1] + "/plugin_EML_StatsGraphs/stats/eml-extract.praat"
s = open(p).read()
a = "    emlStoreKind$ = .kind$\n"
assert a in s
s = s.replace(a, a + '    emlStoreSeededExtra$ = .kind$\n', 1)
open(p, "w").write(s)
PY
}

echo "v138's red demonstration -- four seeded violations, one check, unmodified"
run_leg second_writer "SECOND WRITER"
run_leg silent_door   "COMPUTES AND DOES NOT PUBLISH"
run_leg late_key      "KEY TAKEN LATE IN"
run_leg unclassified  "UNCLASSIFIED"

if [[ $fails -eq 0 ]]; then
    echo "all four legs went red; v138 catches what it claims to"
    exit 0
fi
echo "$fails leg(s) stayed green -- v138 does not catch what it claims to"
exit 1
