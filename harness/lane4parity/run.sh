#!/usr/bin/env bash
# ============================================================================
# harness/lane4parity/run.sh — every leg, then diff each wizard/menu pair
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
# See doors.praat's header for what this proves and why.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
. "$ROOT/harness/_env.sh" || { echo "lane4parity: no Praat; refusing" >&2; exit 2; }

OUT="${EML_L4P_OUT:-$SCRIPT_DIR/out}"
mkdir -p "$OUT"

[ -f "$SCRIPT_DIR/fixture_two.csv" ] || {
    echo "lane4parity: REFUSED — no fixtures. Nothing was cleared." >&2; exit 2; }

LEGS="two_both_wizard two_both_menu paired_both_wizard paired_both_menu \
corr_both_wizard corr_both_menu anova_only_wizard anova_only_menu \
kw_only_wizard kw_only_menu pw_student_bonf_wizard pw_student_bonf_menu \
corr_group_wizard corr_group_menu norm_all_wizard norm_all_menu \
norm_group_wizard norm_group_menu \
pw_wilcoxon_holm_wizard pw_wilcoxon_holm_menu \
pw_wilcoxon_bonf_wizard pw_wilcoxon_bonf_menu \
pw_wilcoxon_bh_wizard pw_wilcoxon_bh_menu"

echo "lane4parity: running legs"
rc_any=0
for leg in $LEGS; do
    ( cd "$SCRIPT_DIR" && EML_L4P_LEG="$leg" \
      timeout 60 "$PRAAT" $PRAAT_TRUST --run doors.praat \
      > "$OUT/$leg.txt" 2>&1 )
    rc=$?
    [ "$rc" = 0 ] || rc_any=1
    printf '  %-24s rc=%-3s %s lines\n' "$leg" "$rc" "$(wc -l < "$OUT/$leg.txt")"
done

# ---------------------------------------------------------------------------
# Diff each wizard/menu pair. The three "Both" legs and the two "only" legs
# diff their WHOLE transcript (== LEG ... == to == END ... ==, names
# stripped); the pairwise-grid leg diffs only the PARITY_BLOCK, since the
# wizard leg also runs the preceding ANOVA that the pairwise leg does not.
# ---------------------------------------------------------------------------
PAIRS="two_both paired_both corr_both anova_only kw_only norm_all"
RESULT="$OUT/PARITY.tsv"
printf 'pair\tidentical\twizard_lines\tmenu_lines\n' > "$RESULT"

strip () {
    # Drop the "== LEG <name> ==" / "== END <name> ==" bookend lines (differ
    # only in leg NAME) and the report's own wall-clock timestamp line (e.g.
    # "  Tue Aug 25 15:47:04 2026") — each leg is a separate Praat process
    # started a second or two apart, so the timestamp is the one line in an
    # otherwise-identical report that legitimately varies run to run. Every
    # OTHER line — every number, every label — is left untouched.
    sed -E -e '/^== LEG /d' -e '/^== END /d' \
        -e '/^ *(Mon|Tue|Wed|Thu|Fri|Sat|Sun) [A-Z][a-z]{2} +[0-9]+ [0-9:]+ [0-9]{4}$/d' \
        "$1"
}

any_fail=0
for pair in $PAIRS; do
    wf="$OUT/${pair}_wizard.txt"
    mf="$OUT/${pair}_menu.txt"
    if [ ! -s "$wf" ] || [ ! -s "$mf" ]; then
        printf '%s\t%s\t%s\t%s\n' "$pair" "no_output" "0" "0" >> "$RESULT"
        any_fail=1
        continue
    fi
    if diff -q <(strip "$wf") <(strip "$mf") >/dev/null 2>&1; then
        ident="1"
    else
        ident="0"
        any_fail=1
        diff <(strip "$wf") <(strip "$mf") > "$OUT/${pair}.diff" 2>&1
    fi
    printf '%s\t%s\t%s\t%s\n' "$pair" "$ident" \
        "$(wc -l < "$wf")" "$(wc -l < "$mf")" >> "$RESULT"
done

# Block-diffed pairs: only the PARITY_BLOCK is compared, because the wizard
# leg also carries preceding code the menu leg does not run (the ANOVA
# before pw_student_bonf's pairwise call; the overall-correlation call's own
# report before corr_group's per-group block — both sides call it, but
# under different local variable names, and the wizard's B_TEST_PAGE and
# the menu's hasGroupCol branch echo it via the SAME @emlRunCorrelationAnalysis
# call so it belongs on both sides equally and does not need separate proof).
BLOCK_PAIRS="pw_student_bonf corr_group norm_group \
pw_wilcoxon_holm pw_wilcoxon_bonf pw_wilcoxon_bh"
for pair in $BLOCK_PAIRS; do
    pwf="$OUT/${pair}_wizard.txt"
    pmf="$OUT/${pair}_menu.txt"
    if [ -s "$pwf" ] && [ -s "$pmf" ]; then
        tsstrip='/^ *(Mon|Tue|Wed|Thu|Fri|Sat|Sun) [A-Z][a-z]{2} +[0-9]+ [0-9:]+ [0-9]{4}$/d'
        awk '/===PARITY_BLOCK_START===/{f=1;next} /===PARITY_BLOCK_END===/{f=0} f' \
            "$pwf" | sed -E -e "$tsstrip" > "$OUT/${pair}_wizard.block"
        awk '/===PARITY_BLOCK_START===/{f=1;next} /===PARITY_BLOCK_END===/{f=0} f' \
            "$pmf" | sed -E -e "$tsstrip" > "$OUT/${pair}_menu.block"
        if diff -q "$OUT/${pair}_wizard.block" \
                  "$OUT/${pair}_menu.block" >/dev/null 2>&1; then
            ident="1"
        else
            ident="0"
            any_fail=1
            diff "$OUT/${pair}_wizard.block" \
                 "$OUT/${pair}_menu.block" > "$OUT/${pair}.diff" 2>&1
        fi
        printf '%s\t%s\t%s\t%s\n' "$pair" "$ident" \
            "$(wc -l < "$OUT/${pair}_wizard.block")" \
            "$(wc -l < "$OUT/${pair}_menu.block")" >> "$RESULT"
    else
        printf '%s\t%s\t%s\t%s\n' "$pair" "no_output" "0" "0" >> "$RESULT"
        any_fail=1
    fi
done

echo
echo "lane4parity: $RESULT"
cat "$RESULT"

[ "$any_fail" = 0 ] && [ "$rc_any" = 0 ]
