function out = uigetellipse( )
%%    


    cx = 0; cy = 0;
    x1 = 1; y1 = 0;
    x2 = 0; y2 = 1;


    hf = figure;
    ha = gca(hf); 
    hold(ha, 'on');
    
    ellipseContour = plot(cx, cy, 'g', 'LineWidth', 2, 'parent', ha);
    centerPoint = plot(cx, cy, 'xr', 'MarkerSize', 8, 'LineWidth', 2, 'parent', ha, 'ButtonDownFcn', @btn_down);
    axis1 = plot(x1, y1, 'ok', 'MarkerSize', 8,'LineWidth', 2, 'MarkerFaceColor', 'w', 'parent', ha, 'ButtonDownFcn', @btn_down);
    axis2 = plot(x2, y2, 'ok', 'MarkerSize', 8,'LineWidth', 2, 'MarkerFaceColor', 'w', 'parent', ha, 'ButtonDownFcn', @btn_down);
    
    
    axis equal
    set(ha, 'xlim', [-1.5, 1.5], 'ylim', [-1.5, 1.5])
    
    
    activePoint = '';
    btn_move();
    
    function btn_down(varargin)
        activePoint = varargin{1};
        set(hf, 'WindowButtonMotionFcn', @btn_move,...
                'WindowButtonUpFcn',     @btn_up);
    end

    function btn_move(varargin)
        % % %
        % Update currently active point
        cp = get(ha, 'currentPoint'); cp = [cp(1), cp(3)];              % Get current mouse point
        op = [get(activePoint, 'XData'), get(activePoint, 'YData')];    % Get "old" position
        set(activePoint, 'XData', cp(1), 'YData', cp(2));               % Set new position
        
        % % %
        % Update the other points
        switch activePoint
            case centerPoint
                % We're moving the center point => Just shift all the other points
                cx = cp(1); cy = cp(2);     % Update global center point variable
                shifty = cp-op;             % Calculate shift 
                set(axis1, 'XData', get(axis1, 'XData')+shifty(1),...
                           'YData', get(axis1, 'YData')+shifty(2));
                set(axis2, 'XData', get(axis2, 'XData')+shifty(1),...
                           'YData', get(axis2, 'YData')+shifty(2));
                       
            case {axis1, axis2}
                % We're moving one of the axis => Rotate the second point
                if activePoint == axis1
                    otherPoint = axis2; roti = pi/2;
                else
                    otherPoint = axis1; roti = -pi/2; 
                end
                
                ixi = get(otherPoint, 'XData');
                ysi = get(otherPoint, 'YData');
                
                as1 = atan2((cp(2)-cy), (cp(1)-cx));    
                as2 = atan2((ysi-cy),   (ixi-cx));
                
                angleShift = as1-as2+roti;
                set(otherPoint, 'XData', cx+(ixi-cx)*cos(angleShift)-(ysi-cy)*sin(angleShift),...
                                'YData', cy+(ysi-cy)*cos(angleShift)+(ixi-cx)*sin(angleShift));
        end
        
        % % %
        % Update rotated ellipse contour plot
        phi = -pi:0.05:pi;
        phi0 = atan2((get(axis1, 'YData')-cy), (get(axis1, 'XData')-cx));
        a = sqrt((get(axis1, 'XData')-cx).^2 + (get(axis1, 'YData')-cy).^2);
        b = sqrt((get(axis2, 'XData')-cx).^2 + (get(axis2, 'YData')-cy).^2);
        ec = [cx + a.*cos(phi).*cos(phi0) - b.*sin(phi).*sin(phi0); ...
              cy + b.*sin(phi).*cos(phi0) + a.*cos(phi).*sin(phi0)];
        set(ellipseContour, 'XData', ec(1,:), ...
                            'YData', ec(2,:));
        
        set(ha, 'xlim', [-1.5, 1.5], 'ylim', [-1.5, 1.5])
        
    end

    function btn_up(varargin)
        set(hf, 'WindowButtonMotionFcn', [], ...
                'WindowButtonUpFcn',     []);
        btn_move();
        activePoint = ''; 
    end

end

