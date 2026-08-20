#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# vecfig/run.sh -- drive the figure's three formats, including on a host that
#                  has not got one of them
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#   bash harness/vecfig/run.sh
#   Rscript validate/v86_vector_figure_export.R
#
# SIX FORMAT LEGS, THEN A RECORDING. Four ask a working Praat for a different
# combination of formats.
# Two ask a Praat that has been DEPRIVED of a format, which is the condition
# the redirect exists for and the only part of this that has to be arranged:
# the leg's copy of eml-output.praat has `Save as PDF file:` -- and, on the
# second, `Save as EPS file:` as well -- renamed to a command Praat does not
# have. Praat's answer to an absent command is "Command ... not available for
# current selection" and an aborted script, exactly as it is on Windows for
# PDF, and `nocheck` in front of it is what turns that into a survivable no.
#
# THE MUTATION IS OF THE HOST'S CAPABILITY, NOT OF THE CHECK. Nothing in the
# landed-file machinery is touched on any leg. What changes is whether the
# format exists to be written, which is the variable the user's machine sets.
#
# EACH LEG IS A SEPARATE PRAAT under a HOME of its own, because `include` is a
# parse-time text paste: a leg that must see a different eml-output.praat must
# be a different process, and Praat keeps a lock file under its preferences
# folder that two concurrent runs would fight over.
#
# AND THEN THE RECORDER, which is the other half of the same promise: a
# session that ticked EPS and was recorded has to replay as EPS a month later,
# and a recording holding two saves with different choices has to replay as
# both. That leg records, replays, edits one line of the emitted script's
# editable block and replays again, so the block is proved load-bearing rather
# than merely present.
#
# Output: out/VECFIG.tsv        key<TAB>value, one stream, appended per leg
#         out/files/<leg>/      the artefacts themselves, for the validator to
#                               read the first bytes of
#         out/record/           the emitted script, and the edited copy
#         out/files/replay_*/   what each replay actually wrote
#         out/work/<leg>/       scratch: the tree that leg was driven against
# ---------------------------------------------------------------------------
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="${EML_VECFIG_OUT:-$HERE/out}"
TSV="$OUT/VECFIG.tsv"
PRAAT="${EML_PRAAT:-praat}"

# THE TREE UNDER TEST. Unset, it is the shipped plugin. break.sh points it at
# a deliberately broken copy, so a break test never edits the working tree --
# the failure mode where a break test is interrupted and leaves the repair
# reverted is one this harness cannot have.
SRC="${EML_VECFIG_SRC:-$ROOT/plugin/stats}"

rm -rf "$OUT"
mkdir -p "$OUT/files" "$OUT/work"
: > "$TSV"

emit() { printf '%s\t%s\n' "$1" "$2" >> "$TSV"; }

if ! command -v "$PRAAT" >/dev/null 2>&1; then
    echo "vecfig: no Praat on PATH (set EML_PRAAT) — nothing driven" >&2
    emit "meta_praat_found" "0"
    exit 1
fi
emit "meta_praat_found" "1"

# THE TRANSCRIPT IS BOUND TO THE CODE IT WAS TAKEN FROM. Comment lines are
# dropped before the digest so rewrapping a paragraph does not invalidate a
# drive, and any change to a statement does. validate/v86 recomputes this from
# the working tree and refuses a transcript taken from a different file.
sha_of_code() {
    grep -v '^[[:space:]]*[#;!]' "$1" | sha256sum | cut -d' ' -f1
}
emit "meta_output_code_sha256" "$(sha_of_code "$SRC/eml-output.praat")"
# THE RECORDER IS BOUND THE SAME WAY, because the record/replay leg below
# drives it and a transcript taken from a different eml-record.praat is not
# evidence about this one.
emit "meta_record_code_sha256" "$(sha_of_code "$SRC/eml-record.praat")"

