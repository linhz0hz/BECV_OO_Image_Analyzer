function [aiaData] = readAIA(filename)
%READAIA Loads an AIA file specificied by a string argument. Returns a
%   cell array of vectors that specify the names (1) and values (2)of all 
%   the images and/or properties contained in the file, or returns 0 if the
%   file specified in the calling sequence does not exist or is not a vaild
%   AIA.
%
%   aiaData = READAIA('filename')

%   aiaData = READAIA('filename','image3')
%   aiaData = READAIA('filename','MOTFREQ','TOF')
    aiaData=0; %initialize return value to 0 (invalid format)
  
    fid = fopen(filename);      %open the file
    fileFormat = fread(fid,3,'char*1'); %read the file format
    
    if strcmpi(char(fileFormat'),'aia')==0     %check for valid file format
        return
    end
    
    bytesPerInt = fread(fid,1,'uint16');    %read the integer format
    if (bytesPerInt==2)     %check for valid integer format
        intFormat='uint16';
    elseif (bytesPerInt==1)
        intFormat='uint8';
    else
        return
    end
    
    aiaData={};     %initialize return value to empty (valid format checks passed)
    numRows = fread(fid,1,intFormat);      %read the number of rows
    numColumns = fread(fid,1,intFormat);   %read the number of columns
    numImages = fread(fid,1,intFormat);    %read the number of images
    imageLength=numRows*numColumns;           %calculate and store the length of a single image
    imageData = fread(fid,numRows*numColumns*numImages,intFormat);    %read out all image data    
    for i=1:numImages
        aiaData{i} = {['image' num2str(i)];...
            reshape(imageData((1+(i-1)*imageLength):(i*imageLength)),numColumns,numRows)'}; % format images
    end
    
    fread(fid,1,'char*1');      %check for end of file
    propertyNumber=numImages+1;
    while ~feof(fid) 
        propertyName=char(0);
        lastchar='!';
        fseek(fid,-1,0);    %back up one byte after end-of-file check
    
        while lastchar~=char(0)
            lastchar=char(fread(fid,1,'char*1'));   %read property name
            propertyName=strcat(propertyName,lastchar);
        end
    
        propertyValue=fread(fid,1,'double');    %read property value
        aiaData{propertyNumber}={propertyName;propertyValue};   %assign ouput value
        propertyNumber=propertyNumber+1;
        fread(fid,1,'char*1');      %check for end of file
    end

    fclose(fid);    %close file    
end