# Edit Table — review and proposed improvements

6 August 2026. Requested by the author. **This is a proposal. No wrapper code
was changed.**

See also the addendum at the foot: Praat's own TableEditor turns out to be an
editor with the editing removed — a cell cursor, a formula-bar-shaped text
field and a wired-up undo menu, with no binding between them and nothing
exposed to scripting. One integration point IS finished and we are already
relying on it without having named it.

---

## What it is

Praat's own TableEditor is read-only. Edit Table exists to give a Table object
what Praat does not: click-to-navigate cell editing with auto-advance,
find/replace, and structural operations (add/insert/delete rows and columns,
rename columns).

Three files, 623 lines:

| File | Lines | Role |
|---|---:|---|
| `eml-edit-table.praat` | 562 | All the work |
| `eml-edit-table-launch.praat` | 37 | Objects-window button. Opens the editor, then hands off with `"button"` |
| `eml-edit-table-editor.praat` | 24 | TableEditor Edit-menu entry. Hands off with `"editor"` |

The two thin wrappers exist because `View & Edit` opens a duplicate window if
the editor is already open, and because the teardown differs: only the
button path closes the editor it opened. That split is correct and should
stay.

---

## Confirmed defects

Each verified by running Praat, not by reading. The probe output is quoted.

### E1 — Typing a word into a numeric column silently destroys the column

**Severity: high. This is the one that matters.**

Every write goes through `Set string value:` (line 174). Praat accepts it. The
column stops being numeric, and `Get all numbers in column:` then returns
**alphabetical ranks instead of values**, silently:

```
before edit, Get all numbers: 70.5 71.5 72.5
after typing abc into row 2:  1 3 2
```

70.5, 71.5 and 72.5 became 1, 3 and 2. Nothing warns, nothing marks the
column, and the Table looks fine in the editor.

The analysis layer is protected as of the D96 work — `@eml_classifyCell`
rejects the cell by type and names it — so a plugin analysis will refuse
rather than compute on ranks. **But nothing protects the file.** Save that
table to CSV, or use any of Praat's own Table commands, and the ranks
travel. The editing tool creates the exact condition the extraction layer
was hardened against.

### E2 — Destructive operations execute with no confirmation and no undo

`Delete row` and `Delete column` act the moment the button is pressed
(lines 452, 520). Praat Tables have no undo. A mistyped row number is
unrecoverable, and the tool is aimed at people editing research data.

### E3 — Out-of-range deletes silently delete something else

`.target = min (row_number, .nRows)` (line 455). Ask to delete row 500 of a
20-row table and it deletes **row 20**. The user asked for something
impossible and got a different destructive action, with no message. Insert
has the same clamp at line 441.

### E4 — Duplicate column names are accepted, then deleted by name

Confirmed: renaming column 2 to match column 1 gives a table whose labels are
`[a] [a]`. `Delete column` then issues `Remove column: column_to_delete$` —
by **label** (line 522). With duplicates, which one goes is not determined by
anything the user can see:

```
duplicate column names accepted: [a] [a]
after removing by label -> 1 column(s), remaining label [a]
```

The rename dialog can create the state; the delete dialog then cannot address
it unambiguously. Note the neighbouring `Rename column` correctly uses the
numeric index — the two dialogs disagree with each other.

### E5 — Column names may contain commas and spaces

Confirmed: `my column` and `a,b` are both accepted as labels. The comma no
longer breaks CSV export (RFC 4180 quoting was added on 6 August), but a
label containing a comma remains a hazard for every other consumer, and
Praat's own column-name lookups become ambiguous.

### E6 — The Row control is a dropdown with one entry per row

`optionmenu: "Row"` builds an option per row (line 159). On a 40-row demo
table that is fine. On a real corpus of several thousand rows it is a
dropdown of several thousand items, which is not usable — and this tool's
whole purpose is editing real tables.

### E7 — Placeholder attribution shipped to users

