t = Create Table with column names: "narrow", 0, "grp val"
st = 20260815
r = 0
for g from 1 to 3
    for k from 1 to 20
        st = (1103515245 * st + 12345) mod 2147483648
        r = r + 1
        Append row
        Set string value: r, "grp", "G" + string$ (g)
        Set numeric value: r, "val",
        ... 1100 + g * 400 * 0.235 + (st / 2147483648 - 0.5) * 400
    endfor
endfor
Erase all
include /home/claude/EMLPraatTools/harness/drawlayer/out/emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/drawlayer/out/pic_replay_wide.png"
appendFileLine: "/home/claude/EMLPraatTools/harness/drawlayer/out/DRAWLAYER.tsv", "replay_wide_min", tab$,
... fixed$ (emlDrawViolinPlot.yMin, 4)
appendFileLine: "/home/claude/EMLPraatTools/harness/drawlayer/out/DRAWLAYER.tsv", "replay_wide_max", tab$,
... fixed$ (emlDrawViolinPlot.yMax, 4)
