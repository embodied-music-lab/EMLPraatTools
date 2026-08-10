#!/bin/bash
# ============================================================================
# Parallel GUI walk rig — N concurrent full-GUI Praat instances
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Implements §3 of PARALLEL_WALK_PLAN.md. Brings up N independent instances,
# each with its own X display, window manager, compositor and pref-dir, so a
# walk script can own one instance start to finish (§4: partition by menu
# entry, never by field within an entry).
#
#   harness/walks/rig.sh up 3        bring up 3 instances
#   harness/walks/rig.sh shot 1      screenshot instance 1
#   harness/walks/rig.sh down        tear everything down
#
# VERIFIED in this sandbox 7 Aug 2026: 3 instances, plugin loaded in each,
# "+EML Tools" present in the New menu, clicks landing on target.
#
# Deltas from the plan's recipe, found bringing it up here:
#
#   1. openbox is NOT installed by default in this image. `apt-get install -y
#      openbox` first, or the WM step silently no-ops and xdotool clicks land
#      on an unmanaged window. matchbox-window-manager IS present and is what
#      the older single-instance GUI_HARNESS_RECIPE.md uses, but its centering
#      differs, so the plan's pixel anchors do not transfer to it.
#
#   2. The plan's ~26 px Y correction is NOT needed when anchors are read off
#      a screenshot. That offset is between xdotool's REPORTED geometry and
#      the painted position; a coordinate taken from `import -window root`
#      output is already the painted position. Read anchors from the
#      screenshot and click them raw. The correction is only needed if you
#      derive coordinates from `xdotool getwindowgeometry`.
#
#   3. The plugin is SYMLINKED into each pref-dir rather than copied. The
#      older recipe required `rsync -a --delete plugin/ <prefs>/plugin_.../`
#      before every GUI check because the GUI loads an installed copy and a
#      stale copy silently validates the wrong code. A symlink removes that
#      failure mode: the instance loads the working tree, always.
#
# Standing rules this script encodes:
#   - `rm -f pid message` before every launch. A stale pid makes a relaunch
#     silently forward its script to the dead process and exit.
#   - `setsid nohup` on every long-lived process; tool calls reap process
#     groups otherwise.
#   - `pkill -x praat`, NEVER `pkill -f praat` — the -f form matches and kills
#     the driving shell.
#   - clear /tmp/.X9i-lock before Xvfb or it exits 1.
# ============================================================================

set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# PRAAT falls back to the repo-adjacent symlink, then PATH. See
# harness/_env.sh, which this rig predates.
PRAAT=${PRAAT:-$(command -v praat_barren || command -v praat)}
# Scratch GUI rig. Outside the repo on purpose -- it holds a running
# Praat's preferences and Xvfb state, none of which belongs in version
# control. Overridable with RIG=.
RIG=${RIG:-${TMPDIR:-/tmp}/eml-rig}
GEOM=${GEOM:-1280x900x24}

inst_up () {
    local i=$1 D=":9$i" P="$RIG/prefs_$i"
    rm -f "/tmp/.X9$i-lock" "/tmp/.X11-unix/X9$i"
    mkdir -p "$P" "$RIG/log"
    rm -f "$P/pid" "$P/message"
    ln -sfn "$REPO/plugin" "$P/plugin_EML_Praat_Tools"
    setsid nohup Xvfb "$D" -screen 0 "$GEOM" > "$RIG/log/xvfb_$i.log" 2>&1 &
    sleep 2
    DISPLAY=$D setsid nohup openbox  > "$RIG/log/wm_$i.log" 2>&1 &
    DISPLAY=$D setsid nohup xcompmgr > "$RIG/log/xc_$i.log" 2>&1 &
    sleep 1
    DISPLAY=$D HOME=$P setsid nohup "$PRAAT" --pref-dir="$P" --utf8 \
        > "$RIG/log/praat_$i.log" 2>&1 &
}

case "${1:-up}" in
  up)
    N=${2:-3}
    for i in $(seq 1 "$N"); do inst_up "$i"; done
    sleep 8
    ok=0
    for i in $(seq 1 "$N"); do
        D=":9$i"
        w=$(DISPLAY=$D xdotool search --name 'Praat Objects' 2>/dev/null | wc -l)
        x=$(DISPLAY=$D xdpyinfo >/dev/null 2>&1 && echo ok || echo FAIL)
        printf "inst %s  display %-4s  X=%-4s  objects_window=%s\n" "$i" "$D" "$x" "$w"
        [ "$x" = ok ] && [ "$w" -ge 1 ] && ok=$((ok+1))
    done
    echo "up: $ok/$N"
    [ "$ok" -eq "$N" ] || exit 1
    ;;
  shot)
    i=${2:?instance}
    out=${3:-/tmp/rig_$i.png}
    DISPLAY=":9$i" import -window root "$out" && echo "$out"
    ;;
  down)
    pkill -x praat
    pkill -x xcompmgr
    pkill -x openbox
    pkill -x Xvfb
    sleep 1
    rm -f "$RIG"/prefs_*/pid "$RIG"/prefs_*/message
    echo "down"
    ;;
  *) echo "usage: rig.sh {up N|shot i [out]|down}" >&2; exit 2 ;;
esac
