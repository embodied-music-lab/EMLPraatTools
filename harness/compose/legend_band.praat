include fixture.praat
# A COMPOSITE WHOSE SECOND PANEL WOULD HAVE COLLIDED WITH A PARKED LEGEND.
#
# Three tall panels down the left of the page reach 28 inches. A fourth,
# short panel goes at the top right with its legend set to "Separate figure",
# which parks the legend on a patch of picture below the page and saves it as
# a second file.
#
# THE PARK USED TO BE TAKEN FROM THE PANEL WHOSE LEGEND IT IS: twelve inches
# below THAT panel's own bottom, floored at 24. The short panel's bottom is at
# 4, so the band landed at 24 -- inside the third left-hand panel, which runs
# from 19 to 28. The legend file would have carried somebody else's figure.
#
# The band is now taken twelve inches below the EXTENT UNION, which holds
# every panel drawn since the last erase, so it sits below all four.
figure_width = 6
figure_height = 9
@composePanel: 11, 0, 0, 1, 5, "Left column, top"
@composePanel: 12, 0, 9.5, 0, 5, "Left column, middle"
@composePanel: 11, 0, 19, 0, 5, "Left column, bottom"
figure_height = 4
@composePanel: 12, 7, 0, 0, 4, "Right panel, separate legend"
@composeSavePage: 0.5, 0.5
