select all
n = numberOfSelected ()
id = 0
for i from 1 to n
    if index (selected$ (i), "demo_normality") > 0
        id = selected (i)
    endif
endfor
selectObject: id
nr = Get number of rows
writeFileLine: "/home/claude/drive/out/col3.txt", "F0_Hz,shimmer_pct,jitter_pct"
for r from 1 to nr
    a = Get value: r, "F0_Hz"
    b = Get value: r, "shimmer_pct"
    c = Get value: r, "jitter_pct"
    appendFileLine: "/home/claude/drive/out/col3.txt", fixed$ (a, 10), ",", fixed$ (b, 10), ",", fixed$ (c, 10)
endfor
