# Letter to the managing session — rulings and change orders, 15 August 2026

From the stress-test session, after the author reviewed your fix-session transcript and my
independent verification of it. Context you can trust: I pulled `5ecb037`, re-ran the suite
myself (10,873/10,873, 0 failed, exit 0), and live-drove all five headline fixes on a fresh
GUI instance — editor sentinel shim, Matrix/TableOfReal doors, stereo channel dialog
(220 L / 330 R reads 220, not the 110 GCD), standalone annotated Kruskal-Wallis (H, ε², and
all three Holm-adjusted Dunn p's verified by exact-rank computation), and the three-row
normality export. All pass. The author has now ruled on your open questions. Everything
below is a ruling or a specified change order; the three unruled items are marked.

## Rulings (implement)

**1. D5 — the Adjustment menu on the Tukey arm: ACCEPTED as follows.**
Your statistics are agreed (Tukey is already family-wise; stacking Holm/Bonferroni would
double-correct). Disable/remove the Adjustment field on the parametric arm rather than
leaving a live-looking control that is ignored (that is the same class as the
group-column-while-unchecked issue), and have the annotated figure state that Tukey
carries its own family-wise control. The Dunn arm keeps the menu, which it honors
(verified: Holm ≠ Bonferroni there, both matching scipy).

**2. Version floor: no changes, and do not conflate the two floors.**
The plugin's floor is 6.6.30 and it is FINE for setup.praat to refuse below it — the
validation evidence exists only at 6.6.30, and a warn-and-continue plugin would print
unvalidated numbers under a validated banner. PraatGen has its own, lower measured floor
(6.4.39) governed by its own §S15A warn-don't-refuse rule for generated scripts. These are
different artifacts with different contracts. Leave both numbers; if any doc implies the
plugin should follow §S15A, correct the doc to state the distinction instead.

**3. Skewness/kurtosis into the tidy vocabulary: ACCEPTED.**
Add them (they already ship in the glance vocabulary under "our own additions"); this
removes the single-column-exports-them / multi-column-loses-them asymmetry.

**4. Recorder buffer deletion: ACCEPTED per your recommendation.**
No per-step signal. Rename the buffer to something that reads as load-bearing, keep your
corrected Stop-command message ("recording ended when its buffer was removed"). Done.

## Change orders (new, from post-fix verification — evidence in /tmp/aud70/out, and the
key files travel in the evidence zip the author holds)

**5. Matrix/TableOfReal converted-column naming (author-confirmed scope).**
Column 1 stays exactly as it is: named `row`, holding the `r1..rn` labels — that part of
the conversion is correct, including the existing collision guard. The change is only the
DATA columns to its right: the header repair currently numbers them by TABLE position
(where `row` occupies slot 1), so source matrix column k is labeled `Column_{k+1}`, and a
user asking for "column 2 of my matrix" who picks `Column_2` gets matrix column 1's data.
Number them by SOURCE index instead: `Column_k` holds matrix column k. (Evidence:
leg2_converted_mx.csv — Column_2 currently holds source column 1.)

**6. Numeric display standard — one rule, sweep for leaks.**
House standard confirmed across wrappers: statistics at fixed 4 decimals, p in APA style.
That matches peer practice (SPSS: fixed decimals per table, full precision only on export;
JASP/jamovi: 3 significant figures; R: rounded print, full-precision object). The rule to
enforce: NO raw double ever reaches the Info window; full precision belongs to the CSV
export only. Two known leaks to fix, then sweep for siblings behind the same bypass:
- skewness in the converted-matrix Describe path prints `-0.0000000000000001`
  (leg2_mx_describe.info.txt);
- the wizard's p-lines print the raw 16-digit double after "< .001" (audit finding
  NEW-G5-2, /tmp/aud55 evidence).

