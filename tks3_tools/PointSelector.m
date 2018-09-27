function PointSelector(buttonUpFcn, hp, interactionRadius)
% LINESELECTOR(buttonUpFcn, hp, lastPointSelector)
% Small GUI plug-in to allow users to modify lines.
%
% Scientific Software Solutions
% Tobias Kießling 01/2013-08/2016
% support@tks3.de

    if ~exist('buttonUpFcn', 'var'), buttonUpFcn = []; end
    if ~exist('interactionRadius', 'var'), interactionRadius = 15; end
    
    colNormal = [0, 1, 0];
    colSelected = [1, 0, 0];
    currentlySelectedPoint = [];
    
    doByTag = false;
    if ~exist('hp', 'var')
        % Create a Figure and an Image where everything happens
        hf = figure;
        ha = gca;
        hw = 300; hh = 100;
        Im = rand(hh, hw);
    
        % Some Points
        nop = 100;
        lx = hw * rand (1, nop);
        ly = hh * rand (1, nop);
        lr = 20 * rand (1, nop);
        
        
        % Set up the GUI
        tag = 'point';
        imshow(Im); hold on; 
        hp = plotPoints(lx,ly,lr, ha);
        hp = findobj(ha, 'tag', tag);
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
        
        % Add center point to path
%         lx = cellfun(@(s,x) [s(1), x], num2cell(lx)', lx_, 'Uniform', 0); 
%         ly = cellfun(@(s,y) [s(1), y], num2cell(ly)', ly_, 'Uniform', 0);
        doByTag = true;
        
    else
        % called with {tag, handles.axes1} if no graphic object is
        % available yet that could be found via the tag
        if iscell(hp)
            tag = hp{1};
            ha  = hp{2};
            hp = findobj(0, 'tag', tag);
            doByTag = true;
        end
        % Just a tag was provided:
        if ischar(hp)
            tag = hp;
            hp = findobj(0, 'tag', tag);
            ha = ancestor(hp, 'axes');
            doByTag = true;
        end
        % Get data from input
        hf  = ancestor(ha, 'figure');
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
    end
    
    if ~iscell(lx), lx = {lx}; end
    if ~iscell(ly), ly = {ly}; end

    
    if iscell(hf), hf = hf{1}; end
    if iscell(ha), ha = ha{1}; end
    hold(ha, 'on');
    marker = [];
    checkMarker();

    
    hold(ha, 'off');
    
    % ... and bind the windowButtonMotionFuction to monitor mouse movements
    oldWBMF = get(hf, 'WindowButtonMotionFcn');
    oldWBDF = get(hf, 'WindowButtonDownFcn');
    oldWSWF = get(hf, 'WindowScrollWheelFcn');
    
    set(hf, 'WindowButtonMotionFcn', @motion);
    set(hf, 'WindowButtonDownFcn', @buttonDownAxes);
    set(hf, 'WindowScrollWheelFcn', @scrollWheel_callback);
    setappdata(hf, 'buttonDown', false);
    setappdata(hf, 'cleanupfcn', @cleanup);

    hmenu = uicontextmenu(hf, 'Callback', @contextMenuCallback);
    uimenu(hmenu, 'Label', 'Delete', 'Callback', @deleteCallback, 'tag', 'delete')
    uimenu(hmenu, 'Label', 'New Point', 'Callback', @newPointCallback, 'tag', 'new');
    
    function cleanup
        set(hf, 'WindowButtonMotionFcn', oldWBMF);
        set(hf, 'WindowButtonDownFcn', oldWBDF);
        set(hf, 'WindowScrollWheelFcn', oldWSWF);
        delete(hmenu)
        rmappdata(hf, 'buttonDown');
        rmappdata(hf, 'cleanupfcn')
    end

    function scrollWheel_callback(~, wheelData)
        if isempty(currentlySelectedPoint), return; end
        [is_overaxes, ~] = isoveraxes(ha);
        if ~is_overaxes, return; end
            
        % CenterPoint and Radius of the currently selected point
        x = get(currentlySelectedPoint, 'XData');
        y = get(currentlySelectedPoint, 'YData');
        r = getappdata(currentlySelectedPoint, 'Radius');
        
        % Change radius according to wheel action
        r = max([1, r + 1*wheelData.VerticalScrollCount]);
        
        % Update the shape
        contour = get(currentlySelectedPoint, 'UserData');
        coordsFun = get(contour, 'UserData');
        newCoords = coordsFun(x,y,r);
        set(contour, 'XData', newCoords.x,...
                     'YData', newCoords.y);
                 
        %Update the Radius stored in the graphic handle
        setappdata(currentlySelectedPoint, 'Radius', r);
        
        
        % Execute external buttonUpFcn
        if ~isempty(buttonUpFcn)
            feval(buttonUpFcn, lx, ly);
        end
        if doByTag
            hp = findobj(ha, 'tag', tag);
            lx = get(hp, 'XData');
            ly = get(hp, 'YData');
            if ~iscell(lx), lx = {lx}; end
            if ~iscell(ly), ly = {ly}; end
        end
    end

    function contextMenuCallback(menuobj, varargin)
        [is_overaxes, mousepos] = isoveraxes(ha);
        if ~is_overaxes
            newOnOrOff = 'Off';
            deleteOnOrOff = 'Off';
        else
            if isempty(currentlySelectedPoint)
                deleteOnOrOff = 'Off';
                newOnOrOff = 'On';
            else
                deleteOnOrOff = 'On';
                newOnOrOff = 'Off';
            end
        end
        set(findobj(menuobj, 'Tag', 'delete'), 'Visible', deleteOnOrOff)
        set(findobj(menuobj, 'Tag', 'new'), 'Visible', newOnOrOff)
    end

    function deleteCallback(varargin)
        if isempty(currentlySelectedPoint), return; end
        % Delete Contour
        delete(get(currentlySelectedPoint, 'UserData'));
        % Delete Point
        delete(currentlySelectedPoint)
        hp = findobj(ha, 'tag', tag);
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
        if ~iscell(lx), lx = {lx}; end
        if ~iscell(ly), ly = {ly}; end
        % %
        currentlySelectedPoint = [];
        setappdata(hf, 'buttonDown', false);
        setappdata(hf, 'currentIDX', []);
        setappdata(hf, 'lineIDX', []);
        setappdata(hf, 'startPos', []);
        setappdata(hf, 'startPosContour', []);
        motion();
        
        % Execute external buttonUpFcn
        if ~isempty(buttonUpFcn)
            feval(buttonUpFcn, lx, ly);
        end
        if doByTag
            hp = findobj(ha, 'tag', tag);
            lx = get(hp, 'XData');
            ly = get(hp, 'YData');
            if ~iscell(lx), lx = {lx}; end
            if ~iscell(ly), ly = {ly}; end
        end
    end

    function newPointCallback(varargin)
        [is_overaxes, mousepos] = isoveraxes(ha);
        if ~is_overaxes, return; end
        
        wasHold = ishold(ha);
        hold(ha, 'on')
            newX = mousepos(1);
            newY = mousepos(2);
            r = 10;
        newPoint = plotPoints(newX, newY, r, ha);
        if wasHold
            hold(ha, 'on');
        else
            hold(ha, 'off');
        end
        
        hp = findobj(ha, 'tag', tag);
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
        if ~iscell(lx), lx = {lx}; end
        if ~iscell(ly), ly = {ly}; end
        % %
        lineIDX = find(hp==newPoint);
        setappdata(hf, 'buttonDown', false);
        setappdata(hf, 'currentIDX', 1);
        setappdata(hf, 'lineIDX', lineIDX);
        setappdata(hf, 'startPos', struct('lx', get(hp(lineIDX), 'XData'), 'ly', get(hp(lineIDX), 'YData'),...
                                          'dx', mousepos(1)-hp(lineIDX).XData(1),...
                                          'dy', mousepos(2)-hp(lineIDX).YData(1)));
        contour = get(hp(lineIDX), 'UserData');
        setappdata(hf, 'startPosContour', struct('x', get(contour, 'XData'), 'y', get(contour, 'YData')));
        
        % Highlight selected Contour
        contours = get(hp, 'UserData'); if ~iscell(contours), contours = {contours}; end
        cellfun(@(x) set(x, 'Color', colNormal), contours(setdiff(1:length(hp), lineIDX)));
        set(contours {lineIDX}, 'Color', colSelected);
        checkMarker();
        set(marker, 'Color', colSelected);
        currentlySelectedPoint = hp(lineIDX);
        
        motion();
        
        
        % Execute external buttonUpFcn
        if ~isempty(buttonUpFcn)
            feval(buttonUpFcn, lx, ly);
        end
        if doByTag
            hp = findobj(ha, 'tag', tag);
            lx = get(hp, 'XData');
            ly = get(hp, 'YData');
            if ~iscell(lx), lx = {lx}; end
            if ~iscell(ly), ly = {ly}; end
        end
    end

    function motion(varargin)
        if gcf~=hf, return; end % early bail out
        % Check if the mouse if over the axis
        [is_overaxes, mousepos] = isoveraxes(ha);
        getHandles;
        if is_overaxes && ~isempty(hp)
            [px, py, idx, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
            col = colNormal;
            if getappdata(hf, 'buttonDown')
                lineIDX = getappdata(hf, 'lineIDX');
                if doByTag
                    hp = findobj(ha, 'tag', tag);
                    lx = get(hp, 'XData');
                    ly = get(hp, 'YData');
                    if iscell(lx)
                        lx = lx{lineIDX};
                        ly = ly{lineIDX};
                    end
                end
                
%                 col = 'g'; 
%                 nm = interactionRadius;
%                 n = idx-nm:idx+nm;
% 
%                 % circular condition
%                 n2 = n;
%                 n2(n2>length(lx)) = n2(n2>length(lx))-length(lx); 
%                 n2(n2<1) = length(lx)+n2(n2<1);
% 
                 py = [1,1].*mousepos(2);
                 px = [1,1].*mousepos(1);
                 
                 % Move Contour
                 startPos = getappdata(hf, 'startPos'); % Get the
                 px = px-startPos.dx;
                 py = py-startPos.dy;
                 disti_x = px-startPos.lx;  % moved distances in x- and y-
                 disti_y = py-startPos.ly;  % since the button has been pressed
                 % Now move the contour 
                 startPosContour = getappdata(hf, 'startPosContour');
                 contour = get(hp(lineIDX), 'UserData');  % Get Conour handle from User Data
                 set(contour, 'XData', startPosContour.x + disti_x(1),...  % move in x
                              'YData', startPosContour.y + disti_y(1));    % move in y
                 
%                 %lx(n) = interp1(n([1:3,nm+1,end-2:end]), lx(n([1:3,nm+1,end-2:end])), n, 'pchip');
%                 toInterpolate  = unique(n([1:3,nm+1,end-2:end]), 'stable');
%                 toInterpolate2 = unique(n2([1:3,nm+1,end-2:end]), 'stable');
%                 %toInterpolate = unique(n([1,nm+1,end]), 'stable');
%                 ly(n2) = interp1(toInterpolate, ly(toInterpolate2), n, 'pchip');
%                 lx(n2) = interp1(toInterpolate, lx(toInterpolate2), n, 'pchip');
% 
%                 s = [0, cumsum(sqrt((lx(2:end)-lx(1:end-1)).^2 + (ly(2:end)-ly(1:end-1)).^2), 2)];
%                 %ly = interp1(s, ly, linspace(0, max(s), length(ly)));
%                 %lx = interp1(s, lx, linspace(0, max(s), length(lx)));
%                 ly = interp1(s, ly, linspace(0, s(end), ceil(s(end))));
%                 lx = interp1(s, lx, linspace(0, s(end), ceil(s(end))));

%                 
                if length(hp)>1
                    set(hp(lineIDX), 'XData', px, 'YData', py);
                    lx = get(hp, 'XData');
                    ly = get(hp, 'YData');
                    if ~iscell(lx), lx = {lx}; end
                    if ~iscell(ly), ly = {ly}; end
                else
                    lx = px;
                    ly = py;
                    set(hp, 'XData', lx, 'YData', ly);
                end
                [px, py, idx, lineIDX] = getNearestPointOnContour(px(1), py(1), lx, ly);
            end
            
        end
        
        if doByTag
            checkMarker();
        end
%         % Clean up when marker gets destroyed
%         if ~doByTag && ishandle(hp) && ~isappdata(hp, 'deleteListener')
%             try
%                 a = addlistener(hp, 'ObjectBeingDestroyed', @(varargin) cleanup());  % hg2 way
%             catch Me
%                 a = handle.listener(handle(hp, 'ObjectBeingDestroyed', @(varargin) cleanup())); % hg1 way
%             end
%             disp('Hallo')
%             setappdata(hp, 'deleteListener', a);
%         end
        
        if is_overaxes && ~isempty(hp)
            if getappdata(hf, 'buttonDown')
                col = colSelected;
            end
            set(marker, 'XData', px(lineIDX), 'YData', py(lineIDX), 'color', col, 'visible', 'on', 'parent', ha);
        else
            set(marker, 'visible', 'off');
        end
    end

    function ButtonDownFcn(varargin)
        % ButtonDownOnMarker / LastPointSelector
        [is_overaxes, mousepos] = isoveraxes(ha);
        if ~is_overaxes, return; end
        
        % Identify nearest Point and save the lineIDX
        getHandles;
        [px, py, idx, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
        setappdata(hf, 'currentIDX', idx);
        setappdata(hf, 'lineIDX', lineIDX);
        
        % Save start Position of the contour
        setappdata(hf, 'startPos', struct('lx', get(hp(lineIDX), 'XData'), 'ly', get(hp(lineIDX), 'YData'),...
                                          'dx', mousepos(1)-hp(lineIDX).XData(1),...
                                          'dy', mousepos(2)-hp(lineIDX).YData(1)));
        contour = get(hp(lineIDX), 'UserData');
        setappdata(hf, 'startPosContour', struct('x', get(contour, 'XData'), 'y', get(contour, 'YData')));
        
        % Highlight selected Contour
        contours = get(hp, 'UserData'); if ~iscell(contours), contours = {contours}; end
        cellfun(@(x) set(x, 'Color', colNormal), contours(setdiff(1:length(hp), lineIDX)));
        set(contours{lineIDX}, 'Color', colSelected);
        checkMarker();
        set(marker, 'Color', colSelected);
        
        currentlySelectedPoint = hp(lineIDX);
        
        set(hf, 'WindowButtonUpFcn', @buttonUp)
        setappdata(hf, 'buttonDown', true);
        
        disp('Hallo')
        function buttonUp(varargin)
            setappdata(hf, 'buttonDown', false);
            setappdata(hf, 'currentIDX', []);
            setappdata(hf, 'lineIDX', []);
            setappdata(hf, 'startPos', []);
            setappdata(hf, 'startPosContour', []);
            
            set(hf, 'WindowButtonUpFcn', []);
            checkMarker();
            set(marker, 'Color', colNormal);

            disp('bye')
            % Execute external buttonUpFcn
            if ~isempty(buttonUpFcn)
                feval(buttonUpFcn, lx, ly);
            end
            if doByTag
                hp = findobj(ha, 'tag', tag);
                lx = get(hp, 'XData');
                ly = get(hp, 'YData');
                if ~iscell(lx), lx = {lx}; end
                if ~iscell(ly), ly = {ly}; end
            end
        end
        
    end

    function buttonDownAxes(varargin)
        % ButtonDownOnMarker / LastPointSelector
        [is_overaxes, mousepos] = isoveraxes(ha);
        if ~is_overaxes, return; end
        
        % Inside Contour?
        inside = false;
        getHandles;
        if ~isempty(hp)
            [~, ~, ~, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
            r = getappdata(hp(lineIDX), 'Radius');
            inside = ((lx{lineIDX}(1)-mousepos(1))^2 + (ly{lineIDX}(1)-mousepos(2))^2)<r^2;
        end
        if inside
            setappdata(hf, 'lineIDX', lineIDX);
            % Highlight selected Contour
            contours = get(hp, 'UserData'); if ~iscell(contours), contours = {contours}; end
            cellfun(@(x) set(x, 'Color', colNormal), contours(setdiff(1:length(hp), lineIDX)));
            set(contours {lineIDX}, 'Color', colSelected);
            checkMarker();
            set(marker, 'Color', colSelected);
            currentlySelectedPoint = hp(lineIDX);
        else
            % We clicked outside the contour
            % => Highlight nothing
            contours = get(hp, 'UserData'); if ~iscell(contours), contours = {contours}; end
            cellfun(@(x) set(x, 'Color', colNormal), contours);
            currentlySelectedPoint = [];
        end    
        
        % Right click?
        if strcmpi(get(varargin{1},'SelectionType'), 'alt')
            % Evaluate the 
            feval(get(hmenu, 'Callback'), hmenu);
            set(hmenu, 'Position', get(varargin{1}, 'CurrentPoint'), 'Visible', 'on');
            return
        end
        
        % Just forward to ButtonDownFcn if we're inside a Point Contour
        if inside
            ButtonDownFcn(varargin{:});
        end
    end


    function [tf, mpos]=isoveraxes(ha)
        % Get Mouse Position
        mpos = get(ha, 'CurrentPoint'); 
        mpos = mpos([1, 3]);

        % Get Axes Limits
        xl = get(ha, 'Xlim');
        yl = get(ha, 'Ylim');
        
        % Evaluate
        tf = false;
        if (mpos(1)>xl(1)) && (mpos(1)<xl(2)) && ...
           (mpos(2)>yl(1)) && (mpos(2)<yl(2))
            tf = true;
        end
    end

    function [px, py, idx, lineIDX] = getNearestPointOnContour(mpos_x, mpos_y, cx, cy)
        lineIDX = 1; wasCell=false;
        if iscell(cx) && iscell(cy) % Support multiple lines;
            wasCell = true;
            cx = cell2mat(cx);
            cy = cell2mat(cy); 
        end
        
        disti = (cx-mpos_x).^2 + (cy-mpos_y).^2;
        [mval, idx] = min(disti, [], 2);
        
        if wasCell
            [~, lineIDX] = min(mval); 
            if isempty(lineIDX)
                lineIDX = [];
            else
                lineIDX = lineIDX(1);
            end
        end
        
        px = cx(lineIDX, idx);
        py = cy(lineIDX, idx);
        
    end

    function getHandles
        hp = findobj(ha, 'tag', tag);
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
         
        if ~iscell(lx), lx = {lx}; end
        if ~iscell(ly), ly = {ly}; end
    end

    function checkMarker
        marker = findobj(ha, 'tag', 'marker');
        if isempty(marker)
            hold(ha, 'on');
                marker = plot([0], [0], 'ro', 'ButtonDownFcn', @ButtonDownFcn, 'tag', 'marker', 'parent', ha);
            hold(ha, 'off');
        end
    end

    function hp = plotPoints(x,y,r, parent)
        phi = linspace(0, 2*pi, 20);
        x = x(:);
        y = y(:);
        r = r(:);
        
%         ixi = x(:, ones(1, length(phi))) + r(:, ones(1, length(phi))) .* cos(phi(ones(1, length(r)), :));
%         ysi = y(:, ones(1, length(phi))) + r(:, ones(1, length(phi))) .* sin(phi(ones(1, length(r)), :));
        coordsFun = @(x,y,r) struct('x', x(:, ones(1, length(phi))) + r(:, ones(1, length(phi))) .* cos(phi(ones(1, length(r)), :)),...
                                    'y', y(:, ones(1, length(phi))) + r(:, ones(1, length(phi))) .* sin(phi(ones(1, length(r)), :)));


        coords = coordsFun(x,y,r);
        ixi = coords.x;
        ysi = coords.y;
        
        hpc = line(ixi', ysi', 'parent', parent, 'color', [0,1,0], 'tag', 'contour');
        for i = 1 : length(hpc)
            set(hpc(i), 'UserData', coordsFun);
        end
        
        hp = line([x,x]', [y,y]', 'parent', parent, 'color', [1,0,0], 'tag', tag);
        for i = 1 : length(hpc)
            set(hp(i), 'UserData', hpc(i));
            setappdata(hp(i), 'Radius', r(i));
        end
        
        
    end
end