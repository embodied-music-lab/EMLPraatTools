# Contradiction sweep — 7 August 2026

Tree at `236b915`, read-only. Target class: **a rule stated in one place and
broken nearby** — a comment whose code does the opposite, a closure record for
a defect that is still open, a changelog describing behaviour the procedure no
longer has, a guard propagated by hand that stopped short, a doc instructing
what another doc forbids, a stale line reference.

Everything below is either demonstrated by a command whose output is quoted, or
is a two-file citation you can check with `grep`. Nothing here duplicates the
KNOWN list.

Ranked by consequence: shipped-behaviour defects first, then doc hazards that
would cause a maintainer to break working code, then stale references.

---

## Reading note — citations in this document (rewritten 8 August 2026)

**This document was itself full of the defect it documents.** It was written as
a record against `236b915` and cited nearly everything by bare line number; the
tree has moved under it every day since, and several of its numbers were wrong
on the day they were written. Sweeping it found: a heading counting four rows
over a five-row table; `emlmenu` cited 25 lines off; the `curpause` comment
cited 65 lines off; the C5 row for Theil-Sen offering *replacement* targets that
were themselves stale; a "found clean" note giving two counts that were both
one too high; and C10's own three numbers already 33 lines adrift before anyone
edited the file.

Every citation is therefore now **anchor-first**: a quoted line of code, a
`procedure` name or a document heading, with the `grep` that finds it. Where a
current line number appears at all it is marked *verified 8 Aug* and is a
convenience, not the citation — if it disagrees with the anchor, the anchor
wins.

**C1 through C10 have all since been resolved.** Where the text this sweep
quotes no longer exists in the tree, the quote is kept as the historical record
(that is what a sweep is for) and the anchor points at the surviving artefact —
usually the fix's own note. Those are marked **[CLOSED]** with the anchor that
resolves today.

---

## C1 — [CLOSED, D131 / v31]. The gridline-mode clamp reached three of seven categorical graph types

> **Closed 8 Aug 2026.** Anchors that resolve today:
> `grep -n 'gridModeStyle\[' plugin/graphs/eml-graphs-form.praat` — the registry
> flag this section proposes now exists, one entry per graph type, with two
> include-time validation loops behind it; and
> `grep -n 'procedure emlGridModeToMenu\|procedure emlGridModeFromMenu\|procedure emlSeedGridMode'`
> on the same file — the single canonical encoding, translated at the dialog.
> `grep -n 'if config_gridlineMode = 2' plugin/graphs/eml-graphs-form.praat`
> now returns **nothing**: the three per-type clamps below are gone. The
> quotations in this section are the pre-fix text and no longer resolve.

**The rule.** `plugin/graphs/eml-graphs-form.praat`, in the shared-tmp block
(anchor: the comment "Shared tmp variables"; the assignment quoted was
`tmpGridMode = config_gridlineMode`):

```
    # Shared tmp variables — initialized from config before graph type
    # branching. Ensures valid defaults exist on first pass regardless
    # of which graph type is selected. Per-type sections may override
    # graph-specific tmp vars but inherit these shared ones.
    tmpGridMode = config_gridlineMode
```

**Why the rule is false.** `.gridMode` has *two* incompatible encodings in this
plugin, and both are documented as such in the draw layer:

Anchors, both in `plugin/graphs/eml-draw-procedures.praat` — the two comment
strings are still there today, one per consuming procedure:

| encoding | anchor | used by |
|---|---|---|
| `1=Both, 2=Horizontal only, 3=Vertical only, 4=Off` | `grep -n '# gridMode: 1=Both' plugin/graphs/eml-draw-procedures.praat` | F0, waveform, spectrum, LTAS, time series, time series CI, scatter |
| `1=Horizontal, 2=Off` | `grep -n '# gridMode: 1=Horizontal' plugin/graphs/eml-draw-procedures.praat` | spaghetti, bar, violin, box, histogram, grouped violin, grouped box |

`config_gridlineMode` is a **single** persisted key — anchor
`grep -n 'config_gridlineMode' plugin/graphs/eml-graphs-form.praat`, whose
default assignment, config parse and `appendFileLine: .configPath$,
"gridlineMode: "` write are the three sites the sentence means — and at the
time of the sweep it was committed from *both* encodings, at every one of the
thirteen `config_gridlineMode = gridline_mode` sites.

**The half-fix.** Three of the seven 2-option types clamped the shared seed
before their dialog — bar, violin and box, found then by
`grep -n "config_gridlineMode = 2" plugin/graphs/eml-graphs-form.praat` (three
hits; **zero today**), each identically:

```
        if config_gridlineMode = 2
            tmpGridMode = 2
        else
            tmpGridMode = 1
        endif
```

The other four did not — histogram (10), grouped violin (11), grouped box (12)
and spaghetti (13). Their `if lastDrawnGraphType = N` init blocks were otherwise
the same shape and contained no clamp. Anchor for the four types and their
option counts, today: the `gridModeStyle[10..13] = 2` lines in the GRAPH TYPE
REGISTRY of `eml-graphs-form.praat`, which is where that fact now lives as data
rather than as four hand-copied blocks.

**Demonstrated consequence.** An `optionmenu` whose default index exceeds its
option count renders **blank**, and Praat then refuses to accept the form.
Probe (Praat 6.6.30, Xvfb + matchbox, `--new-send`):