All three files carry `Script author: [Your name here]` and
`Code generation: Claude (Anthropic)` in their headers. The first is an
unfilled template. The second is the standing-instruction question already
raised for the other 35 files — flagged here, not acted on.

---

## Proposed improvements

Ranked by what they prevent, not by effort.

### P1 — Type-aware cell writes (fixes E1)

Before writing, classify the column and the proposed value using
`@eml_classifyCell`, which already exists and is already validated
(33 checks in `phase1/test-extract.praat`).

- Column currently numeric, new value not numeric → **refuse by default**,
  with the reason named: *"Column SPL_dB is numeric. Writing "abc" would
  make Praat read the whole column as alphabetical ranks rather than values.
  Values 70.5, 71.5, 72.5 would become 1, 3, 2."*
- Offer an explicit override for the case where the user genuinely intends
  to make the column textual, and say what it costs.
- Column already textual → write freely; nothing to lose.

This reuses the D96 classifier rather than adding a second opinion about what
counts as numeric. One classifier, one answer, whether the cell is being read
or written.

### P2 — Confirm before destroying (fixes E2, E3)

Delete row and delete column get a confirmation step that **states what will
be lost**, not a generic "Are you sure?":

> Delete row 14 of 20?
> `S014, 71.2, Soprano, 0.31`
> This cannot be undone.

Out-of-range requests are **refused rather than clamped**: *"Row 500 does not
exist; the table has 20 rows."* Silently retargeting a delete is worse than
declining it.

### P3 — Address columns by index, everywhere (fixes E4)

`Delete column` switches from `Remove column: <label>` to
`Remove column (by number): <index>`, matching what `Rename column` already
does. Then a duplicate label cannot make the operation ambiguous.

Separately, `Rename` and `Add column` reject a name that duplicates an
existing one, and reject empty names.

### P4 — Validate column names on entry (fixes E5)

Refuse commas and leading/trailing whitespace. Allow internal spaces but warn
once that reports display underscores as spaces, so `my column` and
`my_column` will look identical in output — which is D6 arriving from the
editing side.

### P5 — Replace the row dropdown above a threshold (fixes E6)

Under ~100 rows, keep the dropdown; it is genuinely convenient. Above it,
switch to `natural: "Row"` with the range stated in the comment. Same dialog,
one branch.

### P6 — A dry-run for Replace All

`Rep All` currently reports the count after the fact. It should report the
count **before**: *"This will change 47 cells in 3 columns. Proceed?"* Same
scan, run once, acted on only if confirmed.

---

## Not proposed, deliberately

- **Undo.** Praat gives no undo for Table objects, and building one means
  snapshotting the table on every edit. That is a real feature with real
  memory cost, and it is a decision about scope rather than a defect fix.
  If wanted, the cheap version is a single snapshot taken when the editor
  opens plus a "Revert all changes" button.
- **Structural rework of the three-file split.** It is correct as it stands.
- **The attribution headers.** Author's call; raised in the verification
  record with the other 35 files.

---

## What needs a ruling

1. **P1's default.** Refuse-with-override, or warn-and-allow? Refusing is
   safer and will occasionally annoy someone who meant it. My recommendation
   is refuse-with-override, because the failure it prevents is silent and the
   annoyance it causes is not.
2. **Whether P6 and the revert-snapshot are in scope**, or whether this pass
   should be confined to E1–E5, which are defects rather than features.

---

# Addendum — what Paul actually built, and whether we can wire into it

Investigated at the author's suggestion: *"imagine whether there is a way to
simply wire into whatever infrastructure Paul has halfheartedly built for
this to be a native feature. You can tell that he is thinking about it, and
he's just not finished it."*

That reading is correct. Praat 6.6.30's TableEditor is not a viewer with a
text box bolted on. It is an editor with the editing removed. Findings below
are from driving it, not from reading about it; screenshots are committed.

## What is built

