function varargout = FishInspector2(varargin)
    % FISHINSPECTOR2 MATLAB code for FishInspector2.fig
    %      FISHINSPECTOR2, by itself, creates a new FISHINSPECTOR2 or raises the existing
    %      singleton*.
    %
    %      H = FISHINSPECTOR2 returns the handle to a new FISHINSPECTOR2 or the handle to
    %      the existing singleton*.
    %
    %      FISHINSPECTOR2('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in FISHINSPECTOR2.M with the given input arguments.
    %
    %      FISHINSPECTOR2('Property','Value',...) creates a new FISHINSPECTOR2 or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before FishInspector2_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to FishInspector2_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % Tobias Kießling 05-08/2016
    % TobiasKiessling@tks3.de
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help FishInspector2

    % Last Modified by GUIDE v2.5 01-Dec-2017 12:32:03
    try
        % Begin initialization code - DO NOT EDIT
        gui_Singleton = 1;
        gui_State = struct('gui_Name',       mfilename, ...
                           'gui_Singleton',  gui_Singleton, ...
                           'gui_OpeningFcn', @FishInspector2_OpeningFcn, ...
                           'gui_OutputFcn',  @FishInspector2_OutputFcn, ...
                           'gui_LayoutFcn',  [] , ...
                           'gui_Callback',   []);
        warning('off', 'MATLAB:str2func:invalidFunctionName');
        if nargin && ischar(varargin{1})
            gui_State.gui_Callback = str2func(varargin{1});
        end

        if nargout
            [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
        else
            gui_mainfcn(gui_State, varargin{:});
        end
        % End initialization code - DO NOT EDIT
    catch ME
            % Close any open waitbars
            close(findall(0, 'tag', 'TMWWaitbar'))
        
            disp(ME.getReport);
            origin = length(ME.stack);
            if origin > 3 && strcmpi(ME.stack(origin-1).name, 'gui_mainfcn')
                origin = origin - 2;
            end
            
            % Make error-msgbox
            message = strsplit(ME.message, '\\n')';
            FishInspectorVersion = 0.99;

            err_msg = cat(1, {},...
                        ['FishInspector ', num2str(FishInspectorVersion), ' Error.'],...
                        {''},...
                        'Please email support@tks3.de if this continues to happen.',...
                        {''},...
                        'Error details:',...
                        ' ',...
                        strrep(ME.identifier,'MATLAB:',''),...
                        message{:},...
                        get_stack_info(ME,1),...
                        get_stack_info(ME,origin)...
                      );
            err_msg(6:end) = cellfun(@(x) ['    ', x], err_msg(6:end), 'UniformOutput', 0);
            waitfor(msgbox(err_msg, 'FishInspector Error', 'error', 'modal'));
            handles = varargin{find(cellfun(@isstruct, varargin), 1, 'first')};
            GUI_active(handles)
    end


function id = setSelectedFile(handles, filename)
    id = find(strcmpi(handles.fullfiles, filename), 1, 'first');
    
    setappdata(handles.figure1, 'isAdjusting', true);
        handles.jCBList.setSelectedIndex(id-1);
        drawnow
    setappdata(handles.figure1, 'isAdjusting', false);
    listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));
    

    
    
% --- Executes just before FishInspector2 is made visible.
function FishInspector2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FishInspector2 (see VARARGIN)

handles.setSelectedFile = @(filename) setSelectedFile(guidata(handles.figure1), filename);


handles.version = '1.03';
% Additional Folders
if ~isdeployed
    addpath(genpath('external'))
    addpath('tks3_tools');
    addpath('myImscrollpanel');
    addpath('fish_plugins');
    set(handles.menu_export_to_workspace, 'visible', 'on');
end

% Process Input
handles.batch = false;
if any(ismember({'-process', '-open'}, varargin))
    handles.batch = true;
    if ismember('-open', varargin)
        handles.batchOpen = true;
        idx = ismember(varargin, '-open');
    else
        handles.batchOpen = false;
        idx = ismember(varargin, '-process');
    end
    if idx+1>length(varargin)
        disp('At least one input argument is expected when starting with "-process" option');
        delete(handles.figure1);
        return
    end
    handles.batchInput = varargin(idx+1:end);
end

% Choose default command line output for FishInspector2
handles.output = hObject;
set(handles.figure1, 'NumberTitle', 'off', 'Name', 'FishInspector', 'ToolBar', 'none');

%%
% Generate Tab for Folders/FileList    
set([handles.uipanel_directory, handles.listbox_files, handles.axes_im1], 'Units', 'pixel');

% Adjust position of Filter label/editbox to look nice on different Windows display menu_settings
border = (handles.axes_im1.Position(1)-sum(handles.listbox_files.Position([1,3])));
handles.uipanel_directory.Position(2) = handles.figure1.Position(4)-handles.uipanel_directory.Position(4)-border;

% Make Tabs
handles.uitabgroup = uitabgroup('parent', handles.figure1,...
                                'Units',    handles.uipanel_directory.Units,...
                                'Position', handles.uipanel_directory.Position);
handles.Tab1 = uitab(handles.uitabgroup, 'title', 'Scan folder for images');
    hc1 = copyobj(handles.uipanel_directory.Children, handles.Tab1, 'legacy');
    for i = 1 : length(hc1)
        handles.(hc1(i).Tag) = hc1(i);
        set(handles.(hc1(i).Tag), 'Units', 'Pixel');
    end
    
    % Adjust position of Filter label/editbox to look nice on different Windows display menu_settings
    handles.text5.Position(1) = sum(handles.edit_ImDir.Position([1,3]));
    handles.text5.Position(3) = handles.text5.Extent(3);
    handles.edit_Filter.Position(1) = sum(handles.text5.Position([1,3]));
    handles.edit_Filter.Position(3) = handles.uitabgroup.Position(3)-handles.edit_Filter.Position(1)-border;
    uistack(handles.edit_ImDir, 'top');
    
handles.Tab2 = uitab(handles.uitabgroup, 'title', 'Read image list from file');
    hc2 = copyobj(handles.uipanel_directory.Children, handles.Tab2);
    handles.pushbutton_FilePath = hc2(strcmp({hc2.Tag}, 'pushbutton_ImDir')); 
        set(handles.pushbutton_FilePath, 'Tag', 'pushbutton_FilePath',...
                                         'Callback', @(varargin) pushubutton_FilePath_Callback(handles.pushbutton_FilePath, [], guidata(handles.figure1)),...
                                         'String', '');
    handles.edit_FilePath = hc2(strcmp({hc2.Tag}, 'edit_ImDir'));             
        set(handles.edit_FilePath, 'Tag', 'edit_FilePath',...
                                   'Callback', @(varargin) edit_FilePath_Callback(handles.edit_FilePath, [], guidata(handles.figure1)),...
                                   'Position', handles.edit_FilePath.Position.*[1,1,0,1]+ [0,0,1,0].*(sum(hc2(strcmp({hc2.Tag}, 'edit_Filter')).Position([1,3]))-handles.edit_FilePath.Position(1)));
    delete(hc2(ismember({hc2.Tag}, {'edit_Filter', 'text5'})));
    
% Set up resize FCN for TABS
h.to_resize = [handles.edit_ImDir, handles.text5, handles.edit_Filter,...
              handles.edit_FilePath];
h.figure1 = handles.figure1;
set([h.figure1, h.to_resize], 'units', 'pixel');
h.start_fig_pos = get(h.figure1,   'position');
h.start_pos     = get(h.to_resize, 'position');
h.dock_top    = [0, 0, 0, 0];
h.dock_bottom = [0, 0, 0, 0];
h.dock_left   = [1, 0, 0, 1];
h.dock_right  = [1, 1, 1, 1];            
set(handles.uitabgroup, 'SizeChangedFcn',  @(varargin) guitools.resize_function(h, varargin{:}));    
handles.uipanel_directory.Visible = 'off';
%%
% Adjust position of Filter label/editbox to look nice on different Windows display menu_settings

% Arrange Listbox and ParameterPanel
handles.listbox_files.Position(4) = handles.uitabgroup.Position(2) - handles.listbox_files.Position(2) + 2;
handles.listbox_files.Position(1) = handles.uitabgroup.Position(1);
uistack(handles.listbox_files, 'top')
handles.uipanel5.Position(1) = handles.uitabgroup.Position(1);
handles.uipanel5.Position(4) = handles.uipanel5.Position(4) + 5;
handles.uipanel5.Position(2) = handles.listbox_files.Position(2)-handles.uipanel5.Position(4)+1;
handles.uipanel5.Position(3) = handles.listbox_files.Position(3)+1;

% Arrange axis position
handles.axes_im1.Units = 'Pixel';
handles.axes_im1.Position(4) = handles.uitabgroup.Position(2)-handles.axes_im1.Position(2)-border;
handles.axes_im1.Position(3) = handles.figure1.Position(3)-handles.axes_im1.Position(1)-border;

% Arrange Feature Panel position
set(handles.uipanel_edits, 'Units', 'Pixel');
pos = get(handles.uipanel_edits, 'Position');
pos(1) = handles.axes_im1.Position(1);
pos(3) = handles.figure1.Position(3)-pos(1)-border;
pos(4) = handles.axes_im1.Position(2)-pos(2)-border;
set(handles.uipanel_edits, 'Position', pos);
%%

% Remember previouly selected Image Directory
diri = getImDir();
setImDir(diri, handles);

