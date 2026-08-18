#!/usr/bin/env bash
# ============================================================================
# harness/archshape/break.sh — nothing is validated until it has been broken
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# validate/v85 is the only thing standing between a user and an archive that
# is the wrong shape, and every one of its claims is about a zip it built
# itself. A file like that can be green because the tree is right or because
# the check is asleep, and reading it cannot tell the two apart. So each break
# below is a COMPLETE CLONE of this repository carrying one deliberate defect,
# COMMITTED in that clone, with v85 run against it and its reds counted.
#
# THE CLONE IS THE POINT. The working tree is never touched, so an interrupted
# run cannot leave a defect behind; and the damage is COMMITTED rather than
# left dirty, because v85 compares HEAD's .gitattributes with the working
# tree's and reports a divergence. Leaving the damage uncommitted would turn
# that check red in every case and drown the one red each break is for.
#
# WHAT THE BREAKS ARE FOR. They fall in two groups, and the split is the
# argument rather than a filing convention.
#
#   THE ARCHIVE'S SHAPE — the four things a user receives. The symlink
#   shipping beside the plugin; the plugin folder wearing a different name;
#   dev/ back inside the folder that gets dragged into Praat; validate/ gone.
#   validate_thinned is the sharp one: validate/ is still there, still has a
#   runner, a registry and this validator in it, and only the COUNT is wrong.
#   Anything that tested validate/ by presence passes that break.
#
#   THE SYMLINK IN THE CHECKOUT — the half that the archive cannot see, and
#   the reason the rename was done by symlink rather than by editing 2,178
#   paths. Deleted, dangling, committed as a regular file (the Windows
#   checkout without developer mode), or repaired into a physical COPY of the
#   tree. In EVERY one of these the archive is still perfectly shaped, so
#   every archive check stays green while the checkout every other rig reads
#   is empty or duplicated. Those four breaks are what says the symlink half
#   of v85 is load-bearing and not decoration.
#
#   Run:  bash harness/archshape/break.sh [name-substring]
#   Out:  harness/archshape/out/BREAKS.tsv    break, red-count, first fail
#         harness/archshape/out/break_<name>.v85.log
# ============================================================================
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/harness/archshape/out"
WORK="${TMPDIR:-/tmp}/archshape.$$"
ONLY="${1:-}"
mkdir -p "$OUT"; rm -rf "$WORK"; mkdir -p "$WORK"
TSV="$OUT/BREAKS.tsv"; : > "$TSV"

clone() {                      # $1 = break name -> echoes the clone path
    local d="$WORK/$1"
    git clone --quiet --local "$ROOT" "$d" 2>/dev/null || return 1
    git -C "$d" config user.name  "Ian Howell"
    git -C "$d" config user.email "admin@embodiedmusiclab.com"
    # THE RIG SCORES THE VALIDATOR AS IT STANDS IN THIS TREE, not as HEAD
    # carries it. A break test whose subject is the committed copy cannot be
    # run until after the commit, which is the wrong moment to learn a check
    # does not go red. The clone is HEAD; this one file is the working tree's.
    cp "$ROOT/validate/v85_source_archive_shape.R" "$d/validate/"
    echo "$d"
}

run_break() {                  # $1 = name, $2 = shell body run inside the clone
    local name="$1" body="$2"
    [ -n "$ONLY" ] && case "$name" in *"$ONLY"*) ;; *) return 0 ;; esac
    local d; d="$(clone "$name")" || { echo "CLONE FAILED $name"; return 1; }
    ( cd "$d" && eval "$body" && git add -A && \
      git commit --quiet -m "break: $name" ) >/dev/null 2>&1
    local log="$OUT/break_$name.v85.log"
    ( cd "$d" && Rscript validate/v85_source_archive_shape.R ) > "$log" 2>&1
    local red first
    red=$(grep -c '^FAIL ' "$log")
    first=$(grep -m1 '^FAIL ' "$log" | sed 's/^FAIL *v85 *//; s/  *computed=.*$//')
    [ -z "$first" ] && first="(none — THIS BREAK DID NOT GO RED)"
    printf '%s\t%s\t%s\n' "$name" "$red" "$first" >> "$TSV"
    printf '%-22s %3s red   %s\n' "$name" "$red" "$first"
    rm -rf "$d"
}

echo "== control: an undamaged clone must be GREEN, or every count below is noise"
run_break control ':'

echo
echo "== the archive's shape"
run_break symlink_ships    "sed -i '/^\/plugin export-ignore/d' .gitattributes"
run_break folder_misnamed  "git mv plugin_EML_StatsGraphs plugin_EML_Graphs && \
                            rm -f plugin && ln -s plugin_EML_Graphs plugin && \
                            sed -i 's|^plugin_EML_StatsGraphs/dev/|plugin_EML_Graphs/dev/|' .gitattributes"
run_break dev_returns      "sed -i '/^plugin_EML_StatsGraphs\/dev\/ export-ignore/d' .gitattributes"
run_break validate_gone    "printf 'validate/ export-ignore\n' >> .gitattributes"
run_break validate_thinned "printf 'validate/v0*.R export-ignore\n' >> .gitattributes"

echo
echo "== the symlink in the checkout (the archive stays perfect in all four)"
run_break link_deleted     "git rm -q --cached plugin && rm -f plugin"
run_break link_dangling    "rm -f plugin && ln -s plugin_EML_Stats_Graphs plugin"
run_break link_regular_file "rm -f plugin && printf 'plugin_EML_StatsGraphs' > plugin"
run_break link_is_a_copy   "rm -f plugin && cp -a plugin_EML_StatsGraphs plugin"

rm -rf "$WORK"
echo
echo "wrote $TSV"
