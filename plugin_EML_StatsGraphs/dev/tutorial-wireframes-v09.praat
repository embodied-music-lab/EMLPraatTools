# ============================================================================
# EML Stats Tutorial — Layout Wireframes v0.10
# ============================================================================
# 11 page templates. Progress bar + arrow navigation. Consistent alignment.
# Design rule: text anchored left, one visual element max per page.
#
# Date: 4 August 2026
# Version: 0.10
#
# Changes from v0.9:
#   1. Rule 1 compliance — the bare "demo Marks left: 4" on the page-8
#      scatter (computed 120-260 range, arbitrary ticks at 166.67/213.33)
#      is replaced by explicit "demo One mark left:" calls at 150/200/250.
#      "demo One mark left:" verified empirically in Praat 6.4.x under
#      Xvfb, 4 August 2026 — it is not listed in COMMANDS_DemoWindow.txt.
#
# Changes from v0.8:
#   1. Draw line parameter order corrected (fromX, fromY, toX, toY)
#   2. Interactive page nav trap fixed (phase-based input loop)
#   3. Home screen title spacing — "Tutorial" raised to y=80
#   4. Text column width on page 3 — right edge from 62 to 78
#   5. Full-bleed range — @clear uses -10/110
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

# ============================================================================
# TYPOGRAPHY
# ============================================================================

bodySize = 14
captionSize = 11
headingSize = 20
titleSize = 28
heroSize = 36
numSize = 60
lineHeightFactor = 0.32

# ============================================================================
# PALETTE
# ============================================================================

bg$ = "{0.97, 0.96, 0.94}"
ink$ = "{0.10, 0.10, 0.10}"
text$ = "{0.25, 0.25, 0.24}"
light$ = "{0.60, 0.59, 0.57}"
faint$ = "{0.82, 0.81, 0.79}"
accent$ = "{0.18, 0.45, 0.58}"
accentPale$ = "{0.85, 0.91, 0.94}"
warmGray$ = "{0.92, 0.91, 0.88}"
groupA$ = "{0.35, 0.55, 0.78}"
groupB$ = "{0.78, 0.48, 0.28}"
groupC$ = "{0.28, 0.62, 0.52}"
meanRed$ = "{0.72, 0.28, 0.28}"
progressBg$ = "{0.90, 0.89, 0.87}"
progressFill$ = "{0.18, 0.45, 0.58}"
arrowColor$ = "{0.50, 0.49, 0.47}"

# ============================================================================
# LAYOUT CONSTANTS
# ============================================================================

# Left edge alignment system: two stops
edgeLabel = 10
edgeContent = 12

# Total pages across all templates in wireframe
totalPages = 11

# ============================================================================
# STATE
# ============================================================================

currentPage = 1
running = 1
demoWindowTitle: "EML Stats Tutorial"

# ============================================================================
# CORE PROCEDURES
# ============================================================================

procedure resetSans: .size
    demo Helvetica
    demo Font size: .size
    demo Axes: 0, 100, 0, 100
endproc

procedure resetSerif: .size
    demo Times
    demo Font size: .size
    demo Axes: 0, 100, 0, 100
endproc

procedure wrapText: .x1, .x2, .yTop, .yBottom, .align$, .fontSize, .isSerif, .text$
    if .isSerif
        @resetSerif: .fontSize
    else
        @resetSans: .fontSize
    endif
    .lineH = .fontSize * lineHeightFactor
    .availW = .x2 - .x1
    .currentY = .yTop
    .remaining$ = .text$
    .currentLine$ = ""
    while .remaining$ <> ""
        if .currentY - .lineH < .yBottom
            goto WRAP_END
        endif
        .spacePos = index (.remaining$, " ")
        if .spacePos = 0
            .word$ = .remaining$
            .remaining$ = ""
        else
            .word$ = left$ (.remaining$, .spacePos - 1)
            .remaining$ = mid$ (.remaining$, .spacePos + 1,
            ... length (.remaining$) - .spacePos)
        endif
        if .currentLine$ = ""
            .testLine$ = .word$
        else
            .testLine$ = .currentLine$ + " " + .word$
        endif
        .testW = demo Text width (world coordinates): .testLine$
        if .testW > .availW and .currentLine$ <> ""
            if .align$ = "left"
                demo Text: .x1, "left", .currentY, "top", .currentLine$
            elsif .align$ = "centre"
                demo Text: (.x1 + .x2) / 2, "centre", .currentY, "top", .currentLine$
            else
                demo Text: .x2, "right", .currentY, "top", .currentLine$
            endif
            .currentY = .currentY - .lineH
            .currentLine$ = .word$
        else
            .currentLine$ = .testLine$
        endif
    endwhile
    if .currentLine$ <> "" and .currentY - .lineH >= .yBottom
        if .align$ = "left"
            demo Text: .x1, "left", .currentY, "top", .currentLine$
        elsif .align$ = "centre"
            demo Text: (.x1 + .x2) / 2, "centre", .currentY, "top", .currentLine$
        else
            demo Text: .x2, "right", .currentY, "top", .currentLine$
        endif
    endif
    label WRAP_END
