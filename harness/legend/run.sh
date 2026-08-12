#!/bin/bash
# ---------------------------------------------------------------------------
# LEGEND DRIVER. Renders the legend cases and measures every figure ON THE
# PIXELS OF THE SAVED PNG.
#
# Usage:  harness/legend/run.sh [case-name-substring]
# Output: <out>/<case>.png            the figure
#         <out>/<case>.log            the Praat transcript
#         <out>/RESULTS.tsv           one row per case, 72 fields:
#             case vpW vpH n mode labels legend pReq pAct verdict
#             imgW imgH frameL frameT frameR frameB
#             inkLeft inkRight inkAbove inkBelow edgeR edgeB inkDark
#             boxX boxY boxW boxH cols rows shown hidden
#             mL mR mT mB innerL innerR innerT innerB
#             extMinX extMaxX extMinY extMaxY layoutW layoutH note
#             mxK mxTch mxSupp mxGap mxPanelH mxTotal
#             panelBot mxTop mxBot mxInk lgInk strayInk belowInk
#             inkTop inkBot
#             graph k room roomApp corner axMin axMax ctl
#             dataPx coverPx diffPx
#
#   The first 61 are what they have always been, in the order they have
#   always been in, so a check written against a column index still reads the
#   same number. The eleven that follow are the multi-series block and are
#   "-" / -1 / NA on every case that is not one.
#
#   <out> is $EML_LEGEND_DIR, default harness/legend/out — IN-REPO, for the
#   reason harness/stress_graphs.sh gives: validate/v32_legend_geometry.R
#   HARD STOPS on a missing artefact rather than skipping, so a fresh clone
#   has to be able to produce it, and an out-of-tree default would make the
#   validator unrunnable on a machine that has never driven this. The
#   override exists so a second agent rendering into the tree at the same
#   time can be given a private directory.
#
# $EML_PLUGIN_ROOT — WHICH PLUGIN IS UNDER TEST. Default: the plugin of the
# tree these case files live in, reached by the relative includes in
# harness/legend/_prelude.praat. Set it to render this fixture against a
# DIFFERENT tree — a shadow build, a stashed branch, an installed copy — and
# the driver stages the case files into <out>/_stage beside a generated
# prelude whose includes are absolute into that root. Nothing outside
# harness/legend/ is involved either way.
#
#   Before this existed the cases included harness/stress_cases/_prelude.praat,
#   which names the plugin by absolute path, so a copy of this repo rendered
#   anywhere else loaded $ROOT/plugin regardless of which
#   tree it was run from — SILENTLY, because the figures still came out.
#   harness/stress_cases/_prelude.praat is deliberately NOT changed: other
#   harnesses depend on its current form.
#
# Every case runs in its OWN praat process, for the reason
# harness/stress_graphs.sh states: a Praat script error aborts the script, so
# one driver running the whole matrix reports one failure and hides the rest
# behind it.
#
# ---------------------------------------------------------------------------
# THE TWO FIXTURES, AND WHICH ONE ANSWERS WHICH QUESTION.
#
#   case.praat        THE RULER. Two violins under a legend of 0 to 24
#                     entries, corner forced to "top-left", the comparison
#                     matrix, the five placements. Everything it measures is
#                     a RECTANGLE: the plot frame against the requested
#                     inches, the matrix band against the legend band, the
#                     saved extent against the panel. Holding the figure
#                     constant while the entry count sweeps is what makes
#                     those comparisons clean, and it is also why nothing it
#                     draws is a picture of a legend doing its job — the key
#                     names ten groups that are not in the figure, and a
#                     grouped violin has the category labels on its x-axis
#                     anyway.
#
#   series_case.praat THE DEMONSTRATION. A k-series line chart and a k-group
#                     scatter, drawn through @emlDrawTimeSeries and
#                     @emlDrawScatterPlot — the product's own graph-level
#                     procedures — where the legend is the ONLY way to tell
#                     one series from another, the number of entries IS the
#                     number of series, and the corner is the one
#                     @emlPlaceElements scored rather than one the fixture
#                     chose. Blocks 5 and 6.
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
#
# ---------------------------------------------------------------------------
# BLOCK 5 — DOES THE KEY SIT ON THE DATA. 72 figures, named sr_*.
#
# THE ASSERTION THIS BLOCK EXISTS FOR, and it was missing: at placement 1 the
# legend is drawn INSIDE the plot, so it can cover the very series it names.
# Nothing in this harness measured that, and nothing could have — the old
# fixture's twelve-entry key sat over two violins, so "the data it names" was
# not on the page.
#
# Each case is a PAIR of renders and one comparison:
#
#   sr_<graph>_<size>_k<k>_r<room>       TREATMENT, placement 1
#   sr_<graph>_<size>_k<k>_r<room>_ctl   CONTROL, placement 5, PINNED to the
#                                        axis the treatment reported
#
# Placement 5 is one line inside @emlDrawLegend (`.draw = 0`); the axis, the
# quadrant scan, the chosen corner and the drawn extent are all computed the
# same way, so the two files differ in legend ink and in nothing else. The
# control is pinned to the treatment's own axis because the headroom pass can
# widen it, and a pixel comparison across two different axes would be
# measuring the axis.
#
#   graph  line     @emlDrawTimeSeries, graph type 5 — the LINE CHART
#          scatter  @emlDrawScatterPlot, graph type 8, grouped
#   size   6x4, 5x5, 10x3, as everywhere else here
#   k      3, 5, 12 SERIES — and therefore 3, 5 and 12 legend entries. Five
#          is the count the plugin's own defect note is written about; twelve
#          is more entries than the panel can hold at 6 x 4, which is where
#          the headroom cap has to be honest about what it could not afford
#   room   0  drawn ONCE, which is what every caller that is not the graphs
#             form does — every companion script, every direct call into
#             eml-draw-procedures.praat. No headroom pass exists for them.
#          1  the form's two-pass path: draw, ask @emlLegendHeadroomAfterDraw
#             whether the legend needs y-axis room, and if so draw again on
#             the widened axis
#
# BOTH ARMS ARE RECORDED AS NUMBERS. coverPx is a column in RESULTS.tsv, not
# a pass/fail, so a future change to the headroom moves a visible figure
# rather than flipping a boolean. Measured 9 August 2026 on the 6 x 4
# five-group line chart: 1717 data pixels covered at room=0, 0 at room=1.
#
# BLOCK 7 — THE FOUR NON-CATEGORICAL TYPES. 20 figures, named sw_t*_p*.
#
# Six graph types offer the Legend placement menu. Blocks 2, 3 and 6 between
# them sweep three of them. This block is the other three plus the scatter as
# a bridge: 5 Line +/-CI, 8 Scatter, 10 Histogram, 13 Spaghetti, at all five
# placements, on one figure size. Fixture: placement_sweep_case.praat.
#
# It also carries the one thing no other fixture does — placement 4's SECOND
# FILE. The parked legend is written by selecting emlLegendSepX0..Y1 and
# saving again, which is the graphs form's own save-site handshake, and it is
# asserted in section 11 rather than argued from the source.
#
# BLOCK 6 — THE FIVE PLACEMENTS ON THE REAL PATH. 30 figures, named sp_*.
# Two graph types x three sizes x five placements, five series, no headroom
# pass. Block 2 makes this statement with the corner forced and the legend
# describing nothing; this makes it where the legend is real and the corner
# is chosen. p5 is ALSO the legend-free control for p1 and p4 — the axis is
# the same in all five when no headroom pass runs, and those two are the
# placements that leave the saved image the same size, so the pixel
# comparison is defined for them. Placements 2 and 3 deliberately grow the
# file, so there is no pixel-for-pixel control for them and coverPx is NA;
# what they must not do is take anything out of the PLOT, which is the frame
# check every placement gets.
#
# ---------------------------------------------------------------------------
#
# WHY THE MEASUREMENTS COME FROM THE PYTHON AND NOT FROM THE CASE. The case
# prints the box @emlDrawLegend says it drew, and that is recorded — but it
# is computed with the same arithmetic the procedure used, so if the drawing
# and the arithmetic disagree the two sides move together and nothing shows.
# The frame, the image, the ink and the coverage are therefore read off the
# rendered pixels; see the block comments at the head of measure.py,
# measure_bands.py and measure_cover.py.
#
# validate/v32_legend_geometry.R reads RESULTS.tsv and the logs.
# ---------------------------------------------------------------------------
set -u
# Resolved from this script's own location, never hardcoded. harness/_env.sh
# also supplies PRAAT and PRAAT_TRUST, and REFUSES a Praat below the plugin's
# 6.6.30 floor. See its header for why an absolute ROOT was a real defect and
# not a cosmetic one.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_env.sh" || exit 1
ROOT="$EML_ROOT"
SRC=$ROOT/harness/legend
MEASURE=$SRC/measure.py
BANDS=$SRC/measure_bands.py
COVER=$SRC/measure_cover.py
OUT=${EML_LEGEND_DIR:-$SRC/out}
# PRAAT and PRAAT_TRUST come from _env.sh.
# Scratch only, never read by a check. Its own directory rather than the
# shared harness one, so a concurrent run of another driver cannot collide
# with this one over Praat's preferences file.
PREFS=${EML_LEGEND_PREFS:-$ROOT/harness/legend/prefs}
FILTER="${1:-}"

