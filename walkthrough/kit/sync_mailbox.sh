#!/usr/bin/env bash
# ============================================================================
# sync_mailbox.sh -- copy the live mailbox into the repository for archiving.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS. Three sessions pass notes and none can reach the others
# directly. Fable and the settlement session write files onto Ian's machine;
# neither has git. When they wrote straight into the repository's working
# tree, every delivery became an untracked file, and git refuses to overwrite
# untracked files during a merge. On 2 September that blocked syncing for
# hours: the fetch succeeded, the merge aborted, and the push reported success
# while carrying nothing.
#
# So the live drop is OUTSIDE the repository and this script copies it in.
# mailbox/ in the repository is the archive; ~/EML-mailbox/ is where mail
# actually arrives.
#
# HOW TO RUN, before building a bundle:
#
#   bash walkthrough/kit/sync_mailbox.sh
#
# It copies, never moves and never deletes: the live mailbox keeps every file,
# so a session that reads it directly still sees the full record.
# ============================================================================
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIVE="${EML_MAILBOX:-$HOME/EML-mailbox}"
DEST="$REPO/mailbox"

if [ ! -d "$LIVE" ]; then
    echo "no live mailbox at $LIVE"
    echo "  Set EML_MAILBOX to point somewhere else, or create it:"
    echo "    mkdir -p $LIVE/{to-opus,to-fable,to-sonnet}"
    exit 0
fi

copied=0
changed=()
for box in to-opus to-fable to-sonnet; do
    [ -d "$LIVE/$box" ] || continue
    mkdir -p "$DEST/$box"
    while IFS= read -r -d '' f; do
        base="$(basename "$f")"
        target="$DEST/$box/$base"
        if [ ! -f "$target" ]; then
            cp "$f" "$target"; changed+=("new     $box/$base"); copied=$((copied+1))
        elif ! cmp -s "$f" "$target"; then
            # A file already in the archive has changed on disk. Rule 2 says a
            # superseded note is never edited, so this is worth naming rather
            # than absorbing silently -- but the live copy is what the author
            # meant, so it wins.
            cp "$f" "$target"; changed+=("CHANGED $box/$base"); copied=$((copied+1))
        fi
    done < <(find "$LIVE/$box" -maxdepth 1 -type f -name '*.md' -print0)
done

if [ "$copied" -eq 0 ]; then
    echo "mailbox already current with $LIVE"
else
    printf '%s\n' "${changed[@]}"
    echo "copied $copied file(s) from $LIVE into mailbox/"
    echo "Commit them before building the bundle."
fi
