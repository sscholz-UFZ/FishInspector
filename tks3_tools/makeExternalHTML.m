function makeExternalHTML

    ext_dir = 'C:\Users\tobi\Documents\Freelancer\UFZ\implementation\external';
    output_dir = fullfile(ext_dir, 'Licenses');
    % Delete previous content in the output directory
    if exist(output_dir, 'dir')==7
        rmdir(output_dir, 's');
    end
    mkdir(output_dir);
    
    % Get all folders of external functions
    folders = dir(ext_dir);
    folders(~[folders.isdir]) = [];
    folders(strcmp({folders.name}, 'Licenses')) = [];

    % Gather Information
    fileOut = {};
    for i = 1 : length(folders)
        
        thisName = folders(i).name;
        if ismember(thisName, {'.', '..'})
            continue;
        end
        
        files = dir(fullfile(ext_dir, folders(i).name, 'license*.txt'));
        if isempty(files)
            error(['no license*.txt file found in ', folders(i).name])
        else
            fileOut{end+1} = thisName;
            for j = 1 : length(files)
                copyfile(fullfile(ext_dir, folders(i).name, files(j).name),...
                         fullfile(output_dir, [thisName, '_', files(j).name]), 'f');
            end
        end
        
    end
    
    % Write File
    fid = fopen(fullfile(output_dir, '_externals.txt'), 'w');
    for i = 1 : length(fileOut)
        fprintf(fid, '%s\r\n', fileOut{i});
    end
    fclose(fid);
    
end