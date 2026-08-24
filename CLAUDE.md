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

**WHEN A BUNDLE WILL NOT TRANSFER, CHAIN IT FROM THE LAST ONE DELIVERED.**
The delivery path is an upload from this container followed by a write to
Ian's disk, and the upload is the half that fails. On 24 August every
attempt at 1.1 MB timed out while 2.5 KB went through on the first try.
The size grows because the bundle is built from GitHub's head, and a
stalled push makes that delta wider every commit -- re-driven harness
evidence is what pushes it over.

So when a bundle fails to transfer, rebuild it from the SHA of the last
bundle that reached his disk (`git bundle create <path> ^<last-delivered-sha>
main`) and deliver that. It applies in sequence after the one before it, so
the chain stays valid and each link stays small. Say plainly which order
they apply in.

TRY THE FULL BUNDLE FIRST, EVERY TIME. The ceiling may be temporary or may
not exist at all -- it is inferred from timeouts, not from anything the
service states. Attempting the full one and falling back is how that
assumption keeps getting tested instead of hardening into a fact. If a
single commit ever carries too much evidence for even a chained delta,
split the file into sub-megabyte parts and have Ian reassemble with one
`cat` -- `eml-part-aa` through `-ad` on his disk are from an earlier
occasion of exactly that.

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

**NAME THE MODEL ON EVERY AGENT. OMITTING IT IS THE DEFECT.** An agent with
no model named inherits the session model, which is the expensive one, so
doing nothing is the costly choice and it is invisible in the script. On
24 August roughly twenty agents ran and two named a model; a day's work took
a large share of a weekly plan.

The test is one question: DOES A MISTAKE HERE ANNOUNCE ITSELF?

- Loud, so `model: "sonnet"` — driving a harness, running checks, mechanical
  edits a check will catch, writing a check against a pattern that already
  exists, measuring, reporting.
- Silent, so the default model — adversarial passes, design where a wrong
  choice looks right, and the single end-of-batch verification.

Drop `effort` from high to medium on mechanical work. State the split in chat
when launching a batch, so it can be vetoed before the tokens are spent.

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

## Writing Praat in this repository

How Praat is written here is governed by the PraatGen knowledge base, which is
not in this repo. Fetch it read-only when you need it; never edit it:

    git clone --depth 1 https://github.com/embodied-music-lab/PraatGen.git /tmp/pg

**Where PraatGen and anything here disagree, PraatGen governs** — except two
settled carve-outs. PraatGen forbids `include` in *generated* scripts, which must
stand alone; this plugin is the tree those includes are internal to, so the
barrel includes stay. And our floor is `emlMinPraatVersion = 6630`, refusing at
load, where PraatGen's 6.4.39 warn-and-continue is for generated scripts. Two
artefacts, two contracts — do not lower ours. The rest bites silently:

- Read a procedure's `Outputs:` header before consuming its return; the name
  differs from the parameter. `@emlGenerateUniquePath` takes `.path$`, returns
  `.result$` — reading `.path$` back compiles and defeats the collision guard.
  Outputs survive only until that procedure runs again: copy them on the next line.
- Inside a procedure an undotted variable is the main-script global, for read
  **and write**. Pass inputs as dotted parameters; never assign undotted.
- `'`-interpolation of variable names works in procedure bodies only; main body
  uses `var[i]` / `var#[i]`. `$` goes before the bracket (`v$[i]`) and after a
  full interpolated name (`v'.i'$`). `e`, `pi`, `undefined` are constants.
- Commands are statements, not expressions: `x = Get total duration`, then use x.
  `Unknown symbol «Get» in formula` always means exactly this.
- Dialog labels carry letters, digits and spaces only before the parenthetical
  (`docs/RULING_DIALOG_LABELS_v3.md`). `left Y-limits` binds a name no script can
  write; the read parses as subtraction and yields a plausible wrong number.
- Form variables are globals nothing can unset. Read a page's fields into
  page-scoped variables between its `endPause` and the next dialog, never later.
- Every string literal that can reach a file must be ASCII. One non-ASCII
  character makes Praat write the whole file UTF-16BE. Use `@emlAsciiFold`.
- `%`, `#`, `^`, `_` are style toggles in drawn text. Variable-derived display
  text goes through `@emlSanitizeLabel`; literals need only reading.
- Set `Font size:` once per panel, before `Select inner viewport:`; use
  `Text special:` for any other size — it takes its own and leaves state alone.
- Vectorize: `Formula: ~self ...`, `List values in all frames`, `Get all numbers
  in column`. A per-element `Get`/`Set` loop is 100-400x slower, not untidy.
- DRY here: state the canon once in a procedure **and** add a text check that the
  copies agree (`v105` is the model). A procedure records a rule, never enforces it.
- Two PraatGen rules are knowingly unmet, pending Ian's adjudication: leading
  `;` comments (~4,900 of them) and `+=`. Do not sweep either.
