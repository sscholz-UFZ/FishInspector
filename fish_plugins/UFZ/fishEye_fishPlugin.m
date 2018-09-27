function output_ = fishEye_fishPlugin(fobj, varargin)
% FishEye - FishPlugin
% Detects the contour of the inner and outer capillary borders
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
    thisPlugin.plugin_tag          = 'fishEye';
    thisPlugin.plugin_name         = 'FishEye';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {'fishContour'};
    thisPlugin.hasManualMode       = true;
    thisPlugin.helpURL             = 'help\fishEye.html';
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
    output = struct();
    
    function [parameter, displays, debugs] = ParameterDefinitions(fobj)

        % ===========   TAG                 NAME                TYPE        DEFAULT     MIN     MAX     INCREMENT HasAuto
        parameter = {   'relLengthOfHead',  'relLengthOfHead',  'numeric',  0.15,      0.01,   0.5,    0.025,    false;...
                        'autothresh_multiplier','autothresh_multiplier','numeric',0.96,  0,      Inf,    0.01,     false};%;...
                        %'vertCutoff',       'vertCutoff',       'numeric',  20,         0,      Inf,    1,        false;...
                        %'horizCutoff',      'horizCutoff',      'numeric',  20,         0,      Inf,    1,        false;...
                        %'imclose_disksize', 'imclose_disksize', 'numeric',  0,          0,      Inf,    1,        false};

        % ===========   TAG               NAME              DEFAULT AddOPACITY     OpacityDEFAULT
        displays  = {   'showBinary',     'showBinary',     true,   true,          0.5     ;...
                        'showContour',    'showContour',    true,   false,         NaN     };

        % ===========   TAG             NAME                DebugTAG        AddOPACITY      OpacityDEFAULT
        debugs    = { };%'debug_here',   'debug_here',       'getCapillary', false,          NaN     };%...
                        %'debug2',       'DebugName2',       'DebugTag2',    false,          NaN     };
            
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end
        
    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
%         disp('Calculation Function')
%         disp(parameterValues);
%         disp(debugStatus);
        
        % Calculate Output
        % 1) Get input image
        im0 = fobj.getImdata('toGray', 'invert');
        output.step1_inputImage = im0;

        fc = fobj.fishContour.shape(strcmp({fobj.fishContour.shape.name}, 'fineContour'));
        % Draw it
        binaryImage = poly2mask(fc.x, fc.y, size(fobj.imdata, 1),size(fobj.imdata, 2));
        mask = (binaryImage==0) & ( (binaryImage([2:end,end],:)==1) | (binaryImage(:,[2:end,end])==1) | (binaryImage([2:end,end], [2:end,end])==1));
        binaryImage(mask) = 1;
        binaryImage = ~binaryImage;     % Invert
%        RGB = zeros([size(fobj.imdata, 1), size(fobj.imdata, 2), 3]);%; RGB(:,:,2) = binaryImage;
%        im = imshow(RGB, 'parent', ha.axes_overlay);
%        set(im, 'AlphaData', displayStatus.plot_binary_shape_opacity.*double(binaryImage), 'ButtonDownFcn', oldBtnDownFcn);
        
        mini = min(fc.x);
        widthi = max(fc.x)-mini;
        binaryImage(:, ceil(mini+parameterValues.relLengthOfHead*widthi):floor(mini+(1-parameterValues.relLengthOfHead)*widthi)) = 1;
        output.step2_fishContour = binaryImage;
        
        % 2) Apply threshold
        im_bw = false;
        while ~any(im_bw(:))
            %im_bw = im0>parameterValues.autothresh_multiplier*max(max(im0(parameterValues.vertCutoff+1:end-parameterValues.vertCutoff, :)));
            im_bw = (~binaryImage.*double(im0))>parameterValues.autothresh_multiplier*max(max(im0(~binaryImage)));
            %im_bw([1:parameterValues.vertCutoff,end-parameterValues.vertCutoff+1:end],:) = 0;
            if ~any(im_bw(:))
                parameterValues.autorhresh_multiplier = parameterValues.autorhresh_multiplier - 0.05;
            end
        end
        
        %im1 = (im0.*uint8(~binaryImage));
        %im_bw = im2bw(im1, parameterValues.autothresh_multiplier);%*max(im1(~binaryImage)));
        
        % 3) Get biggest region
        label = bwlabel(im_bw);
%             figure(123); imshow(label2rgb(label))
        props = regionprops(label);
        idx = find([props.Area] == max([props.Area]), 1, 'first');
        %im_bw = im_bw==idx;
