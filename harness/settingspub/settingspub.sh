#!/usr/bin/env bash
# ============================================================================
# harness/settingspub/settingspub.sh -- record at a setting, replay, compare
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Three settings decide what a computing step ANSWERS and travel to it as
# globals rather than as arguments: the multiple-comparison correction, the
# alpha every confidence interval is built at, and the order the group levels
# are put in. A recorded step carries its call and its arguments, so a step
# that does not state those three replays under whatever the replaying process
# happens to hold -- which for an emitted script is the seed
# @emlInitializeDrawingDefaults writes at the top of the file.
#
# WHAT THIS RIG ESTABLISHES, AND WHY GREP WOULD NOT.
#
# Six record legs, one Praat process each: two values of each setting. Every
# leg records a session, emits the script, and reports the numbers the session
# computed. Six replay legs, one fresh Praat process each, run the emitted
# file and report the numbers IT computed.
#
#   session == replay          the recorded script reproduces its session
#   replay(A) != replay(B)     and it does so BECAUSE of the setting
#
# The second line is the one that cannot be skipped. A replay that ignored the
# setting entirely would still satisfy the first at whichever value happens to
# equal the default -- which is exactly what a one-value rig would have
# reported as a pass.
#
# THE REPLAY OPENS THE FIXTURE THE SESSION SAVED. An emitted script names its
# object and states, in its own header, that the object must be open before
# the file is run. So each record leg writes its table to fx.csv and each
# replay leg reads it back under the same name; nothing is regenerated and the
# two sides cannot drift.
#
# ONE PRAAT PROCESS PER LEG, for the reason harness/stress_graphs.sh gives: a
# Praat script error aborts the script, so twelve legs in one process report
# one failure and hide eleven.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED -- nothing here calls beginPause: --
# and DISPLAY is unset rather than merely ignored, so the claim is proved
# rather than relied on.
#
# $EML_SP_SRC points every leg at a DIFFERENT COPY of the repository, and
# $EML_SP_OUTDIR moves the evidence with it, so validate/v115's break test can
# replay against a library with the capture removed without editing the
# working tree.
#
# Run from anywhere:  bash harness/settingspub/settingspub.sh
# Output: harness/settingspub/out/SETTINGSPUB.tsv     read by validate/v115
#         harness/settingspub/out/<leg>/emitted.praat the recorded scripts
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

SRC="${EML_SP_SRC:-$EML_ROOT}"
OUT="${EML_SP_OUTDIR:-$SCRIPT_DIR/out}"
PREFS="$OUT/prefs"
DRIVE="$SRC/harness/settingspub/settingspub_drive.praat"

LEGS="corr_holm corr_bonf alpha_05 alpha_01 sort_disc sort_alpha"