```praat
beginPause: "OUT OF RANGE default=4 on a 2-option menu"
    optionmenu: "Gridline mode", 4
        option: "Horizontal"
        option: "Off"
clicked = endPause: "OK", 1
```

The combo box drew empty (screenshot captured), and clicking OK produced:

```
No option chosen for “Gridline mode”.
Please correct command window “Pause: OUT OF RANGE default=4 on a 2-option menu” or cancel.
(END OF PRAAT ERROR MESSAGE)
```

**User path to it.** Draw any of the seven 4-option types in Advanced mode and
pick "Vertical only" (3) or "Off" (4). `config_gridlineMode` becomes 3 or 4 and
is written to the config file. Now open Histogram / Grouped Violin / Grouped
Box / Spaghetti in Advanced mode: the shared `tmpGridMode = config_gridlineMode`
seed puts 3 or 4 into a two-option menu, the control is blank, and **OK will not
proceed**. The dialog is a dead end until the user notices an unlabelled
dropdown and opens it. It survives a Praat restart, because the bad value is on
disk.

**Second defect in the same three lines.** Even where the clamp exists it
preserves the *index*, not the *meaning*. Continuous `2` = "Horizontal only"
maps to categorical `2` = "Off"; continuous `4` = "Off" maps to categorical `1`
= "Horizontal". Both are inverted. A user who turns gridlines off on a scatter
plot gets them on for the next bar chart, and vice versa.

**Resolution.** One conversion, applied at the shared seed rather than per
type — the point of the "Shared tmp variables" block is that per-type sections
should not have to know. Give the type registry a `gridModeStyle[]` flag (`4` or
`2`) beside `hasGridlines[]` (anchor:
`grep -n 'hasGridlines\[' plugin/graphs/eml-graphs-form.praat`), and at the
shared seed map:

```
if gridModeStyle[graph_type] = 2
    # 1=Both / 2=Horizontal only -> Horizontal ; 3=Vertical only / 4=Off -> Off
    if config_gridlineMode <= 2
        tmpGridMode = 1
    else
        tmpGridMode = 2
    endif
else
    tmpGridMode = config_gridlineMode
endif
```

and delete the three per-type clamps. Committing back (`config_gridlineMode =
gridline_mode`) needs the inverse map on the 2-option types, or the config key
must be split in two — otherwise the shared key still carries a categorical `2`
that a scatter plot will read as "Horizontal only".

---

## C2 — [CLOSED]. §9.4 of the GUI recipe stated the opposite of §1, §3 and §10 of the same document, and the false half had been copied into `gui.sh`

> **Closed 7 Aug 2026.** Anchors that resolve today:
> `grep -n 'WITHDRAWN, C2' harness/GUI_HARNESS_RECIPE.md` — §9.4 is now headed
> *"Raise the Objects window before clicking its menubar"* and carries the
> withdrawal; and `grep -n 'C2\.' harness/gui.sh`, in the comment block above
> `curpause`, which records that the "fails outright under matchbox" sentence
> was struck. The quotations below are the pre-fix text.

**§1** (`harness/GUI_HARNESS_RECIPE.md`, anchor: the heading
`### The window-manager finding (critical)`):

> `matchbox-window-manager -use_titlebar no` fixes both. With it:
> `windowactivate --sync` and `windowfocus --sync` succeed, `getwindowfocus`
> returns the dialog id, and typing lands.

**§3** (anchor: the heading `## 3. Interaction primitives (all verified)`, and
inside it the comment line `# Focus (works ONLY with a WM running)`):

> ```
> # Focus (works ONLY with a WM running)
> xdotool windowactivate --sync $W
> ```

**§9.4**, then headed *"`windowactivate` does not work under matchbox
— use `windowraise`"*:

> `xdotool windowactivate` and `getactivewindow` both fail. `xdotool windowraise
> <id>` works and is what `emlmenu` needs before clicking the menubar.

**§10** (anchor: the heading
`### \`xdotool windowraise\` is not enough under matchbox`):

> Raising a window does not give it input focus, so clicks and keystrokes go to
> whatever had focus before. The reliable sequence before *any* click or type:
> `xdotool windowactivate --sync $id` / `xdotool windowfocus $id`

Four sections, three mutually exclusive instructions for one primitive.

**Demonstrated.** Fresh `Xvfb :87` + `matchbox-window-manager -use_titlebar no`
+ Praat 6.6.30 GUI, this sandbox:

```
$ xprop -root _NET_SUPPORTED | tr ',' '\n' | grep -i active_window
 _NET_ACTIVE_WINDOW
$ xdotool windowactivate --sync 4194307 ; echo "rc=$?"
rc=0
$ xdotool getactivewindow ; echo "rc=$?"
4194307
rc=0
```

matchbox advertises `_NET_ACTIVE_WINDOW`; both calls succeed. §9.4 is simply
wrong. It was also used successfully throughout this sweep to drive a pause
dialog (`windowactivate --sync` then `windowfocus`, then click).

**Where it has already spread.** The comment block immediately above `curpause`
in `harness/gui.sh` — anchor `grep -n '^curpause ()' harness/gui.sh` (`:251`,
verified 8 Aug; this section originally cited `:186-192`, which was 65 lines
off and landed in `infotext`):