%         im_bw(label == idx) = 4;
%         im_bw(im_bw) = 15;
        output.step3_labeledImage = im_bw;

        % 4) Fill holes / imclose
        %imclose_disksize = parameterValues.imclose_disksize;
        imclose_disksize = 0;
        im_bw = label == idx;
        im_bw = bwfill(im_bw, 'holes');
        im_bw = imclose(im_bw, strel('disk', imclose_disksize));
        im_bw = bwfill(im_bw, 'holes');
        output.step4_bwImage = im_bw;

        % 5) Get Boundary coordinates from bw image
        b = bwboundaries(im_bw, 8, 'noholes');      
        % Transform boundary to global coordinates
        b_global_x = b{1}(:,2);
        b_global_y = b{1}(:,1);
        % Calculate smooth boundary coordinates
        [b_global_x_smooth,  b_global_y_smooth]  = contour_smooth(b{1}(:,2), b{1}(:,1), 5);
        try
            fineContour = detectFineContour(b_global_x_smooth, b_global_y_smooth, fobj, parameterValues, debugStatus);
        catch
            fineContour.x = b_global_x_smooth;
            fineContour.y = b_global_y_smooth;
        end
        b_global_x_smooth = fineContour.x;
        b_global_y_smooth = fineContour.y;
        
        output.step5_boundary = struct( 'global_x',        b_global_x,        'global_y',         b_global_y,...
                                        'smooth_global_x', b_global_x_smooth, 'smooth_global_y',  b_global_y_smooth);

        
        % Return Output
        precission = 10;
        calculationResults = struct('mode',         'auto',...
                                    'parameter',    parameterValues,...
                                    'shape',        struct('name',     'fishEye',...
                                                           'x',        makePrecission(output.step5_boundary.smooth_global_x(:)', precission),...
                                                           'y',        makePrecission(output.step5_boundary.smooth_global_y(:)', precission)));

        function roundVal = makePrecission(value, precission)
            roundVal = (round(precission.*value)./precission);
            roundVal = roundVal(:)';
        end

    end


    function fishEye = detectFineContour(bf_x, bf_y, fobj, parameterValues, debugStatus)
        min_peak_width = 3;
        dbug_active_contour = false;

        % 1) Gather input
        im = fobj.getImdata(double(fobj.getImdata('toGray')), 'normalize');

        % 2) Fit Ellipse and get x/y coordinates
        efit = fit_ellipse(bf_x, bf_y);  % Center coordinates: efit.X0_in efit.Y0_in
        if (efit.a/efit.b)>2,
          %  error('eye detection failed?');
        end
        % Rotation matrix to rotate the axes with respect to an angle phi
        R = [ cos(efit.phi), sin(efit.phi);...
             -sin(efit.phi), cos(efit.phi) ];
        theta_r         = linspace(0, 2*pi);
        rotated_ellipse = R * [efit.X0 + efit.a*cos( theta_r(1:end-1) );...
                               efit.Y0 + efit.b*sin( theta_r(1:end-1) ) ];
        ixi = rotated_ellipse(1, :);
        ysi = rotated_ellipse(2, :);

        % 3) Unwrap the Fish
        [imi, x_imi, y_imi] = imunwrap_poly(im, ixi, ysi);
        %imi = fobj.getImdata(imi, 'normalize');
        % Get modified PeakImage
        peakimage = getPeakImage(imi, min_peak_width);
        %peakimage(peakimage>(max(peakimage(:))/2)) = ceil(max(peakimage(:))/2);
        % Use some kind of active contour to get the fine position
        startline = repmat(ceil(size(peakimage,1)/2), 1, size(peakimage,2));
        fine_contour = fishobj2.move2extreme(peakimage, startline, 'min', true, dbug_active_contour, 5);
        % Transform to cartesian coordinates
        indi = sub2ind(size(peakimage), fine_contour, 1:length(fine_contour));
        global_x = x_imi(indi);      % global
        global_y = y_imi(indi);

        % 4) Fit Ellipse and get x/y coordinates
        efit = fit_ellipse(global_x, global_y);  % Center coordinates: efit.X0_in efit.Y0_in
        % Rotation matrix to rotate the axes with respect to an angle phi
        R = [ cos(efit.phi), sin(efit.phi);...
             -sin(efit.phi), cos(efit.phi) ];
        theta_r         = linspace(0, 2*pi);
        rotated_ellipse = R * [efit.X0 + efit.a*cos( theta_r );...
                               efit.Y0 + efit.b*sin( theta_r ) ];
        global_x = rotated_ellipse(1, :);
        global_y = rotated_ellipse(2, :);        

        s = [0, cumsum(sqrt((global_x(2:end)-global_x(1:end-1)).^2 + (global_y(2:end)-global_y(1:end-1)).^2), 2)];
        global_y = interp1(s, global_y, linspace(0, s(end), ceil(s(end))));
        global_x = interp1(s, global_x, linspace(0, s(end), ceil(s(end))));
        
        % Make output
        fishEye = struct( 'name',     'fishEye',...
                          'x',        global_x,...
                          'y',        global_y);

    end


    function manualModeFunction(fobj, ha, modeStatus, calculationResults,  parameterValues, debugStatus, ManualSelectionUpdateFCN)
               
        % Get parent figure
        hf = get(ha.axes1, 'parent');
        hacki = [thisPlugin.parameterClassObject.handles.checkbox_showBinary,...
                 thisPlugin.parameterClassObject.handles.labelOpacity_showBinary,...
                 thisPlugin.parameterClassObject.handles.editDisplayOpacity_showBinary];
        while ~strcmp('figure', get(hf, 'Type')), hf = get(hf, 'parent'); end

        switch modeStatus

            case {'manual', 'off', 0, false}
                %set(ha.axes1, 'ButtonDownFcn', @manual_mode_button_down_fcn);
                calculationResults.mode = 'manual';
                set(hacki, 'Enable', 'off');
                set(thisPlugin.parameterClassObject.handles.checkbox_showBinary, 'Value', 0);
                ManualSelectionUpdateFCN(calculationResults);
                
                cp = fobj.capillary.shape; namy = {cp.name};
                averageCapilaryWidth = round(mean(cp(strcmp(namy, 'lower')).y - cp(strcmp(namy, 'upper')).y));
                interactionRadius = max([1, round(0.1 * averageCapilaryWidth)]);
                
                lineselector2(@manual_mode_button_up_fcn, 'fisheye', interactionRadius);
                
            case {'auto', 'on', 1, true}
                set(ha.axes1, 'ButtonDownFcn', []);
                set(hf, 'WindowButtonMotionFcn', []);
                set(hacki, 'Enable', 'on');
                
        end


        function manual_mode_button_up_fcn(br_x, br_y)
