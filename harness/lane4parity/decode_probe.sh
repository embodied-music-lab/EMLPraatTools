#!/usr/bin/env bash
# ============================================================================
# harness/lane4parity/decode_probe.sh — proves the k-group ROW DECODER
#                                        itself, not just the engine call
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS PROVES, AND WHY doors.praat DOES NOT ALREADY PROVE IT.
#
# doors.praat's pw_wilcoxon_* legs hand-transcribe the row's decoded
# arguments (test$ = "wilcoxon", adjMethod$ = "holm"/"bonferroni"/"bh") and
# call @emlRunPairwiseAnalysis with them directly — proving that call is the
# SAME call the standalone dialog makes, which is the lane's engine-call
# acceptance. It does NOT exercise eml-wizard.praat's own
# @emlWizard3GroupTestFromMenu procedure, because that file cannot be
# `include`d headless (its top-level code is the dialog chain itself, and
# `beginPause` crashes under --run — see doors.praat's header). So a bug in
# the DECODER — row 16 silently falling through to the wrong branch, a
# transposed adjustment string — would pass doors.praat's parity legs
# outright, because doors.praat never calls the decoder; it calls the thing
# the decoder is SUPPOSED to produce.
#
# THIS SCRIPT closes that gap by extracting ONLY the
# @emlWizard3GroupTestFromMenu procedure body (a pure function of .row --
# see its own header comment) out of the live source file, by its own
# `procedure ... / endproc` markers, into a throwaway include file with a
# tiny driver appended. No hand-copy: whatever the procedure says today is
# what runs. It is the v105-style DRY check CLAUDE.md asks for: the canon
# lives once, in eml-wizard.praat, and this is the text check that a
# specific set of rows still decode the way they are documented to.
#
# Usage: ./decode_probe.sh   (no args; reads
#        ../../plugin_EML_StatsGraphs/scripts/eml-wizard.praat)
# Exit 0 and "PASS" line per row on success; exit 1 and "FAIL" lines listing
# every mismatch otherwise.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WIZARD="$ROOT/plugin_EML_StatsGraphs/scripts/eml-wizard.praat"

# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || { echo "decode_probe: no Praat; refusing" >&2; exit 2; }

[ -f "$WIZARD" ] || { echo "decode_probe: REFUSED — $WIZARD not found" >&2; exit 2; }

START_LINE="$(grep -n '^procedure emlWizard3GroupTestFromMenu' "$WIZARD" | head -1 | cut -d: -f1)"
[ -n "$START_LINE" ] || {
    echo "decode_probe: REFUSED — emlWizard3GroupTestFromMenu not found" >&2
    exit 2
}
END_LINE="$(tail -n "+$START_LINE" "$WIZARD" | grep -n '^endproc' | head -1 | cut -d: -f1)"
[ -n "$END_LINE" ] || {
    echo "decode_probe: REFUSED — no matching endproc found" >&2
    exit 2
}
END_LINE=$((START_LINE + END_LINE - 1))

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PROC_FILE="$TMP/decoder.praat"
sed -n "${START_LINE},${END_LINE}p" "$WIZARD" > "$PROC_FILE"

DRIVER="$TMP/drive.praat"
{
    echo "include $PROC_FILE"
    for row in $(seq 1 18); do
        echo "@emlWizard3GroupTestFromMenu: $row"
        printf 'appendInfoLine: "ROW %s | ", emlWizard3GroupTestFromMenu.isHeader, " | ", emlWizard3GroupTestFromMenu.testApproach, " | ", emlWizard3GroupTestFromMenu.phTest$, " | ", emlWizard3GroupTestFromMenu.phAdj$, " | ", emlWizard3GroupTestFromMenu.phLabel$\n' "$row"
    done
} > "$DRIVER"

OUT="$TMP/out.txt"
( cd "$TMP" && timeout 30 "$PRAAT" $PRAAT_TRUST --run "$DRIVER" > "$OUT" 2>&1 )
rc=$?
if [ "$rc" != 0 ]; then
    echo "decode_probe: FAIL — Praat did not complete (rc=$rc)" >&2
    cat "$OUT" >&2
    exit 1
fi

# Expected decode for the three rows this file exists to prove (punch list
# 4.3's correction), plus the two Dunn rows immediately above them and the
# nonparametric header, so a shift in row numbering is caught too.
declare -A EXPECT=(
    # Row 11 is the nonparametric header ("-- Nonparametric (Kruskal-Wallis)
    # --"); the wizard's own header guard (isHeader = 1) re-shows the page
    # before testApproach/phTest$ are ever read for a header row, so — same
    # as row 1's parametric header, whose testApproach also reads its
    # do-nothing default of 1 — the decoder does not bother setting
    # testApproach for it either. Asserted here as isHeader = 1 only.
    [11]="11 | 1 | 1 |  |  | ANOVA only, no pairwise tests"
    [12]="12 | 0 | 2 |  |  | Kruskal-Wallis only, no pairwise tests"
    [13]="13 | 0 | 2 | dunn | holm | Dunn, Holm"
    [14]="14 | 0 | 2 | dunn | bonferroni | Dunn, Bonferroni"
    [15]="15 | 0 | 2 | dunn | bh | Dunn, Benjamini-Hochberg"
    [16]="16 | 0 | 2 | wilcoxon | holm | Pairwise Wilcoxon, Holm"
    [17]="17 | 0 | 2 | wilcoxon | bonferroni | Pairwise Wilcoxon, Bonferroni"
    [18]="18 | 0 | 2 | wilcoxon | bh | Pairwise Wilcoxon, Benjamini-Hochberg"
)

fail=0
for row in 11 12 13 14 15 16 17 18; do
    got="$(grep "^ROW $row |" "$OUT" | sed -E 's/^ROW ([0-9]+) \| /\1 | /')"
    want="${EXPECT[$row]}"
    if [ "$got" = "$want" ]; then
        printf 'PASS  row %-3s decodes to: %s\n' "$row" "$got"
    else
        printf 'FAIL  row %-3s got:  %s\n' "$row" "$got"
        printf '            want: %s\n' "$want"
        fail=1
    fi
done

echo
echo "decode_probe: full transcript"
cat "$OUT"

exit "$fail"
