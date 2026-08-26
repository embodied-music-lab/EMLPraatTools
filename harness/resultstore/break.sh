#!/usr/bin/env bash
# ============================================================================
# harness/resultstore/break.sh -- the seeded violation for v139's mutation legs
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# A GREEN v139 IS NOT EVIDENCE THAT v139 IS MEASURING ANYTHING unless it can
# be shown RED against a tree that actually breaks the property it claims to
# hold. This copies the plugin, neuters @emlStoreKeyTake so the published key
# NEVER MOVES no matter what the table says, and re-drives
# harness/resultstore/probe.praat against the copy -- so every one of
# validate/v139's four "the published key changed" assertions fails.
#
# WHAT IS PATCHED, AND WHY THIS SHAPE AND NOT ANOTHER. @emlStoreKeyTake's
# assignment of .key$ from @emlGroupFingerprint's own result is replaced with
# a literal constant. This is not a hypothetical bug: it is exactly the
# failure mode RULING_RESULT_STORE.md's own header warns about under WHERE THE
# KEY IS TAKEN -- a caller that takes a key and does not let it describe the
# table -- reproduced at the one call site the ruling names as the place that
# must not do this.
#
# THE COPY IS A COPY. Nothing here edits the working tree and puts it back --
# the same discipline harness/settingspub/break.sh and
# harness/settings/seed_violation.sh use, for the same reason: a rig that
# edits the repository and restores it is one interrupted run away from
# committing the defect it exists to demonstrate.
#
# Run from anywhere:  bash harness/resultstore/break.sh
# Output: harness/resultstore/out/break/STORE.tsv
#         and this script's own run of validate/v139 against that shadow
#         evidence, which is expected to print FAILs -- that is the point.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EML_ROOT_REAL="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$EML_ROOT_REAL/harness/_env.sh" || exit 1

WORK="$(mktemp -d "${TMPDIR:-/tmp}/resultstore-break-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
OUT="$SCRIPT_DIR/out/break"
rm -rf "$OUT"
mkdir -p "$OUT"

# The smallest tree the probe can run out of: the plugin under the folder
# name its includes are written against, and this rig's own two files.
mkdir -p "$WORK/harness/resultstore"
cp -r "$EML_ROOT/plugin_EML_StatsGraphs" "$WORK/plugin_EML_StatsGraphs"
ln -s plugin_EML_StatsGraphs "$WORK/plugin"
cp "$EML_ROOT/harness/_env.sh" "$WORK/harness/_env.sh" 2>/dev/null || mkdir -p "$WORK/harness" && cp "$EML_ROOT/harness/_env.sh" "$WORK/harness/_env.sh"
cp "$SCRIPT_DIR/probe.praat" "$WORK/harness/resultstore/"
cp "$SCRIPT_DIR/run.sh" "$WORK/harness/resultstore/"

EXTRACT="$WORK/plugin_EML_StatsGraphs/stats/eml-extract.praat"
python3 - "$EXTRACT" <<'PY'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
mark = "    .key$ = emlGroupFingerprint.result$\n"
if mark not in s:
    sys.exit("break.sh: the line to neuter is not in @emlStoreKeyTake -- "
              "this script names the shape it breaks, so a rename is a "
              "failure here rather than a break test that quietly does "
              "nothing.")
io.open(p, "w", encoding="utf-8").write(
    s.replace(mark,
              '    .key$ = "eTF2|BROKEN-CONSTANT-KEY-FOR-BREAK-TEST"\n',
              1))
PY
[[ $? -eq 0 ]] || exit 1

PRAAT="$PRAAT" EML_STORE_OUT="$OUT" \
    bash "$WORK/harness/resultstore/run.sh" || exit 1

echo "break: keysAgree column, every mutation leg (expect all 1 -- held where it must have moved)"
grep "keysAgree" "$OUT/STORE.tsv"

# AND THE CHECK IS RUN AGAINST IT, pointed at the shadow tree's evidence and
# the shadow tree's own probe source, so nothing here reads the working tree.
echo "break: validate/v139 against the shadow tree"
EML_STORE_OUT="$OUT/STORE.tsv" EML_STORE_PROBE="$WORK/harness/resultstore/probe.praat" \
    Rscript "$EML_ROOT_REAL/validate/v139_fingerprint_store_mutations.R" 2>&1 \
    | grep -E '^FAIL|checks,' | sed 's/^/break: /'
exit 0
