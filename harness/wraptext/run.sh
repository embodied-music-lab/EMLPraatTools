#!/bin/bash
# ---------------------------------------------------------------------------
# WRAP PROBE DRIVER. Measures what @emlWrapText's "label = value" rule costs,
# against the plain greedy wrapper, on the same corpus in the same process
# shape.
#
# NOT WIRED INTO validate/. Run it by hand:
#
#     harness/wraptext/run.sh
#
# It stages a BEFORE tree under harness/wraptext/out/before/ -- a copy of
# plugin/graphs and plugin/stats with @emlWrapText replaced by
# harness/wraptext/greedy_wrap.praat, and nothing else touched -- then runs
# harness/wraptext/probe_wrap.praat once there and once in this tree. Two
# trees rather than two procedures in one process because PART B has to reach
# the wrap through @emlDrawAnnotationBlock's own fit loop, which calls
# @emlWrapText by name.
#
# Output: harness/wraptext/out/before.tsv, after.tsv, SUMMARY.txt
# ---------------------------------------------------------------------------
set -u
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../_env.sh" || exit 1
ROOT="$EML_ROOT"
HERE="$ROOT/harness/wraptext"
OUT="$HERE/out"
WORK="$OUT/before"
PREFS="$OUT/prefs"

rm -rf "$WORK"
mkdir -p "$OUT" "$PREFS" "$WORK/plugin" "$WORK/harness/wraptext"
cp -R "$ROOT/plugin/graphs" "$ROOT/plugin/stats" "$WORK/plugin/"
cp "$HERE/probe_wrap.praat" "$WORK/harness/wraptext/"

# Splice the greedy wrapper into the staged copy. The awk deletes the shipped
# procedure from its `procedure emlWrapText:` line to its `endproc` and prints
# the fixture's own procedure in its place; the fixture's comment header is
# dropped, so the staged file gains no lines but the algorithm.
python3 - "$WORK/plugin/stats/eml-output.praat" "$HERE/greedy_wrap.praat" <<'PY'
import sys
target, fixture = sys.argv[1], sys.argv[2]
src = open(target, encoding="utf-8").read().splitlines(True)
fx  = open(fixture, encoding="utf-8").read().splitlines(True)
fx  = fx[next(i for i, l in enumerate(fx) if l.startswith("procedure emlWrapText:")):]
a = next(i for i, l in enumerate(src) if l.startswith("procedure emlWrapText:"))
b = next(i for i in range(a, len(src)) if src[i].startswith("endproc"))
open(target, "w", encoding="utf-8").writelines(src[:a] + fx + src[b + 1:])
print("staged greedy @emlWrapText at line %d" % (a + 1))
PY
[ $? -eq 0 ] || { echo "harness/wraptext/run.sh: could not stage the before tree" >&2; exit 1; }

run_probe () {   # $1 = tree root, $2 = tag, $3 = output file
    ( cd "$1/harness/wraptext" \
      && env -u DISPLAY EML_WRAP_TAG="$2" \
         "$PRAAT" $PRAAT_TRUST --pref-dir="$PREFS" --run ./probe_wrap.praat ) \
      > "$3" 2>&1
}

run_probe "$WORK" before "$OUT/before.tsv" || true
run_probe "$ROOT" after  "$OUT/after.tsv"  || true

for f in "$OUT/before.tsv" "$OUT/after.tsv"; do
    if grep -qiE "^Error|not completed|Unknown variable" "$f"; then
        echo "harness/wraptext/run.sh: probe failed, see $f" >&2
        head -20 "$f" >&2
        exit 1
    fi
done

awk -F'\t' -v OFS='' '
    FNR == NR {
        if ($2 == "A") { aMax[$3 "_" $4] = $5; aLines[$3 "_" $4] = $6; aSplit[$3 "_" $4] = $7 }
        if ($2 == "B") { bPass[$3 "_" $4 "_" $5] = $6; bRows[$3 "_" $4 "_" $5] = $7; bSplit[$3 "_" $4 "_" $5] = $10 }
        next
    }
    $2 == "A" {
        k = $3 "_" $4; nA++
        splitBefore += aSplit[k]; splitAfter += $7
        if (aSplit[k] > 0) casesWithSplit++
        d = $5 - aMax[k]
        if (d > 0) { grew++; growSum += d; growHist[d]++; if (d > growMax) growMax = d }
        if (d < 0) shrank++
        if ($6 > aLines[k]) taller++
        if ($5 > $4) overWidth++
    }
    $2 == "B" {
        k = $3 "_" $4 "_" $5; nB++
        dp = $6 - bPass[k]
        if (dp > 0) { passUp++; passUpSum += dp; if (dp > passUpMax) passUpMax = dp }
        if (dp < 0) passDown++
        if ($7 > bRows[k]) rowsUp++
        if ($7 < bRows[k]) rowsDown++
        bSplitBefore += bSplit[k]; bSplitAfter += $10
        if (bSplit[k] > 0) boxesWithSplit++
    }
    END {
        printf "PART A -- the wrap alone (%d wraps: 39 strings x widths 16..72)\n", nA
        printf "  breaks touching an \"=\"      before %d   after %d\n", splitBefore, splitAfter
        printf "  wraps carrying one          %d of %d (%.1f%%)\n", casesWithSplit, nA, 100 * casesWithSplit / nA
        printf "  longest line grew           %d of %d (%.2f%%)\n", grew, nA, 100 * grew / nA
        printf "    mean growth when it does  %.2f characters, max %d\n", (grew ? growSum / grew : 0), growMax
        printf "  longest line shrank         %d (%.2f%%)\n", shrank, 100 * shrank / nA
        printf "  line count grew             %d (%.2f%%)\n", taller, 100 * taller / nA
        printf "  any line over the width     %d  (must be 0)\n", overWidth
        printf "\nPART B -- the annotation box (%d boxes: %d blocks x 7 figure sizes)\n", nB, nB / 7
        printf "  drawn rows split at an \"=\"  before %d   after %d\n", bSplitBefore, bSplitAfter
        printf "  boxes showing one           before %d of %d (%.1f%%)\n", boxesWithSplit, nB, 100 * boxesWithSplit / nB
        printf "  fit passes grew             %d of %d (%.2f%%)  1 in %d\n", passUp, nB, 100 * passUp / nB, (passUp ? int(nB / passUp + 0.5) : 0)
        printf "    mean extra passes         %.2f, max %d\n", (passUp ? passUpSum / passUp : 0), passUpMax
        printf "  fit passes fell             %d (%.2f%%)\n", passDown, 100 * passDown / nB
        printf "  drawn rows grew             %d (%.2f%%)\n", rowsUp, 100 * rowsUp / nB
        printf "  drawn rows fell             %d (%.2f%%)\n", rowsDown, 100 * rowsDown / nB
    }
' "$OUT/before.tsv" "$OUT/after.tsv" | tee "$OUT/SUMMARY.txt"

# The growth histogram, printed separately so the summary stays one screen.
awk -F'\t' '
    FNR == NR { if ($2 == "A") m[$3 "_" $4] = $5; next }
    $2 == "A" { d = $5 - m[$3 "_" $4]; if (d > 0) h[d]++ }
    END {
        printf "\nlongest-line growth, characters:\n"
        hi = 0; for (d in h) if (d + 0 > hi) hi = d + 0
        for (d = 1; d <= hi; d++) if (d in h) printf "  +%-3d %d\n", d, h[d]
    }
' "$OUT/before.tsv" "$OUT/after.tsv" | tee -a "$OUT/SUMMARY.txt"
