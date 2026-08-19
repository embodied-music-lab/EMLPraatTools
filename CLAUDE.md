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