# ---------------------------------------------------------------------------
# ONE LEG
#   $1 leg name   $2 want EPS   $3 want PDF   $4 run the unit section
#   $5 mutation: "none", "nopdf", "novector"
# ---------------------------------------------------------------------------
leg() {
    local name="$1" eps="$2" pdf="$3" units="$4" mut="$5"
    local work="$OUT/work/$name"
    mkdir -p "$work/plugin" "$work/home"
    cp -r "$SRC" "$work/plugin/stats"
    cp "$HERE/drive.praat" "$work/drive.praat"

    # THE COMMAND IS TAKEN AWAY BY RENAMING IT, and only on the `nocheck`
    # lines that attempt it -- a rename anywhere else would be a change to
    # something this leg is not about. "PDF document" and "EPS vector" are
    # names Praat has never had.
    case "$mut" in
        nopdf)
            sed -i 's/^\([[:space:]]*\)nocheck Save as PDF file:/\1nocheck Save as PDF document file:/' \
                "$work/plugin/stats/eml-output.praat" ;;
        novector)
            sed -i 's/^\([[:space:]]*\)nocheck Save as PDF file:/\1nocheck Save as PDF document file:/;
                    s/^\([[:space:]]*\)nocheck Save as EPS file:/\1nocheck Save as EPS vector file:/' \
                "$work/plugin/stats/eml-output.praat" ;;
    esac

    # THE MUTATION IS RECORDED AS A COUNT, so a sed that silently matched
    # nothing -- a renamed procedure, a reindented line -- is visible in the
    # transcript instead of turning the leg into a duplicate of the first one.
    emit "${name}_attempt_pdf_lines" \
         "$(grep -c '^[[:space:]]*nocheck Save as PDF file:' "$work/plugin/stats/eml-output.praat")"
    emit "${name}_attempt_eps_lines" \
         "$(grep -c '^[[:space:]]*nocheck Save as EPS file:' "$work/plugin/stats/eml-output.praat")"
    emit "${name}_mutation" "$mut"
    emit "${name}_want_eps" "$eps"
    emit "${name}_want_pdf" "$pdf"

    (
        cd "$work" || exit 1
        HOME="$work/home" \
        EML_VECFIG_LEG="$name" \
        EML_VECFIG_TSV="$TSV" \
        EML_VECFIG_FILES="$OUT/files/$name" \
        EML_VECFIG_EPS="$eps" \
        EML_VECFIG_PDF="$pdf" \
        EML_VECFIG_UNITS="$units" \
        timeout 180 "$PRAAT" --run drive.praat > "$OUT/$name.log" 2>&1
    )
    # THE COPY IS THROWN AWAY, not kept as evidence. What it was is already
    # in the transcript, as the count of attempt lines the leg's tree carried,
    # and six copies of the stats layer per run is eight megabytes of scratch
    # that reads like something a reviewer should open.
    rm -rf "$work/plugin"
    echo "vecfig: $name done ($(grep -c "^${name}_" "$TSV") rows)"
}

leg all       1 1 1 none
leg pngonly   0 0 0 none
leg epsonly   1 0 0 none
leg pdfonly   0 1 0 none
leg nopdf     1 1 0 nopdf
leg novector  1 1 0 novector

# ---------------------------------------------------------------------------
# THE OTHER HALF OF THE PLATFORM MEASUREMENT
# ---------------------------------------------------------------------------
# What an absent command does WITHOUT `nocheck`, taken in a process of its own
# because the answer is that the script stops. This is the reason the whole
# design is built on `nocheck` plus a look at the disk, and it is measured
# here rather than quoted from the manual.
UN="$OUT/work/unguarded"
mkdir -p "$UN/home"
cat > "$UN/bare.praat" <<'EOF'
Erase all
Select outer viewport: 0, 6, 0, 4
Axes: 0, 1, 0, 1
Draw inner box
appendInfoLine: "BEFORE"
Save as SVG file: "bare.svg"
appendInfoLine: "AFTER"
EOF
(
    cd "$UN" || exit 1
    HOME="$UN/home" timeout 60 "$PRAAT" --run bare.praat > "$UN/bare.log" 2>&1
)
if grep -q '^BEFORE' "$UN/bare.log"; then
    emit "meta_unguarded_before" "1"
else
    emit "meta_unguarded_before" "0"
fi
if grep -q '^AFTER' "$UN/bare.log"; then
    emit "meta_unguarded_after" "1"
else
    emit "meta_unguarded_after" "0"
fi
if grep -q 'not available for current selection' "$UN/bare.log"; then
    emit "meta_unguarded_message" "not available for current selection"
else
    emit "meta_unguarded_message" ""
fi

