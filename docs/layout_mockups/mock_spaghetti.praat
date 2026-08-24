beginPause: "Spaghetti Plot -- Column Mapping"
    comment: "📋 Columns"
    optionmenu: "Value column (Y-axis)", 1
        option: "f0"
    optionmenu: "Condition column (X-axis)", 1
        option: "condition"
    optionmenu: "Subject column (participant ID)", 1
        option: "subject"
    boolean: "Use group column", 0
    optionmenu: "Group column (colors lines)", 1
        option: "group"
    optionmenu: "Group order", 1
        option: "Table order"
        option: "Alphabetical"
    comment: "📐 Y-axis (both 0 = auto)"
    real: "left Value (bottom/top)", 0
    real: "right Value (bottom/top)", 0
    comment: "🏷️ Labels · %italic #bold ^super _sub · \% and a space prints %"
    sentence: "left Axis labels (x / y; blank = auto)", ""
    sentence: "right Axis labels (x / y; blank = auto)", ""
    comment: "🎨 Layout"
    boolean: "Show mean overlay", 1
    optionmenu: "Line style", 1
        option: "Solid"
        option: "Dotted"
        option: "Dashed"
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
writeFileLine: "mock_spaghetti_done.txt", clicked
