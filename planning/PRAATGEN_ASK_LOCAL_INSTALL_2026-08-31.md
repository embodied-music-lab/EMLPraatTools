# Scoped ask for PraatGen — install a plugin from disk, REV 4

Revision after review of the first generated draft. Carried forward
as correct: the overall structure, the platform command matrix, the
staging rails, the setup.praat scanner including its
continuation-line joining and separator-row exclusion, and the
archive timestamping. Changed by this revision: the selection
dialog's variable scheme (the draft's read-back cannot work), the
search's silent 200-folder cap (forbidden), placement semantics
(always copy, never move), archive-failure handling, and the two
standing rulings on headers and preference mutation. Regenerate
from this text.

Every design decision below is made. Generate one Praat script to
this specification. Where the specification is ambiguous or
impossible as written, STOP and list questions at the top of your
reply — do not improvise.

## What to produce

One file, `eml-install-plugin-from-disk.praat`: a standalone script
that installs an already-downloaded plugin into Praat's preferences
folder. The input may be a `.zip`, a `.tar.gz`/`.tgz`, or an
already-unpacked folder. The plugin folder inside the input may sit
at any depth, but its name always starts with `plugin_`. The script
is later mounted as a manager menu command; build it now as work
procedures plus a main sequence, every procedure independently
callable from a test driver.

## Hard constraints

1. Praat 6.6.30 floor; runs unmodified on 7.x. Modern syntax only.
2. All content ASCII. No comments about history or this spec. The
   file header states the script's purpose and nothing else — no
   attribution block, no authorship placeholders, no disclosure
   boilerplate (author of record for this project's shipped
   artifacts is Ian Howell; disclosure lives in the paper and
   repository). Do NOT set text writing preferences or any other
   Praat preference: preference commands persist in the user's own
   settings.
2a. No script variable may share the name of a built-in function it
   or any procedure uses (the draft's `folderNames$#` variable
   shadowing the `folderNames$#` function is the example). Rename
   such variables.
3. Nothing hardcoded twice: folder names, the staging and archive
   locations, extension lists, command templates, and every message
   string are each defined once.
4. Shell commands are allowed (this feature is why), but ONLY these,
   with every path in double quotes, via `runSystem_nocheck`:
   unpack (`tar`, and `unzip` on Linux for zip), move (`mv`, or
   `move` on Windows), and staging cleanup (`rm -rf` / `rmdir /s /q`
   applied ONLY to the fixed staging path). No other shell use. No
   `curl`. Never delete anything outside the staging path.
5. NEVER parse shell output. After every shell step, verify the
   expected filesystem state (folder exists, files present) and fail
   with a named message if it does not hold.
6. Deletion rails: the only path ever deleted is the staging folder,
   whose name is a constant; the deletion command is built from that
   constant, never from user input.

## Fixed locations

- Staging: `preferencesDirectory$ + "/eml_pm_staging"` — created
  fresh at start (if it exists from a crashed run, remove it first
  under rail 6), removed at the end of every run, success or
  failure.
- Archive: `preferencesDirectory$ + "/eml_pm_archive"` — created if
  absent; replaced plugins are MOVED here, never deleted, into
  `<foldername>-<stamp>` where `<stamp>` is yyyymmdd-hhmmss built
  from `date#()` components, zero-padded.

## Platform command matrix (fixed)

- macOS: `tar -xf` for both zip and tar.gz; `mv`; `rm -rf`.
- Windows: `tar -xf` for both (bsdtar ships with Windows 10+);
  `move`; `rmdir /s /q`.
- Linux: `tar -xzf` for tar.gz; `unzip -q` for zip; `mv`; `rm -rf`.
  If unzip produced nothing, the failure message states that the
  `unzip` tool may not be installed on this system and names the
  file that could not be unpacked.

Use Praat's `macintosh` / `windows` / `unix` predefined variables to
select, in exactly the procedures that run commands and nowhere
else.

## Behavior (fixed)

1. Dialog 1 — what to install: choice between "A compressed file
   (.zip or .tar.gz)" and "A folder that is already unpacked", plus
   a Cancel.
2. Picker: `chooseReadFile$` for the file path; the folder chooser
   for the folder path. Compressed files with any extension other
   than `.zip`, `.tar.gz`, or `.tgz` are refused by name.
3. If compressed: unpack into a fresh subfolder of staging, then
   search. If a folder: search it directly (if the chosen folder's
   own name starts with `plugin_`, it is itself the candidate).
4. Search rule: COMPLETE recursive walk of the whole tree for
   folders whose name starts with `plugin_` — collect every match,
   at any depth, including matches nested inside other matches. Do
   not stop at the first or topmost find. EXCLUDE the `__MACOSX`
   subtree entirely (macOS zips shadow every path there, including
   fake `plugin_` folders). The walk is UNBOUNDED: no fixed queue
   or array cap may limit it (the draft's 200-entry queue silently
   dropped subtrees — forbidden). Use growable storage or a
   file-backed queue; if any internal limit is ever reached
   despite this, the script stops with a named error — it never
   silently returns a partial result.
   - Zero matches: refuse — "No plugin folder (a folder whose name
     starts with plugin_) was found inside <name>."
   - One or more matches: the selection dialog of step 5.
