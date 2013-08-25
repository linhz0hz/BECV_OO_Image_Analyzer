function [objAlreadyExists, obj] = checkForObject(filename)
    currentObjects = CloudImageObject.findall();
    objIndex=0;
    objAlreadyExists = false;
    while ~objAlreadyExists && objIndex<length(currentObjects)
         objIndex=objIndex+1;
         if currentObjects{objIndex}.filename == filename
              objAlreadyExists = true;
         end               
    end
    if objAlreadyExists
        obj=currentObjects{objIndex};
    else
        obj = {};
    end
end