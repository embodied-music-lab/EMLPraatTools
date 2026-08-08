# C1 gridline-mode walk — one small numeric Table, enough for both a Scatter
# Plot (two numeric columns) and a Histogram (one numeric column). The walk
# never looks at the figure; the subject is the Gridline mode optionmenu on
# the two dialogs, and this table exists only so both dialogs can be reached.
tid = Create Table with column names: "grid_demo", 24, "x y grp"
for i from 1 to 24
    Set numeric value: i, "x", i
    Set numeric value: i, "y", 40 + (i mod 7) * 3 + (i mod 4)
    if i mod 2 = 1
        Set string value: i, "grp", "A"
    else
        Set string value: i, "grp", "B"
    endif
endfor
selectObject: tid
runScript: preferencesDirectory$
... + "/plugin_EML_Praat_Tools/scripts/eml-graphs.praat"
