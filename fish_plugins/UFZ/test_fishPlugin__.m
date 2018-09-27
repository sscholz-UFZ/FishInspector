function output_ = notochord_fishPlugin(fobj, varargin)
% Capillary - FishPlugin
% Detects the upper and lower contour of the notochord
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
    thisPlugin.drawingFunction     = @(varargin) DrawingFunction(    thisPlugin.fish, varargin{:});
    thisPlugin.mainDrawingFunction = @(varargin) MainDrawingFunction(thisPlugin.fish, varargin{:});
    % ----- EDIT ONLY FROM HERE -------------------------
    thisPlugin.plugin_tag          = 'test';
    thisPlugin.plugin_name         = 'Test';
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
    output = [];
    
    %% Plugin Functions (Here is where the Parameters, Calculations, and Drawings are implemented)
    
    function [parameter, displays, debugs] = ParameterDefinitions(fobj)

        % ===========    TAG                NAME                TYPE        DEFAULT     MIN     MAX     INCREMENT   HasAuto
        parameter = {   'LPF',              'LPF',              'numeric',  0.5,        0,      1,      0.05,       false;...
                        'Phase_strength',   'Phase_strength',   'numeric',  0.05,       0,      1,      0.05,       false;...
                        'Warp_strength',    'Warp_strength',    'numeric',  1,       0,      100,    1,       false;...
                        'Thresh_min',       'Thresh_min',       'numeric',  0.05,      -1,      1,      0.05,       false;...
                        'Thresh_max',       'Thresh_max',       'numeric',  0.05,       0,      1,      0.05,       false;...
                        'Morph_flag',       'Morph_flag',       'numeric',  0.00,       0,      1,      1,          false};

        % ===========   TAG                       NAME                      DEFAULT     AddOPACITY     OpacityDEFAULT
        displays  = {   'plot',                 'plot',         true,       false,         NaN     };

        % ===========   TAG                     NAME                    DebugTAG                AddOPACITY      OpacityDEFAULT
        debugs    = {  'debug_here',            'debug_here',           'notochord',            false,          NaN     ;...
                       'debug_active_contour',  'debug_active_contour', 'move2extreme_debug',   false,          NaN     };
    
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end

    im = [];
    out = [];
    bw = [];
    
    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
        %addpath('C:\Users\tobi\Documents\Freelancer\Basteleien\Git repository\sandbox')
      
        im = double(fobj.getImdata('toGray'));%, 'subtractBackground', 'smooth', 1, 'invert'));
        [fx,fy] = imgradient(im, 'Sobel');
        im = fx;
        %im = double(fobj.getImdata(im, 'normalize'));
        im = im - min(im(:));
        im = im ./ max(im(:));
        out = watershed(im);
        bw = out==0 & fy<0 & im>graythresh(im)*parameterValues.LPF;
        
        %% Return Output
        calculationResults = struct();
        calculationResults = struct('mode',                 'auto',...
                                    'parameter',            parameterValues,...
                                    'shape',                [ ]);

             
        
    end

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
        
        im = double(fobj.getImdata('toGray'));%, 'subtractBackground');
        
       

            % overlay original image with detected features
            overlay = double(imoverlay(im, bw, [1 0 0]));
            imshow(overlay/max(max(max(overlay))), 'parent', ha.axes1);
            %imshow(bw, 'parent', ha.axes1);
    end

    function MainDrawingFunction(fobj, ha, calculationResults)
overlay = double(imoverlay(im, bw, [1 0 0]));
            imshow(overlay/max(max(max(overlay))), 'parent', ha);
%         plot(calculationResults.shape(1).x,  calculationResults.shape(1).y, 'r', 'parent', ha);
%         plot(calculationResults.shape(2).x,  calculationResults.shape(2).y, 'r', 'parent', ha);
        
    end

end