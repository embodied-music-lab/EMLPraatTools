select all
n = numberOfSelected ()
id = 0
for i from 1 to n
    if index (selected$ (i), "demo_2groups") > 0
        id = selected (i)
    endif
endfor
selectObject: id
nr = Get number of rows
writeFileLine: "/home/claude/drive/out/col2g.txt", "group,F0_Hz,jitter_pct"
for r from 1 to nr
    g$ = Get value: r, "group"
    a = Get value: r, "F0_Hz"
    b = Get value: r, "jitter_pct"
    appendFileLine: "/home/claude/drive/out/col2g.txt", g$, ",", fixed$ (a, 10), ",", fixed$ (b, 10)
endfor
