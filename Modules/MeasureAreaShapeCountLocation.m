function handles = AlgMeasureAreaShapeCountLocation(handles)

% Help for the Measure Area Shape Count Location module:
% Category: Measurement
%
% Given an image with objects identified (e.g. nuclei or cells), this
% module makes measurements of each object, including area (and
% perimeter), shape (several measures), count, and location.
% Measurements are recorded for each object, and some population
% measurements are calculated: Mean, Median, Standard Deviation, and
% in some cases Sum. The units of the measurements are based on the
% pixel size the user entered in the main window of CellProfiler.  If
% pixel size = 1, then the measurements are in pixels.
%
% TECHNICAL NOTES: Retrieves a segmented image, in label matrix format
% and makes lots of measurements of the objects that are segmented in
% the image. The label matrix image should be "compacted": I mean that
% each number should correspond to an object, with no numbers skipped.
% So, if some objects were discarded from the label matrix image, the
% image should be converted to binary and re-made into a label matrix
% image before feeding into this module.
%
% See also ALGMEASUREAREAOCCUPIED,
% ALGMEASURECORRELATION,
% ALGMEASUREINTENSITYTEXTURE,
% ALGMEASURETOTALINTENSITY.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
% 
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
% 
% Authors:
%   Anne Carpenter <carpenter@wi.mit.edu>
%   Thouis Jones   <thouis@csail.mit.edu>
%   In Han Kang    <inthek@mit.edu>
%
% $Revision$

% PROGRAMMING NOTE
% HELP:
% The first unbroken block of lines will be extracted as help by
% CellProfiler's 'Help for this analysis module' button as well as
% Matlab's built in 'help' and 'doc' functions at the command line. It
% will also be used to automatically generate a manual page for the
% module. An example image demonstrating the function of the module
% can also be saved in tif format, using the same name as the
% module (minus Alg), and it will automatically be included in the
% manual page as well.  Follow the convention of: purpose of the
% module, description of the variables and acceptable range for each,
% how it works (technical description), info on which images can be 
% saved, and See also CAPITALLETTEROTHERMODULES. The license/author
% information should be separated from the help lines with a blank
% line so that it does not show up in the help displays.  Do not
% change the programming notes in any modules! These are standard
% across all modules for maintenance purposes, so anything
% module-specific should be kept separate.

% PROGRAMMING NOTE
% DRAWNOW:
% The 'drawnow' function allows figure windows to be updated and
% buttons to be pushed (like the pause, cancel, help, and view
% buttons).  The 'drawnow' function is sprinkled throughout the code
% so there are plenty of breaks where the figure windows/buttons can
% be interacted with.  This does theoretically slow the computation
% somewhat, so it might be reasonable to remove most of these lines
% when running jobs on a cluster where speed is important.
drawnow

%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%

% PROGRAMMING NOTE
% VARIABLE BOXES AND TEXT: 
% The '%textVAR' lines contain the text which is displayed in the GUI
% next to each variable box. The '%defaultVAR' lines contain the
% default values which are displayed in the variable boxes when the
% user loads the module. The line of code after the textVAR and
% defaultVAR extracts the value that the user has entered from the
% handles structure and saves it as a variable in the workspace of
% this module with a descriptive name. The syntax is important for
% the %textVAR and %defaultVAR lines: be sure there is a space before
% and after the equals sign and also that the capitalization is as
% shown.  Don't allow the text to wrap around to another line; the
% second line will not be displayed.  If you need more space to
% describe a variable, you can refer the user to the help file, or you
% can put text in the %textVAR line above or below the one of
% interest, and do not include a %defaultVAR line so that the variable
% edit box for that variable will not be displayed; the text will
% still be displayed. Keep in mind that you can have
% several inputs into the same box: for example, a box could be
% designed to receive two numbers separated by a comma, as long as you
% write a little extraction algorithm that separates the input into
% two distinct variables.  Any extraction algorithms like this should
% be within the VARIABLES section of the code, at the end.

%%% Reads the current module number, because this is needed to find 
%%% the variable values that the user entered.
CurrentModule = handles.Current.CurrentModuleNumber;
CurrentModuleNum = str2double(CurrentModule);

