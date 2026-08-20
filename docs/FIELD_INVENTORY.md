# Field inventory — every dialog on the draw path

Regenerate with the script in this file's history; it reads the form source
directly, so it is never stale for long.

WHY IT EXISTS. A field label carries three separate kinds of information and
they compete: the parameter's identity, the variable name Praat DERIVES from
the label, and parenthetical unit and direction detail. A heading
disambiguates for the eye; the label disambiguates for Praat, and only the
second is enforced. So no label can be decided without seeing the rest of its
page: "Range" works on a page with one range and collides on a page with two.

THE RULE THAT FALLS OUT.
  - The heading says what the section is, and carries nothing the variable
    needs.
  - The label stem carries the minimum that keeps the derived name unique
    among that dialog's fields, and no more.
  - The parenthetical is free: Praat truncates the name at the first bracket,
    so units, which-box-is-which and sentinels cost nothing there.
  - `left`/`right` as a first word is a layout cue that STAYS in the derived
    name, so it contributes uniqueness too.

Uniqueness and truncation are checked by v98; the "minimum" half is judgement,
which is what this table is for.


## EML Graphs  (line 3675, 9 fields)

    heading: Untick Erase to add this figure to the page already drawn.
    heading:    On a composed page a legend inside the plot is not
    heading:    given axis room — use Right of plot or Below plot.

    Graph type                                     -> graph_type                   
    Title (blank = auto from table and columns)    -> title$                       
    Subtitle                                       -> subtitle$                    
    Color mode                                     -> color_mode                   
    Figure width (inches)                          -> figure_width                 shared: figure
    Figure height (inches)                         -> figure_height                shared: figure
    Erase page first                               -> erase_page_first             
    Panel origin x (inches)                        -> panel_origin_x               shared: origin panel
    Panel origin y (inches)                        -> panel_origin_y               shared: origin panel

## Pitch Contour Settings  (line 4069, 17 fields)

    heading: ⏱️ Time (both 0 = auto)
    heading: 📐 Frequency (both 0 = auto)
    heading: 🎵 Pitch analysis (auto-converted from Sound)
    heading: Ceiling is doubled internally for the analysis algorithm.
    heading: 🏷️ Axis labels · %italic #bold ^super _sub · \% and a space prints %

    left Time range (left/right)                   -> left_Time_range              shared: left range right time
    right Time range (left/right)                  -> right_Time_range             shared: left range right time
    left Frequency range (bottom/top)              -> left_Frequency_range         shared: frequency left range
    right Frequency range (bottom/top)             -> right_Frequency_range        shared: frequency range right
    Y axis unit                                    -> y_axis_unit                  shared: axis
    Line style                                     -> line_style                   
    Pitch floor (Hz)                               -> pitch_floor                  shared: pitch
    Pitch ceiling (Hz)                             -> pitch_ceiling                shared: pitch
    Gridline mode                                  -> gridline_mode                
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label

## Waveform Settings  (line 4296, 14 fields)

    heading: ⏱️ Time (both 0 = auto)
    heading: 📐 Amplitude (both 0 = auto)
    heading: 🏷️ Axis labels · %italic #bold ^super _sub · \% and a space prints %

    left Time range (left/right)                   -> left_Time_range              shared: left range right time
    right Time range (left/right)                  -> right_Time_range             shared: left range right time
    left Amplitude range (bottom/top)              -> left_Amplitude_range         shared: amplitude left range
    right Amplitude range (bottom/top)             -> right_Amplitude_range        shared: amplitude range right
    Line style                                     -> line_style                   
    Gridline mode                                  -> gridline_mode                
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label

## Spectrum Settings  (line 4466, 14 fields)

    heading: 📐 Frequency (both 0 = auto)
    heading: 📐 Power (both 0 = auto)
    heading: 🏷️ Axis labels · %italic #bold ^super _sub · \% and a space prints %

    left Frequency range (left/right)              -> left_Frequency_range         shared: frequency left range right
    right Frequency range (left/right)             -> right_Frequency_range        shared: frequency left range right
    left Power range (bottom/top)                  -> left_Power_range             shared: left power range
    right Power range (bottom/top)                 -> right_Power_range            shared: power range right
    Line style                                     -> line_style                   
    Gridline mode                                  -> gridline_mode                
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label

## LTAS Settings  (line 4644, 18 fields)

    heading: 📐 Frequency (both 0 = auto)
    heading: 📐 Power (both 0 = auto)
    heading: 🎨 Drawing methods
    heading: 🏷️ Axis labels · %italic #bold ^super _sub · \% and a space prints %

    left Frequency range (left/right)              -> left_Frequency_range         shared: frequency left range right
    right Frequency range (left/right)             -> right_Frequency_range        shared: frequency left range right
    left Power range (bottom/top)                  -> left_Power_range             shared: left power range
    right Power range (bottom/top)                 -> right_Power_range            shared: power range right
    Line style                                     -> line_style                   
    Gridline mode                                  -> gridline_mode                
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show
    Font                                           -> font                         
    Show curve                                     -> show_curve                   shared: show
    Show bars                                      -> show_bars                    shared: show
    Show poles                                     -> show_poles                   shared: show
    Show speckles                                  -> show_speckles                shared: show
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label