%             dbug_active_contour = false;
%             cropped_temp = output.step5_cropped_columnNormalized;
%             
            % Button is up again
            set(hf,     'WindowButtonUpFcn', []);

%             out = fishobj2.move2extreme(cropped_temp, [br_x', br_y'], 'max', false, dbug_active_contour);
%             br_x = out(:,1); br_y = out(:,2);
%             temp.step6_cdl = [br_x, br_y];
% 
% 
%             % Return Output
%             calculationResults = struct('mode',                 'manual',...
%                                         'parameter',            parameterValues,...
%                                         'shape',                struct('name',     'centralDarkLine',...
%                                                                        'x',        temp.step6_cdl(:,1)',...
%                                                                        'y',        temp.step6_cdl(:,2)'));
%             
            
            % Transform boundary to global coordinates
            b_global_x = br_x;
            b_global_y = br_y;
            % Calculate smooth boundary coordinates
            %[b_global_x_smooth,  b_global_y_smooth]  = contour_smooth(br_x', br_y', 2);

            fineContour = detectFineContour(br_x, br_y, fobj, parameterValues, debugStatus);

            b_global_x_smooth = fineContour.x;
            b_global_y_smooth = fineContour.y;
            
            output.step5_boundary = struct( 'global_x',        b_global_x,        'global_y',         b_global_y,...
                                            'smooth_global_x', b_global_x_smooth, 'smooth_global_y',  b_global_y_smooth);


            % Return Output
            precission = 10;
            calculationResults = struct('mode',         'manual',...
                                        'parameter',    parameterValues,...
                                        'shape',        struct('name',     'fishEye',...
                                                               'x',        makePrecission(output.step5_boundary.smooth_global_x(:)', precission),...
                                                               'y',        makePrecission(output.step5_boundary.smooth_global_y(:)', precission)));

            ManualSelectionUpdateFCN(calculationResults);
          
            
            function roundVal = makePrecission(value, precission)
                roundVal = (round(precission.*value)./precission);
                roundVal = roundVal(:)';
            end

        end

    end


    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
        
        % % % %
        % Display Binary Shape
        calculationResults.mode
        if strcmp(calculationResults.mode, 'auto') &&...
           displayStatus.showBinary
            %hold(ha.axes_overlay, 'on');
                RGB = zeros([size(fobj.imdata, 1), size(fobj.imdata, 2), 3]);%; RGB(:,:,2) = binaryImage;
                im = imshow(RGB, 'parent', ha.axes_overlay);
                set(im, 'AlphaData', displayStatus.showBinary_opacity.*double(output.step2_fishContour>0));
            %hold(ha.axes_overlay, 'off');
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
        % Display Binary Shape
        if displayStatus.showContour
            hold(ha.axes1, 'on');
                plot(calculationResults.shape.x, calculationResults.shape.y, 'g', 'parent', ha.axes1, 'tag', 'fisheye');        
            hold(ha.axes1, 'off');
        end

    end

    function MainDrawingFunction(fobj, ha, calculationResults)
        
       plot(calculationResults.shape.x, calculationResults.shape.y, 'g', 'parent', ha);        

    end

end