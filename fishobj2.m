classdef fishobj2 < dynamicprops 
% FISHOBJ2
% Central fishobject model.
% 
% Scientific Software Solutions
% Tobias Kieﬂling 05/2016-08/2016
% support@tks3.de

    properties(SetAccess=protected)
    
        impath          @char
        iminfo          @struct
        datapath        @char
        userdir         @char 
        parameterFile   @char 
        imdata          %@uint8
        json            @struct
        enabled         @logical
        pluginGroups    @cell
        pluginCurrentGroup @char
        plugins         @fish_plugin_class
        
    end
    
    properties(Hidden, Constant)
        
        % Directory of the exe file
        exedir          = guitools.getCurrentDir;
        
        % Plugin Constants
        plugin_dir      = fullfile(pwd, 'fish_plugins');
        plugin_pattern  = '*_fishPlugin.m';
        plugin_initFCN  = 'getFishPlugin';
        
        % JSON datafile constants
        file_version    = 0.99;
        datafile_suffix = '__SHAPES.json';
        
    end
    
    properties(Hidden);%, SetAccess=protected)
        
        % Parameter File
        parameterFile_default   = 'FishParameter_default.json';
        parameterFile_dir       = 'parameterFiles';
        parameterFile_pattern   = 'FishParameter_*.json';
        
        requestedPluginList = 'all';
        pluginMetaDynamicProperty = {};
        temp
        lastAction
        
    end
        
    methods(Static)
        % % %
        % Nested active contour function
        function [out, out2] = move2extreme(peakimage, startline, minmax, circular, debug_here, nn)
        % out = move2extreme(peakimage, startline, minmax, circular, debug_here, nn)
        %
        
            max_iter = 100;
            debug_tag = 'move2extreme_debug';
            
            % Default values
            if ~exist('debug_here', 'var')
                debug_here = false;
            end
            if ~exist('nn', 'var')
                nn = 10;
            end
            if ~exist('minmax', 'var')
                minmax = 'max';
            end
            if ~exist('circular', 'var')
                circular = true;
            end
            
            % Moving to minimum is like moving to maximum on an inverted peak image
            if strcmpi(minmax, 'min')
                peakimage = max(peakimage(:))-peakimage;
            end
            % Support 2d startlines
            is2d = sum(size(startline)>1)==2;
            if is2d
                mini_x = min(startline(:,1));
                maxi_x = max(startline(:,1));
                % Cut peakimage and everything down to the size of the contour
                peakimage = peakimage(:, mini_x:maxi_x);
                startline = (startline(:,2))';
                
            end
            if ~circular
                newVal_left  = startline(1);
                newVal_right = startline(end);
            end
            nor = size(peakimage,1);    % Number of rows
            noc = size(peakimage,2);    % Number of columns
            
            out = round(startline);
            out_log = zeros(max_iter, length(startline));
            doMove = true;
            counter = 0;
            
            % Prepare the loop
            % 1) Linear indices of the lower and upper neighbours
            neighbourIDX = ones(2*nn+1, 1) * (1:(length(startline)));
            for i = -nn:nn
                neighbourIDX(i+nn+1, :) = circshift(neighbourIDX(i+nn+1, :), [0, -i]);
            end
            % 2) Linear indices to ascribe non-circular boundary conditions
            if ~circular
                leftIDX = zeros(1, nn^2/2);
                rightIDX = zeros(1, nn^2/2);
                counter = 0;
                for j=1:nn
                    for i = 1 : (nn-j+1)
                        counter = counter + 1;
                        leftIDX(counter) = (j-1).*(2*nn+1) + i;
                        rightIDX(counter) = (length(startline)-j+1-1).*(2*nn+1) + ((2*nn+1)-i+1);
                    end
                end
            end
            % 3) Weights for weighted mean
            weights = (1./exp(abs(-nn:nn)/(2.5*nn)).^2)' * ones(1, length(startline));
                
            % Now we loop
            while doMove
                counter = counter +1;
                out_log(counter, :) = out;

                % % % %
                % 1) Move each point up or down towards min/max
                out(out<3) = 3; out(out>nor-2) = nor-2;
                val = peakimage((0:(noc-1)).*nor + round(out));
                upp_neighbours = peakimage((0:(noc-1)).*nor + round(out-1));
                low_neighbours = peakimage((0:(noc-1)).*nor + round(out+1));
                moveup   = (val<upp_neighbours) & (upp_neighbours>low_neighbours);
                movedown = (val<low_neighbours) & (upp_neighbours<low_neighbours);
                out(moveup)   = out(moveup)   - 1;
                out(movedown) = out(movedown) + 1;
                
                % % % %
                % 2) Now move points towards the center of neighboured points to avoid spikes and have a smoothe edge
                % Get neighbour matrix
                temp = out(neighbourIDX);
                % Fix the endpoints if we're not circular
                if ~circular
                    temp(leftIDX)  = newVal_left;
                    temp(rightIDX) = newVal_right;
                end
