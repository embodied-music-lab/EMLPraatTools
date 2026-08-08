#!/bin/bash
# ---------------------------------------------------------------------------
# LEGEND GEOMETRY DRIVER. Renders the legend matrix and measures every figure
# ON THE PIXELS OF THE SAVED PNG.
#
# Usage:  harness/legend/run.sh [case-name-substring]
# Output: <out>/<case>.png            the figure
#         <out>/<case>.log            the Praat transcript
#         <out>/RESULTS.tsv           one row per case, 61 fields:
#             case vpW vpH n mode labels legend pReq pAct verdict
#             imgW imgH frameL frameT frameR frameB
#             inkLeft inkRight inkAbove inkBelow edgeR edgeB inkDark
#             boxX boxY boxW boxH cols rows shown hidden
#             mL mR mT mB innerL innerR innerT innerB
#             extMinX extMaxX extMinY extMaxY layoutW layoutH note
#             mxK mxTch mxSupp mxGap mxPanelH mxTotal
#             panelBot mxTop mxBot mxInk lgInk strayInk belowInk
#             inkTop inkBot
#
#   The first 46 are what they have always been, in the order they have
#   always been in, so a check written against a column index still reads the
#   same number. The fifteen that follow are the comparison-matrix band and
#   are NA / 0 / -1 on every case that carries no matrix.
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
#
# ---------------------------------------------------------------------------
# BLOCK 3 — THE COMPARISON MATRIX AND THE LEGEND, ON THE SAME PAGE. 36
# figures: three sizes x twelve and twenty-four legend entries x the five
# placements, plus a legend-free CONTROL at each size and count.
#
# A post-hoc comparison matrix is a second panel drawn BELOW the plot, and
# placement 3 puts the legend below the plot as well. Reading the code they
# do not collide — @emlDrawLegend starts its band below the page bottom, and
# the form has already pushed that down past the matrix. Nothing in the tree
# rendered the two together, so that was an argument. This is the rendering.
#
# The matrix is four groups, from a real one-way ANOVA with Tukey HSD, at
# every size and every placement. Twelve and twenty-four legend entries
# because the question is whether the legend BAND, which is tall at those
# counts, clears a panel that is itself two to three inches deep.
#
# THE CONTROL IS THE MEASUREMENT. `_ctl` is the same figure with the matrix
# and without the legend call, so the ink inside the matrix band in a control
# is the matrix's own ink and nothing else. Any placement whose figure counts
# a different number in that band has put legend ink on the matrix. That
# comparison is the whole of the disjointness check, and it is made on the
# pixels of the two PNGs.
#
# ---------------------------------------------------------------------------
# BLOCK 4 — THE RED PATHS, ten figures, named rp_*.
#
#   rp_notch_*   THE MATRIX IS THERE AND totalCanvasHeight IS NOT. The graphs
#                form computes that global before it dispatches the draw, so
#                inside the form it is always present — but it is a FORM
#                local, and @emlInitDrawingDefaults, the documented entry
#                point for "standalone scripts or PraatGen companion files",
#                sets emlLegendPlacement and does not set it. Placements 3,
#                2 and 4 are all driven that way, because only 3 and 4 read
#                the page bottom and 2 is the control for that claim.
#   rp_tall_*    A MATRIX AS DEEP AS THE FIGURE. Twelve groups on a 6 x 4:
#                the panel is 3.96 inches under a 4 inch plot, so the legend
#                band starts past 8 inches on a figure the user asked for 4
#                of. Placements 3 and 2, and 3 again with the global unset.
#   rp_supp_*    A MATRIX THAT WAS MEASURED AND SUPPRESSED. Sixteen groups on
#                a 2 x 2 figure: @emlMeasureMatrixLayout gives up, no panel
#                is drawn at all, and the legend band must NOT reserve space
#                for a panel that does not exist.
#
# Each group has one legend-free control, shared by its treatments, for the
# same reason block 3's controls exist.
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
BANDS=$ROOT/harness/legend/measure_bands.py
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

