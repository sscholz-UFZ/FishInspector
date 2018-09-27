function output_ = centralDarkLine_fishPlugin(fobj, varargin)
% Capillary - FishPlugin
% Detects the central dark line of the fishembryo
%
% Scientific Software Solutions
% Tobias Kießling 05/2016-08/2016
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
    thisPlugin.plugin_tag          = 'centralDarkLine';
    thisPlugin.plugin_name         = 'CentralDarkLine';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {'fishEye', 'fishContour', 'fishOrientation'};
    thisPlugin.hasManualMode       = true;
    thisPlugin.helpURL             = 'help\centralDarkLine.html';
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

        % ===========    TAG                    NAME                    TYPE        DEFAULT     MIN     MAX     INCREMENT   HasAuto
        parameter = {   'upper_border_mindist', 'upper_border_mindist', 'numeric',  0.1,        0,      1,      0.01,       false;...
                        'thick_part_thresh',    'thick_part_thresh',    'numeric',  0.8,        0,      1,      0.05,       false;...
                        'thick_part_cutoff',    'thick_part_cutoff',    'numeric',  0.25,       0,      1,      0.05,       false;...
                        'low_thresh',           'low_thresh',           'numeric',  0.05,       0,      1,      0.05,       false};

        % ===========   TAG                       NAME                      DEFAULT AddOPACITY     OpacityDEFAULT
        displays  = {   'plot_CentralDarkLine',   'plot_CentralDarkLine',   true,   false,         NaN     ;...
                        'plotFishContour',        'plotFishContour',        true,   false,         NaN     ;...
                        'showUpperExclusion',     'showUpperExclusion',     true,   false,         NaN     ;...
                        'showThickPartExclusion', 'showThickPartExclusion', true,   true,          0.5     };

        % ===========   TAG                     NAME                    DebugTAG                AddOPACITY      OpacityDEFAULT
        debugs    = {  'debug_here',            'debug_here',           'centralDarkLine',      false,          NaN     ;...
                       'debug_active_contour',  'debug_active_contour', 'move2extreme_debug',   false,          NaN     };
    
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end
        
    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
