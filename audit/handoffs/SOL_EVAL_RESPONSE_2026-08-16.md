# Response memo — Sol 5.6 evaluation + rulings on the three open questions

From the stress-test session, 16 Aug 2026, after independent verification at HEAD
(post-batch-two, suite 11,786/11,786 per AUDIT_RESPONSE_STATUS_20260815.md).

## Part 1 — Sol 5.6's claims, verified

**CONFIRMED, act on it first: the one-tailed contract (Sol §1).**
Empirically reproduced at HEAD with the kernel directly (praat_barren):
group1=[8..12], group2=[10..18] → t=-2.5298, tails=1 p=0.0227; groups REVERSED →
t=+2.5298, tails=1 p=0.0227 (same). A fixed-direction test must give .0227/.9773.
Mechanism: eml-inferential.praat computes `.p = studentQ(abs(.t), .df)` for tails=1
(same pattern in paired t and the Pearson/Spearman kernel). Scope verified: every
REGISTERED call site passes tails=2 (eml-analysis.praat:243/1796/3633; the only
tails-agnostic extra callers are the unregistered quick-start/stats-demo scripts) —
so shipping menus are unaffected; the public scripting API is wrong. MW/Wilcoxon
already implement true fixed alternatives (matching R's wilcox.test) — use them as
the in-house model. Implement Sol's fix as specified: explicit
two-sided/greater/less parameter (deprecate numeric tails=1), tail from the SIGNED
statistic, p=1 for wrong-direction perfect effects, sign-reversal regression matrix
across Welch/Student/paired/Pearson/Spearman. This is now the only known wrong
NUMBER in the plugin; it outranks everything else open.

**CONFIRMED at HEAD:** manifest --check red (stale since 4 Aug); check_includes red
with 22 entries (the tutorial's guarded @thisProcedureDoesNotExist is a documented
KNOWN state — the checker needs guarded/optional-call awareness per Sol §3, plus
the fixture suite Sol suggests); docs/procedure-reference.md and docs/recipes.md do
not exist while plugin/README.md links both (lines 92/115/116); root README still
"coming soon"; no .github/workflows.

**STALE in Sol (already closed at HEAD — its snapshot predates batch two):**
one-bin Spectrum (+ the LTAS sibling), skew/kurtosis in tidy, recorded axis into
the editable block, the stale oracled capture, batch registration. When relaying
anything from Sol's open-issues table, check it against
AUDIT_RESPONSE_STATUS_20260815.md first.

**ENDORSED from Sol's test lists:** the directional matrix (P0-1, part of the fix
above); "one result through every door" (P0-2) — adopt as the UNIFICATION'S
acceptance test, not a separate project; built-artifact install smoke test (P0-3;
Linux is coverable in this sandbox, macOS/Windows need real machines); CI gates
(P0-4). From P1: cross-platform render comparison and CSV round-trip fuzzing are
real and new; interaction follow-up and performance envelope are already tracked
(D38/D40; 10k-row timings measured in the audit).

**AUTHOR-PHILOSOPHY items (not defects; for Ian's editorial queue):** the wizard's
deterministic test-selector framing vs evidence-and-tradeoffs (sound critique,
consistent with the smoke-alarm wording philosophy); vector (PDF/SVG/EPS) export
for the "publication-quality" claim; release positioning ("core teaching and
small-study procedures inside Praat" vs implied general coverage); README shipping
surface vs roadmap.

## Part 2 — recommendations on the status file's three open rulings

**A (axis publication escapes the form, session-scoped):** the ruled semantics are
CONSUME-ONCE — the form's published request is valid for exactly one draw, then
spent. Root cause, precisely: @emlRecordAxisRequest prefers the form globals
whenever they EXIST, and existence is permanent in Praat, so "a form ran earlier
this session" masquerades as "this draw came from the form"; every formless draw
after the first form draw then inherits stale numbers over its own correct
arguments (which the fallback already handles right). Implement either as a
validity flag (form sets requestLive=1 at publication; recorder reads the pair
only when live and immediately reassigns 0) or, preferred, as a STEP STAMP (form
publishes pair + current recorder step number; recorder accepts only when the
stamp matches the step being recorded) — the stamp is self-cleaning and
generalizes to any future published-state family. The pair itself cannot be reset
(0/0 is the auto sentinel); the companion signal can, which is the entire trick.
Both-or-neither on the pair stands, as the status file argues.

**B (legend two-pass records two draw steps):** add the record mark/rewind so one
user action emits ONE draw step carrying the FINAL resolved range. This is the
recorder-side twin of the duplicate-export defect already fixed; same principle,
same test shape (replay must be byte-identical on same data).

**C (two-group bracket figure names no test):** set annotTextN on the two-group
arms so the corner box names the test and statistics, exactly as the k>=3 arms do
after ruling 11. One invariant — "every bracket-bearing figure names its test" —
with no two-group special case; the two-group line claims no adjustment, which is
honest for a single comparison.

## Part 3 — notes on the "just work" queue

D (dead @emlCheckPlausibility): retire it; wiring it up adds a caller nothing
asked for, and v68's pin makes either choice deliberate. E (first-ink trap in
v66): fix with the pattern already used elsewhere this week. F (REGISTRY narrative
stops at v38): real debt — 34 validators undescribed in the file that calls itself
the full reference; schedule as a writing task, not a lint. G (gridmode positional
drift, exits 0 while setting wrong controls): same class as the menu-coordinate
drift — recommend the same remedy that fixed the menus: anchors proved by
screenshot at run time, or a rendered-state assertion after setting each control.
