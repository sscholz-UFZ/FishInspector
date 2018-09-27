function output_ = pericard_fishPlugin(fobj, varargin)
% Yolk - FishPlugin
% Detects the yolk of the Fish
%
% Scientific Software Solutions
% Tobias Kießling 05/2016-01/2017
% support@tks3.de

    %% Plugin Header (Do NOT edit except for the indicated section)
    if ~isdeployed && ~(exist(fullfile(pwd, 'fish_plugin_class.m'), 'file')==2), cd(fileparts(pwd)); end
    thisPlugin = fish_plugin_class;  
    % Link Parameter and Display/Debug Definitions
    thisPlugin.ParameterDefinitionsFCN  = @ParameterDefinitions;
    % Link Callbacks
    thisPlugin.calculationFunction = @(varargin) CalculationFunction(thisPlugin.fish, varargin{:});
    thisPlugin.ManualSelectionFcn  = @(varargin) manualModeFunction( thisPlugin.fish, varargin{:});    
    thisPlugin.drawingFunction     = @(varargin) DrawingFunction(    thisPlugin.fish, varargin{:});
    thisPlugin.mainDrawingFunction = @(varargin) MainDrawingFunction(thisPlugin.fish, varargin{:});
    % ----- EDIT ONLY FROM HERE -------------------------
    thisPlugin.plugin_tag          = 'pericard';
    thisPlugin.plugin_name         = 'Pericard';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {'fishContour', 'centralDarkLine', 'fishEye', 'yolk'};
    thisPlugin.hasManualMode       = true;
    thisPlugin.helpURL             = 'help\pericard.html';
    % ----- ...UNTIL HERE -------------------------------
    % Debugging/Developing:
    if ~ismember('getFishPlugin', varargin) % Called without argument?
        if ~exist('fobj', 'var')            % No fishobject was provided? 
            fobj = thisPlugin.uiGetFish;    % => Let the user select an image file)
        end  
        thisPlugin.set_fishobj(fobj);
        thisPlugin.GUIcreationFCN();        % => Create ParameterPannel
    end
    output_ = thisPlugin;
    output = [];
    %% Plugin Functions (Here is where the Parameters, Calculations, and Drawings are implemented)
    
    function [parameter, displays, debugs] = ParameterDefinitions(fobj)

        % ===========    TAG                        NAME                        TYPE        DEFAULT     MIN     MAX     INCREMENT   HasAuto  
        parameter = {'cutoff_left',              'Eye Offset',               'numeric',  0.05,       0,      1,      0.005,      false;...};
                     'threshMultiplier',         'Autothresh multiplier',    'numeric',  1,        0,      inf,    0.05,       false};%;...
                    ...    'cutoff_right',             'Rear Cutoff',              'numeric',  0.44,       0,      1,      0.005,      false};...
                    ...    'min_peak_width',           'MinPeakWidth',             'numeric',  0.01,       0,      1,      0.005,      false;...
                    ...    'binary_contour_smoothing', 'BinaryContourSmoothing',   'numeric',  0.07,       0,      1,      0.005,      false};

        % ===========   TAG                     NAME                    DEFAULT     AddOPACITY     OpacityDEFAULT
%         displays  = {   'plot_binary_shape',    'plot_binary_shape',    true,       false,         NaN;...
%                         'plot_fine_contour',    'plot_fine_contour',    true,       false,         NaN};
        displays = {};
                    
                    
        % ===========   TAG                         NAME                    DebugTAG                AddOPACITY      OpacityDEFAULT
