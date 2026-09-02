# Scoped ask for PraatGen — canonical-name proposals in install-from-disk

Revision to `install-from-disk.praat` (currently drive-green at four
commits of evidence). Every design decision below is made; the
normative table in §9 is part of the specification, ships as a
fixture, and outranks any prose reading you form. Where spec text
and table disagree, STOP and report the row — do not resolve it.

## 1. Why (context, not instructions)

Hosts and users mangle plugin folder names: GitHub Download-ZIPs
append `-master`/`-main`/branch names, release archives append
version tags, commit archives append hex hashes, Bitbucket and
Zenodo snapshots PREPEND `owner-`, macOS and browsers append
` copy` / ` (2)`, and re-zipping wraps `plugin_X/plugin_X/`. A
mangled name breaks two things: future duplicate installs, and any
script inside the plugin that references its own folder by name.
The fix is a rename OFFER, applied by default, never forced.

## 2. Terminology

- LITERAL name: the folder name as found.
- PROPOSED name: the canonicalization output of §3-§5.
- INSTALL name: proposed name normally; literal name when the §7
  toggle is on.

## 3. Candidate set (extends the existing search)

The existing complete recursive search stands. It now collects TWO
classes:

- TRUE matches: folder name starts with `plugin_` (unchanged).
- NEAR-MISSES: folder name contains `plugin_` at a position past
  the start. Prefix rule: the candidate stem is the substring from
  the FIRST occurrence of `plugin_` to the end (then §4 applies to
  that). Near-miss rows are gated by §5's evidence rule.

`plugin_` is matched case-sensitively (Praat's own activation rule
is the authority).

## 4. Suffix rule (applied to every candidate)

Strip trailing junk tokens, repeatedly, MAXIMUM 3 iterations. One
junk token = a separator (`-`, `_`, `.`, or space) followed to the
end of the name by one of, case-insensitively:

a. a branch word: master, main, develop, dev, trunk, release,
   latest, head
b. a hex hash: 7 to 40 characters, all 0-9a-f
c. a version: optional `v`, then digits with up to three
   dot-separated groups, optional single trailing letter
   (`1`, `2.0`, `v1.2.0`, `1.2.0b`)
d. a copy artifact: `copy`, `copy` + digits, or a parenthesized
   number `(2)` (its separator is a space)

HARD GUARD on every iteration: if stripping would leave a result
of `plugin_` or shorter, do not strip; stop iterating. This is
what keeps `plugin_dev`, `plugin_master`, and `plugin_2` intact —
their apparent suffix IS the stem.

If after all rules the proposed name equals the literal name, the
folder is UNCHANGED (no annotation, no offer — the common case).

## 5. Content evidence (overrides the heuristic)

The existing setup.praat scan extends to a name-evidence scan: in
every `.praat` file in the folder (recursive, string matching only,
never execution, skip any file over 1 MB), collect every maximal
match of `plugin_` followed by name characters (letters, digits,
`_`, `-`). Compare each match against exactly two strings — the
proposal and the literal. References to OTHER plugin names are
IGNORED (they are dependencies, not identity).

RESOLUTION DISCRIMINATOR (a match equal to proposal or literal is
still not automatically identity — a full-path reference to a
DIFFERENT plugin can coincidentally carry the same name, e.g. a
fork of `plugin_utils` arriving as `plugin_utils-master` while
depending on the real `plugin_utils`): extract the SUBPATH that
follows the match — the characters after it up to the first double
quote, whitespace, or end of line, with any leading `/` removed. A
match COUNTS as evidence only when (a) the subpath is empty (a
bare root reference), or (b) a file or folder at that subpath
exists INSIDE the folder under evaluation. A match whose subpath
does not resolve inside this folder is an EXTERNAL reference to a
same-named plugin elsewhere and is ignored — it neither confirms
nor cancels.

- A match equal to the PROPOSAL: the proposal is CONFIRMED.
  Annotation adds: "name confirmed by the plugin's own scripts".
- A match equal to the LITERAL (when literal differs from
  proposal): the rename is CANCELLED for this folder — proposed
  name reverts to literal. Annotation adds: "keeps its folder name
  — the plugin's scripts reference it". This protects an author
  who deliberately ships `plugin_X_v2` and self-references it.
- Neither: the heuristic stands. A renamed row's annotation adds:
  "renamed from <literal>".

Near-miss gating: a near-miss row appears in the dialog ONLY if
its proposal is content-CONFIRMED (checked by default) OR the
folder has a top-level setup.praat (listed UNCHECKED, annotation
"name guessed from folder <literal>"). Other near-misses are
ignored silently — `my_plugin_backup` full of data files is not a
plugin.

## 6. Ancestor collapse (the double-zip wrapper)

When found folder A is an ancestor of found folder B and their
PROPOSED names are equal, drop A entirely — keep the innermost.
No row is shown for A. (No real plugin contains itself; the outer
copy is a wrapper artifact.) Folders with UNEQUAL proposals keep
the existing behavior: both rows, nesting visible.

