function [x_smooth, y_smooth] = contour_smooth(x, y, fft_cutoff, closed)
% CONTOUR_SMOOTH(x, y, fft_cutoff, closed)
% Smooth 2D contours using fft approach. fft_cutoff is the number of
% used fourier coefficients (the less the smoother). If closed=true
% a closed contour is assumed.
%
% Scientific Software Solutions
% Tobias Kießling 01/2013-06/2016
% support@tks3.de

    % Default fft cutoff (10% of contour length)
    if ~exist('fft_cutoff', 'var') || isempty(fft_cutoff)
        fft_cutoff = ceil(0.10.*length(x));
    end
    if ~exist('closed', 'var')
        closed = true;
    end
    % Make sure we have row vectors
    x = x(:)'; y = y(:)';
    
    % Remove double points
    temp = unique([x;y]', 'rows', 'stable');
    x = temp(:,1)'; y = temp(:,2)';
    
    if closed
        % Close the contour
        x = [x, x(1)];
        y = [y, y(1)];
    else
        % mirror the edges (=>loose ends!)
        orig_length = length(x);
        x = [x(end:-1:2), x, x((end-1):-1:1)];
        y = [y(end:-1:2), y, y((end-1):-1:1)];
        fft_cutoff = fft_cutoff*((3*length(x)-2)/length(x));
    end
    
    % Smooth the contour using fft
    x_smooth = fft(x);
    x_smooth(fft_cutoff+1:end-fft_cutoff) = 0;
    x_smooth = real( ifft( x_smooth));
    
    
    y_smooth = fft(y);
    y_smooth(fft_cutoff+1:end-fft_cutoff) = 0;
    y_smooth = real( ifft( y_smooth));
    
    if ~closed
        x_smooth = x_smooth(orig_length+1:(orig_length*2));
        y_smooth = y_smooth(orig_length+1:(orig_length*2));
    end
end