mkdir -p "$OUT" "$PREFS"
rm -f "$OUT"/*.log 2>/dev/null
for leg in $LEGS; do rm -rf "${OUT:?}/$leg"; done
TSV="$OUT/SETTINGSPUB.tsv"
: > "$TSV"
printf 'praat_version\t%s\n' "$("$PRAAT" --version 2>&1 | head -1)" >> "$TSV"
printf 'source_tree\t%s\n' "$SRC" >> "$TSV"

emit_kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

run_praat () {
    # STALE LOCK. Only the two files Praat leaves behind are removed, and only
    # from this rig's own scratch pref dir -- never from anyone else's, and
    # never the preferences directory itself.
    rm -f "$PREFS/pid" "$PREFS/message" 2>/dev/null
    local script="$1" logf="$2" leg="$3" aux="$4"
    env -u DISPLAY \
        EML_SP_LEG="$leg" EML_SP_OUT="$TSV" \
        EML_SP_AUX="$aux" EML_SP_ROOT="$SRC" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$script" \
        > "$logf" 2>&1
    return $?
}

# ---------------------------------------------------------------------------
# THE REPLAY DRIVER IS GENERATED PER LEG, because `include` takes a literal
# path and cannot be handed one in a variable. It is `include` and not
# `runScript:` for the reason the drive's header sets out: both execute the
# same text, and only include leaves the numbers the emitted file computed
# where this rig can read them. The Info report is written out as well, from
# the same run, so the comparison does not rest on that choice.
# ---------------------------------------------------------------------------
write_replay () {
    local leg="$1" aux="$2" f="$3"
    {
        printf 'Text writing preferences: "UTF-8"\n'
        printf 'Read Table from comma-separated file: "%s/fx.csv"\n' "$aux"
        printf 'clearinfo\n'
        printf 'include %s/emitted.praat\n' "$aux"
        printf 'writeFileLine: "%s/replay_info.txt", info$ ()\n' "$aux"
        printf 'procedure spOut: .key$, .value$\n'
        printf '    appendFileLine: "%s", .key$, tab$, .value$\n' "$TSV"
        printf 'endproc\n'
        printf '@spOut: "%s_replay_brackets", string$ (annotBracketN)\n' "$leg"
        printf '@spOut: "%s_replay_adjust", annotBracketAdjust$\n' "$leg"
        printf 'for b from 1 to annotBracketN\n'
        printf '    @spOut: "%s_replay_p" + string$ (b), fixed$ (annotBracketP[b], 6)\n' "$leg"
        printf '    @spOut: "%s_replay_label" + string$ (b), annotBracketLabel$[b]\n' "$leg"
        printf 'endfor\n'
        # THE THREE GLOBALS AS THE REPLAY LEFT THEM, each behind its own
        # variableExists. A replay that never received one has no such
        # variable, and reading it would abort this probe AFTER every
        # observable above was already written -- turning "the setting did
        # not arrive" into "the replay crashed", which are not the same
        # finding and must not share an exit status.
        printf 'if variableExists ("annotAlpha")\n'
        printf '    @spOut: "%s_replay_alpha_inforce", string$ (annotAlpha)\n' "$leg"
        printf 'else\n'
        printf '    @spOut: "%s_replay_alpha_inforce", "<unset>"\n' "$leg"
        printf 'endif\n'
        printf 'if variableExists ("emlGroupSortAlphabetical")\n'
        printf '    @spOut: "%s_replay_sort_inforce", string$ (emlGroupSortAlphabetical)\n' "$leg"
        printf 'else\n'
        printf '    @spOut: "%s_replay_sort_inforce", "<unset>"\n' "$leg"
        printf 'endif\n'
        printf 'if variableExists ("annotCorrectionMethod$")\n'
        printf '    @spOut: "%s_replay_corr_inforce", annotCorrectionMethod$\n' "$leg"
        printf 'else\n'
        printf '    @spOut: "%s_replay_corr_inforce", "<unset>"\n' "$leg"
        printf 'endif\n'
    } > "$f"
}

# ---------------------------------------------------------------------------
# WHAT THE REPORT SAYS, extracted from BOTH Info captures by ONE reader.
#
# The interval's level is printed in the label the reporter builds -- "95% CI
# of diff" -- and the group order is printed in the two group lines and in the
# SIGN of the mean difference. Reading both sides with the same patterns is
# what makes "session == replay" a comparison and not two separate readings
# that happen to agree.
# ---------------------------------------------------------------------------
report_lines () {
    local leg="$1" side="$2" f="$3"
    if [[ ! -s "$f" ]]; then
        emit_kv "${leg}_${side}_report" "0"
        return 0
    fi
    emit_kv "${leg}_${side}_report" "1"
    # THE FOUR LINES THAT CARRY A DECISION. The interval's level is printed
    # in the label the reporter builds; the group order is printed in the
    # two group rows, in the sentence that states which group is subtracted
    # from which, and in the SIGN of t and of the mean difference. Reading
    # both sides with the same patterns is what makes session == replay a
    # comparison rather than two readings that happen to agree.
    while IFS= read -r ln; do
        emit_kv "${leg}_${side}_ci" "$(printf '%s' "$ln" | tr -s ' ')"
    done < <(grep -a 'CI of diff' "$f")
    while IFS= read -r ln; do
        emit_kv "${leg}_${side}_meandiff" "$(printf '%s' "$ln" | tr -s ' ' | cut -f1)"
    done < <(grep -a 'Mean diff' "$f")
    while IFS= read -r ln; do
        emit_kv "${leg}_${side}_sign" "$(printf '%s' "$ln" | tr -s ' ')"
    done < <(grep -a 'every difference below is' "$f")
    while IFS= read -r ln; do
        emit_kv "${leg}_${side}_t" "$(printf '%s' "$ln" | tr -s ' ' | cut -f1)"
    done < <(grep -aE '^  t  ' "$f")
    while IFS= read -r ln; do
        emit_kv "${leg}_${side}_grouprow" "$(printf '%s' "$ln" | tr -s ' ')"
    done < <(grep -aE '^  (zulu|alfa) ' "$f")
}

for leg in $LEGS; do
    AUX="$OUT/$leg"
    mkdir -p "$AUX"
    emit_kv "leg" "$leg"
    run_praat "$DRIVE" "$OUT/${leg}_record.log" "$leg" "$AUX"
    emit_kv "${leg}_record_exit" "$?"
    if [[ ! -s "$AUX/emitted.praat" ]]; then
        emit_kv "${leg}_emitted" "<none>"
        continue
    fi
    emit_kv "${leg}_emitted" "yes"
    # THE THREE LINES, READ OUT OF THE FILE A USER WOULD RUN. Anchored, so a
    # comment that merely names a setting is never counted as a statement of
    # one.
    for name in 'annotCorrectionMethod\$' 'annotAlpha' 'emlGroupSortAlphabetical'; do
        n=$(grep -acE "^${name} = " "$AUX/emitted.praat")
        emit_kv "${leg}_emits_$(printf '%s' "$name" | tr -d '\\$')" "$n"
    done
    while IFS= read -r ln; do
        emit_kv "${leg}_settingline" "$ln"
    done < <(grep -aE '^(annotCorrectionMethod\$|annotAlpha|emlGroupSortAlphabetical) = ' "$AUX/emitted.praat")

    write_replay "$leg" "$AUX" "$AUX/replay.praat"
    run_praat "$AUX/replay.praat" "$OUT/${leg}_replay.log" "$leg" "$AUX"
    emit_kv "${leg}_replay_exit" "$?"
    report_lines "$leg" "session" "$AUX/session_info.txt"
    report_lines "$leg" "replay"  "$AUX/replay_info.txt"
done

emit_kv "leg" "--shell--"
echo "settingspub: wrote $TSV"
grep -c . "$TSV" | sed 's/^/settingspub: rows /'
exit 0
