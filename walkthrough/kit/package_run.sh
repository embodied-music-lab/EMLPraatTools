#!/usr/bin/env bash
# ============================================================================
# package_run.sh -- package an authoritative run for Fable's gate inspection.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS. Ian's packaging rule, set 25 August 2026: he must never be
# unsure whether a zip is complete. A deliverable zip is built from a WHOLE
# DIRECTORY, never from hand-picked files; it carries MANIFEST.txt and
# SHA256SUMS.txt; and it is rebuilt whenever any content changes. Hand-picking
# is what makes a reader wonder what was left out.
#
# Ordered by RULING_PROTOCOL_ARTIFACTS_2026-09-02.md. The input list is
# section 1 of walkthrough/kit/INSPECTION_PROTOCOL.md, which also says a
# missing input is a send-back rather than something to work around -- so this
# script REFUSES to build an incomplete package instead of warning and
# continuing.
#
# HOW TO RUN, on the machine that did the authoritative run:
#
#   bash walkthrough/kit/package_run.sh
#
# It writes ./run_package_<shortsha>/ and ./run_package_<shortsha>.zip beside
# the repository, never inside it.
# ============================================================================
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO" || exit 1

fail() { echo "REFUSED: $*" >&2; exit 1; }

# ---- provenance, which the protocol requires before anything else ----------
command -v git >/dev/null || fail "git is not on PATH"
SHA="$(git rev-parse HEAD)" || fail "not a git repository"
SHORT="${SHA:0:7}"

DIRTY="$(git status --porcelain)"
if [ -n "$DIRTY" ]; then
    echo "$DIRTY" >&2
    fail "the working tree is not clean; the protocol requires a clean-tree
        attestation at a pushed commit. Commit or revert, then re-run."
fi

if ! git merge-base --is-ancestor "$SHA" origin/main 2>/dev/null; then
    fail "HEAD is not reachable on origin/main. The protocol requires the run
        commit to be pushed. Push, fetch, then re-run."
fi

# ---- the inputs, exactly as INSPECTION_PROTOCOL section 1 lists them -------
INPUTS=(
    "audit/praat_results.tsv"
    "audit/r_results.tsv"
    "audit/VERDICT.txt"
    "walkthrough/kit/results/reconciliation.tsv"
    "walkthrough/kit/grand_ledger.tsv"
    "validate/RUN_ALL_SUMMARY.tsv"
    "planning/CLAIMS_EVIDENCE_LEDGER_2026-09-02.md"
    "walkthrough/kit/ACCEPTANCE_RULES.md"
    "walkthrough/kit/INSPECTION_PROTOCOL.md"
)

# The environment capture, whose filename the runners choose.
ENVCAP="$(find walkthrough/kit audit -maxdepth 2 -name 'environment*' -o \
          -maxdepth 2 -name 'env_capture*' 2>/dev/null | head -1)"
[ -n "$ENVCAP" ] && INPUTS+=("$ENVCAP")

MISSING=()
for f in "${INPUTS[@]}"; do [ -f "$f" ] || MISSING+=("$f"); done
if [ ${#MISSING[@]} -gt 0 ]; then
    printf '  missing: %s\n' "${MISSING[@]}" >&2
    fail "${#MISSING[@]} required input(s) absent. A missing input is a
        send-back, not something to package around. Run the kit first."
fi
[ -n "$ENVCAP" ] || fail "no environment capture found under walkthrough/kit
        or audit. The protocol lists it as a required input."

# ---- build the directory, then zip the whole of it ------------------------
OUT="${REPO%/*}/run_package_${SHORT}"
rm -rf "$OUT"; mkdir -p "$OUT"

for f in "${INPUTS[@]}"; do
    mkdir -p "$OUT/$(dirname "$f")"
    cp "$f" "$OUT/$f"
done

{
    echo "Run package for EML Stats & Graphs validation kit"
    echo
    echo "commit          : $SHA"
    echo "clean tree      : yes, asserted by package_run.sh before packaging"
    echo "reachable on    : origin/main"
    echo "packaged by     : walkthrough/kit/package_run.sh"
    echo "packaging rule  : whole directory, MANIFEST.txt + SHA256SUMS.txt"
    echo "input list from : walkthrough/kit/INSPECTION_PROTOCOL.md section 1"
    echo
    echo "Files:"
    (cd "$OUT" && find . -type f ! -name MANIFEST.txt ! -name SHA256SUMS.txt \
        | sed 's|^\./|  |' | sort)
} > "$OUT/MANIFEST.txt"

(cd "$OUT" && find . -type f ! -name SHA256SUMS.txt -print0 \
    | sort -z | xargs -0 shasum -a 256) > "$OUT/SHA256SUMS.txt" 2>/dev/null \
  || (cd "$OUT" && find . -type f ! -name SHA256SUMS.txt -print0 \
    | sort -z | xargs -0 sha256sum) > "$OUT/SHA256SUMS.txt" \
  || fail "no sha256 tool found (tried shasum and sha256sum)"

command -v zip >/dev/null || fail "zip is not on PATH"
(cd "${OUT%/*}" && rm -f "${OUT##*/}.zip" && zip -qr "${OUT##*/}.zip" "${OUT##*/}") \
    || fail "zip failed"

echo "wrote ${OUT}.zip"
echo "  commit  $SHA"
echo "  files   $(grep -c '^  ' "$OUT/MANIFEST.txt")"
echo "  sums    $(wc -l < "$OUT/SHA256SUMS.txt")"
