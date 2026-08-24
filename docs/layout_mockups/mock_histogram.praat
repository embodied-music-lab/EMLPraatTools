beginPause: "Histogram -- Column Mapping (Advanced)"
    comment: "📋 Columns"
    optionmenu: "Value column", 1
        option: "f0"
    boolean: "Use group column", 1
    optionmenu: "Group column", 1
        option: "group"
    optionmenu: "Group order", 1
        option: "Table order"
        option: "Alphabetical"
    comment: "📊 Histogram"
    integer: "Bin count (0 = auto)", 0
    real: "Frequency maximum (0 = auto)", 0
    optionmenu: "Display mode", 3
        option: "Overlaid"
        option: "Stacked"
        option: "Faceted"
    comment: "📈 Analysis · comparisons appear as a matrix panel below the plot"
    boolean: "Annotate results on graph", 1
    optionmenu: "Comparison", 2
        option: "Parametric"
        option: "Nonparametric"
    optionmenu: "Significance style", 1
        option: "stars"
        option: "p-value"
        option: "both"
    boolean: "Show nonsignificant", 0
    boolean: "Show effect sizes", 0
    real: "Alpha", 0.05
    comment: "📐 Value axis (both 0 = auto)"
    real: "left Value (left/right)", 0
    real: "right Value (left/right)", 0
    comment: "🏷️ Labels · %italic #bold ^super _sub · \% and a space prints %"
    sentence: "left Axis labels (x / y; blank = auto)", ""
    sentence: "right Axis labels (x / y; blank = auto)", ""
    comment: "🎨 Layout"
    optionmenu: "Legend placement (when drawn)", 1
        option: "Auto"
        option: "Right of plot"
        option: "Below plot"
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
writeFileLine: "mock_histogram_done.txt", clicked
