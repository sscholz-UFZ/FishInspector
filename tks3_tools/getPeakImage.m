function [PeakImage, B_diff] = getPeakImage(A, nextNeighbours)
% GETPEAKIMAGE(A, nextNeighbours)
% Create peakimage by counting nextNeighbours column-wise;
%
% Scientific Software Solutions
% Tobias Kieﬂling 01/2013-06/2016
% support@tks3.de


% % % % % % % % % % % % % % %
% Parameters & Constants    % 
nor = size(A, 1);           % Number of rows in A
noc = size(A, 2);           % Number of columns in A
% % % % % % % % % % % % % % % 
% Calculate 1st derivative  % 
%B_diff = [ zeros(1, noc); diff(A, 1, 1) ];  
%[~, B_diff] = imgradientxy(A, 'IntermediateDifference');
[~, B_diff] = imgradientxy(A, 'CentralDifference');
% Calculate Peakimage       % 
PeakImage = reshape(peakfinder(reshape(B_diff, 1, noc*nor)), nor, noc); % 
% % % % % % % % % % % % % % %

    function erg_p = peakfinder(unwrap)

        nn_before = zeros(nextNeighbours, size(unwrap,2));
        nn_after  = zeros(nextNeighbours, size(unwrap,2));

        pad_unwrap = repmat(unwrap,nextNeighbours,1);

        for i = 1 : 1 : nextNeighbours
            nn_before(i,:) = circshift(unwrap,[0  i]);    
            nn_after(i,:)  = circshift(unwrap,[0 -i]);
        end

        binary_before = (nn_before < pad_unwrap);
        binary_after = (nn_after < pad_unwrap);

        erg_p = sum(binary_before, 1) + sum(binary_after, 1);

    end

end