## 7. Dialog changes

- Rows are keyed on PROPOSED names: the boolean label, the
  sanitize/derive machinery, the pre-dialog derived-name collision
  check, and the already-installed check all operate on proposed
  names. (This correctly refuses an archive holding
  `plugin_X-master` and `plugin_X-1.2.0`, which are one plugin.)
- The description comment shows, in order: display name,
  command-count annotation (existing), the §5 annotation when one
  applies, already-installed annotation (existing), and
  "-- at <relative path>" (existing).
- On the FINAL page only, above the buttons, one extra boolean:
  label `Use folder names exactly as found`, default off. When
  checked at OK: install names are literal names for every row;
  re-run the collision and already-installed logic against literal
  names, and if a collision appears, exit with the existing
  collision message before installing anything.

## 8. Placement, verify, summary

Placement copies the found folder to
`preferencesDirectory$/<install name>` (the copy-destination name
is the only thing that changes; source is untouched as before).
Verify checks the install name. Summary lines: `<install name>`
plus, when renamed, ` (renamed from <literal>)`, composing with
the existing archive note.

## 9. NORMATIVE TABLE — ships as `harness/canonical_names.tsv`,
tab-separated, exactly these columns:
literal, has_setup (0/1), content_ref
(none|literal|proposal|literal_external|proposal_external — the
_external forms mean the reference's subpath does NOT resolve
inside the folder, per §5's discriminator),
expected_proposal, expected_row (row|row_unchecked|dropped),
note

    plugin_tgutils-master	1	none	plugin_tgutils	row	branch word
    plugin_X-main	1	none	plugin_X	row	branch word
    plugin_X-develop	1	none	plugin_X	row	branch word
    plugin_X-1.2.0	1	none	plugin_X	row	version, v stripped by GitHub
    plugin_X-v1.2.0	1	none	plugin_X	row	version, GitLab keeps v
    plugin_X-2	1	none	plugin_X	row	bare numeric version
    plugin_X-a1b2c3d	1	none	plugin_X	row	7-hex sha
    plugin_X-0123456789abcdef0123456789abcdef01234567	1	none	plugin_X	row	40-hex sha
    plugin_X copy	1	none	plugin_X	row	macOS copy
    plugin_X (2)	1	none	plugin_X	row	browser duplicate
    plugin_X-main (1)	1	none	plugin_X	row	two iterations
    plugin_dev	1	none	plugin_dev	row	guard: suffix IS stem
    plugin_master	1	none	plugin_master	row	guard: suffix IS stem
    plugin_2	1	none	plugin_2	row	guard: suffix IS stem
    plugin_praat7-main	1	none	plugin_praat7	row	digit in stem survives
    plugin_X_v2	1	literal	plugin_X_v2	row	author-versioned, content cancels
    plugin_X_v2	1	literal_external	plugin_X	row	same-named EXTERNAL ref, discarded, heuristic stands
    plugin_X_v2	1	none	plugin_X	row	no self-reference, heuristic stands
    plugin_utils-master	1	proposal_external	plugin_utils	row	fork depending on real plugin_utils; external ref discarded, rename by heuristic only, no "confirmed" annotation
    plugin_utils	1	none	plugin_utils	row	clean name untouched
    owner-plugin_X-a1b2c3d	1	none	plugin_X	row_unchecked	near-miss, setup present, unconfirmed
    owner-plugin_X-a1b2c3d	1	proposal	plugin_X	row	near-miss, content-confirmed
    my_plugin_backup	0	none	plugin_backup	dropped	near-miss, no setup, no confirmation
    jjatria-plugin_utils-1a2b3c4	1	none	plugin_utils	row_unchecked	Zenodo/Bitbucket shape

(The double-zip `plugin_X/plugin_X/` ancestor case is a structural
fixture, not a name row: expected = ONE row for the inner folder.)

## 10. Structure requirement

The entire §3-§6 logic lives in ONE procedure,
`emlpmL_canonicalName`, taking the literal name plus the content-
evidence result and returning the proposal — so the harness drives
the WHOLE normative table headlessly through the real procedure.
The content-evidence scan is its own procedure. Main-sequence code
only wires them.

## 11. What does not change

The search walk, the queue, staging and deletion rails, unpack,
copy-only placement, archive-on-replace, pagination, and every
message not named here. The existing drive evidence stands; this
revision must not regress any prior acceptance case.

## 12. Acceptance

- Headless: every row of `canonical_names.tsv` driven through
  `emlpmL_canonicalName`; any mismatch names the row. The
  double-zip structural fixture yields one row (innermost).
- GUI: install `plugin_tgutils-master` → installed as
  `plugin_tgutils`, summary shows the rename; same archive with
  "Use folder names exactly as found" checked → installed as
  `plugin_tgutils-master`; an archive with `plugin_X-master` and
  `plugin_X-1.2.0` refuses on proposals; the near-miss unconfirmed
  case appears unchecked with its annotation.
- Regression: the full prior acceptance set re-driven green.
