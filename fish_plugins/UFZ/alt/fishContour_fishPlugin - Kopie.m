function output_ = fishContour_fishPlugin(fobj, varargin)
% FishContour - FishPlugin
% Detects the contour of the Fish
%
% Scientific Software Solutions
% Tobias Kießling 05/2016-06/2016
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
    thisPlugin.plugin_tag          = 'fishContour';
    thisPlugin.plugin_name         = 'FishContour';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {'capillary'};
    thisPlugin.hasManualMode       = true;
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
    
    %% Plugin Functions (Here is where the Parameters, Calculations, and Drawings are implemented)
    
    function [parameter, displays, debugs] = ParameterDefinitions(fobj)

        % Auto parameter settings (depend on capillary)
        cp = fobj.capillary.shape; namy = {cp.name};
        % Default for "width_of_capillary_wall"
        wocw_default = 3*ceil(mean(abs([cp(strcmp(namy, 'lower_in')).y-cp(strcmp(namy, 'lower')).y,...
                                        cp(strcmp(namy, 'upper')).y-cp(strcmp(namy, 'upper_in')).y]))) ;
        % Default for "imclose_disksize"
        id_default = round(wocw_default/2);
        % % % %
                                    
        % ===========   TAG                         NAME                        TYPE        DEFAULT         MIN     MAX     INCREMENT   HasAuto
        parameter = {   'auto_thresh_multiplier',   'auto_thresh_multiplier',   'numeric',  0.3,            0,      1,      0.05,       false;...
                        'width_of_capillary_wall',  'width_of_capillary_wall',  'numeric',  wocw_default,   0,      Inf,    1,          true;...
                        'imclose_disksize',         'imclose_disksize',         'numeric',  id_default,     0,      Inf,    1,          true;...
                        'binary_contour_smoothing', 'binary_contour_smoothing', 'numeric',  20,             0,      Inf,    1,          false;...
                        'min_peak_width',           'min_peak_width',           'numeric',  3,              1,      Inf,    1,          false};

        % ===========   TAG                     NAME                    DEFAULT,    AddOPACITY     OpacityDEFAULT
        displays  = {   'plot_binary_shape',    'plot_binary_shape',    true,       true,          0.5     ;...
                        'plot_binary_contour',  'plot_binary_contour',  false,      false,         NaN     ;...
                        'plot_fine_contour',    'plot_fine_contour',    true,       false,         NaN     };

        % ===========   TAG                         NAME                        DebugTAG             AddOPACITY      OpacityDEFAULT
        debugs    = {   'debug_detectBinaryFish',   'debug_detectBinaryFish',   'detectBinaryFish',  false,          NaN     ;...
                        'debug_detectFineContour',  'debug_detectFineContour',  'move2extreme_debug', false,          NaN     };
        
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end
        
    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