endproc

# Fix 5: full-bleed range -10/110
procedure clear
    @resetSans: bodySize
    demo Paint rectangle: bg$, -10, 110, -10, 110
endproc

# ============================================================================
# NAVIGATION — progress bar + arrows
# ============================================================================

procedure drawNav: .pageNum, .totalPages, .showBack
    # Progress bar — thin, top of page
    demo Paint rectangle: progressBg$, 0, 100, 97.5, 98.5
    .fillW = (.pageNum / .totalPages) * 100
    if .fillW > 0
        demo Paint rectangle: progressFill$, 0, .fillW, 97.5, 98.5
    endif

    # Right arrow — always visible
    @resetSans: headingSize
    demo Colour: arrowColor$
    demo Text: 94, "right", 3, "half", "→"

    # Left arrow — only after page 1
    if .showBack
        demo Text: 6, "left", 3, "half", "←"
    endif

    # Page number — small, near right arrow
    @resetSans: captionSize
    demo Colour: light$
    .str$ = string$ (.pageNum) + " / " + string$ (.totalPages)
    demo Text: 94, "right", 96, "half", .str$
endproc

# ============================================================================
# IMAGE PLACEHOLDER
# ============================================================================

procedure drawImage: .x1, .x2, .y1, .y2, .label$
    demo Paint rectangle: warmGray$, .x1, .x2, .y1, .y2
    @resetSans: captionSize
    demo Colour: light$
    demo Rectangle text (wrap & truncate): .x1, .x2, "centre",
    ... .y1, .y2, "half", .label$
endproc

# ============================================================================
# 1. HOME
# ============================================================================

procedure pageHome
    @clear

    # Circle motif — bottom right, partially clipped
    demo Paint circle: accentPale$, 88, 8, 30

    # Title — high, left-aligned
    # Fix 3: raised "Tutorial" from y=77 to y=80
    @resetSans: heroSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 88, "top", "EML Stats"
    demo Text: edgeContent, "left", 80, "top", "Tutorial"

    # Subtitle — well below title
    @resetSerif: bodySize
    demo Colour: light$
    demo Text: edgeContent, "left", 63, "top",
    ... "An interactive statistics guide"
    demo Text: edgeContent, "left", 58.5, "top",
    ... "for voice researchers."

    # Module list
    .x = edgeContent + 2
    .y = 50
    .step = 4.5

    @resetSans: captionSize
    for .i from 1 to 10
        if .i < 10
            .num$ = "0" + string$ (.i)
        else
            .num$ = string$ (.i)
        endif
        demo Colour: light$
        demo Text: .x, "left", .y, "top", .num$
        demo Colour: text$
        if .i = 1
            .name$ = "What Is Data?"
        elsif .i = 2
            .name$ = "Looking at Your Data"
        elsif .i = 3
            .name$ = "Describing Your Data"
        elsif .i = 4
            .name$ = "Are These Groups Different?"
        elsif .i = 5
            .name$ = "Before and After"
        elsif .i = 6
            .name$ = "More Than Two Groups"
        elsif .i = 7
            .name$ = "Do These Move Together?"
        elsif .i = 8
            .name$ = "Change Over Time"
        elsif .i = 9
            .name$ = "Choosing the Right Test"
        else
            .name$ = "Graph Gallery"
        endif
        demo Text: .x + 5, "left", .y, "top", .name$
        .y = .y - .step
    endfor

    # Arrow only (no back on home)
    @resetSans: headingSize
    demo Colour: arrowColor$
    demo Text: 94, "right", 3, "half", "→"

    # Input
    @resetSans: bodySize
    demo Axes: 0, 100, 0, 100
    .done = 0
    while .done = 0
        demoWaitForInput ()
        if demoClicked () or demoKeyPressed ()
            if demoKeyPressed ()
                .k$ = demoKey$ ()
                if .k$ = "q" or .k$ = "Q"
                    running = 0
                endif
            endif
            currentPage = 2
            .done = 1
        endif
    endwhile
