# Praat's own pen, with no plugin loaded.
leg$ = environment$ ("EML_PA_LEG")
png$ = environment$ ("EML_PA_PNG")

Create Sound from formula: "tone", 1, 0, 1, 44100,
... "0.6*sin(2*pi*220*x) + 0.3*sin(2*pi*640*x)
...  + 0.15*sin(2*pi*1310*x) + 0.08*sin(2*pi*2570*x)"
ltas = To Ltas: 100

Erase all
# THE "_def" LEGS TOUCH THE PEN AT ALL. They are how 1.0 is established as
# Praat 6.6.30's own value for both settings rather than recalled from a
# manual: each is compared against its "_lo" partner, which asks for 1.0.
if leg$ = "ctl_arrow_def"
    ; pen untouched
elsif leg$ = "ctl_arrow_lo"
    Arrow size: 1.0
elsif leg$ = "ctl_arrow_hi"
    Arrow size: 5.0
elsif leg$ = "ctl_speck_def"
    ; pen untouched
elsif leg$ = "ctl_speck_lo"
    Speckle size: 1.0
elsif leg$ = "ctl_speck_hi"
    Speckle size: 12.0
elsif leg$ = "ctl_paint_lo"
    Speckle size: 1.0
elsif leg$ = "ctl_paint_hi"
    Speckle size: 12.0
else
    exitScript: "penassert: unknown control leg " + leg$
endif

if left$ (leg$, 9) = "ctl_arrow"
    Select outer viewport: 0, 4, 0, 3
    Axes: 0, 10, 0, 10
    Draw arrow: 1, 1, 9, 9
elsif left$ (leg$, 9) = "ctl_paint"
    # WHICH MARKS READ "SPECKLE SIZE" AND WHICH DO NOT. `Paint circle` takes
    # its radius in world coordinates and is the mark @emlDrawLTAS lays down
    # for its own speckle layer. Measuring it beside the native "Speckles"
    # draw above is what tells the fig pair below apart from the witness
    # pair: a zero on a mark that cannot read the setting is not immunity.
    selectObject: ltas
    Select outer viewport: 0, 4, 0, 3
    Axes: 0, 5000, -20, 80
    Paint circle: "Black", 2500, 30, 30
else
    selectObject: ltas
    Select outer viewport: 0, 4, 0, 3
    Draw: 0, 5000, -20, 80, "no", "Speckles"
endif
Save as 300-dpi PNG file: png$
writeInfoLine: "leg ", leg$, " ok"
