include _prelude.praat
# Zero-row table. The graphs form refuses this before it ever reaches a
# draw procedure. Cite the guard by its STRING, never by a line number:
#     grep -n 'exitScript: "Table has no rows."' \
#         plugin/graphs/eml-graphs-form.praat
# The columns guard, `exitScript: "Table has no columns."`, is the guard
# immediately above it — same if/endif shape, four lines up.
#
# C3: eleven files used to cite `:1305` for the rows guard, which is a
# grouped-violin persistence variable and always was. They were retargeted
# to `:2061`, and that had drifted to `:2078` a day later. Two wrong numbers
# in two days is why this cites the string. Do NOT write a line number back
# into this comment.
#
# NOT this branch: an ALL-BLANK category column. `@emlCountGroups`
# (plugin/stats/eml-extract.praat) counts "" as a group — measured nGroups=1
# on a 3-row all-blank table. It returns nGroups=0 only for a 0-row table or
# a missing column. The zero-row case below is the first of those.
#
# This is the non-form route: PraatGen scripts and any future wrapper.
t = Create Table with column names: "e", 0, "cat sub val err time id"
Erase all
@emlDrawTimeSeries: t, "Empty", "Time", "Value", 6, 4, "color", 1, "time", "val", "", 0, 0, 0, 0
@stressSave: 6, 4
