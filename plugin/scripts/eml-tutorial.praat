# ============================================================================
# EML Stats Tutorial — Interactive Statistics Guide
# ============================================================================
# Demo window tutorial for learning statistics with voice science data.
# Uses the EML Demo Window layout engine and EML Stats library.
#
# Part of plugin_EML_Praat_Tools.
# Location: plugin_EML_Praat_Tools/scripts/eml-tutorial.praat
#
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Version: 0.19
# Date: 2 August 2026
#
# v0.19: Item 4 — neutralised the include of tutorial/eml-demo-procedures.praat.
#        That directory has never been shipped with this plugin, so every page
#        renderer here calls undefined procedures (@emlClearPage, @emlDrawGuides,
#        @emlPlaceBody, ...). The menu registration in setup.praat has been
#        removed; running this file directly now exits with an explanation
#        instead of "Procedure not found". Restore the include and the
#        setup.praat entry once tutorial/eml-demo-procedures.praat ships.
# ============================================================================

# ============================================================================
# INCLUDES
# ============================================================================
# include ../tutorial/eml-demo-procedures.praat
exitScript: "EML Interactive Tutorial is not available in this build: its layout engine (tutorial/eml-demo-procedures.praat) is not shipped with the plugin."

showGrid = 1

# ============================================================================
# TYPOGRAPHY + STEP SYSTEM
# ============================================================================
bodySize = 14
captionSize = 11
subheadSize = 17
headingSize = 20
titleSize = 28
heroSize = 36
numSize = 60
lineHeightFactor = 0.32
ambientSize = bodySize
sans$ = "Helvetica"
serif$ = "Times"
mono$ = "Courier"

clearanceRatio = 0.3
stepRatio = 1.0 + clearanceRatio

heroStep = heroSize * lineHeightFactor * stepRatio
titleStep = titleSize * lineHeightFactor * stepRatio
headingStep = headingSize * lineHeightFactor * stepRatio
subheadStep = subheadSize * lineHeightFactor * stepRatio
captionStep = captionSize * lineHeightFactor * stepRatio
bodyLineH = bodySize * lineHeightFactor
codeSize = 12
codeLineH = codeSize * lineHeightFactor
bulletStep = bodyLineH * 2.5

# ============================================================================
# GRID
# ============================================================================
zProgressBottom = 97.5
zProgressTop = 98.5
zPageCounterY = 96
zContentTop = 90
zContentBottom = 12
zNavTop = 10
zNavY = 4
topPad = 3
mL = 6
mR = 94
mB = 8
colLEnd = 46
colR = 52
bodyRight = 78
accentLen = 35
accentWeight = 10
gridColor$ = "{0.75, 0.82, 0.92}"
tickColor$ = "{0.85, 0.40, 0.40}"

# ============================================================================
# PALETTE
# ============================================================================
# UI colors: stock greyscales matching EML Graphs adaptive theme
bg$ = "{0.95, 0.95, 0.95}"
ink$ = "{0.1, 0.1, 0.1}"
text$ = "{0.3, 0.3, 0.3}"
light$ = "{0.6, 0.6, 0.6}"
faint$ = "{0.85, 0.85, 0.85}"
accent$ = "{0.00, 0.45, 0.70}"
accentPale$ = "{0.70, 0.83, 0.91}"
warmGray$ = "{0.90, 0.90, 0.90}"
embossShadow$ = "{0.90, 0.90, 0.90}"
# Data group colors — Okabe-Ito (matches EML Graphs palette)
groupA$ = "{0.00, 0.45, 0.70}"
groupB$ = "{0.90, 0.62, 0.00}"
groupC$ = "{0.00, 0.62, 0.45}"
# Data annotation colors
meanLine$ = "{0.85, 0.30, 0.30}"
medianLine$ = "{0.30, 0.75, 0.40}"
annotGray$ = "{0.75, 0.75, 0.75}"
progressBg$ = "{0.90, 0.90, 0.90}"
progressFill$ = "{0.00, 0.45, 0.70}"
arrowColor$ = "{0.5, 0.5, 0.5}"

# ============================================================================
# IMAGE DIRECTORY
# ============================================================================
# Resolve path to pre-rendered tutorial figures.
# Strategy 1: installed plugin in preferences directory
# Strategy 2: development layout (running from scripts/)
tutorialImgDir$ = ""
tryPath$ = preferencesDirectory$ + "/plugin_EML_Praat_Tools/tutorial/images/"
if fileReadable (tryPath$ + "placeholder.txt")
    tutorialImgDir$ = tryPath$