% Remember previously entered Filter setting
filti = getFilter();
setFilter(filti, handles);

% Remember previously entered FilePath
fily = getFilePath();
setFilePath(fily, handles);

% % % % %
% Setup Figure ResizeFcn    
handles.to_resize = [ handles.uitabgroup,...
                      handles.uipanel5,...
                      handles.listbox_files,...
                      handles.axes_im1,...
                      handles.uipanel_edits];
set([handles.figure1, handles.to_resize], 'units', 'pixel');
handles.start_fig_pos = get(handles.figure1,   'position');
handles.start_pos     = get(handles.to_resize, 'position');
handles.dock_top    = [1, 0, 1, 1, 0];
handles.dock_bottom = [0, 0, 1, 1, 1];
handles.dock_left   = [1, 1, 1, 1, 1];
handles.dock_right  = [1, 0, 0, 1, 1];                
set(handles.figure1, 'ResizeFcn',  @(varargin) figure1_SizeChangedFcn([],varargin,guidata(handles.figure1)));

%% Hook up to a fishobject
handles.fishobj = fishobj2;

% Create Menu for different feature groups if necessary
if length(handles.fishobj.pluginGroups)>1
	item0 = uimenu('Label', 'Feature Sets');
    for i = 1:length(handles.fishobj.pluginGroups) 
        thisName = handles.fishobj.pluginGroups{i};
        thisNameDisplay = thisName;
        if isempty(thisNameDisplay), thisNameDisplay = '<base>'; end
        onOff = {'on', 'off'}; onOff = onOff{~strcmp(handles.fishobj.pluginCurrentGroup, thisName)+1};
        uimenu(item0, 'Label', thisNameDisplay, 'Callback', @(varargin) menu_featureSets(guidata(handles.figure1), thisName, varargin{:}), 'Checked', onOff);
    end
end

% Make Feature Panel
delete(findall(handles.uipanel_edits, 'parent', handles.uipanel_edits));
handles.fishobj.makeFeaturePanel(handles.uipanel_edits, @(varargin) interfaceStartFCN(guidata(handles.figure1), varargin{:}), @(varargin) interfaceReadyFCN(guidata(handles.figure1), varargin{:}) ,@(varargin) updateDisplay(guidata(handles.figure1)), handles.axes_im1, 'visible', 'off');
handles.popupmenu_ParameterFile = handles.fishobj.makeParameterFilePanel(handles.uipanel_parameterFile, @(varargin) listbox_files_Callback([], [], guidata(handles.figure1)));

% Read Directory
getImagesFromDir(handles, diri);
handles = guidata(handles.figure1);
set(handles.axes_im1, 'Color', [0.5,0.5,0.5]);


% Create Statusbar
handles.statusbar = tks3_guitools.statusbar(handles.figure1, 2, [0, 0.8875]);
txts = getappdata(handles.statusbar, 'txthandles');
handles.statusbar_setFile       = @(txt) set(txts(1), 'String', txt);
handles.statusbar_setCoordinate = @(txt) set(txts(2), 'String', txt);
handles.statusbar_setFile('');
handles.statusbar_setCoordinate('');

% Create MousePosition diplay
tks3_guitools.axesMouseMoveObserver(handles.axes_im1, @(ha) handles.statusbar_setCoordinate(sprintf('x: %.0f, y: %.0f', ha.CurrentPoint([1,3]))),...
                                                      @(ha) handles.statusbar_setCoordinate(''));

% Update handles structure
guidata(hObject, handles);

if handles.batch
    processInput(handles, handles.batchInput{:});
    if ~handles.batchOpen
        if isdeployed
            delete(findall(0, 'Parent', 0));
        else
            delete(handles.figure1);
        end
    end
end

function interfaceStartFCN(handles, plugin, varargin)
    GUI_inactive(handles)

function interfaceReadyFCN(handles, h_interface, plugin, varargin)
    % Plugin interface is ready to be displayed
    
    % Activate Zoomtools
	if isfield(handles, 'zoomtool')
        set(handles.zoomtool.uipanel.Children, 'Enable', 'on')
	end
    
    % Set Position
    x_offset = 10; y_offset = 10;
    fpos = get(handles.figure1, 'position');
    ipos = get(h_interface, 'position');
    set(h_interface, 'position', [sum(fpos([1,3]))-ipos(3)-x_offset, fpos(2)+y_offset, ipos(3:4)], 'visible', 'on');
    WinOnTop(h_interface);      % Always on Top
    
    % Focus on Main Figure if mode is manual
    if isfield(plugin.fish.(plugin.plugin_tag), 'mode') && strcmpi(plugin.fish.(plugin.plugin_tag).mode, 'manual')
        figure(handles.figure1);    % Active FishInspector Window
    end
    
    % Establish a listener to get notified when the plugin interface is closed
    l = addlistener(h_interface, 'ObjectBeingDestroyed', @(varargin) interfaceClosedFCN(guidata(handles.figure1)));    
    setappdata(handles.figure1, 'InterfaceCloseListener', l);

    % Switch manual mode if requested
    if isfield(plugin.fish.(plugin.plugin_tag), 'mode') && ...
        strcmpi('on', get(handles.menu_autoSwitchToManual, 'checked'))
        btn = findobj(h_interface, 'String', 'Manual Selection');
        if ~isempty(btn) && ~get(btn, 'Value')
            set(btn, 'Value', true);
            btn.Parent.SelectionChangedFcn(btn.Parent);
        end
    end
    
    
function interfaceClosedFCN(handles)
    % Plugin Interface was closed
    if isappdata(handles.figure1, 'InterfaceCloseListener')
        rmappdata(handles.figure1, 'InterfaceCloseListener')
    end
    if isappdata(handles.figure1, 'cleanupfcn')
        feval(getappdata(handles.figure1, 'cleanupfcn'))
    end
    GUI_active(handles)
    
% --- Outputs from this function are returned to the command line.
function varargout = FishInspector2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% % % %
% Use Java to set Minimum Size of figure
try
    jFrame = get(handle(handles.figure1), 'JavaFrame');
    jClient = jFrame.fHG2Client;     % R2015
    jWindow = jClient.getWindow;
    if isempty(jWindow); drawnow; pause(0.02); jWindow = jClient.getWindow; end
    jWindow.setMinimumSize(java.awt.Dimension(800, 600));
end

% Get default command line output from handles structure
if exist('handles', 'var') && isstruct(handles);
    varargout{1} = handles.output;
end

function processInput(handles, varargin)
    % List of supported image formats
    imfmts = imformats; imfmts = cellfun(@(x) ['.', x], [imfmts.ext], 'UniformOutput', 0);

    % Check Parameter File Input
    parameterFile = handles.fishobj.parameterFile_default;
    if ~isempty(varargin) && exist(varargin{1}, 'dir')==7 && length(varargin)>=3;
        parameterFile = varargin{3};
    elseif ~isempty(varargin) && exist(varargin{1}, 'file')==2 && length(varargin)>=2;
        parameterFile = varargin{2};
    end
    pIDX = find(strcmpi(handles.popupmenu_ParameterFile.String, parameterFile));
    if isempty(pIDX)
        msg = [{ 'The specified parameter file was not found.';...
                 ' ';...
                ['input: ', parameterFile];...
                 ' ';...
                 'Valid inputs are: '};...
                 handles.popupmenu_ParameterFile.String(cellfun(@(x) isempty(strfind(upper(x), '<HTML>')), handles.popupmenu_ParameterFile.String))];
        if handles.batchOpen
            msgbox(msg, 'Warning', 'warning');
            return
        else
            disp(msg);
            error('The specified parameter file was not found');
        end
    end
    handles.popupmenu_ParameterFile.Value = pIDX;
    handles.fishobj.set_parameterFile(parameterFile);
    
    % % % % % 
    % Get List Of Files
    % A) Folder processing
    if ~isempty(varargin) && exist(varargin{1}, 'dir')==7
        
        % Define file path and filter
        path = varargin{1};
        filter = ''; if length(varargin)>=2; filter = varargin{2}; end
        
        handles.uitabgroup.SelectedTab = handles.Tab1;
        setImDir(path, handles);
        setFilter(filter, handles);
        edit_ImDir_Callback(handles.edit_ImDir, [], handles);
        handles = guidata(handles.figure1);
        
        % Display found files
        disp(['Found ',num2str(length(handles.fullfiles)), ' Files:']);
        cellfun(@(x) disp(x), handles.fullfiles);
        disp(['Found ',num2str(length(handles.fullfiles)), ' Files']);
        
    end

    % B) File processing
    if ~isempty(varargin) && exist(varargin{1}, 'file')==2
        
        handles.uitabgroup.SelectedTab = handles.Tab2;
        [~, ~, ext] = fileparts(varargin{1});
        switch ext
            
            case imfmts
                % Single Image file processing
                files = varargin(1);
                set(handles.edit_FilePath, 'String', files{1});
                handles.fullfiles = files;
                [~, f, e] = fileparts(files{1});
                handles.files = cellstr([f, e]);
                makeListBox(handles, handles.files);
            
            case '.txt'
                % Text-file
                % => Parse txt file
                setFilePath(varargin{1}, handles);
                edit_FilePath_Callback(handles.edit_FilePath, [], handles);
                handles = guidata(handles.figure1);
        
                % Display found files
                disp(['Found ',num2str(length(handles.fullfiles)), ' Files:']);
                cellfun(@(x) disp(x), handles.fullfiles);
                disp(['Found ',num2str(length(handles.fullfiles)), ' Files']);

            otherwise
                % Received a single file but couldn't recognize the content
                disp('Received a single file but couldn''t recognize the content');
                disp(['File: ', varargin{1}]);
                disp('Note: Only imagefiles; and textfiles with ending ''.txt'' are supported');
                return
        end
        
    end
    
    if ~isempty(varargin) && ~(exist(varargin{1}, 'dir')==7) && ~(exist(varargin{1}, 'file')==2)
        % Received a single file but couldn't recognize the content
        disp('Error while batch processing. Couldn''t interpret intput (maybe file does not exist?)');
        disp(['Input: ', varargin{1}]);
        disp('Note: Only imagefiles; and textfiles with ending ''.txt'' are supported');
        return
    end
    
    if ~handles.batchOpen
        % Call Menu item to process all files
        menu_process_all_images_Callback(handles.menu_process_all_images, [], handles);
    end


