# v4.1 → v5 polish: four pinned items, delegated to agents

1 September 2026. All decisions made here; agents execute
mechanically. PraatGen is not involved in this round.

## 1. Namespace rename (mechanical)

The project namespace is `eml`; `emlpmL_`/`emlpmB_`/`k...` were
spec-side inventions and are retired. In the installer, its
harness, and the bootstrap:

- Procedures: `emlpmL_<name>` → `emlManager<Name>` (first letter of
  the old name uppercased): `emlpmL_canonicalName` →
  `emlManagerCanonicalName`, `emlpmL_stripOnce` →
  `emlManagerStripOnce`, etc. Bootstrap: `emlpmB_<name>` →
  `emlManager<Name>` likewise (no collisions exist between the two
  files' procedure sets except conceptually shared names — the
  bootstrap and installer are separate scripts and may share the
  new names).
- Constants: `k<Name>` / `k<Name>$` → `emlManager_<name>` with the
  first letter lowercased: `kMsgCancelled$` →
  `emlManager_msgCancelled$`, `kFloorVersion` →
  `emlManager_floorVersion`.
- Flag: `emlpm_harnessMode` → `emlManager_harnessMode` (installer
  and harness together).
- Every call site, output-variable reference
  (`emlpmL_x.y` → `emlManagerX.y`), and the harness follow.
- Folder-name constants' VALUES (`eml_pm_staging`,
  `eml_pm_archive`, filenames) are UNCHANGED — this is a code
  identifier rename only, not an on-disk rename.

Verification (the executing agent runs these itself): zero
remaining occurrences of `emlpmL_`, `emlpmB_`, `emlpm_`, and of
`^k[A-Z]` assignments in the three files; the canonical harness
still returns 25 pass 0 fail; both files still parse (harness-mode
include probe for the installer; a library-include probe for the
bootstrap).

## 2. Bootstrap exit buttons (mechanical, same agent)

In the bootstrap script, every button whose action stops the
script is relabeled `Quit` (was `Cancel`); the confirmation
dialog's action button stays `Install`. This applies the project's
standing rule already adopted in the installer at 4.1.

## 3. Version-aware already-installed annotations (new logic)

New procedure `emlManagerCompareVersions: .a$, .b$` → `.cmp`
(-1 a older, 0 equal, 1 a newer): split both on `.`, compare
numerically component-wise, missing components count as 0; a
non-numeric component makes that component compare as plain text.
(This is deliberately the comparator the future catalog layer
needs.)

New procedure `emlManagerReadVersion: .folder$` → `.version$`
(first line of a top-level `VERSION` file, trimmed of whitespace;
empty string when the file is absent).

When a candidate's install name collides with an installed folder,
the already-installed annotation is replaced by one of, verbatim
(X = installed version, Y = candidate version):

- both have VERSION, Y newer: `already installed (you have X; this
  archive is Y); replacing keeps the current copy in the archive
  folder`
- both, equal: `this version (X) is already installed; replacing
  keeps the current copy in the archive folder`
- both, Y older: `OLDER than installed (you have X; this archive
  is Y); replacing keeps the current copy in the archive folder`
- either side lacks VERSION: run the difference probe — the sorted
  relative file lists of both trees are equal AND the two
  setup.praat files are byte-equal (when both exist) →
  `already installed; appears identical to the installed copy;
  replacing keeps the current copy in the archive folder` —
  otherwise `already installed; differs from the installed copy;
  replacing keeps the current copy in the archive folder`.

Default checkbox state for colliding rows changes with the
information: newer or differs → CHECKED (the current behavior);
equal, appears-identical, or older → UNCHECKED (installing is not
the recommended action; the user can still check it). Non-colliding
rows are unaffected.

Headless acceptance rows (drive through the comparator):
1.2 vs 1.10 → candidate newer when candidate is 1.10; 1.2.0 vs
1.2 → equal; 2 vs 1.9.9 → newer; 1.2 vs 1.2b → text comparison on
component 2. Plus one staged-folder case per annotation branch.

## 4. Selection-dialog wrap fix (small logic, GUI-verified)

A description longer than 78 characters is split at word
boundaries into successive `comment:` lines (each its own widget,
so nothing renders under the following checkbox). No text is
shortened or removed. GUI verification: re-shoot the v4.1 G1 case
and confirm the full annotation is visible with no overlap.

## 5. Regression gate

After all four items: canonical harness 25/25 (plus the new
comparator rows), the 17-case headless suite green against the
renamed file, and three GUI spot checks (G1 rename flow with the
wrap fix visible, G2 literal toggle, one equal-version collision
showing its new annotation and unchecked default).
