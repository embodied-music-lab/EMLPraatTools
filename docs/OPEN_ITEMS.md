# Open items — EML Stats & Graphs, road to 1.0.0

Kept in the repo on purpose: this file survives session loss. Update it
when an item is opened, changed, or closed. Newest ruling wins.

This file's ITEM LIST is maintained continuously; its last full
reconciliation against the tree was 20 August 2026. Read a single item
here as current, and read the completeness of the list as of that date.

For live status during the kit freeze and the road to 1.0.0, the tracker
is authoritative: `mailbox/to-opus/TRACKER_KIT_AND_1p0.md`. Where the two
disagree, the tracker wins.

The phase register for features beyond 1.0.0 is `ROADMAP.md` at the repo
root. This file is defects and ruled-but-unbuilt work; that one is where
the plugin is going.

## A. The unification (largest remaining piece)

### RULED 24 Aug — the re-run and the reprint are two decisions

Ian, through the verification session. Any key mismatch RE-RUNS the analysis.
The Info report is reprinted only when what the user reads has changed, and a
reprint carries one line above it: "Data changed since this analysis was last
run; re-measured." A re-run that reproduces the stored report exactly prints
nothing.

The store therefore keeps the REPORT TEXT beside the key. On a mismatch:
re-run, compare the new report to the stored one, and either stay silent and
update the stored key, or print with the note. THE REPORT COMPARISON, NOT THE
KEY, DECIDES WHAT THE USER SEES — which is what makes this hold under either
group-order default, and it needs no machinery the whole-table key removed.

A richer note — which group, whether a group was renamed, whether n moved —
needs a small order-ignoring describer (per-group n, label, content digest) as
a DESCRIBER ONLY, never as the trigger. Priced separately and not ruled.


Drawing a figure re-runs the analysis instead of receiving its result.
Confirmed still true: the bridge that draws a group comparison computes the
test itself from its arguments rather than reading a stored result, and no
result store exists anywhere in the plugin.

Ruled: the graph carries the analysis's settings forward; changing a
result-affecting setting from the graph re-runs and says so in one line in
the Info window; changing nothing re-runs nothing and prints nothing. The
duplicate-report stopgap is rolled into this, not taken separately.

Memo with the design questions is with Fable
(`docs/MEMO_TO_FABLE_unification.md`); the answers are
`docs/RULING_RESULT_STORE.md`.

FIRST PIECE BUILT, 24 Aug: THE DATA KEY. `@emlDataFingerprint` and
`@emlFingerprintsAgree` in `stats/eml-extract.praat`, with
`@emlGroupFingerprint` and `@emlAnalysisFingerprint` kept as thin wrappers —
the ruling's §a data fingerprint. It lives in the extraction layer because
both sides of the store need it: the kernels stamp it on a published result,
the annotation bridge recomputes it at draw time. The key is TEXT and is only
ever compared as text; nothing about it is a float comparison.

REBUILT FOUR TIMES IN ONE DAY. `eGF1` (per-level moment aggregates) was
defeated six times; `eGF2` (a digest of each level's quantised sorted value
list) once; `eDF1` (a digest of the whole sorted row list over the columns an
analysis declared) twice; `eTF1` (the whole table and no declaration at all)
once, by Defeat 9. THE SHIPPED FORMAT IS `eTF2`.

THE RULING THAT MADE `eTF1` POSSIBLE, Ian, 24 Aug:

> "Since the result of 'somehow this data changed' is to safely rerun the
> tests, I am fine with 'any change to the data including reordering of rows'
> forces the mismatch error and redoing of the stats. Otherwise rebuild as you
> see fit. Agreed we don't round away machine precision."

WHAT THAT OVERTURNED. Every earlier format carried a requirement that a row
reorder must HOLD the cache, on the rationale that reordering changes no
result. THAT RATIONALE WAS FALSE. Group order comes from discovery order under
the shipped default (`emlGroupSortAlphabetical = 0`, from `config_groupSort`
in `graphs/eml-graphs-form.praat`), so moving one group's rows above another's
flips the sign of t, of Cohen's d, of rank-biserial r and of every Tukey mean
difference, and inverts the comparison names. The requirement was not merely
expensive, it was wrong.

DEFEAT 9, AND WHY `eTF1` DID NOT SURVIVE THE DAY. Deleting the column
declaration closed under-declaration — a caller cannot under-declare what it
never declares — and opened something worse: the key could not tell two
analyses of ONE unmodified table apart. Measured on a 9 x 4 table never
touched between the calls: KW(val ~ grp) p = 0.670320, KW(val2 ~ grp)
p = 0.021128, KW(val2 ~ grp2) p = 0.953497, and
`@emlGroupFingerprint: t, "val", "grp"` and
`@emlGroupFingerprint: t, "val2", "grp2"` returned the SAME key with
`@emlFingerprintsAgree` reporting the data unchanged. A store keying on that
serves one comparison's result to a figure drawing another. §a of the ruling
requires table identity plus BOTH COLUMN NAMES plus content; the 24 Aug ruling
overturned only the row-reorder clause and said nothing about the names.

`eTF2` IN ONE SENTENCE: digest the whole table — its name, its row and column
counts, every column name in order, and every cell's content in row order then
column order, exactly as the table holds it — and then digest the DECLARED
SCOPE, the column names the caller handed in, folded verbatim and in order.
The key is `eTF2|r=<rows>|c=<cols>|n=<chars>|s=<scope items>|d=<h1>_<h2>_<h3>`,
about 60 characters.

TWO TERMS, BOTH LOAD-BEARING. Content without scope is Defeat 9; scope without
content is Defeat 8. The content term is folded identically in all three
doors, so the scope is the only thing that can make two keys on one table
differ. The item count is folded before the items, so `@emlDataFingerprint`
(no scope), `@emlAnalysisFingerprint` (one list string) and
`@emlGroupFingerprint` (two names) never coincide on one table.

NOTHING PARSES THE DECLARATION. The scope is the caller's text, folded in the
caller's order, with each item's length folded after its characters. No
separator is split on, no empty item dropped, no role prefix stripped, no name
resolved against the table. A name that is not a column is not refused: it
folds like any other text, so a typo yields a key only the same typo matches —
a permanent cache miss, never a false hit. That is how the whole class of
list-parsing defects stays closed while the scope comes back.

WHAT `eTF1` DELETED AND `eTF2` KEEPS DELETED, none of it back without a new
ruling:

- THE SORT. Rows are folded where they sit.
- COLUMN-LIST PARSING, and every decision it required. The declaration is
  digested, not interpreted.
- IDENTITY CANONICALISATION — the block digests, and the refusal of two
  identity columns. A subject label is text and goes in as text.
- THE LEVEL CENSUS, and all special handling of blank, unusable and excluded
  cells. Every cell is in the key as its literal content.
- `@eml_fpNumber`, `@eml_fpTextHash`, `@eml_fpFoldText` and the `eml_fpReq`
  namespace. What remains is `@eml_fpMix`, one composer (`@eml_fpCompose`,
  the single place a key is built) and the three doors.

HOW A NUMBER REACHES THE KEY: AS TEXT, AND NOTHING IS ROUNDED. Praat stores a
Table cell as a string and derives its numeric queries from that string, so
the text IS the cell rather than a rendering of it. Measured on 6.6.30 and
asserted in the suite: 2000 random doubles all re-parse from their cell text
bit-identically; `Get mean` on a cell holding 0.1 + 0.2 returns exactly
`number (cellText$)`, which is 0.30000000000000004; 500 pairs one ulp apart
and 500 pairs 2.25 ulps apart all get different texts; three consecutive
subnormals get three different texts. Reading text also sidesteps formatting
entirely, so the `--undefined--e-324` underflow that `eDF1` emitted for two
different subnormals cannot occur — no exponent is computed.

THE TEXT-TO-NUMBER STEP WAS THE EIGHTH DEFEAT AND IS REPLACED. `eDF1`'s
`@eml_fpFoldText` was two salted polynomial hashes. For two strings OF EQUAL
LENGTH the difference of the folded pair is a fixed linear form in the
character differences and THE SALT CANCELS, so a colliding difference pattern
found once collides under every salt, and lattice reduction finds one in under
a second — inside the digit alphabet, on the key's own numeric text, with
digit changes of at most 7. `@eml_fpMix` breaks the linearity rather than
adding more polynomials: three 31-bit words, every multiplier drawn from
another word's current value, a quadratic term in the state every step, and
the words feeding forward within the step. Measured: for one fixed difference
pattern over 40 random equal-length strings, a plain polynomial gives ONE
digest difference and `@eml_fpMix` gives 40; a single digit change moves about
half of the 93 bits; over 3 million equal-length numeric strings the collision
counts at 32 and 40 bits match a uniform random function (1025 against 1047
expected, 2 against 4.1) and the full width gives none. A birthday search
against 93 bits is about 1e14 digest evaluations, AND SO IS A SECOND PREIMAGE
— see THE SECOND PREIMAGE IS NOT 2^93 below. IT IS A HOME-MADE MIXER AND IS
NOT PROVEN SECURE; the claim is that both attacks cost about 1e14 mixing
steps, which is far beyond the accidental edit this key is sized against, and
is not a claim of resistance to anyone attacking on purpose.

