function tf = isdeployed

    % Disable annoying warnings
    warning('off', 'MATLAB:dispatcher:nameConflict');
    
    if builtin('isdeployed')
        tf = true;
    else
        tf = false;
    end


end