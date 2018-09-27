classdef parameterPanelClass < handle
% PARAMETERPPANELCLASS
% Basic class for creating parameter panels
%
% Scientific Software Solutions
% Tobias Kießling 01/2013-08/2016
% support@tks3.de
    
    properties
        
        manualModeEnable                        @logical = true
        manualModeChangedCallback               @function_handle        % Low Level Callback
        externalAxes                            @matlab.graphics.axis.Axes
        currentMode                             @char = 'auto'
        title                                   @char = 'Title'
        
        parameterControl_tag                    @cell
        parameterControl_name                   @cell
        parameterControl_type                   @cell
        parameterControl_default                @double
        parameterControl_min                    @double
        parameterControl_max                    @double
        parameterControl_increment              @double
        parameterControl_hasAuto                @logical
        parameterControlChangedCallback         @function_handle        % Low Level Callback

        displayControl_tag                      @cell
        displayControl_name                     @cell
        displayControl_default                  @logical
        displayControl_addOpacityControl        @logical
        displayControl_opacityDefault           @double
        displayControlChangedCallback           @function_handle        % Low Level Callback

        debugControl_tag                        @cell        
        debugControl_name                       @cell
        debugControl_debug_tag                  @cell
        debugControl_addOpacityControl          @logical
        debugControl_opacityDefault             @double
        debugControlChangedCallback             @function_handle        % Low Level Callback

        axes_generateOverlay                    @logical = true
        axes_generateImagetools                 @logical = true   % todo

        handles                                 @struct
        calculationResults                      @struct
        ParameterValues                         @struct
        DisplayStatus                           @struct
        DebugStatus                             @struct
        UpdateCalculationFunction               @function_handle        % High Level Callback
        ManualSelectionFcn                      @function_handle        % High Level Callback
        DrawingFunction                         @function_handle        % High Level Callback
        OK_callback                             @function_handle        % High Level Callback
        Cancle_callback                         @function_handle        % High Level Callback
        helpURL                                 @char
        
    end
    
    methods
        
        function obj = parameterPanelClass(varargin)
            
            % Support Simple initalization via cell arrays
            if length(varargin)==3 && all(cellfun(@(x) iscell(x), varargin))
                obj.addParameterControl(varargin{1});
                obj.addDisplayControl(varargin{2});
                obj.addDebugControl(varargin{3});
            end
            
        end
        
        function addParameterControl(obj, varargin)
            % % %
            % 1) Check input
            input_is_name_value_pair = (((length(varargin)/2)==round(length(varargin)/2)) && ...                                     % number of input arguments is even
                                        (all(cellfun(@ischar, varargin(1:2:end))) && all(cellfun(@isnumeric, varargin(2:2:end)))));  % characters and numbers alternate
            % Support cell-array input / comma seperated input
            if ~input_is_name_value_pair
                if iscell(varargin{1})
                    % Support Cell array
                    for i = 1 : size(varargin{1},1)
                        obj.addParameterControl(varargin{1}{i,:});
                    end
                    return
                else
                    % Transform comma seperated input to 'key-value-pair'-input
                    fnames = properties(obj)';  % Get list of properties
                    fnames = fnames(cellfun(@(x) ~isempty(strfind(x, 'parameterControl_')), fnames));
                    fnames = cellfun(@(x) x(length('parameterControl_')+1:end), fnames, 'UniformOutput', 0);
                    
                    newVarargin = [fnames(1:length(varargin)); varargin];
                    varargin = newVarargin(:)';
                end
            end
            % Process 'key-value-pair'-input
            required = {'tag'};
            p = parameterPanelClass.varargin2struct(varargin);
            if any(cellfun(@(tag) ~isfield(p, tag), required))
                error(['Required at least: ', parameterPanelClass.cellstr2list(required)])
            end
            
            % % %
            % 2) Ascribe input
            % TAG
            obj.parameterControl_tag{end+1}           = p.tag;
            % NAME
            obj.parameterControl_name{end+1}          = p.tag;
            if isfield(p, 'name'),      obj.parameterControl_name{end}      = p.name;      end
            % TYPE
            obj.parameterControl_type{end+1}          = 'numeric';
            if isfield(p, 'type'),      obj.parameterControl_type{end}      = p.type;      end
            % DEFAULT
            obj.parameterControl_default(end+1)       = 0.5;
            if isfield(p, 'default'),   obj.parameterControl_default(end)   = p.default;   end
            % MIN
            obj.parameterControl_min(end+1)           = 0;
            if isfield(p, 'min'),       obj.parameterControl_min(end)       = p.min;       end
            % MAX
            obj.parameterControl_max(end+1)           = 1;
            if isfield(p, 'max'),       obj.parameterControl_max(end)       = p.max;       end
            % INCREMENT
            obj.parameterControl_increment(end+1)     = 0.05;
            if isfield(p, 'increment'), obj.parameterControl_increment(end) = p.increment; end
            % HasAUTO
            obj.parameterControl_hasAuto(end+1)       = false;
            if isfield(p, 'has_Auto'), obj.parameterControl_hasAuto(end)   = p.has_Auto;   end
            % PARMETER VALUE
            obj.ParameterValues(1).(p.tag) = obj.parameterControl_default(end);
        end
        
        function addDisplayControl(obj, varargin)
            % % %
            % 1) Check input
            input_is_key_value_pair = (((length(varargin)/2)==round(length(varargin)/2)) && ...                                     % number of input arguments is even
                                        (all(cellfun(@ischar, varargin(1:2:end))) && all(cellfun(@isnumeric, varargin(2:2:end))))); % we characters and numbers alterating
            % Support cell-array input / comma seperated input
            if ~input_is_key_value_pair
                fnames = properties(obj)';  % Get list of properties
                fnames = fnames(cellfun(@(x) ~isempty(strfind(x, 'displayControl_')), fnames));
                fnames = cellfun(@(x) x(length('displayControl_')+1:end), fnames, 'UniformOutput', 0);
                if iscell(varargin{1})
                    % Support Cell array
                    for i = 1 : size(varargin{1},1)
                        obj.addDisplayControl(varargin{1}{i,:});
                    end
                    return
                else
                    % Transform comma seperated input to 'key-value-pair'-input
                    newVarargin = [fnames(1:length(varargin)); varargin];
                    varargin = newVarargin(:)';
                end
            end
            % Process 'key-value-pair'-input
            required = {'tag'};
            p = parameterPanelClass.varargin2struct(varargin);
            if any(cellfun(@(tag) ~isfield(p, tag), required))
                error(['Required at least: ', parameterPanelClass.cellstr2list(required)])
            end
            
            % % %
            % 2) Ascribe input
            % TAG
            obj.displayControl_tag{end+1}               = p.tag;
            % NAME
            obj.displayControl_name{end+1}              = p.tag;
            if isfield(p, 'name'),              obj.displayControl_name{end}                = p.name;               end
            % ADD CONTROL DEFAULT
            obj.displayControl_default(end+1) = false;
            if isfield(p, 'default'),           obj.displayControl_default(end)             = p.default;            end
            % ADD OPACITY CONTROL
            obj.displayControl_addOpacityControl(end+1) = true;
            if isfield(p, 'addOpacityControl'), obj.displayControl_addOpacityControl(end)   = p.addOpacityControl;  end
            % OPACITY CONTROL DEFAULT
            obj.displayControl_opacityDefault(end+1)    = 0.5;
            if isfield(p, 'opacityDefault'),    obj.displayControl_opacityDefault(end)      = p.opacityDefault;     end
            % DISPLAY STATUS
            obj.DisplayStatus(1).(p.tag)       = obj.displayControl_default(end);
            if obj.displayControl_addOpacityControl(end)
                obj.DisplayStatus(1).([p.tag, '_opacity']) = obj.displayControl_opacityDefault(end);
            end
        end
        
        function addDebugControl(obj, varargin)
            % % %
            % 1) Check input
            input_is_key_value_pair = (((length(varargin)/2)==round(length(varargin)/2)) && ...                                      % number of input arguments is even
                                        (all(cellfun(@ischar, varargin(1:2:end))) && all(cellfun(@isnumeric, varargin(2:2:end)))));  % we characters and numbers alterating
            % Support cell-array input / comma seperated input
            if ~input_is_key_value_pair
                fnames = properties(obj)';      % Get list of properties
                fnames = fnames(cellfun(@(x) ~isempty(strfind(x, 'debugControl_')), fnames));
                fnames = cellfun(@(x) x(length('debugControl_')+1:end), fnames, 'UniformOutput', 0);
                if iscell(varargin{1})
                    % Support Cell array
                    for i = 1 : size(varargin{1},1)
                        obj.addDebugControl(varargin{1}{i,:});
                    end
                    return
                else
                    % Transform comma seperated input to 'key-value-pair'-input
                    newVarargin = [fnames(1:length(varargin)); varargin];
                    varargin = newVarargin(:)';
                end
            end
            % Process 'key-value-pair'-input
            required = {'tag'};
            p = parameterPanelClass.varargin2struct(varargin);
            if any(cellfun(@(tag) ~isfield(p, tag), required))
                error(['Required at least: ', parameterPanelClass.cellstr2list(required)])
            end
            
            % % %
            % 2) Ascribe input
            % TAG
            obj.debugControl_tag{end+1}               = p.tag;
            % NAME
            obj.debugControl_name{end+1}              = p.tag;
            if isfield(p, 'name'),              obj.debugControl_name{end}                = p.name;               end
            % DEBUG TAG
            obj.debugControl_debug_tag{end+1}         = p.tag;
            if isfield(p, 'name'),              obj.debugControl_debug_tag{end}           = p.name;               end
            
            % ADD OPACITY CONTROL
            obj.debugControl_addOpacityControl(end+1) = true;
            if isfield(p, 'addOpacityControl'), obj.debugControl_addOpacityControl(end)   = p.addOpacityControl;  end
            % OPACITY CONTROL DEFAULT
            obj.debugControl_opacityDefault(end+1)    = 0.5;
            if isfield(p, 'opacityDefault'),    obj.debugControl_opacityDefault(end)      = p.opacityDefault;     end
            % DEBUG STATUS
            obj.DebugStatus(1).(p.tag) = false;
            if obj.debugControl_addOpacityControl(end)
                obj.DebugStatus(1).([p.tag, '_opacity']) = false;
            end
        end
        
        
        function handles = makeFigure(obj, varargin)
           
            handles.figure1 = figure;
            hf = handles.figure1;
            set(hf, 'NumberTitle', 'off', 'Name', ['Edit ', regexprep(obj.title, 'Detection', '')], 'ToolBar', 'None', 'MenuBar', 'None', varargin{:});
            set(hf, 'CloseRequestFcn', @(varargin) execute_Cancle_function(obj, varargin{:}));
            %set(hf, 'Position', get(0, 'ScreenSize'))
            if isdeployed, set(hf, 'menubar', 'none', 'toolbar', 'none', 'WindowStyle', 'modal'); end
            hf.Position(4) = 2*hf.Position(4);
            % % % % % %
            %% Create/Layout User Interface
            % % % % % %
            main_offset_x = 10;
            main_offset_y = 10;
            
            offset_x = 10;
            offset_y = 10;
            
            control_height = 20;
            button_width  = 70;
            button_height =  30;
            
            % Dynamically adjust label width 
            testi = uicontrol(hf, 'Style', 'Text');
               
                parameter_labelWidth = 100;
                parameter_editWidth = 50;
                for i = 1 : length(obj.parameterControl_name)
                    set(testi, 'String', obj.parameterControl_name{i});
                    parameter_labelWidth = max([parameter_labelWidth, get(testi, 'Extent') .* [0,0,1,0]]);
                end
                
                display_labelWidth = 50;
                display_editWidth = 30;
                display_checkboxWidth = 80;
                teststr = [obj.displayControl_name, obj.debugControl_name];
                for i = 1 : length(teststr)
                    set(testi, 'String', teststr{i});
                    display_checkboxWidth = max([display_checkboxWidth, get(testi, 'Extent') .* [0,0,1,0]]);
                end
                display_checkboxWidth = display_checkboxWidth + 20;
                
            delete(testi)
                
            
            
            nop = length(obj.parameterControl_tag); % Number of parameters
            parameterPanelHeight = nop*0.3*offset_y + nop*control_height + 3*offset_y + (~obj.manualModeEnable*5);
            if isempty(obj.parameterControl_tag), parameterPanelHeight = 1; end
            parameterPanelWidth  = 7*offset_x+parameter_labelWidth+parameter_editWidth+2*control_height;
            
            nodi = length(obj.displayControl_tag);  % Number of displays
            node = length(obj.debugControl_tag);  % Number of debugs
            displayPanelHeight = 3*offset_y + (node+nodi)*(0.3*offset_y+control_height) + (sum([obj.displayControl_addOpacityControl, obj.debugControl_addOpacityControl]))*(0.2*offset_y+control_height) + (node>0)*(0.9*offset_y + 2);
            displayPanelWidth  = max([(node>0)*(5.5*offset_x+display_labelWidth+display_editWidth),...
                                               (4*offset_x+display_checkboxWidth)]);
            
            main_height   = 15 + max([parameterPanelHeight + (obj.manualModeEnable )*(2*control_height), displayPanelHeight])+1.5*offset_y;
            main_width    = parameterPanelWidth+displayPanelWidth+3.3*offset_x+6*obj.manualModeEnable;
            
            offset_y_parameterpanel = max([0, displayPanelHeight-parameterPanelHeight-obj.manualModeEnable*(2*control_height)]);
            offset_y_displaypanel   = max([0, parameterPanelHeight-displayPanelHeight]);
            
            % % % %
            % Main CotrolPanel
            if ~isempty(obj.externalAxes)                                                                  
                pos = get(hf, 'position');
                widthi  = 4*main_offset_x + main_width + button_width;
                heighti = 2*main_offset_y + main_height;
                set(hf, 'position', [pos(1:2), widthi, heighti]);
            end
            fheight = sum(get(hf, 'position').*[0,0,0,1]); % figure height
            fwidth  = sum(get(hf, 'position').*[0,0,1,0]); % figure width
            if obj.manualModeEnable
                handles.uipanelControlMain      = uibuttongroup(hf, 'Units',    'Pixels',...
                                                                    'Position', [main_offset_x, fheight-main_offset_y-main_height, main_width, main_height],...
                                                                    'FontWeight',  'bold',...
                                                                    'FontSize',  9,...    
                                                                    'Title',    obj.title);
                
                handles.radiobutton_manual      = uicontrol(handles.uipanelControlMain, 'Style',  'Radiobutton',...
                                                                                        'String', 'Manual Selection',...
                                                                                        'Units',    'Pixels',...
                                                                                        'Position', [offset_x, main_height-control_height-offset_y-15, 150, control_height]);
                if ~isempty(obj.UpdateCalculationFunction)
                    handles.radiobutton_automatic   = uicontrol(handles.uipanelControlMain, 'Style',  'Radiobutton',...
                                                                                            'String', 'Automatic detection',...
                                                                                            'Units',    'Pixels',...
                                                                                            'Position', [offset_x, main_height-2*control_height-1.5*offset_y-15, 150, control_height]);
                else
                    handles.radiobutton_automatic = [];
                end
            %    parameterPanelHeight = main_height - 2*control_height - 2*offset_y;
            else
                handles.uipanelControlMain      = uipanel(hf, 'Units',    'Pixels',...
                                                              'Position', [main_offset_x, fheight-main_offset_y-main_height, main_width, main_height],...
                                                              'FontWeight',  'bold',...
                                                              'FontSize',  9,...    
                                                              'Title',    obj.title);
            %    parameterPanelHeight = main_height - 2*offset_y;
            end
            
            % % % %
            % Parameter ControlPanel
            handles.uipanelParameterControl     = uipanel(handles.uipanelControlMain, 'Units',    'Pixels',...
                                                                                      'Position', [offset_x+6*obj.manualModeEnable, offset_y+offset_y_parameterpanel, parameterPanelWidth, parameterPanelHeight]);
            % Hide Parameter Control Panel if we have no parameter Controls
            if isempty(obj.parameterControl_tag)
                set(handles.uipanelParameterControl, 'visible', 'off');
            end
            if obj.manualModeEnable  && ~isempty(obj.UpdateCalculationFunction)
                uistack(handles.radiobutton_automatic, 'top');
                set(handles.radiobutton_automatic, 'Position', get(handles.radiobutton_automatic, 'Position').*[1,1,0,1]+get(handles.radiobutton_automatic, 'Extent').*[0,0,1,0]+control_height.*[0,0,1,0]);
            else
                set(handles.uipanelParameterControl, 'Title', 'Parameter', 'Position', get(handles.uipanelParameterControl, 'Position'));
            end
            for i = 1 : length(obj.parameterControl_tag)
                this_y = parameterPanelHeight-i*0.3*offset_y-1.5*offset_y-i*control_height-(~obj.manualModeEnable)*5;
                handles.(['label_',                obj.parameterControl_tag{i}]) = uicontrol(handles.uipanelParameterControl, 'Style',    'Text',...
                                                                                                                              'String',   obj.parameterControl_name{i},...
                                                                                                                              'HorizontalAlignment', 'left',...
                                                                                                                              'Units',    'Pixels',...
                                                                                                                              'Position', [2*offset_x, this_y-4.7, parameter_labelWidth, control_height]);
                handles.(['edit_',                 obj.parameterControl_tag{i}]) = uicontrol(handles.uipanelParameterControl, 'Style',    'Edit',...
                                                                                                                              'String',   obj.parameterControl_default(i),...
                                                                                                                              'Units',    'Pixels',...
                                                                                                                              'Position', [3*offset_x+parameter_labelWidth, this_y, parameter_editWidth, control_height]);
                handles.(['pushbutton_increase_',  obj.parameterControl_tag{i}]) = uicontrol(handles.uipanelParameterControl, 'Style', 'Pushbutton',...
                                                                                                                              'String', '+',...
                                                                                                                              'Units',    'Pixels',...
                                                                                                                              'Position', [4*offset_x+parameter_labelWidth+parameter_editWidth, this_y, control_height, control_height]);
                handles.(['pushbutton_decrease_',  obj.parameterControl_tag{i}]) = uicontrol(handles.uipanelParameterControl, 'Style', 'Pushbutton',...
                                                                                                                              'String', '-',...
                                                                                                                              'Units',    'Pixels',...
                                                                                                                              'Position', [4.5*offset_x+parameter_labelWidth+parameter_editWidth+control_height, this_y, control_height, control_height]);
            end

            % % % %
            % Display ControlPanel
            handles.uipanelDisplayControl       = uipanel(handles.uipanelControlMain, 'Units',    'Pixels',...
                                                                                      'Position', [2*offset_x+parameterPanelWidth+6*obj.manualModeEnable, offset_y+offset_y_displaypanel, displayPanelWidth, displayPanelHeight],...
                                                                                      'Title',    'Display');
            if isempty(obj.displayControl_tag), set(handles.uipanelDisplayControl, 'visible', 'off'); end
            irregular_offset = 0;
            this_y = displayPanelHeight;
            for i = 1 : length(obj.displayControl_tag)
                this_y = displayPanelHeight-i*0.3*offset_y-1.5*offset_y-i*control_height-irregular_offset;
                handles.(['checkbox_', obj.displayControl_tag{i}]) = uicontrol(handles.uipanelDisplayControl, 'Style', 'Checkbox',...
                                                                                                              'String', obj.displayControl_name{i},...
                                                                                                              'Units',    'Pixels',...
                                                                                                              'Value',  obj.displayControl_default(i),...
                                                                                                              'Position', [2*offset_x, this_y, display_checkboxWidth, control_height]);
                
                if obj.displayControl_addOpacityControl(i)
                    new_irregular_offset = 0.2*offset_y+control_height;
                    handles.(['labelOpacity_',       obj.displayControl_tag{i}]) = uicontrol(handles.uipanelDisplayControl,   'Style',    'Text',...
                                                                                                                              'String',   'Opacity',...
                                                                                                                              'Units',    'Pixels',...
                                                                                                                              'Position', [3.5*offset_x, this_y-new_irregular_offset-4.2, display_labelWidth, control_height]);    
                    handles.(['editDisplayOpacity_', obj.displayControl_tag{i}]) = uicontrol(handles.uipanelDisplayControl,   'Style',    'Edit',...
                                                                                                                              'String', obj.displayControl_opacityDefault(i),...
                                                                                                                              'Units',    'Pixels',...
                                                                                                                              'Position', [3.5*offset_x+display_labelWidth, this_y-new_irregular_offset, display_editWidth, control_height]);
                    irregular_offset = irregular_offset + new_irregular_offset + 0.3*offset_y;
                end
            end
            
            
            % % % %
            % DebugControl
            if ~isempty(obj.debugControl_tag)
                this_y = this_y - 1.3*offset_y - control_height*obj.displayControl_addOpacityControl(end);
                handles.divider = uipanel(handles.uipanelDisplayControl,    'Units',    'Pixels',...
                                                                            'Position', [offset_x, this_y, displayPanelWidth-2*offset_x, 2]);
                this_y = this_y - 0.3*offset_y;
                for i = 1 : length(obj.debugControl_tag)
                    this_y = this_y - 0.3*offset_y - control_height;
                    handles.(['checkbox_', obj.debugControl_tag{i}]) = uicontrol(handles.uipanelDisplayControl, 'Style', 'Checkbox',...
                                                                                                                'String', obj.debugControl_name{i},...
                                                                                                                'Units',    'Pixels',...
                                                                                                                'Position', [2*offset_x, this_y, display_checkboxWidth, control_height]);
                    if obj.debugControl_addOpacityControl(i)
                        this_y = this_y - 0.2*offset_y - control_height;
                        handles.(['labelOpacity_',     obj.debugControl_tag{i}]) = uicontrol(handles.uipanelDisplayControl, 'Style',    'Text',...
                                                                                                                            'String',   'Opacity',...
                                                                                                                            'Units',    'Pixels',...
                                                                                                                            'Position', [3.5*offset_x, this_y-4.2, display_labelWidth, control_height]); 
                        handles.(['editDebugOpacity_', obj.debugControl_tag{i}]) = uicontrol(handles.uipanelDisplayControl, 'Style',    'Edit',...
                                                                                                                            'String',   obj.debugControl_opacityDefault(i),...
                                                                                                                            'Units',    'Pixels',...
                                                                                                                            'Position', [3.5*offset_x+display_labelWidth, this_y, display_editWidth, control_height]);
                    end
                end
            end


            % % % %
            % Buttons
            mainPanelPos = get(handles.uipanelControlMain, 'Position');
            handles.pushbutton_OK     = uicontrol(hf, 'Style',    'Pushbutton',...
                                                      'String',   '<html><center>Save to<br>SHAPE.json',...
                                                      'Units',    'Pixels',...
                                                      'Position', [sum(mainPanelPos([1,3]))+offset_x, sum(mainPanelPos([2,4]))-1.25*button_height-6, button_width, 1.25*button_height]);
            handles.pushbutton_Cancel = uicontrol(hf, 'Style', 'Pushbutton',...
                                                      'String', 'Cancel',...
                                                      'Units',    'Pixels',...
                                                      'Position', [sum(mainPanelPos([1,3]))+offset_x, sum(mainPanelPos([2,4]))-2.25*button_height-6-offset_y, button_width, button_height]);
            
            handles.pushbutton_Help   = uicontrol(hf, 'Style', 'Pushbutton',...
                                                      'String', 'Help',...
                                                      'Units',    'Pixels',...
                                                      'Position', [sum(mainPanelPos([1,3]))+offset_x, mainPanelPos(2), button_width, button_height]);
            if isempty(obj.helpURL)
                set(handles.pushbutton_Help, 'Visible', 'off');
            end
            
            % % % %
            % Axes
            if isempty(obj.externalAxes)
                handles.axes1 = axes('Parent',   hf,...
                                     'Units',    'Pixels',...
                                     'Position', [main_offset_x, main_offset_y, fwidth-2*main_offset_x, fheight-3*main_offset_y-mainPanelPos(4)]);
            else
                handles.axes1 = obj.externalAxes(1);
            end
            if obj.axes_generateOverlay
                if isempty(obj.externalAxes)
                    handles.axes_overlay = axes('Parent',   get(handles.axes1, 'Parent'),...
                                                'units',    get(handles.axes1, 'units'),...
                                                'position', get(handles.axes1, 'position'));
                    axis(handles.axes_overlay,  'off');
                    setappdata(handles.axes1, 'axes_overlay', handles.axes_overlay);
                    linkprop([handles.axes1, handles.axes_overlay], {'XLim', 'YLim', 'XDir', 'YDir', 'DataAspectRatio'});
                else
                    handles.axes_overlay = obj.externalAxes(2);
                end
            end
          
            % % % % %
            % Setup Figure ResizeFcn  
            resizeArg.figure1 = handles.figure1;
            resizeArg.to_resize = [ handles.uipanelControlMain,...
                                    handles.pushbutton_OK,...
                                    handles.pushbutton_Cancel,...
                                    handles.pushbutton_Help ];%,...
            if isempty(obj.externalAxes)
                resizeArg.to_resize(end+1) = handles.axes1;
                if obj.axes_generateOverlay, resizeArg.to_resize(end+1) = handles.axes_overlay; end
            end
            set([resizeArg.figure1, resizeArg.to_resize], 'units', 'pixel');
            resizeArg.start_fig_pos = get(resizeArg.figure1,   'position');
            resizeArg.start_pos     = get(resizeArg.to_resize, 'position');
            resizeArg.dock_top    = [1, 1, 1, 1];
            resizeArg.dock_bottom = [0, 0, 0, 0];
            resizeArg.dock_left   = [1, 1, 1, 1];
            resizeArg.dock_right  = [0, 0, 0, 0];                
            if isempty(obj.externalAxes)
                resizeArg.dock_top(end+1)    = 1;
                resizeArg.dock_bottom(end+1) = 1;
                resizeArg.dock_left(end+1)   = 1;
                resizeArg.dock_right(end+1)  = 1;
                if obj.axes_generateOverlay, 
                    resizeArg.dock_top(end+1)    = 1;
                    resizeArg.dock_bottom(end+1) = 1;
                    resizeArg.dock_left(end+1)   = 1;
                    resizeArg.dock_right(end+1)  = 1;
                end
            end
            if isempty(obj.externalAxes)
                set(resizeArg.figure1, 'ResizeFcn',  @(varargin) guitools.resize_function(resizeArg));
            else
                set(resizeArg.figure1, 'Resize', 'off');
            end
            %% Ascribe Callbacks
            % % % % % % % %
            
            % % % %
            % Callbacks for +/- buttons
            fns = fieldnames(handles);
            is_increaseDecrease_pushbutton = cellfun(@(x) ~isempty(strfind(x, '_increase_')) ||...
                                                          ~isempty(strfind(x, '_decrease_')), fns);
            arrayfun(@(x)...
                     set(handles.(fns{x}), 'Callback', @increase_decrease_callback),...
                     find(is_increaseDecrease_pushbutton));
            
            % Callbacks for edit boxes
            is_editbox = cellfun(@(x) ~isempty(strfind(x, 'edit_')) ||...
                                      ~isempty(strfind(x, 'editDisplayOpacity_')) ||...
                                      ~isempty(strfind(x, 'editDebugOpacity_')), fns);
            arrayfun(@(x)...
                     set(handles.(fns{x}), 'Callback', @edit_callback),...
                     find(is_editbox));                 
         
            % Callback for 'Display View'-checkboxes
            arrayfun(@(x)...
                     set(handles.(['checkbox_', obj.displayControl_tag{x}]), 'Callback', @display_checkbox_callback),...
                     1:length(obj.displayControl_tag));
                 
            % Callback for 'Debug View'-checkboxes
            arrayfun(@(x)...
                     set(handles.(['checkbox_', obj.debugControl_tag{x}]), 'Callback', @debug_checkbox_callback),...
                     1:length(obj.debugControl_tag));  

            % Callback for 'OK/Cancel/Help'-buttons
            set(handles.pushbutton_OK, 'Callback', @(varargin) execute_OK_function(obj, varargin{:}))
            set(handles.pushbutton_Cancel, 'Callback', @(varargin) execute_Cancle_function(obj, varargin{:}))
            set(handles.pushbutton_Help, 'Callback', @(varargin) execute_Help_function(obj, varargin{:}))
            if isempty(obj.helpURL), set(handles.pushbutton_Help, 'visible', 'off'); end
                
            if obj.manualModeEnable
                % Callback for detection method radiobuttons ('manual'/'auto')
                set(handles.uipanelControlMain, 'SelectionChangedFcn', @MethodChanged_callback);
                % Select radiobutton according to object state
                if isempty(obj.UpdateCalculationFunction) 
                    obj.currentMode = 'manual'; %  only manual is available
                else
                    sel_radiobutton = handles.radiobutton_automatic;          %  'auto' is default
                end
                if strcmpi('manual', obj.currentMode)                     %   = = " = =
                    sel_radiobutton = handles.radiobutton_manual;         %   = = " = =
                end                                                       %   = = " = =
                set(handles.uipanelControlMain, 'SelectedObject', sel_radiobutton);
                %MethodChanged_callback(handles.uipanelControlMain);                           % Run callback to update view
            end
            
            %% Callbacks
            % % % % % % % %
            function increase_decrease_callback(btn_handle, event)
                % Called when any of the +/- buttons is pressed
                
                % Get caller-string
                btn_tag = fns{cellfun(@(x) x==btn_handle, struct2cell(handles))};
                loc = strfind(btn_tag, '_');
                caller_tag = btn_tag((loc(2)+1):end);    
                currentVal = str2double(get(handles.(['edit_', caller_tag]), 'String'));    % Get value from corresponding edit-box
                objIDX = strcmp(obj.parameterControl_tag, caller_tag);
                
                % Define operation_sign (+/- 1) & do incrementing
                operation_sign = -1 + 2*strcmp(btn_tag(loc(1)+1:loc(2)-1), 'increase');
                newVal = currentVal+operation_sign*obj.parameterControl_increment(objIDX);
                
                % Check Min & Max
                if newVal < obj.parameterControl_min(objIDX); 
                    newVal = obj.parameterControl_min(objIDX);
                elseif newVal > obj.parameterControl_max(objIDX); 
                    newVal = obj.parameterControl_max(objIDX);
                end

                % Set New Value
                obj.ParameterValues.(caller_tag) = newVal;                  % Set corresponding global variable  
                set(handles.(['edit_', caller_tag]), 'String', newVal);     % Set corresponding editbox
                
                % % % %
                % Update Calculation and Plot
                % Low-Level Callback
                execute_LowLevelCallback(obj, obj.parameterControlChangedCallback, obj.ParameterValues)
                
                % High-Level Update function (e.g. update_centralDarkLine)
                execute_UpdateCalculationFunction(obj)
                
                % High-Level Draw function (e.g. draw_preview)
                execute_DrawingFunction(obj)
     
            end
           
            function edit_callback(edit_handle, event)
                % Called when user has entered a new number in editbox
                
                % Get caller-string
                edit_tag = fns{cellfun(@(x) x==edit_handle, struct2cell(handles))};
                loc = strfind(edit_tag, '_');
                isDisplayEdit = strcmp('editDisplayOpacity_', edit_tag(1:loc(1)));
                isDebugEdit   = strcmp('editDebugOpacity_',   edit_tag(1:loc(1)));
                caller_tag  = edit_tag((loc(1)+1):end);    
                newVal      = str2double(get(edit_handle, 'String'));

                % Get valid min and max values for this edit
                if isDisplayEdit || isDebugEdit
                    mini = 0;
                    maxi = 1;
                else
                    objIDX = strcmp(obj.parameterControl_tag, caller_tag);
                    mini = obj.parameterControl_min(objIDX);
                    maxi = obj.parameterControl_max(objIDX);
                end
                
                % Check new input
                if isnan(newVal) || newVal<mini || newVal>maxi
                    % A non-numeric value has been entered
                    hmsg = msgbox(['Value must be numeric, and between ', num2str(mini), ' and ', num2str(maxi), '!'], 'Error');
                    set(hmsg, 'WindowStyle', 'modal');
                    WinOnTop(hmsg); 
                    waitfor(hmsg);
                    % Get previous valid value 
                    if isDisplayEdit
                        newVal = obj.DisplayStatus.([caller_tag,'_opacity']);                  
                    elseif isDebugEdit
                        newVal = obj.DebugStatus.([caller_tag,'_opacity']);
                    else  % Normal Parameter Edit
                        newVal = obj.ParameterValues.(caller_tag);                  
                    end
                    % Restore precious value
                    set(edit_handle, 'String', newVal);
                    return
                end
                
                
                % Set corresponding global variable and execute callbacks
                if isDisplayEdit
                    % Update Display Status
                    obj.DisplayStatus.([caller_tag,'_opacity']) = newVal;                  
                    
                    % Callbacks
                    execute_LowLevelCallback(obj, obj.displayControlChangedCallback, obj.DisplayStatus)
                    execute_DrawingFunction(obj)
                    
                elseif isDebugEdit
                    % Update Debug Status
                    obj.DebugStatus.([caller_tag,'_opacity']) = newVal;
                    
                    % Callbacks
                    execute_LowLevelCallback(obj, obj.debugControlChangedCallback, obj.DebugStatus)
                    execute_UpdateCalculationFunction(obj)
                    
                else  % Normal Parameter Edit
                    % Update Parameter Status
                    obj.ParameterValues.(caller_tag) = newVal;
                    
                    % Callbacks
                    execute_LowLevelCallback(obj, obj.parameterControlChangedCallback, obj.ParameterValues)
                    execute_UpdateCalculationFunction(obj)
                    execute_DrawingFunction(obj);
                    
                end
                
            end
        
            function debug_checkbox_callback(chkbox_handle, event)
            
                % Set debug-tag and function handle
                chkbox_tag = fns{cellfun(@(x) x==chkbox_handle, struct2cell(handles))};
                loc = strfind(chkbox_tag, '_');
                caller_tag  = chkbox_tag((loc(1)+1):end);    
                        
                objIDX = strcmp(obj.debugControl_tag, caller_tag);
                debug_tag = obj.debugControl_debug_tag{objIDX};
            
                % Update DEBUG STATUS
                obj.DebugStatus.(caller_tag) = chkbox_handle.Value;  
                
                switch chkbox_handle.Value;
                    
                    case true
                        % Checkbox was enabled => re-run processing with "debug == true" to generate the extra window ...
                        % Callbacks
                        execute_LowLevelCallback(obj, obj.debugControlChangedCallback, obj.DebugStatus)
                        execute_UpdateCalculationFunction(obj)
                        
                        % ... and ascribe the extra window's deletefcn to uncheck the checkbox if the window is closed
                        set(findall(0, 'parent', 0, 'tag', debug_tag), 'DeleteFcn', @(varargin) set(chkbox_handle, 'Value', 0));
                        
                    case false
                        % Checkbox was disabled => close extra window that visualized the single steps
                        delete(findall(0, 'parent', 0, 'tag', debug_tag));
                        
                end
                
            end
               
            function display_checkbox_callback(chkbox_handle, event, Redraw)
                if ~exist('Redraw', 'var'), Redraw=true; end
                
                % Set debug-tag and function handle
                chkbox_tag = fns{cellfun(@(x) x==chkbox_handle, struct2cell(handles))};
                loc = strfind(chkbox_tag, '_');
                caller_tag  = chkbox_tag((loc(1)+1):end);    
                objIDX = strcmp(obj.displayControl_tag, caller_tag);
                
                % Update DisplayStatus
                obj.DisplayStatus.(caller_tag) = chkbox_handle.Value;
                    
                % Callbacks
                if Redraw
                    execute_LowLevelCallback(obj, obj.displayControlChangedCallback, obj.DisplayStatus)
                    execute_DrawingFunction(obj)
                end
                
            end
                           
            function MethodChanged_callback(panel_handle, event)
                
                debugcheckboxes = [ arrayfun(@(x) handles.(['checkbox_', obj.debugControl_tag{x}]),     1:length(obj.debugControl_tag), 'Uniform', 0),...
                                    arrayfun(@(x) handles.(['labelOpacity_', obj.debugControl_tag{x}]), find(obj.debugControl_addOpacityControl), 'Uniform', 0),...
                                    arrayfun(@(x) handles.(['editOpacity_', obj.debugControl_tag{x}]),  find(obj.debugControl_addOpacityControl), 'Uniform', 0) ];
                debugcheckboxes = [debugcheckboxes{:}]';
                
                % Update GUI according to selection
                switch panel_handle.SelectedObject
                    
                    case handles.radiobutton_automatic
                        obj.currentMode = 'auto';
                        % We switched to automatic detection => ENABLE Parameter interface
                        set([findall(handles.uipanelParameterControl, '-property', 'enable');...
                                     debugcheckboxes], 'Enable', 'on');
                        % Low Level Callback
                        execute_LowLevelCallback(obj, obj.manualModeChangedCallback, 'auto')
                
                        % Disable ButtonDownFcn to overlay axes
                        execute_ManualSelectionFcn(obj, 'on')
                        execute_UpdateCalculationFunction(obj)
                        execute_DrawingFunction(obj)
                        
                    case handles.radiobutton_manual
                        obj.currentMode = 'manual';
                        % We switched to manual detection    => DISABLE Parameter interface
                        set([findall(handles.uipanelParameterControl, '-property', 'enable');...
                                     debugcheckboxes],  'Enable', 'off');
                        % Low Level Callback
                        execute_LowLevelCallback(obj, obj.manualModeChangedCallback, obj.DisplayStatus)

                        % Enable ButtonDownFcn to overlay axes
                        execute_ManualSelectionFcn(obj, 'off')
                        execute_DrawingFunction(obj)
                        
                end
                
            end
            
            %% Finish
            % % % % %
            obj.handles = handles;
            if strcmp(obj.currentMode, 'auto')
                execute_UpdateCalculationFunction(obj);
            else
                %execute_ManualSelectionFcn(obj, 'manual');
                MethodChanged_callback(handles.uipanelControlMain);                           % Run callback to update view
            end
            execute_DrawingFunction(obj);
            
            % Scale figure to have best view
            if isempty(obj.externalAxes)
                imi = findobj(handles.axes1, 'type', 'image');
                if ~isempty(imi)
                    imi = imi(1);
                    screendim = get(0, 'ScreenSize');
                    fpos = get(handles.figure1, 'position');
                    hpos = get(handles.axes1, 'position');
                    imdim = size(get(imi, 'CData'));

                    new_width = max(1151, min(hpos(4)/imdim(1)*imdim(2),...
                                              0.8.*screendim(3)));
                    new_height = max(210, 210 + min(imdim(1)/imdim(2)*new_width,...
                                                0.8.*screendim(4)));
                    set(handles.figure1, 'position', [0.1*screendim(3), fpos(2)-new_height+fpos(4), new_width, new_height]);
                    feval(get(handles.figure1, 'ResizeFcn'));
                end
            end
        end
        
        function defaults = setcontrols(obj, settings)
            defaults = 1;
            if ~exist('settings', var)
                disp('hallo');
                
            end
        end
        
        function execute_LowLevelCallback(obj, cb, varargin)
            % Low-Level Callback
            % e.g.  parameterControlChangedCallback
            %       displayControlChangedCallback
            %       debugControlChangedCallback
            %       
            if ~isempty(cb)
                feval(cb, obj, varargin{:});
            end
        end
        
        function execute_UpdateCalculationFunction(obj)
            % Execute High-Level Callback
            % e.g.  update_centralDarkLine
            if ~isempty(obj.UpdateCalculationFunction)
                obj.calculationResults = feval(obj.UpdateCalculationFunction, obj.ParameterValues, obj.DebugStatus, obj.DisplayStatus);
            end
        end
        
        function execute_ManualSelectionFcn(obj, onORoff)
            % Execute High-Level Callback
            % e.g.  manual_selection_mode(onORoff)
            if ~isempty(obj.ManualSelectionFcn)
                ha = struct('axes1', obj.handles.axes1);
                if obj.axes_generateOverlay
                    ha.axes_overlay = obj.handles.axes_overlay;
                end
                feval(obj.ManualSelectionFcn, ha, onORoff, obj.calculationResults, obj.ParameterValues, obj.DebugStatus, @ManualSelectionUpdateFCN);
            end
            
            % If we switched to manual mode then activate external axis (if we have one)
            if ~isempty(obj.externalAxes)
                if strcmpi(onORoff, 'OFF')
                    figure(ancestor(obj.externalAxes(1), 'figure'));
                end
            end
            
            function ManualSelectionUpdateFCN(newCalculationResults, noRedraw)
                if ~exist('noRedraw', 'var'), noRedraw = false; end
                obj.calculationResults = newCalculationResults;
                if ~noRedraw
                    execute_DrawingFunction(obj);
                end
            end
        end
        
        function execute_DrawingFunction(obj)
            % Execute High-Level Callback
            % e.g.  draw_preview
            if ~isempty(obj.DrawingFunction)
                ha = struct('axes1', obj.handles.axes1);
                if obj.axes_generateOverlay
                    ha.axes_overlay = obj.handles.axes_overlay;
                end
                feval(obj.DrawingFunction, ha, obj.calculationResults, obj.ParameterValues, obj.DisplayStatus);
                if obj.axes_generateOverlay
                    set(ha.axes_overlay, 'HitTest', 'off');
                end
            end
            
        end
        
        function execute_OK_function(obj, varargin)
            if ~isempty(obj.OK_callback)
                ha = struct('axes1', obj.handles.axes1);
                if obj.axes_generateOverlay
                    ha.axes_overlay = obj.handles.axes_overlay;
                end
                feval(obj.OK_callback, obj.calculationResults, obj.ParameterValues, obj.DisplayStatus, obj.handles);
            end
        end
        
        function execute_Cancle_function(obj, varargin)
            if ~isempty(obj.Cancle_callback)
                ha = struct('axes1', obj.handles.axes1);
                if obj.axes_generateOverlay
                    ha.axes_overlay = obj.handles.axes_overlay;
                end
                feval(obj.Cancle_callback, obj.calculationResults, obj.ParameterValues, obj.DisplayStatus, obj.handles);
            end
            delete(obj.handles.figure1)
        end
        
        function execute_Help_function(obj, varargin)

            % Add absolute path if necessary
            pfadi = obj.helpURL;
            if exist(fullfile(guitools.getCurrentDir, pfadi), 'file')==2
                pfadi = fullfile(guitools.getCurrentDir, pfadi);
            end
            % Open help file
            web(pfadi, '-browser')

        end
        
    end
    
    methods(Static)
        
        function output = cellstr2list(input)
            if ~iscell(input)
                error('input was expected to be a cellarray of strings');
            end
            l = length(input);
            list = [repmat({''''}, 1, l);...
                    input;...
                    repmat({''''}, 1, l);...
                   [repmat({', '}, 1, l-1), {''}]];
            output = [list{:}];
        end
        
        function opt = varargin2struct(varargin)
        % VARARGIN2STRUCT Convert a series of input parameters into a structure
        % Usage:
        %   opt=varargin2struct('param1',value1,'param2',value2,...)
        %   opt=varargin2struct(...,optstruct,...)
        %
            % Support cell input
            if length(varargin)==1 && iscell(varargin{1})
                varargin = varargin{1};
            end
            
            % Extract parameter value pairs
            len=length(varargin);
            opt=struct;
            if(len==0), return; end
            i=1;
            while(i<=len)
                if(isstruct(varargin{i}))
                    opt=mergestruct(opt,varargin{i});
                elseif(ischar(varargin{i}) && i<len)
                    opt.(varargin{i}) = varargin{i+1};
                    i=i+1;
                else
                    error('Expected input in the form of ...,''name'',value,... pairs or structs');
                end
                i=i+1;
            end
 
        end
    end
    
end

