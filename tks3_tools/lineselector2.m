function lineselector2(buttonUpFcn, hp, interactionRadius, isCircular)
% LINESELECTOR(buttonUpFcn, hp, lastPointSelector)
% Small GUI plug-in to allow users to modify lines.
%
% Scientific Software Solutions
% Tobias Kießling 01/2013-08/2016
% support@tks3.de
    if ~exist('buttonUpFcn', 'var'), buttonUpFcn = []; end
    if ~exist('interactionRadius', 'var'), interactionRadius = 15; end
    if ~exist('isCircular', 'var'), isCircular = true; end
    
    doByTag = false;
    if ~exist('hp', 'var')
        % Create a Figure and an Image where everything happens
        hf = figure;
        ha = gca;
        hw = 300; hh = 100;
        Im = zeros(hh, hw);
    
        % The Contour
        t = 0:0.01:pi;
        r = 0.9 * min([hw/2, hh/2]);
        lx = hw/2+r.*sin(t);
        ly = hh/2+r.*cos(t);

        % Set up the GUI
        imshow(Im); hold on; 
        hp = plot(lx, ly);
    else
        if ischar(hp)
            tag = hp;
            hp = findobj(0, 'tag', tag);
            doByTag = true;
        end
        % Get data from input
        hf = ancestor(hp, 'figure');
        ha = ancestor(hp, 'axes');
        lx = get(hp, 'XData');
        ly = get(hp, 'YData');
    end
    
    if iscell(hf), hf = hf{1}; end
    if iscell(ha), ha = ha{1}; end
    hold(ha, 'on');
    if isempty(findobj(ha, 'tag', 'marker'))
        marker = plot([0], [0], 'ro', 'ButtonDownFcn', @ButtonDownFcn, 'tag', 'marker', 'parent', ha);
    end

    hold(ha, 'off');
    
    % ... and bind the windowButtonMotionFuction to monitor mouse movements
    oldWBMF = get(hf, 'WindowButtonMotionFcn');
    set(hf, 'WindowButtonMotionFcn', @motion)
    setappdata(hf, 'buttonDown', false);
    setappdata(hf, 'cleanupfcn', @cleanup);
    
    function cleanup
        try
            set(hf, 'WindowButtonMotionFcn', oldWBMF)
        end
        try
            rmappdata(hf, 'buttonDown');
        end
        try
            rmappdata(hf, 'wasEndpoint');
        end
    end
    
    function motion(varargin)
        if gcf~=hf, return; end % early bail out
        % Check if the mouse if over the axis
        [is_overaxes, mousepos] = isoveraxes(ha);
        if is_overaxes
            [px, py, idx, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
            col = 'r';
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
                
                col = 'g'; 
                
                
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
%                centerPoint = false(size(n));
%                centerPoint(nm+1) = true;
                
                % circular condition
                if isCircular
                    n2 = n;
                    n2(n2>length(lx)) = n2(n2>length(lx))-length(lx); 
                    n2(n2<1) = length(lx)+n2(n2<1);
                else
                    n2 = n;
                    intoWeight(n2>length(lx)) = [];
%                    centerPoint(n2>length(lx)) = [];
                    n2(n2>length(lx)) = []; 
                    intoWeight(n2<1) = [];
%                    centerPoint(n2<1) = [];
                    n2(n2<1) = [];
                    n = n2;
                end

                ly(idx) = mousepos(2);
                lx(idx) = mousepos(1);
                %lx(n) = interp1(n([1:3,nm+1,end-2:end]), lx(n([1:3,nm+1,end-2:end])), n, 'pchip');
                toInterpolate  = unique(n(intoWeight), 'stable');
                toInterpolate2 = unique(n2(intoWeight), 'stable');
                %toInterpolate = n(in)
                %toInterpolate = unique(n([1,nm+1,end]), 'stable');
                ly(n2) = interp1(toInterpolate, ly(toInterpolate2), n, 'pchip');
                lx(n2) = interp1(toInterpolate, lx(toInterpolate2), n, 'pchip');

%                 ly(n2(centerPoint)) = mousepos(2);
%                 lx(n2(centerPoint)) = mousepos(1);
                
                s = [0, cumsum(sqrt((lx(2:end)-lx(1:end-1)).^2 + (ly(2:end)-ly(1:end-1)).^2), 2)];
                d = diff(s);
                remove = (d==0);
                s(remove) = [];
                ly(remove) = [];
                lx(remove) = [];
                %ly = interp1(s, ly, linspace(0, max(s), length(ly)));
                %lx = interp1(s, lx, linspace(0, max(s), length(lx)));
                ly = interp1(s, ly, linspace(0, s(end), ceil(s(end))));
                lx = interp1(s, lx, linspace(0, s(end), ceil(s(end))));

                
                if length(hp)>1
                    set(hp(lineIDX), 'XData', lx, 'YData', ly);
                    lx = get(hp, 'XData');
                    ly = get(hp, 'YData');
                else
                    set(hp, 'XData', lx, 'YData', ly);
                end
            end
            
        end
        
        if doByTag
            marker = findobj(ha, 'tag', 'marker');
            if isempty(marker)
                hold(ha, 'on');
                    marker = plot([0], [0], 'ro', 'ButtonDownFcn', @ButtonDownFcn, 'tag', 'marker', 'parent', ha);
                hold(ha, 'off');
            end
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
            set(marker, 'XData', px(lineIDX), 'YData', py(lineIDX), 'color', col, 'visible', 'on', 'parent', ha);
        else
            set(marker, 'visible', 'off');
        end
    end

    function ButtonDownFcn(varargin)
        % ButtonDownOnMarker / LastPointSelector
        set(hf, 'WindowButtonUpFcn', @buttonUp)
        setappdata(hf, 'buttonDown', true);
        [is_overaxes, mousepos] = isoveraxes(ha);
        [~, ~, idx, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
        setappdata(hf, 'currentIDX', idx);
        setappdata(hf, 'lineIDX', lineIDX);
        setappdata(hf, 'wasEndpoint', 0)
        set(marker, 'color', 'g')
        
        function buttonUp(varargin)
            setappdata(hf, 'buttonDown', false);
            setappdata(hf, 'currentIDX', []);
            setappdata(hf, 'wasEndpoint', 0)
            set(hf, 'WindowButtonUpFcn', []);
            set(marker, 'color', 'r');
            disp('bye')
            % Execute external buttonUpFcn
            if ~isempty(buttonUpFcn)
                feval(buttonUpFcn, lx, ly);
            end
            if doByTag
                hp = findobj(ha, 'tag', tag);
                lx = get(hp, 'XData');
                ly = get(hp, 'YData');
            end
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
            [~, lineIDX] = min(mval); lineIDX = lineIDX(1);
        end
        
        px = cx(lineIDX, idx);
        py = cy(lineIDX, idx);
        
    end

end