**7. Y-axis margin vs 4-significant-digit ticks (author delegates the mechanism; the
requirement is no collision).**
Measured at HEAD: Praat's left-margin allocation is FIXED (~100 px ≈ 5.2 digit-widths;
the rotated axis name renders in the same band regardless of tick width; ticks
right-aligned to the frame). Five-character ticks ("200.2") leave ~¼ digit of gap;
six-character ticks are the failure edge: semitone axes with negatives ("-32.98") read as
touching, and an explicit 2-decimal dB axis genuinely touches ("Power (dB)" against
"100.10"). No truncation or overprint anywhere; the mode is gap exhaustion. Since
@emlTickPrecision sits inside the shared aligned-marks procedures (one formatter, all draw
paths), implement one guard there or in @emlDrawAxes: when explicit precision engages OR
the widest rendered tick label exceeds 5 characters, widen the plugin's left viewport
margin by one character-width before drawing. Evidence: pic_case2_semitone_full.png,
pic_case3_spectrum_full.png, case2_margin_zoom.png, case3_zoom.png.

**8. Housekeeping observed in passing (sev-4, batch at will):**
- each door press on the same Matrix/TableOfReal creates a fresh `eml_converted_*` Table,
  and each stereo draw leaves the extracted channel Sound — both accumulate per press;
  reuse or clean up;
- a Spectrum drawn with a ~1-bin x-range (999.4–1000.2 Hz) renders an empty frame with
  axis furniture only — unchased, filed for the queue.

**9. Recorder: lift column names into the editable header block (author ruling).**
The emitted script's retarget block currently gathers only object names (`data1$ = "Table
vt"` — "edit a name to run the same workflow on other data"). Column names stay hard-coded
literals at each call site (`@emlBridgeGroupComparison: data, "val", "grp", ...`), so
retargeting to a same-shape table with different headers means hunting literals through
the steps. Gather them into the same block — `valueCol$ = "val"`, `groupCol$ = "grp"`
(one variable per distinct role the recording used) — and have the steps reference the
variables. The block's existing promise ("nothing below this block names an object")
extends to: nothing below this block names a column. Evidence:
harness/record/replay_out/adv_emitted.praat lines 53-62.

**10. Recorder: record the user's axis CHOICE, and put any explicit range in the editable
block (author ruling).**
The emission currently bakes the RESOLVED axis range into the draw call as numeric
literals (`@emlDrawViolinPlot: ... 1.554964, 4.416270` — "Axis resolved to 1.5550 ..
4.4163") even when the user left the axis on auto. On retargeted data the statistics
recompute honestly but the frame stays frozen at the original data's range — clipped or
swimming. Two-part fix: (a) when the user chose AUTO, emit auto — let the draw resolve
the range from the data at replay time; (b) when the user set an explicit range, emit it
as variables IN the editable header block (`axisYMin = 6` etc.), referenced by the draw
call — so the one place a user edits for new data is still the top block. The replay
comparison harness needs a same-data leg (byte-identical figure must still hold when the
data is unchanged) and a retargeted leg (figure must rescale under auto).

## Still open (no author ruling yet — do not act)

- **Batch voice analysis registration.** Your 255 checks and the STOP.txt/output-folder
  rework are noted. The stress-test session's standing recommendation: one
  savepaths-style GUI drive leg through the real dialog before the menu line returns.
  Awaiting the author's explicit ruling.
- **The unification** (graphing-door stats onto shared machinery) remains a project, not
  a fix; the engine-agreement measurements from the audit stand as its regression
  baseline. D7 (annotate-preset discard on beginner Draw) and the config
  write-never-restore family remain queued under it unless you fixed them since — your
  transcript's gui_adv note ("the beginner draw annotates too") suggests D7 may already
  be closed; if so, mark it against the audit's findings JSON.

## Bookkeeping

The author's findings JSON (FINDINGS_MACHINE.json, 41 rows) is the checklist of record for
the audit round; the five spot-verified fixes above can be marked fixed-and-verified. The
audit report's §7 doc items are all superseded by your delete-totals-from-prose lint
except the gui.sh coordinate note, which your re-measure closed.

— stress-test session, 15 Aug 2026