%textVAR01 = What did you call the segmented objects that you want to measure?
%defaultVAR01 = Nuclei
ObjectNameList{1} = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%textVAR02 = Type / in unused boxes.
%defaultVAR02 = Cells
ObjectNameList{2} = char(handles.Settings.VariableValues{CurrentModuleNum,2});
%textVAR03 = 
%defaultVAR03 = /
ObjectNameList{3} = char(handles.Settings.VariableValues{CurrentModuleNum,3});
%textVAR04 = 
%defaultVAR04 = /
ObjectNameList{4} = char(handles.Settings.VariableValues{CurrentModuleNum,4});
%textVAR05 = 
%defaultVAR05 = /
ObjectNameList{5} = char(handles.Settings.VariableValues{CurrentModuleNum,5});
%textVAR06 = It is easy to expand the code for more than 5 objects. See AlgMeasureAreaShapeCountLocation.m for details.

%%% To expand for more than 5 objects, just add more lines in groups
%%% of three like those above, then change the line about ten lines
%%% down from here (for i = 1:5).

%%% Retrieves the pixel size that the user entered (micrometers per pixel).
PixelSize = str2double(handles.Settings.PixelSize);

%%% POTENTIAL IMPROVEMENT: Allow the user to select which measurements will
%%% be made, particularly for those which take a long time to calculate?
%%% Probably not a good idea: we want the measurements coming out to be
%%% uniform from experiment to experiment so as to have comparable data for
%%% comparing experiments.  If the user wants to skip some measurements,
%%% they can alter this .m file to comment out the measurements.

%%% START LOOP THROUGH ALL THE OBJECTS
for i = 1:5
    ObjectName = ObjectNameList{i};
if strcmp(ObjectName,'/') == 1
break
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Retrieves the label matrix image that contains the segmented objects which
%%% will be measured with this module.
fieldname = ['Segmented', ObjectName];
%%% Checks whether the image exists in the handles structure.
if isfield(handles.Pipeline, fieldname)==0,
    error(['Image processing has been canceled. Prior to running the Measure module, you must have previously run a module that generates an image with the objects identified.  You specified in the Measure module that the primary objects were named ',ObjectName,' which should have produced an image in the handles structure called ', fieldname, '. The Measure module cannot locate this image.']);
end
LabelMatrixImage = handles.Pipeline.(fieldname);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MAKE MEASUREMENTS & SAVE TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

% PROGRAMMING NOTE
% HANDLES STRUCTURE:
%       In CellProfiler (and Matlab in general), each independent
% function (module) has its own workspace and is not able to 'see'
% variables produced by other modules. For data or images to be shared
% from one module to the next, they must be saved to what is called
% the 'handles structure'. This is a variable, whose class is
% 'structure', and whose name is handles. Data which should be saved
% to the handles structure within each module includes: any images,
% data or measurements which are to be eventually saved to the hard
% drive (either in an output file, or using the SaveImages module) or
% which are to be used by a later module in the analysis pipeline. Any
% module which produces or passes on an image needs to also pass along
% the original filename of the image, named after the new image name,
% so that if the SaveImages module attempts to save the resulting
% image, it can be named by appending text to the original file name.
% handles.Pipeline is for storing data which must be retrieved by other modules.
% This data can be overwritten as each image set is processed, or it
% can be generated once and then retrieved during every subsequent image
% set's processing, or it can be saved for each image set by
% saving it according to which image set is being analyzed.
%       Anything stored in handles.Measurements or handles.Pipeline
% will be deleted at the end of the analysis run, whereas anything
% stored in handles.Settings will be retained from one analysis to the
% next. It is important to think about which of these data should be
% deleted at the end of an analysis run because of the way Matlab
% saves variables: For example, a user might process 12 image sets of
% nuclei which results in a set of 12 measurements ("TotalNucArea")
% stored in the handles structure. In addition, a processed image of
% nuclei from the last image set is left in the handles structure
% ("SegmNucImg"). Now, if the user uses a different module which
% happens to have the same measurement output name "TotalNucArea" to
% analyze 4 image sets, the 4 measurements will overwrite the first 4
% measurements of the previous analysis, but the remaining 8
% measurements will still be present. So, the user will end up with 12
% measurements from the 4 sets. Another potential problem is that if,
% in the second analysis run, the user runs only a module which
% depends on the output "SegmNucImg" but does not run a module
% that produces an image by that name, the module will run just
% fine: it will just repeatedly use the processed image of nuclei
% leftover from the last image set, which was left in the handles
% structure ("SegmNucImg").
%       Note that two types of measurements are typically made: Object
% and Image measurements.  Object measurements have one number for
% every object in the image (e.g. ObjectArea) and image measurements
% have one number for the entire image, which could come from one
% measurement from the entire image (e.g. ImageTotalIntensity), or
% which could be an aggregate measurement based on individual object
% measurements (e.g. ImageMeanArea).  Use the appropriate prefix to
% ensure that your data will be extracted properly.
%       Saving measurements: The data extraction functions of
% CellProfiler are designed to deal with only one "column" of data per
% named measurement field. So, for example, instead of creating a
% field of XY locations stored in pairs, they should be split into a field
% of X locations and a field of Y locations. Measurements must be
% stored in double format, because the extraction part of the program
% is designed to deal with that type of array only, not cell or
% structure arrays. It is wise to include the user's input for
% 'ObjectName' as part of the fieldname in the handles structure so
% that multiple modules can be run and their data will not overwrite
% each other.
%       Extracting measurements: handles.Measurements.CenterXNuclei{1}(2) gives
% the X position for the second object in the first image.
% handles.Measurements.AreaNuclei{2}(1) gives the area of the first object in
% the second image.