**A real cell cursor.** Clicking any cell highlights it, and the highlight is
cell-precise — it sizes itself to the cell's contents, not the column.
Clicking row 4 / column 3 highlights exactly that cell.
(`evidence/shots/praat_tableeditor_cell_cursor.png`)

**A text entry field**, full width, sitting immediately above the column
headers — exactly where a spreadsheet's formula bar goes. There is no other
reason for that widget to exist in a read-only viewer.

**An undo framework.** The Edit menu carries **Can't undo (Ctrl+Z)**,
**Can't redo (Ctrl+Y)** and **Clear undo history**, all greyed out. Those are
not decoration: they are the standard menu of Praat's undoable-editor base,
present with keyboard shortcuts and permanently disabled because nothing ever
registers an undoable action. A read-only viewer would not carry them.
(`evidence/shots/praat_tableeditor_undo_menu.png`)

**Live refresh — and this one is finished.** Writing to the Table from a
script while the editor is open updates the view immediately: a changed cell,
a changed number, and an appended row all appeared, and the column widths
re-flowed to fit the new content. The cell cursor held its position through
the redraw. (`evidence/shots/praat_tableeditor_live_refresh.png`)

## What is not built

**The field does not read the cell.** Select a cell and the field stays empty.
Select a different cell and it keeps whatever was in it before.

**The field does not write to the cell.** Typing `CHANGED` and pressing Return
leaves the table untouched. Verified by reading the Table back through
sendpraat rather than by looking at the screen.

**No commit gesture works.** Return in the field, typing directly with a cell
selected, and double-clicking a cell all leave the data unchanged.

**Nothing is exposed to scripting.** Entering `editor: "Table X"` succeeds,
but the editor registers no accessor for its own state — `Get selected cell`,
`Get row`, `Get column` and `Get text` are all unknown commands. *(Four
plausible names probed, not an exhaustive enumeration of the command table.)*

So: a cell cursor and an undo stack with no commit path between them, and no
way for a script to see either.

## Can we wire into it?

**No — not the editing.** The cursor lives in C++ and is not queryable, the
field has no accessor, and the undo stack has nothing registered. There is
nothing for a plugin to hook.

**But one integration point IS finished, and we are already using it without
having named it: the live refresh.** That reframes the architecture. The
current two-window arrangement — TableEditor open alongside the EML dialog —
is not a workaround for a broken editor. It is a live spreadsheet view beside
an editing surface, and it works today. Every write the EML dialog makes
appears in the TableEditor immediately.

The second finished integration point is the one that puts our command in the
TableEditor's Edit menu at all. Both are real; neither was being described as
a feature.

## What this changes in the proposal

**Keep the two-window design and name it.** The launcher should say what the
TableEditor is for — a live view of the table as you edit it — rather than
opening a window the user reasonably assumes is broken because typing in it
does nothing. That is a comment and a dialog line, not a rewrite.

**One request worth sending upstream.** Two accessors would close the only
seam that matters:

    Get selected row
    Get selected column

With those, the EML dialog could open on the cell the user just clicked,
instead of on row 1 or on wherever it was left last time. That is the whole
gap between "two windows that cooperate" and "one editor". It is a small,
concrete, well-specified request — two read-only queries against state the
editor already maintains — and it is the kind of thing Paul has historically
added when a researcher asks for it with a use case attached.

A larger request, worth mentioning but not worth leading with, is to finish
the field binding itself: populate on selection, commit on Return, register
the change with the undo stack that is already sitting there. That would make
the EML editor unnecessary for cell editing — which would be a good outcome,
and it would leave the structural operations (insert, delete, rename) as the
part still worth keeping.

**Nothing in E1–E7 changes.** The defects are in our wrapper and remain ours
to fix, whatever Paul does. In particular E1 — typing a word into a numeric
column silently converting it to alphabetical ranks — would become *more*
urgent if the native field ever starts committing, because it would then be
reachable without going through our dialog at all.
