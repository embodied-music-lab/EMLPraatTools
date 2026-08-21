# What a recorded script brings back

One recording session, six ordinary user actions, then five separate
attempts to replay the script it produced. This file reports what came
back, what did not, and what each missing piece costs the person who opens
the script a month later.

Measured 21 August 2026 against Praat 6.6.30. Every claim below has a
number behind it, and the demonstration's own substitutions are named in
the last-but-one section. Nothing in the plugin was changed.

## The short version

The recorder is trustworthy about the things it records and silent about
the things it does not. It reproduces analysis, figures and saved output
so exactly that the replayed picture is the same file, byte for byte. It
says nothing at all about where the table came from or what was done to it
before the analysis ran. That silence is the whole risk, and it is
concentrated in one place: a hand edit to the data.

## What was done in the recording session

The recording was started, and then six things happened in order, in one
Praat session:

1. A demonstration table was created with the plugin's demo generator.
2. A data file was opened from disk — 24 rows, three cohorts.
3. One cell was changed by hand in the table editor: row 1, the f0 column,
   from 100 to 4242.
4. A one-way ANOVA was run comparing f0 across the three cohorts.
5. A violin plot of the same data was drawn.
6. The results and the figure were saved.

The edit in step 3 was chosen to be impossible to miss. The three cohorts
in the file do not overlap at all — one sits near 100, one near 300, one
near 900. Changing a single value to 4242 drags the first cohort's average
from 103.5 up to 621.25 and inflates its spread enormously. The analysis
that follows lands on a completely different answer depending on whether
that edit happened. No replay can reproduce the recorded numbers by luck.

The recording then produced a script. That script is 114 lines. It
contains three steps: the analysis, the figure, and the save.

## Action by action

### Creating the demonstration table — not recorded

The recorded script contains nothing about it. The proof is a count of
what is on screen at the end. The recording session finished with two
tables open. Every one of the five replays finished with one. The
demonstration table simply never comes into existence when the script is
run, and neither the script nor anything it prints mentions that it is
absent.

**What it costs you a month later:** very little on its own, but it is the
clearest illustration of the underlying limitation. The recorder has no
notion of a table coming into existence. It can describe what was done to
your data; it cannot describe where your data came from.

### Opening the data file — not recorded

No step is written for the file that was opened. The first instruction in
the recorded script assumes the table is already there and selects it by
name. Every replay therefore had to open the file itself before running
the script.

This one is honest about itself, which matters. The script's header names
the table it was recorded against, gives its size — 24 rows, three columns
— and states plainly that the objects it needs must be open before you
run it. The table's name also appears in the editable block near the top,
where you are invited to change it to point at other data.

So the file is documented but not reproduced. A reader is told what they
need; they are not given it.

**What it costs you a month later:** you must remember, or work out, which
file this was. The script names the table but not the file on disk. If the
table was called something forgettable, or if you have several versions of
the data, the script will not tell you which one it meant. It will run
perfectly happily against the wrong one.

There is a small sign that this gap was anticipated. The plugin ships a
table of sentences the recorder uses to describe steps in plain English.
One of those sentences reads *"Loaded {1} as supplied. Nothing below
modifies it."* Nothing in the plugin's working code ever uses it. The
wording for a "you opened this file" step was written; the step itself was
never built.

### The hand edit to a cell — not recorded, and this is the one that bites

Nothing is written for the edit. This is the only gap that changes the
answer without saying so.

The test for this was to play the part of a colleague. Fresh Praat, the
data file exactly as it was sent, the script run without modification
except for the one line that tells it where to put the output. It ran
cleanly to the end. It printed no warning. It wrote the same seven files
with the same names.

And it reported completely different results:

| | recording session | colleague's replay |
|---|---|---|
| F | 1.0103 | 231111.1111 |
| p | .381 — not significant | < .001 — significant |
| Effect size | 0.0878 | 1.0000 |
| First cohort's mean | 621.25 | 103.50 |
| Every pairwise comparison | not significant | all significant |

The figure changed too, by 137,074 pixels — about 8% of the image. Its
vertical axis reads 0 to 1000 where the recorded one read -2000 to 6000.

The four replays that staged the edit by hand matched the recording
exactly. So the divergence is precisely and only the missing edit. Nothing
else differed.

