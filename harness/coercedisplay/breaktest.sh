#!/usr/bin/env bash
# ============================================================================
# coercedisplay/breaktest.sh -- prove v63's new sections and v64 bite.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# NOTHING IS VALIDATED UNTIL IT HAS BEEN BROKEN. Each case below corrupts a
# COPY of the plugin under $TMPDIR, points the validator at it with
# $EML_PLUGIN_DIR, and reports RED (the validator noticed) or DEAD (it did
# not). Same rule, same reporting vocabulary and the same preflight as
# harness/exportint/breaktest.sh, which does this for v57.
#
# THE OFF-BY-ONE IS THE WHOLE FINDING, so it is broken in BOTH directions and
# in the one shape that a naive check would miss:
#
#   b1  Column_k -> Column_{k+1}   the defect as shipped
#   b3  Column_k -> Column_{k-1}   the same error mirrored, so the check is
#                                  not merely "not equal to the old answer"
#   b2  numbering by GAP COUNT     identical to the correct answer on a fully
#                                  unlabelled source, and wrong only on a
#                                  partially labelled one. A check driven on
#                                  Matrices alone goes green on this, which is
#                                  why v63 grew a partially-labelled case.
#
# AND THE FORMATTER IS BROKEN IN THE DIRECTION THAT LOOKS LIKE A FIX (c2):
# clamping every escaped value to zero closes the reported leak, passes any
# check written only from the reported symptom, and silently turns a printed
# 0.6 into 0 at zero decimals. If v64 stayed green on c2 it would be pinning
# a repair that rounds towards nothing.
#
# PREFLIGHT, and it is not decoration. @mutate compares the file before and
# after and reports UNBUILT if nothing changed: a pattern that has drifted
# corrupts nothing, so it can never be detected, so a green validator under it
# means nothing at all -- and it reads exactly like a passing case.
#
#     bash harness/coercedisplay/breaktest.sh
#
# Exit 0 = every case went RED. Exit 1 = at least one case is DEAD or UNBUILT.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK="${TMPDIR:-/tmp}/coercedisplay_break"
FAILED=0

OUT=plugin/stats/eml-output.praat
GRA=plugin/graphs/eml-graph-procedures.praat
ANA=plugin/stats/eml-analysis.praat
WRI=plugin/stats/eml-result-writer.praat

rm -rf "$WORK"; mkdir -p "$WORK"

# EVERY RUN'S FAILING CHECK NAMES ARE KEPT, not just its count. A case that
# goes red for the wrong reason -- the drive dying, a parse error, a gate --
# reads identically to one that bit, and that is how a break test comes to
# certify a check it never exercised. The names are written beside the case
# and echoed with BREAKTEST_VERBOSE=1.
runv () {   # runv <validator> <plugin-dir>
    local log="$WORK/last.log"
    (cd "$REPO" && EML_PLUGIN_DIR="$2" Rscript "validate/$1" >"$log" 2>&1)
    grep -E "checks, .* passed" "$log" | tail -1
}

for v in v63_coercion_parity.R v64_display_and_coercion.R; do
    base=$(runv "$v" "$REPO/plugin")
    echo "BASELINE  $v  $base"
    case "$base" in
        *", 0 FAILED"*) ;;
        *) echo "breaktest: FAIL -- baseline $v is not green; stopping"; exit 1 ;;
    esac
done
echo

newtree () {   # newtree <name> -> echoes the plugin root of a fresh copy
    local t="$WORK/$1"
    rm -rf "$t"; mkdir -p "$t"
    cp -r "$REPO/plugin" "$t/plugin"
    printf '%s' "$t/plugin"
}

mutate () {   # mutate <file> <perl-expr>
    local f="$1" expr="$2" before after
    before=$(md5sum "$f" | cut -d' ' -f1)
    perl -0pi -e "$expr" "$f"
    after=$(md5sum "$f" | cut -d' ' -f1)
    if [[ "$before" == "$after" ]]; then
        echo "UNBUILT  $(basename "$f") -- the pattern matched nothing"
        FAILED=1
        return 1
    fi
    return 0
}

report () {   # report <name> <validator> <last-line>
    local name="$1" v="$2" line="$3"
    case "$line" in
        *", 0 FAILED"*) echo "DEAD   $name [$v] -- stayed green"; FAILED=1 ;;
        *FAILED*)       echo "RED    $name [$v] -- $line"
                        cp -f "$WORK/last.log" "$WORK/$name.log" 2>/dev/null
                        grep -E "^FAIL " "$WORK/$name.log" 2>/dev/null \
                            | sed -E 's/  computed=.*$//; s/^FAIL  /           - /' \
                            > "$WORK/$name.fails"
                        if [[ -n "${BREAKTEST_VERBOSE:-}" ]]; then
                            cat "$WORK/$name.fails"
                        fi ;;
        *)              echo "DEAD   $name [$v] -- no report ($line)"; FAILED=1 ;;
    esac
}

