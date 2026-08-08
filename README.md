# EMLPraatTools

## Eml Praat Tools is coming soon

EML Praat Tools aims to solve multiple challenges for voice researches using the Praat environment for analysis, statistics, and graphing.

Features include robust descriptive and inferential statistics, professional quality graphs with auto-scaling typography and accessible color palettes, direct table editing (a workaround, but faster than writing code or clicking in the GUI), a statistics wizard that surfaces the right test and the right time, a statistics demo window 'mini course,' and direct drawing and statistics access. Additionally, EML analysis tools (EGG, RespTrack RIP, Vibrato, and Acoustic measures) will find their home here. 

My goal is to reorient Praat's GUI phisolophy. Rather than tie commands directly to object type, instead I lay out workflows and manage objects in a hidden layer. This is a time saving plugin that produces professional results. 

Check back, it is very close to a release and I'll upload the modules as they pass my tests. 

Ian Howell — Embodied Music Lab — www.embodiedmusiclab.com — GPL-3.0-or-later.
Plugin code generated with the EML PraatGen framework; audit driven by Claude
(Anthropic) in a Linux sandbox.

---

## Checking the statistics yourself

The statistics layer can be verified with **R and nothing else** — no Praat,
no packages, no network:

```bash
Rscript validate/run_all.R
```

Expect `4104 checks, 4104 passed, 0 FAILED`. Each check pairs a number the
plugin *printed* (read out of a committed Info-window capture in
`evidence/info/`) with a number R computes from the same committed input in
`evidence/csv/`.

**[`validate/README.md`](validate/README.md)** is the one-page starting point,
and it walks a single number from input file to printed output to R's answer
so you can confirm the method by hand in two minutes.
[`validate/REGISTRY.md`](validate/REGISTRY.md) is the full reference.

---

# Development

From here down this file is the working record, not the front door. This
repository is the source of truth for the plugin and for the GUI-driven audit
being run against it.

## Layout

```
plugin/        the plugin itself — this is the working tree, and the thing
               that gets packaged for release
audit/         the audit record
  DRIVE_FINDINGS_2026-08-04.md   primary log: every wrapper driven through its
                                 real GUI, screenshot by screenshot
  FINDINGS_INDEX.md              machine-readable table of D1–D81
  static/      earlier static (read-the-source) audits, pre-GUI
  reports/     derived reports: actionable list, adversarial re-check,
               R/scipy cross-validation, degenerate-input stress, handoffs
harness/       the GUI driving rig
  gui.sh                         bash helpers (shot, emlmenu, sendp, picsave …)
  GUI_HARNESS_RECIPE.md          how to stand the rig up, and every trap hit
  MENU_MAP.md                    menu geometry: item y-coordinates, button grid
  probes/      one-off .praat probes written during the drive
evidence/      raw artefacts produced by the drive
  shots/       109 screenshots
  figures/     104 exported Picture-window PNGs
  csv/         14 CSV exports taken from the wrappers under test
  info/        15 Info-window transcripts captured via info$() → file
```

## History

The plugin's git history is layered so the fix work is a browsable diff:

1. scaffolding
2. `plugin/` at the 2026-07-22 state (pre-audit original, 69 files)
3. `plugin/` at the 2026-08-02 state (post-S9 fixes, 74 files)
4. `plugin/` at the 2026-08-04 state (current, 103 files — adds the test and
   tooling tree under `dev/`, `FIX_NOTES.md`, `MANIFEST.txt`)
5. the audit, harness, and evidence trees

From here forward, `plugin/` is edited in place and each fix is its own commit,
referencing the finding ID it closes.

## Audit status

Eleven of sixteen in-scope menu wrappers have been driven end to end through
the real GUI under Xvfb. `Linear mixed model` is out of scope by author ruling.
Still to drive: EML Graphs, Batch voice analysis, Run Stats Demo, EML Stats
Quick Start, Stats Wizard.

`START_HERE.md` is the entry point for whoever picks the drive up next: it
names the remaining targets in priority order and points at the rig rebuild.

Findings are judged in the order the author asked for: **accuracy** first
(is the reported number the right number, from the right test), then **clarity
of Info-window output**, then **the graphing paths that result**. Every
statistic called correct or incorrect was checked against Python/scipy ground
truth rather than by inspection.

The highest-severity open items are D77 and D78 (`@emlGuessColumnRoles`
mis-assigns column roles, so the Compare Paired dialog can silently default to
comparing two *different measures* rather than two timepoints of one measure),
D15, D20, D32, D33, D63, and D66. See `audit/FINDINGS_INDEX.md`.

D66's blast radius was **corrected on 5 August** after live drive: *Compare
paired/repeated* exports its CSV correctly and is cleared. The three genuinely
affected orchestrators are `emlRunPairwiseAnalysis`,
`emlRunRepeatedMeasuresAnalysis`, and `emlRunFriedmanAnalysis` — reachable only
from the *Pairwise comparisons* wrapper and two Stats Wizard branches. Those
three are the next drive targets.

## Known gap: file modes are not carried by git

Finding **P1** records that 13 of the 21 files in `plugin/scripts/` are mode
`0600` in the built tree, which makes the plugin unreadable for any user other
than the installing account. Git records only the executable bit, so that
defect **cannot** be represented in this repository and will not appear in a
`git diff`. It has to be fixed in the packaging step (`chmod 0644` across the
tree before zipping) and verified on the built artefact, not here.

## Reproducing the drive

The harness runs Praat 6.6.30 under Xvfb `:99` (1400x1000x24) with
matchbox-window-manager, driven by `xdotool`, captured with ImageMagick.
`harness/GUI_HARNESS_RECIPE.md` has the full standing-up procedure. Two
constraints dominate the design:

- `beginPause:` crashes under `praat --run` (SIGTRAP, exit 133), and every EML
  wrapper uses `beginPause:`. So `runScript:` with positional arguments cannot
  drive these dialogs — real clicking is the only route.
- Reading Info-window text off a screenshot costs ~1,900 tokens and invites
  transcription error. `info$ ()` piped to a file with `writeFileLine:` costs
  ~30–120 tokens and is exact. Every transcript in `evidence/info/` was
  captured that way.
