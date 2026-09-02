# Memo — Ian struck the compatibility wrappers, and wave one is building

Opus, 1 September 2026. Two operational notes on
`RULING_CONSOLIDATED_KERNELS_2026-09-01`. Neither changes what you ruled to
build; the first removes a piece of it on Ian's instruction.

## The wrappers are struck

Ian's ruling, verbatim in substance: we are not at version one yet, there are no
users, and no backwards compatibility is required.

I checked rather than took it on trust. There are no git tags, `CITATION.cff`'s
version line is commented out, and the README describes the release as
upcoming. The plugin has never shipped.

So settlement item 2 — "canonical word-based procedure names with compatibility
wrappers for every old name (`@emlTTestAlt` pattern)" — becomes a straight
rename with no wrappers. Compatibility wrappers protect existing callers, and
there are none. The only callers are Ian's own scripts and the kit, and both are
updated in the same pass.

What this removes, concretely: fifteen `emlRun*` public entry points plus the
rest of the surface would each have needed a wrapper, an equivalence probe
apiece under the "one probe per wrapper" rule, and a row in Table S2 documenting
a name that never existed anywhere. That is real build and real validation
surface added to preserve compatibility with a version that never shipped.

Two consequential edits follow:

- **Item 2**: rename only. No `Alt`-pattern wrappers, no wrapper equivalence
  checks, and Table S2 documents the canonical names alone.
- **Item 5**: the registry becomes the single source of one name per procedure
  rather than a canonical name plus an alias. The docs, the recorder and the
  `eml-lib-user.praat` barrel all regenerate from that simpler surface.

Four `Alt` procedures already exist in the tree — `emlTTestAlt`,
`emlTTestPairedAlt`, `emlPearsonCorrelationAlt`, `emlSpearmanCorrelationAlt`.
They predate this decision and I have not touched them. Whether they are kept as
genuine alternate procedures or removed as vestigial compatibility shims is a
question for you, and it is a different question from the one Ian settled.

## Wave one is building

Four agents in parallel, disjoint files by construction, one review pass to
follow. Estimate stated before launch: 600 to 750k. I will report the actual
against it.

- **ptukey port**, new file, sonnet. Both directions, ported from the published
  algorithm behind `stats::ptukey`, validated against R across the far tail.
- **two-way kernel**, new file, sonnet. Types I, II and III, default III, Type
  III on `solve#` rather than an explicit inverse. Also creates the unbalanced
  three-level fixture your §2 requires.
- **one-extraction-per-case**, sonnet, in `eml-analysis`, `eml-inferential` and
  `eml-extract`. Required to change no computed value and to demonstrate that
  rather than assert it.
- **result state and the LMM stale export**, haiku, in `eml-result-writer` and
  `eml-lmm`.

The two numerical builds write NEW files and are explicitly forbidden from
wiring themselves in, which is what makes the parallelism safe — the extraction
agent has `eml-inferential.praat` to itself, and it needs it, since
`@eml_getGroupData` is called from there 43 times.

Deliberately out of scope this wave, and flagged so you know it is deferred
rather than dropped: estimated marginal means, post hoc on marginal means, and
simple effects. They are in your 1.0 output set and they are wave two. The
renames and the uniform outcome contract are also wave two, because they touch
every file and cannot run beside anything.

— Opus
