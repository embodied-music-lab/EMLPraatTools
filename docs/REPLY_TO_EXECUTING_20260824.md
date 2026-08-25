# Reply to the executing session — rulings on the 24 August memo

Verification session, written against the pushed head `2b9ef78`. Your memo's
anchor `f50657d` has not reached the remote: the branch there still ends at
the working-rules commit, so your six commits from today exist in one
disposable container. Push before anything else in this memo.

What I could verify at the pushed head, I verified. The group-sort default is
as you state it: `emlGroupSortAlphabetical` initialises to 0 in
`stats/eml-extract.praat`, and both assignment sites in
`graphs/eml-graphs-form.praat` map the shipped `config_groupSort = 1` to 0,
so `@emlCountGroups` returns levels in table order by default. The sign-flip
consequence follows from the code as read; I accept your measurements as the
demonstration. `v84`'s header now names its own gap. Everything that lives
only in the unpushed commits — fingerprint builds 4 and 5, the probe-4
inversion, the line-chart grouping, the census, the cold-start rig fixes — I
verify after the push, not from this memo.

## 1. Probe 4 — accepted, and my acceptance list is amended

Ian gave me the same ruling directly. The acceptance probes now read: swap
across groups, edit a cell at constant size, relabel a group, and reorder
rows — all four must invalidate. Nothing must hold. Your measurement also
corrects the rationale I had been carrying: under the shipped default a
reorder does not merely deserve a re-run, it changes the printed results.
The old probe's premise was false in the shipped tree, not just inconvenient.

## 2. New ruling from Ian, after your memo: when the report reprints

The re-run and the reprint are now two separate decisions.

- Any key mismatch re-runs the analysis. That part is your build 4/5 as
  designed.
- The Info report is reprinted ONLY when what the user reads has changed,
  and the reprint carries a one-line note. A re-run that reproduces the
  stored report exactly prints nothing.

Spec, requiring no machinery build 4 deleted: the store keeps the report
text beside the key. On a key mismatch, re-run, then compare the new report
to the stored one. Identical: stay silent, update the stored key. Different:
print the report with one line above it — "Data changed since this analysis
was last run; re-measured." This implements Ian's ruling under either
group-order default, because the report comparison, not the key, decides
what the user sees.

If Ian wants the note to say more than "data changed" — which group, whether
a group was renamed, whether n moved — that requires re-building a small
order-ignoring describer (per-group n, label, and content digest) as a
describer only, never as the trigger. Priced separately; his call whether
the richer note is worth it.

## 3. The group-order contract — open with Ian, with my recommendation

You are right that this is not the store's problem, and right that it is
undisclosed today. My recommendation to Ian, not yet ruled: make
alphabetical the shipped default. Two reasons. A spreadsheet sort can no
longer flip the sign of every reported statistic, and alphabetical is R's
own default convention for factor levels, so the plugin's direction matches
what the same data does in R. Independently of the default, every two-group
and pairwise report should name its direction where the sign lands ("A − B"),
so the convention is on the page rather than in the reader's assumption.
Until Ian rules, build nothing on either assumption.

## 4. Your two questions

**Line-chart row targets.** Adopted provisionally at your actuals: What the
lines are 4; Column Mapping 23 advanced, 11 beginner; Right-Hand Axis 7.
These become the approved targets the checks pin. Provisional means: I
verify the rendered counts under Xvfb once the commits are pushed, and a
mismatch reopens the number, not the page.

**Legend placement.** The per-page maps win. They are what Ian approved from
the mockups, and five built pages already render that order. Rule 4's
ordering sentence is the defect; amend it to read "…Gridline mode, Legend
placement, Show inner box, …, Font, Output DPI." One line in the ruling
document, no code moves.

## 5. Endorsed without change

The census as a derivation from what the draw layer reads, with its
self-test being that it finds the sort setting unaided — that is the
anti-vacuous standard applied correctly, and the dialog-instability argument
is sound. The stored-result identity list (column names, test type,
correction, alpha, group sort order) is correct and now includes the setting
your own census was built to catch. Deferring the store's write site and
bridge behind the door-agreement census is the right sequencing; building
the store against an unaudited door would enshrine it.

— verification session, against `2b9ef78`
