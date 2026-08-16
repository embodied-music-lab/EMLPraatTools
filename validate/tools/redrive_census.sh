#!/usr/bin/env bash
# ============================================================================
# validate/tools/redrive_census.sh — does the committed evidence reproduce?
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS EXISTS. Twice in two days a committed harness artefact was found to
# be one the harness beside it could no longer produce, and in both cases the
# validator that reads it had been green the whole time:
#
#   15 Aug 2026   harness/walks/gridmode
#   16 Aug 2026   harness/legendroom/out/LEGENDROOM.tsv — stale since 7f62e75
#                 (15 Aug), bisected by re-driving 32 commits
#
# A validator asserts that an ARTEFACT says the right thing. Nothing asserted
# that the artefact still describes the plugin in the tree. That gap is
# invisible by construction: the suite reads the file, the file is committed,
# the file does not change, and the suite stays green while the code moves out
# from under it. The only way to see it is to re-drive and compare.
#
# WHAT IT DOES. Copies the working tree to a scratch directory, runs each
# harness driver there, and compares every committed artefact byte for byte
# against the one in the real tree. The real tree is NEVER written to.
#
# VERDICTS, one per harness:
#   REPRODUCES     every artefact came back byte-identical
#   VOLATILE       differs only in wall-clock / path / pid lines. The harness
#                  reproduces; the artefact cannot be byte-compared as it
#                  stands, which is its own (smaller) finding.
#   DIFFERS        at least one artefact changed in substance. THIS IS THE
#                  LIST. It means the committed file no longer describes the
#                  plugin, exactly as LEGENDROOM.tsv did not.
#   DRIVER-FAILED  the driver exited non-zero; nothing could be compared
#   TIMEOUT        the driver exceeded --timeout
#   NO-ARTEFACTS   the driver ran but commits no artefact to compare
#
# WHAT IT DOES NOT COVER, named rather than skipped silently:
#   * break drivers (break*.sh, *_break*.sh, breaktest*.sh). They mutate a
#     source file on purpose; a few do commit a BREAKS.tsv, and those are not
#     checked here.
#   * harnesses with no shell driver — a bare .praat with an out/ directory
#     (acoustic, colmissing, coltype, homogeneity, influence, broom_cases,
#     sweep, qq_cases). They are LISTED in the output as NO-DRIVER rather than
#     driven by a command this script guessed at.
#   * harness/gui.sh (a sourced library, not a driver) and harness/walks/rig.sh
#     (a multi-display GUI rig driven by hand).
# Run with --list to see the full inventory and which bucket each dir is in.
#
#   bash validate/tools/redrive_census.sh                 everything
#   bash validate/tools/redrive_census.sh --only legendroom,legend
#   bash validate/tools/redrive_census.sh --timeout 900
#   bash validate/tools/redrive_census.sh --list
#
# Exit 0 if every harness reproduced (VOLATILE counts as reproduced), 1 if any
# DIFFERS / DRIVER-FAILED / TIMEOUT.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRATCH="${EML_REDRIVE_SCRATCH:-${TMPDIR:-/tmp}/eml_redrive}"
TIMEOUT="${EML_REDRIVE_TIMEOUT:-600}"
ONLY=""
LIST_ONLY=0
COMPARE_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)    ONLY="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --scratch) SCRATCH="$2"; shift 2 ;;
        --list)    LIST_ONLY=1; shift ;;
        # SCORE AN EXISTING SCRATCH TREE WITHOUT RE-DRIVING IT. The drive is
        # the expensive half — over half an hour for the full set — and the
        # comparison rules are the half that gets refined while it runs. This
        # re-scores what is already on disk, reading each driver's exit code
        # and elapsed time back from the stamps the drive left behind, so a
        # TIMEOUT stays a TIMEOUT and does not silently become a verdict.
        --compare-only) COMPARE_ONLY=1; shift ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------------------
# ARTEFACT FILES. Committed files under the harness that are not SOURCE — the
# outputs, whatever their extension. Source is what produces them and is
# expected to be identical; counting it would dilute the answer to 99%.
# ---------------------------------------------------------------------------
artefacts_of() {   # $1 = path prefix under the repo
    git -C "$REAL" ls-files "$1" \
        | grep -vE '\.(sh|praat|py|R|md)$' || true
}

# ---------------------------------------------------------------------------
# VOLATILE LINES. A wall-clock stamp, an absolute scratch path or a pid is not
# evidence about the plugin, and several committed logs carry one — the
# legendroom driver.log prints "Sun Aug 16 17:00:11 2026" inside a report
# header. A file whose every changed line looks like one of these is reported
# as VOLATILE, not as a difference, and the distinction is kept visible rather
# than filtered away: an artefact that cannot be byte-compared is a weaker
# artefact than one that can.
# ---------------------------------------------------------------------------
VOLATILE_RE='(Mon|Tue|Wed|Thu|Fri|Sat|Sun) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) '
VOLATILE_RE+='|[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}'
VOLATILE_RE+='|[0-9]{2}:[0-9]{2}:[0-9]{2}'
VOLATILE_RE+='|elapsed|seconds|[Pp][Ii][Dd] *[=:] *[0-9]+'

