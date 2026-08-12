# ---------------------------------------------------------------------------
# THE FIXTURE AND THE OPERATION LIST, SHARED BY TWO DRIVERS.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# harness/record_e2e drives these 27 operations WITH a recording running;
# harness/norecord drives the same 27 with the recorder not loaded at all.
# The two answer different questions and must be asking them about the same
# population, so the data and the list live here rather than being written
# down twice and allowed to disagree.
#
# Included by both drivers. Creates: Table voiceA, Sound/Pitch/Spectrum/Ltas
# "tone". Defines: nOps, op$[1..nOps].
# ---------------------------------------------------------------------------
# A fixture every operation below can consume: two numeric columns and a group.
Create Table with column names: "voiceA", 0,
... "spl spl2 grp grp2 grp3 t subj r1 r2 r3 c1 c2 c3"
rngState = 20260812
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .g = (rngState / 2147483648 - 0.5) * 3.4
endproc
for i from 1 to 24
    Append row
    r = Get number of rows
    @rnd
    Set numeric value: r, "spl", 60 + (i mod 4) * 3 + rnd.g
    @rnd
    Set numeric value: r, "spl2", 200 + (i mod 5) * 2 + rnd.g
    Set string value: r, "grp", if i mod 2 = 0 then "x" else "y" fi
    ; A second factor for the two-way and the grouped figures, a third with
    ; three levels for the pairwise path, a time column and a subject id for
    ; the repeated-measures and spaghetti paths, and rater/condition columns
    ; for reliability and Friedman.
    Set string value: r, "grp2", if i mod 3 = 0 then "p" else "q" fi
    ; NESTED, BECAUSE PRAAT'S INLINE CONDITIONAL HAS NO `elsif`. Measured
    ; 12 Aug 2026: `if c then "a" elsif c2 then "b" else "c" fi` fails with
    ; "Expected else, but found a variable name".
    Set string value: r, "grp3",
    ... if i mod 3 = 0 then "a" else if i mod 3 = 1 then "b" else "c" fi fi
    Set numeric value: r, "t", (i mod 6) + 1
    Set numeric value: r, "subj", ((i - 1) mod 4) + 1
    @rnd
    Set numeric value: r, "r1", 5 + rnd.g
    @rnd
    Set numeric value: r, "r2", 5 + rnd.g
    @rnd
    Set numeric value: r, "r3", 5 + rnd.g
    @rnd
    Set numeric value: r, "c1", 10 + rnd.g
    @rnd
    Set numeric value: r, "c2", 12 + rnd.g
    @rnd
    Set numeric value: r, "c3", 14 + rnd.g
endfor

; THE ACOUSTIC OBJECTS. Four of the fourteen hooked draw procedures take a
; Sound, a Pitch, a Spectrum and an Ltas rather than a Table -- which is the
; author's "do not lock into one object type" made concrete, and the only way
; to prove the recorder handles them is to record one.
; A TableOfReal and a Matrix, the two non-acoustic sources the graphs form
; converts to a Table. Two columns of numbers is all the table-shaped figures
; need from them.
Create TableOfReal: "tor", 12, 2
for i from 1 to 12
    Set value: i, 1, 60 + i
    Set value: i, 2, 200 + i * 2
endfor
Create simple Matrix: "mat", 12, 2, "60 + row + col * 3"

Create Sound as pure tone: "tone", 1, 0, 0.4, 44100, 220, 0.4, 0.01, 0.01
selectObject: "Sound tone"
To Pitch: 0, 75, 600
selectObject: "Sound tone"
To Spectrum: "yes"
selectObject: "Sound tone"
To Ltas: 100

nOps = 36
op$[1] = "anova"
op$[2] = "twogroup"
op$[3] = "kw"
op$[4] = "descriptive"
op$[5] = "normality"
op$[6] = "correlation"
op$[7] = "regression"
op$[8] = "pairwise"
op$[9] = "twoway"
op$[10] = "paired"
op$[11] = "reliability"
op$[12] = "rm"
op$[13] = "friedman"
op$[14] = "violin"
op$[15] = "scatter"
op$[16] = "histogram"
op$[17] = "timeseries"
op$[18] = "timeseriesci"
op$[19] = "spaghetti"
op$[20] = "barchart"
op$[21] = "boxplot"
op$[22] = "gviolin"
op$[23] = "gbox"
op$[24] = "waveform"
op$[25] = "f0contour"
op$[26] = "spectrum"
op$[27] = "ltas"
; THE SAME THREE FIGURES REACHED THE WAY MOST USERS REACH THEM: from a Sound,
; with the plugin doing the conversion. Author, 12 Aug 2026 -- "fo, waveform,
; spectrum, and LTAS will all also run from just a sound. They auto convert."
; The four above are handed a ready-made Pitch/Spectrum/Ltas, which is the
; API-level call; these three go through @emlConvertSoundForGraph, which is
; what the menu does and what nothing had ever driven.
op$[28] = "sound2f0"
op$[29] = "sound2spectrum"
op$[30] = "sound2ltas"
; THE OTHER TWO SOURCE TYPES THE FORM CONVERTS FROM. A Spectrum reaches an
; Ltas, a Sound and (through a Sound) a Pitch; a Matrix and a TableOfReal each
; reach a Table. All five conversions carried the same defect and all five are
; driven here, so a future one added to @emlConvertForGraph has an obvious
; place to be driven from.
op$[31] = "spectrum2ltas"
op$[32] = "spectrum2sound"
op$[33] = "spectrum2f0"
op$[34] = "tor2table"
op$[35] = "matrix2table"
; THE GRAPHS -> STATS PATH. Reaching a group comparison by asking a figure
; for its statistical annotation is the second half of a bidirectional design:
; stats can lead to a graph and a graph can lead to stats. Both must record
; the same analysis, and on 12 Aug 2026 only the stats-menu half did.
op$[36] = "bridge"
