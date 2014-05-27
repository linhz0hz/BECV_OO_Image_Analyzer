function [filename, path] = checkForFilename(file)
    if strcmp(file,'')
        [filename, path]=AbsorptionImageObject.selectFile();
    else
        [dir, name, ext] = fileparts(file);
        if strcmpi(ext,'.aia')
            if strcmp(dir,'')
                path=pwd;
            else
                path=dir;
            end
            filename=[name ext];
        else
            error('File is not a .aia');
        end
    end
    if path(end)~='\'
        path=[path '\'];
    end
end