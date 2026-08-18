include fixture.praat
# ALL FOUR PENS ON ONE PAGE -- the figure Ian is sent.
#
# FOUR PRESSES OF DRAW, not one drawing with four lines on it. Each panel is
# the same line chart with one option changed, laid out with the page
# composition that landed before this change order: the first panel erases the
# page and the other three do not, and each states its own panel origin. So
# the figure is a photograph of the CONTROL, not of the four Praat commands
# underneath it.
#
# The panel titles are taken from the plugin's own @emlLineStyleName, so a
# renamed option renames the label on the picture rather than making it a lie.
@lsSetType: 5
figure_width = 6
figure_height = 4
totalCanvasHeight = 4
for s from 1 to 4
    @emlLineStyleName: s
    title$ = "Line style " + string$ (s) + ": " + emlLineStyleName.word$
    tsLineStyle = s
    if s = 1
        emlPanelOriginX = 0
        emlPanelOriginY = 0
        emlEraseFirst = 1
    elsif s = 2
        emlPanelOriginX = 6
        emlPanelOriginY = 0
        emlEraseFirst = 0
    elsif s = 3
        emlPanelOriginX = 0
        emlPanelOriginY = 4
        emlEraseFirst = 0
    else
        emlPanelOriginX = 6
        emlPanelOriginY = 4
        emlEraseFirst = 0
    endif
    valueMin = 0
    valueMax = 0
    @lsPress
endfor
@lsReport: 4
@lsSave