# ---------------------------------------------------------------------------
# THE FIELD NAMES, MEASURED
# ---------------------------------------------------------------------------
# Praat derives a dialog field's variable from its LABEL, lowercasing the first
# character and keeping every other character's case, so "Also EPS" is read
# back as also_EPS. Read it as also_eps and the save aborts with "Unknown
# variable" at the moment the user presses Save -- which is the one failure a
# tickbox panel is most able to hide, and the reason the panel's own comments
# warn about it. It is measured here rather than argued: a `form` filled from
# the command line uses the same derivation and shows no dialog, so the three
# labels the panel uses are declared and read back by name.
FN="$OUT/work/fieldnames"
mkdir -p "$FN/home"
cat > "$FN/names.praat" <<'EOF'
form: "field name probe"
    boolean: "Figure PNG", 1
    boolean: "Also EPS", 0
    boolean: "Also PDF", 0
endform
appendInfoLine: "figure_PNG=", figure_PNG
appendInfoLine: "also_EPS=", also_EPS
appendInfoLine: "also_PDF=", also_PDF
EOF
(
    cd "$FN" || exit 1
    HOME="$FN/home" timeout 60 "$PRAAT" --run names.praat 1 1 0 > "$FN/names.log" 2>&1
)
for k in figure_PNG also_EPS also_PDF; do
    if grep -q "^${k}=" "$FN/names.log"; then
        emit "meta_field_${k}" "$(grep "^${k}=" "$FN/names.log" | head -1 | cut -d= -f2)"
    else
        emit "meta_field_${k}" ""
    fi
done

# ---------------------------------------------------------------------------
# THE PLATFORM FLAGS PRAAT EXPOSES, MEASURED
# ---------------------------------------------------------------------------
# The Save panel offers the PDF tickbox only where Praat has the command, and
# it asks Praat's own `windows` flag. Read here so the validator knows which
# arm of that branch this box took -- a check that asserted "the PDF box is
# offered" without knowing the answer to this question would be asserting the
# wrong half on a Windows machine.
FLG="$OUT/work/flags"
mkdir -p "$FLG/home"
cat > "$FLG/flags.praat" <<'EOF'
appendInfoLine: "windows=", windows
appendInfoLine: "macintosh=", macintosh
appendInfoLine: "unix=", unix
EOF
(
    cd "$FLG" || exit 1
    HOME="$FLG/home" timeout 60 "$PRAAT" --run flags.praat > "$FLG/flags.log" 2>&1
)
for k in windows macintosh unix; do
    if grep -q "^${k}=" "$FLG/flags.log"; then
        emit "meta_flag_${k}" "$(grep "^${k}=" "$FLG/flags.log" | head -1 | cut -d= -f2)"
    else
        emit "meta_flag_${k}" ""
    fi
done

# ---------------------------------------------------------------------------
# A FIELD THAT WAS NOT DECLARED HAS NO VARIABLE
# ---------------------------------------------------------------------------
# `boolean:` builds the tickbox AND the variable, so a panel that leaves the
# PDF box out on Windows leaves also_PDF unbound -- and reading an unbound
# variable ends the script at that line, inside the save, which is the outage
# the panel's .alsoPDF exists to avoid. Both halves are measured: that the
# variable is absent, and that reading it stops the run.
FA="$OUT/work/absentfield"
mkdir -p "$FA/home"
cat > "$FA/absent.praat" <<'EOF'
form: "absent field probe"
    boolean: "Figure PNG", 1
    boolean: "Also EPS", 0
endform
appendInfoLine: "eps_exists=", variableExists ("also_EPS")
appendInfoLine: "pdf_exists=", variableExists ("also_PDF")
appendInfoLine: "BEFORE"
x = also_PDF
appendInfoLine: "AFTER"
EOF
(
    cd "$FA" || exit 1
    HOME="$FA/home" timeout 60 "$PRAAT" --run absent.praat 1 1 > "$FA/absent.log" 2>&1
)
for k in eps_exists pdf_exists; do
    if grep -q "^${k}=" "$FA/absent.log"; then
        emit "meta_absent_${k}" "$(grep "^${k}=" "$FA/absent.log" | head -1 | cut -d= -f2)"
    else
        emit "meta_absent_${k}" ""
    fi
done
emit "meta_absent_before" "$(grep -c '^BEFORE' "$FA/absent.log")"
emit "meta_absent_after"  "$(grep -c '^AFTER' "$FA/absent.log")"

