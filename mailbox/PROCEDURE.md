# Procedure — checking mail and acting without Ian

**One rule before anything else: `_mailbox_live/` is the mailbox.**
Sessions read and write there and nowhere else. `mailbox/`, where this
file sits, is the committed archive; Opus copies the live folder into
it before each push. Writing into `mailbox/` creates an untracked file
that blocks the next merge, which cost most of 2 September.

Three sessions work on this repository. Ian is the only human, and he
is not always at the machine. This procedure exists so that mail keeps
moving while he is away, and so that nothing is silently dropped when
it does.

## The routing header

Every file placed in an inbox starts with this block. No exceptions —
a file without it is treated as `Needs: unknown` and held.

    To:       opus | fable | sonnet
    From:     opus | fable | sonnet
    Needs:    nothing | ian | fable | opus | sonnet
    Blocking: <what stops until this is answered, or "nothing">

`Needs:` is the field that decides whether Ian is in the loop.

- `Needs: nothing` — the reader ACTS ON RECEIPT. No human is required.
  Most measured reports, status notes, and answers are this.
- `Needs: ian` — a decision only Ian makes. State the decision in one
  sentence at the top. Do the preparatory work that does not depend on
  the answer, then stop and record what you are waiting for.
- `Needs: fable` — a design, scope or sequencing question. Fable rules
  it; nobody adjudicates it in place.
- `Needs: opus` / `Needs: sonnet` — a defect or a task for that session.

`Blocking:` is what makes the difference between a queue and a
backlog. If a memo blocks nothing, say so, and it can wait. If it
blocks a named lane, that is visible to whoever reads the log.

## Check your mail

Check at three moments, not on a timer alone:

1. Before you start a unit of work.
2. When you finish one.
3. When you are about to tell Ian you are blocked — the answer may
   already be sitting in your inbox.

To see what is unread for you:

    bash walkthrough/kit/mailbox_check.sh opus

It lists files in your inbox with no log entry from you.

## Ian's local folder is the source of truth; GitHub is a backup

Ruled 2 September (`RULING_SOURCE_OF_TRUTH`), in Ian's words. Every
rule naming "the repository of record" anchors at
`~/EMLPraatTools` on his machine, not at origin.

Nobody waits on origin. A stale origin is the normal state of a
backup. A session blocked "until Ian pushes" is blocked on nothing:
take current state from his disk and proceed. Where sync
instructions offer a pull or a bundle, the bundle is the primary
route and a successful pull is a coincidence.

If origin and local disagree, local wins and origin is brought up to
date when Ian chooses. Origin is never a tiebreaker.

Pushing stays Ian's alone and is a backup operation. One thing still
depends on it, deliberately: the authoritative run happens at a
commit that has been backed up to GitHub first. That is
tamper-evidence — an off-machine copy of the exact commit the paper's
numbers anchor to — not GitHub having authority. One backup, once,
before the run. Nothing else in any lane waits on a push.

## Verify a delivery at its destination

A file has LANDED when a listing of the destination shows it, or when a
commit reachable from Ian's `main` contains it. Not when your write
completed locally.

    Wrong:  "RENAME_SCOPE.tsv landed at the repository root."
            (Committed in my container. Never delivered.)
    Right:  deliver, then list the destination, then say it landed.

Ruled 2 September (`RULING_LANDED_MEANS_LANDED`) after exactly that
claim was made and the settlement session disproved it four ways. It
is the same rule as "a claim carries its artifact", with a
preposition: the artifact for a delivery claim is a listing of the
place it was delivered TO.

This applies to every session. Your container, your clone and Ian's
disk are three different places, and only the third is where the
other sessions read.

## Record what you did

After reading a file, append one line to your log. This is what stops
two sessions doing the same job, and what stops a memo being read and
forgotten.

    bash walkthrough/kit/mailbox_check.sh opus --acted FILENAME "what you did"

The log lives in `_mailbox_live/_log/<session>.log`, one line per
entry: timestamp, filename, and what you did about it. It is
append-only. Never edit a line; add a new one.

## Acting without Ian

You may act on receipt when ALL of these hold:

- the file's `Needs:` is `nothing`, or names YOU;
- a committed ruling authorizes what you are about to do, and you can
  name the file;
- the work is verifiable — a check, a measurement, or a test can show
  it was done right;
- it does not edit a directory another session holds.

If any of those fails, do the part that passes and write down the
rest. Doing half a task and saying which half is always better than
doing all of it on an assumption.

## What never happens without Ian

- Pushing to the remote. He is the only one who can, and that is
  deliberate.
- A decision his ruling reserved to him.
- Deleting anything from his machine.
- Starting a long or expensive run to answer a question a short one
  would answer.

## When you disagree with a memo

Write a new file saying so, with your measurement. Never edit the one
you disagree with. The newest file on a topic is the authority, and
the trail is the point.
