include /home/claude/repo/plugin/stats/eml-core-utilities.praat
include /home/claude/repo/plugin/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin/stats/eml-extract.praat
include /home/claude/repo/plugin/stats/eml-output.praat
include /home/claude/repo/plugin/stats/eml-inferential.praat
include /home/claude/repo/plugin/stats/eml-result-writer.praat
include /home/claude/repo/plugin/stats/eml-record.praat
include /home/claude/repo/plugin/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin/graphs/eml-draw-procedures.praat
include /home/claude/repo/plugin/stats/eml-analysis.praat

leg$ = environment$ ("EML_PA_LEG")
png$ = environment$ ("EML_PA_PNG")

# DETERMINISTIC SOURCE. A pixel comparison across processes cannot be built
# on randomGauss; four sinusoids give the Ltas real structure and the same
# structure every run.
Create Sound from formula: "tone", 1, 0, 1, 44100,
... "0.6*sin(2*pi*220*x) + 0.3*sin(2*pi*640*x)
...  + 0.15*sin(2*pi*1310*x) + 0.08*sin(2*pi*2570*x)"
ltas = To Ltas: 100

@emlInitDrawingDefaults

# THE HOSTILE SESSION. Two settings, nothing else.
if right$ (leg$, 8) = "_hostile"
    Arrow size: 7.5
    Speckle size: 9.0
endif

Erase all
if left$ (leg$, 7) = "witness"
    # A MARK THAT READS THE TWO SETTINGS, PLACED DIRECTLY DOWNSTREAM OF THE
    # THEME. The plugin draws no arrow and no native speckle of its own, so
    # without this leg the assert would be measured only by figures that
    # cannot show it either way.
    @emlSetAdaptiveTheme: 6, 4
    Select outer viewport: 0, 3, 0, 3
    Axes: 0, 10, 0, 10
    Draw arrow: 1, 1, 9, 9
    selectObject: ltas
    Select outer viewport: 3, 6, 0, 3
    Draw: 0, 5000, -20, 80, "no", "Speckles"
    Save as 300-dpi PNG file: png$
elsif left$ (leg$, 3) = "fig"
    # THE FIGURE A USER GETS: curve, poles and speckles, speckles last.
    @emlDrawLTAS: ltas, "Pen assertion", "Frequency (Hz)",
    ... "Sound pressure level (dB/Hz)", 6, 4, "color", 1,
    ... 0, 5000, 0, 0, 1, 0, 1, 1
    @emlAssertFullViewport
    Save as 300-dpi PNG file: png$
else
    exitScript: "penassert: unknown plugin leg " + leg$
endif
writeInfoLine: "leg ", leg$, " ok"