else
    tryPath$ = defaultDirectory$ + "/../tutorial/images/"
    if fileReadable (tryPath$ + "placeholder.txt")
        tutorialImgDir$ = tryPath$
    endif
endif

# ============================================================================
# CONTENT LOADER
# ============================================================================
# Reads a structured text file and populates pg[N]_field$ globals.
# Format: PAGE N / field: value / # comments / blank lines ignored.

procedure emlLoadContent: .path$
    if not fileReadable (.path$)
        exitScript: "Content file not found: " + .path$
    endif
    .stringsId = Read Strings from raw text file: .path$
    .nStrings = Get number of strings
    .pageNum = 0
    .maxPage = 0
    for .i from 1 to .nStrings
        selectObject: .stringsId
        .line$ = Get string: .i
        # Skip blank lines and comments
        if .line$ = "" or left$ (.line$, 1) = "#"
            goto LOAD_NEXT_LINE
        endif
        # PAGE header
        if left$ (.line$, 5) = "PAGE "
            .pageNum = number (right$ (.line$, length (.line$) - 5))
            if .pageNum > .maxPage
                .maxPage = .pageNum
            endif
            goto LOAD_NEXT_LINE
        endif
        # Parse field: value
        .fieldName$ = ""
        .value$ = ""
        .colonPos = index (.line$, ": ")
        if .colonPos > 0
            .fieldName$ = left$ (.line$, .colonPos - 1)
            .remain = length (.line$) - .colonPos - 1
            if .remain > 0
                .value$ = right$ (.line$, .remain)
            endif
        elsif right$ (.line$, 1) = ":"
            .fieldName$ = left$ (.line$, length (.line$) - 1)
        endif
        if .fieldName$ <> "" and .pageNum > 0
            # Numeric fields
            if .fieldName$ = "nLines" or .fieldName$ = "nBullets"
                ... or .fieldName$ = "nOptions" or .fieldName$ = "nImages"
                pg'.pageNum'_'.fieldName$' = number (.value$)
            else
                # Sanitize special characters for demo text rendering
                # Skip code fields — they display literal Praat syntax
                if left$ (.fieldName$, 4) <> "code"
                    .value$ = replace$ (.value$, "_", "\_ ", 0)
                    .value$ = replace$ (.value$, "%", "\% ", 0)
                    .value$ = replace$ (.value$, "#", "\# ", 0)
                    .value$ = replace$ (.value$, "^", "\^ ", 0)
                endif
                pg'.pageNum'_'.fieldName$'$ = .value$
            endif
        endif
        label LOAD_NEXT_LINE
    endfor
    removeObject: .stringsId
endproc

# ============================================================================
# LOAD CONTENT
# ============================================================================
# Resolve path to content file, then load it.
contentPath$ = ""
tryPath$ = preferencesDirectory$ + "/plugin_EML_Praat_Tools/tutorial/module1-content.txt"
if fileReadable (tryPath$)
    contentPath$ = tryPath$
else
    tryPath$ = defaultDirectory$ + "/../tutorial/module1-content.txt"
    if fileReadable (tryPath$)
        contentPath$ = tryPath$
    endif
endif

if contentPath$ = ""
    exitScript: "Cannot find module1-content.txt in plugin or development directories."
endif

@emlLoadContent: contentPath$
totalPages = emlLoadContent.maxPage

# ============================================================================
# STATE
# ============================================================================
currentPage = 1
running = 1
demoWindowTitle: "EML Stats Tutorial"


