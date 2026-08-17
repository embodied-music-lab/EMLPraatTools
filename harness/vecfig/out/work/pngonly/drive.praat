# ---------------------------------------------------------------------------
# vecfig/drive.praat -- the figure's vector formats, written and then looked
#                       for
# ---------------------------------------------------------------------------
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT IS DRIVEN. @eml_saveFigureFormats and @eml_saveFileLanded from
# plugin/stats/eml-output.praat, against a REAL Praat Picture window with a
# real figure in it, writing REAL files to a real folder. Nothing here is
# simulated except the one thing that has to be: a host whose Praat does not
# provide a format.
#
# WHY PROCEDURE LEVEL AND NOT THE DIALOG. @emlSavePanel's figure block is
# reached by pressing Save on the post-draw dialog, and a pause form cannot be
# driven without a display -- measured: `beginPause` under `praat --run` with
# no X server does not return. The panel's own doctrine is the answer to that
# and it predates this file: @eml_saveReceiptLines was split out so the lines
# a dialog will draw can be built and read without a screen. The same split is
# what this drives. What the dialog does with the results -- which tickbox
# feeds which argument, that the redirect is shown when a format is missing --
# is a claim about the panel's TEXT, and validate/v86 reads it there.
#
# THE UNAVAILABLE COMMAND IS SIMULATED BY TAKING THE COMMAND AWAY, not by
# hiding the file afterwards. run.sh's `nopdf` and `novector` legs run against
# a COPY of plugin/stats in which `Save as PDF file:` (and, in the second,
# `Save as EPS file:` too) has been renamed to a command Praat does not have.
# That is bit-for-bit the Windows condition Praat's own manual describes: the
# command is absent, `nocheck` lets the script live, and no file arrives. A
# leg that deleted the file after a successful save would prove the check can
# see a missing file; this proves it can see an ABSENT FORMAT, which is the
# thing the user hits.
#
# WHAT IT WRITES. One TSV of key<TAB>value pairs at $EML_VECFIG_TSV, appended
# to across legs, plus the artefacts themselves under $EML_VECFIG_FILES so the
# validator can read their first bytes itself rather than believe a line in a
# transcript. Every row is a MEASUREMENT; validate/v86 decides what passes.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------

# THE MODULES BY NAME, NOT THE BARREL, for the reason harness/savepaths states:
# a relative `include` inside an included file resolves against the TOP-LEVEL
# script's folder, so the shipped barrel's "../stats/..." lines would look in
# the wrong place from here. run.sh copies this file and the tree under test
# into one work folder per leg, so these paths are the same on every leg and
# the mutated legs need no different script.
include plugin/stats/eml-core-utilities.praat
include plugin/stats/eml-core-descriptive.praat
include plugin/stats/eml-extract.praat
include plugin/stats/eml-output.praat
include plugin/stats/eml-inferential.praat
include plugin/stats/eml-result-writer.praat
include plugin/stats/eml-analysis.praat

leg$ = environment$ ("EML_VECFIG_LEG")
tsv$ = environment$ ("EML_VECFIG_TSV")
files$ = environment$ ("EML_VECFIG_FILES")
wantEPS = number (environment$ ("EML_VECFIG_EPS"))
wantPDF = number (environment$ ("EML_VECFIG_PDF"))
doUnits = number (environment$ ("EML_VECFIG_UNITS"))

createFolder: files$

procedure emit: .key$, .value$
    appendFile: tsv$, leg$, "_", .key$, tab$, .value$, newline$
endproc

procedure emitN: .key$, .value
    @emit: .key$, string$ (.value)
endproc

# ===========================================================================
# A FIGURE, DRAWN. Not a blank page: a blank Picture window still saves to a
# valid file of every format, so a check driven on one would pass on a plugin
# that had lost its drawing.
# ===========================================================================
Erase all
Select outer viewport: 0, 6, 0, 4
Axes: 0, 10, 0, 100
Draw inner box
Marks left every: 1, 20, "yes", "yes", "no"
Marks bottom every: 1, 2, "yes", "yes", "no"
Text special: 5, "centre", 105, "half", "Helvetica", 14, "0", "vecfig"
Paint rectangle: "red", 2, 4, 10, 60
Paint rectangle: "blue", 6, 8, 10, 80

# ===========================================================================
# 1. THE SAVE, WITH WHATEVER THIS LEG ASKED FOR
# ===========================================================================
# THE OBJECT LIST IS WATCHED ACROSS THE SAVE. The landed-file check reads the
# saved file back through a Strings object, which means a save now touches the
# Objects window. Two objects are selected before the call and the selection
# is read back after it: a check that leaves the user's selection somewhere
# else has broken the caller that runs next.
t1 = Create Table with column names: "vecfig_a", 2, "x"
t2 = Create Table with column names: "vecfig_b", 2, "x"
selectObject: t1, t2
@emitN: "sel_before", numberOfSelected ()

@eml_saveFigureFormats: files$, "fig", 1, wantEPS, wantPDF