```
# 5 Aug 2026: ... the LIVE dialog is
# frequently absent from `xdotool search` results altogether while plainly
# visible and accepting clicks. `getactivewindow` returns it every time.
#
# 7 Aug 2026: the "absent from search results" half of that is now explained —
# ... `getactivewindow` is kept
# as the first route because it is one round trip, but it fails outright under
# matchbox ("windowmanager claims not to support _NET_ACTIVE_WINDOW", §9.4 of
# the recipe), ...
```

"returns it every time" and "fails outright under matchbox" are five lines
apart in the same comment, and the second cites §9.4 as its authority.

**Why this is not cosmetic.** The code is currently right — `emlmenu`,
`infoshot`, `picshot`, `objshot` and `raise` all use `windowactivate`. Anchor
for all five at once:
`grep -n 'windowactivate' harness/gui.sh`. `raise` additionally *confirms* with
`getactivewindow` and returns `NOTRAISED` if it does not match (anchor: the
line `echo "NOTRAISED $w (active=$act)"; return 1`); `eml()` aborts on that. If
a maintainer follows §9.4 and switches to `windowraise`, the verified note above
`typein` applies (anchor: `grep -n '^typein ()' harness/gui.sh`) — "the entry
takes the click (caret shows) but receives no key events, so the field stays
empty and the script silently proceeds with the default." That is a
silent-wrong-data failure, the same family as D126.

**Resolution.** Delete §9.4's claim and its heading. Replace with: `windowraise`
alone does not confer focus; use `windowactivate --sync` then `windowfocus`,
which is what §1, §3, §10 and every function in `gui.sh` already do. Then strike
the "fails outright under matchbox" sentence from the `curpause` comment — the
client-list fallback in `curpause` is still worth keeping, but its justification
is the withdrawn-husk problem, not a `_NET_ACTIVE_WINDOW` failure that does not
occur. **Both halves done**; see the [CLOSED] note at the head of this section.

---

## C3 — [CLOSED, 8 Aug]. `eml-graphs-form.praat:1305` cited as the zero-row refusal, in eleven files

Eleven files sent a reader to `eml-graphs-form.praat:1305` for the guard that
refuses an empty table:

- `plugin/graphs/eml-graph-procedures.praat` (anchor:
  `grep -n 'Table has no rows' plugin/graphs/eml-graph-procedures.praat`)
- `harness/stress_cases/empty_{bar,box,gbox,gviolin,hist,scatter,spaghetti,ts,tsci,violin}.praat` (ten files)

Line 1305 was `prev_gvAnnotStyle = 1` — a grouped-violin persistence variable.

The refusal is:

```praat
        nRows = Get number of rows
        if nRows < 1
            exitScript: "Table has no rows."
```

with the columns guard, `exitScript: "Table has no columns."`, as the guard
immediately above it — same `if`/`endif` shape, four lines up. Anchor:
`grep -n 'exitScript: "Table has no rows."' plugin/graphs/eml-graphs-form.praat`.

**Resolution.** Retarget all eleven to the string, not to a number.
**Done, all eleven** — and the retargeting *via a number* is itself the
cautionary tale: the ten harness files were first pointed at `:2061`, which had
drifted to `:2078` a day later. They now carry the `grep` and an explicit "do
NOT write a line number back into this comment".

While retargeting them, one adjacent claim was measured rather than assumed: an
**all-blank category column does not reach this branch.** `@emlCountGroups`
(anchor: `grep -n 'procedure emlCountGroups' plugin/stats/eml-extract.praat`)
counts `""` as a group. Measured on Praat 6.4.06 against the shipped procedure:
3-row all-blank table → `nGroups=1`; 0-row table → `nGroups=0`; missing column →
`nGroups=0` with `error$ = "Column not found: …"`; blank + one real label →
`nGroups=2`. So `nGroups=0` means *no rows* or *no such column*, never *blank
labels*.

---

## C4 — [CLOSED]. The D108 note in `eml-graphs-form.praat` pointed at the Dunn branch while naming the Tukey branch

`plugin/graphs/eml-graphs-form.praat`, in the D108 comment (anchor:
`grep -n 'What is NOT fixed here' plugin/graphs/eml-graphs-form.praat`), then
read:

> What is NOT fixed here … The Tukey branch of `@emlBridgeGroupComparison`
> (`eml-annotation-procedures.praat:2151+`) never reads `.correction$` — only
> the Dunn branch does.

Line 2151 was inside the **Dunn** branch — the non-significant-omnibus matrix
fill opening `# --- Kruskal-Wallis + Dunn's post-hoc ---`, whose
`@emlDunnTest: … .correction$` call is the only consumer of the value. The
Tukey branch opens `# --- One-way ANOVA + Tukey HSD ---`.

So the reference landed on the one branch the sentence says *does* read
`.correction$`, which is the opposite of what the note is warning about. The
claim itself is true. Anchors, all in
`plugin/graphs/eml-annotation-procedures.praat`:

```bash
grep -n "# --- Kruskal-Wallis + Dunn's post-hoc ---"   # the Dunn branch
grep -n '# --- One-way ANOVA + Tukey HSD ---'          # the Tukey branch
grep -n '\.correction\$'                               # 4 hits, all Dunn-side
```