# ============================================================================
# TEMPLATE: home
# ============================================================================
procedure emlTplHome: .n
    @emlClearPage
    @emlDrawGuides
    demo Paint circle: accentPale$, 88, 8, 30
    .y = zContentTop - topPad
    @emlPlaceHero: .y, pg'.n'_heroLine1$
    .y = .y - heroSize * lineHeightFactor
    @emlPlaceHero: .y, pg'.n'_heroLine2$
    .y = emlPlaceHero.nextY
    @emlPlaceBodyLine: .y, pg'.n'_sub1$
    .y = emlPlaceBodyLine.nextY
    @emlPlaceBodyLine: .y, pg'.n'_sub2$
    .y = .y - captionStep * 2
    @emlGuideTick: .y
    for .i from 1 to 10
        if .i < 10
            .num$ = "0" + string$ (.i)
        else
            .num$ = string$ (.i)
        endif
        .name$ = pg'.n'_mod'.i'$
        @emlPlaceModuleListItem: .y, .num$, .name$
        .y = emlPlaceModuleListItem.nextY
    endfor
    @emlDrawNav: .n, totalPages, 0
    @emlResetSans
    .done = 0
    while .done = 0
        demoWaitForInput ()
        if demoKeyPressed ()
            .k$ = demoKey$ ()
            if .k$ = "q" or .k$ = "Q"
                running = 0
                .done = 1
            elsif .k$ = "→" or .k$ = " "
                currentPage = currentPage + 1
                .done = 1
            endif
        elsif demoClicked ()
            if demoClickedIn (88, 100, 0, 10)
                currentPage = currentPage + 1
                .done = 1
            endif
        endif
    endwhile
endproc

# ============================================================================
# TEMPLATE: titleCard
# ============================================================================
procedure emlTplTitleCard: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceModuleNum: .y, pg'.n'_moduleNum$
    @emlPlacePartLabel: .y, pg'.n'_partLabel$
    # Cross-type: title is larger, governs spacing
    .y = .y - titleStep
    @emlPlaceTextAccent: .y, mL, titleSize, pg'.n'_title$
    .y = emlPlaceTextAccent.nextY
    @emlPlaceBodyLine: .y, pg'.n'_sub1$
    .y = emlPlaceBodyLine.nextY
    @emlPlaceBodyLine: .y, pg'.n'_sub2$
endproc

# ============================================================================
# TEMPLATE: textPage
# ============================================================================
procedure emlTplTextPage: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceTextAccent: .y, mL, headingSize, pg'.n'_heading$
    .y = emlPlaceTextAccent.nextY
    @emlPlaceBody: .y, mB, bodyRight, text$, pg'.n'_body$
    .y = emlPlaceBody.nextY
    @emlPlaceBody: .y, mB, bodyRight, accent$, pg'.n'_keyQ$
endproc

# ============================================================================
# TEMPLATE: textImage
# ============================================================================
procedure emlTplTextImage: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    # Image — left column
    @emlDrawImage: mL, colLEnd, zContentBottom, .y + 1, pg'.n'_imageLabel$
    # Text — right column
    @emlPlaceTextAccent: .y, colR, headingSize, pg'.n'_heading$
    .y = emlPlaceTextAccent.nextY
    @emlPlaceBody: .y, colR, mR, text$, pg'.n'_body$
    .y = emlPlaceBody.nextY
    @emlPlaceBody: .y, colR, mR, text$, pg'.n'_callout$
endproc

# ============================================================================
# TEMPLATE: fullImage
# ============================================================================
procedure emlTplFullImage: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    # Image — centered, full width
    .imgBottom = .y - 50
    @emlDrawImage: mL, mR, .imgBottom, .y, pg'.n'_imageLabel$
    .y = .imgBottom - captionStep
    @emlPlaceBody: .y, mB, 80, text$, pg'.n'_caption$
endproc

# ============================================================================
# TEMPLATE: multiImage
# ============================================================================
procedure emlTplMultiImage: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceTextAccent: .y, mL, headingSize, pg'.n'_heading$
    .y = emlPlaceTextAccent.nextY
    # Three equal images: 8-32, 36-60, 64-88
    .imgTop = .y
    .imgBottom = .imgTop - 26
    @emlDrawImage: 8, 32, .imgBottom, .imgTop, pg'.n'_imgLabel1$
    @emlDrawImage: 36, 60, .imgBottom, .imgTop, pg'.n'_imgLabel2$
    @emlDrawImage: 64, 88, .imgBottom, .imgTop, pg'.n'_imgLabel3$
    .y = .imgBottom - captionStep
    @emlPlaceCaption: .y, 20, "centre", pg'.n'_subLabel1$
    @emlPlaceCaption: .y, 48, "centre", pg'.n'_subLabel2$
    @emlPlaceCaption: .y, 76, "centre", pg'.n'_subLabel3$
    .y = emlPlaceCaption.nextY - captionStep
    @emlPlaceBody: .y, mB, 72, text$, pg'.n'_body$
endproc

