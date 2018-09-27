function [im_out, coords_x, coords_y] = imunwrap_poly(im, x, y, method, closed, radius)
% [im_out, coords_x, coords_y] = IMUNWRAP_POLY(im, x, y, method, closed)
% Unwraps images along polynomial path.
%
% Scientific Software Solutions
% Tobias Kieﬂling 01/2013-08/2016
% support@tks3.de


    % Default Values
    if ~exist('x', 'var')                           % For debugging
        n =8;
        alpha = linspace(0, 2*pi, n); alpha = alpha(1:end-1);
        x = (10).*sin(alpha);
        y = (10).*cos(alpha);
    end
    if ~exist('method', 'var') || isempty(method)
        method = 'bicubic';
    end
    if ~exist('closed', 'var') || isempty(closed)
        closed = true;
    end
    if ~exist('radius', 'var') || isempty(radius)
        radius = 25;
    end
    interpolatePoints = true;
    
    % Ensure to have the image in double precision
    if ~isa(im, 'double')
        im = im2double(im);
    end
    
    % Remove double points
    temp = unique([x;y]', 'rows', 'stable');
    x = temp(:,1)'; y = temp(:,2)';
    
    % Apply boundary condition & Calculate contour length
    if closed
        % Nothing to do here
        
    else
        % Extent the ends
        x = [x(1)-abs(x(2)-x(1)), x, x(end)+abs(x(end)-x(end-1))];
        y = [y(1)-(y(2)-y(1)), y, y(end)+(y(end)-y(end-1))];
        
    end
    
    % Generate a set of equally spaced points along the shape
    if interpolatePoints
        if closed
            contour_length = cumsum([0, sqrt((x-x([2:end,1])).^2+(y-y([2:end,1])).^2)]);
            normLength = contour_length./max(contour_length(:));    
            x_i = interp1(normLength, x([1:end,1]), linspace(0, 1, contour_length(end)), 'pchip');
            y_i = interp1(normLength, y([1:end,1]), linspace(0, 1, contour_length(end)), 'pchip');
            x = x_i(1:end-1);
            y = y_i(1:end-1);
        else
            contour_length = cumsum([0, sqrt((x(1:end-1)-x(2:end)).^2+(y(1:end-1)-y(2:end)).^2)]);
            normLength = contour_length./max(contour_length(:));    
            x = interp1(normLength, x, linspace(normLength(2), normLength(end-1), contour_length(end)), 'pchip');
            y = interp1(normLength, y, linspace(normLength(2), normLength(end-1), contour_length(end)), 'pchip');
        end
    end
    

    % Calculate normals
    shape = [x', y'];
    righti = shape([2:end,1],:)-shape;
    lefti  = shape-shape([end,1:end-1],:);
    meani = (righti+lefti)./2;
    meani = meani./repmat(sqrt(sum(meani.^2,2)),1,2);
    normals = [-meani(:,2), meani(:,1)];

    % Calculate cartesian coordinates
    coords_x = (repmat(shape(:,1), 1, 2*radius+1) + normals(:,1)*(-radius:radius))';
    coords_y = (repmat(shape(:,2), 1, 2*radius+1) + normals(:,2)*(-radius:radius))';

    % Show normal vectors
%     figure(1), imshow(im); 
%     hold on;
%         line(coords_x', coords_y', 'color', [0,0,0])
%         plot(x, y, 'g', 'LineWidth', 2); 
%         axis equal
%     hold off;

    % Get Profile along normals
    [ixi, ysi] = meshgrid(1:size(im, 2), 1:size(im, 1));
    im_out = interp2(ixi, ysi, mean(im,3),...
                               coords_x, coords_y, 'bilinear');




% width = 10;
% nop = size(normals, 1);
% 
%     normals2_x = interp1(0:nop+1, normals([nop,1:nop,1], 1), linspace(0.5, nop+0.5, width*nop));
%     normals2_y = interp1(0:nop+1, normals([nop,1:nop,1], 2), linspace(0.5, nop+0.5, width*nop));
%     
%     shape2_x  = interp1(0:nop+1, shape([nop,1:nop,1], 1), linspace(0.5, nop+0.5, width*nop));
%     shape2_y  = interp1(0:nop+1, shape([nop,1:nop,1], 2), linspace(0.5, nop+0.5, width*nop));
%     
%     coords2_x = repmat(shape2_x', 1, 2*leng+1) + normals2_x'*(-leng:leng);
%     coords2_y = repmat(shape2_y', 1, 2*leng+1) + normals2_y'*(-leng:leng);
    
%     figure, imshow(Im_new); hold on;
%     plot(shape(:,1), shape(:,2),'+-')
%     line(coords2_x', coords2_y')
    
%    prof_large = interp2(ixi, ysi, mean(double(Im_new),3),...
%                         coords2_x, coords2_y);
%    [~, diffi_large] = imgradientxy(prof_large', 'CentralDifference'); diffi_large=-diffi_large;
    
    
	% Mean along width to get smaller version
%    prof = permute(reshape(prof_large', 2*leng+1, width, []),[2,1,3]);
%    prof = permute(mean(prof, 1), [2,3,1])';
    
%    diffi = permute(reshape(diffi_large, 2*leng+1, width, []),[2,1,3]);
%    diffi = permute(mean(diffi, 1), [2,3,1])';

    
end