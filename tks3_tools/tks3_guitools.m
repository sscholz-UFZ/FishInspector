classdef tks3_guitools
    
    methods(Static)
   
        function pos = getPixelValue(hobj, property)
            % getPixelValue(hObj, {Property})
            % Get a property value from a handle object in pixel coordinates
            % If property is 'mouse2D', the 2-dimensional coordinate of the
            % figure/axes is returned using the 'CurrentPoint' property.
            % Default value of Property = 'Position'
            % For example:
            %   hf = figure;
            %   ha = gca(hf);
            %   axPos = getPixelValue(ha, 'Position');
            %   mPos  = getPixelValue(ha, 'mouse2D');
            %
            % Scientific Software Solutions
            % Tobias Kieﬂling 05/2016-06/2016
            % support@tks3.de
            mouse2D = false;
            if ~exist('property', 'var')
                property = 'Position'; 
            elseif strcmp(property, 'mouse2D')
                property = 'CurrentPoint';
                mouse2D = true;
            end
            
            oldUnits = hobj.Units;
            hobj.Units = 'Pixel';
            pos = get(hobj, property);
            hobj.Units = oldUnits;
            
            if mouse2D 
                pos = [pos(1,1), pos(1,2)];
            end
            
        end
        
        function elements = fileparts2(path2fileOrFolder)
            % fileparts2(path2FileORFolder)
            % Get all single path-elements from a path to a file or a folder.
            % Works like fileparts, but returns all elements of the path at once.
            % Example:
            %   elements = fileparts2('C:\folderA\folderB\file.txt')
            % returns
            %   elements = {'C:\', 'folderA', 'folderB', 'file.txt'}
            %
            % Scientific Software Solutions
            % Tobias Kieﬂling 05/2016-06/2016
            % support@tks3.de
            
            elements = {};
            while ~isempty(path2fileOrFolder)
                [path2fileOrFolder, fpA, fpB] = fileparts(path2fileOrFolder);
                elements{end+1} = [fpA, fpB]; %#ok<AGROW>
                if isempty(elements{end})
                    elements{end} = path2fileOrFolder;
                    path2fileOrFolder = '';
                end
            end
            elements = elements(end:-1:1);
            
        end
        
        function sb = statusbar(hf, divNum, divPos)
            % Note: UISTACK kills resize function :-(, i.e. don't use
            %       uistack after having introduced the statusbar to the GUI
            if ~exist('hf', 'var'), hf = figure; end
            if ~exist('divNum', 'var'), divNum = 2; end
            if ~exist('divPos', 'var')
                divPos = ((1:divNum)-1)./divNum; 
            elseif length(divPos)~=divNum
                error('Number of divider Positions does not match number of dividers')
            end
            divWidth = [divPos(2:end),1]-divPos;
            
            height = 20;
            swidth = 0.95;
            tag = 'statusbar';
            
            % Create Statusbar
            sb = uipanel(hf, 'Tag',             tag,...
                             'Units',           'Pixel',...
                             'BorderType',      'line',...
                             'HighlightColor',  [0.9,0.9,0.9]);

            % Create txthandles
            txthandles = zeros(divNum, 1);
            for i = 1:divNum
                txthandles(i) = uicontrol(sb,   'Style',                'Text',...
                                                'String',               'Text1',...
                                                'Units',                'Normalized',...
                                                'HorizontalAlignment',  'left',...
                                                'ForegroundColor',      [0.5, 0.5, 0.5],...
                                                'Position',             [swidth*divPos(i), 0, swidth*divWidth(i), 0.85]);
            end
            setappdata(sb, 'txthandles', txthandles);
            
            % Create Resize Icon
            hIcon = axes('parent', sb, 'units', 'pixel');
            ri = resizeIcon();
            hi = imshow(ri, 'parent', hIcon);
            set(hi, 'AlphaData', ~isnan(ri(:,:,1)));
            
            % Hook up to resize function of the figure
            jPanel_ = handle(sb.JavaFrame.getPrintableComponent, 'CallbackProperties');
            set(jPanel_, 'AncestorResizedCallback', @(varargin) statusbar_resizeFCN);
            setappdata(sb, 'jPanel', jPanel_);
            
            function statusbar_resizeFCN(varargin)
                
                hfpos = tks3_guitools.getPixelValue(hf, 'Position');
                set(sb,    'Position', [0, 0, hfpos(3)+2, height]);
                set(hIcon, 'Position', [hfpos(3)-12,3, 11, 12]);
                
%%                % Support nice cropping of filenames if necessary
%                 s = get(txthandles(1), 'String');
%                 e = get(txthandles(1), 'Extent');
%                 p = get(txthandles(1), 'Position');
%                 if e(3)>p(3)  % Extend is bigger than available space
%                     if exist(s, 'file')==2
%                         % Make path elements
%                         elements = {};
%                         [tempd, fily, ext] = fileparts(s);
%                         fily = [fily, ext];
%                         complete = false;
%                         while ~complete
%                             [tempd, elements{end+1}, ~] = fileparts(tempd);
%                             if isempty(elements{end})
%                                 elements{end} = [];
%                                 elements{1} = tempd; 
%                                 complete = true;
%                             end
%                         end
%                         elements{end+1} = fily;
%                         
%                         % Try shorter path variants until one of them fits
%                         for j = 2:(length(elements)-1)
%                             elements{j} = '...';
%                             newStr = fullfile(elements{:});
%                             set(txthandles(1), 'String', newStr)
%                             e = get(txthandles(1), 'Extent');
%                             p = get(txthandles(1), 'Position');
%                             if e(3)<p(3)
%                                 break
%                             end
%                         end
%                     end
%                     if e(3)>p(3)
%                         for j = 1 : length(s)
%                             newStr = ['...', s(j:end)];
%                             set(txthandles(1), 'String', newStr)
%                             e = get(txthandles(1), 'Extent');
%                             p = get(txthandles(1), 'Position');
%                             if e(3)<p(3)
%                                 break
%                             end
%                         end
%                     end
%                 end
%                 
            end
            
            function out = resizeIcon
               
                out = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;...
                       0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0;...
                       0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2;...
                       0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2;...
                       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;...
                       0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0;...
                       0, 0, 0, 0, 1, 1, 2, 0, 1, 1, 2;...
                       0, 0, 0, 0, 0, 2, 2, 0, 0, 2, 2;...
                       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;...
                       1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0;...
                       1, 1, 2, 0, 1, 1, 2, 0, 1, 1, 2;...
                       0, 2, 2, 0, 0, 2, 2, 0, 0, 2, 2];
                col = [NaN, NaN, NaN;...
                       0.6, 0.6, 0.6;...
                       1.0, 1.0, 1.0];
                out = ind2rgb(out, col);
                
            end
            
        end
        
        function id = axesMouseMoveObserver(ha, overAxesCallback, outsideAxesCallback)
            % Scientific Software Solutions
            % Tobias Kieﬂling 05/2016-06/2016
            % support@tks3.de
            if ~exist('overAxesCallback', 'var')    || isempty(overAxesCallback),    overAxesCallback    = @(varargin) []; end
            if ~exist('outsideAxesCallback', 'var') || isempty(outsideAxesCallback), outsideAxesCallback = @(varargin) []; end
            
            hf = ancestor(ha, 'figure');
            id = iptaddcallback(hf, 'WindowButtonMotionFcn', @motionFcn);
            setappdata(hf, 'motionFcnID', id);
            
            function motionFcn(varargin)
                % Support imscrollpanels if this axes is embedded into one
                thisHa = findobj(get(ha, 'parent'), 'tag', 'imscrollpanel');
                if isempty(thisHa), thisHa = ha; end
                
                % Get axis location in pixel
                haPos = tks3_guitools.getPixelValue(thisHa, 'Position');
                
                % Get mouse position in pixel
                mPos  = tks3_guitools.getPixelValue(hf, 'mouse2D');
                
                % Check if mouse is over axes
                overAxes = all(mPos>haPos(1:2)) && all(mPos<(haPos([1,2])+haPos([3,4])));
                
                % Call the Callbacks
                if overAxes
                    feval(overAxesCallback, ha);
                else
                    feval(outsideAxesCallback, ha);
                end
                
            end
            
        end
        
        
        function hoverEffect(hf, hMarker, mousePointer, disbaleWhenOff)
            % Apply default values
            if ~exist('mousePointer', 'var'),   mousePointer = 'hand'; end
            if ~exist('disbaleWhenOff', 'var'), disbaleWhenOff = true; end
            
            % Assign MouseEntered/MouseExited-Callbacks
            set(hMarker, 'MouseEnteredCallback', @hoverEnter);
            set(hMarker, 'MouseExitedCallback',  @hoverExit );
            
            function hoverEnter(jhandle, varargin)
                if disbaleWhenOff || jhandle.isEnabled
                    set(hf, 'Pointer', mousePointer)
                    jhandle.setEnabled(true)
                end
            end
            function hoverExit(jhandle, varargin)
                set(hf, 'Pointer', 'arrow');
                if disbaleWhenOff
                    jhandle.setEnabled(false)
                end
            end
        end
        
    end
    
end