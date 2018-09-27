function output_ = capillary_fishPlugin(fobj, varargin)
% Capillary - FishPlugin
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
    thisPlugin.drawingFunction     = @(varargin) DrawingFunction(    thisPlugin.fish, varargin{:});
    thisPlugin.mainDrawingFunction = @(varargin) MainDrawingFunction(thisPlugin.fish, varargin{:});
    % ----- EDIT ONLY FROM HERE -------------------------
    thisPlugin.plugin_tag          = 'capillary';
    thisPlugin.plugin_name         = 'Capillary';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {};
    thisPlugin.hasManualMode       = false;
    thisPlugin.helpURL             = 'help\capillary.html';
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

        % ===========   TAG                 NAME                TYPE        DEFAULT     MIN     MAX     INCREMENT   HasAuto
        parameter = {   'threshMultiplier', 'threshMultiplier', 'numeric',  0.95,        0,      3,      0.05,       false;...
                        'vertCutoff',       'vertCutoff',       'numeric',  0.075        0,      0.5,    0.025,      false;...
                        'horizCutoff',      'horizCutoff',      'numeric',  0.25,        0,      0.5,    0.025,      false;...
                        'steps',            'steps',            'numeric',  0.0125,      0,      0.5,    0.025,      false};

        % ===========   TAG               NAME              DEFAULT AddOPACITY     OpacityDEFAULT
        displays  = {   'showBinary',     'showBinary',     false,  true,          0.5     ;...
                        'plotCutoffs',    'plotCutoffs',    true,   false,         NaN     ;...
                        'plotCapillary',  'plotCapillary',  true,   false,         NaN     };

        % ===========   TAG             NAME                DebugTAG        AddOPACITY      OpacityDEFAULT
        debugs    = {   'debug_here',   'debug_here',       'getCapillary', false,          NaN     };%...
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
        Im     = double(fobj.getImdata('toGray', 'invert'))./255;
        cap = getCapilary_v2(Im, parameterValues.threshMultiplier, ...
                                 max([0, round(size(Im, 1).*parameterValues.vertCutoff)]), ...
                                 max([0, round(size(Im, 2).*parameterValues.horizCutoff)]), ...
                                 max([1, round(size(Im, 1).*parameterValues.steps)]), ...    
                                 debugStatus.debug_here);
            
        
%         % Calculate Output
%         t = 1:(2*pi/360):2*pi;
%         ixi = cos(parameterValues.parameter3.*t);
%         ysi = parameterValues.parameter1.*sin(parameterValues.parameter2.*t);
        
        % Return Output
        precission = 10;
        calculationResults = struct('mode',         'auto',...
                                    'parameter',    parameterValues,...
                                    'shape',      [ struct('name',     'upper',...
                                                           'x',        1:length(cap.upper),...           
                                                           'y',        makePrecission(cap.upper,     precission)),...
                                                    struct('name',     'upper_in',...
                                                           'x',        1:length(cap.upper_in),...           
                                                           'y',        makePrecission(cap.upper_in,  precission)),...
                                                    struct('name',     'lower',...
                                                           'x',        1:length(cap.lower),...           
                                                           'y',        makePrecission(cap.lower,     precission)),...
                                                    struct('name',     'lower_in',...
                                                           'x',        1:length(cap.lower_in),...           
                                                           'y',        makePrecission(cap.lower_in,  precission)) ]);

        function roundVal = makePrecission(value, precission)
            roundVal = (round(precission.*value)./precission);
            roundVal = roundVal(:)';
        end

    end

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)

        im = fobj.getImdata();

        % % % %
        % Display Binary Shape
        if displayStatus.showBinary
            %% Calculate absolute derivative
%             A = abs(diff((im2double(im)),1,1));
%             A = A-min(A(:));
%             A = A./max(A(:));
%             A = [A; repmat(zeros(1,size(A,2)),1,1,size(A,3))];
            A = double(fobj.getImdata('toGray', 'invert'))./255;
            % % % %
            % 2) Create binary image from derivative image...
            B = im2bw(A, parameterValues.threshMultiplier*graythresh(A(round(size(im, 1).*parameterValues.vertCutoff+1):end-round(size(im, 1).*parameterValues.vertCutoff), :)));
            RGB = zeros([size(B, 1), size(B, 2), 3]); RGB(:,:,1) = B;
            imh = imshow(RGB, 'parent', ha.axes_overlay);
            set(imh, 'AlphaData', displayStatus.showBinary_opacity.*double(B));%, 'ButtonDownFcn', oldBtnDownFcn);
        else
            cla(ha.axes_overlay);
        end
        
        % % % %
        % Display Capillary
        if displayStatus.plotCapillary      % Plot contour checkbox?
            ax = ha.axes_overlay;
            hold(ax, 'on');
                plot(calculationResults.shape(1).x, calculationResults.shape(1).y, 'g', 'parent', ax); 
                plot(calculationResults.shape(2).x, calculationResults.shape(2).y, 'b', 'parent', ax); 
                plot(calculationResults.shape(3).x, calculationResults.shape(3).y, 'b', 'parent', ax); 
                plot(calculationResults.shape(4).x, calculationResults.shape(4).y, 'g', 'parent', ax);
            hold(ax, 'off');
        end
        set(findall(ha.axes_overlay), 'PickableParts', 'none', 'HitTest', 'off');
        
        % % % %
        % Display Image
        oldTag        = get(ha.axes1, 'Tag');          % The Tag-property and ButtonDownFcn are erased when using imshow
        oldBtnDownFcn = get(ha.axes1, 'ButtonDownFcn');        
        imh = imshow(im, 'parent', ha.axes1);
        set(imh, 'ButtonDownFcn', oldBtnDownFcn);
        set(ha.axes1, 'Tag', oldTag, 'ButtonDownFcn', oldBtnDownFcn);      % This way we keep the Tag/ButtonDownFcn despite of imshow
        
        % % % %
        % Display Cutoffs
        if displayStatus.plotCutoffs
            vertCutoff = max([0, round(size(im, 1).*parameterValues.vertCutoff)]);
            horizCutoff = max([0, round(size(im, 2).*parameterValues.horizCutoff)]);
            ax = ha.axes1;
            hold(ax, 'on');
                plot(horizCutoff.*[1,1],                  [1,size(im, 1)], 'r', 'parent', ax); 
                plot((size(im, 2)-horizCutoff+1).*[1,1] , [1,size(im, 1)], 'r', 'parent', ax); 
                plot([1,size(im, 2)],   vertCutoff.*[1,1] ,                'r', 'parent', ax); 
                plot([1,size(im, 2)],  (size(im, 1)-vertCutoff+1).*[1,1],  'r', 'parent', ax); 
            hold(ax, 'off');
        end

    end

    function MainDrawingFunction(fobj, ha, calculationResults)
        
        plot(calculationResults.shape(1).x, calculationResults.shape(1).y, 'b', 'parent', ha); 
        plot(calculationResults.shape(2).x, calculationResults.shape(2).y, 'g', 'parent', ha); 
        plot(calculationResults.shape(3).x, calculationResults.shape(3).y, 'b', 'parent', ha); 
        plot(calculationResults.shape(4).x, calculationResults.shape(4).y, 'g', 'parent', ha);
        
    end

end