# ============================================================================
# TEMPLATE: interactive
# ============================================================================
procedure emlTplInteractive: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceTitle: .y, pg'.n'_q1$
    .y = emlPlaceTitle.nextY
    @emlPlaceTitle: .y, pg'.n'_q2$
    .y = emlPlaceTitle.nextY
    # Options
    .optStep = subheadStep
    for .i from 1 to pg'.n'_nOptions
        .letter$ = pg'.n'_optLetter'.i'$
        .label$ = pg'.n'_optLabel'.i'$
        @emlPlaceOption: .y, .letter$, .label$
        .y = emlPlaceOption.nextY
    endfor
    @emlPlaceCaption: .y, mB, "left", "Press A, B, or C."
    .ansY = .y - captionStep * 2
    # Input loop
    @emlResetSans
    .phase = 1
    while .phase > 0
        demoWaitForInput ()
        if demoKeyPressed ()
            .k$ = demoKey$ ()
            if .phase = 1
                .ansIdx = 0
                if .k$ = "a" or .k$ = "A"
                    .ansIdx = 1
                elsif .k$ = "b" or .k$ = "B"
                    .ansIdx = 2
                elsif .k$ = "c" or .k$ = "C"
                    .ansIdx = 3
                elsif .k$ = "→" or .k$ = " "
                    currentPage = currentPage + 1
                    .phase = 0
                elsif .k$ = "←"
                    currentPage = currentPage - 1
                    if currentPage < 1
                        currentPage = 1
                    endif
                    .phase = 0
                elsif .k$ = "q" or .k$ = "Q"
                    running = 0
                    .phase = 0
                endif
                if .ansIdx > 0
                    .ansText$ = pg'.n'_answer'.ansIdx'$
                    @emlPlaceBody: .ansY, mB, 70, text$, .ansText$
                    .phase = 2
                endif
            elsif .phase = 2
                if .k$ = "→" or .k$ = " "
                    currentPage = currentPage + 1
                    .phase = 0
                elsif .k$ = "←"
                    currentPage = currentPage - 1
                    if currentPage < 1
                        currentPage = 1
                    endif
                    .phase = 0
                elsif .k$ = "q" or .k$ = "Q"
                    running = 0
                    .phase = 0
                endif
            endif
        elsif demoClicked ()
            if demoClickedIn (0, 12, 0, zNavTop) and currentPage > 1
                currentPage = currentPage - 1
                .phase = 0
            elsif demoClickedIn (88, 100, 0, zNavTop)
                currentPage = currentPage + 1
                .phase = 0
            endif
        endif
    endwhile
endproc

# ============================================================================
# TEMPLATE: animation (placeholder)
# ============================================================================
procedure emlTplAnimation: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceHeading: .y, pg'.n'_heading$
    .y = emlPlaceHeading.nextY
    # Drawing area placeholder — left two-thirds
    @emlDrawImage: mL, 66, zContentBottom + 2, .y,
    ... "[Animation Area]"
    # Commentary — right column
    @emlPlaceBody: .y, 70, mR, text$, pg'.n'_commentary$
endproc

# ============================================================================
# TEMPLATE: summary
# ============================================================================
procedure emlTplSummary: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceTextAccent: .y, mL, headingSize, pg'.n'_heading$
    .y = emlPlaceTextAccent.nextY
    for .i from 1 to pg'.n'_nBullets
        .bText$ = pg'.n'_bullet'.i'$
        @emlPlaceBullet: .y, mB + 4, 76, .bText$
        .y = emlPlaceBullet.nextY
    endfor
endproc

