# Memo to Fable — where the item 22 disclosure is printed

27 August 2026. Answers to your five questions, measured against the tree
at `2cd1e55`. Line numbers are current as of that commit.

## 1. The claim, verbatim

I searched this session's transcript for any statement of mine about the
reporting mechanism being plugin, harness, or a combination. There is
none. I am not going to supply a quote that does not exist.

What I did say about item 22's plumbing, in full, is one sentence:

> **Next is the plumbing** — building the row dark in all three
> procedures, wired but printing nothing until you approve the strings.
> That touches `eml-inferential.praat`, `eml-output.praat` and the
> reporters, and it's a Sonnet job. Say go and I'll launch one agent.

Every file named there ships in `plugin_EML_StatsGraphs/`. The assumption
behind it was plugin-only. It was also wrong in a different way, and
question 4 corrects it: two of the three named files need no change at all.

The other sentence touching the mechanism:

> The row follows the house shape rather than a new one — two-space
> indent, label padded to 20, value, same as every other labelled row in
> `eml-output.praat`

That one holds, and question 4 sharpens it.

## 2. The print path for the Spearman p line

Printed by:

    plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat:6448
    @emlReportPWithExact: "p", emlSpearmanCorrelation.p

inside `procedure emlReportCorrelationAnalysis` (line 6302), which builds
the whole correlation report with `@emlReportHeader`, `@emlReportSection`,
`@emlReportLine`, `@emlReportLineString`, and `@emlReportPWithExact`.

Those helpers are defined in `plugin_EML_StatsGraphs/stats/eml-output.praat`
at lines 776, 807, and 932.

**Both files ship in `plugin_EML_StatsGraphs/`.** Nothing under
`walkthrough/` prints any part of the report.

The other two procedures print their p in the same file:

| Procedure | Site |
|---|---|
| Mann-Whitney | `eml-annotation-procedures.praat:5244` |
| Spearman | `eml-annotation-procedures.praat:6448` |
| Wilcoxon signed-rank | `eml-annotation-procedures.praat:7130` |

## 3. The two sections in a kit report file

Both are written by `procedure emlKitEndCell` in
`walkthrough/kit/RUN_ME_FIRST.praat` (line 405), but they carry different
authorship:

**`--- library report (as printed to the Info window) ---`** (line 430).
The content is `info$ ()` — Praat's Info window buffer, verbatim. Every
character in it was written by the plugin's own shipped report code. The
harness contributes the header line and nothing else.

**`--- quantities extracted (raw, unrounded) ---`** (line 433). The
content is `emlKitQtyLog$`, built by the harness. Kit code reads the
plugin's qualified globals and logs them itself. This block is
harness-authored.

The consequence for your decision rule: a row printed by the plugin's
report code appears in the first block automatically, with no harness
change, because that block is a verbatim capture. The harness only needs
touching if the method is also to be compared as a quantity.

## 4. The file list, corrected

My earlier list was too long. Measured:

| File | Tree | Change |
|---|---|---|
| `plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat` | plugin | Three inserted rows, after lines 5244, 6448, 7130 |
| `plugin_EML_StatsGraphs/stats/eml-output.praat` | plugin | **None.** `@emlReportLineString: .label$, .value$` at line 807 is already the two-column string row your ruling describes |
| `plugin_EML_StatsGraphs/stats/eml-inferential.praat` | plugin | **None.** All three tags already exist, and Spearman's `.methodReason$` already exists |
| `validate/` new check | harness | Asserts the row prints, and that it prints the branch that ran |
| `walkthrough/kit/RUN_ME_FIRST.praat` | harness | Only if the method becomes an extracted quantity |
| `walkthrough/kit/quantities.tsv` | harness | Only if the method becomes a compared quantity |

Nothing user-facing lands outside `plugin_EML_StatsGraphs/`. The
disclosure is three calls to a helper that already ships.

## 5. The limitation, as a checkable sentence

I referenced no limitation on the reporting mechanism, and on inspection
there is none to reference: the plugin already owns every piece needed.

The one real limitation in this session is unrelated to item 22:

> This container cannot push to GitHub, because it holds no credentials
> for the remote, so every commit reaches `origin` only as a bundle Ian
> applies and pushes himself.

Checkable by attempting a push from here.

## One thing your questions turned up

`@emlBridgeCorrelation` (`eml-annotation-procedures.praat:4567`) calls
`@emlSpearmanCorrelation` raw at line 4596, bypassing the dispatch, so it
would publish the asymptotic p. It has no callers anywhere in
`plugin_EML_StatsGraphs/` or `walkthrough/` — verified, not relayed — so
it is dead code rather than an unwired door. `v147`'s door census checks
`eml-draw-procedures.praat` and does not look at this file, so if that
procedure is ever revived it will be revived unwired and nothing will
say so.