% % % % %
% Set/Get Image Directory
function setImDir(diri, handles)
    setpref('fishlab', 'imdir', diri);
    set(handles.edit_ImDir, 'String', diri);

function diri = getImDir()
    diri = pwd;
    if ispref('fishlab', 'imdir')
        diri = getpref('fishlab', 'imdir');
    end
    
function pushbutton_ImDir_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ImDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    diri = getImDir();
    newDir = uigetdir(diri);
    if ischar(newDir)
        setImDir(newDir, handles);
        getImagesFromDir(handles, newDir); 
    end
    
function edit_ImDir_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ImDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ImDir as text
%        str2double(get(hObject,'String')) returns contents of edit_ImDir as a double

% The user has entered a new Directory path
newDir = get(handles.edit_ImDir, 'String');

% Check if new directory exists
if ~(exist(newDir, 'dir')==7)
    msgbox({'The directory:', '', newDir, '', 'does not exist :-('}, 'error', 'modal');
    makeListBox(handles, {});
    GUI_off(handles);
    return
end

% Update listbox
setImDir(newDir, handles);
getImagesFromDir(handles, newDir);


% % % % %
% Set/Get File Filter
function setFilter(filti, handles)
    setpref('fishlab', 'filter', filti);
    set(handles.edit_Filter, 'String', filti); 
    
function filti = getFilter()
    filti = '';
    if ispref('fishlab', 'filter');
        filti = getpref('fishlab', 'filter');
    end

function edit_Filter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Filter as text
%        str2double(get(hObject,'String')) returns contents of edit_Filter as a double
% The user has entered a new Directory path
filter = get(handles.edit_Filter, 'String');
setFilter(filter, handles);

% Check if new directory exists
newDir = get(handles.edit_ImDir, 'String');
if ~exist(newDir, 'dir')
    makeListBox(handles, {});
    GUI_off(handles);
    return
end

% Update listbox
setImDir(newDir, handles);
getImagesFromDir(handles, newDir);

    
% % % % %
% Set/Get FilePath Directory
function setFilePath(filePath, handles)
    setpref('fishlab', 'filePath', filePath);
    set(handles.edit_FilePath, 'String', filePath);

function filePath = getFilePath()
    filePath = '';
    if ispref('fishlab', 'filePath')
        filePath = getpref('fishlab', 'filePath');
    end

function pushubutton_FilePath_Callback(hObject, eventdata, handles)
    filePath = fileparts(getFilePath());
    [newFile, pathy] = uigetfile(fullfile(filePath, '*.txt'));
    if ischar(newFile)
        newFile = fullfile(pathy, newFile);
        setFilePath(newFile, handles);
        getImagesFromFileList(handles, newFile); 
    end

function edit_FilePath_Callback(hObject, eventdata, handles)
    % The user has entered a new File path
    newFile = get(handles.edit_FilePath, 'String');

    % Check if new File Exists
    if ~(exist(newFile, 'file')==2)
        msgbox({'The File:', '', newFile, '', 'does not exist :-('}, 'error', 'modal');
        makeListBox(handles, {});
        GUI_off(handles);
        return
    end

    % Update listbox
    setFilePath(newFile, handles);
    getImagesFromFileList(handles, newFile);
    

    
function getImagesFromDir(handles, path)    
    % List of supported image formats
    imfmts = imformats; imfmts = cellfun(@(x) ['.', x], [imfmts.ext], 'UniformOutput', 0);
    
    filter = getFilter();
    files = findfiles(path, filter);
    %files = findfiles(path);

    handles.fullfiles = files;
    [~, files, exts] = cellfun(@(x) fileparts(x), files, 'Uniform', 0);
    file_filt = ismember(upper(exts), upper(imfmts));

    files = cellfun(@(fname, ext) [fname, ext], files(file_filt), exts(file_filt), 'Uniform', 0);
    handles.fullfiles = handles.fullfiles(file_filt);
    handles.files = files;
    guidata(handles.figure1, handles);

    makeListBox(handles, files);
    GUI_off(handles);
    
function getImagesFromFileList(handles, filePath)  
    % Read path names from txt file
    fileList = {};
    fid = fopen(filePath);
    counter = 0;
    while ~feof(fid)
        counter = counter + 1;
        thisLine = fgetl(fid);
        if ~isempty(thisLine) 
            if exist(thisLine, 'file')==2
                fileList{end+1} = thisLine;
            else
                disp(['Skipping Line ', num2str(counter), ': File does not exist'])
            end
        else    
            %disp(['Skipping empty line ', num2str(counter)])
        end
    end
    fclose(fid);

    % Get Filenames with file extenstions
    [~, files, exts] = cellfun(@(x) fileparts(x), fileList, 'Uniform', 0);
    files = cellfun(@(fname, ext) [fname, ext], files, exts, 'Uniform', 0);
    
    % Update everything
    handles.fullfiles = fileList;
    handles.files = files;
    guidata(handles.figure1, handles);

    makeListBox(handles, files);
    GUI_off(handles);

    
    
function GUI_off(handles)
    % Clear image in imscrollpanel
    ha = handles.axes_im1;
    im1 = uint8(0.5.*255.*ones(10));%'toGray');
    if isfield(handles, 'imscrollpanel')
        % Imscrollpanel is already here... just update it
        ch = findall(ha); delete(ch(~ismember(get(ch, 'Type'), {'image', 'axes'})));  % Delete old lines
        handles.imscrollpanel_api.replaceImage(im1);
    end
    
    % Remove html tags from pushbuttons
	hb = findobj(handles.uipanel_edits, 'Style', 'pushbutton');
    for i = 1 : length(hb)
        str = regexprep(get(hb(i), 'String'), '<[^>]*>', '');
        str = regexprep(str, '&.*\;', '');
        hb(i).String = str;
    end
    % Disable all plugin buttons
    ch = findobj(handles.uipanel_edits, '-property', 'Enable');
    set(ch, 'Enable', 'off')
    ch2 = findobj(handles.uipanel_edits);
    ch2(ismember(ch2, [ch; handles.uipanel_edits])) = [];
    for i = 1 : length(ch2)
        thisCH = get(ch2(i), 'JavaPeer');
        thisCH.setEnabled(false);
    end
    % Disable Zoomtool panel
    if isfield(handles, 'zoomtool')
        set(handles.zoomtool.uipanel.Children, 'Enable', 'off')
    end
    if isfield(handles, 'popupmenu_ParameterFile')
        set(handles.popupmenu_ParameterFile, 'Enable', 'off')
    end
    % Disable Shape Data buttons
    set([handles.pushbutton_openJsonFile,...
         handles.text15,...
         handles.pushbutton_deleteJson,...
         handles.pushbutton_saveShape,...
         handles.text13,...
         handles.text14,...
         handles.menu_export_current_image,...
         handles.text12], 'Enable', 'off');
     handles.pushbutton_deleteJson.Visible = 'off';
     % Clear Statusbar
     if isfield(handles, 'statusbar_setFile')
         handles.statusbar_setFile('');
     end
     
function GUI_inactive(handles)
    set(handles.figure1, 'Pointer', 'watch');
	set([handles.pushbutton_ImDir;...
         handles.Tab1.Children;...
         handles.Tab2.Children], 'Enable', 'off')
    ch = findobj(handles.uipanel_edits, '-property', 'Enable');
    %set(ch, 'Enable', 'off')
    set([ch...;...
         ...handles.listbox_files
         ], 'Enable', 'inactive');
    handles.listbox_files.get('JavaPeer').getViewport.getView.setEnabled(false);
    ch2 = findobj(handles.uipanel_edits);
    ch2(ismember(ch2, [ch; handles.uipanel_edits])) = [];
    for i = 1 : length(ch2)
        thisCH = get(ch2(i), 'JavaPeer');
        if ~isempty(get(thisCH, 'MouseExitedCallback')) % Don't disable the Checks/Crosses in front 
            thisCH.setEnabled(false);
        else
            thisCH.setEnabled(true);
        end
    end
    if isfield(handles, 'zoomtool')
        set(handles.zoomtool.uipanel.Children, 'Enable', 'off')
    end
    % Disable Shape Data buttons
    set([handles.pushbutton_openJsonFile,...
         handles.text15,...
         handles.pushbutton_deleteJson,...
         handles.pushbutton_saveShape,...
         handles.text13,...
         handles.text14,...
         handles.popupmenu_ParameterFile,...
         handles.text12], 'Enable', 'off');
    % Disable Menu
    fnames = fieldnames(handles);
    fnames = fnames(cellfun(@(x) ~isempty(strfind(x, 'menu_')), fnames));
    isH = cellfun(@(x) ishandle(handles.(x)), fnames);
    cellfun(@(x) set(handles.(x), 'Enable', 'off'), fnames(isH)); 
    