# ---------------------------------------------------------------------------
# THE RECORDING, AND THE TWO REPLAYS OF IT
# ---------------------------------------------------------------------------
# A recording holds two figures saved with DIFFERENT formats. It is replayed
# as emitted, then replayed again with ONE line of its editable block changed
# -- the second save's format -- and the files each replay leaves, TOGETHER
# WITH THE RECEIPT IT PRINTED ABOUT THEM, are what the validator reads. The
# second half is the point of putting the choice in the block at all: a block
# whose variables change nothing is decoration.
#
# THE WHOLE PLUGIN IS COPIED for this leg, not the stats layer alone: a
# recording draws figures, so the graphs modules have to be there, and the
# emitted script includes them by absolute path out of the tree it was
# recorded against. $SRC still supplies stats/, so a break test's damaged copy
# is what the recording and both replays run.
REC="$OUT/work/record"
RECOUT="$OUT/record"
SAVEDIR="$OUT/files/replay"
mkdir -p "$REC/home" "$RECOUT" "$SAVEDIR"
# THE SOURCE IS THE REAL FOLDER, NOT THE COMPATIBILITY SYMLINK. `plugin` in
# the repository root is a symlink to plugin_EML_StatsGraphs, and `cp -r` of a
# symlink argument copies the LINK: $REC/plugin then points at a relative name
# that does not exist beside it, and every write into it fails with "No such
# file or directory" while the leg carries on. The destination keeps the short
# name because record_drive.praat includes plugin/stats/... out of $REC.
cp -r "$ROOT/plugin_EML_StatsGraphs" "$REC/plugin"
rm -rf "$REC/plugin/stats"
cp -r "$SRC" "$REC/plugin/stats"
cp "$HERE/record_drive.praat" "$REC/drive.praat"
(
    cd "$REC" || exit 1
    HOME="$REC/home" \
    EML_VECFIG_TSV="$TSV" \
    EML_VECFIG_REC="$RECOUT" \
    EML_VECFIG_ROOT="$REC" \
    EML_VECFIG_SAVEDIR="$SAVEDIR" \
    timeout 240 "$PRAAT" --run drive.praat > "$OUT/record.log" 2>&1
)

EMITTED="$RECOUT/emitted.praat"
EDITED="$RECOUT/edited.praat"

if [[ -s "$EMITTED" ]]; then
    emit "rec_emitted" "1"
    # EVERY DECLARATION LINE THE BLOCK HOLDS FOR A FORMAT, in order, read out
    # of the file a user would open rather than out of a variable in the
    # process that wrote it.
    while IFS= read -r ln; do
        emit "rec_blockline" "$ln"
    done < <(sed -n '/^# Name your data objects/,/^$/p' "$EMITTED" \
             | grep -E '^figureFormat[0-9]*\$ *=')
    # AND THE CALLS THAT READ THEM. A block that declares the variables and
    # leaves the steps below holding their own literals passes every grep and
    # is worth nothing.
    emit "rec_save_call1" \
         "$(grep -m1 'figA_20260817_120000' "$EMITTED")"
    emit "rec_save_call2" \
         "$(grep -m1 'figB_20260817_120000' "$EMITTED")"
    emit "rec_savepanel_left" "$(grep -c '@emlSavePanel:' "$EMITTED")"
    emit "rec_replaysave" "$(grep -c '@emlRecordReplaySave:' "$EMITTED")"
    emit "rec_beginpause" "$(grep -c 'beginPause' "$EMITTED")"
    emit "rec_block_promise" \
         "$(grep -c 'names an object, a column or an axis' "$EMITTED")"

    # ── THE EDIT A USER WOULD MAKE ────────────────────────────────────────
    # One line: the SECOND save's format, PDF swapped for EPS. Nothing else
    # in the file is touched, and both halves of that are measured -- how many
    # lines changed, and whether any of them was below the first step.
    sed -e 's/^figureFormat2\$\( *\)= "PNG, PDF"/figureFormat2$\1= "PNG, EPS"/' \
        "$EMITTED" > "$EDITED"
    emit "rec_edit_lines_changed" "$(diff "$EMITTED" "$EDITED" | grep -c '^< ')"
    firststep="$(grep -n '^# --- Step ' "$EMITTED" | head -1 | cut -d: -f1)"
    if [[ -n "$firststep" ]]; then
        emit "rec_edit_below_block" \
             "$(diff <(tail -n +"$firststep" "$EMITTED") \
                     <(tail -n +"$firststep" "$EDITED") | grep -c '^< ')"
    else
        emit "rec_edit_below_block" "-1"
    fi
else
    emit "rec_emitted" "0"
fi