THE SECOND PREIMAGE IS NOT 2^93, AND THE SHIPPED HEADER NOW SAYS SO. The
header quoted the birthday number alone and did not distinguish the two
attacks, which read as a 2^93 second-preimage cost it does not have. THE STEP
INVERTS EFFICIENTLY: given an output triple and the character, `m2` is read
off the output's own first word and `m3` off its second, so `h2` and `h3` each
come back by ONE modular inverse; `h1` then comes back by a scan of the 46337
values of `r` in the affine form below. Milliseconds, about two candidates,
and the true preimage is among them — 300 times in 300. So attacking ONE
SPECIFIC STORED KEY is a meet-in-the-middle at about 2^46.5, the same 1e14 as
the collision, plus roughly a petabyte of stored states or a memoryless
variant that pays for it in time. Both numbers are far beyond the failure this
key exists to catch, which is a table edited between the analysis and the
figure that quotes it, by someone who is not attacking anything.

THE STEP IS NOT INJECTIVE, AND THE HEADER NOW SAYS WHY THAT COSTS NOTHING.
Writing `h1 = 46337 * u + r`, the first word's update is exactly
`(46337 * m1) * u + (m1 + K) * r + 1031 * c + 1 mod 2147483647` with
`K = h2 mod 46337` — verified identical to the shipped expression over 5000
random state-and-character pairs, and over 240 more inside the suite. Within
one step `h1` is a 2-D affine form, so the merging differences of a fixed
`(h2, h3)` are the short vectors of a lattice of determinant 2147483647 in a
box of about four times that area: a handful, median two, and none of 4000
sampled pairs admitted none. Two states that share `h2` and `h3` and differ in
`h1` by a merging amount fold to one state under ANY string, the empty string
included, and never separate again. THAT IS NOT A WEAKNESS: reaching two such
states requires `h2` and `h3` to agree exactly — 62 bits — with `h1` differing
by one of about two values out of 2^31, so about 2^-92 for a pair, no better
than the birthday bound the digest already carries. The separation is carried
by the MULTI-STEP nonlinearity, where each multiplier is drawn from another
word's current value, and that held under every measurement: 4000 of 4000
distinct digest differences for one fixed difference pattern, zero commuting
distinct-character pairs in 400000 state-and-pair trials, and the collision
counts above.

PINNED, NOT ASSERTED. Under `h2 = 1554331573` and `h3 = 1375090233` the
merging sets are arithmetic progressions of step 24928653, and the suite folds
TWO WHOLE SETS through the shipped `@eml_fpMix`: all 66 members of the one
beginning at `h1 = 510355490`, and all 71 of the one beginning at
`h1 = 45710`. Each size is exact rather than a lower bound, because one end of
each progression falls out of the modulus and the other end's neighbour is a
legal `h1` that the suite folds and finds apart. An earlier draft of the
header called 66 "the largest found", which is a claim about a search and was
wrong on its own terms — 71 is larger, under the same pair.

THE LENGTH TERMINATOR SEES ONLY `length mod 1000003`, so two pieces whose
lengths differ by exactly 1000003, or by any multiple of it, terminate
identically. WHAT THAT BUYS: the re-cut guarantee for every piece this module
folds, because a cell, a column label, a table name and a scope item are all
far shorter than 1000003 characters, and inside that range the length term IS
the length. WHAT IT DOES NOT BUY: a length guarantee in general — two pieces a
million characters apart are told apart by their CHARACTERS, which run the
step a different number of times, and not by the terminator. Total length is
carried separately and exactly by the key's `n=` field, which nothing reduces.
Pinned in the suite by a local copy of the terminator whose length comes from
a parameter, tied to the shipped procedure by legs that fold both and compare,
plus text checks that every length term in the shipped file reduces modulo
1000003 — a real 1000003-character fold runs past ten minutes against a suite
that finishes in under three seconds.

PRAAT REWRITES OBJECT NAMES, AND THE KEY CARRIES THE REWRITTEN ONE. The name
term is read with `selected$ ("Table")`, not the string the caller handed to
the create command, and Praat replaces a space, a bar, a comma or a slash with
an underscore: `"a b"` becomes `"a_b"`, `"data|1"` becomes `"data_1"`. So two
tables a user believes are named apart can share one name term. This is the
mirror image of the standing fixture rule — a mutant and its control must
share a table name, or the mutant goes green on the name alone — and it is the
same trap from the other side: a fixture named `"data|1"` against a control
named `"data_1"` IS named alike whatever its author intended, and pins nothing
while passing. Measured in the suite, both the rewriting and the shared key.

STORED `eGF1`, `eGF2`, `eDF1` AND `eTF1` KEYS DO NOT UPGRADE and must not be
treated as if they did: the format tag is part of the compared text, so none
of them matches an `eTF2` key and the analysis re-runs. That is the intended
behaviour, not a migration to be written. `eTF1` is the one to watch, because
it digests the same cells in the same order and differs only in folding no
scope.

WHAT THE DOOR REFUSES is now one thing: a table ID that is not a positive
number, which is what an uninitialised caller variable looks like. Selecting
on it would abort the whole script, so the refusal turns a crash into a
re-run.

THE NON-FINITE CORNER IS NARROWER THAN IT WAS WRITTEN. The header claimed
`+inf`, `-inf` and `undefined` share one text, implying a three-way ambiguity.
Measured on 6.6.30: Praat has no reachable `+inf` in a Table at all —
`1e308 * 10`, `-1e308 * 10`, `1e308 + 1e308` and `exp (1000)` each test equal
to `undefined` as a NUMBER, before any cell holds them. So there is ONE
non-finite state, the key sees it as `--undefined--`, and there is no
exploitable ambiguity between three states. Asserted in the suite.

WHAT IS STILL NOT COVERED, and there are exactly three:

- THE SETTINGS, and this is the boundary a store builder must read. The key
  answers "same data, same declared scope?" and nothing else. Measured on a
  byte-identical key: the same Dunn post-hoc gives p = 0.329830 under holm and
  p = 0.494744 under bonferroni; and `emlGroupSortAlphabetical` — a global
  with NO DIALOG OF ITS OWN, set from `config_groupSort` at two sites in
  `graphs/eml-graphs-form.praat`, and therefore not one of the three
  result-affecting dialog controls the ruling's settings census enumerates —
  turns a Tukey comparison from `Zebra - Alpha = +10.0000` into
  `Alpha - Zebra = -10.0000`, sign and names together. A stored result carries,
  beside the key: the column names in readable form (the key distinguishes
  scopes without disclosing them), the test type, the correction method,
  alpha, and the group sort order.
- A DIGEST COLLISION, AND A SECOND PREIMAGE. 93 bits over a table of any size,
  both at about 1e14 mixing steps, with the measured costs above.
- WHEN THE KEY WAS TAKEN, and this is the one that matters. A key describes
  the table at the instant it is asked for. A caller that computes a result,
  lets the table change, and only then stamps a key has stamped a truthful key
  on a result the table does not support. The fault is in the ORDER of the
  calls, not in the arithmetic, so nothing inside the module can see it — it
  is the structural successor to under-declaration, which the content term
  closed. THE RULE THAT CLOSES IT BELONGS TO THE STORE: take the key in the
  same pass that reads the data, before anything can touch the table, and
  stamp that key on the result. It is a large part of why the store must have
  a SINGLE write site, and it should be checked when that write site is built.

WHAT IT COSTS, AND THE COST IS REAL. A reorder, a subject rename, a new
column, a typo fixed in a column nobody read — each re-runs the analysis and
none of them changes a printed number. That is the deliberate exchange: cache
hits for the impossibility of a whole class of stale result.

COST, measured on Praat 6.6.30 and linear in the table's characters (each
doubling of the rows doubles the time, measured at 100, 1000, 2000, 4000 and
8000 rows): 1000 x 2 in 0.35 s, 1000 x 3 in 0.43 s, 2000 x 3 in 0.90 s,
8000 x 3 in 3.26 s. `eDF1` took 0.63-0.73 s on 1000 x 2, so the whole-table
key is about twice as fast as the sorted per-column key it replaces while
digesting more. The scope adds one pass over two short column names, which is
below the noise of the table. The table copy that makes every cell read
positional is 2 ms on a 4000 x 3 table.

WHAT IT ALSO COSTS: the same question asked through a different door is a
different key. A pair declared as two names and the same pair declared as one
list string are two scopes and two re-runs. Joining a list to a pair would need
a separator rule nothing could enforce against a column literally named with
it, so the doors stay apart and the cost is a cache miss.

TWO REPAIRS FOUND BY THE ATTACK, both closed by deletion: a real column named
`num:v` was silently resolved to a different column `v` and issued a
bit-identical key, and empty items in a declaration list were silently dropped
so `"v,,grp"` and `"v,grp"` were indistinguishable. There is no declaration
list. Separately, Praat's `Get value:` resolves a column by LABEL and returns
the first match, so two columns sharing a name would leave one unread — the
door copies the table and renames its columns BY POSITION before reading a
cell, so every read is positional.

TESTS: `dev/tests/phase2/test-fingerprint.praat`, 278 checks, all green in
about 2.6 s. Every defeat of all four formats is a section, and each goes
green. TWO LEGS ASSERT THE OPPOSITE OF WHAT THEY ONCE ASSERTED — a within-group
row reorder, and a subject rename in an identity column, both now MOVE the key
— and the file says so loudly at the top, with Ian's ruling quoted, so that
nobody "fixes" them back. New sections: a column the analysis never read now
invalidates; two columns sharing a name; a column really named `num:v`; the
measured precision of a cell's text; the nonlinearity of the mixing step
against a plain polynomial built in the file for the comparison; and a loose
linear-cost guard.

