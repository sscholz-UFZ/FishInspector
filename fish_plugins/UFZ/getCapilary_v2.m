function coords = getCapilary_v2(Im, thresh_mulitplier, vertCutoff, horizCutoff, steps, debug_here)
% Detection function used in capillary_fishPlugin.m
%
% Scientific Software Solutions
% Tobias Kießling 05/2016-08/2016
% support@tks3.de

    % Some parameter
    if ~exist('debug_here', 'var'), debug_here = false; end
    tag = 'getCapillary';
    normalizeColumns = false; % obsolete

    if ~exist('vertCutoff', 'var')
        vertCutoff = 20;
    end
    if ~exist('horizCutoff', 'var')
        horizCutoff = 20;
    end
    if ~exist('steps', 'var')
        steps = 20;
    end
    
    nor = size(Im, 1);  % Number of rows
    noc = size(Im, 2);  % Number of columns
    
%     Im = medfilt2(Im, [7,7]);
%     Im = Im - min(Im(:));
%     Im = Im./max(Im(:));
    
    % Show input image
    if debug_here
        ha = debugfigure;
        cla(ha(1), 'reset');
        imshow(Im, 'parent', ha(1));
        title(ha(1), 'Input Image');
    end
    
    % % % %
    % 1) Normalize column-wise using 5%/95% of sorted dynamic range as min & max
    if normalizeColumns
        As = sort(Im(vertCutoff+1:end-vertCutoff, :),1);
        nor2 = size(As,1);
        capilary_lower = As( ceil(0.05 * nor2), :);
        maxi = As(floor(0.95 * nor2), :);
        A = Im -  repmat(capilary_lower, nor, 1);
        A = A ./ repmat(maxi-capilary_lower, nor, 1);
        A(A>1)=1;   % Cut off high
        A(A<0)=0;   % and low values
    else
        A = abs(diff((Im),1,1));
        A = A-min(A(:));
        A = A./max(A(:));
        A = [A; zeros(1,size(A,2))];
    end
    % % % % 
    % Show column-wise normalized image
    if debug_here
        ha = debugfigure;
        cla(ha(2), 'reset');
        imshow(A, 'parent', ha(2));
        title(ha(2), 'Column-wise normalized');
    end

    % % % %
    % 2) Create binary image from column-wise normalized image...
    A = Im;
    B = im2bw(A, thresh_mulitplier*graythresh(A(vertCutoff+1:end-vertCutoff, horizCutoff+1:end-horizCutoff)));
    % % % %
    % Show binary image
    if debug_here
        ha = debugfigure;
        cla(ha(3), 'reset');
        imshow(B, 'parent', ha(3));
        title(ha(3), 'Binary Image');
    end
    % ...and find first and last non-zero row of the binary image for each column
    loc = B.*repmat((1:nor)', 1, noc); % location matrix
    loc([1:vertCutoff,end-vertCutoff+1:end], :) = NaN;
    loc(:,[1:horizCutoff,end-horizCutoff+1:end]) = NaN;
    capilary_lower = max(loc, [], 1);
    loc(loc==0) = nor;
    capilary_upper = min(loc, [], 1);
    % % % %
    % Plot upper and lower capilary 
    if debug_here
        ha = debugfigure;
        for j = 2 : 3
            hold(ha(j), 'on');
            plot(capilary_upper, 'r', 'parent', ha(j)); 
            plot(capilary_lower, 'r', 'parent', ha(j));
            hold(ha(j), 'off');
        end
    end

    % % % %
    % 3) Remove outliers from upper and lower capilary
    cl_fit = polyfit(horizCutoff+1:noc-horizCutoff, capilary_lower(horizCutoff+1:end-horizCutoff), 2); % Qudratic fit of
    cl_fit_vec = polyval(cl_fit, 1:noc);
    cu_fit = polyfit(horizCutoff+1:noc-horizCutoff, capilary_upper(horizCutoff+1:end-horizCutoff), 2); % detected edge points
    cu_fit_vec = polyval(cu_fit, 1:noc);
    % % % %
    % Plot upper and lower capilary quadratic fits
    if debug_here
        ha = debugfigure;
        for j = 2 : 3
            hold(ha(j), 'on');
            plot(cl_fit_vec, 'g', 'parent', ha(j)); 
            plot(cu_fit_vec, 'g', 'parent', ha(j)); 
            hold(ha(j), 'off');
        end
    end
    
    % % % %
    % 4) Get Subpixel location of outer capilary boundaries
    [PeakImage, B_diff] = getPeakImage(Im, 3);
    % % % %
    % Display PeakImage
    if debug_here
        ha = debugfigure;
        cla(ha(4), 'reset');
        imshow(label2rgb(PeakImage), 'parent', ha(4));
    end
    % Move upper to maxpeak
    edge_upper = move2extreme(PeakImage, cu_fit_vec, 'max');
    edge_upper = getSubpixel(B_diff, edge_upper, 'max');
    edge_upper_in = moveParallel(PeakImage, edge_upper, 1, 'min');
    edge_upper_in = move2extreme(PeakImage, edge_upper_in, 'min');
    edge_upper_in = getSubpixel(B_diff, edge_upper_in, 'min');
    % Move lower to minpeak
    edge_lower = move2extreme(PeakImage, cl_fit_vec, 'min');
    edge_lower = getSubpixel(B_diff, edge_lower, 'min');
    edge_lower_in = moveParallel(PeakImage, edge_lower, -1, 'max');
    edge_lower_in = move2extreme(PeakImage, edge_lower_in, 'max');
    edge_lower_in = getSubpixel(B_diff, edge_lower_in, 'max');
    % % % %
    % Plot upper and lower capilary 
    if debug_here
        ha = debugfigure;
        for j = 1 : 1
            hold(ha(j), 'on');
            plot(edge_upper, 'g', 'parent', ha(j)); 
            plot(edge_upper_in, 'b', 'parent', ha(j)); 
            plot(edge_lower, 'g', 'parent', ha(j));
            plot(edge_lower_in, 'b', 'parent', ha(j)); 
            hold(ha(j), 'off');
        end
    end
    
    
    % % % %
    % 5) Return coordinates
    coords = struct('upper', edge_upper,...
                    'upper_in', edge_upper_in,...
                    'lower', edge_lower,...
                    'lower_in', edge_lower_in);
    
    function out = move2extreme(peakimage, startline, minmax)
        is_circular = false;
        debug_here_  = false;
        out = fishobj2.move2extreme(peakimage, startline, minmax, is_circular, debug_here_);
    end
    
    function out = getSubpixel(B_diff, location, minmax)
        debug_here_ = false;
        if strcmpi(minmax, 'min')
            B_diff = -B_diff;
        end
        Mat4wmean = repmat((1:size(B_diff,1))', 1, size(B_diff,2));
        CleanRoi = zeros(size(B_diff));
        for shifty = -1:1
            idx = (0:(noc-1)).*nor + (location+shifty);
            idx(idx<1)=1; idx(idx>numel(CleanRoi)) = numel(CleanRoi);
            CleanRoi(idx) = 1;
        end
        out = wmean(Mat4wmean, (CleanRoi.*(B_diff-min(B_diff(:))).^2),1);        % Get Edge by weighted mean
        % Display PeakImage
        if debug_here_
            figure(123);
            ha = gca(123);
            imshow(label2rgb(B_diff), 'parent', ha);
            hold(ha, 'on');
            plot(out, 'g', 'parent', ha);
            
            drawnow;
            pause
        end  
        idx = 1:noc; idx(isnan(out)) = []; out(isnan(out)) = []; % Remove Nans before fitting
        out = polyfit(idx, out, 2); % Qudratic fit of
        out = polyval(out, 1:noc);
        out(out>nor) = nor; out(out<1) = 1; % Remove outliers
        if debug_here_
            plot(out, 'k', 'parent', ha);
            hold(ha, 'off');
        end
    end

    function out = moveParallel(peakimage, startline, direction, minmax)
        % direction either -1 or 1
        
        debug_here_ = false;
        if strcmpi(minmax, 'min')
            peakimage = max(peakimage(:))-peakimage;
        end
        
        out = round(startline);
        ok = false;
        %steps = 10;
        while ~ok
            
            val = zeros(1, steps);
            for i = 1 : steps
                val(i) = sum(peakimage((0:(noc-1)).*nor + (out+i*direction)));
            end
        
            ixi = 1:steps;
            loc1 = max(find(val==max(val)));
            if debug_here_
                figure(124); hax = gca(124);
                plot(ixi, val, 'parent', hax);
                hold(hax, 'on'); 
                plot([1,1].*loc1, [min(val), max(val)], 'parent', hax)
            end
            if loc1 == steps
                steps = steps + 1;
            else
                ok = true;
            end
        end
        
        ixi2 = (-1:1)+round(loc1); ixi2(ixi2<1) = 1; ixi2(ixi2>size(peakimage,1)) = size(peakimage,1);
        p = polyfit(ixi(ixi2), val(ixi2).^2, 2);
        loc2 = (-p(2)/(2*p(1)));
        if debug_here_
            plot(linspace(min(ixi(ixi2)), max(ixi(ixi2)), 100), polyval(p, linspace(min(ixi(ixi2)), max(ixi(ixi2)), 100)), 'parent', hax)
            plot([1,1].*loc2, [min(val.^2), max(val.^2)], 'parent', hax)
            hold(hax, 'off')
            pause
        end
        
        out = startline + loc2*direction;
        
    end

    function h_axes = debugfigure()
        persistent hf;
        if ~ishandle(hf)
            hf = findall(0, 'parent', 0, 'tag', tag);
        end
        if isempty(hf)
            % Create debug figure
            hf = figure;
            set(hf, 'tag', tag);
            h_axes(1) = subplot(4,1,1, 'parent', hf);
            h_axes(2) = subplot(4,1,2, 'parent', hf);
            h_axes(3) = subplot(4,1,3, 'parent', hf);
            h_axes(4) = subplot(4,1,4, 'parent', hf);
            setappdata(hf, 'axes', h_axes)
        else
            h_axes = getappdata(hf, 'axes');
        end
    end

end