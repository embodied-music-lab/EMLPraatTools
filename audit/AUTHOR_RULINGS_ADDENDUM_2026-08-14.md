> **Historical record (2026-08-14).** Current finding status lives in `audit/FINDINGS_MACHINE.json`.

# Author rulings — 14 Aug 2026 stress-test session (addendum for the managing session)

Given by Ian in the stress-test thread after report delivery. These resolve the three
open design questions in §10 of EML_AUDIT_REPORT_2026-08-14.md.

## 1. Matrix / TableOfReal pathways: MAKE OPERABLE (not unregister)
Mechanism (verified): conversion Matrix→TableOfReal→Table succeeds; the crash is
downstream — unlabeled row labels yield an all-undefined `row` column, and the wrapper's
numeric probe (`Get all numbers in column:`, eml-output.praat ~:2849 region) dies on it
before the dialog opens. Fix shape:
- default row labels (r1..rn) at conversion time, or skip/classify the label column in
  the probe; probe should classify column types, never assume numeric;
- separately: eml-describe-table.praat:36 does its own Table-only refusal and never
  reaches @emlWrapperInit — route it through the same coercion as the other wrappers.
Evidence: /tmp/aud67 (v67.03/04/07/09 screenshots), evidence zip.

## 2. Stereo channel handling: ABSOLUTELY NECESSARY — wire it
The Mix-to-mono / Left / Right choice must be reachable when an audio object is stereo.
@emlHandleStereo/@emlCheckChannels/@emlApplyChannelChoice exist (eml-graph-procedures.praat
:3876–3942) with zero callers; the only live copy of the dialog is inline in the tabled
batch script. Wire the existing procedures into the EML Graphs flow for Sound (and any
derived-object path where channel choice matters, e.g. before To Pitch).

## 3. Recorder replay: NON-INTERACTIVE — "just output the output"
A replayed recording must not reopen any dialog (the current Save-panel reopen is wrong).
This is the SPSS model (dialogs author syntax; running syntax is headless), same as Stata
do-files / R scripts / Praat's own paradigm. Consequences:
- recorded save steps embed the chosen folder + base name as literals;
- REGENERATE the timestamp at replay (also dissolves the stamp-accretion defect
  NEW-G11-5);
- users who want different settings run the workflow fresh, not the recording;
- pair with the include-block portability fix (NEW-G11-1) — SPSS's answer is FILE
  HANDLE / relative paths; the emitted script should be honest about, or solve,
  machine-portability.