STILL UNBUILT in this item, and each is a separate piece of work: the §b
census of result-affecting vs display-only settings is BUILT as
`validate/v112_settings_census.R`; the single write site and the published
names are BUILT (`@emlPublishAnalysisResult`, `stats/eml-extract.praat`); the
one-line announcement and the bridge reading the store instead of recomputing
are BUILT (see the entry below). What remains is the canonical report
comparison, the export buffer on the changed-setting path, the figure's alpha
and group-order disclosure, and the SCATTER door -- all four listed below.

SECOND PIECE BUILT, 26 Aug: THE BRIDGE CONSUMES INSTEAD OF RECOMPUTING
(ruling sections c and d, the read side). `@emlConsumeGroupResult`,
`@emlStoreGroupMap` and `@emlBridgeStoreIdentity` in
`graphs/eml-annotation-procedures.praat`, with the announcement's wording in
`@emlRenderResultSettings`, `@emlSettingsChangeNote` and
`@emlSettingsVocabulary` in `stats/eml-output.praat`. Driven by
`harness/bridgeconsume/`, asserted by `validate/v142_bridge_consumption.R`
(178 checks).

WHAT THE READ SIDE DOES NOT DO, and this is the shape of it: it does not
re-implement either half of the validity test. The data half is
`@emlStoreKeyTake` plus `@emlFingerprintsAgree`; the settings half is
`@emlStoreIdentityAgrees`; both belong to the store. What the read side owns
is which QUESTION to ask, the map from the store's group order onto the
figure's x axis, and the SENTENCE.

THE FOUR VERDICTS, and the wording matters as much as the decision.
`consume` draws from the store and prints NOTHING -- exactly one report
exists and the analysis door printed it. `settings` re-runs and prints ONE
line in the contract's form. `data` re-runs and prints the 24 August line.
`none` -- nothing published, another table, another pair of columns, a
refusal, an unknown schema, or an omnibus with no post-hoc beside it --
computes and prints its report as the FIRST report of that result.

A PUBLICATION ABOUT ANOTHER COMPARISON IS A MISS, NOT A CHANGED DATA SET.
The key cannot tell the two apart -- it is one digest over content AND
declared scope -- so a reader leaning on it alone answers a figure of a
DIFFERENT table with "Data changed since this analysis was last run", a
sentence about an edit nobody made. Measured before the guard existed
(harness/bridgeconsume). The store's readable record of the table name and
both column names is what separates them.

THE GROUP-ORDER REMAP IS THE DANGEROUS PART AND IT IS PINNED CELL BY CELL.
`annotBracketI[]`/`annotBracketJ[]` are x-axis POSITIONS; the store's
matrices are indexed by `emlStoreGroupLabel$[]`, which for a one-way ANOVA is
Tukey's alphabetical sort. `@emlStoreGroupMap` maps LABEL BY LABEL and
refuses on a level the store never saw or two levels sharing a label. v142
compares a COMPUTED and a CONSUMED draw of one comparison observable by
observable -- every matrix cell, its significance flag and its effect size,
every bracket's indices, p, effect and label, the omnibus sentence and both
caption halves -- at both layouts on both arms. All identical.

FOUR ARMS AND ONE RENDERER. The four arms of `@emlRunAnnotationComparison` each
carried their own copy of the bracket loop and the matrix loop; the consume
path would have been a fifth. They now build one display-ordered p matrix and
one SIGNED effect matrix and hand them to `@emlBridgeRenderAnnotations`, which
is the only place a group comparison becomes an annotation. `@emlBridgeOmnibusLine`
is the same move for the omnibus sentence and `@emlBridgeEffectPolicy` for the
per-arm sign policy, which is PRESERVED rather than tidied (v112's census note
records the asymmetry; the drawn ink is magnitude on every arm either way).
Measured: `harness/settings/out/SETTINGS.tsv` re-driven over all 291 rows is
BIT-IDENTICAL to a drive of the pre-change tree.

THE EFFECT SIZES ARE NOW COMPUTED WHETHER OR NOT THEY ARE SHOWN. That
discharges the condition v112 attached to classifying `showEffect` as
display-only -- "a result published under it cannot serve a later figure that
wants effect sizes" -- and it is what section (d)'s "states the whole result
on every run" requires.

STILL OPEN, AND EACH IS NAMED WHERE IT BITES:

- **PUNCH ITEM 1.2 — BUILT, NOT YET COMMITTED (26 Aug), to the
  minimal-renderer shape Fable ruled.** The capture approach was REJECTED and
  is not what was built. WHAT EXISTS NOW:
  - `@emlEmit: .line$, .explain$` in `stats/eml-output.praat` — THE ONE
    DUAL-MODE EMIT HELPER. It buffers `.line$` into `emlEmitText$` always and
    prints only when `emlEmitPrint = 1`; `@emlEmitMode: .print` is its mode
    switch and touches no buffer. The two-tab gloss travels as the SECOND
    ARGUMENT and is appended at PRINT time, so it cannot reach the buffer.
  - `@emlExplainLine: .text$, .wrap` — THE EXPLAIN HELPER, WHICH NEVER
    BUFFERS. Every whole line of explanation goes through it: the six "Why:"
    headers in the three shared comparison reporters, `@emlPostHocCaution`'s
    caution and `@emlEffectMatrixCaption`'s second sentence. `.wrap = 0`
    prints verbatim, `.wrap > 0` wraps at that column with `@emlReportNote`'s
    two-space indent — one helper, because the two shapes of explanation line
    in this tree print differently and always did.
  - THAT IS WHAT MAKES THE BUFFER CANONICAL WITHOUT A STRIP LIST. An
    explanation never enters it in the first place, so the explanations
    toggle cannot move one character of the stored text, and no list of
    which lines an explanation is has to be kept right against lane 6.
  - THE REPORT FRAME IS ROUTED (`@emlReportHeader`, `Footer`, `Section`,
    `Line`, `LineString`, `Blank`, `Note`, `GroupOrderLine`,
    `DescriptiveHeader`, `DescriptiveRow`) and so are all 36 raw
    `appendInfoLine` sites inside the three reporters the two store-wired
    doors share. THE TIMESTAMP AND THE PROVENANCE LINE ARE DELIBERATELY NOT
    CANONICAL — `date$ ()` differs on every run and the provenance names the
    door, so either in the buffer would make "identical → print nothing"
    unreachable, which is exactly why capture was rejected.
  - THE STORE KEEPS THE TEXT: `emlStoreReport$`, written at the one write
    site from the declared hand-off `emlPublishInReport$` (the shape
    `emlPublishInLabel$[]` already uses), unconditionally, like every other
    published name. `""` MEANS NO REPORT WAS PRINTED FOR THIS RESULT and is
    not an empty report — the changed-setting path publishes `""`, and a
    stored `""` never matches, so a later run cannot fall silent against a
    report nobody has read.
  - THE PRE-PRINT COMPARISON IS IN `@emlRunAnnotationComparison`, not in
    `@emlGraphsReportBridgeIfNew`, because that procedure's own header
    forbids it a rule of its own. On a `data` verdict the bridge renders
    buffer-only, compares against `emlStoreReport$` AS IT STANDS BEFORE ITS
    OWN PUBLICATION, and on a match lowers both `.printReport` and the new
    `.notePending`. ONLY THE `data` VERDICT CAN GO SILENT: reaching it means
    the store's publication is already known to be about this table and this
    pair of columns.
  - THE 24 AUGUST LINE IS NOW PRINTED BY THE GATE, not by the bridge, on
    the data path only — whether it is said at all depends on a comparison
    that is not finished when that verdict is taken. The settings line is
    still printed where it is decided, because it is the whole of what that
    path says.
  - **Acceptance, driven:** `harness/reprintpins` gains two legs and now
    calls the reprint gate (without that call no "second report" pin in
    `v140` could ever have failed). `changed_data_same_report` moves 10.1 to
    10.2 inside its own rank position: verdict `data`, `printReport = 0`,
    `notePending = 0`, and the figure's whole contribution to the Info
    window is zero lines. `changed_data_new_report` moves 8.4 to 12.0 across
    a rank boundary: verdict `data`, one line, exactly one report, line
    above report. `v140` is 43/43.
  - **Red demonstration, measured, not argued:** the same probe against the
    pre-item tree (`git worktree add --detach <dir> 2bccd8e`) prints the
    24 August line and A SECOND COMPLETE 62-LINE REPORT which diffs
    byte-identical against the first, timestamp line aside; the amended
    `v140` reports **13 FAILED of 43** there against 43/43 here.
  - **`v138`** classifies `emlStoreReport$`. **`v112`** gains six entries
    (`emlPairwiseFollows`, `emlResult_MAXCOL`, `emlResult_MAXROW`,
    `emlVocabTidy$`, `emlVocabGlance$`, `emlVocabAugment$`) — see the note
    below.