# THE TREE'S OWN PATH IS NORMALISED, NOT PATTERN-MATCHED. Several harnesses
# stamp `source_tree <repo root>` or `SAVED <abs path>` into their artefact on
# purpose, so a result can be traced to the checkout that produced it —
# harness/_env.sh exists because a copy of this repo once silently loaded the
# ORIGINAL tree's plugin. Re-driving in scratch changes those lines by
# construction. Both sides are rewritten to @ROOT@ before the comparison, so
# the path drops out and everything ELSE on the same line is still compared:
# a regex alternative would have swallowed the whole line, and the first
# attempt to write one did worse than that -- `[.` inside a bracket
# expression is a POSIX collating symbol, sed rejected the program, the
# alternative expanded to nothing, and an EMPTY alternative in an extended
# regex matches every line. Every text artefact in the repository was scored
# VOLATILE for one run. Caught by re-reading a file the run called clean
# (harness/parity/out/parity.log, which really does differ: "SD 0" against
# "SD 0.000"). A filter that fails open is worse than no filter.
norm() { sed -e "s|$REAL|@ROOT@|g" -e "s|$SCRATCH|@ROOT@|g" "$1" 2>/dev/null; }

# ---------------------------------------------------------------------------
# INVENTORY
# ---------------------------------------------------------------------------
declare -a NAMES DRIVERS PATHS
add_entry() { NAMES+=("$1"); DRIVERS+=("$2"); PATHS+=("$3"); }