%                curveshift = wmean(temp, weights, 1) - temp(nn+1,:);
%                out = (out + curveshift);
                out = wmean(temp, weights, 1);
                
                % % % %
                % Check if we have to move on
                % doMove = any(moveup) || any(movedown) || any(curveshift);
                doMove = doMove && (counter<max_iter);
            end

            if is2d
                out = [(mini_x:maxi_x)',out'];
            end
            out2 = out;
            out = round(out);
            
            % Degugging Display
            if debug_here
                debugFunction();
            end
            
            function debugFunction
                hplot = [];
                peakimage_ = peakimage;
                data = out_log;
                
                % Support for gray scaled peakimages
                if isa(peakimage_, 'double')    
                    if length(unique(peakimage(:)))>50
                        peakimage_ = uint8(peakimage.*255);
                    else
                        peakimage_ = uint8(peakimage);
                    end
                end
                
                % Call the sliderGUI
                [~, ha, ~] = sliderGUI(@(fn, h) updateFrame(fn, h, data), peakimage_, [1, max_iter, 1, 10], debug_tag);
                % ... modify the output
                colormap(ha, 'jet');
                set(ha, 'Clim', [0, max(peakimage_(:))])
                
                function updateFrame(framenumber, handles, out_log)  % Triggered by sliderGUI
                    framenumber = round(framenumber);
                    ydata = out_log(framenumber, :);

                    % Plot / Update Line
                    if isempty(hplot) || ~ishandle(hplot)   % Plot line on first draw or when hplot was deleted
                        ch = findall(handles(2)); 
                        delete(ch(~ismember(get(ch, 'Type'), {'image', 'axes'})));  % Delete old lines
                        hold(handles(2), 'on');
                            hplot = plot(ydata, 'g', 'parent', handles(2), 'LineWidth', 2);
                        hold(handles(2), 'off');
                    else                                    % Update line
                        set(hplot, 'ydata', ydata);
                    end

                    % Plot 
                    set(handles(1), 'name', ['DEBUGGING: move2extreme (step: ', num2str(framenumber), ')'])
                end
            
            end
            
        end
        
        function [cdata, alpha] = getIcon(iconstring)
            
            switch iconstring
                case 'save'
                    alpha = [...
                      113,  144,  204,  238,  250,  254,  255,  255,  255,  255,  255,  255,  239,  203,   84,    0;...
                      155,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  254,  251,  236,   99;...
                      216,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  248;...
                      240,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  254;...
                      250,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      254,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255;...
                      254,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  254;...
                      222,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  237;...
                      143,  181,  238,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  254,  241,  196];

                    cdata = cat(3, [...
                       54,   54,   54,   54,   54,   54,   54,   54,   54,   57,   59,   58,   56,   62,   53,  255;...
                       54,  209,  209,  248,  247,  246,  240,  234,  237,  246,  247,  235,  223,  189,   94,   53;...
                       54,  209,  128,  246,  246,  100,  238,  234,  242,  248,  241,  226,  219,  186,  189,   62;...
                       54,  208,  126,  241,  241,  100,  233,  238,  247,  246,  232,  221,  219,  122,  195,   53;...
                       54,  204,  126,  232,  232,  102,  233,  243,  248,  239,  223,  219,  217,  120,  169,   53;...
                       54,  201,  125,  225,  225,  227,  238,  247,  243,  229,  219,  217,  216,  119,  164,   52;...
                       54,  199,  125,  100,  101,  103,  108,  109,  105,  101,  100,  100,  100,  116,  159,   52;...
                       54,  197,  123,  122,  122,  123,  123,  123,  121,  119,  118,  116,  114,  116,  154,   52;...
                       54,  194,  122,  122,  123,  123,  123,  121,  120,  119,  117,  116,  115,  115,  149,   51;...
                       54,  190,  122,  122,  122,  123,  123,  120,  119,  118,  116,  114,  113,  112,  142,   51;...
                       54,  187,  122,  248,  248,  248,  248,  248,  248,  248,  248,  248,  248,  109,  138,   50;...
                       56,  184,  121,  247,  136,  136,  136,  136,  136,  136,  136,  136,  246,  106,  132,   50;...
                       56,  182,  122,  247,  194,  194,  194,  194,  194,  194,  194,  194,  246,  104,  129,   50;...
                       55,  179,  122,  247,  136,  136,  136,  136,  136,  136,  136,  136,  246,  101,  124,   49;...
                       53,  173,  173,  248,  248,  248,  248,  248,  248,  248,  248,  248,  248,  124,  121,   49;...
                       54,   53,   53,   53,   53,   52,   52,   51,   51,   50,   50,   50,   49,   49,   49,   49],...
                    ...
                     [107,  107,  107,  107,  107,  107,  107,  106,  106,  108,  110,  109,  107,  112,  105,  255;...
                      107,  224,  224,  251,  251,  249,  245,  240,  242,  249,  250,  241,  233,  208,  137,  105;...
                      107,  223,  170,  250,  250,  140,  243,  241,  246,  251,  246,  236,  231,  208,  208,  112;...
                      107,  223,  168,  246,  246,  140,  241,  244,  250,  249,  240,  232,  230,  163,  213,  105;...
                      107,  221,  168,  240,  240,  141,  240,  248,  250,  244,  233,  231,  229,  162,  194,  104;...
                      107,  220,  167,  236,  236,  237,  244,  250,  247,  237,  231,  229,  229,  160,  190,  103;...
                      107,  217,  166,  140,  141,  142,  146,  146,  144,  140,  140,  140,  140,  156,  186,  102;...
                      106,  216,  164,  163,  164,  164,  163,  163,  162,  160,  159,  158,  156,  157,  181,  101;...
                      106,  213,  163,  163,  163,  163,  164,  162,  161,  160,  158,  157,  155,  155,  176,  100;...
                      106,  210,  163,  163,  163,  163,  163,  161,  159,  159,  157,  155,  153,  153,  171,   99;...
                      106,  208,  162,  251,  251,  251,  251,  251,  251,  251,  251,  251,  251,  150,  167,   98;...
                      107,  206,  162,  250,  192,  192,  192,  192,  192,  192,  192,  192,  249,  147,  163,   97;...
                      108,  204,  162,  250,  220,  220,  220,  220,  220,  220,  220,  220,  249,  144,  158,   97;...
                      107,  202,  162,  250,  192,  192,  192,  192,  192,  192,  192,  192,  249,  141,  155,   96;...
                      106,  198,  197,  251,  251,  251,  251,  251,  251,  251,  251,  251,  251,  154,  152,   96;...
                      106,  105,  105,  104,  104,  103,  102,  101,  100,   99,   98,   97,   96,   96,   96,   97],...
                    ...
                     [188,  188,  188,  188,  188,  187,  187,  187,  187,  188,  189,  187,  187,  187,  182,  255;...
                      188,  246,  247,  254,  254,  253,  252,  250,  251,  253,  253,  251,  248,  236,  201,  181;...
                      188,  246,  233,  254,  253,  200,  251,  251,  252,  254,  252,  249,  248,  238,  236,  187;...
                      188,  246,  232,  252,  252,  200,  250,  251,  253,  253,  250,  248,  247,  225,  239,  183;...
                      188,  245,  231,  250,  250,  201,  250,  253,  254,  252,  249,  247,  247,  224,  231,  182;...
                      187,  244,  231,  249,  249,  249,  252,  253,  253,  250,  247,  247,  246,  222,  228,  180;...
                      187,  244,  230,  200,  201,  201,  203,  203,  202,  200,  200,  200,  200,  218,  225,  179;...
                      187,  242,  227,  227,  227,  226,  226,  225,  225,  223,  222,  221,  219,  220,  221,  177;...
                      187,  242,  227,  227,  226,  226,  226,  225,  224,  222,  222,  220,  218,  217,  218,  175;...
                      187,  240,  226,  226,  225,  226,  225,  224,  222,  221,  220,  217,  216,  214,  213,  173;...
                      186,  239,  226,  254,  254,  254,  254,  254,  254,  254,  254,  254,  254,  211,  210,  171;...
                      187,  239,  225,  254,   98,   98,   98,   98,   98,   98,   98,   98,  253,  207,  206,  170;...
                      187,  238,  225,  254,  191,  191,  191,  191,  191,  191,  191,  191,  253,  205,  204,  168;...
                      186,  237,  224,  254,   98,   98,   98,   98,   98,   98,   98,   98,  253,  202,  201,  167;...
                      186,  235,  234,  254,  254,  254,  254,  254,  254,  254,  254,  254,  254,  200,  199,  167;...
                      186,  185,  184,  183,  181,  180,  178,  176,  174,  172,  170,  169,  168,  167,  166,  168]);
                  alpha = alpha./255;  
                  cdata = cdata./255;
                  
                case 'view_on'
                    
                case 'view_off'
            
            end
            
        end
        
        function isEnabled = checkFileIsEnabled(path2file)
           
            % Enabled is true by default
            isEnabled = true;
            
            % Construct path to data file
            suffix = '__SHAPES.json';
            [bpath, file, ~] = fileparts(path2file);
            dpath = fullfile(bpath, [file, suffix]);
            % If the data-file exists, check if enabled is true or false 
            if exist(dpath, 'file')==2
                pat = '"enabled":\s*((true|1)|(false|0))';
                fid = fopen(dpath, 'r');
                found = false;
                while ~feof(fid) && ~found
                    out = regexp(fgetl(fid), pat, 'match');
                    if ~isempty(out)
                        found = true;
                        isEnabled = isempty(strfind(out{1}, 'false')) && isempty(strfind(out{1}, '0'));
                    end
                end
                fclose(fid);
            end
                
        end
        
    end
    
    events
        
        pluginCurrentGroupHasChanged
        parameterFileHasChanged
        processingStart
        processingEnd
        newSelection
        
    end
    
    methods
        
        % % % % % %
        % CONSTRUCTOR
        function obj = fishobj2(im_path, varargin)
            
            % Define UserDirectory and Parameter File
            obj.userdir = fullfile(getenv('Public'), 'FishInspector');
            obj.parameterFile_dir = fullfile(obj.userdir, obj.parameterFile_dir);
            
            if ~exist('im_path', 'var'); im_path = ''; end
            if any(strcmp({'-withPlugins'}, varargin))
                obj.requestedPluginList = varargin{find(strcmp(varargin, '-withPlugins'), 1, 'last')+1};
            end
            
            parameterFile = obj.parameterFile_default;
            if any(strcmp({'-p'}, varargin))
                parameterFile = varargin{find(strcmp(varargin, '-p'),1, 'last')+1};
                if ~(exist(fullfile(obj.parameterFile_dir, parameterFile), 'file')==2)
                    error(['Specified Parameter File Does Not Exist: ', fullfile(obj.parameterFile_dir, parameterFile)])
                end
            end
            set_parameterFile(obj, parameterFile);
            
            % Read plugins from plugin folder
            readPluginGroups(obj);
            if any(strcmp({'-g'}, varargin))
                group = varargin{find(strcmp(varargin, '-g'),1, 'last')+1};
                if ~ismember(group, obj.pluginGroups)
                    error(['Specified Group Does Not Exist: ', group])
                end
                set_pluginCurrentGroup(obj, group);
            elseif ~isempty(obj.pluginGroups)
                set_pluginCurrentGroup(obj, obj.pluginGroups{1});
            else
                initPlugins(obj);
            end
            
            % Set Image file
            obj.set_impath(im_path);
            
        end
        
        function readPluginGroups(obj)
            
            if ~isdeployed
                folder = dir(obj.plugin_dir);
                folder(~[folder.isdir]) = [];
                folder(ismember({folder.name}, {'.', '..'})) = [];
                groups = {};
                % Check if there are m files in the base folder
                if ~isempty(dir(fullfile(obj.plugin_dir, obj.plugin_pattern)))
                        groups{1} = '';
                end
                % Check if there are m files in the folders
                for i = 1 : length(folder)
                    files = dir(fullfile(obj.plugin_dir, folder(i).name, obj.plugin_pattern));
                    if ~isempty(files)
                        groups{end+1} = folder(i).name;
                    end
                end
                obj.pluginGroups = groups;
            else
                obj.pluginGroups = {};
            end
        end
        
        function set_pluginCurrentGroup(obj, group)
            if ~ismember(group, obj.pluginGroups)
                error(['Unknown Group: ', group])
            end
            
            for i = 1 : length(obj.pluginMetaDynamicProperty)
                delete(obj.pluginMetaDynamicProperty{i});
            end
            obj.pluginMetaDynamicProperty = {};
            
            obj.pluginCurrentGroup = group;
            initPlugins(obj, obj.requestedPluginList, group);
            notify(obj, 'pluginCurrentGroupHasChanged');
            drawnow
            obj.set_impath(obj.impath);
        end
            
        function set_impath(obj, impath)
            
            % % % %
            % First, we check if the image file actually exists
            if ~(exist(impath, 'file')==2) && ~isempty(impath)
                impath = '';
                waitfor(msgbox({'The specified imagefile does not exist: ', impath}, 'Error', 'error'));
            end
            
            % % % %
            % Reset temporary field (used in getImdata to cache results)
            obj.temp   = [];
            
            % % % %
            % Set Image path ...
            obj.impath = impath;
            % ... and LOAD it
            obj.imdata = uint8([]);
            obj.iminfo = struct([]);
            if ~isempty(impath)
                obj.imdata = imread(impath);
                obj.iminfo = imfinfo(impath);
            end
            
            % % % %
            % Set Datafile path...
            obj.datapath = constructDatapath(obj.impath, obj.datafile_suffix);
            % ... and LOAD it
            loaddata(obj);
            
            % % % %
            % Reset all previous Results from Plugins
            for i = 1 : length(obj.plugins)
                thisPlugin = obj.plugins(i);
                % Add a dynamic property for this Plugin (if not done yet)
                if ~isprop(obj, thisPlugin.plugin_tag)
                    obj.pluginMetaDynamicProperty{end+1} = addprop(obj, thisPlugin.plugin_tag);
                end
                obj.(thisPlugin.plugin_tag) = [];
            end
            %if obj.enabled
            obj.getAllPluginResults; %... and get the new Results
            %end
            
            function dpath = constructDatapath(impath, suffix)
                
                dpath = '';
                if ~isempty(impath)
                    % Construct datapath from imagepath
                    [bpath, file, ~] = fileparts(impath);
                    dpath = fullfile(bpath, [file, suffix]);
                end
                
            end
            
        end
        
        function set_parameterFile(obj, parameterFileName)
            [bpath, ~, ~] = fileparts(parameterFileName);
            if ~isempty(bpath)
                error('set_parameterFile does only accept file names as input.')
            end
            obj.parameterFile = parameterFileName;
            notify(obj, 'parameterFileHasChanged')
        end
        
        function thisPlugins = initPlugins(obj, requestedPluginList_, group)
            if ~exist('requested', 'var'), requestedPluginList_ = obj.requestedPluginList; end
            if ~exist('group', 'var'), group = ''; end
            
            if ~isdeployed
                % Add plugin folder to MATLAB search path
                groupdir = fullfile(obj.plugin_dir, group);
                addpath(groupdir);

                % Create Plugin directory if it's not there
                if ~(exist(groupdir, 'dir')==7)
                    mkdir(groupdir);
                    winopen(groupdir);
                    msgbox('Created plugin_dir');
                    obj.plugins = [];
                    return
                end

                % Get all plugin files from plugin folder
                files = dir(fullfile(groupdir, obj.plugin_pattern));

                % Initialize all pluginFiles via plugin_initFCN command
                thisPlugins = cell(length(files),1);
                for i = 1 : length(files)
                    try
                        % Get the fish_plugin_class from this file
                        [~, fname, ~] = fileparts(files(i).name);
                        thisPlugin = eval([fname, '(obj, ''', obj.plugin_initFCN, ''')']);
                        thisPlugins{i} = thisPlugin;

                    catch Me
                        % Something went wrong while reading the plugin file :-(
                        disp(Me.getReport);
                        disp(' ');
                        disp('Couldn''t read fishPlugin: ');
                        disp(files(i).name);
                        disp('=>skipping');

                    end
                end
                % Remove empty plugins ...
                thisPlugins(cellfun(@isempty, thisPlugins)) = [];
                thisPlugins = [thisPlugins{:}]; % ...and transform to simple array

                % Sort plugins according to their dependencies
                thisPlugins = fish_plugin_class.sortPlugins(thisPlugins);

                % Create Helper FCN for deployment
                PluginHelperFCN_fileContent = {'function plugins = pluginHelperFCN(fishObj)';...
                                               '% Automatically created Helper-FCN necessary for deployment.';...
                                               '% Do not edit';...
                                               '% 05 - 06/2016';...
                                               '% TobiasKiessling@tks3.de'; ''};
                for i = 1 : length(thisPlugins)
                    [~, fname, ~] = fileparts(thisPlugins(i).sourceFile);
                    PluginHelperFCN_fileContent{end+1} = ['    plugins(', num2str(i), ') = ', fname, '(fishObj, ''', obj.plugin_initFCN, ''');'];
                end
                fid = fopen('pluginHelperFCN.m', 'w');
                fprintf(fid,'%s\n',PluginHelperFCN_fileContent{:});
                fclose(fid);

                % Take only those plugins that are requested
                if isempty(requestedPluginList_) || ~ismember({'all'}, requestedPluginList_)
                list = requestedPluginList_;
                if isempty(list), list = ''; end
                % Inform the user that a request plugin wasn't found
                if ~all(ismember(list, {thisPlugins.plugin_tag}))
                    waitfor(msgbox({'Requested plugin(s) was not found:', ' ', cellstr2list(list(~ismember(list, {thisPlugins.plugin_tag})))}, 'Warning', 'warn'));
                end
                % Remove unnecessary Plugins from the ordered list
                lastID = find(ismember({thisPlugins.plugin_tag}, list), 1, 'last');
                thisPlugins(lastID+1:end) = [];
                end
            
            else
                % When deployed, we can't read the directory and ascribe
                % plugins dynamically :-( We need to have a function that
                % really uses the plugins
                thisPlugins = pluginHelperFCN(obj);
                
            end
            
            % That's it
            if isempty(thisPlugins)
                obj.plugins = obj.plugins([]);
            else
                obj.plugins = thisPlugins;
            end
            
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
        
        function getAllPluginResults(obj, startAt, varargin)
            % % % %
            % Iterate over all Plugins and store results to fishobj...
            if ~exist('startAt', 'var') || isempty(startAt), startAt = obj.plugins(1); end
            startIDX = find(obj.plugins == startAt);
            toProcess = startIDX : length(obj.plugins);
            
            % Feature was enabled/disabled => Create List of features to update
            if any(cellfun(@(x) ischar(x) && strcmpi(x, 'callbackFeatureEnable'), varargin))
                toProcess2 = startIDX;
                changedPlugin = obj.plugins(obj.plugins == startAt);
                changedPluginTags = {changedPlugin.plugin_tag};
                for j = toProcess
                    thisPlugin = obj.plugins(j);
                    if any(ismember(changedPluginTags, thisPlugin.plugin_dependencies))
                        changedPluginTags = [changedPluginTags, thisPlugin.plugin_tag];
                        toProcess2 = [toProcess2, j];
                    end
                end
                toProcess = sort(unique(toProcess2));
            end
            
            for i = startIDX : length(obj.plugins)
                
                % % % %
                % Get this plugin ...
                thisPlugin = obj.plugins(i);
                
                if ismember(i, toProcess)
                    
                    % % % %
                    % Update the fishobj of this plugin to ensure we're getting the right results
                    if ~isempty(obj.impath)
                        thisPlugin.set_fishobj(obj);  
                    end

                    % % % %
                    % Now we can get results from this plugin, and store them to dynamic property
                    obj.(thisPlugin.plugin_tag) = [];
                    if ~isempty(obj.impath)
                        obj.(thisPlugin.plugin_tag) = thisPlugin.getResults('-noWarningMessage', varargin{:});
                    end
                    
                else
                    
                    % This ensures that we have a check everywhere
                    obj.lastAction = struct('Action', 'processingEnd', 'fromFile', false, 'success', ~isempty(thisPlugin.plugin_output), 'Plugin', thisPlugin);
                    notify(obj, 'processingEnd');
                
                end
                
            end
            
            obj.lastAction = struct('Action', 'newSelection', 'Plugin', []);
            notify(obj, 'newSelection');
            
        end
        
        function DrawPlugins(obj, ha, showErrorMessage)
            % % % %
            % Iterate over all Plugins and draw them 
            if ~obj.enabled, return; end
            if ~exist('showErrorMessage', 'var')
                showErrorMessage= false;
            end
            for i = 1 : length(obj.plugins)
                % Get this plugin ...
                thisPlugin = obj.plugins(i);
                % ... draw this plugin to axes ha
                if ~thisPlugin.enabled, continue; end % ...but only if this plugin is enabled
                try
                    if thisPlugin.visible % ...and visible
                        if ~isempty(obj.(thisPlugin.plugin_tag))
                            thisPlugin.mainDrawingFunction(ha, obj.(thisPlugin.plugin_tag));
                        else
                            disp('---------------')
                            disp(['Empty data found in "', thisPlugin.plugin_tag, '"-plugin']);
                        end
                    end
                catch Me
                    if showErrorMessage
                        disp('----------------------');
                        disp(['Error DrawPlugins: Error while executing mainDrawingFunction for ', thisPlugin.plugin_tag]);
                        disp(Me.getReport);

                        waitfor(msgbox({'Error while executing',...
                                       ' ', '    mainDrawingFunction',...
                                       ' ', 'for Plugin: ',...
                                       ' ',['       Name: ', obj.plugins(i).plugin_name],...
                                       ['       Tag:  ', obj.plugins(i).plugin_tag],...
                                       ' ', 'Error:', Me.message,...
                                       ' ', 'Skipping this draw...'}, 'Error', 'warn'));
                    end
                end
            end
            
        end
        
        
        function makeFeaturePanel(obj, hPanel, editStartFCN, editInterfaceReadyFCN, redrawFCN, externalAxes, varargin)
            
            figureCreationArgs = varargin;
            hMarker = {};
            makeButtons();
            
            l1 = addlistener(obj, 'processingStart',              @react2processingEvents);
            l2 = addlistener(obj, 'processingEnd',                @react2processingEvents);
            l3 = addlistener(obj, 'newSelection',                 @react2processingEvents);
            l4 = addlistener(obj, 'pluginCurrentGroupHasChanged', @react2processingEvents);
            
            function cleanupfcn()
                hMarker = {};
                return
                arrayfun(@(x) delete(x), [l1,l2,l3,l4]);
                arrayfun(@(x) clear(x), ['l1','l2','l3','l4']);
            end
            
            function makeButtons()
                nof = length(obj.plugins);  % Number of features
                panel_pos = get(hPanel, 'Position');
                feature_width = panel_pos(3) / nof;
                fpos_x = cumsum([0, repmat(feature_width, 1, nof-1)]);
                border = 0.1;
                hf = ancestor(hPanel, 'figure');
                hbp = [];
                
                % Update Feature Menu
                pMenu = findobj(ancestor(hPanel, 'figure'), 'Tag', 'menu_updateFeature');
                delete(get(pMenu, 'Children'));
                
                for i = 1 : nof
                    
                    hCMenu = uicontextmenu(ancestor(hPanel, 'figure'), 'Callback', @FeaturePanel_contextMenuCallback, 'UserData', obj.plugins(i));
                    uimenu(hCMenu, 'Label', '<Name>', 'Checked', 'off', 'Enable', 'off', 'Tag', 'featureName');
                    uimenu(hCMenu, 'Label', 'Use Feature', 'Checked', 'on', 'Callback', @callbackFeatureEnable,  'UserData', obj.plugins(i));
                
                    uimenu(pMenu, 'Label', obj.plugins(i).plugin_name, 'Callback', @callbackUpdateFeature, 'UserData', obj.plugins(i));
                    
                    [hMarker{i}, mc] = javacomponent('javax.swing.JLabel', [fpos_x(i)+0.5*border*feature_width, 0.3*panel_pos(4), 0.3*panel_pos(4), 0.3*panel_pos(4)], hPanel);
                    set(mc, 'units', 'normalized');
                    
                    hLabel = uicontrol(hPanel, 'Style',     'text',...
                                               'String',    obj.plugins(i).plugin_name,...
                                               'HorizontalAlignment', 'left',...
                                               'FontSize',  10,...
                                               'FontWeight', 'bold',...
                                               'Units',     'Pixel',...
                                               'Position',  [fpos_x(i)+2.1*border*feature_width, (0.35)*panel_pos(4), (1-3*border)*feature_width, (1-3*border)*0.5*panel_pos(4)],...
                                               'UIContextMenu', hCMenu);
                    set(hLabel, 'Units', 'normalized');


    %                 hb = uicontrol(hPanel, 'Style',     'Checkbox',...
    %                                        'String',    '<html><font color="black" size="5">&#x25ba;',...
    %                                        'FontSize',  9,...    
    %                                        'Callback',  @FeaturePanel_editCallback,...
    %                                        'Tooltip',   'Plot Feature',...
    %                                        'Value',     1,...
    %                                        'UserData',  obj.plugins(i),...
    %                                        'Position',  [fpos_x(i)+2.1*border*feature_width+(1-2.4*border)*0.5*panel_pos(4), border*panel_pos(4)+1, 2*(1-4.4*border)*0.5*panel_pos(4), (1-4.4*border)*0.5*panel_pos(4)]);
    %                 set(hb, 'Units', 'normalized');
                    %[hm_, hb] = javacomponent('javax.swing.JLabel', [fpos_x(i)+2.1*border*feature_width+(1-2.4*border)*0.5*panel_pos(4), border*panel_pos(4)+1, 2*(1-4.4*border)*0.5*panel_pos(4), (1-4.4*border)*0.5*panel_pos(4)], hPanel);
                    [hm_, hb] = javacomponent('javax.swing.JLabel', [fpos_x(i)+2.1*border*feature_width, 0.7*border*panel_pos(4), (1-2.4*border)*0.5*panel_pos(4)-9, (1-2.4*border)*0.5*panel_pos(4)], hPanel);
                    setappdata(hb, 'jhandle', hm_);
                    setappdata(hb, 'value', true);
                    set(hb, 'Units',    'normalized',...
                            'UserData', obj.plugins(i),...
                            'UIContextMenu', hCMenu);
                    set(hm_, 'MouseClickedCallback', @(varargin) FeaturePanel_editCallback(hb, varargin{:}));
                    tks3_guitools.hoverEffect(hf, hm_, 'hand', false)
                    %hm_.setText('<html><font color="black" size="5">&#x25ba;');
                    fily = ['file:/', strrep(fullfile(obj.exedir, 'eye-Icon.gif'), '\', '/')];
                    hm_.setText(['<html><img src="', fily, '"/>'])
                    hm_.setToolTipText('Toggle Visibility');

    %                 hbp(i) = uicontrol(hPanel, 'Style',     'Pushbutton',...
    %                                            'String',    'Edit',...
    %                                            'FontSize',  9,...
    %                                            'Callback',  @FeaturePanel_editCallback,...
    %                                            'UserData',  obj.plugins(i),...
    %                                            'Position',  [fpos_x(i)+2.1*border*feature_width, border*panel_pos(4), 1.3*(1-3*border)*0.5*panel_pos(4), (1-3*border)*0.5*panel_pos(4)]);
    %                 set(hbp(i), 'Units', 'normalized');
    %                [hm_, hbp(i)] = javacomponent('javax.swing.JLabel', [fpos_x(i)+2.1*border*feature_width, 1*border*panel_pos(4), 1.3*(1-3*border)*0.5*panel_pos(4), (1-2.4*border)*0.5*panel_pos(4)], hPanel);
                    %[hm_, hbp(i)] = javacomponent('javax.swing.JLabel', [fpos_x(i)+2.1*border*feature_width, 1*border*panel_pos(4), (1-2.4*border)*0.5*panel_pos(4), (1-2.4*border)*0.5*panel_pos(4)], hPanel);
                    [hm_, hbp(i)] = javacomponent('javax.swing.JLabel', [fpos_x(i)+2.1*border*feature_width+(1-2.4*border)*0.5*panel_pos(4), 1.2*border*panel_pos(4)+2, 2*(1-4.4*border)*0.5*panel_pos(4), (1-4.4*border)*0.5*panel_pos(4)], hPanel);
                    setappdata(hbp(i), 'jhandle', hm_);
                    set(hbp(i), 'Units',    'normalized',...
                                'UserData', obj.plugins(i),...
                                'UIContextMenu', hCMenu);
                    set(hm_, 'MouseClickedCallback', @(varargin) FeaturePanel_editCallback(hbp(i), varargin{:}));
                    tks3_guitools.hoverEffect(hf, hm_, 'hand', false)
                    hm_.setText('<html><font color="black" size="6">&#x270e;');
                    hm_.setToolTipText('Edit Feature');


                    if ~isdeployed
                        hb = uicontrol(hPanel, 'Style',     'Pushbutton',...
                                               'String',    'C',...
                                               'FontSize',  9,...    
                                               'Callback',  @FeaturePanel_editSourceCodeCallback,...
                                               'UserData',  obj.plugins(i),...
                                               'Position',  [fpos_x(i)+3.4*border*feature_width+0.5*(1-1.5*border)*feature_width, border*panel_pos(4)+1, 0.25*(1-5*border)*feature_width, (1-4*border)*0.5*panel_pos(4)]);
                        set(hb, 'Units', 'normalized');
                    end

                end

            end

            % Context Menu            
            function FeaturePanel_contextMenuCallback(contextMenu, varargin)
                % Modify Feature Name before context Menu is displayed
                thisPlugin = get(contextMenu, 'UserData');
                set(findobj(get(contextMenu, 'Children'), 'Tag', 'featureName'),...
                    'Label', thisPlugin.plugin_name)
                str = 'off'; if thisPlugin.enabled, str='on'; end
                set(findobj(get(contextMenu, 'Children'), 'Tag', ''),...
                    'Checked', str)
            end
            
            function callbackFeatureEnable(contextMenu, varargin)
                % Set Plugin State
                thisPlugin = get(contextMenu, 'UserData');
                fromFile = ~isempty(obj.json);
                switch upper(get(contextMenu, 'Checked'))
                    case 'ON'
                        % Switch to OFF
                        set(contextMenu, 'Checked', 'Off')
                        thisPlugin.wasEnabled = false;
                        
                    case 'OFF'
                        % Switch to ON
                        set(contextMenu, 'Checked', 'On')
                        thisPlugin.wasEnabled = true;
                        
                end
                
                % Update Object Results
                getAllPluginResults(obj, thisPlugin, [], 'callbackFeatureEnable')
                % Update json File if it's there
                if fromFile
                    obj.json.(thisPlugin.plugin_tag) = thisPlugin.plugin_output;
                    obj.savedata;
                end
                
                % Update GUI
                redrawFCN();
            end
            
            function callbackUpdateFeature(contextMenu, varargin)
                plugin = get(contextMenu, 'UserData');
                
                
                force_new_calculation = true;
                
                % Store Result back to dynamic property of the fishobject
                obj.(plugin.plugin_tag) = plugin.getResults(force_new_calculation, varargin{:});
                
                % % %
                % Update all dependent features
                if any(strcmpi(varargin, '-UpdateDependent'))
                    [~, depTree] = fish_plugin_class.sortPlugins(obj.plugins);
                    pnames = fieldnames(depTree);
                    pnames = pnames(cellfun(@(x) ismember(plugin.plugin_tag, depTree.(x)), pnames));
                    depFeatures = obj.plugins(ismember({obj.plugins.plugin_tag}, pnames));
                    if ~isempty(depFeatures)
                        hwait = waitbar(0, '', 'name', 'Updating dependent features'); 
                    end
                    for i = 1 : length(depFeatures)
                        if ishandle(hwait)
                            waitbar(i/(length(depFeatures)+1), hwait, ['Updating:    "', depFeatures(i).plugin_name, '"     (', num2str(i), ' of ', num2str(length(depFeatures)), ')']);
                        else
                            % User has closed the waitbar => stop processing
                            break
                        end
                        if depFeatures(i).fish ~= obj
                            depFeatures(i).set_fishobj(obj);
                            error('h‰‰‰?');
                        end
                        obj.(depFeatures(i).plugin_tag) = depFeatures(i).getResults(force_new_calculation, varargin{:}); % Recalculate with force_new_calculation
                    end
                end
                
                % Save again to JsonFile
                obj.savedata;
                
                % Clean up
                try delete(hwait); end
                disp('OK');
            end
            
            % Source Code Button (In debug mode only)
            function FeaturePanel_editSourceCodeCallback(btn_handle, varargin)
                % Get plugin associated with this button
                thisPlugin = get(btn_handle, 'UserData');
                edit(thisPlugin.sourceFile);
            end

            % Visibility/Edit button
            function FeaturePanel_editCallback(btn_handle, varargin)
                
                % Get plugin associated with this button
                jhandle = getappdata(btn_handle, 'jhandle');
                thisPlugin = get(btn_handle, 'UserData');
                isSubstitute = isappdata(btn_handle, 'value');
                button = varargin{2}.getButton;
                if jhandle.isEnabled && button==1
                    if ~thisPlugin.enabled, return; end
                    % Toggle Plugin Visibility
                    if isSubstitute || (isprop(btn_handle, 'Style') && ismember(btn_handle.Style, {'checkbox', 'togglebutton'}))
                        if isSubstitute
                            value = ~getappdata(btn_handle, 'value');
                            setappdata(btn_handle, 'value', value);
                        else
                            value = btn_handle.Value;
                        end
                        thisPlugin.visible = value;
                        switch value 
                            case 1
                                %set(btn_handle, 'String', '<html><font color="black" size="5">&#x25ba;');
                                fily_ = ['file:/', strrep(fullfile(obj.exedir, 'eye-Icon.gif'), '\', '/')];
                                jhandle.setText(['<html><img src="', fily_, '"/>'])

                            case 0
                                %set(btn_handle, 'String', '<html><font color="gray" size="5">&#x25ba;');
                                fily_ = ['file:/', strrep(fullfile(obj.exedir, 'eye-dash-Icon.gif'), '\', '/')];
                                jhandle.setText(['<html><img src="', fily_, '"/>'])

                        end
                        redrawFCN();
                        return
                    end
                
                    % Create User Interface
                    feval(editStartFCN, thisPlugin);
                    handles = thisPlugin.GUIcreationFCN(externalAxes, figureCreationArgs{:});
                    % Add Save Parameter set button
                    if ~isempty(thisPlugin.plugin_parameter)
                        fnames = fieldnames(handles);
                        btn = handles.(fnames{find(cellfun(@(x) ~isempty(strfind(x, 'pushbutton_decrease')),fnames), 1, 'first')});
                        [cdata, ~] = fishobj2.getIcon('save');
                        new_button = uicontrol(btn.Parent, 'Style', 'pushbutton',...
                                                           'Position', [handles.uipanelParameterControl.Position(3)-btn.Position(3), 0.1*btn.Position(3), 0.8.*btn.Position(3:4)],...
                                                           'Tooltip',  'Store as default to parameter file',...
                                                           'Callback',  @storeParametersAsDefault,...
                                                           'CData',     cdata,...
                                                           'UserData',  thisPlugin);
                    end
                    feval(editInterfaceReadyFCN, handles.figure1, thisPlugin)

                    % Update drawing of current fish when edit is closed
                    addlistener(handles.figure1, 'ObjectBeingDestroyed', redrawFCN);
                elseif button==3
                    % Let The CotextMenu appear
                    feval(get(get(btn_handle, 'UIContextMenu'), 'Callback'), get(btn_handle, 'UIContextMenu'));
                    set(get(btn_handle, 'UIContextMenu'),...
                                        'Position', get(ancestor(btn_handle, 'figure'), 'CurrentPoint'),...
                                        'Visible', 'on')
                end
            end
            
            function storeParametersAsDefault(btn_handle, varargin)
                
                % Get plugin associated with this button
                thisPlugin = get(btn_handle, 'UserData');
                
                % Create new parameterCell with current Parameters as default
                newParameter = thisPlugin.parameterClassObject.ParameterValues;
                parameterCell = thisPlugin.plugin_parameter;
                parameterCell(:,4) = cellfun(@(x) newParameter.(x), parameterCell(:,1), 'Uniform', 0);
                
                % Overwrite auto parameters
                parameterCell(:,8) = repmat({false}, size(parameterCell,1),1);
                
                processDefaultParameterFile(thisPlugin, parameterCell, true);
                h = msgbox({'Stored parameter to', ' ', ['      "', thisPlugin.fish.parameterFile, '"      .'], ' '}, 'Info');
                WinOnTop(h);
                set(h, 'WindowStyle', 'modal');
                waitfor(h);
                setappdata(ancestor(btn_handle, 'figure'), 'isDirty', true);
            end
            
            function react2processingEvents(thisFO, eventData)
                
                thisPlugin = thisFO.lastAction.Plugin;
                hm = [];
                if ~isempty(thisPlugin)
                    %if (length(hMarker) ~= length(thisFO.plugins)), return; end % fishobj is restructuring due to switching of feature set -> ignore event
                    hm = hMarker{thisFO.plugins == thisPlugin};
                    %if ~ishandle(hm), return; end % object was deleted
                end
                
                switch eventData.EventName
             
                    case 'processingStart'

                        % We don't update Icons for processing if we're reading from file
                        if thisFO.lastAction.fromFile, return; end
                        
                        % Display loader.gif
                        file = ['file:/', strrep(fullfile(obj.exedir, 'loader.gif'), '\', '/')];
                        hm.setText(['<html><img src="', file, '"/>'])
                        
                        % Remove all Markers from subsequent plugins (because they're not processed yet)
                        for j = (find(thisFO.plugins == thisPlugin, 1, 'first')+1):length(thisFO.plugins)
                            if thisFO.plugins(j).enabled
                                hMarker{j}.setText('');
                            else
                                % Indicate this plugin as diabled
                                hMarker{j}.setText('<html><font color="orange" size="7">&#x25E9;</font>') 
                            end
                        end
                        drawnow;
                        
                    case 'processingEnd'
                        if thisFO.lastAction.success && thisPlugin.enabled
                            % Display green check on success
                            hm.setText('<html><font color="green" size="6">&#10004;</font>')
                        else
                            if ~thisFO.enabled
                                % Display nothing
                                hm.setText('')
                            else
                                if ~thisPlugin.enabled
                                    % Indicate this plugin as diabled
                                    hm.setText('<html><font color="orange" size="7">&#x25E9;</font>')
                                else
                                    % Display red cross if something went wrong
                                    hm.setText('<html><font color="red" size="6">&#x2717;</font>')
                                end
                            end
                        end                        
                        % Don't redraw if we're reading from file
                        if ~thisFO.lastAction.fromFile, return; end
                        drawnow;
                      
                    case 'newSelection'
                        ch = findobj(hPanel, '-property', 'Enable');
                        if ~thisFO.enabled 
                            % Disable all plugin buttons
                            set(ch, 'Enable', 'off')
                            ch2 = findobj(hPanel);
                            ch2(ismember(ch2, [ch; hPanel])) = [];
                            for ii = 1 : length(ch2)
                                thisCH = get(ch2(ii), 'JavaPeer');
                                thisCH.setEnabled(false);
                            end
                        else
                            set(ch, 'Enable', 'on')
                            ch2 = findobj(hPanel);
                            ch2(ismember(ch2, [ch; hPanel])) = [];
                            for ii = 1 : length(ch2)
                                thisCH = get(ch2(ii), 'JavaPeer');
                                thisCH.setEnabled(true);
                            end
                        end
                       
                    case 'pluginCurrentGroupHasChanged'
                        delete(findall(hPanel, 'parent', hPanel));
                        cleanupfcn();
                        makeButtons(); 
                        
                    otherwise
                        error('h‰‰?')
                end
            end
        end
            
        function popup = makeParameterFilePanel(obj, hPanel, externalSelectionChangedCallback)
            if ~exist('externalSelectionChangedCallback', 'var')
                externalSelectionChangedCallback = [];
            end
            insertToToolbar = false;
            
            if insertToToolbar
                hf = ancestor(hPanel, 'figure'); set(hf, 'visible', 'on');
                hToolbar = findall(hf,'tag','uitoolbar1');
                jToolbar = get(get(hToolbar,'JavaContainer'),'ComponentPeer');
                if ~isempty(jToolbar)
                   actions = {'a', 'b', 'c'};
                   jCombo = javax.swing.JComboBox(actions(end:-1:1));
                   set(jCombo, 'ActionPerformedCallback', @callback_parameterPopup);
                   jToolbar(1).add(jCombo,3); %3rd position, after printer icon
                   jToolbar(1).repaint;
                   jToolbar(1).revalidate;
                end

                popup = (jCombo);
            
            else
            
                panel_pos = get(hPanel, 'Position');
                offset_x = 0.05*panel_pos(3);
                offset_y = -.2*panel_pos(4);
                popup_width  = 0.9*panel_pos(3);
                popup_height = 0.8*panel_pos(4);

                popup = uicontrol(hPanel.Parent, 'Style', 'popupmenu',...
                                                 'units', get(hPanel, 'Units'),...
                                                 ...'position', [offset_x, offset_y, popup_width, popup_height],...
                                                 'position', get(hPanel, 'Position'),...
                                                 'FontSize', 9,...
                                                 'Callback', @callback_parameterPopup);
                                             
            end
            set(hPanel, 'visible', 'off');
            addlistener(obj, 'parameterFileHasChanged', @updateSelection);
            updateParameterPopup();
            
            function updateSelection(varargin)
                parameterFiles = get(popup, 'String');
                currentFile = obj.parameterFile;
                if ~ismember(currentFile, parameterFiles)
                    updateParameterPopup()
                else
                    set(popup, 'Value', find(strcmp(parameterFiles, currentFile), 1, 'first'));
                end
                
            end
            
            function updateParameterPopup()
                parameterFiles = dir(fullfile(obj.parameterFile_dir, obj.parameterFile_pattern));
                parameterFiles = arrayfun(@(x) x.name, parameterFiles, 'UniformOutput', 0);
                
                currentFile = obj.parameterFile;
                if ~ismember(currentFile, parameterFiles)
                    parameterFiles{end+1} = currentFile;
                    parameterFiles = sort(parameterFiles);
                end
                
                parameterFiles{end+1} = '<HTML><i>Edit File...</i></html>';
                parameterFiles{end+1} = '<HTML><i>Open Directory...</i></html>';
                parameterFiles{end+1} = '<HTML><i>Rescan Directory...</i></html>';
                parameterFiles{end+1} = '<HTML><i>Create New Parameter File...</i></html>';
                
                selIDX = find(strcmp(regexprep(parameterFiles, '<.*?>',''), currentFile));
                switch class(popup)
                    
                    case 'javax.swing.JComboBox'
                        % This is a popupmenu in the toolbar
                        popup.removeAllItems;
                        for i = 1 : length(parameterFiles)
                            popup.addItem(parameterFiles{i})
                        end
                        popup.setMaximumSize(java.awt.Dimension(popup.getPreferredSize().width,...
                                                                popup.getPreferredSize().height))
                        popup.setSelectedIndex(selIDX);
                        
                    otherwise
                        set(popup, 'String', parameterFiles, 'Value', selIDX);
                        
                end
            end
            
            function callback_parameterPopup(varargin)
                
                % Get Popupstring
                switch class(popup)
                    
                    case 'javax.swing.JComboBox'
                        % This is a popupmenu in the toolbar
                        popupstring = popup.getSelectedItem;
                        
                    otherwise
                        popupstring = regexprep(popup.String{popup.Value}, '<.*?>','');
                
                end
                
                % Process selection
                switch popupstring
                   
                    case 'Edit File...'
                        winopen(fullfile(obj.parameterFile_dir, obj.parameterFile))
                        obj.set_parameterFile(obj.parameterFile);  % Restore popup selection
                        
                    case 'Open Directory...'
                        winopen(obj.parameterFile_dir)
                        obj.set_parameterFile(obj.parameterFile);  % Restore popup selection
                        
                    case 'Rescan Directory...'
                        updateParameterPopup;
                        notify(obj, 'parameterFileHasChanged')
                        if ~isempty(externalSelectionChangedCallback)
                            externalSelectionChangedCallback();
                        end
                        
                    case 'Create New Parameter File...'
                        prompt={'Name of the new parameter set'};
                        name='Create New Parameter File';
                        numlines=1;
                        defaultanswer ='newSet'; idx = 2; defaultanswer_ = defaultanswer; while exist(fullfile(obj.parameterFile_dir, strrep(obj.parameterFile_pattern, '*', defaultanswer_)), 'file')==2, defaultanswer_ = [defaultanswer, num2str(idx)]; idx = idx + 1; end; defaultanswer = defaultanswer_;
                        answer=inputdlg(prompt,name,numlines,{defaultanswer});
                        if ~isempty(answer)
                            answer = strrep(obj.parameterFile_pattern, '*', answer);
                            answer = answer{1};
                            obj.set_parameterFile(answer);  % Set new file as popup selection
                            if ~isempty(externalSelectionChangedCallback)
                                externalSelectionChangedCallback();
                            end
                        else
                            % Canceled
                            obj.set_parameterFile(obj.parameterFile);   % Restore popup selection
                        end
                        
                    otherwise
                        % A parameter file was selected
                        obj.set_parameterFile(popupstring)  % inject new selected parameter file
                        if ~isempty(externalSelectionChangedCallback)
                            externalSelectionChangedCallback();
                        end
                end
            end
            
        end

        
        
        function savedata(obj)
            
            % % % %
            % Build the JSON FILE
            % - JSON HEADER
            hl = 2; % Header length
            jsonout = cell(length(obj.plugins)+hl, 2);
            jsonout(1,:) = {'version',   obj.file_version}; % # Header 1
            jsonout(2,:) = {'enabled',   obj.enabled};      % # Header 2
            
            % - GATHER RESULTS from all plugins
            toRemove = [];
            for i = 1 : length(obj.plugins)
                thisPlugin = obj.plugins(i);
                if thisPlugin.wasEnabled && thisPlugin.enabled
                    jsonout(i+hl, :) = {thisPlugin.plugin_tag, obj.(thisPlugin.plugin_tag)};
                else
                    toRemove = cat(1, toRemove, i+hl);
                end
            end
            jsonout(toRemove, :) = [];
            jsonout = jsonout'; 
            json_ = struct(jsonout{:});
            % - Make sure we're not deleting anything (except for available plugin fields) from the original JSON file
            if isempty(obj.json), obj.json = struct(); end
            jFields = fieldnames(obj.json);
            obj.json = rmfield(obj.json, jFields(ismember(jFields, {obj.plugins.plugin_tag})));
            json_ = mergestruct(obj.json, json_);
            fnames = fieldnames(json_);
            for i = 1 : length(fnames)
                if isempty(json_.(fnames{i}))
                    json_ = rmfield(json_, fnames{i});
                end
            end
            
            % % % %
            % Save it
            savejson('', json_, struct('FileName', obj.datapath, 'SingletArray', 0));
            % And directly set the json property to keep this object up to date
            obj.json = json_;
            
        end
        
        function loaddata(obj)
        
            obj.json = struct([]);
            obj.enabled = true;
            
            if exist(obj.datapath, 'file')
                
                % % % %
                % Load the associated json file
                obj.json = loadjson(obj.datapath);
                obj.json = replaceCellsInStruct(obj.json);
                
                if isfield(obj.json, 'enabled')
                    obj.enabled = logical(obj.json.enabled);
                end
            end
            
            function struct_out = replaceCellsInStruct(struct_in)
                % % %
                % Transform cell arrays of structs to arrays of structs if possible
                struct_out = struct_in;
                for i = 1: length(struct_in)
                    fnames = fieldnames(struct_in(i));
                    %fnames = fnames(cellfun(@(x) iscell(struct_in(i).(x)), cellstr(fnames)));
                    for j = 1 : length(fnames)
                        if iscell(struct_in(i).(fnames{j}))
                            try %#ok<TRYNC>
                                struct_out(i).(fnames{j}) = [struct_in(i).(fnames{j}){:}];
                                if iscell(struct_out(i).(fnames{j}))
                                    struct_out(i).(fnames{j}) = [struct_out(i).(fnames{j}){:}];
                                end
                            end
                        end
                        if isstruct(struct_in(i).(fnames{j}))
                            struct_out(i).(fnames{j}) = replaceCellsInStruct(struct_in(i).(fnames{j}));
                        end
                    end
                end
                        
            end
            
        end
       
        
        % % % % % %
        % Basic image processing
        function data = getImdata(obj, varargin)
            
            data = obj.imdata;
            if length(varargin)>=1 && (isnumeric(varargin{1}) || islogical(varargin{1}))
                data = varargin{1};
                varargin = varargin(2:end);
            end
            
            for i = 1 : length(varargin)
                
                switch varargin{i}
                    
                    case 'smooth'
                        averWindSize = varargin{i+1};
                        smooth = fspecial('disk', max(floor(averWindSize/2),1));
                        data = imfilter(data, smooth, 'conv', 'symmetric');
                    
                    case 'invert'
                        maxi = 1;
                        if isa(data, 'uint8'), maxi = 255; end
                        data = maxi-data;
                        
                    case 'toGray'
                        if size(data, 3) == 3
                            data = rgb2gray(data);
                        end
                     
                    case 'normalizeColumn'
                        wasUint8 = false;
                        if isa(data, 'uint8')
                            wasUint8 = true; 
                            data = double(data);
                        end
                        
                        for ii = 1 : size(data,3)
                            % Normalize column-wise using 5%/95% of sorted dynamic range as min & max
                            As = sort(data(:,:,ii),1);
                            capilary_lower = zeros(1, size(data,2));%
%                             capilary_lower = As( ceil(0.05 * size(data,1)), :);
%                             capilary_lower = polyval(polyfit(1:size(data,2), capilary_lower, 1), 1:size(data,2));
                            maxi = As(floor(0.95 * size(data,1)), :);
                            maxi = polyval(polyfit(1:size(data,2), maxi,3), 1:size(data,2));
                            A = data(:,:,ii) -  repmat(capilary_lower, size(data,1), 1);
                            A = A ./ repmat(maxi-capilary_lower, size(data,1), 1);
                            A(A>1)=1;   % Cut off high
                            A(A<0)=0;   % and low values
                            data(:,:,ii) = A;
                        end
                        
                        if wasUint8
                            data = uint8(data.*255);
                        end
                        
                    case 'normalize'
                        wasUint8 = false;
                        if isa(data, 'uint8')
                            wasUint8 = true; 
                            data = double(data);
                        end
                        wasUint16 = false;
                        if isa(data, 'uint16')
                            wasUint16 = true; 
                            data = double(data);
                        end
%                         cutoff_ = 0.00;
%                         for ii = 1 : size(data,3)
%                             tempi = data(:,:,ii);
%                             vals = sort(tempi(:));
%                             mini = vals(max(1, ceil(cutoff_*sum(~isnan(vals)))));
%                             maxi = vals(min(length(vals), ceil((1-cutoff_)*sum(~isnan(vals)))))-mini;
%                             data(:,:,ii) = (tempi - mini)./maxi;
%                         end
                        for ii = 1 : size(data,3)
                            tempi = data(:,:,ii);
                            mini = min(tempi(:));
                            maxi = max(tempi(:))-mini;
                            data(:,:,ii) = (tempi - mini)./maxi;
                        end
                        
                        data(isnan(data)) = 0;
                        data(data<0) = 0;
                        data(data>1) = 1;
                        if wasUint8
                            data = uint8(data.*255);
                        end
                        if wasUint16
                            data = uint16(data.*65535);
                        end
                        
                    case 'canny'
                        data = edge(data, 'canny');
                        
                    case 'median'
                        s = floor(0.05*size(data,1));
                        for ii = 1 : size(data,3)
                            data(:,:,ii) = medfilt2(data(:,:,ii), [s,s]);
                        end
                        
                    case 'subtractBackground'
                        if false% isfield(obj.temp, 'removedBackground')
                            data = obj.temp.removedBackground;
                            
                        else
                            wasUint8 = false;
                            if isa(data, 'uint8')
                                wasUint8 = true; 
                                data = double(data);
                            end
    %                         % see http://de.mathworks.com/help/images/examples/correcting-nonuniform-illumination.html
    %                         %data = obj.getImdata(data, 'smooth', 0.01*size(data,1));
    %                         for ii = 1 : size(data,3)
    %                             data(:,:,ii) = imtophat(data(:,:,ii), strel('disk', ceil(0.4*size(data,1))));
    %                         end
    %                         
    %                         data = obj.getImdata(data, 'normalize');

                            processing_height = 150;                        
                            data_temp = double(data);
                            data_orig = data_temp;

                            scaling = processing_height .* [1, size(data_temp,2)/size(data_temp,1)];
                            sf = scaling ./ size(data_temp);

                            % Generate scaled capillary mask
                            data_scaled = imresize(data_temp, scaling); 
                            data_scaled = imfilter(data_scaled, fspecial('gauss', 5,5));
                            data_scaled(:, [1:5,end-4:end])=NaN; data_scaled([1:5,end-4:end], :)=NaN;
                            cp = obj.capillary.shape;
                            namy = {cp.name};
                            cmask = poly2mask( sf(1).*[1:size(data_temp,2), size(data_temp,2):-1:1],...
                                               sf(2).*[cp(strcmp(namy, 'upper')).y, cp(strcmp(namy, 'lower')).y(end:-1:1)],...
                                               size(data_scaled, 1), size(data_scaled, 2));
                            [x,y]=meshgrid(-4:4,-4:4);se = (x.^2+y.^2)<25;
                            cmask = imdilate(cmask, se);

                            % Indicate inner capillary pixels as missing values
                            data_scaled(cmask) = NaN;

                            % Interpolate missing values and resize to original size
                            interpolated_background = imresize(inpaintn(data_scaled, 10), size(data_orig), 'bicubic');
                            interpolated_background = medfilt2(uint8(interpolated_background), [5,5]);

                            % Remove Background
                            interpolated_background(interpolated_background==0) = 1;
                            cleanData = data_temp./double(interpolated_background);
                            %data = mean(cat(3, cleanData, im2double(uint8(data_temp))), 3);
                            data = cleanData;
                            %data = obj.getImdata(data, 'normalize');

%                             data_scaled = imresize(cleanData, scaling);
%                             data_scaled(imdilate(~im2bw(data_scaled, graythresh(data_scaled)), se)) = NaN;
%                             data_scaled = inpaintn(data_scaled, 10);
%                             data_scaled = imresize(data_scaled, size(data_orig), 'bicubic');
%                             data_scaled(data_scaled==0) = min(data_scaled(data_scaled(:)~=0));
%                             cleanData = cleanData./data_scaled;
                            
                            if wasUint8
                                data = uint8(data.*255);
                            end
                            obj.temp.removedBackground = data;
                        end
                        
                    case 'removeCapillary'
                        %%
                        wasUint8 = false;
                        if isa(data, 'uint8')
                            wasUint8 = true; 
                            data = double(data);
                        end
                        se = true(5);
                        data_temp = data;
                        sf = [1,1];
                        cp = obj.capillary.shape;
                        namy = {cp.name};
                        cmask = poly2mask( sf(1).*[1:size(data_temp,2), size(data_temp,2):-1:1],...
                                           sf(2).*[cp(strcmp(namy, 'upper')).y, cp(strcmp(namy, 'upper_in')).y(end:-1:1)],...
                                           size(data_temp, 1), size(data_temp, 2));
                        cmask = imdilate(cmask, se);
                        data_temp(cmask) = NaN;
                        cmask = poly2mask( sf(1).*[1:size(data_temp,2), size(data_temp,2):-1:1],...
                                           sf(2).*[cp(strcmp(namy, 'lower')).y, cp(strcmp(namy, 'lower_in')).y(end:-1:1)],...
                                           size(data_temp, 1), size(data_temp, 2));
                        cmask = imdilate(cmask, se);
                        data_temp(cmask) = NaN;
                        
                        % %
                        data_temp = inpaintn(data_temp, 100);
                        
                        if wasUint8
                            data_temp = uint8(data_temp);
                        end
                        data = data_temp;
                        
                    case 'getInner'
                        wasUint8 = false;
                        if isa(data, 'uint8')
                            wasUint8 = true; 
                            data = double(data);
                        end
                        
                        % inner
                        cp = obj.capillary.shape;
                        namy = {cp.name};                       
                        middle =    (cp(strcmp(namy, 'upper_in')).y + cp(strcmp(namy, 'lower_in')).y)./2;
                        %len    = abs(cp(strcmp(namy, 'upper_in')).y - cp(strcmp(namy, 'lower_in')).y);
                        len =  mean(cp(strcmp(namy, 'lower_in')).y - cp(strcmp(namy, 'upper_in')).y);
                        width = floor(min(len)/2);

                        % outer
                        % middle = (CapillaryCoords.upper+CapillaryCoords.lower)./2;
                        % len = abs(CapillaryCoords.upper-CapillaryCoords.lower);
                        % width = floor(max(len)/2);


                        x_coords = repmat(1:size(data,2), 2*width+1, 1);
                        y_coords = repmat(middle, 2*width+1, 1) + repmat((-width:width)', 1, size(middle,2));
                        data2 = [];
                        waslogical = false;
                        if islogical(data), data=single(data); waslogical = true; end
                        for ii = 1 : size(data,3)
                            data2 = cat(3, data2, interp2(data(:,:,ii), x_coords, y_coords, 'cubic'));
                        end
                        
                        if ~waslogical
                            data = obj.getImdata(data2, 'normalize');
                        else
                            data = logical(data2);
                        end
                        if wasUint8
                            data = uint8(data.*255);
                        end
                
                    case 'colorDecompose'
                        data0 = obj.getImdata(double(data), 'normalize');
%                         data1 = rgb2ntsc(data0);     % hsv:3d    lab:1d  ycbr:1d ntsc:1d
%                         data1 = data1(:,:,1).^2;
%                         data2 = rgb2hsv(data0);     % hsv:3d    lab:1d  ycbr:1d ntsc:1d
%                         data2 = data2(:,:,3).^2;
%                         data3 = rgb2lab(data0);     % hsv:3d    lab:1d  ycbr:1d ntsc:1d
%                         data3 = data3(:,:,1).^2;
%                         data4 = rgb2ycbcr(data0);     % hsv:3d    lab:1d  ycbr:1d ntsc:1d
%                         data4 = data4(:,:,1).^2;
%                         
%                         data = prod(cat(3, data1, data2, data3, data4), 3);
                        
                        data = rgb2hsv(data0);
                        data = obj.getImdata(data(:,:,3), 'invert', 'normalizeColumn') + obj.getImdata(data(:,:,2), 'normalizeColumn');
                        %data = obj.getImdata(data(:,:,2), 'normalizeColumn');
                        data = obj.getImdata(data, 'normalize');
                        
                    case 'getBinaryFish'
                        maxshift = 5; 
                        gthresh_factor = 0.35;
                        close_disksize = 5;
                        
                        % Get bw image
                        data = obj.getImdata(data, 'toGray', 'getInner','normalizeColumn', 'invert');
                        data = obj.getImdata( double(data), 'normalize');
                        data = im2bw(data, gthresh_factor*graythresh(data));
                        
                        % Remove capillary (All white border pixels with less than maxshift pixels are removed)
                        leni_u = zeros(1, size(data, 2));   leni_l = zeros(1, size(data, 2));
                        addi_u = true(size(leni_u));        addi_l = true(size(leni_u));
                        for ii = 1 : maxshift
                            has_entry = (data(ii,:)>0);
                            addi_u(~has_entry) = false;
                            leni_u = leni_u + has_entry;

                            has_entry = (data(end-ii+1,:)>0);
                            addi_l(~has_entry) = false;
                            leni_l = leni_l + has_entry;
                        end
                        remove_u = leni_u < maxshift; addi_u = true(size(leni_u));
                        remove_l = leni_l < maxshift; addi_l = true(size(leni_l));
                        for ii = 1 : maxshift
                            has_entry = (data(ii,:)>0);
                            addi_u(~has_entry) = false;
                            data(ii, remove_u & addi_u & has_entry) = 0;

                            has_entry = (data(end-ii+1,:)>0);
                            addi_l(~has_entry) = false;
                            data(end-ii+1, remove_l & addi_l & has_entry) = 0;
                        end
                        
                        % Get biggest region
                        label = bwlabel(data);
                        props = regionprops(label);
                        idx = find([props.Area] == max([props.Area]), 1, 'first');
                        data(label == idx) = 4;
                        data(data) = 15;
                        
                        % Fill holes
                        data = label == idx;
                        data = bwfill(data, 'holes');
                        data = imclose(data, strel('disk', close_disksize));
                        data = bwfill(data, 'holes');
                    
                    case 'getNotochord'
                        
                end
                
            end
            
        end

        
    end
    
end