function GUI_active(handles)
    ch = findobj(handles.uipanel_edits, '-property', 'Enable');
	set([handles.pushbutton_ImDir;...
         handles.Tab1.Children;...
         handles.Tab2.Children;...
         ...handles.listbox_files;...
         handles.menu_export_current_image], 'Enable', 'on')
    handles.listbox_files.get('JavaPeer').getViewport.getView.setEnabled(true);
    handles.listbox_files.get('JavaPeer').getViewport.getView.requestFocus
    if handles.fishobj.enabled
        set(ch, 'Enable', 'on')
        ch2 = findobj(handles.uipanel_edits);
        ch2(ismember(ch2, [ch; handles.uipanel_edits])) = [];
        for i = 1 : length(ch2)
            thisCH = get(ch2(i), 'JavaPeer');
            thisCH.setEnabled(true);
        end
    else
        % Disable all plugin buttons
        set(ch, 'Enable', 'off')
        ch2 = findobj(handles.uipanel_edits);
        ch2(ismember(ch2, [ch; handles.uipanel_edits])) = [];
        for i = 1 : length(ch2)
            thisCH = get(ch2(i), 'JavaPeer');
            thisCH.setEnabled(false);
        end
    end
    if isfield(handles, 'zoomtool')
        set(handles.zoomtool.uipanel.Children, 'Enable', 'on')
    end
    set(handles.text14, 'Enable', 'on');
    update_ShapeDataPanel(handles);
    % Enable Menu
    fnames = fieldnames(handles);
    fnames = fnames(cellfun(@(x) strncmp(x, 'menu_', length('menu_')), fnames));
    fnames = fnames(cellfun(@(x) ~isempty(strfind(x, 'menu_')), fnames));
    isH = cellfun(@(x) ishandle(handles.(x)), fnames);
    cellfun(@(x) set(handles.(x), 'Enable', 'on'), fnames(isH)); 
    
    set(handles.figure1, 'Pointer', 'arrow');

    
    
    
    
function makeListBox(handles, files)

    % Create Context Menu if not done yet
    if isempty(get(handles.listbox_files, 'UIContextMenu'))
        cm = uicontextmenu(handles.figure1);
        cm_callback = @(varargin) listbox_context_menu(guidata(handles.figure1), varargin{:});
        set(cm, 'Callback', @(varargin) listbox_context_menu(guidata(handles.figure1), varargin{:}), 'UserData', handles.figure1);
        uimenu(cm, 'Tag', 'info',        'Label', '* info *',        'Enable', 'off',          'UserData', handles.figure1);
        % - - - - - - - - - - 
        uimenu(cm, 'Tag', 'reveal',     'Label', 'Show in Explorer', 'Callback', cm_callback, 'UserData', handles.figure1, 'Separator', 'off');
        uimenu(cm, 'Tag', 'copyName',   'Label', 'Copy File Name',   'Callback', cm_callback, 'UserData', handles.figure1, 'Separator', 'on');
        uimenu(cm, 'Tag', 'copyPath',   'Label', 'Copy File Path',   'Callback', cm_callback, 'UserData', handles.figure1);
        % - - - - - - - - - - 
        infoMenu = uimenu(cm, 'Tag', 'info2',       'Label', 'Image Info',        'Enable', 'on',          'UserData', handles.figure1, 'Separator', 'on');
             uimenu(infoMenu, 'Tag', 'infoDetail',  'Label', '* finfo *',       'Enable', 'off',          'UserData', handles.figure1);
        set(handles.listbox_files, 'UIContextMenu', cm);
    end
    if isa(handles.listbox_files, 'matlab.ui.control.UIControl')
        % 1) Create Data Model
        if isempty(files)
            jCBList = com.jidesoft.swing.CheckBoxList();
        else
            jList = java.util.ArrayList;
            isenabled = true(size(files));
            for i = 1 : length(files)
                jList.add(files{i});
                isenabled(i) = fishobj2.checkFileIsEnabled(handles.fullfiles{i});
            end
            % 2) Prepare a CheckBoxList component within a scroll-pane
            jCBList = com.jidesoft.swing.CheckBoxList(jList.toArray);
            jCBList.setCheckBoxListSelectedIndices(find(isenabled)-1);
        end
        jCBList.getSelectionModel.setSelectionMode(0); % Enable Single selection only
        handles.jCBList = jCBList;
        jScrollPane = com.mathworks.mwswing.MJScrollPane(jCBList);
        % 3) Place this scroll-pane within a Matlab container (figure or panel)
        oldUnits = get(handles.listbox_files, 'units');
        set(handles.listbox_files, 'units', 'pixel');
        pos = get(handles.listbox_files, 'position');
        set(handles.listbox_files, 'units', oldUnits);
        [jhScroll, hContainer] = javacomponent(jScrollPane, pos, get(handles.listbox_files, 'parent'));
        handles.to_resize(handles.to_resize==handles.listbox_files) = hContainer;
        handles.listbox_files_old = handles.listbox_files;
        set(handles.listbox_files_old, 'visible', 'off');
        
        % ContextMenu Implementation
        handles.listbox_files = handle(hContainer, 'CallbackProperties');
        set(handles.listbox_files, 'UIContextMenu', cm);
        handles.contextMenu = cm;
        
        guidata(handles.figure1, handles);
        
        % Link Callbacks
        selectionModel = handle(jCBList.getSelectionModel, 'CallbackProperties');
        selectionModel.ValueChangedCallback = @(varargin) listbox_files_Callback([], [], guidata(handles.figure1));
        CBselectionModel = handle(jCBList.getCheckBoxListSelectionModel, 'CallbackProperties');
        CBselectionModel.ValueChangedCallback = @(varargin) listbox_files_CB_Callback([], [], guidata(handles.figure1));
        
        scrollView = handle(get(get(get(handles.listbox_files, 'JavaPeer'), 'Viewport'), 'View'), 'CallbackProperties');
        set(scrollView, 'Font', java.awt.Font(get(handles.listbox_files_old, 'FontName'), java.awt.Font.PLAIN, 1.4*get(handles.listbox_files_old, 'FontSize')))
        set(scrollView, 'MousePressedCallback', @(varargin) listbox_context_menu(guidata(handles.figure1), varargin{:}))
    else
        % Update listbox list
        % 1) Create Data Model
        if isempty(files)
            jList = java.util.ArrayList;
            jList.add('-------');
            drawnow;
            handles.jCBList.setListData(jList.toArray);
            handles.jCBList.setCheckBoxListSelectedIndices(0);
        else
            jList = java.util.ArrayList;
            isenabled = true(size(files));
            for i = 1 : length(files)
                jList.add(files{i});
                isenabled(i) = fishobj2.checkFileIsEnabled(handles.fullfiles{i});
            end
            handles.jCBList.setListData(jList.toArray);
            setappdata(handles.figure1, 'isAdjusting', true);
                handles.jCBList.setCheckBoxListSelectedIndices(find(isenabled)-1);
                drawnow;
            setappdata(handles.figure1, 'isAdjusting', false);
        end
    end
%    set(handles.listbox_files, 'String', files, 'Value', 1);

function listbox_context_menu(handles, varargin)
    % Get currently selected filename
    selVal = get(handle(handles.jCBList.getSelectionModel, 'CallbackProperties'), 'MaxSelectionIndex') + 1;
    if selVal<1, return; end % No file selected => return
    fname = handles.files{selVal};
    fullpath = handles.fullfiles{selVal};
    [~, fname_, ext_] = fileparts(fullpath);
    if ~strcmp([fname_, ext_], fname), error('handles.fullfiles doesn''t match files displayed in listbox???'); end
    
    % Called by MousePressedCallback
    if length(varargin)>=2 && isa(varargin{1}, 'javahandle_withcallbacks.com.jidesoft.swing.CheckBoxList')
        if varargin{2}.get('Button')==3  % Did we right click??
            % 1) Calculate correct location of the context Menu 
            set(0, 'Units', 'pixel'); s = get(0, 'ScreenSize');
            pos = [0, -140] + [varargin{2}.get('XOnScreen'), s(3)-varargin{2}.get('YOnScreen')] - handles.figure1.Position(1:2) - [0, handles.figure1.Position(4)];
            
            % Update info text
            infoItem = findall(handles.contextMenu, 'Type', 'uimenu', 'Tag', 'info');
            imSize   = [num2str(handles.fishobj.iminfo.Width), ' x ', num2str(handles.fishobj.iminfo.Height)];
            fileSize = [num2str(floor(handles.fishobj.iminfo.FileSize/1024)), ' kB'];