# ---------------------------------------------------------------------------
# RULING 5 -- the source-index numbering of Column_<n>
# ---------------------------------------------------------------------------

# b1  The defect exactly as shipped: number by TABLE position, so the label
#     column takes slot 1 and source column k is called Column_{k+1}.
p=$(newtree b1_table_position)
mutate "$p/stats/eml-output.praat" \
    's/            \.\.\. "Column_" \+ string\$ \(\.c - \.insertedCols\)/            ... "Column_" + string\$ (.c)/' &&
report b1_table_position v63 "$(runv v63_coercion_parity.R "$p")"

# b2  Number the GAPS in order instead of by source index. Indistinguishable
#     from correct on a Matrix; wrong on a partially labelled TableOfReal.
p=$(newtree b2_gap_count)
mutate "$p/stats/eml-output.praat" \
    's/            \.\.\. "Column_" \+ string\$ \(\.c - \.insertedCols\)/            ... "Column_" + string\$ (.nNamed + 1)/' &&
report b2_gap_count v63 "$(runv v63_coercion_parity.R "$p")"

# b3  The mirror image: one too FEW, so the numbering starts at Column_0.
p=$(newtree b3_off_by_one_down)
mutate "$p/stats/eml-output.praat" \
    's/            \.\.\. "Column_" \+ string\$ \(\.c - \.insertedCols\)/            ... "Column_" + string\$ (.c - .insertedCols - 1)/' &&
report b3_off_by_one_down v63 "$(runv v63_coercion_parity.R "$p")"

# b4  The headers stop being invented at all -- the state before the S1
#     repair, kept here because §3f's "every manufactured header was found"
#     must not be satisfiable by a table that has none.
p=$(newtree b4_no_naming)
mutate "$p/stats/eml-output.praat" \
    's/        if \.lab\$ = "\?" or \.lab\$ = ""\n            Rename column \(by number\): \.c,/        if 1 = 0\n            Rename column (by number): .c,/' &&
report b4_no_naming v63 "$(runv v63_coercion_parity.R "$p")"

# b5  The other two doors made to collide: every unnamed column takes one
#     name. Duplicate-free is §3c; addressing each source column exactly once
#     is §3h, and this breaks both over a file v63 only MEASURES.
p=$(newtree b5_graphs_duplicate)
mutate "$p/graphs/eml-graph-procedures.praat" \
    's/            Rename column \(by number\): \.iCol, "Column_" \+ string\$ \(\.iCol\)/            Rename column (by number): .iCol, "Column_9"/' &&
report b5_graphs_duplicate v63 "$(runv v63_coercion_parity.R "$p")"

# ---------------------------------------------------------------------------
# RULING 8a -- one source object, one converted Table
# ---------------------------------------------------------------------------

# b6  The cleanup removed from the Matrix arm: presses accumulate again.
p=$(newtree b6_no_cleanup)
mutate "$p/stats/eml-output.praat" \
    's/        \@eml_dropStaleConverted: "eml_converted_" \+ \.matName\$\n        \.nStale = eml_dropStaleConverted\.nDropped\n/        .nStale = 0\n/' &&
report b6_no_cleanup v63 "$(runv v63_coercion_parity.R "$p")"

# b7  The cleanup left in place but neutered -- it looks for the wrong name,
#     so it runs, reports nothing dropped, and collects nothing. A check that
#     only asserted "the procedure is called" would go green here.
p=$(newtree b7_cleanup_wrong_name)
mutate "$p/stats/eml-output.praat" \
    's/        \@eml_dropStaleConverted: "eml_converted_" \+ \.matName\$/        \@eml_dropStaleConverted: "eml_notaname_" + .matName\$/' &&
report b7_cleanup_wrong_name v63 "$(runv v63_coercion_parity.R "$p")"

# ---------------------------------------------------------------------------
# RULING 6 -- no raw double reaches the Info window
# ---------------------------------------------------------------------------

# c1  @emlReportLine goes back to calling fixed$ directly. This is the defect
#     as reported: the one row printer unrouted.
p=$(newtree c1_unrouted_reportline)
mutate "$p/stats/eml-output.praat" \
    's/    \@eml_fixed: \.value, \.decimals\n    \.formattedValue\$ = eml_fixed\.result\$/    .formattedValue\$ = fixed\$ (.value, .decimals)/' &&
report c1_unrouted_reportline v64 "$(runv v64_display_and_coercion.R "$p")"

# c2  THE REPAIR THAT LOOKS LIKE A REPAIR. Every escaped value is clamped to
#     zero instead of being rounded, which closes the reported leak and turns
#     0.6 at zero decimals into 0. A grid built only from the symptom passes.
p=$(newtree c2_clamp_to_zero)
mutate "$p/stats/eml-output.praat" \
    's/            \.pow = 10 \^ \.decimals\n            \.rounded = round \(\.value \* \.pow\) \/ \.pow\n            if \.rounded = 0/            .pow = 10 ^ .decimals\n            .rounded = 0\n            if .rounded = 0/' &&
