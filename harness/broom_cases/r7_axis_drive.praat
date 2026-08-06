# R7 — drive the small-range measure and RECORD the axis it produced.
#
# R7 was the one red-path case never driven: "an axis case, judged from a
# figure". It is finding D88 as a data case — contact quotient in the 0.4-0.6
# band, where a roundTo of 10 gives a 0-10 axis and the data occupies 2% of
# the panel. The D88 fix made every call site compute its step from
# @emlComputeNiceStep. This drives the exact red-path table through a real
# draw procedure, writes the resulting axis to a capture v07 can read, and
# saves the figure as visual evidence.

include /home/claude/EMLPraatTools/plugin/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-extract.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-output.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-draw-procedures.praat

# Praat writes UTF-16 on Linux even under --utf8, and capture() in the R
# harness reads UTF-8. Without this the capture is unreadable and every label
# lookup fails with "not found".
Text writing preferences: "UTF-8"

@emlInitDrawingDefaults

src$ = environment$ ("EML_R7_INPUT")
out$ = environment$ ("EML_R7_OUT")
fig$ = environment$ ("EML_R7_FIG")

wide = Read Table from comma-separated file: src$
selectObject: wide
nS = Get number of rows

# Reshape to long: one row per singer per condition, which is what the
# spaghetti plot consumes.
long = Create Table with column names: "r7_long", nS * 2, "singer cond CQ"
for i to nS
    selectObject: wide
    s$ = Get value: i, "singer"
    a$ = Get value: i, "CQ_pre"
    b$ = Get value: i, "CQ_post"
    selectObject: long
    Set string value: i, "singer", s$
    Set string value: i, "cond", "pre"
    Set string value: i, "CQ", a$
    Set string value: nS + i, "singer", s$
    Set string value: nS + i, "cond", "post"
    Set string value: nS + i, "CQ", b$
endfor

Erase all
@emlDrawSpaghettiPlot: long, "R7 — contact quotient, pre vs post",
... "Condition", "Contact quotient", 6, 4, "color", 1,
... "cond", "CQ", "singer", "", 1, 0, 0

@emlAssertFullViewport
Select outer viewport: 0, 6, 0, 4
select all
n = numberOfSelected ()
if n > 0
    Remove
endif
Select outer viewport: 0, 6, 0, 4
Save as 300-dpi PNG file: fig$

# The drawn y-axis, as the plot actually used it.
axMin = emlDrawSpaghettiPlot.yMin
axMax = emlDrawSpaghettiPlot.yMax
dataMin = 0.401
dataMax = 0.548
span = axMax - axMin
frac = (dataMax - dataMin) / span

txt$ = "EML R7 — small-range measure axis drive" + newline$
txt$ = txt$ + "Table               r7_small_range_measure" + newline$
txt$ = txt$ + "Data column         CQ" + newline$
txt$ = txt$ + "axis min            " + fixed$ (axMin, 6) + newline$
txt$ = txt$ + "axis max            " + fixed$ (axMax, 6) + newline$
txt$ = txt$ + "axis span           " + fixed$ (span, 6) + newline$
txt$ = txt$ + "data min            " + fixed$ (dataMin, 6) + newline$
txt$ = txt$ + "data max            " + fixed$ (dataMax, 6) + newline$
txt$ = txt$ + "data fraction       " + fixed$ (frac, 6) + newline$
writeFile: out$, txt$
writeInfoLine: txt$
