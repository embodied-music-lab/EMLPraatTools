form: "absent field probe"
    boolean: "Figure PNG", 1
    boolean: "Also EPS", 0
endform
appendInfoLine: "eps_exists=", variableExists ("also_EPS")
appendInfoLine: "pdf_exists=", variableExists ("also_PDF")
appendInfoLine: "BEFORE"
x = also_PDF
appendInfoLine: "AFTER"