%             infoTXT = { ['<table style="border-spacing: 0px;border: 0px;margin: 0px 0px 0px 0px;"><tr><td>FileName:  </td><td><i>', fname],...
%                         ['</i><tr><td>Size: </td><td><i>', fileSize, '   (', imSize, ')']};%,...
%                         %['</i><tr><td>BitDepth:  </td><td><i>', num2str(handles.fishobj.iminfo.BitDepth), ' bit (', handles.fishobj.iminfo.ColorType, ')'],...
%                         %['</i><tr><td>FileSize:  </td><td><i>', num2str(floor(handles.fishobj.iminfo.FileSize/1024)), ' kB'] };
%            infoTXT = [infoTXT; repmat({'</td></tr>'}, 1, size(infoTXT, 2))];
            infoTXT = {['<i>', fname, '<br>', fileSize, ' ( ', imSize, ' )']};
            set(infoItem, 'Label', ['<html><b> ', infoTXT{:}]); 
            
            infoItem = findall(handles.contextMenu, 'Type', 'uimenu', 'Tag', 'infoDetail');
            info = handles.fishobj.iminfo;
            if isfield(handles.fishobj.iminfo, 'XMP')
                info = rmfield(handles.fishobj.iminfo, 'XMP');
            end
            labels = fieldnames(info);
            isEmp = cellfun(@(x) isempty(info.(x)), labels);
            infoTXT2 = createTableDataFromStruct(info);
            infoTXT2(ismember(infoTXT2(:,1), labels(isEmp)), :) = [];
            infoTXT2 = sortrows(infoTXT2);
            
%             labels = fieldnames(info);
%             data = cellfun(@(x) info.(x), labels, 'Uniform', 0);
%             isStr = cellfun(@(x) ischar(x), data);
%             data(~isStr) = cellfun(@(x) num2str(x), data(~isStr), 'Uniform', 0);
%             data(cellfun(@isempty, data)) = {'-'};
            infoTXT2 = cellfun(@(l, d) ['<tr><td>',l,'</td><td><i>',d,'</i></td></tr>'], infoTXT2(:,1), infoTXT2(:,2), 'Uniform', 0);
            infoTXT2 = ['<table style="border-spacing: 0px">'; infoTXT2; '</table>'];
            set(infoItem, 'Label', ['<html><b> ', infoTXT2{:}]); 
            
            % Place context menu and make it visible
            set(handles.contextMenu, 'Position', pos,...
                                     'Visible',  'on');
        end
        return
    end
    
    % Called by ContextMenuCallback
    switch get(varargin{1}, 'Tag')
        case 'reveal'             
            dos(['explorer /select,"', fullpath, '"']);  % Open Explorer Window and select File     
            
        case 'copyName'
            clipboard('copy', fname)
            
        case 'copyPath'
            clipboard('copy', fullpath);
        
        otherwise
            disp('sdf')
        
    end
    
%------------------------------------------------
function tableData = createTableDataFromStruct(s)

fieldNames = fieldnames(s);
values = struct2cell(s);

charArray = evalc('disp(s)');
C = textscan(charArray,'%s','delimiter','\n');
fieldnameAndValue = C{1};
numLines = length(fieldnameAndValue);
dispOfValues = cell(numLines, 1);
for k = 1 : numLines
  idx = find(fieldnameAndValue{k}==':');
  if ~isempty(idx) % to avoid blank lines
    dispOfValues{k} = fieldnameAndValue{k}((idx(1)+2):end);
  end
end

numFields = length(fieldNames);
tableData = cell(numFields,2);

% First column of tableData contain fieldNames. Second column of tableData
% contains the string representation of values. We use the values or
% dispOfValues depending on whether each element of values is a vector of
% characters.
tableData(:,1) = fieldNames;
for idx = 1: numFields
    val = values{idx};
    if ischar(val) && size(val,1) == 1
        tableData{idx,2} = val;
    else
        tableData{idx,2} = dispOfValues{idx};
    end
end

%end % createTableDataFromStructure
    
    
    
    
% --- Executes on selection change in listbox_files.
function listbox_files_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_files contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_files

% 1) Get selected file
try
    selModel = handle(handles.jCBList.getSelectionModel, 'CallbackProperties');
    if get(selModel, 'ValueIsAdjusting')
        return; 
    end
    if isappdata(handles.figure1, 'isAdjusting') && getappdata(handles.figure1, 'isAdjusting'), return; end
    val = get(selModel, 'MaxSelectionIndex') + 1;
    if val==0, return; end
catch
    val = get(handles.listbox_files, 'Value');
end
fname = handles.fullfiles{val};

% 2) Update fishobj
GUI_inactive(handles)
handles.fishobj.set_impath(fname);
% [~,fn,ext] = fileparts(fname);
% handles.statusbar_setFile([fn,ext]);  % Update Statusbar
handles.statusbar_setFile(fname);  % Update Statusbar

% Update checkbox
setappdata(handles.figure1, 'isAdjusting', true);
switch handles.fishobj.enabled
    case true
        handles.jCBList.addCheckBoxListSelectedIndex(val-1);
    case false
        handles.jCBList.removeCheckBoxListSelectedIndex(val-1);
end
drawnow;
setappdata(handles.figure1, 'isAdjusting', false);

% 3) Update Display
updateDisplay(handles);
GUI_active(handles)



function listbox_files_CB_Callback(hObject, eventdata, handles)
    
    CBselectionModel = handle(handles.jCBList.getCheckBoxListSelectionModel, 'CallbackProperties');
    if get(CBselectionModel, 'ValueIsAdjusting'), return; end
    if isappdata(handles.figure1, 'isAdjusting') && getappdata(handles.figure1, 'isAdjusting'), return; end
    idx = get(CBselectionModel, 'AnchorSelectionIndex') + 1;
    ischecked = ismember(idx, handles.jCBList.getCheckBoxListSelectedIndices+1);
    fname = handles.fullfiles{idx};
    
%     disp(fname);
%     disp([idx, ischecked]);
    
    % Construct path to data file
    suffix = '__SHAPES.json';
    [bpath, file, ~] = fileparts(fname);
    dpath = fullfile(bpath, [file, suffix]);
    
    if ~ischecked 
        if ~(exist(dpath, 'file')==2)
            data = struct();
        else
            data = loadjson(dpath);
        end
        data.enabled = false;
        savejson('', data, struct('FileName', dpath, 'SingletArray', 0));
        
    else
        if (exist(dpath, 'file')==2)
            data = loadjson(dpath);
            fnames = fieldnames(data);
            if length(fnames)==1 && strcmpi('enabled', fnames)
                delete(dpath);
            else
                data.enabled = true;
                savejson('', data, struct('FileName', dpath, 'SingletArray', 0));
            end
        end

    end
    
    selModel = handle(handles.jCBList.getSelectionModel, 'CallbackProperties');
    if (get(selModel, 'MaxSelectionIndex') + 1) == idx
        listbox_files_Callback([], [], guidata(handles.figure1))
    end
    
function updateDisplay(handles)
% Indicate if there's a datafile
update_ShapeDataPanel(handles);

% Show image in imscrollpanel
ha = handles.axes_im1;
handles.im1 = handles.fishobj.getImdata();%'toGray');
%handles.im1 = handles.fishobj.getImdata('normalize', 'toGray', 'invert');

if isfield(handles, 'imscrollpanel')
    % Imscrollpanel is already here... just update it
    ch = findall(ha); delete(ch(~ismember(get(ch, 'Type'), {'image', 'axes'})));  % Delete old lines
    currIm = get(findall(ha, 'type', 'image'), 'CData');
    if (length(size(currIm))==length(size(handles.im1))) && all(size(currIm)==size(handles.im1)) && all(all(all(handles.im1==currIm)))
        % Image hasn't changed
    else
        % Image has changed => update
        mag = handles.imscrollpanel_api.getMagnification();
        loc = handles.imscrollpanel_api.getVisibleImageRect();
        handles.imscrollpanel_api.replaceImage(handles.im1);
        handles.imscrollpanel_api.setMagnificationAndCenter(mag, loc(1)+loc(3)/2, loc(2)+loc(4)/2);
        %imshow(handles.im1, 'parent', handles.axes_im1)
    end
else
    % Initialize Imscrollpanel, and connect it to resize function
    hi = imshow(handles.im1, 'parent', handles.axes_im1);
    pos = get(handles.axes_im1, 'position');
    imageChangedCallback = @() adjustFishOrientation(guidata(handles.figure1));
    handles.imscrollpanel     = imscrollpanel(handles.figure1, hi, imageChangedCallback);
    handles.imscrollpanel_api = iptgetapi(handles.imscrollpanel);
    handles.to_resize(handles.to_resize==handles.axes_im1) = handles.imscrollpanel;
    set(handles.imscrollpanel, 'units', 'pixel', 'position', pos, 'BackgroundColor', [0.5,0.5,0.5]);
    guidata(handles.figure1, handles)
    handles = makeImageTools(handles, handles.figure1);
    % Create overlay axes
    handles.axes_im1_overlay = axes('Parent',   get(handles.axes_im1, 'Parent'),...
                                    'units',    get(handles.axes_im1, 'units'),...
                                    'position', get(handles.axes_im1, 'position'));
    axis(handles.axes_im1_overlay,  'off'); set(handles.axes_im1_overlay, 'Visible', 'off');
    setappdata(handles.axes_im1, 'axes_overlay', handles.axes_im1_overlay);

	hlink = linkprop([handles.axes_im1, handles.axes_im1_overlay], {'Position', 'units', 'XLim', 'YLim', 'XDir', 'YDir', 'DataAspectRatio'});
    setappdata(handles.axes_im1, 'hlink', hlink);
end

% Plot the features
hold(ha, 'on');
handles.fishobj.DrawPlugins(handles.axes_im1, ~isdeployed);
hold(ha, 'off'); 


% Adjust Fish Orientation
adjustFishOrientation(handles)

% Adjust zooming
ImageToolsCallback(handles.figure1);
handles = adjustOverviewPanelSize(handles);


