beginPause: "EML Graphs"
    comment: "🖼️ Figure"
    optionmenu: "Graph type", 1
        option: "Line chart"
        option: "Bar chart"
        option: "Scatter plot"
    sentence: "Title (blank = auto from table and columns)", ""
    sentence: "Subtitle", ""
    optionmenu: "Color mode", 1
        option: "Color"
        option: "Grayscale"
    real: "left Figure size (w and h, inches)", 6
    real: "right Figure size (w and h, inches)", 4
    comment: "📄 Page · untick Erase to add to the page already drawn · park the legend Right of plot or Below plot"
    boolean: "Erase page first", 1
    real: "left Panel origin (x and y, inches)", 0
    real: "right Panel origin (x and y, inches)", 0
clicked = endPause: "Go Back", "Quit", "Advanced", "Draw", 4, 1
writeFileLine: "mock_emlgraphs_done.txt", clicked