endproc

# ============================================================================
# 2. TITLE CARD
# ============================================================================

procedure pageTitle
    @clear
    @drawNav: 2, totalPages, 1

    # Module number — large, right side
    @resetSans: numSize
    demo Colour: faint$
    demo Text: 88, "right", 72, "top", "01"

    # Part label
    @resetSans: captionSize
    demo Colour: light$
    demo Text: edgeLabel, "left", 70, "top", "PART ONE"

    # Title
    @resetSans: titleSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 60, "top", "What Is Data?"

    # Subtitle — serif
    @resetSerif: bodySize
    demo Colour: text$
    demo Text: edgeContent, "left", 46, "top",
    ... "How measurements become a table"
    demo Text: edgeContent, "left", 41.5, "top",
    ... "you can analyze."

    # Data dots — right side, suggestive of what's coming
    demo Paint circle: groupA$, 72, 42, 0.9
    demo Paint circle: groupA$, 76, 46, 0.9
    demo Paint circle: groupA$, 70, 48, 0.9
    demo Paint circle: groupA$, 78, 38, 0.9
    demo Paint circle: groupA$, 74, 52, 0.9
    demo Paint circle: groupB$, 82, 34, 0.9
    demo Paint circle: groupB$, 84, 38, 0.9
    demo Paint circle: groupB$, 86, 32, 0.9
endproc

# ============================================================================
# 3. TEXT
# ============================================================================

procedure pageText
    @clear
    @drawNav: 3, totalPages, 1

    # Heading
    @resetSans: headingSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 84, "top", "The scenario"

    # Fix 1: corrected Draw line parameter order (fromX, fromY, toX, toY)
    demo Colour: accent$
    demo Line width: 1.5
    demo Draw line: edgeContent, 78.5, edgeContent + 8, 78.5
    demo Line width: 1

    # Fix 4: widened text column from 62 to 78
    demo Colour: text$
    @wrapText: edgeContent, 78, 73, 44, "left", bodySize, 1,
    ... "Imagine you're a voice therapist. Six clients come to your clinic. Three haven't started therapy. Three have finished a course of therapy. You record each of them saying 'ah' and measure their pitch. Now you have six numbers."

    # Key question — accent
    demo Colour: accent$
    @wrapText: edgeContent, 78, 38, 18, "left", bodySize, 1,
    ... "How do you organize those numbers so you can compare the two groups?"
endproc

# ============================================================================
# 4. TEXT + IMAGE
# ============================================================================

procedure pageTextImage
    @clear
    @drawNav: 4, totalPages, 1

    # Image — left side, dominant
    @drawImage: 3, 48, 18, 86, "Box Plot"

    # Text — right side
    @resetSans: headingSize
    demo Colour: ink$
    demo Text: 54, "left", 82, "top", "The box plot"

    # Fix 1: corrected Draw line parameter order
    demo Colour: accent$
    demo Line width: 1.5
    demo Draw line: 54, 76.5, 62, 76.5
    demo Line width: 1

    demo Colour: text$
    @wrapText: 54, 90, 71, 40, "left", bodySize, 1,
    ... "The box plot summarizes center, spread, and outliers in one compact picture. The median line, the Q1-to-Q3 box, and the whiskers show you the structure of your data at a glance."

    demo Colour: accent$
    @wrapText: 54, 90, 34, 16, "left", bodySize, 1,
    ... "Dots beyond the whiskers are outliers — values unusually far from the center."
endproc

# ============================================================================
# 5. FULL IMAGE
# ============================================================================

procedure pageFullImage
    @clear
    @drawNav: 5, totalPages, 1

    # Image — large, bleeds left
    @drawImage: 0, 80, 32, 92, "Violin Plot"

    # Caption below
    demo Colour: text$
    @wrapText: edgeContent, 80, 26, 10, "left", bodySize, 1,
    ... "The smooth outline reveals the data's shape. The box inside shows median and quartiles."

    @resetSans: captionSize
    demo Colour: light$
    demo Text: edgeContent, "left", 6, "half",
    ... "t-test · Mann-Whitney U · group comparisons"
endproc

# ============================================================================
# 6. MULTI-IMAGE
# ============================================================================

