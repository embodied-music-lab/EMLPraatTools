# ---------------------------------------------------------------------------
# harness/boxgeom/data.praat -- THE OBJECTS, AND NOTHING ELSE.
#
# Split out of the fixture the way harness/linestyle/data.praat is, and for
# the same reason: what this harness measures is geometry, so the numbers in
# the table have to be stated once, in a file the case scripts and the
# validator can both point at, rather than buried in a fixture that also sets
# forty form variables.
#
# THE DATA IS CHOSEN SO THAT ITS EXTREMES ARE ROUND NUMBERS. `t` runs 1..12
# and `v` runs 10..120 exactly; the fixture then pins the axis to those same
# numbers, which is what lets the validator assert that the plotted extremes
# REACH the inner box rather than merely sit inside it. Data whose range were
# 10.3714..119.02 would still be inside the box under the defect this harness
# hunts, and the check would have nothing to bite on.
#
# THE SOUND IS SYNTHETIC AND CONSTANT BY CONSTRUCTION, as in
# harness/linestyle: a 220 Hz tone with one harmonic gives a pitch contour
# Praat tracks without gaps, a waveform that strokes the whole panel, and a
# spectrum with two peaks -- all reproducible from these lines and from
# nothing on disk.
# ---------------------------------------------------------------------------
Create Table with column names: "boxgeom", 0, "t v w g id"
for i from 1 to 36
    Append row
    r = Get number of rows
    tt = (i - 1) mod 12 + 1
    Set numeric value: r, "t", tt
    ; v = 10 * tt, so the column spans exactly 10..120 and every value is a
    ; whole multiple of ten. The x extreme and the y extreme therefore land on
    ; the corner of the inner box when the fixture pins the axis to them.
    Set numeric value: r, "v", 10 * tt
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
bgTableId = selected ("Table")

Create Sound from formula: "tone", 1, 0, 0.3, 22050,
... "0.5*sin(2*pi*220*x) + 0.2*sin(2*pi*440*x)"
bgSoundId = selected ("Sound")
To Pitch: 0, 75, 600
bgPitchId = selected ("Pitch")
selectObject: bgSoundId
To Spectrum: "yes"
bgSpectrumId = selected ("Spectrum")
selectObject: bgSoundId
To Ltas: 100
bgLtasId = selected ("Ltas")