%         disp('Calculation Function')
%         disp(parameterValues);
%         disp(debugStatus);
%         disp(displayStatus);
        
        % Calculate Output
        %% Binary Fish
        debug_tag = 'detectBinaryFish';
        debug_here = debugStatus.debug_detectBinaryFish;
            
        % 1) Get bw image
        data0 = fobj.getImdata('toGray', 'subtractBackground', 'invert', 'getInner');
        data = im2bw(data0, parameterValues.auto_thresh_multiplier*graythresh(data0));
        output.step1_grayImage = data0;
        output.step1_bwImage = data;
        if debug_here
            h_axes = debugfigure;
            imshow(output.step1_grayImage, 'parent', h_axes(1));
            title(h_axes(1), '1. Get BW image from inner capillary (auto threshold muliplier)', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
            if isappdata(h_axes(1), 'overlay_axes')
                h2 = getappdata(h_axes(1), 'overlay_axes');
            else
                h2 = axes('parent', get(h_axes(1), 'parent'));
                setappdata(h_axes(1), 'overlay_axes', h2);
                set(h2, 'units', get(h_axes(1), 'units'), 'position', get(h_axes(1), 'position'));
                axis(h2, 'off');
            end
            RGB = zeros([size(output.step1_bwImage), 3]); RGB(:,:,2) = output.step1_bwImage;
            im = imshow(RGB, 'parent', h2);
            set(im, 'AlphaData', 0.5.*double(output.step1_bwImage));
        end
            
        % 2) Remove capillary (All white border pixels with less than width_of_capillary_wall pixels are removed)
        width_of_capillary_wall = parameterValues.width_of_capillary_wall;
        leni_u = zeros(1, size(data, 2));   leni_l = zeros(1, size(data, 2));
        addi_u = true(size(leni_u));        addi_l = true(size(leni_u));
        for ii = 1 : min(width_of_capillary_wall, size(data,1))
            has_entry = (data(ii,:)>0);
            addi_u(~has_entry) = false;
            leni_u = leni_u + has_entry;

            has_entry = (data(end-ii+1,:)>0);
            addi_l(~has_entry) = false;
            leni_l = leni_l + has_entry;
        end
        remove_u = leni_u < width_of_capillary_wall; addi_u = true(size(leni_u));
        remove_l = leni_l < width_of_capillary_wall; addi_l = true(size(leni_l));
        for ii = 1 : min(width_of_capillary_wall, size(data,1))
            has_entry = (data(ii,:)>0);
            addi_u(~has_entry) = false;
            data(ii, remove_u & addi_u & has_entry) = 0;

            has_entry = (data(end-ii+1,:)>0);
            addi_l(~has_entry) = false;
            data(end-ii+1, remove_l & addi_l & has_entry) = 0;
        end
        output.step2_bwImage = data;
        if debug_here
            h_axes = debugfigure;
            imshow(output.step2_bwImage, 'parent', h_axes(2));
            title(h_axes(2), '2. Remove capillary from BW image (with of capillary wall)', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end
            
        % 3) Get biggest region
        label = bwlabel(data);
        Aprops = regionprops(label);
        idx = find([Aprops.Area] == max([Aprops.Area]), 1, 'first');
        data2 = double(data);
        data2(data) = 1;
        data2(label == idx) = 2;
        %data(data) = 15;
        output.step3_labeledImage = data2;
        if debug_here
            h_axes = debugfigure;
            imshow(label2rgb(output.step3_labeledImage, [1,0,0;0,1,0;colormap(gca)], [0,0,0]), 'parent', h_axes(3));
            title(h_axes(3), '3. Get biggest region', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end
            
        % 4) Fill holes / imclose
        data = label == idx;
        data = bwfill(data, 'holes');
        data = imclose(data, strel('disk', parameterValues.imclose_disksize));
        data = bwfill(data, 'holes');

        output.step4_bwImage = data;
        if debug_here
            h_axes = debugfigure;
            imshow(output.step4_bwImage, 'parent', h_axes(4));
            title(h_axes(4), '4. Fill holes / imclose  (imclose disksize)', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end
            
        % 5 Get Boundary coordinates from bw image
        b = bwboundaries(data, 8, 'noholes');       % In "inner capillary"-coordinates
        % Transform boundary to global coordinates
        cp = fobj.capillary.shape;
        namy = {cp.name};
                
        middle = ( cp(strcmp(namy, 'upper_in')).y + cp(strcmp(namy, 'lower_in')).y ) /2;
        width = min(abs(cp(strcmp(namy, 'upper_in')).y - cp(strcmp(namy, 'lower_in')).y));
        b_global_x = b{1}(:,2);
        b_global_y = round(middle(b{1}(:,2))'-floor(width/2)+b{1}(:,1)-1);

        output.step5_boundary = struct( 'inner_x',         b{1}(:,2),         'inner_y',          b{1}(:,1),...
                                        'global_x',        b_global_x,        'global_y',         b_global_y);
           
        %% FineContour    
        fineContour = detectFineContour(b_global_x, b_global_y, fobj, parameterValues, debugStatus);
        

        
        
        % Return Output
        
        calculationResults = struct('mode',         'auto',...
                                    'parameter',    parameterValues,...
                                    'shape',        [struct( 'name',     'binaryShape',...
                                                             'x',        output.step5_boundary.global_x(:)',...
                                                             'y',        output.step5_boundary.global_y(:)'),...
                                                     fineContour]);

        function h_axes = debugfigure()
            persistent hf;
            if ~ishandle(hf)
                hf = findall(0, 'parent', 0, 'tag', debug_tag);
            end
            if isempty(hf)
                % Create debug figure
                hf = figure;
                set(hf, 'tag', debug_tag);
                h_axes(1) = subplot(4,1,1, 'parent', hf);
                h_axes(2) = subplot(4,1,2, 'parent', hf);
                h_axes(3) = subplot(4,1,3, 'parent', hf);
                h_axes(4) = subplot(4,1,4, 'parent', hf);
                setappdata(hf, 'axes', h_axes)
                for i = 1:4
                    set(h_axes(i), 'units', 'normalized');
                    pos = get(h_axes(i), 'position');
                    set(h_axes(i), 'position', [0.05, pos(2)-0.1*pos(4), 0.9, pos(4)+0.2*pos(4)]);
                end
            else
                h_axes = getappdata(hf, 'axes');
            end
        end
        
    end

    function fineContour = detectFineContour(bf_x, bf_y, fobj, parameterValues, debugStatus)
        dbug_active_contour = debugStatus.debug_detectFineContour;
            
        % 1) Gather input
        im = fobj.getImdata(double(fobj.getImdata('toGray', 'invert')), 'normalize');

        % Calculate smooth boundary coordinates
        [ixi2, ysi2] = contour_smooth(bf_x, bf_y, parameterValues.binary_contour_smoothing);
%%
%         binaryImage = poly2mask(ixi2, ysi2, size(fobj.imdata, 1),size(fobj.imdata, 2));
%         mask = (binaryImage==0) & ( (binaryImage([2:end,end],:)==1) | (binaryImage(:,[2:end,end])==1) | (binaryImage([2:end,end], [2:end,end])==1));
%         binaryImage(mask) = 1;

%         addpath('C:\Users\tobi\Documents\Freelancer\UFZ\implementation\fish_plugins\sfm_chanvese_demo');
%         iterations = 1000;
%         rad = 100;
%         lambda = 0;
%         [seg] = sfm_local_chanvese(imresize(im, 0.4), imresize(binaryImage, 0.4),iterations,lambda,rad);
        
%       GrowCut
%         labels = zeros(size(binaryImage));
%         idx = find(binaryImage);
%         labels(idx(round(length(idx).*rand(nf,1))+1)) = 1;
%         idx = find(~binaryImage);
%         labels(idx(round(length(idx).*rand(no,1))+1)) = -1;
%         
%         [labels_out, strengths] = growcut(im, labels);%
%         imshow(labels_out);
%%        
        output.step1_inputImage = im;
        output.step1_contour = struct('x', ixi2, 'y', ysi2);

        % 2) Unwrap the Fish
        [imi, x_imi, y_imi] = imunwrap_poly(im, ixi2, ysi2);
        imi = fobj.getImdata(imi, 'normalize');
        output.step2_unwrappedFish = imi;

        % 3) Get modified PeakImage
        peakimage = getPeakImage(imi, parameterValues.min_peak_width);
        peakimage(peakimage<(max(peakimage(:))/2)) = ceil(max(peakimage(:))/2);
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

    function manualModeFunction(fobj, ha, modeStatus, calculationResults,  parameterValues, debugStatus, ManualSelectionUpdateFCN);
               
        % Get parent figure
        hf = get(ha.axes1, 'parent');
        while ~strcmp('figure', get(hf, 'Type')), hf = get(hf, 'parent'); end

               
        trail = [];
        switch modeStatus

            case {'manual', 'off', 0, false}
                set(ha.axes1, 'ButtonDownFcn', @manual_mode_button_down_fcn);
                calculationResults.mode = 'manual';
                ManualSelectionUpdateFCN(calculationResults);
                
            case {'auto', 'on', 1, true}
                set(ha.axes1, 'ButtonDownFcn', []);

        end


        function manual_mode_button_down_fcn(varargin)

            % Button down on axes
            set(hf,     'WindowButtonUpFcn', @manual_mode_button_up_fcn);
            set(hf, 'WindowButtonMotionFcn', @manual_mode_button_motion_fcn);

            % Record first point
            cp = get(ha.axes1, 'CurrentPoint');
            trail = cp([1,3]);
            manual_mode_insert_trail();
            set(ha.trail_plot, 'XData', trail(:,1), 'YData', trail(:,2));

        end

        function manual_mode_insert_trail(varargin)
            if ~isfield(ha, 'trail_plot') || ~ishandle(ha.trail_plot)
                holdWasOn = ishold(ha.axes1);
                hold(ha.axes1, 'on');
                ha.trail_plot = plot([0,0], [0,0], 'parent', ha.axes1);
                if ~holdWasOn, hold(ha.axes1, 'off'); end
            end
        end

        function manual_mode_button_motion_fcn(varargin)

            % Record all points as we move
            cp = get(ha.axes1, 'CurrentPoint');
            trail = cat(1, trail, cp([1,3]));
            manual_mode_insert_trail();
            set(ha.trail_plot, 'XData', trail(:,1), 'YData', trail(:,2));

        end

        function manual_mode_button_up_fcn(varargin)

            % Button is up again
            set(hf,     'WindowButtonUpFcn', []);
            set(hf, 'WindowButtonMotionFcn', []);

            % Record last point
            cp = get(ha.axes1, 'CurrentPoint');
            trail = cat(1, trail, cp([1,3]));  
            manual_mode_insert_trail();
            set(ha.trail_plot, 'XData', trail([end,1:end],1),... % Draw closed contour;
                               'YData', trail([end,1:end],2));

            selected    = poly2mask(trail(:, 1),                 trail(:, 2),...
                                    size(fobj.imdata, 1),        size(fobj.imdata, 2));
            binray = calculationResults.shape(strcmp({calculationResults.shape.name}, 'binaryShape'));
            binaryImage = poly2mask(binray.x,               binray.y,...
                                    size(fobj.imdata, 1),   size(fobj.imdata, 2));
            mask = (binaryImage==0) & ( (binaryImage([2:end,end],:)==1) | (binaryImage(:,[2:end,end])==1) | (binaryImage([2:end,end], [2:end,end])==1));
            binaryImage(mask) = 1;
            newVal = binaryImage(sub2ind(size(binaryImage), round(trail([1,end],2)), round(trail([1,end],1))));
            if newVal(1) ~= newVal(2)
                % trail starts and ends in two differen regions => ignore
                set(ha.trail_plot, 'XData', [], 'YData', []);
                
            else
                % Add trail to image
                binaryImage(selected) = newVal(1);

                % Take biggest region
                label = bwlabel(binaryImage);
                Aprops = regionprops(label, 'Area'); %#ok<MRPBW>
                idx = find([Aprops.Area] == max([Aprops.Area]), 1, 'first');
                binaryImage = label == idx;

                % Get Boundary coordinates from bw image and calculate smooth boundary coordinates
                b = bwboundaries(binaryImage, 8, 'noholes');

                % Recalculate fine contour 
                fineContour = detectFineContour(b{1}(:,2)', b{1}(:,1)', fobj, parameterValues, debugStatus);
                calculationResults = struct('mode',         'manual',...
                                            'parameter',    parameterValues,...
                                            'shape',        [struct( 'name',     'binaryShape',...
                                                                     'x',        b{1}(:,2)',...
                                                                     'y',        b{1}(:,1)'),...
                                                            fineContour]);

            end
            
            ManualSelectionUpdateFCN(calculationResults);
               
        end

    end

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
        
        im = fobj.getImdata();
        oldTag        = get(ha.axes1, 'Tag');          % The Tag-property and ButtonDownFcn are erased when using imshow
        oldBtnDownFcn = get(ha.axes1, 'ButtonDownFcn');        
        imh = imshow(im, 'parent', ha.axes1);
        set(imh, 'ButtonDownFcn', oldBtnDownFcn);
        set(ha.axes1, 'Tag', oldTag, 'ButtonDownFcn', oldBtnDownFcn);      % This way we keep the Tag/ButtonDownFcn despite of imshow
                
        % % % %
        % Display binary fish SHAPE to overlay axis
        if displayStatus.plot_binary_shape
            bf = calculationResults.shape(strcmp({calculationResults.shape.name}, 'binaryShape'));
            % Draw it
            binaryImage = poly2mask(bf.x, bf.y, size(fobj.imdata, 1),size(fobj.imdata, 2));
            mask = (binaryImage==0) & ( (binaryImage([2:end,end],:)==1) | (binaryImage(:,[2:end,end])==1) | (binaryImage([2:end,end], [2:end,end])==1));
            binaryImage(mask) = 1;
            binaryImage = ~binaryImage;     % Invert
            RGB = zeros([size(fobj.imdata, 1), size(fobj.imdata, 2), 3]);%; RGB(:,:,2) = binaryImage;
            im = imshow(RGB, 'parent', ha.axes_overlay);
            set(im, 'AlphaData', displayStatus.plot_binary_shape_opacity.*double(binaryImage), 'ButtonDownFcn', oldBtnDownFcn);
        else
            cla(ha.axes_overlay);
        end

        % % % %
        % Display binary fish CONTOUR
        if displayStatus.plot_binary_contour
            bf = calculationResults.shape(strcmp({calculationResults.shape.name}, 'binaryShape'));
            % Draw it
            hold(ha.axes_overlay, 'on')
                plot(bf.x, bf.y,  'parent', ha.axes_overlay);
            hold(ha.axes_overlay, 'off')
        end

        
        % % % %
        % Display fine contour
        if displayStatus.plot_fine_contour
            fc = calculationResults.shape(strcmp({calculationResults.shape.name}, 'fineContour'));
            % Draw it
            hold(ha.axes_overlay, 'on')
                plot(fc.x, fc.y,  'parent', ha.axes_overlay);
            hold(ha.axes_overlay, 'off')
        end

    end

    function MainDrawingFunction(fobj, ha, calculationResults)
        fc = calculationResults.shape(strcmp({calculationResults.shape.name}, 'fineContour'));
        plot(fc.x, fc.y, 'r', 'parent', ha);
    end

end