**What it costs you a month later:** this is a correctness problem, not a
convenience problem. A script that silently produces a different answer
from the one written in its own comments is worse than a script that
fails. The recorded file even contains the original numbers as a comment —
`F(2, 21) = 1.0103, p = 0.3811` — sitting directly above code that will
compute something else entirely. A reader comparing the two would conclude
the plugin is unreliable, when in fact the plugin is faithfully analysing
a table that is no longer the table that was analysed.

The same applies to anyone you send the script to. They receive an
artefact that looks complete, runs without complaint, and quietly answers
a different question.

### The analysis — recorded and reproduced exactly

Every number came back. The recorded script's analysis step is a single
readable instruction under a block where the table name and the two column
names are laid out for editing.

Four independent replays, four fresh Praat processes, reproduced the
59-line results report with one line of difference. Every figure in it is
identical: the sums of squares, the F ratio, the p value, the equal-spread
check, all three Tukey comparisons, every group's count and mean and
spread. The five machine-readable result files are identical byte for
byte.

The one line that differs is a provenance note. The recording session's
report carries a line reading `from: analysis dialog`, recording which
route through the plugin produced it. The replayed report does not carry
that line. The recorded script never sets it, so the information is
dropped.

**What it costs you a month later:** almost nothing. The single missing
line means a replayed report cannot tell you which menu the original
analysis was reached from. That is a small loss of provenance in a
document that is otherwise complete.

### The figure — recorded and reproduced exactly, pixel for pixel

Every faithfully-staged replay produced an image with the same fingerprint
as the recording session's: the same 62,639 bytes, the same 1800x1200
pixels, zero differing pixels. Not "visually indistinguishable" — the same
file.

The recorded script gives you real control over it. The step sits under a
block of named settings with plain-English notes: whether to clear the page
first, where on the page the panel goes, the line style, whether a second
axis is drawn, and the vertical axis range.

There is one caveat, and the colleague's replay exposed it. The axis range
is recorded as "work it out from the data" rather than as the two numbers
it worked out to. Those numbers appear only in a comment: *"on the recorded
data it resolved to -2000.0000 .. 6000.0000."* On the recorded data the
replay works out the same range and the picture is identical. On the
colleague's unedited data it works out 0 to 1000 instead. The comment
describes what happened; it does not constrain what will happen.

**What it costs you a month later:** nothing, if the data is the data that
was recorded. If you point the script at different data, the axis will
move to suit it, and the comment in the file will then be describing a
range the figure no longer uses. That is arguably correct behaviour — an
auto axis should adapt — but the comment reads like a promise, and it is
not one.

### Saving — recorded and reproduced, with two differences by design

The save step comes back and works. The replay wrote seven files: the
figure, five machine-readable result tables, and the text report. The
figure was byte-identical; all five tables were byte-identical; the report
matched apart from its timestamp and the provenance line already
mentioned.

Two things differ on purpose. The file name gets a fresh date-and-time
stamp, so a replay never quietly overwrites the originals. And the
destination folder is recorded as the folder used during the session — if
you do not edit that line, the replayed output lands next to the original
output rather than wherever you are working now. We confirmed that by
accident: a second run of the recording wrote its files into the first
run's folder. The plugin handles this sensibly by keeping the whole set
together under one name, so the outputs never interleave.

**What it costs you a month later:** you must remember to change the output
folder. The line is right there and clearly commented, but the script will
not stop you if you leave it. Everything else about saving is faithful.

### Ambient display settings — the recording does not inherit them, and that is good news

The obvious worry with any recorded figure is that it will look different
because your Praat is set up differently — a different typeface, a
different pen, a leftover drawing on the page. We tried hard to break it.

One replay was set up to be as hostile as possible before running the
script: a different typeface, font size 60, thick lines, red ink, the page
area redefined, the coordinate system redefined, and a figure already drawn
on the page. The script then ran. The figure it produced was byte-identical
to the recording session's. Zero differing pixels.

This is not a case of the perturbation being too weak to matter. Applied to
an ordinary Praat drawing, those same settings do change it, measured on a
simple control figure:

| setting changed | differing pixels |
|---|---|
| Line width 5 | 32,448 |
| Red ink | 10,561 |
| Font size 60 | 60,471 |
| Typeface Helvetica to Palatino | 26,238 |

