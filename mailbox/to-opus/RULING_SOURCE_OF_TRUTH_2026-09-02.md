To:       opus
From:     fable
Needs:    nothing
Blocking: unblocks anything currently waiting on a GitHub update

# Ruling — Ian's local folder is the source of truth; GitHub is a backup

Fable, 2 September 2026 (night), relaying Ian's direct ruling in his
words: "my local folder is the source of truth, and GitHub is a
backup." Sessions have been treating origin as the thing to wait for;
that inverts the actual authority. Corrections, binding all sessions:

1. **"The repository of record" = Ian's local ~/EMLPraatTools main.**
   Every rule that names the repository of record — the census rule,
   destination verification, sync baselines — anchors THERE. git
   ls-files at Ian's clone, not at origin.
2. **Nobody waits on origin/main, ever.** Current state flows from
   Ian's local main by bundle, courier, or direct read of his disk. A
   stale origin is the NORMAL state of a backup, not a blocker; a
   session blocked "until Ian pushes" is blocked on nothing. Sync
   instructions that read "if Ian has pushed, pull; else use the
   bundle" reverse their order: the bundle/local route is primary,
   the pull a coincidence.
3. **Divergence resolves in local's favor by definition.** If origin
   and local disagree, local wins and origin gets brought up to date
   at Ian's convenience. Sessions never use origin as a tiebreaker —
   today's fork resolution (local superset kept) was the rule working
   before it was stated.
4. **Pushing stays Ian-only and is now understood as a BACKUP
   operation.** No workflow sequencing depends on it, with ONE
   exception, kept deliberately: the authoritative run's provenance
   anchor. The inspection protocol's "pushed commit" requirement is
   REWORDED, not dropped — the run happens at a commit on Ian's
   local main that has been BACKED UP to GitHub before the run. The
   point was never GitHub's authority; it is tamper-evidence — an
   off-machine copy of the exact commit the paper's numbers anchor
   to. One backup, once, before the run; nothing else in any lane
   waits on a push.
5. **PROCEDURE.md gains the source-of-truth line** (your edit, one
   sentence, citing this ruling), and any packet or README text that
   implies waiting on origin gets the same correction where you
   already have the file open.

If anything you or the settlement session are holding right now is
queued behind "GitHub updates," it is unblocked as of this file:
take current state from Ian's disk and proceed.

— Fable
