# ---------------------------------------------------------------------------
# harness/linestyle/data.praat -- THE OBJECTS, AND NOTHING ELSE.
#
# Split out of the fixture the way harness/secondaxis/data.praat is, and for
# the same reason: a recorded script that includes the plugin itself must be
# able to rebuild the data without loading the library a second time.
#
# SIX TYPES STROKE A SERIES and this file makes something for each of them: a
# Table for the line chart, the confidence-band line chart and the spaghetti
# plot; a Sound for the waveform; a Pitch for the contour; a Spectrum and an
# Ltas for the two spectral types.
#
# THE SOUND IS SYNTHETIC AND ITS PITCH IS CONSTANT BY CONSTRUCTION. A recorded
# vowel would make the pixel counts below depend on a WAV file's bytes; a
# 220 Hz tone with one harmonic gives a contour Praat tracks without gaps, a
# waveform with a stroke across the whole panel, and a spectrum with two
# peaks, all of them reproducible from these four lines.
# ---------------------------------------------------------------------------
Create Table with column names: "linestyle", 0, "t v w g id"
for i from 1 to 36
    Append row
    r = Get number of rows
    tt = (i - 1) mod 12 + 1
    Set numeric value: r, "t", tt
    ; A SERIES THAT MOVES ACROSS THE WHOLE PANEL. A stroke that spends the
    ; figure near one value would lay its dots and its dashes down in a short
    ; band, and the run structure this harness measures would be a statement
    ; about the fixture rather than about the pen.
    Set numeric value: r, "v", 100 + tt * 6 + (tt mod 3) * 4
    Set numeric value: r, "w", 40 + tt * 2
    if i <= 12
        Set string value: r, "g", "a"
        Set string value: r, "id", "s" + string$ (tt mod 3 + 1)
    elsif i <= 24
        Set string value: r, "g", "b"
        Set string value: r, "id", "s" + string$ (tt mod 3 + 4)
    else
        Set string value: r, "g", "c"
        Set string value: r, "id", "s" + string$ (tt mod 3 + 7)
    endif
endfor
lsTableId = selected ("Table")

Create Sound from formula: "tone", 1, 0, 0.3, 22050,
... "0.5*sin(2*pi*220*x) + 0.2*sin(2*pi*440*x)"
lsSoundId = selected ("Sound")
To Pitch: 0, 75, 600
lsPitchId = selected ("Pitch")
selectObject: lsSoundId
To Spectrum: "yes"
lsSpectrumId = selected ("Spectrum")
selectObject: lsSoundId
To Ltas: 100
lsLtasId = selected ("Ltas")
