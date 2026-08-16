#!/usr/bin/env bash
# ============================================================================
# harness/drawlayer/pergroup_gui.sh — the ONE leg of this rig that needs an X
#                                     server, and why
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Ruling 6's fourth site is the PER-GROUP branch of
# plugin/scripts/eml-check-normality.praat. It is not a procedure: it is inline
# in a wrapper whose first statement is `beginPause:`, and `praat --run` cannot
# open a display connection at all -- so that branch cannot be reached
# headlessly, and re-implementing its four report lines in a harness would be a
# COPY of the thing under test. Copying that branch is what D137 was.
#
# So this leg runs a real GUI instance and clicks, on harness/walks/rig.sh
# instance 7 -- DISPLAY :97. Instances :88, :94, :121 and :180+ were in use by
# other work on 15 August 2026 and :91 belongs to harness/normality/pergroup.sh;
# :97 was unclaimed, and `I=7` is the only thing that decides it. The rig is
# brought up only if it is not already serving and it is NOT torn down here,
# for the reason rig.sh gives: a teardown that runs while another walk is up
# takes that walk with it. Kill by instance, never `pkill -f praat`.
#
# Everything in the walk itself -- launch, ptitle, popt, pbtn, infodump -- is
# harness/walks/d117/lib.sh's, unchanged and unforked. Two dialogs are driven:
#
#   Page 1  "Pause: Check Normality"     group column := grp, then Run
#   Page 2  the completion dialog        Done
#
# Output: harness/drawlayer/out/info_pergroup.txt  (the Info window verbatim)
#         and a PERGROUP.tsv verdict line, so a walk that mis-drove is a
#         recorded fact rather than a short file the validator reads as
#         evidence.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
OUTDIR="${EML_DL_OUTDIR:-$HERE/out}"
I=${I:-7}
export I REPO
export OUT="$OUTDIR"
mkdir -p "$OUTDIR"

# THE FIXTURE. One symmetric group, whose skewness is a genuine zero that
# floating-point arithmetic leaves a few ulps away from it, and one strongly
# skewed group, whose Shapiro-Wilk p is far past the APA floor. Those are the
# two shapes Praat's fixed$ answers wrongly, in opposite directions, and both
# of them are the ORDINARY case for a normality preview rather than a corner.
CSV="$OUTDIR/pergroup.csv"
{
    echo "grp,y"
    for k in $(seq 1 24); do
        printf 'sym,%s\n' "$(awk -v k="$k" 'BEGIN{printf "%.6f", k - 12.5}')"
    done
    for k in $(seq 1 24); do
        printf 'skw,%s\n' "$(awk -v k="$k" 'BEGIN{printf "%.6f", exp((k-1)/3)}')"
    done
} > "$CSV"

. "$REPO/harness/walks/d117/lib.sh"

TSV="$OUTDIR/PERGROUP.tsv"
: > "$TSV"

if ! DISPLAY=":9$I" xdpyinfo >/dev/null 2>&1; then
    echo "pergroup_gui: bringing up rig instance $I"
    # Through `bash`: no .sh in this repository carries an execute bit, so a
    # direct exec is "Permission denied" and this leg records NO_RIG for a
    # reason that is not the rig's. Same repair as harness/normality/
    # pergroup.sh, 16 Aug 2026.
    REPO="$REPO" bash "$REPO/harness/walks/rig.sh" up "$I" >/dev/null 2>&1 || {
        printf 'verdict\tNO_RIG\n' >> "$TSV"
        echo "pergroup_gui: rig instance $I would not come up" >&2
        exit 0
    }
fi

EML_DL_CSV="$CSV" launch "$HERE/pergroup_case.praat"

t=$(ptitle)
if [ "$t" != "Pause: Check Normality" ]; then
    printf 'verdict\tNO_DIALOG\n' >> "$TSV"
    printf 'saw_title\t%s\n' "$t" >> "$TSV"
    echo "pergroup_gui: expected the entry form, saw [$t]" >&2
    exit 0
fi

# THE GROUP COLUMN MENU is built from the table's own column order, prefixed
# by "(none - overall only)", so "grp" -- written first in the CSV above -- is
# item 2. Read off the wrapper, not guessed.
popt 1 2 1
# Praat adds Undo to every pause window, so a two-button endPause is a
# THREE-button row: Undo, Quit, Run.
pbtn 3 3 5

t=$(ptitle)
printf 'page2_title\t%s\n' "$t" >> "$TSV"
# The completion dialog: Undo, Done, Draw, New. Done, so the Info window is
# left intact and Praat goes idle -- infodump talks to an idle Praat only.
pbtn 2 4 3

infodump "$OUTDIR/info_pergroup.txt" >/dev/null 2>&1
if [ -s "$OUTDIR/info_pergroup.txt" ]; then
    printf 'verdict\tOK\n' >> "$TSV"
    printf 'bytes\t%s\n' "$(stat -c%s "$OUTDIR/info_pergroup.txt")" >> "$TSV"
else
    printf 'verdict\tNO_CAPTURE\n' >> "$TSV"
fi

# Leave the instance up. See the header.
echo "pergroup_gui: $(cat "$TSV" | tr '\n' ' ')"
exit 0