# render NAME W H N MODE LABELS LEGEND PLACEMENT [MATRIX] [TCH]
#   PLACEMENT of "-" leaves emlLegendPlacement undeclared, which is what every
#   caller written before the placements supplies.
#   MATRIX defaults to 0 (no comparison matrix) and TCH to 1 (declare
#   totalCanvasHeight, as the graphs form does), so every call written before
#   block 3 existed renders exactly what it rendered before.
render () {
    local name=$1 w=$2 h=$3 n=$4 mode=$5 labels=$6 legend=$7 placement=$8
    local matrix=${9:-0} tch=${10:-1}
    [ -n "$FILTER" ] && case "$name" in *"$FILTER"*) ;; *) return 0 ;; esac

    rm -f "$OUT/$name.png"
    local pEnv=""
    [ "$placement" != "-" ] && pEnv="$placement"
    # DISPLAY deliberately unset: proves the case needs no X server, and stops
    # a stray connection to an interactive instance.
    env -u DISPLAY EML_OUT="$OUT/$name.png" EML_CASE="$name" \
        EML_VPW="$w" EML_VPH="$h" EML_N="$n" EML_MODE="$mode" \
        EML_LABELS="$labels" EML_LEGEND="$legend" EML_PLACEMENT="$pEnv" \
        EML_MATRIX="$matrix" EML_TCH="$tch" \
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

    local log="$OUT/$name.log"

    # The three horizontal boundaries the case reports, in pixels of the PNG
    # it just wrote. panelBot is where the plot panel ends: it bounds the
    # frame SEARCH (a figure carrying a matrix band is taller than the plot,
    # and "half the image" stops describing the frame's edges), and it is
    # where the band counting starts.
    local panelBot mxTop mxBot
    panelBot=$(field BANDS panelBot "$log")
    mxTop=$(field BANDS mxTop "$log")
    mxBot=$(field BANDS mxBot "$log")
    : "${panelBot:=}" "${mxTop:=-1}" "${mxBot:=-1}"

    local imgW=NA imgH=NA fL=NA fT=NA fR=NA fB=NA
    local iL=NA iR=NA iA=NA iB=NA eR=NA eB=NA iD=NA m
    local mxInk=NA lgInk=NA stray=NA belowInk=NA inkTop=NA inkBot=NA b
    if [ "$verdict" = OK ]; then
        if m=$(python3 "$MEASURE" "$OUT/$name.png" $panelBot \
                   2>>"$OUT/$name.log"); then
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
    if [ "$verdict" = OK ] && [ -n "$panelBot" ]; then
        # The legend band is the box @emlDrawLegend REPORTED, in the same
        # pixel convention. measure_bands.py clamps it to the region below
        # the plot panel, so placements 1 and 5 report no legend ink here
        # rather than counting the plot's own.
        local lbT=$(field LEGENDBOX y "$log") lbH=$(field LEGENDBOX h "$log")
        local lgT=-1 lgB=-1
        if [ -n "$lbT" ] && [ "$lbT" != "-1" ]; then
            lgT=$lbT; lgB=$((lbT + lbH))
        fi
        if b=$(python3 "$BANDS" "$OUT/$name.png" "$panelBot" "$mxTop" \
                   "$mxBot" "$lgT" "$lgB" 2>>"$OUT/$name.log"); then
            set -- $b
            mxInk=$1; lgInk=$2; stray=$3; belowInk=$4; inkTop=$5; inkBot=$6
        else
            verdict=BANDS_FAILED
        fi
    fi

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
    # Tabs stripped: `note` used to be the last field on the line and a tab in
    # it could only truncate itself. It is field 46 of 61 now, so a tab in it
    # would shift every band measurement one column right.
    note=$(grep -iE "^Error|Unknown|not completed|^NOTE:" "$log" \
           | head -1 | cut -c1-110 | tr '\t' ' ')
    local mxK mxTch mxSupp mxGap mxPanelH mxTotal
    mxK=$(field MATRIX k "$log");        mxTch=$(field MATRIX tch "$log")
    mxSupp=$(field MATRIX suppressed "$log")
    mxGap=$(field MATRIX gap "$log");    mxPanelH=$(field MATRIX panelH "$log")
    mxTotal=$(field MATRIX total "$log")

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$name" "$w" "$h" "$n" "$mode" "$labels" "$legend" \
        "${pReq:-NA}" "${pAct:-NA}" "$verdict" \
        "$imgW" "$imgH" "$fL" "$fT" "$fR" "$fB" \
        "$iL" "$iR" "$iA" "$iB" "$eR" "$eB" "$iD" \
        "${bx:-NA}" "${by:-NA}" "${bw:-NA}" "${bh:-NA}" \
        "${cols:-NA}" "${rows:-NA}" "${shown:-NA}" "${hidden:-NA}" \
        "${mL:-NA}" "${mR:-NA}" "${mT:-NA}" "${mB:-NA}" \
        "${iLft:-NA}" "${iRgt:-NA}" "${iTop:-NA}" "${iBot:-NA}" \
        "${xMinE:-NA}" "${xMaxE:-NA}" "${yMinE:-NA}" "${yMaxE:-NA}" \
        "${lgW:-NA}" "${lgH:-NA}" "$note" \
        "${mxK:-NA}" "${mxTch:-NA}" "${mxSupp:-NA}" \
        "${mxGap:-NA}" "${mxPanelH:-NA}" "${mxTotal:-NA}" \
        "${panelBot:-NA}" "${mxTop:-NA}" "${mxBot:-NA}" \
        "$mxInk" "$lgInk" "$stray" "$belowInk" "$inkTop" "$inkBot" \
        >> "$OUT/RESULTS.tsv"
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

    # --- Block 3: the same five placements with a four-group comparison
    # matrix under the plot, at twelve and at twenty-four entries, plus the
    # legend-free control that says what the matrix band holds on its own.
    for n in 12 24; do
        for p in 1 2 3 4 5; do
            render "${size}_n${n}_mx_p${p}" "$w" "$h" "$n" color normal 1 \
                   "$p" 4 1
        done
        render "${size}_n${n}_mx_ctl" "$w" "$h" "$n" color normal 0 "-" 4 1
    done