procedure pageMultiImage
    @clear
    @drawNav: 6, totalPages, 1

    @resetSans: headingSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 88, "top", "Correlation"

    # Fix 1: corrected Draw line parameter order
    demo Colour: accent$
    demo Line width: 1.5
    demo Draw line: edgeContent, 82.5, edgeContent + 6, 82.5
    demo Line width: 1

    # Three images
    @drawImage: 8, 32, 50, 78, "r = 0.8"
    @drawImage: 36, 64, 50, 78, "r = −0.7"
    @drawImage: 68, 92, 50, 78, "r = 0.0"

    # Labels
    @resetSans: captionSize
    demo Colour: text$
    demo Text: 20, "centre", 46, "top", "Positive"
    demo Text: 50, "centre", 46, "top", "Negative"
    demo Text: 80, "centre", 46, "top", "None"

    # Body
    demo Colour: text$
    @wrapText: edgeContent, 72, 36, 12, "left", bodySize, 1,
    ... "The correlation coefficient measures how strongly two variables move together. It says nothing about whether one causes the other."
endproc

# ============================================================================
# 7. INTERACTIVE
# ============================================================================

# Fix 2: phase-based input loop replaces nav-trapping single loop
procedure pageInteractive
    @clear
    @drawNav: 7, totalPages, 1

    # Question
    @resetSans: titleSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 82, "top", "What are you"
    demo Text: edgeContent, "left", 72, "top", "trying to do?"

    # Options — lettered, no boxes
    .y = 56
    .step = 7
    @resetSans: bodySize

    demo Colour: accent$
    demo Text: edgeContent + 2, "left", .y, "top", "A"
    demo Colour: text$
    demo Text: edgeContent + 7, "left", .y, "top", "Describe one variable"

    .y = .y - .step
    demo Colour: accent$
    demo Text: edgeContent + 2, "left", .y, "top", "B"
    demo Colour: text$
    demo Text: edgeContent + 7, "left", .y, "top", "Compare groups"

    .y = .y - .step
    demo Colour: accent$
    demo Text: edgeContent + 2, "left", .y, "top", "C"
    demo Colour: text$
    demo Text: edgeContent + 7, "left", .y, "top", "Find a relationship"

    @resetSans: captionSize
    demo Colour: light$
    demo Text: edgeContent + 2, "left", 32, "top",
    ... "Press A, B, or C."

    # Phase 1: wait for A/B/C answer or navigation
    # Phase 2: answer shown, wait for advance
    @resetSans: bodySize
    demo Axes: 0, 100, 0, 100
    .phase = 1
    while .phase > 0
        demoWaitForInput ()
        if demoKeyPressed ()
            .k$ = demoKey$ ()
            if .phase = 1
                if .k$ = "a" or .k$ = "A"
                    demo Colour: accent$
                    @wrapText: edgeContent, 70, 24, 12, "left", bodySize, 1,
                    ... "Descriptive statistics — mean, median, SD, quartiles, confidence interval."
                    .phase = 2
                elsif .k$ = "b" or .k$ = "B"
                    demo Colour: accent$
                    @wrapText: edgeContent, 70, 24, 12, "left", bodySize, 1,
                    ... "t-test, Mann-Whitney U, ANOVA, Kruskal-Wallis, and post-hoc tests."
                    .phase = 2
                elsif .k$ = "c" or .k$ = "C"
                    demo Colour: accent$
                    @wrapText: edgeContent, 70, 24, 12, "left", bodySize, 1,
                    ... "Pearson correlation, Spearman rho, and regression."
                    .phase = 2
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
            if demoClickedIn (0, 12, 0, 10) and currentPage > 1
                currentPage = currentPage - 1
                .phase = 0
            elsif demoClickedIn (88, 100, 0, 10)
                currentPage = currentPage + 1
                .phase = 0
            else
                if .phase = 1
                    # Click anywhere skips question, advances
                    currentPage = currentPage + 1
                    .phase = 0
                else
                    # Click anywhere after answer, advances
                    currentPage = currentPage + 1
                    .phase = 0
                endif
            endif
        endif
    endwhile
endproc

# ============================================================================
# 8. ANIMATION
# ============================================================================

