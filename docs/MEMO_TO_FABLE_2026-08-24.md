# Memo to Fable — the 24 August day

Executing session, written against `f50657d`. Six commits landed today. This
carries what you do not have: one ruling of Ian's that overturns an acceptance
probe you published, four findings that change documents you own, a sequencing
decision, and the state of the two lanes still open.

---

## 1. IAN OVERTURNED PROBE 4, AND THE PREMISE UNDER IT WAS FALSE

Your result-store acceptance list required that a within-group row reorder
LEGITIMATELY HOLD the cache, on the reasoning that reordering changes nothing a
group comparison computes. That reasoning is wrong, and it was measured wrong
rather than argued wrong.

`emlGroupSortAlphabetical` initialises to 0 (`stats/eml-extract.praat:1639`) and
the shipped default `config_groupSort = 1` maps to 0
(`graphs/eml-graphs-form.praat:5666`, `:10176`). At 0, `@emlCountGroups` returns
levels in DISCOVERY ORDER, which is table row order. Every consumer takes group
indices straight from it — `@emlRunTwoGroupAnalysis`, `@emlTukeyHSD`,
Games–Howell.

Measured on eight rows, group B's block moved above group A's, nothing else
changed: t goes −10.954 to +10.954; Cohen's d −7.746 to +7.746; rank-biserial r
−1 to +1; Mann–Whitney U1/U2 exchange. On a three-group table every Tukey mean
difference reverses and the comparison NAMES invert with them. Setting the sort
to alphabetical removes it entirely.

**Ian's ruling, 24 Aug, verbatim:** "Since the result of 'somehow this data
changed' is to safely rerun the tests, I am fine with 'any change to the data
including reordering of rows' forces the mismatch error and redoing of the
stats. Otherwise rebuild as you see fit. Agreed we don't round away machine
precision."

Your other three probes stand and pass. Probe 4 is inverted, and the inversion
is stated at the head of the test file under a heading that says READ THIS
BEFORE "FIXING" ANY EXPECTATION IN THIS FILE, with the ruling quoted and the
reason the old rationale was false, so nobody restores it from the document.

**The separate question this leaves open is yours and Ian's, not the store's:**
whether "group one is whichever group appears first in the table" is the
intended contract. It is defensible. It is also undisclosed — sort a spreadsheet,
re-run, and every sign flips with no warning. Under the ruling above the
fingerprint is safe either way, so this is no longer blocking.

## 2. THE FINGERPRINT TOOK FOUR BUILDS AND FOUR ADVERSARIAL PASSES

Reported because the shape of the failures is more useful than the final code.

**Build 1, per-group aggregates as your §a specifies** — n, sum, sum of squares,
min, max per level. Defeated: three cells changed inside one level, all strictly
between its min and max, holding all five aggregates identical. Key
byte-identical, Kruskal–Wallis p .0437 → .1013, Dunn adjusted p .0400 → .1209.
Structural, not lucky: five aggregates constrain four numbers across n−2 interior
values, so from n = 5 up a continuum of alternative datasets satisfies all five.
Levels of n ≤ 4 are provably safe. Reproduced on realistic one-decimal formant
data. **Aggregates cannot describe a multiset, and adding moments only raises
the n at which the manifold reappears.**

**Build 2, per-level sorted value digests.** Closed that. Defeated on a second
grouping factor the key could not name: rewriting six of twelve cells of a
second factor held the key while F(group) moved 7.564 → 2.687, p .0229 → .1468.

**Build 3, declared column list with roles.** Closed that. Defeated by lattice
reduction against the text-to-number step: two salted polynomials, and for two
strings of EQUAL LENGTH the difference of the digest pair is linear in the
character differences with the salt cancelling — so one colliding pattern
collides under every salt in the file. Found in under a second. Applied to the
key's own numeric text it needed digit deltas of at most 7. One cell changed
from 8455843.16466246 to 144.315683422652: key identical character for
character, ANOVA p .3559 → .00039.

**Build 4, under Ian's ruling: the whole table, every cell, in table order, as
TEXT, plus the analysis scope.** The ruling removed the sort, the identity
canonicalisation, the level census and the special handling of unusable cells —
about half the code — and closed three coverage defeats by construction. Reading
cells as text was measured, not assumed: `Get mean` on a cell holding 0.1+0.2
returns exactly `number(cellText$)`, so the text IS the table's state and
nothing a Praat statistic reads is finer. 20,000 doubles across 1e-300..1e300
round-trip; consecutive subnormals stay distinct. The mixing step is now
nonlinear.

**One defeat survived into build 4 and is fixed in build 5.** Deleting the
column declaration closed under-declaration and opened worse: the key could no
longer tell two analyses of ONE unmodified table apart. Same table, KW(val~grp)
p = .670 and KW(val2~grp2) p = .021, identical key, `@emlFingerprintsAgree`
reporting the data unchanged. **This was a scope regression against your §a,
which requires table identity plus both column names plus content.** Ian's
ruling overturned one clause and said nothing about the column names. The key
now folds content and then scope, with the scope item count folded first so an
unscoped key can never equal a scoped one.

**Not merged yet.** A fifth adversarial pass is running, then a full-suite
verification. 230 checks in its own file.

## 3. YOUR §b CENSUS COUNTS THREE RESULT-AFFECTING CONTROLS. THERE ARE AT LEAST FOUR

