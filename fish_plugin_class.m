classdef fish_plugin_class < handle
% FISH_PLUGIN_CLASS
% Central plugin_class for fishobjects
% 
% Scientific Software Solutions
% Tobias Kießling 05/2016-08/2016
% support@tks3.de
    
    properties
    
        fish                    @fishobj2
        plugin_tag              @char
        plugin_name             @char
        plugin_title            @char
        plugin_description      @cell
        plugin_dependencies     @cell
        hasManualMode           @logical = false
        helpURL                 @char
        
        parameterClassObject    @parameterPanelClass
        plugin_parameter        @cell
        parameterClass_display  @cell
        parameterClass_debugs   @cell
        
        ParameterDefinitionsFCN @function_handle
        calculationFunction     @function_handle
        ManualSelectionFcn      @function_handle
        drawingFunction         @function_handle
        mainDrawingFunction     @function_handle
        
        plugin_output           @struct
        visible                 @logical = true
        
        enabled                 @logical = true
        
    end
    
    properties
        sourceFile
        wasEnabled = true;
    end
    
    methods
        
        function obj = fish_plugin_class
            
            % Ascribe the calling file as sourceFile
            try
                throw(MException('phony:error',''));
            catch ME
                source = {ME.stack.file};
                if length(source)>2
                    obj.sourceFile = source{2};
                end
            end
            
        end
        
        function set_fishobj(obj, newFish)
            
            obj.fish = newFish;
            % Update parameter set if a ParameterDefinitionsFCN was defined
            if ~isempty(obj.ParameterDefinitionsFCN) && ~isempty(obj.fish.impath)
                try
                    [parameter, displays, debugs] = obj.ParameterDefinitionsFCN(obj.fish);
                    obj.plugin_parameter         = parameter;
                    obj.parameterClass_display   = displays;
                    obj.parameterClass_debugs    = debugs;
                catch Me
                    obj.plugin_parameter         = {};
                    obj.parameterClass_display   = {};
                    obj.parameterClass_debugs    = {};
                end
            end     
            
            % Keep custom parameter values stored in json data
            if isstruct(obj.fish.json) && isfield(obj.fish.json, obj.plugin_tag) && isfield(obj.fish.json.(obj.plugin_tag), 'parameter') && isstruct(obj.fish.json.(obj.plugin_tag).parameter)
                storedParameterValues = obj.fish.json.(obj.plugin_tag).parameter;
                fnames = fieldnames(storedParameterValues);
                for i = 1 : length(fnames)
                    idx = find(strcmpi(obj.plugin_parameter(:,1), fnames{i}), 1, 'first');
                    if ~isempty(idx)
                        obj.plugin_parameter{idx, 4} = obj.fish.json.(obj.plugin_tag).parameter.(fnames{i});
                    end
                end
            end
            
        end
        
        
        function handles = GUIcreationFCN(obj, externalAxes, varargin)
           
            % Do we already have a parameter Class Object for this plugin?
            if isempty(obj.parameterClassObject)
                initParameterPanelClass();
            end
            % Synchronize values of the parameter panel with the fishobject
            updateParameterPanel()
            
            % Create edit GUI
            oldWBMF = get(ancestor(externalAxes(1), 'figure'), 'WindowButtonMotionFcn');
            handles = obj.parameterClassObject.makeFigure(varargin{:});
            
            function cleanup
                set(ancestor(externalAxes(1), 'figure'), 'WindowButtonMotionFcn', oldWBMF);
            end
            
            function initParameterPanelClass()
                % % % %
                % Initialize Parameter Panel Class
                pc = parameterPanelClass(obj.plugin_parameter, obj.parameterClass_display, obj.parameterClass_debugs);
                pc.manualModeEnable          = obj.hasManualMode;
                if ~isempty(obj.calculationFunction)
                    pc.UpdateCalculationFunction = obj.calculationFunction;
                end
                if ~isempty(obj.ManualSelectionFcn)
                    pc.ManualSelectionFcn        = obj.ManualSelectionFcn;
                end
                if isempty(obj.plugin_title)
                    pc.title = [obj.plugin_name, ' Detection'];
                else
                    pc.title = obj.plugin_title;
                end
                pc.DrawingFunction           = obj.drawingFunction;
                pc.OK_callback               = @(varargin) OK_callback(obj, varargin{:});
                pc.Cancle_callback           = @(varargin) Cancle_callback(obj, varargin{:});
                pc.helpURL                   = obj.helpURL;
                obj.parameterClassObject = pc;
            end
            
            function updateParameterPanel()
                % Adjust parameter of this parameterClassObject to match the parameter set of the current fishobject
                pc = obj.parameterClassObject;
                try
                    % Update mode
                    pc.currentMode = 'auto';
                    if isfield(obj.fish.(obj.plugin_tag), 'mode')
                        pc.currentMode = obj.fish.(obj.plugin_tag).mode;
                    end
                    if strcmp('manual', pc.currentMode)
                        % If in manual mode, we integrate manul selection by updating calculation Results manually
                        pc.calculationResults = obj.fish.(obj.plugin_tag);
                    end
                    
                    % Update Parameter Values (Use Values of the current fishobject)
                    pc.parameterControl_default = cellfun(@(x) obj.fish.(obj.plugin_tag).parameter.(x), pc.parameterControl_tag);
                    if ~isfield(obj.fish.(obj.plugin_tag), 'parameter') || isempty(obj.fish.(obj.plugin_tag).parameter)
                        if isempty(obj.fish.(obj.plugin_tag))
                            obj.fish.(obj.plugin_tag) = struct('parameter', struct());
                        else
                            obj.fish.(obj.plugin_tag).parameter= struct(); 
                        end
                    end
                    pc.ParameterValues = obj.fish.(obj.plugin_tag).parameter;
                    
                    % Update Display Status (Use default values from fish_plugin)
                    pd = obj.parameterClass_display;
                    if ~isempty(pd)
                        pc.displayControl_default   = cellfun(@(x) pd{strcmp(pd(:,1),x), 3}, pc.displayControl_tag);
                        status = [[pd(:,1);cellfun(@(x) [x, '_opacity'], pd([pd{:,4}],1), 'Uniform', 0)], [pd(:,3); pd([pd{:,4}],5)]]';
                        pc.DisplayStatus = struct(status{:});
                    else
                        pc.DisplayStatus = struct([]);
                    end
                    
                    % ... and set debugStatus = false for all
                    debugStatus = struct([]);
                    if ~isempty(obj.parameterClass_debugs)
                        debugStatus = [obj.parameterClass_debugs(:,1)';repmat({false}, 1, size(obj.parameterClass_debugs,1))];
                        debugStatus = struct(debugStatus{:});
                    end
                    pc.DebugStatus = debugStatus;
                    
                    pc.externalAxes = [externalAxes, getappdata(externalAxes, 'axes_overlay')];
                    
                catch Me
                    disp(Me.getReport);
                    waitfor(msgbox({'Parameter mismatch while reading parameter from json file.', ' ', 'Error:', Me.message, ' ', 'Will ignore parameters from JSON-file, and use default Parameter instead...'}, 'Warning', 'warn'));
                end
                
                
            end
            
            function OK_callback(varargin)
                % Store Result back to dynamic property of the fishobject
                obj.fish.(obj.plugin_tag) = obj.parameterClassObject.calculationResults;
                % Save to JsonFile
                obj.fish.savedata;
                
                % Make edit GUI invisible while updating
                set(obj.parameterClassObject.handles.figure1, 'visible', 'off')
                % % %
                % Update all dependent features
                hwait = waitbar(0, '', 'name', ['Updating dependent features']);
                [~, depTree] = fish_plugin_class.sortPlugins(obj.fish.plugins);
                pnames = fieldnames(depTree);
                pnames = pnames(cellfun(@(x) ismember(obj.plugin_tag, depTree.(x)), pnames));
                depFeatures = obj.fish.plugins(ismember({obj.fish.plugins.plugin_tag}, pnames));
                for i = 1 : length(depFeatures)
                    if ishandle(hwait)
                        waitbar(i/(length(depFeatures)+1), hwait, ['Updating:    "', depFeatures(i).plugin_name, '"     (', num2str(i), ' of ', num2str(length(depFeatures)), ')']);
                    else
                        % User has closed the waitbar => stop processing
                        break
                    end
                    if depFeatures(i).fish ~= obj.fish
                        depFeatures(i).set_fishobj(obj.fish);
                        error('häää?');
                    end
                    obj.fish.(depFeatures(i).plugin_tag) = depFeatures(i).getResults(true); % Recalculate with force_new_calculation
                end
                
                % Save again to JsonFile
                obj.fish.savedata;
                
                % This Ensures that we have a check everywhere
                minIDX = find(strcmp({obj.fish.plugins.plugin_tag}, obj.plugin_tag), 1, 'first') + 1;
                for i = minIDX : length(obj.fish.plugins)
                    thisPlugin = obj.fish.plugins(i);
                    if ~ismember(thisPlugin, depFeatures)
                        obj.fish.lastAction = struct('Action', 'processingEnd', 'fromFile', false, 'success', ~isempty(thisPlugin.plugin_output), 'Plugin', thisPlugin);
                        notify(obj.fish, 'processingEnd');
                    end
                end
                
                % Clean up
                cleanup();
                delete(hwait)
                delete(obj.parameterClassObject.handles.figure1);
                disp('OK');
                
            end

            function Cancle_callback(varargin)
                cleanup();
                delete(obj.parameterClassObject.handles.figure1);
                disp('Cancle');
            end

        end
        
        function output = getResults(obj, force_new_calculation, varargin)
            showErrors = true;
            if ~exist('force_new_calculation', 'var'), force_new_calculation = false; end
            if ischar(force_new_calculation) && strcmp('-noWarningMessage', force_new_calculation)
                force_new_calculation = false;
                showErrors = false;
            end
            
            eraseManualSelections = any(cellfun(@(x) ischar(x) && strcmpi(x, '-eraseManualSelections'), varargin));
            forceEnable = any(cellfun(@(x) ischar(x) && strcmpi(x, 'callbackFeatureEnable'), varargin));
            
            fromFile = ~force_new_calculation && ~isempty(obj.fish.json);
            if fromFile
                if forceEnable
                    obj.enabled = obj.wasEnabled;
                else
                    % Don't display out put if disabled (even if we have some stored data here
                    obj.enabled = isfield(obj.fish.json, obj.plugin_tag);
                    % Always display output if we have stored data despite of whether this plugin is enabled or not
                    %obj.enabled = obj.wasEnabled;
                end
            else
                obj.enabled = obj.wasEnabled;
            end
            
            if ~obj.fish.enabled
                output = struct([]);

            elseif ~obj.enabled 
                output = struct([]);
                
            else

                % Notify fishobj that we're processing
                %fromFile = fromFile && isfield(obj.fish.json, obj.plugin_tag) && ~isempty(obj.fish.json.(obj.plugin_tag));
                noSpinner = fromFile && ~any(cellfun(@(x) ischar(x) && strcmpi(x, 'callbackFeatureEnable'), varargin));
                obj.fish.lastAction = struct('Action', 'processingStart', 'fromFile', noSpinner, 'Plugin', obj);
                notify(obj.fish, 'processingStart');

                try
                    % Get Results from JSON file if present
                    if ~eraseManualSelections && fromFile && isfield(obj.fish.json, obj.plugin_tag) && ~isempty(obj.fish.json.(obj.plugin_tag)) && (~forceEnable || (obj.hasManualMode && isfield(obj.plugin_output, 'mode') && ~strcmpi('auto', obj.plugin_output.mode)))
                        % % %
                        % Just return the stored data
                        output = obj.fish.json.(obj.plugin_tag);

                    else
                        % % % 
                        % Get parameter  for calculation
                        if ~isempty(obj.plugin_parameter)
                            % There's already s.th. stored in the JSON-file?
                            % => Use parameters from JSON - file
                            if ~eraseManualSelections && force_new_calculation && isfield(obj.fish.json, obj.plugin_tag)
                                defaultParameter = obj.fish.(obj.plugin_tag).parameter;
                                % If in manual mode, we change nothing!
                                if isfield(obj.fish.(obj.plugin_tag), 'mode') && strcmp('manual', obj.fish.(obj.plugin_tag).mode)
                                    output = obj.fish.(obj.plugin_tag);
                                    obj.plugin_output = output;

                                    % Notify fishobj that we stopped processing
                                    obj.fish.lastAction = struct('Action', 'processingEnd', 'fromFile', fromFile, 'success', ~isempty(output), 'Plugin', obj);
                                    notify(obj.fish, 'processingEnd');
                                    return
                                end
                            else
                                %   => Do Calculation with default Parameters
                                % Update parameter set if a ParameterDefinitionsFCN was provided
                                if ~isempty(obj.ParameterDefinitionsFCN)
                                    [parameter, displays, debugs] = obj.ParameterDefinitionsFCN(obj.fish);
                                    obj.plugin_parameter         = parameter;
                                    obj.parameterClass_display   = displays;
                                    obj.parameterClass_debugs    = debugs;
                                end
                                defaultParameter = [obj.plugin_parameter(:,1)';obj.plugin_parameter(:,4)'];
                                defaultParameter = struct(defaultParameter{:});
                                
                                % Keep custom parameter values stored in json data
                                if isstruct(obj.fish.json) && isfield(obj.fish.json, obj.plugin_tag) && isfield(obj.fish.json.(obj.plugin_tag), 'parameter')
                                    storedParameterValues = obj.fish.json.(obj.plugin_tag).parameter;
                                    defaultParameter = mergestruct(defaultParameter, storedParameterValues);
                                end
                                
                            end
                        else
                            defaultParameter = [];
                        end
                        % ... and set debugStatus = false for all
                        if ~isempty(obj.parameterClass_debugs)
                            debugStatus = [obj.parameterClass_debugs(:,1)';repmat({false}, 1, size(obj.parameterClass_debugs,1))];
                            debugStatus = struct(debugStatus{:});
                        else
                            debugStatus = struct([]);
                        end
                        % -.-
                        if ~isempty(obj.calculationFunction)
                            output = obj.calculationFunction(defaultParameter, debugStatus);
                        else
                            output = struct([]);
                        end

                    end

                catch Me
                    catblock(Me)
%                     try
%                         output = struct('mode', 'auto', 'parameter', defaultParameter, 'shape', struct([]));
%                     catch
                        output = struct([]);
%                    end

                end
            end
            
            obj.plugin_output = output;
            
            % Notify fishobj that we stopped processing
            noSpinner = fromFile && ~any(cellfun(@(x) ischar(x) && strcmpi(x, 'callbackFeatureEnable'), varargin));
            obj.fish.lastAction = struct('Action', 'processingEnd', 'fromFile', noSpinner, 'success', ~isempty(output) || isempty(obj.calculationFunction), 'Plugin', obj);
            notify(obj.fish, 'processingEnd');
            
            function catblock(Me)
                if ~isdeployed
                    disp('----------------------');
                    disp(Me.getReport);
                end
                if showErrors
                    waitfor(msgbox({'Error while executing',...
                                   ' ', '    calculationFunction',...
                                   ' ', 'for Plugin: ',...
                                   ' ',['       Name: ', obj.plugin_name],...
                                       ['       Tag:  ', obj.plugin_tag],...
                                   ' ', 'Error:', Me.message,...
                                   ' ', 'Ascribing empty output and proceed...'}, 'Error', 'warn'));
                end
            end
        end
        
        
        function fobj = uiGetFish(obj, dependencies)
            if ~exist('dependencies', 'var'), dependencies = obj.plugin_dependencies; end
            dependencies{end+1} = obj.plugin_tag;
            
            location = pwd; 
            file = '';
            
            % Sticky file/location
            if ispref('fish_plugin_class', 'uiSelectDir')
                location = getpref('fish_plugin_class', 'uiSelectDir');
                file     = getpref('fish_plugin_class', 'uiSelectFile');
            end
                        
            % List of supported image formats
            imfmts = imformats; 
            imfmts = cellfun(@(x) ['*.', x, ';'], [imfmts.ext], 'UniformOutput', 0);
            imfmts = [imfmts{:}];
            
            % Let the user select 
            [file, location] = uigetfile({'*.*',  'All Files';...
                                          imfmts, 'All Image Files'},...
                                         'Select a fish image',...
                                         fullfile(location, file));
            
            if file==0
                % Cancled -> Return empty fishobject
                impath = '';
            else
                % OK
                impath = fullfile(location, file);
                % Sticky file(location
                setpref('fish_plugin_class', 'uiSelectDir',  location);
                setpref('fish_plugin_class', 'uiSelectFile', file);
            end
            
            % Return fishobject
            fobj = fishobj2(impath, '-withPlugins', dependencies);

        end
       
        function list = getDependencyList(thisPlugin, allPlugins, list)
            if ~exist('list', 'var'), list = {}; end
                
            thisList = thisPlugin.plugin_dependencies;
            for i = 1 : length(thisList)
                pii = allPlugins(strcmp({allPlugins.plugin_tag}, thisList{i}));
                list = unique([getDependencyList(pii, allPlugins, list), pii.plugin_tag, list], 'stable');
            end
            
        end
        
        
        function parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults)
            persistent defaults
            if isempty(parameter), return; end
            defaults = [];
            if ~exist('rewrite_defaults', 'var'), rewrite_defaults = false; end
            
            parameter_defaultpath = fullfile(thisPlugin.fish.parameterFile_dir, thisPlugin.fish.parameterFile);
            
            % Load central default parameter file if not cached already
            if isempty(defaults) || ~isstruct(defaults)
                addlistener(thisPlugin.fish, 'parameterFileHasChanged', @updateDefaultsFile);
                if exist(parameter_defaultpath, 'file'), updateDefaultsFile(); end
            end
            
            if exist(parameter_defaultpath, 'file')
                % Does the central paramter file has information about this plugin?
                if isfield(defaults, thisPlugin.plugin_tag) && ~rewrite_defaults
                    needsUpdate = false;
                    % Yes, update parameter cell
                    default_values = defaults.(thisPlugin.plugin_tag);
                    fnames = parameter(:, 1);
                    for i = 1 : length(fnames)
                        if isfield(default_values, fnames{i}) && ~strcmp('auto', default_values.(fnames{i}))
                            % Get Value from central default file only if it's not in auto mode
                            parameter{strcmp(parameter(:,1), fnames{i}), 4} = default_values.(fnames{i});
                        elseif ~parameter{strcmp(parameter(:,1), fnames{i}), 8}
                            % The default file has 'auto' saved, but this is no auto parameter => correct the central parameter file
                            defaults.(thisPlugin.plugin_tag).(fnames{i}) = parameter{strcmp(parameter(:,1), fnames{i}), 4};
                            needsUpdate = true;
                        end
                    end
                    % Update central parameter file if necessary
                    if ~all(ismember(parameter(:,1), fnames))
                        % The input parameter cell has more parameter than listed in the default file
                        new_parameters = parameter(~ismember(parameter(:,1), fnames), 1);
                        for i = 1 : length(new_parameters)
                            if (size(parameter,2)>7) && (parameter{strcmp(parameter(:,1), new_parameters{i}), 8})
                                defaults.(thisPlugin.plugin_tag).(new_parameters{i}) = 'auto';
                            else
                                defaults.(thisPlugin.plugin_tag).(new_parameters{i}) = parameter{strcmp(parameter(:,1), new_parameters{i}), 4};
                            end
                        end
                        needsUpdate = true;
                    end
                    if ~isstruct(defaults.(thisPlugin.plugin_tag)), defaults.(thisPlugin.plugin_tag) = struct(); end
                    fnames = fieldnames(defaults.(thisPlugin.plugin_tag));
                    if ~all(ismember(fnames, parameter(:,1)))
                        % The default file has more parameters than the input parameter cell
                        parameters2remove = fnames(~ismember(fnames, parameter(:,1)));
                        for i = 1 : length(parameters2remove)
                            defaults.(thisPlugin.plugin_tag) = rmfield(defaults.(thisPlugin.plugin_tag), parameters2remove{i});
                        end
                        needsUpdate = true;
                    end
                    % Write to central parameter file if necessary
                    if needsUpdate
                        savejson('', defaults, struct('FileName', parameter_defaultpath, 'SingletArray', 0));
                    end
                else
                    % The central parameter file has NO information about this plugin
                    defaults.(thisPlugin.plugin_tag) = struct;
                    new_parameters = parameter(:, 1);
                    for i = 1 : length(new_parameters)
                        if (size(parameter,2)>7) && (parameter{i, 8}) % HasAuto?
                            defaults.(thisPlugin.plugin_tag).(new_parameters{i}) = 'auto';
                        else
                            defaults.(thisPlugin.plugin_tag).(new_parameters{i}) = parameter{i, 4};
                        end
                    end
                    savejson('', defaults, struct('FileName', parameter_defaultpath, 'SingletArray', 0));
                end
                
            else
                % No central default parameter file can be found?
                defaults = struct();
                new_parameters = parameter(:, 1);
                for i = 1 : length(new_parameters)
                    if (size(parameter,2)>7) && (parameter{i, 8})
                        defaults.(thisPlugin.plugin_tag).(new_parameters{i}) = 'auto';
                    else
                        defaults.(thisPlugin.plugin_tag).(new_parameters{i}) = parameter{i, 4};
                    end
                end
                if ~(exist(fileparts(parameter_defaultpath), 'dir')==7)
                    % Check if user direcory exists
                    if ~(exist(fileparts(fileparts(parameter_defaultpath)), 'dir')==7) %~(exist(thisPlugin.fish.userdir, 'dir')==7)
                        mkdir(fileparts(fileparts(parameter_defaultpath)));            % mkdir(thisPlugin.fish.userdir);
                    end
                    mkdir(fileparts(parameter_defaultpath));
                end
                savejson('', defaults, struct('FileName', parameter_defaultpath, 'SingletArray', 0));
%                 msgbox({'New defaults file created!'}, 'Info');
%                 
%                 % Open Explorer Window and select File
%                 [~, fname_, ext_] = fileparts(parameter_defaultpath);
%                 dos(['explorer /select,"', parameter_defaultpath, '"']);
            end
            
            function updateDefaultsFile(varargin)
                parameter_defaultpath = fullfile(thisPlugin.fish.parameterFile_dir, thisPlugin.fish.parameterFile);
                defaults = struct();
                if exist(parameter_defaultpath, 'file')==2
                    defaults = loadjson(parameter_defaultpath);
                end
            end
        end
        
    end
    
    methods(Static)
       
        function [sortedPlugins, dependencyTree] = sortPlugins(pluginList)
            if isempty(pluginList), sortedPlugins = pluginList; dependencyTree =struct([]); return; end
            
            % Build dependency tree
            for i = 1 : length(pluginList)
                dependencyTree.(pluginList(i).plugin_tag) = getDependencyList(pluginList(i), pluginList);
                dependencyTree.(pluginList(i).plugin_tag) = unique(dependencyTree.(pluginList(i).plugin_tag), 'stable');
%                disp([pluginList(i).plugin_name, ':    ', cellstr2list(dependencyTree.(pluginList(i).plugin_tag))]);
            end
            
            % Order Plugins so that Plugins come behind the plugins they depend on
            sortedPlugins = pluginList(1);
            for i = 2 : length(pluginList)
                insertAt = 0.5;
                for j = 1 : length(sortedPlugins)
                    if ismember(pluginList(i).plugin_tag, dependencyTree.(sortedPlugins(j).plugin_tag)) ||...
                            isempty(dependencyTree.(pluginList(i).plugin_tag))
                      %(~ismember(sortedPlugins(j).plugin_tag, dependencyTree.(pluginList(i).plugin_tag)) && all(ismember(dependencyTree.(pluginList(i).plugin_tag), {sortedPlugins(1:j).plugin_tag})) ) 
                        break
                    else
                        insertAt = insertAt + 1;
                    end
                end
                sortedPlugins = [sortedPlugins(1:floor(insertAt)), pluginList(i), sortedPlugins(ceil(insertAt):end)];
                %{sortedPlugins.plugin_name}';
            end    
            
            disp('sorted')
            
            function output = cellstr2list(input)
                if ~iscell(input)
                    error('input was expected to be a cellarray of strings');
                end
                l = length(input);
                list_ = [repmat({''''}, 1, l);...
                         input;...
                         repmat({''''}, 1, l);...
                        [repmat({', '}, 1, l-1), {''}]];
                output = [list_{:}];
            end
            
        end
        
    end
    
end

