#!/usr/bin/env bash
# ============================================================================
# harness/suiteguard/break.sh — the runner's own refusal, watched
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# validate/run_all.R now refuses to end quietly: it reads its script list as
# data before it sources anything, counts what it sourced against the length
# of that list, and requires at least one recorded check per sourced script.
# Any one of those unmet ends the output in a banner and exits 2.
#
# EVERY ONE OF THOSE IS A CLAIM ABOUT A RUN THAT DOES NOT HAPPEN, which is
# the one kind of claim reading cannot settle: a guard that never fires and a
# guard that cannot fire produce the same green suite. So each break below is
# a COMPLETE CLONE of this repository carrying one deliberate defect, with the
# suite run against it and its exit status, its banner and its headline read
# off the log.
#
# THE CLONE IS THE POINT. The working tree is never damaged, so an interrupted
# run cannot leave a broken validator behind.
#
# THE FOUR DEFECTS, and why these four:
#
#   renamed_file    A validator is renamed and the list is not. This is what
#                   a rename actually looks like — nobody adds a fictional
#                   name to the list, they move a file. `source()` would
#                   error on it, which the error handler catches; the list
#                   check names it first and names it as data.
#
#   emptied_file    A validator truncated to nothing. `source()` on an empty
#                   file SUCCEEDS. There is no error to catch and no check to
#                   count, and before this guard existed the run stayed green
#                   one validator lighter.
#
#   comments_only   The sharp one. The file is present, non-empty, valid R,
#                   and sources without a word — it just records nothing.
#                   Every file-level check in the list pass passes it. What
#                   the run has to do is notice the SILENCE, and the two
#                   clones below are the two shapes that takes: a validator
#                   whose checks the coverage pass depends on, and one whose
#                   checks nothing downstream reads.
#
#   Run:  bash harness/suiteguard/break.sh [name-substring]
#   Out:  harness/suiteguard/out/BREAKS.tsv
#             break, exit status, banner y/n, headline
#         harness/suiteguard/out/break_<name>.run_all.log
# ============================================================================
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/harness/suiteguard/out"
WORK="${TMPDIR:-/tmp}/suiteguard.$$"
ONLY="${1:-}"
mkdir -p "$OUT"; rm -rf "$WORK"; mkdir -p "$WORK"
TSV="$OUT/BREAKS.tsv"
if [ -z "$ONLY" ]; then
    printf '# break\texit\tbanner\tred\tquiet\theadline\n' > "$TSV"
fi

clone() {                      # $1 = break name -> echoes the clone path
    local d="$WORK/$1"
    git clone --quiet --local "$ROOT" "$d" 2>/dev/null || return 1
    git -C "$d" config user.name  "Ian Howell"
    git -C "$d" config user.email "admin@embodiedmusiclab.com"
    # THE RIG SCORES THE RUNNER AS IT STANDS IN THIS TREE, not as HEAD carries
    # it: a break test whose subject is the committed copy cannot be run until
    # after the commit, which is the wrong moment to learn a guard is asleep.
    cp "$ROOT/validate/run_all.R" "$d/validate/"
    echo "$d"
}

run_break() {                  # $1 = name, $2 = shell body run inside the clone
    local name="$1" body="$2"
    [ -n "$ONLY" ] && case "$name" in *"$ONLY"*) ;; *) return 0 ;; esac
    local d; d="$(clone "$name")" || { echo "CLONE FAILED $name"; return 1; }
    ( cd "$d" && eval "$body" ) >/dev/null 2>&1
    local log="$OUT/break_$name.run_all.log"
    ( cd "$d" && Rscript validate/run_all.R ) > "$log.full" 2>&1
    local st=$?
    # THE PASS LINES ARE DROPPED AND THE COUNT OF THEM IS KEPT. A full suite
    # log is 2.7 MB of "PASS", the same 13,000 lines in every clone, and the
    # four lines that differ are the ones this rig is about: the banner, the
    # "recorded nothing" line, any FAIL, and the summary. Storing seven
    # near-identical copies of the rest would bury them. The dropped count is
    # written into the header so the log still says how big the run was, and
    # re-running this rig reproduces the whole thing.
    local kept
    kept=$(grep -c '^PASS ' "$log.full")
    { printf '# %s -- validate/run_all.R, exit %s\n' "$name" "$st"
      printf '# %s PASS lines removed; every other line of the run is below.\n' "$kept"
      printf '# Reproduce in full: bash harness/suiteguard/break.sh %s\n\n' "$name"
      grep -v '^PASS ' "$log.full"
    } > "$log"
    rm -f "$log.full"
    local banner headline quiet total
    banner=no
    grep -q 'THE VALIDATION SUITE DID NOT RUN TO COMPLETION' "$log" && banner=yes
    headline="$(grep -A1 '^!!!!' "$log" | grep -v '^!!' | grep -v '^--' \
                | head -1)"
    [ -z "$headline" ] && headline="$(grep -E '^[0-9]+ checks, ' "$log" | tail -1)"
    [ -z "$headline" ] && headline="(no banner, no summary)"
    quiet="$(grep -m1 '^recorded nothing: ' "$log" | sed 's/^recorded nothing: //')"
    [ -z "$quiet" ] && quiet="-"
    total="$(grep -cE '^FAIL ' "$log")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$name" "$st" "$banner" "$total" "$quiet" "$headline" >> "$TSV"
    printf '%-18s exit %s  banner %-3s  %s red   quiet=%s\n   %s\n' \
        "$name" "$st" "$banner" "$total" "$quiet" "$headline"
    rm -rf "$d"
}

echo "== control: an undamaged clone must be GREEN, or every line below is noise"
run_break control ':'

echo
echo "== a name in the list that is not a file on disk"
run_break renamed_file \
    "git mv validate/v22_homogeneity.R validate/v22_homogeneity_renamed.R"

echo
echo "== a file that is there and holds nothing"
run_break emptied_file ": > validate/v37_determinism.R"

echo
echo "== a validator that sources cleanly and records no check at all"
run_break comments_only_claimed \
    "printf '# v43_form_helpers.R -- body removed by harness/suiteguard/break.sh\\n# It still parses, still sources, and records nothing.\\n' \
     > validate/v43_form_helpers.R"
run_break comments_only_unclaimed \
    "printf '# v05_paired_t.R -- body removed by harness/suiteguard/break.sh\\n# It still parses, still sources, and records nothing.\\n' \
     > validate/v05_paired_t.R"

# THE SAME DEFECT WITH ITS INCIDENTAL CATCHES REMOVED. Both clones above are
# also caught by v83, whose subject is the evidence census -- editing a
# validator file changes the census, and the census disagreeing with its
# committed record is red for reasons that have nothing to do with checks not
# running. This clone regenerates the census after the damage, so what is left
# is the question actually being asked: does anything notice a validator that
# sources cleanly and records NOTHING?
run_break comments_only_alone \
    "printf '# v05_paired_t.R -- body removed by harness/suiteguard/break.sh\\n# It still parses, still sources, and records nothing.\\n' \
     > validate/v05_paired_t.R && Rscript validate/tools/evidence_census.R"

echo
echo "== the legitimate silence the aggregate floor exists for"
# NOT A DEFECT. The NIST .dat files are not redistributable, so a fresh clone
# has none and v19_nist_strd.R prints a SKIP and records nothing. This clone
# is what a clean machine looks like, and it is the reason the floor is an
# aggregate rather than one check per file: a per-script rule would refuse a
# correct run. It is here so that the claim is measured rather than asserted.
run_break nist_absent "rm -f evidence/nist/results.csv"

echo
echo "wrote $TSV"
