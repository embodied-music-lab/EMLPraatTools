# Adversarial check — EML Praat Tools audit program

Date: 4 August 2026
Scope: everything delivered in this audit/remediation program.
Method: seven independent probes, each designed to *fail* if the claimed
result were false. Verification is against what is saved on disk, not
against the session record.

---

## Why these seven

A remediation program produces two kinds of claim: "this artifact is
correct now" and "this mechanism will catch it if it stops being
correct." The first kind is checkable by re-running. The second is not —
a green harness proves nothing about a harness that cannot go red. So
four of the seven probes are re-runs (1, 3, 5, 6) and three are hostile
injections (2, 4, 7) that deliberately break something and require the
mechanism to notice.

---

## 1. Full-suite re-baseline — HOLDS

    python3 dev/tools/run-tests.py    ->  exit 0

    Summary: PASS=20, XFAIL=1
    Checks:  1232 declared, 0 failed, 0 skipped
    Controls: 1 negative-control suite(s), 4 checks, 4 failed by design

No `NO-SENTINEL` line anywhere in the output, down from eight before the
counter-bridge conversion. Per-suite check counts: phase2/test-12-groups 6,
batch1 57, batch2 48, batch3 87, batch4 82, batch5 111, batch6 165,
batch6b 85, batch7 108, test-regression 36, test-shapiro-wilk 31,
test-theilsen 47, test-wizard-explanations 29, test-workflow-verification 33,
test-helpers-selftest 3, test-helpers-selftest-negative XFAIL (0/4, exit 255).

The XFAIL is the negative control: a suite that is *expected* to fail,
scored green when it does. If the helpers ever stopped failing on a bad
assertion, that suite would flip to XPASS and turn the run red.

## 2. Manifest drift detection is real, not decorative — HOLDS

`dev/tools/build-manifest.py --check` is only worth having if it can
distinguish a current manifest from a stale one. Tested both directions:

    append a probe line to dev/tests/REFERENCE_PROVENANCE.md
      -> --check exit 1, "MANIFEST.txt is STALE"
    strip the probe line
      -> --check exit 0, "MANIFEST.txt is current"

MANIFEST.txt md5 returns to `11bd1f95e4adfe605efba2f364766568`, matching
the pre-probe backup byte for byte — the check is not merely detecting a
timestamp. `grep -c "| TODO:" MANIFEST.txt` returns 0, confirming the
`first_docstring_line()` fix (14 rows previously read
`TODO: !/usr/bin/env python3`) is still landed.

## 3. Registry reconciliation still clean — HOLDS

    python3 dev/tools/reg-reconcile.py EML_PROCEDURE_REGISTRY.md  ->  exit 0

    OK — 15 undocumented files, 163 procedures
    total documented rows: 283
    sections with defects: 0

Ground truth unchanged: 241 documented (228 public, 13 internal) across
13 files present in the tree, plus 163 undocumented across 15 files =
404 procedures across 27 procedure-bearing files.

## 4. Runner sentinel enforcement survives hostile suites — HOLDS

The TEST RESULT REPORTING CONTRACT binds the runner, not just the
suites: *"A runner MUST NOT treat 'exit 0' as sufficient evidence of a
green suite... Absence of the sentinel means the suite died before
reaching @emlTestSummary and must be treated as FAIL, not PASS."*

Both halves were attacked with a temporary suite,
`dev/tests/zz-adversarial-probe.praat` (since removed):

| Attack | Suite behaviour | Runner verdict |
|---|---|---|
| Silent green | exit 0, prints `ALL TESTS PASSED`, emits no sentinel | exit 1, scored `NO-SENTINEL` |
| Lying sentinel | emits `status=PASS passed=99`, then `exitScript:` | exit 1, scored `FAIL [contract_mismatch]: sentinel said PASS but process exited 255` |

A suite cannot buy a green by printing a reassuring string, and cannot
buy one by claiming a status its exit code contradicts.

