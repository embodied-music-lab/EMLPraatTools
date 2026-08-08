#!/bin/bash
# ---------------------------------------------------------------------------
# LEGEND GEOMETRY DRIVER. Renders the legend matrix and measures every figure
# ON THE PIXELS OF THE SAVED PNG.
#
# Usage:  harness/legend/run.sh [case-name-substring]
# Output: <out>/<case>.png            the figure
#         <out>/<case>.log            the Praat transcript
#         <out>/RESULTS.tsv           one row per case, 46 fields:
#             case vpW vpH n mode labels legend pReq pAct verdict
#             imgW imgH frameL frameT frameR frameB
#             inkLeft inkRight inkAbove inkBelow edgeR edgeB inkDark
#             boxX boxY boxW boxH cols rows shown hidden
#             mL mR mT mB innerL innerR innerT innerB
#             extMinX extMaxX extMinY extMaxY layoutW layoutH note
#
#   <out> is $EML_LEGEND_DIR, default harness/legend/out — IN-REPO, for the
#   reason harness/stress_graphs.sh gives: validate/v32_legend_geometry.R
#   HARD STOPS on a missing artefact rather than skipping, so a fresh clone
#   has to be able to produce it, and an out-of-tree default would make the
#   validator unrunnable on a machine that has never driven this. The
#   override exists so a second agent rendering into the tree at the same
#   time can be given a private directory.
#
# Every case runs in its OWN praat process, for the reason
# harness/stress_graphs.sh states: a Praat script error aborts the script, so
# one driver running the whole matrix reports one failure and hides the rest
# behind it.
#
# ---------------------------------------------------------------------------
# BLOCK 1 — THE LEGEND MATRIX. Three figure sizes x two colour modes x seven
# legend variants = 42 figures, all of them with no emlLegendPlacement
# declared at all, which is the pre-placement world every existing caller
# still lives in.
#
#   6x4    the plugin's default, and the size D123 and D135 were measured on
#   5x5    SQUARE. The author's objection is stated in this case: if a legend
#          carves space out of the figure, "make my figure square" cannot be
#          satisfied, because the plot goes oblong while the file stays square
#   10x3   short and wide. A legend placed below has nowhere to go here, and
#          a legend placed right has room to spare — the two placements fail
#          in opposite directions on this shape
#
#   g0     zero entries — the red path
#   g1     one entry. D123 promised that any legend fitting one column keeps
#          the pre-layout geometry "to the last decimal", so this is the case
#          that catches the layout changing something it said it would not
#   g3     three entries, the ordinary figure
#   g12    twelve — two columns' worth of the palette on the default figure
#   g24    the palette's full style space, and the count that used to run off
#          the top of the frame before D123
#   wide   three entries, the first of them 480 characters — wider than the
#          frame of every size here. D135
#   none   no legend drawn at all, everything else identical to g24. This is
#          the CONTROL: the plot rectangle must measure the same with a
#          legend as without one
#
# BLOCK 2 — THE FIVE PLACEMENTS, at twelve entries, one render each per size:
# 15 figures. This is the constraint itself, driven rather than argued:
#
#     1 Inside plot   2 Right of plot   3 Below plot
#     4 Separate figure                 5 None
#
# The plot rectangle must be the SAME RECTANGLE in all five and the same as
# the unset case in block 1, and what changes between them is the SAVED
# IMAGE. Placement 1 is rendered explicitly as well as by default, because
# "the global is absent" and "the global is 1" are different inputs and only
# one of them is what every existing caller supplies.
# ---------------------------------------------------------------------------
#
# WHY THE MEASUREMENTS COME FROM measure.py AND NOT FROM THE CASE. The case
# prints the box @emlDrawLegend says it drew, and that is recorded — but it
# is computed with the same arithmetic the procedure used, so if the drawing
# and the arithmetic disagree the two sides move together and nothing shows.
# The frame, the image and the ink are therefore read off the rendered
# pixels; see the block comment at the head of measure.py.
#
# validate/v32_legend_geometry.R reads RESULTS.tsv and the logs.
# ---------------------------------------------------------------------------
set -u
ROOT=/home/claude/EMLPraatTools
CASE=$ROOT/harness/legend/case.praat
MEASURE=$ROOT/harness/legend/measure.py
OUT=${EML_LEGEND_DIR:-$ROOT/harness/legend/out}
PRAAT=/home/claude/praat
# Scratch only, never read by a check. Its own directory rather than the
# shared harness one, so a concurrent run of another driver cannot collide
# with this one over Praat's preferences file.
PREFS=${EML_LEGEND_PREFS:-/home/claude/stress/prefs-legend}
FILTER="${1:-}"

