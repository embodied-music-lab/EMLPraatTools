select all
n = numberOfSelected ()
id = 0
for i from 1 to n
    nm$ = selected$ (i)
    if index (nm$, "demo_paired") > 0
        id = selected (i)
    endif
endfor
selectObject: id
writeInfoLine: "selected ", id, " ", selected$ (1)