% Store stuff to handles
guidata(handles.figure1, handles);
cla(handles.axes_im1_overlay)
set(handles.axes_im1_overlay, 'Visible', 'off');
drawnow


function adjustFishOrientation(handles)
    if handles.togglobutton_autorotate.Value && isprop(handles.fishobj, 'fishOrientation')
        if ~isempty(handles.fishobj.fishOrientation) && handles.fishobj.fishOrientation.horizontally_flipped
            handles.axes_im1.XDir = 'reverse';
        else
            handles.axes_im1.XDir = 'normal';
        end
        if ~isempty(handles.fishobj.fishOrientation) && handles.fishobj.fishOrientation.vertically_flipped
            handles.axes_im1.YDir = 'normal';
        else
            handles.axes_im1.YDir = 'reverse';
        end
    else
        handles.axes_im1.XDir = 'normal';
        handles.axes_im1.YDir = 'reverse';
    end
    
function handles = makeImageTools(handles, parent, settings)
    hf = handles.figure1;    
    hfpos = get(hf, 'Position'); 
    
    sp = handles.imscrollpanel;
    sppos = get(sp, 'position');
    spAPI = handles.imscrollpanel_api;
    
    magboxwidth  = 70;
    magboxheight = 20;
    
    popupwidth = 190;
    popupheight = 20;
    popupfontsize = 9;

    buttonwidth  = 20;
    buttonheight = 20;
    
    xgap = 10;
    ygap = 7;
    
    meth = {'Fit fish',...
            'Fit image',...
            'Fit image height',...
            'Fit image width',...
            '50%',...
            '100%',...
            '200%',...
            'Custom'};
    
    hpanel = uipanel(parent);
    set(hpanel, 'Units', 'pixel',...
                'Position', [sppos(1)+sppos(3)-xgap/2-25-xgap/2-buttonwidth-xgap/2-buttonwidth-xgap-magboxwidth-xgap-popupwidth-xgap, sppos(2)+sppos(4)+ygap, 4.5*xgap+magboxwidth+popupwidth+2*buttonwidth+25, 4*ygap+popupheight],...
                'FontSize', 9,...
                'FontWeight', 'normal',...
                'title', 'Zoom');
    
    hi = findobj(handles.axes_im1, 'type', 'image');
    hMagBox = immagbox(hpanel, hi);
    hp = uicontrol(hpanel, 'Style',    'popupmenu',...
                           'String',   meth,...
                           'Units',    'pixel',...
                           'FontSize', popupfontsize,...
                           'Position', [xgap, ygap, popupwidth, popupheight],...
                           'Callback', @ImageToolsCallback);
    cbmb = get(hMagBox, 'Callback');
    set(hMagBox, 'Units', 'pixel',...
                 'Position', [xgap+popupwidth+xgap, ygap-1, magboxwidth, magboxheight],...
                 'Callback', @(varargin) cellfun(@(x) feval(x, varargin{:}), {@(varargin) feval(cbmb, varargin{1}), @(varargin) set(hp, 'Value', find(strcmpi(meth, 'Custom')))}));
    hbplus = uicontrol(hpanel, 'Style', 'Pushbutton', ...
                               'String', '+',...
                               'Units',  'pixel', ...
                               'Position', [xgap+popupwidth+xgap+magboxwidth+xgap/2, ygap-1, buttonwidth, buttonheight],...
                               'Callback', @(varargin) cellfun(@(x) feval(x, varargin{:}), {@(varargin) handles.imscrollpanel_api.setMagnification(handles.imscrollpanel_api.getMagnification()+0.25), @(varargin) set(hp, 'Value', find(strcmpi(meth, 'Custom'))), @(varargin) setpref('fishlab', 'lastCustomMagnification', handles.imscrollpanel_api.getMagnification())}));
    hbminus = uicontrol(hpanel, 'Style', 'Pushbutton', ...
                                'String', '-',...
                                'Units',  'pixel', ...
                                'Position', [xgap+popupwidth+xgap+magboxwidth+xgap/2+buttonwidth+xgap/2, ygap-1, buttonwidth, buttonheight],...
                                'Callback', @(varargin) cellfun(@(x) feval(x, varargin{:}), {@(varargin) handles.imscrollpanel_api.setMagnification(handles.imscrollpanel_api.getMagnification()-0.25), @(varargin) set(hp, 'Value', find(strcmpi(meth, 'Custom'))), @(varargin) setpref('fishlab', 'lastCustomMagnification', handles.imscrollpanel_api.getMagnification())}));
    set(handles.togglobutton_autorotate, 'parent',      hpanel,...
                                         'Units',       'pixel',...
                                         'Visible',     'on',...
                                         'Position',    [xgap+popupwidth+xgap+magboxwidth+xgap/2+buttonwidth+xgap/2+buttonwidth+xgap/2, ygap-1-(25-buttonheight)/2, 25, 25])
	hop = imoverviewpanel(handles.figure1, hi);
    %uistack(hop, 'bottom')
    ygap = 10;
    lbpos = get(handles.listbox_files, 'position');
    ppos = get(handles.uipanel_edits, 'position'); 
    heighty = lbpos(3) / size(handles.fishobj.imdata, 2) * size(handles.fishobj.imdata, 1);% + 17;
    set(hop, 'units', 'pixel',...
             'position', [lbpos(1), ppos(2), lbpos(3), heighty],...
             'BorderType', 'etchedin',...
             'FontSize', 9,...
             'FontWeight', 'bold');%,...
             %'Title', 'Overview');
	handles.uipanel5.Position(2) = ppos(2)+heighty+ygap;
	set(handles.listbox_files, 'position', [lbpos(1), sum(handles.uipanel5.Position([2,4]))-1, lbpos(3), lbpos(4)+(lbpos(2)-(sum(handles.uipanel5.Position([2,4]))-1))]);
    
handles.to_resize = [ handles.to_resize,....
                      hpanel, hop];  
handles.start_fig_pos = get(handles.figure1, 'position');
handles.start_pos     = get(handles.to_resize, 'position');
handles.dock_top    = [handles.dock_top,     1, 0];
handles.dock_bottom = [handles.dock_bottom,  0, 1];
handles.dock_left   = [handles.dock_left,    0, 1];
handles.dock_right  = [handles.dock_right,   1, 0]; 

% Store zoom panel handles
handles.zoomtool = struct(   'uipanel',          hpanel,...
                             'txt_mag',          hMagBox,...
                             'popup_mag',        hp,...
                             'pushbutton_plus',  hbplus,...
                             'pushbutton_minus', hbminus,...
                             'overview',         hop);
guidata(handles.figure1, handles);

% --- Executes on button press in togglobutton_autorotate.
function togglobutton_autorotate_Callback(hObject, eventdata, handles)
% hObject    handle to togglobutton_autorotate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglobutton_autorotate
adjustFishOrientation(handles);
ImageToolsCallback(handles.figure1);

function handles = adjustOverviewPanelSize(handles)
    hop = handles.zoomtool.overview;
    ygap = 10;
    lbpos = get(handles.listbox_files, 'position');
    ppos = get(handles.uipanel_edits, 'position'); 
    heighty = lbpos(3) / size(handles.fishobj.imdata, 2) * size(handles.fishobj.imdata, 1);% + 25;
    set(hop,                   'position', [lbpos(1), ppos(2),              lbpos(3)+1, heighty+8]);
	
    handles.uipanel5.Position(2) = ppos(2)+heighty+5;%+ygap;
	set(handles.listbox_files, 'position', [lbpos(1), sum(handles.uipanel5.Position([2,4]))-1, lbpos(3), lbpos(4)+(lbpos(2)-(sum(handles.uipanel5.Position([2,4]))-1))]);
    
    %set(handles.listbox_files, 'position', [lbpos(1), ppos(2)+heighty+ygap, lbpos(3), lbpos(4)+(lbpos(2)-(ppos(2)+heighty+ygap))]);
    handles.start_fig_pos = get(handles.figure1, 'position');
    handles.start_pos     = get(handles.to_resize, 'position');

function ImageToolsCallback(hobj, event)

handles = guidata(hobj);
spAPI = handles.imscrollpanel_api;
visRect = spAPI.getViewport();

hobj = handles.zoomtool.popup_mag;
selVal = hobj.String{hobj.Value};
switch selVal

    case 'Fit fish'
        try
            fineContour = handles.fishobj.fishContour.shape(strcmp('fineContour', {handles.fishobj.fishContour.shape.name}));
            minx = min(fineContour.x);
            maxx = max(fineContour.x);
            miny = min(fineContour.y);
            maxy = max(fineContour.y);
            newMag = min([visRect(2)/(1.1.*(maxy-miny)), visRect(1)/(1.1.*(maxx-minx))]);
        catch Me
            disp('-----------------')
            disp('ZoomTool Error:');
            disp(Me.message);
            hobj.Value = find(strcmp(hobj.String, 'Fit image'));
            ImageToolsCallback(hobj, []);
            hobj.Value = find(strcmp(hobj.String, 'Fit fish'));
            return
        end
        
    case 'Fit image',...
        newMag = handles.imscrollpanel_api.findFitMag();
    
    case 'Fit image height',...
        newMag = visRect(2)/size(handles.im1, 1);
    
    case 'Fit image width',...
        newMag = visRect(1)/size(handles.im1, 2);

    case '50%',...
        newMag = 0.5;
    
    case '100%',...
        newMag = 1;
    
    case '200%',...
        newMag = 2;
    
    case 'Custom'
        if ispref('fishlab', 'lastCustomMagnification')
            newMag = getpref('fishlab', 'lastCustomMagnification');
        else
            newMag = handles.imscrollpanel_api.getMagnification();
        end
        
