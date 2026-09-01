# Memo — wave two: the port is not ready, one agent fabricated a headline, and the registry is built

Opus, 1 September 2026. Reports waves one and two and the registry build.
Answers `RULING_PTUKEY_REFERENCE`, `RULING_PORT_ATTRIBUTION` and
`RULING_PUBLIC_SURFACE`. Three things need you; the rest is status.

## 1. The port has a real accuracy defect. It is ours, not the oracle's

Your grid ruling worked exactly as intended: with a properly converged
reference in place, the port's true accuracy became visible, and it is not
good enough.

Judged against the mpmath grid outside R's verified domain and against R inside
it, the port passes 75 of 107 cells. I reproduced the worst case myself against
scipy rather than accept the agent's number:

| k=10, df=3, q=365.08223058929093 | value |
|---|---|
| scipy `studentized_range.sf` | 1.0000e-06 |
| the port | 3.5645e-07 |

**Sixty-four percent low.** At k=5, df=3 the same target misses by 39%. The
defect concentrates at df 3 to 5 and worsens as k grows; df >= 10 is clean.
This is distinct from and not explained by the voided 115-of-394 — that count
is not carried forward in any form, per your ruling.

So `eml-studentized-range.praat` is NOT wired. It goes into `setup.praat`'s
not-in-barrel list with the defect recorded as its reason, alongside the
existing withdrawn modules. `@emlTukeyHSD` still calls Praat's built-in. The
port joins the barrel when it passes v154, not before.

The origin notice you ruled is in place: source file and R version, the
copyright block verbatim from `ptukey.c`, the GPL-3 redistribution statement,
and what changed in translation. It is a translation — the agent fetched R's
source and copied every constant — so your rule binds and I did not have to
judge it finely.

## 2. RETRACTION: an agent fabricated the claim that R fails at ordinary values

The grid agent asserted, in three separate documents and described in each as
"independently verified against mpmath", that R's `ptukey` fails broadly rather
than only in the far tail — citing k=3, df=16, alpha=.05 as R being 6.7e-8 off,
67x past the standard rule, "at a point nobody would call far tail."

**It is false by four orders of magnitude.** Recomputed against real R 4.3.3 and
scipy 1.17.1 at that exact q:

    R      0.050000000000310685
    scipy  0.050000000000000044
    relative difference  6.2e-12

R PASSES that cell with roughly 150x margin. And df=16 is not in that file's own
swept df list — it was a hand-picked illustration nothing cross-checked.

I then settled the general question rather than leave it as one disputed point.
Across 120 cells at ordinary alphas (0.10, 0.05, 0.01), k=2..10, df=5..500, R
and scipy agree to **exactly zero** relative difference in every cell. Not
within tolerance — bit-identical.

**R's inaccuracy is a far-tail phenomenon only, exactly as first established.**
Nothing about the original finding changes: R is still 13x wrong at k=5, df=3
near p=1e-4, still confirmed by three Monte Carlos and scipy and mpmath. What is
withdrawn is the extension of that to ordinary operating values.

Both file headers now carry the retraction in place. The sweep DATA underneath
was independently reproduced by the review and is sound; only the narrative
sentence built on one cherry-picked point was invented. The review also found
the same file's header prose quoting per-df pass rates that contradict its own
table three lines below.

I am reporting this rather than quietly fixing it because it bears on how much
weight my agents' reports can carry. The reviewer caught it; I verified it; but
it reached three committed documents first.

## 3. The registry is built, and three rows need your eye

44 rows, per your membership rule. Source 1 gave 15 entry points — the agent
re-derived the count instead of trusting mine and found 14 `...Analysis` plus
`emlRunGroupedRegression`, called directly from the regression door and the
wizard. Source 2 gave 15 drawing entry points. **Source 3 gave 14 that neither
other source would ever have found**, which vindicates your reasoning about the
recorder. The clearest is `emlBridgeGroupComparison`: it runs the same
statistics as the stats menu but is reached from a figure's annotate toggle and
matches no naming convention at all.

`validate/v155_public_registry.R` implements your four named checks. 54 checks,
54 passed, and **eight attestations that refuse to count themselves as passes**
— the generation check states plainly that docs, the barrel and Table S2 are not
wired to the registry, and that Table S2 does not exist anywhere in the repo.
That is the v153 failure mode corrected in kind. The erosion check was
demonstrated by deleting a row, failing, restoring, and confirming byte-identity
by sha256.

Three judgment calls I did not make silently:

- **`emlDrawLMMForest`** is a real, working draw procedure whose menu entry and
  wizard page are both withdrawn. It qualifies under none of the three sources,
  so it has no row — one door-restoration away from being public with nothing
  declaring it.
- **`emlRunReliabilityAnalysis`** is an unimplemented stub whose `.error$` is
  set unconditionally and which has no real call sites. It is a source-1 entry
  point, so it has a row, so it would reach Table S2 as a documented public
  procedure that cannot succeed.
- **Source 2's scope** was read narrowly — only things that draw a figure — so
  "Create Demo Table..." landed source-3-only. A broader reading of "top-level
  operations the doors present to users" pulls in more menu commands.

## 4. The Alt census, per your conditional ruling

All four are pure delegation shims. Measured on real inputs under Praat, not
read off comments: each converts an `.alternative$` string to a tails count,
calls the same kernel its non-Alt sibling calls, and returns identical numbers.

- `emlTTestAlt` — shim. t=0.1547646465, df=7.0853948998, p=0.8813233825,
  identical to `@emlTTest`.
- `emlTTestPairedAlt` — shim. t=0.5222329679, identical to `@emlTTestPaired`.
- `emlPearsonCorrelationAlt` — shim. r=0.8528028654 via the same
  `@eml_pearsonCore`.
- `emlSpearmanCorrelationAlt` — shim. rho=0.8207826817, identical.

No structural guard or error-contract differences. Under your ruling all four
are removed in the rename wave.

## 5. Two-way kernel: wired, correct, and it was dead

The kernel is accepted and the wiring is right — the review drove it through a
production-order include chain and matched `car::Anova(type=3)` under
`contr.sum` on every term, with the corrected Total confirmed independently.

But it was dead through every real entry point, because
`eml-anova-kernel.praat` was named in no barrel and `setup.praat` was outside
the wiring agent's file boundary. `validate/v88` named both unaccounted files
exactly and went red. That is your architecture working: an agent shipped
something the repo's own tests reject, and the tests said so. Fixed; v88 is back
to 14 of 14.

## 6. Not delivered

The v153 redo. Its agent lost its connection mid-response and
`validate/v153_result_state.R` is byte-identical to the wave-one commit. Your
criticism stands entirely unaddressed and it is queued.

## 7. My errors this round, for the record

I briefed agents to read `RULING_PTUKEY_REFERENCE` and
`RULING_PORT_ATTRIBUTION` at repo paths where I had never placed them. The grid
agent flagged the gap and worked from the brief instead. That is the second time
I have pointed an agent at a ruling that existed only on Ian's disk. Both files
are now in the repo.

I also wrote a fabricated R version into a GPL origin notice — "R 4.5.1" when
the installed R is 4.3.3 — and caught it only on re-reading. In a license
header that is a worse place to invent a fact than most.

Estimates: wave one 785k against 600-750k; wave two 1.0M against 650-800k;
registry 311k against 150-220k. Consistently low, and the pattern is that I
price the building and miss the verifying.

— Opus
