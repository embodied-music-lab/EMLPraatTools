#!/usr/bin/env bash
# ============================================================================
# harness/penassert/run.sh — the two pen sizes the theme now asserts
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE QUESTION. A figure is drawn in a session whose Picture-window pen has
# been left at some other size. Colour, line width and font size cannot reach
# the figure — @emlSetAdaptiveTheme and the drawing sites re-assert all three,
# and harness/roundtrip measured a whole recorded figure surviving a hostile
# session at zero differing pixels. Arrow size and speckle size are the two
# pen settings with no drawing site of their own. This rig measures them.
#
# FOUR PAIRS, EACH PAIR ONE NUMBER.
#
#   ctl_arrow    bare Praat, one arrow, size 1.0 against size 5.0
#   ctl_speck    bare Praat, an Ltas "Speckles" draw, 1.0 against 12.0
#                — the two controls. They say the channel carries ink, so a
#                  zero further down is immunity and not a dead measurement.
#                Each is joined by a "_default" pair, pen untouched against
#                pen set to 1.0, which is where 1.0 comes from; and by
#                ctl_paint_circle, which asks whether `Paint circle` — the
#                mark @emlDrawLTAS uses for its own speckles — reads the
#                setting at all.
#
#   witness      the plugin's theme, then an arrow and a native Ltas
#                "Speckles" draw at whatever pen the theme left. Clean
#                session against hostile session. THIS is the measurement of
#                the assert itself: it puts a mark that READS the two
#                settings directly downstream of @emlSetAdaptiveTheme.
#
#   fig          @emlDrawLTAS with curve, poles and speckles on. Clean
#                session against hostile session. The figure a user gets.
#
# AND EVERY PAIR IS RUN TWICE: once against the shipped tree, once against a
# shadow copy of it with the theme's two assert lines cut out. The shadow arm
# is what makes the shipped arm's zero mean something — without it, a figure
# that never rode the channel and a figure protected from it report the same
# number.
#
# THE HOSTILE LEG PERTURBS THESE TWO SETTINGS AND NOTHING ELSE. Font, colour,
# line width and the page were carried by harness/roundtrip; mixing them in
# here would leave a difference unattributable to a channel.
#
# ONE PRAAT PROCESS PER LEG, and A FRESH PREFERENCE DIRECTORY PER LEG. Praat
# saves the Picture pen into its preferences, so a hostile leg sharing a pref
# dir with the next leg hands its own perturbation on — which is exactly how
# a real user acquires an ambient setting, and exactly what would make this
# rig measure itself.
#
# NO DISPLAY IS BOUND. DISPLAY is unset for every leg rather than ignored.
#
# Run from anywhere:  bash harness/penassert/run.sh
# Output: harness/penassert/out/PENASSERT.tsv   every number below
#         harness/penassert/out/png/*.png       the figures compared
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPT_DIR/.." && pwd)/_env.sh" || exit 1

OUT="$SCRIPT_DIR/out"
PNG="$OUT/png"
GEN="$OUT/gen"
SHADOW="$OUT/shadow"
TSV="$OUT/PENASSERT.tsv"

rm -rf "$OUT"
mkdir -p "$PNG" "$GEN" "$SHADOW"
: > "$TSV"

