function output_ = aNew_fishPlugin(fobj, varargin)
% a New - FishPlugin
% Template for a new fish plugin
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
    thisPlugin.plugin_tag          = 'newPlugin';
    thisPlugin.plugin_name         = 'Example Plugin';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {};
    thisPlugin.hasManualMode       = false;
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

        % ===========    TAG                NAME                TYPE        DEFAULT     MIN     MAX     INCREMENT   
        parameter = {   'threshold',        'Variable NAme',    'numeric',  0.95,        0,      1,     0.025;...
                        'anotherValue',     '2nd value',        'numeric',  0.5,         0,      1,     0.01};

        % ===========   TAG                 NAME             DEFAULT     AddOPACITY     OpacityDEFAULT
        displays  = {   'plotA',            'plotA',         true,       false,         NaN;...
                        'plotB',            'plotB',         true,       true,          0.5 };

        % ===========   TAG                     NAME                    DebugTAG                AddOPACITY      OpacityDEFAULT
        debugs    = {  'debug_here',            'debug_here',           'notochord',            false,          NaN     };
    
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = true;       % <= Set to true to apply new values
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end

    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
        % Get image from fish object
        im = fobj.getImdata('toGray');
        
        % Transform image to bw image using the threshold parameter
        imbw = im2bw(imcomplement(im), parameterValues.threshold);
        
        % Get contour of the biggest darkest region
        out = bwboundaries(imbw);
        if isempty(out)
            out = zeros(0,2);
        else
            [~, maxIDX] = max(cellfun(@(x) size(x,1), out));
            out = out{maxIDX};
        end
        
        %% Return Output
        calculationResults = struct('mode',                 'auto',...
                                    'parameter',            parameterValues,...
                                    'perimeter',            123,...
                                    'shape',                struct('name',  'outline',...
                                                                   'x',     out(:,2)',...
                                                                   'y',     out(:,1)'));

             
        
    end

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
        
        % Display Image
        im = fobj.getImdata();
        imshow(im, 'parent', ha.axes1);
       
        % Plot contour of the biggest darkest region if the checkbox is checked
        if displayStatus.plotA
            hold(ha.axes1, 'on')
                plot(calculationResults.shape.x, calculationResults.shape.y, 'r', 'parent', ha.axes1, 'LineWidth', 2);
            hold(ha.axes1, 'off')
        end
        
    end

    function MainDrawingFunction(fobj, ha, calculationResults)
        plot(calculationResults.shape.x, calculationResults.shape.y, 'r', 'parent', ha, 'LineWidth', 2);
    end

end