# Scoped ask for PraatGen — plugin-manager bootstrap installer, REV 2

Revision 2 after review of draft 1. Draft 1's generated payload
content, manifest counts, escaping, and overall structure were
verified correct and carry forward. This revision changes five
things: the already-installed gate (a broken install must not dead-
end), the UTF-8 preference line (removed), the file header
(attribution block removed), naming consistency, and the floor-
version constants. Sections below are the complete authority;
regenerate the whole script from this text.

Every design decision below is made. The task is mechanical
generation of one Praat script to this specification. Where the
specification is ambiguous or impossible as written, STOP and list
the questions at the top of your reply — do not improvise a design
choice.

## What to produce

One file, `eml-plugin-manager-install.praat`: a self-extracting
installer. When a user opens it in Praat and clicks Run, it creates
`plugin_EMLPluginManager` inside Praat's preferences folder and
writes the embedded payload files into it. Nothing else.

## Hard constraints

1. File writes and folder creation ONLY. No system commands, no
   network, no deletions, no renames of existing folders. (This
   keeps the Praat 7 trust prompt to the file-write class and makes
   the script inert beyond its one job.)
2. Praat 6.6.30 is the floor; the script must also run unmodified on
   Praat 7.x. Modern script syntax throughout; no legacy
   space-separated argument strings. Use the modern folder-function
   names (`createFolder`, `folderExists`) consistently — never mix
   generations (`createDirectory` is out).
3. Do NOT set text writing preferences: preference commands persist
   in the user's own settings, which breaks the "nothing else is
   touched" promise. All payload content is ASCII-only, so output
   bytes are encoding-independent.
4. Nothing hardcoded twice: the plugin folder name, version string,
   file count, and all user-facing message texts are each defined
   once in one place and read from there. The floor version exists
   as ONE fact: define the numeric form and derive the display
   label from it (or, if derivation is awkward, add a mechanical
   startup check that the two constants agree and stops the script
   if they do not).
5. No comments about history, defects, or this specification inside
   the generated script. Comments describe current behavior only.
   The file header states the script's purpose and nothing else: no
   attribution block, no authorship placeholders, no research-
   disclosure boilerplate. The author of record for shipped
   artifacts in this project is Ian Howell; disclosure language
   lives in the project's paper and repository, not in shipped
   files.

## Structure (fixed)

Top to bottom:

1. A constants section: procedures or variables defining the folder
   name (`plugin_EMLPluginManager`), the payload version (`0.1.0`),
   the payload manifest (each file's relative path and its line
   count), and every message string.
2. Work procedures, each independently callable so a test driver can
   run them without the dialog:
   - `emlpmB_versionOk` — parses `praatVersion` and refuses below
     the floor.
   - `emlpmB_alreadyInstalled` — reports whether a COMPLETE install
     exists: true only when the target folder exists AND contains a
     `VERSION` file. `VERSION` is the completion marker; a folder
     without it is an incomplete install and is rewritten in place
     (every writer opens with `writeFileLine`, so overwriting is
     clean and no deletion is ever needed).
   - `emlpmB_writePayload` — creates the folder if absent and calls
     the writer procedures in this order: `setup.praat`,
     `about.praat`, `README.txt`. It does NOT write `VERSION`.
   - `emlpmB_verify` — re-reads the written files and checks line
     counts against the manifest; any mismatch is a named failure
     identifying the file. Called twice (see main sequence).
   - `emlpmB_writeVersion` — writes `VERSION` alone. It runs ONLY
     after the first verify passes, so the completion marker can
     never exist beside a broken payload.
   - One writer procedure per payload file, each consisting of
     `writeFileLine`/`appendFileLine` calls, one per line of
     content, with double quotes in content escaped by doubling.
3. The main sequence: confirmation dialog → version check →
   already-installed check (complete installs only) → write the
   three payload files → verify them → write `VERSION` → final
   verify of all four → final message.

## Behavior (fixed)

- Confirmation dialog before anything is written. Text, verbatim:
  title "Install EML Plugin Manager"; body "This installs the EML
  Plugin Manager into your Praat preferences folder. Nothing else
  on your computer is touched. Praat may ask for permission to
  write files; choose \"Approve for this session\"."; buttons
  Cancel / Install.
- Praat too old: stop with, verbatim: "This installer needs Praat
  6.6.30 or newer. You have <version>. Please update Praat from
  praat.org and run this installer again."
- Already installed (folder exists AND `VERSION` present): stop
  WITHOUT writing, with, verbatim: "EML Plugin Manager is already
  installed. To update or repair it, use the Plugin manager menu
  inside Praat." A folder WITHOUT `VERSION` is an incomplete
  install: proceed and rewrite it in place, no extra dialog.
- Success: final message, verbatim: "Installed. Restart Praat to
  activate the Plugin manager menu." One message total, at the end.
- Any failure in write or verify: one message naming the step and
  the file, and instructing the user that nothing needs to be
  cleaned up manually.

## Payload for this draft (placeholder — will be replaced by a
generator later; build the pattern, not the product)

Three files:

1. `setup.praat` — registers one menu command under Praat's
   Objects-window menu: "EML Plugin Manager: About", which prints
   to the Info window: the manager name, the payload version read
   from the VERSION file, and the line "The full manager arrives in
   a later build." Use the standard plugin menu-registration syntax.
2. `VERSION` — exactly one line: `0.1.0`.
3. `README.txt` — three lines: what this folder is, that it was
   installed by the bootstrap installer, and that it can be managed
   from the Plugin manager menu in a later build.

## Acceptance (the generated script is done when)

- On a machine at or above the floor with no prior install: one run
  creates the folder with exactly the three files, verify passes,
  and after a Praat restart the About command appears and prints
  the three lines.
- A second run stops at the already-installed message and writes
  nothing.
- With the folder present but `VERSION` deleted (a simulated
  broken install), a rerun rewrites everything and finishes green.
- On a Praat below the floor, it stops at the version message and
  writes nothing.
- The work procedures run headlessly from a driver script without
  the confirmation dialog, so the harness can exercise them.
- Confirmed during the drive, on 6.6.30 and 7.x: `folderExists` and
  `readLinesFromFile$#` exist at the floor; `praatVersion` reports
  6.6.30 in the numeric form the version gate compares against; and
  the final `exitScript` message does not present as an error-styled
  dialog (if it does, report it — the final-message mechanism then
  changes by ruling, not by improvisation).

## Explicitly out of scope for this draft

Network access, catalog reading, downloading, checksums, unpacking,
updating or removing anything, settings files, additional menu
commands, Windows-vs-mac-vs-Linux branches (none are needed — there
are no shell commands), and any interaction with other plugins.
