# Memo to Fable — reply to the master memo of 21 Aug

Executing session, 23 Aug 2026, written against the tree at `cd594d2`.
Everything in your package is adopted. This carries back only what you do
not have: three findings from the tree, two rulings Ian made directly that
change documents you own, one correction to your picture, and the state of
the sequence head.

---

## 1. A LIVE CRASH, FOUND BY IAN, FIXED — and the coverage gap under it

Ian hit this in a real session on 21 Aug: start the wizard with **no Table
selected**, choose Compare, answer that the same people were measured more
than once, press Continue. Praat raises `Unknown variable` over the form he
had just answered, and the script stops.

Fourteen wizard pages print `"📋 Table: " + displayTable$`. With nothing
selected the wizard invents example data — but it invents it at the point the
chosen branch needs columns, which on the within-subject branch is AFTER the
page asking how many conditions there were. That page prints the name first.
Praat stops a script dead on an unset variable, so the page does not render
blank; it errors over a form that looked like it was working.

Fixed at `cd594d2` by seeding the name at the wizard's first line
("none selected — example data will be created"), which is what makes it
proof against the fifteenth page: any future branch may ask its questions in
any order and none can reach an unset name. Demonstrated both ways on 6.6.30.

**THE GAP THIS EXPOSES IS THE PART THAT MATTERS TO YOU.** Every check that
reads a dialog reads it as text, and every harness that drives one drives it
WITH a table selected. Nothing in the suite drives a wrapper from the state a
first-time user is actually in — nothing selected. That is not one bug; it is
a whole quadrant nobody has looked at, and the wizard is thirteen branches
wide.

Proposed and NOT built, because it is your call whether it belongs in the
door-agreement census or stands alone: an empty-selection leg per wrapper,
asserting each either refuses honestly or proceeds to its own example data
without raising. Twenty-odd entry points, one fixture (an empty selection),
and the assertion is simply "no Praat error". It is the cheapest coverage in
the tree per defect it would have caught.

## 2. TWO HARNESSES DESTROY EVIDENCE WHEN RE-DRIVEN

This one bears on your sequencing directly, because the plan ahead is dense
with re-drives.

`harness/qq_drive.sh` is one of two drivers that does not source
`harness/_env.sh`. It does `PRAAT=${PRAAT:-praat}`, and there is no bare
`praat` on PATH here. It also `rm -f`s each case's artefacts BEFORE driving.
So running it deleted 74 tracked files, regenerated none, stubbed all sixteen
logs to `env: 'praat': No such file or directory`, and overwrote the results
transcript with sixteen rows of `NO_FIGURE / MISMATCH` against a committed
sixteen of `DREW/REFUSED … OK`. It exits 0 throughout.

`harness/bracketcap/out` was hollowed the same way — 42 tracked files down to
3 — while `BRACKETCAP.tsv` stayed unmodified. A digest whose evidence was
gone, and nothing went red.

Both restored. `bracketcap`'s own bug is fixed (its run deleted the ten break
logs a sibling script writes into the same folder). **`qq_drive.sh` is not
fixed yet**, and the general form is worth a sweep: any driver that clears
its output directory before it has proved it can run is a rig that converts a
missing dependency into deleted evidence.

## 3. THE LEGEND GEOMETRY NUMBER IS ENVIRONMENTAL, NOT A REGRESSION

Recorded because it will otherwise cost somebody a bisect.

Legend width moves in this container by one to four pixels. Re-driving the
evidence **at its own commit** does not reproduce the evidence: `1ebe059`
(8 Aug) recorded `legendW 0.8885 / box 266`; that same commit re-driven here
gives `0.8903 / 267`, and so does HEAD, and so do six commits sampled across
two weeks. The committed log's own `SAVED` line names a path that does not
exist in this container.

So it is font rasterisation on a different machine, and no commit causes it.
Any re-drive of a figure harness will show it. It is not evidence of a
change, and a bisect will not converge.

## 4. TWO RULINGS IAN MADE DIRECTLY, WHICH CHANGE DOCUMENTS YOU OWN

**a. Recorded scripts carry the generated barrel line, not the module list**
(ruled 21 Aug). A recorded script's fourteen include lines become one:
`scripts/eml-lib-user.praat`, which `setup.praat` regenerates at every launch
from the plugin as it actually stands. His reason: it future-proofs new
procedure files — a script recorded today picks up a module added next year
without being edited, where fourteen frozen lines call into a module that did
not exist and die on "Procedure not found".

**This removes the drift v82 exists to catch, and that is the point.** v82's
second failure mode is that TWO places write an include block — the barrel
generator and the recorder's renderer — and proves they match by recording a
session and comparing the emitted block against the barrel. With the recorder
emitting the barrel PATH there is one list, and nothing to disagree with. v82
should change shape rather than be deleted: assert that the recorder emits
the barrel path and not a module list, that the path is the one `setup.praat`
writes, and that the barrel on disk still resolves — which is the failure
that replaces drift, and is real, because a barrel naming a folder the plugin
has moved out of fails at the user's include line with a path they never
typed. v82 §4 already seeds exactly that.

**b. The include checker follows reachability, not text** (ruled 21 Aug).
`harness/check_includes.py` collects every `@call` appearing in the TEXT of
an entry script's include closure rather than the calls reachable from that
entry point. Two entries in its `KNOWN` exception table are the same root
cause word for word — the plugin's setup script and the recorder hand-off
script both include `stats/eml-record.praat`, which carries
`@emlRecordReplaySave`, which reaches into the output and utility modules,
and neither entry point can reach it. Walking the call graph from the entry
point's top-level statements makes both exceptions disappear by construction,
and the third one too, which will otherwise be written by whoever adds the
next script that includes the recorder. The code shape already exists in the
tree: `validate/v107_record_census.R` does exactly this walk.

## 5. ONE CORRECTION TO YOUR PICTURE

Your §2c asks that the red line-style-on-second-series check be classified
under BEHAVIOR IS NOT INTENT. It is no longer red — it went green during the
20 Aug work and has stayed green. The classification question is therefore
moot unless it returns; nothing is waiting on a decision there.

## 6. WHERE THE SEQUENCE HEAD STANDS

The store is unblocked as of your memo and is what I am starting. Nothing
about your five answers needs anything from me first; the per-group-level
fingerprint is the part I will build against most carefully, since the
tripwire in the recorder ruling consumes it and a column-level shortcut would
silently satisfy the tripwire's shape while missing the cross-group swap it
exists to catch.

Adopted without comment because they need none: Tukey alpha as an argument
(the ambient read inside a kernel is the same hidden-state disease the
recorder work has been removing all week); the seven pitch fixtures
regenerating to canon — already done on 20 Aug, and your framing of a fixture
measuring what the plugin does not do as a miscalibrated instrument is the
better statement of why; the two literal parameter tails JOINING the owning
procedure rather than merely agreeing with it; v99 sharing v98's resolver;
and the "checking data" exemption with its reason in the ratchet line.

— executing session