@emitN: "sel_after", numberOfSelected ()
selAfter$ = ""
after# = selected# ()
for i to size (after#)
    if after# [i] = t1
        selAfter$ = selAfter$ + "a"
    endif
    if after# [i] = t2
        selAfter$ = selAfter$ + "b"
    endif
endfor
@emit: "sel_after_ids", selAfter$

@emitN: "n_written", eml_saveFigureFormats.nWritten
@emit: "landed", eml_saveFigureFormats.landed$
@emit: "missing", eml_saveFigureFormats.missing$
@emit: "png_path", eml_saveFigureFormats.pngPath$
fl$ = replace$ (eml_saveFigureFormats.fileList$, newline$, " | ", 0)
@emit: "file_list", fl$

missing$ = eml_saveFigureFormats.missing$
landed$ = eml_saveFigureFormats.landed$
; WHAT THE REDIRECT WILL BE HANDED. The panel accumulates the figure's landed
; files ACROSS the figure and its separate legend and gives the message all of
; them, so the message names every file the user actually has and not the PNG
; alone. Accumulated here the same way, or this drive would be testing a
; shorter list than the panel builds.
figFileList$ = eml_saveFigureFormats.fileList$

removeObject: t1, t2

# ===========================================================================
# 2. THE LEGEND, THE SAME WAY
# ===========================================================================
# The panel writes the separate legend through this same procedure, so a
# legend placed outside the frame arrives in every format the figure did.
# Driven here under the legend's own name so the artefacts exist on disk and
# the validator can read their markers too.
Select outer viewport: 0, 2, 0, 1
@eml_saveFigureFormats: files$, "fig_legend", 1, wantEPS, wantPDF
@emitN: "legend_n_written", eml_saveFigureFormats.nWritten
@emit: "legend_landed", eml_saveFigureFormats.landed$
@emit: "legend_missing", eml_saveFigureFormats.missing$
figFileList$ = figFileList$ + eml_saveFigureFormats.fileList$
@emit: "fig_file_list", replace$ (figFileList$, newline$, " | ", 0)
Select outer viewport: 0, 6, 0, 4

# ===========================================================================
# 3. WHAT THE USER WOULD BE TOLD
# ===========================================================================
# Built whenever this leg lost a format, from the sets the drive above
# actually produced -- not from a list typed in here, or the message would be
# a transcript of this file rather than of the plugin.
if missing$ <> ""
    @eml_saveFormatRedirectLines: missing$, landed$, figFileList$
    @emitN: "redirect_lines", eml_saveFormatRedirectLines.nLines
    joined$ = ""
    for rl from 1 to eml_saveFormatRedirectLines.nLines
        @emit: "redirect_line", eml_saveFormatRedirectLines.line$ [rl]
        joined$ = joined$ + eml_saveFormatRedirectLines.line$ [rl] + " "
    endfor
    @emit: "redirect_text", joined$
    # THE LONGEST LINE, because these are drawn with `comment:` in a pause
    # form and a line past the dialog's width overprints the line below it --
    # the SAVED-OVERPRINT defect, which this dialog would otherwise repeat.
    longest = 0
    for rl from 1 to eml_saveFormatRedirectLines.nLines
        if length (eml_saveFormatRedirectLines.line$ [rl]) > longest
            longest = length (eml_saveFormatRedirectLines.line$ [rl])
        endif
    endfor
    @emitN: "redirect_longest_line", longest
else
    @emitN: "redirect_lines", 0
endif

# ===========================================================================
# 4. THE CHECKER ITSELF, ON KNOWN FILES
# ===========================================================================
# @eml_saveFileLanded is the whole basis of every claim above, so it is driven
# against files whose answers are known before it runs: the real artefacts
# with their real markers, the same artefacts against the WRONG marker, a file
# of nothing, a file of the wrong content, and a path with no file at all. A
# checker that answered 1 to everything would satisfy every other row in this
# transcript and only these rows can see it.
if doUnits = 1
    writeFile: files$ + "/unit_empty.dat", ""
    writeFile: files$ + "/unit_junk.dat", "this is not a figure" + newline$

    @eml_saveFileLanded: files$ + "/fig.png", "PNG"
    @emitN: "unit_png_right", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/fig.png", "%PDF"
    @emitN: "unit_png_wrong", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/fig.eps", "%!PS"
    @emitN: "unit_eps_right", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/fig.eps", "%PDF"
    @emitN: "unit_eps_wrong", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/fig.pdf", "%PDF"
    @emitN: "unit_pdf_right", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/fig.pdf", "%!PS"
    @emitN: "unit_pdf_wrong", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/unit_empty.dat", "PNG"
    @emitN: "unit_empty", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/unit_junk.dat", "%PDF"
    @emitN: "unit_junk", eml_saveFileLanded.ok
    @eml_saveFileLanded: files$ + "/unit_absent.pdf", "%PDF"
    @emitN: "unit_absent", eml_saveFileLanded.ok

    # AND IT LEAVES NOTHING BEHIND. Nine reads, each of which makes a Strings
    # object; if one were left, the Objects window would fill up over a
    # session and the panel's caller would find a stranger selected.
    select all
    @emitN: "unit_objects_left", numberOfSelected ()

    # ── THE PLATFORM TRAP, MEASURED RATHER THAN QUOTED ─────────────────────
    # `Save as SVG file:` is a command Praat does not have, which is what
    # `Save as PDF file:` IS on Windows. Under `nocheck` the script survives
    # it and no file arrives -- the two facts the whole design rests on. The
    # unguarded half of the same measurement cannot be taken here, because it
    # ends the script; run.sh takes it in a process of its own.
    nocheck Save as SVG file: files$ + "/absent_command.svg"
    @emitN: "absent_command_survived", 1
    @emitN: "absent_command_file", fileReadable (files$ + "/absent_command.svg")
endif

@emit: "praat_version", "'praatVersion$'"
@emitN: "finished", 1
