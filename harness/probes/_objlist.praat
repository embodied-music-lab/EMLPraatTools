writeInfoLine: "OBJECTS"
select all
n = numberOfSelected ()
for i from 1 to n
    appendInfoLine: selected (i), tab$, selected$ (i)
endfor