mkdir -p "$OUT" "$PREFS"

# --- WHICH PLUGIN. Default: the one the case files' relative includes reach,
# i.e. this tree's. With EML_PLUGIN_ROOT set, the cases are staged beside a
# GENERATED prelude that names that root absolutely.
#
# Staging rather than editing in place, because Praat resolves an `include`
# inside an included file against the folder of the script that was RUN — so
# the prelude only has to sit next to the case, and a staged copy is a
# complete, self-contained fixture pointed at another plugin.
CASEDIR=$SRC
if [ -n "${EML_PLUGIN_ROOT:-}" ]; then
    CASEDIR=$OUT/_stage
    rm -rf "$CASEDIR"
    mkdir -p "$CASEDIR"
    cp "$SRC"/*.praat "$CASEDIR"/
    {
        echo "# GENERATED by harness/legend/run.sh from EML_PLUGIN_ROOT."
        echo "# Do not edit; edit harness/legend/_prelude.praat instead."
        for f in graphs/eml-graph-procedures.praat \
                 stats/eml-core-utilities.praat \
                 stats/eml-core-descriptive.praat \
                 stats/eml-extract.praat \
                 stats/eml-output.praat \
                 stats/eml-inferential.praat \
                 graphs/eml-annotation-procedures.praat \
                 graphs/eml-draw-procedures.praat; do
            echo "include $EML_PLUGIN_ROOT/$f"
        done
        # Everything from @emlInitDrawingDefaults on is path-free.
        sed -n '/^@emlInitDrawingDefaults/,$p' "$SRC/_prelude.praat"
    } > "$CASEDIR/_prelude.praat"
    # series_case.praat reaches for the form on its own; retarget that too.
    sed -i "s|^include \.\./\.\./plugin/graphs/eml-graphs-form\.praat\$|include $EML_PLUGIN_ROOT/graphs/eml-graphs-form.praat|" \
        "$CASEDIR/series_case.praat"
    echo "run.sh: staged against EML_PLUGIN_ROOT=$EML_PLUGIN_ROOT" >&2
fi
CASE=$CASEDIR/case.praat
SERIES=$CASEDIR/series_case.praat
SWEEP=$CASEDIR/placement_sweep_case.praat

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

# want NAME — does this case pass the command-line filter?
want () {
    [ -z "$FILTER" ] && return 0
    case "$1" in *"$FILTER"*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# emit_row NAME W H N MODE LABELS LEGEND CTL DATAPX COVERPX DIFFPX
#
# Measures the PNG this case just wrote and appends its row. Everything but
# the eleven arguments is read back out of the transcript or off the pixels,
# so one emitter serves both fixtures and there is exactly one printf in this
# file — a second one is how a column count drifts.
#
# CTL / DATAPX / COVERPX / DIFFPX are the caller's, because the coverage
# comparison needs a SECOND render and only the caller knows which one.
# ---------------------------------------------------------------------------
emit_row () {
    local name=$1 w=$2 h=$3 n=$4 mode=$5 labels=$6 legend=$7
    local ctl=$8 dataPx=$9 coverPx=${10} diffPx=${11}
    local log="$OUT/$name.log"

    local verdict
    if [ -s "$OUT/$name.png" ]; then
        if grep -qiE "^Error|not completed|Unknown variable" "$log"; then
            verdict=DREW_THEN_FAILED
        else
            verdict=OK
        fi
    else
        verdict=NO_FIGURE
    fi

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
                   2>>"$log"); then
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
                   "$mxBot" "$lgT" "$lgB" 2>>"$log"); then
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
    # it could only truncate itself. It is field 46 of 72 now, so a tab in it
    # would shift every band and coverage measurement one column right.
    note=$(grep -iE "^Error|Unknown|not completed|^NOTE:" "$log" \
           | head -1 | cut -c1-110 | tr '\t' ' ')
    local mxK mxTch mxSupp mxGap mxPanelH mxTotal
    mxK=$(field MATRIX k "$log");        mxTch=$(field MATRIX tch "$log")
    mxSupp=$(field MATRIX suppressed "$log")
    mxGap=$(field MATRIX gap "$log");    mxPanelH=$(field MATRIX panelH "$log")
    mxTotal=$(field MATRIX total "$log")

    # The multi-series fields. Absent from a case.praat transcript, which is
    # what makes their defaults the legacy row: graph "-", k/room/roomApp -1,
    # corner "-", axis NA.
    local graph k room roomApp corner axMin axMax
    graph=$(field SRCASE graph "$log");  k=$(field SRCASE k "$log")
    room=$(field ROOM used "$log");      roomApp=$(field ROOM applied "$log")
    corner=$(field CORNER corner "$log")
    axMin=$(field AXIS yMin "$log");     axMax=$(field AXIS yMax "$log")

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
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
        "${graph:--}" "${k:--1}" "${room:--1}" "${roomApp:--1}" \
        "${corner:--}" "${axMin:-NA}" "${axMax:-NA}" \
        "$ctl" "$dataPx" "$coverPx" "$diffPx" \
        >> "$OUT/RESULTS.tsv"
}

# render NAME W H N MODE LABELS LEGEND PLACEMENT [MATRIX] [TCH]
#   The geometry rig, case.praat. PLACEMENT of "-" leaves emlLegendPlacement
#   undeclared, which is what every caller written before the placements
#   supplies. MATRIX defaults to 0 (no comparison matrix) and TCH to 1
#   (declare totalCanvasHeight, as the graphs form does), so every call
#   written before block 3 existed renders exactly what it rendered before.
render () {
    local name=$1 w=$2 h=$3 n=$4 mode=$5 labels=$6 legend=$7 placement=$8
    local matrix=${9:-0} tch=${10:-1}
    want "$name" || return 0

    rm -f "$OUT/$name.png"
    local pEnv=""
    [ "$placement" != "-" ] && pEnv="$placement"
    # DISPLAY deliberately unset: proves the case needs no X server, and stops
    # a stray connection to an interactive instance.
    env -u DISPLAY EML_OUT="$OUT/$name.png" EML_CASE="$name" \
        EML_VPW="$w" EML_VPH="$h" EML_N="$n" EML_MODE="$mode" \
        EML_LABELS="$labels" EML_LEGEND="$legend" EML_PLACEMENT="$pEnv" \
        EML_MATRIX="$matrix" EML_TCH="$tch" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$CASE" \
        > "$OUT/$name.log" 2>&1

    emit_row "$name" "$w" "$h" "$n" "$mode" "$labels" "$legend" \
             "-" NA NA NA
}

# series_run NAME GRAPH W H K MODE PLACEMENT ROOM YMIN YMAX
#   One render of series_case.praat. YMIN/YMAX of 0/0 lets the figure choose
#   its own axis; anything else pins it, which is how a control is put on the
#   treatment's axis.
series_run () {
    local name=$1 graph=$2 w=$3 h=$4 k=$5 mode=$6 placement=$7 room=$8
    local ymin=$9 ymax=${10}
    rm -f "$OUT/$name.png"
    env -u DISPLAY EML_OUT="$OUT/$name.png" EML_CASE="$name" \
        EML_VPW="$w" EML_VPH="$h" EML_K="$k" EML_GRAPH="$graph" \
        EML_MODE="$mode" EML_PLACEMENT="$placement" EML_ROOM="$room" \
        EML_YMIN="$ymin" EML_YMAX="$ymax" \
        "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$SERIES" \
        > "$OUT/$name.log" 2>&1
}

# cover CONTROL TREATMENT — the coverage triple, or "NA NA NA" if the frame
# could not be measured or the two files are not the same shape. The frame is
# taken off the CONTROL, because the control is the figure whose data ink is
# being counted.
cover () {
    local ctl=$1 trt=$2 m
    if ! m=$(python3 "$MEASURE" "$OUT/$ctl.png" 2>/dev/null); then
        echo "NA NA NA"; return 0
    fi
    set -- $m
    local fL=$3 fT=$4 fR=$5 fB=$6 c
    if ! c=$(python3 "$COVER" "$OUT/$ctl.png" "$OUT/$trt.png" \
                 "$fL" "$fT" "$fR" "$fB" 2>/dev/null); then
        echo "NA NA NA"; return 0
    fi
    echo $c
}

# render_series NAME GRAPH W H K MODE ROOM
#   A treatment at placement 1 and its own legend-free control at placement 5,
#   pinned to the axis the treatment reported, and the coverage between them.
render_series () {
    local name=$1 graph=$2 w=$3 h=$4 k=$5 mode=$6 room=$7
    local ctl="${name}_ctl"
    want "$name" || return 0

    series_run "$name" "$graph" "$w" "$h" "$k" "$mode" 1 "$room" 0 0
    # The axis the TREATMENT drew on, read back out of its own transcript.
    # Ten decimal places: the control takes the `else` branch of the draw
    # procedure's `if .vMin = 0 and .vMax = 0`, so what is passed here IS the
    # axis, and a rounding at the tenth place is four ten-millionths of a
    # pixel.
    local ay ax
    ay=$(field AXIS yMin "$OUT/$name.log")
    ax=$(field AXIS yMax "$OUT/$name.log")
    : "${ay:=0}" "${ax:=0}"
    series_run "$ctl" "$graph" "$w" "$h" "$k" "$mode" 5 0 "$ay" "$ax"

    local cv
    cv=$(cover "$ctl" "$name")
    set -- $cv
    emit_row "$name" "$w" "$h" "$k" "$mode" series 1 "$ctl" "$1" "$2" "$3"
    emit_row "$ctl"  "$w" "$h" "$k" "$mode" series 0 "-" NA NA NA
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

# --- Block 5: the legend over the series it names. Colour only — the
# coverage rule identifies data ink by CHROMA, and in greyscale mode the data
# is achromatic, so a bw case would report dataPx = 0 rather than a small
# wrong number. The greyscale ink rules are measured on their own terms by
# block 1's bw variants.
for graph in line scatter; do
    for size in 6x4 5x5 10x3; do
        w=${size%x*}
        h=${size#*x}
        for k in 3 5 12; do
            for room in 0 1; do
                render_series "sr_${graph}_${size}_k${k}_r${room}" \
                              "$graph" "$w" "$h" "$k" color "$room"
            done
        done
    done
done

# --- Block 6: the five placements, on the real path, with a real legend and
# a chosen corner. p5 doubles as the legend-free control for p1 and p4: with
# no headroom pass the axis is the same in all five, and those are the two
# placements that leave the saved image the same size, so a pixel-for-pixel
# comparison is defined for them and not for 2 and 3.
for graph in line scatter; do
    for size in 6x4 5x5 10x3; do
        w=${size%x*}
        h=${size#*x}
        base="sp_${graph}_${size}"
        for p in 5 1 2 3 4; do
            name="${base}_p${p}"
            want "$name" || continue
            series_run "$name" "$graph" "$w" "$h" 5 color "$p" 0 0 0
        done
        for p in 5 1 2 3 4; do
            name="${base}_p${p}"
            want "$name" || continue
            cv="NA NA NA"
            case "$p" in
                1|4) if want "${base}_p5"; then cv=$(cover "${base}_p5" "$name"); fi ;;
            esac
            set -- $cv
            ctlName=-
            case "$p" in 1|4) ctlName="${base}_p5" ;; esac
            emit_row "$name" "$w" "$h" 5 color series \
                     "$([ "$p" = 5 ] && echo 0 || echo 1)" \
                     "$ctlName" "$1" "$2" "$3"
        done
    done
done

# --- Block 7: the four NON-CATEGORICAL types, all five placements. 20
# figures, named sw_t<type>_p<placement>.
#
# Blocks 2, 3 and 6 sweep the placements too, but between them they exercise
# exactly three of the six types that offer the menu: the grouped violin the
# geometry rig draws, and the line chart and grouped scatter the series
# fixture draws. Types 5 (Line +/-CI), 10 (Histogram) and 13 (Spaghetti) had
# never been swept by anything an R script reads — they were measured by hand
# on 9 August 2026 and the numbers went into the audit tracker, which is not
# a check. Section 11 of validate/v32_legend_geometry.R is.
#
# ONE SIZE, not three. What varies here is the GRAPH TYPE, and the three-size
# sweep is already carried by blocks 2, 3 and 6 on the types they draw; adding
# it here would triple the render time to restate a claim those blocks already
# make. 6 x 4.5 rather than 6 x 4 so this block does not sit on the same
# figure as everything else, which is how a size-specific accident hides.
for t in 5 8 10 13; do
    for p in 1 2 3 4 5; do
        name="sw_t${t}_p${p}"
        want "$name" || continue
        rm -f "$OUT/$name.png" "$OUT/${name}_legend.png"
        env -u DISPLAY EML_OUT="$OUT/$name.png" EML_CASE="$name" \
            EML_GTYPE="$t" EML_PLACEMENT="$p" \
            EML_VPW=6 EML_VPH=4.5 EML_MODE=color \
            "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run "$SWEEP" \
            > "$OUT/$name.log" 2>&1
        emit_row "$name" 6 4.5 4 color sweep 1 "-" NA NA NA
    done
done

awk -F"\t" '{printf "%-26s %-16s p=%s/%s img=%sx%s frame=%s,%s..%s,%s box=%sx%s corner=%-13s cover=%s/%s\n",
             $1, $10, $8, $9, $11, $12, $13, $14, $15, $16, $26, $27,
             $66, $71, $70}' \
    "$OUT/RESULTS.tsv"
