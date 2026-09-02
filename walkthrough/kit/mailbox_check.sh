#!/usr/bin/env bash
# ============================================================================
# mailbox_check.sh -- what is unread in your inbox, and recording what you did.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Three sessions pass notes and none can reach the others directly. Ian is the
# only human and is not always at the machine. This script is how a session
# sees what has arrived for it and records what it did, so that mail keeps
# moving while he is away and nothing is read and then forgotten.
#
# The convention it serves is mailbox/PROCEDURE.md. Read that first.
#
#   bash walkthrough/kit/mailbox_check.sh opus
#   bash walkthrough/kit/mailbox_check.sh opus --acted MEMO_X_2026-09-02.md "filed the 53 exemptions"
#
# Unread means: a file in your inbox with no line naming it in your log.
# ============================================================================
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIVE="${EML_MAILBOX:-$REPO/_mailbox_live}"

WHO="${1:-}"
case "$WHO" in
    opus|fable|sonnet) ;;
    *) echo "usage: mailbox_check.sh <opus|fable|sonnet> [--acted FILE \"what you did\"]" >&2
       exit 2 ;;
esac

BOX="$LIVE/to-$WHO"
LOGDIR="$LIVE/_log"
LOG="$LOGDIR/$WHO.log"
mkdir -p "$LOGDIR"
touch "$LOG"

if [ "${2:-}" = "--acted" ]; then
    FILE="${3:-}"; WHAT="${4:-}"
    [ -n "$FILE" ] && [ -n "$WHAT" ] || {
        echo "--acted needs a filename and a description" >&2; exit 2; }
    # Append only. A line is never edited; a correction is a new line.
    printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$FILE" "$WHAT" >> "$LOG"
    echo "logged: $FILE"
    exit 0
fi

[ -d "$BOX" ] || { echo "no inbox at $BOX"; exit 0; }

unread=0
while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    [ "$base" = "README.md" ] && continue
    if ! cut -f2 "$LOG" | grep -qxF "$base"; then
        unread=$((unread+1))
        needs="$(grep -m1 -i '^Needs:' "$f" | sed 's/^[Nn]eeds:[[:space:]]*//')"
        block="$(grep -m1 -i '^Blocking:' "$f" | sed 's/^[Bb]locking:[[:space:]]*//')"
        printf '\n  %s\n' "$base"
        printf '    needs    : %s\n' "${needs:-UNKNOWN -- no routing header, treat as held}"
        printf '    blocking : %s\n' "${block:-unstated}"
        printf '    first line: %s\n' "$(grep -m1 '^#' "$f" | cut -c1-90)"
    fi
done < <(find "$BOX" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)

if [ "$unread" -eq 0 ]; then
    echo "nothing unread in to-$WHO"
else
    printf '\n  %d unread. Act on receipt where Needs is "nothing" or names you.\n' "$unread"
    printf '  Record each one:\n'
    printf '    bash walkthrough/kit/mailbox_check.sh %s --acted <file> "<what you did>"\n' "$WHO"
fi
