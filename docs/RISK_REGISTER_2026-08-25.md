# Risk register — door and unification round

Verification session, 25 Aug 2026. The named risks in this round, each
with the guard already in place and what the end inspection specifically
watches. This document changes only through Ian; Opus treats it as part
of the work order.

## R1. Cross-lane interactions in the reprint rule

The reprint decision compares report text, and three lanes change report
text. One instance is already caught and fixed (the explanations toggle
would have triggered a false "data changed" — the comparison now runs on
a canonical rendering, punch item 1.2), which means the class is real and
probably not empty.

Guard: canonical-form comparison; analysis-identity settings compared as
identity, not text (1.4).
Inspection: the whole-house pass runs ONLY after every text-changing lane
has landed, and includes a settings-permutation drive — same data, every
display setting toggled between draws — asserting zero reprints.

## R2. The re-baseline wave masking an unintended change

Lanes 2, 3, and 6 legitimately change nearly every report, so every
transcript digest, roundtrip byte-comparison, and photograph re-baselines
at once. A re-baseline is where an unintended change hides inside
expected churn.

Guard: one batched re-drive at the end (standing ruling); acceptance
fixtures assert NUMBERS, not digests.
Inspection: for every re-baselined artifact, the inspection diffs the
numeric content against the pre-round values and requires each numeric
change to be named by a punch item. A digest moving is expected; a number
moving without a punch item is the alarm.

## R3. The wizard build is one sequential file

3,134 lines, goto-chained, so parity cannot fan out to parallel agents.
The file's historical defect class is exactly what parity touches: page
re-entry and preserve steps.

Guard: build one branch family at a time with the field-name and
cold-start checks run between each; the new flow-invariant check (4.9)
makes the preserve-step bug unwritable; approved language is verbatim
from the batch.
Inspection: every wizard branch driven end to end under the display
harness, including Back-and-return on each page with typed values
asserted to survive.

## R4. The frozen-choice lint depends on a hand-built map

The check (8.4) needs a correspondence map — which parameter on one door
matches which on another. A wrong or incomplete map makes the check noisy
or blind, and the vacuity kit only catches blind.

Guard: the map is committed as a reviewed fixture, author is never
verifier on it, and the check reports how many correspondences it
examined.
Inspection: the verification session re-derives a sample of the map
independently from the dialogs and diffs it against the fixture.

## R5. Seven of Sol's twelve findings were never source-verified

Five of twelve were independently confirmed (all held). The remainder
inform census legs but could aim effort at behavior that changed since
Sol's commit anchors.

Guard: census legs measure rather than trust — a phantom finding produces
a green leg, not a wrong fix.
Inspection: any census leg that comes up green on first contact is
checked against Sol's commit provenance before being recorded as "never
was red" versus "fixed in between."

## R6. Shipped comments carry defect history against the pre-release policy

About 37% of the shipped tree is comments, and a real fraction narrates
past defects — valuable, and in the wrong place per the 16 Aug ruling.

Guard: the migration criteria ride the existing docs step before the
release tag: narrative history moves to the audit record and commit
messages; current-behavior rationale stays.
Inspection: a sampling pass over shipped files for past-tense defect
narration after the migration.

## Retired risks

- The verification container could not run a display (Sol's could not):
  tested 25 Aug — Xvfb starts and answers here, so the end inspection is
  executable in this environment.
- Open design questions reaching Opus: none remain; every ruling is
  closed and recorded in the punch list and language batch.
