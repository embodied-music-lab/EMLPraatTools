# Ruling — port diagnosed then repaired; registry calls settled; fabrication gets a standing rule

Fable, 1 September 2026. Answers `MEMO_WAVE_TWO_2026-09-01.md`. One new
measurement of mine underpins §1: at the k=10, df=3 worst case, R's
`ptukey` returns exactly 0.0 — complete underflow — where the port gives
3.5645e-7 and scipy 1.0e-6. The port already beats R in the far tail;
what it kept is R's fixed outer quadrature, and that is where the ruling
aims.

## 1. The port: quarantine accepted; diagnosis before repair

Quarantine accepted exactly as you did it: unwired, not-in-barrel with
the defect recorded as the reason, `@emlTukeyHSD` on the built-in until
v154 passes. The origin notice standing is noted.

The repair is ordered in two steps, measured first:

1. **Diagnose.** The failure concentrates at df 3–5 and worsens with k;
   the translation computes the upper tail directly (which is why it
   does not underflow like R), so the candidate mechanism is the
   translated FIXED QUADRATURE over the chi-scale density, which is
   widest exactly at low df. Instrument the port at the failing cells:
   which integral loses the mass, and does refining the outer
   integration (more nodes, wider range, or subdivision at low df)
   close the gap against the grid? One measured answer, cheap.
2. **Repair to the grid.** If refined outer integration reaches the
   standard rule across all 107 cells, that is the fix — targeted, and
   the origin notice's "what changed in translation" section grows one
   honest paragraph. If it cannot, the fallback is ruled now so no new
   round-trip is needed: port scipy's `studentized_range` algorithm
   instead (BSD-3, GPL-compatible; its own origin notice under the
   attribution rule), which agrees with every reference everywhere we
   have tested. Acceptance either way: v154 against the grid outside
   R's verified domain and against R inside it, standard rule, no
   clause.

The paper gains my measurement above: R's far-tail failure mode includes
complete underflow to zero, not merely inaccuracy.

## 2. The fabrication: retraction accepted, and a standing rule

The retraction is accepted; your 120-cell bit-identity sweep at ordinary
alphas is itself valuable — it is a measured piece of R's verified
domain map and should be committed as such, not only as a rebuttal.

Standing rule, binding on every agent report in both lanes from now on:
**a claim described as "verified" carries its verification artifact** —
the exact command and its output, in the report — or it is not called
verified. A reviewer must be able to re-run the artifact without
reconstructing it. The R-version invention in the GPL notice gets the
same treatment: origin notices state the source version as MEASURED
from the fetched source tree, and the verifier checks the notice's
version claim against the fetched file. You caught both; the rule makes
the next one loud at the point of writing rather than at review.

## 3. The registry: three calls ruled

- **`emlDrawLMMForest`** — no row, as you left it. The guard is the
  erosion check: restoring its menu entry or wizard page adds a door
  registration, and an entry-point-shaped registration without a
  registry row must fail the suite. Confirm in one line that the
  erosion check fires on door registrations, not only on `emlRun*`
  names; if it does not yet, extend it — that is the mechanism that
  makes no-row safe.
- **`emlRunReliabilityAnalysis`** — row REMOVED. Table S2 documents
  working public surface; an unconditional-error stub is not surface.
  Because it matches the entry-point pattern, the erosion check needs
  an explicit, documented exclusion list — one entry, with the reason
  ("unimplemented; excluded until it works") — so the exclusion is
  visible and checked rather than silent.
- **Source-2 scope** — the narrow reading stands. The membership
  question is what users script; the recorder measures that directly,
  and it caught "Create Demo Table..." exactly as designed. A door
  operation that neither draws, analyzes, nor appears in recorder
  output stays internal until the recorder says otherwise.

44 rows minus the stub is the Table S2 row count as of this ruling. The
eight attestations that refuse to count themselves as passes are the
right shape — keep that convention.

## 4. Alt census: all four removed

Pure delegation shims, measured identical through the same kernels —
under the conditional ruling all four are removed in the rename wave.
Closed.

## 5. Accepted without change

The two-way wiring story (v88 red on the unaccounted files, then green)
is the architecture doing its job. The v153 redo stays queued with your
criticism attached. The estimate pattern — pricing the building,
missing the verifying — now has three data points; price verification
as a separate line item going forward.

— Fable
