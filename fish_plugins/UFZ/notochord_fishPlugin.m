function output_ = notochord_fishPlugin(fobj, varargin)
% Capillary - FishPlugin
% Detects the upper and lower contour of the notochord
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
    thisPlugin.plugin_tag          = 'notochord';
    thisPlugin.plugin_name         = 'Notochord';
    thisPlugin.plugin_description  = {'Hello Everybody!', 'This is a test for plugin s.th. into to the fishobj'};
    thisPlugin.plugin_dependencies = {'fishEye', 'fishContour', 'fishOrientation', 'centralDarkLine', 'bladder'};
    thisPlugin.hasManualMode       = true;
    thisPlugin.helpURL             = 'help\notochord.html';
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
    output = [];
    
    %% Plugin Functions (Here is where the Parameters, Calculations, and Drawings are implemented)
    
    function [parameter, displays, debugs] = ParameterDefinitions(fobj)

        % ===========    TAG                            NAME                            TYPE        DEFAULT     MIN     MAX     INCREMENT   HasAuto
        parameter = {   'upper_border_exclude_factor',  'upper_border_exclude_factor',  'numeric',  0.4,        0,      1,      0.05,       false;...
                        'low_thresh',                   'low_thresh',                   'numeric',  0.00,       0,      1,      0.05,       false};

        % ===========   TAG                       NAME                      DEFAULT     AddOPACITY     OpacityDEFAULT
        displays  = {   'plot_Notochord',         'plot_Notochord',         true,       false,         NaN     ;...
                        'showUpperExclusion',     'showUpperExclusion',     false,      false,         NaN     ;...
                        'showLowerExclusion',     'showLowerExclusion',     false,      true,          0.5     };

        % ===========   TAG                     NAME                    DebugTAG                AddOPACITY      OpacityDEFAULT
        debugs    = {  'debug_here',            'debug_here',           'notochord',            false,          NaN     ;...
                       'debug_active_contour',  'debug_active_contour', 'move2extreme_debug',   false,          NaN     };
    
        % % % % % %
        % Synchronize with default Parameter file (Do not edit)
        rewrite_defaults = false;
        parameter = processDefaultParameterFile(thisPlugin, parameter, rewrite_defaults);
    end
        
    function calculationResults = CalculationFunction(fobj, parameterValues, debugStatus, displayStatus)
