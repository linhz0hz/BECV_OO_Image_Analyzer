function tf = objExists(filename)
     currentObjects = AbsorptionImageObject.findall();
           objIndex=0;
           tf = false;
           while ~tf && objIndex<length(currentObjects)
               objIndex=objIndex+1;
               if currentObjects{objIndex}.filename == filename
                   tf = true;
               end               
           end
end