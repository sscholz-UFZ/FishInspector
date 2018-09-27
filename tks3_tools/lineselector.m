function lineselector(buttonUpFcn, hp, interactionRadius)
% LINESELECTOR(buttonUpFcn, hp, lastPointSelector)
% Small GUI plug-in to allow users to modify lines.
%
% Scientific Software Solutions
% Tobias Kießling 01/2013-08/2016
% support@tks3.de

    if ~exist('buttonUpFcn', 'var'), buttonUpFcn = []; end
    if ~exist('interactionRadius', 'var'), interactionRadius = 20; end
    plotLastPointSelector = true;
    
    doByTag = false;
    if ~exist('hp', 'var')
        % Create a Figure and an Image where everything happens
        hf = figure;
        ha = gca;
        hw = 300; hh = 100;
        Im = zeros(hh, hw);
    
        % The Contour
        lx = 10:hw-9;
        ly = hh./2.*ones(size(lx));

        % Set up the GUI
        imshow(Im); hold on; 
        hp = plot(lx,ly);
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
    if plotLastPointSelector
        if iscell(lx)
            [~, maxIDX] = max(lx{1});
            [~, minIDX] = min(lx{1});            
            xmin = lx{1}(minIDX);
            xmax = lx{1}(maxIDX);
        else
            [~, maxIDX] = max(lx);
            [~, minIDX] = min(lx);
            xmin = lx(minIDX);
            xmax = lx(maxIDX);
        end
        ylims = ylim(ha);
        o = 0;
        marker_min = plot([1,1].*xmin-o, ylims, 'r', 'ButtonDownFcn', @ButtonDownFcn2, 'tag', 'marker_min', 'parent', ha);
        marker_max = plot([1,1].*xmax+o, ylims, 'r', 'ButtonDownFcn', @ButtonDownFcn2, 'tag', 'marker_max', 'parent', ha);
        
        iptPointerManager(hf, 'enable');
        enterFcnLine = @(f,cp) set(f, 'Pointer', 'left');
        iptSetPointerBehavior(marker_min, enterFcnLine);
        iptSetPointerBehavior(marker_max, enterFcnLine);
    end
    hold(ha, 'off');
    
    % ... and bind the windowButtonMotionFuction to monitor mouse movements
    oldWBMF = get(hf, 'WindowButtonMotionFcn');
    set(hf, 'WindowButtonMotionFcn', @motion)
    setappdata(hf, 'buttonDown', false);
    setappdata(hf, 'limitsButtonDown', false);
    
    setappdata(hf, 'cleanupfcn', @cleanup);
    
    function cleanup
        set(hf, 'WindowButtonMotionFcn', oldWBMF)
        try
            rmappdata(hf, 'buttonDown');
        end
        try
            rmappdata(hf, 'limitsButtonDown');
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
                idx = getappdata(hf, 'currentIDX');

                [~, idx] = min(abs(mousepos(1)-lx));
                
                nm = interactionRadius;
                n = idx-nm:idx+nm;
                if false && isCircular
                    n(n>length(lx)) = n(n>length(lx))-length(lx); 
                    n(n<1) = length(lx)+n(n<1);
                else                    
                    n(n>length(lx)) = length(lx); 
                    n(n<1) = 1;
                end

                ly(idx) = mousepos(2);
                %lx(n) = interp1(n([1:3,nm+1,end-2:end]), lx(n([1:3,nm+1,end-2:end])), n, 'pchip');
                toInterpolate = unique(n([1:3,nm+1,end-2:end]), 'stable');
                ly(n) = interp1(toInterpolate, ly(toInterpolate), n, 'pchip');

                if length(hp)>1
                    set(hp(lineIDX), 'XData', lx, 'YData', ly);
                    lx = get(hp, 'XData');
                    ly = get(hp, 'YData');
                else
                    set(hp, 'XData', lx, 'YData', ly);
                end
            end
            
            if getappdata(hf, 'limitsButtonDown')
                limiter = getappdata(hf, 'selectedLimit');
                switch limiter
                    case marker_min
                        maxi = max(marker_max.XData)-o-1;
                        mini = min(ha.XLim);
                        
                    case marker_max
                        maxi = max(ha.XLim);
                        mini = min(marker_min.XData)+o+1;
                end
                limiter.XData = round([1, 1].*min(max(mousepos(1), mini), maxi));
            end
            
        end
        
        if doByTag
            marker = findobj(ha, 'tag', 'marker');
            if isempty(marker)
                hold(ha, 'on');
                    marker = plot([0], [0], 'ro', 'ButtonDownFcn', @ButtonDownFcn, 'tag', 'marker', 'parent', ha);
                    
                    if iscell(lx)
                        [~, maxIDX_] = max(lx{1});
                        [~, minIDX_] = min(lx{1});            
                        xmin_ = lx{1}(minIDX_);
                        xmax_ = lx{1}(maxIDX_);
                    else
                        [~, maxIDX_] = max(lx);
                        [~, minIDX_] = min(lx);
                        xmin_ = lx(minIDX_);
                        xmax_ = lx(maxIDX_);
                    end
                    marker_min = plot([1,1].*xmin_-o, ylims, 'r', 'ButtonDownFcn', @ButtonDownFcn2, 'tag', 'marker_min', 'parent', ha);
                    marker_max = plot([1,1].*xmax_+o, ylims, 'r', 'ButtonDownFcn', @ButtonDownFcn2, 'tag', 'marker_max', 'parent', ha);
                    iptPointerManager(hf);
                    enterFcnLine = @(f,cp) set(f, 'Pointer', 'left');
                    iptSetPointerBehavior(marker_min, enterFcnLine);
                    iptSetPointerBehavior(marker_max, enterFcnLine);
        
                hold(ha, 'off');
            end
        end
        if is_overaxes && ~getappdata(hf, 'limitsButtonDown')
            set(marker, 'XData', px(lineIDX), 'YData', py(lineIDX), 'color', col, 'visible', 'on', 'parent', ha);
        else
            set(marker, 'visible', 'off');
        end
    end

    function ButtonDownFcn2(varargin)
        set(hf, 'WindowButtonUpFcn', @buttonUp)
        setappdata(hf, 'limitsButtonDown', true);
        setappdata(hf, 'selectedLimit', varargin{1});
        %set(hf, 'pointer', 'left')
        set(marker, 'visible', 'off');

        function [lx_, ly_] = enlarge_reduce(lx_, ly_, limi)
            xpos = min(limi.XData);
            
            switch upper(limi.Tag(end-2:end))
                case 'MIN'
                    if any(lx_<xpos+o)
                        % we have to remove some points
                        mask = lx_<xpos+o;
                        lx_(mask) = [];
                        ly_(mask) = [];
                        
                    elseif (xpos+o)<min(lx_)
                        % we have to add some points
                        [~, minIDX_] = min(lx_);
                        toInsert_x = (xpos+o):(min(lx_)-1);
                        toInsert_y = repmat(ly_(minIDX_), size(toInsert_x));
                        lx_ = [toInsert_x, lx_];
                        ly_ = [toInsert_y, ly_];
                        
                    end
                    
                case 'MAX'
                    if any(lx_>(xpos-o))
                        % we have to remove some points
                        mask = lx_>(xpos-o);
                        lx_(mask) = [];
                        ly_(mask) = [];
                    
                    elseif (xpos-1)>max(lx_)
                        % we have to add some points
                        [~, maxIDX_] = max(lx_);
                        toInsert_x = (max(lx_)+1):(xpos-o);
                        toInsert_y = repmat(ly_(maxIDX_), size(toInsert_x));
                        lx_ = [lx_, toInsert_x];
                        ly_ = [ly_, toInsert_y];
                        
                    end
                    
            end
        end
        
        function buttonUp(varargin)
            setappdata(hf, 'limitsButtonDown', false);
            %set(hf, 'pointer', 'arrow');
            limi = getappdata(hf, 'selectedLimit');
            
            if doByTag
                hp = findobj(ha, 'tag', tag);
                lx = get(hp, 'XData');
                ly = get(hp, 'YData');
            end
            
            if iscell(lx)
                for i = 1:length(lx)
                    [lx{i}, ly{i}] = enlarge_reduce(lx{i}, ly{i}, limi);
                    set(hp(i), 'XData', lx{i}, 'YData', ly{i});
                end
            else
                [lx, ly] = enlarge_reduce(lx, ly, limi);
                set(hp, 'XData', lx, 'YData', ly);
            end
            
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

    function ButtonDownFcn(varargin)
        % ButtonDownOnMarker / LastPointSelector
        iptPointerManager(hf, 'disable');
        set(hf, 'WindowButtonUpFcn', @buttonUp)
        setappdata(hf, 'buttonDown', true);
        [is_overaxes, mousepos] = isoveraxes(ha);
        [~, ~, idx, lineIDX] = getNearestPointOnContour(mousepos(1), mousepos(2), lx, ly);
        setappdata(hf, 'currentIDX', idx);
        setappdata(hf, 'lineIDX', lineIDX);
        set(marker, 'color', 'g')
        
        function buttonUp(varargin)
            iptPointerManager(hf, 'enable');
            setappdata(hf, 'buttonDown', false);
            setappdata(hf, 'currentIDX', []);
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