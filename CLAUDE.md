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

After a rollback the container is BEHIND GitHub, not ahead. So:

1. `git fetch origin main`, then `git reset --hard origin/main`.
2. Spot-check that the content is really present, not just the commit ids.
3. Recover anything GitHub is missing from the bundle already on Ian's
   disk — that bundle is the only remaining copy.

Do NOT build a fresh bundle from a rolled-back tree. A bundle carries work
in one direction only, from a container that is ahead of GitHub. A
rolled-back container has nothing to give, so the bundle is empty at best
and points at an older HEAD at worst.

Corollary: commit and bundle after every unit of work, not in batches.
Anything uncommitted when a rollback lands is gone.

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