end

if strcmpi(selVal, 'Fit fish')
    center = [(maxx+minx)/2, (maxy+miny)/2];
    if handles.togglobutton_autorotate.Value
        try
            if handles.fishobj.fishOrientation.horizontally_flipped
                center(1) = size(handles.fishobj.imdata,2)-center(1);
            end
            if handles.fishobj.fishOrientation.vertically_flipped
                center(2) = size(handles.fishobj.imdata,1)-center(2);
            end
        end
    end
    handles.imscrollpanel_api.setMagnificationAndCenter(newMag, center(1), center(2));
else
%    if strcmpi(selVal, 'Custom')
%         if ~isempty(lastRect) && ~isempty(oldSize)
%                 [new_cx,new_cy] = handles.imscrollpanel_api.getPreserveViewCenter(old_size, size(get(hIm, 'CData')), lastRect);
%                  setVisibleLocation(new_cx, new_cy)
%                  disp('done');
%             end
%             oldSize = size(get(hIm, 'CData'));
%         end
%         lastRect = getVisibleImageRect(); 
%     end
    handles.imscrollpanel_api.setMagnification(newMag);
end

setpref('fishlab', 'lastCustomMagnification', newMag);

     


% 
% function nice_plot(x,y, fo, ha, color, varargin)
%     in = inpolygon(x, y, fo.fishEye_shape.x, fo.fishEye_shape.y);
%     plot(x(~in), y(~in), color, 'parent', ha, varargin{:});
% 


% Helper to return a stack-row's file-name and function name
function str = get_stack_info(ME,row)
    try
        func_name = ME.stack(row).name;
        [~,file_name] = fileparts(ME.stack(row).file);
        if strcmpi(file_name,func_name)
            file_name = '';
        else
            file_name = [file_name '.'];
        end
    catch
        file_name = '';
    end
    str = [file_name func_name ':' num2str(ME.stack(row).line)];

% General create function for most ui components
function general_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
% Adjust scaling of all GUI components
guitools.resize_function(guidata(handles.figure1), eventdata{:})

% Adjust zooming
if isfield(handles, 'imscrollpanel_api')
    ImageToolsCallback(handles.figure1);
    handles = adjustOverviewPanelSize(handles);
    guidata(handles.figure1, handles);
end
end






% JSON Data Panal
% --------------------------------------------------------------------
% --------------------------------------------------------------------

function update_ShapeDataPanel(handles)
    if exist(handles.fishobj.datapath, 'file')==2
        set([handles.pushbutton_openJsonFile,...
             handles.text15,...
             handles.pushbutton_deleteJson], 'Enable', 'on');
        handles.pushbutton_deleteJson.Visible = 'on';
        set([handles.pushbutton_saveShape,...
             handles.text13,...
             handles.popupmenu_ParameterFile,...
             handles.text12], 'Enable', 'off');
    else
        set([handles.pushbutton_openJsonFile,...
             handles.text15,...
             handles.pushbutton_deleteJson], 'Enable', 'off');
        handles.pushbutton_deleteJson.Visible = 'off';
        set([handles.pushbutton_saveShape,...
             handles.text13,...
             handles.popupmenu_ParameterFile,...
             handles.text12], 'Enable', 'on');
    end

% --- Executes on button press in pushbutton_saveShape.
function pushbutton_saveShape_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_saveShape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.fishobj.savedata();
update_ShapeDataPanel(handles);

% --- Executes on button press in pushbutton_openJsonFile.
function pushbutton_openJsonFile_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_openJsonFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fullpath = handles.fishobj.datapath;
dos(['explorer /select,"', fullpath, '"']);

% --- Executes on button press in pushbutton_deleteJson.
function pushbutton_deleteJson_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_deleteJson (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.fishobj.datapath);
listbox_files_Callback(handles.listbox_files, [], handles);





% Menu Callbacks
% --------------------------------------------------------------------
% --------------------------------------------------------------------