The reason the plugin is immune is that it re-asserts everything it uses
every time it draws. It sets its own colour in 121 places, its own line
width in 84, its own font size in 64, and it clears the page before
starting a panel.

**What it costs you a month later:** nothing, for this figure. Two pen
settings the plugin never sets anywhere — arrow size and speckle size — are
an untested channel. This particular figure draws neither, so nothing here
proves what would happen to a figure that did.

## Where this demonstration substituted something

A demonstration that overstates its coverage is worse than none, so here is
exactly what was faked and what was not.

**The dialogs were replaced; the code behind them was not.** Praat's
dialogs need a person to click them, so the four scripts involved — the
demo generator, the table editor, the ANOVA command and the save panel —
were each rebuilt as a copy with only the dialog boxes cut out and replaced
by a scripted record of which buttons were pressed and what was typed. The
remaining body of each copy is byte-for-byte identical to the shipped
script. That was verified for all four, and the cut-out regions were kept
so they can be inspected.

**The cell edit ran through the real editor, not around it.** This is the
substitution most worth being precise about. The scripted button record
supplied exactly what a person would have supplied to the editor's main
dialog — column 3, row 1, the value 4242, and the "Set" button — and the
plugin's own cell-writing code then did the work. The edit was not
performed by reaching past the editor and setting the value directly. What
was not exercised is the dialog widget itself.

**The recording was stopped from a script rather than from its menu
command.** The shipped "save the recording" command cannot be run from a
script: doing so crashes Praat 6.6.30 outright. The recording was therefore
flushed and closed by calling the same two operations that command calls
underneath. This is a limitation of driving Praat without a person present,
not a defect in the plugin.

**The save step could not be originated without a display.** Attempting to
run the save panel headlessly crashed Praat 6.6.30. For the purpose of
checking that saving records and replays correctly, the step was
constructed by hand to match exactly what the plugin writes, and the replay
of it is genuine — it really did write eight files in one test and seven in
another. But the act of a person pressing Save was not itself performed
without a screen.

**The replays staged the missing edit with a direct value write.** Since the
recorded script contains no edit step, the four faithful replays had to put
4242 into the cell themselves before running the script. They did this
directly rather than through the editor, because the point of those legs
was to test the script, not the editor.

**One control measurement was initially void and was re-done.** The first
attempt to show that a changed typeface affects a drawing measured zero
difference. That turned out to be an artefact of the settings that control
run started from, not evidence that typeface does not matter. A fresh
direct probe under clean settings confirms it does: Helvetica against
Palatino differs by 26,238 pixels, and all four typefaces tested produce
distinct images. The table above uses the re-done number.

## The smallest change that would close the largest gap

Record a step when the data changes.

Everything else in this report is a documentation gap or a minor loss of
provenance. The edit is the only gap that makes a replayed script produce a
different answer while looking like it produced the same one. It is also
the only gap a reader has no way to detect: the missing demonstration table
is visible if you look at what is open, and the missing file is described
in the script's own header, but a changed cell leaves no trace anywhere.

The narrow version — a step that reproduces the edit — is the complete fix
but the larger build. The much smaller version captures most of the value:
**when a recording is running and the data is modified, write a visible
warning into the recorded script.** A few lines near the top saying that
the table was edited during the recording, and that the script will only
reproduce the recorded numbers if the same edits are applied first, would
convert a silent wrong answer into an obvious question. That is the
difference between a colleague quietly publishing the wrong F ratio and a
colleague sending an email.

The same reasoning applies, more weakly, to the file that was opened. The
plugin already contains the sentence it would use — *"Loaded {1} as
supplied. Nothing below modifies it."* — sitting unused in its phrase
table. Recording the file's path alongside the table's name would let a
script say which data it meant, not merely what that data was called.

Ranked by what it buys per unit of work:

1. **Warn when the data was edited during a recording.** Turns a silent
   wrong answer into a visible caution. Largest gap, smallest change.
2. **Record the opened file's path, not just the table's name.** The
   wording already exists. Removes the "which file was this?" problem.
3. **Write the resolved axis range as a comment that says it is advisory.**
   One word of wording; prevents the comment reading as a promise.
4. **Carry the provenance line through to replayed reports.** Cosmetic, and
   the only thing standing between a replayed report and an identical one.
