#!/usr/bin/env python3
# ---------------------------------------------------------------------------
# vecfig/mutate.py -- the three deliberate breaks, applied to a copy
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Called by break.sh with a break name and the path of the COPY of plugin/stats
# to damage. Each break names the ONE file it edits and expresses every
# mutation as an exact old/new text pair; this file exits non-zero if the old
# text is not found, so a break that silently applied nothing -- because the
# source moved under it -- is a failed break test rather than a validator that
# looks like it survived a break.
#
# TWO FILES ARE DAMAGEABLE, because the feature lives in two: the Save panel
# writes the figure and the recorder replays it. A break that could only reach
# eml-output.praat would leave the recorder's half of the work unwatched.
# ---------------------------------------------------------------------------
import os
import sys

OUTPUT = "eml-output.praat"
RECORD = "eml-record.praat"

BREAKS = {
    # THE LANDED-FILE CHECK REMOVED FROM THE VECTOR ARMS. The file is counted
    # because a Save command was issued. On a host without the format the
    # plugin then reports a PDF it has not got, `missing` stays empty and the
    # redirect is never built -- a silent failure passing.
    "no_landed_check": (OUTPUT, [
        ('        nocheck Save as EPS file: .epsPath$\n'
         '        @eml_saveFileLanded: .epsPath$, "%!PS"\n'
         '        if eml_saveFileLanded.ok = 1\n',
         '        nocheck Save as EPS file: .epsPath$\n'
         '        if 1 = 1\n'),
        ('        nocheck Save as PDF file: .pdfPath$\n'
         '        @eml_saveFileLanded: .pdfPath$, "%PDF"\n'
         '        if eml_saveFileLanded.ok = 1\n',
         '        nocheck Save as PDF file: .pdfPath$\n'
         '        if 1 = 1\n'),
    ]),
    # THE MESSAGE STRIPPED OF THE ALTERNATIVES. Every other sentence stays:
    # the format that failed is still named, what did write is still listed,
    # the PNG is still confirmed by path, the dialog still appears.
    "no_alternatives": (OUTPUT, [
        ('    if .haveEPS = 1\n'
         '        .advice$ = "Praat\'s figure formats are PNG, EPS and PDF. The EPS "\n'
         '        ... + "above is a vector file, so this figure is already in the "\n'
         '        ... + "form a journal asks for."\n'
         '    elsif .lostEPS = 1\n'
         '        .advice$ = "Praat\'s figure formats are PNG, EPS and PDF. No vector "\n'
         '        ... + "copy arrived this time. EPS is the vector format Praat "\n'
         '        ... + "writes wherever it runs, so it is worth pressing Save again, "\n'
         '        ... + "or saving to a folder with more room on it."\n'
         '    else\n'
         '        .advice$ = "Praat\'s figure formats are PNG, EPS and PDF. EPS is "\n'
         '        ... + "vector too and Praat writes it wherever it runs, so tick "\n'
         '        ... + "Also EPS in the Save panel and press Save again for a "\n'
         '        ... + "vector copy of this figure."\n'
         '    endif\n',
         '    .advice$ = "That format is not available."\n'),
    ]),
    # THE PNG CHECK DROPPED. The count is made unconditional, which is what
    # the panel did before this work: a save that quietly wrote nothing would
    # be listed on the receipt as a file the user has.
    "no_png_check": (OUTPUT, [
        ('    @eml_saveFileLanded: .pngPath$, "PNG"\n'
         '    if eml_saveFileLanded.ok = 1\n'
         '        .nWritten = .nWritten + 1\n'
         '        .fileList$ = .fileList$ + .pngPath$ + newline$\n'
         '        @eml_saveAddFormat: .landed$, "PNG"\n'
         '        .landed$ = eml_saveAddFormat.result$\n'
         '    else\n'
         '        @eml_saveAddFormat: .missing$, "PNG"\n'
         '        .missing$ = eml_saveAddFormat.result$\n'
         '    endif\n',
         '    .nWritten = .nWritten + 1\n'
         '    .fileList$ = .fileList$ + .pngPath$ + newline$\n'
         '    @eml_saveAddFormat: .landed$, "PNG"\n'
         '    .landed$ = eml_saveAddFormat.result$\n'),
    ]),


    # THE PDF TICKBOX OFFERED WHEREVER THE PANEL RUNS, which is the state the
    # 17 August correction reverses. Praat's manual documents "Save as PDF
    # file..." as a Macintosh and Linux command; on Windows it is absent, and
    # the author reports that reaching for it crashed. A tickbox that is
    # documented to do nothing, followed by an apology, is worse than no
    # tickbox -- so the guard is removed here and the panel goes back to
    # offering it on every host.
    "pdf_box_on_windows": (OUTPUT, [
        ('            if windows = 0\n'
         '                boolean: "Also PDF", 0\n'
         '            else\n'
         '                comment: "PDF is not available in Praat on Windows."\n'
         '            endif\n',
         '            boolean: "Also PDF", 0\n'),
    ]),
    # THE MESSAGE BACK TO IMPLYING PNG IS THE FORMAT THAT SURVIVES. Every
    # other part of it is untouched: the format that failed is still named,
    # what did write is still listed, the dialog still appears, every line
    # still fits. What goes is the EPS-forward closing paragraph and the
    # listing of every file that landed -- replaced by the PNG's own, which
    # tells a user who asked for vector that their raster is safe.
    "png_only_message": (OUTPUT, [
        ('        .line$ [.nLines] = "These figure files are on disk:"\n',
         '        .line$ [.nLines] = "Your figure is still saved as PNG:"\n'),
        ('    if .haveEPS = 1\n'
         '        .advice$ = "Praat\'s figure formats are PNG, EPS and PDF. The EPS "\n'
         '        ... + "above is a vector file, so this figure is already in the "\n'
         '        ... + "form a journal asks for."\n'
         '    elsif .lostEPS = 1\n'
         '        .advice$ = "Praat\'s figure formats are PNG, EPS and PDF. No vector "\n'
         '        ... + "copy arrived this time. EPS is the vector format Praat "\n'
         '        ... + "writes wherever it runs, so it is worth pressing Save again, "\n'
         '        ... + "or saving to a folder with more room on it."\n'
         '    else\n'
         '        .advice$ = "Praat\'s figure formats are PNG, EPS and PDF. EPS is "\n'
         '        ... + "vector too and Praat writes it wherever it runs, so tick "\n'
         '        ... + "Also EPS in the Save panel and press Save again for a "\n'
         '        ... + "vector copy of this figure."\n'
         '    endif\n',
         '    .advice$ = "Praat\'s figure formats are PNG, EPS and PDF, and not "\n'
         '    ... + "every system offers all three. Tick another format in the Save "\n'
         '    ... + "panel and press Save again to find out which this one has."\n'),
    ]),
    # THE RECORDER'S OWN SAVE PUT BACK. @emlRecordReplaySave writes its own
    # 300-dpi PNG instead of calling the panel's writer, which is the state
    # that dropped the format choice on the floor: tick EPS, record, replay
    # next month, get no EPS and no warning.
    "recorder_own_save": (RECORD, [
        ('        @eml_saveFigureFormats: .folder$, .stem$, 1, .wantEPS, .wantPDF\n'
         '        .nWritten = .nWritten + eml_saveFigureFormats.nWritten\n'
         '        .fileList$ = .fileList$ + eml_saveFigureFormats.fileList$\n'
         '        .figLanded$ = eml_saveFigureFormats.landed$\n'
         '        .figMissing$ = eml_saveFigureFormats.missing$\n'
         '        .figFileList$ = eml_saveFigureFormats.fileList$\n',
         '        .figPath$ = .folder$ + "/" + .stem$ + ".png"\n'
         '        Save as 300-dpi PNG file: .figPath$\n'
         '        .nWritten = .nWritten + 1\n'
         '        .fileList$ = .fileList$ + .figPath$ + newline$\n'
         '        .figLanded$ = "PNG"\n'
         '        .figMissing$ = ""\n'
         '        .figFileList$ = ""\n'),
    ]),
    # THE PER-SAVE SUFFIX FLATTENED. Every format choice is declared under one
    # name, so a recording holding two saves with different choices emits two
    # figureFormat$ lines, the second wins at run time, and both figures come
    # back in whichever choice was recorded last. Invisible in any session
    # that saved once.
    "shared_format_var": (RECORD, [
        ('                                    .fSuffix$ = ""\n'
         '                                    if .fSame > 0\n'
         '                                        .fSuffix$ = string$ (.fSame + 1)\n'
         '                                    endif\n',
         '                                    .fSuffix$ = ""\n'),
    ]),
}


def main():
    name, tree = sys.argv[1], sys.argv[2]
    if name not in BREAKS:
        sys.exit("unknown break: " + name)
    fname, pairs = BREAKS[name]
    path = os.path.join(tree, fname)
    text = open(path, encoding="utf-8").read()
    for old, new in pairs:
        if old not in text:
            sys.exit("mutate: %s -- anchor not found in %s:\n%s"
                     % (name, fname, old))
        text = text.replace(old, new, 1)
    open(path, "w", encoding="utf-8").write(text)
    print("mutate: %s applied to %s" % (name, fname))


if __name__ == "__main__":
    main()
