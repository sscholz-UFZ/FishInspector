function output_ = pigmentation_fishPlugin(fobj, varargin)
% Yolk - FishPlugin
% Detects the yolk of the Fish
%
% Scientific Software Solutions
% Tobias Kie�ling 05/2016-01/2017
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
    thisPlugin.plugin_tag          = 'pigmentation';
    thisPlugin.plugin_name         = 'Pigmentation';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {'centralDarkLine', 'fishEye', 'bladder'};
    thisPlugin.hasManualMode       = true;
    thisPlugin.helpURL             = 'help\pigmentation.html';
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

        % ===========    TAG                        NAME                        TYPE        DEFAULT     MIN     MAX     INCREMENT   HasAuto  
        parameter = {   'rel_offset',               'Relative Offset',          'numeric',  0.15,          0,      inf,    0.25,       false;...
                        'rel_length',               'Relative Length',          'numeric',  0.2,       0,      inf,    0.25,       false;...
                        'upperCutoff',              'Relative Vertical Cutoff', 'numeric',  0.75,       0,      1,      0.05,       false;...
                        'min_peak_width',           'MinPeakWidth',             'numeric',  0.01,       0,      1,      0.005,      false;...
                        'binary_contour_smoothing', 'BinaryContourSmoothing',   'numeric',  0.07,       0,      1,      0.005,      false};

        % ===========   TAG                     NAME                    DEFAULT     AddOPACITY     OpacityDEFAULT
        displays  = {   'plot_binary_shape',    'plot_binary_shape',    true,       false,         NaN;...
                        'plot_fine_contour',    'plot_fine_contour',    false,      false,         NaN;...
                        'showBinary',           'showBinary',           true,       true,          0.5};

        % ===========   TAG                         NAME                    DebugTAG                AddOPACITY      OpacityDEFAULT
        debugs    = {  'debug_detectFineContour',   'debug_fineContours',   'yolk',            false,          NaN     };
    
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;       % <= Set to true to apply new values
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end
output = [];
    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
        
        % 1) Get input and flip if necessary
        im0 = fobj.getImdata('toGray');
        fContour = fobj.fishContour;
        fEye = fobj.fishEye;
        cdl = fobj.centralDarkLine;
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
        end
        if fobj.fishOrientation.vertically_flipped
            im0 = im0(end:-1:1, :);
            fContour.shape(1).y = size(im0, 1) - fContour.shape(1).y + 1;
            fContour.shape(2).y = size(im0, 1) - fContour.shape(2).y + 1;
            fEye.shape.y = size(im0, 1) - fEye.shape.y + 1;
            cdl.shape.y = size(im0, 1) - cdl.shape.y + 1;
        end
        
        % % %
        % A) Generate a mask to narrow down the region where to look for the bladder
        % A1) FishContour mask
        fineContour = fContour.shape(strcmpi({fContour.shape.name}, 'fineContour'));
        fineContour_mask = poly2mask(fineContour.x, fineContour.y, size(im0,1),  size(im0, 2));
        mask_correcture = (fineContour_mask==0) & ( (fineContour_mask([2:end,end],:)==1) | (fineContour_mask(:,[2:end,end])==1) | (fineContour_mask([2:end,end], [2:end,end])==1));
        fineContour_mask(mask_correcture) = 1;   
        % A2) Upper half of the fish (via central dark line)
        cdl_expanded = interp1(cdl.shape.x, cdl.shape.y, 1:size(im0,2));
        idx_mask = repmat(cdl_expanded, size(im0, 1), 1);
        row_mask = repmat((1:size(im0,1))', 1, size(im0,2));   
        cdl_mask = row_mask<idx_mask; 
        % A3) Exclude the eye
        eye_mask = poly2mask(fEye.shape.x, fEye.shape.y, size(im0,1),  size(im0, 2));
        mask_correcture = (eye_mask==0) & ( (eye_mask([2:end,end],:)==1) | (eye_mask(:,[2:end,end])==1) | (eye_mask([2:end,end], [2:end,end])==1));
        eye_mask(mask_correcture) = 1;   
        % A4) Finally combine all the masks
        mask = (fineContour_mask & cdl_mask & ~eye_mask);
        % ----------------------- %
        