`emlGroupSortAlphabetical` is result-affecting — §1 above measures it — and it is
NOT one of the three dialog controls your census enumerates, because it has no
dialog control of its own. A census built from the controls the dialog offers
cannot see it.

**So the census is being built as a DERIVATION**, on Ian's direction: enumerate
what the DRAWING LAYER reads and classify each, rather than enumerating the
dialog. Two reasons, both measured. First, that setting, and whatever else of
its kind exists. Second, the dialogs are not stable — they changed twice today —
while the draw layer did not move at all, and each regrouped page now carries a
remap block whose whole purpose is to let dialog names change while the names
the draw code reads stay put. The draw layer is the stable layer.

The census is in flight now. It carries the four properties: population derived
never written, one property per member, a ratchet in both directions, and a
failure if it walked zero members. Its own correctness test is whether it finds
the sort setting without being told.

**What a stored result needs BESIDES the key**, measured on a byte-identical
key, and now written into the module header because a store builder will read
that header and could conclude otherwise: the column names; the test type; the
correction method (Dunn holm p = .3298 vs bonferroni p = .4947); alpha; and the
group sort order. The key proves the data is unchanged. It cannot prove the
analysis is the same analysis.

## 4. THREE SMALLER FINDINGS AGAINST DOCUMENTS YOU OWN

**a. A check marked its own homework.** `v84`'s header claimed that a range pair
filed under a non-axis heading is caught by the page-composition checks.
Measured against all twenty-five checks that read the graphs form: it is not.
A pair planted under the layout heading leaves the axis roster, escapes the
max-below-min refusal, and nothing objects. The narrowing edit was correct; the
defence-in-depth it rested on was never built. The header now names the gap.

**b. The cold-start driver produced confident wrong verdicts, and the seeded
violation is what found the worst one.** Five defects: the health probe killed
the instance it was checking and reported it alive; the Objects-window probe
discarded its own output because Praat wrote it UTF-16; display allocation could
seize a display another harness was live on and clear its lock; a window manager
that lost its start race read as a dead plugin; and `state = error` — the verdict
the family exists to produce — could never fire, because the Praat error arrives
on the receiving instance and the reader watched the sender. A wrapper seeded to
die with a textbook Praat error was recorded as "stalled". Four legs had been
recorded as crashes that were rig faults. **Your standard kit earned its place
twice today**: this, and the escape-hatch lint now building under the same rule.

**c. The pitch floor and ceiling are judged by nothing.** Correctly removed from
the axis roster — they set an analysis search range, not a plot axis, and only
qualified because they render as a paired row. But floor above ceiling is still
nonsense and no check now asserts their ordering. Scope, not a defect.

## 5. THE FIELD REWORK IS COMPLETE; SEQUENCING AHEAD

All thirteen graphs pages and the line chart's three are grouped, row counts on
target within one. The photographed evidence was re-driven twice and is green;
the axis-refusal transcript changed in ONE line the second time, its code
digest, with every refusal, ink measure and figure identical — which is the
evidence the re-taught tab indices are right rather than merely different.

**The re-drive taught one thing worth recording in your compaction ruling: group
headings shift no tab stops.** They are comment rows and take none. What moved
the seven indices was the REORDERING that came with grouping — range rows
leaving the layout group for the axis heading. The note in the standing list
said headings did it, and anyone re-deriving indices by counting headings will
get the wrong answer.

**Deferred on Ian's direction, and I agree:** the store's single write site, the
bridge reading a stored result, and the announcement line. All three sit on door
behaviour that is under audit elsewhere, and the door-agreement census
(`docs/WORK_ORDER_DOOR_CENSUS.md`, ruled 20 Aug) is still unbuilt. Building the
store now would enshrine whichever door version happens to be in front of us.

## 6. TWO THINGS NEEDING YOUR RULING

1. **No approved row target exists for any line-chart page.** Your per-page maps
   stop at Spaghetti; the line-chart entry says "same rules" and names no count.
   Actuals, proposed as the targets: What the lines are 4, Column Mapping 23
   advanced / 11 beginner, Right-Hand Axis 7.
2. **Rule 4 contradicts the per-page maps on where Legend placement sits.** Rule
   4 orders it "…Font, Legend placement, Output DPI"; every one of the five
   built pages that has a legend renders "…Gridline mode, Legend placement, Show
   inner box, …, Font, Output DPI", which is what your own per-page maps say and
   what Ian approved in the mockups. The line chart was matched to the five
   built pages so a user moving between them finds one order. One line moves it
   if you want rule 4 taken literally.

## 7. ONE PROCESS CHANGE

No agent working in this repository has ever had the PraatGen knowledge base.
`CLAUDE.md` carried delivery and scoping rules and nothing about how to write
Praat; `docs/PRAAT_FACTS.md` defers to PraatGen without being reachable from it.
That is now fixed: `CLAUDE.md` carries a 42-line constraining set — the traps
that fail silently — with the clone command and two named carve-outs where
following PraatGen literally would damage this repo.

A periodic standards audit is designed and not built. Its calibration is the
part worth your attention: it pins on five counts known to be wrong today,
including Ian's two unadjudicated rules, and **an audit reporting zero findings
is defined as a failed run**.

— executing session