kv () { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

kv praat_version "$("$PRAAT" --version 2>&1 | head -1)"
kv shipped_plugin "$EML_ROOT/plugin"

# ---------------------------------------------------------------------------
# THE SHADOW TREE — the shipped plugin with the two assert lines cut
# ---------------------------------------------------------------------------
# Cut by exact text, and the count is checked. A sed that matched nothing
# would build a shadow identical to the shipped tree, and the arm would then
# report "the assert makes no difference" about a file that still has it.
cp -a "$EML_ROOT/plugin_EML_StatsGraphs" "$SHADOW/plugin"
THEME="$SHADOW/plugin/graphs/eml-graph-procedures.praat"
before="$(grep -c -E '^    (Arrow|Speckle) size: \.(arrow|speckle)Size$' "$THEME")"
sed -i -E '/^    (Arrow|Speckle) size: \.(arrow|speckle)Size$/d' "$THEME"
after="$(grep -c -E '^    (Arrow|Speckle) size: \.(arrow|speckle)Size$' "$THEME")"
kv shadow_assert_lines_before "$before"
kv shadow_assert_lines_after  "$after"
if [[ "$before" != "2" || "$after" != "0" ]]; then
    echo "penassert: shadow tree not built as intended ($before -> $after)" >&2
    kv shadow_build FAILED
    exit 1
fi
kv shadow_build ok

# ---------------------------------------------------------------------------
# THE DRIVES
# ---------------------------------------------------------------------------
# The control drive includes nothing: its subject is Praat's own pen, and a
# control that loaded the plugin would be measuring the plugin.
#
# The plugin drive is generated once per tree, because `include` takes a
# literal path and the two trees are at different paths.
cat > "$GEN/control.praat" <<'PRAAT'
# Praat's own pen, with no plugin loaded.
leg$ = environment$ ("EML_PA_LEG")
png$ = environment$ ("EML_PA_PNG")

Create Sound from formula: "tone", 1, 0, 1, 44100,
... "0.6*sin(2*pi*220*x) + 0.3*sin(2*pi*640*x)
...  + 0.15*sin(2*pi*1310*x) + 0.08*sin(2*pi*2570*x)"
ltas = To Ltas: 100

Erase all
# THE "_def" LEGS TOUCH THE PEN AT ALL. They are how 1.0 is established as
# Praat 6.6.30's own value for both settings rather than recalled from a
# manual: each is compared against its "_lo" partner, which asks for 1.0.
if leg$ = "ctl_arrow_def"
    ; pen untouched
elsif leg$ = "ctl_arrow_lo"
    Arrow size: 1.0
elsif leg$ = "ctl_arrow_hi"
    Arrow size: 5.0
elsif leg$ = "ctl_speck_def"
    ; pen untouched
elsif leg$ = "ctl_speck_lo"
    Speckle size: 1.0
elsif leg$ = "ctl_speck_hi"
    Speckle size: 12.0
elsif leg$ = "ctl_paint_lo"
    Speckle size: 1.0
elsif leg$ = "ctl_paint_hi"
    Speckle size: 12.0
else
    exitScript: "penassert: unknown control leg " + leg$
endif

if left$ (leg$, 9) = "ctl_arrow"
    Select outer viewport: 0, 4, 0, 3
    Axes: 0, 10, 0, 10
    Draw arrow: 1, 1, 9, 9
elsif left$ (leg$, 9) = "ctl_paint"
    # WHICH MARKS READ "SPECKLE SIZE" AND WHICH DO NOT. `Paint circle` takes
    # its radius in world coordinates and is the mark @emlDrawLTAS lays down
    # for its own speckle layer. Measuring it beside the native "Speckles"
    # draw above is what tells the fig pair below apart from the witness
    # pair: a zero on a mark that cannot read the setting is not immunity.
    selectObject: ltas
    Select outer viewport: 0, 4, 0, 3
    Axes: 0, 5000, -20, 80
    Paint circle: "Black", 2500, 30, 30
else
    selectObject: ltas
    Select outer viewport: 0, 4, 0, 3
    Draw: 0, 5000, -20, 80, "no", "Speckles"
endif
Save as 300-dpi PNG file: png$
writeInfoLine: "leg ", leg$, " ok"
PRAAT

gen_plugin_drive () {   # gen_plugin_drive <plugin-root> <outfile>
    local plug="$1" dst="$2"
    cat > "$dst" <<PRAATINC
include $plug/stats/eml-core-utilities.praat
include $plug/stats/eml-core-descriptive.praat
include $plug/stats/eml-extract.praat
include $plug/stats/eml-output.praat
include $plug/stats/eml-inferential.praat
include $plug/stats/eml-result-writer.praat
include $plug/stats/eml-record.praat
include $plug/graphs/eml-graph-procedures.praat
include $plug/graphs/eml-annotation-procedures.praat
include $plug/graphs/eml-draw-procedures.praat
include $plug/stats/eml-analysis.praat
PRAATINC
    cat >> "$dst" <<'PRAAT'

leg$ = environment$ ("EML_PA_LEG")
png$ = environment$ ("EML_PA_PNG")

# DETERMINISTIC SOURCE. A pixel comparison across processes cannot be built
# on randomGauss; four sinusoids give the Ltas real structure and the same
# structure every run.
Create Sound from formula: "tone", 1, 0, 1, 44100,
... "0.6*sin(2*pi*220*x) + 0.3*sin(2*pi*640*x)
...  + 0.15*sin(2*pi*1310*x) + 0.08*sin(2*pi*2570*x)"
ltas = To Ltas: 100

@emlInitDrawingDefaults

# THE HOSTILE SESSION. Two settings, nothing else.
if right$ (leg$, 8) = "_hostile"
    Arrow size: 7.5
    Speckle size: 9.0
endif

Erase all
if left$ (leg$, 7) = "witness"
    # A MARK THAT READS THE TWO SETTINGS, PLACED DIRECTLY DOWNSTREAM OF THE
    # THEME. The plugin draws no arrow and no native speckle of its own, so
    # without this leg the assert would be measured only by figures that
    # cannot show it either way.
    @emlSetAdaptiveTheme: 6, 4
    Select outer viewport: 0, 3, 0, 3
    Axes: 0, 10, 0, 10
    Draw arrow: 1, 1, 9, 9
    selectObject: ltas
    Select outer viewport: 3, 6, 0, 3
    Draw: 0, 5000, -20, 80, "no", "Speckles"
    Save as 300-dpi PNG file: png$
elsif left$ (leg$, 3) = "fig"
    # THE FIGURE A USER GETS: curve, poles and speckles, speckles last.
    @emlDrawLTAS: ltas, "Pen assertion", "Frequency (Hz)",
    ... "Sound pressure level (dB/Hz)", 6, 4, "color", 1,
    ... 0, 5000, 0, 0, 1, 0, 1, 1
    @emlAssertFullViewport
    Save as 300-dpi PNG file: png$
else
    exitScript: "penassert: unknown plugin leg " + leg$
endif
writeInfoLine: "leg ", leg$, " ok"
PRAAT
}

gen_plugin_drive "$EML_ROOT/plugin"   "$GEN/shipped.praat"
gen_plugin_drive "$SHADOW/plugin"     "$GEN/shadow.praat"

# ---------------------------------------------------------------------------
# RUNNING A LEG
# ---------------------------------------------------------------------------
run_leg () {   # run_leg <tag> <drive> <leg>
    local tag="$1" drive="$2" leg="$3"
    local prefs="$OUT/prefs/$tag"
    rm -rf "$prefs"; mkdir -p "$prefs"
    env -u DISPLAY EML_PA_LEG="$leg" EML_PA_PNG="$PNG/$tag.png" \
        timeout 300 "$PRAAT" $PRAAT_TRUST --pref-dir="$prefs" --run "$drive" \
        > "$OUT/$tag.log" 2>&1
    local rc=$?
    if [[ $rc -ne 0 || ! -s "$PNG/$tag.png" ]]; then
        kv "$tag.status" "FAILED rc=$rc"
        return 1
    fi
    kv "$tag.status" ok
}

# diff_pair <name> <tagA> <tagB> — differing pixels, and the two sizes.
diff_pair () {
    local name="$1" a="$2" b="$3" ae
    if [[ ! -s "$PNG/$a.png" || ! -s "$PNG/$b.png" ]]; then
        kv "$name.diff_pixels" "<leg missing>"
        return
    fi
    ae="$(compare -metric AE "$PNG/$a.png" "$PNG/$b.png" null: 2>&1)"
    kv "$name.diff_pixels" "$ae"
    kv "$name.bytes_a" "$(stat -c %s "$PNG/$a.png")"
    kv "$name.bytes_b" "$(stat -c %s "$PNG/$b.png")"
    kv "$name.sha_a" "$(sha256sum "$PNG/$a.png" | cut -c1-16)"
    kv "$name.sha_b" "$(sha256sum "$PNG/$b.png" | cut -c1-16)"
}

# ---- the two controls ------------------------------------------------------
for leg in ctl_arrow_def ctl_arrow_lo ctl_arrow_hi \
           ctl_speck_def ctl_speck_lo ctl_speck_hi \
           ctl_paint_lo  ctl_paint_hi; do
    run_leg "$leg" "$GEN/control.praat" "$leg"
done
diff_pair ctl_arrow          ctl_arrow_lo  ctl_arrow_hi
diff_pair ctl_speckle        ctl_speck_lo  ctl_speck_hi
diff_pair ctl_arrow_default  ctl_arrow_def ctl_arrow_lo
diff_pair ctl_speck_default  ctl_speck_def ctl_speck_lo
diff_pair ctl_paint_circle   ctl_paint_lo  ctl_paint_hi

# ---- the shipped tree ------------------------------------------------------
for leg in witness_clean witness_hostile fig_clean fig_hostile; do
    run_leg "shipped_$leg" "$GEN/shipped.praat" "$leg"
done
diff_pair shipped_witness shipped_witness_clean shipped_witness_hostile
diff_pair shipped_fig     shipped_fig_clean     shipped_fig_hostile

# ---- the shadow tree, assert lines cut -------------------------------------
for leg in witness_clean witness_hostile fig_clean fig_hostile; do
    run_leg "shadow_$leg" "$GEN/shadow.praat" "$leg"
done
diff_pair shadow_witness shadow_witness_clean shadow_witness_hostile
diff_pair shadow_fig     shadow_fig_clean     shadow_fig_hostile

# ---- the two trees against each other on a clean session -------------------
# The assert must not move the picture anyone already has. Both figures were
# drawn in an unperturbed session; 1.0 is Praat's own value for both settings,
# so this pair is the check that says so in pixels.
diff_pair clean_shipped_vs_shadow shipped_fig_clean shadow_fig_clean

printf '\n%s\n' "$TSV"
cat "$TSV"