- **STILL OPEN AFTER 1.2, AND NAMED RATHER THAN LEFT IMPLIED:**
  - **THE PAIRWISE MENU DOOR PUBLISHES NO CANONICAL TEXT, ON PURPOSE.**
    `@emlReportPairwiseComparison` is not one of the three reporters the two
    store-wired doors share, so it is not routed and
    `@emlRunPairwiseAnalysis` hands over `""`. Nothing is lost today: a
    figure asking the store about that result finds a pairwise family
    against the graph door's `one-way anova + tukey`, so the verdict is
    `settings` and no report is reprinted on that path. It becomes real work
    the day the graphs door can offer a pairwise family (8.2 / 1.6).
  - **THE REPORTER RUNS TWICE ON THE PATH THAT PRINTS**, once buffer-only
    and once printing. The buffer cannot be flushed instead: it holds no
    explanation lines by construction, so printing it would silently drop
    every gloss. On the path that stays silent it runs once and nothing
    prints.
  - **`v112`'S CENSUS GREW BY SIX, and the reason is the render moving
    inside the door.** `@emlRunAnnotationComparison`'s closure now reaches
    `@emlReportBridgeStats` and the result writer. THE DRAW PATH ALWAYS RAN
    THAT CODE — the graphs form has always called
    `@emlGraphsReportBridgeIfNew` right after the bridge — but the form is
    not a door the census walks, so the walk was blind to it. All six are
    DISPLAY_ONLY with stated reasons; two of them (`emlResult_MAXCOL`,
    `emlResult_MAXROW`) are fixed capacity constants and say so.
- THE EXPORT BUFFER ON THE CHANGED-SETTING PATH — NARROWED BY 1.2, NOT
  CLOSED. Suppressing the report also suppresses `@emlReportBridgeStats`'
  `@emlCSVInit` and its three-file declaration. On the consume path that is
  correct -- the analysis door declared this very result. ON THE DATA PATH IT
  IS NOW CLOSED as a side effect of the canonical rendering: the bridge runs
  the reporter buffer-only before publishing, so the export buffer describes
  the run the figure draws even when nothing is printed. ON THE
  CHANGED-SETTING PATH IT IS UNCHANGED: `.printReport` is 0 from the moment
  that verdict is taken, so no rendering happens, the bridge recomputed and
  the export buffer still holds the analysis door's older run, and a Save
  then writes the settings the figure does not draw. Closing it is now one
  decision, not a missing mechanism: whether the settings path should render
  buffer-only too. It must NOT publish that text as `emlStoreReport$` if it
  does -- the reader has not seen that report -- so the two uses of the
  rendering come apart there and it wants a ruling rather than a patch.
- ALPHA AND THE GROUP ORDER ARE STILL NOT ON THE FIGURE. The bracket caption
  carries the test and the adjustment, set on BOTH paths now so a consumed
  figure cannot wear the last figure's caption. It does not carry alpha or the
  group order, and the 7 August ruling's "a reader of the figure never needs
  the Info window's history" wants them. Adding a third clause changes strings
  v69 pins verbatim and geometry harness/bracketcap photographs; it needs a
  coordinated re-drive and is not done here. THIS GAP PREDATES THE STORE.
