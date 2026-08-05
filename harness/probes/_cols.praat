selectObject: 19
n = Get number of columns
writeInfoLine: "cols ", n
for i from 1 to n
    lab$ = Get column label: i
    appendInfoLine: i, tab$, lab$
endfor
