#!/bin/bash
# Fails if the committed golden results file no longer matches the sha256 its
# manifest records. Run from anywhere; paths resolve to this script's folder.
d="$(cd "$(dirname "$0")" && pwd)"
want=$(grep -oE 'sha256: [0-9a-f]{64}' "$d/golden_manifest.txt" | awk '{print $2}')
got=$(sha256sum "$d/golden_praat_results.tsv" | cut -d' ' -f1)
[ "$want" = "$got" ] && { echo "golden checksum OK ($got)"; exit 0; } || { echo "GOLDEN CHECKSUM MISMATCH: manifest=$want file=$got"; exit 1; }
