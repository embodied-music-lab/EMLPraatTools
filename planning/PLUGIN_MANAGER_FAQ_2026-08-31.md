# EML plugin manager for Praat — frequently asked questions

31 August 2026. Companion to `PLUGIN_MANAGER_ROADMAP_2026-08-31.md`.

## For users

**What is this?**
A plugin that installs, updates, and removes other Praat plugins
from a menu inside Praat. You never locate the preferences folder,
never unzip anything by hand, and never copy folders.

**How do I install the manager itself?**
Download one `.praat` file, open it in Praat, and click Run. It
installs itself, lets you pick plugins in the same sitting, and asks
you to restart Praat once. That restart is the only one you need,
however many plugins you chose.

**Why does Praat ask me for permission?**
Praat 7 asks before any script writes files or runs system commands,
and the approval lasts at most until you close Praat. The manager is
built around that: it only touches your disk when you have clicked
an action, so every prompt arrives in direct answer to something you
just asked for. Choose "approve for this session" and you see one
prompt per sitting at most. Nothing runs at startup that needs
permission.

**Does it phone home? What does it send?**
Nothing, to nobody. The manager contacts the network only when you
use it, only to fetch the catalog file and download the plugins you
selected, and it reports nothing anywhere. There are no accounts, no
telemetry, and no tracking. The update indicator you see at launch
comes from a local file written during your last session, not from
a network call.

**Is it safe?**
Every download is verified against a checksum published in the
catalog before it is unpacked; a corrupted or tampered file is
refused and deleted, and nothing is installed. Nothing the manager
downloads is ever executed during install — archives are data, and
what they contain only runs as a Praat plugin after you installed
it, which is the same trust decision installing any plugin has
always been. The manager itself needs no administrator rights and
installs nothing outside Praat's own preferences area.

**What happens to my settings when I update or remove a plugin?**
They survive. Updates preserve your settings and saved files
automatically. "Remove" keeps the plugin in a local archive — with
its settings — so you can restore it later; permanently deleting
archived plugins is a separate, explicit command that shows you
exactly what it is about to delete.

**A plugin update broke my workflow mid-project. Now what?**
Every update automatically keeps the previous version in the
archive. Restore it from the manager and restart; you are back
where you were.

**Can I move my setup to another computer?**
Yes (planned feature): Export setup writes one file holding your
installed plugins and their settings; Import setup on the other
machine installs the same plugins and lays the settings down. This
also lets an instructor hand a whole class an identical
environment.

**I installed some plugins by hand years ago. Does the manager
touch them?**
No. Hand-installed plugins show up as "installed, not in the
catalog" and the manager never modifies or removes anything it did
not install unless you explicitly ask.

**Which Praat versions does it support?**
Praat 6.6.30 and later, including Praat 7. Each catalog entry also
declares the lowest Praat version that plugin supports, and the
manager refuses to install a plugin your Praat cannot run.

**What does it need besides Praat?**
Nothing you have to install. The manager uses tools your operating
system already ships (`curl` for downloads, `tar` for unpacking) on
macOS, Windows 10 and later, and Linux. No Python, no Perl, no
runtimes.

## For plugin developers

**What do I have to do to list my plugin?**
If it is already a plugin folder: add a one-line `VERSION` file, run
the publisher tool (it packages your folder, computes the checksum,
generates the manifest, and prints your catalog row), publish the
archive wherever you host releases, and submit the row. No code
changes, no restructuring. Budget under an hour the first time,
minutes after that.

**My tool is a folder of scripts, not a plugin. Am I out?**
No — the publisher tool's scaffolder converts a folder of scripts
into a proper plugin: you name a menu label for each script and it
generates the wrapper folder and a correct `setup.praat`. An
afternoon, and your tool is better off for it even if you never
list it.

**Do I have to rename my procedures?**
No. Hard requirements cover only what actually collides: your
submenu name, your config filenames, and your folder name — things
that cost you a prefix, not a refactor. Procedure-name prefixes are
a recommendation (and a lint warning), because they only matter if
plugins ever include each other's files. Your catalog id reserves
your prefix either way, first come.

**Where do my users' settings have to live?**
New submissions keep config outside the plugin folder, in a
location keyed by your catalog id — that is what makes updates and
removal safe by construction. If your existing plugin writes
settings inside its own folder, declare those files in the manifest
instead and the updater preserves them; you can migrate later or
never.

**Who controls the catalog? Can I be delisted or edited?**
The canonical catalog lives in a neutral repository with multiple
maintainers and mechanical submission checks — a machine validates
your row; a human only glances at first-time listings. The catalog
only ever states what your own release declares; nobody edits your
metadata. Rows are removed for dead links or malicious content
under a written policy, and removal never touches anyone's
installed copy.

**Do I have to be in the official catalog at all?**
No. The catalog format is an open, versioned spec; you can host your
own `catalog.tsv` anywhere, and users add its URL in the manager's
settings. The official catalog is a default, not a gate.

**How do updates reach my users?**
You publish a new release and update your row's version and
checksum. Users see "update available" the next time their manager
looks, and install it in one click. Compare that with the current
reality, where a fixed zip reaches almost nobody who downloaded the
broken one.

**What if I stop maintaining my plugin?**
Nothing breaks. Your last release stays installable as long as its
URL resolves; if the link dies, the row is removed and installed
copies are unaffected. Forks can be listed under their own id per
the normal rules.

## About the project

**Why hasn't someone done this before?**
Someone did. CPrAN (2015-2018) was a real Praat plugin manager — as
a Perl command-line client, with a catalog of developer libraries.
The people with the installation problem are the people who will
never open a terminal, so it stayed unknown even to long-time
community members. This design inverts that: the manager lives
inside Praat, is installable by end users, and launches with
plugins users actually want. The other historical blockers were
real but are gone: stock Windows has shipped `curl` and `tar` since
2018, and the native-installer route (signing, notarization, three
platforms of packaging) remains poisoned for academic maintainers —
which is why this design never goes near it.

**Why a TSV catalog and tar.gz archives, and not JSON and zip?**
Praat script has no JSON parser, and parsing TSV in Praat is
trivial and robust. GNU tar on Linux does not read zip, while
`tar -xzf` works on stock macOS, Windows, and Linux alike — one
format, three platforms. Boring formats are the point: anything the
platform already understands is a dependency we never ship.

**Why no GitHub API?**
Unauthenticated API calls are rate-limited per address, and one
conference network exhausts the limit. Raw files have no such
limit. The catalog is a raw file by design.

**Is this endorsed by the Praat team?**
It does not need to be — everything runs in userland over ordinary
files, and nothing patches or modifies Praat. It works within
Praat 7's permission model rather than around it: every prompt the
user sees is Praat's own, in response to an action the user took.

**What is deliberately NOT here?**
No accounts, no telemetry, no servers beyond static file hosting,
no native installers, no automatic startup behavior beyond reading
one local file, no dependency resolution (plugins in the initial
catalog do not depend on each other), and no multi-version
installs. The spec is written so none of these are foreclosed if
the ecosystem ever needs them.

**What would make this fail, and what is the defense?**
The known failure modes have names: wrong side of the audience's
skill boundary (defense: it lives in Praat, one file to start);
empty-shelf launch (defense: convert two or three known non-EML
tools with their authors before going public); maintainer burnout
(defense: mechanical CI, written policies, three maintainers);
trust-prompt fatigue on Praat 7 (defense: one session approval per
sitting, nothing automatic); and user-data loss undermining
confidence (defense: archive-by-default removal, automatic
rollback, preservation by inventory even for plugins that declare
nothing).
