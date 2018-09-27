function [hFig, ha, hs] = sliderGUI(frameUpdateFunction, imdata, minmaxsteps, figure_tag)

    % Default Values
    if ~exist('frameUpdateFunction', 'var') % For debugging/developing
        frameUpdateFunction = @(varargin) disp(varargin{1});
    end
    if ~exist('imdata', 'var')
        imdata = rand(400);
    end
    if ~exist('minmaxsteps', 'var')
        minmaxsteps = [1, 100, 1, 10];
    end
    if ~exist('figure_tag', 'var')          % To ensure we can find our GUI again on 2nd call
        figure_tag = 'tks3_slidergui';
    end
    
    % Make / Get debugging figure and axes
    hFig = findobj(0, 'Parent', 0, 'Tag', figure_tag);
    if isempty(hFig)
        % % % %
        % 1) Make figure
        hFig = figure('Tag', figure_tag, 'Units', 'Pixel', 'NumberTitle', 'off'); 
        fsize = get(hFig, 'position');
        % 1A) Make Axes
        pos = [2, 32, fsize(3)-1, fsize(4)-31];
        ha = gca(hFig); 
        set(ha, 'Units', 'Pixel', 'Position', pos, 'Tag', [figure_tag, '_axes']);
        % 1A-2) Make imscrollpanel
        hi = imshow(imdata, 'parent', ha);
        himscrollpanel     = imscrollpanel(hFig, hi, @ImageChangedFunction);
        himscrollpanel_api = iptgetapi(himscrollpanel);
        set(himscrollpanel, 'units', 'pixel', 'position', pos, 'BackgroundColor', [0.5,0.5,0.5]);
        setappdata(hFig, 'axes', ha);
        setappdata(hFig, 'himscrollpanel_api', himscrollpanel_api);
        % 1A-2) Add zoomtools
        [hp, toolsCallback, RestorePositionCallback] = makeZoomTools(himscrollpanel);
        setappdata(hFig, 'toolsCallback', toolsCallback);
        setappdata(hFig, 'RestorePositionCallback', RestorePositionCallback);
        % 1B) Make a slider...
        pos = [7, 7, fsize(3)-13, 19];
        hs = uicontrol('Style', 'Slider', 'parent', hFig, 'units', 'pixel', 'position', pos, 'min', minmaxsteps(1), 'max', minmaxsteps(2), 'Value', 1, 'SliderStep', minmaxsteps(3:4)/(minmaxsteps(2)-minmaxsteps(1)));
        a = addlistener(hs,   'Value', 'PostSet', @(s,e) updateFrame(hs)); % ... which supports continious updating
        setappdata(hs, 'Listener_Slidervalue', a);
        setappdata(hFig, 'slider', hs);
        % % % %
        % 2) Set everything up for resizing
        handles.figure1 = hFig;
        handles.to_resize = [ himscrollpanel, hs, hp];
        handles.dock_top    = [1, 0, 1];
        handles.dock_bottom = [1, 1, 0];
        handles.dock_left   = [1, 1, 0];
        handles.dock_right  = [1, 1, 1];
        set([handles.figure1, handles.to_resize], 'units', 'pixel');
        handles.start_fig_pos = get(handles.figure1,   'position');
        handles.start_pos     = get(handles.to_resize, 'position');
        %set(handles.figure1, 'ResizeFcn',  @(varargin) figureResizeFunction(handles, varargin));
        set(handles.figure1, 'ResizeFcn',  @(varargin) cellfun(@(x) feval(x, varargin{:}), {@(varargin) guitools.resize_function(handles, varargin{:}),...
                                                                                            @(varargin) toolsCallback()}));
    
        
    else
        % Get the interface
        hs                      = getappdata(hFig, 'slider');
        ha                      = getappdata(hFig, 'axes');
        himscrollpanel_api      = getappdata(hFig, 'himscrollpanel_api');
        toolsCallback           = getappdata(hFig, 'toolsCallback');
        RestorePositionCallback = getappdata(hFig, 'RestorePositionCallback');
        % Update Callback
        a = getappdata(hs, 'Listener_Slidervalue');
        a.Callback = @(s,e)updateFrame(hs);
        % Update Image
        himscrollpanel_api.replaceImage(imdata);
        ImageChangedFunction();
    end
    updateFrame(hs)

    % Slider Changed Callback
    function updateFrame(hSlider)
        currentValue = get(hSlider, 'Value');
        if isa(frameUpdateFunction, 'function_handle')
            frameUpdateFunction(currentValue, [hFig, ha, hs])
        end
    end

    function ImageChangedFunction(varargin)
        toolsCallback();
        RestorePositionCallback();
    end

    function [hpanel, ImageToolsCB, RestorePositionCB] = makeZoomTools(hImscrollPanel)
        spAPI = iptgetapi(hImscrollPanel);
        sppos = get(hImscrollPanel, 'position');
        parent = get(hImscrollPanel, 'parent');
        
        magboxwidth  = 70;
        magboxheight = 20;

        popupwidth = 150;
        popupheight = 20;
        popupfontsize = 9;

        buttonwidth  = 20;
        buttonheight = 20;

        xgap = 10;
        ygap = 7;
        
        meth = {'Fit 2/3 of image height',...
                'Fit image',...
                'Fit image height',...
                'Fit image width',...
                '50%',...
                '100%',...
                '200%',...
                'Custom'};
        
        paneldim = [4*xgap+magboxwidth+popupwidth+2*buttonwidth,   1.6*ygap+popupheight];
        hpanel = uipanel(parent, 'Units', 'Pixel',....
                                 'Position', [sum(sppos([1,3]))-paneldim(1)-14, sum(sppos([2,4]))-paneldim(2)-1, paneldim],...
                                 'FontSize', 9,...
                                 'FontWeight', 'normal',...
                                 ...'Title', 'Zoom',...
                                 'BorderType', 'Line');
        
        hpopup = uicontrol(hpanel, 'Style',    'popupmenu',...
                                   'String',   meth,...
                                   'Units',    'pixel',...
                                   'FontSize', popupfontsize,...
                                   'Position', [xgap, ygap, popupwidth, popupheight],...
                                   'Callback', @ImageToolsCallback);
                       
        him = findobj(hImscrollPanel, 'type', 'image');
        hMagBox = immagbox(hpanel, him);
        cbmb = get(hMagBox, 'Callback');
        set(hMagBox, 'Units', 'pixel',...
                     'Position', [xgap+popupwidth+xgap, ygap-1, magboxwidth, magboxheight],...
                     'Callback', @(varargin) cellfun(@(x) feval(x, varargin{:}), {@(varargin) feval(cbmb, varargin{1}),...
                                                                                  @(varargin) set(hpopup, 'Value', find(strcmpi(meth, 'Custom')))}));
    
        hbplus = uicontrol(hpanel, 'Style', 'Pushbutton', ...
                                   'String', '+',...
                                   'Units',  'pixel', ...
                                   'Position', [xgap+popupwidth+xgap+magboxwidth+xgap/2, ygap-1, buttonwidth, buttonheight],...
                                   'Callback', @(varargin) cellfun(@(x) feval(x, varargin{:}), {@(varargin) spAPI.setMagnification(spAPI.getMagnification()+0.25),...
                                                                                                @(varargin) set(hpopup, 'Value', find(strcmpi(meth, 'Custom'))),...
                                                                                                @(varargin) setpref('zoomtool', 'lastCustomMagnification', spAPI.getMagnification())}));
        hbminus = uicontrol(hpanel, 'Style', 'Pushbutton', ...
                                    'String', '-',...
                                    'Units',  'pixel', ...
                                    'Position', [xgap+popupwidth+xgap+magboxwidth+xgap/2+buttonwidth+xgap/2, ygap-1, buttonwidth, buttonheight],...
                                    'Callback', @(varargin) cellfun(@(x) feval(x, varargin{:}), {@(varargin) spAPI.setMagnification(spAPI.getMagnification()-0.25),...
                                                                                                 @(varargin) set(hpopup, 'Value', find(strcmpi(meth, 'Custom'))),...
                                                                                                 @(varargin) setpref('zoomtool', 'lastCustomMagnification', spAPI.getMagnification())}));
        spAPI.addNewLocationCallback(@NewImageLocationCallback);
        ImageToolsCB = @ImageToolsCallback;
        RestorePositionCB = @RestorePositionCallback;
        
        function NewImageLocationCallback(varargin)
            stack = dbstack;
            if ~any(ismember({'imscrollpanel/replaceImage', 'sliderGUI/makeZoomTools/ImageToolsCallback'}, {stack.name}))
                newPos = spAPI.getVisibleLocation();
                setpref('zoomtool', 'lastVisibleLocation', newPos);
            end
        end
        
        function RestorePositionCallback(varargin)
            if ispref('zoomtool', 'lastVisibleLocation');
                newPos = getpref('zoomtool', 'lastVisibleLocation');
                spAPI.setVisibleLocation(newPos);
            end
        end
        
        function ImageToolsCallback(varargin)
            methods = cellstr(get(hpopup, 'String'));
            selVal = methods{get(hpopup, 'Value')};
            
            switch selVal

                case 'Fit 2/3 of image height'
                    him = findobj(hImscrollPanel, 'type', 'image');
                    im1 = get(him, 'CData');
                    visRect = spAPI.getViewport();
                    newMag = visRect(2)/(3/2*size(im1, 1));
                    
                case 'Fit image',...
                    newMag = spAPI.findFitMag();

                case 'Fit image height'
                    him = findobj(hImscrollPanel, 'type', 'image');
                    im1 = get(him, 'CData');
                    visRect = spAPI.getViewport();
                    newMag = visRect(2)/size(im1, 1);

                case 'Fit image width',...
                    him = findobj(hImscrollPanel, 'type', 'image');
                    im1 = get(him, 'CData');    
                    visRect = spAPI.getViewport();
                    newMag = visRect(1)/size(im1, 2);

                case '50%',...
                    newMag = 0.5;

                case '100%',...
                    newMag = 1;

                case '200%',...
                    newMag = 2;

                case 'Custom'
                    if ispref('zoomtool', 'lastCustomMagnification')
                        newMag = getpref('zoomtool', 'lastCustomMagnification');
                    else
                        newMag = spAPI.getMagnification();
                    end

            end

            spAPI.setMagnification(newMag)
            setpref('zoomtool', 'lastCustomMagnification', newMag);
            
        end
    end

end