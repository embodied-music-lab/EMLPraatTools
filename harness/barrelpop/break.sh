#!/usr/bin/env bash
# ============================================================================
# harness/barrelpop/break.sh — the barrel's account of itself, broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# validate/v88_barrel_population.R says that every .praat under stats/ and
# graphs/ is either in setup.praat's module table or named in the
# not-in-barrel rows beneath it with a reason. A check like that is green on a
# correct tree AND green if it is asleep, and reading it cannot tell the two
# apart — so each break below is a COMPLETE CLONE of this repository carrying
# one deliberate defect, with v88 run against it and its reds counted.
#
# v82 IS RUN ON EVERY CLONE TOO, and that column is half the argument. v82 is
# the check that already reads the module table; it pins the table against
# CANON, a list retyped inside v82, and against the block @emlRecordRender
# emits. Both of those are satisfied by a change made in both places. The
# `dropped_from_both` clone is exactly that commit — a module taken out of the
# barrel and out of CANON together — and the two columns are the point: v82
# green, v88 red. Without that line, v88 is plausibly redundant with v82.
#
# THE EIGHT DEFECTS
#
#   control              undamaged; every count below is noise if this is not
#                        green.
#   module_dropped       a module removed from the table, count corrected.
#                        This is the failure the file was written for: the
#                        procedures in it become unloadable from a user's one
#                        include line and nothing else in the suite changes.
#   dropped_from_both    the same removal, with v82's CANON edited to match.
#   new_module_unlisted  a module added to stats/ and named in neither list —
#                        the shape the survey kernels had for weeks.
#   renamed_module       a module renamed on disk and not in the table: the
#                        barrel then emits an include for a file that is not
#                        there, and the parse error arrives in the USER's
#                        script.
#   reason_removed       an exclusion with the reason taken off, which is how
#                        an exclusion stops being a decision.
#   in_both_lists        one module in the table and in the exclusions.
#   count_short          emlSetupNModules left one behind the table, so the
#                        generator's loop stops early and the last row is
#                        written down but never shipped.
#   excluded_but_reached a barrel module includes an excluded one, so the
#                        exclusion is false and silently so.
#
#   Run:  bash harness/barrelpop/break.sh [name-substring]
#   Out:  harness/barrelpop/out/BREAKS.tsv
#             break, v88 reds, v82 reds, first v88 failure
#         harness/barrelpop/out/break_<name>.v88.log
#         harness/barrelpop/out/break_<name>.v82.log
# ============================================================================
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/harness/barrelpop/out"
WORK="${TMPDIR:-/tmp}/barrelpop.$$"
ONLY="${1:-}"
mkdir -p "$OUT"; rm -rf "$WORK"; mkdir -p "$WORK"
TSV="$OUT/BREAKS.tsv"
if [ -z "$ONLY" ]; then
    printf '# break\tv88_red\tv82_red\tfirst_v88_failure\n' > "$TSV"
fi

clone() {                      # $1 = break name -> echoes the clone path
    local d="$WORK/$1"
    git clone --quiet --local "$ROOT" "$d" 2>/dev/null || return 1
    git -C "$d" config user.name  "Ian Howell"
    git -C "$d" config user.email "admin@embodiedmusiclab.com"
    # THE RIG SCORES THE VALIDATOR AS IT STANDS IN THIS TREE, not as HEAD
    # carries it: a break test whose subject is the committed copy cannot run
    # until after the commit, which is the wrong moment to learn a check is
    # asleep. The clone is HEAD; these two files are the working tree's.
    cp "$ROOT/validate/v88_barrel_population.R" "$d/validate/"
    cp "$ROOT/validate/v82_generated_barrel.R"  "$d/validate/"
    # AND THE FILE THEY READ. v88's subject is not only the validator: it is
    # the two lists inside setup.praat, and the two are edited together. A rig
    # that took the validator from the working tree and the table from HEAD
    # would score a check against a table it was not written for, and its
    # control clone would go red for that reason alone.
    cp "$ROOT/plugin_EML_StatsGraphs/setup.praat" "$d/plugin_EML_StatsGraphs/"
    echo "$d"
}