## Line Chart -- Column Mapping  (line 5063, 21 fields)

    heading: 📋 Select columns from your Table.
    heading: Every numeric column is drawn. Untick any you do not want.
    heading: Measurement column: 
    heading: Measurement column: 
    heading: 📐 X-axis (both 0 = auto)
    heading: 📐 Y-axis (both 0 = auto)

    Time column                                    -> time_column                  shared: time
    Series                                         -> series                       shared: series
    Series names come from                         -> series_names_come_from       shared: names series
    Group order                                    -> group_order                  
    Draw the mean and its interval (up to          -> draw_the_mean_and_its_interval 
    Y axis label                                   -> y_axis_label$                shared: axis label
    Line style                                     -> line_style                   
    left Time range (left/right)                   -> left_Time_range              shared: left range right time
    right Time range (left/right)                  -> right_Time_range             shared: left range right time
    left Value range (bottom/top)                  -> left_Value_range             shared: left range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range right value
    Gridline mode                                  -> gridline_mode                
    Legend placement (when drawn)                  -> legend_placement             
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis names show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label

## Line Chart -- The Right-Hand Axis  (line 5553, 5 fields)

    heading: These two measurements are on different scales, so each gets its own.
    heading: Its ticks and its name go in the right margin.
    heading: 📐 Right y-axis

    Which measurement                              -> which_measurement            
    left Range (bottom/top, both 0 = auto)         -> left_Range                   shared: range
    right Range (bottom/top, both 0 = auto)        -> right_Range                  shared: range
    Axis name (blank = the column name)            -> axis_name$                   
    Line style                                     -> line_style                   

## Bar Chart -- Column Mapping  (line 5894, 23 fields)

    heading: 📋 Select columns from your Table.
    heading: 📐 Y-axis (both 0 = auto)
    heading: 📈 Your analysis found a result to put on this figure.

    Value column                                   -> value_column                 shared: column value
    Error bars                                     -> error_bars                   
    Group column                                   -> group_column                 shared: column group
    Group order                                    -> group_order                  shared: group
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results
    Comparison                                     -> comparison                   
    Significance style                             -> significance_style           
    Show nonsignificant                            -> show_nonsignificant          shared: show
    Show effect sizes                              -> show_effect_sizes            shared: show
    Annotation layout                              -> annotation_layout            
    Alpha                                          -> alpha                        
    left Value range (bottom/top)                  -> left_Value_range             shared: range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range value
    Gridline mode                                  -> gridline_mode                
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results

## Violin Plot -- Column Mapping  (line 6348, 23 fields)

    heading: 📋 Select columns from your Table.
    heading: 📐 Y-axis (both 0 = auto)
    heading: 📈 Your analysis found a result to put on this figure.

    Value column                                   -> value_column                 shared: column value
    Group column                                   -> group_column                 shared: column group
    Group order                                    -> group_order                  shared: group
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results
    Comparison                                     -> comparison                   
    Significance style                             -> significance_style           
    Show nonsignificant                            -> show_nonsignificant          shared: show
    Show effect sizes                              -> show_effect_sizes            shared: show
    Annotation layout                              -> annotation_layout            
    Alpha                                          -> alpha                        
    Show jittered points                           -> show_jittered_points         shared: show
    left Value range (bottom/top)                  -> left_Value_range             shared: range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range value
    Gridline mode                                  -> gridline_mode                
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results

## Scatter Plot -- Column Mapping  (line 6864, 24 fields)

    heading: 📋 Select columns from your Table.
    heading: 📊 Analysis
    heading: 📐 Axis (both 0 = auto)
    heading: 🎨 Layout

    X column                                       -> x_column                     shared: column
    Y column                                       -> y_column                     shared: column
    Use group column                               -> use_group_column             shared: column group
    Group column                                   -> group_column                 shared: column group
    Group order                                    -> group_order                  shared: group
    Correlation method                             -> correlation_method           
    Regression                                     -> regression                   
    Significance style                             -> significance_style           
    Show data points                               -> show_data_points             shared: show
    Dot size                                       -> dot_size                     
    left X range (left/right)                      -> left_X_range                 shared: left range right
    right X range (left/right)                     -> right_X_range                shared: left range right
    left Y range (bottom/top)                      -> left_Y_range                 shared: left range
    right Y range (bottom/top)                     -> right_Y_range                shared: range right
    Gridline mode                                  -> gridline_mode                
    Legend placement (when drawn)                  -> legend_placement             
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label

## Box Plot -- Column Mapping  (line 7331, 23 fields)

    heading: 📋 Select columns from your Table.
    heading: 📐 Y-axis (both 0 = auto)
    heading: 📈 Your analysis found a result to put on this figure.

    Value column                                   -> value_column                 shared: column value
    Group column                                   -> group_column                 shared: column group
    Group order                                    -> group_order                  shared: group
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results
    Comparison                                     -> comparison                   
    Significance style                             -> significance_style           
    Show nonsignificant                            -> show_nonsignificant          shared: show
    Show effect sizes                              -> show_effect_sizes            shared: show
    Annotation layout                              -> annotation_layout            
    Alpha                                          -> alpha                        
    Show jittered points                           -> show_jittered_points         shared: show
    left Value range (bottom/top)                  -> left_Value_range             shared: range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range value
    Gridline mode                                  -> gridline_mode                
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results

## Histogram -- Column Mapping  (line 7763, 26 fields)

    heading: 📋 Select columns from your Table.
    heading: 📊 Binning
    heading: 📊 Grouped display
    heading: Comparisons appear as a matrix panel below the plot.
    heading: 📐 Axis (both 0 = auto)
    heading: 📈 Your analysis found a result to put on this figure.

    Value column                                   -> value_column                 shared: column value
    Use group column                               -> use_group_column             shared: column group
    Group column                                   -> group_column                 shared: column group
    Group order                                    -> group_order                  shared: group
    Bin count (0 = auto)                           -> bin_count                    
    Display mode                                   -> display_mode                 shared: mode
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results
    Comparison                                     -> comparison                   
    Significance style                             -> significance_style           
    Show nonsignificant                            -> show_nonsignificant          shared: show
    Show effect sizes                              -> show_effect_sizes            shared: show
    Alpha                                          -> alpha                        
    left Value range (bottom/top)                  -> left_Value_range             shared: range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range value
    Frequency maximum (0 = auto)                   -> frequency_maximum            
    Gridline mode                                  -> gridline_mode                shared: mode
    Legend placement (when drawn)                  -> legend_placement             
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results

## Grouped Violin -- Column Mapping  (line 8309, 24 fields)

    heading: 📋 Select columns from your Table.
    heading: Comparisons appear as a matrix panel below the plot.
    heading: 📐 Y-axis (both 0 = auto)
    heading: 📈 Your analysis found a result to put on this figure.

    Value column                                   -> value_column                 shared: column value
    Category column                                -> category_column              shared: column
    Subgroup column                                -> subgroup_column              shared: column
    Group order                                    -> group_order                  
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results
    Comparison                                     -> comparison                   
    Significance style                             -> significance_style           
    Show nonsignificant                            -> show_nonsignificant          shared: show
    Show effect sizes                              -> show_effect_sizes            shared: show
    Alpha                                          -> alpha                        
    Show jittered points                           -> show_jittered_points         shared: show
    left Value range (bottom/top)                  -> left_Value_range             shared: range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range value
    Gridline mode                                  -> gridline_mode                
    Legend placement (when drawn)                  -> legend_placement             
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results

## Grouped Box Plot -- Column Mapping  (line 8762, 24 fields)

    heading: 📋 Select columns from your Table.
    heading: Comparisons appear as a matrix panel below the plot.
    heading: 📐 Y-axis (both 0 = auto)
    heading: 📈 Your analysis found a result to put on this figure.

    Value column                                   -> value_column                 shared: column value
    Category column                                -> category_column              shared: column
    Subgroup column                                -> subgroup_column              shared: column
    Group order                                    -> group_order                  
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results
    Comparison                                     -> comparison                   
    Significance style                             -> significance_style           
    Show nonsignificant                            -> show_nonsignificant          shared: show
    Show effect sizes                              -> show_effect_sizes            shared: show
    Alpha                                          -> alpha                        
    Show jittered points                           -> show_jittered_points         shared: show
    left Value range (bottom/top)                  -> left_Value_range             shared: range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range value
    Gridline mode                                  -> gridline_mode                
    Legend placement (when drawn)                  -> legend_placement             
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label
    Annotate results on graph                      -> annotate_results_on_graph    shared: annotate graph results

## Spaghetti Plot -- Column Mapping  (line 9225, 20 fields)

    heading: 📋 Select columns from your Table.
    heading: 📐 Y-axis (both 0 = auto)

    Value column (Y-axis)                          -> value_column                 shared: axis column value
    Condition column (X-axis)                      -> condition_column             shared: axis column
    Subject column (participant ID)                -> subject_column               shared: column
    Use group column                               -> use_group_column             shared: column group
    Group column (colors lines)                    -> group_column                 shared: column group
    Group order                                    -> group_order                  shared: group
    Show mean overlay                              -> show_mean_overlay            shared: show
    Line style                                     -> line_style                   
    left Value range (bottom/top)                  -> left_Value_range             shared: range value
    right Value range (bottom/top)                 -> right_Value_range            shared: range value
    Gridline mode                                  -> gridline_mode                
    Legend placement (when drawn)                  -> legend_placement             
    Output DPI                                     -> output_DPI                   
    Show inner box                                 -> show_inner_box               shared: show
    Show axis names                                -> show_axis_names              shared: axis show
    Show ticks                                     -> show_ticks                   shared: show
    Show axis values                               -> show_axis_values             shared: axis show value
    Font                                           -> font                         
    X axis label                                   -> x_axis_label$                shared: axis label
    Y axis label                                   -> y_axis_label$                shared: axis label


pages listed: 15
