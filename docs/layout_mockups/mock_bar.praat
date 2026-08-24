beginPause: "Bar Chart -- Column Mapping (Advanced)"
    comment: "📋 Columns"
    optionmenu: "Value column", 1
        option: "pre"
        option: "post"
    optionmenu: "Error bars", 2
        option: "None"
        option: "SD"
        option: "SE"
        option: "95% CI"
    optionmenu: "Group column", 1
        option: "group"
    optionmenu: "Group order", 1
        option: "Table order"
        option: "Alphabetical"
    comment: "📈 Analysis"
    boolean: "Annotate results on graph", 1
    optionmenu: "Test type", 2
        option: "Parametric"
        option: "Nonparametric"
    optionmenu: "Adjustment method (nonparametric post-hoc only)", 1
        option: "Holm"
        option: "Bonferroni"
        option: "None"
    optionmenu: "Significance style", 1
        option: "stars"
        option: "p-value"
        option: "both"
    boolean: "Show nonsignificant", 0
    boolean: "Show effect sizes", 0
    optionmenu: "Annotation layout", 1
        option: "Auto"
        option: "Brackets"
        option: "Matrix"
    real: "Alpha", 0.05
    comment: "📐 Y-axis (both 0 = auto)"
    real: "left Value (bottom/top)", 0
    real: "right Value (bottom/top)", 0
    comment: "🏷️ Labels · %italic #bold ^super _sub · \% and a space prints %"
    sentence: "left Axis labels (x / y; blank = auto)", ""
    sentence: "right Axis labels (x / y; blank = auto)", ""
    comment: "🎨 Layout"
    optionmenu: "Gridline mode", 1
        option: "Horizontal"
        option: "Off"
    boolean: "Show inner box", 1
    optionmenu: "Show axis names", 1
        option: "Both"
        option: "Neither"
    optionmenu: "Show ticks", 1
        option: "Both"
        option: "Neither"
    optionmenu: "Show axis values", 1
        option: "Both"
        option: "Neither"
    optionmenu: "Font", 1
        option: "Helvetica"
        option: "Times"
    optionmenu: "Output DPI", 2
        option: "150"
        option: "300"
clicked = endPause: "Go Back", "Quit", "Advanced", "Draw", 4, 1
writeFileLine: "mock_bar_done.txt", clicked