%        debugs    = {  'debug_detectFineContour',   'debug_fineContours',   'yolk',            false,          NaN     };
        debugs = {};
        
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;       % <= Set to true to apply new values
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end

    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
        
        % 1) Get input and flip if necessary
        im0 = fobj.getImdata('toGray');
        fContour = fobj.fishContour;
        fEye = fobj.fishEye;
        cdl = fobj.centralDarkLine;
        yolk = fobj.yolk;
        bladder = fobj.bladder;
        hasBladder = ~isempty(bladder) && ~isempty(bladder.shape) && ~any(cellfun(@isempty, {bladder.shape.x}));

        if fobj.fishOrientation.horizontally_flipped
            im0 = im0(:, end:-1:1);
            fContour.shape(1).x = size(im0, 2) - fContour.shape(1).x(end:-1:1) + 1;
            fContour.shape(1).y = fContour.shape(1).y(end:-1:1);
            fContour.shape(2).x = size(im0, 2) - fContour.shape(2).x(end:-1:1) + 1;
            fContour.shape(2).y = fContour.shape(2).y(end:-1:1);
            fEye.shape.x = size(im0, 2) - fEye.shape.x(end:-1:1) + 1;
            fEye.shape.y = fEye.shape.y(end:-1:1);
            cdl.shape.x  = size(im0, 2) - cdl.shape.x(end:-1:1) + 1;
            cdl.shape.y  = cdl.shape.y(end:-1:1);
            yolk.shape(1).x = size(im0, 2) - yolk.shape(1).x(end:-1:1) + 1;
            yolk.shape(1).y = yolk.shape(1).y(end:-1:1);
            yolk.shape(2).x = size(im0, 2) - yolk.shape(2).x(end:-1:1) + 1;
            yolk.shape(2).y = yolk.shape(2).y(end:-1:1);
            if hasBladder
                bladder.shape(1).x = size(im0, 2) - bladder.shape(1).x(end:-1:1) + 1;
                bladder.shape(1).y = bladder.shape(1).y(end:-1:1);
                bladder.shape(2).x = size(im0, 2) - bladder.shape(2).x(end:-1:1) + 1;
                bladder.shape(2).y = bladder.shape(2).y(end:-1:1);
            end
        end
        if fobj.fishOrientation.vertically_flipped
            im0 = im0(end:-1:1, :);
            fContour.shape(1).y = size(im0, 1) - fContour.shape(1).y + 1;
            fContour.shape(2).y = size(im0, 1) - fContour.shape(2).y + 1;
            fEye.shape.y = size(im0, 1) - fEye.shape.y + 1;
            cdl.shape.y = size(im0, 1) - cdl.shape.y + 1;
            yolk.shape(1).y = size(im0, 1) - yolk.shape(1).y + 1;
            yolk.shape(2).y = size(im0, 1) - yolk.shape(2).y + 1;
            if hasBladder
                bladder.shape(1).y = size(im0, 1) - bladder.shape(1).y + 1;
                bladder.shape(2).y = size(im0, 1) - bladder.shape(2).y + 1;
            end
        end
        
        
        % % %
        % A) Generate a mask to narrow down the region where to look for the yolk
        % A1) FishContour mask
        fineContour = fContour.shape(strcmpi({fContour.shape.name}, 'fineContour'));
        fineContour_mask = poly2mask(fineContour.x, fineContour.y, size(im0,1),  size(im0, 2));
        mask_correcture = (fineContour_mask==0) & ( (fineContour_mask([2:end,end],:)==1) | (fineContour_mask(:,[2:end,end])==1) | (fineContour_mask([2:end,end], [2:end,end])==1));
        fineContour_mask(mask_correcture) = 1;   
        % A2) Lower half of the fish (via central dark line)
        cdl_expanded = interp1(cdl.shape.x, cdl.shape.y, 1:size(im0,2));
        idx_mask = repmat(cdl_expanded, size(im0, 1), 1);
        row_mask = repmat((1:size(im0,1))', 1, size(im0,2));   
        cdl_mask = row_mask>idx_mask;
        % A2) Exclude the eye
        eye_mask = poly2mask(fEye.shape.x, fEye.shape.y, size(im0,1),  size(im0, 2));
        mask_correcture = (eye_mask==0) & ( (eye_mask([2:end,end],:)==1) | (eye_mask(:,[2:end,end])==1) | (eye_mask([2:end,end], [2:end,end])==1));
        eye_mask(mask_correcture) = 1;   
        % A3) Exclude the yolk
        fineContour = yolk.shape(strcmpi({yolk.shape.name}, 'fineContour'));
        yolk_mask = poly2mask(fineContour.x, fineContour.y, size(im0,1),  size(im0, 2));
        mask_correcture = (yolk_mask==0) & ( (yolk_mask([2:end,end],:)==1) | (yolk_mask(:,[2:end,end])==1) | (yolk_mask([2:end,end], [2:end,end])==1));
        yolk_mask(mask_correcture) = 1;
        yolk_mask(:, round(mean(fineContour.x)):end) = 1; % Remove everything which is right of the mid of the yolk
        % A3) remove bladder
        if hasBladder
            bladder = bladder.shape(strcmpi({bladder.shape.name}, 'fineContour'));
            bladder_mask = poly2mask(bladder.x, bladder.y, size(im0,1),  size(im0, 2));
            mask_correcture = (bladder_mask==0) & ( (bladder_mask([2:end,end],:)==1) | (bladder_mask(:,[2:end,end])==1) | (bladder_mask([2:end,end], [2:end,end])==1));
            bladder_mask(mask_correcture) = 1;
        else
            bladder_mask = false(size(fineContour_mask));
        end
        % A4) Finally combine all the masks
        mask = (fineContour_mask & cdl_mask & ~eye_mask & ~yolk_mask & ~bladder_mask);%|(round(row_mask)==round(idx_mask));
        % ----------------------- %

