function cdata = getImdata(name)
    
    diry = 'C:\Program Files\MATLAB\R2015b\toolbox\matlab\icons';
    [~, fname, ext] = fileparts(name);
    switch ext
        case '.png'
%             [A0, map, ALPHA] = imread(fullfile(diry, name));
%             if isempty(ALPHA)
%                 ALPHA = ones(size(A0));
%             end
%             A = im2double(ALPHA);
%             A = cat(3, A, A, A);
%             A(repmat((A(:,:,1)==0) & (A(:,:,2)==0) & (A(:,:,3)==0), [1,1,3])) = NaN;
%             A(repmat((A(:,:,1)==1) & (A(:,:,2)==1) & (A(:,:,3)==1), [1,1,3])) = 0;
            [A, ~, alpha] = imread(fullfile(diry, name));
            A = im2double(A);
            A(repmat((alpha==0),[1,1,3])) = NaN;
            
            
            
            
        case '.gif'
            [A, map, ALPHA] = imread(fullfile(diry, name));
            A = ind2rgb(A, map);
            A = im2double(A);
            A((A(:,:,1)==0) & (A(:,:,2)==0) & (A(:,:,3)==0)) = NaN;
    end
    
    
    cdata =A;