%         disp('Calculation Function')
%         disp(parameterValues);
%         disp(debugStatus);
        debug_tag = 'centralDarkLine';
        debug_here = debugStatus.debug_here;
        dbug_active_contour = debugStatus.debug_active_contour;
        
        %% Calculate Output
        % 1) Get input and flip if necessary
        im0 = fobj.getImdata('toGray');
        fContour = fobj.fishContour;
        fEye = fobj.fishEye;
        cdl = fobj.centralDarkLine;
        bladder = fobj.bladder;
        hasBladder = ~isempty(bladder) && ~isempty(bladder.shape) && ~any(cellfun(@isempty, {bladder.shape.x}));
        
        if fobj.fishOrientation.horizontally_flipped
            im0 = im0(:, end:-1:1);
            fContour.shape(1).x = size(im0, 2) - fContour.shape(1).x(end:-1:1) + 1;
            fContour.shape(1).y = fContour.shape(1).y(end:-1:1);
            fContour.shape(2).x = size(im0, 2) - fContour.shape(2).x(end:-1:1) + 1;
            fContour.shape(2).y = fContour.shape(2).y(end:-1:1);
            fEye.shape.x = size(im0, 2) - fEye.shape.x(end:-1:1) + 1;
            fEye.shape.y = fEye.shape.y(end:-1:1);
            cdl.shape.x = size(im0, 2) - cdl.shape.x(end:-1:1) + 1;
            cdl.shape.y = cdl.shape.y(end:-1:1);
            if hasBladder
                bladder.shape(1).x = size(im0, 2) - bladder.shape(1).x(end:-1:1) + 1;
                bladder.shape(1).y = bladder.shape(1).y(end:-1:1);
                bladder.shape(2).x = size(im0, 2) - bladder.shape(2).x(end:-1:1) + 1;
                bladder.shape(2).y = bladder.shape(2).y(end:-1:1);
            end
        end
        if fobj.fishOrientation.vertically_flipped
            im0 = im0(end:-1:1, :);
            fContour.shape(1).y = size(im0, 1) - fContour.shape(1).y + 1;
            fContour.shape(2).y = size(im0, 1) - fContour.shape(2).y + 1;
            fEye.shape.y = size(im0, 1) - fEye.shape.y + 1;
            cdl.shape.y = size(im0, 1) - cdl.shape.y + 1;
            if hasBladder
                bladder.shape(1).y = size(im0, 1) - bladder.shape(1).y + 1;
                bladder.shape(2).y = size(im0, 1) - bladder.shape(2).y + 1;
            end
        end
        output.step1_inputImage = im0;
        
        % 2) Generate Masks from fish-contour, fishEye, and centralDarkLine data
        idx = strcmp({fContour.shape.name}, 'fineContour');
        mask = poly2mask(fContour.shape(idx).x, fContour.shape(idx).y, size(im0,1), size(im0,2));
            mask_correcture = (mask==0) & ( (mask([2:end,end],:)==1) | (mask(:,[2:end,end])==1) | (mask([2:end,end], [2:end,end])==1));
        mask(mask_correcture) = 1;        
        rowmat = repmat((1:size(mask))', 1, size(mask,2));
        
        % find upper border of the central line
        [imi, coords_x, coords_y] = imunwrap_poly(im0, cdl.shape.x, cdl.shape.y, 'bilinear', false);
        midi = (size(imi,1)-1)/2;
        imi(midi:end, :) = 0;
        fCutoff = ceil(max(fEye.shape.x)-min(fEye.shape.x));
        imi(:, 1:fCutoff) = 0;
        %imi = imgaussfilt(imi, 1);
        peaky = getPeakImage(imcomplement(imi), ceil(midi/2));
        peaky(peaky<(8*max(peaky(:)/10))) = 0;
        offset =3;
        startline = repmat(midi-offset, 1, size(imi,2));
        startline(1:fCutoff) = midi;% startline(1:fCutoff);%((fCutoff:-1:1)-1).*(offset/fCutoff);
        startline(end:-1:end-fCutoff) = midi;
        lini = fishobj2.move2extreme(peaky, startline, 'max', false, dbug_active_contour);
        
        cutoff=floor(0.2*length(lini));
        lini(end:-1:end-cutoff) = startline((end:-1:end-cutoff));
%         diffi = lini - median(lini);
%         [~, maxIDX] = max(abs(diffi));
%         % linearly cut from the maximum to the end of unwrapped image
%         lini(maxIDX:round(0.9*size(imi,2))) = min(size(imi,1), max(1, round( lini(maxIDX) - ((maxIDX:round(0.9*size(imi,2)))-maxIDX) * (lini(maxIDX)-lini(end))/(size(imi,2)-maxIDX) ) ) );
        % linearly cut from the beginning to the maximum
        %lini(1:maxIDX) = lini(1) - ((1:maxIDX)-1) *(lini(1)-1)/(maxIDX);
        
        globalx = coords_x(sub2ind(size(imi), lini, 1:size(imi,2)));
        globaly = coords_y(sub2ind(size(imi), lini, 1:size(imi,2)));
        newY = interp1(globalx', globaly', cdl.shape.x', 'pchip', 'extrap');
        
        central = nan(1,size(mask,2)); 
%        central(cdl.shape.x') = cdl.shape.y';
        central(cdl.shape.x') = newY;
       
        % Erase everything which is left from the eye-center
        eyecenter = mean([fEye.shape.x', fEye.shape.y'], 1);
        mask(:, 1:floor(eyecenter(1))) = 0;
        
        % A3) remove bladder
        if hasBladder
            bladder = bladder.shape(strcmpi({bladder.shape.name}, 'fineContour'));
            bladder_mask = poly2mask(bladder.x, bladder.y, size(im0,1),  size(im0, 2));
            mask_correcture = (bladder_mask==0) & ( (bladder_mask([2:end,end],:)==1) | (bladder_mask(:,[2:end,end])==1) | (bladder_mask([2:end,end], [2:end,end])==1));
            bladder_mask(mask_correcture) = 1;
            mask(bladder_mask) = 0;
        %else
        %    bladder_mask = false(size(fineContour_mask));
        end
        
        % Erase all pixels below central dark line
        mask(mask.*rowmat > repmat(central, size(mask, 1), 1)) = 0;
        
        % Get upper part of the fish
        nanmask = nan(size(mask)); nanmask(mask) = 1;   % Nan variant of mask
        cropped = im2double(im0).*repmat(nanmask,[1,1,size(im0,3)]);
        output.step2_upper_fishmask = mask;
        output.step2_inputImage_cropped = cropped;


        if debug_here
            h_axes = debugfigure;
            imshow(output.step1_inputImage, 'parent', h_axes(1));
            title(h_axes(1), '1. Crop input image', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
            if isappdata(h_axes(1), 'overlay_axes')
                h2 = getappdata(h_axes(1), 'overlay_axes');
            else
                h2 = axes('parent', get(h_axes(1), 'parent'));
                setappdata(h_axes(1), 'overlay_axes', h2);
                set(h2, 'units', get(h_axes(1), 'units'), 'position', get(h_axes(1), 'position'));
                axis(h2, 'off');
            end
            RGB = zeros([size(output.step2_upper_fishmask), 3]); RGB(:,:,2) = output.step2_upper_fishmask;
            im = imshow(RGB, 'parent', h2);
            set(im, 'AlphaData', 0.5.*double(output.step2_upper_fishmask));

            imshow(output.step2_inputImage_cropped, 'parent', h_axes(2));
            title(h_axes(2), '2. Cropped', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);

        end

        % 3) Don't accept bright pixels close to upper border
        % 3a) Get upper fish border
        mask_temp = nanmask; mask_temp(isnan(mask_temp)) = size(mask,1)+1;
        upper = min(mask_temp .* repmat((1:size(mask,1))', 1, size(mask,2)), [], 1);
        upper(upper == size(mask,1)+1) = NaN;
        % 3b) Get lower fish border
        mask_temp = nanmask; mask_temp(isnan(mask_temp)) = 0;
        lower = max(mask_temp .* repmat((1:size(mask,1))', 1, size(mask,2)), [], 1);
        lower(lower == 0) = NaN;
        % Calculate width at each point
        idxmask = (output.step2_upper_fishmask.* repmat((1:size(mask,1))', 1, size(mask,2)));
        upper_width = abs(lower-upper);
        %upper_width(isnan(upper_width)) = size(mask,1)+1;
        % Remove bright pixels close to upper border

            toRemove = (idxmask >= repmat(upper, size(mask,1), 1)) & (idxmask < repmat(upper+parameterValues.upper_border_exclude_factor.*upper_width, size(mask,1), 1));

        cropped(toRemove) = NaN;
        mask(toRemove) = 0;
        output.step3_upperBorderToRemove = toRemove;

        if debug_here
            if isappdata(h_axes(2), 'overlay_axes')
                h2 = getappdata(h_axes(2), 'overlay_axes');
            else
                h2 = axes('parent', get(h_axes(2), 'parent'));
                setappdata(h_axes(2), 'overlay_axes', h2);
                set(h2, 'units', get(h_axes(2), 'units'), 'position', get(h_axes(2), 'position'));
                axis(h2, 'off');
            end
            RGB = zeros([size(output.step3_upperBorderToRemove), 3]); RGB(:,:,1) = output.step3_upperBorderToRemove;
            im = imshow(RGB, 'parent', h2);
            set(im, 'AlphaData', 0.5.*double(output.step3_upperBorderToRemove));
        end

        % 4) Normalize mask-region column-wise
        % Columnwise nanmax and nanmin
        maxi = max(cropped, [], 1);                 % Get nanmax
        cropped(isnan(cropped)) = max(maxi(:));     % &
        mini = min(cropped, [], 1);                 % nanmin for each column
        mini(mini== max(maxi(:)))=NaN;
        cropped(repmat(~mask,1,1,size(cropped,3))) = NaN;
        % Normalize
        cropped = cropped-repmat(mini,size(cropped,1),1);
        cropped = cropped./repmat(maxi-mini, size(cropped,1),1);
        cropped = imgaussfilt(cropped, 1);
        output.step4_cropped_columnNormalized = cropped;
        if debug_here
            h_axes = debugfigure;

            imshow(output.step4_cropped_columnNormalized, 'parent', h_axes(3));
            title(h_axes(3), '3. Columns normalized', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end

        % 4) Get brightest pixels in each column
        br_y = max((cropped==repmat(max(cropped,[],1),size(cropped,1),1)).*repmat((1:size(cropped,1))',1,size(cropped,2)), [], 1);
        br_x = find(br_y~=0); br_y(br_y==0) = [];
%         [br_x2, br_y2] = contour_smooth(br_x, br_y, 0.05*length(br_x),false);
%         diffi = abs(br_y-interp1(br_x2, br_y2, br_x, 'linear', 'extrap'));
%         br_x(diffi>(1.5*median(diffi))) = [];
%         br_y(diffi>(1.5*median(diffi))) = [];
%         
        % Align Start to central dark line
%        br_y(1:floor(range(fEye.shape.x'))) = cdl.shape.y(1:floor(range(fEye.shape.x')))'; % Align Start to central dark line
        br_y(1:floor(1.5*range(fEye.shape.x'))) = newY(1:floor(1.5*range(fEye.shape.x')))'; % Align Start to central dark line
               
        % Fix Startpoint to eye center
        if ~ismember(round(eyecenter(1)), br_x)
            br_x = [round(eyecenter(1)), br_x];
            br_y = [round(eyecenter(2)), br_y];
        else
            br_y(br_x==round(eyecenter(1))) = round(eyecenter(2));
        end

        output.step5_nc_estimation_init = [br_x', br_y'];

        if debug_here
            h_axes = debugfigure;

            imshow(output.step4_cropped_columnNormalized, 'parent', h_axes(4));
            hold (h_axes(4), 'on')
                plot(output.step5_nc_estimation_init(:,1), output.step5_nc_estimation_init(:,2), 'r+', 'parent', h_axes(4));
            hold (h_axes(4), 'off')
            title(h_axes(4), '"Lower Notochord" - initial estimation', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end


        % Interpolate missing bright points
        fullrange = find(~isnan(upper),1,'first'):find(~isnan(upper),1,'last');
        br_y = interp1(br_x, br_y, fullrange, 'linear' ,'extrap' );
        br_x = fullrange;
        
        % Fix Startpoint to eye center
        rm = 2;
        %br_y(1:floor(rm*range(fEye.shape.x'))) = cdl.shape.y(1:floor(rm*range(fEye.shape.x')));
        br_y(1:floor(rm*range(fEye.shape.x'))) = newY(1:floor(rm*range(fEye.shape.x')));
        
        output.step5_nc_estimation_interpolated = [br_x', br_y'];

        % 6) Active contour to maximum
        cropped_temp = (im0);%cropped;%fobj.getImdata(uint8(cropped.*255));
        cropped_temp(cropped_temp<=max(cropped_temp(:)).*(parameterValues.low_thresh)) = max(cropped_temp(:));%(127+64);
        %cropped_temp=diff(cropped_temp,1,1);
        cropped_temp = uint8(getPeakImage(cropped_temp,5));
        cropped_temp(~output.step2_upper_fishmask) = max(cropped_temp(:));
        cropped_temp(cropped_temp>max(cropped_temp(:))*1/3) = max(cropped_temp(:));
        %cropped_temp = medfilt2(cropped_temp, [3,3]);
        cropped_temp = imgaussfilt(cropped_temp, 1);
        
        %cropped_temp(cropped_temp>=(127+100)) = (127+100);
        out = fishobj2.move2extreme(cropped_temp, [br_x', br_y'], 'min', false, dbug_active_contour);
        
        br_x = out(:,1); br_y = out(:,2);
        output.step6_nc = [br_x, br_y];

        % % % % % % % % % %
        % % % % % % % % % %

%         if debugStatus.debug_active_contour
%             try
%                 fig = findobj(0, 'parent', 0, 'Tag', 'move2extreme_debug');
%                 WinOnTop(msgbox('Close the debug figure to proceed'));
%                 waitfor(fig);
%             catch Me
%                 Me.getReport;
%             end
%         end
        
        %% % % NOTOCHORD UPPER BORDER:
        %im0 = fobj.getImdata('toGray', 'invert');

        % 7) Detect upper border of the Notochord
        % Erase all pixels below lower Notochord border
        mask = output.step2_upper_fishmask;
        rowmat = repmat((1:size(mask))', 1, size(mask,2));
        lower_nc = nan(1,size(mask,2)); lower_nc(br_x) = br_y;
            mask(mask.*rowmat > repmat(lower_nc, size(mask, 1), 1)) = 0;
        % Nan variant of mask
        nanmask = nan(size(mask)); nanmask(mask) = 1;
        % Get upper part of the fish
        cropped = im2double(im0).*repmat(nanmask,[1,1,size(im0,3)]);
        output.step7_upper_notochord_mask = mask;
        output.step7_inputImage_cropped = cropped;


        % 8) Don't accept bright pixels close to upper border
        % 8a) Get upper fish border
        mask_temp = nanmask; mask_temp(isnan(mask_temp)) = size(mask,1)+1;
        upper = min(mask_temp .* repmat((1:size(mask,1))', 1, size(mask,2)), [], 1);
        upper(upper == size(mask,1)+1) = NaN;
        % 8b) Get lower fish border
        mask_temp = nanmask; mask_temp(isnan(mask_temp)) = 0;
        lower = max(mask_temp .* repmat((1:size(mask,1))', 1, size(mask,2)), [], 1);
        lower(lower == 0) = NaN;
        % Calculate width at each point
        idxmask = (output.step2_upper_fishmask.* repmat((1:size(mask,1))', 1, size(mask,2)));
        upper_width = abs(lower-upper);
        %upper_width(isnan(upper_width)) = size(mask,1)+1;
        % Remove bright pixels close to upper border
        
        toRemove =                (idxmask >= repmat(upper, size(mask,1), 1)) & (idxmask < repmat(upper+parameterValues.upper_border_exclude_factor.*upper_width, size(mask,1), 1));

        cropped(toRemove) = NaN;
        mask(toRemove) = 0;
        output.step8_upperBorderToRemove = toRemove;

        if debug_here
            imshow(im2double(output.step1_inputImage).*nanmask, 'parent', h_axes(5))
            if isappdata(h_axes(5), 'overlay_axes')
                h2 = getappdata(h_axes(5), 'overlay_axes');
            else
                h2 = axes('parent', get(h_axes(5), 'parent'));
                setappdata(h_axes(5), 'overlay_axes', h2);
                set(h2, 'units', get(h_axes(5), 'units'), 'position', get(h_axes(5), 'position'));
                axis(h2, 'off');
            end
            RGB = zeros([size(output.step8_upperBorderToRemove), 3]); RGB(:,:,1) = output.step8_upperBorderToRemove;
            im = imshow(RGB, 'parent', h2);
            set(im, 'AlphaData', 0.5.*double(output.step8_upperBorderToRemove));
            title(h_axes(5), '"Upper Notochord" - cropped', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end


        % 8) Normalize mask-region column-wise
        % Columnwise nanmax and nanmin
        maxi = max(cropped, [], 1);                 % Get nanmax
        cropped(isnan(cropped)) = max(maxi(:));     % &
        mini = min(cropped, [], 1);                 % nanmin for each column
        mini(mini== max(maxi(:)))=NaN;
        cropped(repmat(~mask,1,1,size(cropped,3))) = NaN;
        % Normalize
        cropped = cropped-repmat(mini,size(cropped,1),1);
        cropped = cropped./repmat(maxi-mini, size(cropped,1),1);
        output.step8_cropped_columnNormalized = cropped;
        if debug_here
            h_axes = debugfigure;

            imshow(output.step8_cropped_columnNormalized, 'parent', h_axes(6));
            title(h_axes(6), '6. Columns normalized', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end


        % 9) Get startpixel
        br_x = output.step6_nc(:,1);                                        % Fix Startpoint to eye center
            br_y = (output.step6_nc(:,2)+upper(output.step6_nc(:,1))')./2; 
        % Add missing points... This can happen if upper has some gaps
        if any(isnan(br_y))
            br_y(isnan(br_y)) = interp1(find(~isnan(br_y)), br_y(~isnan(br_y)), find(isnan(br_y)), 'linear', 'extrap');
        end

        % Maka parallel to lower
        disti = output.step6_nc(:,2)-br_y;
        toReplace = bwlabel(abs(disti-median(disti))>(0.1*median(disti)));
        toReplace(toReplace~=toReplace(1))=0; toReplace=logical(toReplace);
        br_y(toReplace) = output.step6_nc(toReplace,2)-median(disti);
        
        % Align Beginning to the beginning of the lower
        rm1 = 0.5;
        leni1 = floor(rm1*range(fEye.shape.x'));
        br_y(1:leni1) = output.step6_nc(1:leni1,2);
        rm2 = 1.0;
        leni2 = floor(rm2*range(fEye.shape.x'));
        br_y(leni1:leni2) = output.step6_nc(leni1,2) + (0:(leni2-leni1)) .* (br_y(leni2)-output.step6_nc(leni1,2)) / (leni2-leni1);
        
%         % Fix Startpoint to eye center
%         if ~ismember(round(eyecenter(1)), br_x)
%             br_x = [round(eyecenter(1)); br_x];
%             br_y = [round(eyecenter(2)); br_y];
%         else
%             br_y(br_x==round(eyecenter(1))) = round(eyecenter(2));
%         end
        
        output.step9_nc_estimation_init = [br_x, br_y];

        if debug_here
            h_axes = debugfigure;

            hold (h_axes(6), 'on')
                plot(output.step9_nc_estimation_init(:,1), output.step9_nc_estimation_init(:,2), 'r+', 'parent', h_axes(6));
            hold (h_axes(6), 'off')
            title(h_axes(6), '"Upper Notochord" - initial estimation', 'HorizontalAlignment', 'left', 'Position', [0,0,0]);
        end

        % 10) Active contour to maximum
        %cropped_temp = uint8(getPeakImage(cropped,2));%fobj.getImdata(uint8(cropped.*255));
        cropped_temp = im0;
        cropped_temp = output.step8_cropped_columnNormalized;
        
        cropped_temp = output.step1_inputImage;%(fobj.getImdata('toGray'));
        cropped_temp(cropped_temp<=max(cropped_temp(:)).*(parameterValues.low_thresh)) = NaN;%(127+64);
        cropped_temp = uint8(getPeakImage(cropped_temp,5));

        %cropped_temp = uint8(getPeakImage(cropped_temp,ceil(median(disti)/2)));

        %cropped_temp(cropped_temp<=max(cropped(:)).*(parameterValues.low_thresh)) = NaN;%(127+64);
        %cropped_temp(cropped_temp>=(127+100)) = (127+100);
        %dbug_active_contour = true;
        out = fishobj2.move2extreme(cropped_temp, [br_x, br_y], 'min', false, dbug_active_contour);

        br_x = out(:,1); br_y = out(:,2);
        idxTooBig = br_y>=(output.step6_nc(:,2)-1);
        br_y(idxTooBig) = output.step6_nc(idxTooBig,2)-1; % Align to lower notochord line
        output.step10_nc = [br_x, br_y];
        
        
        %% Cut everything inside the eye
        toDelete = output.step6_nc(:,1) < max(fEye.shape.x);
        output.step6_nc(toDelete,:) = [];
        toDelete = output.step10_nc(:,1) < max(fEye.shape.x);
        output.step10_nc(toDelete,:) = [];
        
        
        
        %% Re-orient
        if fobj.fishOrientation.horizontally_flipped
            output.step6_nc(:,1) = size(im0, 2) - output.step6_nc(end:-1:1,1) + 1;
            output.step6_nc(:,2) = output.step6_nc(end:-1:1,2);
            output.step10_nc(:,1) = size(im0, 2) - output.step10_nc(end:-1:1,1) + 1;
            output.step10_nc(:,2) = output.step10_nc(end:-1:1,2);
        end
        if fobj.fishOrientation.vertically_flipped
            output.step6_nc(:,2) = size(im0, 1) - output.step6_nc(:,2) + 1;
            output.step10_nc(:,2) = size(im0, 1) - output.step10_nc(:,2) + 1;
        end
        
        
        %% Return Output
        calculationResults = struct('mode',                 'auto',...
                                    'parameter',            parameterValues,...
                                    'shape',                [ struct(  'name',     'notochord_upper',...
                                                                       'x',        output.step6_nc(:,1)',...
                                                                       'y',        output.step6_nc(:,2)'),...
                                                              struct(  'name',     'notochord_lower',...
                                                                       'x',        output.step10_nc(:,1)',...
                                                                       'y',        output.step10_nc(:,2)')]);

                                
        function l = range(a)
            l = max(a)-min(a);
        end

        function h_axes = debugfigure()
            persistent hf;
            if ~ishandle(hf)
                hf = findall(0, 'parent', 0, 'tag', debug_tag);
            end
            if isempty(hf)
                % Create debug figure
                hf = figure;
                set(hf, 'tag', debug_tag);
                h_axes(1) = subplot(2,3,1, 'parent', hf);
                h_axes(2) = subplot(2,3,2, 'parent', hf);
                h_axes(3) = subplot(2,3,3, 'parent', hf);
                h_axes(4) = subplot(2,3,4, 'parent', hf);
                h_axes(5) = subplot(2,3,5, 'parent', hf);
                h_axes(6) = subplot(2,3,6, 'parent', hf);
                setappdata(hf, 'axes', h_axes)
                for i = 1:6
                    set(h_axes(i), 'units', 'normalized');
                    pos = get(h_axes(i), 'position');
                    if ismember(i,[1,4])
                        set(h_axes(i), 'position', [0.025, pos(2)-0.1*pos(4), 0.28, pos(4)+0.2*pos(4)]);
                    elseif ismember(i,[2,5])
                        set(h_axes(i), 'position', [0.355, pos(2)-0.1*pos(4), 0.28, pos(4)+0.2*pos(4)]);
                    else
                        set(h_axes(i), 'position', [0.685, pos(2)-0.1*pos(4), 0.28, pos(4)+0.2*pos(4)]);
                    end
                end
            else
                h_axes = getappdata(hf, 'axes');
            end
        end
        
    end

    function manualModeFunction(fobj, ha, modeStatus, calculationResults,  parameterValues, debugStatus, ManualSelectionUpdateFCN)
               
        % Get parent figure
        hf = ancestor(ha.axes1, 'figure');
        hacki = [thisPlugin.parameterClassObject.handles.checkbox_showUpperExclusion,...
                 thisPlugin.parameterClassObject.handles.checkbox_showLowerExclusion,...
                 thisPlugin.parameterClassObject.handles.labelOpacity_showLowerExclusion,...
                 thisPlugin.parameterClassObject.handles.editDisplayOpacity_showLowerExclusion];
             
        switch modeStatus

            case {'manual', 'off', 0, false}
                %set(ha.axes1, 'ButtonDownFcn', @manual_mode_button_down_fcn);
                calculationResults.mode = 'manual';
                set(hacki, 'Enable', 'off');
                ManualSelectionUpdateFCN(calculationResults);
                
                cp = fobj.capillary.shape; namy = {cp.name};
                averageCapilaryWidth = round(mean(cp(strcmp(namy, 'lower')).y - cp(strcmp(namy, 'upper')).y));
                interactionRadius = max([1, round(0.2 * averageCapilaryWidth)]);
                
                lineselector(@manual_mode_button_up_fcn, 'nc', interactionRadius);
                
            case {'auto', 'on', 1, true}
                set(ha.axes1, 'ButtonDownFcn', []);
                set(hf, 'WindowButtonMotionFcn', []);
                set(hacki, 'Enable', 'on');
                
        end


        function manual_mode_button_up_fcn(br_x, br_y)
            dbug_active_contour = false;
            
            % Button is up again
            set(hf,     'WindowButtonUpFcn', []);
            
            cropped_temp = (fobj.getImdata('toGray'));
%            cropped_temp(cropped_temp<=max(cropped_temp(:)).*(parameterValues.low_thresh)) = NaN;%(127+64);
            cropped_temp = uint8(getPeakImage(cropped_temp,2));

            minMax = 'min';
            if fobj.fishOrientation.vertically_flipped
                minMax = 'max';
            end
            
            out = fishobj2.move2extreme(cropped_temp, [br_x{1}', br_y{1}'], minMax, false, dbug_active_contour);
            br_x{1} = out(:,1); br_y{1} = out(:,2);
            
            out = fishobj2.move2extreme(cropped_temp, [br_x{2}', br_y{2}'], minMax, false, dbug_active_contour);
            br_x{2} = out(:,1); br_y{2} = out(:,2);
            

            % Return Output
            calculationResults = struct('mode',                 'manual',...
                                        'parameter',            parameterValues,...
                                        'shape',                [ struct(  'name',     'notochord_upper',...
                                                                           'x',        br_x{1}(:)',...
                                                                           'y',        br_y{1}(:)'),...
                                                                  struct(  'name',     'notochord_lower',...
                                                                           'x',        br_x{2}(:)',...
                                                                           'y',        br_y{2}(:)')]);

            ManualSelectionUpdateFCN(calculationResults);
               
        end

    end

    function DrawingFunction(fobj, ha, calculationResults, parameterValues, displayStatus)
%         disp('Drawing Function')
%         disp(calculationResults)
%         disp(displayStatus)
                
        % % % %
        % Display Lower/Upper Exclusion
        if strcmp(calculationResults.mode, 'auto') &&...
           any([displayStatus.showUpperExclusion,...
                displayStatus.showLowerExclusion])
            % Draw it to overlay axes
            RGB = zeros([size(output.step8_upperBorderToRemove), 3]);
            if displayStatus.showUpperExclusion
                RGB(:,:,1) = output.step8_upperBorderToRemove;
            end
            if displayStatus.showUpperExclusion && displayStatus.showLowerExclusion
                RGB(:,:,3) = output.step3_upperBorderToRemove & ~output.step8_upperBorderToRemove;
            elseif displayStatus.showLowerExclusion
                %RGB(:,:,3) = output.step3_upperBorderToRemove;
                RGB(:,:,3) = ~output.step2_upper_fishmask;
            end
            
            if fobj.fishOrientation.horizontally_flipped, RGB = RGB(:,end:-1:1,:); end
            if fobj.fishOrientation.vertically_flipped,   RGB = RGB(end:-1:1,:,:); end
            
            imh = imshow(RGB, 'parent',  ha.axes_overlay);
            set(imh, 'AlphaData', displayStatus.showLowerExclusion_opacity.*(double(any(RGB,3))));
        else
            cla(ha.axes_overlay);
        end

        % % % %
        % Display Image
        im = fobj.getImdata('toGray');%, 'subtractBackground');
        oldTag        = get(ha.axes1, 'Tag');          % The Tag-property and ButtonDownFcn are erased when using imshow
        oldBtnDownFcn = get(ha.axes1, 'ButtonDownFcn');        
        imh = imshow((im), 'parent', ha.axes1);        
        set(imh, 'ButtonDownFcn', oldBtnDownFcn);        
        set(ha.axes1, 'Tag', oldTag, 'ButtonDownFcn', oldBtnDownFcn);      % This way we keep the Tag/ButtonDownFcn despite of imshow
        
        % % % %
        % Display Notochord
        if displayStatus.plot_Notochord
            % Draw it
            hold(ha.axes1, 'on')
                plot(calculationResults.shape(1).x,  calculationResults.shape(1).y, 'r', 'parent', ha.axes1, 'tag', 'nc');
                plot(calculationResults.shape(2).x,  calculationResults.shape(2).y, 'r', 'parent', ha.axes1, 'tag', 'nc');
            %    plot([calculationResults.shape(1).x, calculationResults.shape(2).x(end:-1:1)], [calculationResults.shape(1).y, calculationResults.shape(2).y(end:-1:1)] , 'r', 'parent', ha.axes1, 'tag', 'nc');
                
            hold(ha.axes1, 'off')
        end

    end

    function MainDrawingFunction(fobj, ha, calculationResults)

        plot(calculationResults.shape(1).x,  calculationResults.shape(1).y, 'r', 'parent', ha);
        plot(calculationResults.shape(2).x,  calculationResults.shape(2).y, 'r', 'parent', ha);
        
    end

end