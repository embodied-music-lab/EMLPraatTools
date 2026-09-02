# mailbox — where the three sessions pass notes

Three sessions work on this repository and none of them can talk to
the others directly. Ian carries mail between them. This folder is
the record of what was carried.

## The three inboxes

- `to-opus/` — for Opus, who executes and delegates. Fable's rulings,
  work orders and specs land here, and so does anything the
  settlement session needs Opus to know.
- `to-fable/` — for Fable, who owns planning, sequencing and rulings.
  Opus's memos, proposals, measured reports and questions land here.
- `to-sonnet/` — for the settlement session, which runs the
  mechanical half of the pre-run wave on Ian's machine. Rulings that
  bear on its work, corrections to its instructions, and answers to
  the questions it raises land here.

An inbox is named for its READER, never its writer. If you are
writing to Fable, you write into `to-fable/`.

## The standing procedure

`PROCEDURE.md` beside this file states how mail is checked and when a
session may act without Ian. Read it before you read anything else in
here. In short: every file carries a routing header saying who it is
for and whether a human is needed, `walkthrough/kit/mailbox_check.sh`
lists what is unread for you, and you log what you did so nothing is
read and then forgotten.

## Rules

1. Filenames carry a topic and a date: `RULING_<topic>_<date>.md`,
   `MEMO_<topic>_<date>.md`, `REPORT_<topic>_<date>.md`.
2. The newest file on a topic is the authority. Superseded files stay
   for the trail and are never edited. If you must correct one, write
   a new file that says what it supersedes.
3. Anything actionable goes in a file here, not only in chat. Chat
   relays are lost between sessions; this folder is not.
4. No session edits another session's inbox contents. You add files
   to someone's inbox; you never revise what is already in yours.
5. Notes only. A bundle or a zip stays outside the mailbox; the note
   names its path and its checksum. This folder stays small text.
6. State the measurement, not the impression. A claim called verified
   carries the command that produced it and that command's real
   output.

## Where mail actually arrives, and why this folder is an archive

Fable and the settlement session write to `_mailbox_live/` at the
repository root, which git ignores. Opus copies it into this folder and
commits it as part of preparing a push, so this folder is the archived
record rather than the working drop point.

The reason is mechanical. A file written straight into the working
tree is untracked, and git refuses to overwrite untracked files
during a merge. On 2 September that blocked every attempt to sync for
several hours: the fetch succeeded, the merge aborted, and the push
reported success while carrying nothing. Keeping the live drop
outside the repository removes that failure entirely.

The live folder sits inside the repository rather than beside it for a
practical reason: `~/EMLPraatTools` is the only folder connected to
these sessions. A directory anywhere else would be invisible until Ian
granted it separately, to each session, from his machine. An ignored
subdirectory needs no permission and every session can already reach it.

`walkthrough/kit/sync_mailbox.sh` does the copy. Run it before building
a bundle.

    ~/EMLPraatTools/_mailbox_live/to-opus/     <- write here
    ~/EMLPraatTools/mailbox/to-opus/           <- read the archive here
