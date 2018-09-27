function output_ = fishOrientation_fishPlugin(fobj, varargin)
% FishOrientation - FishPlugin
% Detects the orientation of the fish.
%
% Scientific Software Solutions
% Tobias Kießling 05/2016-08/2016
% support@tks3.de

    %% Plugin Header (Do NOT edit except for the indicated section)
    if ~isdeployed && ~(exist(fullfile(pwd, 'fish_plugin_class.m'), 'file')==2), cd(fileparts(pwd)); end
    thisPlugin = fish_plugin_class;  
    % Link Parameter and Display/Debug Definitions
    thisPlugin.ParameterDefinitionsFCN  = @ParameterDefinitions;
    % Link Callbacks
    thisPlugin.calculationFunction = @(varargin) CalculationFunction(thisPlugin.fish, varargin{:});
    thisPlugin.ManualSelectionFcn  = @(varargin) manualModeFunction( thisPlugin.fish, varargin{:});
    thisPlugin.drawingFunction     = @(varargin) DrawingFunction(    thisPlugin.fish, varargin{:});
    thisPlugin.mainDrawingFunction = @(varargin) MainDrawingFunction(thisPlugin.fish, varargin{:});
    % ----- EDIT ONLY FROM HERE -------------------------
    thisPlugin.plugin_tag          = 'fishOrientation';
    thisPlugin.plugin_name         = 'FishOrientation';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {'fishEye', 'fishContour'};
    thisPlugin.hasManualMode       = true;
    thisPlugin.helpURL             = 'help\fishOrientation.html';
    % ----- ...UNTIL HERE -------------------------------
    % Debugging/Developing:
    if ~ismember('getFishPlugin', varargin) % Called without argument?
        if ~exist('fobj', 'var')            % No fishobject was provided? 
            fobj = thisPlugin.uiGetFish;    % => Let the user select an image file)
        end  
        thisPlugin.set_fishobj(fobj);
        thisPlugin.GUIcreationFCN();        % => Create ParameterPannel
    end
    output_ = thisPlugin;
    
    %% Plugin Functions (Here is where the Parameters, Calculations, and Drawings are implemented)
    
    function [parameter, displays, debugs] = ParameterDefinitions(fobj)

        % ===========    TAG                 NAME                TYPE        DEFAULT     MIN     MAX     INCREMENT  HasAuto
        parameter = cell(0, 8);  %{'parameter1',        'parameter1',       'numeric',  20,         0,      Inf,    1,         false};%   ;...
                       % 'horizCutoff',      'horizCutoff',      'numeric',  20,         0,      Inf,    1,         false;...
                       % 'imclose_disksize', 'imclose_disksize', 'numeric',  5,          0,      Inf,    1,         false};

        % ===========   TAG                 NAME                DEFAULT AddOPACITY     OpacityDEFAULT
        displays  = {   'showOrientation',  'showOrientation',  true,   false,         NaN     };

        % ===========   TAG             NAME                DebugTAG        AddOPACITY      OpacityDEFAULT
        debugs    = { };%'debug_here',   'debug_here',       'getCapillary', false,          NaN     };%...
                        %'debug2',       'DebugName2',       'DebugTag2',    false,          NaN     };
            
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end
        
    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
%         disp('Calculation Function')
%         disp(parameterValues);
%         disp(debugStatus);
        
        % Calculate Output
        % 1) Get input image
        im0 = fobj.getImdata('toGray', 'invert');
        output.step1_inputImage = im0;

        % 2) Determine horizontal orientation
%         % Unwrap the Eye-region and find column with maximum sum of pixel values
%         [im_unwrapped, x_imi, y_imi] = imunwrap_poly(im2double(im0), fobj.fishEye.shape.x, fobj.fishEye.shape.y);
%         [~, max_col] = max(sum(im_unwrapped,1)); mid = (size(y_imi, 1)+1)/2;
%         output.step2_unwrappedEye       = im_unwrapped;
%         output.step2_unwrapped_x        = x_imi;
%         output.step2_unwrapped_y        = y_imi;
%         output.step2_max_col            = max_col;
%         output.step2_horizontally_correct = x_imi(1, max_col) > x_imi(mid, max_col);
%         
        fishContour = fobj.fishContour.shape(strcmp({fobj.fishContour.shape.name}, 'fineContour'));
        fcenter_x = (max(fishContour.x) + min(fishContour.x))/2;
        output.step2_horizontally_correct = mean(fobj.fishEye.shape.x) < fcenter_x;
        
        % output.step2_vertically_correct = y_imi(1, max_col) < y_imi(mid, max_col);                % Attempt1 for VERTICAL orientation: Doesn't work with 96h embryos :-(            