run_break() {                  # $1 = name, $2 = shell body run inside the clone
    local name="$1" body="$2"
    [ -n "$ONLY" ] && case "$name" in *"$ONLY"*) ;; *) return 0 ;; esac
    local d; d="$(clone "$name")" || { echo "CLONE FAILED $name"; return 1; }
    ( cd "$d" && eval "$body" ) >/dev/null 2>&1
    local l88="$OUT/break_$name.v88.log" l82="$OUT/break_$name.v82.log"
    ( cd "$d" && Rscript validate/v88_barrel_population.R ) > "$l88" 2>&1
    ( cd "$d" && Rscript validate/v82_generated_barrel.R  ) > "$l82" 2>&1
    local r88 r82 first
    r88=$(grep -c '^FAIL ' "$l88"); r82=$(grep -c '^FAIL ' "$l82")
    first=$(grep -m1 '^FAIL ' "$l88" | sed 's/^FAIL *v88 *//; s/  *computed=.*$//; s/  *reported=.*$//')
    [ -z "$first" ] && first="(none — THIS BREAK DID NOT GO RED)"
    printf '%s\t%s\t%s\t%s\n' "$name" "$r88" "$r82" "$first" >> "$TSV"
    printf '%-20s v88 %2s red   v82 %2s red   %s\n' "$name" "$r88" "$r82" "$first"
    rm -rf "$d"
}

S=plugin_EML_StatsGraphs/setup.praat

echo "== control: an undamaged clone must be GREEN"
run_break control ':'

echo
echo "== a module taken out of the barrel"
run_break module_dropped \
    "sed -i '/^emlSetupModule\\\$ \\[13\\] = \"stats\\/eml-analysis.praat\"\$/d' $S && \
     sed -i 's/^emlSetupNModules = 13\$/emlSetupNModules = 12/' $S"
run_break dropped_from_both \
    "sed -i '/^emlSetupModule\\\$ \\[13\\] = \"stats\\/eml-analysis.praat\"\$/d' $S && \
     sed -i 's/^emlSetupNModules = 13\$/emlSetupNModules = 12/' $S && \
     sed -i '/^    \"stats\\/eml-analysis.praat\")\$/d' validate/v82_generated_barrel.R && \
     sed -i 's|^    \"graphs/eml-draw-procedures.praat\",\$|    \"graphs/eml-draw-procedures.praat\")|' validate/v82_generated_barrel.R"
run_break dropped_from_all_three \
    "sed -i '/^emlSetupModule\\\$ \\[13\\] = \"stats\\/eml-analysis.praat\"\$/d' $S && \
     sed -i 's/^emlSetupNModules = 13\$/emlSetupNModules = 12/' $S && \
     sed -i '/^    \"stats\\/eml-analysis.praat\")\$/d' validate/v82_generated_barrel.R && \
     sed -i 's|^    \"graphs/eml-draw-procedures.praat\",\$|    \"graphs/eml-draw-procedures.praat\")|' validate/v82_generated_barrel.R && \
     python3 -c \"import io;p='plugin_EML_StatsGraphs/stats/eml-record.praat';l=io.open(p,encoding='utf-8').read().split(chr(10));i=[n for n,x in enumerate(l) if 'stats/eml-analysis.praat\\\"' in x][0];del l[i:i+2];io.open(p,'w',encoding='utf-8').write(chr(10).join(l))\""

echo
echo "== a module that is in neither list"
run_break new_module_unlisted \
    "printf '# EML Stats \\u0026 Graphs — survival curves\\nprocedure emlKaplanMeier: .t#, .e#\\nendproc\\n' \
     > plugin_EML_StatsGraphs/stats/eml-survival.praat"
run_break renamed_module \
    "git mv plugin_EML_StatsGraphs/stats/eml-extract.praat \
            plugin_EML_StatsGraphs/stats/eml-extraction.praat"

echo
echo "== the account contradicting itself"
run_break reason_removed \
    "sed -i 's|^# not-in-barrel: stats/eml-optimizer.praat -- .*\$|# not-in-barrel: stats/eml-optimizer.praat -- out|' $S"
run_break in_both_lists \
    "printf '# not-in-barrel: stats/eml-output.praat -- a row that contradicts the table above it, planted by harness/barrelpop/break.sh\\n' >> $S"
run_break count_short \
    "sed -i 's/^emlSetupNModules = 13\$/emlSetupNModules = 12/' $S"
run_break excluded_but_reached \
    "printf 'include ../stats/eml-lmm.praat\\n' >> plugin_EML_StatsGraphs/stats/eml-analysis.praat"

echo
echo "wrote $TSV"