## 5. Fix fingerprints re-verified against disk — HOLDS

    graphs/eml-draw-procedures.praat
      # Version: 1.20, 4016 lines, md5 d370f12c0ff65f8c7ffe8dd5dd426cc3
      procedure emlDrawLMMForest      3909
      guard variableExists emlShowTicksX  3944
      guard variableExists colorMode$     3947

    git status  ->  fatal: not a git repository

The tree is not under version control, which is why every removal in
this program was a retire-by-move (`dev/retired/`) and never a delete.

## 6. The order-dependence experiment re-derived from scratch — REPRODUCES BIT-FOR-BIT

The claim under test is that the v1.19 forest was order-dependent (its
output changed depending on what had been drawn before it) and that
v1.20 is not. Re-derived in a *fresh* directory `/home/claude/fv2` with
fresh pref dirs, nothing reused from the original harness:

    84f9c7573990a0d2cd76cdefdfcbcd47  old_a.png   62947 B   v1.19 cold
    ed1e8c56e85b7cc7b37aa1db6bdf6558  old_b.png   48017 B   v1.19 warm
    dd6db65a5bbbc041bf205c769ba9b547  run_a.png   58436 B   v1.20 cold
    dd6db65a5bbbc041bf205c769ba9b547  run_b.png   58436 B   v1.20 warm

All four arms exit 0; all four stderr files are 0 bytes. `run_a.txt`
logs `emlShowTicksX defined at entry: 0`, so the guard genuinely fires on
the cold arm rather than the state being pre-seeded. Both fixed runs
report `figW=6.5 figH=3.6`, `xlo=-0.820708 xhi=1.440308`.

Fixed arm: byte-identical cold vs warm. Pre-fix arm: differs by ~15 KB.
The second number is the load-bearing one — it proves the exposure was
real *and* that the test is sensitive enough to have detected it. A test
that showed no difference on the broken version would prove nothing
about the fixed one.

Note the counterfactual is honest about its own limits: `old_forest.praat`
is the v1.19 procedure renamed and loaded against the *current* v1.20
library, so the experiment isolates the forest change and does not
confound it with a library version difference.

## 7. Guard-stripped cold probe — CONFIRMS THE CONCLUSION, REFUTES THE STATED CAUSE

The handoff return document (§3) claimed that without its
`variableExists` guard the shipped forest aborts, citing a transcript
that named `emlShowTicksX` at `eml-graph-procedures.praat:1209`
(`@emlDrawAlignedMarksBottom`). That transcript was from an isolated
one-line snippet, not from the real path. Probe: extract the shipped
`@emlDrawLMMForest` verbatim, delete its two guard blocks (6 lines),
rename it, drive it cold — fresh Praat, fresh pref dir, three library
includes, synthetic LMM state, nothing else.

    exit=124  (modal dialog holds the process open; stderr empty)
    marker file:  "emlShowTicksX defined at entry: 0"
                  "about to call"          <- no "returned OK"
    stdout:       Unknown variable: « emlSubtitle$
                  Script line 411 not performed: « if emlSubtitle$ <> "" »

The conclusion stands — without the guard the shipped path aborts — but
it dies roughly 800 lines earlier than stated, on a different variable,
in the theme prologue. `@emlDrawAlignedMarksBottom` is never reached.

Follow-on static analysis of `@emlSetAdaptiveTheme`:

| Global | Read at | Guarded? |
|---|---|---|
| `emlPanelOriginX` | :366 | yes — `variableExists` |
| `emlPanelOriginY` | :369 | yes — `variableExists` |
| `emlSubtitle$` | :411 | **no** |
| `emlFont$` | :460, :461 | **no** |

All four are seeded by `@emlInitDrawingDefaults`, and **callers are
expected to initialize — that is the library's design, not a defect.**
(Ruling from the library author, 4 August 2026, recorded after this probe
ran: "Many procedures call other procedures… It's designed this way.")
The count — **53 call sites across five files** against **one** tree-wide
call to `@emlInitDrawingDefaults` (`scripts/eml-stats-demo.praat:54`) — is
therefore a map of that contract's reach, not an exposure metric. An
earlier draft of this section recommended extending the guards and called
the partial guard "worse than none"; both are retracted.