- ITEM 1.6 — SCATTER STORE WIRING. Ruled by Fable, 26 Aug: its sequencing
  behind the census fixtures STANDS — it is not started. THE SCATTER DOOR
  IS NOT WIRED. Ruling section (e) names two doors for 1.0;
  this is the first. `@emlDrawScatterPlot` still computes r and p at draw time
  from `annotCorrType$` (in `graphs/eml-draw-procedures.praat`, not
  `eml-graphs-form.praat` as the census's line numbers suggest -- those point
  at the dialog's seeding block). Same store, same read side, and
  `@emlRenderResultSettings` takes a second `.kind$` branch when it lands.

THE TWO NEIGHBOURING KEYS THE RULING ANTICIPATED ARE MOOT. A paired/repeated
door was to need row pairing in the key and the scatter a cross term, because
no per-column or per-level description of one column can supply either. The
whole-table key describes every cell, so there is nothing left for either to
add and nothing for a call site to declare.

STILL TRUE, AND NAMED BY THE 24 AUG VERIFICATION PASS: there is no pinned
validator for the fingerprint. Its mutation legs live in the phase2 suite, not
in `validate/`, so the main suite's count is unmoved by the shipped code and
the only evidence for it is evidence it wrote about itself. The cheap fix is
one `validate/` check that runs the phase2 legs, not more phase2 legs. It also
has no shipped caller — expected while the store is unbuilt, and the reason the
coverage question is worth settling before the store lands rather than after.

### FOUND BY VERIFICATION, 26 Aug — five items against the result-store batch, before it commits

- **A generated file installs into the source tree.**
  `plugin_EML_StatsGraphs/scripts/eml-lib-user.praat` is gitignored and
  generated. A GUI harness drive wrote it into the shipped source tree during
  this batch. While it is present it reddens `v47` twice, `v78` once and
  `v79` twice. The verification pass deleted it, but it RETURNS on the next
  Praat launch that runs `setup.praat` from this tree, so those five reds
  reappear after any GUI harness drive. Standing hazard, same family as the
  bracketcap rig deleting sibling break logs.
- **ITEM 3.5 (Fable's 26 Aug ruling) — the two `doTukey` literals. BUILT,
  NOT YET COMMITTED.** The two sites named in the ruling
  (`graphs/eml-annotation-procedures.praat:4042` and `:4649`) now take a
  resolved `.doTukey`, and the value comes from the launching dialog: the
  graphs form's shared Comparison menu carries an **"ANOVA only, no pairwise
  tests"** row (the wizard's own language-batch item-4 wording, punch list
  4.2), all six annotate-capable pages commit it to a new `annotPostHoc`
  global, and `@emlRunAnnotationComparison` reads that global on the same
  channel `annotCorrectionMethod$` uses. `@emlReportBridgeStats` reads the
  bridge's resolved flag rather than restating it, so the report and the
  three broom declarations under it follow the same one answer. A ROW AND
  NOT A NEW FIELD, deliberately: the Comparison menu exists precisely so a
  test family and its correction cannot be expressed inconsistently, a
  tickbox beside it could contradict a row naming a post-hoc, and a row
  costs no tab stop — so no page's tab order moved.
  - **Acceptance, as ruled:** `v127`'s leg1 and leg3, which were themselves
    the defect — they were written as "the literal is present" and so passed
    while the disagreement stood. They now assert the chain and the driven
    behaviour. Against the pre-item tree the amended `v127` reports **10
    FAILED of 68**; against the tree with the item built, **68/68**. The
    probe (`harness/doorcensus/probe.praat`) drives
    `@emlRunAnnotationComparison` twice on the leg1 fixture: pre-item both
    drives give `hasPairwise = 1`, `matrix rows = 3`; after, the opt-out
    drive gives `0`/`0` with the omnibus line unchanged.
  - **`v112`** gains `annotPostHoc` as RESULT-AFFECTING, with that
    measurement quoted. **`v61`** gains two checks that the Comparison
    menu's emitted rows and its decode/inverse agree on which rows are
    category headings — the row insertion moved every index below it, and
    nothing in Praat notices a decode left behind.
  - **STILL OPEN, and NOT closed by 3.5:** leg1's other half. The graphs
    door offers Tukey or nothing, so a user who chose Student t with
    Bonferroni at the Pairwise dialog still cannot make the figure show that
    test, and no sentence reconciles the two doors' pairwise verdicts. That
    is punch-list 8.2 / item 1.6, and `v127` now pins it open by name.
  - **FOLLOW-ON, opened by 3.5 and deliberately not built in it — the
    recorder does not capture `annotPostHoc`.**
    `@emlRecordCaptureStats` (`stats/eml-record.praat`) emits
    `annotCorrectionMethod$`, `annotAlpha`, `emlGroupSortAlphabetical` and
    `emlShowExplanations` into every recorded analysis or draw step, for the
    stated reason that a setting read from a global is invisible to a
    recorded call. `annotPostHoc` is read the same way and is classified
    result-affecting, so a recorded figure drawn with the post-hoc declined
    replays with a full Tukey matrix and a post-hoc table in its report.
    NOT BUILT HERE because that capture set is evidenced by a driven
    two-value leg in `harness/settingspub` plus four `v115` checks, and
    adding a fifth captured global without its leg makes `v115` describe an
    artefact that does not contain it. Build: one `posthoc_on`/`posthoc_off`
    leg pair in `harness/settingspub/settingspub.sh` and
    `settingspub_drive.praat`, `annotPostHoc` into `v115`'s `SETTINGS`, then
    the capture line. The capture line was written and reverted in the 3.5
    unit; it reddens `v115` on its own and is one line.
- **`v112` does not see the store's names.** Its derivation walks 71
  settings over 166 procedure bodies and finds zero `emlStore*`,
  `emlSettings*` or `emlPublishIn*` among them, because the walk drops any
  global written inside the doors' own closure and the bridge publishes.
  Ruling section (d) says "the section b census covers the store's names."
  It does not. Coverage comes from `v138` instead (60/60, asserting
  single-writer on the `emlStore` prefix). Either re-point the ruling's
  sentence at `v138` or extend `v112`.
- **Section (e)'s second door is not wired (ITEM 1.6).** `@emlDrawScatterPlot` computes
  Pearson and Spearman at draw time in seven places in
  `graphs/eml-draw-procedures.praat` — lines 4644, 4677, 4769, 5081, 5098,
  5164 and 5257 — with zero store references. The ruling wires both doors in
  1.0. Compounding it: `v112` already classifies eight
  `emlDrawScatterPlot` settings as result-affecting, so the settings census
  is built for a door the store does not serve.
- **`v84` and `v97` staleness deepens.** Both were already red before this
  batch; the batch changed `eml-graphs-form.praat` again, so the
  transcripts are now stale for a second reason. Needs a coordinated
  re-drive before the tag.

### RULED 26 Aug (Fable) — process instruction, and two punch-list items new to this file

**EVERY DIFF NAMES ITS ITEM.** A commit that changes behaviour states which
numbered item it serves, so the end inspection can tie changes to numbers.
A change that names no item cannot be tied. Applies to every diff in this
repo from 26 Aug on.

- **LANE 6 — the explanations default.** Not started. Ruled: built as
  ROUTING, never as a bare global flip — the menu seeds OFF, the wizard
  forces ON, and the graphs door inherits by launch path. See
  `PUNCH_LIST_DOORS_UNIFICATION_2026-08-25.md` lane 6 (6.1 toggle, 6.2
  wiring, 6.3 recording) for the full build.
- **ITEM 2.2 — the two-group "Group order:" line.** Already the remaining
  ordering clause of item 2.2 (not a new item). HALF BUILT: the direction
  half is done (`095dddb`). REMAINING: one line stating the group order in
  force ("Group order: table order (pre, post)") on grouped comparison
  reports, through menu, wizard, and graph doors. Red demo: a signed
  statistic with no named subtraction.

### RULED 26 Aug (Fable) — D-KW-ETA is a documented absence, not an exemption

`docs/RULING_KIT_DELTAS_2026-08-26.md`. The Kruskal-Wallis eta-squared[H] row
(`walkthrough/kit/quantities.tsv`, `emlRunKruskalWallisAnalysis` / `eta_squared`, 80 kit
rows) reads as a coverage gap in `compare.R`'s current `DECLARED[]` text — "a
coverage gap, not an error." Fable's ruling recharacterises it: the plugin
reports epsilon-squared only, by decision, and that decision is now recorded
rather than merely tolerated. Under the quantity contract's balance invariant
(`compared + documented-absent + tolerance-bounded = total`), these 80 rows
move into the DOCUMENTED-ABSENT bucket, cited to this ruling — never counted
as an exemption or left as an unexplained one-sided row.

The approved explainer line, gated on Ian's language-batch approval and NOT
to print before then:

    Epsilon-squared is reported; it corrects a small-sample bias in
    eta-squared.

`quantities.tsv`'s `D-KW-ETA` note now cites this ruling directly. `compare.R`'s
own `DECLARED[]` entry and its accounting categories are a separate, already-
queued change — not touched here, by the by-file rule.

## B. Form and dialog work

The ruling arrived 19-20 Aug and the block is lifted:
`docs/RULING_DIALOG_LABELS_v3.md` (supersedes v1 and v2) plus
`docs/ADDENDUM_WORDING_AND_ROADMAP.md`. Both rest on live probes of
Praat 6.6.30 under Xvfb, not on reasoning about Praat.

- **The label sweep, per the ruling.** Headings group; rows carry only what
  distinguishes them. Ranges become one paired row named by QUANTITY, never
  by axis. X and Y axis labels become one sentence-paired row on every page
  that has them. One page at a time, with the locality check run between,
  and the ruling's per-page row counts (12→9, 20→17, and so on) verified
  against the rendered page under Xvfb.

  DONE, all thirteen pages, 24 Aug, as one batched sweep with a single
  photographed re-drive at the end (ruled: the source-level checks stay
  green page by page, the photographed evidence goes stale en bloc). Row
  counts land on the approved targets ±1; the only overshoot is Spaghetti
  at +1. Every page now closes its fields inside a named group, the four
  acoustic pages carry one merged axes heading, and the paired axis-labels
  row exists on every page that has axis labels.

  Two answers the sweep had to measure rather than assume, both now in the
  code: the histogram's value range governs the HORIZONTAL axis
  (`@emlDrawHistogram` assigns `.xMin = .vMin`), so the label that read
  "Value range (bottom/top)" was backwards and now reads "Value
  (left/right)"; and the paired-row idiom is not exclusive to axes — the
  panel origin's x/y inches and the pitch floor/ceiling render the same
  way, which is why v84's axis roster is now derived from the group each
  row sits in rather than from the row's shape.

  Follow-up, small: the line-chart pages take the same grouping in their
  own file set as a separate commit, never as a retrofit against the old
  form.

  DONE, 24 Aug, as its own change over the tree's own pages. "What the lines
  are" folds its question into a 📋 Columns heading and stays at 4 rows.
  "Column Mapping" gains 📊 Analysis and 🎛️ Layout headings, merges its two
  📐 headings into one, and pairs its two axis-label rows: 23 rows before and
  23 after in advanced mode, 8 to 11 in beginner mode, where the three
  headings are what a branch that had none has to pay. Measured under Xvfb on
  6.6.30: 817 px to 787 px advanced, 347 px to 398 px beginner, both
  unclipped, and each delta accounted for row by row. "The Right-Hand Axis"
  is untouched -- rule 5 keeps its ruled rows and every field on it already
  renders under its 📐 heading.

  THE RANGE PAIRS ARE NAMED BY THE QUANTITY NOW ("left Time", "left Value"),
  like every other page, with a remap block after endPause carrying them to
  the *_range names the toggle and draw arms read; the paired axis-label row
  remaps to x_axis_label$ / y_axis_label$ the same way. v97 gained checks for
  both remaps, because a page whose typed values reach nothing passes a check
  that only reads labels.

  NO TAB INDEX MOVED ON ANY DRIVEN LEG. harness/linetree drives these pages
  in beginner mode, and no beginner field was reordered -- Time column, the
  tickboxes, the y-axis name, Line style, in that order, as run.sh's plans
  record. Headings take no tab stop. The ADVANCED page's fields did reorder
  (Line style, Gridline and the six frame controls move down; Output DPI
  moves to the end; the two range pairs and the labels row move up), and no
  leg addresses an advanced-page widget by index -- subjects_ci reaches that
  page and presses only buttons, which count from the end of the ring.
- **The 🏷️ heading overprints the row below it on a narrow dialog** (OPEN,
  measured 24 Aug, six pages). The markup legend the sweep gave every
  axis-label group is 83 characters —

      🏷️ Axis labels (blank = auto) · %italic #bold ^super _sub · \% and a space prints %

  — and where the page is narrower than that, GTK wraps it onto a second
  line while Praat has allotted the row one line's advance. The overflow
  ("prints %") is drawn ON TOP of the next row's label. It is legible as
  damage rather than as text: the paired label reads "printex# labels (x /
  y; blank = auto):" off the photograph.

  IT IS A PROPERTY OF THE PAGE'S WIDTH, WHICH IS DATA. A dialog is as wide as
  its widest row, and the rows are built from the user's column names — so
  the same page overprints on one table and not on another. Photographed on
  the scatter page at 689 px (`t8_2_Scatter_Plot_Column_Mapping.png`) and on
  the line chart at 707 px.

  IT PREDATES THE LINE CHART'S GROUPING and was not caused by it. Before
  that change the line chart's next row was the short "X axis label:", whose
  right-aligned label starts well clear of the overflow, so the wrap was
  merely an odd-looking two-line heading; pairing the labels lengthened that
  label and the two now collide. Every page the sweep gave a paired labels
  row has the collision: scatter, spaghetti, histogram, grouped violin,
  grouped box, and now the line chart.

  NOT FIXED HERE, DELIBERATELY. The string is shared by six pages; shortening
  it on one would leave five broken and add a sixth spelling of one heading.
  It wants one commit over all six, and a decision about what to drop —
  "\% and a space prints %" is the half that overflows and also the half
  that states a real Praat rule.

- **The label character law** (ruling, measured). Before the parenthetical,
  a field label may contain letters, digits and spaces only, plus the
  leading left/right pairing word. Praat strips the label from the first
  "(" onward, turns spaces into underscores, and keeps everything else
  verbatim — so a hyphen, a slash or an emoji makes a variable that is
  bound but unreachable, and code referring to it silently reads
  arithmetic instead. Demonstrated: a field named "left Y-limits" fed -99
  to code that thought it was reading the user's 5.

  BUILT, and both of the wider things the ruling asked for are in
  `validate/v98_field_names.R`: the full character class (letters, digits
  and spaces only before the parenthetical, plus the leading left/right
  pairing word), and uniqueness per RENDERED BRANCH — every field carries
  the branch path it sits on, and a shared name is judged provably-together
  (fails), provably-apart in two branches of one `if` (legal, and it stays
  legal), or cannot-rule-on, which is pinned by name so a new one gets read
  by a person.

  A rendered page also carries rows nothing in the block declares. A
  `beginPause` block is ordinary code, so a procedure called from inside one
  emits its field rows into that dialog: `@emlWrapperCommonFields` is
  declared in `stats/eml-output.praat`, ten wrapper dialogs call it, and
  eleven sites read the `clear_Info_window` it binds. The sweep follows a
  call made inside a block, audits the rows it contributes as rows of the
  calling page, and fails a call it cannot resolve. Measured under Xvfb by
  `harness/labellaw/inject.sh`, which renders
  `validate/fixtures/dialog_labels/inject_collision.praat` and reads the
  collision back out of Praat; demonstrated red against seeded copies of the
  shipped tree via `$EML_DIALOG_SRC`.

  OPEN, AND NOT PART OF THIS ITEM: `validate/v99_form_variable_locality.R`
  reads dialog blocks with a scanner of its own that does not follow a
  procedure call, so the rows a procedure contributes are outside its
  subject too. Whether locality should see them is a question for whoever
  owns v99.
