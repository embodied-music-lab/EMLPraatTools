# EML plugin manager for Praat — product design roadmap

31 August 2026. This consolidates the full design discussion and
supersedes `PLUGIN_MANAGER_DESIGN_2026-08-31.md`. The implementation
handoff (`praatpluginmanagerhandoff.md`) remains the engineering
companion; where the two differ, this document governs.

## 1. What this is and what's at stake

A plugin that installs, updates, archives, and removes Praat plugins
from inside Praat: one submenu, a catalog fetched from the web,
checksummed archives, and a restart to activate. No native installer,
no code signing, no external runtime — Praat plus what the operating
system already ships.

Installation is one of the central annoyances that keeps Praat a
niche-community tool. Today a plugin means finding a zip, locating a
hidden preferences folder whose path differs by platform, copying a
folder exactly, and restarting on faith. Every step loses people.
This project either demonstrates that an in-Praat package manager
fails, or it becomes the architecture a community-wide system is
built on. Design for the second outcome; ship the first release
small.

## 2. Prior art: CPrAN, and the four inversions

CPrAN (José Joaquín Atria, mid-2010s) was a real Praat plugin
manager: browse, install, update, remove. It never spread — the
client is a Perl command-line tool (3 GitHub stars, dormant since
2018), and its catalog held the author's own developer libraries
(`utils`, `tgutils`, `serialise`), not tools end users wanted. The
people crushed by the installation problem are exactly the people
who will never open a terminal.

This design inverts all four failure axes: the manager lives inside
Praat instead of an external client; it is installable by end users
instead of developers; the catalog is seeded with destination
plugins people already want instead of libraries; and it gets an
institutional home with multiple maintainers instead of one author's
weekend project. CPrAN is credited as prior art, and its plugin
descriptor design gets mined before our manifest schema freezes.

## 3. The Praat 7 reality

Praat 7.0 (4 August 2026) introduced full-trust checking: a script
that writes files or runs system commands triggers a permission
prompt with three options — reject, approve once for this script, or
approve for this script for the rest of the Praat session. Approvals
are dumped when Praat closes. There is no way around it, and the
design does not fight it: minimize the number of challenges, and
lean into session approval when a prompt is unavoidable.

Design consequences:

- Every write and every system command happens inside an explicit
  user action in the manager's own dialogs, where the prompt reads
  as confirmation of what the user just asked for.
- The bootstrap and each manager command open with one
  approve-for-this-session grant; everything in that sitting rides
  on it. Target: at most one prompt per sitting, none at startup.
- Reads are prompt-free, which the notification design exploits (§6).

Measurement items to confirm on a real 7.0.x install before the
relevant designs freeze: where the preferences/plugin folder now
lives per platform (7.0 standardized config locations); that
`preferencesDirectory$` resolves there for a bare script; that
file reads at startup are prompt-free; and whether a menu label can
differ per launch (it should, since `setup.praat` re-registers menus
at every startup).

## 4. Architecture

Five parts. The second is what makes this community infrastructure
rather than an EML convenience.

1. **The manager plugin** (`plugin_EMLPluginManager`): one submenu —
   Install or update plugins, Check for updates, Remove a plugin,
   Settings. Reads the catalog over HTTPS (`curl` to stdout),
   downloads archives, verifies SHA-256, unpacks with `tar`,
   swaps folders atomically, reports one line per plugin, one
   restart notice per sitting.
2. **The spec, versioned and permissively licensed**: catalog schema
   (`schema_version` as the first non-comment line), archive layout
   (`.tar.gz`, one top-level folder named as the catalog says),
   `VERSION` file convention, in-archive `MANIFEST` (id, name,
   version, license, homepage, declared menu paths, config
   locations, preserve globs, shipped-file inventory with
   checksums), and the namespace rules (§10). Anyone can host a
   catalog anywhere; anyone can build a compatible manager or
   publisher against the spec.
3. **The catalog**: one `catalog.tsv` in a public repository, read
   raw (no API, no rate-limit exposure). Columns per the handoff
   plus `schema_version` at the head and, per row: `tested_praat`,
   `tags` (drives filtering, categories, and the web directory),
   and `maintainers` (the accounts registered at first listing —
   the ownership anchor, §12). A row is an atomic triple of
   version, URL, and checksum, all three updated together each
   release. URLs must be pinned per release (e.g. a tagged GitHub
   asset URL); floating "latest" URLs are forbidden by the spec —
   they decouple the row's checksum from the bytes behind the URL.
   Hosting is agnostic: any stable, direct HTTPS URL works — GitHub
   release assets, a lab web server, an institutional repository,
   or Zenodo, which adds a DOI per version and suits academic
   citability. No forge, no git, and no account anywhere is
   required of a publisher. Settings hold a LIST of catalog URLs —
   federation from day one.
