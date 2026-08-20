# Working rules for this repo

## Delivering commits to Ian

This container cannot push to GitHub. Ian pushes. Therefore:

**Every time work is committed, write the bundle to Ian's computer.**
Not just into the chat — onto his disk, at `~/EMLPraatTools/`, using the
device bridge (`SendUserFile` to get a file_uuid, then
`mcp__remote-devices__device_commit_files`). This is a standing
instruction, not a per-occasion request. A bundle offered only as a chat
attachment does not count as delivered.

Build it incrementally from the commit currently on GitHub main
(`git bundle create <path> ^<github-main-sha> main`) — a full-history
bundle is ~90 MB and will not transfer.

Name it for what it carries, e.g. `eml-guardfix.bundle`, and say plainly
in chat which earlier bundle it supersedes.

**ALWAYS paste the five push commands with the bundle, every single time.**
Not "same commands as before" — the actual block, with the actual filename.
Ian should never have to ask for it or scroll back for it:

```
cd ~/EMLPraatTools
git bundle verify <name>.bundle
git fetch <name>.bundle main
git log --oneline HEAD..FETCH_HEAD
git merge --ff-only FETCH_HEAD
git push origin main
```

## When the container rolls back

This container is reclaimed and restored from older snapshots without
warning; it has happened four times in one day. GitHub is the only durable
copy of the work.

A bundle is a DELTA: it carries commits from a container that has them to
a GitHub that does not. After a rollback the container has FEWER commits
than GitHub, so it has nothing to send. A bundle built then is empty at
best and anchored to an older HEAD at worst. Never build one from a
rolled-back tree.

### Establish that it is a rollback before treating it as one

`git reset --hard` destroys uncommitted work silently, so it is not the
first move. In order:

1. `git status --porcelain`. If anything is uncommitted, COMMIT IT FIRST,
   on the branch as it stands. It may be the only copy of a finished
   drive. Never reset over it, never stash it and move on — a stash in
   this container is as temporary as the container.
2. `git fetch origin main`.
3. Ask whether HEAD is an ancestor of origin/main:
   `git merge-base --is-ancestor HEAD origin/main`. True means the
   container is simply behind — a rollback, or a push made elsewhere —
   and fast-forwarding is safe and loses nothing.
4. If it is NOT an ancestor, the histories have diverged and something
   here is not on GitHub. Do not reset. Say so, and bundle the divergent
   commits, because in that case the container IS ahead and the bundle is
   exactly right.
5. After moving, spot-check that the CONTENT is present — grep for
   something the work added — not just that the commit ids look right.
6. Recover anything GitHub still lacks from the bundle already on Ian's
   disk. That bundle is the only remaining copy; do not delete it.

### The corollary that prevents most of this

Commit and bundle after every unit of work, not in batches. Anything
uncommitted when a rollback lands is gone, and "I showed him the result"
is not the same as "the result is saved".

## Scope of work units

One narrow stated scope per unit of work. Do not launch long drives that
re-run everything; verify what the change touched and re-run the rest
separately. Long jobs block Ian from interacting and correlate with
things getting dropped.

## Standing list

`docs/OPEN_ITEMS.md` holds every open defect and every ruled-but-unbuilt
item. Read it at the start of a session; update it when something opens,
changes, or closes. It exists because session context is lost and this
file is not.