mkdir -p "$OUT" "$PREFS"
: > "$OUT/RESULTS.tsv"
# Clear stale per-case artefacts, for the reason harness/disclosure/run.sh
# gives: a renamed case leaves its old .log behind and a validator that still
# names it reads a previous run's evidence and passes.
rm -f "$OUT"/*.log "$OUT"/*.png

# field RECORD KEY FILE — pull "key=value" out of a record line in a transcript
field () {
    sed -n "s/^$1 .*[[:space:]]$2=\([^ ]*\).*$/\1/p;s/^$1 $2=\([^ ]*\).*$/\1/p" \
        "$3" | head -1
}

# render NAME W H N MODE LABELS LEGEND PLACEMENT
#   PLACEMENT of "-" leaves emlLegendPlacement undeclared, which is what every
#   caller written before the placements supplies.
render () {
    local name=$1 w=$2 h=$3 n=$4 mode=$5 labels=$6 legend=$7 placement=$8
    [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) return 0 ;; esac

    rm -f "$OUT/$name.png"
    local pEnv=""
    [ "$placement" != "-" ] && pEnv="$placement"
    # DISPLAY deliberately unset: proves the case needs no X server, and stops
    # a stray connection to an interactive instance.
    env -u DISPLAY EML_OUT="$OUT/$name.png" EML_CASE="$name" \
        EML_VPW="$w" EML_VPH="$h" EML_N="$n" EML_MODE="$mode" \
        EML_LABELS="$labels" EML_LEGEND="$legend" EML_PLACEMENT="$pEnv" \
        "$PRAAT" --pref-dir="$PREFS" --run "$CASE" \
        > "$OUT/$name.log" 2>&1

    local verdict
    if [ -s "$OUT/$name.png" ]; then
        if grep -qiE "^Error|not completed|Unknown variable" "$OUT/$name.log"; then
            verdict=DREW_THEN_FAILED
        else
            verdict=OK
        fi
    else
        verdict=NO_FIGURE
    fi

    local imgW=NA imgH=NA fL=NA fT=NA fR=NA fB=NA
    local iL=NA iR=NA iA=NA iB=NA eR=NA eB=NA iD=NA m
    if [ "$verdict" = OK ]; then
        if m=$(python3 "$MEASURE" "$OUT/$name.png" 2>>"$OUT/$name.log"); then
            set -- $m
            imgW=$1; imgH=$2; fL=$3; fT=$4; fR=$5; fB=$6
            iL=$7; iR=$8; iA=$9; iB=${10}; eR=${11}; eB=${12}; iD=${13}
        else
            case "$m" in
                FRAME_NOT_FOUND) verdict=FRAME_NOT_FOUND ;;
                *)               verdict=MEASURE_FAILED ;;
            esac
        fi
    fi

    local log="$OUT/$name.log"
    local bx by bw bh cols rows shown hidden
    bx=$(field LEGENDBOX x "$log");     by=$(field LEGENDBOX y "$log")
    bw=$(field LEGENDBOX w "$log");     bh=$(field LEGENDBOX h "$log")
    cols=$(field LEGENDLAYOUT cols "$log")
    rows=$(field LEGENDLAYOUT rows "$log")
    shown=$(field LEGENDLAYOUT shown "$log")
    hidden=$(field LEGENDLAYOUT hidden "$log")
    local pReq pAct mL mR mT mB iLft iRgt iTop iBot xMinE xMaxE yMinE yMaxE lgW lgH note
    pReq=$(field PLACEMENT requested "$log")
    pAct=$(field PLACEMENT actual "$log")
    mL=$(field THEME mL "$log");        mR=$(field THEME mR "$log")
    mT=$(field THEME mT "$log");        mB=$(field THEME mB "$log")
    iLft=$(field THEME innerL "$log");  iRgt=$(field THEME innerR "$log")
    iTop=$(field THEME innerT "$log");  iBot=$(field THEME innerB "$log")
    xMinE=$(field EXTENT minX "$log");  xMaxE=$(field EXTENT maxX "$log")
    yMinE=$(field EXTENT minY "$log");  yMaxE=$(field EXTENT maxY "$log")
    lgW=$(field LAYOUT legendW "$log"); lgH=$(field LAYOUT legendH "$log")
    note=$(grep -iE "^Error|Unknown|not completed|^NOTE:" "$log" \
           | head -1 | cut -c1-110)

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$name" "$w" "$h" "$n" "$mode" "$labels" "$legend" \
        "${pReq:-NA}" "${pAct:-NA}" "$verdict" \
        "$imgW" "$imgH" "$fL" "$fT" "$fR" "$fB" \
        "$iL" "$iR" "$iA" "$iB" "$eR" "$eB" "$iD" \
        "${bx:-NA}" "${by:-NA}" "${bw:-NA}" "${bh:-NA}" \
        "${cols:-NA}" "${rows:-NA}" "${shown:-NA}" "${hidden:-NA}" \
        "${mL:-NA}" "${mR:-NA}" "${mT:-NA}" "${mB:-NA}" \
        "${iLft:-NA}" "${iRgt:-NA}" "${iTop:-NA}" "${iBot:-NA}" \
        "${xMinE:-NA}" "${xMaxE:-NA}" "${yMinE:-NA}" "${yMaxE:-NA}" \
        "${lgW:-NA}" "${lgH:-NA}" "$note" >> "$OUT/RESULTS.tsv"
}

for size in 6x4 5x5 10x3; do
    w=${size%x*}
    h=${size#*x}

    # --- Block 1: the legend matrix, placement undeclared.
    for mode in color bw; do
        for variant in g0 g1 g3 g12 g24 wide none; do
            labels=normal
            legend=1
            case "$variant" in
                g0)   n=0 ;;
                g1)   n=1 ;;
                g3)   n=3 ;;
                g12)  n=12 ;;
                g24)  n=24 ;;
                wide) n=3;  labels=wide ;;
                # Identical to g24 in every input but the draw call, so the
                # control differs from the treatment in one thing only.
                none) n=24; legend=0 ;;
            esac
            render "${size}_${mode}_${variant}" "$w" "$h" "$n" "$mode" \
                   "$labels" "$legend" "-"
        done
    done

    # --- Block 2: the five placements, twelve entries, colour.
    for p in 1 2 3 4 5; do
        render "${size}_p${p}" "$w" "$h" 12 color normal 1 "$p"
    done
done

awk -F"\t" '{printf "%-18s %-16s p=%s/%s img=%sx%s frame=%s,%s..%s,%s inkR=%-6s box=%sx%s\n",
             $1, $10, $8, $9, $11, $12, $13, $14, $15, $16, $18, $26, $27}' \
    "$OUT/RESULTS.tsv"
