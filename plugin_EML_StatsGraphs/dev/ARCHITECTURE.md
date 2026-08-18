# Architecture — the stats core and the plugins that depend on it

Ian Howell — Embodied Music Lab — GPL-3.0-or-later

These are design rules, not a record of a decision. They say what the code in
this repository is allowed to do and what it is not. A change that breaks one
of them is not a change to this document, it is a change that needs the rule
changed first.

This file lives under `dev/` because it is not shipped. A user installing
**EML Stats & Graphs** gets a plugin that does statistics and figures; nothing
in the folder they install needs to know that a second plugin exists.

---

## 1. This plugin is the statistical core, and it is self-contained

`plugin_EML_StatsGraphs` never includes from, calls into, or registers
anything belonging to a signal plugin. Not optionally, not behind a presence
check, not "if the folder happens to be there". There is no code path in this
tree that names a sibling plugin.

Concretely, in this tree:

- no `include` line resolves outside `plugin_EML_StatsGraphs/`
- no `runScript:` names a path outside it
- no `Add menu command:` registers a command belonging to another plugin
- no procedure here is written to be overridden by one defined elsewhere

The dependency runs ONE WAY, permanently: **a signal plugin imports the core;
the core never reaches back.** That is what makes the core installable and
testable on its own, and it is what lets this suite say the plugin works
without knowing what else the user has installed.

The practical test is the one `harness/release` already performs: unzip the
artefact into an empty preferences directory, start Praat, and everything
must work. A core that reached sideways would pass that only by accident of
what happened to be installed on the machine that built it.

## 2. No signal-analysis code lands in this plugin

EGG, respiration band / RIP, vibrato, acoustic measures: none of it belongs
here. The first such module is the FOUNDING RESIDENT of the second plugin —
it is what causes that plugin to be created, and it does not pass through this
one on the way.

The line is about what a procedure takes, not about what it is called. A
procedure that takes a Table of numbers and returns statistics or a figure is
core work whatever the numbers came from. A procedure that takes a Sound, an
EGG signal or a respiration trace and derives a measure from the WAVEFORM is
signal work, and it goes in the signal plugin, which then hands its Table to
the core like any other caller.

A statistical helper that is useful to both is core, and the signal plugin
imports it. That is the whole point of the direction in rule 1.

## 3. How the second plugin reaches this one

**By sibling relative path.** Every Praat plugin installs as a folder directly
under `preferencesDirectory$`, so from inside any plugin the core is at:

```praat
include ../plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
```

That is stable on all three platforms, because it is a statement about the
preferences directory's own shape rather than about any machine.

**The user-script path problem does NOT apply here.** The reason the user
barrel under `scripts/` has to be GENERATED at launch — Praat resolves a relative
`include` inside an included file against the TOP-LEVEL script's folder, not
against the folder of the file the line is written in — bites a user's script,
which sits somewhere this project cannot predict. A sibling plugin's
`setup.praat` is not in that position: Praat executes it from that plugin's
own folder at every launch, so `../plugin_EML_StatsGraphs/...` resolves from a
known place. The barrel is for users. Plugin-to-plugin is a relative path and
needs nothing.

**Its `setup.praat` does a presence check with an honest refusal.** If the
core is not installed, the signal plugin registers no menu commands and says
so in one line naming the fix:

> requires EML Stats & Graphs — install it first

Not a stack of parse errors from eleven dead `include` lines, and not a menu
that appears and fails on click. The same shape as this plugin's own refusal
when Praat is below the version floor: state the requirement, register
nothing, stop.

**And it declares a version floor against the core**, the same way this plugin
declares `emlMinPraatVersion = 6630` against Praat. A signal plugin built
against a core procedure that did not exist two releases ago must say which
core it needs, and refuse below it, for exactly the reason the Praat floor
exists: below the floor the failure is not graceful, it is an error naming a
procedure rather than a version.

**Validating that dependency contract belongs to the signal plugin's suite,
not to this one.** This suite's subject is a plugin that stands alone; a
validator here that asserted how some other plugin imports it would be
asserting something it cannot install, cannot drive, and cannot see change.

## 4. What this leaves the core free to do

Nothing in the rules above constrains the core's own growth. More tests, more
figures, better output, a wider scripting API — all of that is core work and
lands here. The rules constrain DIRECTION, not scope: whatever the core grows,
it grows without acquiring a dependency on anything installed beside it.