4. **The publisher tool**: packages a plugin folder, computes the
   checksum, generates the shipped-file inventory and most of the
   manifest by scanning `setup.praat`, runs the namespace lint, and
   emits the catalog row. Also generates the manager's own
   bootstrap at each manager release. Runs the same checks the
   catalog CI runs, so failures happen privately with explanations.
5. **The one-file bootstrap**: the manager's files embedded as text
   in a single `.praat`. Run it once in Praat; it resolves
   `preferencesDirectory$`, creates the plugin folder, and writes
   its files out — pure `createFolder`/`writeFile`, no network, no
   archives. Because the whole manager is in memory during that
   first run, it can offer the install dialog immediately: install
   the manager and pick plugins in one sitting, one restart
   activates everything. The bootstrap is a build product of the
   publisher tool, never hand-maintained.

## 5. End-user experience

First contact: download one file, open it in Praat, click Run,
choose Approve for this session, tick the plugins you want, restart
once. The preferences folder stops existing as a concept the user
needs.

Steady state: the Plugin manager submenu shows every catalog plugin
with its state — not installed, current, update available, or
installed but not in the catalog (hand-installed plugins are shown,
never touched). Failures are named in plain language: offline says
the catalog was unreachable; a checksum mismatch says the download
did not match what the publisher declared and nothing was installed.

Finding plugins: Praat forms cannot do live type-ahead, so search is
a chained dialog — a "Filter (leave empty to show all)" text field
plus a category dropdown (from `tags`); the next dialog lists only
the matches with checkboxes. This also solves dialog height once the
catalog outgrows one screen. Discovery at large lives outside Praat:
the catalog repo generates a static, searchable web directory from
`catalog.tsv` — the PyPI to the manager's pip. Both render the same
TSV, so they cannot drift.

## 6. Update notification

Praat has no badges or persistent chrome; the menu is the UI, and it
is rebuilt from `setup.praat` at every launch. So the menu label is
the indicator: "Plugin manager" most days, "Plugin manager (update
available)" when something is waiting.

Mechanism, zero prompts: the manager never touches the network at
launch. During any user-approved manager action it refreshes the
catalog and writes a small local state file as part of the approved
work. At the next launch, `setup.praat` only READS that file and
labels the menu. Information is one sitting stale, which for plugin
updates is nothing.

When an update exists, at most one notice per session, listing all
updates at once, with three buttons: **Install now** (opens the
manager; approvals flow normally), **Later** (writes nothing; the
notice returns next launch), **Skip this version** (one
user-initiated write; that version never prompts again). No
launch-counting snooze — a countdown requires a write at every
launch, which is exactly the automatic write the permission scheme
taxes.

"Push" announcements reduce to the same channel: the catalog fetch
can carry a short message per plugin version, cached in the state
file, shown once. Push-like latency of one sitting at zero prompt
cost. There is no other channel, and none is wanted: the manager
contacts the network only during user-approved actions, downloads
only from the catalog's declared URLs, and reports nothing anywhere.

## 7. Deletion, archiving, and rollback

Archiving is the default meaning of "remove"; true deletion is a
deliberate second act.

- Praat activates a plugin because its `plugin_` folder sits
  directly in the preferences directory — so deactivation is
  relocation. Remove moves the folder to the manager's archive area,
  versioned (`archive/plugin_X-1.0.0/`). Restore is the reverse
  move. The button says "Remove (kept in archive)".
- Updates are atomic and self-archiving: unpack to a temporary
  folder, verify, copy preserved files in, rename old aside, rename
  new into place — and the old version slides into the archive
  instead of being deleted. Every update leaves a one-version
  rollback for free. This supersedes the handoff's
  delete-then-unpack sequence, which can strand a user with no
  plugin on a failed unpack.