# ONE REPLAY, IN A PROCESS OF ITS OWN, with the fixture rebuilt from the same
# seeded sequence the recording used -- the emitted script selects its object
# by NAME through the block, and a name resolves to nothing in a fresh Praat.
# The emitted file is INCLUDED rather than runScript:-ed, because `include` is
# a textual paste into one scope, which is how a user runs it.
replay_arm() {
    local arm="$1" script="$2"
    local rw="$OUT/work/replay_$arm"
    mkdir -p "$rw/home"
    [[ -s "$script" ]] || { emit "rec_${arm}_ran" "0"; return; }
    cat > "$rw/replay.praat" <<PRAAT
Text writing preferences: "UTF-8"
t = Create Table with column names: "vt", 0, "grp val"
st = 20260817
r = 0
for g from 1 to 3
    for k from 1 to 20
        st = (1103515245 * st + 12345) mod 2147483648
        r = r + 1
        Append row
        Set string value: r, "grp", "G" + string\$ (g)
        Set numeric value: r, "val", 200 + g * 18 + (st / 2147483648 - 0.5) * 80
    endfor
endfor
include $script
PRAAT
    (
        cd "$rw" || exit 1
        HOME="$rw/home" timeout 240 "$PRAAT" --run replay.praat \
            > "$OUT/replay_$arm.log" 2>&1
    )
    emit "rec_${arm}_ran" "1"
    emit "rec_${arm}_abort" \
         "$(grep -c 'not performed or completed' "$OUT/replay_$arm.log")"

    # ── THE RECEIPT THE REPLAY PRINTED ────────────────────────────────────
    # A save that says nothing about itself is the failure @eml_saveFileLanded
    # exists against, and @emlRecordReplaySave's answer to a replay -- which
    # may open no dialog -- is three printed lines per save:
    #
    #     EML: replayed save -- wrote <n> file(s) to
    #     <folder>
    #     base name <stem>
    #
    # They are taken VERBATIM into the transcript first, so a reader can see
    # what the run said, and then parsed into the three numbers the validator
    # compares against the files below. What must correspond is the REPLAY's
    # receipt to the REPLAY's disk -- not to the recording's receipt, which
    # the procedure's own contract forbids: the stamp in the stem is
    # regenerated at replay time rather than replayed, so a replay's outputs
    # are dated when they were made, and the folder is a line the reader is
    # invited to edit. A check that demanded the two receipts match would be
    # demanding the opposite of what the code promises.
    #
    # THE FOLDER THE REPLAY WAS POINTED AT is recorded beside them, because
    # "the receipt names the right folder" is otherwise a claim with nothing
    # to be right about.
    emit "rec_${arm}_savedir" "$SAVEDIR"
    local rk rv
    while IFS=$'\t' read -r rk rv; do
        emit "rec_${arm}_$rk" "$rv"
    done < <(awk '
        /^EML: replayed save -- wrote / {
            n = $0
            sub(/^EML: replayed save -- wrote /, "", n)
            sub(/ file\(s\) to$/, "", n)
            print "receipt_line\t" $0
            folder = ""
            stem = ""
            if ((getline folder) > 0) { print "receipt_line\t" folder }
            if ((getline stem)   > 0) { print "receipt_line\t" stem }
            sub(/^base name /, "", stem)
            print "receipt_n\t"      n
            print "receipt_folder\t" folder
            print "receipt_stem\t"   stem
            seen = seen + 1
        }
        END { print "receipts\t" seen + 0 }
    ' "$OUT/replay_$arm.log")

    # THE FILES THE REPLAY LEFT, moved out of the shared folder so the second
    # replay writes into an empty one and the two arms cannot be confused.
    local dest="$OUT/files/replay_$arm"
    mkdir -p "$dest"
    if compgen -G "$SAVEDIR/*" > /dev/null; then
        mv "$SAVEDIR"/* "$dest"/
    fi
    local f
    for f in "$dest"/*; do
        [[ -e "$f" ]] || continue
        emit "rec_${arm}_file" "$f"
    done
    local stem ext
    for stem in figA figB; do
        for ext in png eps pdf; do
            emit "rec_${arm}_${stem}_${ext}" \
                 "$(ls -1 "$dest/${stem}_"*".${ext}" 2>/dev/null | wc -l)"
        done
    done
}

replay_arm same "$EMITTED"
replay_arm edited "$EDITED"

# The recording's copy of the tree goes the way every leg's does: what it was
# is in the transcript, and a second copy of the plugin is scratch that reads
# like evidence.
rm -rf "$REC/plugin"

emit "meta_legs" "6"
echo "vecfig: $(wc -l < "$TSV") rows in $TSV"