procedure pageAnimation
    @clear
    @drawNav: 8, totalPages, 1

    @resetSans: headingSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 90, "top",
    ... "Each dot is one person."

    # Visualization — left two-thirds, no border
    .vpScale = 12.0 / 100
    .vpLeft = 10 * .vpScale
    .vpRight = 68 * .vpScale
    .vpTop = (100 - 80) * .vpScale
    .vpBottom = (100 - 18) * .vpScale
    demo Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
    demo Axes: 0.5, 1.5, 120, 260

    @resetSans: captionSize
    demo Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
    demo Axes: 0.5, 1.5, 120, 260
    demo Colour: faint$
    demo Line width: 0.5
    # Rule 1: nice-number ticks. A bare "demo Marks left: 4" would divide the
    # computed 120-260 range into three arbitrary intervals, labelling the
    # axis 120 / 166.67 / 213.33 / 260.
    demo One mark left: 150, "yes", "no", "no", ""
    demo One mark left: 200, "yes", "no", "no", ""
    demo One mark left: 250, "yes", "no", "no", ""
    demo Line width: 1
    demo Colour: light$
    demo Text left: "yes", "Pitch (Hz)"

    for .i from 1 to 20
        .val = randomGauss (190, 25)
        if .val < 130
            .val = randomUniform (130, 160)
        endif
        if .val > 280
            .val = randomUniform (240, 270)
        endif
        .jx = 1 + randomUniform (-0.15, 0.15)
        demo Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
        demo Axes: 0.5, 1.5, 120, 260
        demo Paint circle: groupA$, .jx, .val, 0.03
        demoShow ()
        sleep (0.06)
    endfor

    demo Colour: meanRed$
    demo Line width: 1.5
    demo Draw line: 0.7, 190, 1.3, 190
    demo Line width: 1
    @resetSans: captionSize
    demo Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
    demo Axes: 0.5, 1.5, 120, 260
    demo Colour: meanRed$
    demo Text: 1.35, "left", 190, "half", "mean"

    # Restore
    demo Select inner viewport: 0, 100, 0, 100
    demo Axes: 0, 100, 0, 100

    # Commentary — right column, serif
    demo Colour: text$
    @wrapText: 74, 92, 60, 28, "left", bodySize, 1,
    ... "Where do most values cluster? How spread out are they? These are the first questions to ask about any dataset."
endproc

# ============================================================================
# 9. SUMMARY
# ============================================================================

procedure pageSummary
    @clear
    @drawNav: 9, totalPages, 1

    @resetSans: headingSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 86, "top", "Key Ideas"

    # Fix 1: corrected Draw line parameter order
    demo Colour: accent$
    demo Line width: 1.5
    demo Draw line: edgeContent, 80, edgeContent + 8, 80
    demo Line width: 1

    .y = 74
    .step = 11

    # Bullet 1
    demo Paint circle: accent$, edgeContent + 1, .y - 1.5, 0.5
    demo Colour: text$
    @wrapText: edgeContent + 4, 76, .y, .y - .step,
    ... "left", bodySize, 1,
    ... "t-test — signal / noise ratio for two independent groups"

    # Bullet 2
    .y = .y - .step
    demo Paint circle: accent$, edgeContent + 1, .y - 1.5, 0.5
    demo Colour: text$
    @wrapText: edgeContent + 4, 76, .y, .y - .step,
    ... "left", bodySize, 1,
    ... "p-value — probability of this result if no real difference exists"

    # Bullet 3
    .y = .y - .step
    demo Paint circle: accent$, edgeContent + 1, .y - 1.5, 0.5
    demo Colour: text$
    @wrapText: edgeContent + 4, 76, .y, .y - .step,
    ... "left", bodySize, 1,
    ... "Cohen's d — size of the difference in SD units"

    # Bullet 4
    .y = .y - .step
    demo Paint circle: accent$, edgeContent + 1, .y - 1.5, 0.5
    demo Colour: text$
    @wrapText: edgeContent + 4, 76, .y, .y - .step,
    ... "left", bodySize, 1,
    ... "Parametric vs. nonparametric — choose based on data shape"

    # Bullet 5
    .y = .y - .step
    demo Paint circle: accent$, edgeContent + 1, .y - 1.5, 0.5
    demo Colour: text$
    @wrapText: edgeContent + 4, 76, .y, .y - .step,
    ... "left", bodySize, 1,
    ... "Always report both p-value and effect size"
endproc

# ============================================================================
# 10. FLOWCHART
# ============================================================================