%%%
%%% COUNT
%%%
    %%% Counts the number of objects in the label matrix image. This
    %%% does not require that the objects be contiguous. Strange
    %%% results may ensue with non-contiguous objects. Subtracting the
    %%% 1 is necessary because zero (the background) would otherwise
    %%% be counted as an object.
    ObjectCount = length(unique(LabelMatrixImage(:))) - 1;
    %%% Saves the count to the handles structure.
    fieldname = ['ImageCount', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {ObjectCount};

if ObjectCount ~= 0
    %%% None of the measurements are made if there are no objects.

    %%% The regionprops command extracts a lot of measurements.  It
    %%% is most efficient to call the regionprops command once for all the
    %%% properties rather than calling it for each property separately.
    Statistics = regionprops(LabelMatrixImage,'Area', 'ConvexArea', 'MajorAxisLength', 'MinorAxisLength', 'Eccentricity', 'Solidity', 'Extent', 'Centroid');

    %%% CATCH NAN's -->>
    if sum(isnan(cat(1,Statistics.Solidity))) ~= 0
        error('Image processing was canceled because there was a problem in the Measure Area Shape Intensity Texture module. Some of the measurements could not be made.  This might be because some objects had zero area or because some measurements were attempted that were divided by zero. If you want to make measurements despite this problem, remove the 3 lines in the .m file for this module following the line CATCH NANs. This will result in some non-numeric values in the output file, which will be represented as NaN (Not a Number).')
    end

    %%%
    %%% AREA
    %%%

    %%% Makes the Area array a double object rather than a cell or struct
    %%% object.
    Area = cat(1,Statistics.Area);
    %%% Converts the measurement to micrometers.  Converts the number of pixels
    %%% to micrometers squared.
    Area = Area.*(PixelSize*PixelSize);
    %%% Saves the areas to the handles structure.
    fieldname = ['ObjectArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {Area};
    fieldname = ['ImageMeanArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(Area)};
    fieldname = ['ImageStdevArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(Area)};
    fieldname = ['ImageMedianArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(Area)};
    fieldname = ['ImageSumArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {sum(Area)};

    %%%
    %%% PERIMETER
    %%%

    %%% Shifts labels in each of the 4 cardinal directions (stretching the
    %%% exposed row/column), and compares to the original labels.
    temp_labels = LabelMatrixImage .* ((LabelMatrixImage ~= LabelMatrixImage([1 1:end-1], :)) | ...
        (LabelMatrixImage ~= LabelMatrixImage([2:end end], :)) | ...
        (LabelMatrixImage ~= LabelMatrixImage(:, [1 1:end-1], :)) | ...
        (LabelMatrixImage ~= LabelMatrixImage(:, [2:end end])));
    %%% Finds the locations and labels for perimeter pixels.
    perim_locations = find(temp_labels);
    perim_labels = LabelMatrixImage(perim_locations);
    %%% Creates a sparse matrix with column as label and row as location,
    %%% with a 1 at (A,B) if location A has label B.  Summing the columns
    %%% gives the count of perimeter pixels with a given label.
    Perimeter = full(sum(sparse(perim_locations, perim_labels, 1)));
    Perimeter = Perimeter';
    %%% Converts the measurement to micrometers.
    Perimeter = Perimeter*PixelSize;
    %%% Saves Perimeters to handles structure.
    fieldname = ['ObjectPerimeter', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {Perimeter};
    fieldname = ['ImageMeanPerimeter', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(Perimeter)};
    fieldname = ['ImageStdevPerimeter', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(Perimeter)};
    fieldname = ['ImageMedianPerimeter', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(Perimeter)};

    %%%
    %%% CONVEX AREA
    %%%

    %%% Makes the ConvexAreas array a double object rather than a cell or struct
    %%% object.
    ConvexArea = cat(1,Statistics.ConvexArea);
    %%% Converts the measurement to micrometers. The number of pixels is
    %%% converted to micrometers squared.
    ConvexArea = ConvexArea.*(PixelSize*PixelSize);
    %%% Saves the areas to the handles structure.
    fieldname = ['ObjectConvexArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {ConvexArea};
    fieldname = ['ImageMeanConvexArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(ConvexArea)};
    fieldname = ['ImageStdevConvexArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(ConvexArea)};
    fieldname = ['ImageMedianConvexArea', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(ConvexArea)};

    %%%
    %%% MAJOR AXIS
    %%%

    %%% Makes the major axis array a double object rather than a cell or struct
    %%% object.
    MajorAxis = cat(1,Statistics.MajorAxisLength);
    %%% Converts the measurement to micrometers.
    MajorAxis = MajorAxis*PixelSize;
    %%% Saves the major axis lengths to the handles structure.
    fieldname = ['ObjectMajorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {MajorAxis};
    fieldname = ['ImageMeanMajorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(MajorAxis)};
    fieldname = ['ImageStdevMajorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(MajorAxis)};
    fieldname = ['ImageMedianMajorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(MajorAxis)};

    %%%
    %%% MINOR AXIS
    %%%

    %%% Makes the minor axis array a double object rather than a cell or struct
    %%% object.
    MinorAxis = cat(1,Statistics.MinorAxisLength);
    %%% Converts the measurement to micrometers.
    MinorAxis = MinorAxis*PixelSize;
    %%% Saves the minor axis lengths to the handles structure.
    fieldname = ['ObjectMinorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {MinorAxis};
    fieldname = ['ImageMeanMinorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(MinorAxis)};
    fieldname = ['ImageStdevMinorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(MinorAxis)};
    fieldname = ['ImageMedianMinorAxis', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(MinorAxis)};

    %%%
    %%% ECCENTRICITY
    %%%

    %%% The eccentricity of the ellipse that has the same second-moments as the
    %%% region. The eccentricity is the ratio of the distance between the foci
    %%% of the ellipse and its major axis length. The value is between 0 and 1.
    %%% (0 and 1 are degenerate cases; an ellipse whose eccentricity is 0 is
    %%% actually a circle, while an ellipse whose eccentricity is 1 is a line
    %%% segment.)  Other sources define Eccentricity as the ratio of the major
    %%% axis to the minor axis, but I have named that "Aspect Ratio" below
    %%% since it is apparently calculated differently than Matlab's
    %%% eccentricity measurement.

    %%% Makes the Eccentricity array a double object rather than a cell or struct
    %%% object.
    Eccentricity = cat(1,Statistics.Eccentricity);
    %%% Note: No need to convert the measurement to micrometers because it is
    %%% dimensionless.
    %%% Saves the Eccentricities to the handles structure.
    fieldname = ['ObjectEccentricity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {Eccentricity};
    fieldname = ['ImageMeanEccentricity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(Eccentricity)};
    fieldname = ['ImageStdevEccentricity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(Eccentricity)};
    fieldname = ['ImageMedianEccentricity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(Eccentricity)};

    %%%
    %%% SOLIDITY
    %%%

    %%% Solidity is the proportion of pixels in the convex hull that are also
    %%% in the region. Defined as Area/Convex area.

    %%% Makes the solidity array a double object rather than a cell or struct
    %%% object.
    Solidity = cat(1,Statistics.Solidity);
    %%% Note: No need to convert the measurement to micrometers because it is
    %%% dimensionless.
    %%% Saves the Solidities to the handles structure.
    fieldname = ['ObjectSolidity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {Solidity};
    fieldname = ['ImageMeanSolidity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(Solidity)};
    fieldname = ['ImageStdevSolidity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(Solidity)};
    fieldname = ['ImageMedianSolidity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(Solidity)};

    %%%
    %%% EXTENT
    %%%

    %%% Extent is the proportion of the pixels in the convex hull that are also
    %%% in the region. (Area divided by the area of the bounding box).

    %%% Makes the Extent array a double object rather than a cell or struct
    %%% object.
    Extent = cat(1,Statistics.Extent);
    %%% Note: No need to convert the measurement to micrometers because it is
    %%% dimensionless.
    %%% Saves the Extents to the handles structure.
    fieldname = ['ObjectExtent', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {Extent};
    fieldname = ['ImageMeanExtent', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(Extent)};
    fieldname = ['ImageStdevExtent', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(Extent)};
    fieldname = ['ImageMedianExtent', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(Extent)};

    %%%
    %%% CIRCULARITY
    %%%

    %%% Defined as Perimeter squared divided by Area.  Conversion to
    %%% micrometers was already done above; the result of the calculation below
    %%% is dimensionless anyway.
    Circularity = (Perimeter.*Perimeter)./Area;
    fieldname = ['ObjectCircularity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {Circularity};
    fieldname = ['ImageMeanCircularity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(Circularity)};
    fieldname = ['ImageStdevCircularity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(Circularity)};
    fieldname = ['ImageMedianCircularity', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(Circularity)};

    %%%
    %%% FORM FACTOR
    %%%

    %%% Defined as 4pi*Area divided by the Perimeter squared. Conversion to
    %%% micrometers was already done above; the result of the calculation below
    %%% is dimensionless anyway.
    FormFactor = 4*pi.*Area./(Perimeter.*Perimeter);
    fieldname = ['ObjectFormFactor', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {FormFactor};
    fieldname = ['ImageMeanFormFactor', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(FormFactor)};
    fieldname = ['ImageStdevFormFactor', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(FormFactor)};
    fieldname = ['ImageMedianFormFactor', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(FormFactor)};

    %%%
    %%% AREA TO PERIMETER RATIO
    %%%

    %%% Conversion to micrometers was already done above.
    AreaPerimRatio = Area./Perimeter;

    fieldname = ['ObjectAreaPerimRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {AreaPerimRatio};
    fieldname = ['ImageMeanAreaPerimRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(AreaPerimRatio)};
    fieldname = ['ImageStdevAreaPerimRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(AreaPerimRatio)};
    fieldname = ['ImageMedianAreaPerimRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(AreaPerimRatio)};

    %%%
    %%% ASPECT RATIO
    %%%

    %%% This should really be the maximum diameter divided by the minimum
    %%% diameter, but those measurements would add a lot of time to measure.
    %%% Conversion to micrometers was already done above; the result of the
    %%% calculation below is dimensionless anyway.

    AspectRatio = MajorAxis./MinorAxis;

    fieldname = ['ObjectAspectRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {AspectRatio};
    fieldname = ['ImageMeanAspectRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {mean(AspectRatio)};
    fieldname = ['ImageStdevAspectRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {std(AspectRatio)};
    fieldname = ['ImageMedianAspectRatio', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {median(AspectRatio)};

    %%%
    %%% CENTER POSITIONS
    %%%

    %%% Note that the X, Y locations are stored as the pixel locations (not
    %%% converted to micrometers.)

    %%% Makes the Centers array a double object rather than a cell or struct
    %%% object.  There are two columns in this array, the first is X and the
    %%% second is Y, so they are extracted into two separate variables, CentersX
    %%% and CentersY.
    CentersXY = cat(1,Statistics.Centroid);
    CentersX = CentersXY(:,1);
    CentersY = CentersXY(:,2);
    %%% Saves X and Y positions to handles structure.
    fieldname = ['ObjectCenterX', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {CentersX};
    fieldname = ['ObjectCenterY', ObjectName];
    handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {CentersY};

end % Goes with: if no objects are in the image.

%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%

% PROGRAMMING NOTE
% DISPLAYING RESULTS:
% Each module checks whether its figure is open before calculating
% images that are for display only. This is done by examining all the
% figure handles for one whose handle is equal to the assigned figure
% number for this module. If the figure is not open, everything
% between the "if" and "end" is ignored (to speed execution), so do
% not do any important calculations here. Otherwise an error message
% will be produced if the user has closed the window but you have
% attempted to access data that was supposed to be produced by this
% part of the code. If you plan to save images which are normally
% produced for display only, the corresponding lines should be moved
% outside this if statement.

fieldname = ['FigureNumberForModule',CurrentModule];
ThisAlgFigureNumber = handles.Current.(fieldname);
if any(findobj == ThisAlgFigureNumber) == 1;
    figure(ThisAlgFigureNumber);
    originalsize = get(ThisAlgFigureNumber, 'position');
    newsize = originalsize;
    if handles.Current.SetBeingAnalyzed == 1 && i == 1
        newsize(3) = originalsize(3)*.5;
        set(ThisAlgFigureNumber, 'position', newsize);
    end
    newsize(1) = 0;
    newsize(2) = 0;
    displaytexthandle = uicontrol(ThisAlgFigureNumber,'style','text', 'position', newsize,'fontname','fixedwidth','backgroundcolor',[0.7,0.7,0.7]);
    if i == 1
        displaytext =[];
    end
    %%% Note that the number of spaces after each measurement name results in
    %%% the measurement numbers lining up properly when displayed in a fixed
    %%% width font.  Also, it costs less than 0.1 seconds to do all of these
    %%% calculations, so I won't bother to retrieve the already calculated
    %%% means and sums from each measurement's code above.
    %%% Checks whether any objects were found in the image.
    if sum(sum(LabelMatrixImage)) == 0
        displaytext = strvcat(displaytext,['      Image Set # ',num2str(handles.Current.SetBeingAnalyzed)],... %#ok We want to ignore MLint error checking for this line.
            ['Number of ', ObjectName ,':      zero']);
    else
        displaytext = strvcat(displaytext,['      Image Set # ',num2str(handles.Current.SetBeingAnalyzed)],... %#ok We want to ignore MLint error checking for this line.
            ['Number of ', ObjectName ,':      ', num2str(ObjectCount)],...
            ['SumArea:                  ', num2str(sum(Area))],...
            ['MeanArea:                 ', num2str(mean(Area))],...
            ['MeanPerimeter:            ', num2str(mean(Perimeter))],...
            ['MeanConvexArea:           ', num2str(mean(ConvexArea))],...
            ['MeanMajorAxis:            ', num2str(mean(MajorAxis))],...
            ['MeanMinorAxis:            ', num2str(mean(MinorAxis))],...
            ['MeanEccentricity:         ', num2str(mean(Eccentricity))],...
            ['MeanSolidity:             ', num2str(mean(Solidity))],...
            ['MeanExtent:               ', num2str(mean(Extent))],...
            ['MeanCircularity:          ', num2str(mean(Circularity))],...
            ['MeanFormFactor:           ', num2str(mean(FormFactor))],...
            ['MeanAreaPerimRatio:       ', num2str(mean(AreaPerimRatio))],...
            ['MeanAspectRatio:          ', num2str(mean(AspectRatio))]);
    end % Goes with: if no objects were in the label matrix image.
    set(displaytexthandle,'string',displaytext)
end
end
% PROGRAMMING NOTES THAT ARE UNNECESSARY FOR THIS MODULE:
% PROGRAMMING NOTE
% TO TEMPORARILY SHOW IMAGES DURING DEBUGGING: 
% figure, imshow(BlurredImage, []), title('BlurredImage') 
% TO TEMPORARILY SAVE IMAGES DURING DEBUGGING: 
% imwrite(BlurredImage, FileName, FileFormat);
% Note that you may have to alter the format of the image before
% saving.  If the image is not saved correctly, for example, try
% adding the uint8 command:
% imwrite(uint8(BlurredImage), FileName, FileFormat);
% To routinely save images produced by this module, see the help in
% the SaveImages module.

% PROGRAMMING NOTE
% DRAWNOW BEFORE FIGURE COMMAND:
% The "drawnow" function executes any pending figure window-related
% commands.  In general, Matlab does not update figure windows until
% breaks between image analysis modules, or when a few select commands
% are used. "figure" and "drawnow" are two of the commands that allow
% Matlab to pause and carry out any pending figure window- related
% commands (like zooming, or pressing timer pause or cancel buttons or
% pressing a help button.)  If the drawnow command is not used
% immediately prior to the figure(ThisAlgFigureNumber) line, then
% immediately after the figure line executes, the other commands that
% have been waiting are executed in the other windows.  Then, when
% Matlab returns to this module and goes to the subplot line, the
% figure which is active is not necessarily the correct one. This
% results in strange things like the subplots appearing in the timer
% window or in the wrong figure window, or in help dialog boxes.