report c2_clamp_to_zero v64 "$(runv v64_display_and_coercion.R "$p")"

# c3  @eml_fixed becomes a pass-through: the procedure exists, is called
#     everywhere, and does nothing. The static census of section 1 stays
#     green on this, which is exactly why section 2 drives it.
p=$(newtree c3_passthrough)
mutate "$p/stats/eml-output.praat" \
    's/        if \.shown <> \.decimals\n            \.pow = 10 \^ \.decimals/        if 1 = 0\n            .pow = 10 ^ .decimals/' &&
report c3_passthrough v64 "$(runv v64_display_and_coercion.R "$p")"

# c4  The zero is produced but not padded, so an exact zero prints "0" in a
#     column of four-decimal neighbours -- the second half of the mechanism.
p=$(newtree c4_unpadded_zero)
mutate "$p/stats/eml-output.praat" \
    's/                \.result\$ = "0"\n                if \.decimals > 0/                .result\$ = "0"\n                if 1 = 0/' &&
report c4_unpadded_zero v64 "$(runv v64_display_and_coercion.R "$p")"

# c5  A printed negative zero: the sign of a value that is not there.
p=$(newtree c5_negative_zero)
mutate "$p/stats/eml-output.praat" \
    's/                \.result\$ = "0"\n                if \.decimals > 0/                .result\$ = "-0"\n                if .decimals > 0/' &&
report c5_negative_zero v64 "$(runv v64_display_and_coercion.R "$p")"

# c6  A SECOND DOOR TO fixed$ opened in the module, with every printed value
#     still correct. Only the static one-door census of section 1 can see
#     this, and it is the check that keeps the repair a repair.
p=$(newtree c6_second_door)
mutate "$p/stats/eml-output.praat" \
    's/procedure emlReportBlank\n    # Print empty line/procedure emlReportBlank\n    .unused\$ = fixed\$ (1, 2)\n    # Print empty line/' &&
report c6_second_door v64 "$(runv v64_display_and_coercion.R "$p")"

# c7  RULING 3'"'"'S PREMISE, BROKEN THE WAY A WRONG FIX WOULD BREAK IT: the
#     asymmetry resolved by LOSING the shape statistics from the single-column
#     export instead of gaining them in tidy. Both frames would then agree,
#     and the agreement would be the wrong one.
#
#     BROKEN AT THE DECLARATION, NOT AT THE VOCABULARY, and the distinction is
#     v57's S12 finding. Deleting `skewness kurtosis` from emlVocabGlance$
#     instead makes @eml_vocabCheck exitScript at the EMISSION site, which
#     kills the drive outright: the case then goes red on "the display probe
#     ran" and proves only that the writer is loud when a script emits an
#     unknown name. The silent loss this check is for happens at WRITE, to a
#     column nobody emitted, so the mutation has to leave the writer happy.
p=$(newtree c7_glance_loses_shape)
mutate "$p/stats/eml-analysis.praat" \
    's/        \@emlGlanceNum: "skewness",    emlNorm_skew \[1\]\n        \@emlGlanceNum: "kurtosis",    emlNorm_kurt \[1\]\n//' &&
report c7_glance_loses_shape v64 "$(runv v64_display_and_coercion.R "$p")"

# c8  The multi-column tidy frame collapses to one row -- the shape failure
#     that shipped once already, and the one a whitelist drop produces.
p=$(newtree c8_tidy_one_row)
mutate "$p/stats/eml-analysis.praat" \
    's/    for \.i from 1 to emlNorm_n\n        \@emlTidyRow: emlNorm_col\$ \[\.i\]/    for .i from 1 to 1\n        \@emlTidyRow: emlNorm_col\$ [.i]/' &&
report c8_tidy_one_row v64 "$(runv v64_display_and_coercion.R "$p")"

# ---------------------------------------------------------------------------
# THE GATES -- a validator that cannot drive must go RED, not quiet
# ---------------------------------------------------------------------------
# Section 2a of v64 measures PRAAT'S OWN fixed$, which no source mutation can
# change: it is a property of the binary, not of the plugin. What can be shown
# is the gate around it -- that a run with no usable Praat reports the missing
# evidence as a failure instead of passing the static half and going quiet.
for v in v63_coercion_parity.R v64_display_and_coercion.R; do
    # Through the same log capture as every other case, so the recorded
    # failing-check names belong to THIS run and not to the one before it.
    (cd "$REPO" && PRAAT=/nonexistent/praat Rscript "validate/$v" \
        >"$WORK/last.log" 2>&1)
    line=$(grep -E "checks, .* passed" "$WORK/last.log" | tail -1)
    report "g1_no_binary_${v%%_*}" "${v%%_*}" "$line"
done

echo
if [[ $FAILED -eq 0 ]]; then
    echo "breaktest: every case went RED"
else
    echo "breaktest: at least one case is DEAD or UNBUILT -- see above"
fi
exit $FAILED