declare -a NODRIVER
for d in "$REAL"/harness/*/; do
    n="$(basename "$d")"
    [[ "$n" == "__pycache__" ]] && continue
    # break drivers excluded by name; see the header
    # harness/walks/rig.sh is a multi-display GUI rig driven by hand, not a
    # one-shot driver; see the header.
    [[ "$n" == "walks" ]] && { NODRIVER+=("$n (GUI rig, rig.sh)"); continue; }
    mapfile -t drv < <(cd "$d" && ls *.sh 2>/dev/null \
        | grep -vE '^(break|breaktest)|_break|_gui\.sh$' || true)
    if [[ ${#drv[@]} -eq 0 ]]; then
        NODRIVER+=("$n")
        continue
    fi
    dstr=""
    for one in "${drv[@]}"; do dstr+="harness/$n/$one;"; done
    add_entry "$n" "$dstr" "harness/$n"
done
# Two artefact-producing drivers live at harness/ top level, with their cases
# and their output in sibling directories.
add_entry "qq"     "harness/qq_drive.sh;"     "harness/qq_out harness/qq_cases"
add_entry "stress" "harness/stress_graphs.sh;" "harness/stress_out"

if [[ $LIST_ONLY -eq 1 ]]; then
    printf '%-16s %-46s %s\n' HARNESS DRIVERS ARTEFACTS
    for i in "${!NAMES[@]}"; do
        nf=0
        for p in ${PATHS[$i]}; do
            nf=$(( nf + $(artefacts_of "$p" | wc -l) ))
        done
        printf '%-16s %-46s %s\n' "${NAMES[$i]}" \
            "$(echo "${DRIVERS[$i]}" | tr ';' ' ')" "$nf"
    done
    echo
    echo "NO-DRIVER (a .praat and an out/, no shell driver — not re-driven here):"
    printf '  %s\n' "${NODRIVER[@]}"
    exit 0
fi

if [[ -n "$ONLY" ]]; then
    keep="${ONLY//,/ }"
    declare -a kN kD kP
    for i in "${!NAMES[@]}"; do
        for k in $keep; do
            [[ "${NAMES[$i]}" == "$k" ]] && { kN+=("${NAMES[$i]}"); \
                kD+=("${DRIVERS[$i]}"); kP+=("${PATHS[$i]}"); }
        done
    done
    NAMES=("${kN[@]}"); DRIVERS=("${kD[@]}"); PATHS=("${kP[@]}")
fi

# ---------------------------------------------------------------------------
# THE SCRATCH TREE. A full copy, minus .git, so a driver that writes anywhere
# in the repo writes THERE. The real tree is read-only to this script.
# ---------------------------------------------------------------------------
echo "redrive census"
echo "  repo     $REAL"
echo "  scratch  $SCRATCH"
echo "  timeout  ${TIMEOUT}s per driver"
echo "  praat    $(command -v praat) $(praat --version 2>&1 | head -1)"
echo
if [[ $COMPARE_ONLY -eq 0 ]]; then
    rm -rf "$SCRATCH"
    mkdir -p "$SCRATCH"
    tar -C "$REAL" --exclude=.git -cf - . | tar -C "$SCRATCH" -xf -
else
    [[ -d "$SCRATCH" ]] || { echo "no scratch tree at $SCRATCH" >&2; exit 2; }
    echo "  (compare-only: scoring the tree already in scratch)"
fi

REPORT="$SCRATCH/CENSUS.tsv"
: > "$REPORT"
printf '%-16s %-8s %-6s %5s %5s %5s %5s  %s\n' \
    HARNESS VERDICT rc secs files same vol diff
printf '%s\n' "----------------------------------------------------------------------"

nRepro=0; nVol=0; nDiff=0; nFail=0; nTimeout=0; nNone=0
for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"; paths="${PATHS[$i]}"
    rc=0; t0=$SECONDS
    if [[ $COMPARE_ONLY -eq 1 ]]; then
        read -r rc secs < "$SCRATCH/_redrive_${name}.rc" 2>/dev/null \
            || { rc=0; secs=0; }
    else
        IFS=';' read -ra dlist <<< "${DRIVERS[$i]}"
        for drv in "${dlist[@]}"; do
            [[ -z "$drv" ]] && continue
            ( cd "$SCRATCH" && timeout "$TIMEOUT" bash "$drv" ) \
                > "$SCRATCH/_redrive_${name}.log" 2>&1
            rc=$?
            [[ $rc -ne 0 ]] && break
        done
        secs=$(( SECONDS - t0 ))
        echo "$rc $secs" > "$SCRATCH/_redrive_${name}.rc"
    fi

    same=0; vol=0; diff=0; total=0
    for p in $paths; do
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            total=$(( total + 1 ))
            if cmp -s "$REAL/$f" "$SCRATCH/$f" 2>/dev/null; then
                same=$(( same + 1 ))
            elif [[ ! -f "$SCRATCH/$f" ]]; then
                diff=$(( diff + 1 ))
                echo -e "$name\tMISSING\t$f" >> "$REPORT"
            elif diff -q <(norm "$REAL/$f") <(norm "$SCRATCH/$f") >/dev/null \
                 2>&1; then
                # Identical once the tree root is normalised: the artefact
                # reproduced, it just records where it was produced.
                vol=$(( vol + 1 ))
                echo -e "$name\tVOLATILE-path\t$f" >> "$REPORT"
            else
                # Changed lines only. If every one of them is a clock or a
                # pid, the harness reproduced and the artefact merely is not
                # byte-stable.
                # A BINARY FILE HAS NO VOLATILE LINES. diff reports "Binary
                # files ... differ" with no ^[<>] output, so `changed` comes
                # back empty and the file falls through to DIFFERS, which is
                # the right answer: a PNG that changed, changed.
                changed=$(diff <(norm "$REAL/$f") <(norm "$SCRATCH/$f") \
                    2>/dev/null | grep -E '^[<>]' || true)
                if [[ -n "$changed" ]] && \
                   ! echo "$changed" | grep -qvE "$VOLATILE_RE"; then
                    vol=$(( vol + 1 ))
                    echo -e "$name\tVOLATILE\t$f" >> "$REPORT"
                else
                    diff=$(( diff + 1 ))
                    echo -e "$name\tDIFFERS\t$f" >> "$REPORT"
                fi
            fi
        done < <(artefacts_of "$p")
    done

    if   [[ $rc -eq 124 ]]; then verdict=TIMEOUT;  nTimeout=$(( nTimeout + 1 ))
    elif [[ $rc -ne 0 ]];   then verdict=DRVFAIL;  nFail=$(( nFail + 1 ))
    elif [[ $total -eq 0 ]];then verdict=NOARTEF;  nNone=$(( nNone + 1 ))
    elif [[ $diff -gt 0 ]]; then verdict=DIFFERS;  nDiff=$(( nDiff + 1 ))
    elif [[ $vol -gt 0 ]];  then verdict=VOLATILE; nVol=$(( nVol + 1 ))
    else                         verdict=REPRO;    nRepro=$(( nRepro + 1 ))
    fi
    printf '%-16s %-8s %-6s %5s %5s %5s %5s  %s\n' \
        "$name" "$verdict" "$rc" "$secs" "$total" "$same" "$vol" "$diff"
done

echo
echo "  REPRODUCES $nRepro   VOLATILE $nVol   DIFFERS $nDiff" \
     "  DRIVER-FAILED $nFail   TIMEOUT $nTimeout   NO-ARTEFACTS $nNone"
if [[ $nTimeout -gt 0 || $nFail -gt 0 ]]; then
    echo "  NOTE: the file counts on a TIMEOUT or DRIVER-FAILED row are"
    echo "  PARTIAL — the driver stopped part way, so an artefact it had not"
    echo "  reached yet still holds the committed bytes and counts as 'same'."
    echo "  Those rows say 'not measured', not 'reproduces'."
fi
echo "  per-file detail: $REPORT"
echo
echo "NOT RE-DRIVEN (no shell driver; a .praat and an out/ directory):"
printf '  %s\n' "${NODRIVER[@]:-none}"

[[ $(( nDiff + nFail + nTimeout )) -eq 0 ]]
