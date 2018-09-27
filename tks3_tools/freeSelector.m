function freeSelector(buttonUpFcn, hp, interactionRadius, isCircular)
% LINESELECTOR(buttonUpFcn, hp, lastPointSelector)
% Small GUI plug-in to allow users to modify lines.
%
% Scientific Software Solutions
% Tobias Kießling 01/2013-08/2016
% support@tks3.de

    if ~exist('buttonUpFcn', 'var'), buttonUpFcn = []; end
    if ~exist('interactionRadius', 'var'), interactionRadius = 10; end
    if ~exist('isCircular', 'var'), isCircular = false; end
    
    markerSize = 8;
    colNormal = [0, 1, 0];
    colSelected = [1, 0, 0];
    currentlySelectedPoint = [];
    
    tag = 'free';
    doByTag = false;
    if ~exist('hp', 'var')
        % Create a Figure and an Image where everything happens
        hf = figure;
        ha = gca;
        hw = 300; hh = 100;
        Im = zeros(hh, hw);
        imshow(Im); hold on; 
        
        % The Contour
        t = 0:0.01:pi;
        r = 0.9 * min([hw/2, hh/2]);
        lx = hw/2+r.*sin(t);
        ly = hh/2+r.*cos(t);
        %plot(lx, ly, 'r', 'tag', tag);
        
        % Some Points
        nop = 0;
        lx = hw * rand (1, nop);
        ly = hh * rand (1, nop);
        lr = 20 * rand (1, nop);
        
        % Set up the GUI
        
        hp = plotPoints(lx,ly,lr, ha);
        hp = findobj(ha, 'tag', tag);
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
        
        % Add center point to path
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
        for l = 1 : length(hp)
            if isempty(get(hp(l), 'UserData'))
                set(hp(l), 'ButtonDownFcn', @ButtonDownFcn)
            end
        end
         % Get data from input
        hf  = ancestor(ha, 'figure');
        lx = get(hp, 'XData'); if isempty(lx), lx = {};end
        ly = get(hp, 'YData'); if isempty(ly), ly = {};end
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
    uimenu(hmenu, 'Label', 'New Line', 'Callback', @newLineCallback, 'tag', 'newL');
    
    function cleanup
        try
            set(hf, 'WindowButtonMotionFcn', oldWBMF)
        end
        try
            rmappdata(hf, 'buttonDown');
        end
        try
            set(hf, 'WindowButtonDownFcn', oldWBDF);
            set(hf, 'WindowScrollWheelFcn', oldWSWF);
            delete(hmenu)
            rmappdata(hf, 'wasEndpoint');
            rmappdata(hf, 'cleanupfcn');
        end
    end

    function scrollWheel_callback(~, wheelData)
        if isempty(currentlySelectedPoint), return; end
        [is_overaxes, ~] = isoveraxes(ha);
        if ~is_overaxes, return; end
            
        % CenterPoint and Radius of the currently selected point
        x = get(currentlySelectedPoint, 'XData');
        y = get(currentlySelectedPoint, 'YData');
        if isappdata(currentlySelectedPoint, 'Radius')
            r = getappdata(currentlySelectedPoint, 'Radius');

            % Change radius according to wheel action
            r = max([1, r + 1*wheelData.VerticalScrollCount]);

            % Update the shape
            contour = get(currentlySelectedPoint, 'UserData');
            coordsFun = get(contour, 'UserData');
            newCoords = coordsFun(x,y,r);
            set(contour, 'XData', newCoords.x,...
                         'YData', newCoords.y);
            set(marker, 'visible', 'off');
            %Update the Radius stored in the graphic handle
            setappdata(currentlySelectedPoint, 'Radius', r);
        else
            interactionRadius = max([1, interactionRadius + 1*wheelData.VerticalScrollCount]);
            set(marker, 'markerSize', 2*interactionRadius);
        end
        
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
        set(findobj(menuobj, 'Tag', 'newL'), 'Visible', newOnOrOff)
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
            hold(ha, 'off');
        end
        
        hp = findobj(ha, 'tag', tag);
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
        if ~iscell(lx), lx = {lx}; end
        if ~iscell(ly), ly = {ly}; end
        % %
        lineIDX = find(hp==newPoint);
        
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
        setappdata(hf, 'buttonDown', true);
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

    function newLineCallback(varargin)
        setappdata(hf, 'newLine', true);
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
                
                if isempty(get(hp(lineIDX), 'UserData'))
                    idx = idx(lineIDX);
                    % Non-circular boundary condition
                    if ~isCircular 
                        % Check if we have modified the endpoint during this draw
                        if (isappdata(hf, 'wasEndpoint') && getappdata(hf,'wasEndpoint')~=0)
                            endi = getappdata(hf,'wasEndpoint');
                            if endi>0
                                idx = 1;
                            elseif endi<0
                                idx = length(lx);
                            end
                        end
                        % If we're currently modifying the end, we should remeber that
                        if idx==1 
                            setappdata(hf, 'wasEndpoint', 1)
                        elseif idx==length(lx)
                            setappdata(hf, 'wasEndpoint', -1)
                        else
                            setappdata(hf, 'wasEndpoint', 0)
                        end
                    end

                    nm = interactionRadius;
                    n = idx-nm:idx+nm;

                    intoWeight = false(size(n));
                    intoWeight([1:3,nm+1,end-2:end]) = true;

                    % circular condition
                    if isCircular
                        n2 = n;
                        n2(n2>length(lx)) = n2(n2>length(lx))-length(lx); 
                        n2(n2<1) = length(lx)+n2(n2<1);
                    else
                        n2 = n;
                        if length(lx)>((2*interactionRadius)-1)+5
                            tooBig = n2>length(lx);
                            if any(tooBig), tooBig(nm+2:end) = true; end
                            intoWeight(tooBig) = [];
                            n2(tooBig) = []; 
                            tooSmall = n2<1;
                            if any(tooSmall), tooSmall(2:nm-1) = true; end
                            intoWeight(tooSmall) = [];
                            n2(tooSmall) = []; 
                            n = n2;
                        end
                    end

                    if length(lx)<(2*interactionRadius)+5
                        lx = [mousepos(1), lx];
                        ly = [mousepos(2), ly];
                    else                    
                        ly(idx) = mousepos(2);
                        lx(idx) = mousepos(1);
                        toInterpolate  = unique(n(intoWeight), 'stable');
                        toInterpolate2 = unique(n2(intoWeight), 'stable');
                        ly(n2) = interp1(toInterpolate, ly(toInterpolate2), n, 'pchip');
                        lx(n2) = interp1(toInterpolate, lx(toInterpolate2), n, 'pchip');
                    end

                    s = [0, cumsum(sqrt((lx(2:end)-lx(1:end-1)).^2 + (ly(2:end)-ly(1:end-1)).^2), 2)];
                    ly = interp1(s, ly, linspace(0, s(end), ceil(s(end))));
                    lx = interp1(s, lx, linspace(0, s(end), ceil(s(end))));
                    px = lx; py = ly;
                else
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
                     coordsFun = get(contour, 'UserData');
                     newCoords = coordsFun(px,...
                                           py,...
                                           getappdata(hp(lineIDX), 'Radius'));
                     set(contour, 'XData', newCoords.x,...
                                  'YData', newCoords.y);
                end
                
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
                [px, py, idx, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
                lineIDX = getappdata(hf, 'lineIDX');
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
        
        if is_overaxes 
            if getappdata(hf, 'buttonDown')
                col = colSelected;
            else
                col = colNormal;
            end
            if isappdata(hf, 'newLine') && getappdata(hf, 'newLine');
                set(marker, 'XData', mousepos(1), 'YData', mousepos(2), 'color', col, 'visible', 'on', 'parent', ha);
                set(marker, 'markerSize', 2*interactionRadius);
            elseif ~isempty(hp)
                set(marker, 'XData', px(lineIDX), 'YData', py(lineIDX), 'color', col, 'visible', 'on', 'parent', ha);
                if ~isempty(get(hp(lineIDX), 'UserData'))
                    set(marker, 'markerSize', markerSize);
                else
                    set(marker, 'markerSize', 2*interactionRadius);
                end
            else
                set(marker, 'visible', 'off');
            end
        else
            set(marker, 'visible', 'off');
        end
    end

    function ButtonDownFcn(varargin)
        % ButtonDownOnMarker / LastPointSelector
        [is_overaxes, mousepos] = isoveraxes(ha);
        if ~is_overaxes, return; end
        
        if isappdata(hf, 'newLine') && getappdata(hf, 'newLine');
            % Create new line
            oldhold = ishold;
            hold(ha, 'on')
            newLine = plot(mousepos(1), mousepos(2), 'color', colSelected, 'tag', tag, 'ButtonDownFcn', @ButtonDownFcn);
            if ~oldhold
                hold(ha, 'off')
            end
            getHandles;
            lineIDX = find(hp==newLine);
            currentlySelectedPoint = newLine;
            setappdata(hf, 'lineIDX', lineIDX);
            setappdata(hf, 'newLine', false);
            setappdata(hf, 'currentIDX', 1);
            setappdata(hf, 'wasEndpoint', 0)
        else
            % Identify nearest Point and save the lineIDX
            getHandles;
            [px, py, idx, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
            setappdata(hf, 'currentIDX', idx);
            setappdata(hf, 'lineIDX', lineIDX);
            setappdata(hf, 'wasEndpoint', 0)

            % Save start Position of the contour
            setappdata(hf, 'startPos', struct('lx', get(hp(lineIDX), 'XData'), 'ly', get(hp(lineIDX), 'YData'),...
                                              'dx', mousepos(1)-hp(lineIDX).XData(1),...
                                              'dy', mousepos(2)-hp(lineIDX).YData(1)));
            contour = get(hp(lineIDX), 'UserData');
            setappdata(hf, 'startPosContour', struct('x', get(contour, 'XData'), 'y', get(contour, 'YData')));

            % Highlight selected Contour
            contours = get(hp, 'UserData'); if isempty(contours), contours = {}; end; if ~iscell(contours), contours = {contours}; end
            for i=1:length(contours); if isempty(contours{i}), contours{i} = hp(i); end; end
            cellfun(@(x) set(x, 'Color', colNormal), contours(setdiff(1:length(hp), lineIDX)));
            if ~isempty(contours), set(contours{lineIDX}, 'Color', colSelected); end
            checkMarker();
            set(marker, 'Color', colSelected);

            currentlySelectedPoint = hp(lineIDX);
        end
        
        % Right click?
        if strcmpi(get(hf,'SelectionType'), 'alt')
            % Evaluate the 
            feval(get(hmenu, 'Callback'), hmenu);
            set(hmenu, 'Position', get(hf, 'CurrentPoint'), 'Visible', 'on');
            return
        end
        
        set(hf, 'WindowButtonUpFcn', @buttonUp)
        setappdata(hf, 'buttonDown', true);
         
        disp('Hallo')
        function buttonUp(varargin)
            setappdata(hf, 'newLine', false);
                
            setappdata(hf, 'buttonDown', false);
            setappdata(hf, 'currentIDX', []);
            setappdata(hf, 'lineIDX', []);
            setappdata(hf, 'startPos', []);
            setappdata(hf, 'startPosContour', []);
            setappdata(hf, 'wasEndpoint', 0)
            
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
            for i=1:length(contours); if isempty(contours{i}), contours{i} = hp(i); end; end
            cellfun(@(x) set(x, 'Color', colNormal), contours(setdiff(1:length(hp), lineIDX)));
            set(contours {lineIDX}, 'Color', colSelected);
            checkMarker();
            set(marker, 'Color', colSelected);
            currentlySelectedPoint = hp(lineIDX);
        else
            % We clicked outside the contour
            % => Highlight nothing
            contours = get(hp, 'UserData'); if isempty(contours), contours = {}; end; if ~iscell(contours), contours = {contours}; end
            for i=1:length(contours); if isempty(contours{i}), contours{i} = hp(i); end; end
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
        if (~isempty(inside) && inside) || (isappdata(hf, 'newLine') && getappdata(hf, 'newLine'))
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

        if iscell(cx) && iscell(cy) % Support multiple lines;
            disti = cellfun(@(x,y) (x-mpos_x).^2 + (y-mpos_y).^2, cx, cy, 'Uniform', 0);
            [mval, idx] = cellfun(@(x) min(x, [], 2), disti);
            [~, lineIDX] = min(mval);
            %idx = idx(lineIDX);
            px = cellfun(@(x, i) x(i), cx, num2cell(idx));
            py = cellfun(@(y, i) y(i), cy, num2cell(idx));
        else
            disti = (cx-mpos_x).^2 + (cy-mpos_y).^2;
            [mval, idx] = min(disti, [], 2);
            [~, lineIDX] = min(mval);
            px = cx(lineIDX, idx);
            py = cy(lineIDX, idx);
        end
        
%         
%         if wasCell
%              lineIDX = lineIDX(1);
%         end
%         
        
        
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