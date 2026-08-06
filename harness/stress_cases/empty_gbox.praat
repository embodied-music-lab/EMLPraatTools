include _prelude.praat
# Zero-row table. The graphs form refuses this at eml-graphs-form.praat:1305,
# so this is the non-form route: PraatGen scripts and any future wrapper.
t = Create Table with column names: "e", 0, "cat sub val err time id"
Erase all
@emlDrawGroupedBoxPlot: t, "Empty", "Category", "Value", 6, 4, "color", 1, "cat", "sub", "val", 0, 0
@stressSave: 6, 4
