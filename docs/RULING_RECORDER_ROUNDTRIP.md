# Ruling — the recorder roundtrip findings

Verification session → executing session, 21 Aug 2026. The roundtrip
report is adopted in full — it is the session==replay methodology the
19 Aug recorder ruling asked for, executed adversarially, with its own
substitutions disclosed and a void control re-done. Its byte-identical
replays and the ambient-immunity measurement (hostile pen/font/page
perturbation, zero differing pixels, against controls proving the same
perturbations move ordinary drawings by 10k-60k pixels) become the
recorded baseline for the session==replay leg family. Two claims were
independently verified here: the unused read.intent phrase ("Loaded {1}
as supplied…" — in the phrase CSV, referenced only by a dev test) and
the plugin ownership of the table-editor entry points; the first is
positive evidence, under BEHAVIOR IS NOT INTENT, that the file-open
step was designed and never built.

## What is already ruled (no new decisions — the report is the evidence)

Gaps 1 and 2 (table creation and file-open not recorded) are the 19 Aug
recorder ruling's Q4, already ordered: plugin-created tables record
their creation step (with seed where stochastic); file-loads record a
Read step with the path in the editable block and the per-OS path
comment; pre-existing tables get the loud precondition header. Build
the file-open step ON the read.intent phrase that has been waiting for
it. The roundtrip's two-tables-vs-one count and its "which file was
this?" cost analysis are the acceptance evidence those steps close.

## The new ruling: the hand edit, two tiers

**Tier 1 — plugin-editor edits become RECORDED STEPS.** The EML table
editor is plugin code (eml-edit-table-launch / -editor); its commit
path emits a recorded step like any other command — the actual Set
operation(s) plus a plain-language phrase ("Changed f0 in row 1 from
100 to 4242"). This is the complete fix for every edit made through
the plugin's own door, and it rides the recorder-publication family.

**Tier 2 — ALL OTHER edits are caught by the FINGERPRINT TRIPWIRE.**
Praat's native editor and foreign scripts cannot be hooked, so the
recorder does not try. Instead it captures the table's content
fingerprint (the result store's per-level fingerprint machinery — the
store lands first, already sequenced) at recording start and at each
recorded step. At flush, any mismatch between what a step analyzed and
what the recording started with writes the WARNING BLOCK at the top of
the emitted script: the table was modified during this recording; the
script reproduces the recorded numbers only if the same modifications
are applied first — naming the step(s) where the fingerprint moved.
This implements the report's "smallest change" as detection rather
than hooking, so it catches every edit route including the ones nobody
anticipated. The roundtrip's 4242 scenario — F = 1.0103 recorded
against F = 231111.1111 replayed, clean run, no warning — becomes the
permanent negative control: with the tripwire, that replay must open
with the warning block.

**Tier 2 upgrade (Ian's measurement, 21 Aug):** Ian demonstrated in a
live GUI session that a native-TableEditor hand edit ENTERS PRAAT'S
COMMAND HISTORY in replayable script syntax ("Set numeric value: 1,
\"Speaker\", 1.5"), while a plugin-script edit appears only as a bare
"runScript:" with its internal commands invisible — the two recorders
are exact complements, which also confirms the bespoke recorder is
necessary, not redundant. Programmatic access probed and CLOSED on both
versions: 6.6.30 and 7.0.01 alike have no script-context "Clear
history" and no history$() — harvest by code is impossible (PKB entries
due). Therefore the warning block gains RECOVERY INSTRUCTIONS: it tells
the user their exact edits are recoverable — open a new Praat script
window, Edit > Paste history, find the Set lines — and the emitted
script carries a marked "paste recovered edits here" section directly
under the warning, positioned so pasted history replays before the
analysis steps. The negative-control leg asserts the instructions and
the marked section appear whenever the tripwire fires.

**Ceiling investigation CLOSED (21 Aug, three measured negatives):**
(1) the command history is programmatically unreachable in every
context — script, editor-run script (Ian: "Clear history" not
recognized inside a ScriptEditor), both 6.6.30 and 7.0.01; (2) Praat's
tracing facility, though scriptably toggleable (Debug: 1, 0 on /
Debug: 0, 0 off — a new PKB fact, verified Linux 6.6.30 and Ian's
macOS build), records NOTHING for a hand-committed TableEditor edit —
Ian's trace shows the edit only as charDraw glyph paints, no dispatch,
no values; (3) no third channel found. The tripwire + recovery design
therefore sits at Praat's actual ceiling, not an assumed one. PKB
entries: the Debug toggle; TableEditor commits are untraced; history
is human-only (Paste history).

## Three small items, ruled

1. **Provenance line:** do NOT carry the original verbatim — a replay
   claiming "from: analysis dialog" would lie. The emitted script sets
   its own: "from: recorded script (recorded <date>, originally
   analysis dialog)". The report's suggestion, amended for honesty.
2. **Auto-axis comment:** adopt the one-word class fix — the resolved
   range comment states it is descriptive, not binding: "on the
   recorded data this resolved to −2000 .. 6000; auto adapts to other
   data." Same wording rule anywhere a resolved-from-data value is
   quoted in a comment.
3. **The two unasserted pen settings** (arrow size, speckle size): add
   both to the theme's re-assert set beside the colour/width/font
   asserts the immunity measurement counted (121/84/64 sites) — the
   untested channel closes by construction, and one hostile leg on a
   speckled LTAS figure proves it.

## Records and relays

- PKB/harness recipe: two measured Praat 6.6.30 facts from the report's
  substitutions — the shipped stop-recording menu command crashes Praat
  when invoked from a script, and the save panel crashes headless. Both
  are rig constraints future harnesses must know.
- The roundtrip procedure itself is adopted as a COMMITTED HARNESS (the
  session==replay family): its legs, fixtures, and the dialog-ectomy
  copies (with cut regions kept inspectable) enter the tree with the
  usual one-commit-per-harness discipline, so the roundtrip re-runs on
  every recorder change instead of being a one-time demonstration.

Sequencing: all of it is 1.0 work in the item-9 recorder-publication
family; the tripwire follows the store's fingerprint machinery, which
is already ordered to land first. Ledger rows: the edit gap (fixedBy
tier 1 + tier 2 commits), the file-open step (fixedBy its commit,
closing the designed-never-built finding), the provenance line, the
axis comment, the pen-settings channel.

— verification session