%         % % %
%         % B) Apply cutoffs
%         cdl_length = max(cdl.shape.x) - min(cdl.shape.x);
%         mini = floor(min(cdl.shape.x)+cdl_length*parameterValues.rel_offset);
%         leni = ceil(cdl_length*parameterValues.rel_length);
%         mask(:,[1:mini,mini+leni:end]) = 0;
        
        % C) Get contour of the biggest region
        [out, labeled_mask] = bwboundaries(mask);
        if isempty(out)
            out = zeros(0,2);
            mask = zeros(size(mask));
        else
            [~, maxIDX] = max(cellfun(@(x) size(x,1), out));
            out = out{maxIDX};
            mask = labeled_mask==maxIDX;
        end
        out = out(:,[2,1]);
        output.step2_fishContour = mask;
        
        
        if fobj.fishOrientation.horizontally_flipped
            out(:,1) = size(im0, 2) - out(end:-1:1, 1) + 1;
            out(:,2) = out(end:-1:1, 2);
            output.step2_fishContour = fliplr(output.step2_fishContour);
        end
        if fobj.fishOrientation.vertically_flipped
            out(:,2) = size(im0, 1) - out(:,2) + 1;
            output.step2_fishContour = flipud(output.step2_fishContour);
        end
        
       % fineContour = detectFineContour(out(:,1), out(:,2), fobj, parameterValues, debugStatus);
        
        %% Return Output
        calculationResults = struct('mode',                 'auto',...
                                    'parameter',            parameterValues,...
                                    'shape',                [struct('name',  'outline',...
                                                                   'x',     out(:,1)',...
                                                                   'y',     out(:,2)')]);%,...
                                                                %   fineContour]);

             
        
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
        %peakimage(peakimage<(max(peakimage(:))/2)) = ceil(max(peakimage(:))/2);
        output.step3_PeakImage = peakimage;

        % 4) Use some kind of active contour to get the fine position
        startline = repmat(ceil(size(peakimage,1)/2), 1, size(peakimage,2));
        fine_contour = fishobj2.move2extreme(peakimage, startline, 'max', true, dbug_active_contour);
        output.step4_startline = startline;
        output.step4_fineline  = fine_contour;

if 0
    if ~ishandle(424),
        figure(424); 
    end
    ha = gca(424);
    imshow(label2rgb(peakimage), 'parent', ha);
    hold(ha,'on'); plot(fine_contour, 'r', 'parent', ha, 'linewidth', 1); 
    hold(ha, 'off');
    [~, f, e] = fileparts(fobj.impath);
    h_ = ha;
    switch [f,e]
        case 'ATRA_1_2 (4).bmp'
            set(h_, 'xdir', 'normal', 'ydir', 'reverse');
        case 'ATRA_1_2 (4)_rot.png'
            set(h_, 'xdir', 'reverse', 'ydir', 'reverse');
        case 'ATRA_1_2 (4)_rot2.png'
            set(h_, 'xdir', 'normal', 'ydir', 'reverse');
        case 'ATRA_1_2 (4)_rot3.png'
            set(h_, 'xdir', 'reverse', 'ydir', 'reverse');
        otherwise
            set(h_, 'xdir', 'normal', 'ydir', 'reverse');
    end 
end
        
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
        hacki  = [thisPlugin.parameterClassObject.handles.checkbox_plot_binary_shape];
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
                set(hacki, 'Enable', 'off');
%                set(hacki2, 'Enable', 'on');
                ManualSelectionUpdateFCN(calculationResults);
                
                cp = fobj.capillary.shape; namy = {cp.name};
                averageCapilaryWidth = round(mean(cp(strcmp(namy, 'lower')).y - cp(strcmp(namy, 'upper')).y));
                interactionRadius = max([1, round(0.15 * averageCapilaryWidth)]);
                
                lineselector2(@manual_mode_button_up_fcn, 'yolk', interactionRadius);
                
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
            fineContour = detectFineContour(br_x, br_y, fobj, parameterValues, debugStatus);
            calculationResults = struct('mode',         'manual',...
                                        'parameter',    parameterValues,...
                                        'shape',        [struct( 'name',     'binaryShape',...
                                                                 'x',        br_x,...
                                                                 'y',        br_y),...
                                                        fineContour]);
            
            ManualSelectionUpdateFCN(calculationResults);
               
        end
        
    end

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
        isAuto = strcmp(calculationResults.mode, 'auto');
        
        % % % %
        % Display Binary Shape
        calculationResults.mode
        if isAuto && displayStatus.showBinary
            RGB = zeros([size(fobj.imdata, 1), size(fobj.imdata, 2), 3]);%; RGB(:,:,2) = binaryImage;
            im = imshow(RGB, 'parent', ha.axes_overlay);
            set(im, 'AlphaData', displayStatus.showBinary_opacity.*double(output.step2_fishContour>0));
        else
            cla(ha.axes_overlay);
        end
        set(findall(ha.axes_overlay), 'PickableParts', 'none', 'HitTest', 'off');
        
        % Display Image
        im = fobj.getImdata();
        imshow(im, 'parent', ha.axes1);
       
        % Plot contours
        if  isAuto && displayStatus.plot_binary_shape % BINARY
            hold(ha.axes1, 'on') 
                plot(calculationResults.shape(1).x, calculationResults.shape(1).y, 'r', 'parent', ha.axes1, 'LineWidth', 1);
            hold(ha.axes1, 'off')
        end
        if displayStatus.plot_fine_contour            % FINE CONTOUR
            hold(ha.axes1, 'on') 
                plot(calculationResults.shape(2).x, calculationResults.shape(2).y, 'g', 'parent', ha.axes1, 'LineWidth', 1, 'tag', 'yolk');
            hold(ha.axes1, 'off')
        end
    end

    function MainDrawingFunction(fobj, ha, calculationResults)
        %try
        %    plot(calculationResults.shape(2).x, calculationResults.shape(2).y, 'g', 'parent', ha, 'LineWidth', 1);
        %catch
            plot(calculationResults.shape(1).x, calculationResults.shape(1).y, 'y--', 'parent', ha, 'LineWidth', 1);
        %end
    end

end