- **The histogram compound row is REFUSED** (Ian, 20 Aug): bin count and top
  frequency are totally different measures, and the paired row is for two
  halves of one quantity. The histogram page takes the other two savings and
  goes 32 to 30, not 29. Nothing else uses the pattern, so it is now unused
  everywhere.
- **Terminology-uniformity audit — done, with six fixes.** The four terms
  now read the same way everywhere: CONDITION (a level of a within-subject
  factor), TOKEN (a replicate within one cell), MEASUREMENT (the dependent
  variable), and WITHIN-SUBJECT / PAIRED (a design property; "paired" only at
  k = 2). What it caught is in the closed section. The line-chart tree's
  "different measurements" wording was confirmed correct and left alone —
  there it names genuinely different variables.
- Booleans are OUT OF SCOPE by ruling: no gating, no collapsing, no
  relocation, labels unchanged. Title and subtitle stay two full-width
  rows, also by ruling.
- **Legend placement has no encoding validator.** It has the structural
  protection gridline mode has — one registry, one seed, one commit,
  identical option lists, and now a clamp on load — but nothing pins the
  encoding the way the gridline-mode check does. The legend geometry check
  says in its own text that the dialog side is out of its scope.

## B3. Dialog audit, 20 Aug — what the hand-read found

Every one of the 128 dialogs was opened and read. The claim that the
lagging-control defect existed only on the six comparison pages was WRONG.

STILL OPEN, lagging controls:

(The line-chart column-mapping page is closed -- see below.)

(Stored values that could seed a menu out of range are closed -- see below.)

DEAD CONTROLS -- RULED BY FABLE, 20 Aug (`docs/RULING_DEAD_CONTROLS.md`).
One principle governs all of them, and it is house law now: THE PLUGIN MAY
OVERRIDE A USER'S CHOICE, BUT NEVER QUIETLY. Wherever code ignores a control
-- because of the data or because of a sibling control -- it says so at the
moment it happens, in the output the user reads and in the recorded script.

- Histogram display mode: kept, with the condition in the label ("2 or more
  groups") and a line at the override site saying a faceted request on one
  group was drawn overlapped.
- The regression group column: CLOSED (punch list 4.5, 26 August 2026). Ported
  the correlate dialog's whole pattern into ONE shared procedure,
  `@emlRunGroupedRegressionAnalysis` (stats/eml-analysis.praat), called from BOTH
  doors -- the menu's scripts/eml-regress.praat and both of the wizard's
  regression pages (B_REG_COLUMNS and D_PREDICT_COLUMNS) -- rather than a
  copy per door. Per-group fits beside the overall one, groups too small
  named and skipped (n < 3, the same floor @emlLinearRegression enforces),
  labelled rows in the export ("(overall) ...", "<group> = <level> ..."),
  and the drawn lines now match the report on both doors (the menu door's
  Draw already carried the group column; the wizard's regression Draw did
  not, and now does). Oracled against base R's own `lm()` per group on
  Sol's Simpson fixture: validate/v136_regression_grouping.R,
  harness/regressiongroup/. The door census's own leg5
  (validate/v127_door_agreement_census.R) is revised from SILENT
  DISAGREEMENT to AGREE alongside it.
- The wizard's variance assumption and the three wrapper labels: both become
  ONE list of complete choices, the pattern the comparison pages already use
  -- "Parametric -- Welch t (unequal variances)", "Pairwise t (Welch), Holm".
  The dead control disappears by construction, because the sub-choice only
  exists inside the options where it is real.

Sequencing is Fable's: the histogram disclosure and the two collapses ride
the compaction sweep's re-drives; the regression feature has landed (see
above) using the language batch's existing verbatim wording, so its report
strings were written once.

## Newly ordered, 20 Aug

- **The Tukey family-wise interval ignores the alpha you set.** Found by the
  quantile sweep, not named in the 20 Aug ruling, and the same defect class:
  the ANOVA report's "Tukey HSD Mean Differences (95% family-wise CI)" table
  and the `conf.low` / `conf.high` pair in the Tukey export frame both take
  their critical q from `@emlOneWayAnova`, which passes 0.05 to
  `@emlTukeyHSD` and takes no alpha of its own. Measured: on a three-group
  fixture the whole report is byte-identical at annotAlpha = .05 and .01,
  under a fixed "95%" heading, on a path where the stars beside it do obey
  the user's alpha.

  It is NOT the same fix as the other three. `@emlTukeyHSD` already takes
  `.alpha`; the constant is at the call site inside `@emlOneWayAnova`, whose
  arity is fixed by roughly twenty-five callers across the plugin, the dev
  tests and the harness drivers, and whose `.qCritical` also reaches an
  exported column. That is a scope of its own and needs a ruling on whether
  the level travels as a new argument or as a graphs-layer resolution at the
  reporter.
- **The door-agreement census** (`docs/WORK_ORDER_DOOR_CENSUS.md`). Every
  user intent reachable through more than one door gets one adversarial
  fixture -- built so that divergent mappings produce loudly different
  numbers rather than coincidentally equal ones -- and a leg per door. Each
  leg asserts one of exactly two things: the doors agree to oracle tolerance,
  or they state plainly that they are showing different models. Silent
  disagreement is the only red. Seeded with one already found: the
  correlation dialog reports overall and per-group labelled, the regression
  dialog reports overall only, and the scatter annotation reports per-group
  only.
- **Behaviour is not intent** (standing law). When a control's promise and
  the code's behaviour disagree, the first question is which side is the
  defect. Lowering a label to match the behaviour needs positive evidence
  that the behaviour is the design; without it the finding is an unfinished
  implementation and goes to Ian as scope.

## C. Everything else

### Not started

1. **Recorder state publication.** The form states its complete display
   state once per press; the recorder writes it ahead of each step; a check
   pins seeded == published == emitted.

   THE THREE SETTINGS THAT CHANGE A RESULT ARE BUILT AND DRIVEN (24 Aug).
   `@emlRecordCaptureStats` in `stats/eml-record.praat` writes
   `annotCorrectionMethod$`, `annotAlpha` and `emlGroupSortAlphabetical`
   ahead of every analysis and draw step, each behind its own
   `variableExists`, in the same place and for the same reason as
   `@emlRecordCaptureEnv`. `harness/settingspub` records a session at each
   of two values of each setting, replays the emitted script in a fresh
   Praat process, and compares the numbers.
   `validate/v115_settings_publication.R` reads it, 105 checks;
   `harness/settingspub/break.sh` removes the call and reds 53 of them. The census moves 14 -> 15 emitted,
   18 -> 17 not-emitted user choices; it sees only `annotAlpha`, because
   its frame is `@emlInitializeDrawingDefaults`' seeded block and the other two
   belong to the form and to `stats/eml-extract.praat`.

   WHAT IS LEFT OF THIS ITEM: the twelve DISPLAY-ONLY settings v112's
   census names — the font, the gridline mode, the legend placement, the
   tick, axis-name and axis-value flags, the inner box, the subtitle, the
   annotation style, the scatter's dot size and its formula toggle — and
   the `.displayMode` instance below. None of them changes a number.

   ONE CONCRETE INSTANCE, FOUND 24 AUG WHILE READING THE HISTOGRAM DRAW.
   The recorder writes `.displayMode` into the emitted script AFTER the
   one-group path has forced it from 2 (faceted) to 1 (overlap). So a
   session in which the user chose faceting and got one panel records a
   script that says they chose overlap. The replay draws the same picture,
   which is why nothing has gone red: the fidelity claim the recorder makes
   is about the USER'S CHOICES, and this is the draw layer's derived value
   standing in for one. Publication (this item) is the fix — the form
   states what was chosen, not what survived the draw.

   MEASURED, AND THE MEASUREMENT IS NOW IN THE REPO:
   `validate/tools/recorder_census.py`, so this stops being a number in a
   sentence. Of 41 globals the draw layer seeds, 14 are assigned in scripts
   the recorder actually produced and 27 are not; 18 of those 27 are real
   user choices — the font, gridline mode, legend placement, the tick,
   axis-name and axis-value flags, the inner box, the subtitle, the
   annotation style and alpha, the scatter's dot size and formula toggle.
   The rest is bookkeeping.

   The earlier "13 emitted" was measured by asking whether the RECORDER'S
   SOURCE mentions a name, which over-counts: two names it mentions
   (`emlDrawnMinX`, `emlLegendSepActive`) appear in no emitted script. The
   census reads emitted scripts instead. It measures a FLOOR — a setting
   only shows as emitted if some committed recording exercised the figure
   that carries it — and says so.

   WHY THEY ARE MISSING, which decides the fix: a recorded step is a
   procedure CALL with its arguments, so a setting passed as an argument is
   recorded and a setting read from a global is invisible. The plugin's
   display state travels in globals. `@emlRecordAxisRequest` is the
   existing precedent for the answer — the form publishes what the user
   asked for and the recorder prefers it over what the draw resolved.

