# Design brief — EML plugin manager for Praat

Fable, 31 August 2026. This sits beside the implementation handoff
(`praatpluginmanagerhandoff.md`) and governs where they differ. The
handoff's engineering standards, stage gates, and agent plan stand.
Ian's framing: this is either the demonstration of why the idea fails
or the architecture a community-wide system gets built on. Design for
the second outcome; ship the first release small.

## 0. The measured fact that reshapes the handoff

Praat 7.0 (4 August 2026) introduced full-trust checking for scripts
that write files or run system commands — a breaking change for
automation — and standardized config file locations across platforms.
The handoff was written against the 6.x world: its three
preferences-folder paths, its assumption that `curl`/`tar`/checksum
commands just run, and its 6.6.30 measurement target all predate this.
The manager must run on 6.6.30 AND 7.0.x.

**First work item of the new session, before any design freezes:
measure the 7.0.x trust model on a real install.** Which calls prompt
(file write, `runSystem`, both), whether a grant persists (per script,
per folder, per session, forever), whether `setup.praat` under the
preferences folder runs with any implicit trust, where the
preferences/plugin folder now lives on each platform, and whether
6.x-installed plugins migrate. Every downstream decision cites that
measurement. Do not design against the 6.x manual.

## 1. Ease of use

- One primary command does the whole job: a single dialog listing
  every catalog plugin with its state (not installed / current /
  update available / installed but not in catalog), one checkbox
  column, one action button. Summary lines at the end, one restart
  notice total.
- Bootstrap is one file: the manager ships as a single `.praat` the
  user opens once, and it installs ITSELF into
  `plugin_EMLPluginManager` (subject to the trust prompt, which is
  legible there: the user just asked for exactly this). Step one of
  the instructions is "open this file", not "create a folder".
- The manager appears as a row in its own catalog and updates itself
  through the same path as everything else. No special case.

## 2. Procedure collisions

Get the layer right. At runtime, each Praat menu command runs its own
script; plugins do not share one procedure namespace while running.
The real collision surfaces are: menu paths and command labels,
`include`d library files, preference filenames in the shared
preferences folder, and installed folder names.

- Collision prevention is a PUBLISHING-time concern, not an
  install-time scan. The spec (see §6) requires every plugin to
  namespace its procedures, menu paths, and pref filenames with its
  id, and the publisher tool lints for it before a release is cut.
- The catalog refuses two rows with the same `folder` or the same
  declared top-level menu path. The archive manifest (§6) declares
  menu paths so this is checkable without unpacking a build.
- Install-time, the manager does one cheap check: compare the incoming
  manifest's declared menu paths and folder name against every
  installed manifest; warn by name on overlap, proceed only on
  confirmation.
- Build no runtime detection. The handoff's out-of-scope line stands
  for the code; the SPEC is where the future generic answer lives.

## 3. Update notification without annoyance

The etiquette rules, in order of force:

1. A popup appears ONLY when an update actually exists. "You're up to
   date" is never a popup; it's a line in the manager dialog.
2. Startup is never blocked on the network: short timeout, silent
   failure, no error dialog for an offline launch.
3. At most one notice per Praat session, listing all updates at once.
4. The notice's buttons are "Open plugin manager", "Skip this
   version", "Later". "Later" writes nothing and repeats next
   session. "Skip this version" writes one settings line — a
   user-initiated write — and that version never prompts again.

Under the 7.x trust model, whether a passive launch check is even
polite depends on the measurement in §0: fetching the catalog needs a
system command (`curl`), and if that prompts every launch, the feature
is annoyance by construction. So: the launch check is a SETTING;
default ON only if the measurement shows a trusted manager runs it
silently; otherwise default OFF, and the primary update path is the
manual "Check for updates" command plus a state refresh every time
the manager dialog opens (the user is already there; no popup
needed). Fetch the catalog to stdout — no temp file — so the
automatic path performs zero disk writes either way.

## 4. Deletion, and preference files inside plugin folders

The invariant: the manager never silently destroys user state.

- EML convention, effective now and written into the spec: plugins
  keep user preference files OUTSIDE their own folder (under the
  preferences directory in a per-plugin config location; align with
  wherever Praat 7 standardized config). A plugin folder is then
  pure code, and delete-and-replace is safe by construction.
- For plugins that keep prefs inside their folder (our current ones
  until migrated; third-party later): the archive manifest declares
  `preserve` paths. Update = unpack to a temp folder, verify, copy
  preserved files in from the old tree, then swap: rename old to
  `.old`, rename new into place, delete `.old` on success. This also
  makes the handoff's install sequence atomic — its current step 3
  (delete the old folder BEFORE unpacking) can strand the user with
  no plugin on a failed unpack. Amend that sequence.
- Removal dialog offers "keep settings" (preserved files parked under
  the manager's folder, restored on reinstall) or "remove
  everything", with keep as the default. The resolved path display
  and the `plugin_`-prefix and catalog-membership rails from the
  handoff all stand.

## 5. Praat 7 trust scheme — posture

- Concentrate every write and every system command inside explicit
  user actions in the manager's own dialogs, where a trust prompt
  reads as confirmation of what the user just asked for. The
  automatic launch path does zero writes; worst case it does one
  network read, and only if the setting is on.
- Never attempt to defeat or route around the trust checks; the goal
  is to be the best citizen the scheme has. If the measurement shows
  a per-launch prompt is unavoidable for any automatic behavior, the
  automatic behavior goes, and the manual commands carry the load.
- The catalog's `min_praat` column plus a `tested_praat` column (see
  §6) let a row say both "needs at least" and "verified through" —
  under a 6→7 breaking change, users on both sides need that.

## 6. Extensibility: the spec IS the product

The repository ships three things, and the second is the one that
makes this community infrastructure rather than an EML convenience:

1. The reference manager (this plugin).
2. **A versioned spec document**: the catalog schema (add
   `schema_version` as the file's first non-comment line — the
   handoff's schema has no way to evolve without stranding old
   managers), the archive layout, the `VERSION` file convention, the
   in-archive `MANIFEST` (id, version, license, homepage, declared
   menu paths, preserve globs), and the namespace rules from §2.
   Anyone can host a catalog anywhere; anyone can build a compatible
   manager or publisher against the spec.
3. **The publisher tool**: a script that packages a plugin folder,
   computes the checksum, runs the namespace lint, and emits the
   catalog row. Third parties publish without hand-rolling any of it.
   (This also replaces hand-maintained checksums for our own
   releases.)
- Multiple catalog sources: the settings hold a LIST of catalog URLs,
  ours preinstalled; "add a source" is pasting one URL. Federation
  from day one costs almost nothing and removes EML as a gatekeeper.
- License the spec and manager permissively and say so in the repo.

## 7. Handoff amendments, consolidated

1. §0 measurement precedes design freeze; 6.x paths and trust
   assumptions are unverified until then.
2. Install sequence becomes atomic (temp-unpack, preserve, swap) —
   supersedes the handoff's delete-then-unpack.
3. `catalog.tsv` gains `schema_version` (file head) and
   `tested_praat` (per row); archives gain `MANIFEST`.
4. Settings hold a catalog-URL list, not a single URL.
5. The manager lists itself in the catalog.
6. Launch-time update check is a setting whose default is decided by
   the §0 measurement; notification etiquette per §3.
7. Removal defaults to preserving user settings per §4.
8. Out-of-scope list otherwise stands (no dependency resolution, no
   content-addressed store, no third-party rows yet) — but the spec
   is written so none of those are foreclosed.

— Fable
