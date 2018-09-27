classdef guitools
% GUITOOLS
% Collection of useful GUI functions
%
% Scientific Software Solutions
% Tobias Kieﬂling 01/2013-08/2016
% support@tks3.de

    methods(Static)
   
        function handles = getGUIcomponents(hfig)
            % Get all GUI components (with non-empty tag) from a figure, and return a
            % "handle-structure" similarly to those provided by MATLAB's GUIDE mechanism
            
            h = findall(hfig);
            tags = get(h, 'Tag');
            withTags = ~cellfun('isempty', tags);
            temp = [tags(withTags)'; num2cell(h(withTags))'];
            handles = struct(temp{:});
            
        end
        
        function resize_function(handles, varargin)
            if ~isfield(handles, 'to_resize') || isempty(handles.to_resize)
                return;
            end
            
            try
                hFig = handles.figure1;
            catch
                hFig = ancestor(handles.to_resize(1), 'figure');
            end
            now_fig_pos = get(hFig, 'Position');
            
            % Loop over all things to resize
            for i = 1 : length(handles.to_resize)
                % Neither docked to top or bottom?
                if ~handles.dock_top(i) && ~handles.dock_bottom(i)
                    vert_size = handles.start_pos{i}(4);
                    vert_i = handles.start_pos{i}(2);
                end

                % Dock only to top and don't resize?
                if handles.dock_top(i) && ~handles.dock_bottom(i)
                    % Get starting vertical offset
                    vert_size = handles.start_pos{i}(4);
                    vert_i = (now_fig_pos(4) - handles.start_fig_pos(4)) + handles.start_pos{i}(2);
                end

                % Dock only to bottom and don't resize?
                if handles.dock_bottom(i) && ~handles.dock_top(i)
                    % Get starting vertical offset
                    vert_size = handles.start_pos{i}(4);
                    vert_i = handles.start_pos{i}(2);
                end

                % Dock only to left and don't resize?
                if handles.dock_left(i) && ~handles.dock_right(i)
                    % Get starting horizontal offset
                    hor_size = handles.start_pos{i}(3);
                    hor_i = handles.start_pos{i}(1);
                end

                % Dock only to right and don't resize?
                if handles.dock_right(i) && ~handles.dock_left(i)
                    % Get starting horizontal offset
                    hor_size = handles.start_pos{i}(3);
                    hor_i = (now_fig_pos(3) - handles.start_fig_pos(3)) + handles.start_pos{i}(1);
                end

                % Resize horizontally
                if handles.dock_right(i) && handles.dock_left(i)
                    % Get starting horizontal offset
                    hor_i = handles.start_pos{i}(1);
                    hor_size = handles.start_pos{i}(3) + now_fig_pos(3) - handles.start_fig_pos(3);
                end

                % Resize vertically
                if handles.dock_top(i) && handles.dock_bottom(i)
                    % Get starting vertical offset
                    vert_i = handles.start_pos{i}(2);
                    vert_size = handles.start_pos{i}(4) + now_fig_pos(4) - handles.start_fig_pos(4);
                end

                % Make sure we have some sizing
                hor_size  = max(1, hor_size);
                vert_size = max(1, vert_size);

                set(handles.to_resize(i), 'Position', [hor_i vert_i hor_size vert_size]);
            end

        end 
        
        function currentDir = getCurrentDir() 
            % Get Filepath to spinner gif
            if isdeployed % Stand-alone mode.
                [~, result] = system('path');
                currentDir = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
            else % MATLAB mode.
                currentDir = pwd;
            end
        end
        
        function fileURL = path2fileURL(fullpath2file)
           fileURL = ['file:/', strrep(fullpath2file, '\', '/')]; 
        end
        
    end
    
end