What survives is smaller and is about **documentation**:
`@emlSetAdaptiveTheme`'s header declares `Arguments:` and a 30-item
`Outputs:` list and no `Requires:` line, while `eml-draw-procedures.praat`
declares the same dependency 14 times (`# Requires: @emlInitDrawingDefaults
(or manual global initialization).`). On that reasoning the two existing
guards at `:366`/`:369` are the anomaly rather than the missing pair — a
caller reading the body could infer a self-sufficiency the design does not
intend.

The shipped plugin is unaffected either way — `@emlDrawLMMForest`'s guard
calls `@emlInitDrawingDefaults`, which seeds all four, and the cold arm
runs clean with a byte-identical PNG (probe 6).

Recorded as PRAATGEN_RETURN §3A plus a new §6 owner row. §3's original
evidence was relabelled "isolated snippet" rather than rewritten, so the
record of what was actually verified when is preserved.

---

## What the check did not clear — since closed

This section is kept rather than deleted: it records what was still open
at the moment the adversarial check was written, and what closing it
took. Both items below have since been resolved on disk.

**`scan-assertion-vacuity.py` had an unresolved-tolerance blind spot —
CLOSED 4 August 2026.**
As written, the check reported Class A = 0 and Class B = 0 while a set of
sites was reported only as `(tol unresolved: ...)`, resolved by hand from
`dev/tests/phase2/test-theilsen.praat:64-66` (`tsTol = 5e-11`,
`tsTolZero = 1e-12`, `tsExact = 0`) and argued harmless because the
smallest nonzero expected value in that set is `0.1`, about 2x10^9 times
the largest of those tolerances.

Two corrections to that paragraph as originally written. First, the
counts were wrong: the true pre-fix figures were **28 tol-unresolved and
20 runtime-valued-expected — 48 unevaluable sites in total**, not "27
plus one." Second, "currently harmless" was a hand-verification result,
not a tool result, and the tool's red path had indeed never executed.

Both holes are now fixed in the scanner:

- Tolerance harvest no longer filters on `"toler" in name`. Every
  top-level `name = <numeric literal>` assignment is harvested, so
  `tsTol` / `tsExact` / `tsTolZero` resolve. A name assigned twice with
  *different* literals is marked unresolvable rather than silently
  rebound to the last one.
- An unresolved tolerance now counts toward the failure total
  (`bad = subtol + unmatched + relmisuse + badtol`). Previously the
  scanner could report a blind spot and still exit 0 — the blind spot
  could not fail the run that revealed it.

Post-fix run against the shipped tree: **exit 0, VERDICT CLEAN, parsed
649/649, UNRESOLVED TOLERANCE 0.** The 28 theilsen sites resolve to 4
CLASS C (legitimate zero-target), 1 CLASS F, and a remainder separated
from their tolerances by roughly 2x10^9. 21 sites remain CLASS F —
symmetry and passthrough assertions where *both* sides are computed at
run time, so `|expected|/tol` cannot be formed statically. These are
reported with their tolerances for hand review, not failed.

The red path is now exercised by `dev/tools/vacuity-negative-controls.py`
(238 lines), which copies the phase2 tree to scratch, injects one defect
per class, and requires the scanner to catch each: **7 / 7 as expected,
shipped tree proved unchanged by md5 over 15 files.** NC-1a / NC-1b are
the load-bearing pair — tolerance 2.5 vs 2.4 against expected 2.5, four
percent apart, flipping the verdict across the vacuity boundary. A single
tripped control would only show the tool reacts to edits; the pair shows
it tracks the ratio it claims to measure.

**Queue item 1 — CLOSED as out of scope.** It was recorded here as
"blocked on project-knowledge capacity, not on correctness." It is a
PraatGen-side item, and the author has since ruled that this work serves
the plugin only. It is not blocked; it is not this session's.

---

## Verdict

Every claim re-tested reproduced. One claim — the *named cause* in
PRAATGEN_RETURN §3 — was wrong and is corrected; its conclusion survives
and the underlying problem turned out to be broader than originally
described. The three mechanisms that exist to catch future regressions
(sentinel enforcement, manifest drift, registry reconciliation) were each
made to go red on demand and then back to green, so none of them is
decorative.