**Resolution.** Retarget to `# --- One-way ANOVA + Tukey HSD ---`.
**Applied**, and the applied form is itself a demonstration: the in-source note
now says "currently `:2183`", and `:2183` had already drifted by 8 Aug. Cite the
branch comment, not the number.

---

## C5 — [CLOSED]. FIVE more stale line references

The heading of this section read "Four more stale line references" over a table
of **five** rows, from the day it was written until 8 August. It is the smallest
instance in this document of the thing this document is about.

Each row was verified by reading the cited line and locating the real target.
The "real target" column is now the **anchor**, because two of the five
replacement targets offered here in the original went stale within the day —
see the note under the table.

| Citing site (anchor) | Said | Cited line actually held | Anchor that resolves |
|---|---|---|---|
| `plugin/graphs/eml-graphs-form.praat`, the D108 comment — `grep -n 'D108\. annotCorrectionMethod' plugin/graphs/eml-graphs-form.praat` | `@emlBridgeGroupComparison` "reads the global (`eml-annotation-procedures.praat:1808`)" | `.nGroups = emlCountGroups.nGroups` | `grep -n '\.correction\$ = "holm"' plugin/graphs/eml-annotation-procedures.praat` — the resolution block inside `procedure emlBridgeGroupComparison` |
| `plugin/graphs/eml-annotation-procedures.praat` — `grep -n 'The same two thresholds are announced' …` | "The same two lines exist in `scripts/eml-wizard.praat:2085`" | a "Data column:" padding line in the analysis plan | `grep -n 'skKurtFail' plugin/scripts/eml-wizard.praat` |
| `plugin/dev/tests/phase2/theilsen_scipy_refs.py` — `grep -n 'eml-draw-procedures' …` | Theil-Sen used at "`graphs/eml-draw-procedures.praat:2410` and `:2660`" | bar-chart gridlines; bar quadrant scan | `grep -n '@emlTheilSen: ' plugin/graphs/eml-draw-procedures.praat` — exactly 2 hits, `.xData#, .yData#` (ungrouped) and `.gXTrim#, .gYTrim#` (per group), both inside `procedure emlDrawScatterPlot` |
| `harness/stress_cases/_prelude.praat`, in `procedure stressSave` | "the plugin's own pre-save idiom (`eml-graphs-form.praat:5735`)" | `spGroupIdx = spPresetGroupIdx` | `grep -n '@emlAssertFullViewport' plugin/graphs/eml-graphs-form.praat` — 2 hits; the procedure is `procedure emlAssertFullViewport` in `graphs/eml-graph-procedures.praat` |
| `validate/README.md`, the "Check one by hand, in two minutes" walkthrough | "`validate/v09_anova_tukey_orchestrator.R`, line 60" for the quoted `check("v09", "F (summary line)", …)` | `fit <- aov(SPL_dB ~ voice_type, data = d)` | `grep -n '"F (summary line)"' validate/v09_anova_tukey_orchestrator.R` |

The last one is the most user-facing: it is inside the "Check one by hand, in
two minutes" walkthrough, so a first-time reader following the README lands on
the wrong line of the file the README told them to open.

**The replacement targets this section originally offered were themselves
stale within the day.** Row 3 proposed `:3253-3258` and `:3550-3557` for
Theil-Sen; the two `@emlTheilSen:` calls have moved several times since — twice
during the writing of this very paragraph, which is why no replacement number is
given for them here. Row 4 proposed `:6348` and `:6423` for
`@emlAssertFullViewport`; those became `:6595`/`:6670`, then `:6612`/`:6687`
within an hour. **A retargeted number is not a fix for a stale number.** Run the
`grep` in the table; it is correct at the moment you run it, which no number in
this file can promise.

**Resolution.** All five retargeted, every one of them to a quoted string or a
procedure name rather than to a number — which is what every one of these was
really identifying all along. Rows 2, 4 and 5 additionally carry an in-file
warning not to write a number back.

---

## C6 — [CLOSED]. False *open*-defect record: `emlmenu` no longer uses `windowraise`

`harness/GUI_HARNESS_RECIPE.md`, anchor
`grep -n 'known latent bug' harness/GUI_HARNESS_RECIPE.md`, then read:

> `emlmenu` in `gui.sh` still uses `windowraise` — known latent bug, unfixed.

`harness/gui.sh`, anchor `grep -n '^emlmenu ()' harness/gui.sh` (`:107`,
verified 8 Aug — this section originally cited `:82-90`, which was 25 lines off
and landed in the `findwin` region):

```bash
emlmenu () {
  local y="$1"
  local o
  o=$(findwin "^Praat Objects$" | head -1)
  xdotool windowactivate --sync "$o" 2>/dev/null; sleep 0.6
  xdotool windowfocus "$o" 2>/dev/null
```

No `windowraise`. `grep -n windowraise harness/gui.sh` returns two hits, both
inside functions where it is *followed* by `windowfocus` — anchors
`grep -n '^typein ()' harness/gui.sh` and `grep -n '^raise ()' harness/gui.sh`.
The defect was fixed; the record said it was open.