function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % --------------------------------------------------------------------
    function menu_openDirectory_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_openDirectory (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    handles.uitabgroup.SelectedTab = handles.Tab1;
    handles.pushbutton_ImDir.Callback(handles.pushbutton_ImDir, []);

    % --------------------------------------------------------------------
    function menu_openImageList_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_openImageList (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    handles.uitabgroup.SelectedTab = handles.Tab2;
    handles.pushbutton_FilePath.Callback();

    % --------------------------------------------------------------------
    function menu_quit_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_quit (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if isdeployed
        delete(findall(0, 'parent', 0));
    else
        delete(handles.figure1);
    end



% --------------------------------------------------------------------
function menu_run_Callback(hObject, eventdata, handles)
% hObject    handle to menu_run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % --------------------------------------------------------------------
    function menu_process_all_images_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_process_all_images (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    filesIdx = handles.jCBList.getCheckBoxListSelectedIndices+1;
    files2process = handles.fullfiles(filesIdx);
    hwait = waitbar(0, ['Processing ', num2str(length(files2process)), ' images'], 'Name', 'Image Processing');
    WinOnTop(hwait);
    if isdeployed, set(hwait, 'WindowStyle', 'modal'); end
    for i = 1 : length(files2process)

        disp(['Processing #', num2str(i),' / #', num2str(length(files2process))]);
        if ishandle(hwait)
            waitbar(i/(length(files2process)+1), hwait, ['Processing image ', num2str(i), ' of ', num2str(length(files2process))]);
        else
            % User has closed the waitbar => stop processing
            break
        end
        setappdata(handles.figure1, 'isAdjusting', true);
            handles.jCBList.setSelectedIndex(filesIdx(i)-1);
            drawnow
        setappdata(handles.figure1, 'isAdjusting', false);
        listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));
        handles.fishobj.savedata();
        drawnow

    end
    listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));
    delete(hwait)
    
    % --------------------------------------------------------------------
    function menu_updateFeature_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_updateFeature (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)


        ch = get(hObject, 'Children');
        newCB = @(varargin) updateFeatureLoop(guidata(handles.figure1), varargin{:});
        for j = 1:length(ch)
            if ~isappdata(ch(j), 'registered')
                cb = get(ch(j), 'Callback');
                set(ch(j), 'Callback', @(varargin) newCB(cb, varargin{:}));
                setappdata(ch(j), 'registered', true);
            end
        end

        function updateFeatureLoop(handles, originalCallback, hMenu, varargin)

            filesIdx = handles.jCBList.getCheckBoxListSelectedIndices+1;
            files2process = handles.fullfiles(filesIdx);
            hwait = waitbar(0, ['Processing ', num2str(length(files2process)), ' images'], 'Name', 'Image Processing');
            WinOnTop(hwait);
            if isdeployed, set(hwait, 'WindowStyle', 'modal'); end
            for i = 1 : length(files2process)

                disp(['Processing #', num2str(i),' / #', num2str(length(files2process))]);
                if ishandle(hwait)
                    waitbar(i/(length(files2process)+1), hwait, ['Processing image ', num2str(i), ' of ', num2str(length(files2process))]);
                else
                    % User has closed the waitbar => stop processing
                    break
                end
                setappdata(handles.figure1, 'isAdjusting', true);
                    handles.jCBList.setSelectedIndex(filesIdx(i)-1);
                    drawnow
                setappdata(handles.figure1, 'isAdjusting', false);
                listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));

                % Call actual menu callback in fishobj2/makeFeaturePanel/callbackUpdateFeature
                eventdata = {};
                if ~strcmpi('On', get(handles.menu_checkPreserveManualSelection, 'Checked'))
                    eventdata = {'-eraseManualSelections'};
                end
                if strcmpi('On', get(handles.menu_checkUpdateDependent, 'Checked'))
                    eventdata = cat(1, eventdata, '-UpdateDependent');
                end
                originalCallback(hMenu, eventdata{:});
                listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));
                drawnow
            end
            listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));
            delete(hwait)

    % --------------------------------------------------------------------
    function menu_checkUpdateDependent_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_checkUpdateDependent (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Toggle Checked Status
    currentState = get(hObject, 'Checked');
    if strcmpi('On', currentState)
        newState = 'Off';
    else
        newState = 'On';
    end
    set(hObject, 'Checked', newState);

    % --------------------------------------------------------------------
    function menu_checkPreserveManualSelection_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_checkPreserveManualSelection (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Toggle Checked Status
    state = get(hObject, 'Checked');
    if strcmpi('On', state)
        newState = 'Off';
    else
        newState = 'On';
    end
    set(hObject, 'Checked', newState);

    
    
% --------------------------------------------------------------------
function menu_export_Callback(hObject, eventdata, handles)
% hObject    handle to menu_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % --------------------------------------------------------------------
    function menu_export_current_image_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_export_current_image (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    imageExportGUI(handles.axes_im1)

    % --------------------------------------------------------------------
    function menu_export_image_list_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_export_image_list (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    DefaultName0 = 'images';
    % Get Default Folder for storing
    if ~isempty(strfind(upper(handles.uitabgroup.SelectedTab.Title), 'FOLDER'))
        % Folder Tab is active
        DefaultPath = getImDir;
    else
        % File Tab is active
        DefaultPath = fileparts(getFilePath);
    end
    if isempty(DefaultPath), DefaultPath = pwd; end

    % Get unique Filename
    counter = 1; DefaultName = DefaultName0;
    while exist(fullfile(DefaultPath, [DefaultName, '.txt']), 'file')==2
        DefaultName = [DefaultName0, '_' num2str(counter, '%02d')]; counter = counter + 1;
    end

    % Let user select a file
    FilterSpec  = fullfile(DefaultPath, [DefaultName,'.txt']);
    DialogTitle = 'Save Image List';
    [filename, pathname] = uiputfile(FilterSpec,DialogTitle);
    if ischar(filename)
        fid = fopen(fullfile(pathname, filename), 'w');
        isEnabled = handles.jCBList.getCheckBoxListSelectedIndices;
        for i = 1 : length(handles.fullfiles)
            if ismember(i-1, isEnabled)
                fprintf(fid, '%s\r\n', handles.fullfiles{i});
            end
        end
        fclose(fid);

        dos(['explorer /select,"', fullfile(pathname, filename), '"']);
    end

    % --------------------------------------------------------------------
    function menu_exportWOBackground_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_exportWOBackground (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get Default Folder for storing
    if ~isempty(strfind(upper(handles.uitabgroup.SelectedTab.Title), 'FOLDER'))
        DefaultPath = getImDir;                 % Folder Tab is active
    else
        DefaultPath = fileparts(getFilePath);   % File Tab is active
    end
    savepath = uigetdir(DefaultPath, 'Select Output Folder');
    if ~ischar(savepath)
        return
    end
    
    filesIdx = handles.jCBList.getCheckBoxListSelectedIndices+1;
    files2export = handles.fullfiles(filesIdx);
    hwait = waitbar(0, ['Processing ', num2str(length(files2export)), ' images'], 'Name', 'Export images...');
    if isdeployed, set(hwait, 'WindowStyle', 'modal'); end
    for i = 1 : length(files2export)

        if ishandle(hwait)
            waitbar(i/(length(files2export)+1), hwait, ['Processing image ', num2str(i), ' of ', num2str(length(files2export))]);
        else
            % User has closed the waitbar => stop processing
            msgbox('stopped');
            break
        end
        setappdata(handles.figure1, 'isAdjusting', true);
            handles.jCBList.setSelectedIndex(filesIdx(i)-1);
            drawnow
        setappdata(handles.figure1, 'isAdjusting', false);
        listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));
        
        %set(handles.listbox_files, 'Value', filesIdx(i));
        %listbox_files_Callback(handles.listbox_files, [], guidata(handles.figure1));
        
            A = handles.fishobj.getImdata('subtractBackground');
            [~, fname, ext] = fileparts(handles.fishobj.impath);
            newFile = [fname, '__removedBackground'];
            imwrite(A, fullfile(savepath, [newFile, ext]));

        drawnow

    end
    delete(hwait)

    % --------------------------------------------------------------------
    function menu_export_to_workspace_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_export_to_workspace (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

        assignin('base', 'im1', handles.im1)
        assignin('base', 'fish', handles.fishobj)

        

% --------------------------------------------------------------------
function menu_settings_Callback(hObject, eventdata, handles)
% hObject    handle to menu_settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % --------------------------------------------------------------------
    function menu_autoSwitchToManual_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_autoSwitchToManual (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Toggle OnOff State of this menu item
    onOff = {'on', 'off'};
    onOff = onOff{~strcmpi(get(hObject, 'checked'), onOff)};
    set(hObject, 'checked', onOff)

        
    
% --------------------------------------------------------------------
function menu_help_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % --------------------------------------------------------------------
    function menu_dosCommands_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_dosCommands (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    msg = {['FishInspector, version ', handles.version]; ...
            '=====================';...
            '"FishInspector.exe -process ..." recursively scans folders for images, and';...
            'does automatic feature extraction for Zebrafishembryos.';...
            ' ';
            '"FishInspector.exe -open ..." loads the GUI with specified files, filter,';...
            'and parameter file.';...
            ' ';
            'Usage:';...
            ' #1) "Folder-processing"';...
            ' -------------------------------';...
            '    FishInspector.exe -process <folder> [<filter>] [<parameterFile>]';...
            ' with';...
            '       <folder>                 Full path to a folder that contains images';...
            '       [<filter>]                 (Optional) applies filter on filenames';...
            '       [<parameterFile>]  (Optional) uses the specified parameter set';...
            ' '
            ' Example: ';...
            ' FishInspector.exe -process "C:\Img\" "2.png" "FishParameter_default.json"';...
            '     => Recursively searches the folder "C:\Img" for image files';...
            '           that contain the string "_2.png", and extracts features using';...
            '           the parameter set "FishParameter_default.json"';...
            ' ';...
            ' Note: The specified parameter file must be located in the default';...
            '       paramater file folder.';...
            ' ';...
            ' #2) "Single-image-processing"';...
            ' ----------------------------------------';...
            '    FishInspector.exe -process <imagefile> [<parameterFile>]';...
            ' with';...
            '       <imagefile>             Full path to image file';...
            '       [<parameterFile>]   (Optional) uses the specified parameter set';...
            ' ';...
            ' Example: FishInspector.exe -process "C:\Images\Image_001.png"';...
            '     => Extracts features from image "C:\Images\Image_001.png"';...
            ' ';...
            ' #3) "Text-file batch processing"';...
            ' ------------------------------------------';...
            '    FishInspector.exe -process <txtfile> [<parameterFile>]';...
            ' with';...
            '       <txtfile>       Full path to txtfile that lists the images,';...
            '                           which should be processed. The txtfile is ';...
            '                           expected to contain one image file per line,';...
            '                           e.g.';...
            '                           txtfile = C:\Images\Image_001.png';...
            '                                        C:\Images\Image_002.png';...
            '                                        C:\Images\Image_003.png';...
            '                                     ...';...
            '       [<parameterFile>]   (Optional) uses the specified parameter set';...
            ' ';...
            ' Example: FishInspector.exe -process "C:\Images\imagefiles.txt"';...
            '     => Does feature extraction on all images listed in "imagefiles.txt"';...
            ' ';...
            };
    cellfun(@(x) disp(x), msg);
    hm = msgbox(msg, 'Dos Commands');
    
    % --------------------------------------------------------------------
    function menu_licenses_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_licenses (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        str = {['FishInspector, version ', handles.version]; ...
                ' '; ...
                'FishInspector contains source code from these open source projects: ';...
                ' '};
        if ~isdeployed
            fid = fopen(fullfile(guitools.getCurrentDir, 'external', 'Licenses', '_externals.txt'));
        else
            fid = fopen(fullfile(guitools.getCurrentDir, 'Licenses', '_externals.txt'));
        end
        while ~feof(fid)
            thisLine = fgetl(fid);
            str{end+1} = ['     - ', thisLine];
        end
        fclose(fid);

        % Read License txt
        str_file = {};
        fid = fopen(fullfile(guitools.getCurrentDir, 'License.txt'));
        while ~feof(fid)
            str_file{end+1, 1} = fgetl(fid);
        end
        fclose(fid);
        
        str = [str_file; str(2:end)];
        
        str{end+1} = ' '; ...
        str{end+1} = ['More information can be found in the "', guitools.getCurrentDir, '\Licenses" directory.']; ...
        str{end+1} = ' '; ...
        str{end+1} = 'For support, please contact support@tks3.com'; ...
        str{end+1} = ' '; ...
        str{end+1} = ' ';

        hbox = msgbox( str, 'Licenses FishInspector', 'modal');

    % --------------------------------------------------------------------
    function menu_about_Callback(hObject, eventdata, handles)
    % hObject    handle to menu_about (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    [A, map] = imread(fullfile(guitools.getCurrentDir, 'splash.png'));
    hf = figure;
    ss = get(0, 'ScreenSize')./2; ss=ss(3:4);sa = size(A); sa=sa(1:2);
    set(hf, 'MenuBar', 'None', 'ToolBar', 'none', 'WindowStyle', 'modal', 'NumberTitle', 'off', 'Name', 'About', 'Position', [ss-sa./2, sa+[0, 0]]);
    ha = gca(hf); set(ha, 'Units', 'Pixel', 'Position', [1,1,sa]);
    imshow(A, map, 'parent', ha);
    ht = text(10,size(A, 1)-15, ['Version ', handles.version, '  (C) 2016-2018']);
    
    ht = text(10+ht.Extent(3)+10, size(A, 1)-15, 'see License.txt', 'Color', 'blue', 'FontWeight', 'normal');
    set(ht, 'ButtonDownFcn', @(varargin) winopen(fullfile(guitools.getCurrentDir, 'License.txt')));
    enterFcn = @(fig, currentPoint)...
                      set(fig, 'Pointer', 'hand');
    iptSetPointerBehavior(ht, enterFcn);
    iptPointerManager(hf);
    
    
% --------------------------------------------------------------------
function menu_featureSets(handles, selectedFeature, varargin)
    disp(selectedFeature)
     % Update FeatureMenu Checks
    m = varargin{1}; p = get(m, 'parent'); ch = get(p, 'children'); for i = 1: length(ch); set(ch(i), 'Checked', 'off'); end; set(m, 'Checked', 'on');
    
    % Update FishObject
    GUI_inactive(handles)
    set_pluginCurrentGroup(handles.fishobj, selectedFeature);   % Feature Panel gets updated automatically
    if ~isempty(handles.fishobj.imdata), updateDisplay(handles); end
    GUI_active(handles)