5. Selection dialog: for each found folder, a `comment:` line
   carrying the full description (folder name, annotations, and its
   relative path inside the source so nesting is visible), followed
   by `boolean: "Install <n>", <default>` where <n> is the folder's
   index. Praat derives the variables deterministically as
   `install_1` … `install_n`; read selections back by constructing
   those names — NEVER derive variable names from folder names or
   annotated labels (the draft's read-back was unreachable). The
   description `comment:` is the row's identity; the checkbox label
   stays short.
   After OK: if two or more SELECTED folders share the same folder
   name, refuse the whole operation naming that folder — two
   same-named folders cannot both exist in the preferences
   directory. Nothing installs until the user unchecks one.
   Content of the description line: Default state and
   annotations follow the documented plugin contract — a plugin is
   a `plugin_` folder with a `setup.praat` that Praat executes at
   startup:
   - `setup.praat` present at the folder's top level: CHECKED by
     default. Scan it (string matching only, never execution) for
     lines beginning "Add menu command" or "Add action command"
     and annotate "(adds N commands)"; if none, "(registers no
     commands)".
   - No `setup.praat`: UNCHECKED by default, annotated "(no
     setup.praat — not a functioning plugin as-is)". Listed and
     selectable, never refused.
   - Additionally, when a same-named folder is already installed:
     "(already installed — replacing keeps the current version in
     the archive folder)".
   Buttons: Cancel / Install selected. Zero boxes checked at OK is
   treated as Cancel.
6. Collision handling per selected folder whose name already exists
   in `preferencesDirectory$`: move the existing folder to the
   archive location (rail: move, never delete) and VERIFY the move
   (archive destination exists, original gone). If the archive
   move fails, that plugin is NOT placed; its summary line reads
   FAILED with the reason, and the loop continues with the others.
   The annotation in step 5 is the user's notice; no additional
   dialog.
7. Placement, looped over every selected folder: ALWAYS A COPY
   into `preferencesDirectory$` (`cp -R` on mac/Linux,
   `xcopy /E /I /Q` on Windows), whether the source is the staging
   area or the user's chosen folder — never a move. Copying is
   what makes selecting both a parent plugin and a plugin nested
   inside it work: each lands independently and neither mutates
   the other's source. The user's original folder is never touched
   or moved; staging cleanup removes all leftovers. The complete
   shell roster is therefore: unpack, copy, archive-move,
   staging-delete — nothing else.
8. Verify, per selected folder: the target folder now exists in
   `preferencesDirectory$` and, when `setup.praat` was present in
   the source, is present in the target. Named failure identifying
   the folder; folders already installed in the same run stay
   installed and the summary reports them.
9. Cleanup staging (rail 6). Final message is ONE summary: each
   installed folder on its own line, replaced ones noting "previous
   version kept in the archive folder", then "Restart Praat to
   activate." One restart notice regardless of count.
10. Praat version gate identical in mechanism to the bootstrap's,
    same floor, message adapted to this script's name.

## Structure (fixed)

Constants section; work procedures — `emlpmL_versionOk`,
`emlpmL_makeStaging`, `emlpmL_unpack` (format, source, destination),
`emlpmL_findPluginDirs` (root → ALL matched paths, complete
recursion, honoring the `__MACOSX` exclusion),
`emlpmL_checkSetupPresent`,
`emlpmL_archiveExisting`, `emlpmL_placeFolder`, `emlpmL_verify`,
`emlpmL_cleanupStaging` — then the main sequence with the dialogs.
Procedures never open dialogs; all dialogs live in the main
sequence, so the driver can exercise every procedure headlessly.

## Acceptance (done when, driven on macOS and Linux; Windows by
documented behavior, marked unverified)

- A tar.gz with the plugin at top level installs correctly.
- A zip with the plugin nested two levels deep installs correctly.
- A zip built on macOS (containing `__MACOSX`) installs the real
  plugin, never the shadow.
- An unpacked folder chosen directly installs as a copy; the
  user's original folder is untouched (verify by checksum or
  listing before/after).
- An archive containing three plugin_ folders in different
  subfolders shows all three checked; unchecking one installs
  exactly the other two.
- A plugin_ folder nested INSIDE another plugin_ folder appears as
  its own row with its nesting visible in the label; selecting BOTH
  installs both, and the parent's inner copy is intact.
- An archive whose tree holds more than 200 folders is searched
  completely (regression against the draft's silent cap).
- Two same-named plugin_ folders both selected refuse by name
  before anything installs.
- An archive containing none refuses with the named message.
- A simulated archive-move failure (archive path made unwritable)
  reports FAILED for that plugin, does not place it, and installs
  the rest.
- Replacing an installed plugin moves the old folder to the archive
  location with a stamp, and the new one works.
- A found folder without setup.praat appears unchecked with its
  annotation; checking it by hand installs it anyway.
- A setup.praat registering two menu commands shows "(adds 2
  commands)" in its row label.
- After every run, success or failure, the staging folder is gone.
- The staging folder is the only thing ever deleted (assert by
  inspection of the command constants).