done

# --- Block 4: the red paths. All on the default figure except the suppressed
# matrix, which needs a figure too small to hold one.
#
#   _notch   totalCanvasHeight NOT declared: the caller is not the form
#   _tall    twelve groups, a matrix panel as deep as the plot above it
#   _supp    sixteen groups on 2 x 2, measured and suppressed
render rp_notch_p3     6 4 12 color normal 1 3  4  0
render rp_notch_p2     6 4 12 color normal 1 2  4  0
render rp_notch_p4     6 4 12 color normal 1 4  4  0
render rp_notch_ctl    6 4 12 color normal 0 -  4  0
render rp_tall_p3      6 4 24 color normal 1 3  12 1
render rp_tall_p2      6 4 24 color normal 1 2  12 1
render rp_tallnotch_p3 6 4 24 color normal 1 3  12 0
render rp_tall_ctl     6 4 24 color normal 0 -  12 1
render rp_supp_p3      2 2 12 color normal 1 3  16 1
render rp_supp_ctl     2 2 12 color normal 0 -  16 1

awk -F"\t" '{printf "%-20s %-16s p=%s/%s img=%sx%s frame=%s,%s..%s,%s inkR=%-6s box=%sx%s mx=%s/%s ink=%s/%s/%s\n",
             $1, $10, $8, $9, $11, $12, $13, $14, $15, $16, $18, $26, $27,
             $47, $48, $56, $57, $58}' \
    "$OUT/RESULTS.tsv"
