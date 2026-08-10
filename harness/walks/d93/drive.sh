#!/bin/bash
# drive.sh <instance> <script>   — relaunch ONE rig instance running <script>.
# Kills only that instance's praat (by recorded pid), never `pkill -x praat`,
# so the other instances keep their walk state.
set -u
i=$1; S=$2
# Scratch GUI rig. Outside the repo on purpose -- it holds a running
# Praat's preferences and Xvfb state, none of which belongs in version
# control. Overridable with RIG=.
RIG=${RIG:-${TMPDIR:-/tmp}/eml-rig}
P="$RIG/prefs_$i"; D=":9$i"
if [ -f "$RIG/log/drivepid_$i" ]; then
    kill "$(cat "$RIG/log/drivepid_$i")" 2>/dev/null
    sleep 1
fi
# any praat holding this display, without touching the others
for pid in $(pgrep -x praat); do
    tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
        | grep -qx "DISPLAY=$D" && kill "$pid" 2>/dev/null
done
sleep 1
rm -f "$P/pid" "$P/message"
DISPLAY=$D HOME=$P setsid nohup "${PRAAT:-$(command -v praat_barren || command -v praat)}" --new-send \
    --pref-dir="$P" --utf8 "$S" > "$RIG/log/drive_$i.log" 2>&1 &
echo $! > "$RIG/log/drivepid_$i"
sleep 6
DISPLAY=$D xdotool search --name . getwindowname %@ 2>/dev/null | sort -u