2. **Four commands leave no trace in a recorded script**, measured by
   `validate/v107_record_census.R` over every command `setup.praat`
   registers: creating a demo table, both doors of the table editor, and
   checking data. Thirteen record their work. The check is a ratchet — red if
   a fifth appears, and red if one is fixed without its line being removed —
   so the gap cannot grow quietly and the list cannot outlive the defect.

   The demo generator is the sharpest of the four: it makes a table out of
   nothing, so a recording taken afterwards describes an analysis of data
   whose origin the script cannot state. The editor is the most dangerous:
   a replay runs the recorded analysis against the table as it stands now,
   and nothing says the numbers were edited in between. Checking data is the
   weakest and may end up exempt with a reason rather than fixed.

3. **Recorder records table creation.** Ruled: creation becomes a recorded
   step, split by source — plugin-created gets its command and a seed,
   file-loaded gets its path, pre-existing states its precondition loudly.
   The recorder has five step kinds and none of them is creation; it has no
   notion of how a table came to exist.

### Red today, and known

TWO STALENESS BINDINGS, ON PURPOSE, both since the line chart's own pages
took the layout grouping:

- `v97` "the transcript was taken from THIS eml-graphs-form.praat"
- `v84` "the transcript was driven on THIS form's code"

Each is one check. Both are the photographed evidence declaring itself older
than the form, which is what those digests exist to do; nothing else in
either file is red, and no other check anywhere reads a line-chart
photograph. They clear on the next re-drive of harness/linetree and
harness/axisrefuse, which is one drive at the end of this page set under the
standing one-re-drive rule -- and which needs no re-teaching, because no tab
index on any driven leg moved.

A THIRD, since the recorder gained `@emlRecordCaptureStats` on 24 August:

- `v97` "the transcript was taken from THIS eml-record.praat"

`v97` binds the recorder's own comment-stripped digest as well as the three
graph files', because section 15 claims a script that file emitted redraws
the figure byte for byte. The two headless rigs bound the same way -- `v86`'s
`harness/vecfig` and `v87`'s `harness/runblock` -- were re-driven with the
change and are green, and the only line either emitted script gained is the
settings statement in front of the draw call; no number in either moved.
`v97`'s is a GUI drive and clears with the same re-drive of
`harness/linetree` the two bindings above are waiting on.

Before that: the suite was green -- 15974 checks, 15974 passed, on the 24 Aug
verification pass over the whole tree.

The two entries that stood here are closed. The line-style menu on the second
series went green on 20 Aug and stayed green -- it was listed as red here for
twenty-one commits after it was fixed, which is the argument for reconciling
this file against a run rather than against the last edit. The line-chart
photographs were one commit stale on two digests and were re-driven on 24 Aug.

### Test-coverage gaps

- **The pitch floor and ceiling are now judged by nothing.** Removing them
  from the axis-refusal roster was correct — they set an analysis search
  range, not a plot axis, and they only ever qualified because they render as
  a paired row. But they remain a range a user types, floor above ceiling
  remains nonsense, and after the 24 Aug sweep no check asserts anything about
  their ordering. Whether they want a refusal of their own is scope, not a
  defect.
- **A range pair filed under a non-axis heading escapes the whole suite.**
  Measured 24 Aug against all twenty-five checks that read the graphs form: a
  pair placed under the layout heading leaves the axis roster and nothing
  objects, so it also escapes the max-below-min refusal. Only the transcript
  digests move, and they move for any edit at all. The axis-refusal check's
  header previously claimed the page-composition checks caught this; they do
  not, and the header now names the gap instead.
- **RESOLVED 25 Aug.** The validator index documented the older checks only;
  nine of the newest (v107-v115) had no entry. `validate/REGISTRY.md`'s
  script table is now current with `validate/run_all.R`, derived by diffing
  the two programmatically rather than by re-reading the directory; each new
  row states what the check asserts and what it reads, in the voice of the
  rows beside it. The table has no generated portion -- it is hand-written
  throughout, and this pass touched only the nine new rows.
- Seven filtered-autocorrelation calls under harness/graphaxes run with "very
  accurate" ON where canon has it OFF. Test fixtures, not shipped code, so no
  user's number is wrong -- but those fixtures measure something the plugin
  does not do. Reported rather than changed: which way it goes is Ian's.
- Two plugin versions installed at once can produce a truncated menu with
  no warning. Nothing tests it.
- **RESOLVED 25 Aug.** The pitch parameters were pinned equal across every
  path, but two exec call sites in the graphs form spelled the
  filtered-autocorrelation tail literally instead of calling the procedure
  that owns it. Both now call `@emlPitchArgsFAC` and interpolate its
  `.args$` straight into the `To Pitch (filtered autocorrelation)` call
  (verified against a live Praat 6.6.30 run: the interpolation produces the
  identical command and the identical mean F0 as the literal spelling did).
  `v105_pitch_parity.R`'s source-level scan cannot argument-match a single
  interpolated token against canon the way it does a literal tail, so it now
  recognises the joined pattern (the same "builds its arguments from the
  procedure / spells no literal tail" shape section 4 already used for
  emitted calls) and still goes red if a literal tail creeps back in --
  confirmed by re-introducing one by hand and watching the two `== canon`
  assertions fail. `v105`'s text assertions for every other still-literal
  site are unchanged.

### Housekeeping

- **RESOLVED 25 Aug.** The process-artefact debris the dialog-height entry
  above closed was still tracked in two other harnesses: `axisrefuse` and
  `linetree` each carried their own `xvfb.log` and `wm.log`. Established
  before untracking, not assumed: `grep -rl` for both names across
  `validate/` and `harness/` turns up only each rig's own `run.sh`, which
  only ever creates them with a `>` redirect or reads `wm.log` back for a
  diagnostic print on a failed launch -- no check opens either file to
  decide anything, matching the dialog-height precedent exactly. Everything
  else under each `out/` -- the TSVs, the per-case logs, the photographs --
  stays tracked; only these two names per rig were untracked, following the
  same `.gitignore` convention dialog-height already established.

- Line-chart evidence was stale deliberately behind the sweep's single
  re-drive. Discharged 24 Aug: driven on Praat 6.6.30, 765 checks green. The
  line chart's own pages were never touched by the sweep -- 80 widget lines
  identical on each side of the commit -- so only the digests moved.
- **Photographed-dialog evidence — DISCHARGED 24 Aug.** The batching ruling
  held the pictures stale behind one re-drive at the sweep's end. That drive
  ran: axis refusal 78 checks green, line chart 765 green, and the whole suite
  green behind them.

  WHAT THE RE-DRIVE TAUGHT, kept because the next sweep meets it again. The
  harnesses address dialog fields by TAB INDEX, and seven indices moved on the
  box-plot and scatter pages. The reason is not the one this file recorded:
  group headings are comment rows and take no tab stop, so they shift nothing.
  The range rows moving out of the layout group and up under the axis heading
  is what moved them. Anyone re-deriving indices by counting added headings
  gets the wrong answer.

  Each corrected index was measured before anything was driven — a marker typed
  at every position and read back from the variable that received it, with the
  neighbouring positions recorded beside it. A Praat paired row takes one tab
  stop per box, not one per row; that had never been covered and now is.

  The evidence that the indices are right rather than merely different: across
  the re-drive the axis-refusal transcript changed in exactly two lines, the
  code digest and a new line naming the machine. Every refusal message, every
  ink measure and every recorded axis range is byte-identical. A wrong index
  types into another box and the refusal names a different axis or never fires.

## Closed

**Every report interval takes its level from the alpha in force.** The
correlation band was the first; the sweep the ruling ordered found three more
that spell the level as a TAIL PROBABILITY rather than as a z value, which is
why grepping for 1.96 could not see them: the two-group report's CI of the
difference and the regression coefficient table's CI column, both
`invStudentQ (0.025, df)`, and the Feldt interval on Cronbach's alpha,
`invFisherQ (0.025 / 0.975, ...)`. All three were measured ignoring the
control before they were touched -- at annotAlpha = .05 and .01 the three
printed intervals were byte-identical.

The two report sites now resolve the level through one procedure,
`@emlCIAlphaInForce`, so the stars, the error bars and every bracket in that
module read one answer. The Cronbach kernel takes its level as an argument
the way its sibling `@emlWilsonInterval` does, and its outputs are `.ciLow` /
`.ciHigh` rather than names that assert a level the caller chose. Every label
is built by `@emlCILevelLabel`, which renders the percentage without rounding
it to a whole number -- so alpha = .005 reads "99.5%" and .025 reads "97.5%",
where rounding printed "100%" and "98%".

`validate/v109` drives all three live at two alphas against `t.test`,
`confint(lm)` and the published Feldt form, requires each printed label to
name the level it used, requires every bound to move when the alpha does, and
carries one seeded-constant negative control per site. 65 checks. Agreement
with R is exact to the printed precision at .05, .01, .005, .025 and .1.

The rest of the sweep is dispositioned in place, with the reason written at
the site: `@emlDescribe`'s interval, the LMM Wald intervals and the Tukey
call inside `@emlOneWayAnova` keep their constants because the label beside
each states the same level and no dialog offers a control for it -- except
the Tukey one, which is a real finding and is in the open list above.

