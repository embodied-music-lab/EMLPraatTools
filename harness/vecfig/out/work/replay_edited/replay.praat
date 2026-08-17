Text writing preferences: "UTF-8"
t = Create Table with column names: "vt", 0, "grp val"
st = 20260817
r = 0
for g from 1 to 3
    for k from 1 to 20
        st = (1103515245 * st + 12345) mod 2147483648
        r = r + 1
        Append row
        Set string value: r, "grp", "G" + string$ (g)
        Set numeric value: r, "val", 200 + g * 18 + (st / 2147483648 - 0.5) * 80
    endfor
endfor
include /home/claude/EMLPraatTools/harness/vecfig/out/record/edited.praat
