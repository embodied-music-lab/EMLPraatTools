beginPause: "Pitch Contour Settings"
    comment: "📐 Axes (both 0 = auto)"
    real: "left Time (left/right)", 0
    real: "right Time (left/right)", 0
    real: "left Frequency (bottom/top)", 0
    real: "right Frequency (bottom/top)", 0
    optionmenu: "Y axis unit", 1
        option: "Hertz"
        option: "Semitones re 100 Hz"
    comment: "🏷️ Labels · %italic #bold ^super _sub · \% and a space prints %"
    sentence: "left Axis labels (x / y; blank = auto)", ""
    sentence: "right Axis labels (x / y; blank = auto)", ""
    comment: "🎵 Pitch analysis (auto-converted from Sound)"
    comment: "Ceiling is doubled internally for the analysis algorithm."
    real: "left Pitch (floor/ceiling, Hz)", 50
    real: "right Pitch (floor/ceiling, Hz)", 800
    comment: "🎨 Layout"
    optionmenu: "Line style", 1
        option: "Solid"
        option: "Dotted"
        option: "Dashed"
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
writeFileLine: "page2_out.txt", "ok ", clicked