- Permanent deletion lives behind its own command ("Delete archived
  plugins"), shows the resolved path, and keeps the handoff's rails:
  path built from `preferencesDirectory$` plus a catalog-known
  `plugin_` name, never from typed text.

## 8. User state: preservation and transfer

Three-tier preservation model, from automatic to conventional:

1. **Derived inventory (covers everyone)**: the publisher tool's
   shipped-file inventory rides in the manifest. Any file in the
   installed folder that is not in the inventory is user-created by
   definition — settings, templates, caches — and is preserved
   without any declaration.
2. **Preserve globs (the one awkward class)**: files that ship with
   defaults and get edited in place are ambiguous under checksums,
   so the manifest declares them. One or two lines, written once.
3. **External-config convention (the recommended path)**: config
   lives outside the plugin folder, keyed by catalog id. The folder
   is pure code; update, archive, restore, and transfer operate on
   the config location without declared paths. Required for new
   submissions; the globs path stays open for legacy plugins so
   entry cost stays near zero. Stats & Graphs already conforms — it
   writes config to the preferences directory — so its manifest
   just names those files.

Transfer between machines: **Export setup** writes one archive
holding the installed-plugin manifest (ids and versions) plus each
plugin's config files; **Import setup** installs the listed plugins
from the catalog and lays the config down, warning on version
mismatches. One instructor exports a lab setup; thirty students
import it; one restart. Also a reproducibility artifact a methods
section can name.

## 9. Developer experience

Two onboarding paths:

- **Already a plugin**: add `VERSION` and let the publisher tool
  generate the manifest and the release. No code changes, no
  restructuring, no new hosting. First release under an hour;
  after that, bump the version and rerun the tool.
- **A folder of scripts** (most of the Praat world): the publisher
  tool's scaffolder converts it — point it at the scripts, name
  each menu label, and it generates the `plugin_` wrapper with a
  correct `setup.praat`. An afternoon that improves the tool whether
  or not it ever joins the catalog. This scaffolder is the single
  highest-leverage growth feature: it converts script-distributors
  into plugin-publishers.

What repels developers, and the countermeasures baked in: gatekeeping
(federation plus a neutral org, §11); forced refactoring (namespace
rules bind only cheap external surfaces, §10); fear of the updater
eating user data (§8's inventory rule protects even undeclared
plugins); packaging friction (the tool runs anywhere and does
everything); schema churn (`schema_version` plus a written stability
promise); being listed or edited without consent (the catalog only
ever says what the publisher's own release says).

## 10. Collisions: the layered namespace model

Only one plugin EXECUTES at a time — each menu command runs its own
script in its own interpreter context — but every plugin's
`setup.praat` runs at every startup. So collision surfaces split by
when they exist:

- **Always-on, therefore hard requirements** (checked by catalog
  CI): menu paths and command labels (shared menu tree at startup),
  config filenames (shared preferences folder on disk), installed
  folder names.
- **Include-boundary only, therefore lint plus convention**:
  procedure names collide only when one plugin includes another's
  files. Nearly never today — but that scenario IS dependencies,
  and CPrAN's most-listed plugin was a shared `utils` library, so
  the demand is proven. The catalog's id-claims-prefix registry
  (first come, recorded in catalog history) costs nearly nothing
  now and means the safety infrastructure is standing when the
  first genuinely shared library plugin arrives, instead of needing
  retrofit across an ecosystem.

## 11. Governance and human overhead

Design principle: every judgment that occurs twice becomes a written
rule plus a machine check, so overhead decays as the catalog grows.

- **Zero-human by construction**: schema validity, checksum matches,
  URL reachability, name and prefix uniqueness, menu-path collision
  against listed manifests, archive layout — all CI on the
  submission PR, with failure messages naming the line and the fix.
  The publisher tool runs the same checks locally first. Version
  bumps to a listed plugin from the same source repo auto-merge on
  green.
- **Human, brief, rare**: first listings get one pair of eyes (a few
  minutes; a handful of times per year at Praat scale). Removals
  are one commit under a yank policy written once — the row
  disappears, installed copies are untouched. A scheduled job
  re-checks catalog URLs and opens issues for dead links.
- **Bounded by policy**: prefix and name disputes resolve by
  first-come rules recorded in catalog history; the arbitration
  paragraph is in the spec before the first dispute exists.
- **Structure**: the canonical catalog lives in a neutral org
  (e.g. `praat-plugins`), three maintainers with merge rights — for
  bus factor and for the recruitment story ("submit to the
  praat-plugins maintainers", not "submit to Ian").

Steady state: minutes per month, bursting to an hour when a new
plugin arrives. The real cost is at launch — CI checks, spec,
policies — and that is build work, not recurring labor.

## 12. Release flow, hosting, and catalog security

**How a release reaches users.** The author runs the publisher tool
(package, checksum, manifest, lints, emits the new row with the
pinned URL), publishes the archive wherever they host, then edits
their one row in `catalog.tsv` by pull request — a thirty-second
job in a web editor. The catalog never watches anyone's repository:
no webhooks, no polling. Author-pushes is deliberate — it needs no
server infrastructure, and cutting a release is not publishing to
users, so release candidates cost nothing. CI on the PR validates
the schema, downloads the URL, verifies the checksum, unpacks in a
sandbox, confirms folder name and internal `VERSION` agree with the
row, and runs the collision checks. An opt-in bot that opens the PR
automatically when a listed repo tags a release is Phase 4 comfort,
never the mechanism.

**Private and restricted hosting.** Self-hosted archives (lab
server, departmental web space) use the identical flow; only the
URL differs. Access-restricted plugins (intranet, licensed,
clinical) cannot be in the public catalog — public CI and public
users cannot fetch them — and are served by federation instead: a
private `catalog.tsv` hosted beside the archives, added once in the
manager's Settings. Same UX end to end, invisible to the world; the
publisher tool's local validation stands in for CI.

**Ownership rules (the supply-chain defense).** The threat is a
tidy PR that edits someone else's row to point at an attacker's
archive; a checksum is no defense, since the attacker computes a
valid one for their own bytes. The defenses:

1. **Ownership, mechanical**: each row's `maintainers` field holds
   the accounts registered at first listing. CI maps every PR's
   changed lines to rows and FAILS when the PR author is not among
   that row's maintainers (catalog maintainers excepted). The
   first-listing human glance anchors the chain by confirming the
   claimed account really is the plugin's author.
2. **Provenance continuity, mechanical**: auto-merge exists only
   for version bumps whose new URL stays on the current row's host
   and repository. Any change of source — different repo, host, or
   owner, and any edit to the `maintainers` field itself — drops to
   human review unconditionally, even from the legitimate
   maintainer, because "the bytes now come from somewhere new" is
   exactly the event a hijack must cause.
3. **Transfer process, written once**: legitimate moves (org
   renames, hosting migrations, handovers) proceed by the current
   maintainer's confirmation or, failing that, the catalog
   maintainers' adjudication under the published policy.
4. **Backstop**: every change is a public git diff — visible,
   attributable, revertable in one commit — and the yank policy
   covers response; removal never touches installed copies.

An attacker therefore needs to pass an ownership check that fails
mechanically, a provenance check that fails mechanically, and a
human who reviews exactly the cases the machines refuse.

## 13. Phases

**Phase 0 — measurement.** The 7.0.x probes (§3) plus one plugin
question already answered: Stats & Graphs config location (external;
conformant).

**Phase 1 — scaffold, one plugin end to end.** `VERSION` and
manifest for Stats & Graphs; catalog repo with one live row; minimum
publisher script (tar, checksum, row — twenty lines, manual is
fine); a `0.9.x` test release exercising the whole pipeline; the
manager at core-loop depth (catalog parse, download, verify, unpack,
remove, version compare) driven by a test script, with the simplest
install dialog. The kit lane's frozen release then hands the catalog
its first real `1.0.0` row, and the manager becomes the install path
the validation paper can name. The manager needs nothing from the
kit; the dependency is one pleasant direction only.

**Phase 2 — the manager as a product.** Bootstrap generator; update
notification (§6); archive and restore UI (§7); the full publisher
tool with manifest generation and lint; adversarial verification per
the handoff's stage 4 (fresh install, update over existing,
corrupted checksum, unreachable catalog, version floor, removal,
out-of-tree removal attempt), on all three platforms, with the
Windows pass on real hardware.

**Phase 3 — community launch.** Spec published; catalog moved to the
neutral org with CI, the ownership and provenance checks (§12), and
the written policies (yank, transfer, disputes); the static web
directory generated from the catalog; two or three flagship non-EML
plugins converted with their authors (the actively maintained tools
people already hunt down as zips) so the first screen is an
ecosystem, not a lab; CPrAN credited, its author contacted.

**Phase 4 — ecosystem features.** Export/import setup transfer
(§8); catalog announcements; the scripts-to-plugin scaffolder
promoted as a first-class command; additional catalog sources
documented.

**Later, deliberately**: dependency resolution, multi-version
stores, signing beyond checksums, machine-readable environment
records for publication. The spec leaves room; nothing forecloses
them.

## 14. Out of scope, permanently or until proven needed

No native application, no installer framework, no code signing, no
accounts, no telemetry, no server infrastructure beyond static file
hosting, and no automatic anything at startup beyond one read of one
local file.

## 15. Success criteria

- A first-time user goes from download to installed plugin in under
  five minutes with at most one permission prompt.
- A plugin author goes from existing plugin to listed row in under
  an hour without changing code.
- The steady-state maintainer burden is minutes per month.
- At least two non-EML plugins are listed by their own authors
  within the first release cycle.
- Every claim above survives the stage-4 adversarial pass before
  anyone outside the lab sees the manager.
