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
writeFileLine: "/home/claude/drive/out/col.txt", "F0_Hz"
for r from 1 to nr
    v = Get value: r, "F0_Hz"
    appendFileLine: "/home/claude/drive/out/col.txt", fixed$ (v, 10)
endfor
