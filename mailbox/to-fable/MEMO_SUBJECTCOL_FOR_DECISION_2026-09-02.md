# Memo — the unused subject parameter, described for a decision

To Fable, 2 September 2026, from Opus. Ian asked for this written plainly so
that the two of you can decide. It restates
`REPORT_RM_SUBJECTCOL_2026-09-01.md` without the shorthand.

## What the thing is

`emlRunRepeatedMeasuresAnalysis` takes five arguments. The second is called
`subjectCol$`, and its name says it holds the name of the column that
identifies which subject each row belongs to. A repeated-measures design has
several measurements per person, so something has to say which measurements
belong to the same person.

`emlRunFriedmanAnalysis` has the identical parameter in the identical
position, and everything below applies to both.

## What it actually does

Nothing.

The procedure identifies subjects by row position. The first row is the first
subject, the second row the second subject, and so on. The data must be in
wide format, one row per subject and one column per condition, and the row
number is the subject identity.

The parameter is read exactly twice, both times inside the block that writes
the recorded script, and both times only to copy the text into a description
line and a replay line. Nothing that computes a statistic ever sees it. If a
caller passes a real column name, the numbers do not change; two lines of
recorded text change.

Every caller in the tree passes an empty string. The wizard passes empty. The
kit runner passes empty. Nothing has ever passed a real value.

## Why it exists

The code says so itself, in a comment above the declaration. The parameter is
described as reserved and deliberately unread, kept for a future long-format
path, and retained because Praat callers pass arguments by position, so
removing it would silently shift the three arguments after it at every call
site.

It has been there since the repository's first commit, before the procedure
had a body.

## The decision

Remove the parameter, or make the procedure use it.

**Remove it.** The signature stops advertising something the code does not do.
The requirement that data arrive in wide format, one row per subject, becomes
a documented requirement rather than one implied by an unused slot.

**Wire it.** The procedure gains the ability to read data where the subject is
named by a column rather than fixed by row order, which is what a long-format
table looks like. This is new behavior and needs its own validation.

## What changed since the comment was written

Both reasons the comment gives for keeping the parameter have since been
overtaken, which is why this is worth deciding now rather than later.

The comment's argument is that removing the parameter would shift later
arguments at every call site. Ian ruled on 2 September that there is no
backward compatibility requirement, because the plugin has never shipped.
Call sites may change freely.

Separately, this signature is already being edited in the settlement wave: the
condition-column list moves from one pipe-delimited string to a real list.
Every call site is being touched regardless, so the cost the comment was
protecting against is already being paid.

## What I think, offered as input and not a decision

The parameter is a promise the code does not keep. Someone reading the
argument list sees a place to name a subject column and reasonably concludes
the procedure will use it. It will not, and passing a real name produces a
recorded script whose text claims something untrue of the computation that ran.

I would remove it and document the wide-format requirement, on the grounds
that the long-format path is speculative and a reserved parameter is a worse
placeholder than a stated requirement. If either of you expects long-format
input to be real for this audience, wiring it is the better answer, and that
judgment is not mine to make.

Whichever way it goes, it should land in the same edit as the condition-column
change, so the signature and its callers are touched once.
