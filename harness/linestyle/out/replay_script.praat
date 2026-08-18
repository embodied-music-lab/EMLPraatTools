#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# Tue Aug 18 22:32:43 2026  --  recorded on Praat 6.6.30
# Input: Sound tone
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    /home/claude/EMLPraatTools/plugin_EML_StatsGraphs
#   Praat 7.x  Linux    ~/.config/praat/plugin_EML_StatsGraphs
#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EML_StatsGraphs
#   Windows    ~/Praat/plugin_EML_StatsGraphs
#   Not sure?  Run  writeInfoLine: preferencesDirectory$
#
# A version guard cannot help here: `include` is refused inside an
# if-block, so the file cannot choose its own path at run time.
# The barrel eml-lib-stats.praat will NOT work in place of this
# list: its own relative includes resolve against THIS file's
# folder, not its own.
# ------------------------------------------------------------

include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-extract.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-output.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-psychometrics.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-categorical.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-record.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include /home/claude/EMLPraatTools/plugin_EML_StatsGraphs/stats/eml-analysis.praat

@emlInitDrawingDefaults
@emlClearAnnotations
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

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Sound tone.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Sound tone"   ; run 1, step 1 (draw)
axisYMin     = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax     = 0.0   ; on the recorded data it resolved to -0.7000 .. 0.7000
eraseFirst   = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 1 (draw)
panelOriginX = 0   ; inches from the left of the page to this panel's corner -- run 1, step 1 (draw)
panelOriginY = 0   ; inches from the top of the page to this panel's corner -- run 1, step 1 (draw)
lineStyle    = 3   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
secondAxisOn = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 1 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# [MISSING PHRASE: drawstep.intent]

annotate = 0
emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
@emlDrawWaveform: data, "Line style", "Time (s)", "Value", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


Select outer viewport: 0, 6, 0, 4
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/linestyle/out/replay.png"