procedure pageFlowchart
    @clear
    @drawNav: 10, totalPages, 1

    @resetSans: headingSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 92, "top", "Which test?"

    # Root
    demo Colour: faint$
    demo Line width: 0.5
    demo Draw rectangle: 33, 67, 74, 83
    @resetSans: captionSize
    demo Colour: text$
    demo Rectangle text (wrap & truncate): 33, 67, "centre",
    ... 74, 83, "half", "What's your question?"

    # Connectors from root
    demo Colour: faint$
    demo Draw line: 40, 74, 18, 68
    demo Draw line: 50, 74, 50, 68
    demo Draw line: 60, 74, 82, 68

    # Level 2
    demo Draw rectangle: 5, 31, 59, 68
    demo Draw rectangle: 37, 63, 59, 68
    demo Draw rectangle: 69, 95, 59, 68
    demo Colour: text$
    demo Rectangle text (wrap & truncate): 5, 31, "centre",
    ... 59, 68, "half", "Describe"
    demo Rectangle text (wrap & truncate): 37, 63, "centre",
    ... 59, 68, "half", "Compare"
    demo Rectangle text (wrap & truncate): 69, 95, "centre",
    ... 59, 68, "half", "Relate"

    # Connectors from Compare
    demo Colour: faint$
    demo Draw line: 44, 59, 30, 52
    demo Draw line: 56, 59, 70, 52

    demo Draw rectangle: 17, 43, 43, 52
    demo Draw rectangle: 57, 83, 43, 52
    demo Colour: text$
    demo Rectangle text (wrap & truncate): 17, 43, "centre",
    ... 43, 52, "half", "2 groups"
    demo Rectangle text (wrap & truncate): 57, 83, "centre",
    ... 43, 52, "half", "3+ groups"

    # Leaf connectors
    demo Colour: faint$
    demo Draw line: 25, 43, 15, 36
    demo Draw line: 35, 43, 45, 36
    demo Draw line: 70, 43, 70, 36
    demo Draw line: 18, 59, 18, 22
    demo Draw line: 82, 59, 82, 22
    demo Line width: 1

    # Leaves — filled
    demo Paint rectangle: groupA$, 5, 28, 26, 36
    demo Paint rectangle: groupB$, 32, 58, 26, 36
    demo Paint rectangle: groupC$, 57, 83, 26, 36
    demo Paint rectangle: groupA$, 5, 31, 13, 22
    demo Paint rectangle: groupB$, 69, 95, 13, 22

    @resetSans: captionSize
    demo Colour: "{1, 1, 1}"
    demo Rectangle text (wrap & truncate): 5, 28, "centre",
    ... 26, 36, "half", "t / MWU"
    demo Rectangle text (wrap & truncate): 32, 58, "centre",
    ... 26, 36, "half", "Paired t / W"
    demo Rectangle text (wrap & truncate): 57, 83, "centre",
    ... 26, 36, "half", "ANOVA / KW"
    demo Rectangle text (wrap & truncate): 5, 31, "centre",
    ... 13, 22, "half", "Describe"
    demo Rectangle text (wrap & truncate): 69, 95, "centre",
    ... 13, 22, "half", "Correlate"
endproc

# ============================================================================
# 11. END
# ============================================================================

procedure pageEnd
    @clear
    @resetSans: titleSize
    demo Colour: ink$
    demo Text: edgeContent, "left", 56, "half", "Done."
    @resetSerif: bodySize
    demo Colour: light$
    demo Text: edgeContent, "left", 44, "half",
    ... "Close this window to return to Praat."
endproc

# ============================================================================
# MAIN LOOP
# ============================================================================

while running
    if currentPage = 1
        @pageHome
        goto NEXT_ITERATION
    elsif currentPage = 2
        @pageTitle
    elsif currentPage = 3
        @pageText
    elsif currentPage = 4
        @pageTextImage
    elsif currentPage = 5
        @pageFullImage
    elsif currentPage = 6
        @pageMultiImage
    elsif currentPage = 7
        # Fix 2: pageInteractive now manages its own currentPage
        @pageInteractive
        goto NEXT_ITERATION
    elsif currentPage = 8
        @pageAnimation
    elsif currentPage = 9
        @pageSummary
    elsif currentPage = 10
        @pageFlowchart
    else
        running = 0
        goto NEXT_ITERATION
    endif

    # Generic input — arrow clicks + keyboard
    @resetSans: bodySize
    demo Axes: 0, 100, 0, 100
    while demoWaitForInput ()
        if demoClicked ()
            # Check arrow click zones
            if demoClickedIn (88, 100, 0, 10)
                # Right arrow zone
                currentPage = currentPage + 1
                goto NEXT_ITERATION
            elsif demoClickedIn (0, 12, 0, 10) and currentPage > 1
                # Left arrow zone
                currentPage = currentPage - 1
                goto NEXT_ITERATION
            else
                # Click anywhere else — advance
                currentPage = currentPage + 1
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
    if currentPage > totalPages
        running = 0
    endif
endwhile

@pageEnd
