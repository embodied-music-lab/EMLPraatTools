# Handback to PraatGen — install from disk, draft 2 → draft 3

Draft 2 is accepted except for the items below. Carried forward as
correct and not to be relitigated: the platform command matrix, the
staging and deletion rails, copy-only placement, archive-verify
gating placement, the setup.praat scanner with continuation-line
joining and separator exclusion, the timestamped archive naming, the
results-file guard, and the header block exactly as Ian instructed
it (the attribution block stands; do not modify it).

## 1. Selection booleans: sanitized folder names, not Install N

Ian's ruling replaces the `Install <n>` scheme. For each found
folder:

- The boolean's LABEL is the folder name with every character that
  is not a letter, digit, or underscore replaced by a space.
  (`plugin_my-tools` → label `plugin_my tools`.) Every name begins
  with lowercase `plugin_`, so the lowercase-start requirement for
  variable derivation is automatically met.
- Praat derives the variable by converting spaces to underscores:
  the DERIVED NAME. Compute it per row (sanitize, then space →
  underscore) and store it in a parallel array; read selections
  back by constructing exactly these derived names, row by row.
- Annotations and the relative path stay in the `comment:` line
  above each boolean, including the underscores-as-spaces display
  name Ian specified. Refusal and summary messages use the EXACT
  folder name.

New refusal, BEFORE the dialog opens: if two found folders produce
the same derived variable name, stop, naming both original folder
names and the collision, and suggest installing them one at a time
via the folder option. This covers literal duplicate names as the
special case. The after-selection duplicate check from draft 2 is
REMOVED — it is superseded by this earlier, stronger check.

## 2. The walk: in-memory growable vector queue, no files

Replace the file-backed queue entirely. The pattern:

- One string vector used as a queue with two indexes: `head` and
  `tail`. Initial capacity 64.
- Push: write at `tail + 1`, increment `tail`. Pop: read at `head`,
  increment `head`. Nothing is ever shifted or rewritten.
- When a push would exceed capacity: allocate a vector of twice the
  size, copy the LIVE entries (`head` through `tail`) to its front,
  reset `head` to 1 and `tail` to the live count, continue. The
  doubling is the unbounded guarantee — no cap exists anywhere.
- The walk is otherwise unchanged: pop a folder, list its
  subfolders once with `folderNames$#`, record `plugin_` matches,
  push every subfolder except `__MACOSX`.
- The results list may remain the small file it is (one line per
  FOUND plugin), or use the same vector pattern — either is fine.
- Delete the queue-file machinery and `kQueueName$`.

## 3. Dead constants

Delete `kPrefixLen` (unused, and a second statement of a fact
`kPluginPrefix$` owns) and `kMsgWalkOverflow$` (unreachable — the
unbounded queue has no overflow). Nothing ships unused.

## 4. Drive-confirmation list (verify these during acceptance, do
not redesign around them)

- Element assignment into a string vector (`queue$# [i] = path$`)
  works at 6.6.30. If it does not, report it — the fallback is a
  rounds-based two-file walk, adopted by ruling, not improvised.
- A boolean labeled with an underscore-containing name derives its
  variable verbatim at 6.6.30.
- `endPause` argument semantics in both dialogs.
- `chooseFolder$` trailing-slash behavior (a trailing separator
  would make baseName return empty — confirm it does not occur, or
  strip a trailing separator in baseName).
- Windows `xcopy /E /I /Q` produces the correct folder shape
  (documented behavior; remains marked unverified until driven on
  real hardware).

## 5. Acceptance list changes

- Replace the two `Install <n>`-specific cases with: a folder named
  with a dash (`plugin_my-tools`) displays sanitized, installs
  correctly under its exact original name; and an archive
  containing `plugin_my-tools` AND `plugin_my_tools` refuses before
  the dialog, naming both.
- The two-same-named-folders case moves from "refuse after
  selection" to "refuse before the dialog".
- The large-tree completeness case (several hundred folders) stays,
  now also serving as the vector-queue growth test — it must force
  at least two capacity doublings.
- All other acceptance cases from rev 4 stand.
