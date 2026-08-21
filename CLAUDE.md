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
in chat which bundle is the one to push.

**NEVER DELETE A BUNDLE FROM IAN'S DISK, AND NEVER TELL HIM TO.** Ever. The
bundles in `~/EMLPraatTools/` are the backup chain -- the only durable copy
of any commit GitHub does not yet have, and the only thing that survives a
container rollback. A newer bundle usually CONTAINS the commits of the older
ones, which makes deleting the old ones look tidy; it is not tidy, it is
removing every earlier restore point in favour of one. They cost kilobytes.
They stay.

The word "supersedes" caused this: it reads as "the old one is now rubbish".
Say instead which bundle to push, and leave the rest alone.

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

## Fanning work out to agents

**Default to agents for basically everything.** Independent pieces of work
run in parallel, in their own context, and only their conclusions come back.
A sweep that would take an hour of one context takes minutes of it this way.
Reserve doing it yourself for the case where the work is genuinely one
thread.

**ONE VERIFICATION PASS, AT THE END, BY ONE AGENT.** Builders build; they do
not each run the suite. Three agents fixing three unrelated checks will
otherwise each run most of the validators, which is the same work three
times, and none of them sees the interactions between the three changes --
which is the thing that actually needs checking. So: fan out the builders,
then send one agent over the whole tree once.

Two corollaries learned the hard way:

- A builder agent must be told what the OTHER agents are touching, or it
  reports their in-flight edits as unexplained churn in its own diff.
- Before changing anything, an agent states the check's result as it found
  it. Without that baseline, a failure that was already there gets
  attributed to the change in front of it -- which cost most of an evening
  on 20 August, when good work was reverted because a harness that had been
  broken for weeks went red at the wrong moment.

## Run the checks that read what you touched, before committing

Not after. The suite knows which files each check reads; a check that
describes a file you edited is a check you have to run before you believe
the edit. Three defects shipped on 20 August for want of this: a comment
that tripped the release gate's history rule, a comma that stopped the
whole suite from parsing, and a renamed export column the result writer's
vocabulary refused -- which killed every repeated-measures and Friedman
export, and whose error message says, in the message itself, to update the
vocabulary in the same commit.

## Standing list

`docs/OPEN_ITEMS.md` holds every open defect and every ruled-but-unbuilt
item. Read it at the start of a session; update it when something opens,
changes, or closes. It exists because session context is lost and this
file is not.
