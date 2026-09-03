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
        ... 200 + g * 80 * 0.235 + (st / 2147483648 - 0.5) * 80
    endfor
endfor
Erase all
include /home/claude/repo/harness/drawlayer/out/emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/drawlayer/out/pic_replay_same.png"
appendFileLine: "/home/claude/repo/harness/drawlayer/out/DRAWLAYER.tsv", "replay_same_min", tab$,
... fixed$ (emlDrawViolinPlot.yMin, 4)
appendFileLine: "/home/claude/repo/harness/drawlayer/out/DRAWLAYER.tsv", "replay_same_max", tab$,
... fixed$ (emlDrawViolinPlot.yMax, 4)