%                 % Debug view
%                 if ~ishandle(123); figure(123); end; 
%                 imshow(im0, 'parent', gca(123)); hold(gca(123), 'on'); 
%                     plot(fishEye(:,1),          fishEye(:,2),                   'parent', gca(123)); 
%                     plot(x_imi(:, max_col),     y_imi(:, max_col),              'parent', gca(123)); 
%                     plot(x_imi(1, max_col),     y_imi(1, max_col),      '+',    'parent', gca(123)); 
%                     plot(x_imi(mid, max_col),   y_imi(mid, max_col),    'o',    'parent', gca(123)); 
%                 hold(gca(123), 'off');

        % 3) Deterimine vertical orientation                                                        % Attempt2 for vertical orientation: Less clean but stably works
        % Generate Masks from contour data
        
        mask = poly2mask(fishContour.x, fishContour.y, size(im0,1), size(im0,2));
%        eyerad = (max(fobj.fishEye.shape.x,[],2)-min(fobj.fishEye.shape.x,[],2));

        
        wmask = nan(size(mask)); wmask(mask) = 1;
%         f1 = -2;
%         f2 = 15;
%         if output.step2_horizontally_correct
%             wmask(:,     ceil(max(fobj.fishEye.shape.x',[],1) + f2*eyerad):end ) = NaN;
%             wmask(:,     1:ceil(max(fobj.fishEye.shape.x',[],1) - f1*eyerad) ) = NaN;
%         else
%             wmask(:,     1:floor(min(fobj.fishEye.shape.x',[],1) - f2*eyerad)     ) = NaN;
%             wmask(:,     ceil(min(fobj.fishEye.shape.x',[],1) + f1*eyerad):end ) = NaN;
%         end
%       
        flength =   (max(fishContour.x) - min(fishContour.x));
        f = 0.6;
        if output.step2_horizontally_correct
            wmask(:,     1:floor(max(fishContour.x)-f*flength) )      = NaN;
        else
            wmask(:,     end:-1:ceil(min(fishContour.x)+f*flength) ) = NaN;
        end
        
        wmask = wmask.*repmat((1:size(mask,1))', 1, size(mask,2)); 
        w2 =    wmean( repmat((1:size(mask,1))', 1, size(mask,2)), double(mask), 1);
        w2 = repmat(w2, size(mask,1), 1);
        
        upp = wmask<w2;
        low = wmask>w2;
%         im0_ = double(im0);
%         upp_mean = median(im0_(upp));
%         low_mean = median(im0_(low));
        
        im0_ = im2bw(im0, min([1.2*graythresh(im0(upp|low)), 0.95]));
        upp_mean = sum(im0_(upp))/sum(upp(:));
        low_mean = sum(im0_(low))/sum(low(:));
        
%         disp(['upper_mean: ', num2str(upp_mean), '   lower_mean: ', num2str(low_mean)]);
%         % Debug view 
%         if ~ishandle(123); figure(123); end; 
%         imshow(im0_, 'parent', gca(123)); 
%         hold(gca(123), 'on'); 
%             visboundaries(gca(123), bwboundaries(upp), 'LineWidth', 1, 'EnhanceVisibility', false, 'Color', 'blue', 'LineStyle', '--');
%             visboundaries(gca(123), bwboundaries(low), 'LineWidth', 1, 'EnhanceVisibility', false, 'Color', 'green', 'LineStyle', '--');
%         hold(gca(123), 'off');
        
        output.step3_vertically_correct = upp_mean<low_mean;
        
%         meany = double(im0); meany(meany<repmat(nanmax(meany,[],1)*5/10, size(meany,1), 1)) = 0;
%         meany = wmean(repmat((1:size(mask,1))', 1, size(mask,2)), (meany).*~isnan(wmask), 1);
%         minx = find(~isnan(meany), 1, 'first'); maxx = find(~isnan(meany), 1, 'last');
%         p = polyfit(minx:maxx, meany(minx:maxx), 2);
%         output.step3_mask_full   = mask;
%         output.step3_mask_eroded = mask2;
%         output.step3_found_wmean = meany;
%         output.step3_polyfit     = p;
%         output.step3_vertically_correct = p(1)>0;
%                 % Debug view of weighted mean and polyfit
%                 if ~ishandle(123); figure(123); end; 
%                 imshow(uint8(im0).*uint8(mask2), 'parent', gca(123)); 
%                 hold(gca(123), 'on'); 
%                     visboundaries(gca(123), bwboundaries(~isnan(wmask)), 'LineWidth', 1, 'EnhanceVisibility', false, 'Color', 'blue', 'LineStyle', '--');
%                     plot(polyval(p, 1:size(mask,2)), 'parent', gca(123)); 
%                     plot(meany, 'r', 'parent', gca(123));                     
%                 hold(gca(123), 'off');
%                 
% 
%         % 4) Store orientation in object
%         obj.props.horizontally_flipped = ~output.step2_horizontally_correct;
%         obj.props.vertically_flipped = ~output.step3_vertically_correct;
            
        
        % Return Output
        calculationResults = struct('mode',                 'auto',...
                                    'parameter',            parameterValues,...
                                    'horizontally_flipped', ~output.step2_horizontally_correct,...
                                    'vertically_flipped',   ~output.step3_vertically_correct);

    end


    function manualModeFunction(fobj, ha, modeStatus, calculationResults,  parameterValues, debugStatus, ManualSelectionUpdateFCN)
               
        % Get parent figure
        hf = get(ha.axes1, 'parent');
        while ~strcmp('figure', get(hf, 'Type')), hf = get(hf, 'parent'); end

        oldWBMF = get(hf, 'WindowButtonMotionFcn');
        setappdata(hf, 'cleanupfcn', @cleanup);
        
        switch modeStatus

            case {'manual', 'off', 0, false}
                %set(ha.axes1, 'ButtonDownFcn', @manual_mode_button_down_fcn);
                calculationResults.mode = 'manual';
                ManualSelectionUpdateFCN(calculationResults);
                orientationSelector('orientationArrow');
                
            case {'auto', 'on', 1, true}
                set(ha.axes1, 'ButtonDownFcn', []);
                set(hf, 'WindowButtonMotionFcn', []);
                
        end

        function cleanup
            set(hf, 'WindowButtonMotionFcn', oldWBMF)
            if isappdata(hf, 'buttonDown') ,rmappdata(hf, 'buttonDown'); end
        end
        
        function orientationSelector(tag)
            setappdata(hf, 'buttonDown', false);
            set(hf, 'WindowButtonMotionFcn', @motion)
            hflipped = fobj.fishOrientation.horizontally_flipped;
            vflipped = fobj.fishOrientation.vertically_flipped;
                        
            function motion(varargin)
                if gcf~=hf, return; end % early bail out
                % Check if the mouse if over the axis
                [is_overaxes, mousepos] = isoveraxes(ha.axes1);
                hm = getMarker;
                if is_overaxes
                    
                    if getappdata(hf, 'buttonDown')
                        center = getappdata(hm, 'center');
                        hp = getappdata(hm, 'hp');
                        
                        hflipped = center(1)<mousepos(1);
                        vflipped = center(2)>mousepos(2);
                       
                        % Calculate new orientation
                        startpos = center; %[size(im, 2)./2, size(im, 1)./2];
                        fe = fobj.fishEye.shape;
                        mindiameter = 10;%
                        vec = [-1, 1].*max([mindiameter, max(fe.x)-min(fe.x), max(fe.y)-min(fe.y)])./2;%startpos./3;
                        endpos  = startpos + vec - 2.*vec.*[hflipped, vflipped];
                        
                        % Draw new orientation
                        hm.XData = endpos(1);
                        hm.YData = endpos(2);
                        hp.UData = endpos(1)-startpos(1);
                        hp.VData = endpos(2)-startpos(2);
                        
                    end

                    %set(hm, 'visible', 'on');
                    
                else
                    %set(hm, 'visible', 'off');
                end
            end
            
            function marker0 = getMarker
                marker_ = [];
                if isempty(marker_) || ~ishandle(marker_)
                    marker0 = findobj(ha.axes1, 'tag', 'marker');
                else
                    marker0 = marker_;
                end
                if isempty(marker0)
                    hp = findobj(ha.axes1, 'tag', tag);
                    hold(ha.axes1, 'on')
                        msize = round(sqrt(hp.UData.^2 + hp.VData.^2)/2.5);
                        marker0 = plot(hp.XData+hp.UData, hp.YData+hp.VData, 'ro', 'markerSize', msize, 'parent', ha.axes1, 'buttonDownFcn', @manual_mode_button_down_fcn, 'tag', 'marker', 'LineWidth', 2);
                        setappdata(marker0, 'center', [hp.XData, hp.YData]);
                        setappdata(marker0, 'hp', hp);
                    hold(ha.axes1, 'off')
                end
                marker_ = marker0;
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

            function manual_mode_button_down_fcn(varargin)
                set(hf, 'WindowButtonUpFcn', @manual_mode_button_up_fcn);
                setappdata(hf, 'buttonDown', true)
                hm = getMarker;
                hm.LineWidth = 4;
            end
            
            function manual_mode_button_up_fcn(varargin)
                setappdata(hf, 'buttonDown', false);
                hm = getMarker;
                hm.LineWidth = 2;
                
                % Button is up again
                set(hf,     'WindowButtonUpFcn', []);

                % Return Output
                calculationResults = struct('mode',                 'manual',...
                                            'parameter',            parameterValues,...
                                            'horizontally_flipped', hflipped,...
                                            'vertically_flipped',   vflipped);

                ManualSelectionUpdateFCN(calculationResults, true);

            end

        end
        
    end


    drawArrow = @(x,y, ha, sizy) quiver(ha, x(1),y(1),x(2)-x(1),y(2)-y(1), 'g', 'LineWidth', 2, 'MaxHeadSize', sizy/norm([x(2)-x(1),y(2)-y(1)]), 'tag', 'orientationArrow');

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
        
        im = fobj.getImdata('toGray', 'subtractBackground');
        oldTag        = get(ha.axes1, 'Tag');          % The Tag-property and ButtonDownFcn are erased when using imshow
        oldBtnDownFcn = get(ha.axes1, 'ButtonDownFcn');        
        imh = imshow(im, 'parent', ha.axes1);
        set(imh, 'ButtonDownFcn', oldBtnDownFcn);
        set(ha.axes1, 'Tag', oldTag, 'ButtonDownFcn', oldBtnDownFcn);      % This way we keep the Tag/ButtonDownFcn despite of imshow
        
        % % % %
        % Display Binary Shape
        hold(ha.axes1, 'on');
            % Draw eye
            fe = fobj.fishEye.shape;
            he = plot(fe.x, fe.y, 'g', 'parent', ha.axes1);
            center = mean([fe.x', fe.y'], 1);
            % Draw Orientation
            startpos = center; %[size(im, 2)./2, size(im, 1)./2];
            mindiameter = 10;%
            vec = [-1, 1].*max([mindiameter, max(fe.x)-min(fe.x), max(fe.y)-min(fe.y)])./2;%startpos./3;
            endpos  = startpos + vec - 2.*vec.*[calculationResults.horizontally_flipped, calculationResults.vertically_flipped];
            hp = drawArrow([startpos(1), endpos(1)], [startpos(2), endpos(2)], ha.axes1, 100);        
        hold(ha.axes1, 'off');
        if ~displayStatus.showOrientation    
            set([he, hp], 'visible', 'off');
        end

    end

    function MainDrawingFunction(fobj, ha, calculationResults)
        % Draw eye
        fe = fobj.fishEye.shape;
        %plot(fe.x, fe.y, 'g', 'parent', ha);
        center = mean([fe.x', fe.y'], 1);
                
        startpos = center; %[size(im, 2)./2, size(im, 1)./2];
        mindiameter = 10;%
        vec = [-1, 1].*max([mindiameter, max(fe.x)-min(fe.x), max(fe.y)-min(fe.y)])./2;%startpos./3;
        endpos  = startpos + vec - 2.*vec.*[calculationResults.horizontally_flipped, calculationResults.vertically_flipped];
        drawArrow([startpos(1), endpos(1)], [startpos(2), endpos(2)], ha, 100);
                
    end

end