function imageExportGUI(h2save)
% IMAGEEXPORTGUI(h2save)
% Simple user interface for storing axes to image files
%
% Scientific Software Solutions
% Tobias Kieﬂling 01/2013-06/2016
% support@tks3.de

    hf = figure;
    set(hf, 'ToolBar', 'none', 'MenuBar', 'none', 'NumberTitle', 'off', 'Name', 'Export Image', 'Units', 'Pixel');
    set(hf, 'Position', hf.Position.*[1,1,1,0]+[0,0,0,216], 'Resize', 'off');
    options = {'VectorGraphics (PDF)', 'pdf';...
               'PixelGraphics  (PNG)', 'png'};
	
    lastFile = '';
    if ispref('ImageExportGUI', 'lastFile')
        lastFile = getpref('ImageExportGUI', 'lastFile');
    end
    lastOption = 1;
    if ispref('ImageExportGUI', 'lastOption')
        lastOption = getpref('ImageExportGUI', 'lastOption');
    end
    bg = [];
    he = [];
    createGUI();
    
    function createGUI
       
        bg = uibuttongroup(hf, 'Title', 'Export Options', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.9, 0.4]);
        cheight = 0.9 / size(options, 1);
        for i = 1 : size(options, 1)
            uicontrol(bg, 'Style', 'Radiobutton', 'String', options{i, 1}, 'Value', i==lastOption, 'UserData', options{i,2}, 'Callback', @optionChanged_callback, 'Units', 'normalized', 'Position', [0.05, 0.1+(i-1)*cheight, 0.9, 0.8*cheight]);
        end
        uicontrol(hf, 'Style', 'Pushbutton', 'String', 'File',   'Units', 'normalized', 'Position', [0.05, 0.35, 0.1, 0.1], 'Callback', @dirButton_callback);
        he = uicontrol(hf, 'Style', 'Edit',       'String', lastFile, 'Units', 'normalized', 'Position', [0.175, 0.35, 0.775, 0.1], 'Callback', @edit_callback, 'HorizontalAlignment', 'left');
        
        uicontrol(hf, 'Style', 'Pushbutton', 'String', 'OK',     'Units', 'normalized', 'Position', [0.50, 0.1, 0.2, 0.2], 'Callback', @ok_callback);
        uicontrol(hf, 'Style', 'Pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.75, 0.1, 0.2, 0.2], 'Callback', @cancel_callback);
        
    end

    function optionChanged_callback(btn_handle, varargin)

        disp(get(btn_handle, 'UserData'));
        lastOption = find(strcmp(options(:,2), get(btn_handle, 'UserData')));
        setpref('ImageExportGUI', 'lastOption', lastOption)
        
        % Adjust file ending
        [bpath, fname, ext] = fileparts(lastFile);
        if ~isempty(ext) && ~strcmpi(ext, ['.', btn_handle.UserData])
            he.String = fullfile(bpath, [fname '.', btn_handle.UserData]);
            edit_callback;
        end
        
    end

    function dirButton_callback(varargin)
        [filename, pathname] = uiputfile(['*.', bg.SelectedObject.UserData], 'Save Image File', fileparts(lastFile));
        if filename == 0
            return
        end
        file = fullfile(pathname, filename);
        lastFile = file;
        setpref('ImageExportGUI', 'lastFile', file);
        set(he, 'String', file);
    end

    function edit_callback(varargin)
        file = he.String;
        if ~(exist(fileparts(file), 'dir')==7)
            waitfor(msgbox('The specified path does not exist :-(', 'Error', 'error', 'modal'));
            return
        end
        lastFile = file;
        setpref('ImageExportGUI', 'lastFile', file);
    end

    function ok_callback(varargin)
        if isempty(lastFile)
            waitfor(msgbox('No Filename entered', 'Error', 'error', 'modal'));
            return
        end
        
        fmt = lower(bg.SelectedObject.UserData);
        
        % Adjust file ending
        [bpath, fname, ext] = fileparts(lastFile);
        if ~isempty(ext) && ~strcmpi(ext, ['.', fmt])
            he.String = fullfile(bpath, [fname '.', fmt]);
            edit_callback;
        end
        
        % Close Figure so users don't double click
        delete(hf);
        
        % Write Image
        export_fig(h2save, lastFile, ['-', fmt]);        
        
        % Open Explorer Window and select File
        dos(['explorer /select,"', lastFile, '"']);
        
    end

    function cancel_callback(varargin)
        delete(hf);
    end
end