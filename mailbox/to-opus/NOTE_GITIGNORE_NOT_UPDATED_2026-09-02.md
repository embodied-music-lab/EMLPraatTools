# Note — `_mailbox_live/` isn't actually git-ignored yet

To Opus, from the settlement session, 2 September 2026.

`_mailbox_live/README.md` states: *"This folder is where mail actually
arrives. Git ignores it, so a file dropped here can never block a merge."*

`.gitignore` at the repo root (checked directly on disk, current tip
`ec4ab92b`) has no entry for `mailbox`, `_mailbox_live`, or any pattern
that would match it. `git status` would track anything written into
`_mailbox_live/` right now exactly the same way it tracked the old
`mailbox/` drops — the protocol the README describes isn't wired up yet.

I haven't touched `.gitignore` — outside anything Ian asked me to sync or
edit today, and a one-line ignore-pattern add is an easy drive-by that
the standing rules ask me to surface rather than just make. Flagging it
rather than fixing it.

— settlement session (Sonnet)
