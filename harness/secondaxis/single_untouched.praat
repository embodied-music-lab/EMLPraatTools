include fixture.praat
# THE COMPATIBILITY CASE, AND THE MOST IMPORTANT ONE HERE. No second axis, no
# line style, nothing about either feature said at all -- the figure a caller
# who has never heard of this change order gets. validate/v95 asserts this PNG
# is byte-identical to the one drawn with the two globals at their documented
# defaults (solid_default.png), which is a comparison between two files this
# harness made rather than a hash somebody typed.
@emlGraphsDrawWithLegendRoom
@secondReport
@secondSave