%         disp('Calculation Function')
%         disp(parameterValues);
%         disp(debugStatus);
        debug_tag = 'centralDarkLine';
        debug_here = debugStatus.debug_here;
        dbug_active_contour = debugStatus.debug_active_contour;
        
        % Calculate Output
        % 1) Get input and flip if necessary
        im0 = fobj.getImdata('toGray', 'invert');
        fContour = fobj.fishContour;
        fEye = fobj.fishEye;
        if fobj.fishOrientation.horizontally_flipped
            im0 = im0(:, end:-1:1);
            fContour.shape(1).x = size(im0, 2) - fContour.shape(1).x(end:-1:1) + 1;
            fContour.shape(1).y = fContour.shape(1).y(end:-1:1);
            fContour.shape(2).x = size(im0, 2) - fContour.shape(2).x(end:-1:1) + 1;
            fContour.shape(2).y = fContour.shape(2).y(end:-1:1);
            fEye.shape.x = size(im0, 2) - fEye.shape.x(end:-1:1) + 1;
            fEye.shape.y = fEye.shape.y(end:-1:1);
        end
        if fobj.fishOrientation.vertically_flipped
            im0 = im0(end:-1:1, :);
            fContour.shape(1).y = size(im0, 1) - fContour.shape(1).y + 1;
            fContour.shape(2).y = size(im0, 1) - fContour.shape(2).y + 1;
            fEye.shape.y = size(im0, 1) - fEye.shape.y + 1;
        end
        output.step1_inputImage = im0;

        
        cp = fobj.capillary.shape; namy = {cp.name};
        averageCapilaryWidth = round(mean(cp(strcmp(namy, 'lower')).y - cp(strcmp(namy, 'upper')).y));
        
        
        % 2) Generate mask from fish-contour
        idx = strcmp({fContour.shape.name}, 'fineContour');
        mask = poly2mask(fContour.shape(idx).x, fContour.shape(idx).y, size(im0,1), size(im0,2));
            mask_correcture = (mask==0) & ( (mask([2:end,end],:)==1) | (mask(:,[2:end,end])==1) | (mask([2:end,end], [2:end,end])==1));
        mask(mask_correcture) = 1;
            
        % Erase everything which is left from the eye-center
        eyecenter = mean([fEye.shape.x', fEye.shape.y'], 1);
        mask(:, 1:floor(eyecenter(1))) = 0;
        
        % Get upper part of the fish
        nanmask = nan(size(mask)); nanmask(mask) = 1;   % Nan variant of mask
        cropped = im2double(im0).*repmat(nanmask,[1,1,size(im0,3)]);
        output.step2_fishmask = mask;
        output.step2_inputImage_cropped = cropped;

        if debug_here
            h_axes = debugfigure;
            imshow(output.step1_inputImage, 'parent', h_axes(1));
            title(h_axes(1), '1. Crop input image', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
            if isappdata(h_axes(1), 'overlay_axes')
                h2 = getappdata(h_axes(1), 'overlay_axes');
            else
                h2 = axes('parent', get(h_axes(1), 'parent'));
                setappdata(h_axes(1), 'overlay_axes', h2);
                set(h2, 'units', get(h_axes(1), 'units'), 'position', get(h_axes(1), 'position'));
                axis(h2, 'off');
            end
            RGB = zeros([size(output.step2_fishmask), 3]); RGB(:,:,2) = output.step2_fishmask;
            im = imshow(RGB, 'parent', h2);
            set(im, 'AlphaData', 0.5.*double(output.step2_fishmask));

            imshow(output.step2_inputImage_cropped, 'parent', h_axes(2));
            title(h_axes(2), '2. Cropped', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);

        end

        % 3) Don't accept bright pixels close to borders
        % 3a) Get upper border
        mask_temp = nanmask; mask_temp(isnan(mask_temp)) = size(mask,1)+1;
        upper = min(mask_temp .* repmat((1:size(mask,1))', 1, size(mask,2)), [], 1);
        upper(upper == size(mask,1)+1) = NaN;
        % 3b) Get lower border
        mask_temp = nanmask; mask_temp(isnan(mask_temp)) = 0;
        lower = max(mask_temp .* repmat((1:size(mask,1))', 1, size(mask,2)), [], 1);
        lower(lower == 0) = NaN;
        % Remove bright pixels close to upper border
        idxmask = (mask.* repmat((1:size(mask,1))', 1, size(mask,2)));
        upper_border_mindist = max([0, round(averageCapilaryWidth .* parameterValues.upper_border_mindist)]);

            toRemove = (idxmask >= repmat(upper, size(mask,1), 1)) & (idxmask < repmat(upper+upper_border_mindist, size(mask,1), 1));

        cropped(toRemove) = NaN;
        mask(toRemove) = 0;
        output.step3_upperBorderToRemove = toRemove;

        if debug_here
            if isappdata(h_axes(2), 'overlay_axes')
                h2 = getappdata(h_axes(2), 'overlay_axes');
            else
                h2 = axes('parent', get(h_axes(2), 'parent'));
                setappdata(h_axes(2), 'overlay_axes', h2);
                set(h2, 'units', get(h_axes(2), 'units'), 'position', get(h_axes(2), 'position'));
                axis(h2, 'off');
            end
            RGB = zeros([size(output.step3_upperBorderToRemove), 3]); RGB(:,:,1) = output.step3_upperBorderToRemove;
            im = imshow(RGB, 'parent', h2);
            set(im, 'AlphaData', 0.5.*double(output.step3_upperBorderToRemove));
        end

        % 4) Remove bright pixels in the lower/upper half of the thik part of the embryo
        idxmask = (output.step2_fishmask.* repmat((1:size(mask,1))', 1, size(mask,2)));
        embryowidth = abs(lower-upper);
        thickpart = embryowidth>parameterValues.thick_part_thresh*max(embryowidth);

            toRemove = repmat(thickpart, size(mask,1), 1) & (idxmask>repmat((upper+(1-parameterValues.thick_part_cutoff).*embryowidth), size(mask,1), 1));

        cropped(toRemove) = NaN;
        mask(toRemove) = 0;
        output.step4_thickPartToRemove = toRemove;

        if debug_here
            if isappdata(h_axes(2), 'overlay_axes')
                h2 = getappdata(h_axes(2), 'overlay_axes');
            else
                h2 = axes('parent', get(h_axes(2), 'parent'));
                setappdata(h_axes(2), 'overlay_axes', h2);
                set(h2, 'units', get(h_axes(2), 'units'), 'position', get(h_axes(2), 'position'));
                axis(h2, 'off');
            end
            RGB = zeros([size(output.step3_upperBorderToRemove), 3]); 
                RGB(:,:,1) =  output.step3_upperBorderToRemove;  
                %RGB(:,:,2) =  output.step2_fishmask;
                RGB(:,:,3) =  output.step4_thickPartToRemove;
            im = imshow(RGB, 'parent', h2);
            set(im, 'AlphaData', 0.5.*(double(any(RGB,3))));
        end

        % 5) Normalize mask-region column-wise
        % Columnwise nanmax and nanmin
        maxi = max(cropped, [], 1);                 % Get nanmax
        cropped(isnan(cropped)) = max(maxi(:));     % &
        mini = min(cropped, [], 1);                 % nanmin for each column
        mini(mini== max(maxi(:)))=NaN;
        cropped(repmat(~mask,1,1,size(cropped,3))) = NaN;
        % Normalize
        cropped = cropped-repmat(mini,size(cropped,1),1);
        cropped = cropped./repmat(maxi-mini, size(cropped,1),1);
        output.step5_cropped_columnNormalized = cropped;
        if debug_here
            h_axes = debugfigure;

            imshow(output.step5_cropped_columnNormalized, 'parent', h_axes(3));
            title(h_axes(3), '3. Columns normalized', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end


        % 6) Get brightest pixels (==darkest pixel in original image) in each column
        br_y = max((cropped==repmat(max(cropped,[],1),size(cropped,1),1)).*repmat((1:size(cropped,1))',1,size(cropped,2)), [], 1);
        br_x = find(br_y~=0); br_y(br_y==0) = [];
        % Fix Startpoint to eye center
        remove = br_x < max(fEye.shape.x);
        br_x(remove) = [];
        br_y(remove) = [];
        if ~ismember(round(eyecenter(1)), br_x)
            br_x = [round(eyecenter(1)), br_x];
            br_y = [round(eyecenter(2)), br_y];
        else
            br_y(br_x==round(eyecenter(1))) = round(eyecenter(2));
        end
        % Fix Endpoint to tail
        lastLower = find(~isnan(lower), 1, 'last');
        if ~ismember(lastLower, br_x)
            br_x = [br_x, lastLower];
            br_y = [br_y, lower(lastLower)];
        else
            br_y(br_x==lastLower) = lower(lastLower);
        end
        
        
        output.step6_cdl_estimation_init = [br_x', br_y'];
        if debug_here
            h_axes = debugfigure;

            imshow(output.step5_cropped_columnNormalized, 'parent', h_axes(4));
            hold (h_axes(4), 'on')
                plot(output.step6_cdl_estimation_init(:,1), output.step6_cdl_estimation_init(:,2), 'r+', 'parent', h_axes(4));
            hold (h_axes(4), 'off')
            title(h_axes(4), '4. CDL - initial estimation', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end



%             % Remove bright pixels in the lower/upper half of the thik part of the embryo
%             embryowidth = abs(lower-upper);
%             thickpart = embryowidth>thick_part_thresh*max(embryowidth);
%             if obj.fishOrientation.vertically_flipped
%                 mask_temp = thickpart(br_x) & br_y<(lower(br_x)+thick_part_cutoff.*embryowidth(br_x));
%             else
%                 mask_temp = thickpart(br_x) & br_y>(upper(br_x)+thick_part_cutoff.*embryowidth(br_x));
%             end
%             br_x(mask_temp) = [];
%             br_y(mask_temp) = [];
%             output.step5_cdl_estimation_no_lower = [br_x', br_y'];

        % Interpolate missing bright points
        fullrange = find(~isnan(upper),1,'first'):find(~isnan(upper),1,'last');
        br_y = interp1(br_x, br_y, fullrange, 'linear' ,'extrap' );
        br_x = fullrange;
        output.step5_cdl_estimation = [br_x', br_y'];
        

        
        % 6) Active contour to maximum
        cropped_temp = cropped;%obj.getImdata(uint8(cropped.*255));%, 'smooth', 4);
        cropped_temp(cropped_temp<=max(cropped(:)).*(parameterValues.low_thresh)) = NaN;%(127+64);
        cropped_temp = im0;
        out = fishobj2.move2extreme(cropped_temp, [br_x', br_y'], 'max', false, dbug_active_contour);
        br_x = out(:,1); br_y = out(:,2);
        output.step6_cdl = [br_x, br_y];

        if fobj.fishOrientation.horizontally_flipped
            output.step6_cdl(:,1) = size(im0, 2) - output.step6_cdl(end:-1:1,1) + 1;
            output.step6_cdl(:,2) = output.step6_cdl(end:-1:1,2);
        end
        if fobj.fishOrientation.vertically_flipped
            output.step6_cdl(:,2) = size(im0, 1) - output.step6_cdl(:,2) + 1;
        end
        
        
        % Return Output
        calculationResults = struct('mode',                 'auto',...
                                    'parameter',            parameterValues,...
                                    'shape',                struct('name',     'centralDarkLine',...
                                                                   'x',        output.step6_cdl(:,1)',...
                                                                   'y',        output.step6_cdl(:,2)'));

                                
        function h_axes = debugfigure()
            persistent hf;
            if ~ishandle(hf)
                hf = findall(0, 'parent', 0, 'tag', debug_tag);
            end
            if isempty(hf)
                % Create debug figure
                hf = figure;
                set(hf, 'tag', debug_tag);
                h_axes(1) = subplot(2,2,1, 'parent', hf);
                h_axes(2) = subplot(2,2,2, 'parent', hf);
                h_axes(3) = subplot(2,2,3, 'parent', hf);
                h_axes(4) = subplot(2,2,4, 'parent', hf);
                setappdata(hf, 'axes', h_axes)
                for i = 1:4
                    set(h_axes(i), 'units', 'normalized');
                    pos = get(h_axes(i), 'position');
                    if ismember(i,[1,3])
                        set(h_axes(i), 'position', [0.025, pos(2)-0.1*pos(4), 0.45, pos(4)+0.2*pos(4)]);
                    else
                        set(h_axes(i), 'position', [0.525, pos(2)-0.1*pos(4), 0.45, pos(4)+0.2*pos(4)]);
                    end
                end
            else
                h_axes = getappdata(hf, 'axes');
            end
        end

    end


    function manualModeFunction(fobj, ha, modeStatus, calculationResults,  parameterValues, debugStatus, ManualSelectionUpdateFCN)
               
        % Get parent figure
        hf = get(ha.axes1, 'parent');
        hacki = [thisPlugin.parameterClassObject.handles.checkbox_showUpperExclusion,...
                 thisPlugin.parameterClassObject.handles.checkbox_showThickPartExclusion,...
                 thisPlugin.parameterClassObject.handles.labelOpacity_showThickPartExclusion,...
                 thisPlugin.parameterClassObject.handles.editDisplayOpacity_showThickPartExclusion];
        while ~strcmp('figure', get(hf, 'Type')), hf = get(hf, 'parent'); end

        switch modeStatus

            case {'manual', 'off', 0, false}
                %set(ha.axes1, 'ButtonDownFcn', @manual_mode_button_down_fcn);
                calculationResults.mode = 'manual';
                set(hacki, 'Enable', 'off');
                ManualSelectionUpdateFCN(calculationResults);
                
                cp = fobj.capillary.shape; namy = {cp.name};
                averageCapilaryWidth = round(mean(cp(strcmp(namy, 'lower')).y - cp(strcmp(namy, 'upper')).y));
                interactionRadius = max([1, round(0.2 * averageCapilaryWidth)]);
                
                lineselector(@manual_mode_button_up_fcn, 'cdl', interactionRadius);
                
                    
            case {'auto', 'on', 1, true}
                set(ha.axes1, 'ButtonDownFcn', []);
                set(hf, 'WindowButtonMotionFcn', []);
                set(hacki, 'Enable', 'on');
        end


        function manual_mode_button_up_fcn(br_x, br_y)
            dbug_active_contour = false;
            cropped_temp = fobj.getImdata('toGray', 'invert');
            
            % Button is up again
            set(hf,     'WindowButtonUpFcn', []);

            out = fishobj2.move2extreme(cropped_temp, [br_x', br_y'], 'max', false, dbug_active_contour);
            br_x = out(:,1); br_y = out(:,2);
            temp.step6_cdl = [br_x, br_y];


            % Return Output
            calculationResults = struct('mode',                 'manual',...
                                        'parameter',            parameterValues,...
                                        'shape',                struct('name',     'centralDarkLine',...
                                                                       'x',        temp.step6_cdl(:,1)',...
                                                                       'y',        temp.step6_cdl(:,2)'));
            
            
            ManualSelectionUpdateFCN(calculationResults);
               
        end

    end


    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
        
        % % % %
        % Overlay Upper / ThickPart Exclusion
        if strcmp(calculationResults.mode, 'auto') &&...
           any([displayStatus.showUpperExclusion,...
                displayStatus.showThickPartExclusion])       % Plot Contour checkbox?
            % Draw it                    
            RGB = zeros([size(output.step3_upperBorderToRemove), 3]); 

            if displayStatus.showUpperExclusion
                RGB(:, :, 1) = output.step3_upperBorderToRemove;
            end

            if displayStatus.showThickPartExclusion
                RGB(:, :, 3) = output.step4_thickPartToRemove;
            end
            if fobj.fishOrientation.horizontally_flipped
                RGB = RGB(:,end:-1:1,:);
            end
            if fobj.fishOrientation.vertically_flipped
                RGB = RGB(end:-1:1,:,:);
            end
            im = imshow(RGB, 'parent',  ha.axes_overlay);
            set(im, 'AlphaData', displayStatus.showThickPartExclusion_opacity.*(double(any(RGB,3))));

        else
            cla(ha.axes_overlay);
        end
        set(findall(ha.axes_overlay), 'PickableParts', 'none', 'HitTest', 'off');
        
        % % % %
        % Display Image
        im = fobj.getImdata('toGray', 'subtractBackground');
        oldTag        = get(ha.axes1, 'Tag');          % The Tag-property and ButtonDownFcn are erased when using imshow
        oldBtnDownFcn = get(ha.axes1, 'ButtonDownFcn');        
        imh = imshow(im, 'parent', ha.axes1);
        set(imh, 'ButtonDownFcn', oldBtnDownFcn);
        set(ha.axes1, 'Tag', oldTag, 'ButtonDownFcn', oldBtnDownFcn);      % This way we keep the Tag/ButtonDownFcn despite of imshow
                
        % % % %
        % Display CentralDarkLine
        % Draw it anyway (and hide it if display is unchecked) since we
        % need it in manual mode
        hold(ha.axes1, 'on')
            hp = plot(calculationResults.shape.x, calculationResults.shape.y, 'g', 'parent', ha.axes1, 'tag', 'cdl');
        hold(ha.axes1, 'off')
        if displayStatus.plot_CentralDarkLine
            set(hp, 'Visible', 'on'), 
        else
            set(hp, 'Visible', 'off');
        end

        % % % %
        % Display fine contour
        if displayStatus.plotFishContour
            % Draw it
            fContour = fobj.fishContour;
            idx = strcmp({fContour.shape.name}, 'fineContour');
            hold(ha.axes1, 'on')
                plot(fContour.shape(idx).x, fContour.shape(idx).y,  'parent', ha.axes1);
            hold(ha.axes1, 'off')
        end
        set(findall(ha.axes1), 'PickableParts', 'all', 'HitTest', 'on');
        
    end

    function MainDrawingFunction(fobj, ha, calculationResults)

        plot(calculationResults.shape.x, calculationResults.shape.y, 'g', 'parent', ha);
        
    end

end