This is the mirror image of the calibration example in
`eml-annotation-procedures.praat` — a false *closure* record. That comment read
`# D37: n1,n2 were literal 0,0. D41: effect_label was ""` beside a block that
emitted neither; it has since been rewritten in place and the surviving anchor
is
`grep -n 'were both false when written' plugin/graphs/eml-annotation-procedures.praat`.
A false open record is cheaper but costs the next reader a re-derivation.

**Resolution.** Strike the sentence. **Done** — the recipe now records the
withdrawal in place rather than the claim.

---

## C7 — [CLOSED]. `gui.sh` forbade `xdotool search --name` in its banner and fell back to it in the next function

`harness/gui.sh`, the lookup banner — anchor
`grep -n 'NEVER .xdotool search --name' harness/gui.sh`:

```bash
# Window lookup — enumerate _NET_CLIENT_LIST, NEVER `xdotool search --name`
```

`harness/gui.sh`, the fallback inside `xwins` — anchor
`grep -n 'xdotool search --name "\."' harness/gui.sh`:

```
  if [ -z "$raw" ]; then
    # No EWMH window manager. Nothing else in this harness works without one,
    # but a degraded list beats a silently empty one.
    xdotool search --name "." 2>/dev/null
    return
  fi
```

Same shape as the calibration example: the banner names the prohibition, and
the enumeration keeps the prohibited call. Unlike the `raise` case this one is
deliberate and commented — but the justification ("a degraded list beats a
silently empty one") is exactly the reasoning the file's own `raise` note
rejects (anchor: `grep -n '^raise ()' harness/gui.sh` and read the comment block
above it): `xdotool search --name "."` "only lists windows that have a
`WM_NAME` at all — so a pause window titled with an em dash never entered the
loop". Under the fallback, `findwin "^Pause:"` returns nothing while the dialog
is on screen, and `raise` reports `NOWIN` — indistinguishable from "no such
window", which is the failure mode §11 of the recipe spends a page saying is
expensive.

**Resolution.** Keep the fallback but make it audible. **Done** — anchor
`grep -n 'WARNING: no _NET_CLIENT_LIST' harness/gui.sh`, a three-line warning
to stderr naming the em-dash consequence.

**Closing it found something worse in the same function**, now filed as D132:
`xprop -root _NET_CLIENT_LIST` prints `"…no such atom on any window."` **on
stdout with exit 0** when the atom is absent, and the unanchored `sed` passed
that sentence through as data — so `raw` was never empty and this fallback
**never ran**. `printf '%d'` over seven English words returned seven zeros and
every caller then ran `xwininfo -id 0`. Anchor for the fix:
`grep -n "sed -n 's/.*# //p'" harness/gui.sh`.

---

## C8 — [CLOSED]. The recipe's diagnosis of `infotext` was half wrong, and the wrong half matters

`harness/GUI_HARNESS_RECIPE.md`, anchor
`grep -n 'infotext. takes no argument' harness/GUI_HARNESS_RECIPE.md` (the
section is now headed that; it then read):

> `infotext <path>` prints to stdout, **exits 1**, and does not create the file.

`infotext` in `harness/gui.sh` — anchor `grep -n '^infotext ()' harness/gui.sh`
— took no argument and ignored any. Reproduced with the function body verbatim,
`sendp` stubbed and a fixture `info.txt`:

```
--- infotext with an argument ---
stdout=[hello info]  exit=0
ls: cannot access '/tmp/probe/fake/w5.txt': No such file or directory
--- infotext with no argument ---
stdout=[hello info]  exit=0
```

"Does not create the file" is right; "exits 1" is wrong — it exits **0**. That
is the worse case, and the reason to correct it: a caller written as
`infotext out/x.txt && wc -l out/x.txt` sees success and then reads a file that
was never written. An exit 1 would have stopped it.

**Resolution.** Either fix the doc, or (better, since the doc calls this "Known
latent bug, unfixed") make the function reject an argument:
`[ $# -gt 0 ] && { echo "infotext takes no argument; use a shell redirect" >&2; return 2; }`.
**Both done** — anchors
`grep -n 'infotext takes no argument' harness/gui.sh` (the guard inside the
function, which `return 2`s) and
`grep -n 'takes no argument' harness/GUI_HARNESS_RECIPE.md` (the corrected
section heading, which carries backticks around the function name and so does
not match the first pattern).

---

## C9 — [CLOSED, D134, 8 Aug]. The wizard kept the normality gate `eml-analysis.praat` says was removed for inverting the hierarchy

> **Closed 8 Aug 2026.** `@wizardNormDiag` now mirrors the
> `eml-analysis.praat` hierarchy branch for branch, verified on eight cases
> including forced threshold moves. Anchors that resolve today:
> `grep -n 'procedure wizardNormDiag' plugin/scripts/eml-wizard.praat`, and
> `grep -n 'skKurtFail' plugin/scripts/eml-wizard.praat` — which no longer
> returns a gate, only the two comments recording what the gate used to be.

`plugin/stats/eml-analysis.praat`, anchor
`grep -n 'skKurtFail or swFail' plugin/stats/eml-analysis.praat`:

> Until 5 August this gate read `skKurtFail OR swFail`, which let a descriptive
> rule of thumb overrule a formal test … That inverts the hierarchy. …
> The one place shape legitimately intervenes is the large-n case …

(That wording was itself rewritten on 8 Aug into a fuller hierarchy block; the
`skKurtFail or swFail` grep still finds it, which is why that is the anchor and
not the sentence.)

The corrected gate is the branch that block documents — anchor
`grep -n 'Shapiro-Wilk usable, does not reject' plugin/stats/eml-analysis.praat`:
when Shapiro-Wilk is available and does **not** reject, the recommendation is
`parametric` unconditionally, shape is reported but does not overturn the test,
and shape decides only where Shapiro-Wilk cannot run.

`plugin/scripts/eml-wizard.praat`, inside `procedure wizardNormDiag`, then still
read:

```praat
    if .skKurtFail or .swFail
```

with an `else` giving `parametric`. So on the SW-passes branch the wizard
returned *nonparametric* where `@emlRunNormalityAnalysis` returned *parametric*.
The wizard's own comment a few lines above claimed the opposite — that the two
paths can no longer "reach opposite conclusions on the same column" (D95) — but
D95 unified the *thresholds*, not the *gate*.

**Reachability, measured.** The divergence needs `|skew| ≥ 2` or
`|excess kurtosis| ≥ 7` together with Shapiro-Wilk `p ≥ 0.05`. Searched 4000
random samples, n ∈ [4, 30], 0–2 injected outliers of magnitude U(3, 40), using
the plugin's own `@emlSkewness` / `@emlKurtosis` / `@emlShapiroWilk`:

```
searching for  skKurtFail=1 AND swFail=0  (wizard says nonparametric, analysis says parametric)
total divergent samples out of 4000 trials: 0
```

At `emlSkewThreshold = 2` / `emlKurtosisThreshold = 7` — anchor
`grep -n '^emlSkewThreshold\|^emlKurtosisThreshold' plugin/stats/eml-output.praat`
— Shapiro-Wilk rejects first in every case I could construct. So this is a real
structural divergence with no demonstrated input. **Do not prioritise it as a
behaviour bug; do fix the comment**, because the comment is what will stop the
next reader noticing the gate.

Two stale constants ride along, both harmless but both false today: a comment in
`eml-wizard.praat` reading "the constants said 1 and 1", and one in
`eml-annotation-procedures.praat` reading "With the kurtosis threshold at 1,
a g2 of 1.5 …". The constants are 2 and 7. Both **corrected 8 Aug** —
`grep -rn 'kurtosis threshold at' plugin/` now returns nothing, and the
thresholds are printed from the variables rather than spelled out (anchor:
`grep -n 'emlKurtosisThreshold' plugin/scripts/eml-wizard.praat`).

**Resolution.** Rewrite `@wizardNormDiag`'s gate to mirror the
`eml-analysis.praat` hierarchy branch exactly, or — cleaner, and in keeping with
"the diagnosis is written once" — have `@wizardNormDiag` call
`@emlRunNormalityAnalysis` and read `.recommendation$`. **Done**, the first
way; see the [CLOSED] note at the head of this section.

---

## C10 — [CLOSED]. Three false statements in the `eml-draw-procedures.praat` header, one of them a dangling forward reference

**These three citations were the worst-behaved in this document.** Written as
`:186`, `:465` and `:466`, they had already drifted to `:219`, `:498` and `:499`
before anyone edited this file, and moved again afterwards. All three are cited
by quoted string below; none by number.

- `grep -n 'Contains all 14 drawing procedures' plugin/graphs/eml-draw-procedures.praat`
  — "Contains all 14 drawing procedures."
  `grep -c "^procedure emlDraw" plugin/graphs/eml-draw-procedures.praat` → **15**
  (re-counted 8 Aug: still 15). The `Procedures:` list below it omitted
  `@emlDrawLMMForest` (anchor:
  `grep -n '^procedure emlDrawLMMForest' plugin/graphs/eml-draw-procedures.praat`).
- `grep -n 'Real implementations for all 7 graph types' plugin/graphs/eml-draw-procedures.praat`
  — fourteen lines below a list of fourteen. Two different counts of the same
  thing in one header.
- `grep -rn 'MAIN EXECUTION' plugin/` — "matches the dispatch calls in the MAIN
  EXECUTION section below." That grep returned exactly one hit: the claim
  itself. There is no such section, here or anywhere in the plugin; the same
  header says "No standalone executable code."

**Resolution.** One count, `@emlDrawLMMForest` added to the list, and the
dangling "MAIN EXECUTION" clause deleted. **All three done** — anchor
`grep -n 'MAIN EXECUTION' plugin/graphs/eml-draw-procedures.praat`, which now
hits only the changelog entry recording the deletion, and the header's count is
stated with the `grep` that reproduces it rather than as a bare number.

---

# Categories checked and found clean

Recording these so nobody re-walks them.

**The D116 missing-column guard is fully propagated.** All eleven
Table-taking procedures in `eml-inferential.praat` call
`@emlRequireColumnPresent` before any group work: `emlTukeyHSD`,
`emlOneWayAnova`, `emlTwoWayAnova`, `emlKruskalWallis`, `emlDunnTest`,
`emlPairwiseT`, `emlPairwiseWilcoxon`, `emlScheffe`, `emlBrownForsythe`,
`emlWelchAnova`, `emlGamesHowell`. The orchestrators that cannot delegate,
`emlRunTwoGroupAnalysis` and `emlRunPairwiseAnalysis` in `eml-analysis.praat`,
carry it too. No twelfth sibling was left short. Reproduce the whole list at
once, procedure by procedure rather than by line number:

```bash
awk 'BEGIN{p="(top)"} /^procedure /{p=$2} /@emlRequireColumnPresent:/ && !/^ *#/ {print NR, p}' \
    plugin/stats/eml-inferential.praat plugin/stats/eml-analysis.praat
```

Re-run 8 Aug: still exactly those eleven procedures (18 call sites — several
guard more than one column) plus the two orchestrators.

**Figure disclosure is symmetric across the TEN draw procedures that have it.**
Corrected 8 Aug: this note said "eleven draw procedures" and "all ten that
render their own block", and **both numbers were one too high**. Measured:

```bash
awk 'BEGIN{p="(top)"} /^procedure /{p=$2} /@emlDisclose(Begin|End):/ && !/^ *#/ {print NR, p}' \
    plugin/graphs/eml-draw-procedures.praat
```

→ **10** `@emlDiscloseBegin:` call sites and **9** `@emlDiscloseEnd:` call sites
(comment mentions excluded by the `!/^ *#/` filter). The ten that begin are
`emlDrawTimeSeries`, `emlDrawTimeSeriesCI`, `emlDrawSpaghettiPlot`,
`emlDrawBarChart`, `emlDrawViolinPlot`, `emlDrawScatterPlot`, `emlDrawBoxPlot`,
`emlDrawHistogram`, `emlDrawGroupedViolin`, `emlDrawGroupedBoxPlot`. They pair
correctly in the nine that render their own block; `@emlDrawScatterPlot` is the
one that begins and does not end, and it is the documented exception — anchor
`grep -n 'is the one exception' plugin/graphs/eml-draw-procedures.praat`. The
file's own header states the count of ten with the grep that reproduces it
(anchor: `grep -n 'returns 10' plugin/graphs/eml-draw-procedures.praat`), so
the number and its proof travel together.

The `legendCorner$` argument is `""` for exactly the three types that draw no
legend — bar, violin and box, all three of which put group names on the x-axis
— and is the real corner in the six that do. Verified 8 Aug by reading all nine
call sites: three end `…, ""`, six end `… .legendCorner$`. The five procedures
with no disclosure at all (`emlDrawF0Contour`, `emlDrawWaveform`,
`emlDrawSpectrum`, `emlDrawLTAS`, `emlDrawLMMForest`) take objects, not tables,
and have no rows to drop — 15 procedures total, minus the 10 that disclose.

**No draw procedure writes `emlSubtitle$`.** Corrected 8 Aug: this note stated
the command as `grep -rn 'emlSubtitle\$' plugin/ --include=*.praat` and claimed
it "returns **zero** hits", which it does not and never did — that pattern
matches every mention, including the two claims being verified. The claim is
about *assignment*, and the command that demonstrates it is:

```bash
grep -rn 'emlSubtitle\$ *=' plugin/graphs/eml-draw-procedures.praat \
                            plugin/graphs/eml-draw-qq.praat
```

→ zero hits, both at `236b915` and on 8 Aug. The claims hold; anchor them at
`grep -n 'emlSubtitle\$  NEVER' plugin/graphs/eml-draw-procedures.praat plugin/graphs/eml-draw-qq.praat`.
(The global *is* assigned in `eml-graphs-form.praat`, which owns it — it is the
user's own subtitle field — and cleared in `@emlInitDrawingDefaults`. That is
the point of the rule, not a violation of it.)

**`@emlMeasureBarData`'s "CALLERS MUST GUARD" contract is honoured.** Anchor:
`grep -n 'CALLERS MUST GUARD' plugin/graphs/eml-graph-procedures.praat` (one
hit). All three per-group readers in `@emlDrawBarChart` — the bar loop, the
error-bar loop and the quadrant scan — test `<> undefined` or `valid[g]` first,
and the visible-range scan the note says was fixed does substitute 0 for an
undefined error.

**The grouped-violin / grouped-box sub-group cap pair is symmetric.** Same
`.maxSubs` / `.nSubsDrawn` / `.nSubsDropped` / `.nDroppedSubRows` plumbing, same
`legendN = .nSubsDrawn`, same disclosure, in both. Anchor:
`grep -n '\.maxSubs = ' plugin/graphs/eml-draw-procedures.praat` — two hits, one
per procedure, with identical values. (The value itself has since moved 10 → 24
under D127; the *symmetry* is what this note asserts and it still holds.)

**`@emlBridgeCorrelation`'s "UNUSED — no caller anywhere in the plugin" is
true.** Anchor:
`grep -n 'UNUSED — no caller' plugin/graphs/eml-annotation-procedures.praat`.
The only other occurrences are its own doc lines and
`plugin/dev/tools/procs.json`.

**The `>10 groups` changelog entry is accurate.** Anchor:
`grep -n 'Removed >10 group hard' plugin/graphs/eml-annotation-procedures.praat`
— the changelog says the hard error was removed; the surviving site is an
informational `appendInfoLine` (anchor:
`grep -n 'groups detected' plugin/graphs/eml-annotation-procedures.praat`), not
an error.

**Module reachability and call resolution are clean.**
`bash validate/tools/check_wired.sh` → *"all stats/ and graphs/ modules are
reachable from plugin/scripts/"*, exit 0.
`python3 validate/tools/check_calls.py` → one script with unresolved calls,
`eml-tutorial.praat` (23 of them), which is correctly `exitScript`-ed (anchor:
`grep -n 'exitScript' plugin/scripts/eml-tutorial.praat | head -1` — the "not
available in this build" refusal), unregistered from the menu (anchor:
`grep -n 'eml-tutorial.praat' plugin/setup.praat`), and whose count and status
the setup comment states correctly.

**Suite headline counts agreed at `236b915`: `3881`,** in `README.md`,
`validate/README.md` and `validate/REGISTRY.md`. That number is a moving target
by design — as of 8 Aug it is **4104** (anchor:
`grep -rn '4104' README.md validate/REGISTRY.md`) — so the claim to carry
forward is *"they agree with each other"*, not the digits. Re-check with:

```bash
grep -rhon '[0-9]\{4\} checks' README.md validate/README.md validate/REGISTRY.md
```

**The `@emlDiscloseEnd` duplication of the form's omnibus-box rule is
faithful.** Anchor:
`grep -n 'bottom-right' plugin/graphs/eml-draw-procedures.praat plugin/graphs/eml-graphs-form.praat`.
Its mirror of "brackets → bottom-right, otherwise top-right, suppressed when a
matrix panel exists" matches the form's `omnibusCorner$` assignment case for
case. The coupling is real and is already named in the comment; it is not
currently *wrong*.

**Refusal messages naming the wrong cause:** beyond the filed D116 pair I found
none. Every `@emlRequireColumnPresent` site carries a comment naming the
specific wrong message it replaced ("Group ""H3"" has 0 observations", "0
observations across 3 groups leave no within-groups degrees of freedom",
"nothing at all"), and each of those is genuinely no longer reachable ahead of
the guard.

---

# Coverage — honest accounting

**Read in full** (≈1,250 lines): `harness/GUI_HARNESS_RECIPE.md`,
`harness/gui.sh`, `validate/tools/check_wired.sh`, `validate/tools/check_calls.py`,
`plugin/setup.praat` (relevant halves), `validate/README.md` §1–§3.

**Read closely in targeted regions** (≈3,000 of the ~52,000 Praat lines under
`plugin/`): the disclosure contract and bar/grouped-violin/grouped-box bodies of
`eml-draw-procedures.praat`; the palette, bar-data and categorical-axis regions
of `eml-graph-procedures.praat`; the bridge entry, normality report and two-way
report of `eml-annotation-procedures.praat`; the gridline, preset, persistence
and POST-DISPATCH regions of `eml-graphs-form.praat`; the guard block of
`eml-inferential.praat` (anchor:
`grep -n 'procedure emlRequireColumnPresent\|procedure emlRequireNumericColumn' plugin/stats/eml-inferential.praat`)
and all eleven guard sites in that file; the orchestrator entries and normality
gate of `eml-analysis.praat`; the threshold constants and wizard-explain
procedures of `eml-output.praat`; `eml-draw-qq.praat` header;
`eml-wizard.praat` `@wizardNormDiag`.

**Grep-swept only, not read** — every file under `plugin/`, `harness/`,
`validate/` was passed through pattern sweeps for: defect-number comments (416
hits), normative comment keywords (`NEVER`/`MUST`/`ALWAYS`/`no longer`/`is gone`/
`does not`/`never calls`), uniqueness claims (`the only caller`/`every caller`/
`one place`/`no caller`), `all <N>` parity claims, numeric caps with prose
justifications, and embedded line references (`line NNN`, `:NNN`). Every hit in
those sweeps was inspected; the ones that survived are above.

**Not covered at all.** `plugin/stats/eml-lmm.praat` (4391 lines at `236b915`;
4408 on 8 Aug), `eml-optimizer.praat` (2387 → 2402), `eml-extract.praat`
(2800 → 2817 — greps only), `eml-linalg.praat`,
`eml-result-writer.praat`; the thirty `validate/v*.R` validators (~350 KB — I
ran the two repository tools but read none of the assertion bodies, so **"a
validator whose comment says it asserts X while it asserts Y" is NOT a category
I can report clean**); `plugin/dev/tests/`; `harness/walks/`, `harness/qq_cases/`,
`harness/broom_cases/`, `harness/disclosure/` beyond grep.

Call it **full mechanical coverage, ~6 % close reading**, with the close reading
concentrated on `plugin/graphs/` and the harness because that is where the three
calibration examples came from. The largest unswept surface is
`validate/v*.R`; the second largest is `eml-lmm.praat`.

---

*Sweep run 7 Aug 2026 against `236b915`. Probes under `/tmp/probe/`; nothing in
the repository was modified. Praat 6.6.30 (`/home/claude/praat`) for the GUI
probes, Praat 6.4.06 (`/usr/bin/praat`) for the batch probes.*

*Citations rewritten to anchor-first form 8 Aug 2026, after this document was
found to contain the defect it documents: a five-row table under a heading
saying "four", two citations 25 and 65 lines off, replacement targets that went
stale the same day they were offered, and two counts in the "found clean"
section that were each one too high. Every anchor above was re-verified against
the working tree on 8 Aug. C1–C10 are all closed; the pre-fix text is kept as
the record and marked as such.*