# ============================================================================
# TEMPLATE: textTree
# ============================================================================
procedure emlTplTextTree: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceTextAccent: .y, mL, headingSize, pg'.n'_heading$
    .y = emlPlaceTextAccent.nextY
    @emlPlaceSubhead: .y, pg'.n'_rootQ$
    .y = emlPlaceSubhead.nextY
    # Tree indent levels
    .l1 = mB + 6
    .l2 = mB + 14
    .l3 = mB + 22
    .sectionGap = bodyLineH * stepRatio * 0.5
    # Branch 1
    @emlPlaceTreeBranch: .y, .l1, pg'.n'_branch1$
    .y = emlPlaceTreeBranch.nextY
    @emlPlaceTreeLeaf: .y, .l2, pg'.n'_branch1leaf$
    .y = emlPlaceTreeLeaf.nextY - .sectionGap
    # Branch 2
    @emlPlaceTreeBranch: .y, .l1, pg'.n'_branch2$
    .y = emlPlaceTreeBranch.nextY
    @emlPlaceTreeSub: .y, .l2, pg'.n'_sub2a$
    .y = emlPlaceTreeSub.nextY
    @emlPlaceTreeLeaf: .y, .l3, pg'.n'_leaf2a$
    .y = emlPlaceTreeLeaf.nextY
    @emlPlaceTreeSub: .y, .l2, pg'.n'_sub2b$
    .y = emlPlaceTreeSub.nextY
    @emlPlaceTreeLeaf: .y, .l3, pg'.n'_leaf2b$
    .y = emlPlaceTreeLeaf.nextY
    @emlPlaceTreeSub: .y, .l2, pg'.n'_sub2c$
    .y = emlPlaceTreeSub.nextY
    @emlPlaceTreeLeaf: .y, .l3, pg'.n'_leaf2c$
    .y = emlPlaceTreeLeaf.nextY - .sectionGap
    # Branch 3
    @emlPlaceTreeBranch: .y, .l1, pg'.n'_branch3$
    .y = emlPlaceTreeBranch.nextY
    @emlPlaceTreeLeaf: .y, .l2, pg'.n'_branch3leaf$
endproc

# ============================================================================
# TEMPLATE: codePage
# ============================================================================
procedure emlTplCodePage: .n
    @emlClearPage
    @emlDrawNav: .n, totalPages, 1
    @emlDrawGuides
    .y = zContentTop - topPad
    @emlPlaceTextAccent: .y, mL, headingSize, pg'.n'_heading$
    .y = emlPlaceTextAccent.nextY
    # Body text (skip if empty)
    if pg'.n'_body$ <> ""
        @emlPlaceBody: .y, mB, bodyRight, text$, pg'.n'_body$
        .y = emlPlaceBody.nextY
    endif
    # Code block geometry — derived from typographic scale
    .codePad = codeLineH * clearanceRatio
    .codeInset = mB - mL
    .codeLineStep = codeLineH * stepRatio
    .codeBlockH = pg'.n'_nLines * .codeLineStep + .codePad * 2
    .codeTop = .y
    .codeBottom = .codeTop - .codeBlockH
    demo Paint rectangle: warmGray$, mB, bodyRight, .codeBottom, .codeTop
    # Code lines
    .lineY = .codeTop - .codePad
    for .i from 1 to pg'.n'_nLines
        .lineText$ = pg'.n'_code'.i'$
        @emlPlaceCodeLine: .lineY, mB + .codeInset, .lineText$
        .lineY = emlPlaceCodeLine.nextY
    endfor
    .y = .codeBottom - captionStep
    # Info window callout
    @emlPlaceCaption: .y, mB, "left", pg'.n'_infoCallout$
    # Input loop — I key copies code to Info window
    @emlResetSans
    .done = 0
    while .done = 0
        demoWaitForInput ()
        if demoKeyPressed ()
            .k$ = demoKey$ ()
            if .k$ = "i" or .k$ = "I"
                writeInfoLine: "# === COPY FROM HERE ==="
                for .j from 1 to pg'.n'_nLines
                    .rawLine$ = pg'.n'_code'.j'$
                    appendInfoLine: .rawLine$
                endfor
                appendInfoLine: "# === TO HERE ==="
            elsif .k$ = "→" or .k$ = " "
                currentPage = currentPage + 1
                .done = 1
            elsif .k$ = "←"
                currentPage = currentPage - 1
                if currentPage < 1
                    currentPage = 1
                endif
                .done = 1
            elsif .k$ = "q" or .k$ = "Q"
                running = 0
                .done = 1
            endif
        elsif demoClicked ()
            if demoClickedIn (0, 12, 0, zNavTop) and currentPage > 1
                currentPage = currentPage - 1
                .done = 1
            elsif demoClickedIn (88, 100, 0, zNavTop)
                currentPage = currentPage + 1
                .done = 1
            endif
        endif
    endwhile
endproc