%         % % %
%         % B) Apply cutoffs
        fishLength = max(fineContour.x)-min(fineContour.x);
        minmask = find(any(mask, 1), 1, 'first');
        maxmask = find(any(mask, 1), 1, 'last');
        mask(:, 1:ceil(minmask+fishLength*parameterValues.cutoff_left)) = false;
        %mask(:, floor(maxmask-fishLength*parameterValues.cutoff_right):end) = false;
        
        % % % %
        % Get biggest region
        lmask = bwlabel(mask);
        rprops = regionprops(lmask);
        maxIDX = find([rprops.Area]==max([rprops.Area]), 1, 'first');
        mask = lmask==maxIDX;

        % % % %
        % Find bright region inside ROI
        mask_temp = imdilate(imerode(mask, ones(5)), ones(5));
        
        % Store mask so it can be displayed below
        output.mask_temp = mask_temp;
        if fobj.fishOrientation.horizontally_flipped
            output.mask_temp = output.mask_temp(:, end:-1:1);
        end
        if fobj.fishOrientation.vertically_flipped
            output.mask_temp = output.mask_temp(end:-1:1, :);
        end
        mask_boundary = bwboundaries(output.mask_temp);
        if ~isempty(mask_boundary)
            output.mask_boundary = mask_boundary{1};
        else
            output.mask_boundary = zeros(0,2);
        end
        
        % Apply threshold
        im1 = im0;
        auto_thresh = graythresh(im1(mask_temp));
        mask3 = im2bw(im1, auto_thresh.*parameterValues.threshMultiplier);
        mask = mask & mask3;

        mask = imdilate(imerode(mask, ones(5)), ones(5));

        % B) Get contour of the biggest region
        out = bwboundaries(mask);
        if isempty(out)
            out = zeros(0,2);
        else
            [~, maxIDX] = max(cellfun(@(x) size(x,1), out));
            out = out{maxIDX};
        end
        out = out(:,[2,1]);
        
        %if ~ishandle(43), figure(43), end; imshow(im0.*uint8(poly2mask(out(:,1), out(:,2), size(im0,1),  size(im0, 2))), 'parent', gca(43))
        
        if fobj.fishOrientation.horizontally_flipped
            out(:,1) = size(im0, 2) - out(end:-1:1, 1) + 1;
            out(:,2) = out(end:-1:1, 2);
        end
        if fobj.fishOrientation.vertically_flipped
            out(:,2) = size(im0, 1) - out(:,2) + 1;
        end
        
        %fineContour = detectFineContour(out(:,1), out(:,2), fobj, parameterValues, debugStatus);
        fineContour.x = out(:,1)';
        fineContour.y = out(:,2)';
        %% Return Output
        calculationResults = struct('mode',                 'auto',...
                                    'parameter',            parameterValues,...
                                    'shape',                struct('name',  'outline',...
                                                                   'x',     out(:,1)',...
                                                                   'y',     out(:,2)'));

             
        
    end

    function fineContour = detectFineContour(bf_x, bf_y, fobj, parameterValues, debugStatus)
        dbug_active_contour = debugStatus.debug_detectFineContour;

        cp = fobj.capillary.shape; namy = {cp.name};
        averageCapilaryWidth = round(mean(cp(strcmp(namy, 'lower')).y - cp(strcmp(namy, 'upper')).y));
        min_peak_width = max(1, round(parameterValues.min_peak_width * averageCapilaryWidth));
        
        % 1) Gather input
        im = fobj.getImdata(double(fobj.getImdata('toGray', 'invert')), 'normalize');

        % Calculate smooth boundary coordinates
        [ixi2, ysi2] = contour_smooth(bf_x, bf_y, max([1, round(length(bf_x)/2*parameterValues.binary_contour_smoothing)-1]));

%%        
        output.step1_inputImage = im;
        output.step1_contour = struct('x', ixi2, 'y', ysi2);

        % 2) Unwrap the Fish
        [imi, x_imi, y_imi] = imunwrap_poly(im, ixi2, ysi2);
        imi = fobj.getImdata(imi, 'normalize');
        output.step2_unwrappedFish = imi;

        % 3) Get modified PeakImage
        peakimage = getPeakImage(imi, min_peak_width);
        %peakimage = imi;
        %peakimage(peakimage<(max(peakimage(:))/2)) = ceil(max(peakimage(:))/2);
        output.step3_PeakImage = peakimage;

        % 4) Use some kind of active contour to get the fine position
        startline = repmat(ceil(size(peakimage,1)/2), 1, size(peakimage,2));
        fine_contour = fishobj2.move2extreme(peakimage, startline, 'max', true, dbug_active_contour);
        output.step4_startline = startline;
        output.step4_fineline  = fine_contour;

        
        % 5) Transform to cartesian coordinates
        indi = sub2ind(size(peakimage), fine_contour, 1:length(fine_contour));
        global_x = x_imi(indi);      % global
        global_y = y_imi(indi);
        % inner_y (note: inner_x is equal global_x)
        cp = fobj.capillary.shape;
        namy = {cp.name};
        middle = ( cp(strcmp(namy, 'upper_in')).y + cp(strcmp(namy, 'lower_in')).y ) /2;
        width = min(abs(cp(strcmp(namy, 'upper_in')).y - cp(strcmp(namy, 'lower_in')).y));

        inner_y = global_y-interp1(1:length(middle), middle, global_x)+floor(width/2)+1;

        output.step5_fineContour = struct( 'inner_x',     global_x,        'inner_y',          inner_y,...
                                           'global_x',    global_x,        'global_y',         global_y );
        
        precission = 10;                                
        fineContour = struct( 'name',     'fineContour',...
                              'x',        makePrecission(output.step5_fineContour.global_x(:)', precission),...
                              'y',        makePrecission(output.step5_fineContour.global_y(:)', precission));

        function roundVal = makePrecission(value, precission)
            roundVal = (round(precission.*value)./precission);
            roundVal = roundVal(:)';
        end
        
    end


    function manualModeFunction(fobj, ha, modeStatus, calculationResults,  parameterValues, debugStatus, ManualSelectionUpdateFCN)
               
        % Get parent figure
        hf = ancestor(ha.axes1, 'figure');
%        hacki  = [thisPlugin.parameterClassObject.handles.checkbox_plot_binary_shape];
%         hacki2 = [thisPlugin.parameterClassObject.handles.label_binary_contour_smoothing,...
%                   thisPlugin.parameterClassObject.handles.edit_binary_contour_smoothing,...
%                   thisPlugin.parameterClassObject.handles.pushbutton_decrease_binary_contour_smoothing,...
%                   thisPlugin.parameterClassObject.handles.pushbutton_increase_binary_contour_smoothing,...
%                   ...
%                   thisPlugin.parameterClassObject.handles.label_min_peak_width,...
%                   thisPlugin.parameterClassObject.handles.edit_min_peak_width,...
%                   thisPlugin.parameterClassObject.handles.pushbutton_decrease_min_peak_width,...
%                   thisPlugin.parameterClassObject.handles.pushbutton_increase_min_peak_width];
        
        switch modeStatus

            case {'manual', 'off', 0, false}
                %set(ha.axes1, 'ButtonDownFcn', @manual_mode_button_down_fcn);
                calculationResults.mode = 'manual';
%                set(hacki, 'Enable', 'off');
%                set(hacki2, 'Enable', 'on');
                ManualSelectionUpdateFCN(calculationResults);
                
                cp = fobj.capillary.shape; namy = {cp.name};
                averageCapilaryWidth = round(mean(cp(strcmp(namy, 'lower')).y - cp(strcmp(namy, 'upper')).y));
                interactionRadius = max([1, round(0.1*averageCapilaryWidth)]);
                
                lineselector2(@manual_mode_button_up_fcn, 'pericard', interactionRadius);
                
            case {'auto', 'on', 1, true}
                set(ha.axes1, 'ButtonDownFcn', []);
                set(hf, 'WindowButtonMotionFcn', []);
                set(hacki, 'Enable', 'on');
                
        end

        function manual_mode_button_up_fcn(br_x, br_y)
%             dbug_active_contour = false;
%             cropped_temp = output.step5_cropped_columnNormalized;
            
            % Button is up again
            set(hf,     'WindowButtonUpFcn', []);

            % Recalculate fine contour 
            calculationResults = struct('mode',         'manual',...
                                        'parameter',    parameterValues,...
                                        'shape',        struct( 'name',     'binaryShape',...
                                                                 'x',        br_x,...
                                                                 'y',        br_y));
            
            ManualSelectionUpdateFCN(calculationResults);
               
        end
        
    end

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)

        isAuto = strcmp(calculationResults.mode, 'auto');        

        % Display Image
        %im = fobj.getImdata();
        im = fobj.getImdata(double(fobj.getImdata('toGray', 'invert')), 'normalize');
        imshow(im, 'parent', ha.axes1);
       
        % Plot contours
        isAuto = strcmp(calculationResults.mode, 'auto');
%        if displayStatus.plot_binary_shape
            hold(ha.axes1, 'on')
                if isAuto
                    plot(output.mask_boundary(:,2), output.mask_boundary(:,1), 'r', 'parent', ha.axes1, 'LineWidth', 1);
                end    
                plot(calculationResults.shape(1).x, calculationResults.shape(1).y, 'b', 'parent', ha.axes1, 'LineWidth', 1, 'Tag', 'pericard');
            hold(ha.axes1, 'off')
%        end
%         if displayStatus.plot_fine_contour
%             hold(ha.axes1, 'on')
%                 plot(calculationResults.shape(2).x, calculationResults.shape(2).y, 'g', 'parent', ha.axes1, 'LineWidth', 1, 'tag', 'yolk');
%             hold(ha.axes1, 'off')
%         end
    end

    function MainDrawingFunction(fobj, ha, calculationResults)
        %try
        %    plot(calculationResults.shape(2).x, calculationResults.shape(2).y, 'g', 'parent', ha, 'LineWidth', 1);
        %catch
            plot(calculationResults.shape(1).x, calculationResults.shape(1).y, 'b', 'parent', ha, 'LineWidth', 1);
        %end
    end

end