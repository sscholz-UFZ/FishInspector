function files_out = findfiles(bpath, filter)
% FINDFILES(bpath, filter)
% Recursively search folder for files
%
% Scientific Software Solutions
% Tobias Kieﬂling 01/2013-06/2016
% support@tks3.de

    if ~exist('filter', 'var')
        filter = '';
    end

    if ~exist('bpath', 'var')
        bpath = 'C:\Users\tobi\Documents\Freelancer\UFZ\data\';
    end

    % Some global waitbar variables (needed for recursive folder scanning)
    waitbar_string = cell(3,1);  % 1: Base, 2: Folder, 3: File
    waitbar_string{1} = ['Base: ', bpath];
    counti = 0;                  % Global waitbar counter [0,1]
    scannedFiles = 0;            % Global counter for displaing scanned files
    waitdiv = 0.9;               % Scanning direcory 90% of the job. The rest is for the rest

    % Search for files
    files_out = FindImageFiles(bpath);
    myWaitbar('delete');
        
    % % % % %
    % Recursive Search for Image Files
    function [files] = FindImageFiles(bpath, files)
        if ~exist('files', 'var'), files = {}; end
        
        % Read dir
        waitbar_string{2} = ['Folder: ', bpath((length(waitbar_string{1})-5):end), '\'];
        fily = dir(bpath);  % but we don't care about . and ..
        fily(ismember({fily.name}, {'.', '..'})) = [];
        
        if ~isempty(fily)
            % Adjust waitbar increment
            waitdiv = waitdiv / length(fily);

            for j = 1 : length(fily)

                scannedFiles = scannedFiles + 1;
                
                if fily(j).isdir
                    % Recursively call this function with this directory
                    files = FindImageFiles(fullfile(bpath, fily(j).name), files);
                else
                    waitbar_string{3} = ['File: ', fily(j).name];
                    counti = counti + waitdiv;
                    myWaitbar(counti, waitbar_string, 'Scanning for Image files...');
                    % This is a file. Let's see if it matches our condition
                    if isempty(filter) || ~isempty(strfind(fily(j).name, filter))
                        files = cat(2, files, fullfile(bpath, fily(j).name));
                    end
                end

            end

            waitdiv = waitdiv * length(fily);
        end
    end


    % % % % %
    % Advanced waitbar implementation
    function myWaitbar(state, string, title)
        persistent h
        persistent t
        persistent getState
        persistent setState
        updateIntervall = 0.25;
        
        if strcmpi('delete', state)
            if ishandle(h), delete(h); end
            if isa(t, 'timer'), if strcmp(get(t, 'Running'), 'on'), stop(t); end; delete(t); clear('t'); end
            return
        end
            
        if ~isa(t, 'timer')
            % Initialize timer (only on first run)
            t = timer;
            set(t, 'StartDelay', updateIntervall);
        end
        
        if isempty(h) || ~ishandle(h)
            %disp('creating');
            % Only on first run, or when figure was closed by the user
            h = waitbar(state, cellfun(@(str) regexprep(str, '\', '-'), string, 'UniformOutput', 0), 'Name', title, 'Visible', 'off');
            getState = @(string_) getappdata(h, string_);
            setState = @(string_, value_) setappdata(h, string_, value_);
            % Enable simple relative figure resizing
            set(findall(h, 'Parent', h), 'Units', 'Normalized'); set(h, 'Resize', 'on');
            % Adjust text appearance
            txt = findall(h, 'Type', 'Text'); pos = get(txt, 'Position');
            set(txt, 'HorizontalAlignment', 'Left',...
                     'Position', [0, pos(2)],...
                     'Interpreter', 'None',...
                     'String', string,...
                     'FontSize', 8);
            set(t, 'TimerFcn', @(a,b) cellfun(@(x) feval(x), {@() waitbar(getState('state'), h, getState('string')),...
                                                              @() set(h, 'name', getState('title'), 'visible', 'on')}));
        end
        
        % Store current state string and title
        setState('state',  state);
        setState('string', string);
        setState('title',  [title, ' (', num2str(scannedFiles), ' files scanned)']);
        
        % Start Timer if not running currently
        if strcmp(get(t, 'Running'), 'off'); 
            start(t); 
        end
        
    end

end