# ============================================================================
# TEMPLATE: moduleEnd
# ============================================================================
procedure emlTplModuleEnd: .n
    @emlClearPage
    @emlDrawGuides
    @emlPlaceTitle: 58, pg'.n'_title$
    @emlPlaceBodyLine: 48, pg'.n'_subtitle$
    .y = 36
    @emlPlaceCaption: .y, 50, "centre", "Press → to continue"
    .y = emlPlaceCaption.nextY
    @emlPlaceCaption: .y, 50, "centre", "Press H to return to Home"
    .y = emlPlaceCaption.nextY
    @emlPlaceCaption: .y, 50, "centre", "Press Q to quit"
    # Input loop
    @emlResetSans
    .done = 0
    while .done = 0
        demoWaitForInput ()
        if demoKeyPressed ()
            .k$ = demoKey$ ()
            if .k$ = "→" or .k$ = " "
                currentPage = currentPage + 1
                .done = 1
            elsif .k$ = "h" or .k$ = "H"
                currentPage = 1
                .done = 1
            elsif .k$ = "q" or .k$ = "Q"
                running = 0
                .done = 1
            endif
        endif
    endwhile
endproc

# ============================================================================
# TEMPLATE: endScreen
# ============================================================================
procedure emlTplEndScreen: .n
    @emlClearPage
    @emlDrawGuides
    @emlPlaceTitle: 56, pg'.n'_title$
    @emlPlaceBodyLine: 44, pg'.n'_subtitle$
    @emlPlaceCaption: 34, 50, "centre", "Press R to restart or Q to quit"
endproc

# ============================================================================
# MAIN LOOP — template dispatch
# ============================================================================
while running
    if currentPage < 1
        currentPage = 1
    endif
    if currentPage > totalPages
        running = 0
        goto NEXT_ITERATION
    endif

    tpl$ = pg'currentPage'_template$

    if tpl$ = "home"
        @emlTplHome: currentPage
        goto NEXT_ITERATION
    elsif tpl$ = "titleCard"
        @emlTplTitleCard: currentPage
    elsif tpl$ = "textPage"
        @emlTplTextPage: currentPage
    elsif tpl$ = "textImage"
        @emlTplTextImage: currentPage
    elsif tpl$ = "fullImage"
        @emlTplFullImage: currentPage
    elsif tpl$ = "multiImage"
        @emlTplMultiImage: currentPage
    elsif tpl$ = "interactive"
        @emlTplInteractive: currentPage
        goto NEXT_ITERATION
    elsif tpl$ = "animation"
        @emlTplAnimation: currentPage
    elsif tpl$ = "codePage"
        @emlTplCodePage: currentPage
        goto NEXT_ITERATION
    elsif tpl$ = "summary"
        @emlTplSummary: currentPage
    elsif tpl$ = "textTree"
        @emlTplTextTree: currentPage
    elsif tpl$ = "moduleEnd"
        @emlTplModuleEnd: currentPage
        goto NEXT_ITERATION
    elsif tpl$ = "endScreen"
        @emlTplEndScreen: currentPage
        # Input loop — R to restart, Q to quit
        @emlResetSans
        .esDone = 0
        while .esDone = 0
            demoWaitForInput ()
            if demoKeyPressed ()
                .esKey$ = demoKey$ ()
                if .esKey$ = "r" or .esKey$ = "R"
                    currentPage = 1
                    .esDone = 1
                elsif .esKey$ = "q" or .esKey$ = "Q"
                    running = 0
                    .esDone = 1
                endif
            endif
        endwhile
        goto NEXT_ITERATION
    else
        running = 0
        goto NEXT_ITERATION
    endif

    # Standard input — pages that don't handle their own
    @emlResetSans
    while demoWaitForInput ()
        if demoClicked ()
            if demoClickedIn (88, 100, 0, zNavTop)
                currentPage = currentPage + 1
                goto NEXT_ITERATION
            elsif demoClickedIn (0, 12, 0, zNavTop) and currentPage > 1
                currentPage = currentPage - 1
                goto NEXT_ITERATION
            endif
        elsif demoKeyPressed ()
            .key$ = demoKey$ ()
            if .key$ = "→" or .key$ = " "
                currentPage = currentPage + 1
                goto NEXT_ITERATION
            elsif .key$ = "←"
                currentPage = currentPage - 1
                if currentPage < 1
                    currentPage = 1
                endif
                goto NEXT_ITERATION
            elsif .key$ = "q" or .key$ = "Q"
                running = 0
                goto NEXT_ITERATION
            endif
        endif
    endwhile

    label NEXT_ITERATION
endwhile