**The text wrapper keeps "label = value" on one line.** The space before an
equals sign and the space after it are not break candidates in
`@emlWrapText`; the line breaks at the last space that is not part of such a
unit, and when a unit is itself wider than the line the search falls back to
any space and then to a hard break. Every property the callers depend on
holds: breaks land on spaces, no line exceeds the width, and the segments'
word count still sums to the input's, which is what
`@emlDrawAnnotationBlock` needs to carry Picture markup across a break.

The known cost was driven, not assumed. `harness/wraptext/` runs the corpus
through two plugin trees that differ in `@emlWrapText` and nothing else: 39
annotation strings from the omnibus, correlation, regression and disclosure
call sites at every width from 16 to 72 (2223 wraps), and 182 blocks of one
to six of those lines on seven figure sizes (1274 boxes) through
`@emlDrawAnnotationBlock`'s own fit loop. The longest line grows in 0.94% of
wraps, by a median of 3 characters and never past the width, and shrinks in
19.9%. The box takes one extra fit pass on 4 boxes of 1274 — one in 319,
better than the one in 150 the standing list warned of, and never more than
one pass — while 10.6% take fewer. Breaks touching an equals sign, over
those boxes: 1316 to none. The probe is not wired into the suite.

**The replayed save's receipt is read, not just its files.** `harness/vecfig`
drove record and replay and looked only at the disk; the three lines
`@emlRecordReplaySave` prints -- how many files, where, under what base name
-- were the one thing an unattended replay says about itself and nothing
asserted them. The harness now takes them verbatim into `VECFIG.tsv` and
`validate/v86` compares them to that replay's own disk: the count against the
files carrying that base name, the folder against the folder it was pointed
at, and the base name against a base name a file was actually written under.
The comparison is deliberately NOT against the recording's receipt --
`@emlRecordReplaySave` regenerates the stamp rather than replaying it, so two
receipts that agreed would mean the defect that procedure exists to prevent.
Fourteen checks, and two new breaks in `harness/vecfig/break.sh` watched red:
`receipt_stale_stem` (the recorded base name printed instead of the written
one) puts ten red and moves nothing else in the file, `receipt_before_report`
(the report written after the receipt rather than before it) puts the four
count checks red on a save where nothing failed and nothing went missing.


**A bad line in the config file can no longer lock a dialog.** Every menu
setting read from disk is parsed and range-checked in one step, at the line
it is read. A value that is not an option, or a line that is empty or
corrupt, falls back to the default instead of drawing a blank menu the form
then refuses to close -- a dead end that survived restarting, because the bad
value was on disk.

**The exported summary counts conditions, not groups.** A repeated-measures
ANOVA and a Friedman test wrote the number of conditions into the summary
CSV under `n.groups` — the same column every independent-groups test uses.
Anyone reading that file, or a script reading it, was told a
between-subjects design had been run. It reads `n.conditions`.

**"Compare paired..." says what it does.** The menu item read "Compare
paired/repeated...", but the dialog behind it takes exactly two columns and
offers only the paired t-test and Wilcoxon. Anyone with three or more
conditions who followed the word "repeated" landed somewhere that cannot run
their design. The repeated-measures route is the Stats Wizard, and the
reproduction notes recorded with an RM-ANOVA or Friedman result now name it
instead of the two-column dialog they used to point at.

**The wizard stops calling a two-condition design "repeated measures".** Its
plan report described a paired t-test or Wilcoxon as "Two paired / repeated
measures", which reads in a manuscript as a design that was not run. It says
"Two conditions (paired)". The page that chooses between them is titled
"Paired — Choose test", matching the column-selection page beside it.

**The line chart rebuilds its page when the time column moves.** Everything
on that page except the time menu itself -- how many series tickboxes there
are and what they are called, whether the interval offer appears at all, and
the observation count printed inside its label -- is worked out before the
page opens, from the time column it opens with. Choosing a different one and
pressing Draw drew a figure whose page had been answering a different
question. It now says so and rebuilds instead, keeping the ticks by name; one
press, and only on the action that changes what the whole page means. A
sixteenth drive leg walks it under a real X server and reads the box and the
rebuilt page off the photographs; without the guard the walk cannot reach the
box at all.

**A bad line in the config file can no longer lock a dialog.** Thirteen
stored settings are parsed and clamped in one step at the point the line is
read; before, eleven had no range check at all and the two that did tested a
value that could already be undefined, which no comparison catches.

**The table editor's search scope cannot be seeded past the end of the
table**, and **the wizard says conditions and within-subject** rather than
counting "repeated measurements" and calling every within-subject design
"paired" -- the second of which was sending anyone with three or more
conditions to the independent-samples option.

**Three things that worked and were unguarded now have checks**: legend
placement's encoding, the ASCII fold at the file boundary, and the pitch
parameters across every path that uses them.

**Every validator now sets an exit code when run on its own.** Seven printed
their report and returned success whatever the result, so a failing check was
invisible to anything reading exit codes.

**The field-name check reads all 129 dialogs.** It matched a bare `endPause`
to find where a dialog ended, and this tree writes `clicked = endPause:`, so
97 of them were dropped from the population without a word.

**A correlation cannot be grouped by one of the columns it correlates**, and
the dialog is now driven rather than only read. Three cases press its
buttons in order — offer the column, move X onto it, pick it — and assert
that no grouped analysis ran, that the refusal named the column, and that
coming back rebuilt the menu. The pre-guard wrapper turns nine of them red.
The drive answers the shared refusal dialog by replacing that one procedure
in a copy of the tree, with the rest of the file hashed against the shipped
bytes, because a Praat procedure cannot be stubbed by redefining it —
measured: the duplicate warns and the first definition wins.

The list of grouping columns has to be built before the dialog opens, from the X
and Y of the previous pass, while X and Y are chosen on that same page — so
moving X onto a column the list already offered, and then picking it, ran a
correlation of a column against itself split by itself, and reported the
result. That combination is now refused with a sentence saying why, nothing
runs, and coming back rebuilds the list against the columns now chosen. Only
that one combination is refused: nothing else about a column's eligibility
depends on X and Y, so an ordinary change of X or Y still costs no extra
press.

**The render-level geometry check runs.** It reads the frame, the ticks and
the plotted extremes out of a saved figure as numbers and asserts they land
on one rectangle, for all thirteen figure types, with two break tests that
move the font by one point and must turn it red. It was written, passing,
and the one check file the suite runner did not list — so it caught
nothing. The suite now also refuses to run at all if any check file in the
folder is missing from its list, which is the asymmetry that hid this: the
runner asked whether every name was a real file and never whether every
real file was named.

**The comparison control is one dropdown.** Test type, post-hoc and
correction were three controls, and the correction menu was built from the
PREVIOUS run's test type, so a user switching to a nonparametric test got
whatever correction the last run left behind — invisibly, having never
chosen it. They are now a single list of complete choices with
`-- Parametric --` and `-- Nonparametric --` section headers, and the
category-header guard from the graph-type menu is reused on all six pages.
No mismatch is expressible any more. The six pages are bar, violin, box,
histogram, grouped violin and grouped box — spaghetti was named in error in
earlier versions of this file; it has no comparison control at all.

**Save offers the figure.** Every route that draws now detects the drawn
page and starts the figure tickbox ticked, and the check that pins the
tickbox line landed in the same commit.

**Reports and CSVs are ASCII at the file boundary.** One non-ASCII
character used to make Praat rewrite the whole file as UTF-16, which R,
pandas and Excel cannot read. The fold runs on report content and on every
CSV cell. (The recorder log is deliberately outside this, and says so.)

**Duplicate output names go through the shared unique-path procedure**,
which no longer mis-splits a folder whose name contains a dot. Three checks
pin it and two harnesses drive it.

**Pitch analysis uses the canonical parameters on every path**, including
the dev tests and the code the recorder emits. This shifts a reported mean
by about 1 Hz on a short token; ruled, no release note.

**"Erase page first" is remembered while you work** — on at session start,
carried across draws, never written to disk.

**Legend placement says when it applies**: the label reads "(when drawn)",
and the key now has a clamp on load.

**The table editor cannot write one cell's value into another.** Choosing a
different cell and pressing Set without changing the Value box now writes
nothing and shows the chosen cell's real contents instead; typing a value
into a newly chosen cell still writes on the first press. Two drive cases
and eleven checks, with the pre-fix editor demonstrated writing "A1" into
row 3.

**Every figure type is driven through the form's own dispatch**: sixteen
legs, one Praat process each, recorded and unrecorded runs kept separate.
The seam that let a scatter abort reach a user before the suite saw it is
now covered.

**Font geometry root cause found and fixed** — Praat converts a viewport
using the margins in effect when it is SELECTED, so the panel viewport now
asserts the body size before selecting; every annotation routine restores
the ambient size, including on early exits; the coefficient plot uses the
shared layout and honours the frame toggle; facet labels stay on their
panel. Ian confirms the scatter symptom is gone.

**Earlier, and still true.** R-squared appears once per figure. The
subtitle no longer persists across sessions. Stop always stops; recorder
messages append instead of clearing the Info window; the phrase table is
cleaned up; recording starts with nothing selected. Dialog field names are
pinned against truncation and collision, and every dialog is checked to
read the fields it offers — which caught the histogram's frequency cap
being offered but ignored.
